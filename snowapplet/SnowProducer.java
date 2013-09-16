import java.awt.image.*;
import java.awt.*;
import java.util.*;

public class SnowProducer {

    public void initSnow(Image i, int snowcount) {
	wid = i.getWidth(null);
	hei = i.getHeight(null);
	pix = new int[hei*wid];	
	pixels = new int[wid * hei];

        PixelGrabber pg = new PixelGrabber(i, 0, 0, wid, hei, pixels, 0, wid);
        try {
            pg.grabPixels();
        } catch (InterruptedException e) {
            System.err.println("interrupted waiting for pixels!");
            return;
        }
        if ((pg.getStatus() & ImageObserver.ABORT) != 0) {
            System.err.println("image fetch aborted or errored");
            return;
        }	
	snow = new int[snowcount][2];
	for (int ii = 0; ii<snowcount; ii++)
	    snow[ii][1] = (snowRand.nextInt() & 3) + 1;
	snowFlow = new int[512];
	for (int ii = 0; ii<512; ii++) 
	    snowFlow[ii] = wid + (snowRand.nextInt() & 3) - (snowRand.nextInt() & 3);
	raimo = wid*(hei-5);
    }

    
    private int wid, hei;
    public int[] pix = null;
    private int[] pixels = null;    
    private int[][] snow = null; // [1] for speed, [0] for location..
    private int rind = 0;
    private int[] snowFlow;
    private Random snowRand = new Random();
    private int snowStart = 0;
    private int raimo;

    public void advanceSnow() {
       	System.arraycopy((Object)pixels,0,(Object)pix,0,pix.length); // clear our shit
	
	int a=0, b=0, c=0, d=0, e=0, f=0,  i=0;
	if (snowStart < (snow.length-10)) snowStart += 10;
	else snowStart = snow.length;
	c = snowStart;
	i = 0;
	try {
	do {
	    a = snow[i][0];   
	    if (a == 0) {
		snow[i][0] = 1 + (snowRand.nextInt() % wid);
		snow[i][1] = (snowRand.nextInt() & 3) + 1;
	    }
	    else {
		// pix[a] = 0xFF000000;
		b = 0; // different speed snowflakes..
		e = snow[i][1];
		if (e == 69) b = 69;
		do {
		    if (b == 69) {			
			d = a;
			if (pixels[a + wid + 1] != 0xFFFFFFFF) 
			    a += wid +1;
			else if (pixels[a + wid - 1] != 0xFFFFFFFF)
			    a += wid-1;
			if ((d == a) || (a >= raimo)) {
			    pixels[a] = 0xFFFFFFFF; 
			    snow[i][0] = 0;
			}
			else snow[i][0] = a;
		    }
		    else {
			if ((pixels[a + wid] == 0xFFFFFFFF) || (a >= raimo)) {
			    snow[i][1] = 69; // no more normal advancing for this snow particle
			    b = 69;
			}
			else {
			    a += snowFlow[rind];
			    rind++;
			    if (rind == 511) {				
				rind = 0;
			    }
			    snow[i][0] = a;
			    b++;
			    pix[a] = 0xFFFFFFFF;
			}
		    }
		} while (b<e);	   
	    }
	    i++;
	} while (i<c);
	} catch (RuntimeException Ee) {
	    System.out.println("a " +a + " b " + b + " c " + c + " d " + d + " e " + e);
	    Ee.printStackTrace();
	}
    }
}






