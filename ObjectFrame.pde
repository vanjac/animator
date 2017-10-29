public class ObjectFrame extends PApplet {
  
  class ObjectListEntry {
    final DrawObject object, parent;
    
    ObjectListEntry(DrawObject object, DrawObject parent) {
      this.object = object;
      this.parent = parent;
    }
  }
  
  animator parent;
  ControlP5 cp5;
  
  ScrollableList objectList;
  ScrollableList addList;
  Toggle moveToggle;
  
  DrawObject rootObject = null;
  ObjectListEntry movingEntry;
  
  boolean updateList = false;
  boolean fixAddList = false;
  
  ObjectFrame(animator parent) {
    super();   
    this.parent = parent;
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }
  
  void settings() {
    size(250, 480);
  }

  void setup() {
    surface.setResizable(true);
    surface.setLocation(920, 10);
    surface.setTitle("Objects");
    cp5 = new ControlP5(this);
    
    cp5.addButton("remove")
      .setPosition(64, 0)
      .setSize(62, 32);
    moveToggle = cp5.addToggle("move")
      .setPosition(128, 0)
      .setSize(62, 32);
    moveToggle.getCaptionLabel()
      .alignX(CENTER)
      .alignY(CENTER);
    objectList = cp5.addScrollableList("objects")
      .setType(ControlP5.LIST)
      .setPosition(0,36)
      .setSize(width, height);
    addList = cp5.addScrollableList("add")
      .setPosition(0, 0)
      .setSize(62, height)
      .setBarHeight(32)
      .setColorBackground(color(0, 90, 0))
      .close();
    addDrawObjectFactory(new DrawGroupFactory());
    addDrawObjectFactory(new DrawImageFactory());
    addDrawObjectFactory(new DrawTextFactory());
    addDrawObjectFactory(new DrawRectangleFactory());
    addDrawObjectFactory(new DrawEllipseFactory());
    addDrawObjectFactory(new DrawArcFactory());
    addDrawObjectFactory(new DrawBackgroundFactory());
  }
  
  void addDrawObjectFactory(DrawObjectFactory factory) {
    addList.addItem(factory.getName(), factory);
  }
  
  void setRootObject(DrawObject root) {
    rootObject = root;
    updateList = true;
  }
  
  void updateList() {
    updateList = true;
  }
  
  // callback for selecting an object in objectList
  void objects(int n) {
    ObjectListEntry selectedEntry = getEntry(n);
    if(movingEntry == null) {
      parent.propertiesFrame.setSelected(selectedEntry.object);
    } else {
      moveToggle.setBroadcast(false)
        .setState(false)
        .setBroadcast(true);
      
      if(selectedEntry.parent == null || movingEntry.object == selectedEntry.object) {
        movingEntry = null;
        println("Couldn't complete move");
        return;
      }
      
      parent.objectsLock.lock();
      try {
        movingEntry.parent.children.remove(movingEntry.object);
        insertObject(movingEntry.object, selectedEntry);
      } finally {
        parent.objectsLock.unlock();
        movingEntry = null;
        updateList = true;
      }
    }
  }
  
  void insertObject(DrawObject o, ObjectListEntry location) {
    if(location.parent == null) {
      // root object
      rootObject.children.add(0, o);
    } else if(location.object == null) {
      // END item
      location.parent.children.add(o);
    } else {
      int index = location.parent.children.indexOf(location.object);
      location.parent.children.add(index, o);
    }
  }
  
  private ObjectListEntry getEntry(int n) {
    return (ObjectListEntry)(objectList.getItem(n).get("value"));
  }
  
  private ObjectListEntry getSelectedEntry() {
    return getEntry((int)objectList.getValue());
  }
  
  // callback for add list
  void add(int n) {
    fixAddList = true;
    addComplete(null);
  }
  
  public void factoryFileChosen(File f) {
    if(f != null)
      addComplete(f);
  }
  
  void addComplete(File f) {
    DrawObjectFactory factory = (DrawObjectFactory)addList.getItem((int)addList.getValue()).get("value");
    if(factory.requireFile() && f == null) {
      selectInput("Choose a file to create " + factory.getName() + "...",
                  "factoryFileChosen", null, this);
      return;
    }
    
    DrawObject newObject = factory.create(f);
    movingEntry = null;
    moveToggle.setBroadcast(false)
      .setState(false)
      .setBroadcast(true);
    
    ObjectListEntry selectedEntry = getSelectedEntry();
    parent.objectsLock.lock();
    try {
      insertObject(newObject, selectedEntry);
    } finally {
      parent.objectsLock.unlock();
      updateList = true;
    }
    
    parent.propertiesFrame.setSelected(newObject);
  }
  
  // remove button
  void remove() {
    movingEntry = null;
    moveToggle.setBroadcast(false)
      .setState(false)
      .setBroadcast(true);
    
    ObjectListEntry selectedEntry = getSelectedEntry();
    if(selectedEntry.object == null || selectedEntry.parent == null)
      return;
    updateList = true;
    parent.objectsLock.lock();
    try {
      selectedEntry.parent.children.remove(selectedEntry.object);
    } finally {
      parent.objectsLock.unlock();
      updateList = true;
    }
  }
  
  // callback for move button
  void move(boolean on) {
    if(on) {
      movingEntry = getSelectedEntry();
      if(movingEntry.parent == null || movingEntry.object == null) {
        movingEntry = null;
        moveToggle.setBroadcast(false)
          .setState(false)
          .setBroadcast(true);
      }
    } else {
      movingEntry = null;
    }
  }
  
  void draw() {
    background(127);
    if(objectList.getWidth() != width || objectList.getHeight() != height) {
      int w = width;
      int h = height - 36;
      if(w < 1)
        w = 1;
      if(h < 1)
        h = 1;
      objectList.setSize(w, h);
    }
    
    if(fixAddList) {
      fixAddList = false;
      addList.setCaptionLabel("add");
    }
    
    if(updateList) {
      updateList = false;
      objectList.clear();
      addChildrenRecursive(rootObject, null, 0);
    }
  }
  
  private void addChildrenRecursive(DrawObject obj, DrawObject parent, int depth) {
    String name;
    if(obj == null)
      name = "---END---";
    else
      name = obj.name;
    for(int i = 0; i < depth; i++)
      name = "        " + name;
    ObjectListEntry entry = new ObjectListEntry(obj, parent);
    objectList.addItem(name, entry);
    
    if(obj == null)
      return;
    for(DrawObject child : obj.children)
      addChildrenRecursive(child, obj, depth + 1);
    if(obj.allowChildren())
      addChildrenRecursive(null, obj, depth + 1); // END item
  }
  
}