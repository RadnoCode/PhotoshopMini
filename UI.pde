import java.text.SimpleDateFormat;
import java.util.Date;
import com.formdev.flatlaf.extras.FlatSVGIcon;



class UI {
  App app;
  PApplet parent;
  Document doc;

  int RightpanelW = 300;
  int RightpanelX = width-RightpanelW;
  int LeftPannelW = 48;
  int filterPanelMaxW = 48;
  JPanel toolPanel;
  JPanel filterPanel;
  JButton filterButton;
  boolean filterPanelVisible = false;
  ArrayList<JButton> toolButtons = new ArrayList<JButton>();
  HashMap<String, JButton> toolButtonsByKey = new HashMap<String, JButton>();
  Color toolColorNormal = new Color(60, 60, 60);
  Color toolColorActive = new Color(90, 140, 220);

  File lastExportDir;

  LayerListPanel layerListPanel;


  PropertiesPanel propertiesPanel;
  UI(PApplet parent, Document doc, App app) {
    this.parent = parent;
    this.doc = doc;
    this.app = app;
    buildToolPanel();
    layerListPanel = new LayerListPanel(parent, doc, RightpanelX, RightpanelW, 0);
    propertiesPanel = new PropertiesPanel(parent, doc, app, this.layerListPanel.container);
    lastExportDir = new File(System.getProperty("user.home"), "Desktop");
    if (!lastExportDir.exists() || !lastExportDir.isDirectory()) {
      lastExportDir = new File(parent.sketchPath("exports"));
      lastExportDir.mkdirs();
    }
  }

  void draw(Document doc, ToolManager tools, CommandManager history) {
    RightpanelX = width - RightpanelW;
    updateToolPanelLayout(height);
    highlightActiveTool(tools.activeName());

    // statu
    fill(230);
    textSize(12);
    text("Active Tool: " + tools.activeName(), RightpanelX + 12, height - 70);
    text("X-axis: " + /*history.undoCount()*/mouseX, RightpanelX + 12, height - 50);
    text("Y-axis: " + /*history.redoCount()*/mouseY, RightpanelX + 12, height - 30);
    Layer active = doc.layers.getActive();
    if (active == null) {
      if (propertiesPanel != null) propertiesPanel.setVisible(false);
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


  // ----- Icon loading -----
  Icon loadIcon(String file) {
    return loadIcon(file, 26);
  }

  Icon loadIcon(String file, int targetSize) {
    // Prefer SVG for crisp scaling to the exact button size.
    Icon svgIcon = loadSvgIcon(file, targetSize);
    if (svgIcon != null) return svgIcon;

    // PNG fallback from data/icon.
    PImage p = loadImage("icon/" + file + ".png");
    if (p != null) {
      PImage scaled = scaleIcon(p, targetSize);
      return new ImageIcon((java.awt.Image) scaled.getNative());
    }

    println("Icon missing for: " + file + " (expected in data/icon/ as .svg or .png)");
    return null;
  }

  Icon loadSvgIcon(String file, int targetSize) {
    try {
      File svgFile = new File(parent.sketchPath("data/icon/" + file + ".svg"));
      if (!svgFile.exists()) return null;
      FlatSVGIcon base = new FlatSVGIcon(svgFile.toURI().toURL());
      return base.derive(targetSize, targetSize);
    } catch (Exception e) {
      println("Failed to load SVG icon for " + file + ": " + e.getMessage());
      return null;
    }
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

  int SizeFirst=32,SizeSecond=24;
  void addDivider(JPanel panel) {
    panel.add(Box.createVerticalStrut(8));

    JPanel line = new JPanel();
    line.setMaximumSize(new Dimension(Integer.MAX_VALUE, 2));
    line.setPreferredSize(new Dimension(1, 1));
    line.setBackground(new Color(255,255,255,25));
    line.setOpaque(true);

    panel.add(line);
    panel.add(Box.createVerticalStrut(8));
}
  JButton addToolButton(JPanel targetPanel, String iconFile, String tooltip, Runnable action,int size) {
    int btnWidth = (targetPanel == toolPanel)
      ? LeftPannelW
      : (targetPanel == filterPanel ? filterPanelMaxW : 20);
    int btnHeight = size+10;
    int iconTarget =size; 
    Icon icon = loadIcon(iconFile, iconTarget);
    String label = iconFile.length() > 0 ? iconFile.substring(0, 1).toUpperCase() + iconFile.substring(1): "";
    JButton btn = new JButton();
    // --- icon / text  ---
    if (icon != null) {
      btn.setIcon(icon);
      btn.setText("");
    } else {
      btn.setIcon(null);
      btn.setText(label);
      btn.setFont(btn.getFont().deriveFont(Font.BOLD, 13f));
    }
    btn.putClientProperty("JButton.buttonType", "toolBarButton");
    btn.setFocusPainted(false);
    btn.setFocusable(false);
    btn.setRolloverEnabled(true);
    if (icon == null) btn.setText(label);
    else btn.setText("");
    btn.setToolTipText(tooltip);
    btn.setHorizontalAlignment(SwingConstants.CENTER);
    btn.setVerticalAlignment(SwingConstants.CENTER);
    Dimension fixed = new Dimension(btnWidth, btnHeight);
    btn.setMaximumSize(fixed);
    btn.setPreferredSize(fixed);
    btn.setMinimumSize(fixed);
    btn.addActionListener(e -> action.run());
    
    targetPanel.add(btn);
    targetPanel.add(Box.createVerticalStrut(6));
    toolButtons.add(btn);
    return btn;
}

  void registerToolButton(String key, JButton btn) {
    if (btn == null || key == null) return;
    toolButtonsByKey.put(key.toLowerCase(), btn);
  }

  void buildToolPanel() {
    toolPanel = new JPanel();
    toolPanel.setLayout(new BoxLayout(toolPanel, BoxLayout.Y_AXIS));
    toolPanel.setOpaque(true);
    toolPanel.setBackground(new Color(60, 60, 60)); // match app dark background
    toolPanel.setBorder(BorderFactory.createEmptyBorder(16, 0, 0, 4)); // remove padding gap

    addToolButton(toolPanel,"import", "Import image(O)", () -> openFileDialog(),SizeFirst);
    addToolButton(toolPanel,"export", "Export canvas (E)", () -> exportCanvas(),SizeFirst);
    
    addDivider(toolPanel);
    registerToolButton("hand", addToolButton(toolPanel,"hand", "Hand Tool (H)\nUse hand to move whole canvas", () -> app.tools.setTool(new MoveTool()),SizeFirst));
    registerToolButton("move", addToolButton(toolPanel, "move", "Move Tool(M)\nUse move to move layer's position (V)", () -> app.tools.setTool(new LayerMoveTool(app.history)),SizeFirst));
    registerToolButton("crop", addToolButton(toolPanel, "crop", "Crop Tool (C)\nCrop the whole canvas", () -> app.tools.setTool(new CropTool(app.history)),SizeFirst));
    registerToolButton("rotate", addToolButton(toolPanel, "rotate", "Rotate Tool (R)\nRotate the layer", () -> app.tools.setTool(new RotateTool(app.history)),SizeFirst));
    registerToolButton("scale", addToolButton(toolPanel, "scale", "Scale tool (S)\nScale the layer", () -> app.tools.setTool(new ScaleTool(app.history)),SizeFirst));
    
    
    addDivider(toolPanel);
    addToolButton(toolPanel,"undo", "Undo (Ctrl/Cmd+Z)", () -> app.history.undo(app.doc),SizeFirst);
    addToolButton(toolPanel,"redo", "Redo (Ctrl/Cmd+Y)", () -> app.history.redo(app.doc),SizeFirst);

    addDivider(toolPanel);
    filterButton = addToolButton(toolPanel,"filter", "Filters Tool\nClick to chose a filter added to selected layer.Adjust filter in filter panel", () -> toggleFilterPanel(),SizeFirst);
    addToolButton(toolPanel, "text", "Text tool(T)\nCreate a text layer. Edit it in properties panel", () -> createTextLayer(),SizeFirst);
    buildFilterPanel();

    attachToolPanelToFrame();
  }
  



  void buildFilterPanel() {
    filterPanel = new JPanel();
    filterPanel.setLayout(new BoxLayout(filterPanel, BoxLayout.Y_AXIS));
    filterPanel.setBackground(new Color(70, 70, 70));
    filterPanel.setBorder(BorderFactory.createCompoundBorder(
      BorderFactory.createLineBorder(new Color(100, 100, 100)),
      BorderFactory.createEmptyBorder(6, 4, 6, 4)
    ));
    filterPanel.setMaximumSize(new Dimension(filterPanelMaxW, Integer.MAX_VALUE));
    
    

    addToolButton(filterPanel,"blur", "Add Gaussian Blur filter", () -> {applyFilter(new GaussianBlurFilter(5,5));filterPanelVisible=false;},SizeSecond);
    addToolButton(filterPanel,"contrast", "Add Contrast filter", () -> {applyFilter(new ContrastFilter(1.5));filterPanelVisible=false;},SizeSecond);
    addToolButton(filterPanel,"sharpen", "Add Sharpen filter", () -> {applyFilter(new SharpenFilter(1.0));filterPanelVisible=false;},SizeSecond);

    int clampW = filterPanelMaxW;
    Dimension pref = filterPanel.getPreferredSize();
    filterPanel.setPreferredSize(new Dimension(clampW, pref.height));
    filterPanel.setMinimumSize(new Dimension(clampW, 0));
    filterPanel.setMaximumSize(new Dimension(clampW, Integer.MAX_VALUE));

    filterPanel.setVisible(false);
  }


  void highlightActiveTool(String activeName) {
    if (toolButtonsByKey.isEmpty()) return;
    String key = mapToolKey(activeName);
    for (String k : toolButtonsByKey.keySet()) {
      JButton btn = toolButtonsByKey.get(k);
      if (btn == null) continue;
      boolean active = k.equals(key);
      btn.setBackground(active ? toolColorActive : toolColorNormal);
      btn.setOpaque(true);
      btn.setBorderPainted(active);
    }
  }

  String mapToolKey(String activeName) {
    if (activeName == null) return "";
    String k = activeName.toLowerCase();
    if (k.equals("move")) return "hand";       // MoveTool
    if (k.equals("layermove")) return "move";  // LayerMoveTool
    return k;
  }



  void toggleFilterPanel() {
    setFilterPanelVisible(!filterPanelVisible);
  }

  void setFilterPanelVisible(boolean visible) {
    filterPanelVisible = visible;
    if (filterPanel != null) {
      filterPanel.setVisible(visible);
      filterPanel.revalidate();
    }
  }

  void applyFilter(Filter filter) {
    Layer active = app.doc.layers.getActive();
    if (active == null) return;
    app.history.perform(app.doc, new AddFilterCommand(active, filter));
    updatePropertiesFromLayer(active);
    setFilterPanelVisible(false);
  }

  void attachToolPanelToFrame() {
    PSurfaceAWT surf = (PSurfaceAWT) parent.getSurface();
    PSurfaceAWT.SmoothCanvas canvas = (PSurfaceAWT.SmoothCanvas) surf.getNative();
    JFrame frame = (JFrame) canvas.getFrame();
    frame.getLayeredPane().add(toolPanel, JLayeredPane.PALETTE_LAYER);
    if (filterPanel != null) {
      frame.getLayeredPane().add(filterPanel, JLayeredPane.PALETTE_LAYER);
    }
    frame.getLayeredPane().setLayout(null);
  }

  void updateToolPanelLayout(int parentHeight) {
    if (toolPanel == null) return;
    int margin = 0;
    int w = LeftPannelW;
    toolPanel.setBounds(margin, 0, w, parentHeight);
    toolPanel.doLayout();

    if (filterPanel != null && filterButton != null) {
      int gap = 6;
      int filterX = margin + w + gap;
      int filterY = filterButton.getY();
      Dimension pref = filterPanel.getPreferredSize();
      int filterW = filterPanelMaxW;
      filterPanel.setBounds(filterX, filterY, filterW, pref.height);
      filterPanel.revalidate();
    }
    toolPanel.revalidate();
  }

  boolean handleMousePressed(App app, int mx, int my, int btn) {
    // Swing toolbar + right panel consume clicks; canvas area goes to tools.
    if (mx < LeftPannelW || mx >= RightpanelX || inFilterPanel(mx, my)) return true;
    return false;
  }

  boolean handleMouseDragged(App app, int mx, int my, int btn) {
    return (mx >= RightpanelX || mx < LeftPannelW || inFilterPanel(mx, my));
  }
  boolean handleMouseReleased(App app, int mx, int my, int btn) {
    return (mx >= RightpanelX || mx < LeftPannelW || inFilterPanel(mx, my));
  }
  boolean handleMouseWheel(App app, float delta) {
    return false;
  }

  boolean inFilterPanel(int mx, int my) {
    if (filterPanel == null || !filterPanelVisible) return false;
    Rectangle r = filterPanel.getBounds();
    return mx >= r.x && mx <= r.x + r.width && my >= r.y && my <= r.y + r.height;
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
      "Successfully export to\n" + path,
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
