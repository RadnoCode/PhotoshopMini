class Layer {
  PImage img = null;
  float opacity = 1.0;
  boolean visible = true;
  String name = "Layer";
  String blendMode = "Normal";

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
    this(img, "Layer");
  }

  Layer(PImage img, String name) {
    this.img = img;
    if (name != null && name.length() > 0) {
      this.name = name;
    }
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
  int version = 0;

  boolean isEmpty() {
    return list.isEmpty();
  }

  int size() {
    return list.size();
  }

  Layer getActive() {
    if (activeIndex < 0 || activeIndex >= list.size()) return null;
    return list.get(activeIndex);//返回下标为activeIndex的那一个
  }

  Layer get(int idx) {
    if (idx < 0 || idx >= list.size()) return null;
    return list.get(idx);
  }

  void setActive(int idx) {
    if (idx < 0 || idx >= list.size()) return;
    if (idx == activeIndex) return;
    activeIndex = idx;
    version++;
  }

  void setSingleLayer(Layer layer) {
    list.clear();
    list.add(layer);
    activeIndex = 0;
    version++;
  }

  void addLayerOnTop(Layer layer) {
    if (layer == null) return;
    list.add(0, layer);
    activeIndex = 0;
    version++;
  }

  void toggleVisibility(int idx) {
    Layer l = get(idx);
    if (l == null) return;
    l.visible = !l.visible;
    version++;
  }

  void rename(int idx, String newName) {
    Layer l = get(idx);
    if (l == null || newName == null) return;
    String trimmed = newName.trim();
    if (trimmed.length() == 0) return;
    l.name = trimmed;
    version++;
  }

  void moveLayer(int from, int to) {
    if (from < 0 || from >= list.size() || to < 0 || to >= list.size()) return;
    if (from == to) return;
    Layer l = list.remove(from);
    list.add(to, l);
    if (activeIndex == from) {
      activeIndex = to;
    } else if (activeIndex > from && activeIndex <= to) {
      activeIndex--;
    } else if (activeIndex < from && activeIndex >= to) {
      activeIndex++;
    }
    version++;
  }
}