public class Document {
  PGraphics canvas;
  PGraphics checkerCache;
  int checkerTileSize = 50;
  ViewState view = new ViewState();
  LayerStack layers = new LayerStack();
  RenderFlags renderFlags = new RenderFlags();
  int viewX, viewY, viewH, viewW;// be used to crop

  void markChanged() {
    renderFlags.dirtyComposite = true;
  }

  Document() {
    this(2000, 2000);
  }

  Document(int width, int height) {
    resizeCanvas(width, height);
  }

  void resizeCanvas(int width, int height) {
    canvas = createGraphics(width, height);
    viewW = canvas.width;
    viewH = canvas.height;
    viewX = 0;
    viewY = 0;
    buildChecker(checkerTileSize);
  }

  void buildChecker(int tileSize) {
    checkerTileSize = max(1, tileSize);
    checkerCache = createGraphics(canvas.width, canvas.height);
    checkerCache.beginDraw();
    checkerCache.noStroke();
    for (int y = 0; y < checkerCache.height; y += checkerTileSize) {
      int tileH = min(tileSize, checkerCache.height - y);
      for (int x = 0; x < checkerCache.width; x += checkerTileSize) {
        int tileW = min(tileSize, checkerCache.width - x);
        int v = (((x / tileSize) + (y / tileSize)) % 2 == 0) ? 60 : 80;
        checkerCache.fill(v);
        checkerCache.rect(x, y, tileW, tileH);
      }
    }
    checkerCache.endDraw();
  }
}

class CanvasSpec { // Canvas Statement
  int width, height;
  CanvasSpec(int w, int h) {
    this.width = w;
    this.height = h;
  }
}
