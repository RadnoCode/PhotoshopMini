// Property panel with Transform / Filter tabs
import com.formdev.flatlaf.FlatLightLaf;
class PropertiesPanel {
  PApplet parent;
  Document doc;
  App app;

  final Dimension labelSize = new Dimension(90, 24);
  final Color bgRoot = new Color(32, 32, 32);
  final Color bgPanel = new Color(44, 44, 44);
  final Color bgBlock = new Color(52, 52, 52);
  final Color fgText = new Color(225, 225, 225);
  final Color fgMuted = new Color(170, 170, 170);
  final Color accent = new Color(90, 160, 255);

  Layer activeLayer;
  boolean isUpdating = false;

  JPanel root;
  JTabbedPane tabs;

  // Transform controls
  JPanel transformContent;
  JTextField fieldX, fieldY, fieldRotation, fieldScale, fieldOpacity;
  JSlider sliderX, sliderY, sliderRotation, sliderScale, sliderOpacity;

  // Text controls
  JPanel textContent;
  JTextField fieldText;
  JComboBox<String> comboFont;
  JSpinner spinnerFontSize;
  JButton btnTextColor;

  // Filter controls
  JPanel filterContent;

  PropertiesPanel(PApplet parent, Document doc, App app, JPanel hostContainer) {
    

    setupTextFieldStyle();

    this.parent = parent;
    this.doc = doc;
    this.app = app;

    buildUI();
    hostContainer.add(root, BorderLayout.SOUTH);
  }

  void buildUI() {
    root = new JPanel(new BorderLayout());
    root.setOpaque(true);
    root.setBackground(bgRoot);
    root.setPreferredSize(new Dimension(260, 300));
    root.setMaximumSize(new Dimension(260,Integer.MAX_VALUE));
    tabs = new JTabbedPane();
    tabs.setBackground(bgRoot);
    tabs.setForeground(fgText);
    tabs.setOpaque(false);

    buildTransformTab();
    buildTextTab();
    buildFilterTab();

    root.add(tabs, BorderLayout.CENTER);
  }

  void buildTransformTab() {
    transformContent = new JPanel();
    transformContent.setLayout(new BoxLayout(transformContent, BoxLayout.Y_AXIS));
    transformContent.setBackground(bgPanel);
    transformContent.setMaximumSize(new Dimension(300,Integer.MAX_VALUE));
    transformContent.setBorder(BorderFactory.createEmptyBorder(8, 5, 8, 15));

    int rangeX = doc.canvas != null ? doc.canvas.width : 2000;
    int rangeY = doc.canvas != null ? doc.canvas.height : 2000;

    fieldX = styledField("0");
    sliderX = buildSlider(-rangeX, rangeX, 0);
    bindPositionControl(fieldX, sliderX);
    fieldY = styledField("0");
    sliderY = buildSlider(-rangeY, rangeY, 0);
    bindPositionControl(fieldY, sliderY);
    JPanel positionBlock = makeSectionBlock("Position");
    positionBlock.add(makeRow("X", fieldX, sliderX));
    positionBlock.add(makeRow("Y", fieldY, sliderY));
    transformContent.add(positionBlock);

    fieldRotation = styledField("0");
    sliderRotation = buildSlider(-180, 180, 0);
    bindRotationControl(fieldRotation, sliderRotation);
    JPanel rotationBlock = makeSectionBlock("Rotation");
    rotationBlock.add(makeRow("Rotation (deg)", fieldRotation, sliderRotation));
    transformContent.add(Box.createVerticalStrut(8));
    transformContent.add(rotationBlock);

    fieldScale = styledField("1.0");
    sliderScale = buildSlider(10, 900, 100); // 0.1x - 3x
    bindScaleControl(fieldScale, sliderScale);
    JPanel scaleBlock = makeSectionBlock("Scale");
    scaleBlock.add(makeRow("Scale", fieldScale, sliderScale));
    transformContent.add(Box.createVerticalStrut(8));
    transformContent.add(scaleBlock);

    fieldOpacity = styledField("255");
    sliderOpacity = buildSlider(0, 255, 255);
    bindOpacityControl(fieldOpacity, sliderOpacity);
    JPanel opacityBlock = makeSectionBlock("Opacity");
    opacityBlock.add(makeRow("Opacity", fieldOpacity, sliderOpacity));
    transformContent.add(Box.createVerticalStrut(8));
    transformContent.add(opacityBlock);

    JScrollPane transformScroll = new JScrollPane(transformContent);
    transformScroll.setBorder(BorderFactory.createEmptyBorder());
    transformScroll.getViewport().setBackground(bgPanel);
    transformScroll.getVerticalScrollBar().setUnitIncrement(12);
    transformScroll.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_AS_NEEDED);
    tabs.addTab("Transform", transformScroll);
  }

void buildTextTab() {
  textContent = new JPanel();
  textContent.setLayout(new BoxLayout(textContent, BoxLayout.Y_AXIS));
  textContent.setBackground(bgPanel);
  textContent.setBorder(BorderFactory.createEmptyBorder(8, 5, 8, 15));
  textContent.setMaximumSize(new Dimension(300, 300));

  JPanel textPanel = new JPanel(new GridBagLayout());
  textPanel.setOpaque(false);
  textPanel.setBorder(BorderFactory.createEmptyBorder());

  GridBagConstraints gc = new GridBagConstraints();
  gc.insets = new Insets(6, 6, 6, 6);         
  gc.gridy = 0;
  gc.fill = GridBagConstraints.HORIZONTAL;

  // ---- Row 1: Text ----
  JLabel labelText = makeLabel("Text");
  fieldText = styledField("");
  fieldText.putClientProperty("JComponent.sizeVariant", "small");
  fieldText.addActionListener(e -> applyTextChange());
  fieldText.addFocusListener(new java.awt.event.FocusAdapter() {
    public void focusLost(java.awt.event.FocusEvent e) { applyTextChange(); }
  });

  gc.gridx = 0; gc.weightx = 0; gc.anchor = GridBagConstraints.WEST;
  textPanel.add(labelText, gc);
  gc.gridx = 1; gc.weightx = 1;
  textPanel.add(fieldText, gc);

  // ---- Row 2: Font ----
  JLabel labelFont = makeLabel("Font");
  GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
  String[] fontOptions = ge.getAvailableFontFamilyNames();
  comboFont = new JComboBox<String>(fontOptions);
  comboFont.putClientProperty("JComponent.sizeVariant", "small");
  comboFont.setMaximumRowCount(12);
  comboFont.addActionListener(e -> applyFontNameChange());

  gc.gridy++;
  gc.gridx = 0; gc.weightx = 0;
  textPanel.add(labelFont, gc);
  gc.gridx = 1; gc.weightx = 1;
  textPanel.add(comboFont, gc);

  // ---- Row 3: Size ----
  JLabel labelSize = makeLabel("Size");
  spinnerFontSize = new JSpinner(new SpinnerNumberModel(48, 6, 400, 2));
  spinnerFontSize.putClientProperty("JComponent.sizeVariant", "small");
  styleSpinner(spinnerFontSize);                 // 你已有的 Flat spinner 美化
  spinnerFontSize.addChangeListener(e -> applyFontSizeChange());

  gc.gridy++;
  gc.gridx = 0; gc.weightx = 0;
  textPanel.add(labelSize, gc);
  gc.gridx = 1; gc.weightx = 1;
  textPanel.add(spinnerFontSize, gc);

  // ---- Row 4: Color ----
  JLabel labelColor = makeLabel("Color");
  btnTextColor = new JButton();
  btnTextColor.putClientProperty("JComponent.roundRect", true);
  btnTextColor.putClientProperty("JComponent.sizeVariant", "small");

  int colorH = 24; 
  Dimension colorDim = new Dimension(60, colorH);
  btnTextColor.setPreferredSize(colorDim);
  btnTextColor.addActionListener(e -> openColorPicker());

  gc.gridy++;
  gc.gridx = 0; gc.weightx = 0;
  textPanel.add(labelColor, gc);
  gc.gridx = 1; gc.weightx = 1;
  textPanel.add(btnTextColor, gc);
  gc.gridy++;
  gc.gridx = 0;
  gc.gridwidth = 2;
  gc.weightx = 1;
  gc.weighty = 1;            
  gc.fill = GridBagConstraints.BOTH;
  textPanel.add(Box.createVerticalGlue(), gc);

  JPanel textBlock = makeSectionBlock("Text");
  textBlock.add(textPanel);
  textContent.add(textBlock);

  // --- scroll ---
  JScrollPane textScroll = new JScrollPane(textContent);
  textScroll.setBorder(BorderFactory.createEmptyBorder());
  textScroll.getViewport().setBackground(bgPanel);
  textScroll.getVerticalScrollBar().setUnitIncrement(12);
  textScroll.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_AS_NEEDED);

  tabs.addTab("Text", textScroll);
}


  void buildFilterTab() {
    filterContent = new JPanel();
    filterContent.setLayout(new BoxLayout(filterContent, BoxLayout.Y_AXIS));
    filterContent.setBackground(bgPanel);
    filterContent.setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

    JScrollPane scroll = new JScrollPane(filterContent);
    scroll.setBorder(BorderFactory.createEmptyBorder());
    scroll.getViewport().setBackground(bgPanel);
    scroll.getVerticalScrollBar().setUnitIncrement(12);
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
      btnTextColor.setEnabled(true);

      fieldText.setText(tl.text);
      comboFont.setSelectedItem(tl.fontName);
      spinnerFontSize.setValue(tl.fontSize);
      updateColorSwatch(tl.fillCol);
    } else {
      fieldText.setText("");
      fieldText.setEnabled(false);
      comboFont.setEnabled(false);
      spinnerFontSize.setEnabled(false);
      btnTextColor.setEnabled(false);
    }

    rebuildFilterTab();

    isUpdating = false;
    setVisible(true);
  }

  void setVisible(boolean visible) {
    if (root != null) root.setVisible(visible);
  }


  // --- Transform helpers ---
  JSlider buildSlider(int min, int max, int value) {
    JSlider s = new JSlider(min, max, value);
    s.setUI(new FlatSliderUI());
    s.setOpaque(false);

    s.setForeground(accent);
    s.setBorder(BorderFactory.createEmptyBorder());
    return s;
  }

  JLabel makeLabel(String text) {
    JLabel label = new JLabel(text);
    label.setForeground(fgText);
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



  void openColorPicker() {
    if (isUpdating) return;
    if (!(activeLayer instanceof TextLayer)) return;
    TextLayer tl = (TextLayer) activeLayer;

    int initialCol = tl.fillCol;
    final boolean[] committed = new boolean[] { false };

    ColorPickerDialog dlg = new ColorPickerDialog(
      SwingUtilities.getWindowAncestor(root),
      initialCol,
      (previewCol) -> {
        // Live preview without flooding history.
        if (isUpdating) return;
        isUpdating = true;
        tl.setFillCol(previewCol);
        updateColorSwatch(previewCol);
        doc.markChanged();
        isUpdating = false;
      },
      (commitCol) -> {
        committed[0] = true;
        applyTextColorChange(commitCol);
      }
    );

    dlg.addWindowListener(new java.awt.event.WindowAdapter() {
      @Override public void windowClosing(java.awt.event.WindowEvent e) {
        if (!committed[0]) {
          tl.setFillCol(initialCol);
          updateColorSwatch(initialCol);
          doc.markChanged();
        }
      }
      @Override public void windowClosed(java.awt.event.WindowEvent e) {
        if (!committed[0]) {
          tl.setFillCol(initialCol);
          updateColorSwatch(initialCol);
          doc.markChanged();
        }
      }
    });

    dlg.setVisible(true);
  }


  void applyTextColorChange(int col) {
    if (isUpdating) return;
    if (!(activeLayer instanceof TextLayer)) return;
    TextLayer tl = (TextLayer) activeLayer;
    app.history.perform(doc, new SetTextColorCommand(tl, col));
    updateColorSwatch(col);
  }

  void updateColorSwatch(int col) {
    if (btnTextColor == null) return;
    btnTextColor.setBackground(toAwtColor(col));
  }

  Color toAwtColor(int col) {
    return new Color((int)parent.red(col), (int)parent.green(col), (int)parent.blue(col), (int)parent.alpha(col));
  }


  JPanel makeSectionBlock(String title) {
    JPanel panel = new JPanel();
    panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
    panel.setAlignmentX(Component.LEFT_ALIGNMENT);
    panel.setPreferredSize(new Dimension(280,150));
    panel.setMaximumSize(new Dimension(280, Integer.MAX_VALUE));
    panel.setOpaque(true);
    panel.setBackground(bgBlock);
    panel.setBorder(BorderFactory.createCompoundBorder(
      BorderFactory.createLineBorder(new Color(70, 70, 70)),
      BorderFactory.createEmptyBorder(10, 10, 10, 10)
    ));

    JLabel header = new JLabel(title);
    JPanel head=new JPanel();
    head.setLayout(new FlowLayout(FlowLayout.LEFT));
    head.setOpaque(false);
    header.setForeground(fgText);
    header.setFont(header.getFont().deriveFont(Font.BOLD));
    header.setBorder(BorderFactory.createEmptyBorder(0, 0, 0, 0));
    head.add(header);
    head.setMaximumSize(new Dimension(Integer.MAX_VALUE,32));
    panel.add(head);
    return panel;

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
    label.setForeground(fgMuted);
    return label;
  }



  JPanel makeFilterBlock(String title) {
    return makeSectionBlock(title);
  }

JTextField styledField(String text) {
  JTextField field = new JTextField(text, 5);
  return field;
}


  void styleSpinner(JSpinner spinner) {
    if (spinner.getEditor() instanceof JSpinner.DefaultEditor) {
      JSpinner.DefaultEditor editor = (JSpinner.DefaultEditor) spinner.getEditor();
    }
  }

  void addGaussianBlurControls(GaussianBlurFilter filter) {
    
    JPanel block = makeFilterBlock("Gaussian Blur");

    JTextField radiusField = styledField(String.valueOf(filter.radius));
    JSlider radiusSlider = buildSlider(0, 50, filter.radius);
    JTextField sigmaField = styledField(String.valueOf(filter.sigma));
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

    JTextField valueField = styledField(String.format("%.2f", filter.value));
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

    JTextField valueField = styledField(String.format("%.2f", filter.value));
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
    activeLayer.filterdirty = true;
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
