interface DrawObjectFactory {
  String getName();
  boolean requireFile();
  DrawObject create(File f);
}

class DrawGroupFactory implements DrawObjectFactory {
  int count = 0;
  
  String getName() {
    return "Group";
  }
  
  boolean requireFile() {
    return false;
  }
  
  DrawObject create(File f) {
    return new DrawGroup("Group " + (++count));
  }
}

class DrawBackgroundFactory implements DrawObjectFactory {
  int count = 0;
  
  String getName() {
    return "Background";
  }
  
  boolean requireFile() {
    return false;
  }
  
  DrawObject create(File f) {
    return new DrawBackground("Background " + (++count));
  }
}

class DrawImageFactory implements DrawObjectFactory {
  String getName() {
    return "Image";
  }
  
  boolean requireFile() {
    return true;
  }
  
  DrawObject create(File f) {
    return new DrawImage(f);
  }
}

class DrawTextFactory implements DrawObjectFactory {
  String getName() {
    return "Text";
  }
  
  boolean requireFile() {
    return false;
  }
  
  DrawObject create(File f) {
    return new DrawText();
  }
}

class DrawRectangleFactory implements DrawObjectFactory {
  int count = 0;
  
  String getName() {
    return "Rectangle";
  }
  
  boolean requireFile() {
    return false;
  }
  
  DrawObject create(File f) {
    return new DrawRectangle("Rectangle " + (++count));
  }
}