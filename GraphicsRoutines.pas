unit GraphicsRoutines;

{$MODE Delphi}

interface
uses SysUtils, {WinProcs,} Forms, Graphics, LCLType, Types;

const
  {Define some colours}
  black  = clblack;
  white  = clwhite;
  red    = clred;
  green  = clgreen;
  blue   = clblue;
  gray   = clgray;
  yellow = clyellow;
  teal   = clteal;
  purple = clpurple;
  lime   = cllime;
  aqua   = claqua;
  fuchsia= clfuchsia;
  navy   = clnavy;
  silver = clsilver;
  olive  = clolive;
  maroon = clmaroon;
  AlignColor = black;
  FillColor  = 0;  {black initial background for the bitmap}
  RGBBlack : TRGBTriple=(rgbtBlue : 0; rgbtGreen : 0; rgbtRed : 0);
  RGBRed   : TRGBTriple=(rgbtBlue : 0; rgbtGreen : 0; rgbtRed : 255);

const
  PixelCountMax = 2048;

type
  pRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = ARRAY[0..PixelCountMax-1] OF TRGBTriple;

var
{x_scan_div and y_scan_div are the divisions for
scanning in x and y directions when taking a picture.
Bitmap_x and Bitmap_y are the x and y dimensions of ImageBitMap}
  x_scan_div, y_scan_div  : real;
  Bitmap_x, Bitmap_y      : smallint;
  ScanXresolution       : smallint = 512;
  ScanYresolution       : smallint = 512;
  ColorImage                : boolean = FALSE;
  BitDepth   : integer = 65535; //16 bit resolution on the bitmaps
  MaxThresholdRange :integer;
  MinThresholdRange :integer;

  {Global Graphing parameters for the window}
  MonitorWidth, MonitorHeight, ScreenWidth, ScreenHeight, MenuHeight: smallint;
  GDULowerLeft, GDUUpperRight, ScreenLowerLeft, ScreenUpperRight,
  MapLowerLeft, MapUpperRight: TPoint;
  X_GDU_Conversion, Y_GDU_Conversion,
  X_MaptoGDU_Conversion, Y_MaptoGDU_Conversion,
  GDUtoScreen : real;
  XScrollPos, YScrollPos  : integer;
  MinThresholdValue, MaxThresholdValue,
  MedianValue, OldMedianValue         : Word; //min max bitmap thresholds

  procedure InitializeBitMap(SomeBitMap: TBitMap);

  implementation

{----------------------------------------------------------------------------}
  procedure InitializeBitMap(SomeBitMap: TBitMap);
  var
  x, y : integer;
  S    : PRGBTripleArray;

  //for format of 24 bit color, we use the TRGBTripleArray format
  //i.e., five bits of red and blue each, and six bits of green

  begin
    {SomeBitMap.PixelFormat:=pf24bit;
    for y := 0 to SomeBitMap.Height-1 do
      begin
        S := SomeBitMap.ScanLine[y];
        for x := 0 to SomeBitMap.Width -1 do
          with S[x] do
            begin
              RGBtBlue:=FillColor;
              RGBtGreen:=FillColor;
              RGBtRed:=FillColor;
            end;
      end;}
  end;


end.
