/*
UI processing lib by xelo
*/
import java.util.*;

public class DragScrollHandler {
  float panx, pany;
  boolean indrag;
  int dragbutton = RIGHT;
  float anchorx, anchory;
  float cmovex, cmovey;
  float px, py;
  public boolean onMousePressed(int mx, int my, int duration, int button, boolean inbounds) {
    if (button==dragbutton) {
      if (duration==0 && inbounds) {
        indrag = true;
        anchorx=mx;
        anchory=my;
      } else if (indrag) {
        cmovex = mx-anchorx;
        cmovey = my-anchory;
        panx = px+cmovex;
        pany = py+cmovey;
      }
    }
    return false;
  }
  public boolean onMouseReleased(int mx, int my, int button) {
    indrag = false;
    px+=cmovex;
    py+=cmovey;
    cmovex=0;
    cmovey=0;
    panx = px+cmovex;
    pany = py+cmovey;
    return false;
  }
}


public abstract class DiscreteTransition {
  float t;
  float target;
  boolean complete=false;
  float sensitive = 0.05;
  DiscreteTransition(float start, float target) {
    this.t=start;
    this.target=target;
  }

  abstract void update();
}
//one transition after the other
class SequentialTransition extends DiscreteTransition {
  DiscreteTransition[] transitions;
  SequentialTransition(float start, float target, DiscreteTransition[] transitions) {
    super(start, target);
    this.transitions=transitions;
  }
  void update() {

    for (DiscreteTransition ds : transitions) {
      ds.target=target;
      if (ds.complete && abs(ds.t-ds.target)<sensitive) {
        ds.update();
        continue;
      }
      ds.update();

      break;
    }

    complete = true;
    for (DiscreteTransition ds : transitions) {
      complete &=ds.complete;
    }
  }
}
//the classic
class ExponentialTransition extends DiscreteTransition {
  float k;
  ExponentialTransition(float start, float target, float k) {
    super(start, target);
    this.k=k;
  }
  void update() {
    t+=k*(target-t);
    complete = (abs(target-t)<sensitive);
  }
}

//basically a spring
class DampedBounce extends DiscreteTransition {
  float v;
  float damp, k;

  DampedBounce(float start, float target, float damp, float k) {
    super(start, target);
    this.damp=damp;
    this.k=k;
  }
  void update() {
    v+=k*(target-t);
    v*=1-damp;
    t+=v;
    complete = (abs(target-t)<sensitive && abs(v)<sensitive*0.1);
  }
}
//starts slow gets faster
class AcceleratingTransition extends DiscreteTransition {
  float v;
  float damp, k;
  AcceleratingTransition(float start, float target, float damp, float k) {
    super(start, target);
    this.damp=damp;
    this.k=k;
  }
  void update() {
    if (target==t) {
      complete = true;
      return;
    }
    v+=k*((target-t)/abs((target-t)));
    v*=1-damp;
    t+=v;
    if ((target-(t-v))*(target-t)<0) {// aka. if either one is negative
      v=0;
      t=target;
      complete = true;
    } else {
      complete = false;
    }
  }
}

//processing doesnt use scaled fonts properly, a new font instance must be created for each font size you want to use
public class MultiFont {
  String fontname;
  HashMap<Integer, PFont> fontsizes = new HashMap();
  MultiFont(String font) {
    fontname = font;
  }
  void useFont(int size) {
    if (!fontsizes.containsKey(size)) {
      fontsizes.put(size, createFont(fontname, size));
    }
    textSize(size);
    textFont(fontsizes.get(size));
  }
  float getTextWidth(String s, int size) {
    useFont(size);
    return textWidth(s);
  }
}




Stack<PVector> offsets = new Stack();
PVector offset = new PVector();
public void ui_translate_push(float x, float y) {
  offsets.add(new PVector(x, y));
  offset.x+=x;
  offset.y+=y;
  pushMatrix();
  translate(x, y);
  //reAlignClip();
}

public void ui_translate_pop() {
  offset = offset.sub(offsets.pop());
  popMatrix();
  //reAlignClip();
}

public PVector getTotalCulminlativeOffset() {
  PVector output = new PVector();
  PVector[] pp = offsets.toArray(new PVector[]{});
  for (int i = 0; i<pp.length; i++) {
    output=output.add(pp[i]);
  }
  return output;
}


class Rect {
  float x, y, w, h;
  Rect(float x, float y, float w, float h) {
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
  }
}

Stack<Rect> clipStack = new Stack();

public void ui_clip_push(float x, float y, float w, float h) {

  clipStack.add(new Rect(x+offset.x, y+offset.y, w, h));
  clip(x+offset.x, y+offset.y, w, h);
}

public void ui_clip_pop() {
  if (clipStack.isEmpty()) {
    return;
  }
  clipStack.pop();
  if (!clipStack.isEmpty()) {
    Rect newClip = clipStack.peek();
    clip(newClip.x, newClip.y, newClip.w, newClip.h);
  } else {
    noClip();
  }
}

public void reAlignClip() {
  if (clipStack.isEmpty()) {
    return;
  }
  Rect newClip = clipStack.peek();
  clip(newClip.x+offset.x, newClip.y+offset.y, newClip.w, newClip.h);
}


PGraphics old;
PGraphics currentGraphics;
void setGraphics(PGraphics ng) {
  if (ng==null) {
    return;
  }
  if (old!=null) {
    currentGraphics.endDraw();
  } else {
    old = this.g;
  }
  currentGraphics = ng;
  currentGraphics.beginDraw();
  this.g = ng;
}

PGraphics unsetGraphics() {
  if (currentGraphics!=null) {
    this.g = old;
    currentGraphics.endDraw();
    PGraphics out = currentGraphics;
    currentGraphics=null;
    old=null;
    return out;
  }
  return null;
}

class NineSlice {
  PImage source;
  float expandoffset;
  float voffset;
  float ts;
  boolean seethru;
  NineSlice(PImage src, float expandoffset, float voffset) {
    source=src;
    this.expandoffset=expandoffset;
    this.voffset=voffset;
    ts = src.width/3;
    seethru = alpha(source.get(src.width/2, src.height/2))<100;
  } 
  void draw9Slice(float x, float y, float w, float h) {
    x-=expandoffset;
    y-=expandoffset+voffset;
    w+=expandoffset*2;
    h+=expandoffset*2;
    w = max(ts*2, w);
    h = max(ts*2, h);
    pushMatrix();
    noStroke();
    translate(x, y);
    beginShape(QUADS);
    texture(source);

    float xcoord[] = {0, ts, w-ts, w};
    float ycoord[] = {0, ts, h-ts, h};

    for (int i = 0; i<3; i++) {
      for (int j = 0; j<3; j++) {
        vertex(xcoord[i], ycoord[j], i*ts, j*ts);
        vertex(xcoord[i+1], ycoord[j], (i+1)*ts, j*ts);
        vertex(xcoord[i+1], ycoord[j+1], (i+1)*ts, (j+1)*ts );
        vertex(xcoord[i], ycoord[j+1], i*ts, (j+1)*ts );
      }
    }


    endShape();
    popMatrix();
  }
}

boolean isInWH(float qx, float qy, float gx, float gy, float gw, float  gh) {
  return isIn(qx, qy, gx, gy, gx+gw, gy+gh);
}
boolean isIn(float qx, float qy, float gx, float gy, float gx2, float  gy2) {
  return (!(gx2<qx||gy2<qy||gx>qx||gy>qy));
}
public float getLinePointDisSqrd(float lx, float ly, float lx2, float ly2, float px, float py) {
  float u = ((px-lx)*(lx2-lx) + (py-ly)*(ly2-ly))/(distsqrd(lx, ly, lx2, ly2));
  u = constrain(u, 0, 1);
  return distsqrd(lx+u*(lx2-lx), ly+u*(ly2-ly), px, py);
}

public float getLinePointDis(float lx, float ly, float lx2, float ly2, float px, float py) {
  return sqrt(getLinePointDisSqrd(lx, ly, lx2, ly2, px, py));
}

float sqrd(float x) {
  return (x*x);
}
float distsqrd(float x, float y, float x2, float y2) {
  return sqrd(x-x2)+sqrd(y-y2);
}
