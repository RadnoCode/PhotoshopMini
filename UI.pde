// UI.pde
class UI {
  int panelX = 920;
  int panelW = 170;

  UIButton btnOpen, btnMove, btnCrop, btnUndo, btnRedo;

  // UI 字体和大小可调整
  PFont uiFont;
  int uiFontSize = 14; // 可调：12 / 14 / 16 看哪个最清晰

  UI() {
    // 创建矢量字体（确保系统上存在这个字体名）
    uiFont = createFont("Arial", uiFontSize, true);

    int x = panelX + 12;
    int y = 20;
    int w = panelW - 24;
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
    // 确保 UI 使用屏幕坐标绘制（不受 canvas transform 影响）
    textMode(SCREEN);
    textFont(uiFont);
    textSize(uiFontSize);

    // panel background
    noStroke();
    fill(45);
    rect(panelX, 0, panelW, height);

    // buttons
    btnOpen.draw(false);
    btnMove.draw("Move".equals(tools.activeName()));
    btnCrop.draw("Crop".equals(tools.activeName()));
    // 高亮显示 undo/redo 是否可用
    btnUndo.draw(history.undoCount() > 0);
    btnRedo.draw(history.redoCount() > 0);

    // status
    fill(230);
    textAlign(LEFT, BASELINE);
    text("Active Tool: " + tools.activeName(), panelX + 12, height - 70);
    text("Undo: " + history.undoCount(), panelX + 12, height - 50);
    text("Redo: " + history.redoCount(), panelX + 12, height - 30);

    if (doc.layers.getActive() == null || doc.layers.getActive().img == null) {
      fill(255, 160, 160);
      text("No image loaded.", panelX + 12, height - 95);
    } else {
      fill(180);
      Layer a = doc.layers.getActive();
      text("Image: " + a.img.width + "x" + a.img.height, panelX + 12, height - 95);
    }

    // 恢复为模型坐标文本模式（如果后续在 canvas 上绘制文本）
    textMode(MODEL);
  }

  boolean handleMousePressed(App app, int mx, int my, int btn) {
    // 当点击在面板外部（mx < panelX）时，不处理（让事件传给工具）
    if (mx < panelX) return false;

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
    return (mx >= panelX);
  }
  boolean handleMouseReleased(App app, int mx, int my, int btn) {
    return (mx >= panelX);
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

    doc.layers.setSingleLayer(new Layer(img));
    doc.canvas.w = img.width;
    doc.canvas.h = img.height;

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
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
  }

  boolean hit(int mx, int my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }

  void draw(boolean active) {
    stroke(90);
    fill(active ? 90 : 65);
    rect(x, y, w, h, 6);

    fill(235);
    textAlign(LEFT, CENTER);
    textSize(12);
    text(label, x + 10, y + h/2);
    textAlign(LEFT, BASELINE);
  }
}
