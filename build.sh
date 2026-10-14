#!/usr/bin/env bash
# Compila SlimSkins contra MCP 5.6 + ModLoader 1.1 dentro de GitHub Actions.
# El minecraft.jar NO esta en el repositorio: se descarga de Mojang en cada build.
# ModLoader 1.1 (zip) SI debe estar en el repositorio (ver instrucciones).
set -euo pipefail

: "${MCP_URL:?Falta la variable MCP_URL}"

ROOT="$PWD"
WORK="$ROOT/work"

ML_ZIP="$(find "$ROOT" -maxdepth 1 -iname 'modloader*.zip' | head -1)"
if [ -z "$ML_ZIP" ]; then
  echo "ERROR: falta el zip de ModLoader 1.1 en la raiz del repositorio."
  echo "Descargalo (ModLoader 1.1.zip) y subelo al repo."
  exit 1
fi
echo "ModLoader: $ML_ZIP"
sha256sum "$ML_ZIP" || true
echo "(sha256 esperado: b56d925adc210773e4b2390f8189e16456910da4bcd4276b492bb382ea04f079)"

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
  echo "AVISO: no pude bajar minecraft_server.jar (no se uso hasta ahora)."
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

echo "== Agregando ModLoader a minecraft.jar =="
mkdir -p ml
unzip -q -o "$ML_ZIP" -d ml
MLCLASS="$(find ml -name 'ModLoader.class' | head -1)"
test -n "$MLCLASS" || { echo "El zip de ModLoader no trae ModLoader.class. Contenido:"; find ml | head -30; exit 1; }
MLDIR="$(dirname "$MLCLASS")"
(cd "$MLDIR" && zip -qr "$WORK/mcp/jars/bin/minecraft.jar" . -x 'META-INF/*')
unzip -l mcp/jars/bin/minecraft.jar | grep -E 'ModLoader|BaseMod' | head -5 || true

echo "== Decompilando con MCP (puede tardar unos minutos) =="
cd mcp
chmod +x ./*.sh 2>/dev/null || true
dos2unix -q ./*.sh 2>/dev/null || true
bash decompile.sh < /dev/null || true
bash updatemd5.sh < /dev/null || true

SRC="$WORK/mcp/src/minecraft/net/minecraft/src"
if [ ! -d "$SRC" ]; then
  echo "== DIAGNOSTICO: no se creo src =="
  ls -la jars jars/bin 2>&1 | head -30 || true
  ls logs 2>&1 || true
  for f in logs/*.log; do echo "--- $f"; tail -n 40 "$f"; done 2>/dev/null || true
  echo "La decompilacion fallo"
  exit 1
fi

echo "== Copiando el mod y parcheando ImageBufferDownload =="
cp "$ROOT"/*.java "$SRC"/
python3 "$ROOT/patch_parser.py" "$SRC/ImageBufferDownload.java"

echo "== Recompilando =="
if ! bash recompile.sh > "$WORK/recompile.log" 2>&1; then
  echo "== ERRORES DE COMPILACION (resumen) =="
  echo "-- total de errores:"
  grep -cE '\.java:[0-9]+: error' "$WORK/recompile.log" || true
  echo "-- errores por archivo:"
  grep -E '\.java:[0-9]+: error' "$WORK/recompile.log" | sed -E 's/:[0-9]+: error.*//; s#^src/minecraft/net/minecraft/##' | sort | uniq -c | sort -rn | head -25 || true
  echo "-- primeros errores:"
  grep -E -A2 '\.java:[0-9]+: error' "$WORK/recompile.log" | sed 's#src/minecraft/net/minecraft/##' | head -80 || true
  exit 1
fi
echo "== Reofuscando =="
bash reobfuscate.sh

echo "== Empaquetando clases =="
OUT="$WORK/mcp/reobf/minecraft"
test -d "$OUT" || { echo "No hay salida en $OUT"; exit 1; }
cd "$OUT"
zip -qr "$ROOT/dist/slimskins-classes.zip" .
cp "$ROOT/README.md" "$ROOT/dist/README.md"
echo "Listo: dist/slimskins-classes.zip"
