# BreadBox
Nintendo 3DS port of FrodoDS

You need a way to run homebrew applications on your 3DS. See
http://smealum.github.io/3ds/ for details.

Be sure to place BreadBox.3dsx and BreadBox.smdh in /3ds/BreadBox/
Any games you with to load should be placed in /c64/games/

Thats it. Currently when selecting a game, the emulator will try to load it
using Load"*",8,1 however, this does not always work.



Current version ??

Working
o Keyboard - Mostly, can't hold crtl/cbm keys while hitting another key.
o Floppy Drive - I only added support for one drive, shouldn't really need more
o Switch true 1541 support on/off. Some games need it
o Loads .d64, .t64, .prg from /c64/games/ folder on SD card
o Swap joystick ports
o Reset

Not Working
o Sound - This is my first 3DS project, I don't know how to do sound
o Some .d64 file appear empty to the emulator. I don't know why. True 1641 will fix this, but it's slow.
