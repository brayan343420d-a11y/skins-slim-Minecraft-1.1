package net.minecraft.src;

import java.lang.reflect.Field;

/**
 * Renderer de jugador que alterna entre modelo ancho (Steve) y slim (Alex)
 * segun la lista de slimskins.txt.
 */
public class RenderSlimPlayer extends RenderPlayer {

    private final ModelSlimBiped wideModel = new ModelSlimBiped(0.0F, false);
    private final ModelSlimBiped slimModel = new ModelSlimBiped(0.0F, true);
    private final Field mainBipedField;

    public RenderSlimPlayer() {
        super();
        mainBipedField = findMainBipedField();
    }

    /** modelBipedMain es privado en RenderPlayer: se busca por tipo (es el primer ModelBiped declarado). */
    private Field findMainBipedField() {
        Field[] fields = RenderPlayer.class.getDeclaredFields();
        for (int i = 0; i < fields.length; i++) {
            if (fields[i].getType() == ModelBiped.class) {
                fields[i].setAccessible(true);
                return fields[i];
            }
        }
        return null;
    }

    private void useModelFor(String username) {
        ModelSlimBiped m = SlimConfig.isSlim(username) ? slimModel : wideModel;
        this.mainModel = m;
        try {
            if (mainBipedField != null) {
                mainBipedField.set(this, m);
            }
        } catch (Exception e) {
            // si falla, se queda el modelo anterior
        }
    }

    @Override
    public void renderPlayer(EntityPlayer entityplayer, double d, double d1, double d2, float f, float f1) {
        useModelFor(entityplayer.username);
        super.renderPlayer(entityplayer, d, d1, d2, f, f1);
    }

    @Override
    public void drawFirstPersonHand() {
        EntityPlayer local = ModLoader.getMinecraftInstance().thePlayer;
        useModelFor(local != null ? local.username : null);
        super.drawFirstPersonHand();
    }
}
