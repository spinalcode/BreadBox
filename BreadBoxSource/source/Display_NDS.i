/*
 *  Display_NDS.i by Troy Davis(GPF), adapted from:
 *  Display_GP32.i by Mike Dawson - C64 graphics display, emulator window handling,
 *
 *  Frodo (C) 1994-1997,2002 Christian Bauer
 *  X11 stuff by Bernd Schmidt/Lutz Vieweg
 */
//will be moved into ctrulib at some point
#define CONFIG_3D_SLIDERSTATE (*(float*)0x1FF81080)



#define RGB565(r,g,b)  (((b)&0x1f)|(((g)&0x3f)<<5)|(((r)&0x1f)<<11))
#define RGB8_to_565(r,g,b)  (((b)>>3)&0x1f)|((((g)>>2)&0x3f)<<5)|((((r)>>3)&0x1f)<<11)

#include "SAM.h"
#include "C64.h" 
#include "VIC.h" 
#include "file.h"

#include "myfont_bin.h"
#include "myfont1_bin.h"

int hb_count=0;

void printdbg(char *s);
#include <stdlib.h>
#include <stdio.h>
#include <sys/stat.h> 
#include <sys/dir.h> 
#include <unistd.h>

#include "C64_Keyboard_bin.h"
int bmpsize = 230400; // full screen 230*240*rgb

#define MOVE_MAX 16

//#define PEN_DOWN (~IPC->buttons & (1 << 6))
#define X_KEY (~IPC->buttons & (1 << 0))
#define Y_KEY (~IPC->buttons & (1 << 1))

#define ABS(a) (((a) < 0) ? -(a) : (a))
#define	ROUND(f) ((u32) ((f) < 0.0 ? (f) - 0.5 : (f) + 0.5))

//u8 font[24576];
//u8 font1[24576];

// font stuff
int fontWidth[96]={
2,3,5,6,5,7,6,3,4,2,
3,5,3,4,3,6,5,//0
6,5,5,
6,5,5,6,5,5,3,4,6,5,
4,5,8,7,//A
5,6,6,5,5,6,
6,2,4,6,5,8,6,6,5,6,
5,5,6,6,7,11,7,6,6,3,
3,4,5,7,3,
5,//a
5,5,5,5,
5,6,5,3,4,5,2,8,5,5,
5,5,4,4,4,5,6,9,5,6,
5,4,2,4,6,4};

int font1Width[96]={
2,4,6,10,8,13,0,4,6,6,8,
10,5,6,5,6,8,7,8,8,8,8,8,
8,8,8,5,5,9,9,10,7,12,9,
8,9,9,8,8,9,9,6,6,9,8,10,
9,10,8,10,9,8,10,9,9,13,9,
10,8,6,6,6,10,9,6,7,8,8,8,
8,6,8,8,4,4,8,4,12,8,8,8,
8,6,7,7,8,8,11,8,8,6,7,
5,7,10,5};


uint8 *bufmem;

int emu_buf=0;
bool shifted = 0;
bool cmbed = 0;
bool ctrled = 0;

static int keystate[256];
//void timer_function(void); // my timer for scalling

//char filelist[100][256];  // 100 strings of up to 255 characters each
//int filesInList;


char str[500];
int menufirsttime =0;
int choosingfile = 1;
char* dotextmenu()
{
    return 0;
}
void WaitForVblank();

/*
  C64 keyboard matrix:

    Bit 7   6   5   4   3   2   1   0
  0    CUD  F5  F3  F1  F7 CLR RET DEL
  1    SHL  E   S   Z   4   A   W   3
  2     X   T   F   C   6   D   R   5
  3     V   U   H   B   8   G   Y   7
  4     N   O   K   M   0   J   I   9
  5     ,   @   :   .   -   L   P   +
  6     /   ^   =  SHR HOM  ;   *   £
  7    R/S  Q   C= SPC  2  CTL  <-  1
*/

#define MATRIX(a,b) (((a) << 3) | (b))
//255 - 2^2 (A) - 2^7 (Left SHIFT).



/*
 *  Display constructor: Draw Speedometer/LEDs in window
 */

C64Display::C64Display(C64 *the_c64) : TheC64(the_c64)
{

}


/*
 *  Display destructor
 */

C64Display::~C64Display()
{
}


/*
 *  Prefs may have changed
 */

void C64Display::NewPrefs(Prefs *prefs)
{
}


//int bounce;
void vblankhandler()
{

}


extern void InterruptHandler(void);
bool init_graphics(void)
{
//    int temp=0;
//        for(temp=0; temp<24576; temp++){
//			font[temp] = myfont_bin[temp];
//		}
//        for(temp=0; temp<24576; temp++){
//			font1[temp] = myfont1_bin[temp];
//		}

    
    gfxSetScreenFormat(GFX_TOP, GSP_BGR8_OES );
    bufmem = (uint8*)malloc(512*512);
    return  bufmem;
}

int counta,firsttime;

void WaitForVblank()
{
  //  gspWaitForVBlank();
} 
 
/*
 *  Redraw bitmap
 */


void C64Display::drawPixel(int x, int y, char r, char g, char b, u8* screen)
{
	int height=240;
    u32 v=((239-y)+x*height)*3;
	screen[v]=b;
	screen[v+1]=g;
	screen[v+2]=r;
}

void C64Display::Update(void)
{

    // get screen buffer
    u8* bufAdr=gfxGetFramebuffer(GFX_TOP, GFX_LEFT, NULL, NULL);

    int slider = 22- ((CONFIG_3D_SLIDERSTATE)*22); // scroll screen using 3d slider!
    
    
    for(int y=slider; y<240+slider; y++){
        for(int x=0; x<384; x++){
            int r = palette_red[bufmem[x+512*y]];
            int g = palette_green[bufmem[x+512*y]];
            int b = palette_blue[bufmem[x+512*y]];
            drawPixel(x+8,y-slider,r,g,b,bufAdr);
        }
	}

    
    
    
    
    
	// Update drive LEDs
    bufAdr=gfxGetFramebuffer(GFX_BOTTOM, GFX_LEFT, NULL, NULL);
	for (int i=0; i<4; i++){
		if (led_state[i]==LED_ON) {
            drawPixel(16+(80*i),60,255,0,0,bufAdr);
            drawPixel(17+(80*i),60,255,0,0,bufAdr);
		}else{
            drawPixel(16+(80*i),60,0,0,0,bufAdr);
            drawPixel(17+(80*i),60,0,0,0,bufAdr);
        }
    }
    
  // show drive emulation
    if(ThePrefs.Emul1541Proc == 1){
        for(int x=0; x<31; x++){
            drawPixel(123+x,12,255,255,255,bufAdr);
        }
    }
    
	// Flush and swap framebuffers
	gfxFlushBuffers();
	gfxSwapBuffers();

    gspWaitForVBlank();
}












// Bunch of stuff for displaying text (i hope)





int C64Display::mix(int back, int front, int alpha)
{
	if(alpha<8){
		return front;
	}else{
		return back+(((front-back)*(255-alpha))>>8);	
	}
}   

// mix two numbers together
//#define mix(back, front, alpha) back+(((front-back)*(255-alpha))>>8)

void C64Display::drawText(int x, int y, int mx, int my, char* string, int color, int fNum, bool center)
{
	int x1=0, y1=0, temp = 0;
	int line_width = 0;
	int karakta = 0;

    u8* bufAdr=gfxGetFramebuffer(GFX_BOTTOM, GFX_LEFT, NULL, NULL);

    
	for(temp=0; temp<strlen(string); temp++){
	   karakta = string[temp]-32;
	   line_width += fontWidth[karakta];
	}
	if(center)x = ((mx+x)>>1) -(line_width>>1);
	line_width=0;
	int alpha=0;
	int wide=0;

    
  	int height=240;

    for(temp=0; temp<strlen(string); temp++){
	   karakta = string[temp]-32;
		if(fNum==0)wide = fontWidth[karakta];
		if(fNum==1)wide = font1Width[karakta];
	   for(y1=0; y1<16; y1++){
			for(x1=0; x1<16; x1++){
				if(fNum==0)alpha = myfont_bin[(karakta*16*16) + x1 + 16 * y1];
				if(fNum==1)alpha = myfont_bin[(karakta*16*16) + x1 + 16 * y1];
				if(alpha>>3 <31){ // skip plotting if no alpha
                    
                    u32 v=((239-y)+x*height)*3;
                    int pr = mix(bufAdr[v],  palette_red[color],alpha);
                    int pg = mix(bufAdr[v+1],palette_green[color],alpha);
                    int pb = mix(bufAdr[v+2],palette_blue[color],alpha);
                    //pixel = mix(255,bufAdr[v],alpha);
                    
					if(x1+line_width+x >=0 && x1+line_width+x <=mx && x1+line_width+x <mx){
						//	bottomBuffer[(x1+line_width+x) + 256*(y1+y)]=pixel;
                        drawPixel(x1+line_width+x,y+y1,pr,pg,pb,bufAdr);
					}   
				}// alpha			
			}   
		}
		if(fNum==0)line_width += fontWidth[karakta];
		if(fNum==1)line_width += font1Width[karakta]-1;
	}      
}   
































void C64Display::BufSwap(void)
{
	/*
	if (swap)
		swap=0;
	else
		swap=1;
	*/
}


///*
// *  Draw one drive LED
// */
//
//void C64Display::draw_led(int num, int state)
//{
//
//}
//
//
///*
// *  LED error blink 
// */
//
//void C64Display::pulse_handler(...)
//{
//
//}


/*
 *  Draw speedometer
 */

void C64Display::Speedometer(int speed)
{
//	static int delay=0;
//	if(delay>=25) {
//		emu_speed=speed;
//		emu_minutes=(clock()/CLOCKS_PER_SEC)/60;
//		emu_seconds=(clock()/CLOCKS_PER_SEC)%60;
//		delay=0;
//	} else {
//		delay++;
//	}
}


/*
 *  Return pointer to bitmap data
 */

uint8 *C64Display::BitmapBase(void)
{
	return (uint8 *)bufmem;
    //return (uint8 *)gfxGetFramebuffer(GFX_TOP, GFX_LEFT, NULL, NULL);
	
}
	




/*
 *  Return number of bytes per row
 */

int C64Display::BitmapXMod(void)
{
	return 512;
}

void C64Display::KeyPress(int key, uint8 *key_matrix, uint8 *rev_matrix) {
	int c64_byte, c64_bit, shifted;
	if(!keystate[key]) {
		keystate[key]=1;
		c64_byte=key>>3;
		c64_bit=key&7;
		shifted=key&128;
		c64_byte&=7;
		if(shifted) {
			key_matrix[6] &= 0xef;
			rev_matrix[4] &= 0xbf;
		}
		if(ctrled) {
			key_matrix[6] &= 0xef;
			rev_matrix[4] &= 0xbf;
		}
		key_matrix[c64_byte]&=~(1<<c64_bit);
		rev_matrix[c64_bit]&=~(1<<c64_byte);
	}
}

void C64Display::KeyRelease(int key, uint8 *key_matrix, uint8 *rev_matrix) {
	int c64_byte, c64_bit, shifted;
	if(keystate[key]) {
		keystate[key]=0;
		c64_byte=key>>3;
		c64_bit=key&7;
		shifted=key&128;
		c64_byte&=7;
		if(shifted) {
			key_matrix[6] |= 0x10;
			rev_matrix[4] |= 0x40;
		}
        
		if(ctrled) {
			key_matrix[6] |= 0x10;
			rev_matrix[4] |= 0x40;
		}        
        
		key_matrix[c64_byte]|=(1<<c64_bit);
		rev_matrix[c64_bit]|=(1<<c64_byte);
	}
}

/*
 *  Poll the keyboard
 */
int c64_key=-1;
int lastc64key=-1;
void C64Display::PollKeyboard(uint8 *key_matrix, uint8 *rev_matrix, uint8 *joystick)
{
    
    // draw keyboard
    // lower screen
    int shifter=0;
    if(shifted) shifter=1;
    if(cmbed) shifter=2;
    if(ctrled) shifter=3;
    
    u8* bufAdr=gfxGetFramebuffer(GFX_BOTTOM, GFX_LEFT, NULL, NULL);
    memcpy(bufAdr, C64_Keyboard_bin +(shifter*bmpsize), bmpsize-1);
/*


 _____ _ _        _____             
|   __|_| |___   |     |___ ___ _ _ 
|   __| | | -_|  | | | | -_|   | | |
|__|  |_|_|___|  |_|_|_|___|_|_|___|
                                    
*/
    
    // DrawText(x,y,width,height,string,colour,font number,something)
    drawText(4,18,320-4,16,ThePrefs.DrivePath[0],1,0,0);

    // Joystick Port
 
    char str[5];
    sprintf(str, "%d", current_joystick+1);
    drawText(310,2,320,16,str,1,0,0);


    
if (filesGot == 1){

    
//    Show File selector
    u8* bufAdr=gfxGetFramebuffer(GFX_BOTTOM, GFX_LEFT, NULL, NULL);

    for(int y=10; y<=229; y++){
        for(int x=10; x<=309; x++){
            u32 v=((239-y)+x*240)*3;
            int pr = bufAdr[v]>>2;
            int pg = bufAdr[v+1]>>2;
            int pb = bufAdr[v+2]>>2;
            if(y==10 || x==10 || y==229 || x==309){
                drawPixel(x,y,255,255,255,bufAdr);
            }else{
                drawPixel(x,y,pr,pg,pb,bufAdr);
            }
        }
    }
    
    
    int start = currentFile - 21;
    int end = currentFile + 21;
    if(end>filesInList)end=filesInList;
    start = end - 21;
    if(start<0)start=0;
    
    
    
    for(int t=start; t<end; t++){
        int col = 15;
        if(t==currentFile){col=1;}
        int len = strlen(filelist[currentFile])-4;
        drawText(14,12+(10*t)-(start*10),320-14,16,filelist[t],col,0,0);
    }

    //char str[5];
    //sprintf(str, "%d", currentFile);
    //drawText(14,200,320-14,16,str,1,0,0);

    drawText(180,218,400,16,"(A) Load, (Y) Mount, (B) Cancel ",1,0,0);
    
}
    
    
    
    

    
    hidScanInput();
	
	uint32 keys_down = hidKeysDown();
	uint32 keys = hidKeysHeld();
	//uint32 rkeys  = hidKeysUp();

    
    // Read touch screen
	touchPosition touch;

    //Read the touch screen coordinates
	hidTouchRead(&touch);

if(filesGot==0){    
    
    c64_key = -1; // reset keys

    if(keys & KEY_TOUCH ){
    // do touch screen stuff here
    
        int PenY = (touch.py - 130)/16;
        int PenX = -1;
        if(PenY == 0){
            // line 1 of keyboard
            PenX = (touch.px - 11)/16;
            if(PenX == 0 ) c64_key = MATRIX(7,1); // <-
            if(PenX == 1 ) c64_key = MATRIX(7,0); // 1
            if(PenX == 2 ) c64_key = MATRIX(7,3); // 2
            if(PenX == 3 ) c64_key = MATRIX(1,0); // 3
            if(PenX == 4 ) c64_key = MATRIX(1,3); // 4
            if(PenX == 5 ) c64_key = MATRIX(2,0); // 5
            if(PenX == 6 ) c64_key = MATRIX(2,3); // 6
            if(PenX == 7 ) c64_key = MATRIX(3,0); // 7
            if(PenX == 8 ) c64_key = MATRIX(3,3); // 8
            if(PenX == 9 ) c64_key = MATRIX(4,0); // 9
            if(PenX == 10) c64_key = MATRIX(4,3); // 0
            if(PenX == 11) c64_key = MATRIX(5,0); // +
            if(PenX == 12) c64_key = MATRIX(5,3); // -
            if(PenX == 13) c64_key = MATRIX(6,0); // £
            if(PenX == 14) c64_key = MATRIX(6,3); // CLR/HOME
            if(PenX == 15) c64_key = MATRIX(0,0); // INST/DEL
            
            if(touch.px >= 278 && touch.px <=302) c64_key = MATRIX(0,4); // F1
        }
        
        if(PenY == 1){
            // line 2 of keyboard
            PenX = (touch.px - 20)/16;
            if(touch.px >= 11 && touch.px <=34) c64_key = MATRIX(7,2); // CTRL
            if(PenX == 1 ) c64_key = MATRIX(7,6); // Q
            if(PenX == 2 ) c64_key = MATRIX(1,1); // W
            if(PenX == 3 ) c64_key = MATRIX(1,6); // E
            if(PenX == 4 ) c64_key = MATRIX(2,1); // R
            if(PenX == 5 ) c64_key = MATRIX(2,6); // T
            if(PenX == 6 ) c64_key = MATRIX(3,1); // Y
            if(PenX == 7 ) c64_key = MATRIX(3,6); // U
            if(PenX == 8 ) c64_key = MATRIX(4,1); // I
            if(PenX == 9 ) c64_key = MATRIX(4,6); // O
            if(PenX == 10) c64_key = MATRIX(5,1); // P
            if(PenX == 11) c64_key = MATRIX(5,6); // @
            if(PenX == 12) c64_key = MATRIX(6,1); // *
            if(PenX == 13) c64_key = MATRIX(6,6); // ^
            if(touch.px >= 243 && touch.px <=266) c64_key = MATRIX(7,7); // Restore
            if(touch.px >= 278 && touch.px <=302) c64_key = MATRIX(0,5); // F3
        }
        
        if(PenY == 2){
            // line 3 of keyboard
            PenX = (touch.px - 11)/16;
            if(PenX == 0 ) c64_key = MATRIX(7,7); // Run/Stop
            if(PenX == 1 ) c64_key = MATRIX(7,6); // Shift/Lock
            if(PenX == 2 ) c64_key = MATRIX(1,2); // A
            if(PenX == 3 ) c64_key = MATRIX(1,5); // S
            if(PenX == 4 ) c64_key = MATRIX(2,2); // D
            if(PenX == 5 ) c64_key = MATRIX(2,5); // F
            if(PenX == 6 ) c64_key = MATRIX(3,2); // G
            if(PenX == 7 ) c64_key = MATRIX(3,5); // H
            if(PenX == 8 ) c64_key = MATRIX(4,2); // J
            if(PenX == 9 ) c64_key = MATRIX(4,5); // K
            if(PenX == 10) c64_key = MATRIX(5,2); // L
            if(PenX == 11) c64_key = MATRIX(5,5); // :
            if(PenX == 12) c64_key = MATRIX(6,2); // ;
            if(PenX == 13) c64_key = MATRIX(6,5); // =
            if(PenX == 14) c64_key = MATRIX(0,1); // Return
            if(PenX == 15) c64_key = MATRIX(0,1); // Return - cheat with 2x16 by 16 keys :-P
            if(touch.px >= 278 && touch.px <=302) c64_key = MATRIX(0,6); // F5
        }
        
        if(PenY == 3){
            // line 4 of keyboard
            PenX = (touch.px - 20)/16;
            if(PenX == 0 ) c64_key = MATRIX(7,5); // C=
            if(PenX == 1 ) c64_key = MATRIX(1,7); // Shift Left
            if(PenX == 2 ) c64_key = MATRIX(1,4); // Z
            if(PenX == 3 ) c64_key = MATRIX(2,7); // X
            if(PenX == 4 ) c64_key = MATRIX(2,4); // C
            if(PenX == 5 ) c64_key = MATRIX(3,7); // V
            if(PenX == 6 ) c64_key = MATRIX(3,4); // B
            if(PenX == 7 ) c64_key = MATRIX(4,7); // N
            if(PenX == 8 ) c64_key = MATRIX(4,4); // M
            if(PenX == 9 ) c64_key = MATRIX(5,7); // ,
            if(PenX == 10) c64_key = MATRIX(5,4); // .
            if(PenX == 11) c64_key = MATRIX(6,7); // /
            if(PenX == 12) c64_key = MATRIX(6,4); // Shift Right
            // use manual position for wonky keys
            if(touch.px >= 235 && touch.px <=250) c64_key = MATRIX(0,7); // CRSR Up/Down
            if(touch.px >= 251 && touch.px <=266) c64_key = MATRIX(0,2); // CRSR Left/Right
            //if(PenX == 15) c64_key = MATRIX(0,1); // 
            if(touch.px >= 278 && touch.px <=302) c64_key = MATRIX(0,3); // F7
        }
        
        if(PenY == 4){
            // line 5 of keyboard
            PenX = (touch.px - 58);
            if(PenX <= 147 ) c64_key = MATRIX(7,4); // Space
        }
    } // if touch

    
    // check newpress keys for shift lock
    if(keys_down & KEY_TOUCH ){
        if(c64_key == MATRIX(7,6) || c64_key == MATRIX(1,7) || c64_key == MATRIX(6,4)) shifted = !shifted;
      //  if(c64_key == MATRIX(7,5)) cmbed = !cmbed;
    //    if(c64_key == MATRIX(7,2)) ctrled = !ctrled;

    } // if touch

    
    
    if (lastc64key >-1 )
        KeyRelease(lastc64key, key_matrix, rev_matrix); 
    if(c64_key != -1){
        if(shifted == 1) {c64_key|=128;}
        //if(ctrled == 1) {c64_key|=10;}
        
        
	   KeyPress(c64_key, key_matrix, rev_matrix);
	   lastc64key=c64_key;
    }
    

} // filesGot == 0
    

}


/*
 *  Check if NumLock is down (for switching the joystick keyboard emulation)
 */

bool C64Display::NumLock(void)
{
    return false;
}


/*
 *  Allocate C64 colors
 */


typedef struct {
    int r;
    int g;
    int b;
} plt;

static plt palette[256];

void C64Display::InitColors(uint8 *colors)
{
  for (int i = 0; i < 16; i++) {
		palette[i].r = palette_red[i];
		palette[i].g = palette_green[i];
		palette[i].b = palette_blue[i];
  }


	// frodo internal 8 bit palette
	for(int i=0; i<256; i++) {
		colors[i] = (i) & 0x0f;
	}
}


/*
 *  Show a requester (error message)
 */

long int ShowRequester(char *a,char *b,char *)
{
//	iprintf("%s: %s\n", a, b);
	return 1;
}

