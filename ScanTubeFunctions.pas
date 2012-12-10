unit ScanTubeFunctions;

{$MODE Delphi}

interface
  uses GlobalVariables, BGRABitmap, BGRABitmapTypes;
  const
    MinZVoltageStep = 0.0005; //0.5 mV minimum step size

  function MicronsToVoltageUpScan(length : real; WhichAxis: Axis): real;
  function VoltageToMicronsUpScan(Voltage : real; WhichAxis: Axis): real;
  function MicronsToVoltageDownScan(length : real; WhichAxis: Axis): real;
  function VoltageToMicronsDownScan(Voltage : real; WhichAxis: Axis): real;
  procedure SetAxisVoltage(Voltage: real; WhichAxis: Axis);
  procedure SetDistance(ToPoint: real; WhichAxis: Axis);
  procedure RapidZVoltage(Voltage: real);
  procedure RapidZDistance(ToPoint: real);
  procedure MoveToX(ToPoint, StepSize, delay: real);
  procedure MoveToY(ToPoint, StepSize, delay: real);
  procedure MoveToZ(ToPoint, StepSize, delay: real);
  procedure MoveToZVoltage(SetVoltage, StepSize: real);
  function ZVoltageToMicrons(Voltage: real):real;
  function ZMicronsToVoltage(length: real): real;
  function XLineScan(ScanResolution: integer; StartPoint, Step: real;
                        SinglePointDwellTime, NumbAverages: integer): TScanData;
  function YLineScan(ScanResolution: integer; StartPoint, Step: real;
                        SinglePointDwellTime, NumbAverages: integer): TScanData;
  procedure GenerateLUT(RangeIndex: integer);
  function ZMicronsToRGBColor(Z: real; min, max: word): TBGRAPixel;



implementation
  uses DAQFunctions, GlobalFunctions, Forms, rtai_comedi_types, SysUtils, Oscilloscope, Graphics;

{------------------------------------------------------------------}
  function LinearInterpolation(XArray, YArray: InterpolationArray; XValue: real): real;
  {Given an function y=f(x) defined by the arrays XArray and YArray, and a point
    XValue, find the corresponding YValue using linear interpolation.
   It is assumed that the array XArray is sorted in either ascending order
   or descending order, i.e., the function f(x) is monotonic.}
   var
      ValueFound         : boolean;
      Lower, Upper, mid  : Integer;
      Slope              : real;
   begin
     ValueFound:=FALSE;
     //Initialize the indices
     Lower:=0;
     Upper:=LUTPoints-1; //dimension of the array is defined by LUTPoints
     LinearInterpolation:=0;
     if (XArray[Upper]>XArray[Lower]) then //XArray is sorted in ascending order
       begin
         if ((XValue<XArray[Lower]) or (XValue>XArray[Upper])) then
           Application.MessageBox(PChar('Interpolation value is out of range! Point 1'), 'Error!', 0)
          else
            begin
              while ((Upper-Lower)>1) do
                begin
                  mid:=(Upper + Lower) div 2;
                  if (XValue<=XArray[Upper]) then Upper:= mid else Lower:=mid;
                end;
              //Now Xvalue should be between XArray[Lower] and XArray[Upper]
              slope:=(YArray[Upper] - YArray[Lower])/(XArray[Upper]-XArray[Lower]);
              LinearInterpolation:=YArray[Lower] + slope*(XValue - XArray[Lower]);
            end;
       end
      else //the array is sorted in descending order
        begin
         if ((XValue>XArray[Lower]) or (XValue<XArray[Upper])) then
           Application.MessageBox(PChar('Interpolation value is out of range! Point 2'), 'Error!', 0)
          else
            begin
              while ((Upper-Lower)>1) do
                begin
                  mid:=(Upper + Lower) div 2;
                  if (XValue>=XArray[Upper]) then Upper:= mid else Lower:=mid;
                end;
              //Now Xvalue should be between XArray[Lower] and XArray[Upper]
              slope:=(YArray[Upper] - YArray[Lower])/(XArray[Upper]-XArray[Lower]);
              LinearInterpolation:=YArray[Lower] + slope*(XValue - XArray[Lower]);
            end;
        end;
   end;

{------------------------------------------------------------------}
  function MicronsToVoltageUpScan(Length : real; WhichAxis: Axis): real;
  begin
    case WhichAxis of
      XAxis: MicronsToVoltageUpScan:=LinearInterpolation(Xup,V, Length);
      YAxis: MicronsToVoltageUpScan:=LinearInterpolation(Yup,V, Length);
      //Note that we have a -1 in front of AmplifierGainSign, given our
      //definition that +Z means retraction, hence a negative voltage
      ZAxis: MicronsToVoltageUpScan:=-AmplifierGainSign*Length*ZAxisMicronsToVoltage;
    end;
  end;
{------------------------------------------------------------------------}
  function MicronsToVoltageDownScan(Length : real; WhichAxis: Axis): real;
  begin
    case WhichAxis of
      XAxis: MicronsToVoltageDownScan:=LinearInterpolation(XDown,V, Length);
      YAxis: MicronsToVoltageDownScan:=LinearInterpolation(YDown,V, Length);
      ZAxis: MicronsToVoltageDownScan:=-AmplifierGainSign*Length*ZAxisMicronsToVoltage;
    end;
  end;
{------------------------------------------------------------------}
  function VoltageToMicronsUpScan(Voltage : real; WhichAxis: Axis): real;
  begin
    case WhichAxis of
      XAxis:
          VoltageToMicronsUpScan:=UpScanXFactors[ScanRangeIndex].A + Voltage*UpScanXFactors[ScanRangeIndex].B
              + (Voltage*Voltage)*UpScanXFactors[ScanRangeIndex].C + (Voltage*Voltage*Voltage)*UpScanXFactors[ScanRangeIndex].D;

      YAxis:
          VoltageToMicronsUpScan:=UpScanYFactors[ScanRangeIndex].A + Voltage*UpScanYFactors[ScanRangeIndex].B
              + (Voltage*Voltage)*UpScanYFactors[ScanRangeIndex].C + (Voltage*Voltage*Voltage)*UpScanYFactors[ScanRangeIndex].D;

      ZAxis: VoltageToMicronsUpScan:=-(AmplifierGainSign*Voltage)/ZAxisMicronsToVoltage;
    end;
  end;
{-----------------------------------------------------------------}
  function VoltageToMicronsDownScan(Voltage : real; WhichAxis: Axis): real;
  begin
    case WhichAxis of
      XAxis:
          VoltageToMicronsDownScan:=DownScanXFactors[ScanRangeIndex].A + Voltage*DownScanXFactors[ScanRangeIndex].B
              + (Voltage*Voltage)*DownScanXFactors[ScanRangeIndex].C + (Voltage*Voltage*Voltage)*DownScanXFactors[ScanRangeIndex].D;

      YAxis:
          VoltageToMicronsDownScan:=DownScanYFactors[ScanRangeIndex].A + Voltage*DownScanYFactors[ScanRangeIndex].B
              + (Voltage*Voltage)*DownScanYFactors[ScanRangeIndex].C + (Voltage*Voltage*Voltage)*DownScanYFactors[ScanRangeIndex].D;

      ZAxis: VoltageToMicronsDownScan:=-(AmplifierGainSign*Voltage)/ZAxisMicronsToVoltage;
    end;
  end;
{-----------------------------------------------------------------}
  procedure SetAxisVoltage(Voltage: real; WhichAxis: Axis);
  begin
    case WhichAxis of
      XAxis: CurrentXVoltage:=Voltage;
      YAxis: CurrentYVoltage:=Voltage;
      ZAxis: CurrentZVoltage:=Voltage;
    end;
    WriteChannel(WhichAxis, double(Voltage));
  end;
{-----------------------------------------------------------------}
  procedure SetDistance(ToPoint: real; WhichAxis: Axis);
    var
      Voltage : real;
      Value   : real;
  begin
    Value:=ToPoint;
    case WhichAxis of
      XAxis:
        begin
          if ToPoint>CurrentX then
            begin
              if ToPoint>ScanRanges[ScanRangeIndex].Range/2 then
                    Value:=ScanRanges[ScanRangeIndex].Range/2;
              Voltage:=MicronsToVoltageUpScan(Value, XAxis);
            end
           else   //ToPoint<CurrentX
            begin
              if ToPoint<(-ScanRanges[ScanRangeIndex].Range/2) then
                    Value:=-ScanRanges[ScanRangeIndex].Range/2;
              Voltage:=MicronsToVoltageDownScan(Value, XAxis);
            end;
          CurrentX:=Value;
        end;

      YAxis:
        begin
          if ToPoint>CurrentY then
            begin
              if ToPoint>ScanRanges[ScanRangeIndex].Range/2 then
                    Value:=ScanRanges[ScanRangeIndex].Range/2;
              Voltage:=MicronsToVoltageUpScan(Value, YAxis);
            end
           else   //ToPoint<CurrentY
            begin
              if ToPoint<(-ScanRanges[ScanRangeIndex].Range/2) then
                    Value:=-ScanRanges[ScanRangeIndex].Range/2;
              Voltage:=MicronsToVoltageDownScan(Value, YAxis);
            end;
          CurrentY:=Value;
        end;

     ZAxis:
       begin
         if ToPoint>ZPiezoRange/2 then Value:=ZPiezoRange/2;
         if ToPoint<(-ZPiezoRange/2) then Value:=-ZPiezoRange/2;
         Voltage:=MicronsToVoltageUpScan(ToPoint, WhichAxis);
         CurrentZ:=ToPoint;
       end;

    end;

    SetAxisVoltage(Voltage, WhichAxis);
  end;
{-----------------------------------------------------------------}
  procedure RapidZVoltage(Voltage: real);
  begin
    WriteZChannel(double(Voltage));
    CurrentZVoltage:=Voltage;
  end;
{-----------------------------------------------------------------}
  procedure RapidZDistance(ToPoint: real);
    var
      Voltage : real;
  begin
      Voltage:=-ToPoint*ZAxisMicronsToVoltage*AmplifierGainSign;
      CurrentZ:=ToPoint;
      RapidZVoltage(Voltage);
  end;
{------------------------------------------------------------------}
  procedure MoveToX(ToPoint, StepSize, delay: real);
  var
     i, NumbSteps, Direction  : integer;
     TargetPoint,
     LengthStep               : real;
  begin
    //Determine the number of steps based on the Current X position
    if ToPoint>=CurrentX then
      Direction:=1  //positive steps
     else Direction:=-1;
    LengthStep:=Direction*StepSize;
    TargetPoint:=CurrentX;
    NumbSteps := round(abs((ToPoint-CurrentX)/StepSize));
    for i := 0 to NumbSteps-1 do
      begin
        TargetPoint:=TargetPoint+LengthStep;
        SetDistance(TargetPoint, XAxis);
        if delay>0 then fastdelay(delay);
      end;
  end;
{------------------------------------------------------------------}
  procedure MoveToY(ToPoint, StepSize, delay: real);
  var
     i, NumbSteps, Direction  : integer;
     TargetPoint,
     LengthStep                 : real;
  begin
    //Determine the number of steps based on the Current Y position
    if ToPoint>=CurrentY then
      Direction:=1  //positive steps
     else Direction:=-1;
    LengthStep:=Direction*StepSize;
    TargetPoint:=CurrentY;
    NumbSteps := round(abs((ToPoint-CurrentY)/StepSize));
    for i := 0 to NumbSteps-1 do
      begin
        TargetPoint:=TargetPoint+LengthStep;
        SetDistance(TargetPoint, YAxis);
        if delay>0 then fastdelay(delay);
      end;
  end;
{------------------------------------------------------------------}
  procedure MoveToZ(ToPoint, StepSize, delay: real);
  var
     i, NumbSteps, Direction  : integer;
     TargetPoint,
     LengthStep               : real;
  begin
    //Determine the number of steps based on the Current Z position
    if ToPoint>=CurrentZ then
      Direction:=1  //positive steps
     else Direction:=-1;
    LengthStep:=Direction*StepSize;
    TargetPoint:=CurrentZ;
    NumbSteps := round(abs((ToPoint-CurrentZ)/StepSize));
    for i := 0 to NumbSteps-1 do
      begin
        TargetPoint:=TargetPoint+LengthStep;
        SetDistance(TargetPoint, ZAxis);
        if delay>0 then fastdelay(delay);
      end;
  end;
{------------------------------------------------------------------}
  procedure MoveToZVoltage(SetVoltage, StepSize: real);
  var
     i, NumbSteps, Direction  : integer;
     SetVoltagePoint  : double;
     VoltageStep      : real;
  begin
    //Determine the number of steps based on the Current Z position
    if SetVoltage>=CurrentZVoltage then
      Direction:=1  //positive steps
     else Direction:=-1;
    NumbSteps := trunc(abs((SetVoltage-CurrentZVoltage)/StepSize));
    SetVoltagePoint:=CurrentZVoltage;
    VoltageStep:=StepSize*Direction;
    for i := 0 to NumbSteps-1 do
      begin
        SetVoltagePoint:=SetVoltagePoint+VoltageStep;
        SetAxisVoltage(SetVoltagePoint, ZAxis);
        CurrentZ:=ZVoltageToMicrons(CurrentZVoltage);
      end;
  end;
{------------------------------------------------------------------}
  function ZVoltageToMicrons(Voltage: real):real;
  begin
     ZVoltageToMicrons:=-(AmplifierGainSign*Voltage)/ZAxisMicronsToVoltage;
  end;
{------------------------------------------------------------------}
  function ZMicronsToVoltage(length: real): real;
    begin
        ZMicronsToVoltage:=-AmplifierGainSign*length*ZAxisMicronsToVoltage;
    end;
{-------------------------------------------------------------------}
  function XLineScan(ScanResolution: integer; StartPoint, Step: real;
                        SinglePointDwellTime, NumbAverages: integer): TScanData;
  var
      LineData : TScanData;
      i,j         : integer;
      XValue    : real;
      sum       : real;
  begin
    SetLength(LineData, ScanResolution);
    XValue:=StartPoint;
    for i := 0 to ScanResolution - 1 do
      begin
        MoveToX(XValue, StepX, 0);
        if InFeedback then
          begin
            fastdelay(SinglePointDwellTime);
            //while (PIDOutputVariance>1E-7) do Application.ProcessMessages;
            LineData[i]:=ZVoltageToMicrons(AveragedPIDOutput);
          end
         else
          begin
            fastdelay(SinglePointDwellTime*0.2);
            sum:=0;
            for j := 0 to NumbAverages - 1 do
                sum:=sum+CurrentZ;
            LineData[i]:=sum/NumbAverages;
          end;
          if Step>0 then
            OscilloscopeForm.OscilloscopeChartLineSeries1.AddXY(XValue,LineData[i], '',clRed) //color red, first layer, forward scan
           else
            OscilloscopeForm.OscilloscopeChartLineSeries2.AddXY(XValue,LineData[i], '',clBlue); //color blue, second layer, reverse scan
        XValue:=XValue+Step;
      end;
    XLineScan:=LineData;
  end;

{-------------------------------------------------------------------}
  function YLineScan(ScanResolution: integer; StartPoint, Step: real;
                        SinglePointDwellTime, NumbAverages: integer): TScanData;
  var
      LineData : TScanData;
      i,j         : integer;
      YValue    : real;
      sum       : real;
  begin
    SetLength(LineData, ScanResolution);
    YValue:=StartPoint;
    for i := 0 to ScanResolution - 1 do
      begin
        MoveToY(YValue, StepY, 0);
        if InFeedback then
          begin
            fastdelay(SinglePointDwellTime*0.8);
            LineData[i]:=ZVoltageToMicrons(AveragedPIDOutput);
          end
         else
          begin
            fastdelay(SinglePointDwellTime*0.2);
            sum:=0;
            for j := 0 to NumbAverages - 1 do
                sum:=sum+CurrentZ;
            LineData[i]:=sum/NumbAverages;
          end;
          if Step<0 then
            OscilloscopeForm.OscilloscopeChartLineSeries1.AddXY(YValue,LineData[i], '',clRed) //color red, first layer, downward scan
           else
            OscilloscopeForm.OscilloscopeChartLineSeries2.AddXY(YValue,LineData[i], '',clBlue); //color blue, second layer, upward scan
        YValue:=YValue+Step;
      end;
    YLineScan:=LineData;
  end;
{--------------------------------------------------------------------}
  procedure GenerateLUT(RangeIndex: integer);
  //procedure to generate a LUT of X and Y displacements vs voltage for the specified range
  var
    j: integer;
    VStep : real;
  begin
    //Generate the voltage array first
    if ((RangeIndex>=0) and (RangeIndex<=NumberOfScanRanges-1)) then
      begin
        Vstep := ScanRanges[RangeIndex].Voltage/LUTPoints;
        for j:=0 to LUTPoints-1 do
          begin
            V[j]:=-ScanRanges[RangeIndex].Voltage/2 + j*Vstep;
            Xup[j]:=UpScanXFactors[RangeIndex].A + V[j]*UpScanXFactors[RangeIndex].B
                 + V[j]*V[j]*UpScanXFactors[RangeIndex].C + V[j]*V[j]*V[j]*UpScanXFactors[RangeIndex].D;
            XDown[j]:=DownScanXFactors[RangeIndex].A + V[j]*DownScanXFactors[RangeIndex].B
                 + V[j]*V[j]*DownScanXFactors[RangeIndex].C + V[j]*V[j]*V[j]*DownScanXFactors[RangeIndex].D;
            Yup[j]:=UpScanYFactors[RangeIndex].A + V[j]*UpScanYFactors[RangeIndex].B
                 + V[j]*V[j]*UpScanYFactors[RangeIndex].C + V[j]*V[j]*V[j]*UpScanYFactors[RangeIndex].D;
            YDown[j]:=DownScanYFactors[RangeIndex].A + V[j]*DownScanYFactors[RangeIndex].B
                 + V[j]*V[j]*DownScanYFactors[RangeIndex].C + V[j]*V[j]*V[j]*DownScanYFactors[RangeIndex].D;
          end;
      end;
      //Now we need to make sure that the scan range does not exceed the range of the LUT
      //first for Xup
      if (ScanRanges[RangeIndex].Range/2)>Xup[LUTPoints-1] then ScanRanges[RangeIndex].Range:=2*Xup[LUTPoints-1];
      if (ScanRanges[RangeIndex].Range/2)>-Xup[0] then ScanRanges[RangeIndex].Range:=-2*Xup[0];

      //Now for Xdown
      if (ScanRanges[RangeIndex].Range/2)>XDown[LUTPoints-1] then ScanRanges[RangeIndex].Range:=2*XDown[LUTPoints-1];
      if (ScanRanges[RangeIndex].Range/2)>-XDown[0] then ScanRanges[RangeIndex].Range:=-2*XDown[0];

      //Yup
      if (ScanRanges[RangeIndex].Range/2)>Yup[LUTPoints-1] then ScanRanges[RangeIndex].Range:=2*Yup[LUTPoints-1];
      if (ScanRanges[RangeIndex].Range/2)>-Yup[0] then ScanRanges[RangeIndex].Range:=-2*Yup[0];

      //Ydown
      if (ScanRanges[RangeIndex].Range/2)>YDown[LUTPoints-1] then ScanRanges[RangeIndex].Range:=2*YDown[LUTPoints-1];
      if (ScanRanges[RangeIndex].Range/2)>-YDown[0] then ScanRanges[RangeIndex].Range:=-2*YDown[0];

  end;
  function ZMicronsToRGBColor(Z: real; min, max: word): TBGRAPixel;
  var
    Voltage: real;
    DAQOutput: Word;
    Intervalue:integer;
  begin
    //First convert to a voltage
    Voltage:=ZMicronsToVoltage(Z);
    //Then from voltage to a 16 bit unsigned number
    Intervalue:=round(((Voltage-MinDAQVoltage)/DAQVoltageRange)*65535);
    if Intervalue>65535 then
      DAQOutput:=65535
     else if Intervalue<0 then DAQOutput:=0
     else DAQOutput:=Intervalue;
    ZMicronsToRGBColor:=IntegerWordToRGBColor(DAQOutput, min, max);
  end;

end.
