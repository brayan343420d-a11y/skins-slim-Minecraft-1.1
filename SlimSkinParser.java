package net.minecraft.src;

import java.awt.image.BufferedImage;

/**
 * Convierte la skin descargada a un formato 64x64 (o 128x128) sin recortarla.
 * Se usa desde ImageBufferDownload.parseUserSkin (ver README).
 */
public class SlimSkinParser {

    public static BufferedImage parse(BufferedImage src) {
        if (src == null) {
            return null;
        }
        int w = src.getWidth();
        int h = src.getHeight();
        if (w < 64 || w % 64 != 0) {
            return src; // tamano raro: se deja tal cual
        }
        int s = w / 64;
        boolean legacy = (h == 32 * s);
        if (!legacy && h != 64 * s) {
            return src;
        }

        BufferedImage out = new BufferedImage(w, 64 * s, BufferedImage.TYPE_INT_ARGB);
        java.awt.Graphics g = out.getGraphics();
        g.drawImage(src, 0, 0, null);
        g.dispose();

        if (legacy) {
            // reconstruye pierna y brazo izquierdos espejando los derechos
            int[][] r = {
                {4, 16, 16, 32, 4, 4}, {8, 16, 16, 32, 4, 4},
                {0, 20, 24, 32, 4, 12}, {4, 20, 16, 32, 4, 12},
                {8, 20, 8, 32, 4, 12}, {12, 20, 16, 32, 4, 12},
                {44, 16, -8, 32, 4, 4}, {48, 16, -8, 32, 4, 4},
                {40, 20, 0, 32, 4, 12}, {44, 20, -8, 32, 4, 12},
                {48, 20, -16, 32, 4, 12}, {52, 20, -8, 32, 4, 12}
            };
            for (int i = 0; i < r.length; i++) {
                copyMirrored(out, s, r[i][0], r[i][1], r[i][2], r[i][3], r[i][4], r[i][5]);
            }
            // en skins viejas, si la capa del casco no tiene transparencia se descarta
            notchHack(out, s, 32, 0, 64, 16);
        }

        // las capas base siempre son opacas
        setOpaque(out, s, 0, 0, 32, 16);
        setOpaque(out, s, 0, 16, 64, 32);
        setOpaque(out, s, 16, 48, 48, 64);
        return out;
    }

    private static void copyMirrored(BufferedImage img, int s, int x, int y, int xo, int yo, int w, int h) {
        for (int dy = 0; dy < h * s; dy++) {
            for (int dx = 0; dx < w * s; dx++) {
                int px = img.getRGB(x * s + dx, y * s + dy);
                int tx = (x + xo) * s + (w * s - 1 - dx);
                int ty = (y + yo) * s + dy;
                img.setRGB(tx, ty, px);
            }
        }
    }

    private static void notchHack(BufferedImage img, int s, int x1, int y1, int x2, int y2) {
        for (int y = y1 * s; y < y2 * s; y++) {
            for (int x = x1 * s; x < x2 * s; x++) {
                if (((img.getRGB(x, y) >> 24) & 0xFF) < 128) {
                    return; // hay transparencia real, se conserva
                }
            }
        }
        for (int y = y1 * s; y < y2 * s; y++) {
            for (int x = x1 * s; x < x2 * s; x++) {
                img.setRGB(x, y, img.getRGB(x, y) & 0x00FFFFFF);
            }
        }
    }

    private static void setOpaque(BufferedImage img, int s, int x1, int y1, int x2, int y2) {
        for (int y = y1 * s; y < y2 * s; y++) {
            for (int x = x1 * s; x < x2 * s; x++) {
                img.setRGB(x, y, img.getRGB(x, y) | 0xFF000000);
            }
        }
    }
}
