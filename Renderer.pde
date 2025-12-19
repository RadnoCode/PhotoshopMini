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
  void drawCanvas(Document doc,ToolManager tools){
    PGraphics pg=doc.canvas;
    pg.beginDraw();
    pg.clear();
    pg.stroke(255,0,0);
    pg.clip(doc.viewX, doc.viewY, doc.viewW, doc.viewH);


    for(int i=0;i<doc.layers.list.size();i++){
      Layer l=doc.layers.list.get(i);
      if(l==null||l.visible==false||(l.img==null)){
        continue;
      }
      pg.pushMatrix();

      pg.translate(l.x,l.y);
      pg.translate(l.pivotX,l.pivotY);
      pg.rotate(l.rotation);
      pg.scale(l.scale);

      pg.tint(255,255*l.opacity);
      pg.image(l.img,-l.pivotX,-l.pivotY);
      pg.noTint();
      pg.popMatrix();
      
    }
    pg.noClip();

    pg.endDraw();
  }
  void drawToScreen(Document doc,ToolManager tools){
    pushMatrix();
    doc.view.applyTransform();
    image(doc.canvas,0,0);
    tools.drawOverlay(doc);
    popMatrix();


  }
  /*
  void draw(Document doc, ToolManager tools) {
    pushMatrix();
    doc.view.applyTransform();

    drawChecker(pg.width, pg.height, 20);

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

    // canvas border
    noFill();
    stroke(200);
    rect(0, 0, pg.width, pg.height);

    // tool overlay in canvas coords
    tools.drawOverlay(doc);

    popMatrix();

    // tiny hint
    fill(200);
    textSize(12);
    text("Shortcuts: O Open | M Move | C Crop | Ctrl/Cmd+Z Undo | Ctrl/Cmd+Y Redo", 12, height - 12);
  }*/
}


class RenderFlags {
  boolean dirtyComposite = true;
}