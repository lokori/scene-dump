import java.applet.*;
import java.awt.*;
import java.awt.event.*;

public class appl extends tinyptc {

    private Image img = null;
    private SnowProducer limp;

    public void init() {
	System.out.println("applet init");
	setLayout(null);
	this.requestFocus();
	MediaTracker t = new MediaTracker(this);
	img = getImage(getCodeBase(),"kissa.jpg");
	try {
	    t.addImage(img,0);
	    t.waitForAll();
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
	limp = new SnowProducer();
	limp.initSnow(img, 800);
    }

    public void main(int width, int height) {
	while (true) {
	    limp.advanceSnow();
	    update(limp.pix);
	}
    }

}












