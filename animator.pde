import controlP5.*;
import java.util.*;
import java.util.concurrent.locks.*;

PropertiesFrame propertiesFrame;
ObjectFrame objectFrame;
TimelineFrame timelineFrame;

DrawGroup rootObject;
Lock objectsLock;
int startTime = -1;
int time = 0;

void settings() {
  size(640, 480);
}

void setup() {
  surface.setResizable(true);
  surface.setLocation(270, 10);
  propertiesFrame = new PropertiesFrame(this);
  objectFrame = new ObjectFrame(this);
  timelineFrame = new TimelineFrame(this);
  
  objectsLock = new ReentrantLock();
  rootObject = new DrawGroup("Root");
  
  DrawImage obj = new DrawImage(new File("duck.jpg"));
  rootObject.children.add(obj);
  obj.rotation.addTransition(new Transition(0, 250, 360*5, 125, 125));
  obj.tintColor.r.addTransition(new Transition(0, 250, 1));
  obj.xPosition.addTransition(new Transition(25, 75, 100, 25, 25));
  obj.yPosition.addTransition(new Transition(125, 10, 100));
  obj.scale.firstValue.endValue = 0.25;
  obj.scale.addTransition(new Transition(125, 10, 0.7));
}

void draw() {
  if(startTime == -1) {
    startTime = millis()/40;
    objectFrame.setRootObject(rootObject);
  }
  time = millis()/40 - startTime;
  background(255,255,255);
  translate(width/2, height/2);
  scale(float(height) / 200, float(height) / 200);
  objectsLock.lock();
  try {
    rootObject.draw(g, time);
    rootObject.postDraw(g);
  } finally {
    objectsLock.unlock();
  }
  noFill();
  stroke(0);
  strokeWeight(0.1);
  rect(-100.0*4/3, -100, 200.0*4/3, 200);
  line(-100.0*4/3, -100, 200.0*4/3, 200);
  line(100.0*4/3, -100, -200.0*4/3, 200);
  fill(255,255,255);
  strokeWeight(1);
}