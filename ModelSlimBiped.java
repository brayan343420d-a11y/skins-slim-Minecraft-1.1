package net.minecraft.src;

/**
 * Modelo de jugador con formato de skin moderno (64x64 logico).
 * Como las UV se normalizan, tambien funciona con skins de 128x128.
 * Incluye capas extra (chaqueta, mangas, pantalones) y brazos slim (3 px).
 */
public class ModelSlimBiped extends ModelBiped {

    public ModelRenderer bipedJacket;
    public ModelRenderer bipedRightSleeve;
    public ModelRenderer bipedLeftSleeve;
    public ModelRenderer bipedRightPants;
    public ModelRenderer bipedLeftPants;

    public final boolean slim;

    public ModelSlimBiped(float f, boolean slim) {
        super(f);
        this.slim = slim;
        this.textureWidth = 64;
        this.textureHeight = 64;

        int armW = slim ? 3 : 4;
        float armY = slim ? 2.5F : 2.0F;
        float rx = slim ? -2.0F : -3.0F;
        float lx = -1.0F;
        float o = 0.25F;

        bipedHead = part(0, 0, -4F, -8F, -4F, 8, 8, 8, f);
        bipedHead.setRotationPoint(0F, 0F, 0F);
        bipedHeadwear = part(32, 0, -4F, -8F, -4F, 8, 8, 8, f + 0.5F);
        bipedHeadwear.setRotationPoint(0F, 0F, 0F);

        bipedBody = part(16, 16, -4F, 0F, -2F, 8, 12, 4, f);
        bipedBody.setRotationPoint(0F, 0F, 0F);
        bipedJacket = part(16, 32, -4F, 0F, -2F, 8, 12, 4, f + o);
        bipedJacket.setRotationPoint(0F, 0F, 0F);

        bipedRightArm = part(40, 16, rx, -2F, -2F, armW, 12, 4, f);
        bipedRightArm.setRotationPoint(-5F, armY, 0F);
        bipedRightSleeve = part(40, 32, rx, -2F, -2F, armW, 12, 4, f + o);
        bipedRightSleeve.setRotationPoint(-5F, armY, 0F);

        bipedLeftArm = part(32, 48, lx, -2F, -2F, armW, 12, 4, f);
        bipedLeftArm.setRotationPoint(5F, armY, 0F);
        bipedLeftSleeve = part(48, 48, lx, -2F, -2F, armW, 12, 4, f + o);
        bipedLeftSleeve.setRotationPoint(5F, armY, 0F);

        bipedRightLeg = part(0, 16, -2F, 0F, -2F, 4, 12, 4, f);
        bipedRightLeg.setRotationPoint(-1.9F, 12F, 0F);
        bipedRightPants = part(0, 32, -2F, 0F, -2F, 4, 12, 4, f + o);
        bipedRightPants.setRotationPoint(-1.9F, 12F, 0F);

        bipedLeftLeg = part(16, 48, -2F, 0F, -2F, 4, 12, 4, f);
        bipedLeftLeg.setRotationPoint(1.9F, 12F, 0F);
        bipedLeftPants = part(0, 48, -2F, 0F, -2F, 4, 12, 4, f + o);
        bipedLeftPants.setRotationPoint(1.9F, 12F, 0F);
    }

    private ModelRenderer part(int u, int v, float x, float y, float z, int w, int h, int d, float grow) {
        ModelRenderer r = new ModelRenderer(this, u, v);
        r.addBox(x, y, z, w, h, d, grow);
        return r;
    }

    private static void copy(ModelRenderer from, ModelRenderer to) {
        to.rotationPointX = from.rotationPointX;
        to.rotationPointY = from.rotationPointY;
        to.rotationPointZ = from.rotationPointZ;
        to.rotateAngleX = from.rotateAngleX;
        to.rotateAngleY = from.rotateAngleY;
        to.rotateAngleZ = from.rotateAngleZ;
    }

    @Override
    public void setRotationAngles(float f, float f1, float f2, float f3, float f4, float f5) {
        super.setRotationAngles(f, f1, f2, f3, f4, f5);
        copy(bipedBody, bipedJacket);
        copy(bipedRightArm, bipedRightSleeve);
        copy(bipedLeftArm, bipedLeftSleeve);
        copy(bipedRightLeg, bipedRightPants);
        copy(bipedLeftLeg, bipedLeftPants);
    }

    @Override
    public void render(Entity entity, float f, float f1, float f2, float f3, float f4, float f5) {
        super.render(entity, f, f1, f2, f3, f4, f5);
        // capas externas (setRotationAngles ya se llamo dentro de super.render)
        bipedJacket.render(f5);
        bipedRightSleeve.render(f5);
        bipedLeftSleeve.render(f5);
        bipedRightPants.render(f5);
        bipedLeftPants.render(f5);
    }
}
