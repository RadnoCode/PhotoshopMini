class ViewState {
  float zoom = 1.0;
  float panX = 80;
  float panY = 50;

  public void setFit(Document doc){
    float winW = width;
    float winH = height;

    float canvasW = doc.canvas.width;
    float canvasH = doc.canvas.height;

    float scaleW = winW / canvasW;
    float scaleH = winH / canvasH;
    float s = min(scaleW, scaleH) * 0.9;

    float offsetX = (winW - canvasW * s) / 2;
    float offsetY = (winH - canvasH * s) / 2;

    doc.view.zoom = s;
    doc.view.panX = offsetX;
    doc.view.panY = offsetY;
  }
  void applyTransform() {
    translate(panX, panY);
    scale(zoom);
  }

  public float screenToCanvasX(float MouX) {
    return (MouX - panX) / zoom;
  }
  public float screenToCanvasY(float MouY) {
    return (MouY - panY) / zoom;
  }

  public float canvasToScreenX(float MouX) { 
    return panX + MouX * zoom; 
  }
  public float canvasToScreenY(float MouY) { 
    return panY + MouY * zoom; 
  }

  void zoomAroundMouse(float delta) {// 鼠标向上滚动生成一个负数值，传进来delta
    float oldZoom = zoom;
    float factor = pow(1.10, -delta);
    zoom = constrain(oldZoom * factor, 0.1, 12.0); //限制最大和最小缩放

    float mx = mouseX, my = mouseY;
    float beforeX = (mx - panX) / oldZoom;
    float beforeY = (my - panY) / oldZoom;
    panX = mx - beforeX * zoom;
    panY = my - beforeY * zoom;
  }
}