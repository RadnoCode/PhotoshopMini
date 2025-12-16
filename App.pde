class App {
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


  App() {
    doc = new Document();
    renderer = new Renderer();
    tools = new ToolManager();
    history = new CommandManager();
    ui = new UI();

    tools.setTool(new MoveTool()); // When you enter, defualtly choose MoveTool 默认移动工具
  }// 生成函数，新建五大模块


  /*void update() {
   // placeholder for future updates
   }*/

  void render() {
    renderer.draw(doc, tools);
    ui.draw(doc, tools, history);
  }//画图和UI

  // ---------- event routing ----------

  //assign mouse and key event, give them to UI first of to Tool.
  void onMousePressed(int mx, int my, int btn) {
    if (ui.handleMousePressed(this, mx, my, btn)) return;
    tools.mousePressed(doc, mx, my, btn);
  }

  void onMouseDragged(int mx, int my, int btn) {
    if (ui.handleMouseDragged(this, mx, my, btn)) return;
    tools.mouseDragged(doc, mx, my, btn);
  }

  void onMouseReleased(int mx, int my, int btn) {
    if (ui.handleMouseReleased(this, mx, my, btn)) return;
    tools.mouseReleased(doc, mx, my, btn);
  }

  void onMouseWheel(float delta) {
    if (ui.handleMouseWheel(this, delta)) return;
    tools.mouseWheel(doc, delta);
  }

  void onKeyPressed(char k) {
    boolean ctrl = (keyEvent.isMetaDown() || keyEvent.isControlDown());

    if (ctrl && (k=='z' || k=='Z')) {
      history.undo(doc);
      return;
    }
    if (ctrl && (k=='y' || k=='Y')) {
      history.redo(doc);
      return;
    }

    if (k=='o' || k=='O') {
      ui.openFileDialog();
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
    if (k=='r' || k=='R') {
      tools.setTool(new RotateTool(history));
      return;
    }
  
    if (k=='s' || k=='S') {
        tools.setTool(new ScaleTool(history));
        return;
    }
  }
}

class CanvasSpec {// Canvas Statement
  int w, h;
  CanvasSpec(int w, int h) {
    this.w = w;
    this.h = h;
  }
}