class Layer {
    PApplet app;
    final int ID;
    PImage img = null;
    boolean empty = true;
    boolean filterdirty = true;
    boolean thumbnailDirty = true;

    float opacity = 1.0;
    boolean visible = true;
    String name = "Layer";
    String types;

    // Transform in CANVAS space
    float x = 0;
    float y = 0;
    float rotation = 0;
    float scale = 1.0;
    float contrast = 1.0;
    float sharp = 0.0;
    float blur = 0.0;

    ArrayList<Filter> filters = new ArrayList<Filter>();
    // Pivot in LOCAL space (image space)
    float pivotX = 0;
    float pivotY = 0;

    PImage processedImg;
    PImage thumbnail;

    static final int THUMB_W = 64;
    static final int THUMB_H = 64;

    Layer(PImage img, int id) {
        this.ID = id;
        this.img = img;
        this.empty = (img == null);
        if (img != null) {
            this.processedImg = img.get();
            pivotX = img.width * 0.5f;
            pivotY = img.height * 0.5f;
            this.empty = false;
            invalidateThumbnail();
        }
    }

    void invalidateThumbnail() {
        thumbnailDirty = true;
    }

    PImage getThumbnail() {
        if (!thumbnailDirty && thumbnail != null) {
            return thumbnail;
        }
        PImage source = processedImg != null ? processedImg : img;
        thumbnail = generateThumbnail(source, source != null ? source.width : 0, source != null ? source.height : 0);
        thumbnailDirty = false;
        return thumbnail;
    }

    PImage generateThumbnail(PImage source, int baseW, int baseH) {
        if (source == null || baseW <= 0 || baseH <= 0) return null;
        PGraphics pg = createGraphics(THUMB_W, THUMB_H);
        pg.beginDraw();
        pg.clear();
        float s = min((float)THUMB_W / baseW, (float)THUMB_H / baseH);
        float w = baseW * s;
        float h = baseH * s;
        float dx = (THUMB_W - w) * 0.5f;
        float dy = (THUMB_H - h) * 0.5f;
        pg.image(source, dx, dy, w, h);
        pg.endDraw();
        return pg.get();
    }

    PVector canvasToLocal(float cx, float cy) {
        float px = cx - x;
        float py = cy - y;

        float ox = px - pivotX;
        float oy = py - pivotY;

        float cs = cos(-rotation);
        float sn = sin(-rotation);
        float rx = ox * cs - oy * sn;
        float ry = ox * sn + oy * cs;

        float s = (abs(scale) < 1e-6f) ? 1e-6f : scale;
        rx /= s;
        ry /= s;

        return new PVector(rx + pivotX, ry + pivotY);
    }

    void ensureRasterForPaint(int w, int h) {
        if (img != null && !empty) return;

        img = createImage(w, h, ARGB);
        img.loadPixels();
        for (int i = 0; i < img.pixels.length; i++) img.pixels[i] = 0x00000000;
        img.updatePixels();

        processedImg = img.get();

        empty = false;
        types = "Raster";
        pivotX = w * 0.5f;
        pivotY = h * 0.5f;

        filterdirty = true;
        invalidateThumbnail();
    }

    // ---------- Rendering helper ----------
    void applyTransform() {
        translate(x, y);
        translate(pivotX, pivotY);
        rotate(rotation);
        scale(scale);
        translate(-pivotX, -pivotY);
    }

    void drawSelf(Document doc) {
        if (img == null) return;
        if (processedImg == null) {
            processedImg = img.get();
        }
        if (filterdirty && img != null) {
            applyFilters();
        }
        doc.canvas.tint(255, 255 * opacity);
        doc.canvas.image(processedImg, -pivotX, -pivotY);
        doc.canvas.noTint();
    }

    void applyFilters() {
        processedImg = img.get();
        for (int i = 0; i < filters.size(); i++) {
            Filter f = filters.get(i);
            f.layer = this;
            f.apply(this);
        }
        filterdirty = false;
        invalidateThumbnail();
    }

    // ---------- Geometry helpers ----------
    PVector pivotCanvas() {
        return new PVector(x + pivotX, y + pivotY);
    }

    String toString() {
        return name;
    }
}

class TextLayer extends Layer {
    String text = "Text";
    String fontName = "Arial";
    int fontSize = 32;
    int fillCol = color(255, 0, 0);

    PFont fontCache = null;
    boolean metricsDirty = true;

    TextLayer(String text, String fontName, int fontSize, int id) {
        super(null, id);
        this.text = text;
        this.fontName = fontName;
        this.fontSize = fontSize;
        this.name = "Text " + ID;
        this.types = "Text";
    }

    void ensureFont() {
        if (fontCache == null) {
            fontCache = createFont(fontName, fontSize, true);
        }
    }

    void updateMetricsIfNeeded() {
        if (!metricsDirty) return;
        ensureFont();
        textFont(fontCache);
        textSize(fontSize);

        float w = max(1, textWidth(text));
        float h = max(1, textAscent() + textDescent());

        pivotX = w * 0.5f;
        pivotY = h * 0.5f;
        metricsDirty = false;
    }

    PImage generateThumbnail() {
        PGraphics pg = createGraphics(THUMB_W, THUMB_H);
        pg.beginDraw();
        pg.clear();

        ensureFont();
        updateMetricsIfNeeded();
        pg.textFont(fontCache);
        pg.textSize(fontSize);

        float textW = max(1, pg.textWidth(text));
        float textH = max(1, pg.textAscent() + pg.textDescent());
        float s = min((float)THUMB_W / textW, (float)THUMB_H / textH);

        pg.pushMatrix();
        float dx = (THUMB_W - textW * s) * 0.5f;
        float dy = (THUMB_H - textH * s) * 0.5f + pg.textAscent() * s;
        pg.translate(dx, dy);
        pg.scale(s);
        int a = int(alpha(fillCol) * opacity);
        int c = color(red(fillCol), green(fillCol), blue(fillCol), a);
        pg.fill(c);
        pg.textAlign(LEFT, BASELINE);
        pg.text(text, 0, 0);
        pg.popMatrix();

        pg.endDraw();
        return pg.get();
    }

    void drawSelf(Document doc) {
        ensureFont();
        updateMetricsIfNeeded();

        int a = int(alpha(fillCol) * opacity);
        int c = color(red(fillCol), green(fillCol), blue(fillCol), a);

        doc.canvas.textFont(fontCache);
        doc.canvas.textSize(fontSize);
        doc.canvas.textAlign(LEFT, TOP);
        doc.canvas.fill(c);
        doc.canvas.text(text, -pivotX, -pivotY);
    }

    void setText(String s) { text = s; metricsDirty = true; invalidateThumbnail(); }
    void setFontSize(int s) { fontSize = max(1, s); fontCache = null; metricsDirty = true; invalidateThumbnail(); }
    void setFontName(String s) { fontName = s; fontCache = null; metricsDirty = true; invalidateThumbnail(); }
    void setFillCol(int c) { fillCol = c; invalidateThumbnail(); }
}

class LayerStack {
    int NEXT_ID = 1;
    ArrayList<Layer> list = new ArrayList<Layer>();
    int activeIndex = -1;

    int getid() {
        return NEXT_ID++;
    }

    Layer getActive() {
        if (activeIndex < 0 || activeIndex >= list.size()) return null;
        return list.get(activeIndex);
    }

    int indexOf(Layer l) { return list.indexOf(l); }

    int indexOfId(int id) {
        for (int i = 0; i < list.size(); i++) if (list.get(i).ID == id) return i;
        return -1;
    }

    void insertAt(int idx, Layer l) {
        idx = constrain(idx, 0, list.size());
        list.add(idx, l);
        if (activeIndex >= idx) activeIndex++;
        if (activeIndex < 0) activeIndex = 0;
    }

    Layer removeAt(int idx) {
        if (idx < 0 || idx >= list.size()) return null;
        Layer removed = list.remove(idx);
        if (list.size() == 0) activeIndex = -1;
        else if (activeIndex > idx) activeIndex--;
        else if (activeIndex == idx) activeIndex = min(idx, list.size() - 1);
        return removed;
    }

    void move(int start, int end) {
        if (start == end) return;
        if (start < 0 || start >= list.size()) return;

        int size = list.size();
        end = constrain(end, 0, size);
        Layer l = list.remove(start);
        end = constrain(end, 0, list.size());
        list.add(end, l);

        if (activeIndex == start) activeIndex = end;
        else if (start < activeIndex && activeIndex <= end) activeIndex--;
        else if (start > activeIndex && activeIndex >= end) activeIndex++;
    }

    void rename(Layer tar, String s) {
        if (tar == null) return;
        tar.name = s;
    }
}
