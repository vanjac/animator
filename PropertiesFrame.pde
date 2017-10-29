class PropertiesFrame extends PApplet {

  animator parent;
  ControlP5 cp5;
  
  DrawObject selected = null;
  // everything to remove when the selected object is changed
  ArrayList<Controller> selectedControllers;
  ScrollableList addList;
  
  boolean updateControls = false;
  boolean fixAddList = false;

  PropertiesFrame(animator parent) {
    super();   
    this.parent = parent;
    selectedControllers = new ArrayList<Controller>();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  void settings() {
    size(250, 826);
  }

  void setup() {
    surface.setResizable(true);
    surface.setLocation(10, 10);
    surface.setTitle("Properties");
    cp5 = new ControlP5(this);
  }
  
  void setSelected(DrawObject obj) {
    parent.objectsLock.lock();
    selected = obj;
    updateControls = true;
    parent.objectsLock.unlock();
  }
  
  void controlEvent(ControlEvent e) {
    if(e.getController() instanceof Numberbox) {
      int i = e.getId();
      Property p = selected.properties.get(i);
      Transition t = p.transitionAtTime(parent.time);
      if(!t.timeInRange(parent.time)) {
        p.previousTransitionAtTime(parent.time).endValue = e.getValue();
      }
    } else if(e.getController() instanceof ScrollableList) {
      if(e.getName().equals("add"))
        return; // handled by another function
      int i = e.getId();
      StringProperty p = selected.stringProperties.get(i);
      String[] options = p.options.split(",");
      String option = options[(int)(e.getValue())];
      p.value = option;
    } else if(e.getController() instanceof Textfield) {
      if(e.getName().equals("Name")) {
        selected.name = e.getStringValue();
        parent.objectFrame.updateList();
      } else {
        int i = e.getId();
        StringProperty p = selected.stringProperties.get(i);
        p.value = e.getStringValue();
      }
    } else if(e.getController() instanceof Button) {
      if(e.getName().startsWith("p-")) {
        // property remove button
        int i = e.getId();
        Property p = selected.properties.get(i);
        p.enabled = false;
        parent.objectsLock.lock();
        try {
          p.reset();
        } finally {
          parent.objectsLock.unlock();
        }
        updateControls = true;
      }
      if(e.getName().startsWith("s-")) {
        // string property remove button
        int i = e.getId();
        StringProperty p = selected.stringProperties.get(i);
        p.enabled = false;
        p.value = p.defaultValue;
        updateControls = true;
      }
    }
  }

  void draw() {
    background(127);
    
    if(updateControls) {
      drawUpdateControls();
    }
    
    if(fixAddList) {
      fixAddList = false;
      addList.setCaptionLabel("Add Property");
    }
    
    if(selected != null) {
      parent.objectsLock.lock();
      try {
        int time = parent.time;
        for(int i = 0; i < selected.properties.size(); i++) {
          Property p = selected.properties.get(i);
          if(!p.enabled)
            continue;
          Numberbox box = (Numberbox)cp5.getController(p.name);
          float value = p.valueAtTime(time);
          if(box.getValue() != value) {
            box.setBroadcast(false)
              .setValue(p.valueAtTime(time))
              .setBroadcast(true);
          }
          if(!p.transitions.isEmpty()) {
            Transition t = p.transitionAtTime(time);
            if(t.timeInRange(time)) {
              box.setColorBackground(color(90, 45, 0));
            } else {
              box.setColorBackground(color(0, 90, 45));
            }
          } else {
            box.setColorBackground(color(0, 45, 90));
          }
        }
      } finally {
        parent.objectsLock.unlock();
      }
    } // end if(selected != null)
  }
  
  void drawUpdateControls() {
    updateControls = false;
    
    for(Controller c : selectedControllers)
      c.remove();
    selectedControllers.clear();
    
    if(selected == null)
      return;
    
    selectedControllers.add(cp5.addTextfield("Name")
      .setPosition(10, 10)
      .setAutoClear(false)
      .setBroadcast(false)
      .setValue(selected.name)
      .setBroadcast(true));
    
    ArrayList<String> disabledProperties = new ArrayList<String>();
    
    float yPos = 100;
    int i = 0;
    for(Property p : selected.properties) {
      if(!p.enabled) {
        i++;
        String name = propertyGroupName(p.name);
        if(!disabledProperties.contains(name))
          disabledProperties.add(name);
        continue;
      }
      Numberbox b = cp5.addNumberbox(p.name)
        .setPosition(36, yPos)
        .setSize(100, 20)
        .setMultiplier(p.scale)
        .setDirection(Controller.HORIZONTAL)
        .setId(i);
      makeNumberboxEditable(this, b);
      selectedControllers.add(b);
      selectedControllers.add(cp5.addButton("p-" + p.name)
        .setPosition(2, yPos)
        .setSize(24, 24)
        .setLabel("-")
        .setId(i));
      yPos += 40;
      i++;
    }
    
    i = 0;
    for(StringProperty p : selected.stringProperties) {
      if(!p.enabled) {
        i++;
        String name = propertyGroupName(p.name);
        if(!disabledProperties.contains(name))
          disabledProperties.add(name);
        continue;
      }
      if(!p.options.isEmpty()) {
        String[] options = p.options.split(",");
        selectedControllers.add(cp5.addScrollableList(p.name)
          .setPosition(36, yPos)
          .addItems(Arrays.asList(options))
          .setCaptionLabel(p.value)
          .close()
          .setId(i));
        selectedControllers.add(cp5.addLabel(p.name.toUpperCase())
          .setPosition(36, yPos + 14));
      } else {
        selectedControllers.add(cp5.addTextfield(p.name)
          .setPosition(36, yPos)
          .setAutoClear(false)
          .setBroadcast(false)
          .setValue(p.value)
          .setBroadcast(true)
          .setId(i));
      }
      selectedControllers.add(cp5.addButton("s-" + p.name)
        .setPosition(2, yPos)
        .setSize(24, 24)
        .setLabel("-")
        .setId(i));
      yPos += 40;
      i++;
    }
    
    // bring controls to front in reverse order, so menus will layer correctly
    for(int j = selectedControllers.size() - 1; j >= 0; j--)
      selectedControllers.get(j).bringToFront();
    
    addList = cp5.addScrollableList("add")
      .setCaptionLabel("Add Property")
      .setPosition(2, 60)
      .setSize(134, height)
      .setBarHeight(32)
      .setColorBackground(color(0, 90, 0))
      .addItems(disabledProperties)
      .close();
    selectedControllers.add(addList);
  } // end drawUpdateControls()
  
  String propertyGroupName(String name) {
    if(name.length() >= 3 && name.charAt(name.length() - 2) == ' ')
      return name.substring(0, name.length() - 2);
    return name;
  }
  
  // callback for add property select
  void add(int n) {
    fixAddList = true;
    String name = (String)addList.getItem((int)addList.getValue()).get("name");
    for(Property p : selected.properties)
      if(p.name.startsWith(name))
        p.enabled = true;
    for(StringProperty p : selected.stringProperties)
      if(p.name.startsWith(name))
        p.enabled = true;
    updateControls = true;
  }
}