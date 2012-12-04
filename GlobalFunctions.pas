unit GlobalFunctions;

{$MODE Delphi}

interface
  uses Forms, {Windows,} GlobalVariables, Controls, LCLIntf, BGRABitmap, BGRABitmapTypes, Graphics, Extctrls;

{-----------------------------------------------------------------------------------------------------------}
procedure delay(msecs:dword);
procedure fastdelay(msecs:real);
function IntegerWordToRGBColor(Value, min, max: word):TBGRAPixel;

function MicronsToProgressBar(Length: real): word;
procedure RespondToAxisKeyPress(var SetQ, SetQVoltage :real; var EditText: string; WhichAxis :Axis);
procedure GenerateScale(var ScaleImage: TImage; min, max: word);

function LeveledScanData(XData, YData: TScanData): TScanData;

implementation
  uses SysUtils, ScanTubeFunctions, SPM_Main;

{-------------------------------------------------------------------}
function LeveledScanData(XData, YData: TScanData): TScanData;
//function to subtract a linear component from the scandata in YData
  var
    j, NumbScanPoints: integer;
    SumX, SumX2, SumY, SumXY, Det, a, b: real;
    ReturnedData : TScanData;
begin
  NumbScanPoints:=Length(XData);
  SetLength(ReturnedData, NumbScanPoints);
  SumX:=0; SumX2:=0; SumY:=0; SumXY:=0;
  for j:=0 to NumbScanPoints-1 do
    begin
      SumX:=SumX + XData[j];
      SumX2:= SumX2 + XData[j]*XData[j];
      SumY:= SumY + YData[j];
      SumXY:= SumXY + YData[j]*XData[j];
    end;
  Det:=(NumbScanPoints*SumX2) -  SumX*SumX;
  a:=((SumX2*SumY)-(SumX*SumXY))/Det;
  b:=((NumbScanPoints*SumXY)-(SumY*SumX))/Det;
  for j:=0 to NumbScanPoints-1 do
     ReturnedData[j]:=YData[j]- a - b*Xdata[j];

  LeveledScanData:=ReturnedData;
end;
{-------------------------------------------------------------------------}
procedure delay(msecs:dword);
  var
    FirstTickCount:Dword;
  begin
    FirstTickCount:=GetTickCount;
    repeat
      Application.ProcessMessages; {allowing access to other
                                      controls, etc.}
    until ((GetTickCount-FirstTickCount) >= msecs);
  end;

{-----------------------------------------------------------------------}
procedure fastdelay(msecs: real);
  var
    OldTime :extended;
  begin
    with SPM_MainForm.FastTimer do
      begin
        Clear;
        Start;
        OldTime:=Elapsed;
        while ((Elapsed - OldTime)*1000)<msecs do
          Application.ProcessMessages;
        Stop;
      end;
  end;

{----------------------------------------------------------------------------}
 function MicronsToProgressBar(Length: real): word;
//Converts the number for the Z Voltage to an integer between 0 and 65535
var LimitedLength: real;
begin
  if Length>MaxZPosition then LimitedLength:=MaxZPosition
    else if Length<MinZPosition then LimitedLength:=MinZPosition
     else LimitedLength:=Length;
  MicronsToProgressBar:=trunc(((LimitedLength-MinZPosition)/(MaxZPosition-MinZPosition))*65535);
end;
{----------------------------------------------------------------------------}
procedure RespondToAxisKeyPress(var SetQ, SetQVoltage :real; var EditText: string; WhichAxis:Axis);
  begin
    SetQ:=StrToFloat(EditText);
    case WhichAxis of
      XAxis:
        begin
          if SetQ>CurrentX then //we will scan in the up direction
            begin
             if SetQ>ScanRanges[ScanRangeIndex].Range/2 then
               SetQ:=ScanRanges[ScanRangeIndex].Range/2;
             SetQVoltage:=MicronsToVoltageUpScan(SetQ, XAxis);
            end
           else if SetQ<CurrentX then //we will scan in the down direction
            begin
             if SetQ<(-ScanRanges[ScanRangeIndex].Range/2) then
               SetQ:=-(ScanRanges[ScanRangeIndex].Range/2);
               SetQVoltage:=MicronsToVoltageDownScan(SetQ, XAxis);
            end
        end;

      YAxis:
        begin
          if SetQ>CurrentY then //we will scan in the up direction
            begin
             if SetQ>ScanRanges[ScanRangeIndex].Range/2 then
               SetQ:=ScanRanges[ScanRangeIndex].Range/2;
             SetQVoltage:=MicronsToVoltageUpScan(SetQ, YAxis);
            end
           else if SetQ<CurrentX then //we will scan in the down direction
            begin
             if SetQ<(-ScanRanges[ScanRangeIndex].Range/2) then
               SetQ:=-(ScanRanges[ScanRangeIndex].Range/2);
               SetQVoltage:=MicronsToVoltageDownScan(SetQ, YAxis);
            end
        end;

      ZAxis:
        begin
          SetQVoltage:=MicronsToVoltageUpScan(SetQ,WhichAxis);
          if SetQVoltage>=MaxDAQVoltage then
            begin
              SetQVoltage:=MaxDAQVoltage;
              SetQ:=VoltageToMicronsUpScan(SetQVoltage, WhichAxis);
            end
           else if SetQVoltage<=MinDAQVoltage then
            begin
              SetQVoltage:=MinDAQVoltage;
              SetQ:=VoltageToMicronsUpScan(SetQVoltage, WhichAxis);
            end;
        end;
      end;
    EditText:=FloatToStrF(SetQ, ffFixed, 6, 3);
  end;

  function IntegerWordToRGBColor(Value, min, max: Word):TBGRAPixel;
 //generates an color scaled from min to max, i.e., min->max corresponds to the full
 //range of color
    var
      Temp : word;

    begin
      //peg the value at either minimum or maximum if necessary
      if Value>max then Value:=max;
      if Value<min then Value:=min;
      Temp:=round(((Value-min)/(max-min))*65535);
      IntegerWordToRGBColor.red:=Hi(Temp);
      IntegerWordToRGBColor.blue:=Lo(Temp);
      IntegerWordToRGBColor.green:=Hi(Temp);
      IntegerWordToRGBColor.alpha:=RGB_Alpha;
    end;
procedure GenerateScale(var ScaleImage: TImage; min, max: word);
  var
    ScaleImageBitMap: TBGRABitmap;
    TempColor : word;
    redcolor, bluecolor: byte;
    p         : PBGRAPixel;
    x, y      : integer;
begin
  //Now generate the indicator bar
  ScaleImageBitMap:=TBGRABitmap.Create(ScaleImage.Width, ScaleImage.Height, BGRABlack);
  for y:=0 to ScaleImage.Height -1 do
    begin
      p:=ScaleImageBitMap.Scanline[y];
      //we invert the scale, since y=0 is at the top
      TempColor:=round(((ScaleImage.Height-y)/ScaleImage.Height)*65535);
      redcolor:=Hi(TempColor);
      bluecolor:=Lo(TempColor);
      for x:=0 to ScaleImageBitmap.Width-1 do
        begin
          p^.red:=redcolor;
          p^.blue:=bluecolor;
          p^.green:=redcolor;
          p^.alpha:=255;
          inc(p);
        end;
    end;
  ScaleImageBitMap.InvalidateBitmap;
  ScaleImageBitMap.Draw(ScaleImage.Canvas, 0, 0, True);
  ScaleImageBitMap.Free;
end;

end.
