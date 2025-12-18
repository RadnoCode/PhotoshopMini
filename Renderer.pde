class Renderer{
  
  void drawChecker(int w, int h, int s) {
    noStroke();
    for (int y = 0; y+s <= h; y += s) {
      for (int x = 0; x+s <= w; x += s) {
        int v = ((x/s + y/s) % 2 == 0) ? 60 : 80;
        fill(v);
        rect(x, y, s, s);
      }
    }
  }// 棋盘格
  
  void draw(Document doc, ToolManager tools) {
    pushMatrix();
    doc.view.applyTransform();

    drawChecker(doc.canvas.w, doc.canvas.h, 20);

    for(int i=0;i<doc.layers.list.size();i++){
      Layer l=doc.layers.list.get(i);
      if(l==null||l.img==null||l.visible==false){
        continue;
      }
      pushMatrix();
      l.applyTransform();
      tint(255,255*l.opacity);
      image(l.img, 0, 0);
      noTint();
      popMatrix();
    }
    /*draw active layer only (MVP)
    Layer active = doc.layers.getActive();
    if (active != null && active.img != null && active.visible) { 
      pushMatrix();
      active.applyTransform();
      tint(255, 255 * active.opacity);
      image(active.img, 0, 0);
      noTint();
      popMatrix();
    }*/

    // canvas border
    noFill();
    stroke(200);
    rect(0, 0, doc.canvas.w, doc.canvas.h);

    // tool overlay in canvas coords
    tools.drawOverlay(doc);

    popMatrix();

    // tiny hint
    fill(200);
    textSize(12);
    text("Shortcuts: O Open | M Move | C Crop | Ctrl/Cmd+Z Undo | Ctrl/Cmd+Y Redo", 12, height - 12);
  }
}


class RenderFlags {
  boolean dirtyComposite = true;
}