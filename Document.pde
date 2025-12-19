public class Document {
  PGraphics canvas = createGraphics(2000, 2000);
  ViewState view = new ViewState();
  LayerStack layers = new LayerStack();
  RenderFlags renderFlags = new RenderFlags();
  int viewX,viewY,viewH,viewW;
  
  
  void markChanged(){
    renderFlags.dirtyComposite = true;
  }
  Document() {
    viewW=canvas.width;
    viewH=canvas.height;
    viewX=0;
    viewY=0;
  }
}

class CanvasSpec {// Canvas Statement
  int width, height;
  CanvasSpec(int w, int h) {
    this.width = w;
    this.height = h;
  }
}