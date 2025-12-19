class UI {
  App app;      // 持有对 App 的引用

  JSlider sliderOpacity; // 滑动条
  
  PApplet parent;
  Document doc;
  
  int RightpanelW = 270;
  int RightpanelX = width-RightpanelW;
  int LeftPannelW = 64;

  boolean isUpdatingUI = false; // 新增：标记位，防止循环触发

  UIButton btnOpen, btnMove, btnCrop, btnUndo, btnRedo;
  LayerListPanel layerListPanel;

  JTextField fieldX, fieldY;
  JPanel propsPanel;

  UI(PApplet parent, Document doc, App app) {
    this.parent = parent;
    this.doc = doc;
    this.app = app;

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

    //初始化图层面板
    layerListPanel = new LayerListPanel(parent, doc, RightpanelX, RightpanelW, y);

    // 关键：初始化属性面板并放入 layerListPanel 的容器
    setupPropertiesPanel(this.layerListPanel.container);
  }

  void draw(Document doc, ToolManager tools, CommandManager history) {
    // panel background
    noStroke();
    fill(45);
    rect(RightpanelX, 0, RightpanelW, height);
    rect(0,0,LeftPannelW,height);

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
    text("X-axis: " + /*history.undoCount()*/mouseX, RightpanelX + 12, height - 50);
    text("Y-axis: " + /*history.redoCount()*/mouseY, RightpanelX + 12, height - 30);

    if (doc.layers.getActive() == null || doc.layers.getActive().img == null) {
      fill(255, 160, 160);
      text("No image loaded.", RightpanelX + 12, height - 95);
    } else {
      fill(180);
      Layer a = doc.layers.getActive();
      text("Image: " + a.img.width + "x" + a.img.height, RightpanelX + 12, height - 95);
    }

    // layerListPanel.refresh(doc);我把这一行代码注释掉进行调试
    layerListPanel.updateLayout(RightpanelX, RightpanelW, height);
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

    Layer active = doc.layers.getActive();
    boolean canReuseActive = active != null && active.empty;

    if (canReuseActive) {
      active.img = img;
      active.empty=false;
      active.visible = true;
      active.x = 0;
      active.y = 0;
      active.rotation = 0;
      active.scale = 1.0;
      active.pivotX = img.width * 0.5;
      active.pivotY = img.height * 0.5;
      doc.layers.activeIndex = doc.layers.indexOf(active);
    } else {
      Layer l = new Layer(img, doc.layers.getid());
      l.name = "Layer " + l.ID;
      l.empty=false;
      l.visible = true;
      doc.layers.list.add(l);
      doc.layers.activeIndex = doc.layers.indexOf(l);
    }

    doc.renderFlags.dirtyComposite = true;
    layerListPanel.refresh(doc);
  }
void updatePropertiesFromLayer(Layer l) {
    if (l == null || fieldX == null || sliderOpacity == null) return;
    
    isUpdatingUI = true; 
    
    // 同步坐标
    fieldX.setText(String.valueOf((int)l.x));
    fieldY.setText(String.valueOf((int)l.y));
    
    // 同步透明度滑动条：将 0.0-1.0 还原回 0-255
    sliderOpacity.setValue((int)(l.opacity * 255));
    
    isUpdatingUI = false; 
  }

  void updateLayerFromUI() {
    if (isUpdatingUI) return; // 如果是程序自动填写的，不要执行移动指令
    Layer active = doc.layers.getActive();
    if (active == null) return;
    try {
      float nx = Float.parseFloat(fieldX.getText());
      float ny = Float.parseFloat(fieldY.getText());
      app.history.perform(doc, new MoveCommand(active, nx, ny));
    } catch (Exception e) {
      updatePropertiesFromLayer(active);
    }
  }
  void setupPropertiesPanel(JPanel container) {
    // 1. 改为 3 行 2 列以容纳 X, Y, Opacity
    propsPanel = new JPanel(new GridLayout(3, 2, 5, 5));
    propsPanel.setBackground(new Color(60, 60, 60));

    // 初始化 X, Y 输入框
    JLabel labelX = new JLabel(" X:");
    labelX.setForeground(Color.WHITE);
    fieldX = new JTextField("0");
    
    JLabel labelY = new JLabel(" Y:");
    labelY.setForeground(Color.WHITE);
    fieldY = new JTextField("0");
    
    container.add(propsPanel, BorderLayout.SOUTH);
    
    // 监听回车
    fieldX.addActionListener(e -> updateLayerFromUI());
    fieldY.addActionListener(e -> updateLayerFromUI());
    // --- 新增：透明度部分 ---
  JLabel labelOp = new JLabel(" Opacity:");
  labelOp.setForeground(Color.WHITE);
  // 参数：最小值, 最大值, 当前值
  sliderOpacity = new JSlider(0, 255, 255);
  sliderOpacity.setBackground(new Color(60, 60, 60));
  
  // 监听滑动条
  sliderOpacity.addChangeListener(e -> {
    if (!sliderOpacity.getValueIsAdjusting()) { // 当玩家松开手指时执行命令
      updateOpacityFromUI();
    }
  });

  propsPanel.add(labelX); propsPanel.add(fieldX);
  propsPanel.add(labelY); propsPanel.add(fieldY);
  propsPanel.add(labelOp); propsPanel.add(sliderOpacity); // 添加到面板
  
  container.add(propsPanel, BorderLayout.SOUTH);
  
  fieldX.addActionListener(e -> updateLayerFromUI());
  fieldY.addActionListener(e -> updateLayerFromUI());
}
// 从 UI 更新到图层
void updateOpacityFromUI() {
  if (isUpdatingUI) return;
  Layer active = doc.layers.getActive();
  if (active == null) return;

  float newOp = sliderOpacity.getValue();
  app.history.perform(doc, new OpacityCommand(active, newOp));
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
