class Layer {
  PImage img = null;
  float opacity = 1.0;
  boolean visible = true;
  String name = "Layer";

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

  void setSingleLayer(Layer layer) {
    list.clear();
    list.add(layer);
    activeIndex = 0;
  }
}