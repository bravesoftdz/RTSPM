unit GraphicsRoutinesElectron;

interface
  uses SysUtils, WinProcs, Forms, Graphics, ETypes;
  
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
  Bitmap_x, Bitmap_y     : smallint;
  Scan_x_resolution, Scan_y_resolution : smallint;
  test_xshift : real =  0;
  test_yshift : real = 0;
  test_rot : real = 0;
  ImageBitMap,
  RotateBitMap,
  AdjustedBitMap,
  RasterBitMap,
  WritingBitMap              :TBitmap;
  ColorImage                : boolean = FALSE;
  Transparency_factor       : real = 0.3; //transparency factor for bitmap
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

{Global procedures and functions for the unit}
procedure Initialize_PictureBuffer;
procedure Initialize_Graphics;
procedure GDUtoVideoCoord(x,y: real; var Result:TPoint);
procedure MaptoVideoCoord(x,y: real; var Result:TPoint);
procedure MaptoSEMBitMapCoord(x,y: real; var Result: TPoint);
procedure SEMBitMapToMapCoord(xint, yint: Word; var x, y : real);
procedure MaptoGDUCoord(x,y: real; var Result:TPoint);
procedure VideoToMapCoord(xint, yint: Word; var x, y : real);
procedure MapToSEMCoord(x,y: real; var x_int, y_int: longint);
procedure SEMToMapCoord(x_int, y_int: longint; var x,y: real);
procedure SEMToVideoCoord(x_int, y_int: longint; var Result: TPoint);
procedure DefineGDUMapping(x1,y1,x2,y2:smallint);
procedure DefineScreen(x1,y1,x2,y2 :smallint; z1,t1,z2,t2:real);
procedure SEMToBitMapCoord(x_int, y_int:integer; var x_video, y_video: smallint);
procedure ReContrastImage(Min, Max: integer);
procedure FillBitMap;
procedure TransformBitMap(x_shift, y_shift, rotation: real);
procedure RotatePoints(var x, y: real);
procedure ShiftPoints(var x, y: real);
function  ColorToRGBTriple(const Color:  TColor):  TRGBTriple;
procedure SetImagingBitMapsResolution(x_res, y_res:  integer);
procedure MapToRasterBitMapCoord(x,y: real; var BitMapPoint: TPoint);
{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
{A note on coordinate systems:
  We have a number of different coordinate systems, which map onto the screen.
  For example, suppose we are working at a resolution of 640x480.  The default system
  in Borland Pascal maps the upper left as 0,0 and the lower right as 640,480, and
  all intrinsic Pascal graphing functions are written in this format (we call
  this the "Video" coordinates.  Scientifically,
  we prefer to have 0,0 on the lower left and 640, 480 on the upper right, and preferably,
  we should be able to control the upper right coordinates to something we like.
  The function [DefineGDUMapping] does this, in user defined Graphics Display Units.
  Next, we would like to define a user defined display area on the whole screen.  This
  is accomplished by the function [DefineScreen], which defines a usable screen in GDU units
  on the video monitor, and specifies a coordinate system (the Map coordinates) on this usable screen.
  The coordinates of all subsequent objects are specified with respect to this screen.
  This allows one to define a number of different screens on the same display, with different
  coordinate units...

  For example, suppose we have 640x480 monitor.  We issue a DefineGDUMapping with the parameters
  [0,0, 1125, 1175].  This now establishes a coordinate system, the Graphics Display Units, which
  have the origin at the lower left at [0,0] and the maximum at upper right at [1125,1175].  The
  function GDUtoVideoCoord converts between these GDU coordinates and the video coordinates
  that Pascal uses.  Now we issue a DefineScreen command with the parameters [100,100,1100,1100;
  0,0,100,100], which defines a rectangular screen at the GDU coordinates determined by the first
  four numbers, and a new coordinate system specified by the next four numbers which plots onto
  this the area of this user defined screen.  The function MaptoGDUCoord converts numbers in this
  new coordinate system into the GDU coordinate system, and the function MaptoVideoCoord converts
  points in this coordinate system directly into video units.  The coordinates of the graphical
  objects are all in these new screen units.}

implementation
 uses Dialogs, Classes, Histogram;
{-----------------------------------------------------------------------------------------------}
procedure DefineGDUMapping(x1,y1,x2,y2:smallint);
  begin
    GDULowerLeft.x:=x1;
    GDULowerLeft.y:=y1;
    GDUUpperRight.x:=x2;
    GDUUpperRight.y:=y2;
    X_GDU_Conversion:=MonitorWidth/(x2-x1);
    Y_GDU_Conversion:=MonitorHeight/(y2-y1);
  end;

{-------------------------------------------------------------------------}
procedure DefineScreen(x1,y1,x2,y2  :smallint;
                       z1,t1,z2,t2: real);
          {x1,y1,x2,y2 define screen in GDU
          coord....z1,t1,z2,t2 define mapping onto screen}
  begin
    ScreenLowerLeft.x:=x1;
    ScreenLowerLeft.y:=y1;
    ScreenUpperRight.x:=x2;
    ScreenUpperRight.y:=y2;
    MapLowerLeft.x:=round(z1);
    MapLowerLeft.y:=round(t1);
    MapUpperRight.x:=round(z2);
    MapUpperRight.y:=round(t2);
    ScreenWidth:=(x2-x1);
    ScreenHeight:=(y2-y1);
    X_MaptoGDU_Conversion:=ScreenWidth/(z2-z1);
    Y_MaptoGDU_Conversion:=ScreenHeight/(t2-t1);
  end;

{-------------------------------------------------------------------------}


procedure GDUtoVideoCoord(x,y: real; var Result:TPoint);
  {converts the coordinates into the mapping defined by the DefineGDUMapping procedure
   into screen coordinates.  The screen coordinates are defined with the origin
   on the top left, x increasing towards the right, and y increasing down, while
   map coordinates are defined as origin at the bottom left, and y increasing up}

   begin
     Result.x:=round((x-GDULowerLeft.x)*X_GDU_Conversion);
     Result.y:=MonitorHeight+MenuHeight-round((y-GDULowerLeft.y)*Y_GDU_Conversion);
   end;

{--------------------------------------------------------------------------}

procedure MaptoGDUCoord(x,y: real; var Result:TPoint);
  {converts the coordinates into the mapping defined by the DefineGDUMapping procedure
   into screen coordinates.  The screen coordinates are defined with the origin
   on the top left, x increasing towards the right, and y increasing down, while
   map coordinates are defined as origin at the bottom left, and y increasing up}

   begin
     Result.x:=round((x-MapLowerLeft.x)*X_MaptoGDU_Conversion)+ScreenLowerLeft.x;
     Result.y:=(round((y-MapLowerLeft.y)*Y_MaptoGDU_Conversion)+ScreenLowerLeft.y);
   end;

{--------------------------------------------------------------------------}

procedure MaptoVideoCoord(x,y: real; var Result:TPoint);
  {converts the coordinates into the mapping defined by the DefineGDUMapping procedure
   into screen coordinates.  The screen coordinates are defined with the origin
   on the top left, x increasing towards the right, and y increasing down, while
   map coordinates are defined as origin at the bottom left, and y increasing up}
   var
     IntermediatePoint    : TPoint;
   begin
     MaptoGDUCoord(x,y,IntermediatePoint);
     GDUtoVideoCoord(IntermediatePoint.x, IntermediatePoint.y, Result);
     Result.x:=Result.x-XScrollPos; Result.y:=Result.y-YScrollPos;
   end;
{--------------------------------------------------------------------------}

procedure VideoToMapCoord(xint, yint: Word; var x, y : real);
{ converts the screen coordinates xint and yint to Map coordinates x and y}

var
  xm, ym : real;

begin
  xint:=xint+XScrollPos; yint:=yint+YScrollPos;
  xm := (xint/X_GDU_Conversion) + GDULowerLeft.x;
  ym := ((MonitorHeight + MenuHeight - yint)/Y_GDU_Conversion) +
                                                        GDULowerLeft.y;
  x := ((xm - ScreenLowerLeft.x)/X_MaptoGDU_Conversion) + MapLowerLeft.x;
  y := ((ym - ScreenLowerLeft.y)/Y_MaptoGDU_Conversion) + MapLowerLeft.y;
end;

{------------------------------------------------------------------------}
procedure MapToSEMCoord(x,y: real; var x_int, y_int: longint);
{Converts the map, i.e., real, coordinates into integers to be fed to the DA card}
begin
   x_int:= round(((x_channel_sign*x)/Field_of_View)*MaxBits_LessOne-0.5);
   y_int:= round(((y_channel_sign*y)/(Field_of_View*Aspect_Ratio))*MaxBits_LessOne-0.5);
end;
{------------------------------------------------------------------------}
procedure SEMToMapCoord(x_int, y_int: longint; var x,y: real);
begin
 x:= ((x_channel_sign*x_int)/MaxBits_LessOne)*Field_of_View;
 y:= ((y_channel_sign*y_int)/MaxBits_LessOne)*Field_of_View*Aspect_Ratio;
end;
{------------------------------------------------------------------------}
procedure SEMToVideoCoord(x_int, y_int: longint; var Result: TPoint);
var
  x, y : real;
begin
   SEMToMapCoord(x_int, y_int, x, y);
   MapToVideoCoord(x,y, Result);
end;
{-------------------------------------------------------------------------}
procedure MapToRasterBitMapCoord(x,y : real; var BitMapPoint: TPoint);
begin
  {Converts Map (i.e., micron) coordinates into a bit map coordinates, where
  the full field of view corresponds to Scan_x_resolution x Scan_y_resolution}
  BitMapPoint.x:= round((x/Field_of_view)*Scan_x_resolution + (Scan_x_resolution/2));
  BitMapPoint.y:= Scan_y_resolution - round((y/Field_of_view*Aspect_ratio)*Scan_y_resolution + (Scan_y_resolution/2))
end;
{--------------------------------------------------------------------------}
procedure SEMToBitMapCoord(x_int, y_int:integer; var x_video, y_video: smallint);
begin
  {Converts SEM integers to Video integers}
  x_video:= round((Low_Bits+x_channel_sign*x_int)/x_scan_div);
  y_video:=Bitmap_y-round((Low_Bits+y_channel_sign*y_int)/y_scan_div);
end;
{------------------------------------------------------------------------------}
procedure MaptoSEMBitMapCoord(x,y: real; var Result: TPoint);
begin
  Result.x:=round((x+(Field_of_View/2))/Min_exposure_width);
  Result.y:=round((Field_of_View*Aspect_Ratio)/Min_Exposure_width -
              (y+(Field_of_view*Aspect_ratio/2))/Min_Exposure_width);
end;
{------------------------------------------------------------------------------}
procedure SEMBitMapToMapCoord(xint, yint: Word; var x, y : real);
begin
  x:=xint*Min_exposure_width - (Field_of_View/2);
  y:=(Field_of_View*Aspect_Ratio)/2- yint*Min_exposure_width;
end;
{------------------------------------------------------------------------------}
procedure Initialize_PictureBuffer;

var
  x, y : integer;
  P    : PWordArray;
  S    : PRGBTripleArray;

  //format of 16 bit color is rrrrr gggggg bbbbb
  //for format of 24 bit color, we use the TRGBTripleArray format
  //i.e., five bits of red and blue each, and six bits of green

begin
  {Initialize the bitmap color to black}
  if ColorImage then
    begin
      ImageBitMap.PixelFormat:=pf16bit;
      RotateBitMap.PixelFormat:=pf16bit;
      AdjustedBitMap.PixelFormat:=pf16bit;
      for y := 0 to ImageBitMap.Height-1 do
        begin
          P := ImageBitMap.ScanLine[y];
          for x := 0 to ImageBitMap.Width -1 do
              P[x] := FillColor;
          P := RotateBitMap.ScanLine[y];
          for x := 0 to RotateBitMap.Width -1 do
              P[x] := FillColor;
          P := AdjustedBitMap.ScanLine[y];
          for x := 0 to AdjustedBitMap.Width -1 do
              P[x] := FillColor;
        end;
    end
   else
    begin
      ImageBitMap.PixelFormat:=pf24bit;
      RotateBitMap.PixelFormat:=pf24bit;
      AdjustedBitMap.PixelFormat:=pf24bit;
      for y := 0 to ImageBitMap.Height-1 do
        begin
          S := ImageBitMap.ScanLine[y];
          for x := 0 to ImageBitMap.Width -1 do
            with S[x] do
              begin
                RGBtBlue:=FillColor;
                RGBtGreen:=FillColor;
                RGBtRed:=FillColor;
              end;
          S := RotateBitMap.ScanLine[y];
          for x := 0 to RotateBitMap.Width -1 do
            with S[x] do
              begin
                RGBtBlue:=FillColor;
                RGBtGreen:=FillColor;
                RGBtRed:=FillColor;
              end;
          S := AdjustedBitMap.ScanLine[y];
          for x := 0 to AdjustedBitMap.Width -1 do
            with S[x] do
              begin
                RGBtBlue:=FillColor;
                RGBtGreen:=FillColor;
                RGBtRed:=FillColor;
              end;
        end;
    end;
  PictureBufferCount:=0;
 end;


{--------------------------------------------------------------------------}
procedure Initialize_Graphics;
var
  Screen_Height,
  Screen_Width,
  Half_width_y,
  Half_width_x,
  x_cent,
  y_cent
                   :smallint;
begin
  Screen_Height := MonitorHeight;
  Screen_Width  := MonitorWidth;
  Half_Width_y := Screen_Height div 2;
  Half_Width_x := Screen_Width div 2;
  x_cent := MonitorWidth div 2; y_cent := (MonitorHeight div 2);
  DefineScreen(x_cent-Half_Width_x, y_cent-Half_Width_y, x_cent+Half_Width_x,
                y_cent+Half_Width_y, -20,-15,20,15);
  Bitmap_x:=round(768/Aspect_Ratio); Bitmap_y:=768;
  if Screen.Width<1024 then
    begin
      Bitmap_x:=round(600/Aspect_Ratio);
      Bitmap_y:=600;
    end;
  if Screen.Width<800 then
    begin
      Bitmap_x:=round(480/Aspect_Ratio);
      Bitmap_y:=480;
    end;
  SetImagingBitMapsResolution(Bitmap_x, Bitmap_y);
  {x_scan_div:=   Expose_resolution/Bitmap_x;
  y_scan_div:=   Expose_resolution/Bitmap_y;}
end;
{--------------------------------------------------------------------}
procedure ReContrastImage(Min, Max: integer);
//Max and min are the new threshold values
var
  i, j    : integer;
  MultFactor, AddFactor             : real;
  P                                 : PWordArray;
  Q                                 : PRGBTripleArray;

begin
  MultFactor:= (Max-Min)/(MaxThresholdValue-MinThresholdValue);
  AddFactor:=Max - MultFactor*MaxThresholdValue;
  MaxThresholdValue:=round(MultFactor*MaxThresholdValue + AddFactor);
  MinThresholdValue:=round(MultFactor*MinThresholdValue + AddFactor);

  if ColorImage then
    begin
      for i:=0 to RotateBitMap.Height-1 do
        begin
          P:=RotateBitMap.ScanLine[i];
          for j:=0 to RotateBitMap.Width-1 do
            if P[j]<>FillColor then
                P[j]:=Word(round(MultFactor*P[j] + AddFactor));
        end; //for i
    end //for if Colorimage
   else
    begin
      for i:=0 to RotateBitMap.Height-1 do
        begin
          Q:=RotateBitMap.ScanLine[i];
          for j:=0 to RotateBitMap.Width-1 do
            with Q[j] do
              begin //just check one color, since they are all the same
                if rgbtBlue<>FillColor then
                  begin
                    rgbtBlue:=Byte(round(MultFactor*rgbtBlue + AddFactor));
                    rgbtGreen:=rgbtBlue;
                    rgbtRed:=rgbtBlue;
                  end; //if rgbtBlue
              end; //with Q[j]
        end; //for i
    end;//else statement
end;

{--------------------------------------------------------------------}
procedure FillBitMap;
  var
    NumbUpdates,
    j,
    y_point, x_point, y_old                           : integer;
    P: PWordArray;
    Q: PRGBTripleArray;
    CopyRegion, FullRect   : TRect;
    integerColor       : integer; //integer version of color


 begin
   MaxThresholdValue:=0;
   if ColorImage then
     begin
       BitDepth:=65535;
       {MinThresholdValue:=BitDepth;}
       {y_old is the current point being read}
       y_old:=PictureCoords[1]; //second line of coordinate array
       P:=ImageBitMap.ScanLine[y_old];
       //Pprime:=RotateBitMap.ScanLine[y_old];
       NumbUpdates:=TotCount div 2;
       for j:=0 to NumbUpdates-1 do
         begin
           y_point:=PictureCoords[2*j+1];
           if y_point<>y_old then
             begin
               y_old:=y_point;
               P:=ImageBitMap.ScanLine[y_old];
               //Pprime:=RotateBitMap.ScanLine[y_old];
             end;
           x_point:=PictureCoords[2*j];
           IntegerColor:=Max_bits-Low_bits-InputBuffer[j];
           //Invert the image (subtract from BitDepth) to avoid getting a negative
           if NumbScans=1 then
               P[x_point]:=Word(IntegerColor)
            else
            //average the scans
             P[x_point]:=
                round((Word(IntegerColor) + (NumbScans-1)*P[x_point])/NumbScans);
           //Pprime[x_point]:=P[x_point];
           {if P[x_point]>MaxThresholdValue then MaxThresholdValue:=P[x_point];
           if P[x_point]<MinThresholdValue then MinThresholdValue:=P[x_point];}
       end;
     end
    else ///Black and white in pf24bit
     begin
       BitDepth:=255;
       {MinThresholdValue:=BitDepth;}
       {y_old is the current point being read}
        y_old:=PictureCoords[1]; //second line of coordinate array
        Q:=ImageBitMap.ScanLine[y_old];
        //Qprime:=RotateBitMap.ScanLine[y_old];
        NumbUpdates:=TotCount div 2;
        for j:=0 to NumbUpdates-1 do
          begin
            y_point:=PictureCoords[2*j+1];
            if y_point<>y_old then
              begin
                y_old:=y_point;
                Q:=ImageBitMap.ScanLine[y_old];
                //Qprime:=RotateBitMap.ScanLine[y_old];
              end;
            x_point:=PictureCoords[2*j];
            IntegerColor:=Max_bits-Low_bits-InputBuffer[j];
            with Q[x_point] do
              begin
                if NumbScans=1 then rgbtBlue:=Hi(Word(IntegerColor))
                  else rgbtBlue:= round((Hi(Word(IntegerColor)) +
                                   (NumbScans-1)*rgbtBlue)/NumbScans);
                rgbtGreen:=rgbtBlue;
                rgbtRed:=rgbtBlue;
                {if rgbtBlue>MaxThresholdValue then MaxThresholdValue:=rgbtBlue;
                if rgbtBlue<MinThresholdValue then MinThresholdValue:=rgbtBlue;}
              end;
            //Qprime[x_point]:=Q[x_point];
        end;
     end;
  FullRect:=Rect(0,0,ImageBitMap.Width-1, ImageBitMap.Height-1);
{  CopyRegion:=Rect(0,0,ImageBitMap.Width-1, Trunc(ImageBitMap.Width*Aspect_Ratio)-1);}
  CopyRegion:=Rect(0,0,ImageBitMap.Width-1, ImageBitMap.Height-1);
  RotateBitMap.Canvas.CopyRect(CopyRegion, ImageBitMap.Canvas, FullRect);
  AdjustedBitMap.Canvas.CopyRect(CopyRegion, ImageBitMap.Canvas, FullRect);
end;

{------------------------------------------------------------------------}
procedure RotatePoints(var x, y : real);
var
  x_old             : real;

begin
  x_old:=x;
  x:=x_old*cos_rot - y*sin_rot;
  y:=x_old*sin_rot + y*cos_rot;
end;
{-----------------------------------------------------------------------}
procedure ShiftPoints(var x, y : real);
begin
  x:=x+x_shift+x_0;
  y:=y+y_shift+y_0;
end;
{-----------------------------------------------------------------------}
procedure TransformBitMap(x_shift, y_shift, rotation: real);
var
   x_int, y_int, i, j              :integer;
   P,Q                               :PWordArray;
   S, T                              :PRGBTripleArray;
   x_int_shift, y_int_shift        :integer;
   rot_cos, rot_sin                :real;
   PicturePoints                   : integer;
   x_mid, y_mid                    : integer;
   CopyRegion, FullRect                        : TRect;

begin
  x_int_shift:=round((x_shift/Field_of_View)*Scan_x_resolution);
  y_int_shift:=-round((y_shift/(Field_of_View*Aspect_Ratio))*Scan_y_resolution);
  {used to be
  x_int_shift:=round((x_shift/Field_of_View)*BitMap_x);
  y_int_shift:=-round((y_shift/(Field_of_View*Aspect_Ratio))*BitMap_y);}
  rot_cos:=cos(TwoPi*(rotation/360));
  rot_sin:=-sin(TwoPi*(rotation/360));
  PicturePoints:=(TotCount div 2)-1;
  x_mid:=Scan_x_resolution div 2;
  y_mid:=Scan_y_resolution div 2;
  {used to be
  x_mid:=BitMap_x div 2;
  y_mid:=BitMap_y div 2;}


  if ColorImage then
    begin
      RotateBitMap.PixelFormat:=pf16bit;
      {Initialize RotateBitMap}
      for i:=0 to Scan_y_resolution-1 do
      {used to be
      for i:=0 to Bitmap_y-1 do}
        begin
          P:=RotateBitMap.ScanLine[i];
          for j:=0 to Scan_x_resolution-1 do
          {Used to be
          for j:=0 to BitMap_x-1 do}
            P[j]:=FillColor;
        end;

      AdjustedBitMap.PixelFormat:=pf16bit;
      for i:=0 to PicturePoints-1 do
        begin
          x_int:=round((PictureCoords[2*i]-x_mid)*rot_cos -
                      (PictureCoords[2*i+1]-y_mid)*rot_sin) +x_int_shift+x_mid;
          y_int:=round((PictureCoords[2*i]-x_mid)*rot_sin +
                       (PictureCoords[2*i+1]-y_mid)*rot_cos)+y_int_shift+y_mid;
          if (x_int>=0) and (x_int<Scan_x_resolution) and (y_int>=0) and (y_int<Scan_y_resolution) then
          {used to be
          if (x_int>=0) and (x_int<BitMap_x) and (y_int>=0) and (y_int<BitMap_y) then}
            begin
              P:=ImageBitMap.ScanLine[PictureCoords[2*i+1]];
              Q:=RotateBitMap.ScanLine[y_int];
              Q[x_int]:=P[PictureCoords[2*i]];
            end;
        end;
    end
   else
    begin
      RotateBitMap.PixelFormat:=pf24bit;
      {Initialize RotateBitMap}
      for i:=0 to Scan_y_resolution-1 do
      {Used to be
      for i:=0 to Bitmap_y-1 do}
        begin
          S:=RotateBitMap.ScanLine[i];
          for j:=0 to Scan_x_resolution-1 do
          {Used to be
          for j:=0 to BitMap_x-1 do}
            begin
              S[j].rgbtBlue:=FillColor;
              S[j].rgbtRed:=FillColor;
              S[j].rgbtGreen:=FillColor;
            end;
        end;
      AdjustedBitMap.PixelFormat:=pf24bit;
      for i:=0 to PicturePoints-1 do
        begin
          x_int:=round((PictureCoords[2*i]-x_mid)*rot_cos -
                       (PictureCoords[2*i+1]-y_mid)*rot_sin) +x_int_shift+x_mid;
          y_int:=round((PictureCoords[2*i]-x_mid)*rot_sin +
                       (PictureCoords[2*i+1]-y_mid)*rot_cos) +y_int_shift+y_mid;
          if (x_int>=0) and (x_int<Scan_x_resolution) and (y_int>=0) and (y_int<Scan_y_resolution) then
          {used to be
          if (x_int>=0) and (x_int<BitMap_x) and (y_int>=0) and (y_int<BitMap_y) then}
            begin
              S:=ImageBitMap.ScanLine[PictureCoords[2*i+1]];
              T:=RotateBitMap.ScanLine[y_int];
              T[x_int]:=S[PictureCoords[2*i]];
            end;
        end;
    end;
   FullRect:=Rect(0,0,RotateBitmap.Width-1, RotateBitMap.Height-1);
   {CopyRegion:=Rect(0,0,ImageBitMap.Width-1, Trunc(ImageBitMap.Width*Aspect_Ratio)-1);}
   CopyRegion:=Rect(0,0,ImageBitMap.Width-1, ImageBitMap.Height-1);
   AdjustedBitMap.Canvas.CopyRect(CopyRegion, RotateBitMap.Canvas, FullRect);
   if ImageHistogram.AutoContrastCheck.Checked=TRUE then
                                ImageHistogram.AutoContrastImage;
  {if ImageHistogram.ImageChanged then
    begin
      ImageHistogram.AdjustImageContrast;
      ImageHistogram.AdjustImageBrightness;
    end;}
end;

{--------------------------------------------------------------------}
function  ColorToRGBTriple(const Color:  TColor):  TRGBTriple;
begin
  with RESULT do
  begin
    rgbtRed   := GetRValue(Color);
    rgbtGreen := GetGValue(Color);
    rgbtBlue  := GetBValue(Color)
  end
end; {ColorToRGBTriple}

{----------------------------------------------------------------------}
procedure SetImagingBitMapsResolution(x_res, y_res:  integer);
  begin
    x_scan_div:=Expose_resolution/x_res;
    y_scan_div:=Expose_resolution/y_res;
    Scan_x_resolution:=x_res;
    Scan_y_resolution:=y_res;
    ImageBitmap.Width:=x_res;
    ImageBitmap.Height:=y_res;
    RotateBitMap.Width:=x_res;
    RotateBitMap.Height:=y_res;
    AdjustedBitMap.Width:=x_res;
    AdjustedBitMap.Height:=y_res;
  end;
{--------------------------------------------------------------------}

initialization
      MonitorHeight := Screen.Height -GetSystemMetrics(sm_CYMenu);
      MonitorWidth  := Screen.Width;
      DefineGDUMapping(0, 0, MonitorWidth, MonitorHeight);
      ImageBitMap:=TBitMap.Create;
      ImageBitMap.PixelFormat:=pf24bit; //16 bit image: 16 bit is the resolution of the A/Ds
      RotateBitMap:=TBitMap.Create;
      RotateBitMap.PixelFormat:=pf24bit; //16 bit image: 16 bit is the resolution of the A/Ds
      AdjustedBitMap:=TBitMap.Create;
      AdjustedBitMap.PixelFormat:=pf24bit; //16 bit image: 16 bit is the resolution of the A/Ds      BitDepth:=255;
      MaxThresholdRange := round(BitDepth*0.95);
      MinThresholdRange := round(BitDepth*0.05);
      RasterBitMap:= TBitMap.Create;
      WritingBitMap:=TBitMap.Create;
      Initialize_Graphics;
      Initialize_PictureBuffer;

finalization
      ImageBitMap.Free;
      RotateBitMap.Free;
      AdjustedBitMap.Free;
      RasterBitMap.Free;
      WritingBitMap.Free;
end.
