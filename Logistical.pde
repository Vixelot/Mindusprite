/*
UI processing lib by xelo
*/
import java.util.*;
/*
  This entire section is dedicated to make processing draw textured quads faster.
  Feels like a making a rube goldberg machine to flip pancakes for me

  After modding mindustry, it seems anuke had the same idea, but executed 10x better,
*/
class DrawBatcher implements Drawable{
  HashMap<String,SpriteAtlas> textures = new HashMap();
  TreeMap<Integer, DrawBatch> drawbatch = new TreeMap();
  SpriteAtlas defaultTex;
  String activetex = null;
  DrawBatcher(){
    defaultTex = loadSpriteAtlas("404.png", new TileSpriteAtlas()); // the not found texture
    addSpriteAtlas("404",defaultTex);
  }
  SpriteDrawRequest rect(float x,float y,float w, float h,float rot, int z, String sb, int tx,int ty,int tw,int th){
    SpriteAtlas pp = textures.get(sb);
    if(pp==null){
      pp = defaultTex;
    }
    SpriteDrawRequest sdr = new SpriteDrawRequest(sb,x,y,w,h,rot,z,tx,ty,tw,th,this);
    addDrawRequest(sdr);
    return sdr;
  }
  
  SpriteDrawRequest rect(float x,float y,float w, float h,float rot,int z, String sb,int t){
    SpriteAtlas pp = textures.get(sb);
    if(pp==null){
      pp = defaultTex;
      t=0;
    }
    SpriteDrawRequest sdr = new SpriteDrawRequest(sb,x,y,w,h,rot,z,0,0,0,0,this);
    pp.getSpriteIndex(sdr,t);
    addDrawRequest(sdr);
    return sdr;
  }
  
  public void predraw(){
    for(int i :drawbatch.keySet()){
      DrawBatch db  = drawbatch.get(i);
      LinkedList<Drawable> dbl = db.batched.get("--");
      for(Drawable d:dbl){
        d.predraw();
      }
    }
  }
  
  public void draw(Camera c){
    for(int i :drawbatch.keySet()){
      DrawBatch db  = drawbatch.get(i);
      
      // here is where the actual drawing happens
      
      for(String s:db.batched.keySet()){
        LinkedList<Drawable> dbl = db.batched.get(s);
        for(Drawable d:dbl){
          d.draw(c);
        }
      }
      
    }
    if(activetex!=null){
      endShape();
      activetex = null;
    }
  }
  
  
  
  public void postdraw(){
    for(int i :drawbatch.keySet()){
      DrawBatch db  = drawbatch.get(i);
      LinkedList<Drawable> dbl = db.batched.get("--");
      for(Drawable d:dbl){
        d.postdraw();
      }
    }
  }
  
  public void flush(){
    for(int i :drawbatch.keySet()){
      DrawBatch db  = drawbatch.get(i);
      for(String s:db.batched.keySet()){
        db.batched.get(s).clear();
      }
    }
  }
  
  public void clearAll(){
    drawbatch.clear();
  }
  
  public void addSpriteAtlas(String name,SpriteAtlas sa){
    textures.put(name,sa.setName(name));
  }
  
  public void setActiveTexture(String name){
    
    if(name==null){
      endShape();
      activetex = null;
      return;
    }
    if(name.equals(activetex)){
      return;
    }
    
    if(!textures.containsKey(name)){
      name = "404";
    }
    if(activetex!=null){
      endShape();
    }
    activetex = name;
    noStroke();
    beginShape(QUADS);
    texture(textures.get(name));
    
  }
  
  public void addDrawRequest(SpriteDrawRequest dr){
    if(!drawbatch.containsKey(dr.z)){
      drawbatch.put(dr.z,new DrawBatch());
    }
    drawbatch.get(dr.z).addSpriteDrawRequest(dr);
    
  }
  
  public void addDrawable(Drawable dr){
    
    if(!drawbatch.containsKey(dr.getDrawIndex())){
      drawbatch.put(dr.getDrawIndex(),new DrawBatch());
    }
    drawbatch.get(dr.getDrawIndex()).addDrawable(dr);
    
  }
  
  
  public int getDrawIndex(){ return -1;}
  public boolean getActive(){return true;}
  public void setActive(boolean active){}
  
  String toString(){
    StringBuilder sb=  new StringBuilder();
    sb.append("DrawBatcher: ");
    sb.append(drawbatch.toString());
    
    return sb.toString();
  }
}

public abstract class SpriteAtlas extends PImage{
  public SpriteAtlas(){
    super();
  }
  public abstract void getSpriteIndex(SpriteDrawRequest dr, int index);
  public void directDrawSpriteIndexWH(float x,float y,float w,float h, int index){
    directDrawSpriteIndex(x,y,x+w,y+h,index);
  }
  public abstract void directDrawSpriteIndex(float x,float y,float x2,float y2, int index);
  public abstract int maxIndex();
  String name;
  boolean update = false;
  public SpriteAtlas setName(String s){this.name=s; return this;}

}

public class TileSpriteAtlas extends SpriteAtlas{
  int tilew, tileh;
  public TileSpriteAtlas(){
    super();
  }
  public TileSpriteAtlas setName(String s){this.name=s; return this;}
  public TileSpriteAtlas setTileDim(int w,int h){this.tilew=this.width/w; this.tileh=this.height/h; return this;}
  public TileSpriteAtlas setDimInTiles(int w,int h){this.tilew=w; this.tileh=h; return this;}
  public int maxIndex(){
    return tilew*tileh-1;
  }
  void getSpriteIndex(SpriteDrawRequest dr, int index){
    int tx =index%tilew;
    int ty =index/tilew;
    float tw = this.width/(float)tilew;
    float th = this.height/(float)tileh;
    
    dr.tx =  (int)(tw * tx);
    dr.ty =  (int)(th * ty);
    dr.tx2 = (int)(tw * (tx+1));
    dr.ty2 = (int)(th * (ty+1));
  }
  
  void directDrawSpriteIndex(float x,float y,float x2,float y2, int index){
    int tx =index%tilew;
    int ty =index/tilew;
    float tw = this.width/(float)tilew;
    float th = this.height/(float)tileh;
    float vx =  (int)(tw * tx);
    float vy =  (int)(th * ty);
    float vx2 = (int)(tw * (tx+1));
    float vy2 = (int)(th * (ty+1));
    beginShape(QUADS);
    texture(this);
      vertex(x,y,vx,vy);
      vertex(x2,y,vx2,vy);
      vertex(x2,y2,vx2,vy2);
      vertex(x,y2,vx,vy2);
    endShape();
    
    
  }

}


public <T extends SpriteAtlas> T  loadSpriteAtlas(String s, T atlas){
    PImage temp = loadImage(s);
    atlas.init(temp.width,temp.height,ARGB,1);
    atlas.parent=this; //this line is all createImage() adds vs just new Pimage()
    //then copy everything over.
    atlas.loadPixels();
    temp.loadPixels();
    arrayCopy(temp.pixels,atlas.pixels);
    atlas.updatePixels();
    return atlas;
}




Comparator<DrawBatch> batchcomp = new Comparator<DrawBatch>(){
  
  @Override
  public int compare(DrawBatch d1 ,DrawBatch d2){
    return Integer.compare(d1.index, d2.index);
  }
};

Comparator<Drawable> drawablecomp = new Comparator<Drawable>(){
  
  @Override
  public int compare(Drawable d1 ,Drawable d2){
    return Integer.compare(d1.getDrawIndex(), d2.getDrawIndex());
  }
};


class DrawBatch{
  HashMap<String,LinkedList<Drawable>> batched = new HashMap();
  int index;
  DrawBatch(){
    batched.put("--", new LinkedList<Drawable>());
  }
  void addSpriteDrawRequest(SpriteDrawRequest sdr){
    if(!batched.containsKey(sdr.imageid)){
      batched.put(sdr.imageid, new LinkedList<Drawable>());
    }
    batched.get(sdr.imageid).add(sdr);
  }
  void addDrawable(Drawable sdr){
    batched.get("--").add(sdr);
  }
  
  String toString(){
    StringBuilder sb=  new StringBuilder();
    sb.append("DrawBatch on layer ");
    sb.append(index);
    sb.append(": ");
    sb.append(batched.toString());
    
    return sb.toString();
  }
  
}




class SpriteDrawRequest implements Drawable{
  private int z;
  String imageid;
  float x,y,w,h;
  float rotation = 0;
  int tx,ty,tx2,ty2;
  DrawBatcher batcher;
  
  PVector horz,vert;
  
  PVector vertices[] = new PVector[4];
  
  SpriteDrawRequest(String imageid, float x,float y,float w,float h, float rot,int z,int tx, int ty, int tw,int th, DrawBatcher batcher){
    this.imageid = imageid;
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
    this.z=z;
    this.tx=tx;
    this.ty=ty;
    this.tx2=tx+tw;
    this.ty2=ty+th;
    this.batcher=batcher;
    rotation = rot;
    horz = new PVector(cos(rot)*w*0.5,sin(rot)*w*0.5);
    vert = new PVector(sin(rot)*h*0.5,-cos(rot)*h*0.5);
    resetVert();
  }
  public void setRot(float rot){
    rotation = rot;
    horz = new PVector(cos(rot)*w*0.5,sin(rot)*w*0.5);
    vert = new PVector(sin(rot)*h*0.5,-cos(rot)*h*0.5);
    resetVert();
  }
  public void setPos(float x,float y){
    this.x=x;
    this.y=y;
    resetVert();
  }
  public void resetVert(){
    vertices[2] = PVector.add(horz,vert);
    vertices[1] = PVector.add(horz,PVector.mult(vert,-1));
    vertices[0] =PVector.mult(vertices[2],-1);
    vertices[3] =PVector.mult(vertices[1],-1);
    for(int i = 0;i<4;i++){
      vertices[i].add(x,y);
    }
  }
  
  public void predraw(){
  
  }
  public void drawNoTexture(Camera c){
    vertex(vertices[0].x,vertices[0].y);
    vertex(vertices[1].x,vertices[1].y);
    vertex(vertices[2].x,vertices[2].y);
    vertex(vertices[3].x,vertices[3].y);
  }
  public void drawTextureCoords(Camera c){
    vertex(tx,ty);
    vertex(tx2,ty);
    vertex(tx2,ty2);
    vertex(tx,ty2);
  }
  public void draw(Camera c){
    batcher.setActiveTexture(imageid);
    vertex(vertices[0].x,vertices[0].y,tx,ty);
    vertex(vertices[1].x,vertices[1].y,tx2,ty);
    vertex(vertices[2].x,vertices[2].y,tx2,ty2);
    vertex(vertices[3].x,vertices[3].y,tx,ty2);
    

  }
  
  public void postdraw(){
  
  }
  
  public int getDrawIndex(){ return z;}
  public boolean getActive(){return true;}
  public void setActive(boolean active){}
  
  String toString(){
    StringBuilder sb=  new StringBuilder();
    sb.append("Sprite (x,y,z): ");
    sb.append(x);sb.append(", ");sb.append(y);sb.append(", ");sb.append(z);
    sb.append("   sprite:");
    sb.append(imageid); 
    return sb.toString();
  }

}
