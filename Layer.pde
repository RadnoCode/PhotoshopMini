class Layer {
    PApplet app;
    final int ID;
    PImage img = null;
    boolean empty = true;
    boolean filterdirty = true;
    boolean thumbnailDirty = true;
    boolean maskThumbnailDirty = true;
    boolean maskdirty = true;
    
    
    float opacity = 1.0;
    boolean visible = true;
    String name = "Layer";
    String types;
    //int id;
    //Transform in CANVAS space
    float x = 0;            // translation
    float y = 0;
    float rotation = 0;     // radians
    float scale = 1.0;      // 
    float contrast = 1.0;
    float sharp = 0.0;
    float blur = 0.0;       // 模糊基准是 0.0，越大越模糊
    
    ArrayList<Filter> filters = new ArrayList<Filter>();
    //Pivot in LOCAL space (image space)
    float pivotX = 0;
    float pivotY = 0;
    
    PImage processedImg; 
    PImage mask;
    PImage out;
    PImage thumbnail;
    PImage maskThumbnail;
    
    static final int THUMB_W = 64;
    static final int THUMB_H = 64;
    void invalidateThumbnail() {
        thumbnailDirty = true;
    }
    void invalidateMaskThumbnail() {
        maskThumbnailDirty = true;
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
    PImage getMaskThumbnail() {
        if (img == null || empty) return null;
        ensureMaskSizeMatchesImage(false);
        if (mask == null) return null;
        if (!maskThumbnailDirty && !maskdirty && maskThumbnail != null) {
            return maskThumbnail;
        }
        maskThumbnail = generateMaskThumbnail();
        maskThumbnailDirty = false;
        return maskThumbnail;
    }
    PImage generateThumbnail(PImage source, int baseW, int baseH) {
        if (source == null || baseW <= 0 || baseH <= 0) return null;
        PGraphics pg = createGraphics(THUMB_W, THUMB_H);
        pg.beginDraw();
        pg.clear();
        float scale = min(
           (float)THUMB_W / baseW,
           (float)THUMB_H / baseH
           );
        
        float w = baseW * scale;
        float h = baseH * scale;
        float dx = (THUMB_W - w) / 2;
        float dy = (THUMB_H - h) / 2;
        
        pg.image(source, dx, dy, w, h);
        pg.endDraw();
        return pg.get();
    }
    PImage generateMaskThumbnail() {
        if (mask == null || img == null || empty) return null;
        
        mask.loadPixels();
        PImage alphaAsGray = createImage(mask.width, mask.height, ARGB);
        alphaAsGray.loadPixels();
        for (int i = 0; i < mask.pixels.length; i++) {
            int a = (mask.pixels[i] >>> 24) & 0xFF;
            alphaAsGray.pixels[i] = color(a, a, a, 255);
        }
        alphaAsGray.updatePixels();
        
        return generateThumbnail(alphaAsGray, img.width, img.height);
    }
    void ensureMaskSizeMatchesImage(boolean createIfMissing) {
        if (img == null || empty) return;
        if (mask == null && !createIfMissing) return;
        boolean changed = false;
        boolean needsRebuild =  (mask == null) ||
                                (mask.width != img.width) ||
                                (mask.height != img.height) ||
                                (mask.format != ARGB);

        if (needsRebuild) {
            PImage old = mask;
            mask = createImage(img.width, img.height, ARGB);
            mask.loadPixels();
            if (old != null && old.width == img.width && old.height == img.height) {
                old.loadPixels();
                for (int i = 0; i < mask.pixels.length; i++) {
                    int a = int(alpha(old.pixels[i])); // safely read alpha regardless of source format
                    mask.pixels[i] = (a << 24) | 0x00FFFFFF;
                }
            } else {
                for (int i = 0; i < mask.pixels.length; i++) {
                    mask.pixels[i] = 0xFFFFFFFF; // fully white/opaque mask by default
                }
            }
            mask.updatePixels();
            changed = true;
        }
        if (changed) {
            maskdirty = true;
            maskThumbnailDirty = true;
        }
    }
    void addMask() {
        ensureMaskSizeMatchesImage(true);
        maskdirty = true;
        maskThumbnailDirty = true;
    }
    Layer(PImage img,int id) {
        this.ID = id;
        this.img = img;
        this.empty = (img == null);
        if (img != null) {
            this.processedImg = img.get();
            this.out = img.get();
            this.img = this.processedImg;
            pivotX = img.width * 0.5;
            pivotY = img.height * 0.5;
            this.empty = false;
            invalidateThumbnail();
            // Mask is created lazily via addMask()
        }
        
    }
    PVector canvasToLocal(float cx, float cy) {
       // 平移到layer 原点
        float px = cx - x;
        float py = cy - y;
        
       // 围绕 pivot 反变换
        float ox = px - pivotX;
        float oy = py - pivotY;
        
       // 反旋转
        float cs = cos( - rotation);
        float sn = sin( - rotation);
        float rx = ox * cs - oy * sn;
        float ry = ox * sn + oy * cs;
        
       // 反缩放（防止除 0）
        float s = (abs(scale) < 1e0 - 6f) ? 1e0 - 6f : scale;
        rx /= s;
        ry /= s;
        
       // 平移回pivot
        return new PVector(rx + pivotX, ry + pivotY);
    }
        
    void ensureRasterForPaint(int w, int h) {
        if (img !=null && !empty) return;
        
        img = createImage(w, h, ARGB);
        img.loadPixels();
        for (int i= 0; i < img.pixels.length; i++) img.pixels[i] = 0x00000000; // 全透明
        img.updatePixels();
        
        processedImg = img.get();
        out = img.get();
        
        empty = false;
        types = "Raster";
        pivotX = w* 0.5f;
        pivotY = h* 0.5f;
        
        filterdirty = true;
        maskdirty = true;
        invalidateThumbnail();
    }



    //---------- Rendering helper ----------
    void applyTransform() {
        translate(x, y);
        translate(pivotX, pivotY);
        rotate(rotation);
        scale(scale);
        translate( -pivotX, -pivotY);
    }
    
    void applyMask(PImage processedImg, PImage mask) {
        if (processedImg == null) {
            maskdirty = false;
            return;
        }
        if (mask == null) {
            // 没有蒙版时直接把处理后的图拷贝到输出，保持画布可见
            out = processedImg.get();
            maskdirty = false;
            return;
        }
        ensureMaskSizeMatchesImage(true);
        
        // 尺寸保护：至少保证 out 尺寸正确
        if (out == null || out.width != processedImg.width || out.height != processedImg.height) {
            out = createImage(processedImg.width, processedImg.height, ARGB);
        }
        if (mask.width != processedImg.width || mask.height != processedImg.height) {
            // 最简单：直接不做，避免错位/越界
            return;
        }
        
        processedImg.loadPixels();
        mask.loadPixels();
        out.loadPixels();
        
        int n = out.pixels.length;
        for (int i = 0; i < n; i++) {
            int c = processedImg.pixels[i];
            
            int srcA = (c >>> 24) & 0xFF;                 
            int mA  = (mask.pixels[i] >>> 24) & 0xFF;    
            
            int newA = (srcA * mA + 127) / 255;          
            
            out.pixels[i] = (c & 0x00FFFFFF) | (newA << 24);
        }
        
        out.updatePixels();
        maskdirty = false;
    }
    
    void drawSelf(Document doc) {
        if (img == null) return;
        if (out == null) {
            out = img.get();
        }
        if (filterdirty &&  img!= null) {
            applyFilters();
        }
        if (maskdirty &&  img!= null) {
            applyMask(processedImg,mask);
            maskdirty = false;
        }
        doc.canvas.tint(255, 255 * opacity);
        doc.canvas.image(out, -pivotX, -pivotY);
        doc.canvas.noTint();
    }
    void applyFilters() {
        processedImg = img.get();
        for (int i = 0;i < filters.size();i++) {
            Filter f = filters.get(i);
            // Ensure commands know which layer owns this filter.
            f.layer = this;
            f.apply(this);
        }
        filterdirty = false;
        maskdirty = true;
        maskThumbnailDirty = true;
    }
    //- --------- Geometry helpers ----------
    // Pivot position in CANVAS space
    PVector pivotCanvas() {
        return new PVector(x + pivotX, y + pivotY);
    }
    String toString() {
        return name;
    } 
}

class TextLayer extends Layer{
    String text = "Text";
    String fontName = "Arial";
    int fontSize = 32;
    int fillCol = color(255,0,0);   // colcor
    
    PFont fontCache = null;
    boolean metricsDirty = true;
    
    TextLayer(String text,String fontName,int fontSize,int id) {
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
        
        pivotX = w * 0.5;
        pivotY = h * 0.5;
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
        float scale = min((float)THUMB_W / textW,(float)THUMB_H / textH);
        
        pg.pushMatrix();
        float dx = (THUMB_W - textW * scale) * 0.5;
        float dy = (THUMB_H - textH * scale) * 0.5 + pg.textAscent() * scale;
        pg.translate(dx, dy);
        pg.scale(scale);
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
        
        float baseA = alpha(fillCol);
        int a = int(baseA * opacity);
        int c = color(red(fillCol), green(fillCol), blue(fillCol), a);
        
        // Draw text directly onto the document canvas
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
        return list.get(activeIndex);//返回下标为activeIndex的那一个
    }
    int indexOf(Layer l) { return list.indexOf(l); }
    
    int indexOfId(int id) {
        for (int i = 0; i < list.size(); i++) if (list.get(i).ID == id) return i;
        return - 1;
    }
    
    
    void insertAt(int idx, Layer l) {
        idx = constrain(idx, 0, list.size());
        
        list.add(idx, l);
        // activeIndex 维护：如果插在 active 前面，activeIndex 后移
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
        // end is an insertion index in the original list, so allow "size" to mean
        // append to the end.
        end = constrain(end, 0, size);
        Layer l = list.remove(start);
        // After removal, indices shift left for elements after "start".If the
        // target was after the source, shift it back by one so the element lands
        // where the user dropped it.
        end = constrain(end, 0, list.size());
        list.add(end, l);
        
        // activeIndex 维护（常见坑！）
        if (activeIndex == start) activeIndex = end;
        else if (start < activeIndex && activeIndex <= end) activeIndex--;
        else if (start > activeIndex && activeIndex >= end) activeIndex++;
    }
    void rename(Layer tar,String s) {
        if (tar ==  null) return;
        tar.name = s;
    }
    
    
}
