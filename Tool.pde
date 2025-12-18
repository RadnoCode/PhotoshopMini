// =======================================================
// 4) ToolstartYstem: continuous interaction + overlay
// =======================================================
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

// ---------- Move tool (view-only change, not a command) ----------
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

  public void drawOverlay(Document doc) {
  }
  public String name() {
    return "Move";
  }
}

// Rotate Tool
class RotateTool implements Tool{
  
  CommandManager history;
  boolean dragging = false;
  Layer target;

  float startAngle,startRotation;
  PVector pivotCanvas;
  
  RotateTool(CommandManager history) {
    this.history = history;
  }

  public void mousePressed(Document doc, int mx, int my, int btn){
    if(btn!=LEFT) return;
    dragging = true;
    target=doc.layers.getActive();
    pivotCanvas=target.pivotCanvas();
    float px=doc.view.canvasToScreenX(pivotCanvas.x);
    float py=doc.view.canvasToScreenX(pivotCanvas.y);
    startAngle= atan2(my-py,mx-px);
    startRotation=target.rotation;

  }
  public void mouseDragged(Document doc, int mx, int my, int btn){
    if(!dragging||target==null) return;
    float px = doc.view.canvasToScreenX(pivotCanvas.x);
    float py = doc.view.canvasToScreenY(pivotCanvas.y);
    float a = atan2(my-py, mx-px);
    target.rotation = startRotation + (a - startAngle);
  }
  public void mouseReleased(Document doc, int mx, int my, int btn) {
    if(!dragging||target==null) return;
    dragging = false;

    history.perform(doc,new RotateCommand(target,startRotation,target.rotation));
  }
  public void mouseWheel(Document doc, float delta){
    doc.view.zoomAroundMouse(delta);
  }
  void drawOverlay(Document doc){
    if(pivotCanvas==null) return;
  }
  String name() {return "Rotate";}
}

class ScaleTool implements Tool{
  boolean dragging=false;
  Layer target;
  CommandManager history ;
  float startX,startY,endX,endY;
  PVector pivotCanvas;
  float scaleDelta;                                        
  ScaleTool(CommandManager history){
    this.history =history;
  }

  void mousePressed(Document doc, int mx, int my, int btn){
    if(btn!=LEFT) return;
    dragging = true;
    target=doc.layers.getActive();
    pivotCanvas=target.pivotCanvas();
    startX=doc.view.screenToCanvasX(mouseX);
    startY=doc.view.screenToCanvasY(mouseY);
    scaleDelta=target.scale;
  }

  void mouseDragged(Document doc, int mx, int my, int btn){
    if(!dragging) return;
    endX=doc.view.screenToCanvasX(mouseX);
    float ratio=(endX-pivotCanvas.x)/(startX-pivotCanvas.x);
    scaleDelta=ratio;
    target.scale=scaleDelta;
  }
  void mouseReleased(Document doc, int mx, int my, int btn){
    dragging=false;
    history.perform(doc,new ScaleCommand(target,target.scale,scaleDelta));
  }
  void mouseWheel(Document doc, float delta){
    return;
  }
  void drawOverlay(Document doc){
    return;
  }
  String name() {return "Scale";}
}

// ---------- Crop tool (creates a CropCommand on release) ----------
class CropTool implements Tool {
  CommandManager history;

  boolean dragging = false;

  float startX, startY, endX, endY; // in canvas coords

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

    history.perform(doc, new CropCommand(r));
  }

  public void mouseWheel(Document doc, float delta) {
    doc.view.zoomAroundMouse(delta);
  }

  public void drawOverlay(Document doc) {
    if (!dragging) return;

    float x1 = min(startX, endX), y1 = min(startY, endY);
    float x2 = max(startX, endX), y2 = max(startY, endY);

    // dim outside crop area
    noStroke();
    fill(0, 120);
    rect(0, 0, doc.canvas.width, y1);
    rect(0, y2, doc.canvas.width, doc.canvas.height - y2);
    rect(0, y1, x1, y2 - y1);
    rect(x2, y1, doc.canvas.width - x2, y2 - y1);

    // crop border
    noFill();
    stroke(255);
    rect(x1, y1, x2 - x1, y2 - y1);

    // rule-of-thirds lines
    stroke(255, 120);
    float w = x2 - x1, h = y2 - y1;
    line(x1 + w/3, y1, x1 + w/3, y2);
    line(x1 + 2*w/3, y1, x1 + 2*w/3, y2);
    line(x1, y1 + h/3, x2, y1 + h/3);
    line(x1, y1 + 2*h/3, x2, y1 + 2*h/3);
  }

  public String name() {
    return "Crop";
  }

  IntRect buildClampedRect(Document doc, float ax, float ay, float bx, float by) {
    int x1 = floor(min(ax, bx));
    int y1 = floor(min(ay, by));
    int x2 = ceil(max(ax, bx));
    int y2 = ceil(max(ay, by));

    x1 = constrain(x1, 0, doc.canvas.width);
    y1 = constrain(y1, 0, doc.canvas.height);
    x2 = constrain(x2, 0, doc.canvas.width);
    y2 = constrain(y2, 0, doc.canvas.height);

    int w = x2 - x1;
    int h = y2 - y1;
    if (w <= 0 || h <= 0) return null;
    return new IntRect(x1, y1, w, h);
  }
}