#!/usr/bin/env bash
# Compila SlimSkins contra Forge 1.1 + MCP dentro de GitHub Actions.
# El minecraft.jar NO esta en el repositorio: se descarga de Mojang en cada build.
set -euo pipefail

: "${FORGE_SRC_URL:?Falta FORGE_SRC_URL}"
: "${MCP_URL:?Falta la variable MCP_URL (zip de MCP para 1.1). Ver GITHUB.md}"

ROOT="$PWD"
WORK="$ROOT/work"
rm -rf "$WORK" "$ROOT/dist"
mkdir -p "$WORK" "$ROOT/dist"
cd "$WORK"

echo "== Descargando Forge (src) =="
curl -fsSL "$FORGE_SRC_URL" -o forge.zip
unzip -q forge.zip            # debe crear la carpeta forge/
test -d forge || { echo "El zip de Forge no creo la carpeta forge/"; exit 1; }

echo "== Descargando MCP =="
curl -fsSL "$MCP_URL" -o mcp.zip
mkdir -p forge/mcp
unzip -q mcp.zip -d forge/mcp
# algunos zips traen una carpeta intermedia
if [ ! -d forge/mcp/jars ] && [ "$(ls forge/mcp | wc -l)" = "1" ]; then
  inner="forge/mcp/$(ls forge/mcp)"
  mv "$inner"/* forge/mcp/ && rmdir "$inner"
fi

echo "== Descargando jars oficiales de Minecraft 1.1 desde Mojang =="
MANIFEST=$(curl -fsSL https://piston-meta.mojang.com/mc/game/version_manifest_v2.json)
VURL=$(echo "$MANIFEST" | jq -r '.versions[] | select(.id=="1.1") | .url')
test -n "$VURL" || { echo "No encontre la version 1.1 en el manifest de Mojang"; exit 1; }
VJSON=$(curl -fsSL "$VURL")
mkdir -p forge/mcp/jars/bin
curl -fsSL "$(echo "$VJSON" | jq -r '.downloads.client.url')" -o forge/mcp/jars/bin/minecraft.jar
SERVER_URL=$(echo "$VJSON" | jq -r '.downloads.server.url // empty')
if [ -n "$SERVER_URL" ]; then
  curl -fsSL "$SERVER_URL" -o forge/mcp/jars/minecraft_server.jar
else
  echo "AVISO: Mojang no publica minecraft_server.jar para 1.1; MCP puede pedirlo."
fi
# librerias (lwjgl, jinput...) con los nombres que espera MCP
echo "$VJSON" | jq -r '.libraries[].downloads.artifact.url // empty' | while read -r u; do
  f="$(basename "$u")"
  case "$f" in
    lwjgl_util*|lwjgl-util*) out="lwjgl_util.jar" ;;
    lwjgl-platform*)         continue ;;
    lwjgl*)                  out="lwjgl.jar" ;;
    jinput-platform*)        continue ;;
    jinput*)                 out="jinput.jar" ;;
    *)                       out="$f" ;;
  esac
  curl -fsSL "$u" -o "forge/mcp/jars/bin/$out"
done

echo "== Instalando Forge sobre MCP (decompila, puede tardar) =="
cd forge
dos2unix -q install.sh 2>/dev/null || true
bash install.sh
cd ..

SRC="forge/mcp/src/minecraft/net/minecraft/src"
test -d "$SRC" || { echo "No existe $SRC; la instalacion de Forge fallo"; exit 1; }

echo "== Copiando el mod y parcheando ImageBufferDownload =="
cp "$ROOT"/*.java "$SRC"/
python3 "$ROOT/patch_parser.py" "$SRC/ImageBufferDownload.java"

echo "== Recompilando y reofuscando =="
cd forge/mcp
bash recompile.sh
bash reobfuscate.sh
cd "$WORK"

echo "== Empaquetando clases =="
OUT="forge/mcp/reobf/minecraft"
test -d "$OUT" || { echo "No hay salida en $OUT"; exit 1; }
cd "$OUT"
# nombres reofuscados de ImageBufferDownload/RenderPlayer/etc. cambian: se entrega todo lo que cambio
zip -qr "$ROOT/dist/slimskins-classes.zip" .
cp "$ROOT/README.md" "$ROOT/dist/README.md"
echo "Listo: dist/slimskins-classes.zip"
