# AI declaration

We acknowledge the use of <ChatGPT5 <https://chatgpt.com>> to strucure the assssment.

We acknowledge the use of <insert AI system(s) and link> to generate materials
that were included in my final assessment in unmodified form.
## Example:
    
Prompt:I’m currently facing a problem. I want to crop a single photo, but my current cropping logic crops the entire canvas along with all layers. I’d like to know how I can add a new cropping logic, and how this cropping logic should work.

---
    Output:
    
## Core Idea (The Big Picture)

👉 **Do not immediately modify pixel data when cropping**
👉 **Cropping should first be a view, constraint, or mask**

In other words:

* **Canvas crop** affects what part of the world is visible
* **Layer crop** affects what part of a single layer is visible
* **Destructive crop** (real pixel cutting) should only happen when exporting or when the user explicitly confirms “Apply Crop”

This is essentially how Photoshop works internally, even though the UI hides it.

---

## Why Your Current Cropping Feels Wrong

Your current logic is likely:

```text
Crop →
  Resize canvas →
    All layers get cropped together
```

This causes three problems:

1. ❌ Original pixels are lost (hard to undo)
2. ❌ You cannot crop a single image independently
3. ❌ You cannot distinguish canvas crop vs layer crop

So the key is to **decouple cropping from canvas resizing**.

---

## The Three Types of Cropping You Should Separate

### 1️⃣ Canvas Crop

**Cropping the visible world**

* Does not modify any layer data
* Only changes the visible region of the canvas
* Layers still exist outside the visible area

**Conceptually:** viewport / clip rectangle

---

### 2️⃣ Layer Crop (What You Need Now)

**Cropping what a single layer is allowed to display**

* Affects only one layer
* Other layers remain untouched
* Original image data is preserved

**Conceptually:** layer-level mask or clip rectangle

---

### 3️⃣ Destructive Crop

**Actually cutting pixels**

* Changes the PImage / PGraphics size
* Irreversible
* Should be an explicit command

**Conceptually:** data mutation

---

## What You Should Implement First

👉 **Non-destructive layer cropping**

This matches your requirement:
“Crop a single photo without cropping the entire canvas.”

---

## Correct Data Model for Layer Cropping

Add a crop rectangle to your `Layer` class:

```java
class Layer {
  PGraphics img;

  boolean hasCrop = false;
  Rect crop; // x, y, width, height (layer-local)

  float x, y;
  float scale;
  float rotation;
}
```

This crop rectangle does **not** remove pixels.
It only restricts what part of the layer can be drawn.

---

## How Cropping Works During Rendering (Critical Part)

Cropping logic belongs in the **Renderer**, not in the data model.

Using Processing’s `clip()`:

```java
pg.pushMatrix();
l.applyTransform();

if (l.hasCrop) {
  pg.clip(
    l.crop.x,
    l.crop.y,
    l.crop.w,
    l.crop.h
  );
}

pg.image(l.img, 0, 0);

// Always clear the clip
pg.noClip();

pg.popMatrix();
```

### Mental model

```text
Layer image is complete
↓
Cropping only hides part of it during drawing
```

---

## What the Crop Tool Actually Does

The crop tool is **not cutting pixels**.

Instead, it:

1. Draws a selection rectangle (UI only)
2. Lets the user adjust it
3. On mouse release:

```java
layer.crop = selectedRect;
layer.hasCrop = true;
```

This is lightweight and fully undoable.

---

## Integrating with Your Command System

Your existing Command architecture fits perfectly:

```java
class CropLayerCommand implements Command {
  int layerId;
  Rect before;
  Rect after;

  void undo() {
    layer.crop = before;
  }

  void redo() {
    layer.crop = after;
  }
}
```

✅ Non-destructive
✅ Fully undoable
✅ Clean architecture

---

## What Happens on Export

Exporting is separate from on-screen rendering.

Typical export flow:

```text
1. Create a new PGraphics (exportPG)
2. Apply canvas crop as clip
3. For each layer:
   - Apply layer crop
   - Draw image
4. Save exportPG
```

This gives you:

* Flexible on-screen editing
* Correct final output
* Full project data preserved in memory

---

## When Should You Actually Destroy Pixels?

Only when the UI explicitly says:

> **“Apply Crop (Destructive)”**

Then you do:

```java
PImage newImg = layer.img.get(
  crop.x, crop.y, crop.w, crop.h
);
layer.img = newImg;
layer.hasCrop = false;
```

This matches user expectations and professional editor behavior.

---

## One Architecture Rule to Remember

> In editors, most operations like cropping, scaling, and alignment
> should first be **display rules**,
> not **data mutations**.

---

If you want, next I can:

* Design a full `CropTool` state machine
* Connect it cleanly to `ToolManager` and `ViewState`
* Provide a minimal demo for single-layer crop + export

You are already thinking like a professional editor designer. This is just sharpening the blade.

---

How do we use the material generated by AI:
We use the idea of cropping the view instand and write by oursleves.