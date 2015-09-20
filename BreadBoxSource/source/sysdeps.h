/*
 *  sysdeps.h - Try to include the right system headers and get other
 *              system-specific stuff right
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

#include "sysconfig.h"
#include <stdio.h>
//
//#ifdef EMU
//#include <kos/kosstdio.h>
//#else
//#include "gba_nds_fat/gba_nds_fat.h"
//#endif
//#include <nds/jtypes.h>
//#include <stdio.h>
//
//#undef FILE
//#undef DIR
//#undef size_t
//#undef fopen
//#undef fread
//#undef fwrite
//#undef fclose
//#undef ftell
//#undef rewind
//#undef fseek
//#undef chdir
//#undef ftell
//#undef getc
//#undef tmpfile
//#undef rewind
//#undef putc
//#undef fputc
//#undef fscanf
//#undef feof
//#undef stdin
//#undef stdout
//#undef fflush
//
//#ifdef EMU
//#define FILE KOS_FILE
//#define fopen KOS_fopen
//#define fwrite KOS_fwrite
//#define fread KOS_fread
//#define fclose KOS_fclose
//#define fseek KOS_fseek
//#define fputs KOS_fputs
//#define fgets KOS_fgets
//#define fputc KOS_fputc
//#define getc KOS_getc
//#define putc KOS_putc
//#define fgetc KOS_fgetc
//#define fprintf KOS_fprintf
//#define vfprintf KOS_fprintf 
//#define ftell KOS_ftell
//#define tmpfile KOS_tmpfile
//#define rewind KOS_rewind
//#define feof KOS_feof
//#define stdin KOS_stdin
//#define stdout KOS_stdout
//#define fscanf KOS_fscanf
//#define fflush KOS_fflush
//#else
//#define FILE FAT_FILE
//#define fopen FAT_fopen
//#define fwrite FAT_fwrite
//#define fread FAT_fread
//#define fclose FAT_fclose
//#define fseek FAT_fseek
//#define fputs FAT_fputs
//#define fgets FAT_fgets
//#define fputc FAT_fputc
//#define getc FAT_getc
//#define putc FAT_putc
//#define fgetc FAT_fgetc
//#define fprintf FAT_fprintf
//#define vfprintf FAT_fprintf 
//#define ftell FAT_ftell
//#define tmpfile FAT_tmpfile
//#define rewind FAT_rewind
//#define feof FAT_feof
//#define stdin FAT_stdin
//#define stdout FAT_stdout
//#define fscanf FAT_fscanf
//#define fflush FAT_fflush
//#endif
#include <stdlib.h>
#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <signal.h>

#include <vector>
using std::vector;

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif

#ifdef HAVE_VALUES_H
#include <values.h>
#endif

#ifdef HAVE_STRINGS_H
#include <strings.h>
#endif
#ifdef HAVE_STRING_H
#include <string.h>
#endif

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif

#ifdef HAVE_UTIME_H
#include <utime.h>
#endif

#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif

#ifdef HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif

#ifdef HAVE_SYS_VFS_H
#include <sys/vfs.h>
#endif

#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif

#ifdef HAVE_SYS_MOUNT_H
#include <sys/mount.h>
#endif

#ifdef HAVE_SYS_STATFS_H
#include <sys/statfs.h>
#endif

#ifdef HAVE_SYS_STATVFS_H
#include <sys/statvfs.h>
#endif

#if TIME_WITH_SYS_TIME
# include <sys/time.h>
# include <time.h>
#else
# if HAVE_SYS_TIME_H
#  include <sys/time.h>
# else
#  include <time.h>
# endif
#endif

#if HAVE_DIRENT_H
# include <dirent.h>
#else
# define dirent direct
# if HAVE_SYS_NDIR_H
#  include <sys/ndir.h>
# endif
# if HAVE_SYS_DIR_H
#  include <sys/dir.h>
# endif
# if HAVE_NDIR_H
#  include <ndir.h>
# endif
#endif

#include <assert.h>

#if EEXIST == ENOTEMPTY
#define BROKEN_OS_PROBABLY_AIX
#endif

#ifdef __NeXT__
#define S_IRUSR S_IREAD
#define S_IWUSR S_IWRITE
#define S_IXUSR S_IEXEC
#define S_ISDIR(val) (S_IFDIR & val)
struct utimbuf
{
    time_t actime;
    time_t modtime;
};
#endif

#ifdef __DOS__
#include <pc.h>
#include <io.h>
#else
#undef O_BINARY
#define O_BINARY 0
#endif

#ifdef __mac__
#define bool Boolean
#endif

#ifdef __riscos
#define bool int
#endif

#ifdef WIN32
#include <windows.h>
#include <direct.h>
#if !defined(M_PI)
#define M_PI 3.14159265358979323846
#endif
#define S_ISDIR(m) (((m) & S_IFMT) == S_IFDIR)
#if _MSC_VER < 1100
#define bool char
#endif
#define LITTLE_ENDIAN_UNALIGNED 1
#endif

/* If char has more then 8 bits, good night. */
#ifndef __BEOS__
typedef unsigned char uint8;
typedef signed char int8;

#if SIZEOF_SHORT == 2
typedef unsigned short uint16;
typedef short int16;
#elif SIZEOF_INT == 2
typedef unsigned int uint16;
typedef int int16;
#else
#error No 2 byte type, you lose.
#endif

#ifndef __NDS__
#if SIZEOF_INT == 4
typedef unsigned int uint32;
typedef int int32;
#elif SIZEOF_LONG == 4
typedef unsigned long uint32;
typedef long int32;
#else
#error No 4 byte type, you lose.
#endif
#endif
#else
#include <support/SupportDefs.h>
#endif	// __BEOS__
