App app;

// ---------- Processing entry ----------


void settings() {
  int WinHeight=int(displayHeight*0.533);
  int WinWideth=int(displayWidth*0.533);
  size(WinWideth,WinHeight);
}


void setup() {
  surface.setTitle("Crop Demo - Command startYstem (Single File)");
  app = new App();
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
void mouseWheel(MouseEvent event) {
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


