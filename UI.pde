/*
UI processing lib by xelo
 */
HashMap<String, NineSlice> ui_nineslice = new HashMap();
MultiFont guifont;
void init_ui() {
  guifont = new MultiFont("Montserrat-Medium.ttf");
  guifont.useFont(12);
  ui_nineslice.put("panel1", new NineSlice(loadImage("ui/panel9slice.png"), 3, 0));
  ui_nineslice.put("invert", new NineSlice(loadImage("ui/invert9slice.png"), 3, 0));
  ui_nineslice.put("below", new NineSlice(loadImage("ui/below9slice.png"), 3, 0));
  ui_nineslice.put("tab", new NineSlice(loadImage("ui/tab9slice.png"), 0, 0));
  ui_nineslice.put("tabnoshadow", new NineSlice(loadImage("ui/tabnoshadow9slice.png"), 0, 0));
  ui_nineslice.put("downtab", new NineSlice(loadImage("ui/downtab9slice.png"), 0, 0));
  ui_nineslice.put("downtabnoshadow", new NineSlice(loadImage("ui/downtabnoshadow9slice.png"), 0, 0));
  ui_nineslice.put("sideshadow", new NineSlice(loadImage("ui/sideshadow9slice.png"), 0, 0));
  ui_nineslice.put("button1", new NineSlice(loadImage("ui/button9slice.png"), 2, 0));
  ui_nineslice.put("button1pressed", new NineSlice(loadImage("ui/buttonpressed9slice.png"), 2, 0));
  ui_nineslice.put("button2", new NineSlice(loadImage("ui/button29slice.png"), 2, 0));
  ui_nineslice.put("button2pressed", new NineSlice(loadImage("ui/button2pressed9slice.png"), 2, 0));
  ui_nineslice.put("button1inactive", new NineSlice(loadImage("ui/buttoninactive9slice.png"), 2, 0));
  ui_nineslice.put("button3", new NineSlice(loadImage("ui/button39slice.png"), 1, 0));
  ui_nineslice.put("button3pressed", new NineSlice(loadImage("ui/button3pressed9slice.png"), 1, 0));

  ui_nineslice.put("textfield", new NineSlice(loadImage("ui/textfield9slice.png"), 2, 0));
}

color defaulttextcolor = color(50);
color defaultbackgroundcolor = color(230);
color defaultmiddlegroundcolor = color(220);
color defaultmiddlegroundcolor2 = color(180);
color defaultforegroundcolor = color(150);
color accentbgcolor = color(150, 50, 50);

//input
/*
 public boolean onMouseHovered(int mx,int my){return false;}
 public boolean onMousePressed(int mx,int my,int duration,int button,  boolean doubleclicked){return false;}
 public boolean onKeyPressed(char key, char keycode){return false;}
 public boolean onKeyHeld(HashMap<Integer,KeyHeldEvent>keysheld){return false;}
 
 
 */

ArrayList<InputListener> inputListeners = new ArrayList();
InputListener focusedListener = null;
int currentButt = -1;
int duration = 0;
int cursor;
int ccursor = ARROW;
void updateInput() {
  cursor = ARROW;
  for (InputListener il : inputListeners) {
    il.onMouseHovered(mouseX, mouseY);
  }
  if (currentButt!=-1) {
    boolean consumed = false;
    if (focusedListener!=null) {
      consumed=focusedListener.onMousePressed(mouseX, mouseY, duration, currentButt, false);
    }
    if (!consumed) {
      for (InputListener il : inputListeners) {
        il.onMousePressed(mouseX, mouseY, duration, currentButt, false); //todo: double click
      }
    }
    duration ++;
  }
  if (cursor!=ccursor) {
    ccursor = cursor;
    cursor(cursor);
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  for (InputListener il : inputListeners) {
    il.onMouseScrolled(e);
  }
}
void mousePressed() {
  currentButt= (mouseButton);
  duration = 0;
}

void mouseReleased() {
  if (mouseButton == currentButt) {
    currentButt = -1;
  }
  for (InputListener il : inputListeners) {
    il.onMouseReleased(mouseX, mouseY, currentButt);
  }
}

class Camera implements Drawable {
  float cmx, cmy;
  float tcmx, tcmy;
  float speed = 0.5;

  void update() {
  }
  public void predraw() {
    pushMatrix();
    translate(cmx, cmy);
  }
  public void draw(Camera c) {
    cmx += (tcmx-cmx)*speed;
    cmy += (tcmy-cmy)*speed;
  }
  public void postdraw() {
    popMatrix();
  }

  public int getDrawIndex() {
    return 0;
  }

  boolean active = true;
  boolean getActive() {
    return active;
  }
  public void setActive(boolean active) {
    this.active=active;
  }
}





//abstracts
abstract class Component implements InputListener, Drawable {
  color textcolor = defaulttextcolor;
  color backgroundcolor = defaultbackgroundcolor;
  color middlegroundcolor = defaultmiddlegroundcolor;
  color foregroundcolor = defaultforegroundcolor;
  float x, y, w, h;
  int z;
  float left=-1, right=-1, top=-1, bottom=-1;
  float padleft=5, padright=5, padtop=5, padbottom=5;
  float minw=5, minh=5;

  String id;
  boolean active=true;
  boolean focused = false;

  ActionEvent ae = null;
  Container parent;

  abstract Component clone(String id);

  Component(String id) {
    this.id=id;
  }
  Component setTextcolor(color textcolor) {
    this.textcolor = textcolor;
    return this;
  }
  Component setPos(float x_, float y_) {
    x=x_;
    y=y_;
    return this;
  }
  Component setSize(float w_, float h_) {
    w=max(w_, minw);
    h=max(h_, minh);
    return this;
  }
  Component setMinSize(float w_, float h_) {
    minw = w_;
    minh = h_;
    return this;
  }
  Component setIndex(int z_) {
    z=z_;
    return this;
  }
  Component setPad(float pad) {
    padleft=pad;
    padright=pad;
    padtop=pad;
    padbottom=pad;
    return this;
  }
  Component setPad(float padleft, float padright, float padtop, float padbottom) {
    this.padleft=padleft;
    this.padright=padright;
    this.padtop=padtop;
    this.padbottom=padbottom;
    return this;
  }

  Component setPositioning(float left, float right, float top, float bottom) {
    this.left=left;

    this.right=right;
    this.top=top;
    this.bottom=bottom;
    return this;
  }
  Component setActionEvent(ActionEvent ae) {
    this.ae=ae;
    return this;
  }

  abstract void update();
  public void predraw() {
    update();
  }
  boolean getActive() {
    return active;
  }
  public void setActive(boolean active) {
    this.active=active;
  }
  public int getDrawIndex() {
    return z;
  }
  public boolean isContaining(int mx, int my) {
    mx-=x;
    my-=y;
    return(mx>0&&my>0&&mx<w&&my<h);
  }
  public boolean onMouseScrolled(float dir) {
    return false;
  }
}

class StaticImage extends Component {
  PImage img;
  boolean lockratios=true;
  float imgw, imgh;
  StaticImage(String id) {
    super(id);
  }
  StaticImage setImage(String image) {
    img = loadImage(image);
    imgw=img.width;
    imgh=img.height;
    if (w==0||h==0) {
      w=imgw;
      h=imgh;
    }
    return this;
  }
  StaticImage setLockratios(boolean active) {
    this.lockratios=active;
    return this;
  }
  StaticImage setImage(PImage image) {
    img = (image);
    imgw=img.width;
    imgh=img.height;
    if (w==0||h==0) {
      w=imgw;
      h=imgh;
    }
    return this;
  }
  StaticImage setMinSize(float w_, float h_) {
    minw = w_;
    minh = h_;
    return this;
  }
  @Override
    StaticImage setSize(float w_, float h_) {
    if (!lockratios) {
      w=max(w_, minw);
      h=max(h_, minh);
    } else {
      println("Static image", w_, h_);
      w_=max(w_, minw);
      h_=max(h_, minh);
      float r = (imgh/imgw);
      if ((w_<h_/r && w_*r<h_)) {
        w=w_;
        h = w*r;
      } else {
        h=h_;
        w = h/r;
      }
    }
    return this;
  }
  @Override
    Component clone(String id) {
    return (new StaticImage(id==null?this.id+"(copy)":id))
      .setImage(img)
      .setPad(padleft, padright, padtop, padbottom)
      .setPositioning(left, right, top, bottom);
  }
  void update() {
  }
  public boolean onMouseHovered(int mx, int my) {
    return false;
  }
  public boolean onMousePressed(int mx, int my, int duration, int button, boolean doubleclicked) {
    return false;
  }
  public boolean onKeyPressed(char key, char keycode) {
    return false;
  }
  public boolean onKeyHeld(HashMap<Integer, KeyHeldEvent>keysheld) {
    return false;
  }
  public boolean onMouseReleased(int mx, int my, int button) {
    return false;
  }


  public void draw(Camera c) {
    image(img, x, y, w, h);
  }

  public void postdraw() {
  }
}
class Label extends Component {
  String text="";
  int halign=CENTER, valign=BASELINE;
  int size = 12;
  Label(String id) {
    super(id);
  }
  Label setText(String s) {
    text=s;
    getMinDims();
    return this;
  }
  Label setTextSize(int s) {
    size=s;
    getMinDims();
    return this;
  }
  float sminw, sminh;
  Label setMinSize(float w_, float h_) {
    sminw = w_;
    sminh = h_;
    getMinDims();
    return this;
  }
  void getMinDims() {
    textSize(size);
    minw = max(sminw, guifont.getTextWidth(text, size)+padleft+padright);
    minh=max(sminh, size*1.2+padtop+padbottom);
  }
  Label setTextAlign(int halign, int valign) {
    this.halign =halign;
    this.valign=valign;
    return this;
  } 
  @Override
    Component clone(String id) {
    return (new Label(id==null?this.id+"(copy)":id))
      .setText(text)
      .setTextAlign( halign, valign)
      .setPad(padleft, padright, padtop, padbottom)
      .setPositioning(left, right, top, bottom);
  }
  void update() {
  }
  public boolean onMouseHovered(int mx, int my) {
    return false;
  }
  public boolean onMousePressed(int mx, int my, int duration, int button, boolean doubleclicked) {
    return false;
  }
  public boolean onKeyPressed(char key, char keycode) {
    return false;
  }
  public boolean onKeyHeld(HashMap<Integer, KeyHeldEvent>keysheld) {
    return false;
  }
  public boolean onMouseReleased(int mx, int my, int button) {
    return false;
  }


  public void draw(Camera c) {
    fill(textcolor);
    guifont.useFont(size);
    textAlign(halign, valign);
    text(text, x, y, w, h);
  }

  public void postdraw() {
  }
}
enum ButtonState {
  INACTIVE, ACTIVE, HOVERED, PRESSED;
}
class ButtonGroupController {
  ArrayList<Button> buttons = new ArrayList();
  Button currentlyactive = null;
  void addButton(Button b) {
    buttons.add(b);
  }
}

PressableStyle defaultStyle = new PressableStyle();
PressableStyle flatStyle = new PressableStyle("button2", "button2", "button2", "button2pressed");
PressableStyle clearStyle = new PressableStyle("button3", "button3", "button3", "button3pressed");
class PressableStyle {
  String inactive = "button1inactive", 
    active = "button1", 
    hovered = "button1", 
    pressed = "button1pressed";
  PressableStyle() {
  }  
  PressableStyle(String inactive, String active, String hovered, String pressed) {
    this.inactive = inactive;
    this.active = active;
    this.hovered = hovered;
    this.pressed = pressed;
  }
}
class Slider extends Label {
  PressableStyle style = new PressableStyle();
  float num;
  boolean integer = true;
  float min, max;
  float tw;
  Slider(String id, float c, float min, float max, boolean integer) {
    super(id);
    this.integer = integer;
    num = constrain(c, min, max);
    this.min=min;
    this.max=max;
  }
}
class ComboBox extends Label {
  PImage icons=null;
  String options[];
  int selected=-1;
  boolean allowDeselect;
  float gridHeight = 30;
  boolean opened = false;
  DiscreteTransition opentrans = new ExponentialTransition(0, 0, 0.5);



  ComboBox(String id) {
    super(id);
  }
  ComboBox setOptions(String[] s) {
    options=s;
    return this;
  }
  public ComboBox setIcon(String iconp) {
    icons = loadImage(iconp);
    getMinDims();
    return this;
  }
  public ComboBox setIcon(PImage iconp) {
    icons = iconp;
    getMinDims();
    return this;
  }
  void update() {
    opentrans.update();
  }
  public boolean onMouseHovered(int mx, int my) {
    mx-=x;
    my-=y;
    if (mx>0&&my>0&&mx<w&&my<(h+opentrans.t)){
      if(opened&&my<h){
        opentrans.target = options.length*gridHeight -15;
      }else if(!opened){
        opentrans.target = 15;
      }else{
        opentrans.target = options.length*gridHeight;
      }
      return true;
    }
    return false;
  }
  public void draw(Camera c) {
    
  }
}
class Button extends Label {

  PImage icon=null;
  boolean toggle;
  int toggletype = 0;//0-push toggle,1- labelled push toggle, 2- switch toggle,  3-labelled switch toggle
  String toggletext="";
  String tooltip=null;
  ButtonState state=ButtonState.ACTIVE;
  PressableStyle style = new PressableStyle();
  float statetransition = 0;
  ButtonGroupController group=null;
  float timehovered = 0;
  Button(String id) {
    super(id);
  }
  public Button setIcon(String iconp) {
    icon = loadImage(iconp);
    getMinDims();
    return this;
  }
  public Button setIcon(PImage iconp) {
    icon = iconp;
    getMinDims();
    return this;
  }
  public Button setToggle(boolean toggle) {
    this.toggle = toggle;
    return this;
  }
  public Button setStyle(PressableStyle style) {
    this.style = style;
    return this;
  }
  public Button setState(ButtonState state) {
    this.state = state;
    return this;
  }
  Button setToggleText(String toggle) {
    toggletext=toggle;
    return this;
  }
  Button setTextSize(int s) {
    super.setTextSize(s);
    return this;
  }
  Button setToolTip(String s) {
    tooltip=s;
    return this;
  }
  Button setText(String s) {

    super.setText(s);
    if (toggletext=="") {
      toggletext=text;
    }
    return this;
  }
  Button setTextAlign(int halign, int valign) {
    super.setTextAlign(halign, valign);
    return this;
  }   
  void getMinDims() {
    super.getMinDims();
    if (icon!=null) {
      minh = max(minh, icon.height+padtop+padbottom);
      minw += icon.width;
    }
  }
  @Override
    Component clone(String id) {
    return (new Button(id==null?this.id+"(copy)":id))
      .setText(text)
      .setIcon(icon)
      .setTextAlign( halign, valign)
      .setPad(padleft, padright, padtop, padbottom)
      .setPositioning(left, right, top, bottom);
  }

  void update() {
    statetransition /=2;
    if (!toggle) {
    }
  }
  public boolean onMouseHovered(int mx, int my) {
    mx-=x;
    my-=y;
    if (mx>0&&my>0&&mx<w&&my<h) {
      if (state.equals(ButtonState.ACTIVE)) {
        state = ButtonState.HOVERED;
        statetransition=1;
      }
      timehovered++;
      return true;
    } else {
      if (state.equals(ButtonState.HOVERED)) {
        state = ButtonState.ACTIVE;
        statetransition=1;
      }
      timehovered = 0;
    }
    return false;
  }
  public boolean onMousePressed(int mx, int my, int duration, int button, boolean doubleclicked) {
    mx-=x;
    my-=y;
    if (mx>0&&my>0&&mx<w&&my<h) {
      if (!toggle) {
        state = ButtonState.PRESSED;
      } else if (duration==0) {
        state = state.equals(ButtonState.PRESSED)?ButtonState.ACTIVE:ButtonState.PRESSED;
      }
      statetransition=1;
      if (ae!=null&&duration==0) {
        ae.onComponentAction(this);
        timehovered = 0;
      }
      return true;
    }
    return false;
  }
  public boolean onMouseReleased(int mx, int my, int button) {
    return false;
  }
  public boolean onKeyPressed(char key, char keycode) {
    return false;
  }
  public boolean onKeyHeld(HashMap<Integer, KeyHeldEvent>keysheld) {
    return false;
  }



  public void draw(Camera c) {
    if (toggle) {
      switch(toggletype) {
      default:
      case 0:
        switch(state) {
        case INACTIVE:
          ui_nineslice.get(style.inactive).draw9Slice(x, y, w, h);
          break;
        case ACTIVE:
          ui_nineslice.get(style.active).draw9Slice(x, y, w, h);
          break;
        case HOVERED:
          tint(color(lerp(200, 255, statetransition)));
          ui_nineslice.get(style.hovered).draw9Slice(x, y, w, h);
          noTint();
          break;
        case PRESSED:
          ui_nineslice.get(style.pressed).draw9Slice(x, y, w, h);
          break;
        }
        break;
      }
    } else {
      switch(state) {
      case INACTIVE:
        ui_nineslice.get(style.inactive).draw9Slice(x, y, w, h);
        break;
      case ACTIVE:
        ui_nineslice.get(style.active).draw9Slice(x, y, w, h);
        break;
      case HOVERED:
        tint(color(lerp(200, 255, statetransition)));
        ui_nineslice.get(style.hovered).draw9Slice(x, y, w, h);
        noTint();
        break;
      case PRESSED:
        ui_nineslice.get(style.pressed).draw9Slice(x, y, w, h);
        state = ButtonState.ACTIVE;
        break;
      }
    }
    fill(textcolor);
    guifont.useFont(size);
    textAlign(halign, valign);
    float ax=x+padleft;
    if (icon!=null) {
      tint(color(0, 100));
      image(icon, ax, y+h*0.5 - icon.height*0.5);
      noTint();
    }
    text(text, ax, y+padtop-1, w-(padleft+padright)+2, h-(padtop+padbottom));
  }

  public void postdraw() {
    if (tooltip!=null&&state==ButtonState.HOVERED && timehovered>50) {
      float tw = textWidth(tooltip);
      ui_nineslice.get("button2").draw9Slice(x+(w-(tw+10))*0.5, y-30, tw+10, 20);
      textAlign(CENTER, CENTER);
      text(tooltip, x+(w-(tw+10))*0.5, y-33, tw+10, 20);
    }
  }
}
