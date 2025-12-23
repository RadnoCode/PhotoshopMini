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
    boolean act=true;
    Layer l=doc.layers.getActive();
    
    if (l == null || l.img == null) {act=false;}
    if(l.types=="Text"){
      act=true;
    }
    if(!act) {return ;}
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

    // Use the clamped, positive-size rect for cropping to avoid negative widths/heights.
    history.perform(doc, new CropCommand(doc, r.x, r.y, r.w, r.h));
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

class LayerMoveTool implements Tool {
  CommandManager history;
  Layer target;
  
  float startMouseX, startMouseY; // 鼠标按下时的 Canvas 坐标
  float initialLayerX, initialLayerY; // 图层按下时的初始坐标
  boolean dragging = false;

  LayerMoveTool(CommandManager history) {
    this.history = history;
  }

  public void mousePressed(Document doc, int mx, int my, int btn) {
    if (btn != LEFT) return;
    
    target = doc.layers.getActive();
    if (target == null) return;

    dragging = true;
    // 将屏幕坐标转换为 Canvas 坐标，这样在缩放状态下移动也是准确的
    startMouseX = doc.view.screenToCanvasX(mx);
    startMouseY = doc.view.screenToCanvasY(my);
    
    initialLayerX = target.x;
    initialLayerY = target.y;
  }

  public void mouseDragged(Document doc, int mx, int my, int btn) {
    if (!dragging || target == null) return;

    float currentMouseX = doc.view.screenToCanvasX(mx);
    float currentMouseY = doc.view.screenToCanvasY(my);

    // 计算鼠标位移量
    float dx = currentMouseX - startMouseX;
    float dy = currentMouseY - startMouseY;

    // 实时更新图层位置（预览）
    target.x = initialLayerX + dx;
    target.y = initialLayerY + dy;
    
    doc.markChanged(); // 标记需要重新渲染
  }

  public void mouseReleased(Document doc, int mx, int my, int btn) {
    if (!dragging || target == null) return;
    dragging = false;

    // 只有当位置真的发生变化时，才提交到历史记录
    if (target.x != initialLayerX || target.y != initialLayerY) {
      // 注意这里传入的是最终的 target.x 和 target.y
      history.perform(doc, new layerMoveCommand(target, target.x, target.y));
    }
  }

  public void mouseWheel(Document doc, float delta) {
    doc.view.zoomAroundMouse(delta); // 移动工具下通常也允许缩放
  }

  public void drawOverlay(Document doc) {
    // 可以在这里给选中的图层画一个高亮框
  }

  public String name() { return "LayerMove"; }
}
class BrushTool implements Tool {
  CommandManager history;
  IntSupplier colorSupplier;  // 你 ColorPicker 那边已有 IntSupplier 接口
  boolean editMask;

  float radius = 18;      // 笔刷半径（像素）
  float flow = 1.0f;      // 强度 0..1（可以以后接 UI）
  boolean dragging = false;

  Layer targetLayer = null;
  PImage targetImg = null;
  int[] beforePx = null;

  // 记录上一点，用于补点防断线
  float lastLX, lastLY;
  boolean hasLast = false;

  BrushTool(CommandManager history, IntSupplier colorSupplier, boolean editMask) {
    this.history = history;
    this.colorSupplier = colorSupplier;
    this.editMask = editMask;
  }

  public void mousePressed(Document doc, int mx, int my, int btn) {
    if (btn != LEFT && btn != RIGHT) return;

    targetLayer = doc.layers.getActive();
    if (targetLayer == null) return;
    if (targetLayer instanceof TextLayer) return; // 先不刷文本层

    // 确保空层可画
    targetLayer.ensureRasterForPaint(doc.canvas.width, doc.canvas.height);

    // 选择画在蒙版还是图层像素
    if (editMask) {
      if(targetLayer.mask==null) targetLayer.addMask();
      targetImg = targetLayer.mask;
    } else {
      targetImg = targetLayer.img;
    }
    if (targetImg == null) return;

    targetImg.loadPixels();
    beforePx = targetImg.pixels.clone();

    hasLast = false;
    dragging = true;

    paintAt(doc, mx, my, btn);
    targetImg.updatePixels();
    markDirty(doc);
  }

  public void mouseDragged(Document doc, int mx, int my, int btn) {
    if (!dragging || targetLayer == null || targetImg == null) return;
    paintAt(doc, mx, my, btn);
    targetImg.updatePixels();
    markDirty(doc);
  }

  public void mouseReleased(Document doc, int mx, int my, int btn) {
    if (!dragging || targetLayer == null || targetImg == null) return;
    dragging = false;

    targetImg.updatePixels();
    int[] afterPx = targetImg.pixels.clone();

    // 入历史：执行一次也没关系（状态相同）
    history.perform(doc, new PaintPixelsCommand(targetLayer, editMask, beforePx, afterPx));

    targetLayer = null;
    targetImg = null;
    beforePx = null;
    hasLast = false;
  }

  public void mouseWheel(Document doc, float delta) {
    // 保持你项目一致：滚轮缩放视图（如果你想改成调笔刷，也可以换）
    doc.view.zoomAroundMouse(delta);
  }

  public void drawOverlay(Document doc) {
    // 画笔刷圆圈（在 canvas 坐标下）
    Layer l = doc.layers.getActive();
    if (l == null) return;

    float cx = doc.view.screenToCanvasX(mouseX);
    float cy = doc.view.screenToCanvasY(mouseY);

    float rCanvas = radius * l.scale; // 图层缩放会影响屏幕显示尺寸（更像PS）
    noFill();
    stroke(255, 200);
    ellipse(cx, cy, rCanvas * 2, rCanvas * 2);
  }

  public String name() {
    return editMask ? "Mask Brush" : "Brush";
  }

  // ---------------- internal ----------------

  void markDirty(Document doc) {
    if (targetLayer == null) return;
    if (editMask) {
      targetLayer.maskdirty = true;
      targetLayer.invalidateMaskThumbnail();
    } else {
      targetLayer.filterdirty = true;
      targetLayer.maskdirty = true;
      targetLayer.invalidateThumbnail();
    }
    doc.markChanged();
  }

  void paintAt(Document doc, int mx, int my, int btn) {
    // screen -> canvas
    float cx = doc.view.screenToCanvasX(mx);
    float cy = doc.view.screenToCanvasY(my);

    // canvas -> layer local (image pixel space)
    PVector lp = targetLayer.canvasToLocal(cx, cy);
    float lx = lp.x;
    float ly = lp.y;

    if (!hasLast) {
      dab(lx, ly, btn);
      lastLX = lx; lastLY = ly;
      hasLast = true;
      return;
    }

    float dx = lx - lastLX;
    float dy = ly - lastLY;
    float dist = sqrt(dx*dx + dy*dy);

    float step = max(1, radius * 0.35f);
    int steps = max(1, ceil(dist / step));

    for (int s = 1; s <= steps; s++) {
      float t = s / (float)steps;
      dab(lerp(lastLX, lx, t), lerp(lastLY, ly, t), btn);
    }

    lastLX = lx; lastLY = ly;
  }

  void dab(float lx, float ly, int btn) {
    int w = targetImg.width;
    int h = targetImg.height;

    int cx = round(lx);
    int cy = round(ly);
    int r = max(1, round(radius));
    int rr = r * r;

    int x0 = max(0, cx - r);
    int x1 = min(w - 1, cx + r);
    int y0 = max(0, cy - r);
    int y1 = min(h - 1, cy + r);

    int brushCol = (colorSupplier != null) ? colorSupplier.getAsInt() : color(255);

    for (int y = y0; y <= y1; y++) {
      int dy = y - cy;
      for (int x = x0; x <= x1; x++) {
        int dx = x - cx;
        if (dx*dx + dy*dy > rr) continue;

        int idx = y*w + x;

        // 简单硬边强度（以后想软边，就让 strength 随距离衰减）
        float strength = flow;

        if (editMask) {
          // 蒙版：根据当前画笔颜色亮度写入 alpha，右键强制擦为 0
          int curA = (targetImg.pixels[idx] >>> 24) & 0xFF;
          int targetA;
          if (btn == RIGHT) {
            targetA = 0;
          } else {
            int col = (colorSupplier != null) ? colorSupplier.getAsInt() : color(255);
            int sr = (col >>> 16) & 0xFF;
            int sg = (col >>> 8) & 0xFF;
            int sb = (col) & 0xFF;
            int sa = (col >>> 24) & 0xFF;
            int lum = (int)(0.299f * sr + 0.587f * sg + 0.114f * sb + 0.5f);
            // 同时考虑颜色自身透明度
            targetA = (sa * lum + 127) / 255;
          }
          int newA = (int)(curA + (targetA - curA) * strength + 0.5f);
          targetImg.pixels[idx] = (newA << 24) | 0x00FFFFFF;
        } else {
          // 普通图层：左画色，右当橡皮（擦透明）
          int dst = targetImg.pixels[idx];
          int da = (dst >>> 24) & 0xFF;

          if (btn == RIGHT) {
            // 橡皮：把 alpha 往 0 推
            int newA = (int)(da * (1.0f - strength) + 0.5f);
            targetImg.pixels[idx] = (dst & 0x00FFFFFF) | (newA << 24);
          } else {
            int sr = (brushCol >>> 16) & 0xFF;
            int sg = (brushCol >>> 8) & 0xFF;
            int sb = (brushCol) & 0xFF;
            int sa0 = (brushCol >>> 24) & 0xFF;

            float sa = (sa0 / 255.0f) * strength;
            float inv = 1.0f - sa;

            int dr = (dst >>> 16) & 0xFF;
            int dg = (dst >>> 8) & 0xFF;
            int db = (dst) & 0xFF;

            int nr = (int)(sr * sa + dr * inv + 0.5f);
            int ng = (int)(sg * sa + dg * inv + 0.5f);
            int nb = (int)(sb * sa + db * inv + 0.5f);

            float daF = da / 255.0f;
            int na = (int)(((sa + daF * inv) * 255.0f) + 0.5f);

            targetImg.pixels[idx] = (na << 24) | (nr << 16) | (ng << 8) | nb;
          }
        }
      }
    }
  }
}
