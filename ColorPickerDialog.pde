import java.awt.*;
import java.awt.event.*;
import java.awt.image.BufferedImage;
import java.util.function.IntConsumer;
import javax.swing.*;
import javax.swing.border.EmptyBorder;

  // ----------------------------
  // functional tiny interfaces
  // ----------------------------
interface FloatSupplier { float getAsFloat(); }
interface IntSupplier { int getAsInt(); }

interface HueListener { void onHue(float hue, boolean dragging); }
interface SVListener { void onSV(float sat, float val, boolean dragging); }


class ColorPickerDialog extends JDialog {
  // creat HSV color system
  private float hue;        // 0..360
  private float sat;        // 0..1
  private float val;        // 0..1
  private int alpha;        // 0..255

    private final int initialARGB;

    private final IntConsumer onPreview;
    private final IntConsumer onCommit;

    private final PreviewSwatch previewSwatch;
    private final HueBar hueBar;
    private final SVSquare svSquare;

    private boolean adjusting = false; //avoid echoing 

    public ColorPickerDialog(Window owner, int initialColARGB, IntConsumer onPreview, IntConsumer onCommit) {
        super(owner, "Pick text color", ModalityType.APPLICATION_MODAL);
        this.initialARGB = initialColARGB;
        this.onPreview = onPreview;
        this.onCommit = onCommit;

        float[] hsv = rgbToHsv(argbToRgb(initialColARGB));
        hue = hsv[0];
        sat = hsv[1];
        val = hsv[2];
        alpha = (initialColARGB >>> 24) & 0xFF;

        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        setResizable(false);

        JPanel root = new JPanel(new BorderLayout(10, 10));
        root.setBorder(new EmptyBorder(12, 12, 12, 12));
        root.setBackground(new Color(45, 45, 45));

        JPanel center = new JPanel();
        center.setOpaque(false);
        center.setLayout(new BoxLayout(center, BoxLayout.X_AXIS));

        svSquare = new SVSquare(() -> hue, () -> sat, () -> val, (s, v, isDragging) -> {
            sat = clamp01(s);
            val = clamp01(v);
            firePreview();
            if (!isDragging) {}
        });

        hueBar = new HueBar(() -> hue, (h, isDragging) -> {
            hue = (float)((h % 360 + 360) % 360);
            svSquare.invalidateCache(); // use cache to avoid repeatting generation
            firePreview();
            if (!isDragging) { }
        });

        center.add(svSquare);
        center.add(Box.createHorizontalStrut(10));
        center.add(hueBar);

        JPanel right = new JPanel();
        right.setOpaque(false);
        right.setLayout(new BoxLayout(right, BoxLayout.Y_AXIS));

        previewSwatch = new PreviewSwatch(() -> initialARGB, this::getCurrentARGB);
        right.add(previewSwatch);
        right.add(Box.createVerticalStrut(10));

        JButton ok = makeButton("OK");
        JButton cancel = makeButton("Cancel");

        ok.addActionListener(e -> {
            if (onCommit != null) onCommit.accept(getCurrentARGB());
            dispose();
        });
        cancel.addActionListener(e -> dispose());

        JPanel btnRow = new JPanel(new GridLayout(1, 2, 8, 0));
        btnRow.setOpaque(false);
        btnRow.add(cancel);
        btnRow.add(ok);
        right.add(btnRow);

        root.add(center, BorderLayout.CENTER);
        root.add(right, BorderLayout.EAST);

        setContentPane(root);
        pack();
        setLocationRelativeTo(owner);

        firePreview();
    }

    private JButton makeButton(String text) {
        JButton b = new JButton(text);
        b.setFocusPainted(false);
        b.setBackground(new Color(70, 70, 70));
        b.setForeground(new Color(235, 235, 235));
        b.setBorder(BorderFactory.createEmptyBorder(8, 14, 8, 14));
        return b;
    }

    private int getCurrentARGB() {
        int rgb = hsvToRgb(hue, sat, val);
        int r = (rgb >> 16) & 0xFF;
        int g = (rgb >> 8) & 0xFF;
        int b = (rgb) & 0xFF;
        return ((alpha & 0xFF) << 24) | (r << 16) | (g << 8) | b;
    }

    private void firePreview() {
        if (adjusting) return;
        adjusting = true;
        int col = getCurrentARGB();
        previewSwatch.repaint();
        svSquare.repaint();
        hueBar.repaint();
        if (onPreview != null) onPreview.accept(col);
        adjusting = false;
    }

    // ----------------------------
    // Hue
    // ----------------------------
    class HueBar extends JComponent {
        private final FloatSupplier getHue;
        private final HueListener listener;

        private BufferedImage cache;
        private int cacheW = -1, cacheH = -1;

        HueBar(FloatSupplier getHue, HueListener listener) {
            this.getHue = getHue;
            this.listener = listener;
            setPreferredSize(new Dimension(18, 220));

            MouseAdapter ma = new MouseAdapter() {
                boolean dragging = false;

                @Override public void mousePressed(java.awt.event.MouseEvent e) {
                    dragging = true;
                    updateFromMouse(e.getY(), true);
                }

                @Override public void mouseDragged(java.awt.event.MouseEvent e) {
                    if (!dragging) return;
                    updateFromMouse(e.getY(), true);
                }

                @Override public void mouseReleased(java.awt.event.MouseEvent e) {
                    if (!dragging) return;
                    updateFromMouse(e.getY(), false);
                    dragging = false;
                }
            };
            addMouseListener(ma);
            addMouseMotionListener(ma);
        }

        private void updateFromMouse(int my, boolean dragging) {
            int h = getHeight();
            float t = clamp01(my / (float)(h - 1));
            float hue = (1f - t) * 360f; 
            if (listener != null) listener.onHue(hue, dragging);
        }

        @Override protected void paintComponent(Graphics g) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            int w = getWidth();
            int h = getHeight();

            if (cache == null || cacheW != w || cacheH != h) {
            cacheW = w; cacheH = h;
            cache = new BufferedImage(w, h, BufferedImage.TYPE_INT_ARGB);
            for (int y = 0; y < h; y++) {
                    float t = y / (float)(h - 1);
                float hue = (1f - t) * 360f;
                int rgb = hsvToRgb(hue, 1f, 1f);
                int argb = 0xFF000000 | rgb;
                for (int x = 0; x < w; x++) cache.setRGB(x, y, argb);
            }
            }

            g2.drawImage(cache, 0, 0, null);

            float hue = getHue.getAsFloat();
            float t = 1f - (hue / 360f);
            int y = (int)(t * (h - 1));
            g2.setColor(new Color(255, 255, 255, 220));
            g2.drawRoundRect(0, 0, w - 1, h - 1, 8, 8);

            g2.setColor(new Color(0, 0, 0, 160));
            g2.drawLine(0, y, w - 1, y);
            g2.setColor(new Color(255, 255, 255, 220));
            g2.drawLine(0, y + 1, w - 1, y + 1);

            g2.dispose();
            }
    }

    // ----------------------------
    // Squre of SV
    // ----------------------------
    class SVSquare extends JComponent {
        private final FloatSupplier getHue, getSat, getVal;
        private final SVListener listener;

        private BufferedImage cache;
        private int cacheW = -1, cacheH = -1;
        private float cacheHue = -999f;

        SVSquare(FloatSupplier getHue, FloatSupplier getSat, FloatSupplier getVal, SVListener listener) {
            this.getHue = getHue;
            this.getSat = getSat;
            this.getVal = getVal;
            this.listener = listener;
            setPreferredSize(new Dimension(220, 220));

        MouseAdapter ma = new MouseAdapter() {
            boolean dragging = false;
            @Override public void mousePressed(java.awt.event.MouseEvent e) {
                dragging = true;
                updateFromMouse(e.getX(), e.getY(), true);
            }

            @Override public void mouseDragged(java.awt.event.MouseEvent e) {
                if (!dragging) return;
                updateFromMouse(e.getX(), e.getY(), true);
            }

            @Override public void mouseReleased(java.awt.event.MouseEvent e) {
                if (!dragging) return;
                updateFromMouse(e.getX(), e.getY(), false);
                dragging = false;
            }
        };
            addMouseListener(ma);
            addMouseMotionListener(ma);
        }

        void invalidateCache() {
            cacheHue = -999f;
            repaint();
        }

        private void updateFromMouse(int mx, int my, boolean dragging) {
            int w = getWidth();
            int h = getHeight();
            float s = clamp01(mx / (float)(w - 1));
            float v = clamp01(1f - (my / (float)(h - 1)));
            if (listener != null) listener.onSV(s, v, dragging);
        }

        @Override protected void paintComponent(Graphics g) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            int w = getWidth();
            int h = getHeight();
            float hue = getHue.getAsFloat();

            if (cache == null || cacheW != w || cacheH != h || Math.abs(cacheHue - hue) > 0.0001f) {
                cacheW = w; cacheH = h; cacheHue = hue;
                cache = new BufferedImage(w, h, BufferedImage.TYPE_INT_ARGB);

                for (int y = 0; y < h; y++) {
                float v = 1f - (y / (float)(h - 1));
                for (int x = 0; x < w; x++) {
                    float s = x / (float)(w - 1);
                    int rgb = hsvToRgb(hue, s, v);
                    cache.setRGB(x, y, 0xFF000000 | rgb);
                }
                }
            }

            g2.drawImage(cache, 0, 0, null);

            g2.setColor(new Color(255, 255, 255, 220));
            g2.drawRoundRect(0, 0, w - 1, h - 1, 10, 10);

            // ponit of mouse
            float s = getSat.getAsFloat();
            float v = getVal.getAsFloat();
            int cx = (int)(s * (w - 1));
            int cy = (int)((1f - v) * (h - 1));

            int r = 6;
            g2.setStroke(new BasicStroke(2f));
            g2.setColor(new Color(0, 0, 0, 160));
            g2.drawOval(cx - r - 1, cy - r - 1, (r + 1) * 2, (r + 1) * 2);
            g2.setColor(new Color(255, 255, 255, 230));
            g2.drawOval(cx - r, cy - r, r * 2, r * 2);

            g2.dispose();
        }
    }

    // ----------------------------
    // preview color
    // ----------------------------
    class PreviewSwatch extends JComponent {
        private final IntSupplier getOld;
        private final IntSupplier getNew;

        PreviewSwatch(IntSupplier getOld, IntSupplier getNew) {
            this.getOld = getOld;
            this.getNew = getNew;
            setPreferredSize(new Dimension(120, 80));
        }

        @Override protected void paintComponent(Graphics g) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            int w = getWidth();
            int h = getHeight();

            g2.setColor(new Color(255, 255, 255, 220));
            g2.drawRoundRect(0, 0, w - 1, h - 1, 12, 12);

            int pad = 8;
            int innerW = w - pad * 2;
            int innerH = h - pad * 2;

            int mid = innerW / 2;

            g2.setColor(new Color(getOld.getAsInt(), true));
            g2.fillRoundRect(pad, pad, mid - 2, innerH, 10, 10);

            g2.setColor(new Color(getNew.getAsInt(), true));
            g2.fillRoundRect(pad + mid + 2, pad, innerW - mid - 2, innerH, 10, 10);

            g2.setColor(new Color(0, 0, 0, 120));
            g2.drawLine(pad + mid, pad, pad + mid, pad + innerH);

            g2.dispose();
        }
    }

    // ----------------------------
    // change claor system between ARGB HSV
    // ----------------------------
    private  int[] argbToRgb(int argb) {
        return new int[] {
            (argb >> 16) & 0xFF,
            (argb >> 8) & 0xFF,
            (argb) & 0xFF
        };
    }

    private  float[] rgbToHsv(int[] rgb) {
        float r = rgb[0] / 255f, g = rgb[1] / 255f, b = rgb[2] / 255f;
        float max = Math.max(r, Math.max(g, b));
        float min = Math.min(r, Math.min(g, b));
        float d = max - min;

        float h;
        if (d == 0) h = 0;
        else if (max == r) h = 60f * (((g - b) / d) % 6f);
        else if (max == g) h = 60f * (((b - r) / d) + 2f);
        else h = 60f * (((r - g) / d) + 4f);
        if (h < 0) h += 360f;

        float s = (max == 0) ? 0 : (d / max);
        float v = max;

        return new float[] { h, s, v };
    }

    private  int hsvToRgb(float h, float s, float v) {
        h = (float)((h % 360 + 360) % 360);
        float c = v * s;
        float x = c * (1 - Math.abs(((h / 60f) % 2) - 1));
        float m = v - c;

        float rp=0, gp=0, bp=0;
        if (h < 60) { rp=c; gp=x; bp=0; }
        else if (h < 120) { rp=x; gp=c; bp=0; }
        else if (h < 180) { rp=0; gp=c; bp=x; }
        else if (h < 240) { rp=0; gp=x; bp=c; }
        else if (h < 300) { rp=x; gp=0; bp=c; }
        else { rp=c; gp=0; bp=x; }

        int r = clamp255((rp + m) * 255f);
        int g = clamp255((gp + m) * 255f);
        int b = clamp255((bp + m) * 255f);
        return (r << 16) | (g << 8) | b;
    }

    private  int clamp255(float v) {
        int i = Math.round(v);
        if (i < 0) return 0;
        if (i > 255) return 255;
        return i;
    }

    private  float clamp01(float v) {
        if (v < 0) return 0;
        if (v > 1) return 1;
        return v;
    }
}
