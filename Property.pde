// a: acceleration rate from 0 velocity
// t: time
// return: distance travelled
float accelDistance(float a, float t) {
  return 0.5 * a * sq(t);
}

class Transition {
  int startTime, length, easeIn, easeOut;
  float endValue;
  
  Transition() {
    startTime = 0;
    length = 0;
    easeIn = 0;
    easeOut = 0;
    endValue = 0;
  }
  
  Transition(int startTime, int length, float endValue) {
    this.startTime = startTime;
    this.length = length;
    this.endValue = endValue;
    easeIn = 0;
    easeOut = 0;
  }
  
  Transition(int startTime, int length, float endValue, int easeIn, int easeOut) {
    this.startTime = startTime;
    this.length = length;
    this.endValue = endValue;
    this.easeIn = easeIn;
    this.easeOut = easeOut;
  }
  
  boolean timeInRange(int time) {
    return time >= startTime && time < (startTime + length);
  }
  
  float valueAtTime(int time, float startValue) {
    time -= startTime;
    
    float maxVel = (endValue - startValue) / (easeIn/2 + easeOut/2 + (length-easeIn-easeOut));
    float accel = maxVel / easeIn;
    float decel = maxVel / easeOut;
    if(time < easeIn) {
      return startValue + accelDistance(accel, time);
    } else if(time >= length - easeOut) {
      return endValue - accelDistance(decel, length - time);
    } else {
      float endEaseInValue = startValue;
      if(easeIn > 0)
        endEaseInValue = startValue + accelDistance(accel, easeIn);
      return endEaseInValue + maxVel * (time - easeIn);
    }
  }
}

class Property {
  final String name;
  final float defaultValue;
  Transition firstValue;
  private ArrayList<Transition> transitions;
  float scale; // for UI adjustment
  boolean enabled;
  
  Property(String name, float defaultValue, float scale) {
    this.name = name;
    this.defaultValue = defaultValue;
    this.scale = scale;
    transitions = new ArrayList<Transition>();
    firstValue = new Transition(-1, 0, defaultValue);
    enabled = true;
  }
  
  Property(String name, float defaultValue, float scale, boolean enabled) {
    this.name = name;
    this.defaultValue = defaultValue;
    this.scale = scale;
    transitions = new ArrayList<Transition>();
    firstValue = new Transition(-1, 0, defaultValue);
    this.enabled = enabled;
  }
  
  float valueAtTime(int time) {
    Transition t = transitionAtTime(time);
    if(t.timeInRange(time))
      return t.valueAtTime(time, previousTransitionAtTime(time).endValue);
    else
      return t.endValue;
  }
  
  void addTransition(Transition t) {
    // insert at the correct location
    if(transitions.size() == 0)
      transitions.add(t);
    for(int i = 0; i < transitions.size(); i++) {
      if(transitions.get(i).startTime > t.startTime) {
        if(i == 0)
          transitions.add(0, t);
        transitions.add(i-1, t);
      }
    }
    transitions.add(t);
  }
  
  void reset() {
    transitions.clear();
    firstValue.endValue = defaultValue;
  }
  
  Transition transitionAtTime(int time) {
    if(transitions.size() == 0)
      return firstValue;
    for(int i = 0; i < transitions.size(); i++) {
      if(transitions.get(i).startTime > time) {
        if(i == 0)
          return firstValue;
        return transitions.get(i-1);
      }
    }
    return transitions.get(transitions.size() - 1);
  }
  
  Transition previousTransitionAtTime(int time) {
    if(transitions.size() == 0)
      return firstValue;
    for(int i = 0; i < transitions.size(); i++) {
      Transition t = transitions.get(i);
      if(t.startTime + t.length > time) {
        if(i == 0)
          return firstValue;
        return transitions.get(i-1);
      }
    }
    return transitions.get(transitions.size() - 1);
  }
}

class StringProperty {
  final String name, defaultValue, options;
  String value;
  boolean enabled;
  
  StringProperty(String name, String defaultValue) {
    this.name = name;
    this.defaultValue = defaultValue;
    this.options = "";
    value = defaultValue;
    enabled = true;
  }
  
  StringProperty(String name, String defaultValue, boolean enabled) {
    this.name = name;
    this.defaultValue = defaultValue;
    this.options = "";
    value = defaultValue;
    this.enabled = enabled;
  }
  
  StringProperty(String name, String defaultValue, String options) {
    this.name = name;
    this.defaultValue = defaultValue;
    this.options = options;
    value = defaultValue;
    enabled = true;
  }
  
  StringProperty(String name, String defaultValue, String options, boolean enabled) {
    this.name = name;
    this.defaultValue = defaultValue;
    this.options = options;
    value = defaultValue;
    this.enabled = enabled;
  }
}

class ColorPropertyGroup {
  Property r, g, b, a;
  
  ColorPropertyGroup(color defaultColor, String rgbPrefix,
                     String aName, boolean rgbEnabled, boolean aEnabled) {
    r = new Property(rgbPrefix + " R", red(defaultColor) / 255.0, 0.01, rgbEnabled);
    g = new Property(rgbPrefix + " G", green(defaultColor) / 255.0, 0.01, rgbEnabled);
    b = new Property(rgbPrefix + " B", blue(defaultColor) / 255.0, 0.01, rgbEnabled);
    a = new Property(aName, alpha(defaultColor) / 255.0, 0.01, aEnabled);
  }
  
  void addProperties(List<Property> properties) {
    properties.add(r);
    properties.add(g);
    properties.add(b);
    properties.add(a);
  }
  
  void addRGBProperties(List<Property> properties) {
    properties.add(r);
    properties.add(g);
    properties.add(b);
  }
  
  boolean enabled() {
    return r.enabled || g.enabled || b.enabled || a.enabled;
  }
  
  color colorAtTime(int time) {
    return color(r.valueAtTime(time)*255,
      g.valueAtTime(time)*255,
      b.valueAtTime(time)*255,
      a.valueAtTime(time)*255);
  }
}