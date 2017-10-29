class TimelineFrame extends PApplet {

  Animator parent;
  
  TimelineFrame(Animator parent) {
    super();   
    this.parent = parent;
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  void settings() {
    size(900, 300);
  }

  void setup() {
    surface.setResizable(true);
    surface.setLocation(270, 536);
    surface.setTitle("Timeline");
  }
  
  void draw() {
    background(0);
  }
  
}