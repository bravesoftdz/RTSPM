
unit rtai_nam2num_short;
interface

{
  Automatically converted by H2Pas 1.0.0 from /home/chandra/LazarusPrograms/InterfaceTests/rtai_nam2num_short.tmp.h
  The following command line parameters were used:
    -p
    -D
    -w
    -o
    /home/chandra/LazarusPrograms/InterfaceTests/rtai_nam2num_short.pas
    /home/chandra/LazarusPrograms/InterfaceTests/rtai_nam2num_short.tmp.h
}

    const
      External_library='kernel32'; {Setup as you need}

    { Pointers to basic pascal types, inserted by h2pas conversion program.}
    Type
      PLongint  = ^Longint;
      PSmallInt = ^SmallInt;
      PByte     = ^Byte;
      PWord     = ^Word;
      PDWord    = ^DWord;
      PDouble   = ^Double;

{$IFDEF FPC}
{$PACKRECORDS C}
{$ENDIF}


  {*
   * @ingroup shm
   * @ingroup lxrt
   * @ingroup tasklets
   * @file
   *
   * Conversion between characters strings and unsigned long identifiers.
   * 
   * Convert a 6 characters string to un unsigned long, and vice versa, to be used
   * as an identifier for RTAI services symmetrically available in user and kernel
   * space, e.g. @ref shm "shared memory" and @ref lxrt "LXRT and LXRT-INFORMED".
   *
   * @author Paolo Mantegazza
   *
   * @note Copyright &copy; 1999-2003 Paolo Mantegazza <mantegazza@aero.polimi.it>
   *
   * This program is free software; you can redistribute it and/or
   * modify it under the terms of the GNU General Public License as
   * published by the Free Software Foundation; either version 2 of the
   * License, or (at your option) any later version.
   *
   * This program is distributed in the hope that it will be useful,
   * but WITHOUT ANY WARRANTY; without even the implied warranty of
   * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   * GNU General Public License for more details.
   *
   * You should have received a copy of the GNU General Public License
   * along with this program; if not, write to the Free Software
   * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
    }
{$ifndef _RTAI_NAM2NUM_H}
{$define _RTAI_NAM2NUM_H}  
{$include <rtai_types.h>}
{$ifdef __KERNEL__}
(* error 
#define NAM2NUM_PROTO(type, name, arglist)  static inline type name arglist
in define line 39 *)
{$else}

    const
       NAM2NUM_PROTO = RTAI_PROTO;       
{$endif}
    {*
     * Convert a 6 characters string to an unsigned long.
     *
     * Converts a 6 characters string name containing an alpha numeric
     * identifier to its corresponding unsigned long identifier.
     *
     * @param name is the name to be converted.
     *
     * Allowed characters are:
     * -  english letters (no difference between upper and lower case);
     * -  decimal digits;
     * -  underscore (_) and another character of your choice. The latter will be
     * always converted back to a $ by num2nam().
     *
     * @return the unsigned long associated with @a name.
      }
(* error 
NAM2NUM_PROTO(unsigned long, nam2num, (const char *name))
 in declarator_list *)
(* error 
NAM2NUM_PROTO(unsigned long, nam2num, (const char *name))
 in declarator_list *)
(* error 
        unsigned long retval = 0;
 in declarator_list *)

      var
         c : longint;cvar;public;
(* error 
	for (i = 0; i < 6; i++) {
 in declarator_list *)
(* error 
	for (i = 0; i < 6; i++) {
in declaration at line 68 *)
(* error 
	for (i = 0; i < 6; i++) {
in declaration at line 70 *)
(* error 
		if (c >= 'a' && c <= 'z') {
 in declarator_list *)
(* error 
			c +=  (11 - 'a');
 in declarator_list *)
(* error 
		} else if (c >= 'A' && c <= 'Z') {
in declaration at line 74 *)
(* error 
		} else if (c >= '0' && c <= '9') {
in declaration at line 76 *)
(* error 
		} else {
in declaration at line 78 *)
(* error 
		}
in declaration at line 80 *)
(* error 
	}
in declaration at line 83 *)
(* error 
		return 0xFFFFFFFF;
 in declarator_list *)
    { }
    {*
     * Convert an unsigned long to a 6 characters string.
     *
     * @param num is the unsigned long identifier whose alphanumeric name string has
     * to be evaluated;
     * 
     * @param name is a pointer to a 6 characters buffer where the identifier will
     * be returned.
      }
(* error 
NAM2NUM_PROTO(void, num2nam, (unsigned long num, char *name))
 in declarator_list *)
(* error 
NAM2NUM_PROTO(void, num2nam, (unsigned long num, char *name))
(* error 
NAM2NUM_PROTO(void, num2nam, (unsigned long num, char *name))
 in declarator_list *)
 in declarator_list *)
(* error 
        int c, i, k, q; 
 in declarator_list *)
         i : NAM2NUM_PROTO;cvar;public;
(* error 
	if (num == 0xFFFFFFFF) {
 in declarator_list *)
(* error 
        i = 5; 
in declaration at line 104 *)
(* error 
	num -= 2;
in declaration at line 105 *)
(* error 
	while (num && i >= 0) {
in declaration at line 107 *)
(* error 
		c = num - q*39;
in declaration at line 108 *)
(* error 
		num = q;
in declaration at line 109 *)
(* error 
		if ( c < 37) {
 in declarator_list *)
(* error 
			name[i--] = c > 10 ? c + 'A' - 11 : c + '0' - 1;
 in declarator_list *)
(* error 
		} else {
in declaration at line 113 *)
(* error 
		}
in declaration at line 116 *)
(* error 
	for (k = 0; i < 5; k++) {
in declaration at line 116 *)
(* error 
	for (k = 0; i < 5; k++) {
in declaration at line 117 *)
(* error 
	}
in declaration at line 119 *)
    { }
{$endif}
    { !_RTAI_NAM2NUM_H  }

implementation


end.
