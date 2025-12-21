import java.text.SimpleDateFormat;
import java.util.Date;

class UI {
  App app;



  PApplet parent;
  Document doc;

  int RightpanelW = 270;
  int RightpanelX = width-RightpanelW;
  int LeftPannelW = 64;

  boolean isUpdatingUI = false; // 新增：标记位，防止循环触发
  File lastExportDir;

  UIButton btnOpen, btnMove, btnCrop, btnText, btnExport, btnUndo, btnRedo, btnBlur, btnCon, btnSharpen;
  LayerListPanel layerListPanel;


  JTextField fieldX, fieldY, fieldText;
  JComboBox<String> comboFont;
  JSpinner spinnerFontSize;
  JPanel propsPanel;
  JSlider sliderOpacity;
  JSlider sliderContrast;
  JSlider sliderSharpen; 

  UI(PApplet parent, Document doc, App app) {
    this.parent = parent;
    this.doc = doc;
    this.app = app;

    int x = 12;
    int y = 20;
    int w = LeftPannelW - 24;
    int h = 28;
    int gap = 10;

    btnOpen = new UIButton(x, y, w, h, "(O)");
    y += h + gap;
    btnMove = new UIButton(x, y, w, h, "(M)");
    y += h + gap;
    btnCrop = new UIButton(x, y, w, h, "(C)");
    y += h + gap;
    btnText = new UIButton(x, y, w, h, "(T)");
    y += h + gap;
    btnExport = new UIButton(x, y, w, h, "(E)");
    y += h + gap;
    btnUndo = new UIButton(x, y, w, h, "(U)");
    y += h + gap;
    btnRedo = new UIButton(x, y, w, h, "(R)");
    y += h + gap;
    btnBlur = new UIButton(x, y, w, h, "(B)");
    y += h + gap;
    btnCon = new UIButton(x, y, w, h, "(Con)");
    y += h + gap;
    btnSharpen = new UIButton(x, y, w, h, "(Sharp)");
    y += h + gap;

    //初始化图层面板
    layerListPanel = new LayerListPanel(parent, doc, RightpanelX, RightpanelW, 0);

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

    rect(0, 0, LeftPannelW, height);
    
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
    if (active == null) {
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

    if (doc.layers.getActive() == null) {
      fill(255, 160, 160);
      text("No layer selected.", RightpanelX + 12, height - 95);
    } else {
      fill(180);
      Layer a = doc.layers.getActive();
      if (a.img != null) {
        text("Image: " + a.img.width + "x" + a.img.height, RightpanelX + 12, height - 95);
      } else {
        text("Text layer selected", RightpanelX + 12, height - 95);
      }
    }

    // layerListPanel.refresh(doc);我把这一行代码注释掉进行调试
    layerListPanel.updateLayout(RightpanelX, RightpanelW, height);
  }

  boolean handleMousePressed(App app, int mx, int my, int btn) {
    if (mx < RightpanelX && mx > LeftPannelW) return false;

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
    if (btnBlur.hit(mx, my)) {
      app.history.perform(app.doc,new AddFilterCommand(app.doc.layers.getActive(),new GaussianBlurFilter(5,10)));
      return true;
    }
    if( btnCon.hit(mx, my)) {
      app.history.perform(app.doc,new AddFilterCommand(app.doc.layers.getActive(),new ContrastFilter(1.5)));
      return true;
    }
    if( btnSharpen.hit(mx, my)) {
      app.history.perform(app.doc,new AddFilterCommand(app.doc.layers.getActive(),new SharpenFilter(1.0)));
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

  // *******File Opening*******
  void openFileDialog() {
    selectInput("Select an image", "fileSelected");
  }
  void exportCanvas() {
    selectOutput("Export canvas (PNG)", "exportSelected", defaultExportFile());
  }

  void createTextLayer() {
    TextLayer tl = new TextLayer("Text", "Arial", 48, doc.layers.getid());
    int index = doc.layers.indexOf(doc.layers.getActive()) + 1;
    tl.x = doc.viewW * 0.5 - tl.pivotX;
    tl.y = doc.viewH * 0.5 - tl.pivotY;
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

    // 同步对比度滑动条
    if (sliderContrast != null) {
      sliderContrast.setValue((int)(l.contrast * 100));
    }

    // 同步透明度滑动条：将 0.0-1.0 还原回 0-255
    sliderOpacity.setValue((int)(l.opacity * 255));

    // 同步锐度滑动条
    if (sliderSharpen != null){ 
      sliderSharpen.setValue((int)(l.sharp * 100));
    }

    // 同步文本相关控件  
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
    if (isUpdatingUI) return;
    Layer active = doc.layers.getActive();
    if (active == null) return;
    try {
      float nx = Float.parseFloat(fieldX.getText());
      float ny = Float.parseFloat(fieldY.getText());
      float ns = active.scale; // keep current scale
      float nr = active.rotation; // keep current rotation
        app.history.perform(doc, new TransformCommand(active, nx, ny,ns,nr));
    }
    catch (Exception e) {
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
    void handleContrastChange() {
    if (isUpdatingUI) return; // 避免同步 UI 时产生的副作用

    Layer active = doc.layers.getActive();
    if (active == null) return;
    
    // 计算新的对比度值 (0.0 到 2.0)
    float newVal = sliderContrast.getValue() / 100.0f;
    
    // 执行命令，这会触发 Layer.applyContrast 并标记 doc.markChanged()
    app.history.perform(doc, new ContrastCommand(active, newVal));
  }

  /*void handleSharpenChange() {
    if (isUpdatingUI) return;
    Layer active = doc.layers.getActive();
    if (active == null || active.originalImg == null) return;

    float val = sliderSharpen.getValue() / 100.0f;
    app.history.perform(doc, new SharpenCommand(active, val));
  }*/
  void setupPropertiesPanel(JPanel container) {
    // 属性：位置、透明度、文本、对比度、锐度
    propsPanel = new JPanel(new GridLayout(9, 2, 5, 5));
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

    // 锐度相关
    JLabel labelSharpen = new JLabel(" Sharpen:");
    labelSharpen.setForeground(Color.WHITE);
    sliderSharpen = new JSlider(0, 100, 0); 
    sliderSharpen.setBackground(new Color(60, 60, 60));
    sliderSharpen.addChangeListener(e -> {
    if (!sliderSharpen.getValueIsAdjusting()) {
      handleSharpenChange();
    }
  });
  /*
    // 对比度相关
    JLabel labelContrast = new JLabel(" Contrast:");
    labelContrast.setForeground(Color.WHITE);
    sliderContrast = new JSlider(0, 200, 100); // 默认为1.0，范围是 0.0 到 2.0
    sliderContrast.setBackground(new Color(60, 60, 60));
*/
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
    sliderContrast.addChangeListener(e -> {
    // 关键性能优化：只有在用户松开鼠标时，才触发耗时的像素计算
      if (!sliderContrast.getValueIsAdjusting()) {
        handleContrastChange();
      }
    });

    fieldText.addActionListener(e -> updateTextFromUI());
    comboFont.addActionListener(e -> updateFontNameFromUI());
    spinnerFontSize.addChangeListener(e -> updateFontSizeFromUI());

    propsPanel.add(labelX);
    propsPanel.add(fieldX);
    propsPanel.add(labelY);
    propsPanel.add(fieldY);
    propsPanel.add(labelOp);
    propsPanel.add(sliderOpacity);
    propsPanel.add(labelContrast);
    propsPanel.add(sliderContrast);
    propsPanel.add(labelSharpen);
    propsPanel.add(sliderSharpen);
    propsPanel.add(labelText);
    propsPanel.add(fieldText);
    propsPanel.add(labelFont);
    propsPanel.add(comboFont);
    propsPanel.add(labelSize);
    propsPanel.add(spinnerFontSize);

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




  // *******Exporting*******
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
