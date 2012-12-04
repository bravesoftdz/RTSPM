unit ScanTubeFunctionsOld;

interface

  uses
    Forms, GlobalVariables;
  const
    Board_resolution = 65535; //bit resolution of board
    Half_resolution  = 32767;
    ZStepSize        = 32;
    XYStepSize      = 64;
    LargeStepSize   = 512;
    SingleStepSize  = 1;
    Z_control_channel = 0; //analog channel to control the Z piezo
    x_control_channel = 1; //analog channel to control the x scan tube
    y_control_channel = 0; //analog channel to controlt the y scan tube

  var
    StepSize          : integer = 32;
    ScanStepSize      : integer = 1;

  function MoveZ(Z, step: integer): boolean;
  function Tip_GoTo(var x, y : integer; step : integer): boolean;
  function Continuous_feedback(Sender: TObject): boolean;
  function Single_feedback: boolean;
  function Tip_GoTo_WithFeedback(var x, y : integer; step : integer): boolean;

implementation
uses
  NI6733, NIDAQ, NIDAQCNS, TipCoarseApproach, AFM_PLL,
  WalkerFunctions, SysUtils, SPMUtilities, SPM_Main;
{-------------------------------------------------------------------------}
  function MoveZ(Z, step: integer): boolean;
  var
    i    : integer;
  begin
    //Make sure the value of Z is within limits
    //Note that Z is define opposite to the output of the board
    // i.e., Z=65536 actually means an output of -10 V
    if (Z>Board_resolution) then Z:=Board_resolution
      else if (Z<0) then Z:=0;
    i:=Current_Z;
    //thread safe part?
    ExclusiveMoveZ.Enter;
    try
      //If the desired value of Z is more than a step away, then we move
      // in units of a step
      if (Z>=Current_Z+step) then // we move up
        while i<Z do
          begin
            Inc(i, step);
            AO_Write(Analog_output_device, Z_control_channel, -i + Half_resolution);
          end
       else if (Z<=Current_Z-step) then
        while i>Z do
          begin
            Dec(i, step);
            AO_Write(Analog_output_device, Z_control_channel, -i + Half_resolution);
          end;
    //Finally write the value, since we are now less than a step away
      AO_Write(Analog_output_device, Z_control_channel, -Z + Half_resolution);
      //Set the value of Current_Z
      Current_Z := Z;
    finally
      ExclusiveMoveZ.Leave;
    end;
    MoveZ:=TRUE;
  end;


{----------------------------------------------------------------------------}

function Tip_GoTo(var x, y : integer; step : integer): boolean;

var
   i      : integer;

begin
  if x<0 then x:=0 else if x>Board_resolution then x:=Board_resolution;
  if y<0 then y:=0 else if y>Board_resolution then y:=Board_resolution;
  i:= Current_x;
  if x>= Current_x + step then
    while i<=x do
      begin
        Application.ProcessMessages;
        AO_write(Counter_device, x_control_channel, i- Half_resolution);
        inc(i, step);
      end
   else if (x<= Current_x - step) then
    while i>=x do
      begin
        Application.ProcessMessages;
        AO_write(Counter_device, x_control_channel, i- Half_resolution);
        Dec(i, step);
      end;
//final write
  AO_write(Counter_device, x_control_channel, x- Half_resolution);

//same for the y-axis
  i:= Current_y;
  if y>= Current_y + step then
    while i<=y do
      begin
        Application.ProcessMessages;
        AO_write(Counter_device, y_control_channel, i- Half_resolution);
        inc(i, step);
      end
   else if (y<= Current_y - step) then
    while i>=y do
      begin
        Application.ProcessMessages;
        AO_write(Counter_device, y_control_channel, i- Half_resolution);
        Dec(i, step);
      end;
//final write
  AO_write(Counter_device, y_control_channel, y- Half_resolution);
  Current_x := x;
  Current_y := y;
  Tip_GoTo:=FALSE;
end;

{---------------------------------------------------------------------------}
function Single_feedback: boolean;
var
  Instant_reading: real; //Instantaneous reading of Feedback channel
  error            : real;
  correction       : integer;

begin
  if Feedback then
    begin
      Instant_reading:=ReadAveragedAnalogChannel(PrimaryChannelNumber, ReadingAverages);
      error:= Instant_reading - Initial_reading - SetPoint;
      correction:=trunc(PID(PropGain, IntGain, DiffGain, error)*PIDScaleFactor);
      MoveZ(Current_Z-FeedbackSign*correction, SingleStepSize);
    end;
  Single_feedback:=TRUE;
end;

{---------------------------------------------------------------------------}
function Continuous_feedback(Sender: TObject): boolean;
var
  Instant_reading: real; //Instantaneous reading of Feedback channel
  error            : real;
  correction       : integer;

begin
  while Feedback do
    begin
      Instant_reading:=ReadAveragedAnalogChannel(PrimaryChannelNumber, ReadingAverages);
      error:= Instant_reading - Initial_reading - SetPoint;
      correction:=trunc(PID(PropGain, IntGain, DiffGain, error)*PIDScaleFactor);
      MoveZ(Current_Z-FeedbackSign*correction, SingleStepSize);
      if (Sender is TAFMPLL) then
         (Sender as TAFMPLL).UpdateZPositionIndicators;
    end;
  Continuous_feedback:=TRUE;
end;
{----------------------------------------------------------------------------}

function Tip_GoTo_WithFeedback(var x, y : integer; step : integer): boolean;

var
   i      : integer;

begin
  Tip_GoTo_WithFeedback:=FALSE;
  if feedback then
  begin
    if x<0 then x:=0 else if x>Board_resolution then x:=Board_resolution;
    if y<0 then y:=0 else if y>Board_resolution then y:=Board_resolution;
    i:= Current_x;
    if x>= Current_x + step then
       while i<=x do
         begin
           Application.ProcessMessages;
           AO_write(Counter_device, x_control_channel, i- Half_resolution);
           Single_Feedback;
           inc(i, step);
         end
     else if (x<= Current_x - step) then
       while i>=x do
         begin
           Application.ProcessMessages;
           AO_write(Counter_device, x_control_channel, i- Half_resolution);
           Single_Feedback;
           Dec(i, step);
         end;
  //final write
    AO_write(Counter_device, x_control_channel, x- Half_resolution);
    Single_Feedback;
  //same for the y-axis
    i:= Current_y;
    if y>= Current_y + step then
      while i<=y do
        begin
          Application.ProcessMessages;
          AO_write(Counter_device, y_control_channel, i- Half_resolution);
          Single_Feedback;
          inc(i, step);
        end
     else if (y<= Current_y - step) then
      while i>=y do
        begin
          Application.ProcessMessages;
          AO_write(Counter_device, y_control_channel, i- Half_resolution);
          Single_Feedback;
          Dec(i, step);
        end;
  //final write
    AO_write(Counter_device, y_control_channel, y- Half_resolution);
    Single_Feedback;
    Current_x := x;
    Current_y := y;
    Tip_GoTo_WithFeedback:=TRUE;
  end;
end;


end.
