class Layer {
    final int ID;
    PImage img = null;
    boolean empty = true;
    boolean dirty = true;
    
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
    
    PImage originalImg; // 保存未经调色的原图，防止反复处理导致画质损失
    PImage processedImg = null; // 实际绘制到画布上的图
    
    Layer(PImage img,int id) {
        this.ID = id;
        this.img = img;
        if (img != null) {
            this.originalImg = img.get();
            this.processedImg = img.get();
            this.img = this.processedImg; // 兼容原有代码
            pivotX= img.width * 0.5;
            pivotY= img.height * 0.5;
        }
}
    
    //---------- Rendering helper ----------
    //Call inside CANVAS space (after doc.view.applyTransform()).
    
    void applyTransform() {
        translate(x, y);
        translate(pivotX, pivotY);
        rotate(rotation);
        scale(scale);
        translate( - pivotX, -pivotY);
}
    void drawSelf(Document doc) {
        if (img == null) return;
        if (processedImg ==  null &&  img!= null) {
            processedImg = img.get();
        }
        if (dirty &&  img!= null) {
            applyFilters();
        }
        doc.canvas.tint(255, 255 * opacity);
        doc.canvas.image(processedImg, -pivotX, -pivotY);
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
}
    //---------- Geometry helpers ----------
    //Pivot position in CANVAS space
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
    int fillCol = color(255,0,0);      // colcor
    
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
    
    void setText(String s) { text = s; metricsDirty = true; }
    void setFontSize(int s) { fontSize = max(1, s); fontCache = null; metricsDirty = true; }
    void setFontName(String s) { fontName = s; fontCache = null; metricsDirty = true; }
    void setFillCol(int c) { fillCol = c; }
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
        // After removal, indices shift left for elements after "start". If the
        // target was after the source, shift it back by one so the element lands
        // where the user dropped it.
        end = constrain(end, 0, list.size());
        list.add(end, l);
        
        // activeIndex 维护（常见坑！）
        if (activeIndex == start) activeIndex = end;
        else if (start < activeIndex && activeIndex <= end) activeIndex--;
        else if (start > activeIndex && activeIndex >= end) activeIndex++;
}
    void renane(Layer tar,String s) {
        if (tar ==  null) return;
        tar.name = s;
}
    
    
}
