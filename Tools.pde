// Tools.pde
interface Tool {
  void mousePressed(Document doc, int mx, int my, int btn);
  void mouseDragged(Document doc, int mx, int my, int btn);
  void mouseReleased(Document doc, int mx, int my, int btn);
  void mouseWheel(Document doc, float delta);
  void drawOverlay(Document doc);
  String name();
}

class ToolManager {
  Tool active = null;

  void setTool(Tool t) {
    active = t;
  }

  void mousePressed(Document doc, int mx, int my, int btn) {
    if (active != null) active.mousePressed(doc, mx, my, btn);
  }
  void mouseDragged(Document doc, int mx, int my, int btn) {
    if (active != null) active.mouseDragged(doc, mx, my, btn);
  }
  void mouseReleased(Document doc, int mx, int my, int btn) {
    if (active != null) active.mouseReleased(doc, mx, my, btn);
  }
  void mouseWheel(Document doc, float delta) {
    if (active != null) active.mouseWheel(doc, delta);
  }
  void drawOverlay(Document doc) {
    if (active != null) active.drawOverlay(doc);
  }

  String activeName() {
    return (active == null) ? "None" : active.name();
  }
}

// Rotate tool
class RotateTool implements Tool{
  CommandManager history;
  boolean dragging = false;
  Layer target;

  float startAngle, startRotation;
  PVector pivotCanvas;

  RotateTool(CommandManager history) {
    this.history = history;
  }

  public void mousePressed(Document doc, int mx, int my, int btn){
    if (btn != LEFT) return;
    dragging = true;
    target = doc.layers.getActive();
    if (target == null) return;
    pivotCanvas = target.pivotCanvas();
    float px = doc.view.canvasToScreenX(pivotCanvas.x);
    float py = doc.view.canvasToScreenY(pivotCanvas.y); // use canvasToScreenY
    startAngle = atan2(my - py, mx - px);
    startRotation = target.rotation;
  }

  public void mouseDragged(Document doc, int mx, int my, int btn){
    if (!dragging || target == null) return;
    float px = doc.view.canvasToScreenX(pivotCanvas.x);
    float py = doc.view.canvasToScreenY(pivotCanvas.y);
    float a = atan2(my - py, mx - px);
    target.rotation = startRotation + (a - startAngle);
  }

  public void mouseReleased(Document doc, int mx, int my, int btn) {
    if (!dragging || target == null) return;
    dragging = false;
    if (history != null) {
      history.perform(doc, new RotateCommand(target, startRotation, target.rotation));
    }
  }

  public void mouseWheel(Document doc, float delta){
    doc.view.zoomAroundMouse(delta);
  }
  void drawOverlay(Document doc){
    // optional: draw rotation handles
  }
  String name() { return "Rotate"; }
}

// Move tool
class MoveTool implements Tool {
  boolean dragging = false;
  int lastX, lastY;

  public void mousePressed(Document doc, int mx, int my, int btn) {
    if (btn != LEFT) return;
    dragging = true;
    lastX = mx;
    lastY = my;
  }

  public void mouseDragged(Document doc, int mx, int my, int btn) {
    if (!dragging) return;
    doc.view.panX += (mx - lastX);
    doc.view.panY += (my - lastY);
    lastX = mx;
    lastY = my;
  }

  public void mouseReleased(Document doc, int mx, int my, int btn) {
    dragging = false;
  }

  public void mouseWheel(Document doc, float delta) {
    doc.view.zoomAroundMouse(delta);
  }

  public void drawOverlay(Document doc) {}
  public String name() { return "Move"; }
}

// Crop tool
class CropTool implements Tool {
  CommandManager history;

  boolean dragging = false;
  float startX, startY, endX, endY;

  CropTool(CommandManager history) {
    this.history = history;
  }

  public void mousePressed(Document doc, int mx, int my, int btn) {
    if (btn != LEFT) return;
    if (doc.layers.getActive() == null || doc.layers.getActive().img == null) return;

    dragging = true;
    startX = doc.view.screenToCanvasX(mx);
    startY = doc.view.screenToCanvasY(my);
    endX = startX;
    endY = startY;
  }

  public void mouseDragged(Document doc, int mx, int my, int btn) {
    if (!dragging) return;
    endX = doc.view.screenToCanvasX(mx);
    endY = doc.view.screenToCanvasY(my);
  }

  public void mouseReleased(Document doc, int mx, int my, int btn) {
    if (!dragging) return;
    dragging = false;

    endX = doc.view.screenToCanvasX(mx);
    endY = doc.view.screenToCanvasY(my);

    IntRect r = buildClampedRect(doc, startX, startY, endX, endY);
    if (r == null || r.w < 2 || r.h < 2) return;

    if (history != null) {
      history.perform(doc, new CropCommand(r));
    }
  }

  public void mouseWheel(Document doc, float delta) {
    doc.view.zoomAroundMouse(delta);
  }

  public void drawOverlay(Document doc) {
    if (!dragging) return;

    float x1 = min(startX, endX), y1 = min(startY, endY);
    float x2 = max(startX, endX), y2 = max(startY, endY);

    noStroke();
    fill(0, 120);
    rect(0, 0, doc.canvas.w, y1);
    rect(0, y2, doc.canvas.w, doc.canvas.h - y2);
    rect(0, y1, x1, y2 - y1);
    rect(x2, y1, doc.canvas.w - x2, y2 - y1);

    noFill();
    stroke(255);
    rect(x1, y1, x2 - x1, y2 - y1);

    stroke(255, 120);
    float w = x2 - x1, h = y2 - y1;
    line(x1 + w/3, y1, x1 + w/3, y2);
    line(x1 + 2*w/3, y1, x1 + 2*w/3, y2);
    line(x1, y1 + h/3, x2, y1 + h/3);
    line(x1, y1 + 2*h/3, x2, y1 + 2*h/3);
  }

  public String name() { return "Crop"; }

  IntRect buildClampedRect(Document doc, float ax, float ay, float bx, float by) {
    int x1 = floor(min(ax, bx));
    int y1 = floor(min(ay, by));
    int x2 = ceil(max(ax, bx));
    int y2 = ceil(max(ay, by));

    x1 = constrain(x1, 0, doc.canvas.w);
    y1 = constrain(y1, 0, doc.canvas.h);
    x2 = constrain(x2, 0, doc.canvas.w);
    y2 = constrain(y2, 0, doc.canvas.h);

    int w = x2 - x1;
    int h = y2 - y1;
    if (w <= 0 || h <= 0) return null;
    return new IntRect(x1, y1, w, h);
  }
}
