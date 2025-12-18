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
      layer = new Layer(beforeImg.get(),doc.layers.getid());
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