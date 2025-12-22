public class App {
  Document doc;
  Renderer renderer;
  ToolManager tools;
  CommandManager history;
  UI ui;


  
  /* 五大模块
    Doc：工程文件的唯一真实记录，
    Render：渲染器，从Doc中读取图层信息，显示出画布上的图像
    Tool startYstem：负责处理工具选择，记录连续操作的结果。将结果发送给CommandManager
    UI：基本节目图像，以及一些可以发送给CommandM的指令。
    CommandManger：管理Command记录，发出更改Doc的指令
   */
  App(PApplet parent) {
    this(parent, new Document());
  }

  App(PApplet parent, Document doc) {
    this.doc = doc != null ? doc : new Document();
    renderer = new Renderer();
    tools = new ToolManager();
    history = new CommandManager();
    ui = new UI(parent, this.doc, this);

    // Keep UI widgets in sync after any history change (perform/undo/redo).
    history.setListener(new CommandListener() {
      public void onHistoryChanged(Document d) {
        SwingUtilities.invokeLater(new Runnable() {
          public void run() {
            ui.updatePropertiesFromLayer(d.layers.getActive());
            ui.refreshLayerList(d);
          }
        });
      }
    });

    tools.setTool(new MoveTool()); // When you enter, defualtly choose MoveTool 默认移动工具
  }// 生成函数，新建五大模块


  /*void update() {
   // placeholder for future updates
  }*/
  void render() {
    renderer.drawChecker(doc,doc.viewW,doc.viewH,50);
    renderer.drawCanvas(doc, tools);
    renderer.drawToScreen(doc,tools);
    ui.draw(doc, tools, history);
  }//darw concavs and UI

  // ---------- event routing ----------

  //assign mouse and key event, give them to UI first of to Tool.
  void onMousePressed(int mx, int my, int btn) {
    if (ui.handleMousePressed(this, mx, my, btn)) return;
    tools.mousePressed(doc, mx, my, btn);
  }

  void onMouseDragged(int mx, int my, int btn) {
    if (ui.handleMouseDragged(this, mx, my, btn)) return;
    tools.mouseDragged(doc, mx, my, btn);

    // 同步坐标到UI的状态显示
    Layer active = doc.layers.getActive();
    if (active != null) {
      ui.updatePropertiesFromLayer(active);
    }
  }

  void onMouseReleased(int mx, int my, int btn) {
    if (ui.handleMouseReleased(this, mx, my, btn)) return;
    tools.mouseReleased(doc, mx, my, btn);
    ui.refreshLayerList(doc); // 在鼠标释放时刷新图层列表
  }

  void onMouseWheel(float delta) {
    if (ui.handleMouseWheel(this, delta)) return;
    tools.mouseWheel(doc, delta);
  }

  void onKeyPressed(char k) {
    boolean primary = keyEvent.isControlDown() || keyEvent.isMetaDown();
    boolean shift   = keyEvent.isShiftDown();
    boolean alt     = keyEvent.isAltDown();
    Component focus = KeyboardFocusManager.getCurrentKeyboardFocusManager().getFocusOwner();
    
  //Handle focus

    // When typing in a text field, ignore shortcuts.
    if(focus != null && (focus instanceof JTextComponent)) {
      return;
    }


    if (primary && (k=='z' || k=='Z')) {
      history.undo(doc);
      return;
    }
    if (primary && shift&&(k=='z' || k=='Z')) {
      history.redo(doc);
      return;
    }
    if (k=='o' || k=='O') {
      ui.openFileDialog();
      return;
    }
    if (ui != null && ui.layerListPanel != null && ui.layerListPanel.isFocusInside()) {
      return;
    }
    if (k=='m' || k=='M') {
      tools.setTool(new MoveTool());
      return;
    }
    if (k=='c' || k=='C') {
      tools.setTool(new CropTool(history));
      return;
    }
    if (k=='e' || k=='E') {
      ui.exportCanvas();
      return;
    }
    if (k=='r' || k=='R') {
      tools.setTool(new RotateTool(history));
      return;
    }
  
    if (k=='s' || k=='S') {
        tools.setTool(new ScaleTool(history));
        return;
    }
    /*for test only
    if(k=='b' || k=='B') {
      Layer l= doc.layers.getActive();
      l.filters.add(new GaussianBlurFilter(5, 5));
      return;
    }
    if(k=='c' || k=='C') {
      Layer l= doc.layers.getActive();
      l.filters.add(new ContrastFilter(1.2));
      return;
    }
    if(k=='h' || k=='H') {
      Layer l= doc.layers.getActive();
      l.filters.add(new SharpenFilter(1.0));
      return;
    }*/
  }
}

