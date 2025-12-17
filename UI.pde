import javax.swing.*;
import javax.swing.event.*;
import java.awt.*;
import java.awt.event.*;

class UI {

  Document doc;

  int RightpanelW = 170;
  int RightpanelX =width-RightpanelW;
  int LeftPannelW=64;


  UIButton btnOpen, btnMove, btnCrop, btnUndo, btnRedo;

  JFrame layerFrame;
  LayerListPanel layerListPanel;

  UI(Document doc) {
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

    SwingUtilities.invokeLater(() -> {
      layerListPanel = new LayerListPanel(doc);
      layerFrame = new JFrame("Layers");
      layerFrame.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
      layerFrame.getContentPane().add(layerListPanel);
      layerFrame.pack();
      layerFrame.setLocation(50, 50);
      layerFrame.setVisible(true);
    });
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

    if (layerListPanel != null) {
      layerListPanel.refreshIfNeeded();
    }
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

    boolean firstLayer = doc.layers.isEmpty();
    String layerName = selection.getName();
    doc.layers.addLayerOnTop(new Layer(img, layerName));
    if (firstLayer) {
      doc.canvas.w = img.width;
      doc.canvas.h = img.height;
    }

    // reset view (optional)
    doc.view.zoom = 1.0;
    doc.view.panX = 80;
    doc.view.panY = 50;

    doc.renderFlags.dirtyComposite = true;

    if (layerListPanel != null) {
      layerListPanel.markDirty();
    }
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

class LayerListPanel extends JPanel {
  Document doc;
  DefaultListModel<Layer> model = new DefaultListModel<Layer>();
  JList<Layer> list = new JList<Layer>(model);
  int lastVersion = -1;
  int pressedIndex = -1;
  boolean updatingSelection = false;

  LayerListPanel(Document doc) {
    this.doc = doc;
    setLayout(new BorderLayout());

    list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    list.setCellRenderer(new LayerCellRenderer());
    list.setFixedCellHeight(48);
    JScrollPane scrollPane = new JScrollPane(list);
    add(scrollPane, BorderLayout.CENTER);

    list.addListSelectionListener(new ListSelectionListener() {
      public void valueChanged(ListSelectionEvent e) {
        if (e.getValueIsAdjusting()) return;
        if (updatingSelection) return;
        int idx = list.getSelectedIndex();
        if (idx >= 0) {
          doc.layers.setActive(idx);
        }
      }
    });

    list.addMouseListener(new MouseAdapter() {
      public void mousePressed(MouseEvent e) {
        pressedIndex = list.locationToIndex(e.getPoint());
      }

      public void mouseReleased(MouseEvent e) {
        int releaseIndex = list.locationToIndex(e.getPoint());
        if (pressedIndex >= 0 && releaseIndex >= 0 && pressedIndex != releaseIndex) {
          doc.layers.moveLayer(pressedIndex, releaseIndex);
          refreshFromDoc();
        }
        pressedIndex = -1;
      }

      public void mouseClicked(MouseEvent e) {
        int idx = list.locationToIndex(e.getPoint());
        if (idx < 0) return;

        if (isEyeClick(e.getPoint())) {
          doc.layers.toggleVisibility(idx);
          refreshFromDoc();
          return;
        }

        if (e.getClickCount() == 2) {
          Layer target = doc.layers.get(idx);
          String newName = JOptionPane.showInputDialog(LayerListPanel.this, "Rename layer", target == null ? "" : target.name);
          if (newName != null) {
            doc.layers.rename(idx, newName);
            refreshFromDoc();
          }
          return;
        }

        list.setSelectedIndex(idx);
      }
    });

    setPreferredSize(new Dimension(240, 360));
    refreshFromDoc();
  }

  boolean isEyeClick(Point p) {
    return p.x < 28;
  }

  void markDirty() {
    lastVersion = -1;
  }

  void refreshIfNeeded() {
    if (doc == null) return;
    if (doc.layers.version != lastVersion) {
      refreshFromDoc();
    }
  }

  void refreshFromDoc() {
    Runnable update = new Runnable() {
      public void run() {
        model.clear();
        for (Layer layer : doc.layers.list) {
          model.addElement(layer);
        }
        if (doc.layers.activeIndex >= 0 && doc.layers.activeIndex < model.size()) {
          updatingSelection = true;
          list.setSelectedIndex(doc.layers.activeIndex);
          updatingSelection = false;
        }
        lastVersion = doc.layers.version;
      }
    };
    if (SwingUtilities.isEventDispatchThread()) update.run();
    else SwingUtilities.invokeLater(update);
  }
}

class LayerCellRenderer extends JPanel implements ListCellRenderer<Layer> {
  JLabel eyeLabel = new JLabel();
  JLabel nameLabel = new JLabel();
  JLabel blendLabel = new JLabel();

  LayerCellRenderer() {
    setLayout(new BorderLayout(8, 0));
    setBorder(BorderFactory.createEmptyBorder(6, 8, 6, 8));

    JPanel textPanel = new JPanel(new BorderLayout());
    textPanel.setOpaque(false);
    blendLabel.setFont(blendLabel.getFont().deriveFont(10f));

    textPanel.add(nameLabel, BorderLayout.CENTER);
    textPanel.add(blendLabel, BorderLayout.SOUTH);

    add(eyeLabel, BorderLayout.WEST);
    add(textPanel, BorderLayout.CENTER);
  }

  public Component getListCellRendererComponent(JList<? extends Layer> list, Layer value, int index, boolean isSelected, boolean cellHasFocus) {
    eyeLabel.setText(value != null && value.visible ? "👁" : "🚫");
    nameLabel.setText(value == null ? "" : value.name);
    blendLabel.setText(value == null ? "" : value.blendMode);

    Color bg = isSelected ? new Color(70, 120, 200) : new Color(60, 60, 60);
    Color fg = Color.WHITE;
    setBackground(bg);
    nameLabel.setForeground(fg);
    blendLabel.setForeground(fg.brighter());
    setOpaque(true);
    return this;
  }
}
