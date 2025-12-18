public class Document {
  CanvasSpec canvas = new CanvasSpec(1000, 800);
  ViewState view = new ViewState();

  LayerStack layers = new LayerStack();
  RenderFlags renderFlags = new RenderFlags();
  
  void markChanged(){
    renderFlags.dirtyComposite = true;
  }
  Document() {
    // start with an empty doc (no layers yet)
  }
}