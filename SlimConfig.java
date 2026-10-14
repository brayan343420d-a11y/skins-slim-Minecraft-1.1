package net.minecraft.src;

import java.io.*;
import java.util.HashSet;
import java.util.Set;

/**
 * Lee slimskins.txt (en la carpeta .minecraft): un nombre de jugador por linea.
 * Los jugadores listados se dibujan con brazos slim.
 */
public class SlimConfig {

    private static Set<String> slimPlayers = null;

    public static synchronized boolean isSlim(String name) {
        if (slimPlayers == null) {
            load();
        }
        return name != null && slimPlayers.contains(name.toLowerCase());
    }

    private static void load() {
        slimPlayers = new HashSet<String>();
        File f = new File(Minecraft.getMinecraftDir(), "slimskins.txt");
        if (!f.exists()) {
            writeTemplate(f);
            return;
        }
        BufferedReader in = null;
        try {
            in = new BufferedReader(new FileReader(f));
            String line;
            while ((line = in.readLine()) != null) {
                line = line.trim();
                if (line.length() > 0 && !line.startsWith("#")) {
                    slimPlayers.add(line.toLowerCase());
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            try { if (in != null) in.close(); } catch (IOException e) { }
        }
    }

    private static void writeTemplate(File f) {
        PrintWriter out = null;
        try {
            out = new PrintWriter(new FileWriter(f));
            out.println("# Un nombre de jugador por linea (brazos slim).");
            out.println("# Ejemplo:");
            out.println("# MiNombre");
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (out != null) out.close();
        }
    }
}
