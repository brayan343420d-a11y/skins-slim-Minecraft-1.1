# SlimSkins para Minecraft 1.1 (Forge / ModLoader)

Soporta skins 64x64 y 128x128 (con capas extra) y brazos slim.
**Codigo sin compilar ni probar**: los nombres de metodos/campos pueden requerir
ajustes segun el MCP de tu Forge 1.1.

## Archivos
Copia todos los .java a `mcp/src/minecraft/net/minecraft/src/`:
- mod_SlimSkins.java    -> registra el renderer
- RenderSlimPlayer.java -> elige modelo ancho o slim
- ModelSlimBiped.java   -> modelo con capas y brazos de 3 px
- SlimSkinParser.java   -> convierte la skin sin recortarla a 64x32
- SlimConfig.java       -> lee slimskins.txt

## Cambio obligatorio en el codigo del juego
La descarga de skins recorta la imagen a 64x32. En `ImageBufferDownload.java`
(metodo `parseUserSkin`) reemplaza todo el cuerpo por:

    return SlimSkinParser.parse(bufferedimage);

(Si tu MCP lo nombra distinto, es el metodo de la interfaz IImageBuffer.)

## Compilar
1. En la carpeta de Forge/MCP: `recompile` y luego `reobfuscate`.
2. Los .class de `reobf/minecraft` van dentro de minecraft.jar (o como mod en /mods si tu Forge lo permite).

## Usar slim
Crea `slimskins.txt` en la carpeta .minecraft (se genera uno de ejemplo al
primer inicio) y escribe tu nombre de jugador, una linea por nombre.
