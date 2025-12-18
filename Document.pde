public class Document {
  CanvasSpec canvas = new CanvasSpec(1000, 800);
  ViewState view = new ViewState();
  PGraphics Canvas;
  LayerStack layers = new LayerStack();
  RenderFlags renderFlags = new RenderFlags();
  
  void markChanged(){
    renderFlags.dirtyComposite = true;
  }
  Document() {
    // start with an empty doc (no layers yet)
  }
}

class CanvasSpec {// Canvas Statement
  int w, h;
  CanvasSpec(int w, int h) {
    this.w = w;
    this.h = h;
  }
}