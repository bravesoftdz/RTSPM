unit FeedbackThread;

interface

uses
  Classes;

type
  TFeedbackThread = class(TThread)
  private
    { Private declarations }
    function PID(prop, integral, diff, error : real): real;
  protected
    procedure Execute; override;
    procedure ReadGlobalParameters;
    procedure WriteGlobalParameters;
    procedure ReadDataPoint;
  public
    constructor Create(CreateSuspended : boolean);
end;

implementation
  uses
    NI6733, GlobalVariables, Windows, ScanTubeFunctions, TipCoarseApproach, AFM_PLL;

const
  ErrorThreshold = 1.0;
  UpperLimit     = 2.0;
  LowerLimit     = -2.0;

var
  InitReading      : real; //local version of initial reading
  Prop,
  Integral,
  Diff             : real; //local versions of integral, proportional and differential gains
  FeedbackChannel             : integer; //local version of PrimaryChannelNumber
  NReadings                   : integer; //local version of ReadingAverages
  OutputScaleFactor           : real; //local version of PID Scale factor
  SPoint                      : real; //local version of SetPoint
  NewPIDLoop                  : boolean; //true if it is a new PID loop
  LastTime                    : DWord; //Global variables for the PID loop
  LastError                   : real;
  correction                  : integer;
  IntegratedError             : real;
  OutPutZ                     : integer;
  Instant_reading: real; //Instantaneous reading of Feedback channel

{ Important: Methods and properties of objects in VCL can only be used in a
  method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TFeedbackThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ TFeedbackThread }

procedure TFeedbackThread.Execute;
  { Place thread code here }
var
  error            : real;


begin
  NewPIDLoop := TRUE;
  ReadGlobalParameters;
  while (not Terminated) do
    begin
      ReadDataPoint;
      error:= Instant_reading - InitReading - SPoint;
      correction:=trunc(PID(Prop, Integral, Diff, error)*OutputScaleFactor);
      OutPutZ:=OutPutZ-FeedbackSign*correction;
      WriteGlobalParameters;
    end;
end;

procedure TFeedbackThread.WriteGlobalParameters;
begin
  MoveZ(OutPutZ, SingleStepSize);
end;

procedure TFeedbackThread.ReadDataPoint;
begin
  Instant_reading:=ReadAveragedAnalogChannel(FeedbackChannel, NReadings);
end;
procedure TFeedbackThread.ReadGlobalParameters;
begin
  InitReading:=Initial_Reading;
  Prop:=PropGain;
  Integral:=IntGain;
  Diff:=DiffGain;
  FeedbackChannel:=PrimaryChannelNumber;
  NReadings:=ReadingAverages;
  OutputScaleFactor:=PIDScaleFactor;
  SPoint:=SetPoint;
//  OutPutZ:=Current_Z;
end;

{--------------------------------------------------------------------}
constructor TFeedbackThread.Create(CreateSuspended : boolean);
begin
  NewPIDLoop:=FALSE;
  IntegratedError:=0.0;
  Priority:=tpHigher;
  //FreeOnTerminate:=TRUE;
  inherited Create(CreateSuspended);
end;
{------------------------------------------------------------------}
function TFeedbackThread.PID(prop, integral, diff, error : real): real;
var
  PropTerm,
  IntTerm,
  DiffTerm         : real;
  TimeDifference   : DWord;
  PIDOutput        : real;

begin
  if NewPIDLoop then
    begin
      NewPIDLoop:=FALSE;
      LastTime:=GetTickCount;
      PIDOutput:=Prop*error;
      if PIDOutput>UpperLimit then PIDOutput:=UpperLimit;
      if PIDOutput<LowerLimit then PIDOutput:=LowerLimit;
      LastError:=error;
      IntegratedError:=0;
    end
   else
    begin
      TimeDifference:=GetTickCount-LastTime;
      IntegratedError:=IntegratedError+(error*TimeDifference);
      PropTerm:=prop*error;
      IntTerm:=IntegratedError*integral;
      DiffTerm:=diff*(error-LastError)/TimeDifference;
      PIDOutput:=PropTerm + IntTerm + DiffTerm;
      if PIDOutput>UpperLimit then PIDOutput:=UpperLimit;
      if PIDOutput<LowerLimit then PIDOutput:=LowerLimit;
      LastError:=error;
      LastTime:=LastTime+TimeDifference;
    end;
  PID:=PIDOutput;
end;

end.
