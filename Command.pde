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

class AddLayerCommand implements Command {
  Layer layer;
  int index;

  AddLayerCommand(Layer layer, int index) {
    this.layer = layer;
    this.index = index;
  }

  public void execute(Document doc) {
    doc.layers.insertAt(index, layer);
    doc.layers.activeIndex = doc.layers.indexOf(layer);
    doc.renderFlags.dirtyComposite = true;
  }

  public void undo(Document doc) {
    int i = doc.layers.indexOf(layer);
    if (i >= 0) doc.layers.removeAt(i);
    doc.renderFlags.dirtyComposite = true;
  }

  public String name() { return "Add Layer"; }
}


class RemoveLayerCommand implements Command {
  Layer layer;
  int index = -1;

  RemoveLayerCommand(Layer layer) {
    this.layer = layer;
  }

  public void execute(Document doc) {
    index = doc.layers.indexOf(layer);
    if (index < 0) return;
    doc.layers.removeAt(index);
    doc.renderFlags.dirtyComposite = true;
  }

  public void undo(Document doc) {
    if (index < 0) return;
    doc.layers.insertAt(index, layer);
    doc.layers.activeIndex = doc.layers.indexOf(layer);
    doc.renderFlags.dirtyComposite = true;
  }

  public String name() { return "Remove Layer"; }
}

class ToggleVisibleCommand implements Command {
  Layer layer;
  boolean before, after;

  ToggleVisibleCommand(Layer layer) {
    this.layer = layer;
    this.before = layer.visible;
    this.after  = !layer.visible;
  }

  public void execute(Document doc) {
    layer.visible = after;
    doc.renderFlags.dirtyComposite = true;
  }

  public void undo(Document doc) {
    layer.visible = before;
    doc.renderFlags.dirtyComposite = true;
  }

  public String name() { return "Toggle Visibility"; }
}


class MoveLayerCommand implements Command {
  Layer layer;
  int from, toIndex;

  MoveLayerCommand(Layer layer, int from, int toIndex) {
    this.layer = layer;
    this.from = from;
    this.toIndex = toIndex;
  }

  public void execute(Document doc) {
    // 保险：执行时再找一次 layer 当前 index，避免外界变动
    int cur = doc.layers.indexOf(layer);
    println("cur"+cur);
    if (cur < 0) return;
    doc.layers.move(cur, toIndex);
    doc.layers.activeIndex = doc.layers.indexOf(layer);
    doc.renderFlags.dirtyComposite = true;
  }

  public void undo(Document doc) {
    int cur = doc.layers.indexOf(layer);
    if (cur < 0) return;
    doc.layers.move(cur, from);
    doc.layers.activeIndex = doc.layers.indexOf(layer);
    doc.renderFlags.dirtyComposite = true;
  }

  public String name() { return "Move Layer"; }
}

class RenameLayerCommand implements Command {
  Layer layer;
  String before, after;

  RenameLayerCommand(Layer layer, String afterName) {
    this.layer = layer;
    this.before = layer.name;
    this.after  = afterName;
  }

  public void execute(Document doc) { layer.name = after; }
  public void undo(Document doc) { layer.name = before; }
  public String name() { return "Rename Layer"; }
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
    println("rotation: "+after);
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

// ---------- CropCommand (stoIndexres before snapshot for undo) ----------
class CropCommand implements Command {
  int x,y,w,h;
  int befx,befy,befw,befh;


  CropCommand(Document doc,int x,int y,int w,int h) {
    this.x=x;this.y=y;this.w=w;this.h=h;
    this.befx=doc.viewX;this.befy=doc.viewY;this.befw=doc.viewW;this.befh=doc.viewH;
  }

  public void execute(Document doc) {
    if(x<befx||y<befy||x+w>befx+befw||y+h>befy+befh) return ;// Todo: warning for illeagal 

    // apply crop
    doc.viewX=x;
    doc.viewY=y;
    doc.viewH=h;
    doc.viewW=w;

    doc.renderFlags.dirtyComposite = true;
  }

  public void undo(Document doc) {
    doc.viewX=befx;
    doc.viewY=befy;
    doc.viewW=befw;
    doc.viewH = befh;

    doc.renderFlags.dirtyComposite = true;
  }

  public String name() {
    return "Crop";
  }
}

class MoveCommand implements Command {
  Layer target;
  float oldX, oldY, newX, newY;

  MoveCommand(Layer l, float nx, float ny) {
    this.target = l;
    this.oldX = l.x; 
    this.oldY = l.y;
    this.newX = nx;  
    this.newY = ny;
  }

  public void execute(Document doc) {
    target.x = newX;
    target.y = newY;
    doc.markChanged(); // 标记画布需要重绘
  }

  public void undo(Document doc) {
    target.x = oldX;
    target.y = oldY;
    doc.markChanged();
  }

  public String name() { 
    return "Manual Move"; 
  }
}

class OpacityCommand implements Command {
  Layer target;
  float oldOp, newOp;

  OpacityCommand(Layer l, float sliderValue) {
    this.target = l;
    this.oldOp = l.opacity;
    // 将 0-255 映射到 0.0-1.0
    this.newOp = sliderValue / 255.0;
  }

  public void execute(Document doc) {
    target.opacity = newOp;
    // 关键：通知渲染器画面已脏，需要重新合成
    doc.renderFlags.dirtyComposite = true;
  }

  public void undo(Document doc) {
    target.opacity = oldOp;
    doc.renderFlags.dirtyComposite = true;
  }

  public String name() { return "Change Opacity"; }
}