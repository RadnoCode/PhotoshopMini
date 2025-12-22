// Property panel with Transform / Filter tabs
class PropertiesPanel {
  PApplet parent;
  Document doc;
  App app;

  final Dimension labelSize = new Dimension(90, 24);

  Layer activeLayer;
  boolean isUpdating = false;

  JPanel root;
  JTabbedPane tabs;

  // Transform controls
  JPanel transformContent;
  JTextField fieldX, fieldY, fieldRotation, fieldScale, fieldOpacity, fieldText;
  JSlider sliderX, sliderY, sliderRotation, sliderScale, sliderOpacity;
  JComboBox<String> comboFont;
  JSpinner spinnerFontSize;

  // Filter controls
  JPanel filterContent;

  PropertiesPanel(PApplet parent, Document doc, App app, JPanel hostContainer) {
    this.parent = parent;
    this.doc = doc;
    this.app = app;

    buildUI();
    hostContainer.add(root, BorderLayout.SOUTH);
  }

  void buildUI() {
    root = new JPanel(new BorderLayout());
    root.setOpaque(false);
    root.setPreferredSize(new Dimension(300, 300));

    tabs = new JTabbedPane();
    tabs.setBackground(new Color(50, 50, 50));
    tabs.setForeground(Color.WHITE);
    tabs.setBorder(BorderFactory.createEmptyBorder());

    buildTransformTab();
    buildFilterTab();

    root.add(tabs, BorderLayout.CENTER);
  }

  void buildTransformTab() {
    transformContent = new JPanel();
    transformContent.setLayout(new BoxLayout(transformContent, BoxLayout.Y_AXIS));
    transformContent.setBackground(new Color(60, 60, 60));
    transformContent.setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

    int rangeX = doc.canvas != null ? doc.canvas.width : 2000;
    int rangeY = doc.canvas != null ? doc.canvas.height : 2000;

    fieldX = new JTextField("0", 5);
    sliderX = buildSlider(-rangeX, rangeX, 0);
    bindPositionControl(fieldX, sliderX);
    fieldY = new JTextField("0", 5);
    sliderY = buildSlider(-rangeY, rangeY, 0);
    bindPositionControl(fieldY, sliderY);
    JPanel positionBlock = makeSectionBlock("Position");
    positionBlock.add(makeRow("X", fieldX, sliderX));
    positionBlock.add(makeRow("Y", fieldY, sliderY));
    transformContent.add(positionBlock);

    fieldRotation = new JTextField("0", 5);
    sliderRotation = buildSlider(-180, 180, 0);
    bindRotationControl(fieldRotation, sliderRotation);
    JPanel rotationBlock = makeSectionBlock("Rotation");
    rotationBlock.add(makeRow("Rotation (deg)", fieldRotation, sliderRotation));
    transformContent.add(Box.createVerticalStrut(8));
    transformContent.add(rotationBlock);

    fieldScale = new JTextField("1.0", 5);
    sliderScale = buildSlider(10, 300, 100); // 0.1x - 3x
    bindScaleControl(fieldScale, sliderScale);
    JPanel scaleBlock = makeSectionBlock("Scale");
    scaleBlock.add(makeRow("Scale", fieldScale, sliderScale));
    transformContent.add(Box.createVerticalStrut(8));
    transformContent.add(scaleBlock);

    fieldOpacity = new JTextField("255", 5);
    sliderOpacity = buildSlider(0, 255, 255);
    bindOpacityControl(fieldOpacity, sliderOpacity);
    JPanel opacityBlock = makeSectionBlock("Opacity");
    opacityBlock.add(makeRow("Opacity", fieldOpacity, sliderOpacity));
    transformContent.add(Box.createVerticalStrut(8));
    transformContent.add(opacityBlock);

    // Text related controls
    JPanel textPanel = new JPanel();
    textPanel.setLayout(new GridLayout(3, 2, 6, 6));
    textPanel.setOpaque(false);
    textPanel.setBorder(BorderFactory.createEmptyBorder());

    JLabel labelText = makeLabel("Text");
    fieldText = new JTextField("", 8);
    fieldText.addActionListener(e -> applyTextChange());
    fieldText.addFocusListener(new java.awt.event.FocusAdapter() {
      public void focusLost(java.awt.event.FocusEvent e) { applyTextChange(); }
    });

    JLabel labelFont = makeLabel("Font");
    String[] fontOptions = { "Arial", "Helvetica", "Courier", "Times New Roman" };
    comboFont = new JComboBox<String>(fontOptions);
    comboFont.addActionListener(e -> applyFontNameChange());

    JLabel labelSize = makeLabel("Size");
    spinnerFontSize = new JSpinner(new SpinnerNumberModel(48, 6, 400, 2));
    spinnerFontSize.addChangeListener(e -> applyFontSizeChange());

    textPanel.add(labelText);
    textPanel.add(fieldText);
    textPanel.add(labelFont);
    textPanel.add(comboFont);
    textPanel.add(labelSize);
    textPanel.add(spinnerFontSize);

    JPanel textBlock = makeSectionBlock("Text");
    textBlock.add(textPanel);
    transformContent.add(Box.createVerticalStrut(8));
    transformContent.add(textBlock);

    JScrollPane transformScroll = new JScrollPane(transformContent);
    transformScroll.setBorder(BorderFactory.createEmptyBorder());
    transformScroll.getViewport().setBackground(new Color(60, 60, 60));
    transformScroll.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_AS_NEEDED);
    tabs.addTab("Transform", transformScroll);
  }

  void buildFilterTab() {
    filterContent = new JPanel();
    filterContent.setLayout(new BoxLayout(filterContent, BoxLayout.Y_AXIS));
    filterContent.setBackground(new Color(60, 60, 60));
    filterContent.setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

    JScrollPane scroll = new JScrollPane(filterContent);
    scroll.setBorder(BorderFactory.createEmptyBorder());
    scroll.getViewport().setBackground(new Color(60, 60, 60));
    scroll.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_AS_NEEDED);

    tabs.addTab("Filter", scroll);
  }

  void updateFromLayer(Layer layer) {
    activeLayer = layer;
    if (layer == null) {
      setVisible(false);
      return;
    }

    isUpdating = true;

    sliderX.setValue(clampSlider(sliderX, PApplet.round(layer.x)));
    sliderY.setValue(clampSlider(sliderY, PApplet.round(layer.y)));

    int deg = PApplet.round(PApplet.degrees(layer.rotation));
    sliderRotation.setValue(clampSlider(sliderRotation, deg));

    int scaleVal = clampSlider(sliderScale, PApplet.round(layer.scale * 100));
    sliderScale.setValue(scaleVal);

    sliderOpacity.setValue(clampSlider(sliderOpacity, (int)(layer.opacity * 255)));

    fieldX.setText(String.valueOf(PApplet.round(layer.x)));
    fieldY.setText(String.valueOf(PApplet.round(layer.y)));
    fieldRotation.setText(String.valueOf(deg));
    fieldScale.setText(String.format("%.2f", scaleVal / 100.0f));
    fieldOpacity.setText(String.valueOf(sliderOpacity.getValue()));

    if (layer instanceof TextLayer) {
      TextLayer tl = (TextLayer) layer;
      fieldText.setEnabled(true);
      comboFont.setEnabled(true);
      spinnerFontSize.setEnabled(true);

      fieldText.setText(tl.text);
      comboFont.setSelectedItem(tl.fontName);
      spinnerFontSize.setValue(tl.fontSize);
    } else {
      fieldText.setText("");
      fieldText.setEnabled(false);
      comboFont.setEnabled(false);
      spinnerFontSize.setEnabled(false);
    }

    rebuildFilterTab();

    isUpdating = false;
    setVisible(true);
  }

  void setVisible(boolean visible) {
    if (root != null) root.setVisible(visible);
  }
  //add comment
  // --- Transform helpers ---
  JSlider buildSlider(int min, int max, int value) {
    JSlider s = new JSlider(min, max, value);
    s.setBackground(new Color(60, 60, 60));
    return s;
  }

  JLabel makeLabel(String text) {
    JLabel label = new JLabel(text);
    label.setForeground(Color.WHITE);
    return label;
  }

  JPanel makeRow(String labelText, JTextField field, JSlider slider) {
    JPanel row = new JPanel(new BorderLayout(6, 0));
    row.setOpaque(false);

    JLabel label = makeLabel(labelText);
    label.setPreferredSize(labelSize);

    JPanel fieldRow = new JPanel(new BorderLayout(6, 0));
    fieldRow.setOpaque(false);
    fieldRow.add(label, BorderLayout.WEST);
    if (field != null) {
      field.setColumns(5);
      Dimension compact = new Dimension(70, field.getPreferredSize().height);
      field.setPreferredSize(compact);
      field.setMinimumSize(compact);
      field.setMaximumSize(new Dimension(90, compact.height));
      field.setHorizontalAlignment(JTextField.RIGHT);
      fieldRow.add(field, BorderLayout.EAST);
    }

    JPanel sliderRow = new JPanel(new BorderLayout());
    sliderRow.setOpaque(false);
    slider.setMaximumSize(new Dimension(Integer.MAX_VALUE, slider.getPreferredSize().height));
    sliderRow.add(slider, BorderLayout.CENTER);

    row.add(fieldRow, BorderLayout.NORTH);
    row.add(sliderRow, BorderLayout.CENTER);
    row.add(Box.createVerticalStrut(8), BorderLayout.SOUTH);
    row.setMaximumSize(new Dimension(Integer.MAX_VALUE, row.getPreferredSize().height));
    return row;
  }

  void bindPositionControl(JTextField field, JSlider slider) {
    field.addActionListener(e -> {
      if (isUpdating) return;
      int v = parseIntSafe(field.getText(), slider.getValue());
      isUpdating = true;
      slider.setValue(clampSlider(slider, v));
      isUpdating = false;
      applyTransformFromUI();
    });
    field.addFocusListener(new java.awt.event.FocusAdapter() {
      public void focusLost(java.awt.event.FocusEvent e) {
        if (isUpdating) return;
        int v = parseIntSafe(field.getText(), slider.getValue());
        isUpdating = true;
        slider.setValue(clampSlider(slider, v));
        isUpdating = false;
        applyTransformFromUI();
      }
    });
    slider.addChangeListener(e -> {
      if (isUpdating) return;
      field.setText(String.valueOf(slider.getValue()));
      if (!slider.getValueIsAdjusting()) applyTransformFromUI();
    });
  }

  void bindRotationControl(JTextField field, JSlider slider) {
    field.addActionListener(e -> {
      if (isUpdating) return;
      int deg = parseIntSafe(field.getText(), slider.getValue());
      isUpdating = true;
      slider.setValue(clampSlider(slider, deg));
      isUpdating = false;
      applyTransformFromUI();
    });
    field.addFocusListener(new java.awt.event.FocusAdapter() {
      public void focusLost(java.awt.event.FocusEvent e) {
        if (isUpdating) return;
        int deg = parseIntSafe(field.getText(), slider.getValue());
        isUpdating = true;
        slider.setValue(clampSlider(slider, deg));
        isUpdating = false;
        applyTransformFromUI();
      }
    });
    slider.addChangeListener(e -> {
      if (isUpdating) return;
      field.setText(String.valueOf(slider.getValue()));
      if (!slider.getValueIsAdjusting()) applyTransformFromUI();
    });
  }

  void bindScaleControl(JTextField field, JSlider slider) {
    field.addActionListener(e -> {
      if (isUpdating) return;
      float scaleVal = parseFloatSafe(field.getText(), slider.getValue() / 100.0f);
      int sliderVal = clampSlider(slider, PApplet.round(scaleVal * 100));
      isUpdating = true;
      slider.setValue(sliderVal);
      isUpdating = false;
      applyTransformFromUI();
    });
    field.addFocusListener(new java.awt.event.FocusAdapter() {
      public void focusLost(java.awt.event.FocusEvent e) {
        if (isUpdating) return;
        float scaleVal = parseFloatSafe(field.getText(), slider.getValue() / 100.0f);
        int sliderVal = clampSlider(slider, PApplet.round(scaleVal * 100));
        isUpdating = true;
        slider.setValue(sliderVal);
        isUpdating = false;
        applyTransformFromUI();
      }
    });
    slider.addChangeListener(e -> {
      if (isUpdating) return;
      field.setText(String.format("%.2f", slider.getValue() / 100.0f));
      if (!slider.getValueIsAdjusting()) applyTransformFromUI();
    });
  }

  void bindOpacityControl(JTextField field, JSlider slider) {
    field.addActionListener(e -> {
      if (isUpdating) return;
      int val = clampSlider(slider, parseIntSafe(field.getText(), slider.getValue()));
      isUpdating = true;
      slider.setValue(val);
      isUpdating = false;
      applyOpacityFromUI();
    });
    field.addFocusListener(new java.awt.event.FocusAdapter() {
      public void focusLost(java.awt.event.FocusEvent e) {
        if (isUpdating) return;
        int val = clampSlider(slider, parseIntSafe(field.getText(), slider.getValue()));
        isUpdating = true;
        slider.setValue(val);
        isUpdating = false;
        applyOpacityFromUI();
      }
    });
    slider.addChangeListener(e -> {
      if (isUpdating) return;
      field.setText(String.valueOf(slider.getValue()));
      if (!slider.getValueIsAdjusting()) applyOpacityFromUI();
    });
  }

  void applyTransformFromUI() {
    if (activeLayer == null) return;

    float nx = sliderX.getValue();
    float ny = sliderY.getValue();
    float ns = sliderScale.getValue() / 100.0f;
    float nr = PApplet.radians(sliderRotation.getValue());

    app.history.perform(doc, new TransformCommand(activeLayer, nx, ny, ns, nr));
  }

  void applyOpacityFromUI() {
    if (activeLayer == null) return;
    app.history.perform(doc, new OpacityCommand(activeLayer, sliderOpacity.getValue()));
  }


  void applyTextChange() {
    if (isUpdating) return;
    if (!(activeLayer instanceof TextLayer)) return;
    TextLayer tl = (TextLayer) activeLayer;
    app.history.perform(doc, new SetTextCommand(tl, fieldText.getText()));
  }

  void applyFontNameChange() {
    if (isUpdating) return;
    if (!(activeLayer instanceof TextLayer)) return;
    TextLayer tl = (TextLayer) activeLayer;
    String value = (String) comboFont.getSelectedItem();
    app.history.perform(doc, new SetFontNameCommand(tl, value));
  }

  void applyFontSizeChange() {
    if (isUpdating) return;
    if (!(activeLayer instanceof TextLayer)) return;
    TextLayer tl = (TextLayer) activeLayer;
    int size = ((Number) spinnerFontSize.getValue()).intValue();
    app.history.perform(doc, new SetFontSizeCommand(tl, size));
  }



  // --- Filter helpers ---
  void rebuildFilterTab() {
    filterContent.removeAll();

    if (activeLayer == null) {
      filterContent.add(makeInfoLabel("No layer selected."));
    } else if (activeLayer.filters.size() == 0) {
      filterContent.add(makeInfoLabel("No filters on this layer."));
    } else {
      for (Filter f : activeLayer.filters) {
        if (f instanceof GaussianBlurFilter) addGaussianBlurControls((GaussianBlurFilter) f);
        else if (f instanceof ContrastFilter) addContrastControls((ContrastFilter) f);
        else if (f instanceof SharpenFilter) addSharpenControls((SharpenFilter) f);
        else filterContent.add(makeInfoLabel("Unsupported filter: " + f.getClass().getSimpleName()));
        filterContent.add(Box.createVerticalStrut(8));
      }
    }

    filterContent.revalidate();
    filterContent.repaint();
  }

  JLabel makeInfoLabel(String text) {
    JLabel label = new JLabel(text);
    label.setForeground(new Color(200, 200, 200));
    return label;
  }

  JPanel makeSectionBlock(String title) {
    JPanel panel = new JPanel();
    panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
    panel.setOpaque(false);
    TitledBorder border = BorderFactory.createTitledBorder(
      BorderFactory.createLineBorder(new Color(230, 230, 230)),
      title
    );
    border.setTitleColor(new Color(230, 230, 230)); 

    panel.setBorder(border);
    return panel;
  }

  JPanel makeFilterBlock(String title) {
    return makeSectionBlock(title);
  }

  void addGaussianBlurControls(GaussianBlurFilter filter) {
    JPanel block = makeFilterBlock("Gaussian Blur");

    JTextField radiusField = new JTextField(String.valueOf(filter.radius), 4);
    JSlider radiusSlider = buildSlider(0, 50, filter.radius);
    JTextField sigmaField = new JTextField(String.valueOf(filter.sigma), 4);
    JSlider sigmaSlider = buildSlider(1, 50, filter.sigma);

    radiusField.addActionListener(e -> {
      if (isUpdating) return;
      int r = clampSlider(radiusSlider, parseIntSafe(radiusField.getText(), filter.radius));
      isUpdating = true;
      radiusSlider.setValue(r);
      isUpdating = false;
      applyBlurChange(filter, r, sigmaSlider.getValue());
    });
    sigmaField.addActionListener(e -> {
      if (isUpdating) return;
      int s = clampSlider(sigmaSlider, parseIntSafe(sigmaField.getText(), filter.sigma));
      isUpdating = true;
      sigmaSlider.setValue(s);
      isUpdating = false;
      applyBlurChange(filter, radiusSlider.getValue(), s);
    });

    radiusSlider.addChangeListener(e -> {
      if (isUpdating) return;
      radiusField.setText(String.valueOf(radiusSlider.getValue()));
      if (!radiusSlider.getValueIsAdjusting()) applyBlurChange(filter, radiusSlider.getValue(), sigmaSlider.getValue());
    });
    sigmaSlider.addChangeListener(e -> {
      if (isUpdating) return;
      sigmaField.setText(String.valueOf(sigmaSlider.getValue()));
      if (!sigmaSlider.getValueIsAdjusting()) applyBlurChange(filter, radiusSlider.getValue(), sigmaSlider.getValue());
    });

    block.add(makeRow("Radius", radiusField, radiusSlider));
    block.add(makeRow("Sigma", sigmaField, sigmaSlider));
    filterContent.add(block);
  }

  void addContrastControls(ContrastFilter filter) {
    JPanel block = makeFilterBlock("Contrast");

    JTextField valueField = new JTextField(String.format("%.2f", filter.value), 5);
    JSlider valueSlider = buildSlider(0, 200, (int)(filter.value * 100));

    valueField.addActionListener(e -> {
      if (isUpdating) return;
      float val = parseFloatSafe(valueField.getText(), filter.value);
      int sliderVal = clampSlider(valueSlider, PApplet.round(val * 100));
      isUpdating = true;
      valueSlider.setValue(sliderVal);
      isUpdating = false;
      applyContrastChange(filter, sliderVal / 100.0f);
    });
    valueSlider.addChangeListener(e -> {
      if (isUpdating) return;
      float val = valueSlider.getValue() / 100.0f;
      valueField.setText(String.format("%.2f", val));
      if (!valueSlider.getValueIsAdjusting()) applyContrastChange(filter, val);
    });

    block.add(makeRow("Value", valueField, valueSlider));
    filterContent.add(block);
  }

  void addSharpenControls(SharpenFilter filter) {
    JPanel block = makeFilterBlock("Sharpen");

    JTextField valueField = new JTextField(String.format("%.2f", filter.value), 5);
    JSlider valueSlider = buildSlider(0, 300, (int)(filter.value * 100));

    valueField.addActionListener(e -> {
      if (isUpdating) return;
      float val = parseFloatSafe(valueField.getText(), filter.value);
      int sliderVal = clampSlider(valueSlider, PApplet.round(val * 100));
      isUpdating = true;
      valueSlider.setValue(sliderVal);
      isUpdating = false;
      applySharpenChange(filter, sliderVal / 100.0f);
    });
    valueSlider.addChangeListener(e -> {
      if (isUpdating) return;
      float val = valueSlider.getValue() / 100.0f;
      valueField.setText(String.format("%.2f", val));
      if (!valueSlider.getValueIsAdjusting()) applySharpenChange(filter, val);
    });

    block.add(makeRow("Value", valueField, valueSlider));
    filterContent.add(block);
  }

  void applyBlurChange(GaussianBlurFilter filter, int radius, int sigma) {
    if (activeLayer == null) return;
    app.history.perform(doc, new BlurChangeCommand(filter, radius, sigma));
    markFiltersDirty();
  }

  void applyContrastChange(ContrastFilter filter, float value) {
    if (activeLayer == null) return;
    app.history.perform(doc, new ContrastChangeCommand(filter, value));
    markFiltersDirty();
  }

  void applySharpenChange(SharpenFilter filter, float value) {
    if (activeLayer == null) return;
    app.history.perform(doc, new SharpenChangeCommand(filter, value));
    markFiltersDirty();
  }

  void markFiltersDirty() {
    activeLayer.dirty = true;
    doc.markChanged();
  }

  int clampSlider(JSlider slider, int value) {
    return PApplet.constrain(value, slider.getMinimum(), slider.getMaximum());
  }

  int parseIntSafe(String value, int fallback) {
    try {
      return Integer.parseInt(value.trim());
    } catch (Exception e) {
      return fallback;
    }
  }

  float parseFloatSafe(String value, float fallback) {
    try {
      return Float.parseFloat(value.trim());
    } catch (Exception e) {
      return fallback;
    }
  }

  void setPreferredHeight(int preferredHeight) {
    if (root == null) return;
    Dimension current = root.getPreferredSize();
    root.setPreferredSize(new Dimension(current.width, preferredHeight));
    root.revalidate();
  }
}
