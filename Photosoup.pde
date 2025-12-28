/*
Group Member:
    Lirong Zeng 2717396
    Weixi Xiong 2727565
    Boyu Li     2717266
    Chenxin Wan 2717388
    Henwen shi  2717478

AI declaration:
In order to make sure codes are shown in a right way, we make our AI declaration in the file "AI Declaration.markdown".



*/

import java.awt.*;
import java.awt.event.*;
import java.awt.datatransfer.*;
import javax.swing.*;
import javax.swing.event.*;
import processing.awt.PSurfaceAWT;
import javax.swing.text.*;
import javax.swing.border.TitledBorder;
import java.awt.image.BufferedImage;
import java.util.function.IntConsumer;
import javax.swing.border.EmptyBorder;
import com.formdev.flatlaf.FlatLightLaf;
App app;

// Prompt the user for canvas size before initializing the app.
CanvasSpec promptForCanvasSize()  {
    final JTextField widthField = new JTextField("1920", 6);
    final JTextField heightField = new JTextField("1080", 6);
    final JLabel ratioLabel = new JLabel("16 : 9");
    
    AspectPreviewPanel preview = new AspectPreviewPanel(widthField, heightField);
    preview.setOpaque(true);
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
    //Ensure ratio starts simplified with defaults.
    updateRatio.run();
    
    JPanel fields = new JPanel(new GridBagLayout());
    GridBagConstraints gc = new GridBagConstraints();
    gc.insets = new Insets(8,8,8,8);
    gc.gridy = 0;
    gc.gridx = 0;
    gc.fill = GridBagConstraints.HORIZONTAL;
    
    fields.add(new JLabel("Width (px)"),gc);
    gc.gridx = 1;
    fields.add(widthField,gc);
    gc.gridy = 1;
    gc.gridx = 0;
    fields.add(new JLabel("Height (px)"),gc);
    gc.gridx = 1;
    fields.add(heightField,gc);
    
    JPanel previewHolder = new JPanel(new BorderLayout());
    previewHolder.setPreferredSize(new Dimension(220, 160));
    previewHolder.setBorder(BorderFactory.createCompoundBorder(
        BorderFactory.createLineBorder(new Color(100, 100, 100)),
        BorderFactory.createEmptyBorder(6, 6, 6, 6)
    ));
    JPanel previewHeader = new JPanel(new BorderLayout());
    previewHeader.setOpaque(false);
    previewHeader.setBorder(BorderFactory.createEmptyBorder(6, 0, 6, 0));
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
        "Setcanvas size",
        JOptionPane.OK_CANCEL_OPTION,
        JOptionPane.PLAIN_MESSAGE
          );
    
    int w = parsePositiveInt(widthField.getText(), 1920);
    int h = parsePositiveInt(heightField.getText(), 1080);
    if(w <= 0) w = 1920;
    if(h <= 0) h = 1080;
    
    //If the user cancels, fall back to defaults.
    if(result != JOptionPane.OK_OPTION) {
        w = 1920;
        h = 1080;
}
    
    return new CanvasSpec(w, h);
}

int parsePositiveInt(String text, int fallback) {
    try {
        return Math.max(1, Integer.parseInt(text.trim()));
} catch(Exception e) {
        return fallback;
}
}

int gcd(int a, int b) {
    a = Math.abs(a);
    b = Math.abs(b);
    if(a == 0) return b;
    if(b == 0) return a;
    while(b != 0) {
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
    
    void paintComponent(Graphics g) {
        super.paintComponent(g);
        Graphics2D g2 = (Graphics2D) g;
        int widthVal = parsePositiveInt(wField.getText(), 1920);
        int heightVal = parsePositiveInt(hField.getText(), 1080);
        
        int padding = 12;
        int availW = Math.max(1, getWidth() - padding * 2);
        int availH = Math.max(1, getHeight() - padding * 2);
        
        double scale = Math.min(availW / (double) widthVal, availH / (double) heightVal);
        int rectW = Math.max(1,(int) Math.round(widthVal * scale));
        int rectH = Math.max(1,(int) Math.round(heightVal * scale));
        
        int x = (getWidth() - rectW) / 2;
        int y = (getHeight() - rectH) / 2;
        
        //g2.setColor(new Color(235, 235, 235));
        g2.fillRect(0, 0, getWidth(), getHeight());
        
        g2.setColor(new Color(120, 180, 255, 80));
        g2.fillRect(x, y, rectW, rectH);
        g2.setColor(new Color(50, 120, 220));
        g2.drawRect(x, y, rectW, rectH);
}
}

// ---------- Processing entry ----------

void settings() {
    pixelDensity(1);
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
void setupFlatLaf() {
    try {
        UIManager.setLookAndFeel(new FlatLightLaf());
} catch(UnsupportedLookAndFeelException e) {
        e.printStackTrace();
}
}
static void setupTextFieldStyle() {
    UIManager.put("Component.arc", 8);
    UIManager.put("Component.focusWidth", 1);
    UIManager.put("Component.innerFocusWidth", 0);
    UIManager.put("TextComponent.margin", new Insets(3, 8, 3, 8));
    UIManager.put("TextComponent.selectionBackground", new Color(120, 120, 120, 140));
    UIManager.put("TextComponent.selectionForeground", Color.WHITE);
    UIManager.put("TextComponent.caretForeground", new Color(230, 230, 230));
}
static void setupButtonStyle() {
    UIManager.put("Component.arc", 12);
    UIManager.put("Component.focusWidth", 1);
    UIManager.put("Component.innerFocusWidth", 0);
    
    
    UIManager.put("Button.margin", new Insets(8, 14, 8, 14));
    UIManager.put("Button.borderWidth", 1);
    UIManager.put("Button.disabledText", new Color(160, 160, 160));
}
static void setupTabbedPaneStyle() {
    UIManager.put("TabbedPane.showTabSeparators", false);
    UIManager.put("TabbedPane.tabHeight", 28);
    UIManager.put("TabbedPane.tabInsets", new Insets(6, 12, 6, 12));
}
static void setupScrollBarStyle() {
    UIManager.put("ScrollBar.width", 10);                 
    UIManager.put("ScrollBar.thumbArc", 999);
    UIManager.put("ScrollBar.trackArc", 999); 
}
static void setupSliderStyle() {
    UIManager.put("Slider.trackWidth", 4);
    UIManager.put("Slider.thumbSize", new java.awt.Dimension(12, 12));
}
static void setupListStyle() {
    UIManager.put("List.background", new Color(45, 45, 45));
    UIManager.put("List.foreground", new Color(220, 220, 220));
    UIManager.put("List.selectionBackground", new Color(90, 90, 90));
    UIManager.put("List.selectionForeground", Color.WHITE);
    UIManager.put("List.background", new Color(60, 60, 60));
    UIManager.put("List.foreground", new Color(220, 220, 220));
    UIManager.put("List.focusCellHighlightBorder", BorderFactory.createEmptyBorder());
    UIManager.put("List.cellPadding", new Insets(8,10,8,10));
    
}
static void setupCombox() {
    UIManager.put("Component.arc", 10);
    UIManager.put("ComboBox.arc", 10);
    UIManager.put("ComboBox.padding", new Insets(2,6,1,6));
    UIManager.put("ComboBox.sizeVariant", "small");
    UIManager.put("ComboBox.buttonSeparatorWidth", 0);
    UIManager.put("ComboBox.maximumRowCount", 12);
}
static void setupSpinner() {
    UIManager.put("Spinner.sizeVariant", "small");
    UIManager.put("Spinner.minimumHeight", 24);
    UIManager.put("Spinner.maximumHeight", 26);
    UIManager.put("TextComponent.sizeVariant", "small");
    UIManager.put("TextComponent.margin", new Insets(4, 6, 4, 6));
    UIManager.put("Component.focusWidth", 1);
    UIManager.put("Component.innerFocusWidth", 0);
    
}
void setup() {
    FlatDarkLaf.setup();
    setupTabbedPaneStyle();
    setupScrollBarStyle();
    setupSliderStyle();
    setupTextFieldStyle();
    setupButtonStyle();
    setupListStyle();
    setupCombox();
    UIManager.put("Component.focusWidth", 1);
    UIManager.put("Component.innerFocusWidth", 0);
    surface.setTitle("Photosoup");
    CanvasSpec spec = promptForCanvasSize();
    Document doc = new Document(spec.width, spec.height);
    app = new App(this, doc);
    app.doc.view.setFit(app.doc);
    app.ui.layerListPanel.addBlankLayer();
}





void draw() {
    background(30);
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
    if(app != null) app.ui.onFileSelected(app.doc, selection);
    //when a file is selected, the file will be given to app.doc.
}

// export callback
void exportSelected(File selection) {
    if(app != null) app.ui.onExportSelected(app.doc, selection);
}

