import java.text.SimpleDateFormat;
import java.util.Date;

class UI {
  App app;      // 持有对 App 的引用

  JSlider sliderOpacity; // 滑动条
  
  PApplet parent;
  Document doc;
  
  int RightpanelW = 270;
  int RightpanelX = width-RightpanelW;
  int LeftPannelW = 64;

  boolean isUpdatingUI = false; // 新增：标记位，防止循环触发
  File lastExportDir;

  UIButton btnOpen, btnMove, btnCrop, btnText, btnExport, btnUndo, btnRedo;
  LayerListPanel layerListPanel;

  JTextField fieldX, fieldY, fieldText;
  JComboBox<String> comboFont;
  JSpinner spinnerFontSize;
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
    btnText = new UIButton(x, y, w, h, "Text (T)");
    y += h + gap;
    btnExport = new UIButton(x, y, w, h, "Export (E)");
    y += h + gap;
    btnUndo = new UIButton(x, y, w, h, "Undo");
    y += h + gap;
    btnRedo = new UIButton(x, y, w, h, "Redo");
    y += h + gap;

    //初始化图层面板
    layerListPanel = new LayerListPanel(parent, doc, RightpanelX, RightpanelW, y);

    // 关键：初始化属性面板并放入 layerListPanel 的容器
    setupPropertiesPanel(this.layerListPanel.container);

    // 默认导出目录：优先桌面，找不到则放到工程目录下的 exports
    lastExportDir = new File(System.getProperty("user.home"), "Desktop");
    if (!lastExportDir.exists() || !lastExportDir.isDirectory()) {
      lastExportDir = new File(parent.sketchPath("exports"));
      lastExportDir.mkdirs();
    }
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
    btnText.draw("Text".equals(tools.activeName())); // text tool shares active name slot
    btnExport.draw(false);
    btnUndo.draw(false);
    btnRedo.draw(false);

    // status
    fill(230);
    textSize(12);
    text("Active Tool: " + tools.activeName(), RightpanelX + 12, height - 70);
    text("X-axis: " + /*history.undoCount()*/mouseX, RightpanelX + 12, height - 50);
    text("Y-axis: " + /*history.redoCount()*/mouseY, RightpanelX + 12, height - 30);

    // 隐藏/重置属性面板
    Layer active = doc.layers.getActive();
    // 核心逻辑：如果没有活跃图层，隐藏 Java Swing 的属性面板
    if (active == null || active.img == null) {
      if (propsPanel != null && propsPanel.isVisible()) {
        propsPanel.setVisible(false); // 隐藏面板
      }
      // 可以在原本显示属性的地方画一些提示文字
      fill(100);
      textSize(12);
      text("Select a layer to edit properties", RightpanelX + 12, layerListPanel.topY - 20);
    } else {
      if (propsPanel != null && !propsPanel.isVisible()) {
        propsPanel.setVisible(true); // 重新显示面板
      }
    }

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
    if (btnText.hit(mx, my)) {
      createTextLayer();
      return true;
    }
    if (btnExport.hit(mx, my)) {
      exportCanvas();
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
  void exportCanvas() {
    selectOutput("Export canvas (PNG)", "exportSelected", defaultExportFile());
  }

  void createTextLayer() {
    TextLayer tl = new TextLayer("Text", "SansSerif", 48, doc.layers.getid());
    tl.name = "Text " + tl.ID;
    tl.x = doc.viewW * 0.5 - tl.pivotX;
    tl.y = doc.viewH * 0.5 - tl.pivotY;
    int index = doc.layers.list.size();
    app.history.perform(doc, new AddLayerCommand(tl, index));
    doc.renderFlags.dirtyComposite = true;
    layerListPanel.refresh(doc);
    updatePropertiesFromLayer(tl);
  }

  void onFileSelected(Document doc, File selection) {
    if (selection == null) return;
    PImage img = loadImage(selection.getAbsolutePath());
    if (img == null) return;

    Layer active = doc.layers.getActive();
    boolean canReuseActive = active != null && active.empty&&active.types!="Text";

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

    boolean isText = (l instanceof TextLayer);
    fieldText.setEnabled(isText);
    comboFont.setEnabled(isText);
    spinnerFontSize.setEnabled(isText);
    if (isText) {
      TextLayer tl = (TextLayer) l;
      fieldText.setText(tl.text);
      comboFont.setSelectedItem(tl.fontName);
      spinnerFontSize.setValue(tl.fontSize);
    } else {
      fieldText.setText("");
    }

    if (l == null) {
    if (propsPanel != null) {
      propsPanel.setVisible(false); // 隐藏面板
    }
    return;
  }

  // 如果有图层，确保面板可见并更新数值
  if (propsPanel != null) {
    propsPanel.setVisible(true); 
  }
  
  isUpdatingUI = true; 
  if (fieldX != null) fieldX.setText(String.valueOf((int)l.x));
  if (fieldY != null) fieldY.setText(String.valueOf((int)l.y));
  if (sliderOpacity != null) {
    sliderOpacity.setValue((int)(l.opacity * 255));
  }
    
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

  TextLayer getActiveTextLayer() {
    Layer active = doc.layers.getActive();
    if (active == null) return null;
    if (!(active instanceof TextLayer)) return null;
    return (TextLayer) active;
  }

  void updateTextFromUI() {
    if (isUpdatingUI) return;
    TextLayer tl = getActiveTextLayer();
    if (tl == null) return;
    app.history.perform(doc, new SetTextCommand(tl, fieldText.getText()));
  }

  void updateFontNameFromUI() {
    if (isUpdatingUI) return;
    TextLayer tl = getActiveTextLayer();
    if (tl == null) return;
    String value = (String) comboFont.getSelectedItem();
    app.history.perform(doc, new SetFontNameCommand(tl, value));
  }

  void updateFontSizeFromUI() {
    if (isUpdatingUI) return;
    TextLayer tl = getActiveTextLayer();
    if (tl == null) return;
    int size = ((Number) spinnerFontSize.getValue()).intValue();
    app.history.perform(doc, new SetFontSizeCommand(tl, size));
  }
  void setupPropertiesPanel(JPanel container) {
    // 属性：位置、透明度、文本
    propsPanel = new JPanel(new GridLayout(6, 2, 5, 5));
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
    
    // 文本相关
    JLabel labelText = new JLabel(" Text:");
    labelText.setForeground(Color.WHITE);
    fieldText = new JTextField("");

    JLabel labelFont = new JLabel(" Font:");
    labelFont.setForeground(Color.WHITE);
    String[] fontOptions = { "Arial", "Helvetica", "Courier", "Times New Roman" };
    comboFont = new JComboBox<String>(fontOptions);

    JLabel labelSize = new JLabel(" Size:");
    labelSize.setForeground(Color.WHITE);
    spinnerFontSize = new JSpinner(new SpinnerNumberModel(48, 6, 400, 2));

    // 监听滑动条
    sliderOpacity.addChangeListener(e -> {
      if (!sliderOpacity.getValueIsAdjusting()) { // 当玩家松开手指时执行命令
        updateOpacityFromUI();
      }
    });

    fieldText.addActionListener(e -> updateTextFromUI());
    comboFont.addActionListener(e -> updateFontNameFromUI());
    spinnerFontSize.addChangeListener(e -> updateFontSizeFromUI());

    propsPanel.add(labelX); propsPanel.add(fieldX);
    propsPanel.add(labelY); propsPanel.add(fieldY);
    propsPanel.add(labelOp); propsPanel.add(sliderOpacity);
    propsPanel.add(labelText); propsPanel.add(fieldText);
    propsPanel.add(labelFont); propsPanel.add(comboFont);
    propsPanel.add(labelSize); propsPanel.add(spinnerFontSize);
    
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

  File defaultExportFile() {
    return new File(lastExportDir, defaultExportName());
  }

  String defaultExportName() {
    String stamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(new Date());
    return "export-" + stamp + ".png";
  }

  void onExportSelected(Document doc, File selection) {
    if (selection == null || doc == null || doc.canvas == null) return;

    // ensure the backing canvas is up to date before capture
    app.renderer.drawCanvas(doc, app.tools);

    int exportX = max(0, doc.viewX);
    int exportY = max(0, doc.viewY);
    int exportW = max(1, min(doc.viewW, doc.canvas.width - exportX));
    int exportH = max(1, min(doc.viewH, doc.canvas.height - exportY));
    if (exportW <= 0 || exportH <= 0) return;

    PImage output = doc.canvas.get(exportX, exportY, exportW, exportH);
    File target = selection.isDirectory()
      ? new File(selection, defaultExportName())
      : selection;

    String path = target.getAbsolutePath();
    if (!path.toLowerCase().endsWith(".png")) path += ".png";
    output.save(path);
    println("Exported canvas to: " + path);
    lastExportDir = new File(path).getParentFile();
    // 在独立应用里找不到文件时，弹窗告诉用户具体路径
    JOptionPane.showMessageDialog(
      null,
      "已导出到：\n" + path,
      "Export Completed",
      JOptionPane.INFORMATION_MESSAGE
    );
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
