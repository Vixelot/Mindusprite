/*
UI processing lib by xelo
*/
import java.util.*;

interface LoadSavable{
  public void save(JSONObject parent);
  public void load(JSONObject parent);
}
interface Orderable{
  public int getDrawIndex();
}

interface Drawable extends Orderable{
  public void predraw();
  public void draw(Camera c);
  public void postdraw();
  
  
  public boolean getActive();
  public void setActive(boolean active);
}


interface InputListener extends Orderable{
  public final int doubleClickMaxDelay=15;
  public boolean onMouseHovered(int mx,int my);
  public boolean onMousePressed(int mx,int my,int duration,int button, boolean doubleclicked);
  public boolean onMouseReleased(int mx,int my,int button);
  public boolean onMouseScrolled(float dir);
  public boolean onKeyPressed(char key, char keycode);
  public boolean onKeyHeld(HashMap<Integer,KeyHeldEvent>keysheld);
  

}

interface ActionEvent{
  public void onComponentAction(Component c);
}

class KeyHeldEvent{
  int key=-1;
  int keycode=-1;
  int duration=0;
  KeyHeldEvent(char key, int duration){
    this.key=key;
    this.duration=duration;
  }
  KeyHeldEvent(int keycode, int duration){
    this.keycode=keycode;
    this.duration=duration;
  }
  
  
}
