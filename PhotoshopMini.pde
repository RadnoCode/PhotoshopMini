App app;

// ---------- Processing entry ----------


void settings() {
  size(int(displayWidth * 0.5), int(displayHeight * 0.5));
}
int WinHeight=int(displayHeight*0.5);
int WinWideth=int(displayWidth*0.5);

void setup() {
  surface.setTitle("Crop Demo - Command startYstem (Single File)");
  app = new App();
}

void draw() {
  background(30);
  //app.update();
  app.render();
}

void mousePressed() {
  app.onMousePressed(mouseX, mouseY, mouseButton);
}
void mouseDragged() {
  app.onMouseDragged(mouseX, mouseY, mouseButton);
}
void mouseReleased() {
  app.onMouseReleased(mouseX, mouseY, mouseButton);
}
void mouseWheel(MouseEvent event) {
  app.onMouseWheel(event.getCount());
}
void keyPressed() {
  app.onKeyPressed(key);
}

// selectInput callback must be global
void fileSelected(File selection) {
  if (app != null) app.ui.onFileSelected(app.doc, selection);
  // when a file is selected, the file will be given to app.doc.
}

// =======================================================
// 1) App: event routing + composition root
// =======================================================
class App {
  Document doc;
  Renderer renderer;
  ToolManager tools;
  CommandManager history;
  UI ui;
  /* 五大模块
    Doc：工程文件的唯一真实记录，
    Render：渲染器，从Doc中读取图层信息，显示出画布上的图像
    Tool startYstem：负责处理工具选择，记录连续操作的结果。将结果发送给CommandManager
    UI：基本节目图像，以及一些可以发送给CommandM的指令。
    CommandManger：管理Command记录，发出更改Doc的指令
   */


  App() {
    doc = new Document();
    renderer = new Renderer();
    tools = new ToolManager();
    history = new CommandManager();
    ui = new UI();

    tools.setTool(new MoveTool()); // When you enter, defualtly choose MoveTool 默认移动工具
  }// 生成函数，新建五大模块


  /*void update() {
   // placeholder for future updates
   }*/

  void render() {
    renderer.draw(doc, tools);
    ui.draw(doc, tools, history);
  }//画图和UI

  // ---------- event routing ----------

  //assign mouse and key event, give them to UI first of to Tool.
  void onMousePressed(int mx, int my, int btn) {
    if (ui.handleMousePressed(this, mx, my, btn)) return;
    tools.mousePressed(doc, mx, my, btn);
  }

  void onMouseDragged(int mx, int my, int btn) {
    if (ui.handleMouseDragged(this, mx, my, btn)) return;
    tools.mouseDragged(doc, mx, my, btn);
  }

  void onMouseReleased(int mx, int my, int btn) {
    if (ui.handleMouseReleased(this, mx, my, btn)) return;
    tools.mouseReleased(doc, mx, my, btn);
  }

  void onMouseWheel(float delta) {
    if (ui.handleMouseWheel(this, delta)) return;
    tools.mouseWheel(doc, delta);
  }

  void onKeyPressed(char k) {
    boolean ctrl = (keyEvent.isMetaDown() || keyEvent.isControlDown());

    if (ctrl && (k=='z' || k=='Z')) {
      history.undo(doc);
      return;
    }
    if (ctrl && (k=='y' || k=='Y')) {
      history.redo(doc);
      return;
    }

    if (k=='o' || k=='O') {
      ui.openFileDialog();
      return;
    }
    if (k=='m' || k=='M') {
      tools.setTool(new MoveTool());
      return;
    }
    if (k=='c' || k=='C') {
      tools.setTool(new CropTool(history));
      return;
    }
    if (k=='r' || k=='R') {
      tools.setTool(new RotateTool(history));
      return;
    }
  
    if (k=='s' || k=='S') {
        tools.setTool(new ScaleTool(history));
        return;
    }
}
}

// =======================================================
// 2) Document: single source of truth
// =======================================================
class Document {
  CanvasSpec canvas = new CanvasSpec(900, 600);
  ViewState view = new ViewState();

  LayerStack layers = new LayerStack();
  RenderFlags renderFlags = new RenderFlags();

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

class ViewState {
  float zoom = 1.0;
  float panX = 80;
  float panY = 50;

  void applyTransform() {
    translate(panX, panY);
    scale(zoom);
  }

  public float screenToCanvasX(float MouX) {
    return (MouX - panX) / zoom;
  }
  public float screenToCanvasY(float MouY) {
    return (MouY - panY) / zoom;
  }

  public float canvasToScreenX(float MouX) { 
    return panX + MouX * zoom; 
  }
  public float canvasToScreenY(float MouY) { 
    return panY + MouY * zoom; 
  }

  void zoomAroundMouse(float delta) {// 鼠标向上滚动生成一个负数值，传进来delta
    float oldZoom = zoom;
    float factor = pow(1.10, -delta);
    zoom = constrain(oldZoom * factor, 0.1, 12.0); //限制最大和最小缩放

    float mx = mouseX, my = mouseY;
    float beforeX = (mx - panX) / oldZoom;
    float beforeY = (my - panY) / oldZoom;
    panX = mx - beforeX * zoom;
    panY = my - beforeY * zoom;
  }
}


// ---------- Layers ----------
class Layer {
  PImage img = null;
  float opacity = 1.0;
  boolean visible = true;
  String name = "Layer";

  // Transform in CANVAS space
  float x = 0;            // translation
  float y = 0;
  float rotation = 0;     // radians
  float scale = 1.0;      // uniform.................................................................................................................................................................................00000000000000000

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



// =======================================================
// 3) Renderer: read-only draw pipeline
// =======================================================
class RenderFlags {
  boolean dirtyComposite = true;
}

class Renderer {
  
  void drawChecker(int w, int h, int s) {
    noStroke();
    for (int y = 0; y+s <= h; y += s) {
      for (int x = 0; x+s <= w; x += s) {
        int v = ((x/s + y/s) % 2 == 0) ? 60 : 80;
        fill(v);
        rect(x, y, s, s);
      }
    }
  }// 棋盘格
  
  void draw(Document doc, ToolManager tools) {
    pushMatrix();
    doc.view.applyTransform();

    drawChecker(doc.canvas.w, doc.canvas.h, 20);

    // draw active layer only (MVP)
    Layer active = doc.layers.getActive();
    if (active != null && active.img != null && active.visible) { 
      pushMatrix();
      active.applyTransform();
      tint(255, 255 * active.opacity);
      image(active.img, 0, 0);
      noTint();
      popMatrix();
    }

    // canvas border
    noFill();
    stroke(200);
    rect(0, 0, doc.canvas.w, doc.canvas.h);

    // tool overlay in canvas coords
    tools.drawOverlay(doc);

    popMatrix();

    // tiny hint
    fill(200);
    textSize(12);
    text("Shortcuts: O Open | M Move | C Crop | Ctrl/Cmd+Z Undo | Ctrl/Cmd+Y Redo", 12, height - 12);
  }


}

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
    rect(0, 0, doc.canvas.w, y1);
    rect(0, y2, doc.canvas.w, doc.canvas.h - y2);
    rect(0, y1, x1, y2 - y1);
    rect(x2, y1, doc.canvas.w - x2, y2 - y1);

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

// =======================================================
// 5) CommandstartYstem: discrete actions + Undo/Redo
// =======================================================
interface Command {
  void execute(Document doc);
  void undo(Document doc);
  String name();
}

class CommandManager {
  ArrayList<Command> undoStack = new ArrayList<Command>();
  ArrayList<Command> redoStack = new ArrayList<Command>();

  void perform(Document doc, Command c) {
    if (c == null) return;
    c.execute(doc);
    undoStack.add(c);
    redoStack.clear();
  }

  void undo(Document doc) {
    if (undoStack.size() == 0) return;
    Command c = undoStack.remove(undoStack.size()-1);
    c.undo(doc);
    redoStack.add(c);
  }

  void redo(Document doc) {
    if (redoStack.size() == 0) return;
    Command c = redoStack.remove(redoStack.size()-1);
    c.execute(doc);
    undoStack.add(c);
  }

  int undoCount() {
    return undoStack.size();
  }
  int redoCount() {
    return redoStack.size();
  }
}

class RotateCommand implements Command{
  Layer layer;
  float before,after;
  RotateCommand(Layer tar,float befA,float aftA){
    layer = tar;
    before = befA;
    after = aftA;
  }
  void execute(Document doc){
    layer.rotation=after;
  }

  void undo(Document doc){
    layer.rotation=before;
  }
  String name(){
    return "Rotate";
  }

}

class ScaleCommand implements Command{
  Layer target;
  float before,after;
  ScaleCommand(Layer tar,float befS,float aftS){
    target=tar;
    before=befS;
    after=aftS;
  }
  void execute(Document doc){
    target.scale=after;
  }
  void undo(Document doc){
    target.scale=before;
  }
  String name(){
    return"Scale";
  }
}

// ---------- CropCommand (stores before snapshot for undo) ----------
class CropCommand implements Command {
  IntRect rect;

  // undo snapshot (MVP: whole active layer + canvas size)
  PImage beforeImg;
  int beforeW, beforeH;

  CropCommand(IntRect rect) {
    this.rect = rect;
  }

  public void execute(Document doc) {
    Layer layer = doc.layers.getActive();
    if (layer == null || layer.img == null) return;

    // snapshot once (important for redo correctness)
    if (beforeImg == null) {
      beforeImg = layer.img.get();
      beforeW = doc.canvas.w;
      beforeH = doc.canvas.h;
    }

    // apply crop
    PImage cropped = layer.img.get(rect.x, rect.y, rect.w, rect.h);
    layer.img = cropped;
    doc.canvas.h = cropped.height;
    doc.canvas.w = cropped.width;
    doc.renderFlags.dirtyComposite = true;
  }

  public void undo(Document doc) {
    if (beforeImg == null) return;

    Layer layer = doc.layers.getActive();
    if (layer == null) {
      layer = new Layer(beforeImg.get());
      doc.layers.setSingleLayer(layer);
    } else {
      layer.img = beforeImg.get();
    }

    doc.canvas.w = beforeW;
    doc.canvas.h = beforeH;

    doc.renderFlags.dirtyComposite = true;
  }

  public String name() {
    return "Crop";
  }
}

// =======================================================
// 6) UI: intent generator + hit-test consume
// =======================================================
class UI {
  
  int RightpanelW = 170;
  int RightpanelX =width-RightpanelW;


  UIButton btnOpen, btnMove, btnCrop, btnUndo, btnRedo;

  UI() {
    int x = RightpanelX + 12;
    int y = 20;
    int w = RightpanelW - 24;
    int h = 28;
    int gap = 10;

    btnOpen = new UIButton(x, y, w, h, "Open (O)");
    y += h + gap;
    btnMove = new UIButton(x, y, w, h, "Move (M)");
    y += h + gap;
    btnCrop = new UIButton(x, y, w, h, "Crop (C)");
    y += h + gap;
    btnUndo = new UIButton(x, y, w, h, "Undo");
    y += h + gap;
    btnRedo = new UIButton(x, y, w, h, "Redo");
    y += h + gap;
  }

  void draw(Document doc, ToolManager tools, CommandManager history) {
    // panel background
    noStroke();
    fill(45);
    rect(RightpanelX, 0, RightpanelW, height);

    // buttons
    btnOpen.draw(false);
    btnMove.draw("Move".equals(tools.activeName()));
    btnCrop.draw("Crop".equals(tools.activeName()));
    btnUndo.draw(false);
    btnRedo.draw(false);

    // status
    fill(230);
    textSize(12);
    text("Active Tool: " + tools.activeName(), RightpanelX + 12, height - 70);
    text("Undo: " + /*history.undoCount()*/mouseX, RightpanelX + 12, height - 50);
    text("Redo: " + /*history.redoCount()*/mouseY, RightpanelX + 12, height - 30);

    if (doc.layers.getActive() == null || doc.layers.getActive().img == null) {
      fill(255, 160, 160);
      text("No image loaded.", RightpanelX + 12, height - 95);
    } else {
      fill(180);
      Layer a = doc.layers.getActive();
      text("Image: " + a.img.width + "x" + a.img.height, RightpanelX + 12, height - 95);
    }
  }

  boolean handleMousePressed(App app, int mx, int my, int btn) {
    if (mx < RightpanelX) return false;

    // buttons (generate intents)
    if (btnOpen.hit(mx, my)) {
      openFileDialog();
      return true;
    }
    if (btnMove.hit(mx, my)) {
      app.tools.setTool(new MoveTool());
      return true;
    }
    if (btnCrop.hit(mx, my)) {
      app.tools.setTool(new CropTool(app.history));
      return true;
    }
    if (btnUndo.hit(mx, my)) {
      app.history.undo(app.doc);
      return true;
    }
    if (btnRedo.hit(mx, my)) {
      app.history.redo(app.doc);
      return true;
    }

    return true; // consume clicks on panel
  }

  boolean handleMouseDragged(App app, int mx, int my, int btn) {
    return (mx >= RightpanelX);
  }
  boolean handleMouseReleased(App app, int mx, int my, int btn) {
    return (mx >= RightpanelX);
  }
  boolean handleMouseWheel(App app, float delta) {
    return false;
  }

  void openFileDialog() {
    selectInput("Select an image", "fileSelected");
  }

  void onFileSelected(Document doc, File selection) {
    if (selection == null) return;
    PImage img = loadImage(selection.getAbsolutePath());
    if (img == null) return;

    // set doc content
    doc.layers.setSingleLayer(new Layer(img));
    doc.canvas.w = img.width;
    doc.canvas.h = img.height;

    // reset view (optional)
    doc.view.zoom = 1.0;
    doc.view.panX = 80;
    doc.view.panY = 50;

    doc.renderFlags.dirtyComposite = true;
  }
}

class UIButton {
  int x, y, w, h;
  String label;

  UIButton(int x, int y, int w, int h, String label) {
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
    this.label=label;
  }

  boolean hit(int mx, int my) {
    return mx >= x && mx <= x+w && my >= y && my <= y+h;
  }

  void draw(boolean active) {
    stroke(90);
    fill(active ? 90 : 65);
    rect(x, y, w, h, 6);

    fill(235);
    textAlign(LEFT, CENTER);
    textSize(12);
    text(label, x+10, y + h/2);
    textAlign(LEFT, BASELINE);
  }
}

// =======================================================
// 7) Small utility types
// =======================================================
class IntRect {
  int x, y, w, h;
  IntRect(int x, int y, int w, int h) {
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
  }
}
