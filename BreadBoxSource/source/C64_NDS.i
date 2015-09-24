/*
 *  C64_GP32.i by Mike Dawson, adapted from:
 *  C64_x.i - Put the pieces together, X specific stuff
 *f
 *  Frodo (C) 1994-1997,2002 Christian Bauer
 *  Unix stuff by Bernd Schmidt/Lutz Vieweg
 */

#include "main.h"
extern "C" {

//#include "menu.h"
//#include "ui.h"
//#include "input.h"
//#include "gpmisc.h"
}

//#include <nds.h>
//#include "nds/arm9/console.h" 
#include <stdio.h>
#include "1541d64.h"
#include "IEC.h"

#include <stdlib.h>
#include <sys/stat.h> 
#include <sys/dir.h> 
#include <unistd.h>
#include <dirent.h>

#define MATRIX(a,b) (((a) << 3) | (b))

uint8_t* bottom_fb;
int penDown=0;
int oldPenDown=0;

int GetTicks(void) 
{ 
 //  return timers2ms(TIMER0_DATA, TIMER1_DATA);
//    return (int) TIMER0_CR;
    return 0;
} 

void Pause(uint32 ms) 
{ 
//   uint32 now; 
//   now=timers2ms(TIMER0_DATA, TIMER1_DATA); 
//   while((uint32)timers2ms(TIMER0_DATA, TIMER1_DATA)<now+ms); 
} 

char filelist[100][256];  // 100 strings of up to 255 characters each
int fileType[100];
int filesInList;
int filesGot;
int currentFile;
int oldKeys;
int currentDrive=0;





void readFileList(){
struct direct* ent;
DIR *dir=opendir("/c64/games/");
int n=0;
while ((ent=readdir(dir))!= NULL) {
    int len = strlen(ent->d_name)-4;
    // list .prg, .d64 and hite anything starting with "." (mac files)     strncmp("._", &ent->d_name, 2)
    if((!strcasecmp(".d64",&ent->d_name[len]) || !strcasecmp(".prg",&ent->d_name[len]) || !strcasecmp(".t64",&ent->d_name[len])) && strncmp("._", &ent->d_name[0], 2)){
        strcpy(filelist[n++], ent->d_name);
        if(!strcasecmp(".d64",&ent->d_name[len])){fileType[n-1]=1;}
        if(!strcasecmp(".t64",&ent->d_name[len])){fileType[n-1]=1;}
        if(!strcasecmp(".prg",&ent->d_name[len])){fileType[n-1]=2;}

    }
    filesInList = n;
}
closedir(dir);
filesGot=0;
if(n!=0)filesGot=1;
}











extern void print(char *s);

//static int time_start=0;
int total_frames=0;

int current_joystick=1;

#ifndef HAVE_USLEEP

int usleep(unsigned long int microSeconds)
{
	Pause(microSeconds); 
	return 0;
}
#endif


/*
 *  Constructor, system-dependent things
 */

void C64::c64_ctor1(void)
{
   // StartTimers();
    
}

void C64::c64_ctor2(void)
{
}


/*
 *  Destructor, system-dependent things
 */

void C64::c64_dtor(void)
{
}


/*
 *  Start main emulation thread
 */

void C64::Run(void)
{
    //uint8_t* bottom_fb = gfxGetFramebuffer(GFX_BOTTOM, GFX_LEFT, NULL, NULL);

	// Reset chips
    TheCPU->Reset();
	TheSID->Reset();
	TheCIA1->Reset();
	TheCIA2->Reset();
	TheCPU1541->Reset();

	// Patch kernal IEC routines
	orig_kernal_1d84 = Kernal[0x1d84]; 
	orig_kernal_1d85 = Kernal[0x1d85];
	PatchKernal(ThePrefs.FastReset, ThePrefs.Emul1541Proc);
	quit_thyself = false;
	thread_func();
}

//static int key_prev = 0;
//static int key_curr = 0;
//
//#define key_poll() { key_prev=key_curr; key_curr = REG_KEYINPUT; }
//#define key_transit(key) ((key_curr^key_prev) & key)
//#define key_held(key) (~(key_curr|key_prev) & key)
//#define key_hit(key) ((~key_curr&key_prev) & key)
//#define key_released(key) ((key_curr&~key_prev) & key)

void poll_input(){


    
}

char kbd_feedbuf[255];
int kbd_feedbuf_pos;

void kbd_buf_feed(char *s) {
	strcpy(kbd_feedbuf, s);
	kbd_feedbuf_pos=0;
}

void kbd_buf_update(C64 *TheC64) {
	if((kbd_feedbuf[kbd_feedbuf_pos]!=0)
			&& TheC64->RAM[198]==0) {
		TheC64->RAM[631]=kbd_feedbuf[kbd_feedbuf_pos];
		TheC64->RAM[198]=1;

		kbd_feedbuf_pos++;
	}
}

void load_prg(C64 *TheC64, uint8 *prg, int prg_size) {
	uint8 start_hi, start_lo;
	uint16 start;
	int i;

	start_lo=*prg++;
	start_hi=*prg++;
	start=(start_hi<<8)+start_lo;

	for(i=0; i<(prg_size-2); i++) {
		TheC64->RAM[start+i]=prg[i];
	}
} 

/*
 *  Vertical blank: Poll keyboard and joysticks, update window
 */
 
int old_time;
void C64::VBlank(bool draw_frame)
{
    gspWaitForVBlank();
	//double elapsed_time, speed_index;
    //char outputtext[30];
//    sprintf(outputtext, "VBlank %d     ", draw_frame);
//    debugText(outputtext);

	poll_input();
	kbd_buf_update(this);

	TheDisplay->PollKeyboard(TheCIA1->KeyMatrix, TheCIA1->RevMatrix, &joykey);

	TheCIA1->Joystick1 = poll_joystick(0);
	TheCIA1->Joystick2 = poll_joystick(1);


	if(draw_frame) { 
		TheDisplay->Update();
//		if(keyboard_enabled||options_enabled||status_enabled)
//			draw_ui(this);
		TheDisplay->BufSwap();

/*
        //calculate time between vblanks
		int time=GetTicks()-time_start;
		elapsed_time=(double)time*(1000000/CLOCKS_PER_SEC);
		speed_index=20000/(elapsed_time+1)*ThePrefs.SkipFrames*100;
		time_start=GetTicks();

		if((speed_index>100) && ThePrefs.LimitSpeed) {
			usleep((unsigned long)(ThePrefs.SkipFrames*20000-elapsed_time));
			speed_index=100;
		}

		TheDisplay->Speedometer((int)speed_index);

		// calculate fps
		total_frames++;
//		long emu_fps=(total_frames/(((GetTicks()+1)*CLOCKS_PER_SEC)+1))*100;
		long emu_fps=(GetTicks()/CLOCKS_PER_SEC)/10;
		if(old_time != emu_fps){
			char a[20];
			sprintf(a,"fps %d - Skip %d\n",total_frames,ThePrefs.SkipFrames);
			//if(total_frames<=20 && ThePrefs.SkipFrames<5)ThePrefs.SkipFrames++;
			//if(total_frames>20 && ThePrefs.SkipFrames>1)ThePrefs.SkipFrames--;
			
			total_frames=0;
			iprintf(a);
			old_time = emu_fps;
		
		}
*/		
	}

}


/*
 *  Open/close joystick drivers given old and new state of
 *  joystick preferences
 */ 
extern char* dotextmenu();
void C64::open_close_joysticks(int oldjoy1, int oldjoy2, int newjoy1, int newjoy2)
{
}
 

/*
 *  Poll joystick port, return CIA mask 
 */
int space=0;
int switchstick=0;
uint8 C64::poll_joystick(int port)
{
	uint8 j = 0xff;
	
//	if (space ==1){
//    	TheDisplay->KeyRelease(MATRIX(7,4), TheCIA1->KeyMatrix, TheCIA1->RevMatrix); 
//	 space=0;
//    }
    //key_poll();

	hidScanInput();
	
	u32 keys_down = hidKeysDown();
	u32 keys = hidKeysHeld();
	u32 rkeys  = hidKeysUp();

    
    

    
    
    //scanKeys();
	//u32 keys= keysHeld();
    //u32 rkeys = keysUp();

if(filesGot==1){
	if(oldKeys != keys){
        if( keys & KEY_UP   && currentFile >0 ) { currentFile--; }
        if( keys & KEY_DOWN && currentFile <filesInList-1 ) { currentFile++; }
        if( keys & KEY_A ){ // load file
        // if .d64, mount disk
        if(fileType[currentFile] == 1){
            // reload prefs and add filename to drive [0]
            Prefs *prefs = new Prefs(ThePrefs);
            char theDrivePath[256];
            strcpy(theDrivePath, "/c64/games/");
            strcat(theDrivePath, filelist[currentFile]);
            strcpy(prefs->DrivePath[currentDrive], theDrivePath);
            this->NewPrefs(prefs);
            ThePrefs = *prefs;
            delete prefs;
            this->PatchKernal(ThePrefs.FastReset, ThePrefs.Emul1541Proc);
            this->Reset();
            char clr[2]; clr[0]=147; clr[1]=0;
            // throw some instructions on the screen!
			char poop[150];
			sprintf(poop,"%s WHILE HOLDING -R- TAP UP/DOWN TO MOVE   THE CURSOR TO THE FILE YOU WANT TO      LOAD THEN PRESS -A-",clr);
            int len = strlen(poop);
            poop[len] = 19;
            int t=0;
            for(t=1; t<5; t++){
                poop[len+t] = 17;
            }
            poop[len+t] = 0;
            

            kbd_buf_feed("");
            char output[200];
			sprintf(output,"LOAD\"$\",8\r%sLIST\r",poop);
			kbd_buf_feed(output);
        }

        // if.prg, load directly
        if(fileType[currentFile] == 2){
            char theDrivePath[256];
            strcpy(theDrivePath, "/c64/games/");
            strcat(theDrivePath, filelist[currentFile]);

            struct stat st;
            stat(theDrivePath, &st);
            int size = st.st_size;
            
            uint8* buffer= (uint8 *)malloc(size);
            FILE *filepointer = fopen(theDrivePath, "rb");
            fread(buffer,size,1,filepointer);
            fclose(filepointer);
            
            load_prg(this, buffer, size);
            free(buffer);
            kbd_feedbuf[0]=0;
            kbd_buf_feed("\rRUN\r");
        }
            
            filesGot = 0;
        }

        if( keys & KEY_B ){
            filesGot = 0;
        }
    
        if( keys & KEY_Y ){ // mount file
        // if .d64, mount disk
        if(fileType[currentFile] == 1){
            // reload prefs and add filename to drive [0]
            Prefs *prefs = new Prefs(ThePrefs);
            char theDrivePath[256];
            strcpy(theDrivePath, "/c64/games/");
            strcat(theDrivePath, filelist[currentFile]);
            strcpy(prefs->DrivePath[0], theDrivePath);
            this->NewPrefs(prefs);
            ThePrefs = *prefs;
            delete prefs;
            kbd_feedbuf[0]=0;
        }

            filesGot = 0;
        }
    
    
    
    }
}
    
    
    
if(filesGot==0){    
    
    
    
    
	if(port!=current_joystick) return j;

	//if(options_enabled||keyboard_enabled) return j; 

	if( keys & KEY_LEFT  ) j&=0xfb;
	if( keys & KEY_RIGHT ) j&=0xf7;
	if( keys & KEY_UP    ) j&=0xfe;
	if( keys & KEY_DOWN  ) j&=0xfd;
	if( keys & KEY_A     ) j&=0xef; 
//	if( keys & KEY_Y     ) j&=0xfe; // make Y 'UP' for jumping in some games :)

 /*
    if( keys & KEY_B     ) {
		//uint8 *key_matrix;
		//uint8 *rev_matrix;
		TheDisplay->KeyPress(MATRIX(7,4), TheCIA1->KeyMatrix, TheCIA1->RevMatrix);
		space=1;
    }    
*/        

/* D-Pad = cursor keys when 'R' held */    
   
	if(keys & KEY_R ){

		if(keys & KEY_UP){
            if(!(oldKeys & KEY_UP)){
                char poop[2];
                poop[0]=145;
                poop[1]=0;
                kbd_buf_feed(poop);
            }
		}
	
		if(keys & KEY_DOWN){
            if(!(oldKeys & KEY_DOWN)){
                char poop[2];
                poop[0]=17; poop[1]=0; kbd_buf_feed(poop);
            }
        }
        // load file on line
		if(keys & KEY_A){
            if(!(oldKeys & KEY_A)){
			char poop[50];
			char muuv[20];
			muuv[0]= 29;		muuv[1]= 29;		muuv[2]= 29;		muuv[3]= 29;
			muuv[4]= 29;		muuv[5]= 29;		muuv[6]= 29;		muuv[7]= 29;
			muuv[8]= 29;		muuv[9]= 29;		muuv[10]=29;		muuv[11]=29;
			muuv[12]=29;		muuv[13]=29;		muuv[14]=29;		muuv[15]=29;
			muuv[16]=29;		muuv[17]=29;		muuv[18]=29;		muuv[19]=0;
			char clr[2];
			clr[0]=147;
			clr[1]=0;
			sprintf(poop,"LOAD%s,8,1     \r%s\rRUN\r",muuv,clr);
			kbd_buf_feed(poop);
            }
        }
    
    
    }

        
        
        
    // Read touch screen
	touchPosition touch;
    //Read the touch screen coordinates
	hidTouchRead(&touch);
    
    oldPenDown = penDown;
    penDown=0;
    if(keys & KEY_TOUCH){
        penDown = 1;
        int PenY = touch.py;
        int PenX = touch.px;
        
        if(oldPenDown == 0){
            
            // quit button
            if(PenX >=0 && PenX <=31){
                if(PenY >=0 && PenY <=15){
                    quit_thyself=1;
                }
            }
            // reset button
            if(PenX >=33 && PenX <=63){
                if(PenY >=0 && PenY <=15){
                    this->PatchKernal(ThePrefs.FastReset, ThePrefs.Emul1541Proc);
                    strcpy(kbd_feedbuf, "");
                    kbd_feedbuf_pos=0;
                    this->Reset();
                }
            }
            // Floppy drive
            if(PenX >=0 && PenX <=79){
                if(PenY >=30 && PenY <=66){
                    readFileList();
                    currentDrive=0;
                    }
                }
            }
        
            // Swap Joystick
            if(PenX >=65 && PenX <=119){
                if(PenY >=0 && PenY <=15){
                    if(switchstick==0){
                       if (current_joystick == 0) current_joystick=1;
                        else if (current_joystick == 1) current_joystick=0;
                        switchstick=1;
                    }else if(switchstick==1)switchstick=0;                    
                    
                }
            }
        
            // Flip true drive emulation
            if(PenX >=121 && PenX <=155){
                if(PenY >=0 && PenY <=15){
                    //Prefs *prefs = new Prefs(ThePrefs);
                    //prefs->Emul1541Proc = 1-prefs->Emul1541Proc;
                    //this->NewPrefs(prefs);
                    //ThePrefs = *prefs;
                    //delete prefs;
                    if(ThePrefs.Emul1541Proc){
                        ThePrefs.Emul1541Proc = false;
                    }else{
                        ThePrefs.Emul1541Proc = true;
                    }
                    this->PatchKernal(ThePrefs.FastReset, ThePrefs.Emul1541Proc);
                    strcpy(kbd_feedbuf, "");
                    kbd_feedbuf_pos=0;
                    this->Reset();
                }
            }
        
        
        
        }// newpress
    
    
    
} // dont have file list
    
    
    oldKeys = keys;
    
	return j;
}


/*
 * The emulation's main loop
 */

void C64::thread_func(void)
{
//consolePrintf("\tthread_func\n");
	int linecnt = 0;

#ifdef FRODO_SC
	while (!quit_thyself) {

		// The order of calls is important here
		if (TheVIC->EmulateCycle())
			TheSID->EmulateLine();
		TheCIA1->CheckIRQs();
		TheCIA2->CheckIRQs();
		TheCIA1->EmulateCycle();
		TheCIA2->EmulateCycle();
		TheCPU->EmulateCycle();

		if (ThePrefs.Emul1541Proc) {
			TheCPU1541->CountVIATimers(1);
			if (!TheCPU1541->Idle)
				TheCPU1541->EmulateCycle();
		}
		CycleCounter++;
#else
	while (!quit_thyself) {
	
		if(have_a_break)
        {
			poll_input();
//			consolePrintf("&");
			TheDisplay->BufSwap();
			continue; 
		}

		// The order of calls is important here
		int cycles = TheVIC->EmulateLine();
		TheSID->EmulateLine();
#if !PRECISE_CIA_CYCLES
		TheCIA1->EmulateLine(ThePrefs.CIACycles);
		TheCIA2->EmulateLine(ThePrefs.CIACycles);
#endif 

		if (ThePrefs.Emul1541Proc) {
			int cycles_1541 = ThePrefs.FloppyCycles;
			TheCPU1541->CountVIATimers(cycles_1541);

			if (!TheCPU1541->Idle) {
				// 1541 processor active, alternately execute
				//  6502 and 6510 instructions until both have
				//  used up their cycles
				while (cycles >= 0 || cycles_1541 >= 0)
					if (cycles > cycles_1541)
						cycles -= TheCPU->EmulateLine(1);
					else
						cycles_1541 -= TheCPU1541->EmulateLine(1);
			} else
				TheCPU->EmulateLine(cycles);
		} else
			// 1541 processor disabled, only emulate 6510
			TheCPU->EmulateLine(cycles);
#endif
//consolePrintf("\tthread_func\n");
		linecnt++;
	}
}
void C64::Pause() {
	have_a_break=true;
	TheSID->PauseSound();
}

void C64::Resume() {
	have_a_break=false;
	TheSID->ResumeSound();
}

