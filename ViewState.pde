class ViewState {
  float zoom = 1.0;
  float panX = 80;
  float panY = 50;

  void applyTransform() {
    translate(panX, panY);
    scale(zoom);
  }

  // Center the canvas inside the current Processing window with optional left/right
  // padding so it stays visible when side panels are present.
  void centerOnCanvas(int canvasW, int canvasH, int leftPadding, int rightPadding) {
    float availableW = width - (leftPadding + rightPadding);
    float availableH = height;

    float desiredX = leftPadding + (availableW - canvasW) * 0.5;
    float desiredY = (availableH - canvasH) * 0.5;

    // Leave a small gap so the canvas border is visible even when the image is large.
    panX = max(leftPadding + 10, desiredX);
    panY = max(10, desiredY);
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