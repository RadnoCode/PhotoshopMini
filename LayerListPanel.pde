class LayerListPanel {
  PApplet parent;
  Document doc;
  int rightPanelX;
  int panelWidth;
  int topY;
  boolean isRefreshing = false;

  DefaultListModel<Layer> model = new DefaultListModel<Layer>();
  JList<Layer> list = new JList<Layer>(model);
  JScrollPane scrollPane;
  JButton addButton = new JButton("+");
  JPanel container = new JPanel(new BorderLayout(6, 6));

  final int EYE_W = 28;

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

    list.setCellRenderer(new LayerCellRenderer(EYE_W));

    list.setDragEnabled(true);
    list.setDropMode(DropMode.INSERT);
    list.setAutoscrolls(true);
    list.setTransferHandler(new ReorderHandler());
    list.setBackground(new Color(55, 55, 55));
    list.setForeground(Color.WHITE);
    list.setBorder(BorderFactory.createEmptyBorder(4, 6, 4, 6));
    list.addListSelectionListener(e -> {
      if (isRefreshing || e.getValueIsAdjusting()) return;
      int idx = list.getSelectedIndex();
      int docIdx = viewToDocIndex(idx);
      doc.layers.activeIndex = docIdx;
    });
  
    
    // 鼠标：点眼睛 toggle；双击名字 rename
    list.addMouseListener(new MouseAdapter() {
      public void mousePressed(java.awt.event.MouseEvent e) {
        int idx = list.locationToIndex(e.getPoint());
        if (idx < 0) return;

        Rectangle cell = list.getCellBounds(idx, idx);
        int localX = e.getX() - cell.x;

        Layer layer = model.getElementAt(idx);

        //点击眼睛区域
        if (localX >= 0 && localX <= EYE_W) {
          app.history.perform(doc, new ToggleVisibleCommand(layer));
          list.repaint();
          return;
        }

        // double click to rename
        if (e.getClickCount() == 2) {
          String newName = JOptionPane.showInputDialog(container, "Rename layer:", layer.name);
          if (newName != null) {
            newName = newName.trim();
            if (newName.length() > 0) {
              app.history.perform(doc, new RenameLayerCommand(layer, newName));
              list.repaint();
            }
          }
        }
      }
    });


    // Delete：用 Swing Key Binding（别用 processing.event.KeyEvent）
    InputMap im = list.getInputMap(JComponent.WHEN_FOCUSED);
    ActionMap am = list.getActionMap();
    im.put(KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_DELETE, 0), "deleteLayer");
    am.put("deleteLayer", new AbstractAction() {
      public void actionPerformed(ActionEvent e) {
        deleteSelectedLayer();
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
    addButton.addActionListener(e -> addBlankLayer());


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
    isRefreshing = true;

    model.clear();
    ArrayList<Layer> layers = updatedDoc.layers.list;
    for (int i = layers.size() - 1; i >= 0; i--) model.addElement(layers.get(i));

    int viewIdx = docToViewIndex(updatedDoc.layers.activeIndex);
    if (viewIdx >= 0) list.setSelectedIndex(viewIdx);
    else list.clearSelection();

    list.repaint();
    isRefreshing = false;
  }

  void addBlankLayer() {
    PImage blank = parent.createImage(doc.canvas.width, doc.canvas.height, ARGB);
    blank.loadPixels();
    for (int i = 0; i < blank.pixels.length; i++) blank.pixels[i] = parent.color(0, 0, 0, 0);
    blank.updatePixels();
    Layer newLayer = new Layer(blank,doc.layers.getid());
    newLayer.name = "Layer " + (doc.layers.list.size() + 1);
    int index = doc.layers.list.size();
    app.history.perform(doc, new AddLayerCommand(newLayer, index));
    doc.renderFlags.dirtyComposite = true;
    refresh(doc);
  }

  void deleteSelectedLayer() {
    Layer layer = list.getSelectedValue();
    if (layer == null) return;

    app.history.perform(doc, new RemoveLayerCommand(layer));
    doc.renderFlags.dirtyComposite = true;
    refresh(doc);
  }

    class ReorderHandler extends TransferHandler {
    int sourceIndex = -1;

    public int getSourceActions(JComponent c) { return MOVE; }

    protected Transferable createTransferable(JComponent c) {
      sourceIndex = list.getSelectedIndex();
      Layer layer = list.getSelectedValue();
      println("起点："+sourceIndex);
      return new StringSelection(layer == null ? "" : ("" + layer.ID));
    }

    public boolean canImport(TransferSupport support) { return support.isDrop(); }

    public boolean importData(TransferSupport support) {
      if (!support.isDrop()) return false;

      JList.DropLocation dl = (JList.DropLocation) support.getDropLocation();
      int target = dl.getIndex();

      if (target < 0) target = model.getSize();
      // 夹紧到 [0, size]
      target = Math.max(0, Math.min(target, model.getSize()));
      // 从前往后拖：移除 source 后插入点左移 1
      if (target > sourceIndex) target--;

      println(sourceIndex+" "+target);

      Layer layer = model.getElementAt(sourceIndex);

      int sourceDocIndex = viewToDocIndex(sourceIndex);
      int targetDocIndex = viewToDocIndex(target);
      if (sourceDocIndex < 0 || targetDocIndex < 0) return false;

      app.history.perform(doc, new MoveLayerCommand(layer, sourceDocIndex, targetDocIndex));

      refresh(doc);
      int viewIdx = docToViewIndex(doc.layers.indexOf(layer));
      if (viewIdx >= 0) list.setSelectedIndex(viewIdx);
      return true;
    }
  }



  // ---------- Renderer ----------
  class LayerCellRenderer extends JPanel implements ListCellRenderer<Layer> {
    int eyeW;
    JLabel eyeLabel = new JLabel("", SwingConstants.CENTER);
    JLabel nameLabel = new JLabel("");
    JLabel indexLabel = new JLabel("");

    LayerCellRenderer(int eyeW) {
      this.eyeW = eyeW;
      setLayout(new BorderLayout());
      setBorder(BorderFactory.createEmptyBorder(2, 2, 2, 2));
      setOpaque(true);
      
      eyeLabel.setPreferredSize(new Dimension(eyeW, 22));
      eyeLabel.setForeground(Color.WHITE);

      nameLabel.setForeground(Color.WHITE);
      nameLabel.setBorder(BorderFactory.createEmptyBorder(0, 6, 0, 0));

      indexLabel.setForeground(Color.WHITE);

      add(eyeLabel, BorderLayout.WEST);
      add(nameLabel, BorderLayout.CENTER);
      add(indexLabel,BorderLayout.EAST);
    }

    public Component getListCellRendererComponent(
      JList<? extends Layer> list, Layer layer, int index,
      boolean isSelected, boolean cellHasFocus
    ) {
      eyeLabel.setText(layer.visible ? "👁" : "×");
      nameLabel.setText(layer.name);
      indexLabel.setText(String.valueOf(doc.layers.indexOf(layer)));

      Color bg = isSelected ? new Color(80, 80, 80) : list.getBackground();
      setBackground(bg);

      return this;
    }
  }

  int docToViewIndex(int docIndex) {
    int size = doc.layers.list.size();
    if (docIndex < 0 || docIndex >= size) return -1;
    return size - 1 - docIndex;
  }

  int viewToDocIndex(int viewIndex) {
    int size = doc.layers.list.size();
    if (viewIndex < 0 || viewIndex >= size) return -1;
    return size - 1 - viewIndex;
  }
}
