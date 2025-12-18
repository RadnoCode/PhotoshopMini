class LayerListPanel {
  PApplet parent;
  Document doc;
  int rightPanelX;
  int panelWidth;
  int topY;

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
    list.setTransferHandler(new ReorderHandler());
    list.setBackground(new Color(55, 55, 55));
    list.setForeground(Color.WHITE);
    list.setBorder(BorderFactory.createEmptyBorder(4, 6, 4, 6));
    list.addListSelectionListener(e -> {
      if (!e.getValueIsAdjusting()) {
        int idx = list.getSelectedIndex();
        doc.layers.activeIndex = idx;
      }
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

        // 双击重命名（先用对话框，后续你再升级成“行内编辑框”）
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

    model.clear();
    for (Layer l : updatedDoc.layers.list) model.addElement(l);

    int active = updatedDoc.layers.activeIndex;
    if (active >= 0 && active < model.getSize()) list.setSelectedIndex(active);
    else list.clearSelection();

    list.repaint();
  }

  void addBlankLayer() {
    PImage blank = parent.createImage(doc.canvas.w, doc.canvas.h, ARGB);
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
      // 传个“无意义字符串”也行，真正信息我们用 sourceIndex + layer 引用
      return new StringSelection(layer == null ? "" : ("" + layer.ID));
    }

    public boolean canImport(TransferSupport support) { return support.isDrop(); }

    public boolean importData(TransferSupport support) {
      if (!support.isDrop()) return false;

      JList.DropLocation dl = (JList.DropLocation) support.getDropLocation();
      int target = dl.getIndex();

      if (sourceIndex < 0) return false;
      if (target == sourceIndex) return false;
      if (target < 0) target = model.getSize() - 1;

      Layer layer = model.getElementAt(sourceIndex);
      app.history.perform(doc, new MoveLayerCommand(layer, sourceIndex, target));
      refresh(doc);
      list.setSelectedIndex(doc.layers.indexOf(layer));
      return true;
    }
  }



  // ---------- Renderer ----------
  class LayerCellRenderer extends JPanel implements ListCellRenderer<Layer> {
    int eyeW;
    JLabel eyeLabel = new JLabel("", SwingConstants.CENTER);
    JLabel nameLabel = new JLabel("");

    LayerCellRenderer(int eyeW) {
      this.eyeW = eyeW;
      setLayout(new BorderLayout());
      setBorder(BorderFactory.createEmptyBorder(2, 2, 2, 2));
      setOpaque(true);

      eyeLabel.setPreferredSize(new Dimension(eyeW, 22));
      eyeLabel.setForeground(Color.WHITE);

      nameLabel.setForeground(Color.WHITE);
      nameLabel.setBorder(BorderFactory.createEmptyBorder(0, 6, 0, 0));

      add(eyeLabel, BorderLayout.WEST);
      add(nameLabel, BorderLayout.CENTER);
    }

    public Component getListCellRendererComponent(
      JList<? extends Layer> list, Layer layer, int index,
      boolean isSelected, boolean cellHasFocus
    ) {
      eyeLabel.setText(layer.visible ? "👁" : "×");
      nameLabel.setText(layer.name);

      Color bg = isSelected ? new Color(80, 80, 80) : list.getBackground();
      setBackground(bg);

      return this;
    }
  }
}