#!/usr/bin/env python3
"""Reemplaza el cuerpo de ImageBufferDownload.parseUserSkin por una llamada a SlimSkinParser."""
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
src = path.read_text(encoding="utf-8", errors="replace")

m = re.search(r"public\s+BufferedImage\s+\w+\s*\(\s*BufferedImage\s+(\w+)\s*\)\s*\{", src)
if not m:
    sys.exit("No encontre el metodo que recibe y devuelve BufferedImage en " + str(path))

arg = m.group(1)
depth = 1
i = m.end()
while i < len(src) and depth > 0:
    c = src[i]
    if c == "{":
        depth += 1
    elif c == "}":
        depth -= 1
    i += 1
if depth != 0:
    sys.exit("Llaves desbalanceadas en " + str(path))

new_body = "\n        return SlimSkinParser.parse(%s);\n    }" % arg
patched = src[: m.end()] + new_body + src[i:]
path.write_text(patched, encoding="utf-8")
print("Parcheado:", path)
