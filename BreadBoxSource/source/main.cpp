/*
 *  main.cpp - Main program
 *
 *  Frodo (C) 1994-1997,2002-2005 Christian Bauer
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <3ds.h>

#include "sysdeps.h"

#include "main.h"
#include "C64.h"
#include "Display.h"
#include "Prefs.h"
#include "SAM.h"
//#include "text.h"

// Global variables
C64 *TheC64 = NULL;		// Global C64 object
char AppDirPath[1024];	// Path of application directory


// ROM file names
#ifndef DATADIR
#define DATADIR 
#endif

#define BASIC_ROM_FILE "sdmc:/rd/Basic ROM"
#define KERNAL_ROM_FILE "sdmc:/rd/Kernal ROM"
#define CHAR_ROM_FILE "sdmc:/rd/Char ROM"
#define DRIVE_ROM_FILE "sdmc:/rd/1541 ROM"

// Builtin ROMs
#include "Basic_ROM.h"
#include "Kernal_ROM.h"
#include "Char_ROM.h"
#include "1541_ROM.h"

/*
 *  Load C64 ROM files
 */

void Frodo::load_rom(const char *which, const char *path, uint8 *where, size_t size, const uint8 *builtin)
{
	FILE *f = fopen(path, "rb");
	if (f) {
		size_t actual = fread(where, 1, size, f);
		fclose(f);
		if (actual == size)
			return;
	}

	// Use builtin ROM
	printf("%s ROM file (%s) not readable, using builtin.\n", which, path);
	memcpy(where, builtin, size);
}

void Frodo::load_rom_files()
{
	load_rom("Basic", BASIC_ROM_FILE, TheC64->Basic, BASIC_ROM_SIZE, builtin_basic_rom);
	load_rom("Kernal", KERNAL_ROM_FILE, TheC64->Kernal, KERNAL_ROM_SIZE, builtin_kernal_rom);
	load_rom("Char", CHAR_ROM_FILE, TheC64->Char, CHAR_ROM_SIZE, builtin_char_rom);
	load_rom("1541", DRIVE_ROM_FILE, TheC64->ROM1541, DRIVE_ROM_SIZE, builtin_drive_rom);
}

#include "main_NDS.i"
 
