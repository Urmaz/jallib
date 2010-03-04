/* ------------------------------------------------------------------------ *
 * Title: Dev2Jal.cmd - Create JalV2 device include files for flash PICs    *
 *                                                                          *
 * Author: Rob Hamerling, Copyright (c) 2008..2010, all rights reserved.    *
 *                                                                          *
 * Adapted-by:                                                              *
 *                                                                          *
 * Compiler: N/A                                                            *
 *                                                                          *
 * This file is part of jallib  http://jallib.googlecode.com                *
 * Released under the BSD license                                           *
 *              http://www.opensource.org/licenses/bsd-license.php          *
 *                                                                          *
 * Description:                                                             *
 *   Rexx script to create device include files for JALV2, and              *
 *   the file chipdef_jallib.jal, included by each of these.                *
 *   Apart from declaration of all registers, register-subfields, ports     *
 *   and pins of the chip the device files contain shadowing procedures     *
 *   to prevent the 'read-modify-write' problems of midrange PICs and       *
 *   for the 18F force the use of LATx for output in stead of PORTx.        *
 *   In addition some device dependent procedures are provided              *
 *   for common operations, like enable-digital-io().                       *
 *   Also a number of pin-aliases are declared to provide device            *
 *   independent logical names for some pins, registers and bitfields.      *
 *                                                                          *
 * Sources:  MPLAB .dev and .lkr files                                      *
 *                                                                          *
 * Notes:                                                                   *
 *   - This script is developed with 'classic' Rexx as delivered with       *
 *     eComStation (OS/2) and is executed on a specific system.             *
 *     With only a few changes it can be executed on a different system,    *
 *     or even a different platform (Linux, Windows) with the combination   *
 *     of "Regina Rexx" and "RegUtil", ref:                                 *
 *        - http://regina-rexx.sourceforge.net/                             *
 *     See the embedded comments below for instructions for possibly        *
 *     required changes.                                                    *
 *   - A summary of changes of this script is maintained in 'changes.txt'   *
 *     (not published, available on request).                               *
 *                                                                          *
 * ------------------------------------------------------------------------ */
   ScriptVersion   = '0.0.94'
   ScriptAuthor    = 'Rob Hamerling'
   CompilerVersion = '2.4n'
/* ------------------------------------------------------------------------ */

/* 'msglevel' controls the amount of messages being generated               */
/*   1 - all: info, progress, warnings and errors                           */
/*   2 - only warnings and errors                                           */
/*   3 - only errors (always reported!)                                     */

msglevel = 1

/* MPLAB and a local copy of the Jallib SVN tree should be installed.       */
/* For any system or platform the following base information must be        */
/* specified as a minimum.                                                  */

MPLABbase  = 'k:/mplab843/'             /* base directory of MPLAB          */
JALLIBbase = 'k:/jallib/'               /* base directory of JALLIB (local) */

/* When using 'standard' installations no other changes are needed,         */
/* but you may check below which specific sources of information are used,  */
/* and adapt this script for any deviations in your system setup.           */

/* The following libraries are used to collect information from             */
/* MPLAB .dev and .lkr files:                                               */

devdir = MPLABbase'mplab ide/device/'          /* dir with MPLAB .dev files */
lkrdir = MPLABbase'mpasm suite/lkr/'           /* dir with MPLAB .lkr files */

/* Some information is collected from files in JALLIB tools directory       */

PicSpecFile = JALLIBbase'tools/devicespecific.json'   /* pic specific data  */
PinMapFile  = JALLIBbase'tools/pinmap_pinsuffix.json'  /* pin aliases       */
FuseDefFile = JALLIBbase'tools/fusedefmap.cmd'        /* fuse_def mapping   */

call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs                             /* load Rexx system functions */

say ' Dev2Jal version' ScriptVersion '  -  ' ScriptAuthor
if msglevel > 2 then
   say 'Only reporting errors!'

/* The destination of the generated device files depends on the first       */
/* mandatory commandline argument, which must be 'PROD' or 'TEST'           */
/*  - with 'PROD' the files go to directory "<JALLIBbase>include/device"    */
/*  - with 'TEST' the files go to directory "./test>"                       */
/* Note: The destination is not emptied, existing device files will be      */
/*       overwritten, other files remain.                                   */

parse upper arg destination selection .         /* commandline arguments    */
select
   when destination = 'PROD' then               /* production run           */
      dstdir = JALLIBbase'include/device/'      /* local Jallib             */
   when destination = 'TEST' then do            /* test run                 */
      dstdir = './test/'                        /* subdir for testing       */
      rx = SysMkDir(strip(dstdir,'T','/'))      /* create destination dir   */
      if rx \= 0 & rx \= 5 then do              /* not created, not existing*/
         say 'Error' rx 'while creating destination directory' dstdir
         return rx                              /* unrecoverable: terminate */
      end
   end
   otherwise
      say 'Error: Required argument missing: "prod" or "test"'
      say '       Optional second argument: PIC selection (wildcard), e.g.: 18F45*'
      return 1
end

/* The optional second commandline argument designates for which PICs device */
/* files must be generated. This argument is only accepted in a 'TEST' run.  */
/* The selection may contain wildcards like '18LF*', default is '*' (all).   */

select
   when selection = '' then                     /* no selection spec'd      */
      wildcard = 'pic1*.dev'                    /* default (8 bit PICs)     */
   when destination = 'TEST' then               /* TEST run                 */
      wildcard = 'pic'selection'.dev'           /* accept user selection    */
   otherwise                                    /* PROD run with selection  */
      say 'Selection not allowed for production run!'
      return 1                                  /* unrecoverable: terminate */
end

/* Now the generation of device files is actually started!!                 */

call time 'R'                                   /* reset 'elapsed' timer    */

call SysFileTree devdir||wildcard, dir, 'FO'    /* get list of filespecs    */
if dir.0 = 0 then do
   say 'Error: No .dev files matching <'wildcard'> found in' devdir
   return 0                                     /* nothing to do            */
end

signal on syntax name catch_syntax              /* catch syntax errors */
signal on error  name catch_error               /* catch execution errors */

PicSpec. = '?'                                  /* PIC specific data */
call file_read_picspec                          /* read device specific data */

PinMap.  = '?'                                  /* pin mapping data */
call file_read_pinmap                           /* read pin alias names */

Fuse_Def. = '?'                                 /* Fuse_Def name mapping */
call file_read_fusedef                          /* read fuse_def table */

chipdef = dstdir'chipdef_jallib.jal'            /* common include file */
if stream(chipdef, 'c', 'query exists') \= '' then     /* old chipdef file present */
   call SysFileDelete chipdef                   /* delete it */
if stream(chipdef, 'c', 'open write') \= 'READY:' then do  /* new chipdef file */
   Say 'Error: Could not create common include file' chipdef
   return 1                                     /* unrecoverable: terminate */
end
call list_chipdef_header                        /* create new chipdef file */

ListCount = 0                                   /* # created device files */
LkrMissCount = 0                                /* # missing '.lkr' files */

do i=1 to dir.0                                 /* all relevant .dev files */
                                                /* init for each new PIC */
   Dev.        = ''                             /* .dev file contents    */
   Lkr.        = ''                             /* .lkr file contents    */
   Ram.        = ''                             /* sfr usage and mirroring */
   Name.       = '-'                            /* register and subfield names */
   CfgAddr.    = ''                             /* )          */
   IDAddr.     = ''                             /* ) decimal! */

   DevFile = tolower(translate(dir.i,'/','\'))  /* lower case + forward slashes */
   parse value filespec('Name', DevFile) with 'pic' PicName '.dev'
   if PicName = '' then do
      Say '  Error: Could not derive PIC name from filespec: "'DevFile'"'
      leave                                     /* setup error: terminate */
   end

   if substr(PicName,3,1) \= 'f'  &,            /* not flash PIC */
      substr(PicName,3,2) \= 'lf' &,            /* not low power flash PIC */
      substr(PicName,3,2) \= 'hv' then do       /* not high voltage flash PIC */
      iterate                                   /* skip */
   end

   if PicName = '16f54'   |,                    /* not supported by JalV2 compiler */
      PicName = '16f57'   |,
      PicName = '16f59'   |,
      PicName = '16hv540' then do               /* OTP (not flash) PIC */
      if msglevel <= 1 then
         say PicName 'Not supported by JalV2'
      iterate
   end

   PicNameCaps = toupper(PicName)
   if PicSpec.PicNameCaps.DataSheet = '?' then do
      if msglevel <= 2 then
         say PicName 'Warning: not listed in' PicSpecFile', no device file generated'
      iterate                                   /* skip */
   end
   else if PicSpec.PicNameCaps.DataSheet = '-' then do
      if msglevel <= 2 then
         say PicName 'Warning: no datasheet found in' PicSpecFile', no device file generated'
      iterate                                   /* skip */
   end

   if msglevel <= 1 then
      say PicName                               /* progress signal */

   if file_read_dev() = 0 then                  /* read .dev file */
      iterate                                   /* skip */

   if file_read_lkr() = 0 then                  /* read .lkr file */
      iterate                                   /* skip */

   jalfile = dstdir||PicName'.jal'              /* .jal file */
   if stream(jalfile, 'c', 'query exists') \= '' then   /* previous */
      call SysFileDelete jalfile                /* delete */
   if stream(jalfile, 'c', 'open write') \= 'READY:' then do
      Say '  Error: Could not create device file' jalfile
      leave                                     /* setup error: terminate */
   end

   call load_config_info                        /* collect cfg info + core */
   if  core = '12' then                         /* baseline */
      rx = dev2Jal12()
   else if core = '14' then                     /* midrange */
      rx = dev2Jal14()
   else if core = '14H' then                    /* extended midrange */
      rx = dev2Jal14H()
   else if core = '16' then                     /* 18Fs */
      rx = dev2Jal16()
   else do                                      /* other or undetermined core */
      say '  Error: Unsupported core:' Core     /* report detected Core */
      say '         Internal script error, terminating ....'
      leave                                     /* script error: terminate */
   end

   call stream jalfile, 'c', 'close'            /* done */

   if rx = 0 then                               /* device file created */
      ListCount = ListCount + 1;                /* count successful results */

end

call lineout chipdef, '--'                      /* last line */
call stream  chipdef, 'c', 'close'              /* done */

if msglevel <= 1 then
   say 'Generated' listcount 'device files in' format(time('E'),,2) 'seconds'
if LkrMissCount > 0 & msglevel <= 1 then
   say LkrMissCount 'device files could not be created because of missing .lkr files'

signal off error
signal off syntax                               /* restore to default */

call SysDropFuncs                               /* release Rexxutil */

return 0


/* ==================================================================== */
/*                      1 2 - B I T S   C O R E                         */
/* ==================================================================== */
dev2jal12: procedure expose ScriptVersion ScriptAuthor CompilerVersion,
                            Core PicName JalFile ChipDef DevFile LkrFile,
                            msglevel,
                            Dev. Lkr. Ram. Name. CfgAddr. IDAddr.,
                            PicSpec. PinMap. Fuse_Def.

MAXRAM     = 128                                /* range 0..0x7F */
BANKSIZE   = 32                                 /* 0x0020 */
PAGESIZE   = 512                                /* 0x0200 */
DataStart  = '0x400'                            /* default */
NumBanks   = 1                                  /* default */
StackDepth = 2                                  /* default */

call load_stackdepth                            /* check stack depth */
call load_sfr1x                                 /* load sfr + mirror info */

call list_head                                  /* header */
call list_fuses_words1x                         /* config memory */
call list_sfr1x                                 /* special function registers */
call list_nmmr12                                /* non memory mapped regs */
call list_analog_functions                      /* register info */
call list_fuses_bits                            /* fuses details */
return 0


/* ==================================================================== */
/*                      1 4 - B I T S   C O R E                         */
/* ==================================================================== */
dev2jal14: procedure expose ScriptVersion ScriptAuthor CompilerVersion,
                            Core PicName JalFile ChipDef DevFile LkrFile,
                            msglevel,
                            Dev. Lkr. Ram. Name. CfgAddr. IDAddr.,
                            PicSpec. PinMap. Fuse_Def.

MAXRAM     = 512                                /* range 0..0x1FF */
BANKSIZE   = 128                                /* 0x0080 */
PAGESIZE   = 2048                               /* 0x0800 */
DataStart  = '0x2100'                           /* default */
NumBanks   = 1                                  /* default */
StackDepth = 8                                  /* default */

call load_stackdepth                            /* check stack depth */
call load_sfr1x                                 /* load sfr + mirror info */

call list_head                                  /* header */
call list_fuses_words1x                         /* config memory */
call list_sfr1x                                 /* register info */
                                                /* No NMMRs with core_14! */
call list_analog_functions                      /* register info */
call list_fuses_bits                            /* fuses details */
return 0


/* ==================================================================== */
/*             E X T E N D E D   1 4 - B I T S   C O R E                */
/* ==================================================================== */
dev2jal14h: procedure expose ScriptVersion ScriptAuthor CompilerVersion,
                             Core PicName JalFile ChipDef DevFile LkrFile,
                             msglevel,
                             Dev. Lkr. Ram. Name. CfgAddr. IDAddr.,
                             PicSpec. PinMap. Fuse_Def.

MAXRAM     = 4096                               /* range 0..0xFFF */
BANKSIZE   = 128                                /* 0x0080 */
PAGESIZE   = 2048                               /* 0x0800 */
DataStart  = '0xF000'                           /* default */
NumBanks   = 32                                 /* default */
StackDepth = 16                                 /* default */

call load_stackdepth                            /* check stack depth */
call load_sfr1x                                 /* load sfr + mirror info */

call list_head                                  /* header */
call list_fuses_words1x                         /* config memory */
call list_sfr14h                                /* register info */
                                                /* No NMMRs with core_14H */
call list_analog_functions                      /* register info */
call list_fuses_bits                            /* fuses details */
return 0


/* ==================================================================== */
/*                      1 6 - B I T S   C O R E                         */
/* ==================================================================== */
dev2jal16: procedure expose ScriptVersion ScriptAuthor CompilerVersion,
                            Core PicName JalFile ChipDef DevFile LkrFile,
                            msglevel,
                            Dev. Lkr. Ram. Name. CfgAddr. IDAddr.,
                            PicSpec. PinMap. Fuse_Def.

MAXRAM     = 4096                               /* range 0..0x0xFFF */
BANKSIZE   = 256                                /* 0x0100 */
DataStart  = '0xF00000'                         /* default */
NumBanks   = 1                                  /* default */
AccessBankSplitOffset = 128                     /* default */
StackDepth = 31                                 /* default */

call load_sfr16                                 /* load sfr */

call list_head                                  /* header */
call list_fuses_bytes16                         /* config memory */
call list_sfr16                                 /* register info */
call list_nmmr16                                /* selected non memory mapped regs */
call list_analog_functions                      /* register info */
call list_fuses_bits                            /* fuses details */
return 0


/* ==================================================================== */
/*          End of the core-specific main procedures                    */
/* ==================================================================== */


/* ------------------------------------------- */
/* Read .dev file contents into stem variable  */
/* input:                                      */
/*                                             */
/* Collect only relevant lines!                */
/* ------------------------------------------- */
file_read_dev: procedure expose DevFile Dev. msglevel
Dev.0 = 0                                       /* no records read yet */
if stream(DevFile, 'c', 'open read') \= 'READY:' then do
   Say '  Error: could not open .dev file' DevFile
   return 0                                     /* zero records */
end
i = 1                                           /* first record */
do while lines(DevFile) > 0                     /* read whole file */
   parse upper value linein(DevFile) with Dev.i /* store line in upper case */
   if length(Dev.i) \< 3 then do                /* not an 'empty' record */
      if left(word(Dev.i,1),1) \= '#' then      /* not comment */
         i = i + 1                              /* keep this record */
   end
end
call stream DevFile, 'c', 'close'               /* done */
Dev.0 = i - 1                                   /* # of stored records */
return Dev.0


/* -------------------------------------------------------- */
/* Read .lkr file contents into stem variable               */
/* input:  - PicName                                        */
/* output: - LkrFile pathspec                               */
/*                                                          */
/* - Collect only relevant lines!                           */
/* - for 'LF' PIC may try 'L' or 'F' variants of .lkr file  */
/* -------------------------------------------------------- */
file_read_lkr: procedure expose PicName LkrDir LkrFile LkrMissCount Lkr. msglevel
LkrFile = LkrDir||PicName'_g.lkr'               /* try with full PIC name */
if stream(LkrFile, 'c', 'query exists') = '' then do
   lfx = pos('lf', PicName)                     /* check for 'lf' in PicName */
   if lfx > 0 then do                           /* low voltage PIC */
      LkrFile = LkrDir||delstr(PicName,lfx+1,1)'_g.lkr'   /* keep 'l', strip 'f' */
      if stream(LkrFile,'c','query exists') = '' then do
         LkrFile = LkrDir||delstr(PicName,lfx,1)'_g.lkr'  /* strip 'l', keep 'f' */
         if stream(LkrFile,'c','query exists') = '' then
            nop                                 /* all LF alternatives failed */
      end
   end
end
Lkr.0 = 0                                       /* no records read */
if stream(LkrFile, 'c', 'open read') \= 'READY:' then do
   Say '  Error: Could not find any suitable .lkr file for' PicName
   LkrMissCount = LkrMissCount + 1
   return 0                                     /* zero records */
end
i = 1                                           /* first record */
do while lines(LkrFile) > 0                     /* whole file */
   parse upper value linein(LkrFile) with Lkr.i /* store line in upper case */
   if length(Lkr.i) \> 2           |,           /* empty */
      left(word(Lkr.i,1),2) = '//' |,           /* .lkr comment */
      word(Lkr.i,1) = '#FI'        |,           /* end if */
      word(Lkr.i,1) = '#DEFINE'    |,           /* const definition */
      word(Lkr.i,1) = 'LIBPATH' then            /* Library path */
      iterate                                   /* skip these lines */
   if word(Lkr.i,1) = '#IFDEF' then do          /* conditional part */
      if left(word(Lkr.i,2),6) = '_DEBUG'  |,   /* debugging */
         left(word(Lkr.i,2),6) = '_EXTEN' then do /* extended mode */
         do while lines(LkrFile) > 0            /* skip lines */
            parse upper value linein(LkrFile) with ln  /* read line */
            if word(ln,1) = '#ELSE' |,          /* other than debugging */
               word(ln,1) = '#FI' then do       /* end conditional part */
               leave                            /* resume normal */
            end
         end
      end
   end
   else do                                      /* not skipped */
      i = i + 1                                 /* keep this record */
   end
end
call stream LkrFile, 'c', 'close'               /* done */
Lkr.0 = i - 1                                   /* # non-comment records */
return Lkr.0                                    /* number of records */


/* --------------------------------------------------- */
/* Read file with Device Specific data                 */
/* Interpret contents: fill compound variable PicSpec. */
/* --------------------------------------------------- */
file_read_picspec: procedure expose PicSpecFile PicSpec. msglevel
if stream(PicSpecFile, 'c', 'open read') \= 'READY:' then do
   Say '  Error: could not open file with device specific data' PicSpecFile
   exit 1                                       /* zero records */
end
if msglevel <= 1 then
   call charout , 'Reading device specific data items from' PicSpecFile '... '
do until x = '{' | x = 0                        /* search begin of pinmap */
   x = json_newchar(PicSpecFile)
end
do until x = '}' | x = 0                        /* end of pinmap */
   do until x = '}' | x = 0                     /* end of pic */
      PicName = json_newstring(PicSpecFile)     /* new PIC */
      do until x = '{' | x = 0                  /* search begin PIC specs */
         x = json_newchar(PicSpecFile)
      end
      do until x = '}' | x = 0                  /* this PICs specs */
         ItemName = json_newstring(PicSpecFile)
         do until x = '[' | x = 0               /* search item */
            x = json_newchar(PicSpecFile)
         end
         do until x = ']' | x = 0               /* end of item */
            value = json_newstring(PicSpecFile)
            PicSpec.PicName.ItemName = value
            x = json_newchar(PicSpecFile)
         end
         x = json_newchar(PicSpecFile)
      end
      x = json_newchar(PicSpecFile)
   end
   x = json_newchar(PicSpecFile)
end
call stream PicSpecFile, 'c', 'close'
if msglevel <= 1 then
  say 'done!'
return


/* --------------------------------------------------- */
/* Read file with pin alias information (JSON format)  */
/* Fill compound variable PinMap.                      */
/* --------------------------------------------------- */
file_read_pinmap: procedure expose PinMapFile PinMap. msglevel
if stream(PinMapFile, 'c', 'open read') \= 'READY:' then do
   Say '  Error: could not open file with Pin Alias information' PinMapFile
   exit 1                                       /* zero records */
end
if msglevel <= 1 then
   call charout , 'Reading pin alias names from' PinMapFile '... '
do until x = '{' | x = 0                        /* search begin of pinmap */
   x = json_newchar(PinMapFile)
end
do until x = '}' | x = 0                        /* end of pinmap */
   do until x = '}' | x = 0                     /* end of pic */
      PicName = json_newstring(PinMapFile)      /* new PIC */
      PinMap.PicName = PicName                  /* PIC listed in JSON file */
      do until x = '{' | x = 0                  /* search begin PIC specs */
        x = json_newchar(PinMapFile)
      end
      ANcount = 0                               /* zero ANxx count this PIC */
      do until x = '}' | x = 0                  /* this PICs specs */
         pinname = json_newstring(PinMapFile)
         i = 0                                  /* no aliases (yet) */
         do until x = '[' | x = 0               /* search pin aliases */
           x = json_newchar(PinMapFile)
         end
         do until x = ']' | x = 0               /* end of aliases this pin */
            aliasname = json_newstring(PinMapFile)
            if aliasname = '' then do           /* no (more) aliases */
               x = ']'                          /* must have been last char read! */
               iterate
            end
            if right(aliasname,1) = '-' then    /* handle trailing '-' character */
               aliasname = strip(aliasname,'T','-')'_NEG'
            else if right(aliasname,1) = '+' then    /* handle trailing '+' character */
               aliasname = strip(aliasname,'T','+')'_POS'
            i = i + 1
            PinMap.PicName.pinname.i = aliasname
            if left(aliasname,2) = 'AN' & datatype(substr(aliasname,3)) = 'NUM' then
               ANcount = ANcount + 1
            x = json_newchar(PinMapFile)
         end
         PinMap.PicName.pinname.0 = i
         x = json_newchar(PinMapFile)
      end
      ANCountName = 'ANCOUNT'
      PinMap.PicName.ANCountName = ANcount
      x = json_newchar(PinMapFile)
   end
   x = json_newchar(PinMapFile)
end
call stream PinMapFile, 'c', 'close'
if msglevel <= 1 then
   say 'done!'
return


/* -------------------------------- */
json_newstring: procedure
jsonfile = arg(1)
do until x = '"' | x = ']' | x = '}' | x = 0    /* start new string or end of everything */
   x = json_newchar(jsonfile)
end
if x \= '"' then                                /* no string found */
   return ''
str = ''
x = json_newchar(jsonfile)                      /* first char */
do while x \= '"'
   str = str||x
   x = json_newchar(jsonfile)
end
return str

/* -------------------------------- */
json_newchar: procedure
jsonfile = arg(1)
do while chars(jsonfile) > 0
   x = charin(jsonfile)
   if x <= ' ' then                             /* white space */
      iterate
   return x
end
return 0                                        /* dummy */


/* ---------------------------------------------------- */
/* Read file with oscillator name mapping               */
/* Interpret contents: fill compound variable Fuse_Def. */
/* ---------------------------------------------------- */
file_read_fusedef: procedure expose FuseDefFile Fuse_Def. msglevel
if stream(FuseDefFile, 'c', 'open read') \= 'READY:' then do
   Say '  Error: could not open file with fuse_def mappings' FuseDefFile
   exit 1                                       /* zero records */
end
if msglevel <= 1 then
  call charout , 'Reading Fusedef Names from' FuseDefFile '... '
do while lines(FuseDefFile) > 0                 /* read whole file */
   interpret linein(FuseDefFile)                /* read and interpret line */
end
call stream FuseDefFile, 'c', 'close'           /* done */
if msglevel <= 1 then
   say 'done!'
return


/* ---------------------------------------------- */
/* procedure to collect Config (fuses) info       */
/* input:   - nothing                             */
/* output:  - core (0, 12, 14, 14H, 16)           */
/* ---------------------------------------------- */
load_config_info: procedure expose Dev. CfgAddr. Core
CfgAddr.0 = 0                                   /* empty */
Core = 0                                        /* reset: undetermined */
do i = 1 to Dev.0
   parse var Dev.i 'CFGMEM' '(' 'REGION' '=' '0X' Val1 '-' '0X' Val2 ')' .
   if Val1 \= '' then do
      Val1 = X2D(Val1)                          /* take decimal value */
      Val2 = X2D(Val2)
      if Val1 = X2D('FFF') then                 /* 12-bits core */
         Core = '12'
      else if Val1 = X2D('2007') then           /* 14-bits core */
         Core = '14'
      else if Val1 = X2D('8007') then           /* extended 14-bits core */
         Core = '14H'
      else                                      /* presumably 16-bits core */
         Core = '16'
      CfgAddr.0 = Val2 - Val1 + 1               /* number of config bytes */
      do j = 1 to CfgAddr.0                     /* all config bytes */
         CfgAddr.j = Val1 + j - 1               /* address */
      end
      leave                                     /* 1st occurence only */
   end
end
return


/* ---------------------------------------------- */
/* procedure to obtain hardware stack depth       */
/* input:  - nothing                              */
/* ---------------------------------------------- */
load_stackdepth: procedure expose Dev. StackDepth
do i = 1 to Dev.0
   parse var Dev.i 'HWSTACKDEPTH' '=' Val1 .
   if Val1 \= '' then do
      StackDepth = strip(val1)
      leave                                     /* 1st occurence only */
   end
end
return


/* ---------------------------------------------------------- */
/* procedure to build special function register array         */
/* with mirror info and unused registers                      */
/* input:  - nothing                                          */
/* 12-bit and 14-bit core                                     */
/* ---------------------------------------------------------- */
load_sfr1x: procedure expose Dev. Name. Ram. core MAXRAM NumBanks msglevel
do i = 0 to MAXRAM - 1                          /* whole range */
   Ram.i = 0                                    /* mark whole RAM as unused */
end
do i = 1 to Dev.0
   ln = Dev.i                                   /* copy line */
   parse var ln 'NUMBANKS' '=' Value .          /* memory banks */
   if Value \= '' then do
      NumBanks = strip(Value)
      if NumBanks > 4 then do                   /* max 4 banks for core 12 and 14 */
         if core \= '14H' then do               /* (32 banks for core 14h) */
            if msglevel <= 2 then
               say '  Warning: Number of RAM banks > 4'
            NumBanks = 4                        /* compiler limit */
         end
      end
      iterate
   end
   parse var ln 'MIRRORREGS' '(' '0X' lo.1  '-' '0X' hi.1,
                                 '0X' lo.2  '-' '0X' hi.2,
                                 '0X' lo.3  '-' '0X' hi.3,
                                 '0X' lo.4  '-' '0X' hi.4,
                                 '0X' lo.5  '-' '0X' hi.5,
                                 '0X' lo.6  '-' '0X' hi.6,
                                 '0X' lo.7  '-' '0X' hi.7,
                                 '0X' lo.8  '-' '0X' hi.8,
                                 '0X' lo.9  '-' '0X' hi.9,
                                 '0X' lo.10 '-' '0X' hi.10,
                                 '0X' lo.11 '-' '0X' hi.11,
                                 '0X' lo.12 '-' '0X' hi.12,
                                 '0X' lo.13 '-' '0X' hi.13,
                                 '0X' lo.14 '-' '0X' hi.14,
                                 '0X' lo.15 '-' '0X' hi.15,
                                 '0X' lo.16 '-' '0X' hi.16,
                                 '0X' lo.17 '-' '0X' hi.17,
                                 '0X' lo.18 '-' '0X' hi.18,
                                 '0X' lo.19 '-' '0X' hi.19,
                                 '0X' lo.20 '-' '0X' hi.20,
                                 '0X' lo.21 '-' '0X' hi.21,
                                 '0X' lo.22 '-' '0X' hi.22,
                                 '0X' lo.23 '-' '0X' hi.23,
                                 '0X' lo.24 '-' '0X' hi.24,
                                 '0X' lo.25 '-' '0X' hi.25,
                                 '0X' lo.26 '-' '0X' hi.26,
                                 '0X' lo.27 '-' '0X' hi.27,
                                 '0X' lo.28 '-' '0X' hi.28,
                                 '0X' lo.29 '-' '0X' hi.29,
                                 '0X' lo.30 '-' '0X' hi.30,
                                 '0X' lo.31 '-' '0X' hi.31,
                                 '0X' lo.32 '-' '0X' hi.32 ')' .
   if lo.1 \= '' & hi.1 \= '' then do
      a = X2D(strip(lo.1))
      b = X2D(strip(strip(hi.1),'B',')'))
      do j = 2 to 32                            /* all possible banks */
         if lo.j \= '' & hi.j \= '' then do     /* specified bank */
            p = X2D(strip(lo.j))                /* mirror low bound */
            do k = a to b                       /* whole range */
               Ram.k = k                        /* mark 'used' */
               Ram.p = k                        /* mark as mirror */
               p = p + 1                        /* next mirrored reg. */
            end
         end
      end
      iterate
   end
   parse var ln 'UNUSEDREGS' '(' '0X' lo '-' '0X' hi ')' .
   if lo \= '' & hi \= '' then do
      a = X2D(strip(lo))
      b = X2D(strip(hi))
      do k = a to b                             /* whole range */
         Ram.k = -1                             /* mark 'unused' */
      end
      iterate
   end
end
return 0


/* ---------------------------------------------------------- */
/* procedure to build special function register array         */
/* with unused registers                                      */
/*                                                            */
/* input:  - nothing                                          */
/*                                                            */
/* 16-bit core                                                */
/* ---------------------------------------------------------- */
load_sfr16: procedure expose Dev. Ram. BankSize NumBanks AccessBankSplitOffset msglevel
do i = 1 to Dev.0
   parse var Dev.i 'NUMBANKS' '=' Value .       /* memory banks */
   if Value \= '' then do
      NumBanks = strip(Value)                   /* feedback */
      iterate
   end
   parse var Dev.i 'ACCESSBANKSPLITOFFSET' '=' '0X' Value .  /* split */
   if Value \= '' then do
      AccessBankSplitOffset = X2D(strip(Value)) /* feedback */
      iterate
   end
   parse var Dev.i 'UNUSEDREGS' '(' '0X' lo '-' '0X' hi ')' .
   if lo \= '' & hi \= '' then do
      a = X2D(strip(lo))
      b = X2D(strip(hi))
      do k = a to b                             /* whole range */
         Ram.k = -1                             /* mark 'unused' */
      end
   end
end
return 0


/* --------------------------------------------------- */
/* procedure to list code memory size from .dev file   */
/* input:  - nothing                                   */
/* --------------------------------------------------- */
list_code_size: procedure expose Dev. jalfile core CfgAddr. msglevel
CodeSize = 0
do i = 1 to Dev.0
   if word(Dev.i,1) \= 'PGMMEM' then            /* exclude 'EXTPGMMEM' ! */
      iterate
   parse var Dev.i 'PGMMEM' '(' 'REGION' '=' Value ')' .
   if Value \= '' then do
      parse var Value '0X' val1 '-' '0X' val2 .
      CodeSize = X2D(strip(Val2)) - X2D(strip(val1)) + 1
   end
end
if core == '16' then do                         /* 18F */
   if CfgAddr.1 < CodeSize then do              /* code overlaps cfg words */
      if msglevel <= 2 then
         say '  Warning: Code memory overlaps Configuration words'
      CodeSize = CfgAddr.1                      /* correct Code size */
   end
   call lineout jalfile, 'pragma  code    'CodeSize'                    -- (bytes)'
end
else
   call lineout jalfile, 'pragma  code    'CodeSize'                    -- (words)'
return


/* ---------------------------------------------------------- */
/* procedure to list EEPROM data memory size from .dev file   */
/* input:  - nothing                                          */
/* ---------------------------------------------------------- */
list_data_size: procedure expose Dev. jalfile DataStart msglevel
do i = 1 to Dev.0
   if word(Dev.i,1) \= 'EEDATA'    &,
      word(Dev.i,1) \= 'FLASHDATA' then
      iterate
   parse var Dev.i val0 'REGION' '=' Value ')' .
   if Value \= '' then do
      parse var Value '0X' val1 '-' '0X' val2 .
      if X2D(val1) > 0 then do                  /* start address */
         if DataStart \= '0x'val1  & msglevel <= 1 then
            say '   Info: DataStart changed from' DataStart 'to 0x'val1
         DataStart = '0x'val1
      end
      DataSize = X2D(val2) - X2D(val1) + 1
      call lineout jalfile, 'pragma  eeprom  'DataStart','DataSize
      leave                                     /* 1 occurence expected */
   end
end
return


/* ---------------------------------------------------------- */
/* procedure to list ID memory size from .dev file            */
/* input:  - nothing                                          */
/* ---------------------------------------------------------- */
list_ID_size: procedure expose Dev. jalfile msglevel
do i = 1 to Dev.0
   if word(Dev.i,1) \= 'USERID' then
      iterate
   parse var Dev.i val0 'REGION' '=' Value ')' .
   if Value \= '' then do
      parse var Value '0X' val1 '-' '0X' val2 .
      IDSize = X2D(val2) - X2D(val1) + 1
      call lineout jalfile, 'pragma  ID      0x'val1','IDSize
      leave                                     /* 1 occurence expected */
   end
end
return


/* ---------------------------------------------- */
/* procedure to list Device ID from .dev file     */
/* input:  - nothing                              */
/* remarks: some corrections of errors in MPLAB   */
/* ---------------------------------------------- */
list_devid: procedure expose Dev. jalfile chipdef Core PicName msglevel
DevID = '0000'                                  /* default (not found) */
do i = 1 to Dev.0
   parse var Dev.i 'DEVID' val0 'IDMASK' '=' Val1 'ID' '=' '0X' val2 ')' .
   if val2 \= '' then do
      RevMask = right(strip(Val1),4,'0')        /* 4 hex chars */
      DevID = right(strip(Val2),4,'0')          /* 4 hex chars */
      DevID = C2X(bitand(X2C(DevID),X2C(RevMask)))  /* reset revision bits */
      leave                                     /* 1 occurence expected */
   end
end
if DevId == '0000' then do                      /* DevID not found */
   if PicName = '16f627' then                   /* missing in MPlab */
      Devid = '07A0'
   else if PicName = '16f628' then
      Devid = '07C0'
   else if PicName = '16f84A' then
      Devid = '0560'
end
parse upper var PicName PicNameUpper
call lineout jalfile, 'const word DEVICE_ID   = 0x'DevID
if DevId \== '0000' then                        /* DevID not missing */
   call lineout chipdef, left('const       PIC_'PicNameUpper,29) '= 0x_'left(Core,2)'_'DevID
else do                                         /* DevID unknown */
   DevID = right(PicNameUpper,3)                /* rightmost 3 chars of name */
   if datatype(Devid,'X') = 0 then do           /* not all hex digits */
      DevID = right(right(PicNameUpper,2),3,'F')  /* 'F' + rightmost 2 chars */
   end
   call lineout chipdef, left('const       PIC_'PicNameUpper,29) '= 0x_'Core'_F'DevID
end
return


/* ---------------------------------------------- */
/* procedure to list Vpp info from .dev file      */
/* input:  - nothing                              */
/* ---------------------------------------------- */
list_Vpp: procedure expose Dev. jalfile
do i = 1 to Dev.0
   parse var Dev.i 'VPP' '(' 'RANGE' '=' Val1 'DFLT' '=' Val2 ')' .
   if Val1 \= '' then do
      call lineout jalfile, '-- Vpp',
                            'Range:' strip(Val1) 'Default:' strip(Val2)
      leave                                     /* 1st occurence only */
   end
end
return


/* ---------------------------------------------- */
/* procedure to list Vdd info from .dev file      */
/* input:  - nothing                              */
/* ---------------------------------------------- */
list_Vdd: procedure expose Dev. jalfile
do i = 1 to Dev.0
   parse var Dev.i 'VDD' '(' 'RANGE' '=' Val1 'DFLTRANGE' '=' Val2 'NOMINAL' '=' Val3 ')' .
   if Val1 \= '' then do
      call lineout jalfile, '-- Vdd',
                            'Range:' strip(Val1) 'Nominal:' strip(Val3)
      leave                                     /* 1 occurence expected */
   end
end
return


/* --------------------------------------------------------------- */
/* procedure to list shared RAM (gpr) ranges from .dev file        */
/* input:  - nothing                                               */
/* returns - string with range of shared RAM                       */
/*           in MaxSharedRam highest shared RAM address  (decimal) */
/* Note: Some PICs are handled 'exceptionally'                     */
/* --------------------------------------------------------------- */
list_shared_data_range: procedure expose Lkr. jalfile Core MaxSharedRAM PicName msglevel
select                                          /* exceptions first */
   when Left(PicName,3) = '10f' |,
      PicName = '12f508'   then do
      DataRange = '0x1E-0x1F'                   /* 1 bank: some pseudo shared RAM */
      MaxSharedRAM = X2D(1F)
   end
   when PicName = '12f629'  |,
        PicName = '12f675'  |,
        PicName = '16f630'  |,
        PicName = '16f676' then do
      DataRange = '0x5E-0x5F'                   /* for _pic_accum and _pic_isr_w */
      MaxSharedRAM = X2D(5F)
   end
   when PicName = '16f73'   |,
        PicName = '16f74'  then do
      DataRange = '0x7E-0x7F'
      MaxSharedRAM = X2D(7F)
   end
   when PicName = '16f83'  then do
      DataRange = '0x2E-0x2F'
      MaxSharedRAM = X2D(2F)
   end
   when PicName = '16f84'   |,
        PicName = '16f84a' then do
      DataRange = '0x4E-0x4F'
      MaxSharedRAM = X2D(4F)
   end
   when PicName = '16f818' then do
      DataRange = '0x7E-0x7F'
      MaxSharedRAM = X2D(7F)
   end
   when PicName = '16f819'  |,
        PicName = '16f870'  |,
        PicName = '16f871'  |,
        PicName = '16f872' then do
      DataRange = '0x70-0x7F'
      MaxSharedRAM = X2D(7F)
   end
   when PicName = '16f873'  |,
        PicName = '16f873a' |,
        PicName = '16f874'  |,
        PicName = '16f874a' then do
      DataRange = '0x7E-0x7F'
      MaxSharedRAM = X2D(7F)
   end
   otherwise                                    /* scan .lkr file */
      DataRange = ''                            /* set defaults */
      MaxSharedRAM = 0
      do i = 1 to Lkr.0
         ln = Lkr.i
         if pos('PROTECTED', ln) > 0 then       /* skip protected mem */
            iterate
         if Core = '12' | Core = '14'  | core = '14H' then
            parse var ln 'SHAREBANK' Val0 'START' '=' '0X' val1 'END' '=' '0X' val2 .
         else
            parse var Lkr.i 'ACCESSBANK' Val0 'START' '=' '0X' val1 'END' '=' '0X' val2 .
         if val1 \= '' then do
            if DataRange \= '' then             /* not first range */
               DataRange = DataRange','         /* insert separator */
            val1 = strip(val1)
            val2 = strip(val2)
            if X2D(val2) > MaxSharedRAM then    /* new high limit */
               MaxSharedRAM = X2D(val2)         /* upper bound */
            DataRange = DataRange'0x'val1'-0x'val2  /* concatenate range */
         end
      end
end
if DataRange \= '' then do                      /* some shared RAM present */
  call lineout jalfile, 'pragma  shared  'DataRange
end
return DataRange                                /* range */


/* ------------------------------------------------------------- */
/* procedure to list unshared RAM (GPR) ranges from .dev file    */
/* input:  - nothing                                             */
/* returns in MaxUnsharedRam highest unshared RAM addr. in bank0 */
/* Note: Some PICs are handled 'exceptionally'                   */
/* ------------------------------------------------------------- */
list_unshared_data_range: procedure expose Lkr. jalfile MaxUnsharedRAM PicName Core msglevel
select                                          /* exceptions first */
   when PicName = '10f200'  |,
        PicName = '10f204'  |,
        PicName = '10f220' then do
      DataRange = '0x10-0x1D'                   /* 1 bank: 'unshared' part */
      MaxUnSharedRAM = X2D(1D)
   end
   when PicName = '10f202'  |,
        PicName = '10f206' then do
      DataRange = '0x08-0x1D'
      MaxUnSharedRAM = X2D(1D)
   end
   when PicName = '10f222' then do
      DataRange = '0x09-0x1D'
      MaxUnSharedRAM = X2D(1D)
   end
   when PicName = '12f508' then do
      DataRange = '0x07-0x1D'
      MaxUnSharedRAM = X2D(1D)
   end
   when PicName = '12f629'  |,                  /* have only shared RAM */
        PicName = '12f675'  |,
        PicName = '16f630'  |,
        PicName = '16f676' then do
      DataRange = '0x20-0x5D'                   /* 1 bank: 'unshared' part */
      MaxUnsharedRAM = X2D(5D)
   end
   when PicName = '16f73'   |,
        PicName = '16f74'  then do
      DataRange = '0x20-0x7D,0xA0-0xFD'
      MaxUnSharedRAM = X2D(7D)
   end
   when PicName = '16f83'  then do
      DataRange = '0x0C-0x2D'
      MaxUnSharedRAM = X2D(2D)
   end
   when PicName = '16f84'   |,
        PicName = '16f84a' then do
      DataRange = '0x0C-0x4D'
      MaxUnSharedRAM = X2D(4D)
   end
   when PicName = '16f818' then do
      DataRange = '0x20-0x7D,0xA0-0xBF'
      MaxUnsharedRAM = X2D(7D)
   end
   when PicName = '16f819' then do
      DataRange = '0x20-0x6F,0xA0-0xEF,0x120-0x16F'
      MaxUnsharedRAM = X2D(6F)
   end
   when PicName = '16f870'  |,
        PicName = '16f871'  |,
        PicName = '16f872'  then do
      DataRange = '0x20-0x6F,0xA0-0xBF'
      MaxUnsharedRAM = X2D(6F)
   end
   when PicName = '16f873'  |,
        PicName = '16f873a' |,
        PicName = '16f874'  |,
        PicName = '16f874a' then do
      DataRange = '0x20-0x7D,0xA0-0xFD'
      MaxUnsharedRAM = X2D(7D)
   end
   otherwise                                    /* scan .lkr file */
      DataRange = ''                            /* default  */
      MaxUnsharedRAM = 0
      do i = 1 to Lkr.0
         ln = Lkr.i
         if pos('PROTECTED', ln) > 0 then       /* skip protected mem */
            iterate
         parse var ln 'DATABANK' Val0 'START' '=' '0X' val1 'END' '=' '0X' val2 .
         if val1 \= '' & val2 \= '' then do     /* both found */
            if Length(DataRange) > 50 then do   /* long string */
               call lineout jalfile, 'pragma  data    'DataRange   /* 'flush' */
               DataRange = ''                   /* reset */
            end
            if DataRange \= '' then             /* not first range */
               DataRange = DataRange','         /* insert separator */
            val1 = strip(val1)
            val2 = strip(val2)
            if X2D(val2) > MaxUnsharedRAM then  /* new high limit */
               MaxUnSharedRAM = X2D(Val2)       /* bank 0 */
            DataRange = DataRange'0x'val1'-0x'val2  /* concatenate range */
         end
      end
end
if DataRange \= '' then
   call lineout jalfile, 'pragma  data    'DataRange
return


/* ---------------------------------------------- */
/* procedure to list Config (fuses) settings      */
/* input:  - nothing                              */
/* 12-bit and 14-bit core                         */
/* uses device specific table                     */
/* ---------------------------------------------- */
list_fuses_words1x: procedure expose jalfile CfgAddr. PicSpec. PicName msglevel
PicNameCaps = toupper(PicName)
FusesDefault = PicSpec.PicNameCaps.FusesDefault
if FusesDefault = '?' then do
   say '  Error:' PicName 'FusesDefault not listed in devicespecific.cmd!'
   exit 1
end
call lineout jalfile, 'const word  _FUSES_CT             =' CfgAddr.0
if CfgAddr.0 = 1 then do
   call lineout jalfile, 'const word  _FUSE_BASE            = 0x'D2X(CfgAddr.1)
   call charout jalfile, 'const word  _FUSES                = 0b'
   do i = 1 to 4
      call charout jalfile, '_'X2B(substr(FusesDefault,i,1))
   end
   call lineout jalfile, ''
end
else do
   call charout jalfile, 'const word  _FUSE_BASE[_FUSES_CT] = { '
   do  j = 1 to CfgAddr.0
      call charout jalfile, '0x'D2X(CfgAddr.j)
      if j < CfgAddr.0 then
         call charout jalfile, ','
   end
   call lineout jalfile, ' }'
   call charout jalfile, 'const word  _FUSES[_FUSES_CT]     = { '
   do  j = 1 to CfgAddr.0
      call charout jalfile, '0b'
      do i = 1 to 4
         call charout jalfile, '_'X2B(substr(FusesDefault,i+4*(j-1),1,'0'))
      end
      if j < CfgAddr.0 then                     /* not last word */
         call charout jalfile, ', '
      else
         call charout jalfile, ' }'
      call lineout jalfile, '        -- CONFIG'||j
      if j < CfgAddr.0 then
         call charout jalfile, left('',38,' ')
   end
end
call lineout jalfile, '--'
return


/* ---------------------------------------------- */
/* procedure to list Config (fuses) settings      */
/* input:  - nothing                              */
/* 16-bit core                                    */
/* uses device specific table                     */
/* ---------------------------------------------- */
list_fuses_bytes16: procedure expose jalfile CfgAddr. PicSpec. PicName msglevel
PicNameCaps = toupper(PicName)
FusesDefault = PicSpec.PicNameCaps.FusesDefault     /* get default */
if FusesDefault = '?' then do
  say '  Error:' PicName 'FusesDefault not listed in devicespecific.cmd!'
  exit 1
end
call lineout jalfile, 'const word  _FUSES_CT             =' CfgAddr.0
call charout jalfile, 'const dword _FUSE_BASE[_FUSES_CT] = { '
do  j = 1 to CfgAddr.0
   call charout jalfile, '0x'D2X(CfgAddr.j,6)
   if j < CfgAddr.0 then do
      call lineout jalfile, ','
      call charout jalfile, left('',38,' ')
   end
end
call lineout jalfile, ' }'
call charout jalfile, 'const byte  _FUSES[_FUSES_CT]     = { '
do j = 1 to CfgAddr.0
   call charout jalfile, '0b'
   do i = 1 to 2
      call charout jalfile, '_'X2B(substr(FusesDefault,i+2*(j-1),1,'0'))
   end
   if j < CfgAddr.0 then
      call charout jalfile, ', '
   else
      call charout jalfile, ' }'
   call lineout jalfile, '        -- CONFIG'||(j+1)%2||substr('HL',1+(j//2),1)
   if j < CfgAddr.0 then
      call charout jalfile, left('',38,' ')
end
call lineout jalfile, '--'
return


/* -------------------------------------------------- */
/* procedure to list special function registers       */
/* input:  - nothing                                  */
/* Note: name is stored but not checked on duplicates */
/* 12-bit and 14-bit core                             */
/* -------------------------------------------------- */
list_sfr1x: procedure expose Dev. Ram. Name. PinMap. PicName,
                             jalfile BANKSIZE NumBanks msglevel
do i = 1 to Dev.0
   if word(Dev.i,1) \= 'SFR' then               /* skip non SFRs */
      iterate
   parse var Dev.i  val0 '(KEY=' val1 ' ADDR' '=' '0X' val2 'SIZE' '=' val3 .
   if val1 \= '' then do
      reg = strip(val1)                         /* register name */
      if reg = 'SSPCON1' |,                     /* to be normalized */
         reg = 'SSPCON0' then
         reg = 'SSPCON'                         /* normalized name */
      Name.reg = reg                            /* add to collection of names */
      addr = X2D(strip(val2))                   /* decimal */
      Ram.addr = addr                           /* mark address in use */
      addr = sfr_mirror(addr)                   /* add mirror addresses */
      size = strip(val3)                        /* field size */
      if size = 1 then
         field = 'byte  '
      else if size = 2 then
         field = 'word  '
      else
         field = 'dword '
      call lineout jalfile, '-- ------------------------------------------------'
      call lineout jalfile, 'var volatile' field left(reg,25) 'at' addr
      select
         when left(reg,4) = 'PORT' then do      /* port */
            call list_port1x_shadow reg
         end
         when reg = 'GPIO' then do              /* port */
            call lineout jalfile, 'var volatile byte  ' left('PORTA',25) 'at' reg
            call list_port1x_shadow 'PORTA'
         end
         when reg = 'GP' then do                /* port */
            if msglevel <= 2 then
            say '  Warning: register GP to be renamed to GPIO'
         end
         when reg = 'TRISIO' then do            /* low pincount PIC */
            call lineout jalfile, 'var volatile byte  ' left('TRISA',25) 'at' reg
            call lineout jalfile, 'var volatile byte  ' left('PORTA_direction',25) 'at' reg
            call list_tris_nibbles 'TRISA'      /* nibble direction */
         end
         when left(reg,4) = 'TRIS' then do      /* TRISx */
            call lineout jalfile, 'var volatile byte  ',
                                  left('PORT'substr(reg,5)'_direction',25) 'at' reg
            call list_tris_nibbles reg          /* nibble direction */
         end
         otherwise                              /* others */
            nop                                 /* can be ignored */
      end

      call list_sfr_subfields1x i, reg          /* bit fields */

      if reg = 'FSR'    |,
         reg = 'INDF'   |,
         reg = 'PCL'    |,
         reg = 'PCLATH' |,
         reg = 'STATUS' then do
         if reg = 'INDF' then
            reg = 'IND'                         /* compiler wants 'ind' */
         reg = tolower(reg)                     /* to lower case */
         call lineout jalfile, 'var volatile byte  ' left('_'reg,25) 'at' addr,
                                  '     -- (compiler)'
         if reg = 'status' then                 /* status register */
            call list_status1x i                /* extra for compiler */
      end
   end
end
return 0


/* ------------------------------------------------- */
/* Formatting of special function register subfields */
/* input:  - index in .dev                           */
/*         - register name                           */
/* Generates names for pins or bit fields            */
/* 12-bit and 14-bit core                            */
/* ------------------------------------------------- */
list_sfr_subfields1x: procedure expose Dev. Name. PinMap. PicName jalfile msglevel
i = arg(1) + 1                                          /* first after reg */
reg = arg(2)                                            /* register (name) */
PicUpper = toupper(PicName)                             /* for alias handling */
do k = 0 to 8 while (word(Dev.i,1) \= 'SFR'  &,         /* max # of records */
                     word(Dev.i,1) \= 'NMMR')           /* other type */
   parse var Dev.i 'BIT' val0 'NAMES' '=' val1 'WIDTH' '=' val2 ')' .
   if val1 \= ''   &,                                   /* found */
      pos('SCL', val0) = 0  then do                     /* not 'scl' */
      names = strip(strip(val1), 'B', "'")              /* strip blanks */
      sizes = strip(strip(val2), 'B', "'")              /*   and quotes */
      n. = '-'                                          /* reset */
      parse  var names n.1 n.2 n.3 n.4 n.5 n.6 n.7 n.8 .
      parse  var sizes s.1 s.2 s.3 s.4 s.5 s.6 s.7 s.8 .
      offset = 7                                        /* MSbit first */
      do j = 1 to 8 while offset >= 0                   /* max 8 bits */
         if n.j = '-' then do                           /* bit not used */
           nop
         end
         else if s.j = 1 then do                        /* single bit */
            if pos('/', n.j) \= 0 then do               /* twin name */
               parse var n.j val1'/'val2 .
               if val1 \= '' then do                    /* present */
                  field = reg'_'val1                    /* new name */
                  if duplicate_name(field,reg) = 0 then do   /* unique */
                     call lineout jalfile, 'var volatile bit   ',
                                  left(field,25) 'at' reg ':' offset
                  end
               end
               if val2 \= '' then do
                  field = reg'_'val2
                  if duplicate_name(field,reg) = 0 then do   /* unique */
                    call lineout jalfile, 'var volatile bit   ',
                                 left(field,25) 'at' reg ':' offset
                  end
               end
            end
            else do                                     /* not twin name */
               field = reg'_'n.j
               select                                   /* interceptions */
                  when left(reg,5) = 'ANSEL'  &,
                       left(n.j,3) = 'ANS' then do
                     select
                        when reg = 'ANSELH' | reg = 'ANSEL1' then
                           call lineout jalfile, 'var volatile bit   ',
                                left('JANSEL_ANS'offset+8,25) 'at' reg ':' offset
                        when reg = 'ANSELB' then
                           call lineout jalfile, 'var volatile bit   ',
                                left('JANSEL_ANS'offset+6,25) 'at' reg ':' offset
                        when reg = 'ANSELE' then
                           call lineout jalfile, 'var volatile bit   ',
                                left('JANSEL_ANS'offset+12,25) 'at' reg ':' offset
                        otherwise
                           call lineout jalfile, 'var volatile bit   ',
                                left('JANSEL_ANS'offset,25) 'at' reg ':' offset
                     end
                  end
                  when reg = 'T1CON' & n.j = 'T1SYNC' then do
                     field = reg'_N'n.j                 /* insert 'not' prefix */
                     call lineout jalfile, 'var volatile bit   ',
                                  left(field,25) 'at' reg ':' offset
                  end
                  when reg = 'GPIO' & left(n.j,4) = 'GPIO' then do
                    field = reg'_GP'right(n.j,1)        /* pin GPIOx -> GPx */
                    call lineout jalfile, 'var volatile bit   ',
                                 left(field,25) 'at' reg ':' offset
                  end
                  otherwise
                     if duplicate_name(field,reg) = 0 then  /* unique */
                        call lineout jalfile, 'var volatile bit   ',
                                              left(field,25) 'at' reg ':' offset
               end

               select
                  when left(reg,5) = 'ADCON'  &,        /* ADCON0/1 */
                       pos('VCFG',field) > 0  then do   /* VCFG field */
                     p = j - 1                          /* previous bit */
                     if right(n.j,5) = 'VCFG0' & right(n.p,5) = 'VCFG1' then
                       call lineout jalfile, 'var volatile bit*2 ',
                            left(left(field,length(field)-1),25) 'at' reg ':' offset
                  end
                  when left(reg,5) = 'ADCON'  &,        /* ADCON0/1 */
                       n.j = 'CHS3'  then do            /* 'loose' 4th bit */
                     chkname = reg'_CHS012'             /* compose name */
                     if  Name.chkname = '-' then do     /* partner field not present */
                        if msglevel <= 2 then
                           say '  Warning: ADCONx_CHS3 bit without previous',
                               ' ADCONx_CHS012 field declaration'
                     end
                     else do
                        call lineout jalfile, 'procedure' reg'_CHS'"'put"'(byte in x) is'
                        call lineout jalfile, '   pragma inline'
                        call lineout jalfile, '   'reg'_CHS012 = x         -- low order bits'
                        call lineout jalfile, '   'reg'_CHS3 = 0'
                        call lineout jalfile, '   if ((x & 0x08) != 0) then'
                        call lineout jalfile, '      'reg'_CHS3 = 1        -- high order bit'
                        call lineout jalfile, '   end if'
                        call lineout jalfile, 'end procedure'
                     end
                  end
                  when pos('CCP',reg) > 0  &  right(reg,3) = 'CON' &,  /* [E]CCPxCON */
                     ((left(n.j,3) = 'CCP' &  right(n.j,1) = 'Y') |,   /* CCPxY */
                      (left(n.j,2) = 'DC' &  right(n.j,2) = 'B0')) then do  /* DCxB0 */
                     if left(n.j,2) = 'DC' then
                        field = reg'_DC'substr(n.j,3,1)'B'
                     else
                        field = reg'_DC'substr(n.j,4,1)'B'
                     if duplicate_name(field,reg) = 0 then    /* unique */
                        call lineout jalfile, 'var volatile bit*2 ',
                                     left(field,25) 'at' reg ':' offset - s.j + 1
                  end
                  when reg = 'OPTION_REG' &,
                     (n.j = 'T0CS' | n.j = 'T0SE' | n.j = 'PSA') then do
                      call lineout jalfile, 'alias              ',
                                     left('T0CON_'n.j,25) 'is' reg'_'n.j
                  end
                  when reg = 'GPIO' then do
                     shadow = '_PORTA_shadow'
                     pin = 'pin_A'right(n.j,1)
                     call lineout jalfile, 'var volatile bit   ',
                                          left(pin,25) 'at' reg ':' offset
                     call insert_pin_alias 'PORTA', 'RA'right(n.j,1), pin
                     call lineout jalfile, '--'
                     call lineout jalfile, 'procedure' pin"'put"'(bit in x',
                                                      'at' shadow ':' offset') is'
                     call lineout jalfile, '   pragma inline'
                     call lineout jalfile, '   _PORTA_flush()'
                     call lineout jalfile, 'end procedure'
                     call lineout jalfile, '--'
                  end
                  when reg = 'INTCON' then do
                     if left(n.j,2) = 'T0' then
                        call lineout jalfile, 'var volatile bit   ',
                             left(reg'_TMR0'substr(n.j,3),25) 'at' reg ':' offset
                  end
                  when left(reg,4) = 'PORT' then do
                     if left(n.j,1) = 'R'  &,
                         substr(n.j,2,1) = right(reg,1) then do  /* prob. I/O pin */
                        shadow = '_PORT'right(reg,1)'_shadow'
                        pin = 'pin_'substr(n.j,2)
                        call lineout jalfile, 'var volatile bit   ',
                                              left(pin,25) 'at' reg ':' offset
                        call insert_pin_alias reg, n.j, pin
                        call lineout jalfile, '--'
                        call lineout jalfile, 'procedure' pin"'put"'(bit in x',
                                                       'at' shadow ':' offset') is'
                        call lineout jalfile, '   pragma inline'
                        call lineout jalfile, '   _PORT'substr(reg,5)'_flush()'
                        call lineout jalfile, 'end procedure'
                     end
                     call lineout jalfile, '--'
                  end
                  when reg = 'TRISIO' then do
                     pin = 'pin_A'substr(n.j,7)'_direction'
                     call lineout jalfile, 'var volatile bit   ',
                                  left(pin,25) 'at' reg ':' offset
                     call insert_pin_direction_alias 'TRISA', 'RA'substr(n.j,7), pin
                     call lineout jalfile, '--'
                  end
                  when left(reg,4) = 'TRIS'  &,
                       left(n.j,4) = 'TRIS'  then do
                     pin = 'pin_'substr(n.j,5)'_direction'
                     call lineout jalfile, 'var volatile bit   ',
                              left('pin_'substr(n.j,5)'_direction',25) 'at' reg ':' offset
                     if substr(n.j,5,1) = right(reg,1) then do   /* prob. I/O pin */
                       call insert_pin_direction_alias reg, 'R'substr(n.j,5), pin
                     end
                     call lineout jalfile, '--'
                  end
                  otherwise                             /* other regs */
                     nop                                /* can be ignored */
               end
            end
         end
         else if s.j <= 8 then do                       /* multi-bit subfield */
            field = reg'_'n.j
            if field = 'OSCCON_IOSCF' then              /* .dev error */
               field = 'OSCCON_IRCF'                    /* datasheet name */
            if field = 'OSCCON_IRFC' then               /* .dev error */
               field = 'OSCCON_IRCF'                    /* datasheet name */
            select
               when left(reg,5) = 'ADCON'  &,           /* ADCON0/1 */
                    n.j = 'CHS'            &,           /* (multibit) CHS field */
                    pos('CHS3',Dev.i) > 0  then do      /* 'loose' 4th bit present */
                  field = field'012'                    /* rename! */
                  if duplicate_name(field,reg) = 0 then   /* renamed subfield */
                     call lineout jalfile, 'var volatile bit*'s.j' ',
                                           left(field,25) 'at' reg ':' offset - s.j + 1
               end
               when (left(n.j,3) = 'ANS')   &,          /* ANS subfield */
                    (left(reg,5) = 'ADCON'  |,          /* ADCON* reg */
                    left(reg,5) = 'ANSEL')  then do     /* ANSELx reg */
                  k = s.j - 1
                  do while k >= 0
                    if reg = 'ANSELH' then do
                       call lineout jalfile, 'var volatile bit   ',
                            left('JANSEL_ANS'k+8 ,25) 'at' reg ':' offset + k + 1 - s.j
                    end
                    else if reg = 'ANSELE' then do
                       call lineout jalfile, 'var volatile bit   ',
                            left('JANSEL_ANS'k+20,25) 'at' reg ':' offset + k + 1 - s.j
                    end
                    else if reg = 'ANSELD' then do
                       call lineout jalfile, 'var volatile bit   ',
                            left('JANSEL_ANS'k+12,25) 'at' reg ':' offset + k + 1 - s.j
                    end
                    else if reg = 'ANSELB' then do
                       call lineout jalfile, 'var volatile bit   ',
                            left('JANSEL_ANS'k+6 ,25) 'at' reg ':' offset + k + 1 - s.j
                    end
                    else
                       call lineout jalfile, 'var volatile bit   ',
                            left('JANSEL_ANS'k   ,25) 'at' reg ':' offset + k + 1 - s.j
                    k = k - 1
                  end
               end
               when left(reg,5) = 'ADCON' &,            /* ADCONx */
                    pos('VCFG',field) > 0  then do      /* multibit VCFG present */
                  call lineout jalfile, 'var volatile bit   ',
                               left(field'1',25) 'at' reg ':' offset - 0
                  call lineout jalfile, 'var volatile bit   ',
                               left(field'0',25) 'at' reg ':' offset - 1
                  if duplicate_name(field,reg) = 0 then   /* unique */
                     call lineout jalfile, 'var volatile bit*'s.j' ',
                                  left(field,25) 'at' reg ':' offset - s.j + 1
               end
               when reg = 'OPTION_REG' &  n.j = 'PS' then do
                  call lineout jalfile, 'var volatile bit*'s.j' ',
                                     left(field,25) 'at' reg ':' offset - s.j + 1
                  call lineout jalfile, 'alias              ',
                                     left('T0CON_T0'n.j,25) 'is' reg'_'n.j    /* added 'T0' */
               end
               otherwise                                   /* other */
                  if \(s.j = 8  &  n.j = reg) then do      /* subfield not alias of reg */
                     if duplicate_name(field,reg) = 0 then  /* unique */
                        call lineout jalfile, 'var volatile bit*'s.j' ',
                                     left(field,25) 'at' reg ':' offset - s.j + 1
                  end
            end
         end
         offset = offset - s.j
      end
   end
   i = i + 1                                             /* next record */
end
return 0


/* -------------------------------------------------- */
/* procedure to list special function registers       */
/* input:  - nothing                                  */
/* Note: name is stored but not checked on duplicates */
/* Extended 14-bit core                               */
/* -------------------------------------------------- */
list_sfr14h: procedure expose Dev. Ram. Name. PinMap. PicName,
                              jalfile BANKSIZE NumBanks msglevel
do i = 1 to Dev.0
   if word(Dev.i,1) \= 'SFR' then               /* skip non SFRs */
      iterate
   parse var Dev.i  val0 '(KEY=' val1 ' ADDR' '=' '0X' val2 'SIZE' '=' val3 .
   if val1 \= '' then do
      reg = strip(val1)                         /* register name */
      Name.reg = reg                            /* add to collection of names */
      addr = X2D(strip(val2))                   /* decimal */
      Ram.addr = addr                           /* mark address in use */
      size = strip(val3)                        /* field size */
      if size = 1 then
         field = 'byte  '
      else if size = 2 then
         field = 'word  '
      else
         field = 'dword '
      call lineout jalfile, '-- ------------------------------------------------'
      if addr < 12 then                         /* 'CORE' register */
         memtype = 'shared '
      else
         memtype = ''
      call lineout jalfile, 'var volatile' field left(reg,25) memtype'at 0x'D2X(addr,3)
      select
         when left(reg,4) = 'PORT' then do      /* port */
            PortLetter = right(reg,1)
            PortLat.PortLetter. = 0             /* init: zero pins in PORTx */
                                                /* updated in list_sfr_subfields14h */
         end
         when left(reg,3) = 'LAT' then do       /* LATx register */
            call list_port16_shadow reg         /* force use of LATx (core 16 like) */
                                                /* for output to PORTx */
         end
         when left(reg,4) = 'TRIS' then do      /* TRISx */
            call lineout jalfile, 'var volatile byte  ',
                                  left('PORT'substr(reg,5)'_direction',25) 'at' reg
            call list_tris_nibbles reg          /* nibble direction */
         end
         when reg = 'SPBRGL' then do            /* for backward compatibility */
            call lineout jalfile, 'alias              ' left('SPBRG',25) 'is' reg
         end
         otherwise                              /* others */
            nop                                 /* can be ignored */
      end

      call list_sfr_subfields14h i, reg, memtype    /* bit fields */

      if reg = 'BSR'    |,
         reg = 'FSR0L'  |,
         reg = 'FSR0H'  |,
         reg = 'FSR1L'  |,
         reg = 'FSR1H'  |,
         reg = 'INDF0'  |,
         reg = 'PCL'    |,
         reg = 'PCLATH' |,
         reg = 'STATUS' then do
         if reg = 'INDF0' then
            reg = 'IND'                         /* compiler wants '_ind' */
         reg = tolower(reg)                     /* to lower case */
         call lineout jalfile, 'var volatile byte  ' left('_'reg,25) memtype'at 0x'D2X(addr,3),
                                  '     -- (compiler)'
         if reg = 'status' then                 /* status register */
            call list_status1x i                /* extra for compiler */
      end
   end
end

return 0


/* ------------------------------------------------- */
/* Formatting of special function register subfields */
/* input:  - index in .dev                           */
/*         - register name                           */
/* Generates names for pins or bit fields            */
/* Extended 14-bit core                              */
/* ------------------------------------------------- */
list_sfr_subfields14h: procedure expose Dev. Name. PinMap. PortLat. ,
                       PicName jalfile msglevel
i = arg(1) + 1                                          /* first after reg */
reg = arg(2)                                            /* register (name) */
memtype = arg(3)                                        /* shared/blank */
PicUpper = toupper(PicName)                             /* for alias handling */
do k = 0 to 8 while (word(Dev.i,1) \= 'SFR'  &,         /* max # of records */
                     word(Dev.i,1) \= 'NMMR')           /* other type */
   parse var Dev.i 'BIT' val0 'NAMES' '=' val1 'WIDTH' '=' val2 ')' .
   if val1 \= ''   &,                                   /* found */
      pos('SCL', val0) = 0  then do                     /* not 'scl' */
      names = strip(strip(val1), 'B', "'")              /* strip blanks */
      sizes = strip(strip(val2), 'B', "'")              /*   and quotes */
      n. = '-'                                          /* reset */
      parse  var names n.1 n.2 n.3 n.4 n.5 n.6 n.7 n.8 .
      parse  var sizes s.1 s.2 s.3 s.4 s.5 s.6 s.7 s.8 .
      offset = 7                                        /* MSbit first */
      do j = 1 to 8 while offset >= 0                   /* max 8 bits */

         if n.j = '-' then do                           /* bit not used */
           nop
         end

         else if s.j = 1 then do                        /* single bit */
            if pos('/', n.j) \= 0 then do               /* twin name */
               parse var n.j val1'/'val2 .
               if val1 \= '' then do                    /* present */
                  field = reg'_'val1                    /* new name */
                  if duplicate_name(field,reg) = 0 then do   /* unique */
                     call lineout jalfile, 'var volatile bit   ',
                                  left(field,25) memtype'at' reg ':' offset
                  end
               end
               if val2 \= '' then do
                  field = reg'_'val2
                  if duplicate_name(field,reg) = 0 then do   /* unique */
                    call lineout jalfile, 'var volatile bit   ',
                                 left(field,25) memtype'at' reg ':' offset
                  end
               end
            end
            else do                                     /* not twin name */
               field = reg'_'n.j
               select                                   /* intercept */
                  when (left(reg,5) = 'ADCON'  & left(n.j,3) = 'CHS')                       |,
                       (left(reg,6) = 'SSPCON' & left(n.j,4) = 'SSPM')                      |,
                       (reg = 'OPTION_REG'     & (n.j = 'PS0' | n.j = 'PS1' | n.j = 'PS2')) |,
                       (reg = 'T1CON'          & (n.j = 'TMR1CS1' | n.j = 'TMR1CS0'))       |,
                       (reg = 'OSCCON'         & left(n.j,4) = 'IRCF')                      |,
                       (reg = 'OSCTUNE'        & left(n.j,3) = 'TUN')                       |,
                       (reg = 'WDTCON'         & left(n.j,5) = 'WDTPS')            then do
                     nop                                /* suppress enumerated bitfields */
                  end
                  when left(reg,3) = 'CCP'  &  right(reg,3) = 'CON'  &,      /* CCPxCON */
                       datatype(substr(reg,4,1)) = 'NUM'        then do
                     nop                                /* suppress enumerated bitfields */
                  end
                  when left(reg,1) = 'T'  &  right(reg,3) = 'CON'  &,      /* TxCON */
                       datatype(substr(reg,2,1)) = 'NUM'           &,
                       (substr(n.j,3,5) = 'OUTPS' | substr(n.j,3,4) = 'CKPS')   then do
                     nop                                /* suppress enumerated bitfields */
                  end
                  when left(reg,5) = 'ANSEL'  &  left(n.j,3) = 'ANS' then do
                     select
                        when reg = 'ANSELG' then
                           call lineout jalfile, 'var volatile bit   ',
                                left('JANSEL_ANS'offset+12,25) memtype'at' reg ':' offset
                        when reg = 'ANSELF' then
                           call lineout jalfile, 'var volatile bit   ',
                                left('JANSEL_ANS'offset+5,25) memtype'at' reg ':' offset
                        when reg = 'ANSELE' then
                           call lineout jalfile, 'var volatile bit   ',
                                left('JANSEL_ANS'offset+6,25) memtype'at' reg ':' offset
                        when reg = 'ANSELD' then
                           nop                          /* not related to ADC */
                        when reg = 'ANSELC' then
                           call lineout jalfile, 'var volatile bit   ',
                                left('JANSEL_ANS'offset+4,25) memtype'at' reg ':' offset
                        when reg = 'ANSELB' then
                           call lineout jalfile, 'var volatile bit   ',
                                left('JANSEL_ANS'offset+9,25) memtype'at' reg ':' offset
                        when reg = 'ANSELA' then
                           call lineout jalfile, 'var volatile bit   ',
                                left('JANSEL_ANS'offset,25) memtype'at' reg ':' offset
                     otherwise
                        if msglevel <= 2 then
                           say '  Warning: Unsupported ANSEL register:' reg
                     end
                  end
                  when n.j \= '-' then do               /* bit present  */
                     if duplicate_name(field,reg) = 0 then do  /* unique */
                        call lineout jalfile, 'var volatile bit   ',
                                     left(field,25) memtype'at' reg ':' offset
                        if left(reg,4) = 'PORT' then do
                           PortLetter = right(reg,1)
                           if left(n.j,2) = 'R'portletter  &,  /* probably pin */
                              substr(n.j,3) = offset  then     /* matching pin number */
                              PortLat.PortLetter.offset = Portletter||offset
                        end
                     end
                  end
                  otherwise
                     nop                                /* can be ignored */
               end

               select
                  when left(reg,5) = 'ADCON' &  n.j = 'CHS0' then do
                     call lineout jalfile, 'var volatile bit*5 ',
                          left(reg'_CHS',25) memtype'at' reg ':' offset
                  end
                  when pos('CCP',reg) > 0  &  right(reg,3) = 'CON' &,      /* CCPxCON */
                       datatype(substr(reg,4,1)) = 'NUM'        then do
                     if left(n.j,2) = 'DC' & right(n.j,1) = '0' then
                        call lineout jalfile, 'var volatile bit*2 ',
                             left(reg'_DC'substr(n.j,3,1)'B',25) memtype'at' reg ':' offset
                     else if left(n.j,3) = 'CCP' & right(n.j,1) = '0' then
                        call lineout jalfile, 'var volatile bit*4 ',
                             left(reg'_CCP'substr(n.j,4,1)'M',25) memtype'at' reg ':' offset
                     else if left(n.j,1) = 'P' & right(n.j,1) = '0' then
                        call lineout jalfile, 'var volatile bit*2 ',
                             left(reg'_P'substr(n.j,2,1)'M',25) memtype'at' reg ':' offset
                  end
                  when reg = 'INTCON' then do
                     if left(n.j,2) = 'T0' then
                        call lineout jalfile, 'var volatile bit   ',
                             left(reg'_TMR0'substr(n.j,3),25) memtype'at' reg ':' offset
                  end
                  when left(reg,3) = 'LAT' then do      /* LATx register */
                     PortLetter = right(reg,1)
                     PinNumber  = right(n.j,1)
                     pin = 'pin_'PortLat.PortLetter.offset
                     if PortLat.PortLetter.offset \= 0 then do  /* pin present in PORTx */
                        call lineout jalfile, 'var volatile bit   ',
                                left(pin,25) memtype'at' 'PORT'portletter ':' offset
                        call insert_pin_alias 'PORT'portletter, 'R'PortLat.PortLetter.offset, pin
                        call lineout jalfile, '--'
                     end
                     if substr(n.j,4,1) = PortLetter  &,       /* port letter */
                        datatype(PinNumber) = 'NUM' then do    /* pin number */
                        call lineout jalfile, 'procedure' pin"'put"'(bit in x',
                                                   'at' reg ':' offset') is'
                        call lineout jalfile, '   pragma inline'
                        call lineout jalfile, 'end procedure'
                        call lineout jalfile, '--'
                     end
                  end
                  when reg = 'OPTION_REG' then do
                     if n.j = 'PS0' then do
                        call lineout jalfile, 'var volatile bit*3 ',
                             left(reg'_PS',25) memtype'at' reg ':' offset
                        call lineout jalfile, 'alias              ',
                             left('T0CON_T0'PS,25) 'is' reg'_PS'            /* added 'T0' */
                     end
                     else if n.j = 'TMR0CS'  |  n.j = 'TMR0SE' then
                        call lineout jalfile, 'alias              ',
                             left('T0CON_'delstr(n.j,2,2),25) 'is' reg'_'n.j   /* TMR0xx -> T0xx */
                     else if n.j = 'PSA' then
                        call lineout jalfile, 'alias              ',
                             left('T0CON_'n.j,25) 'is' reg'_'n.j
                  end
                  when reg = 'OSCCON'  &  n.j = 'IRCF0' then do
                     call lineout jalfile, 'var volatile bit*4 ',
                          left(reg'_IRCF',25) memtype'at' reg ':' offset
                  end
                  when reg = 'OSCTUNE'  &  n.j = 'TUN0' then do
                     call lineout jalfile, 'var volatile bit*6 ',
                          left(reg'_TUN',25) memtype'at' reg ':' offset
                  end
                  when left(reg,6) = 'SSPCON' & n.j = 'SSPM0' then do
                     call lineout jalfile, 'var volatile bit*4 ',
                          left(reg'_SSPM',25) memtype'at' reg ':' offset
                  end
                  when reg = 'T1CON' & n.j = 'TMR1CS0' then do
                     call lineout jalfile, 'var volatile bit*2 ',
                          left(reg'_TMR1CS',25) memtype'at' reg ':' offset
                  end
                  when left(reg,1) = 'T'  &  right(reg,3) = 'CON'  &,      /* TxCON */
                       datatype(substr(reg,2,1)) = 'NUM'           &,
                       (substr(n.j,3,6) = 'OUTPS0' | substr(n.j,3,5) = 'CKPS0')   then do
                     if substr(n.j,3,5) == 'OUTPS' then
                        call lineout jalfile, 'var volatile bit*4 ',
                            left(reg'_'left(n.j,7),25) memtype'at' reg ':' offset
                     else
                        call lineout jalfile, 'var volatile bit*2 ',
                            left(reg'_'left(n.j,6),25) memtype'at' reg ':' offset
                  end
                  when left(reg,4) = 'TRIS'  &,
                       left(n.j,4) = 'TRIS'  then do
                     pin = 'pin_'substr(n.j,5)'_direction'
                     call lineout jalfile, 'var volatile bit   ',
                              left('pin_'substr(n.j,5)'_direction',25) memtype'at' reg ':' offset
                     if substr(n.j,5,1) = right(reg,1) then do   /* prob. I/O pin */
                       call insert_pin_direction_alias reg, 'R'substr(n.j,5), pin
                     end
                     call lineout jalfile, '--'
                  end
                  when reg = 'WDTCON' &  n.j = 'WDTPS0' then do
                     call lineout jalfile, 'var volatile bit*5 ',
                          left(reg'_WDTPS',25) memtype'at' reg ':' offset
                  end
                  otherwise                             /* other regs */
                     nop                                /* can be ignored */
               end
            end
         end

         else if s.j <= 8 then do                       /* multi-bit subfield */
            field = reg'_'n.j
            if \(s.j = 8  &  n.j = reg) then do      /* subfield not alias of reg */
               if duplicate_name(field,reg) = 0 then  /* unique */
                  call lineout jalfile, 'var volatile bit*'s.j' ',
                               left(field,25) memtype'at' reg ':' offset - s.j + 1
            end
         end

         offset = offset - s.j
      end
   end
   i = i + 1                                             /* next record */
end
return 0


/* -------------------------------------------------------- */
/* procedure to list special function registers             */
/* input:  - nothing                                        */
/* Note: - name is stored but not checked on duplicates     */
/*       - generates some midrange aliases                  */
/* 16-bit core                                              */
/* -------------------------------------------------------  */
list_sfr16: procedure expose Dev. Ram. Name. PinMap. jalfile,
            BANKSIZE NumBanks PicName AccessBankSplitOffset msglevel
multi_usart = 0                                         /* max 1 USART */
do i = 1 to Dev.0
  if pos('RCSTA2',Dev.i) > 0 then do
    multi_usart = 1                                     /* multiple USARTs */
    leave                                               /* know enough */
  end
end
PortLat. = 0                                            /* no pins at all */
do i = 1 to Dev.0
   if word(Dev.i,1) \= 'SFR' then
      iterate
   parse var Dev.i  val0 '(KEY=' val1 ' ADDR' '=' '0X' val2 'SIZE' '=' val3 .
   if val1 \= '' then do
      reg = strip(val1)                                 /* register name */
      if left(reg,3) = 'SSP' then                       /* MSSP register */
         reg = normalize_ssp16(reg)                     /* possibly to be renamed */
      Name.reg = reg                                    /* remember name */
      addr = strip(val2)
      k = X2D(addr)                                     /* address decimal */
      size = strip(val3)                                /* # bytes */
      if size = 1 then                                  /* single byte */
         field = 'byte  '
      else if size = 2 then                             /* two bytes */
         field = 'word  '
      else
         field = 'byte*3'
      Ram.k = k                                         /* mark in use */
      call lineout jalfile, '-- ------------------------------------------------'
      if  k < AccessBankSplitOffset + X2D('F00') then
         memtype = '      '                             /* in non shared memory */
      else
         memtype = 'shared'                             /* in shared memory */
      call lineout jalfile, 'var volatile' field left(reg,25) memtype 'at 0x'addr

      select
         when left(reg,4) = 'PORT' then do              /* PORTx register */
            PortLetter = right(reg,1)
            PortLat.PortLetter. = 0                     /* init: no pins in PORTx */
                                                        /* updated in list_sfr_subfields16 */
         end
         when left(reg,3) = 'LAT' then do               /* LATx register */
            call list_port16_shadow reg                 /* force use of LATx */
                                                        /* for output to PORTx */
         end
         when left(reg,4) = 'TRIS' then do              /* TRISx */
            call lineout jalfile, 'var volatile byte  ',
                         left('PORT'substr(reg,5)'_direction',25) 'shared at' reg
            call list_tris_nibbles reg                  /* nibble directions */
         end
         when left(reg,4) = 'ECCP'  &,                  /* enhanced CCP register */
             (right(reg,3) = 'CON' | left(reg,5) = 'ECCPR') then do   /* declare legacy alias */
            if (PicName = '18f448'  | PicName = '18f4480' |,
                PicName = '18f458'  | PicName = '18f4580' | PicName = '18f4585'  |,
                PicName = '18f4680' | PicName = '18f4682' | PicName = '18f4685')  then do
               if right(reg,3) = 'CON' then
                  alias = 'CCP2CON'                     /* rename to CCP2CON */
               else
                  alias = 'CCPR2'substr(reg,7)          /* rename to CCPR2..  */
            end
            else
               alias = substr(reg,2)                    /* simply strip 'E' prefix */
            if duplicate_name(alias,reg) = 0 then       /* unique */
               call lineout jalfile, 'alias               'left(alias,32) 'is' reg
         end
         when left(reg,4) = 'SSP1' then do              /* first or only SSP module */
            alias = delstr(reg,4,1)                     /* remove '1' from reg */
            if duplicate_name(alias,reg) = 0 then
               call lineout jalfile, 'alias               'left(alias,32) 'is' reg
         end
         otherwise                                      /* others */
            nop                                         /* can be ignored */
      end

      call list_sfr_subfields16 i, reg, memtype         /* bit fields */

      alias = ''                                        /* nul alias */
      select
         when reg = 'FSR0'   |,
              reg = 'FSR0L'  |,
              reg = 'FSR0H'  |,
              reg = 'INDF0'  |,
              reg = 'PCL'    |,
              reg = 'PCLATH' |,
              reg = 'PCLATU' |,
              reg = 'TABLAT' |,
              reg = 'TBLPTR' then do
            if reg = 'INDF0' then
               reg = 'IND'                              /* compiler wants '_ind' */
            reg = tolower(reg)                     /* to lower case */
            call lineout jalfile, 'var volatile' field left('_'reg, 25),
                                  'shared at 0x'addr '     -- (compiler)'
         end

         when reg = 'STATUS' then do                    /* status register */
            call list_status16 i, addr                  /* extra for compiler */
         end

         when reg = 'RCREG1'   |,                       /* 1st USART: reg with suffix */
              reg = 'RCSTA1'   |,
              reg = 'SPBRG1'   |,
              reg = 'SPBRGH1'  |,
              reg = 'TXREG1'   |,
              reg = 'TXSTA1'   |,
              reg = 'BAUDCON1' |,
              reg = 'BAUDCTL1' then do
            alias = strip(reg,'T','1')                  /* remove '1' suffix */
         end

         when multi_usart > 0 then do                   /* PIC with multiple USARTs */
            if reg = 'RCREG'   |,                       /* register without suffix */
               reg = 'RCSTA'   |,
               reg = 'SPBRG'   |,
               reg = 'SPBRGH'  |,
               reg = 'TXREG'   |,
               reg = 'TXSTA'   |,
               reg = 'BAUDCON' |,
               reg = 'BAUDCTL' then do
               alias = reg'1'                           /* add '1' suffix */
               say 'PIC with 2 USARTs, but register ('reg') of first USART has no "1" suffix'
            end
         end

         otherwise                                      /* others */
            nop                                         /* can be ignored */
      end

      if alias \= '' then do                         /* alias to be declared */
         call lineout jalfile, '--'
         if duplicate_name(alias,reg) = 0 then       /* not duplicate */
            call lineout jalfile, 'alias               'left(alias,32) 'is' reg
         call list_sfr_subfields16_aliases i, alias, reg  /* bit field aliases */
      end
   end
end
return 0


/* --------------------------------------- */
/* Formatting of special function register */
/* input:  - index in .dev                 */
/*         - register name                 */
/* Generates names for pins or bit fields  */
/* Normalises ANS bits                     */
/* Generates some midrange aliases         */
/* Fixes some errors in MPLAB              */
/* 16-bit core                             */
/* --------------------------------------- */
list_sfr_subfields16: procedure expose Dev. Name. PinMap. PortLat. PicName,
                                       jalfile msglevel multi_usart
i = arg(1) + 1                                          /* 1st after reg */
reg = arg(2)                                            /* register (name) */
memtype = arg(3)                                        /* shared/blank */
do k = 0 to 8 while (word(Dev.i,1) \= 'SFR'   &,        /* max # of records */
                     word(Dev.i,1) \= 'NMMR')           /* other register */
   parse var Dev.i 'BIT' val0 'NAMES=' val1 'WIDTH=' val2 ')' .
   if val1 \= ''  &,                                    /* found */
      pos('SCL', val0) = 0  &,                          /* not 'scl' */
      word(Dev.i,1) \= 'QBIT' then do                   /* not 'qbit' */
      names = strip(strip(val1), 'B', "'")              /* strip blanks .. */
      sizes = strip(strip(val2), 'B', "'")              /* .. and quotes */
      parse  var names n.1 n.2 n.3 n.4 n.5 n.6 n.7 n.8 .
      parse  var sizes s.1 s.2 s.3 s.4 s.5 s.6 s.7 s.8 .
      offset = 7                                        /* MSbit first */
      do j = 1 to 8 while offset >= 0                   /* 8 bits */
         if s.j = 1 then do                             /* single bit */
            if pos('/', n.j) \= 0 then do               /* twin name */
               parse var n.j val1'/'val2 .
               if val1 \= '' then do
                  field = reg'_'val1
                  if duplicate_name(field,reg) = 0 then do   /* unique */
                     call lineout jalfile, 'var volatile bit   ',
                          left(field,25) memtype 'at' reg ':' offset
                  end
               end
               if val2 \= '' then do
                  field = reg'_'val2
                  if duplicate_name(field,reg) = 0 then do   /* unique */
                     call lineout jalfile, 'var volatile bit   ',
                          left(field,25) memtype 'at' reg ':' offset
                  end
               end
            end
            else do                                     /* not twin name */
               field = reg'_'n.j
               select                                   /* interceptions */
                  when left(reg,5) = 'ADCON'  &,        /* ADCON0/1 */
                       pos('VCFG',field) > 0  then do   /* VCFG field */
                     p = j - 1                          /* previous bit */
                     if right(n.j,5) = 'VCFG0' & right(n.p,5) = 'VCFG1' then
                        call lineout jalfile, 'var volatile bit*2 ',
                           left(left(field,length(field)-1),25) memtype 'at' reg ':' offset
                  end
                  when pos('CCP',reg) > 0  &  right(reg,3) = 'CON' &,   /* [E]CCPxCON */
                      ((left(n.j,3) = 'CCP' &  right(n.j,1) = 'Y') |,   /* CCPxY */
                       (left(n.j,2) = 'DC' &  right(n.j,2) = 'B0')) then do   /* DCxB0 */
                     if left(n.j,2) = 'DC' then
                        field = reg'_DC'substr(n.j,3,1)'B'
                     else
                        field = reg'_DC'substr(n.j,4,1)'B'
                     if duplicate_name(reg'_DC'n'B',reg) = 0 then       /* unique */
                        call lineout jalfile, 'var volatile bit*2 ',
                                   left(field,25) memtype 'at' reg ':' offset - s.j + 1
                  end
                  when left(reg,5) = 'ANSEL'  &,
                       left(n.j,3) = 'ANS' then do
                     select
                        when reg = 'ANSELH' then
                           call lineout jalfile, 'var volatile bit   ',
                                      left('JANSEL_ANS'offset+8,32) 'at' reg ':' offset
                         when reg = 'ANSELE' then
                            call lineout jalfile, 'var volatile bit   ',
                                 left('JANSEL_ANS'offset+5,32) memtype'at' reg ':' offset
                         when reg = 'ANSELD' then
                            call lineout jalfile, 'var volatile bit   ',
                                 left('JANSEL_ANS'offset+20,32) memtype'at' reg ':' offset
                         when reg = 'ANSELC' then
                            call lineout jalfile, 'var volatile bit   ',
                                 left('JANSEL_ANS'offset+12,32) memtype'at' reg ':' offset
                         when reg = 'ANSELB' then do
                            ansx = word('12 10 8 9 11 13', offset + 1)
                            call lineout jalfile, 'var volatile bit   ',
                                 left('JANSEL_ANS'ansx,32) memtype'at' reg ':' offset
                         end
                         when reg = 'ANSELA' then do
                            ansx = offset
                            if n.j = 'ANSA5' then
                               ansx = offset - 1
                            call lineout jalfile, 'var volatile bit   ',
                                 left('JANSEL_ANS'ansx,32) memtype'at' reg ':' offset
                         end
                         otherwise
                            call lineout jalfile, 'var volatile bit   ',
                                     left('JANSEL_ANS'offset,32) 'at' reg ':' offset
                     end
                  end
                  when left(reg,1) = 'T' & right(reg,3) = 'CON'   &,      /* TxCON */
                       left(n.j,1) = 'T' & right(n.j,4) = 'SYNC' then do  /* TxSYNC */
                     call lineout jalfile, 'var volatile bit   ',
                                  left(reg'_N'n.j,25) memtype 'at' reg ':' offset
                  end
                  when n.j \= '-' then do               /* bit present  */
                     if duplicate_name(field,reg) = 0 then do  /* unique */
                        call lineout jalfile, 'var volatile bit   ',
                                     left(field,25) memtype 'at' reg ':' offset
                        if left(reg,4) = 'PORT' then do
                           PortLetter = right(reg,1)
                           if left(n.j,2) = 'R'portletter  &,  /* probably pin */
                              substr(n.j,3) = offset  then     /* matching pin number */
                              PortLat.PortLetter.offset = Portletter||offset
                        end
                     end
                  end
                  otherwise
                     nop                                /* others can be ignored */
               end

               if field = 'WDTCON_ADSHR' then do        /* NMMR mapping bit */
                  call lineout jalfile, field '= FALSE                ',
                                       '-- ensure default (legacy) SFR mapping'
               end

                                                        /* special declarations */
               select
                  when reg = 'INTCON' then do
                     if left(n.j,2) = 'T0' then do
                        call lineout jalfile, 'var volatile bit   ',
                               left(reg'_TMR0'substr(n.j,3),25) memtype 'at' reg ':' offset
                     end
                  end
                  when left(reg,3) = 'LAT' then do      /* LATx register */
                     PortLetter = right(reg,1)
                     PinNumber  = right(n.j,1)
                     pin = 'pin_'PortLat.PortLetter.offset
                     if PortLat.PortLetter.offset \= 0 then do  /* pin present in PORTx */
                        call lineout jalfile, 'var volatile bit   ',
                                left(pin,25) memtype 'at' 'PORT'portletter ':' offset
                        call insert_pin_alias 'PORT'portletter, 'R'PortLat.PortLetter.offset, pin
                        call lineout jalfile, '--'
                     end
                     if substr(n.j,4,1) = portletter  &,       /* port letter */
                        datatype(pinnumber) = 'NUM' then do    /* pin number */
                        call lineout jalfile, 'procedure' pin"'put"'(bit in x',
                                                   'at' reg ':' offset') is'
                        call lineout jalfile, '   pragma inline'
                        call lineout jalfile, 'end procedure'
                        call lineout jalfile, '--'
                     end
                  end
                  when reg = 'PIE1' then do
                     if n.j = 'TX1IE' | n.j = 'RC1IE' then do   /* add alias without '1' */
                        call lineout jalfile, 'alias              ',
                               left(reg'_'delstr(n.j,3,1),32) 'is' reg'_'n.j
                     end
                     else if multi_usart > 0 then do
                        if n.j = 'TXIE' | n.j = 'RCIE' then do   /* add alias with '1' */
                           call lineout jalfile, 'alias              ',
                                 left(reg'_'left(n.j,2)'1'right(n.j,2),32) 'is' reg'_'n.j
                        end
                     end
                  end
                  when reg = 'PIR1' then do
                     if n.j = 'TX1IF' | n.j = 'RC1IF' then do
                        call lineout jalfile, 'alias              ',
                               left(reg'_'delstr(n.j,3,1),32) 'is' reg'_'n.j
                     end
                     else if multi_usart > 0 then do
                        if n.j = 'TXIF' | n.j = 'RCIF' then do   /* add alias with '1' */
                           call lineout jalfile, 'alias              ',
                                 left(reg'_'left(n.j,2)'1'right(n.j,2),32) 'is' reg'_'n.j
                        end
                     end
                  end
                  when left(reg,4) = 'TRIS' then do     /* TRISx register */
                     portletter = right(reg,1)
                     pinnumber  = right(n.j,1)
                     if PortLat.PortLetter.offset \= 0 then do  /* pin present in PORTx */
                        pin = 'pin_'PortLat.PortLetter.offset'_direction'
                        if  left(n.j,4) = 'TRIS' then do        /* only 'TRIS' bits */
                           call lineout jalfile, 'var volatile bit   ',
                                      left(pin,25) memtype 'at' reg ':' offset
                           call insert_pin_direction_alias 'PORT'substr(reg,5),,
                                           'R'substr(n.j,5), pin
                           call lineout jalfile, '--'
                       end
                     end
                  end
                  otherwise                             /* others */
                     nop                                /* no extras */
               end
            end
         end

         else if n.j = '-' then do                      /* bit not used */
            nop
         end

         else if s.j <= 8 then do                       /* multi bit sub field */
            field = reg'_'n.j
            select
               when left(reg,5) = 'ADCON'  &,           /* ADCON0/1 */
                    pos('VCFG',n.j) > 0  then do        /* VCFG field */
                 if duplicate_name(field,reg) = 0 then do   /* unique */
                   call lineout jalfile, 'var volatile bit   ',
                         left(field'1',25) memtype 'at' reg ':' offset - 0
                   call lineout jalfile, 'var volatile bit   ',
                         left(field'0',25) memtype 'at' reg ':' offset - 1
                   call lineout jalfile, 'var volatile bit*'s.j' ',
                         left(field,25) memtype 'at' reg ':' offset - s.j + 1
                 end
               end
               when (left(n.j,3) = 'ANS')   &,          /* ANS subfield */
                    (left(reg,5) = 'ADCON'  |,          /* ADCON* reg */
                    left(reg,5) = 'ANSEL')    then do   /* ANSELx reg */
                  k = s.j - 1
                  do while k >= 0
                     if reg = 'ANSELH' then
                        call lineout jalfile, 'var volatile bit   ',
                             left('JANSEL_ANS'k+8,25) 'at' reg ':' offset + k + 1 - s.j
                     else
                        call lineout jalfile, 'var volatile bit   ',
                             left('JANSEL_ANS'k  ,25) 'at' reg ':' offset + k + 1 - s.j
                     k = k - 1
                  end
               end
               when reg = 'T0CON'  &,                   /* T0CON register */
                    n.j = 'T0PS' & s.j = 4 then do      /* PSA and T0PS glued */
                  field = reg'_PSA'
                  if duplicate_name(field,reg) = 0 then  /* unique */
                     call lineout jalfile, 'var volatile bit   ',
                                  left(field,25) memtype 'at' reg ':' offset
                  field = reg'_T0PS'
                  if duplicate_name(field,reg) = 0 then  /* unique */
                     call lineout jalfile, 'var volatile bit*3 ',
                                  left(field,25) memtype 'at' reg ':' 0
               end
               when left(reg,1) = 'T' & right(reg,3) = 'CON' &,  /* TxCON */
                    n.j = 'TOUTPS' then do              /* unqualified name */
                  parse var reg 'T'tmrno'CON' .         /* extract TMR number */
                  field = reg'_T'tmrno'OUTPS'
                  if duplicate_name(field,reg) = 0 then  /* unique */
                     call lineout jalfile, 'var volatile bit*'s.j' ',
                                  left(field,25) memtype 'at' reg ':' offset - s.j + 1
               end
               otherwise                                /* others */
                  if \(s.j = 8  &  n.j = reg) then do   /* subfield not alias of reg */
                  if duplicate_name(field,reg) = 0 then  /* unique */
                     call lineout jalfile, 'var volatile bit*'s.j' ',
                          left(field,25) memtype 'at' reg ':' offset - s.j + 1
               end
            end
         end

                                                        /* additional declarations */
         if left(reg,4) = 'ECCP'  &,                    /* enhanced CCP register */
            (right(reg,3) = 'CON' | left(reg,5) = 'ECCPR')  &,     /* registers */
            (left(n.j,3) = 'EDC'  | left(n.j,4) = 'ECCP' |,        /* specific .. */
             left(n.j,2) = 'DC'   | left(n.j,3) = 'CCP') then do  /* .. fields */
            if PicName = '18f448'  | PicName = '18f4480' |,
                PicName = '18f458'  | PicName = '18f4580' | PicName = '18f4585' |,
                PicName = '18f4680' | PicName = '18f4682' | PicName = '18f4685' then do
               if right(reg,3) = 'CON' then
                  regalias = 'CCP2CON'                  /* rename reg to CCP2CON */
               else
                  regalias = 'CCPR2'substr(reg,7)       /* rename reg to ECCP2R..  */
               if left(n.j,3) = 'EDC' then
                  alias = regalias'_DC2'substr(n.j,5)   /* rename to EDC2.. */
               else
                  alias = regalias'_CCP2'substr(n.j,6)  /* rename to ECCP2.. */
            end
            else do
               if left(n.j,1) = 'E' then
                  alias = substr(reg,2)'_'substr(n.j,2)  /* strip 'E' prefixes */
               else
                  alias = substr(reg,2)'_'n.j           /* take whole field name */
            end
            if s.j \= 8 & s.j \= 16 then do             /* not full byte/word */
               if duplicate_name(alias,regalias) = 0 then  /* unique */
                  call lineout jalfile, 'alias              ' left(alias,32) 'is' field
            end
         end

         if reg = 'SSP1CON'  |,
            reg = 'SSP1CON2' |,                         /* selected SSP1 regs */
            reg = 'SSP1STAT' then do
            regalias = delstr(reg,4,1)                  /* remove '1' from the name */
            if pos('/', n.j) \= 0 then do               /* twin name */
               parse var n.j val1'/'val2 .
               if val1 \= '' then do
                  alias = regalias'_'val1
                  if duplicate_name(alias,reg) = 0 then do  /* unique */
                     call lineout jalfile, 'alias               'left(alias,32) 'is' reg'_'val1
                  end
               end
               if val2 \= '' then do
                  alias = regalias'_'val2
                  if duplicate_name(alias,reg) = 0 then do  /* unique */
                     call lineout jalfile, 'alias               'left(alias,32) 'is' reg'_'val2
                  end
               end
            end
            else do
               alias = regalias'_'n.j
               if alias \= '' then do                     /* alias to be generated */
                  if duplicate_name(alias,reg) = 0 then
                     call lineout jalfile, 'alias               'left(alias,32) 'is' reg'_'n.j
               end
            end
         end

         offset = offset - s.j                            /* next offset */

      end
   end
   i = i + 1                                             /* next record */
end
return 0


/* --------------------------------------- */
/* Formatting of SFR aliases               */
/* input:  - index in .dev                 */
/*         - alias of register             */
/*         - original register             */
/* Generates alias for bit fields          */
/* 16-bit core                             */
/* applies to USART registers             */
/* --------------------------------------- */
list_sfr_subfields16_aliases: procedure expose Dev. Name. PinMap. PortLat. PicName,
                                               jalfile msglevel
i = arg(1) + 1                                          /* 1st after reg */
reg_alias = arg(2)                                      /* register */
reg = arg(3)                                            /* original register */
do k = 0 to 8 while (word(Dev.i,1) \= 'SFR'   &,        /* max # of records */
                     word(Dev.i,1) \= 'NMMR')           /* other register */
   parse var Dev.i 'BIT' val0 'NAMES=' val1 'WIDTH=' val2 ')' .
   if val1 \= ''  &,                                    /* found */
      pos('SCL', val0) = 0  &,                          /* not 'scl' */
      word(Dev.i,1) \= 'QBIT' then do                   /* not 'qbit' */
      names = strip(strip(val1), 'B', "'")              /* strip blanks .. */
      sizes = strip(strip(val2), 'B', "'")              /* .. and quotes */
      parse  var names n.1 n.2 n.3 n.4 n.5 n.6 n.7 n.8 .
      parse  var sizes s.1 s.2 s.3 s.4 s.5 s.6 s.7 s.8 .
      offset = 7                                        /* MSbit first */
      do j = 1 to 8 while offset >= 0                   /* 8 bits */

         if s.j < 8 then do                             /* sub field */
            field = reg_alias'_'n.j
            if n.j \= '-' then do                       /* bit present  */
               if duplicate_name(field,reg_alias) = 0 then do    /* unique */
                  call lineout jalfile, 'alias              ',
                               left(field,32) 'is'  reg'_'n.j
               end
            end
         end

         offset = offset - s.j                            /* next offset */

      end
   end
   i = i + 1                                             /* next record */
end

return 0


/* -------------------------------------------------------- */
/* procedure to normalize MSSP register names               */
/* input: - register name                                   */
/* 16-bit core                                              */
/* -------------------------------------------------------  */
normalize_ssp16:
select
  when reg = 'SSPADD' then
     reg = 'SSP1ADD'
  when reg = 'SSP1CON1' |,
       reg = 'SSPCON1'  |,
       reg = 'SSPCON'   then
     reg = 'SSP1CON'
  when reg = 'SSPCON2'  then
     reg = 'SSP1CON2'
  when reg = 'SSPMSK'   |,
       reg = 'SSPMASK'  then
     reg = 'SSP1MSK'
  when reg = 'SSPSTAT'  then
     reg = 'SSP1STAT'
  when reg = 'SSPBUF'   then
     reg = 'SSP1BUF'
  when reg = 'SSP2CON1' then                            /* second MSSP module */
     reg = 'SSP2CON'
  otherwise
     nop                                                /* no change needed */
end
return  reg                                             /* return normalized name */


/* -------------------------------------------------- */
/* procedure to list non memory mapped registers      */
/* of 12-bit core as pseudo variables.                */
/* Only some selected registers are handled:          */
/* TRISxx and OPTIONxx                                */
/* input:  - nothing                                  */
/* Note: name is stored but not checked on duplicates */
/* 12-bit core                                        */
/* -------------------------------------------------- */
list_nmmr12: procedure expose Dev. Ram. Name. PinMap. PicName,
                              jalfile BANKSIZE NumBanks msglevel
do i = 1 to Dev.0
   if word(Dev.i,1) \= 'NMMR' then                      /* not 'nmmr' */
      iterate                                           /* skip */
   parse var Dev.i  val0 '(KEY=' val1 ' ADDR' '=' '0X' val2 'SIZE' '=' val3 .
   if val1 \= '' then do                                /* found! */
      reg = strip(val1)                                 /* register name */

      if left(reg,4) = 'TRIS' then do                   /* handle TRISxx */
         Name.reg = reg                                 /* add to collection of names */
         call lineout jalfile, '-- ------------------------------------------------'
         portletter = substr(reg,5)
         if portletter = 'IO'  |  portletter = '' then  /* TRISIO */
            portletter = 'A'                            /* handle it as TRISA */
         shadow = '_TRIS'portletter'_shadow'
         call lineout jalfile, 'var  byte' shadow '= 0b1111_1111         -- default all input'
         call lineout jalfile, '--'
         call lineout jalfile, 'procedure PORT'portletter"_direction'put(byte in x) is"
         call lineout jalfile, '   pragma inline'
         call lineout jalfile, '   'shadow '= x'
         call lineout jalfile, '   asm movf' shadow',W'
         if reg = 'TRISIO' then                         /* TRISIO (small PIC) */
            call lineout jalfile, '   asm tris 6'
         else                                           /* TRISx */
            call lineout jalfile, '   asm tris' 5 + C2D(portletter) - C2D('A')
         call lineout jalfile, 'end procedure'
         call lineout jalfile, '--'
         half = 'PORT'portletter'_low_direction'
         call lineout jalfile, 'procedure' half"'put"'(byte in x) is'
         call lineout jalfile, '   pragma inline'
         call lineout jalfile, '   'shadow '= ('shadow '& 0xF0) | (x & 0x0F)'
         call lineout jalfile, '   asm movf _TRIS'portletter'_shadow,W'
         if reg = 'TRISIO' then                         /* TRISIO (small PICs) */
           call lineout jalfile, '   asm tris 6'
         else                                           /* TRISx */
           call lineout jalfile, '   asm tris' 5 + C2D(portletter) - C2D('A')
         call lineout jalfile, 'end procedure'
         call lineout jalfile, '--'
         half = 'PORT'portletter'_high_direction'
         call lineout jalfile, 'procedure' half"'put"'(byte in x) is'
         call lineout jalfile, '   pragma inline'
         call lineout jalfile, '   'shadow '= ('shadow '& 0x0F) | (x << 4)'
         call lineout jalfile, '   asm movf _TRIS'portletter'_shadow,W'
         if reg = 'TRISIO' then                         /* TRISIO (small PICs) */
           call lineout jalfile, '   asm tris 6'
         else                                           /* TRISx */
           call lineout jalfile, '   asm tris' 5 + C2D(portletter) - C2D('A')
         call lineout jalfile, 'end procedure'
         call lineout jalfile, '--'
         call list_nmmr_sub12_tris i, reg              /* individual TRIS bits */
      end

      else if reg = 'OPTION_REG' | reg = OPTION2 then do  /* option */
        Name.reg = reg                                  /* add to collection of names */
        shadow = '_'reg'_shadow'
        call lineout jalfile, '-- ------------------------------------------------'
        call lineout jalfile, 'var  byte' shadow '= 0b1111_1111         -- default all set'
        call lineout jalfile, '--'
        call lineout jalfile, 'procedure' reg"'put(byte in x) is"
        call lineout jalfile, '   pragma inline'
        call lineout jalfile, '   'shadow '= x'
        call lineout jalfile, '   asm movf' shadow',0'
        if reg = 'OPTION_REG' then                      /* OPTION_REG */
           call lineout jalfile, '   asm option'
        else                                            /* OPTION2 */
           call lineout jalfile, '   asm tris 7'
        call lineout jalfile, 'end procedure'
        call list_nmmr_sub12_option i, reg             /* subfields */
      end

   end
end
return 0


/* ---------------------------------------- */
/* Formatting of non memory mapped register */
/* subfields of TRISx                       */
/* input:  - index in .dev                  */
/*         - port letter                    */
/* 12-bit core                              */
/* ---------------------------------------- */
list_nmmr_sub12_tris: procedure expose Dev. Name. PinMap. PicName,
                                       jalfile msglevel
i = arg(1) + 1                                          /* 1st after reg */
reg = arg(2)                                            /* register (name) */
do k = 0 to 3 while (word(Dev.i,1) \= 'SFR'   &,        /* max # of records */
                     word(Dev.i,1) \= 'NMMR')           /* other register */
   parse var Dev.i 'BIT' val0 'NAMES=' val1 'WIDTH=' val2 ')' .
   if val1 \= '' then do                                /* found */
      names = strip(strip(val1), 'B', "'")              /* strip blanks .. */
      parse  var names n.1 n.2 n.3 n.4 n.5 n.6 n.7 n.8 .
      portletter = substr(reg,5)
      if portletter = 'IO' then                         /* TRISIO */
         portletter = 'A'                               /* handle as TRISA */
      shadow = '_TRIS'portletter'_shadow'
      offset = 7                                        /* MSbit first */
      do j = 1 to 8 while offset >= 0                   /* max 8 bits */
         if n.j \= '-' then do                          /* pin direction present */
            call lineout jalfile, 'procedure pin_'portletter||offset"_direction'put(bit in x",
                                                      'at' shadow ':' offset') is'
            call lineout jalfile, '   pragma inline'
            call lineout jalfile, '   asm movf _TRIS'portletter'_shadow,W'
            if reg = 'TRISIO' then                      /* TRISIO */
               call lineout jalfile, '   asm tris 6'
            else                                        /* TRISx */
               call lineout jalfile, '   asm tris' 5 + C2D(portletter) - C2D('A')
            call lineout jalfile, 'end procedure'
            call insert_pin_direction_alias reg, 'R'portletter||right(n.j,1),,
                                  'pin_'portletter||right(n.j,1)'_direction'
            call lineout jalfile, '--'
         end
         offset = offset - 1
      end
   end
   i = i + 1                                             /* next record */
end
return 0


/* ------------------------------------------------- */
/* Formatting of non memory mapped registers:        */
/* OPTION_REG and OPTION2                            */
/* input:  - index in .dev                           */
/*         - register name                           */
/* Generates names for pins or bits                  */
/* 12-bit core                                       */
/* ------------------------------------------------- */
list_nmmr_sub12_option: procedure expose Dev. Name. PinMap. PicName,
                                         jalfile msglevel
i = arg(1) + 1                                          /* first after reg */
reg = arg(2)                                            /* register (name) */
do k = 0 to 8 while (word(Dev.i,1) \= 'SFR'  &,         /* max # of records */
                     word(Dev.i,1) \= 'NMMR')           /* other type */
   parse var Dev.i 'BIT' val0 'NAMES' '=' val1 'WIDTH' '=' val2 ')' .
   if val1 \= '' then do                                /* found */
      names = strip(strip(val1), 'B', "'")              /* strip blanks */
      sizes = strip(strip(val2), 'B', "'")              /*   and quotes */
      n. = '-'                                          /* reset */
      parse  var names n.1 n.2 n.3 n.4 n.5 n.6 n.7 n.8 .
      parse  var sizes s.1 s.2 s.3 s.4 s.5 s.6 s.7 s.8 .
      shadow = '_'reg'_shadow'
      offset = 7                                        /* MSbit first */
      do j = 1 to 8 while offset >= 0                   /* max 8 bits */
         if n.j \= '-' & n.j \= '' then do              /* bit(s) in use */
            call lineout jalfile, '--'
            field = reg'_'n.j
            Name.field = field                          /* remember name */
            if s.j = 1 then do                          /* single bit */
               call lineout jalfile, 'procedure' field"'put"'(bit in x',
                                                 'at' shadow ':' offset') is'
               call lineout jalfile, '   pragma inline'
            end
            else if s.j > 1  &  s.j < 8  then do        /* multi-bit */
               call lineout jalfile, 'procedure' field"'put"'(bit*'s.j 'in x',
                                                 'at' shadow ':' offset - s.j + 1') is'
               call lineout jalfile, '   pragma inline'
            end
            call lineout jalfile, '   asm movf' shadow',0'
            if reg = 'OPTION_REG' then                  /* OPTION_REG */
               call lineout jalfile, '   asm option'
            else                                        /* OPTION2 */
               call lineout jalfile, '   asm tris 7'
            call lineout jalfile, 'end procedure'
            if reg = 'OPTION_REG' then do
               if n.j = 'T0CS' | n.j = 'T0SE' | n.j = 'PSA' then
                  call lineout jalfile, 'alias              ',
                                        left('T0CON_'n.j,25) 'is' reg'_'n.j
               else if n.j = 'PS' then
                  call lineout jalfile, 'alias              ',
                                        left('T0CON_T0'n.j,25) 'is' reg'_'n.j   /* added 'T0' */
            end
         end
         offset = offset - s.j
      end
   end
   i = i + 1                                            /* next record */
end
return 0


/* ---------------------------------------------------------- */
/* procedure to list 'shared memory' SFRs of the 18Fs (NMMRs) */
/* input:  - nothing                                          */
/* output: - pseudo variables are declared                    */
/*         - subfields are expanded (separate procedure)      */
/* 16-bit core                                                */
/* ---------------------------------------------------------  */
list_nmmr16: procedure expose Dev. Ram. Name. jalfile BANKSIZE NumBanks msglevel
do i = 1 to Dev.0
   if word(Dev.i,1) \= 'NMMR' then
      iterate
   if pos('_INTERNAL',Dev.i) > 0  |,                    /* skip TMRx_internal */
      pos('_PRESCALE',Dev.i) > 0 then                   /*      TMRx_prescale */
      iterate
   parse var Dev.i 'NMMR' '(KEY=' val1 'MAPADDR=0X' val2 ' ADDR=0X' val0 'SIZE=' val3 .
   if val1 \= '' then do
      reg = strip(val1)                                 /* register name */
      Name.reg = reg                                    /* remember */
      subst  = '_'reg                                   /* substitute name */
      addr = strip(val2)                                /* (mapped) address */
      size = strip(val3)                                /* # bytes */
      call lineout jalfile, '-- ------------------------------------------------'
      call lineout jalfile, 'var volatile byte  ' left(subst,25) 'shared at 0x'addr
      call lineout jalfile, '--'
      call lineout jalfile, 'procedure' reg"'put"'(byte in x) is'
      call lineout jalfile, '   pragma inline'
      call lineout jalfile, '   WDTCON_ADSHR = TRUE'
      call lineout jalfile, '   'subst '= x'
      call lineout jalfile, '   WDTCON_ADSHR = FALSE'
      call lineout jalfile, 'end procedure'
      call lineout jalfile, 'function' reg"'get"'() return byte is'
      call lineout jalfile, '   pragma inline'
      call lineout jalfile, '   var  byte  x'
      call lineout jalfile, '   WDTCON_ADSHR = TRUE'
      call lineout jalfile, '   x =' subst
      call lineout jalfile, '   WDTCON_ADSHR = FALSE'
      call lineout jalfile, '   return  x'
      call lineout jalfile, 'end function'
      call lineout jalfile, '--'

      call list_nmmr_sub16 i, reg                       /* declare subfields */

   end
end
return 0


/* ---------------------------------------------------------- */
/* Formatting of non memory mapped registers of 16-bits core  */
/* of the 18F series                                          */
/* input:  - index in .dev                                    */
/*         - register name                                    */
/* 16-bit core                                                */
/* ---------------------------------------------------------- */
list_nmmr_sub16: procedure expose Dev. Name. PinMap. PicName jalfile msgelevel
i = arg(1) + 1                                          /* first after reg */
reg = arg(2)                                            /* register (name) */
do k = 0 to 8 while (word(Dev.i,1) \= 'SFR'  &,         /* max # of records */
                     word(Dev.i,1) \= 'NMMR')           /* other type */
   parse var Dev.i 'BIT' val0 'NAMES' '=' val1 'WIDTH' '=' val2 ')' .
   if val1 \= '' then do                                /* found */
      names = strip(strip(val1), 'B', "'")              /* strip blanks */
      sizes = strip(strip(val2), 'B', "'")              /*   and quotes */
      n. = '-'                                          /* reset */
      parse  var names n.1 n.2 n.3 n.4 n.5 n.6 n.7 n.8 .
      parse  var sizes s.1 s.2 s.3 s.4 s.5 s.6 s.7 s.8 .
      subst  = '_'reg                                   /* substitute name */
      offset = 7                                        /* MSbit first */
      do j = 1 to 8 while offset >= 0                   /* max 8 bits */
         if n.j \= '-' & n.j \= '' then do              /* bit(s) in use */
            field = reg'_'n.j
            Name.field = field                          /* remember name */
            if s.j = 1 then do                          /* single bit */
               call lineout jalfile, 'procedure' field"'put"'(bit in x) is'
               call lineout jalfile, '   pragma inline'
               call lineout jalfile, '   var  bit   y at' subst ':' offset
               call lineout jalfile, '   WDTCON_ADSHR = TRUE'
               call lineout jalfile, '   y = x'
               call lineout jalfile, '   WDTCON_ADSHR = FALSE'
               call lineout jalfile, 'end procedure'
               call lineout jalfile, 'function ' field"'get"'() return bit is'
               call lineout jalfile, '   pragma inline'
               call lineout jalfile, '   var  bit   x at' subst ':' offset
               call lineout jalfile, '   var  bit   y'
               call lineout jalfile, '   WDTCON_ADSHR = TRUE'
               call lineout jalfile, '   y = x'
               call lineout jalfile, '   WDTCON_ADSHR = FALSE'
               call lineout jalfile, '   return y'
               call lineout jalfile, 'end function'
               call lineout jalfile, '--'
            end
            else if s.j > 1  &  s.j < 8  then do        /* multi-bit */
               call lineout jalfile, 'procedure' field"'put"'(bit*'s.j 'in x) is'
               call lineout jalfile, '   pragma inline'
               call lineout jalfile, '   var  bit*'s.j 'y at' subst ':' offset - s.j + 1
               call lineout jalfile, '   WDTCON_ADSHR = TRUE'
               call lineout jalfile, '   y = x'
               call lineout jalfile, '   WDTCON_ADSHR = FALSE'
               call lineout jalfile, 'end procedure'
               call lineout jalfile, 'function ' field"'get"'() return bit*'s.j 'is'
               call lineout jalfile, '   pragma inline'
               call lineout jalfile, '   var  bit*'s.j 'x at' subst ':' offset - s.j + 1
               call lineout jalfile, '   var  bit*'s.j 'y'
               call lineout jalfile, '   WDTCON_ADSHR = TRUE'
               call lineout jalfile, '   y = x'
               call lineout jalfile, '   WDTCON_ADSHR = FALSE'
               call lineout jalfile, '   return y'
               call lineout jalfile, 'end function'
               call lineout jalfile, '--'
            end
            else if s.j = 8 then                        /* synonym */
              nop                                       /* ignore */
         end
         offset = offset - s.j
      end
   end
   i = i + 1                                            /* next record */
end
return 0


/* ---------------------------------------------- */
/* procedure to create port shadowing functions   */
/* for full byte, lower- and upper-nibbles        */
/* For 12- and 14-bit core                        */
/* input:  - Port register                        */
/* ---------------------------------------------- */
list_port1x_shadow: procedure expose jalfile
reg = arg(1)
shadow = '_PORT'substr(reg,5)'_shadow'
call lineout jalfile, '--'
call lineout jalfile, 'var          byte ' shadow '       = 'reg
call lineout jalfile, '--'
call lineout jalfile, 'procedure _PORT'substr(reg,5)'_flush() is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   'reg '=' shadow
call lineout jalfile, 'end procedure'
call lineout jalfile, 'procedure' reg"'put"'(byte in x) is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   'shadow '= x'
call lineout jalfile, '   _PORT'substr(reg,5)'_flush()'
call lineout jalfile, 'end procedure'
call lineout jalfile, '--'
half = 'PORT'substr(reg,5)'_low'
call lineout jalfile, 'procedure' half"'put"'(byte in x) is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   'shadow '= ('shadow '& 0xF0) | (x & 0x0F)'
call lineout jalfile, '   _PORT'substr(reg,5)'_flush()'
call lineout jalfile, 'end procedure'
call lineout jalfile, 'function' half"'get()" 'return byte is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   return ('reg '& 0x0F)'
call lineout jalfile, 'end function'
call lineout jalfile, '--'
half = 'PORT'substr(reg,5)'_high'
call lineout jalfile, 'procedure' half"'put"'(byte in x) is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   'shadow '= ('shadow '& 0x0F) | (x << 4)'
call lineout jalfile, '   _PORT'substr(reg,5)'_flush()'
call lineout jalfile, 'end procedure'
call lineout jalfile, 'function' half"'get()" 'return byte is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   return ('reg '>> 4)'
call lineout jalfile, 'end function'
call lineout jalfile, '--'
return


/* ------------------------------------------------ */
/* procedure to force use of LATx with 16-bits core */
/* for full byte, lower- and upper-nibbles          */
/* input:  - LATx register                          */
/* ------------------------------------------------ */
list_port16_shadow: procedure expose jalfile
lat  = arg(1)                                   /* LATx register */
port = 'PORT'substr(lat,4)                      /* corresponding port */
call lineout jalfile, '--'
call lineout jalfile, 'procedure' port"'put"'(byte in x) is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   'lat '= x'
call lineout jalfile, 'end procedure'
call lineout jalfile, '--'
half = 'PORT'substr(lat,4)'_low'
call lineout jalfile, 'procedure' half"'put"'(byte in x) is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   'lat '= ('port '& 0xF0) | (x & 0x0F)'
call lineout jalfile, 'end procedure'
call lineout jalfile, 'function' half"'get()" 'return byte is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   return ('port '& 0x0F)'
call lineout jalfile, 'end function'
call lineout jalfile, '--'
half = 'PORT'substr(lat,4)'_high'
call lineout jalfile, 'procedure' half"'put"'(byte in x) is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   'lat '= ('port '& 0x0F) | (x << 4)'
call lineout jalfile, 'end procedure'
call lineout jalfile, 'function' half"'get()" 'return byte is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   return ('port '>> 4)'
call lineout jalfile, 'end function'
call lineout jalfile, '--'
return


/* ---------------------------------------------- */
/* procedure to create TRIS functions             */
/* for lower- and upper-nibbles only              */
/* input:  - TRIS register                        */
/* ---------------------------------------------- */
list_tris_nibbles: procedure expose jalfile
reg = arg(1)
call lineout jalfile, '--'
half = 'PORT'substr(reg,5)'_low_direction'
call lineout jalfile, 'procedure' half"'put"'(byte in x) is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   'reg '= ('reg '& 0xF0) | (x & 0x0F)'
call lineout jalfile, 'end procedure'
call lineout jalfile, 'function' half"'get()" 'return byte is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   return ('reg '& 0x0F)'
call lineout jalfile, 'end function'
call lineout jalfile, '--'
half = 'PORT'substr(reg,5)'_high_direction'
call lineout jalfile, 'procedure' half"'put"'(byte in x) is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   'reg '= ('reg '& 0x0F) | (x << 4)'
call lineout jalfile, 'end procedure'
call lineout jalfile, 'function' half"'get()" 'return byte is'
call lineout jalfile, '   pragma inline'
call lineout jalfile, '   return ('reg '>> 4)'
call lineout jalfile, 'end function'
call lineout jalfile, '--'
return


/* -------------------------------------------------------- */
/* procedure to add pin alias declarations                  */
/* input:  - register name                                  */
/*         - original pin name (Rx)                         */
/*         - pinname for aliases (pin_Xy)                   */
/* returns index of alias (0 if none)                       */
/* -------------------------------------------------------- */
insert_pin_alias: procedure expose  PinMap. Name. PicName jalfile msglevel
PicUpper = toupper(PicName)
reg     = arg(1)
PinName = arg(2)
Pin     = arg(3)
if PinMap.PicUpper.PinName.0 = '?' then do
   if msglevel <= 2 then
      Say '  Warning: insert_pin_alias() PinMap.'PicUpper'.'PinName 'is undefined'
   return 0                                             /* no alias */
end
if PinMap.PicUpper.PinName.0 > 0 then do
   do k = 1 to PinMap.PicUpper.PinName.0                /* all aliases */
      pinalias = 'pin_'PinMap.PicUpper.PinName.k
      if duplicate_name(pinalias,reg) = 0 then          /* unique */
         call lineout jalfile, 'alias              ' left(pinalias,25) 'is' Pin
   end
end
return k                                                /* k-th alias */


/* -------------------------------------------------------- */
/* procedure to add pin_direction alias declarations        */
/* input:  - register name                                  */
/*         - original pin name (Rx)                         */
/*         - pinname for aliases (pin_Xy)                   */
/* note: '_direction' is added                              */
/* -------------------------------------------------------- */
insert_pin_direction_alias: procedure expose  PinMap. Name. PicName jalfile msglevel
PicUpper = toupper(PicName)
reg     = arg(1)
PinName = arg(2)
Pin     = arg(3)
if PinMap.PicUpper.PinName.0 = '?' then do
   if msglevel <= 2 then
      Say '  Warning: insert_pin_direction_alias() PinMap.'PicUpper'.'PinName 'is undefined'
   return 0                                             /* ignore no alias */
end
if PinMap.PicUpper.PinName.0 > 0 then do
   do k = 1 to PinMap.PicUpper.PinName.0                /* all aliases */
      pinalias = 'pin_'PinMap.PicUpper.PinName.k'_direction'
      if duplicate_name(pinalias,reg) = 0 then          /* unique */
         call lineout jalfile, 'alias              ' left(pinalias,25) 'is' pin
   end
end
return k


/* -------------------------------------------------------- */
/* Special _extra_ formatting of STATUS register            */
/* input:  - index in .dev                                  */
/* remark: Is extra set of definitions for compiler only.   */
/*         Not intended for use by application programs.    */
/* 12-bit and 14-bit core                                   */
/* -------------------------------------------------------- */
list_status1x: procedure expose Dev. jalfile msglevel
i = arg(1) + 1                                          /* just after register */
do k = 0 to 4 while word(Dev.i, 1) \= 'SFR'             /* max 5 records */
   parse var Dev.i 'BIT' val0 'NAMES=' val1 'WIDTH=' val2 ')' .
   if val1 \= '' then do
      names = strip(strip(val1), 'B', "'")              /* strip quotes */
      sizes = strip(strip(val2), 'B', "'")
      parse  var names n.1 n.2 n.3 n.4 n.5 n.6 n.7 n.8 .
      parse  var sizes s.1 s.2 s.3 s.4 s.5 s.6 s.7 s.8 .
      offset = 7                                        /* MSbit */
      do i = 1 to 8                                     /* all individual bits */
         if n.i = '-' then do                           /* bit not present */
           offset = offset - 1
         end
         else if datatype(s.i) = 'NUM' then do          /* field size */
            if s.i = 1 then do                          /* single bit */
               n.i = tolower(n.i)                       /* to lower case */
               if n.i = 'nto' then do
                  call lineout jalfile, 'const        byte  ',
                       left('_not_to',25) '= ' offset '     -- (compiler)'
               end
               else if n.i = 'npd' then do
                  call lineout jalfile, 'const        byte  ',
                       left('_not_pd',25) '= ' offset '     -- (compiler)'
               end
               else do
                  call lineout jalfile, 'const        byte  ',
                       left('_'n.i,25) '= ' offset '     -- (compiler)'
               end
               offset = offset - 1                      /* next bit */
            end
            else do j = s.i - 1  to  0  by  -1          /* enumerate */
               call lineout jalfile, 'const        byte  ',
                      left('_'n.i||j,25) '= ' offset '     -- (compiler)'
               offset = offset - 1
            end
         end
      end
   end
   i = i + 1                                            /* next record */
end
return


/* -------------------------------------------------------- */
/* Special _extra_ formatting of STATUS register            */
/* input:  - index in .dev                                  */
/*         - register name (STATUS)                         */
/* remark: Is extra set of definitions for compiler only.   */
/*         Not intended for use by application programs.    */
/* 16-bit core                                              */
/* -------------------------------------------------------- */
list_status16: procedure expose Dev. jalfile msglevel
i = arg(1) + 1                                          /* just after register */
addr = arg(2)                                           /* register */
call lineout jalfile, 'var volatile byte  ' left('_status',25),
                                    'shared at 0x'addr '     -- (compiler)'
do k = 0 to 4 while word(Dev.i, 1) \= 'SFR'             /* max 4 records */
   parse var Dev.i 'BIT' val0 'NAMES=' val1 'WIDTH=' val2 ')' .
   if val1 \= '' then do
      names = strip(strip(val1), 'B', "'")              /* strip blanks */
      sizes = strip(strip(val2), 'B', "'")              /* .. and quotes */
      parse  var names n.1 n.2 n.3 n.4 n.5 n.6 n.7 n.8 .
      parse  var sizes s.1 s.2 s.3 s.4 s.5 s.6 s.7 s.8 .
      offset = 7                                        /* MSbit */
      do i = 1 to 8 while offset >= 0                   /* all individual bits */
         if n.i = '-' then                              /* bit not present */
            offset = offset - 1                         /* skip */
         else if datatype(s.i) = 'NUM' then do          /* field size */
            n.i = tolower(n.i)                          /* to lowercase */
            call lineout jalfile, 'const        byte  ',
                         left('_'n.i,25) '= ' offset '     -- (compiler)'
            offset = offset - 1                         /* next bit */
         end
      end
   end
   i = i + 1                                            /* next record */
end
call lineout jalfile, 'const        byte  ' left('_banked',25) '=  1',
                              '     -- (compiler - use BSR)'
call lineout jalfile, 'const        byte  ' left('_access',25) '=  0',
                              '     -- (compiler - use ACCESS)'
return


/* --------------------------------------------------------- */
/* procedure to extend address with mirrored addresses       */
/* input:  - register number (decimal)                       */
/* returns string of addresses between {}                    */
/* (not used for 16-bit core)                                */
/* --------------------------------------------------------- */
sfr_mirror: procedure expose Ram. BANKSIZE NumBanks
addr = arg(1)
addr_list = '{ 0x'D2X(addr)                             /* open bracket, orig. addr */
do i = addr + BANKSIZE to NumBanks * BANKSIZE - 1 by BANKSIZE   /* avail ram */
   if addr = Ram.i then                                 /* matching reg number */
      addr_list = addr_list',0x'D2X(i)                  /* concatenate to string */
end
return addr_list' }'                                    /* complete string */


/* ---------------------------------------------------------------------- */
/* Formatting of configuration bits                                       */
/* input:  - nothing                                                      */
/* Note:  some fuse_defs are omitted because the bit is not supported(!), */
/*        even if it is (partly) specified in the .dev file.              */
/*        See at the bottom of changes.txt for details.                   */
/* ---------------------------------------------------------------------- */
list_fuses_bits:   procedure expose Dev. jalfile CfgAddr. Fuse_Def. Core PicName msglevel
call lineout jalfile, '--'
call lineout jalfile, '-- =================================================='
call lineout jalfile, '--'
call lineout jalfile, '-- Symbolic Fuse definitions'
call lineout jalfile, '-- -------------------------'
k = 0                                                   /* config word count */
do i = 1 to dev.0                                       /* scan .dev file */
   if word(Dev.i,1) \= 'CFGBITS' then                   /* appropriate record */
     iterate
   ln = Dev.i
   parse var ln 'CFGBITS' '(' 'KEY' '=' val0 ' ADDR' '=' '0X' val1 'UNUSED' '=' '0X' val2 ')' .
   if val1 \= '' then do                                /* address found */
      k = k + 1                                         /* count fuse words */
      cfgword = strip(val0)                             /* byte or word name */
      addr = strip(val1)                                /* hex addr */
      call lineout jalfile, '--'
      call lineout jalfile, '--' cfgword '(0x'addr')'
      call lineout jalfile, '--'
      i = i + 1                                         /* next record */
      ln = dev.i                                        /* next line */
      do while i <= dev.0  &  word(ln, 1) \= 'CFGBITS'
         parse var ln 'FIELD' val0 'KEY=' val1 'MASK' '=' '0X' val2 'DESC' '=' '"' val3 '"'.
         key = strip(val1)

         if key \= '' then do                           /* key value found */
                                                        /* skip some superfluous bits */
            if ( key = 'RES' | key = 'RES1' | left(key,8) = 'RESERVED' )    |,
               ( pos('ENICPORT',key) > 0 )                          |,
               ( (key = 'CPD' | key = 'WRTD')  &,
                 (PicName = '18f2410' | PicName = '18f2510' |,
                  PicName = '18f2515' | PicName = '18f2610' |,
                  PicName = '18f4410' | PicName = '18f4510' |,
                  PicName = '18f4515' | PicName = '18f4610') )      |,
               ( (key = 'EBTR_3' | key = 'CP_3' | key = 'WRT_3') &,
                 (PicName = '18f4585') )                            |,
               ( (key = 'EBTR_4' | key = 'CP_4' | key = 'WRT_4' |,
                  key = 'EBTR_5' | key = 'CP_5' | key = 'WRT_5' |,
                  key = 'EBTR_6' | key = 'CP_6' | key = 'WRT_6' |,
                  key = 'EBTR_7' | key = 'CP_7' | key = 'WRT_7')  &,
                 (PicName = '18f6520' | PicName = '18f8520') )      then do
               i = i + 1
               ln = Dev.i
               iterate
            end

            select                                      /* reduce synonyms and */
                                                        /* correct MPLAB errors */
               when key = 'BACKBUG' | key = 'BKBUG' then
                  key = 'DEBUG'
               when key = 'BBSIZ0' then
                  key = 'BBSIZ'
               when key = 'BODENV' | key = 'BOR4V' | key = 'BORV' then
                  key = 'VOLTAGE'
               when key = 'BODEN' | key = 'BOREN' | key = 'DSBOREN' then
                  key = 'BROWNOUT'
               when left(key,3) = 'CCP' & right(key,2) = 'MX' then
                  key = left(key,4)'MUX'                /* CCPxMX -> CCPxMUX */
               when key = 'CPDF' | key = 'CPSW' then
                  key = 'CPD'
               when left(key,3) = 'CP_' & datatype(substr(key,4),'W') = 1 then
                  key = 'CP'substr(key,4)               /* remove underscore */
               when left(key,4) = 'EBRT' then           /* typo in .dev files */
                  key = 'EBTR'substr(key,5)
               when left(key,5) = 'EBTR_' & datatype(substr(key,6),'W') = 1 then
                  key = 'EBTR'substr(key,6)             /* remove underscore */
               when key = 'ECCPMX' | key = 'ECCPXM' then
                  key = 'ECCPMUX'                       /* ECCPxMX -> ECCPxMUX */
               when key = 'EXCLKMX' then
                  key = 'EXCLKMUX'
               when key = 'FLTAMX' then
                  key = 'FLTAMUX'
               when key = 'FOSC' then
                  key = 'OSC'
               when key = 'IOFSCS' then                 /* typo in .dev files */
                  key = 'IOSCFS'
               when key = 'MCLRE' then
                  key = 'MCLR'
               when key = 'MSSP7B_EN' | key = 'MSSPMSK' then
                  key = 'MSSPMASK'
               when key = 'PLL_EN' | key = 'CFGPLLEN' then
                  key = 'PLLEN'
               when key = 'PM' then
                  key = 'PMODE'
               when key = 'PMPMX' then
                  key = 'PMPMUX'
               when key = 'PWM4MX' then
                  key = 'PWM4MUX'
               when key = 'PUT' | key = 'PWRT' | key = 'PWRTEN' |,
                    key = 'NPWRTE' | key = 'NPWRTEN' then
                  key = 'PWRTE'
               when key = 'RTCSOSC' then
                  key = 'RTCOSC'
               when key = 'SOSCEL' then
                  key = 'SOSCSEL'
               when key = 'SSPMX' then
                  key = 'SSPMUX'
               when key = 'STVREN' then
                  key = 'STVR'
               when key = 'T1OSCMX' then
                  key = 'T1OSCMUX'
               when key = 'T3CMX' then
                  key = 'T3CMUX'
               when key = 'WDTEN' | key = 'WDTE' then
                  key = 'WDT'
               when key = 'WRT_ENABLE' then
                  key = 'WRT'
               when left(key,4) = 'WRT_' & datatype(substr(key,5),'W') = 1 then
                  key = 'WRT'substr(key,5)              /* remove underscore */
               otherwise
                  nop                                   /* accept any other key asis */
            end

            if CfgAddr.0 > 1 then                       /* multi fuse bytes/words */
               str = 'pragma fuse_def' key':'X2D(addr) - CfgAddr.1 '0x'strip(val2) '{'
            else                                        /* single use word */
               str = 'pragma fuse_def' key '0x'strip(val2) '{'
            call lineout jalfile, left(str,40)'   --' tolower(val3)

            call list_fuses_bits_details i, key         /* expand bit declations */

            call lineout jalfile, '       }'            /* done with this key */

         end
         i = i + 1
         ln = Dev.i
      end
   end
   i = i - 1                                            /* read one to many */
end
call lineout jalfile, '--'
return


/* ----------------------------------------------------------------------- */
/* Detailed formatting of configuration bits settings                      */
/* input:  - line index in dev.                                            */
/*         - keyword                                                       */
/* output: lines in jalfile                                                */
/*                                                                         */
/* notes: val2 contains keyword description with undesired chars as blank  */
/*        val2u is val2 with blanks between words replaced by 1 underscore */
/* ----------------------------------------------------------------------- */
list_fuses_bits_details: procedure expose Dev. Fuse_Def. jalfile Fuse_Def. PicName msglevel
key           = arg(2)                                  /* fuse_def name */
kwd.          = '-'                                     /* empty kwd compound */

flag_enabled = 0                                        /* to check for missing */
flag_disabled = 0                                       /* enable or disable */

do i = arg(1) + 1  while i <= dev.0  &,
           (word(dev.i,1) = 'SETTING' | word(dev.i,1) = 'CHECKSUM')
   parse var Dev.i 'SETTING' val0 'VALUE' '=' '0X',
                          val1 'DESC' '=' '"' val2 '"' .
   if val1 = '' then                                    /* no setting value found */
      iterate                                           /* skip to next line */

   mask = strip(val1)                                   /* bit mask (hex) */
   val2 = strip(val2)
   val2u = translate(val2, '                 ','+-:;.,<>{}[]()=/?')  /* to blanks */
   val2u = space(val2u,,'_')                            /* single underscores */

   select                                               /* key specific formatting */

      when key = 'ADCSEL'  |,                           /* ADC resolution */
           key = 'ABW'     |,                           /* address bus width */
           key = 'BW'    then do                        /* external memory bus width */
         parse value word(val2,1) with kwd '-' .        /* assign number */
         kwd = 'B'kwd                                   /* add prefix */
      end

      when key = 'BBSIZ' then do
         do j=1 to words(val2)
           if left(word(val2,j),1) >= '0' & left(word(val2,j),1) <= '9' then do
             kwd = 'W'word(val2,j)                      /* found leading digit */
             leave
           end
         end
         if datatype(substr(kwd,2),'W') = 1  &,         /* second char numeric */
             pos('KW',val2u) > 0 then do                /* contains KW */
            kwd = kwd'K'                                /* append 'K' */
         end
      end

      when key = 'BG' then do                           /* band gap */
         kwd = word(val2,1)                             /* first word */
         if kwd = 'ADJUST' then do
            if pos('-',val2) > 0 then                   /* negative voltage */
               kwd = kwd'_NEG'
            else
               kwd = kwd'_POS'
         end
      end

      when key = 'BROWNOUT' then do
         if pos('SLEEP',val2) > 0  &  pos('DEEP SLEEP',val2) = 0 then
            kwd = 'RUNONLY'
         else if pos('ENABLE',val2) \= 0  | val2 = 'ON' then do
            kwd = 'ENABLED'
            flag_enabled = flag_enabled + 1
         end
         else if pos('CONTROL',val2) \= 0 then
            kwd = 'CONTROL'
         else do
            kwd = 'DISABLED'
            flag_disabled = flag_disabled + 1
         end
      end

      when left(key,3) = 'CCP' & right(key,3) = 'MUX' then do   /* CCPxMUX */
         if pos('MICRO',val2) > 0 then                  /* Mcrocontroller mode */
            kwd = 'pin_E7'                              /* valid for all current PICs */
         else
            kwd = 'pin_'right(val2,2)                   /* last 2 chars */
      end

      when key = 'CPUDIV' then do
         if pos('DIVIDE',val2) > 0 & pos('BY',val2) > 0 then
            kwd = P||word(val2,words(val2))             /* last word */
         else if pos('/',val2) > 0 then
            kwd = 'P'substr(val2,lastpos('/',val2)+1,1)
         else if pos('NO',val2) > 0 then
            kwd = 'P1'
         else
            kwd = val2u
      end

      when key = 'DSWDTOSC' then do
         if pos('INT',val2) > 0 then
            kwd = 'INTOSC'
         else
            kwd = 'T1'
      end

      when key = 'DSWDTPS'   |,
           key = 'WDTPS' then do
         parse var val2 p0 ':' p1                       /* split */
         kwd = translate(word(p1,1),'      ','.,()=/')  /* 1st word, cleaned */
         kwd = space(kwd,0)                             /* remove all spaces */
         do j=1 while kwd >= 1024
            kwd = kwd / 1024                            /* reduce to K, M, G, T */
         end
         kwd = 'P'kwd||substr(' KMGT',j,1)
      end

      when key = 'EBTRB' then do
         if pos('UNPROT',val2) > 0 | pos('DISABLE',val2) > 0 then do  /* unprotected */
            kwd = 'DISABLED'
            flag_disabled = flag_disabled + 1
         end
         else do
            kwd = 'ENABLED'
            flag_enabled = flag_enabled + 1
         end
      end

      when key = 'ECCPMUX' then do
         kwd = 'pin_'right(val2,2)                      /* last 2 chars */
      end

      when key = 'EMB' then do
         if pos('12',val2) > 0 then                     /* 12-bit mode */
            kwd = 'B12'
         else if pos('16',val2) > 0 then                /* 16-bit mode */
            kwd = 'B16'
         else if pos('20',val2) > 0 then                /* 20-bit mode */
            kwd = 'B20'
         else
            kwd = 'DISABLED'                            /* no en/disable balancing */
      end

      when key = 'ETHLED' then do
         if pos('ETHERNET',val2) > 0 then do           /* LED enabled */
            kwd = 'ENABLED'
            flag_enabled = flag_enabled + 1
         end
         else do
            kwd = 'DISABLED'
            flag_disabled = flag_disabled + 1
         end
      end

      when key = 'EXCLKMUX' then do                     /* Timer0/5 clock pin */
         kwd = 'pin_'right(val2,2)                      /* last 2 chars */
      end

      when key = 'FLTAMUX' then do
         kwd = 'pin_'right(val2,2)                      /* last 2 chars */
      end

      when key = 'FOSC2' then do
         if pos('INTRC',val2) > 0 then
            kwd = 'INTOSC'
         else
            kwd = 'OSC'
      end

      when key = 'HFOFST' then do
         if pos('STABLE',val2) > 0 | pos('ENABLE',val2) > 0 then do
            kwd = 'ENABLED'
            flag_enabled = flag_enabled + 1
         end
         else do
            kwd = 'DISABLED'
            flag_disabled = flag_disabled + 1
         end
      end

      when key = 'IOSCFS' then do
         if pos('MHZ',val2) > 0 then do
            if pos('8',val2) > 0 then                   /* 8 MHz */
               kwd = 'F8MHZ'
            else
               kwd = 'F4MHZ'                            /* otherwise */
         end
         else do
            kwd = val2u
            if left(kwd,1) >= '0' & left(kwd,1) <= '9' then
               kwd = 'F'kwd                             /* prefix when numeric */
         end
      end

      when key = 'LPT1OSC' then do
         if pos('LOW',val2) > 0 | pos('ENABLE',val2) > 0 then
            kwd = 'LOW_POWER'
         else
            kwd = 'HIGH_POWER'
      end

      when key = 'LVP' then do
         if pos('ENABLE',val2) > 0 then do
            kwd = 'ENABLED'
            flag_enabled = flag_enabled + 1
         end
         else do
            kwd = 'DISABLED'
            flag_disabled = flag_disabled + 1
         end
      end

      when key = 'MCLR' then do
         if pos('EXTERN',val2) > 0           |,
            pos('MCLR ENABLED',val2) > 0     |,
            pos('MCLR PIN ENABLED',val2) > 0 |,
            pos('MASTER',val2) > 0           |,
            pos('AS MCLR',val2) > 0          |,
            pos('IS MCLR',val2) > 0          |,
            val2 = 'MCLR'                    |,
            val2 = 'ENABLED'   then
            kwd = 'EXTERNAL'
         else
            kwd = 'INTERNAL'
      end

      when key = 'MSSPMASK' then do
         kwd = 'B'word(val2,1)                          /* 5 or 7 expected */
      end

      when key = 'OSC' then do
         kwd = Fuse_Def.Osc.val2u
         if kwd = '?' then do
            if msglevel <= 2 then
               say '  Warning: No mapping for fuse_def' key' :' val2u
            return
         end
      end

      when key = 'PLLDIV' then do
         if left(val2,9) = 'DIVIDE BY' then
            kwd = P||word(val2,3)                       /* 3rd word */
         else if word(val2,1) = 'NO' then
            kwd = 'P1'
         else
            kwd = val2u
      end

      when key = 'PLLEN' then do
         if pos('MULTIPL',val2) > 0 then
            kwd = 'P'word(val2,words(val2))             /* last word */
         else if pos('DIRECT',val2) > 0 | pos('DISABLED',val2) > 0 then
            kwd = 'P1'
         else if pos('ENABLED',val2) > 0 then
            kwd = 'P4'                                  /* (assumed) */
         else if pos('DISABLED',val2) > 0 then
            kwd = 'P1'
         else if datatype(left(val2,1),'W') = 1 then
            kwd = 'F'val2u
         else
            kwd = val2u
      end

      when key = 'PMODE' then do
         if pos('EXT',val2) > 0 then do
            if pos('-BIT', val2) > 0 then
               kwd = 'B'left(word(val2,words(val2)),2)     /* 1st two chars last word */
            else
               kwd = 'EXT'
         end
         else if pos('PROCESSOR',val2) > 0 then do
            kwd = 'MICROPROCESSOR'
            if pos('BOOT',val2) > 0 then
               kwd = kwd'_BOOT'
         end
         else
            kwd = 'MICROCONTROLLER'
      end

      when key = 'PMPMUX' then do
         wpos = wordpos('ON',val2)
         if wpos > 0 then
            kwd = left(word(val2,wpos + 1),5)           /* 'portx' behind 'ON' */
         else
            kwd = val2u
      end

      when key = 'PWM4MUX' then do
         kwd = 'pin_'right(val2,2)
      end

      when key = 'RTCOSC' then do
         if pos('INTRC',val2) > 0 then
            kwd = 'INTRC'
         else
            kwd = 'T1OSC'
      end

      when key = 'SIGN' then do
         if pos('CONDUCATED',val2) > 0 then
            kwd = 'NOT_CONDUCATED'
         else
            kwd = 'AREA_COMPLETE'
      end

      when key = 'SSPMUX' then do
         offset1 = pos('MUX',val2)
         if offset1 > 0 then do
         /* say 'offset 1' offset1   */
            offset2 = pos(' R',substr(val2,offset1))      /* pin */
         /* say 'offset 2' offset2   */
            if offset2 > 0 then
               kwd = 'pin_'substr(val2,offset1+offset2+1,2)
            else
               kwd = 'ENABLED'
         end
         else
            kwd = 'DISABLED'                            /* no en/disable balancing */
      end

      when key = 'T1OSCMUX' then do
         if right(val2,3) = 'RA7' then
            kwd = 'pin_A6_A7'
         else if right(val2,3) = 'RB3' then
            kwd = 'pin_B2_B3'
         else
            kwd = val2u
      end

      when key = 'USBDIV' then do
         if pos('NO DIVIDE',val2) > 0 then
            kwd = 'P1'
         else
            kwd = 'P'word(val2,words(val2))             /* last word */
      end

      when key = 'USBPLL' then do
         if pos('PLL',val2) > 0 then
            kwd = 'F48MHZ'
         else
            kwd = 'OSC'
      end

      when key = 'VCAPEN' then do
         if pos('DISABLED',val2) > 0 then               /* no en/disable balancing */
            kwd = 'DISABLED'
         else if pos('ENABLED',val2) > 0 then do
            kwd = word(val2, words(val2))               /* last word */
            if left(kwd,1) = 'R' then                   /* pinname Rxy */
               kwd = 'pin_'substr(kwd,2)                /* make it pin_xy */
         end
         else
            kwd = 'ENABLED'                             /* probably never reached */
      end

      when key = 'VOLTAGE' then do
         do j=1 to words(val2)                          /* scan word by word */
            if left(word(val2,j),1) >= '0' & left(word(val2,j),1) <= '9' then do
               if pos('.',word(val2,j)) > 0 then do     /* select digits */
                  kwd = 'V'left(word(val2,j),1,1)||substr(word(val2,j),3,1)
                  leave                                 /* done */
               end
            end
         end
         if j > words(val2) then                        /* no voltage value found */
            kwd = val2u
      end

      when key = 'WAIT' then do
         if pos('NOT',val2) > 0 | pos('DISABLE',val2) > 0 then do
            kwd = 'DISABLED'
            flag_disabled = flag_disabled + 1
         end
         else do
            kwd = 'ENABLED'
            flag_enabled = flag_enabled + 1
         end
      end

      when key = 'WDT' then do
         p_en = pos('ENABLE', val2)
         p_dis = pos('DISABLE', val2)
         if pos('RUNNING', val2) > 0 then
            kwd = 'RUNONLY'
         else if val2 = 'OFF' | p_dis > 0 then do
            kwd = 'DISABLED'
            flag_disabled = flag_disabled + 1
         end
         else if pos('CONTROLLED', val2) > 0 then
            kwd = 'CONTROL'
         else if val2 = 'ON' | (p_en > 0 & (p_dis = 0 | p_dis > p_en)) then do
            kwd = 'ENABLED'
            flag_enabled = flag_enabled + 1
         end
         else
            kwd = val2u                                 /* normalized text */
      end

      when key = 'WDTCS' then do
         if pos('LOW',val2) > 0 then
            kwd = 'LOW_POWER'
         else
            kwd = 'STANDARD'
      end

      when key = 'WPEND' then do
         if pos('TO_WP',val2u) > 0 then
            kwd = 'P0_WPFP'
         else
            kwd = 'PWPFP_END'
      end

      when key = 'WPFP' then do
         kwd = 'P'word(val2, words(val2))                /* last word */
      end

      when key = 'WRT' then do
         if pos('DISABLED',val2) > 0 |,                 /* unprotected */
            pos('OFF',val2) > 0 then
            kwd = 'NO_PROTECTION'
         else if pos('ENABLED',val2) > 0 then           /* protected */
            kwd = 'ALL_PROTECTED'
         else if left(Val2,1) = '0' then do             /* memory range */
            parse var Val2 '0X'aa '-' '0X'zz .
            if zz = '' then do
               parse var Val2 aa'H' 'TO' zz'H' .
               if zz = '' then do
                  parse var Val2 aa 'TO' zz .
                  if zz = '' then do
                     parse var Val2 aa '-' zz .
                end
              end
            end
            kwd = 'R'right(strip(aa),4,'0')'_'right(strip(zz),4,'0')
         end
         else do
           kwd = val2u                                  /* normalized text */
         end
      end

      otherwise                                         /* generic formatting */
         if pos('ACTIVE',val2) > 0 then do
            if pos('HIGH',val2) > pos('ACTIVE',val2) then
               kwd = 'ACTIVE_HIGH'
            else if pos('LOW',val2) > pos('ACTIVE',val2) then
               kwd = 'ACTIVE_LOW'
            else do
               kwd = 'ENABLED'
               flag_enabled = flag_enabled + 1
            end
         end
         else if pos('ENABLE',val2) > 0 | val2 = 'ON' | val2 = 'ALL' then do
            kwd = 'ENABLED'
            flag_enabled = flag_enabled + 1
         end
         else if pos('DISABLE',val2) > 0 | val2 = 'OFF' then do
            kwd = 'DISABLED'
            flag_disabled = flag_disabled + 1
         end
         else if pos('ANALOG',val2) > 0 then
            kwd = 'ANALOG'
         else if pos('DIGITAL',val2) > 0 then
            kwd = 'DIGITAL'
         else do
            if left(val2u,1) >= '0' & left(val2u,1) <= '9' then do  /* starts with digit */
               if pos('HZ',val2u) > 0  then             /* probably frequency (range) */
                  kwd = 'F'val2u                        /* 'F' prefix */
               else if pos('_TO_',val2u) > 0  |,        /* probably a range */
                       pos('0_',val2u) > 0    |,
                       pos('_0',val2u) > 0  then
                  kwd = 'R'val2u                        /* 'R' prefix */
               else                                     /* probably a range */
                  kwd = 'N'val2u                        /* 'N' prefix */
            end
            else
               kwd = val2u
         end
   end

   if kwd.kwd = '-' then do                             /* unique (not duplicate) */
      kwd.kwd = kwd                                     /* remember keyword */
      if length(kwd) > 22 & msglevel <= 1 then
         say '  Info: fuse_def' key 'keyword excessively long: "'kwd'"'

      str = '       'kwd '= 0x'mask
      if length(str) < 40 then                          /* 'short' */
         str = left(str,40)                             /* alignment of comments */
      call lineout jalfile, str'   --' tolower(val2)
   end
   else do                                              /* duplicate kwd */
      if msglevel <= 2 then
         say '  Warning: Duplicate keyword for fuse_def' key':' kwd '('val2u')'
      if kwd = 'ENABLED' then
         flag_enabled = flag_enabled - 1                /* correction */
      else if kwd = 'DISABLED' then
         flag_disabled = flag_disabled - 1
   end

end

if flag_enabled \= flag_disabled then do                /* unbalanced */
   if msglevel <= 2 then
      say '  Warning: Possibly unbalanced enabled/disabled keywords for' key
end
return


/* ----------------------------------------------------------------------------- *
 * Generate functions w.r.t. analog modules.                                     *
 * First individual procedures for different analog modules,                     *
 * then a procedure to invoke these procedures.                                  *
 *                                                                               *
 * Possible combinations for the different PICS:                                 *
 * ANSEL   [ANSELH]                                                              *
 * ANSEL0  [ANSEL1]                                                              *
 * ANSELA   ANSELB [ANSELD  ANSELE]                                              *
 * ADCON0  [ADCON1 [ADCON2 [ADCON3]]]                                            *
 * ANCON0   ANCON1                                                               *
 * CMCON                                                                         *
 * CMCON0  [CMCON1]                                                              *
 * CM1CON0 [CM1CON1] [CM2CON0 CM2CON1]                                           *
 * Between brackets optional, otherwise always together.                         *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
 * PICs are classified in groups for ADC module settings.                        *
 * Below the register settings for all-digital I/O:                              *
 * ADC_V0   ADCON0 = 0b0000_0000 [ADCON1 = 0b0000_0000]                          *
 *          ANSEL0 = 0b0000_0000  ANSEL1 = 0b0000_0000  (or ANSEL_/H,A/B/D/E)    *
 * ADC_V1   ADCON0 = 0b0000_0000  ADCON1 = 0b0000_0111                           *
 * ADC_V2   ADCON0 = 0b0000_0000  ADCON1 = 0b0000_1111                           *
 * ADC_V3   ADCON0 = 0b0000_0000  ADCON1 = 0b0111_1111                           *
 * ADC_V4   ADCON0 = 0b0000_0000  ADCON1 = 0b0000_1111                           *
 * ADC_V5   ADCON0 = 0b0000_0000  ADCON1 = 0b0000_1111                           *
 * ADC_V6   ADCON0 = 0b0000_0000  ADCON1 = 0b0000_1111                           *
 * ADC_V7   ADCON0 = 0b0000_0000  ADCON1 = 0b0000_0000  ADCON2 = 0b0000_0000     *
 *          ANSEL0 = 0b0000_0000  ANSEL1 = 0b0000_0000                           *
 * ADC_V7_1 ADCON0 = 0b0000_0000  ADCON1 = 0b0000_0000  ADCON2 = 0b0000_0000     *
 *          ANSEL  = 0b0000_0000 [ANSELH = 0b0000_0000]                          *
 * ADC_V8   ADCON0 = 0b0000_0000  ADCON1 = 0b0000_0000  ADCON2 = 0b0000_0000     *
 *          ANSEL  = 0b0000_0000  ANSELH = 0b0000_0000                           *
 * ADC_V9   ADCON0 = 0b0000_0000  ADCON1 = 0b0000_0000                           *
 *          ANCON0 = 0b1111_1111  ANCON1 = 0b1111_1111                           *
 * ADC_V10  ADCON0 = 0b0000_0000  ADCON1 = 0b0000_0000                           *
 *          ANSEL  = 0b0000_0000  ANSELH = 0b0000_0000                           *
 * ADC_V11  ADCON0 = 0b0000_0000  ADCON1 = 0b0000_0000                           *
 *          ANCON0 = 0b1111_1111  ANCON1 = 0b1111_1111                           *
 * ADC_V12  ADCON0 = 0b0000_0000  ADCON1 = 0b0000_1111  ADCON2 = 0b0000_0000     *
 * ----------------------------------------------------------------------------- */
list_analog_functions: procedure expose jalfile Name. Core PicSpec. PinMap. PicName msglevel
PicNameCaps = toupper(PicName)

call lineout jalfile, '--'
call lineout jalfile, '-- ==================================================='
call lineout jalfile, '--'
call lineout jalfile, '-- Special (device specific) constants and procedures'
call lineout jalfile, '--'

if PicSpec.PicNameCaps.ADCgroup = '?' then do
   say PicName 'Error: No ADCgroup for' PicName 'in devicespecific.cmd!'
   exit 1
end
ADCgroup = PicSpec.PicNameCaps.ADCgroup

if  PinMap.PicNameCaps.ANCOUNT = '?' |,                  /* PIC not in pinmap.cmd? */
    ADCGroup = '0'  then                                /* PIC has no ADC module */
   PinMap.PicNameCaps.ANCOUNT = 0
call charout jalfile, 'const ADC_GROUP = 'ADCgroup
if ADCgroup = '0' then
   call lineout jalfile, '             -- no ADC module present'
else
   call lineout jalfile, ''
call lineout jalfile, 'const byte ADC_NTOTAL_CHANNEL =' PinMap.PicNameCaps.ANCOUNT
call lineout jalfile, '--'

if (ADCgroup = '0'  & PinMap.PicNameCaps.ANCOUNT > 0) |,
   (ADCgroup \= '0' & PinMap.PicNameCaps.ANCOUNT = 0) then do
   if msglevel <= 2 then
      say '  Warning: Possible conflict between ADC-group ('ADCgroup')',
          'and number of ADC channels ('PinMap.PicNameCaps.ANCOUNT')'
end
analog. = '-'                                           /* no analog modules */

if Name.ANSEL  \= '-' | Name.ANSEL1 \= '-' |,           /* check on presence */
   Name.ANSELA \= '-' | Name.ANCON0 \= '-'  then do
   analog.ANSEL = 'analog'                       /* analog functions present */
   call lineout jalfile, '-- - - - - - - - - - - - - - - - - - - - - - - - - - -'
   call lineout jalfile, '-- Change analog I/O pins into digital I/O pins.'
   call lineout jalfile, 'procedure analog_off() is'
   call lineout jalfile, '   pragma inline'
   if Name.ANSEL \= '-' then do                         /* ANSEL declared */
      call lineout jalfile, '   ANSEL  = 0b0000_0000       -- all digital'
      if Name.ANSELH \= '-' then
         call lineout jalfile, '   ANSELH = 0b0000_0000       -- all digital'
   end
   if Name.ANSEL0 \= '-' then do                        /* ANSEL0 declared */
      suffix = '0123456789'                             /* suffix numbers */
      do i = 1 to length(suffix)
         qname = 'ANSEL'substr(suffix,i,1)              /* qualified name */
         if Name.qname \= '-' then                      /* ANSELx declared */
            call lineout jalfile, '   'qname '= 0b0000_0000        -- all digital'
      end
   end
   if Name.ANSELA \= '-' then do                        /* ANSELA declared */
      suffix = XRANGE('A','Z')                          /* suffix letters A..Z */
      do i = 1 to length(suffix)
         qname = 'ANSEL'substr(suffix,i,1)              /* qualified name */
         if Name.qname \= '-' then                      /* ANSELx declared */
            call lineout jalfile, '   'qname '= 0b0000_0000        -- all digital'
      end
   end
   if Name.ANCON0 \= '-' then                           /* ANCON0 declared */
      call lineout jalfile, '   ANCON0 = 0b1111_1111        -- all digital'
   if Name.ANCON1 \= '-' then                           /* ANCON1 declared */
      call lineout jalfile, '   ANCON1 = 0b1111_1111        -- all digital'
   call lineout jalfile, 'end procedure'
   call lineout jalfile, '--'
end

if Name.ADCON0 \= '-' then do                           /* check on presence */
   analog.ADC = 'adc'                                   /* ADC module present */
   call lineout jalfile, '-- - - - - - - - - - - - - - - - - - - - - - - - - - -'
   call lineout jalfile, '-- Disable ADC module'
   call lineout jalfile, 'procedure adc_off() is'
   call lineout jalfile, '   pragma inline'
   call lineout jalfile, '   ADCON0 = 0b0000_0000         -- disable ADC'
   if Name.ADCON1 \= '-' then do                        /* ADCON1 declared */
      select
         when ADCgroup = 'ADC_V0' then
            call lineout jalfile, '   ADCON1 = 0b0000_0000'
         when ADCgroup = 'ADC_V1' then
            call lineout jalfile, '   ADCON1 = 0b0000_0111         -- digital I/O'
         when ADCgroup = 'ADC_V2'  |,
              ADCgroup = 'ADC_V4'  |,
              ADCgroup = 'ADC_V5'  |,
              ADCgroup = 'ADC_V6'  |,
              ADCgroup = 'ADC_V12' then
            call lineout jalfile, '   ADCON1 = 0b0000_1111         -- digital I/O'
         when ADCgroup = 'ADC_V3' then
            call lineout jalfile, '   ADCON1 = 0b0111_1111         -- digital I/O'
         otherwise                                      /* ADC_V7,7_1,8,9,10,11 */
            call lineout jalfile, '   ADCON1 = 0b0000_0000'
      end
      if Name.ADCON2 \= '-' then                        /* ADCON2 declared */
         call lineout jalfile, '   ADCON2 = 0b0000_0000'  /* all groups */
   end
   call lineout jalfile, 'end procedure'
   call lineout jalfile, '--'
end

if Name.CMCON   \= '-' | Name.CMCON0 \= '-' |,
   Name.CM1CON0 \= '-' | Name.CM1CON1 \= '-' then do
   analog.CMCON = 'comparator'                          /* Comparator present */
   call lineout jalfile, '-- - - - - - - - - - - - - - - - - - - - - - - - - - -'
   call lineout jalfile, '-- Disable comparator module'
   call lineout jalfile, 'procedure comparator_off() is'
   call lineout jalfile, '   pragma inline'
   select
      when Name.CMCON \= '-' then
         call lineout jalfile, '   CMCON  = 0b0000_0111        -- disable comparator'
      when Name.CMCON0 \= '-' then
         call lineout jalfile, '   CMCON0 = 0b0000_0111        -- disable comparator'
      when Name.CM1CON0 \= '-' then do
         call lineout jalfile, '   CM1CON0 = 0b0000_0000       -- disable comparator'
         if Name.CM2CON0 \= '-' then
            call lineout jalfile, '   CM2CON0 = 0b0000_0000       -- disable 2nd comparator'
      end
      when Name.CM1CON1 \= '-' then do
         call lineout jalfile, '   CM1CON1 = 0b0000_0000       -- disable comparator'
         if Name.CM2CON1 \= '-' then
            call lineout jalfile, '   CM2CON1 = 0b0000_0000       -- disable 2nd comparator'
      end
      otherwise                                         /* others */
         nop                                            /* can be ignored */
   end
   call lineout jalfile, 'end procedure'
   call lineout jalfile, '--'
end

call lineout jalfile, '-- - - - - - - - - - - - - - - - - - - - - - - - - - -'
call lineout jalfile, '-- Switch analog ports to digital mode (if analog module present).'
call lineout jalfile, 'procedure enable_digital_io() is'
call lineout jalfile, '   pragma inline'

if analog.ANSEL \= '-' then
   call lineout jalfile, '   analog_off()'
if analog.ADC \= '-' then
   call lineout jalfile, '   adc_off()'
if analog.CMCON \= '-' then
   call lineout jalfile, '   comparator_off()'

if core = 12 then do                                    /* baseline PIC */
   call lineout jalfile, '   OPTION_REG_T0CS = OFF        -- T0CKI pin input + output'
end
call lineout jalfile, 'end procedure'
return


/* --------------------------------------------- */
/* Signal duplicates names                       */
/* Collect all names in Name. compound variable  */
/* Return - 0 when name is unique                */
/*        - 1 when name is duplicate             */
/* --------------------------------------------- */
duplicate_name: procedure expose Name. PicName msglevel
newname = arg(1)
if newname = '' then                                    /* no name specified */
   return 1                                             /* not acceptable */
reg = arg(2)                                            /* register */
if Name.newname = '-' then do                           /* name not in use yet */
   Name.newname = reg                                   /* mark in use by which reg */
   return 0                                             /* unique */
end
if reg \= newname then do                               /* not alias of register */
   if msglevel <= 2 then
      Say '  Warning: Duplicate name:' newname 'in' reg'. First occurence:' Name.newname
   return 1                                             /* duplicate */
end


/* ---------------------------------------------- */
/* translate string to lower/upper case           */
/* ---------------------------------------------- */

tolower:
return translate(arg(1), xrange('a','z'), xrange('A','Z'))

toupper:
return translate(arg(1), xrange('A','Z'), xrange('a','z'))


/* --------------------------------------- */
/* Generate common header                  */
/* --------------------------------------- */
list_head:
call lineout jalfile, '-- ==================================================='
call lineout jalfile, '-- Title: JalV2 device include file for PIC' toupper(PicName)
call list_copyright_etc jalfile
call lineout jalfile, '-- Description:'
call lineout Jalfile, '--    Device include file for pic'PicName', containing:'
call lineout jalfile, '--    - Declaration of ports and pins of the chip.'
if core \= '16' then do                         /* for the baseline and midrange */
   call lineout jalfile, '--    - Procedures for shadowing of ports and pins'
   call lineout jalfile, '--      to circumvent the read-modify-write problem.'
end
else do                                         /* for the 18F series */
   call lineout jalfile, '--    - Procedures to force the use of the LATx register'
   call lineout jalfile, '--      when PORTx is addressed.'
end
call lineout jalfile, '--    - Symbolic definitions for configuration bits (fuses)'
call lineout jalfile, '--    - Some device dependent procedures for common'
call lineout jalfile, '--      operations, like:'
call lineout jalfile, '--      . enable_digital_io()'
call lineout jalfile, '--'
call lineout jalfile, '-- Sources:'
call lineout jalfile, '--  - "x:'substr(DevFile,3)'"'   /* dummy drive 'x' ! */
call lineout jalfile, '--  - "x:'substr(LkrFile,3)'"'
call lineout jalfile, '--'
call lineout jalfile, '-- Notes:'
call lineout jalfile, '--  - Created with Dev2Jal Rexx script version' ScriptVersion
call lineout jalfile, '--  - File creation date/time:' date('N') left(time('N'),5)
call lineout jalfile, '--'
call lineout jalfile, '-- ==================================================='
call lineout jalfile, '--'
call list_devID
PicNameCaps = toupper(PicName)
call lineout jalfile, 'const byte PICTYPE[]   = "'PicNameCaps'"'
DataSheet = PicSpec.PicNameCaps.DataSheet
if DataSheet = '?' then do
   say PicName 'Error: Datasheet not listed in devicespecific.cmd!'
   exit 1
end
call lineout jalfile, 'const byte DATASHEET[] = "'DataSheet'"'
PgmSpec = PicSpec.PicNameCaps.PgmSpec
if PgmSpec = '?' then do
   say PicName 'Error: PgmSpec not listed in devicespecific.cmd!'
   exit 1
end
call lineout jalfile, 'const byte PGMSPEC[]   = "'PgmSpec'"'
call lineout jalfile, '--'
call list_Vdd
call list_Vpp
call lineout jalfile, '--'
call lineout jalfile, '-- ---------------------------------------------------'
call lineout jalfile, '--'
call lineout jalfile, 'include chipdef_jallib                  -- common constants'
call lineout jalfile, '--'
call lineout jalfile, 'pragma  target  cpu   PIC_'Core '           -- (banks='Numbanks')'
call lineout jalfile, 'pragma  target  chip  'PicName
call lineout jalfile, 'pragma  target  bank  0x'D2X(BANKSIZE,4)
if core = '12' | core = '14' | core = '14H' then
  call lineout jalfile, 'pragma  target  page  0x'D2X(PAGESIZE,4)
call lineout jalfile, 'pragma  stack   'StackDepth
call list_code_size
call list_data_size
call list_ID_size
MaxUnsharedRAM = 0                                      /* no unshared RAM */
call list_unshared_data_range                           /* MaxUnsharedRam updated! */
MaxSharedRAM = 0                                        /* no shared RAM */
x = list_shared_data_range()                            /* returns range string */
/* - - - - - - - -  temporary? - - - - - - - - - - - - - - - - - */
if MaxSharedRam > 0  &  MaxUnsharedRAM = 0  then do     /* no unshared RAM */
   if msglevel <= 2 then do
      say '  Warning:' PicName 'has only shared, no unshared RAM!'
      say '            Must be handled as exceptional chip!'
   end
end
else if MaxSharedRAM = 0 then do                        /* no shared RAM */
   if msglevel <= 2 then do
     say '  Warning:' PicName 'has no shared RAM!'
     say '           Must be handled as exceptional chip!'
   end
end
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
call lineout jalfile, '--'
if Core = '12'  |  Core = '14' then do
   if PicName = '16f73'  | PicName = '16f74' then
      call lineout jalfile,,
         '_warn "Calculations with variables over 16 bits are not supported for a' PicName'"'
   call lineout jalfile, 'var volatile byte _pic_accum shared at',
                             '0x'D2X(MaxSharedRAM-1,2)'        -- (compiler)'
   call lineout jalfile, 'var volatile byte _pic_isr_w shared at',
                          '0x'D2X(MaxSharedRAM,2)'        -- (compiler)'
end
else if Core = '14H' then do
   if x \= '' then do                           /* with shared RAM */
      call lineout jalfile, 'var volatile byte _pic_accum shared at',
                            '0x'D2X(MaxSharedRAM,3)'   -- (compiler)'
   end
end
else if Core = '16' then do
   call lineout jalfile, 'var volatile byte _pic_accum shared at',
                         '0x'D2X(MaxSharedRAM-1)'   -- (compiler)'
   call lineout jalfile, 'var volatile byte _pic_isr_w shared at',
                         '0x'D2X(MaxSharedRAM)'   -- (compiler)'
end
call lineout jalfile, '--'
return


/* ------------------------------------------------- */
/* List common constants in ChipDef.Jal              */
/* input:  - nothing                                 */
/* ------------------------------------------------- */
list_chipdef_header:
call lineout chipdef, '-- =================================================================='
call lineout chipdef, '-- Title: Common JalV2 compiler include file'
call list_copyright_etc chipdef
call lineout chipdef, '-- Sources:'
call lineout chipdef, '--'
call lineout chipdef, '-- Description:'
call lineout chipdef, '--    Common JalV2 compiler include file'
call lineout chipdef, '--'
call lineout chipdef, '-- Notes:'
call lineout chipdef, '--    - Created with Dev2Jal Rexx script version' ScriptVersion
call lineout chipdef, '--    - File creation date/time:' date('N') left(time('N'),5)
call lineout chipdef, '--'
call lineout chipdef, '-- ---------------------------------------------------'
call lineout chipdef, 'const       PIC_12            = 1'
call lineout chipdef, 'const       PIC_14            = 2'
call lineout chipdef, 'const       PIC_16            = 3'
call lineout chipdef, 'const       SX_12             = 4'
call lineout chipdef, 'const       PIC_14H           = 5'
call lineout chipdef, '--'
call lineout chipdef, 'const bit   PJAL              = 1'
call lineout chipdef, '--'
call lineout chipdef, 'const byte  W                 = 0'
call lineout chipdef, 'const byte  F                 = 1'
call lineout chipdef, '--'
call lineout chipdef, 'const bit   TRUE              = 1'
call lineout chipdef, 'const bit   FALSE             = 0'
call lineout chipdef, 'const bit   HIGH              = TRUE'
call lineout chipdef, 'const bit   LOW               = FALSE'
call lineout chipdef, 'const bit   ON                = TRUE'
call lineout chipdef, 'const bit   OFF               = FALSE'
call lineout chipdef, 'const bit   ENABLED           = TRUE'
call lineout chipdef, 'const bit   DISABLED          = FALSE'
call lineout chipdef, 'const bit   INPUT             = TRUE'
call lineout chipdef, 'const bit   OUTPUT            = FALSE'
call lineout chipdef, 'const byte  ALL_INPUT         = 0b_1111_1111'
call lineout chipdef, 'const byte  ALL_OUTPUT        = 0b_0000_0000'
call lineout chipdef, '--'
call lineout chipdef, 'const       ADC_V0            = 0x_ADC_0'
call lineout chipdef, 'const       ADC_V1            = 0x_ADC_1'
call lineout chipdef, 'const       ADC_V2            = 0x_ADC_2'
call lineout chipdef, 'const       ADC_V3            = 0x_ADC_3'
call lineout chipdef, 'const       ADC_V4            = 0x_ADC_4'
call lineout chipdef, 'const       ADC_V5            = 0x_ADC_5'
call lineout chipdef, 'const       ADC_V6            = 0x_ADC_6'
call lineout chipdef, 'const       ADC_V7            = 0x_ADC_7'
call lineout chipdef, 'const       ADC_V7_1          = 0x_ADC_7_1'
call lineout chipdef, 'const       ADC_V8            = 0x_ADC_8'
call lineout chipdef, 'const       ADC_V9            = 0x_ADC_9'
call lineout chipdef, 'const       ADC_V10           = 0x_ADC_10'
call lineout chipdef, 'const       ADC_V11           = 0x_ADC_11'
call lineout chipdef, 'const       ADC_V12           = 0x_ADC_12'
call lineout chipdef, '--'
call lineout chipdef, '-- =================================================================='
call lineout chipdef, '--'
call lineout chipdef, '-- Values assigned to const "target_chip" by"'
call lineout chipdef, '--    "pragma target chip" in device files'
call lineout chipdef, '-- can be used for conditional compilation, for example:'
call lineout chipdef, '--    if (target_chip == PIC_16F88) then'
call lineout chipdef, '--      ....                                  -- for 16F88 only'
call lineout chipdef, '--    endif'
call lineout chipdef, '--'
return


/* ------------------------------------------------- */
/* Add copyright, etc to header in all created files */
/* input: filespec of destination file               */
/* returns: nothing                                  */
/* ------------------------------------------------- */
list_copyright_etc:
listfile = arg(1)                               /* destination filespec */
call lineout listfile, '--'
call lineout listfile, '-- Author:' ScriptAuthor', Copyright (c) 2008..2010,',
                       'all rights reserved.'
call lineout listfile, '--'
call lineout listfile, '-- Adapted-by:'
call lineout listfile, '--'
call lineout listfile, '-- Compiler:' CompilerVersion
call lineout listfile, '--'
call lineout listfile, '-- This file is part of jallib',
                       ' (http://jallib.googlecode.com)'
call lineout listfile, '-- Released under the ZLIB license',
                       '(http://www.opensource.org/licenses/zlib-license.html)'
call lineout listfile, '--'
return


/* ---------------------------------------------- */
/* some script debugging procedures               */
/* ---------------------------------------------- */

catch_error:
Say 'Rexx Execution error, rc' rc 'at script line' SIGL
return rc

catch_syntax:
if rc = 4 then                                  /* interrupted */
   exit
Say 'Rexx Syntax error, rc' rc 'at script line' SIGL":"
Say SourceLine(SIGL)
return rc

