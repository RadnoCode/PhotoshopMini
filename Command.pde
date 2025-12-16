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