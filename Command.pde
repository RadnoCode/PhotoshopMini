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

// ---------- Layer management commands (for undo/redo of panel actions) ----------
class AddLayerCommand implements Command {
  Layer layer;
  int index;

  // Optional canvas/view adjustments when bringing in the very first layer.
  boolean resizeCanvasIfFirst;
  int prevCanvasW, prevCanvasH;
  float prevZoom, prevPanX, prevPanY;
  boolean storedCanvasState = false;

  AddLayerCommand(Layer layer, int index) {
    this(layer, index, false);
  }

  AddLayerCommand(Layer layer, int index, boolean resizeCanvasIfFirst) {
    this.layer = layer;
    this.index = index;
    this.resizeCanvasIfFirst = resizeCanvasIfFirst;
  }

  public void execute(Document doc) {
    if (layer == null) return;

    boolean wasEmpty = doc.layers.isEmpty();

    // When this is the first layer we are adding (including redo), capture the
    // old canvas/view to restore on undo and optionally resize to match the
    // incoming image so beginners immediately see the canvas fit the photo.
    if (resizeCanvasIfFirst && wasEmpty) {
      if (!storedCanvasState) {
        prevCanvasW = doc.canvas.w;
        prevCanvasH = doc.canvas.h;
        prevZoom = doc.view.zoom;
        prevPanX = doc.view.panX;
        prevPanY = doc.view.panY;
        storedCanvasState = true;
      }

      if (layer.img != null) {
        doc.canvas.w = layer.img.width;
        doc.canvas.h = layer.img.height;
        doc.view.zoom = 1.0;
        doc.view.panX = 80;
        doc.view.panY = 50;
      }
    }

    int target = constrain(index, 0, doc.layers.list.size());
    doc.layers.insertLayer(target, layer);
    this.index = target; // keep the clamped slot for redo/undo stability
    doc.renderFlags.dirtyComposite = true;

    // Make sure the new canvas is visible (especially for the first import) by
    // centering it within the window while respecting the space for side panels.
    if (wasEmpty) {
      doc.view.centerOnCanvas(doc.canvas.w, doc.canvas.h, 64, 200);
    }
  }

  public void undo(Document doc) {
    if (layer == null) return;
    int current = doc.layers.list.indexOf(layer);
    if (current >= 0) {
      doc.layers.removeLayer(current);
    }

    if (resizeCanvasIfFirst && doc.layers.isEmpty() && storedCanvasState) {
      doc.canvas.w = prevCanvasW;
      doc.canvas.h = prevCanvasH;
      doc.view.zoom = prevZoom;
      doc.view.panX = prevPanX;
      doc.view.panY = prevPanY;
    }

    doc.renderFlags.dirtyComposite = true;
  }

  public String name() {
    return "Add Layer";
  }
}

class RemoveLayerCommand implements Command {
  Layer layer;
  int priorIndex;

  RemoveLayerCommand(Layer layer, int index) {
    this.layer = layer;
    this.priorIndex = index;
  }

  public void execute(Document doc) {
    if (layer == null) return;
    int idx = doc.layers.list.indexOf(layer);
    if (idx < 0 && priorIndex >= 0 && priorIndex < doc.layers.list.size()) {
      idx = priorIndex;
    }
    if (idx < 0 || idx >= doc.layers.list.size()) return;

    priorIndex = idx; // keep the last known index so undo can re-insert
    doc.layers.removeLayer(idx);
    doc.renderFlags.dirtyComposite = true;
  }

  public void undo(Document doc) {
    if (layer == null) return;
    int target = constrain(priorIndex, 0, doc.layers.list.size());
    doc.layers.insertLayer(target, layer);
    doc.renderFlags.dirtyComposite = true;
  }

  public String name() {
    return "Remove Layer";
  }
}

class MoveLayerCommand implements Command {
  Layer layer;
  int fromIndex;
  int toIndex;

  MoveLayerCommand(Layer layer, int fromIndex, int toIndex) {
    this.layer = layer;
    this.fromIndex = fromIndex;
    this.toIndex = toIndex;
  }

  public void execute(Document doc) {
    if (layer == null) return;
    int current = doc.layers.list.indexOf(layer);
    if (current < 0) return;

    int dest = constrain(toIndex, 0, doc.layers.list.size() - 1);
    doc.layers.moveLayer(current, dest);
    doc.renderFlags.dirtyComposite = true;
  }

  public void undo(Document doc) {
    if (layer == null) return;
    int current = doc.layers.list.indexOf(layer);
    if (current < 0) return;

    int dest = constrain(fromIndex, 0, doc.layers.list.size() - 1);
    doc.layers.moveLayer(current, dest);
    doc.renderFlags.dirtyComposite = true;
  }

  public String name() {
    return "Reorder Layer";
  }
}

class RenameLayerCommand implements Command {
  Layer layer;
  String before;
  String after;

  RenameLayerCommand(Layer layer, String newName) {
    this.layer = layer;
    this.after = (newName == null) ? null : newName.trim();
    if (layer != null) {
      this.before = layer.name;
    }
  }

  public void execute(Document doc) {
    if (layer == null || after == null || after.isEmpty()) return;
    int idx = doc.layers.list.indexOf(layer);
    if (idx < 0) return;
    doc.layers.renameLayer(idx, after);
  }

  public void undo(Document doc) {
    if (layer == null || before == null) return;
    int idx = doc.layers.list.indexOf(layer);
    if (idx < 0) return;
    doc.layers.renameLayer(idx, before);
  }

  public String name() {
    return "Rename Layer";
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