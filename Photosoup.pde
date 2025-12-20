import java.awt.*;
import java.awt.event.*;
import java.awt.datatransfer.*;
import javax.swing.*;
import javax.swing.event.*;
import processing.awt.PSurfaceAWT;
import javax.swing.text.*;


App app;

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
  app = new App(this);
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

