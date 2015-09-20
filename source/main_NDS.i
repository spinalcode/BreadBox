/*
 * main_NDS.i
 *
 */
#include "Version.h"
//#include <nds.h>
//#include "nds/arm9/console.h" 
#include <sys/stat.h> 
#include <stdio.h>
#include <stdlib.h>
extern int init_graphics(void);
#include "costable.h"
//#include "text.h"

//this will contain the data read from SDMC
void* buffer;

// Outputs a string to the dualis console 
void printdbg(char *s) { 
                
} 
extern void InterruptHandler(void);
char Frodo::prefs_path[256] = "/rd/";
extern "C" {


/*
 *  Create application object and start it
 */
    
int main(int argc, char** argv)
{
    
	//initialize the services we're going to be using
	srvInit(); //needed for everything
	aptInit(); //needed for everything
	hidInit(NULL); //needed for input
	//gfxInit(); //makes displaying to screen easier
	fsInit(); //needed for filesystem stuff

    gfxInitDefault();
	init_graphics();
    gfxSetDoubleBuffering(GFX_TOP, true);

//	printdbg("main");
	Frodo *the_app;
	//char *args[]={ "Frodo", NULL };

	if (!init_graphics()){
		init_graphics();
		return 0;
    }   
    
    the_app = new Frodo();
    
	//the_app->ArgvReceived(argc, argv);
	the_app->ArgvReceived(1, argv);

    the_app->ReadyToRun();
	delete the_app;
    
    
	//cleanup and return
	//returning from main() returns to hbmenu when run under ninjhax

    //closing all services even more so
	gfxExit();
	hidExit();
	aptExit();
	srvExit();
	return 0;
    
    
    
    
/*    
	// Initialize services
	srvInit();      // mandatory
	aptInit();      // mandatory
	hidInit(NULL);  // input (buttons, screen)
	gfxInit();      // graphics

    
	//printdbg("main");
	Frodo *the_app;
	//char *args[]={ "Frodo", NULL };

	if (!init_graphics()){
		init_graphics();
		return 0;
    }
		
//consolePrintf("\tGRAPHICS INIT\n");		
   // printdbg("GRAPHICS INIT");

	the_app = new Frodo();
	
//consolePrintf("\tFrodo INIT\n");
		
	//the_app->ArgvReceived(argc, argv);
	//the_app->ArgvReceived(1, args);
 
//consolePrintf("\tFrodo ArgvReceived\n");
//   consolePrintf("\tFrodo ThePrefs\n");

	the_app->ReadyToRun();
	delete the_app;

//	consolePrintf("frodo terminated\n");
    // Exit services
    gfxExit();
    hidExit();
    aptExit();
    srvExit();
    return (0);
    */
}

/*
 *  Constructor: Initialize member variables
 */

Frodo::Frodo()
{
	TheC64 = NULL;
}


/*
 *  Process command line arguments
 */

void Frodo::ArgvReceived(int argc, char **argv)
{
	if (argc == 2)
		strncpy(prefs_path, argv[1], 255);
}


/*
 *  Arguments processed, run emulation
 */

void Frodo::ReadyToRun(void)
{
	// Create and start C64
	TheC64 = new C64;
	
    load_rom_files();	
    TheC64->Run();
	delete TheC64;
}


Prefs *Frodo::reload_prefs(void)
{
	static Prefs newprefs;
	newprefs.Load(prefs_path);
	return &newprefs;
}

}

bool IsDirectory(const char *path){
	struct stat st;
	return stat(path, &st) == 0 && S_ISDIR(st.st_mode);
}
