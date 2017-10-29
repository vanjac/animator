abstract class DrawObject {
  
  String name;
  Property xPosition, yPosition;
  Property scale, horizScale, vertScale;
  Property rotation;

  public ArrayList<Property> properties;
  public ArrayList<StringProperty> stringProperties;
  
  public ArrayList<DrawObject> children;
  
  DrawObject(String name) {
    this.name = name;
    xPosition = new Property("Move X", 0, 1);
    yPosition = new Property("Move Y", 0, 1);
    scale = new Property("Scale", 1, 0.01);
    horizScale = new Property("Stretch H", 1, 0.01, false);
    vertScale = new Property("Stretch V", 1, 0.01, false);
    rotation = new Property("Rotate", 0, 5);
    
    properties = new ArrayList<Property>();
    properties.add(xPosition);
    properties.add(yPosition);
    properties.add(rotation);
    properties.add(scale);
    properties.add(horizScale);
    properties.add(vertScale);
    stringProperties = new ArrayList<StringProperty>();
    
    children = new ArrayList<DrawObject>();
  }
  
  boolean allowChildren() {
    return false;
  }
  
  void draw(PGraphics g, int time) {
    if(xPosition.enabled || yPosition.enabled || rotation.enabled
        || scale.enabled || horizScale.enabled || vertScale.enabled) {
      g.pushMatrix();
      if(xPosition.enabled || yPosition.enabled)
        g.translate(xPosition.valueAtTime(time), yPosition.valueAtTime(time));
      if(rotation.enabled)
        g.rotate(radians(rotation.valueAtTime(time)));
      if(scale.enabled || horizScale.enabled || vertScale.enabled) {
        float s = scale.valueAtTime(time);
        g.scale(s * horizScale.valueAtTime(time), s * vertScale.valueAtTime(time));
      }
    }
  }
  
  void postDraw(PGraphics g) {
    if(xPosition.enabled || yPosition.enabled || rotation.enabled
        || scale.enabled || horizScale.enabled || vertScale.enabled)
      g.popMatrix();
  }
  
}

class DrawGroup extends DrawObject {
  DrawGroup(String name) {
    super(name);
  }
  boolean allowChildren() {
    return true;
  }
  void draw(PGraphics g, int time) {
    super.draw(g, time);
    // in reverse order, so the first object appears on top
    for(int i = children.size() - 1; i >= 0; i--) {
      DrawObject child = children.get(i);
      child.draw(g, time);
      child.postDraw(g);
    }
  }
}

abstract class SingleDrawObject extends DrawObject {
  StringProperty blendMode;
  
  SingleDrawObject(String name) {
    super(name);
    blendMode = new StringProperty("Blend Mode", "Blend",
      "Blend,Add,Subtract,Darkest,Lightest,Difference,Exclusion,Multiply,Screen,Replace",
      false);
    stringProperties.add(blendMode);
  }
  
  void draw(PGraphics g, int time) {
    super.draw(g, time);
    if(blendMode.enabled) {
      String bm = blendMode.value;
      if(bm.equals("Add"))
        blendMode(ADD);
      else if(bm.equals("Subtract"))
        blendMode(SUBTRACT);
      else if(bm.equals("Darkest"))
        blendMode(DARKEST);
      else if(bm.equals("Lightest"))
        blendMode(LIGHTEST);
      else if(bm.equals("Difference"))
        blendMode(DIFFERENCE);
      else if(bm.equals("Exclusion"))
        blendMode(EXCLUSION);
      else if(bm.equals("Multiply"))
        blendMode(MULTIPLY);
      else if(bm.equals("Screen"))
        blendMode(SCREEN);
      else if(bm.equals("Replace"))
        blendMode(REPLACE);
    }
  }
  
  void postDraw(PGraphics g) {
    if(blendMode.enabled)
      blendMode(BLEND);
    super.postDraw(g);
  }
}

class DrawBackground extends DrawObject {
  ColorPropertyGroup backgroundColor;
  
  DrawBackground(String name) {
    super(name);
    properties.clear(); // none are relevant
    backgroundColor = new ColorPropertyGroup(color(255,0,0), "Color", "Transparency", true, false);
    backgroundColor.addRGBProperties(properties);
  }
  
  void draw(PGraphics g, int time) {
    super.draw(g, time);
    background(backgroundColor.colorAtTime(time));
  }
}

class DrawImage extends SingleDrawObject {
  PImage image;
  ColorPropertyGroup tintColor;
  
  DrawImage(File f) {
    super(f.getName());
    this.image = loadImage(f.getPath());
    tintColor = new ColorPropertyGroup(color(255), "Tint", "Transparency", false, false);
    tintColor.addProperties(properties);
  }
  
  void draw(PGraphics g, int time) {
    super.draw(g, time);
    if(tintColor.enabled())
      tint(tintColor.colorAtTime(time));
    image(image, -image.width/2, -image.height/2);
  }
  
  void postDraw(PGraphics g) {
    if(tintColor.enabled())
      noTint();
    super.postDraw(g);
  }
}

class DrawText extends SingleDrawObject {
  Property leading;
  ColorPropertyGroup textColor;
  StringProperty horizAlign, vertAlign;
  
  DrawText() {
    super("Text");
    textColor = new ColorPropertyGroup(color(0), "Color", "Transparency", true, false);
    textColor.addProperties(properties);
    leading = new Property("Leading", 19, 1, false);
    horizAlign = new StringProperty("Align H", "Center", "Left,Center,Right", false);
    vertAlign = new StringProperty("Align V", "Baseline", "Top,Center,Baseline,Bottom", false);
    properties.add(leading);
    stringProperties.add(horizAlign);
    stringProperties.add(vertAlign);
  }
  
  void draw(PGraphics g, int time) {
    super.draw(g, time);
    
    int alignX = CENTER;
    String alignXValue = horizAlign.value;
    if(alignXValue.equals("Left"))
      alignX = LEFT;
    else if(alignXValue.equals("Center"))
      alignX = CENTER;
    else if(alignXValue.equals("Right"))
      alignX = RIGHT;
    int alignY = BASELINE;
    String alignYValue = vertAlign.value;
    if(alignYValue.equals("Top"))
      alignY = TOP;
    else if(alignYValue.equals("Center"))
      alignY = CENTER;
    else if(alignYValue.equals("Baseline"))
      alignY = BASELINE;
    else if(alignYValue.equals("Bottom"))
      alignY = BOTTOM;
    textAlign(alignX, alignY);
    
    fill(textColor.colorAtTime(time));
    textSize(12);
    if(leading.enabled)
      textLeading(leading.valueAtTime(time));
    text(name.replace("\\n", "\n"), 0, 0);
    textAlign(LEFT, BASELINE);
  }
}

abstract class DrawShape extends SingleDrawObject {
  ColorPropertyGroup fillColor, strokeColor;
  Property strokeWeight;
  StringProperty strokeJoin;
  
  DrawShape(String name) {
    super(name);
    
    fillColor = new ColorPropertyGroup(color(0), "Fill Color", "Fill Transparency", true, false);
    strokeColor = new ColorPropertyGroup(color(0), "Border Color", "Border Transparency", false, false);
    strokeWeight = new Property("Border Size", 0, 0.5, false);
    strokeJoin = new StringProperty("Border Join", "Miter", "Miter,Bevel,Round", false);
    
    fillColor.addProperties(properties);
    properties.add(strokeWeight);
    strokeColor.addProperties(properties);
    stringProperties.add(strokeJoin);
  }
  
  void draw(PGraphics g, int time) {
    super.draw(g, time);
    fill(fillColor.colorAtTime(time));
    stroke(strokeColor.colorAtTime(time));
    float sw = strokeWeight.valueAtTime(time);
    if(sw <= 0)
      noStroke();
    else
      strokeWeight(strokeWeight.valueAtTime(time));
    if(strokeJoin.enabled) {
      String sjValue = strokeJoin.value;
      if(sjValue.equals("Miter"))
        strokeJoin(MITER);
      else if(sjValue.equals("Bevel"))
        strokeJoin(BEVEL);
      else if(sjValue.equals("Round"))
        strokeJoin(ROUND);
    }
  }
  
  void postDraw(PGraphics g) {
    strokeWeight(1);
    stroke(0);
    strokeJoin(MITER);
    super.postDraw(g);
  }
}

class DrawRectangle extends DrawShape {
  Property width, height;
  StringProperty horizAlign, vertAlign;
  
  DrawRectangle(String name) {
    super(name);
    width = new Property("Width", 50, 1);
    height = new Property("Height", 50, 1);
    horizAlign = new StringProperty("Align H", "Center", "Left,Center,Right", false);
    vertAlign = new StringProperty("Align V", "Center", "Top,Center,Bottom", false);
    properties.add(width);
    properties.add(height);
    stringProperties.add(horizAlign);
    stringProperties.add(vertAlign);
  }
  
  void draw(PGraphics g, int time) {
    super.draw(g, time);
    float w = width.valueAtTime(time);
    float h = height.valueAtTime(time);
    float x = -w/2;
    float y = -h/2;
    if(horizAlign.enabled) {
      if(horizAlign.value.equals("Left"))
        x = 0;
      else if(horizAlign.value.equals("Right"))
        x = -w;
    }
    if(vertAlign.enabled) {
      if(vertAlign.value.equals("Top"))
        y = 0;
      else if(vertAlign.value.equals("Bottom"))
        y = -h;
    }
    rect(x, y, w, h);
  }
}

class DrawEllipse extends DrawShape {
  Property width, height;
  StringProperty horizAlign, vertAlign;
  
  DrawEllipse(String name) {
    super(name);
    width = new Property("Width", 50, 1);
    height = new Property("Height", 50, 1);
    horizAlign = new StringProperty("Align H", "Center", "Left,Center,Right", false);
    vertAlign = new StringProperty("Align V", "Center", "Top,Center,Bottom", false);
    properties.add(width);
    properties.add(height);
    stringProperties.add(horizAlign);
    stringProperties.add(vertAlign);
  }
  
  void draw(PGraphics g, int time) {
    super.draw(g, time);
    float w = width.valueAtTime(time);
    float h = height.valueAtTime(time);
    float x = 0;
    float y = 0;
    if(horizAlign.enabled) {
      if(horizAlign.value.equals("Left"))
        x = w/2;
      else if(horizAlign.value.equals("Right"))
        x = -w/2;
    }
    if(vertAlign.enabled) {
      if(vertAlign.value.equals("Top"))
        y = h/2;
      else if(vertAlign.value.equals("Bottom"))
        y = -h/2;
    }
    ellipse(x, y, w, h);
  }
}