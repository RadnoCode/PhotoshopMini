class UI {
  PApplet parent;
  Document doc;
  
  int RightpanelW = 270;
  int RightpanelX =width-RightpanelW;
  int LeftPannelW=64;


  UIButton btnOpen, btnMove, btnCrop, btnUndo, btnRedo;
  LayerListPanel layerListPanel;

  UI(PApplet parent, Document doc) {
    this.parent = parent;
    this.doc = doc;
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

    layerListPanel = new LayerListPanel(parent, doc, RightpanelX, RightpanelW, y);
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

    layerListPanel.refresh(doc);
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

    // set doc content
    Layer l=new Layer(img);
    l.name = "Layer " + (doc.layers.list.size() + 1);
    doc.layers.list.add(l);
    doc.layers.activeIndex=doc.layers.indexOf(l);

    // reset view (optional)
    doc.view.zoom = 1.0;
    doc.view.panX = 80;
    doc.view.panY = 50;

    doc.renderFlags.dirtyComposite = true;
    layerListPanel.refresh(doc);
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

class LayerListPanel {
  PApplet parent;
  Document doc;
  int rightPanelX;
  int panelWidth;
  int topY;

  DefaultListModel<String> model = new DefaultListModel<String>();
  JList<String> list = new JList<String>(model);
  JScrollPane scrollPane;
  JButton addButton = new JButton("+");
  JPanel container = new JPanel(new BorderLayout(6, 6));

  LayerListPanel(PApplet parent, Document doc, int rightPanelX, int panelWidth, int topY) {
    this.parent = parent;
    this.doc = doc;
    this.rightPanelX = rightPanelX;
    this.panelWidth = panelWidth;
    this.topY = topY;

    configureList();
    configureHeader();
    attachToFrame();
    refresh(doc);
  }

  void configureList() {
    list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    list.setDragEnabled(true);
    list.setDropMode(DropMode.INSERT);
    list.setTransferHandler(new ReorderHandler());
    list.setBackground(new Color(55, 55, 55));
    list.setForeground(Color.WHITE);
    list.setBorder(BorderFactory.createEmptyBorder(4, 6, 4, 6));
    list.addListSelectionListener(new ListSelectionListener() {
      public void valueChanged(ListSelectionEvent e) {
        if (!e.getValueIsAdjusting()) {
          doc.layers.activeIndex = list.getSelectedIndex();
        }
      }
    });
    list.addKeyListener(new KeyAdapter() {
      public void keyPressed(processing.event.KeyEvent e) {
        if (e.getKeyCode() == java.awt.event.KeyEvent.VK_DELETE) {
          deleteSelectedLayer();
        }
      }
    });

    scrollPane = new JScrollPane(list);
    scrollPane.setBorder(BorderFactory.createLineBorder(new Color(70, 70, 70)));
    scrollPane.getViewport().setBackground(new Color(45, 45, 45));
    scrollPane.setBackground(new Color(45, 45, 45));
  }

  void configureHeader() {
    JPanel header = new JPanel(new BorderLayout());
    header.setOpaque(false);
    JLabel label = new JLabel("Layers");
    label.setForeground(Color.WHITE);

    addButton.setMargin(new Insets(2, 8, 2, 8));
    addButton.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent e) {
        addBlankLayer();
      }
    });

    header.add(label, BorderLayout.WEST);
    header.add(addButton, BorderLayout.EAST);

    container.setOpaque(false);
    container.add(header, BorderLayout.NORTH);
    container.add(scrollPane, BorderLayout.CENTER);
  }

  void attachToFrame() {
    PSurfaceAWT surf = (PSurfaceAWT) parent.getSurface();
    PSurfaceAWT.SmoothCanvas canvas = (PSurfaceAWT.SmoothCanvas) surf.getNative();
    JFrame frame = (JFrame) canvas.getFrame();
    frame.getLayeredPane().add(container, JLayeredPane.PALETTE_LAYER);
    frame.getLayeredPane().setLayout(null);
  }

  void updateLayout(int rightPanelX, int panelWidth, int parentHeight) {
    this.rightPanelX = rightPanelX;
    this.panelWidth = panelWidth;
    int margin = 10;
    int availableHeight = Math.max(120, parentHeight - topY - 30);
    container.setBounds(rightPanelX + margin, topY, panelWidth - margin * 2, availableHeight);
    container.revalidate();
  }

  void refresh(Document updatedDoc) {
    this.doc = updatedDoc;
    while (model.getSize() > updatedDoc.layers.list.size()) {
      model.remove(model.getSize() - 1);
    }
    for (int i = 0; i < updatedDoc.layers.list.size(); i++) {
      String name = updatedDoc.layers.list.get(i).name;
      if (i < model.getSize()) {
        if (!model.get(i).equals(name)) model.set(i, name);
      } else {
        model.addElement(name);
      }
    }

    int active = updatedDoc.layers.activeIndex;
    if (active >= 0 && active < model.getSize()) {
      list.setSelectedIndex(active);
    } else {
      list.clearSelection();
    }
  }

  void addBlankLayer() {
    PImage blank = parent.createImage(doc.canvas.w, doc.canvas.h, ARGB);
    blank.loadPixels();
    for (int i = 0; i < blank.pixels.length; i++) blank.pixels[i] = parent.color(0, 0, 0, 0);
    blank.updatePixels();
    Layer newLayer = new Layer(blank);
    newLayer.name = "Layer " + (doc.layers.list.size() + 1);
    doc.layers.insertAt(doc.layers.list.size(), newLayer);
    doc.renderFlags.dirtyComposite = true;
    refresh(doc);
  }

  void deleteSelectedLayer() {
    int idx = list.getSelectedIndex();
    if (idx >= 0) {
      doc.layers.removeAt(idx);
      doc.renderFlags.dirtyComposite = true;
      refresh(doc);
    }
  }

  class ReorderHandler extends TransferHandler {
    int sourceIndex = -1;

    public int getSourceActions(JComponent c) {
      return MOVE;
    }

    protected Transferable createTransferable(JComponent c) {
      sourceIndex = list.getSelectedIndex();
      return new StringSelection(list.getSelectedValue());
    }

    public boolean canImport(TransferSupport support) {
      return support.isDrop();
    }

    public boolean importData(TransferSupport support) {
      if (!support.isDrop()) return false;
      JList.DropLocation dl = (JList.DropLocation) support.getDropLocation();
      int target = dl.getIndex();
      if (sourceIndex < 0 || target == sourceIndex) return false;

      doc.layers.move(sourceIndex, target);
      doc.renderFlags.dirtyComposite = true;
      refresh(doc);
      list.setSelectedIndex(target);
      return true;
    }
  }
}