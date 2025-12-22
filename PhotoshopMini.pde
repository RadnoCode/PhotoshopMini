import java.awt.*;
import java.awt.event.*;
import java.awt.datatransfer.*;
import javax.swing.*;
import javax.swing.event.*;
import processing.awt.PSurfaceAWT;
import javax.swing.text.*;
import javax.swing.border.TitledBorder;


App app;

// Prompt the user for canvas size before initializing the app.
CanvasSpec promptForCanvasSize() {
  final JTextField widthField = new JTextField("1920", 6);
  final JTextField heightField = new JTextField("1080", 6);
  final JLabel ratioLabel = new JLabel("16 : 9");

  AspectPreviewPanel preview = new AspectPreviewPanel(widthField, heightField);

  Runnable updateRatio = new Runnable() {
    public void run() {
      int w = parsePositiveInt(widthField.getText(), 1920);
      int h = parsePositiveInt(heightField.getText(), 1080);
      int d = gcd(w, h);
      ratioLabel.setText((w / d) + " : " + (h / d));
      preview.repaint();
    }
  };

  javax.swing.event.DocumentListener listener = new javax.swing.event.DocumentListener() {
    public void insertUpdate(javax.swing.event.DocumentEvent e) { updateRatio.run(); }
    public void removeUpdate(javax.swing.event.DocumentEvent e) { updateRatio.run(); }
    public void changedUpdate(javax.swing.event.DocumentEvent e) { updateRatio.run(); }
  };
  widthField.getDocument().addDocumentListener(listener);
  heightField.getDocument().addDocumentListener(listener);
  // Ensure ratio starts simplified with defaults.
  updateRatio.run();

  JPanel fields = new JPanel(new GridLayout(2, 2, 8, 8));
  fields.add(new JLabel("Width (px)"));
  fields.add(widthField);
  fields.add(new JLabel("Height (px)"));
  fields.add(heightField);

  JPanel previewHolder = new JPanel(new BorderLayout());
  previewHolder.setPreferredSize(new Dimension(220, 160));
  previewHolder.setBorder(BorderFactory.createCompoundBorder(
    BorderFactory.createLineBorder(new Color(200, 200, 200)),
    BorderFactory.createEmptyBorder(6, 6, 6, 6)
  ));
  JPanel previewHeader = new JPanel(new BorderLayout());
  previewHeader.setOpaque(false);
  previewHeader.add(new JLabel("Aspect preview"), BorderLayout.WEST);
  previewHeader.add(ratioLabel, BorderLayout.EAST);
  previewHolder.add(previewHeader, BorderLayout.NORTH);
  previewHolder.add(preview, BorderLayout.CENTER);

  JPanel container = new JPanel(new BorderLayout(12, 0));
  container.add(fields, BorderLayout.WEST);
  container.add(previewHolder, BorderLayout.CENTER);

  int result = JOptionPane.showConfirmDialog(
    null,
    container,
    "Set canvas size",
    JOptionPane.OK_CANCEL_OPTION,
    JOptionPane.PLAIN_MESSAGE
  );

  int w = parsePositiveInt(widthField.getText(), 1920);
  int h = parsePositiveInt(heightField.getText(), 1080);
  if (w <= 0) w = 1920;
  if (h <= 0) h = 1080;

  // If the user cancels, fall back to defaults.
  if (result != JOptionPane.OK_OPTION) {
    w = 1920;
    h = 1080;
  }

  return new CanvasSpec(w, h);
}

int parsePositiveInt(String text, int fallback) {
  try {
    return Math.max(1, Integer.parseInt(text.trim()));
  } catch (Exception e) {
    return fallback;
  }
}

int gcd(int a, int b) {
  a = Math.abs(a);
  b = Math.abs(b);
  if (a == 0) return b;
  if (b == 0) return a;
  while (b != 0) {
    int t = b;
    b = a % b;
    a = t;
  }
  return a;
}

class AspectPreviewPanel extends JPanel {
  JTextField wField, hField;
  AspectPreviewPanel(JTextField wField, JTextField hField) {
    this.wField = wField;
    this.hField = hField;
    setPreferredSize(new Dimension(220, 160));
  }

  protected void paintComponent(Graphics g) {
    super.paintComponent(g);
    Graphics2D g2 = (Graphics2D) g;
    int widthVal = parsePositiveInt(wField.getText(), 1920);
    int heightVal = parsePositiveInt(hField.getText(), 1080);

    int padding = 12;
    int availW = Math.max(1, getWidth() - padding * 2);
    int availH = Math.max(1, getHeight() - padding * 2);

    double scale = Math.min(availW / (double) widthVal, availH / (double) heightVal);
    int rectW = Math.max(1, (int) Math.round(widthVal * scale));
    int rectH = Math.max(1, (int) Math.round(heightVal * scale));

    int x = (getWidth() - rectW) / 2;
    int y = (getHeight() - rectH) / 2;

    g2.setColor(new Color(235, 235, 235));
    g2.fillRect(0, 0, getWidth(), getHeight());

    g2.setColor(new Color(120, 180, 255, 80));
    g2.fillRect(x, y, rectW, rectH);
    g2.setColor(new Color(50, 120, 220));
    g2.drawRect(x, y, rectW, rectH);
  }
}

// ---------- Processing entry ----------

void settings() {
  Rectangle usable = GraphicsEnvironment
    .getLocalGraphicsEnvironment()
    .getMaximumWindowBounds();    
    println(usable.width);
    println(usable.height);
  float ratio = 0.90;
  int WinWideth = (int)(usable.width  * ratio);
  int WinHeight = (int)(usable.height * ratio);
  size(WinWideth,WinHeight);
}


void setup() {
  surface.setTitle("Crop Demo - Command startYstem (Single File)");
  CanvasSpec spec = promptForCanvasSize();
  Document doc = new Document(spec.width, spec.height);
  app = new App(this, doc);
  app.doc.view.setFit(app.doc);


}

void draw() {
  background(30);
  //app.update();
  app.render();
}

void mousePressed() {
  app.onMousePressed(mouseX, mouseY, mouseButton);
}
void mouseDragged() {
  app.onMouseDragged(mouseX, mouseY, mouseButton);
}
void mouseReleased() {
  app.onMouseReleased(mouseX, mouseY, mouseButton);
}
void mouseWheel(processing.event.MouseEvent event) {
  app.onMouseWheel(event.getCount());
}
void keyPressed() {
  app.onKeyPressed(key);
}

// selectInput callback must be global
void fileSelected(File selection) {
  if (app != null) app.ui.onFileSelected(app.doc, selection);
  // when a file is selected, the file will be given to app.doc.
}

// export callback
void exportSelected(File selection) {
  if (app != null) app.ui.onExportSelected(app.doc, selection);
}

