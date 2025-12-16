class Document {
  CanvasSpec canvas = new CanvasSpec(900, 600);
  ViewState view = new ViewState();

  LayerStack layers = new LayerStack();
  RenderFlags renderFlags = new RenderFlags();

  Document() {
    // start with an empty doc (no layers yet)
  }
}