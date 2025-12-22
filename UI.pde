import java.text.SimpleDateFormat;
import java.util.Date;

class UI {
  App app;



  PApplet parent;
  Document doc;

  int RightpanelW = 340;
  int RightpanelX = width-RightpanelW;
  int LeftPannelW = 80;

  File lastExportDir;

  UIButton btnOpen, btnMove, btnCrop, btnText, btnExport, btnUndo, btnRedo, btnBlur, btnCon, btnSharpen;
  LayerListPanel layerListPanel;


  PropertiesPanel propertiesPanel;

  UI(PApplet parent, Document doc, App app) {
    this.parent = parent;
    this.doc = doc;
    this.app = app;

    int x = 12;
    int y = 20;
    int w = LeftPannelW - 24;
    int h = 28;
    int gap = 10;

    btnOpen = new UIButton(x, y, w, h, "Open");
    y += h + gap;
    btnMove = new UIButton(x, y, w, h, "Move");
    y += h + gap;
    btnCrop = new UIButton(x, y, w, h, "Crop");
    y += h + gap;
    btnText = new UIButton(x, y, w, h, "Text");
    y += h + gap;
    btnExport = new UIButton(x, y, w, h, "Export");
    y += h + gap;
    btnUndo = new UIButton(x, y, w, h, "Undo");
    y += h + gap;
    btnRedo = new UIButton(x, y, w, h, "Redo");
    y += h + gap;
    btnBlur = new UIButton(x, y, w, h, "Blur");
    y += h + gap;
    btnCon = new UIButton(x, y, w, h, "Contrast");
    y += h + gap;
    btnSharpen = new UIButton(x, y, w, h, "Sharp");
    y += h + gap;

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

    rect(0, 0, LeftPannelW, height);
    
    // buttons
    btnOpen.draw(false);
    btnMove.draw("Move".equals(tools.activeName()));
    btnCrop.draw("Crop".equals(tools.activeName()));
    btnText.draw("Text".equals(tools.activeName())); // text tool shares active name slot
    btnExport.draw(false);
    btnUndo.draw(false);
    btnRedo.draw(false);
    btnBlur.draw(false);
    btnCon.draw(false);
    btnSharpen.draw(false);

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
      if( app.doc == null ) {
        return true;
      }
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
      if( app.doc.layers.getActive() == null ) {
        return true;
      }
      app.history.perform(app.doc,new AddFilterCommand(app.doc.layers.getActive(),new GaussianBlurFilter(5,10)));
      updatePropertiesFromLayer(app.doc.layers.getActive());
      return true;
    }
    if( btnCon.hit(mx, my)) {
      if( app.doc.layers.getActive() == null ) {
        return true;
      }
      app.history.perform(app.doc,new AddFilterCommand(app.doc.layers.getActive(),new ContrastFilter(1.5)));
      updatePropertiesFromLayer(app.doc.layers.getActive());
      return true;
    }
    if( btnSharpen.hit(mx, my)) {
      if( app.doc.layers.getActive() == null ) {
        return true;
      }
      app.history.perform(app.doc,new AddFilterCommand(app.doc.layers.getActive(),new SharpenFilter(1.0)));
      updatePropertiesFromLayer(app.doc.layers.getActive());
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
    refreshLayerList(doc);
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
