#!/usr/bin/env bash
# Compila SlimSkins contra Forge 1.1 + MCP dentro de GitHub Actions.
# El minecraft.jar NO esta en el repositorio: se descarga de Mojang en cada build.
set -euo pipefail

: "${FORGE_SRC_URL:?Falta FORGE_SRC_URL}"
: "${MCP_URL:?Falta la variable MCP_URL}"

ROOT="$PWD"
WORK="$ROOT/work"
rm -rf "$WORK" "$ROOT/dist"
mkdir -p "$WORK" "$ROOT/dist"

echo "== Instalando wine (MCP 5.6 usa jad.exe en Linux) =="
sudo dpkg --add-architecture i386
sudo apt-get update -qq
sudo apt-get install -y -qq wine wine32:i386 wine64 xvfb
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree,mshtml="
export WINEPREFIX="$HOME/.wine"
xvfb-run -a wineboot -u >/dev/null 2>&1 || true
wine --version || true

cd "$WORK"

echo "== Descargando MCP =="
curl -fsSL "$MCP_URL" -o mcp.zip
mkdir -p mcp
unzip -q mcp.zip -d mcp
# algunos zips traen una carpeta intermedia
if [ ! -f mcp/decompile.sh ] && [ "$(ls mcp | wc -l)" = "1" ]; then
  inner="mcp/$(ls mcp)"
  mv "$inner"/* mcp/
  rmdir "$inner"
fi
test -f mcp/decompile.sh || { echo "MCP no trae decompile.sh. Contenido:"; ls mcp; exit 1; }

echo "== Descargando Forge (src) dentro de MCP =="
curl -fsSL "$FORGE_SRC_URL" -o forge.zip
unzip -q forge.zip -d mcp          # crea mcp/forge/
test -f mcp/forge/install.sh || { echo "Forge no trae forge/install.sh. Contenido:"; ls mcp; exit 1; }

echo "== Descargando jars oficiales de Minecraft 1.1 =="
MANIFEST=$(curl -fsSL https://piston-meta.mojang.com/mc/game/version_manifest_v2.json)
VURL=$(echo "$MANIFEST" | jq -r '.versions[] | select(.id=="1.1") | .url')
test -n "$VURL" || { echo "No encontre la version 1.1 en el manifest de Mojang"; exit 1; }
VJSON=$(curl -fsSL "$VURL")
mkdir -p mcp/jars/bin
curl -fsSL "$(echo "$VJSON" | jq -r '.downloads.client.url')" -o mcp/jars/bin/minecraft.jar

SERVER_URL=$(echo "$VJSON" | jq -r '.downloads.server.url // empty')
if [ -z "$SERVER_URL" ]; then
  SERVER_URL="https://s3.amazonaws.com/Minecraft.Download/versions/1.1/minecraft_server.1.1.jar"
fi
if ! curl -fsSL "$SERVER_URL" -o mcp/jars/minecraft_server.jar; then
  rm -f mcp/jars/minecraft_server.jar
  echo "AVISO: no pude bajar minecraft_server.jar; MCP puede fallar al decompilar."
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
  curl -fsSL "$u" -o "mcp/jars/bin/$out"
done

echo "== Instalando Forge sobre MCP (decompila, puede tardar) =="
cd mcp
chmod +x ./*.sh forge/*.sh 2>/dev/null || true
dos2unix -q ./*.sh forge/*.sh 2>/dev/null || true
# Si install.sh sube una carpeta (cd ..), se ejecuta desde forge/; si no, desde la raiz de MCP
if grep -qE '^[[:space:]]*(cd|pushd)[[:space:]]+\.\.' forge/install.sh; then
  (cd forge && bash install.sh < /dev/null) || true
else
  bash forge/install.sh < /dev/null || true
fi

SRC="$WORK/mcp/src/minecraft/net/minecraft/src"
if [ ! -d "$SRC" ]; then
  echo "== DIAGNOSTICO: no se creo src =="
  ls -la jars jars/bin 2>&1 | head -30 || true
  ls logs 2>&1 || true
  for f in logs/*.log; do echo "--- $f"; tail -n 40 "$f"; done 2>/dev/null || true
  echo "La instalacion de Forge fallo"
  exit 1
fi

echo "== Copiando el mod y parcheando ImageBufferDownload =="
cp "$ROOT"/*.java "$SRC"/
python3 "$ROOT/patch_parser.py" "$SRC/ImageBufferDownload.java"

echo "== Recompilando y reofuscando =="
bash recompile.sh
bash reobfuscate.sh

echo "== Empaquetando clases =="
OUT="$WORK/mcp/reobf/minecraft"
test -d "$OUT" || { echo "No hay salida en $OUT"; exit 1; }
cd "$OUT"
zip -qr "$ROOT/dist/slimskins-classes.zip" .
cp "$ROOT/README.md" "$ROOT/dist/README.md"
echo "Listo: dist/slimskins-classes.zip"
