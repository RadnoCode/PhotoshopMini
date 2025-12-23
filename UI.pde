import java.text.SimpleDateFormat;
import java.util.Date;

class UI {
  App app;
  PApplet parent;
  Document doc;

  int RightpanelW = 340;
  int RightpanelX = width-RightpanelW;
  int LeftPannelW = 64;
  JPanel toolPanel;
  ArrayList<JButton> toolButtons = new ArrayList<JButton>();

  File lastExportDir;

  LayerListPanel layerListPanel;


  PropertiesPanel propertiesPanel;

  UI(PApplet parent, Document doc, App app) {
    this.parent = parent;
    this.doc = doc;
    this.app = app;

    buildToolPanel();

    //初始化图层面板
    layerListPanel = new LayerListPanel(parent, doc, RightpanelX, RightpanelW, 0);

    // 初始化属性面板（多标签页）
    propertiesPanel = new PropertiesPanel(parent, doc, app, this.layerListPanel.container);

    // 默认导出目录：优先桌面，找不到则放到工程目录下的 exports
    lastExportDir = new File(System.getProperty("user.home"), "Desktop");
    if (!lastExportDir.exists() || !lastExportDir.isDirectory()) {
      lastExportDir = new File(parent.sketchPath("exports"));
      lastExportDir.mkdirs();
    }
  }

  void draw(Document doc, ToolManager tools, CommandManager history) {
    RightpanelX = width - RightpanelW;
    updateToolPanelLayout(height);

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
      if (propertiesPanel != null) propertiesPanel.setVisible(false);
      // 可以在原本显示属性的地方画一些提示文字
      fill(100);
      textSize(12);
      text("Select a layer to edit properties", RightpanelX + 12, layerListPanel.topY - 20);
    } else {
      if (propertiesPanel != null) {
        propertiesPanel.setVisible(true);
      }
    }
    if (propertiesPanel != null) {
      propertiesPanel.setPreferredHeight(height / 2);
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
    layerListPanel.updateLayout(RightpanelX, RightpanelW, height);
  }

  ImageIcon loadIcon(String file) {
    return loadIcon(file, 26);
  }

  ImageIcon loadIcon(String file, int targetSize) {
    String path="icon/" + file + ".png";

      PImage p = loadImage(path);
      if (p != null) {
        PImage scaled = scaleIcon(p, targetSize);
        return new ImageIcon((Image) scaled.getNative());
      }
    println("Icon missing for: " + file + " (looked in data/icon/)");
    return null;
  }

  // Keep icons within the toolbar width.
  PImage scaleIcon(PImage src, int target) {
    if (src == null) return null;
    PImage copy = src.get();
    int maxSide = max(copy.width, copy.height);
    if (maxSide == 0) return copy;
    float scale = target / (float) maxSide; // can upscale to fill the button
    int w = max(1, round(copy.width * scale));
    int h = max(1, round(copy.height * scale));
    copy.resize(w, h);
    return copy;
  }

  void addDivider(JPanel panel) {
  panel.add(Box.createVerticalStrut(8));

  JPanel line = new JPanel();
  line.setMaximumSize(new Dimension(Integer.MAX_VALUE, 1));
  line.setPreferredSize(new Dimension(1, 1));
  line.setBackground(new Color(255,255,255,25));
  line.setOpaque(true);

  panel.add(line);
  panel.add(Box.createVerticalStrut(8));
}

  void buildToolPanel() {
    toolPanel = new JPanel();
    toolPanel.setLayout(new BoxLayout(toolPanel, BoxLayout.Y_AXIS));
    toolPanel.setOpaque(true);
    toolPanel.setBackground(new Color(60, 60, 60)); // match app dark background
    toolPanel.setBorder(BorderFactory.createEmptyBorder(16, 0, 0, 0)); // remove padding gap

    addToolButton("import", "Import an image", () -> openFileDialog());
    addToolButton("export", "Export canvas (E)", () -> exportCanvas());
    
    addDivider(toolPanel);
    addToolButton("hand", "Hand tool to move whole canvas(M)", () -> app.tools.setTool(new MoveTool()));
    addToolButton("crop", "Crop tool (C)", () -> app.tools.setTool(new CropTool(app.history)));
    addToolButton("rotate", "Rotate tool (R)", () -> app.tools.setTool(new RotateTool(app.history)));
    addToolButton("scale", "Scale tool (S)", () -> app.tools.setTool(new ScaleTool(app.history)));
    addToolButton("text", "Create a text layer", () -> createTextLayer());
    
    addDivider(toolPanel);
    addToolButton("undo", "Undo (Ctrl/Cmd+Z)", () -> app.history.undo(app.doc));
    addToolButton("redo", "Redo (Ctrl/Cmd+Shift+Z)", () -> app.history.redo(app.doc));
    
    addDivider(toolPanel);
    addToolButton("blur", "Add Gaussian Blur filter", () -> {
      Layer active = app.doc.layers.getActive();
      if (active == null) return;
      app.history.perform(app.doc, new AddFilterCommand(active, new GaussianBlurFilter(5, 10)));
      updatePropertiesFromLayer(active);
    });
    addToolButton("contrast", "Add Contrast filter", () -> {
      Layer active = app.doc.layers.getActive();
      if (active == null) return;
      app.history.perform(app.doc, new AddFilterCommand(active, new ContrastFilter(1.5)));
      updatePropertiesFromLayer(active);
    });
    addToolButton("sharp", "Add Sharpen filter", () -> {
      Layer active = app.doc.layers.getActive();
      if (active == null) return;
      app.history.perform(app.doc, new AddFilterCommand(active, new SharpenFilter(1.0)));
      updatePropertiesFromLayer(active);
    });

    attachToolPanelToFrame();
  }

  void addToolButton(String iconFile, String tooltip, Runnable action) {
    
    int btnWidth = max(60, LeftPannelW - 8);
    int btnHeight = 40;
    int iconTarget = max(16, min(btnWidth, btnHeight) - 4); // fill button while keeping square

    ImageIcon icon = loadIcon(iconFile, iconTarget);
    String label = iconFile.length() > 0 ? iconFile.substring(0,1).toUpperCase() + iconFile.substring(1) : "";
    JButton btn = new JButton(icon);

    btn.setBorderPainted(false);
    btn.setFocusPainted(false);
    btn.setContentAreaFilled(false); 
    btn.setOpaque(false);  
    if (icon == null) btn.setText(label);
    else btn.setText(""); // icon-only when available
    btn.setHorizontalTextPosition(SwingConstants.CENTER);
    btn.setVerticalTextPosition(SwingConstants.CENTER);
    btn.setToolTipText(tooltip);
    btn.setAlignmentX(Component.CENTER_ALIGNMENT);
    Dimension fixed = new Dimension(btnWidth, btnHeight);
    btn.setMaximumSize(fixed);
    btn.setPreferredSize(fixed);
    btn.setMinimumSize(fixed);
    btn.setFocusable(false);
    btn.addActionListener(e -> action.run());
    btn.setBackground(new Color(80, 80, 80));
    btn.setForeground(Color.WHITE);
    btn.setBorder(BorderFactory.createLineBorder(new Color(100, 100, 100)));
    toolPanel.add(btn);
    toolPanel.add(Box.createVerticalStrut(6));
    toolButtons.add(btn);
  }

  void attachToolPanelToFrame() {
    PSurfaceAWT surf = (PSurfaceAWT) parent.getSurface();
    PSurfaceAWT.SmoothCanvas canvas = (PSurfaceAWT.SmoothCanvas) surf.getNative();
    JFrame frame = (JFrame) canvas.getFrame();
    frame.getLayeredPane().add(toolPanel, JLayeredPane.PALETTE_LAYER);
    frame.getLayeredPane().setLayout(null);
  }

  void updateToolPanelLayout(int parentHeight) {
    if (toolPanel == null) return;
    int margin = 0;
    int w = max(60, LeftPannelW - margin * 2);
    toolPanel.setBounds(margin, 0, w, parentHeight);
    toolPanel.revalidate();
  }

  boolean handleMousePressed(App app, int mx, int my, int btn) {
    // Swing toolbar + right panel consume clicks; canvas area goes to tools.
    if (mx < LeftPannelW || mx >= RightpanelX) return true;
    return false;
  }

  boolean handleMouseDragged(App app, int mx, int my, int btn) {
    return (mx >= RightpanelX || mx < LeftPannelW);
  }
  boolean handleMouseReleased(App app, int mx, int my, int btn) {
    return (mx >= RightpanelX || mx < LeftPannelW);
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
    refreshLayerList(doc);
    updatePropertiesFromLayer(tl);
  }

  void onFileSelected(Document doc, File selection) {
    if (selection == null) return;
    PImage img = loadImage(selection.getAbsolutePath());
    if (img == null) return;

    Layer active = doc.layers.getActive();
    boolean canReuseActive = active != null && active.types!="Text" && active.empty;

    if (canReuseActive) {
      active.img = img;
      active.processedImg = img.get();
      active.out = img.get();
      active.filterdirty = true;
      active.empty=false;
      active.visible = true;
      active.x = 0;
      active.y = 0;
      active.rotation = 0;
      active.scale = 1.0;
      active.pivotX = img.width * 0.5;
      active.pivotY = img.height * 0.5;
      active.invalidateThumbnail();
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
    refreshLayerList(doc);
    updatePropertiesFromLayer(doc.layers.getActive());
  }



  void updatePropertiesFromLayer(Layer l) {
    if (propertiesPanel == null) return;
    Runnable task = new Runnable() {
      public void run() {
        propertiesPanel.updateFromLayer(l);
      }
    };
    if (SwingUtilities.isEventDispatchThread()) task.run();
    else SwingUtilities.invokeLater(task);
  }

  void refreshLayerList(Document d) {
    if (layerListPanel == null) return;
    Runnable task = new Runnable() {
      public void run() {
        layerListPanel.refresh(d);
      }
    };
    if (SwingUtilities.isEventDispatchThread()) task.run();
    else SwingUtilities.invokeLater(task);
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
