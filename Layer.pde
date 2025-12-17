class Layer {
  PImage img = null;
  float opacity = 1.0;
  boolean visible = true;
  String name = "Layer";
  //int id;
  // Transform in CANVAS space
  float x = 0;            // translation
  float y = 0;
  float rotation = 0;     // radians
  float scale = 1.0;      // 

  //Other properties
  float blur,sharp;// need to be initialize

  // Pivot in LOCAL space (image space)
  float pivotX = 0;
  float pivotY = 0;

  Layer(PImage img) {
    this.img = img;
    if (img != null) {
      pivotX = img.width * 0.5;
      pivotY = img.height * 0.5;
    }
  }

  // ---------- Rendering helper ----------
  // Call inside CANVAS space (after doc.view.applyTransform()).
  void applyTransform() {
    translate(x, y);
    translate(pivotX, pivotY);
    rotate(rotation);
    scale(scale);
    translate(-pivotX, -pivotY);
  }

  // ---------- Geometry helpers ----------
  // Pivot position in CANVAS space
  PVector pivotCanvas() {
    return new PVector(x + pivotX, y + pivotY);
  }


}

class LayerStack {
  ArrayList<Layer> list = new ArrayList<Layer>();
  int activeIndex = -1;

  Layer getActive() {
    if (activeIndex < 0 || activeIndex >= list.size()) return null;
    return list.get(activeIndex);//返回下标为activeIndex的那一个
  }
  int indexOf(Layer l) { return list.indexOf(l); }
  
  void insertAt(int idx, Layer l){
    idx = constrain(idx, 0, list.size());

    list.add(idx, l);
    // activeIndex 维护：如果插在 active 前面，activeIndex 后移
    if (activeIndex >= idx) activeIndex++;
    if (activeIndex < 0) activeIndex = 0;
  }

  Layer removeAt(int idx){
    if (idx < 0 || idx >= list.size()) return null;
    Layer removed = list.remove(idx);
    if (list.size() == 0) activeIndex = -1;
    else if (activeIndex > idx) activeIndex--;
    else if (activeIndex == idx) activeIndex = min(idx, list.size()-1);
    return removed;
  }

  void move(int start, int end){
    if (start == end) return;
    if (start < 0 || start >= list.size()) return;
    end = constrain(end, 0, list.size()-1);

    Layer l = list.remove(start);
    list.add(end, l);

    // activeIndex 维护（常见坑！）
    if (activeIndex == start) activeIndex = end;
    else if (start < activeIndex && end >= activeIndex) activeIndex--;
    else if (start > activeIndex && end <= activeIndex) activeIndex++;
  }
  void renane(Layer tar,String s){
    if(tar==null) return;
    tar.name = s;
  }

  void setSingleLayer(Layer layer) {
    list.clear();
    list.add(layer);
    activeIndex = 0;
  }
}