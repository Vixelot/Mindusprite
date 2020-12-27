
Axis[] rotational = {
  new Axis(iVec(0, 0), iVec(1, 0), iVec(0, 1), true), 
  new Axis(iVec(0, 0), iVec(0, 1), iVec(1, 0), true), 
  new Axis(iVec(0, -1), iVec(1, 0), iVec(0, -1), true), 
  new Axis(iVec(0, -1), iVec(0, -1), iVec(1, 0), true), 

  new Axis(iVec(-1, -1), iVec(0, -1), iVec(-1, 0), true), 
  new Axis(iVec(-1, -1), iVec(-1, 0), iVec(0, -1), true), 

  new Axis(iVec(-1, 0), iVec(-1, 0), iVec(0, 1), true), 
  new Axis(iVec(-1, 0), iVec(0, 1), iVec(-1, 0), true), 

};

Axis[] bilateral = {
  new Axis(iVec(0, 0), iVec(1, 0), iVec(0, 1), true), 
  new Axis(iVec(-1, 0), iVec(-1, 0), iVec(0, 1), true), 
};

interface InvertCond {
  public int convert(int x, int y, int w, int h, int index);
}

class CanvasMode {
  Axis[] axes;
  InvertCond invert;
  boolean allowmidtone;
  int maxpal;
}
HashMap<String, CanvasMode> modes = new HashMap();

class Layer {
  RampIndice[][] sprite;
  String name;
  boolean visible=true;

  public Layer(String name, boolean visible, int w,int h) {
    this.name = name;
    this.visible = visible;
    sprite = new RampIndice[w][h];
  }
}
class SpriteCanvas extends Component {
  int tileSize=2;
  ArrayList<Axis> axes = new ArrayList();
  DragScrollHandler dsh = new DragScrollHandler();
  Ramp current;
  Ramp palette[];

  ArrayList<Layer> layers = new ArrayList();
  Layer currentlayer = null;
  
  CanvasMode canvasmode;
  int selectedindex=2;
  float panx=0, pany=0;
  boolean inhover = true;
  float scale = 10;
  int brushsize = 3;
  int pixelsize;
  int hoverx, hovery;
  float mhoverx, mhovery;
  boolean grid = false;
  int gridsize = 4;

  SpriteCanvas(String id, int tileSize, Ramp current) {
    super(id);
    this.tileSize=tileSize;
    scale = 10.0f/tileSize;
    layers.add(new Layer("base",true,tileSize*32,tileSize*32));
    currentlayer = layers.get(0);
    pixelsize = tileSize*32;
    this.current=current;
  }
  
  SpriteCanvas setMode(CanvasMode m) {
    canvasmode=m;
    axes.clear();
    for (int i =0; i<m.axes.length; i++) {
      axes.add(new Axis(iVec(tileSize*16, tileSize*16), m.axes[i]));
    }
    for(Layer l:layers){
      for (int i =0; i<l.sprite.length; i++) {
        for (int j =0; j<l.sprite[i].length; j++) {
          place(i, j, l,current, 2);
        }
      }
    }
    return this;
  }
  public void gridify() {gridify(currentlayer);}
  public void gridify(Layer l) {
    boolean wasgrid = grid;
    int pindex = selectedindex;
    grid=true;
    Axis origin = axes.get(0);
    iVec corners[] = new iVec[]{iVec(0, 0), iVec(gridsize-1, 0), iVec(gridsize-1, gridsize-1), iVec(0, gridsize-1)}; 
    for (int i =0; i<l.sprite.length; i+=gridsize) {
      for (int j =0; j<l.sprite[i].length; j+=gridsize) {
        if (origin.inLocalBounds(origin.globalToLocal(iVec(i, j)))) {
          int pools[][] = new int[4][3];
          for (int a =-2; a<gridsize+2; a++) {
            for (int b =-2; b<gridsize+2; b++) {
              for (int z=0; z<4; z++) {
                if (i+a>0 && j+b>0 &&i+a<l.sprite.length && j+b<l.sprite.length &&abs(a-corners[z].x)+abs(b-corners[z].y)<=gridsize-1) {
                  int ind = canvasmode.invert.convert(i+a,j+b,l.sprite.length,l.sprite[0].length,l.sprite[i+a][j+b].index);
                  pools[z][ind]++;
                }
              }
            }
          }
          int maxes[][] = new int[4][2];
          float totalslice = (gridsize*gridsize+gridsize)/2;
          for (int z=0; z<4; z++) {
            maxes[z][0] = getLargest(pools[z]);
            maxes[z][1] = pools[z][maxes[z][0]];
          }

          if (max(maxes[0][1], maxes[2][1]) > max(maxes[1][1], maxes[3][1])) {
            selectedindex = maxes[0][0];
            placeBrush(i, j);

            if (origin.inLocalBounds(origin.globalToLocal(iVec(i+corners[2].x, j+corners[2].y)))) {
              selectedindex = maxes[2][0];
              placeBrush(i+corners[2].x, j+corners[2].y);
            }
          } else {
            selectedindex = maxes[1][0];
            placeBrush(i+corners[1].x, j+corners[1].y);
            selectedindex = maxes[3][0];
            placeBrush(i+corners[3].x, j+corners[3].y);
          }
        }
      }
    }
    selectedindex=pindex;
    grid=wasgrid;
  }
  public void placeBrush(int x, int y) {
    placeBrush(x, y, currentlayer,current, selectedindex);
  }
  public void placeBrush(int x, int y,  Layer l, Ramp r, int index) {
    if (grid) {
      int gx = PApplet.parseInt(x/gridsize)*gridsize;
      int gy = PApplet.parseInt(y/gridsize)*gridsize;
      int cornerx = gx+ ((x%gridsize>=gridsize*0.5f)?gridsize-1:0);
      int cornery = gy+ ((y%gridsize>=gridsize*0.5f)?gridsize-1:0);
      for (int i =0; i<gridsize; i++) {
        for (int j =0; j<gridsize; j++) {
          if (abs(gx+i-cornerx)+abs(gy+j-cornery)<=3) {
            place(gx+i, gy+j);
          }
        }
      }
      return;
    }
    int ox = brushsize/2;
    int oy = brushsize/2;
    for (int i =0; i<brushsize; i++) {
      for (int j =0; j<brushsize; j++) {
        place(i+x-ox, j+y-oy,l, r, index);
      }
    }
  }
  public void place(int x, int y) {
    place(x, y, currentlayer,current, selectedindex);
  }
  public void place(int x, int y, Layer l, Ramp r, int index) {
    if (x<0||y<0||x>=pixelsize||y>=pixelsize) {
      return;
    }
    if (canvasmode==null) {
      l.sprite[x][y] = r.get(index);
      return;
    }
    iVec local = null;
    for (Axis a : axes) {
      local = a.globalToLocal(iVec(x, y));
      if (a.inLocalBounds(local)) {
        break;
      }
    }
    for (Axis a : axes) {
      iVec gl = a.localToGlobal(local);
      l.sprite[gl.x][gl.y] = r.get(canvasmode.invert.convert(gl.x, gl.y, l.sprite.length, l.sprite[0].length, index));
    }
  }


  public void update() {
  }
  public void predraw() {
  }
  public void draw(Camera c) {

    ui_translate_push(x, y);
    ui_clip_push(0, 0, w, h);
    noStroke();
    beginShape(QUADS);
    for (int i =0; i<w; i+=64) {
      for (int j =0; j<h; j+=64) {
        fill((i/64+j/64)%2==0?color(180):color(168));
        vertex(i, j);
        vertex(i+64, j);
        vertex(i+64, j+64);
        vertex(i, j+64);
      }
    }
    endShape();
    pushMatrix();
    translate(dsh.panx, dsh.pany);
    stroke(0);
    noFill();
    strokeWeight(2);
    rect(0, 0, tileSize*32*scale, tileSize*32*scale);
    noStroke();
    beginShape(QUADS);
    for(Layer l:layers){
      if(!l.visible){continue;}
      for (int i =0; i<l.sprite.length; i++) {
        for (int j =0; j<l.sprite[i].length; j++) {
          if (l.sprite[i][j]==null) {
            continue;
          }
          fill(l.sprite[i][j].get());
          vertex(i*scale, j*scale);
          vertex(i*scale+scale, j*scale);
          vertex(i*scale+scale, j*scale+scale);
          vertex(i*scale, j*scale+scale);
        }
      }
    }
    endShape();
    if (inhover) {
      stroke(0);
      noFill();
      if (grid) {
        int gx = PApplet.parseInt(hoverx/gridsize)*gridsize;
        int gy = PApplet.parseInt(hovery/gridsize)*gridsize;
        boolean right = (hoverx%gridsize>=gridsize*0.5f);
        boolean bottom = (hovery%gridsize>=gridsize*0.5f);
        int cornerx = gx+ (right?gridsize-1:0);
        int cornery = gy+ (bottom?gridsize-1:0);
        for (int i =0; i<gridsize; i++) {
          for (int j =0; j<gridsize; j++) {
            if (abs(gx+i-cornerx)+abs(gy+j-cornery)<=3) {
              rect(scale*(gx+i), scale*(gy+j), scale, scale);
            }
          }
        }
      } else {
        float ox = (hoverx-brushsize/2)*scale;
        float oy = (hovery-brushsize/2)*scale;
        rect(ox, oy, brushsize*scale, brushsize*scale);
      }
    }

    popMatrix();


    ui_clip_pop();
    ui_translate_pop();


    stroke(0);
    strokeWeight(1);
    for (int i =0; i<3; i++) {
      float ax = x+3+i*23;
      if (current!=null) {
        if (i!=selectedindex) {
          strokeWeight(1);
        } else {
          strokeWeight(2);
        }
        fill(current.getColor(i));
        rect(ax, y, 20, 20);
      } else {
        stroke(0);
        line(ax, y, ax+20, y);
      }
    }

    strokeWeight(1);
    fill(0);
    textAlign(LEFT);
    text("brush:["+nf(hoverx)+", "+nf(hovery)+"]", 10, h-25);
    text("pan:["+nfc(dsh.panx, 2)+", "+nfc(dsh.pany, 2)+"]", 10, h-10);
    ui_nineslice.get("invert").draw9Slice(x, y, w, h);
  }
  public void postdraw() {
  }
  public @Override
    Component clone(String id) {
    //uh extract dimensions from id
    return (new SpriteCanvas(id==null?this.id+"(copy)":id, tileSize, current))
      .setPad(padleft, padright, padtop, padbottom)
      .setPositioning(left, right, top, bottom);
  }

  public PImage export() {
    PImage output = createImage(tileSize*32, tileSize*32, ARGB);
    output.loadPixels();
    Layer l = currentlayer;
    for (int i =0; i<l.sprite.length; i++) {
        for (int j =0; j<l.sprite[i].length; j++) {
          output.pixels[i+j*output.width] = l.sprite[i][j].get();
        }
    }
    return output;
  }

  public boolean onMouseHovered(int mx, int my) {
    if (isContaining(mx, my)) {
      inhover = true;
      hoverx = PApplet.parseInt((mx-x-dsh.panx)/scale);
      hovery = PApplet.parseInt((my-y-dsh.pany)/scale);
      mhoverx = (mx-x-dsh.panx);
      mhovery = (my-y-dsh.pany);
      return true;
    }
    inhover = false;
    return false;
  }
  public boolean onMousePressed(int mx, int my, int duration, int button, boolean doubleclicked) {
    dsh.onMousePressed(mx, my, duration, button, isContaining(mx, my));
    if (button==LEFT&&isContaining(mx, my)) {
      int ax = PApplet.parseInt((mx-x-dsh.panx)/scale);
      int ay = PApplet.parseInt((my-y-dsh.pany)/scale);
      for (int i =0; i<3; i++) {
        float arx = x+3+i*23;
        if (isInWH(mx, my, arx, y, 20, 20)) {
          selectedindex = i;
          return true;
        }
      }

      placeBrush(ax, ay);
      return true;
    }
    return false;
  }
  public boolean onMouseReleased(int mx, int my, int button) {
    dsh.onMouseReleased(mx, my, button);
    return false;
  }
  public boolean onKeyPressed(char key, char keycode) {
    return false;
  }
  public boolean onKeyHeld(HashMap<Integer, KeyHeldEvent>keysheld) {
    return false;
  }
  public boolean onMouseScrolled(float dir) {
    if (inhover) {
      float pscale = scale;
      scale *= (1+dir*0.2f);
      scale = constrain(scale, 0.05f, 20);
      float ascale = scale/pscale;
      println((mhoverx+dsh.panx)*(ascale-1), (mhovery+dsh.pany)*(ascale-1));
      dsh.px+=(-mhoverx)*(ascale-1);
      dsh.py+=(-mhovery)*(ascale-1);
      dsh.panx=dsh.px;
      dsh.pany=dsh.py;
    }
    return inhover;
  }
}

int pwidth, pheight;
void draw() {
  background(180);
  updateInput();
  masterbatch.predraw();
  masterbatch.draw(uicam);
  masterbatch.postdraw();


  surface.setTitle("Mindusprite: "+(int)frameRate+" fps");
  if (pwidth!=width||pheight!=height) {
    uistage.setSize(width-6, height-6);
  }
  pwidth=width;
  pheight=height;
}

class RampIndice {
  Ramp ramp;
  int index;

  public RampIndice(Ramp ramp, int index) {
    this.ramp = ramp;
    this.index = index;
  }
  color get() {
    return ramp.getColor(index);
  }
}

class Ramp {
  String name;
  color[] colors;

  public Ramp(String name, color[] colors) {
    this.name=name;
    this.colors = colors;
  }

  color getColor(int index) {
    return colors[index];
  }

  RampIndice get(int index) {
    return new RampIndice(this, index);
  }
  RampIndice invert(int index) {
    return new RampIndice(this, index==1?1:2-index);
  }
}

class Axis {
  iVec origin, xdir, ydir;
  boolean triangular = true;

  public Axis(iVec origin, iVec dirx, iVec diry, boolean triangular) {
    this.origin  =iVec(origin);
    this.xdir  =iVec(dirx);
    this.ydir  =iVec(diry);
    this.triangular = triangular;
  }
  public Axis(iVec origin, Axis a) {
    this.origin  =iVec(origin).add(a.origin);
    this.xdir  =iVec(a.xdir);
    this.ydir  =iVec(a.ydir);
    this.triangular = a.triangular;
  }
  iVec localToGlobal(iVec i) {
    return iVec(xdir).mul(i.x).add(iVec(ydir).mul(i.y)).add(origin);
  }
  iVec globalToLocal(iVec i) {
    iVec t = iVec(i).sub(origin);
    return iVec(t.dot(xdir), t.dot(ydir));
  }
  boolean inLocalBounds(iVec i) {
    if (triangular && i.y>i.x) {
      return false;
    }
    return i.x>=0 && i.y>=0;
  }
}


iVec iVec() {
  return new iVec();
}
iVec iVec(int x, int y) {
  return new iVec().set(x, y);
}
iVec iVec(iVec i) {
  return new iVec().set(i);
}
class iVec {
  int x, y;
  iVec set(int x, int y) {
    this.x=x;
    this.y=y;
    return this;
  }
  iVec set(iVec i) {
    this.x=i.x;
    this.y=i.y;
    return this;
  }
  PVector toPVec() {
    return new PVector(x, y);
  }
  iVec add(int x, int y) {
    this.x+=x;
    this.y+=y;
    return this;
  }
  iVec add(iVec i) {
    this.x+=i.x;
    this.y+=i.y;
    return this;
  }
  iVec sub(int x, int y) {
    this.x-=x;
    this.y-=y;
    return this;
  }
  iVec sub(iVec i) {
    this.x-=i.x;
    this.y-=i.y;
    return this;
  }
  iVec mul(int x, int y) {
    this.x*=x;
    this.y*=y;
    return this;
  }
  iVec mul(int x) {
    this.x*=x;
    this.y*=x;
    return this;
  }
  iVec mul(iVec i) {
    this.x*=i.x;
    this.y*=i.y;
    return this;
  }
  iVec div(int x, int y) {
    this.x/=x;
    this.y/=y;
    return this;
  }
  iVec div(int x) {
    this.x/=x;
    this.y/=x;
    return this;
  }
  iVec div(iVec i) {
    this.x/=i.x;
    this.y/=i.y;
    return this;
  }
  int dot(iVec i) {
    return this.x*i.x+this.y*i.y;
  }
}
int getLargest(int[] in) {
  int ind=0;
  int max=in[0];
  for (int i =1; i<in.length; i++) {
    if (in[i]>max) {
      max=in[i];
      ind=i;
    }
  }
  return ind;
}
