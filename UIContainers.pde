/*
UI processing lib by xelo
*/

import java.util.*;

abstract class Container extends Component{
  LinkedList<Component> compList = new LinkedList();
  String bgpanel="panel1";
  Container(String id){
    super(id);
    minw=36;minh=36;
  }
  void update(){

  }
  Component getComp(String id){
    for(Component c:compList){
      if(c.id.equals(id)){return c;}
    }
    return null;
  }
  Container setBgPanel(String panel){
    bgpanel = panel;
    return this;
  }
  Container setActionEvent(ActionEvent ae){
    this.ae=ae;
    for(Component comp:compList){
      comp.setActionEvent(ae);
    }
    return this;
  }
  public void draw(Camera c){
    if(bgpanel!=null){
      NineSlice ns = ui_nineslice.get(bgpanel);
      if(!ns.seethru){
        tint(backgroundcolor);
        ui_nineslice.get(bgpanel).draw9Slice(x,y,w,h);
        noTint();
      }else{
        fill(backgroundcolor);
        rect(x,y,w,h);
        ui_nineslice.get(bgpanel).draw9Slice(x,y,w,h);
      }
      
    }
  }
  public boolean onMouseScrolled(float dir){
    Iterator<Component> rv = compList.descendingIterator();
    while(rv.hasNext()){
      Component comp = rv.next();
      if(comp.active)
        if(comp.onMouseScrolled(dir)){return true;}
    }
    return false;
  }
  public boolean onMouseHovered(int mx,int my){
    mx-=x;
    my-=y;
    for(Component comp:compList){
      if(comp.active)
      comp.onMouseHovered(mx,my);
    }
    return (mx>0&&my>0&&mx<w&&my<h);
  }
  public boolean onMousePressed(int mx,int my,int duration,int button,  boolean doubleclicked){
    mx-=x;
    my-=y;
    if(mx>0&&my>0&&mx<w&&my<h){
      
      Iterator<Component> rv = compList.descendingIterator();
      while(rv.hasNext()){
        Component comp = rv.next();
        if(comp.active)
          if(comp.onMousePressed(mx,my,duration,button,doubleclicked)){break;}
      }
      return true;
    }
    return false;
  }
  public boolean onMouseReleased(int mx,int my,int button){
    mx-=x;
    my-=y;
    if(mx>0&&my>0&&mx<w&&my<h){
      for(Component comp:compList){
        if(comp.active)
        comp.onMouseReleased(mx,my,button);
      }
      return true;
    }
    return false;
  }
  public boolean onKeyPressed(char key, char keycode){
    return false;
  }
  public boolean onKeyHeld(HashMap<Integer,KeyHeldEvent>keysheld){
    return false;
  }
  public void addComp(Component c){
    compList.add(c);
    compList.sort(drawablecomp);
    c.parent = this;
  }
  public void alignWithBox(Component c,  
          float bx ,float by  ,float bw    ,float bh){
    if(compList.contains(c)){
      float nx=c.x,ny=c.y,nw=c.w,nh=c.h;
      if(c.left>=0){
        nx = c.left+padleft+bx;
      }
      if(c.top>=0){
        ny = c.top+padtop+by;
      }
      if(c.bottom>=0){
        if(c.top<0){
          ny = (by+bh-nh-padbottom)-c.bottom;
        }else{
          nh = (by+bh-ny-padbottom)-c.bottom;
        }
        
      }
      if(c.right>=0){
        if(c.left<0){
          nx = (bx+bw-nw-padright)-c.right;
        }else{
          nw = (bx+bw-nx-padright)-c.right;
        }
      }
      c.setPos(nx,ny).setSize(nw,nh);
    }
  }
  abstract void align(Component c);
  
  
  //todo
  @Override
  Component clone(String id){
    return (new Button(id==null?this.id+"(copy)":id))
          .setPad(padleft,padright,padtop,padbottom)
          .setPositioning(left,right,top,bottom);
  }

}


class Tab{
  ArrayList<Component> content = new ArrayList();
  String name;
  DiscreteTransition trans; 
  float tabx, tabminw;
  Tab(String name, DiscreteTransition trans,float tabx){
    this.name=name;
    this.trans=trans;
    this.tabx=tabx;
    tabminw = 15+guifont.getTextWidth(name,12);
  }
  float end(){return tabx+tabminw;}
}
abstract class TabbedContainer extends Container{
  ArrayList<Tab> tabs = new ArrayList();
  int activetab = 0;
  boolean toptab=true;
  boolean createTab=false;
  boolean fillspace = false;
  float tabheight = 40;
  float tabpan = 0;
  DiscreteTransition tabpantrans = new ExponentialTransition(0,0,0.2);
  SequentialTransition createBoxtrans = new SequentialTransition(
    0,0,new DiscreteTransition[]{
      new AcceleratingTransition(0,0,0.01,0.01),
      new AcceleratingTransition(0,0,0.01,0.01)
    }
  );
  HashMap<String,String> form = new HashMap();
  ArrayList<Component> toAdd = new ArrayList();
  
  abstract void fillTab(ArrayList<Component> tablist,HashMap<String,String>form);
  
  Container tabform = (CollapsableContainer)(new CollapsableContainer("tabform").setPad(0).setIndex(1));
  
  void createTab(String name, Component[] comps){
    float nx = tabs.isEmpty()?0:tabs.get(tabs.size()-1).end();
    Tab newtab = new Tab(name, new DampedBounce(-nx,0,0.3,0.2),nx);
    newtab.content.addAll(Arrays.asList(comps));
    for(Component c:newtab.content){
      toAdd.add(c);
    }
    tabs.add(newtab);
    changeActiveTab(tabs.indexOf(newtab));
  }
  
  void createTab(){
    float nx = tabs.isEmpty()?0:tabs.get(tabs.size()-1).end();
    Tab newtab = new Tab(form.containsKey("name")?form.get("name"):"New tab "+tabs.size(), new DampedBounce(-nx,0,0.3,0.2),nx);
    fillTab(newtab.content,form);
    for(Component c:newtab.content){
      toAdd.add(c);
    }
    tabs.add(newtab);
    changeActiveTab(tabs.indexOf(newtab));
  }
  
  abstract void createTabForm();
  
  void changeActiveTab(int tab){
    activetab = tab;
    
    for(Tab t:tabs){
      for(Component comp:t.content){
        comp.active = tabs.get(activetab)==t;
      }
    }
    
    
  }
  TabbedContainer(String id){
    super(id);
    minw=100;
    minh=60;
    addComp((new Button("leftscroll")).setText("").setIcon("ui/arrowleft.png").setSize(40,40).setPositioning(-1,40,0,-1).setPad(5,0,0,0));
    addComp((new Button("rightscroll")).setText("").setIcon("ui/arrowright.png").setSize(40,40).setPositioning(-1,0,0,-1).setPad(5,0,0,0));
    ActionEvent scroll = new ActionEvent(){
      public void onComponentAction(Component c){
        println(c.id);
        switch (c.id){
          case "leftscroll":
            tabpantrans.t-=5;
            tabpan = max(0,tabpan-100);
          break;
          case "rightscroll":
            float nx = tabs.isEmpty()?0:tabs.get(tabs.size()-1).end();
            tabpantrans.t+=5;
            tabpan = min(max(0,nx-(w-(tabheight+5)*(createTab?3:2))),tabpan+100);
          break;
        }
      }
    };
    getComp("leftscroll").setActionEvent(scroll);
    getComp("rightscroll").setActionEvent(scroll);
    addComp(tabform);
    tabform.active=false;
    createBoxtrans.transitions[0].sensitive = 0.05;
    createBoxtrans.transitions[1].sensitive = 0.05;
  }
  TabbedContainer haveCreateTab(boolean b){
    if(b==createTab){
      return this;
    }
    createTab = b;
    if(b){
      createTabForm();
    }
    return this;
  }
  TabbedContainer tabsOnTop(boolean b){
    
    toptab = b;
    setSize(w,h);
    return this;
  }
  
  void updateFormAnimation(){
    tabform.setSize(constrain(lerp(tabheight,fw,createBoxtrans.transitions[0].t),tabform.minw,w-padleft-padright),
                    constrain(lerp(tabheight,fh,createBoxtrans.transitions[1].t),tabform.minh,h-padtop-padbottom));
    float ctx=0.0;
    for(Tab t:tabs){
      ctx = max(ctx,t.tabx+t.tabminw);
    }
    tabform.setPos(lerp(ctx+padleft,constrain(ctx-fw*0.5,padleft,w-fw-padright),createBoxtrans.transitions[0].t),tabheight);
  }
  
  public void predraw(){
    
    for(Component c:toAdd){
      addComp(c);
      align(c);
      c.active = tabs.get(activetab).content.contains(c);
    }
    toAdd.clear();
    
    super.predraw();
    tabpantrans.target=tabpan;
    tabpantrans.update();
    createBoxtrans.update();
    
    tabform.active=!(createBoxtrans.complete && createBoxtrans.target==0);
    if(!createBoxtrans.complete){
      updateFormAnimation();
    }
  }
  
  public void draw(Camera c){
    String panel = "tab";
    float taby = 0;
    if(bgpanel!=null){
      tint(backgroundcolor);
      
      
      if(toptab){
        ui_nineslice.get(bgpanel).draw9Slice(x,y+tabheight,w,h-tabheight);
        ui_nineslice.get("below").draw9Slice(x,y,w,tabheight);
      }else{
        taby = h-tabheight;
        panel = "downtab";
        ui_nineslice.get(bgpanel).draw9Slice(x,y,w,h-tabheight);
        ui_nineslice.get("below").draw9Slice(x,y+h-tabheight,w,tabheight);
      }
      noTint();
    }
    ui_translate_push(x,y);
    float ctx = 0;
    float tp = tabpantrans.t;
    float aw = w-(tabheight*2+10);
    ui_clip_push(0,-20,aw,h+40);
    
    //tabs
    
    textAlign(CENTER,CENTER);
    for(Tab t:tabs){
      if(t.tabx-tp<aw && t.tabx+t.tabminw-tp>0){
        if(activetab==tabs.indexOf(t)){
          ui_nineslice.get(panel+"noshadow").draw9Slice(t.tabx-tp,taby,t.tabminw,tabheight);
          fill(80);
        }else{
          tint(150);
          ui_nineslice.get(panel).draw9Slice(t.tabx-tp,taby,t.tabminw,tabheight);
          fill(50);
          noTint();
        }
        text(t.name,t.tabx-tp,taby,t.tabminw,tabheight);
      }
      ctx = max(ctx,t.tabx+t.tabminw);
    }
    
    ui_nineslice.get("sideshadow").draw9Slice(0,taby,aw,tabheight);
    
    
    
    
    ui_clip_push(0,0,w,h);
    
    
    for(Component comp:compList){
      if(comp.active)
      comp.predraw();
    }
    
    for(Component comp:compList){
      if(comp.active)
      comp.draw(c);
    }
    
    for(Component comp:compList){
      if(comp.active)
      comp.postdraw();
    }
    if(createTab&&ctx-tp+tabheight<aw){
      textAlign(CENTER,CENTER);
      ui_nineslice.get(tabform.active?"tabnoshadow":"button1").draw9Slice(ctx-tp+3,taby,tabheight,tabheight);
      text("+",ctx-tp+3,taby,tabheight,tabheight);
    }
    ui_translate_pop();
    ui_clip_pop();
    ui_clip_pop();
  }
  
  public void postdraw(){
  
  }
  public boolean onMousePressed(int mx,int my,int duration,int button,  boolean doubleclicked){
    float amx=mx-this.x;
    float amy=my-this.y;

    if(amx>0&&amy>0&&amx<w&&amy<h){
      float ctx = 0;
      float tp = tabpantrans.t;
      float aw = w-tabheight*2;
      float taby = toptab?0:h-tabheight;
      //tabs
      fill(80);
      if(duration==0){
        if(amx<aw)
        for(Tab t:tabs){
          if(t.tabx-tp<aw && t.tabx+t.tabminw-tp>0){
            if(isInWH(amx,amy,t.tabx-tp,taby,t.tabminw,tabheight)){
              changeActiveTab(tabs.indexOf(t));
            }
          }
          ctx = max(ctx,t.tabx+t.tabminw);
        }
        
        if(createTab){
          if(ctx-tp<aw){
            if(isInWH(amx,amy,ctx-tp+3,taby,tabheight,tabheight)){
              createBoxtrans.target=1-createBoxtrans.target;
            }else if(!isInWH(amx,amy,tabform.x,tabform.y,tabform.w,tabform.h)){
              createBoxtrans.target=0;
            }
          }else{
            createBoxtrans.target=0;
          }
        }
      }
    }
    
    return super.onMousePressed(mx,my,duration,button,doubleclicked);
  }
  float fw,fh;
  TabbedContainer setFormSize(float w_,float h_){
    fw=w_;
    fh=h_;
     return this;
  }
  TabbedContainer setSize(float w_,float h_){
    
    super.setSize(w_,h_);
    for(Component comp:compList){
      align(comp);
      w = max(w,comp.minw+padleft+padright+comp.right+comp.left);
      h = max(h,comp.minh+padleft+padright+comp.top+comp.bottom+tabheight);
    }
    w=max(w,tabheight*3+10);
    if(w!=w_){
      minw = w;
    }
    if(h!=h_){
      minh = h;
    }
    float ay = toptab?0:h-tabheight;
    getComp("leftscroll").setSize(tabheight-5,tabheight-5).setPos(w-86,ay);
    getComp("rightscroll").setSize(tabheight-5,tabheight-5).setPos(w-43,ay);
    updateFormAnimation();
    return this;
  }
  
  TabbedContainer setActionEvent(ActionEvent ae){
    this.ae=ae;
    for(Component comp:compList){
      for(Tab t:tabs){
        if(t.content.contains(comp)){
          comp.setActionEvent(ae);
          break;
        }
      }
    }
    return this;
  }
  
  public void align(Component c){
    if(compList.contains(c)){
      if(toptab){
        alignWithBox(c,0,tabheight,w,h-tabheight);
      }else{
        alignWithBox(c,0,0,w,h-tabheight);
      }
    }
    if(c.minw>w-(padleft+padright+c.left+c.right)){
      minw = padleft+padright+c.left+c.right; 
    }
    if(c.minh>h-(padtop+padbottom+c.top+c.bottom)){
      minh = padtop+padbottom+c.top+c.bottom+tabheight; 
    }
    if(minw>w||minh>h){
      setSize(w,h);
      if(parent!=null){
        parent.align(this);
      }
    }
  }
}

boolean HORIZONTAL_SPLIT=true;
boolean VERTICAL_SPLIT=false;
class TreeContainerNode{
  TreeContainer container;
  Component contain;
  float x,y,w,h;
  float divideam;
  TreeContainerNode n1,n2;
  TreeContainerNode parent;
  int level=0;
  boolean split=false;
  boolean adjustablesplit=false;
  boolean horizontal;
  int id;
  TreeContainerNode(TreeContainer container,int id, float x,float y,float w,float h){
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
    horizontal = w>h;
    this.container = container;
    this.id=id;
    container.nodes.add(this);
  }
  void splitSelect(int x_, int y_){
    if(x_>=x&&y_>=y&&x_<x+w&&y_<y+h){
      if(!split){
        split();
      }else{
        n1.splitSelect(x_,y_);
        n2.splitSelect(x_,y_);
      }
    }
  }
  TreeContainerNode search(Component c){
    if(!split){
      return contain==c? this:null;
    }else{
      TreeContainerNode o = n1.search(c);
      return o==null?n2.search(c):o;
    }
  }
  void split(boolean horizontal, boolean adjustable){
    this.horizontal = horizontal;
    adjustablesplit = adjustable;
    this.split();
  }
  void split(){
    split = true;
    if(horizontal){
      n1 = new TreeContainerNode(container,container.nodeindexcount++,x      ,y,w*0.5,h);
      n2 = new TreeContainerNode(container,container.nodeindexcount++,x+w*0.5,y,w*0.5,h);
      divideam = w*0.5;
    }else{
      n1 = new TreeContainerNode(container,container.nodeindexcount++,x,y      ,w,h*0.5);
      n2 = new TreeContainerNode(container,container.nodeindexcount++,x,y+h*0.5,w,h*0.5);
      divideam = h*0.5;
    }
    n1.contain = contain;
    n1.level=level+1;
    n2.level=level+1;
    n1.parent=this;
    n2.parent=this;
    contain = null;
    container.root.refreshMinSize();
    
  }
  float minw,minh;
  void refreshMinSize(){ //recursively find the minimum width
    if(split){
      n1.refreshMinSize();
      n2.refreshMinSize();
      if(horizontal){
        minw=n1.minw+n2.minw;
        minh=max(n1.minh,n2.minh);
      }else{
        minw=max(n1.minw,n2.minw);
        minh=n1.minh+n2.minh;
      }
    }else if(contain!=null){
      minw=container.padleft+container.padright+contain.minw+contain.left+contain.right;
      minh=container.padtop+container.padbottom+contain.minh+contain.top+contain.bottom;
    }else{
      minw=container.padleft+container.padright;
      minh=container.padtop+container.padbottom;
    }
    if(minw>w||minh>h)
    {
      resize(max(w,minw),max(h,minh));
    }
  }
  void setDivideAm(float d){
    
    divideam = constrain(d,5f,horizontal?w-5:h-5);
    if(!split){return;}
    
    
    
    if(horizontal){
      
      //constrain to the minimum sizes of the containing elements
      divideam = max(divideam,n1.minw);
      divideam = min(divideam,w-(n2.minw));
      n2.reposition(x+divideam,y);
      n1.resize(divideam,h);
      
      n2.resize(w-divideam,h);
      
    }else{
      float cpad = container.padtop+container.padbottom;
      divideam = max(divideam,n1.minh);
      divideam = min(divideam,h-(n2.minh));
      if(n1.contain!=null){
        divideam = max(divideam,n1.contain.minh+cpad+n1.contain.top+n1.contain.bottom);
      }
      if(n2.contain!=null){
        divideam = min(divideam,h-(n2.contain.minh+cpad+n2.contain.top+n2.contain.bottom));
      }
      
      n2.reposition(x,y+divideam);
      n1.resize(w,divideam);
      n2.resize(w,h-divideam);
      
    }
  }
  void resize(float w,float h){
    this.w=w;
    this.h=h;
    if(contain!=null){
      container.align(contain);
    }
    if(split)
      setDivideAm(divideam);
  }
  void reposition(float x,float y){
    this.x=x;
    this.y=y;
    if(split){
      n1.reposition(x,y);
      n2.reposition(x+(horizontal?divideam:0),y+(!horizontal?divideam:0));
    }
  }
  
  void setComponent(Component c){
    contain = c;
    container.addComp(c);
    container.root.refreshMinSize();
  }
  
}
class TreeContainer extends Container{
  TreeContainerNode root;
  LinkedList<TreeContainerNode> nodes = new LinkedList();
  int nodeindexcount=0;
  TreeContainer(String id){
    super(id);
  }
  TreeContainer setIndex(int z_){
    z=z_;
    return this;
  }
  @Override
  TreeContainer setSize(float w_,float h_){
    w=w_;
    h=h_;
    if(root==null){
      root = new TreeContainerNode(this,nodeindexcount++,0,0,w,h);
    }else{
      root.resize(w_,h_);
    }
    return this;
  }
  void update(){
    
  }
  
  public boolean onMouseHovered(int mx,int my){
    float amx=mx-this.x;
    float amy=my-this.y;
     if(amx>0&&amy>0&&amx<w&&amy<h){
        for(TreeContainerNode tn:nodes){
          
          if(tn.split&&tn.adjustablesplit){
            float dist = 9999;
            if(tn.horizontal){
              dist = getLinePointDis(tn.x+tn.divideam,tn.y+5,tn.x+tn.divideam,tn.y+h-10,amx,amy);
            }else{
              dist = getLinePointDis(tn.x+5,tn.y+tn.divideam,tn.x+tn.w-10,tn.y+tn.divideam,amx,amy);
            }
            
            if(dist<5){
              cursor=HAND;
              break;
            }
          }
        }
     }
    return super.onMouseHovered(mx,my);
  }
  TreeContainerNode splitdrag = null;
  float initdiff=0;
  public boolean onMousePressed(int mx,int my,int duration,int button,  boolean doubleclicked){
    float amx=mx-this.x;
    float amy=my-this.y;

    if(amx>0&&amy>0&&amx<w&&amy<h){
      
      if(duration==0){
        
        for(TreeContainerNode tn:nodes){
          if(tn.split&&tn.adjustablesplit){
            float dist = 9999;
            if(tn.horizontal){
              dist = getLinePointDis(tn.x+tn.divideam,tn.y+5,tn.x+tn.divideam,tn.y+h-10,amx,amy);
            }else{
              dist = getLinePointDis(tn.x+5,tn.y+tn.divideam,tn.x+tn.w-10,tn.y+tn.divideam,amx,amy);
            }

            if(dist<5){
              splitdrag = tn;
              initdiff = splitdrag.divideam;
              break;
            }
          }
        }
      }else if(splitdrag!=null){
        cursor=MOVE;
        if(splitdrag.horizontal){
          splitdrag.setDivideAm(constrain(amx-splitdrag.x,0,splitdrag.w));
        }else {
          splitdrag.setDivideAm(constrain(amy-splitdrag.y,0,splitdrag.h));
        }
      }
    }
    
    return splitdrag!=null||super.onMousePressed(mx,my,duration,button,doubleclicked);
  }
  public boolean onMouseReleased(int mx,int my,int button){
    splitdrag =null;
    return super.onMouseReleased(mx,my,button);
  }
  public void predraw(){
  
  }
  
  public void draw(Camera c){
    super.draw(c);
    ui_translate_push(x,y);
    for(Component comp:compList){
      comp.predraw();
    }
    ui_clip_push(0,0,w,h);
    for(TreeContainerNode tn:nodes){
      if(tn.split&&tn.adjustablesplit){
        if(tn.horizontal){
          stroke(0,50);
          line(tn.x+tn.divideam,tn.y+5,tn.x+tn.divideam,tn.y+h-10);
        }else{
          stroke(0,50);
          line(tn.x+5,tn.y+tn.divideam,tn.x+tn.w-10,tn.y+tn.divideam);
        }
      }
      
      
    }
    
    
    
    for(Component comp:compList){
      comp.draw(c);
    }
    
    

    ui_clip_pop();
    ui_translate_pop();
    
  }
  
  public void postdraw(){
    ui_translate_push(x,y);
    for(Component comp:compList){
      comp.postdraw();
    }
    ui_translate_pop();
  }
  

  public void align(Component c){
    if(compList.contains(c)){
      TreeContainerNode tr = root.search(c);
      if(tr!=null){
        //println("tree container align: ",c.id,tr.x,tr.y,tr.w,tr.h);
        alignWithBox(c,tr.x,tr.y,tr.w,tr.h);
      }
    }
  }
  
}

CollapsableContainer makeCollapsable(Component c){
  CollapsableContainer collapse= (CollapsableContainer)(new CollapsableContainer(c.id+"collapse").setSize(c.w,c.h).setPositioning(0,0,0,0).setPad(0));
  collapse.addComp(c);
  return collapse;
}

class CollapsableContainer extends Container{
  boolean collapsed = false;
  PImage collapsedicon;
  boolean allowoverflow=true;
  CollapsableContainer(String id){
    super(id);
    collapsedicon = loadImage("ui/minimised.png");
    minw=36;minh=36;
    
  }
  DampedBounce collapsetransistion=new DampedBounce(0,0,0.3,0.2);
  void update(){
    collapsetransistion.target = collapsed?1:0;
    collapsetransistion.update();
    if(collapsetransistion.t<0){
      collapsetransistion.t=0;
      collapsetransistion.v=0;
    }
  }

  public void draw(Camera c){
    
    
    if(collapsetransistion.t>0.01){
      float aw2 = w*0.5*collapsetransistion.t;
      float ah2 = h*0.5*collapsetransistion.t;
      ui_nineslice.get(bgpanel).draw9Slice(x+w*0.5-aw2,y+h*0.5-ah2,aw2*2,ah2*2);
      pushMatrix();
      translate(x+w/2,y+h/2);
      rotate((1-collapsetransistion.t)*3);
      image(collapsedicon,-24,-24,48,48);
      popMatrix();
    }
    if(collapsed){  
      return;
    }
    
    
    ui_translate_push(x,y);
    if(!allowoverflow){
      ui_clip_push(0,0,w,h);
    }
    for(Component comp:compList){
      comp.predraw();
    }
    
    for(Component comp:compList){
      comp.draw(c);
    }
    
    ui_translate_pop();
    if(!allowoverflow){
      ui_clip_pop();
    }
  }
  
  public void postdraw(){
    ui_translate_push(x,y);
    for(Component comp:compList){
      comp.postdraw();
    }
    ui_translate_pop();
  }
  
  
  CollapsableContainer setSize(float w_,float h_){
    
    w=max(w_,minw);
    h=max(h_,minh);
    float aw=w,ah=h;
    for(Component comp:compList){
      align(comp);
      aw = max(aw,comp.w+padleft+padright+comp.right+comp.left);
      ah = max(ah,comp.h+padleft+padright+comp.top);
    }
    collapsed=(aw>w)||(ah>h);
    for(Component comp:compList){
      comp.active= !collapsed;
    }

    return this;
  }
  public void align(Component c){
    if(compList.contains(c)){
      //println(c.id,0,0,max(w,c.minw),h);
      if(w<c.minw+c.left+padleft+c.right+padright+1  || 
          h<c.minh+c.top+padtop+c.bottom+padbottom+1){
            collapsed=true;
        return;
      }
      alignWithBox(c,0,0,w,h);
    }
    
  }
}
class RowPos{
   Component c;
    float ax,aw,w,minw;
   float weight=1;
    RowPos(Component c,float w,float minw,float weight){
      this.c=c;
      this.w=w;
      this.minw=minw;
      this.weight=weight;
    }
  }
class RowCalc{
  float total=0;
  float mintotal=0;
  LinkedList<RowPos> positions = new LinkedList();
  
  
  void addPos(RowPos r){
    positions.add(r);
    total+=r.w;
    mintotal+=r.minw;
  }
  
  float calc(float reqw){
    if(reqw<=mintotal){
      reqw=mintotal;
    }
    float spare = reqw-mintotal;
    println("-----spare: "+spare);
    float ideal = reqw;
    int am = positions.size();
    for(RowPos r:positions){
      if(r.weight==0){
        ideal-=r.minw;
        am--;
      }
    }
    ideal/=max(1,am);
    
    float totalunder =0.00001;
    float c = 0;
    
    for(RowPos r:positions){
      if(r.minw<ideal){
        totalunder += r.minw*r.weight;
      }
    }
    println("-----ideal: "+ideal,"total: ",totalunder);
    for(RowPos r:positions){
      float iw = r.minw + ((r.minw<ideal)?spare*r.minw*r.weight/totalunder:0);
      r.ax=c;
      r.aw=iw;
      c+=iw;
      println("-----iw: "+iw);
    }
    return reqw;
  }
}
class RowContainer extends Container{
  ArrayList<RowPos> rowcells = new ArrayList();
  boolean adaptive=false;
  float adratio;
  boolean horizontal = HORIZONTAL_SPLIT;
  RowContainer(String id){
    super(id);
  }
  public RowContainer setDirection(boolean dir){
    horizontal=dir;
    alignAll();
    return this;
  }
  public RowContainer setAdaptive(boolean ad,float ratio){
    adaptive=ad;
    adratio = ratio;
    return this;
  }
  public void align(Component c){
    if(compList.contains(c)){
      alignAll();
    }
  }
  public void addComp(Component c){
    addComp(c,1);
    
  }
  public void addComp(Component c,float weight){
    super.addComp(c);
    rowcells.add(new RowPos(c,c.w,c.minw,weight));
    resetRowPos();
  }
  void resetRowPos(){
    float padding = horizontal?(padleft+padright):(padtop+padbottom);
    for(RowPos r:rowcells){
      if(horizontal){
        r.w=r.minw=r.c.minw+r.c.right+r.c.left+padding;

      }else{
        r.w=r.minw=r.c.minh+r.c.top+r.c.bottom+padding;

      }
    }
  }
  public void predraw(){
  
  }
  
  public void draw(Camera c){
    super.draw(c);
    ui_translate_push(x,y);
    ui_clip_push(0,0,w,h);
    for(Component comp:compList){
      comp.predraw();
    }
    
    for(Component comp:compList){
      comp.draw(c);
    }
    
    ui_translate_pop();
    ui_clip_pop();
  }
  
  public void postdraw(){
    ui_translate_push(x,y);
    for(Component comp:compList){
      comp.postdraw();
    }
    ui_translate_pop();
  }
  RowContainer setSize(float w_,float h_){
    
    super.setSize(w_,h_);
    if(adaptive){
      horizontal = w/h > adratio;
    }
    alignAll();
    return this;
  }
  
  public void alignAll(){
    minh=0;
    minw = 0;
    resetRowPos();
    RowCalc rc = new RowCalc();
    
    for(RowPos r:rowcells){
      Component c = r.c;
      rc.addPos(r);
      if(horizontal){
        minh = max(minh,(c.top<0?0:c.top)+padtop+padbottom+c.minh+(c.bottom<0?0:c.bottom));
      }else{
        minw = max(minw,(c.left<0?0:c.left)+padleft+padright+c.minw+(c.right<0?0:c.right));
      }
    }
    if(horizontal){
      float rw = rc.calc(w);
      if(rw>w){
        minw = max(minw,rw);
      }
    }else{
      float rh = rc.calc(h);
      if(rh>h){
        minh = max(minh,rh);
      }
    }
    if(minw>w||minh>h){
      w=minw;
      h=minh;
      if(parent!=null){
        parent.align(this);
      }
      return;
    }
    Iterator<RowPos> iter = rc.positions.iterator();
    for(Component c:compList){
      RowPos rp = (RowPos)iter.next();
      if(horizontal){
        alignWithBox(c,rp.ax,0,rp.aw,h);
        
      }else{
        alignWithBox(c,0,rp.ax,w,rp.aw);
        //println(rp.ax,rp.aw,rc.positions.size());
        
      }
    }
    
  }
  
}
class SingleCellContainer extends Container{
  SingleCellContainer setIndex(int z_){
    z=z_;
    return this;
  }
  
  
  SingleCellContainer(String id){
    super(id);
  }
  
  public void predraw(){
    ui_translate_push(x,y);
    for(Component comp:compList){
      comp.predraw();
    }
    ui_translate_pop();
  }
  
  public void draw(Camera c){
    super.draw(c);
    ui_translate_push(x,y);
    
    
    
    ui_clip_push(0,0,w,h);
    
    
    
    
    for(Component comp:compList){
      comp.draw(c);
    }
    
    
    ui_clip_pop();
    
    ui_translate_pop();
    
  }
  
  public void postdraw(){
    ui_translate_push(x,y);
    for(Component comp:compList){
      comp.postdraw();
    }
    ui_translate_pop();
  }
  
  
  SingleCellContainer setSize(float w_,float h_){
    
    super.setSize(w_,h_);
    for(Component comp:compList){
      align(comp);
      w = max(w,comp.w+padleft+padright+comp.right+comp.left);
      h = max(h,comp.h+padleft+padright+comp.top);
    }
    if(w!=w_){
      minw = w;
    }
    if(h!=h_){
      minh = h;
    }
    return this;
  }
  
  public void align(Component c){
    if(compList.contains(c)){
      //println(c.id,0,0,w,h);
      alignWithBox(c,0,0,w,h);
    }
    if(c.minw>w-(padleft+padright+c.left+c.right)){
      minw = padleft+padright+c.left+c.right; 
    }
    if(c.minh>h-(padtop+padbottom+c.top+c.bottom)){
      minh = padtop+padbottom+c.top+c.bottom; 
    }
    if(minw>w||minh>h){
      setSize(w,h);
      if(parent!=null){
        parent.align(this);
      }
    }
  }
  
}
