// =======================================================
// 5) CommandstartYstem: discrete actions + Undo/Redo
// =======================================================

interface Command {
  void execute(Document doc);
  void undo(Document doc);
  String name();
}

// Optional listener to keep UI/state in sync after history operations.
interface CommandListener {
  void onHistoryChanged(Document doc);
}

class CommandManager {
  ArrayList<Command> undoStack = new ArrayList<Command>();
  ArrayList<Command> redoStack = new ArrayList<Command>();
  CommandListener listener;

  void setListener(CommandListener listener) {
    this.listener = listener;
  }

  void notifyListener(Document doc) {
    if (listener != null) listener.onHistoryChanged(doc);
  }

  void perform(Document doc, Command c) {
    if (c == null) return;
    c.execute(doc);
    undoStack.add(c);
    redoStack.clear();
    notifyListener(doc);
  }

  void undo(Document doc) {
    if (undoStack.size() == 0) return;
    Command c = undoStack.remove(undoStack.size()-1);
    c.undo(doc);
    redoStack.add(c);
    notifyListener(doc);
  }

  void redo(Document doc) {
    if (redoStack.size() == 0) return;
    Command c = redoStack.remove(redoStack.size()-1);
    c.execute(doc);
    undoStack.add(c);
    notifyListener(doc);
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

  public String name() {
    return "Add Layer";
  }
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

  public String name() {
    return "Remove Layer";
  }
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

  public String name() {
    return "Toggle Visibility";
  }
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

  public String name() {
    return "Move Layer";
  }
}

class RenameLayerCommand implements Command {
  Layer layer;
  String before, after;

  RenameLayerCommand(Layer layer, String afterName) {
    this.layer = layer;
    this.before = layer.name;
    this.after  = afterName;
  }

  public void execute(Document doc) {
    layer.name = after;
  }
  public void undo(Document doc) {
    layer.name = before;
  }
  public String name() {
    return "Rename Layer";
  }
}


class RotateCommand implements Command {
  Layer layer;
  float before, after;
  RotateCommand(Layer tar, float befA, float aftA) {
    layer = tar;
    before = befA;
    after = aftA;
  }
  void execute(Document doc) {
    layer.rotation=after;
    doc.renderFlags.dirtyComposite = true;
    //println("rotation: "+after);
  }
  void undo(Document doc) {
    layer.rotation=before;
    doc.renderFlags.dirtyComposite = true;
  }
  String name() {
    return "Rotate";
  }
}

class ScaleCommand implements Command {
  Layer target;
  float before, after;
  ScaleCommand(Layer tar, float befS, float aftS) {
    target=tar;
    before=befS;
    after=aftS;
  }
  void execute(Document doc) {
    target.scale=after;
    doc.renderFlags.dirtyComposite=true;
  }
  void undo(Document doc) {
    target.scale=before;
    doc.renderFlags.dirtyComposite=true;
  }
  String name() {
    return"Scale";
  }
}

// ---------- CropCommand (stoIndexres before snapshot for undo) ----------
class CropCommand implements Command {
  int x, y, w, h;
  int befx, befy, befw, befh;


  CropCommand(Document doc, int x, int y, int w, int h) {
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
    this.befx=doc.viewX;
    this.befy=doc.viewY;
    this.befw=doc.viewW;
    this.befh=doc.viewH;
  }

  public void execute(Document doc) {
    if (x<befx||y<befy||x+w>befx+befw||y+h>befy+befh) return ;// Todo: warning for illeagal

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

class TransformCommand implements Command {
  Layer target;
  float oldX, oldY, oldScale, oldRotation;
  float newX, newY, newScale, newRotation;

  TransformCommand(Layer l, float nx, float ny, float ns, float nr) {
    this.target = l;
    this.oldX = l.x;
    this.oldY = l.y;
    this.oldScale = l.scale;
    this.oldRotation = l.rotation;
    this.newX = nx;
    this.newY = ny;
    this.newScale = ns;
    this.newRotation = nr;
  }

  public void execute(Document doc) {
    target.x = newX;
    target.y = newY;
    target.scale = newScale;
    target.rotation = newRotation;
    doc.markChanged();
  }

  public void undo(Document doc) {
    target.x = oldX;
    target.y = oldY;
    target.scale = oldScale;
    target.rotation = oldRotation;
    doc.markChanged();
  }

  public String name() {
    return "Transform";
  }
}

// ---------- OpacityCommand (0.0 - 1.0) ----------
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
    doc.renderFlags.dirtyComposite = true;
  }

  public void undo(Document doc) {
    target.opacity = oldOp;
    doc.renderFlags.dirtyComposite = true;
  }

  public String name() {
    return "Change Opacity";
  }
}

// ---------- Text commands ----------
class SetTextCommand implements Command {
  TextLayer layer;
  String before, after;

  SetTextCommand(TextLayer layer, String newText) {
    this.layer = layer;
    this.before = layer.text;
    this.after = newText;
  }

  public void execute(Document doc) {
    if (layer == null) return;
    layer.setText(after);
    doc.renderFlags.dirtyComposite = true;
  }

  public void undo(Document doc) {
    if (layer == null) return;
    layer.setText(before);
    doc.renderFlags.dirtyComposite = true;
  }

  public String name() {
    return "Set Text";
  }
}

class SetFontNameCommand implements Command {
  TextLayer layer;
  String before, after;

  SetFontNameCommand(TextLayer layer, String fontName) {
    this.layer = layer;
    this.before = layer.fontName;
    this.after = fontName;
  }

  public void execute(Document doc) {
    if (layer == null) return;
    layer.setFontName(after);
    doc.markChanged();
  }

  public void undo(Document doc) {
    if (layer == null) return;
    layer.setFontName(before);
    doc.markChanged();
  }

  public String name() {
    return "Set Font Name";
  }
}

class SetFontSizeCommand implements Command {
  TextLayer layer;
  int before, after;

  SetFontSizeCommand(TextLayer layer, int size) {
    this.layer = layer;
    this.before = layer.fontSize;
    this.after = size;
  }

  public void execute(Document doc) {
    if (layer == null) return;
    layer.setFontSize(after);
    doc.markChanged();
  }

  public void undo(Document doc) {
    if (layer == null) return;
    layer.setFontSize(before);
    doc.markChanged();
  }

  public String name() {
    return "Set Font Size";
  }
}

class AddFilterCommand implements Command {



  Layer layer;
  Filter filter;

  AddFilterCommand(Layer layer, Filter filter) {
    this.layer = layer;
    this.filter = filter;
  }

  public void execute(Document doc) {
    filter.layer = layer;
    layer.filters.add(filter);
    layer.dirty = true;
    doc.markChanged();
  }

  public void undo(Document doc) {
    layer.filters.remove(filter);
    filter.layer = null;
    layer.dirty = true;
    doc.markChanged();
  }

  public String name() {
    return "Add Filter";
  }
}
class RemoveFilterCommand implements Command {
  Layer layer;
  Filter filter;

  RemoveFilterCommand(Layer layer, Filter filter) {
    this.layer = layer;
    this.filter = filter;
  }

  public void execute(Document doc) {
    layer.filters.remove(filter);
    filter.layer = null;
    layer.dirty = true;
    doc.markChanged();
  }

  public void undo(Document doc) {
    filter.layer = layer;
    layer.filters.add(filter);
    layer.dirty = true;
    doc.markChanged();
  }

  public String name() {
    return "Remove Filter";
  }
}

class BlurChangeCommand implements Command {
  GaussianBlurFilter filter;
  int bR, aR, bS, aS;

  BlurChangeCommand(GaussianBlurFilter filter, int aR,int aS) {
    this.filter = filter;
    this.aR = aR;
    this.aS = aS;
    this.bR = filter.radius;
    this.bS = filter.sigma;
  }

  public void execute(Document doc) {
    filter.radius = aR;
    filter.sigma = aS;
    filter.change = true;
    if (filter.layer != null) filter.layer.dirty = true;
    doc.markChanged();
  }

  public void undo(Document doc) {
    filter.radius = bR;
    filter.sigma = bS;
    filter.change = true;
    if (filter.layer != null) filter.layer.dirty = true;
    doc.markChanged();
  }

  public String name() {
    return "Change Blur Radius";
  }
}

class ContrastChangeCommand implements Command {
  ContrastFilter filter;
  float before, after;

  ContrastChangeCommand(ContrastFilter filter, float after) {
    this.filter = filter;
    this.after = after;
    this.before = filter.value;
  }

  public void execute(Document doc) {
    filter.value = after;
    if (filter.layer != null) filter.layer.dirty = true;
    doc.markChanged();
  }

  public void undo(Document doc) {
    filter.value = before;
    if (filter.layer != null) filter.layer.dirty = true;
    doc.markChanged();
  }

  public String name() {
    return "Change Contrast";
  }
}

class SharpenChangeCommand implements Command {
  SharpenFilter filter;
  float before, after;

  SharpenChangeCommand(SharpenFilter filter, float after) {
    this.filter = filter;
    this.after = after;
    this.before = filter.value;
  }

  public void execute(Document doc) {
    filter.value = after;
    if (filter.layer != null) filter.layer.dirty = true;
    doc.markChanged();
  }

  public void undo(Document doc) {
    filter.value = before;
    if (filter.layer != null) filter.layer.dirty = true;
    doc.markChanged();
  }

  public String name() {
    return "Change Sharpen";
  }
}

class layerMoveCommand implements Command {
  Layer layer;
  float beforeX, beforeY;
  float afterX, afterY;

  layerMoveCommand(Layer layer, float afterX, float afterY) {
    this.layer = layer;
    this.beforeX = layer.x;
    this.beforeY = layer.y;
    this.afterX = afterX;
    this.afterY = afterY;
  }

  public void execute(Document doc) {
    layer.x = afterX;
    layer.y = afterY;
    doc.markChanged();
  }

  public void undo(Document doc) {
    layer.x = beforeX;
    layer.y = beforeY;
    doc.markChanged();
  }

  public String name() {
    return "Move Layer Position";
  }
}
