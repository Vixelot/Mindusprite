
TreeContainer uistage;
DrawBatcher masterbatch;
Camera uicam;

color bg = color(80,80,100);
color bg2 = color(100,100,110);

ArrayList<Ramp> ramps = new ArrayList();
Ramp blank = new Ramp("transparent",new color[]{color(1,0),color(1,0),color(1,0)});

public void setup() {
  masterbatch = new DrawBatcher();
  uicam = new Camera(); 
  init_ui();
  size(1000,700,P2D);
  ramps.add(new Ramp("grey",new int[]{0xff6e7080,0xff989aa4,0xffb0bac0}));
  ramps.add(new Ramp("bottom",new int[]{0x4A4B53,0x4A4B53,0x4A4B53}));
  ramps.add(new Ramp("accent",new int[]{#D4806B,#E9A874,#FFD27E}));
  
  modes.put("8way", new CanvasMode(){{
    axes = rotational;
    invert = new InvertCond(){
      public int convert(int x,int y, int w, int h, int index){
         if(y>x){return 2-index;}
         if(y==x){return 1;}
         return index;
      }
    };
    allowmidtone=true;
    maxpal=3;
  }});
  
  
  
  
  final SpriteCanvas canvas = new SpriteCanvas("canvas",2,ramps.get(0));
  canvas.setMode(modes.get("8way")).setMinSize(200,200).setPositioning(0,0,0,0).setPad(0);
  CollapsableContainer canvascollapse= (CollapsableContainer)(new CollapsableContainer("canvascollapse").setSize(800,720).setPositioning(3,3,3,3).setPad(0));
  canvascollapse.addComp(canvas);
  
  SingleCellContainer topbar = (SingleCellContainer)(new SingleCellContainer("topbar").setPositioning(3,3,3,3).setMinSize(110,100));
  topbar.addComp((StaticImage)(new StaticImage("logo")).setImage("logo.png").setLockratios(false).setSize(100,100).setMinSize(100,100));
  topbar.addComp((Label)(new Label("appname")).setTextSize(24).setText("MINDUSPRITE").setPositioning(100,-1,4,-1).setTextcolor(defaultmiddlegroundcolor));
  topbar.addComp((Label)(new Label("author")).setText("made by Xelo").setPositioning(100,-1,40,-1).setTextcolor(defaultmiddlegroundcolor2));
  
  topbar.addComp((Button)(new Button("export")).setStyle(clearStyle).setText("export").setPositioning(105,-1,65,-1).setSize(50,30).setTextcolor(defaultmiddlegroundcolor));
  ActionEvent topbarae = new ActionEvent(){
    public void onComponentAction(Component c){
      switch (c.id){
        case "export":
          PImage p = canvas.export();
          p.save("output/output.png");
        break;
      }
    }
  };
  topbar.setActionEvent(topbarae);
  
  CollapsableContainer toolcollapse= (CollapsableContainer)(new CollapsableContainer("toolcollapse").setSize(800,720).setPositioning(3,3,3,3).setPad(0));
  TreeContainer toolrows = (TreeContainer)(new TreeContainer("tooldividers")).setSize(800,720).setPositioning(0,0,0,0).setPad(0);
  
  toolrows.root.split(HORIZONTAL_SPLIT, true);
  
  SingleCellContainer toolbar = (SingleCellContainer)(new SingleCellContainer("topbar")).setBgPanel(null).setPositioning(0,0,0,0);
  toolbar.addComp((new Button("grid toggle")).setIcon("ui/gridsmall.png").setToolTip("brush grid").setToggle(true).setStyle(flatStyle).setTextAlign(CENTER,CENTER).setSize(30,30).setPositioning(3,-1,3,3));
  toolbar.addComp((new Button("gridify")).setIcon("ui/gridify.png").setToolTip("gridify").setStyle(flatStyle).setTextAlign(CENTER,CENTER).setSize(30,30).setPositioning(43,-1,3,3));
  
  toolrows.root.n1.setComponent(makeCollapsable(toolbar));
  
  SingleCellContainer toolbar2 = (SingleCellContainer)(new SingleCellContainer("topbar")).setBgPanel(null).setPositioning(0,0,0,0);
  toolbar2.addComp((new Button("brush")).setIcon("ui/brush.png").setToolTip("brush").setToggle(true).setStyle(flatStyle).setTextAlign(CENTER,CENTER).setSize(30,30).setPositioning(3,-1,3,3));
  toolbar2.addComp((new Button("fill")).setIcon("ui/fill.png").setToolTip("fill").setToggle(true).setStyle(flatStyle).setTextAlign(CENTER,CENTER).setSize(30,30).setPositioning(43,-1,3,3));
  
  toolrows.root.n2.setComponent(makeCollapsable(toolbar2));
  
  toolrows.root.setDivideAm(100);
  
  toolcollapse.addComp(toolrows);
  toolcollapse.minh = 50;
  
   ActionEvent ae = new ActionEvent(){
    public void onComponentAction(Component c){
      switch (c.id){
        case "grid toggle":
          canvas.grid = ((Button)c).state == ButtonState.PRESSED;
        break;
        case "gridify":
          canvas.gridify();
        break;
        case "test":
          canvas.current= new  Ramp("accent",new int[]{#D4806B,#E9A874,#FFD27E});
        break;
      }
    }
  };
  toolbar.setActionEvent(ae);
  
  uistage = (TreeContainer)(new TreeContainer("container")).setPos(3,3).setSize(width-6,height-6).setPad(5);
  uistage.root.split(VERTICAL_SPLIT, true);//top bar and everything else
  uistage.root.setDivideAm(100);
  uistage.root.n2.split(HORIZONTAL_SPLIT, true);
  uistage.root.n1.setComponent(topbar);
  
  uistage.root.n2.n1.split(VERTICAL_SPLIT, false);
  uistage.root.n2.n1.setDivideAm(65);
  uistage.root.n2.n1.n1.setComponent(toolcollapse);
  uistage.root.n2.n1.n2.setComponent(canvascollapse);
  topbar.backgroundcolor = bg2;
  uistage.backgroundcolor = bg;
  
  masterbatch.addDrawable(uistage);
  inputListeners.add(uistage);
  ((PGraphicsOpenGL)g).textureSampling(2);
  strokeCap(SQUARE);
}
