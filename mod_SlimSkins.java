package net.minecraft.src;

import java.util.Map;

/**
 * SlimSkins para Minecraft 1.1 + Forge/ModLoader.
 * Reemplaza el render del jugador para soportar skins 64x64 y 128x128
 * (con capas extra) y brazos slim (3 px).
 *
 * Skins slim: el nombre del jugador debe estar en slimskins.txt
 * (carpeta .minecraft), ver SlimConfig.
 */
public class mod_SlimSkins extends BaseMod {

    public String getVersion() {
        return "1.0 (MC 1.1)";
    }

    public void load() {
        // nada que registrar aqui, el render se registra en addRenderer
    }

    @Override
    public void addRenderer(Map map) {
        // Sustituye el renderer del jugador por el nuestro
        map.put(EntityPlayer.class, new RenderSlimPlayer());
    }
}
