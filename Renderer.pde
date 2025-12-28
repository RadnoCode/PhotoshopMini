class Renderer{

  Renderer() {
  }
  void drawChecker(Document doc,int w, int h, int s) {
    pushMatrix();
    doc.view.applyTransform();
    if (doc.checkerCache == null
      || doc.checkerCache.width != doc.canvas.width
      || doc.checkerCache.height != doc.canvas.height
      || doc.checkerTileSize != s) {
      doc.buildChecker(s);
    }
    // Only paint the current view area so the checkerboard matches the cropped bounds.
    image(doc.checkerCache,
      doc.viewX, doc.viewY, doc.viewW, doc.viewH,
      doc.viewX, doc.viewY, doc.viewW, doc.viewH);
    popMatrix();
  }

  //draw layers to canvas
  void drawCanvas(Document doc,ToolManager tools){
    if (!doc.renderFlags.dirtyComposite) {
      return;
    }
    PGraphics pg=doc.canvas;
    pg.beginDraw();
    pg.clear();
    pg.stroke(255,0,0);
    pg.clip(doc.viewX, doc.viewY, doc.viewW, doc.viewH);


    for(int i=0;i<doc.layers.list.size();i++){
      Layer l=doc.layers.list.get(i);
      // Skip empty entries and hidden layers. Allow text layers (img can be null).
      if (l == null || !l.visible || (l.img == null && !(l instanceof TextLayer))) {
        continue;
      }
      pg.pushMatrix();
      pg.translate(l.x,l.y);
      pg.translate(l.pivotX,l.pivotY);
      pg.rotate(l.rotation);
      pg.scale(l.scale);
  
      l.drawSelf(doc);
      pg.popMatrix();
      
    }
    pg.noClip();

    pg.endDraw();
    doc.renderFlags.dirtyComposite = false;
  }
  //draw canvas to screen
  void drawToScreen(Document doc,ToolManager tools){
    pushMatrix();
    doc.view.applyTransform();
    image(doc.canvas,0,0);
    tools.drawOverlay(doc);
    popMatrix();


  }
}


class RenderFlags {
  boolean dirtyComposite = true;
}
