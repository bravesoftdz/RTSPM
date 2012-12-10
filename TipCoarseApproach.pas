unit TipCoarseApproach;

{$MODE Delphi}
//{$mode objfpc}{$H+}

interface

uses
  {$IFNDEF LCL} Windows, Messages, {$ELSE} LclIntf, LMessages, LclType, {$ENDIF}
  SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, {TeeProcs, TeEngine, Chart,} {Series,} Menus,
  Buttons, Spin, LResources, Plotpanel, TAGraph, TASeries;

type

  { TCoarseApproachTool }

  TCoarseApproachTool = class(TForm)
    ProbeSignal: TChart;
    DataTimer: TTimer;
    ProbeSignalLineSeries1: TLineSeries;
    ProbeSignalLineSeries2: TLineSeries;
    ZApproachBar: TProgressBar;
    SignalControlGroupBox: TGroupBox;
    WalkerControlGroupBox: TGroupBox;
    WalkerStepPlusXBtn: TButton;
    WalkerStepPlusYBtn: TButton;
    WalkerRetract: TButton;
    WalkerStepMinusXBtn: TButton;
    WalkerMinusYBtn: TButton;
    WalkerApproach: TButton;
    Panel1: TPanel;
    TimedRetracBtn: TButton;
    TimedApproachBtn: TButton;
    WalkerTimeEdit: TEdit;
    Label6: TLabel;
    Scan_Tube_GroupBox: TGroupBox;
    Label8: TLabel;
    Label9: TLabel;
    SetXEdit: TEdit;
    SetYEdit: TEdit;
    SetZEdit: TEdit;
    SaveDialog: TSaveDialog;
    Label10: TLabel;
    SetXLabel: TLabel;
    Bevel1: TBevel;
    Bevel3: TBevel;
    StepXEdit: TLabeledEdit;
    StepYEdit: TLabeledEdit;
    StepZEdit: TLabeledEdit;
    XPositionText: TStaticText;
    ZPositionText: TStaticText;
    YPositionText: TStaticText;
    Label12: TLabel;
    Bevel4: TBevel;
    Bevel5: TBevel;
    Label13: TLabel;
    Label14: TLabel;
    StatusBar: TStatusBar;
    SetPointEdit: TLabeledEdit;
    ApprCriterionEdit: TLabeledEdit;
    Label1: TLabel;
    Label2: TLabel;
    Ch0OutputLabel: TLabel;
    Ch1OutputLabel: TLabel;
    UpdateTimeEditBox: TLabeledEdit;
    Bevel6: TBevel;
    Bevel7: TBevel;
    StepByStepBtn: TBitBtn;
    AcquireCurveBtn: TBitBtn;
    Bevel8: TBevel;
    Label5: TLabel;
    StepNumberLabel: TLabel;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    SaveApproachCurve1: TMenuItem;
    Exit1: TMenuItem;
    Bevel2: TBevel;
    Label7: TLabel;
    FeedbackOutputLabel: TLabel;
    {Series1: TFastLineSeries;}
    CoarseApproachStepSizeEdit: TSpinEdit;
    Label11: TLabel;
    procedure CoarseApproachStepSizeEditChange(Sender: TObject);
    procedure DataTimerTimer(Sender: TObject);
    procedure AcquireCurveBtnClick(Sender: TObject);
    procedure ApprCriterionEditKeyPress(Sender: TObject; var Key: Char);
    {procedure Series1DrawPointer(ASender: TChartSeries; ACanvas: TCanvas;
      AIndex: Integer; ACenter: TPoint);}
    procedure StepByStepBtnClick(Sender: TObject);
    procedure WalkerMinusYBtnClick(Sender: TObject);
    procedure WalkerStepPlusYBtnClick(Sender: TObject);
    procedure WalkerStepMinusXBtnClick(Sender: TObject);
    procedure WalkerStepPlusXBtnClick(Sender: TObject);
    procedure TimedApproachBtnClick(Sender: TObject);
    procedure TimedRetracBtnClick(Sender: TObject);
    procedure WalkerTimeEditKeyPress(Sender: TObject; var Key: Char);
    procedure WalkerApproachMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure WalkerRetractMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure WalkerRetractMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StepZEditKeyPress(Sender: TObject; var Key: Char);
    procedure StepYEditKeyPress(Sender: TObject; var Key: Char);
    procedure StepXEditKeyPress(Sender: TObject; var Key: Char);
    procedure SetPointEditKeyPress(Sender: TObject; var Key: Char);
    procedure UpdateTimeEditBoxKeyPress(Sender: TObject; var Key: Char);
    procedure SetZEditKeyPress(Sender: TObject; var Key: Char);
    procedure SetYEditKeyPress(Sender: TObject; var Key: Char);
    procedure SetXEditKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function UpdateXYPositionIndicators: boolean;
    function UpdateZPositionIndicators: boolean;
    function UpdateDataChannelIndicators: boolean;


  end;

var
  CoarseApproachTool: TCoarseApproachTool;


  ReadingAverages     : integer = 10; //the number of averages to take on a analog reading
  CoarseApproachStepNumber       : integer = 0; //current coarse approach step number
  CriticalStepNumber             : integer = 0; //Step number at which contact occurs
  ShortAverage                   : integer = 3; //Rapid reading
  Chan0Points,
  Chan1Points                   : array[0..4095] of real;
  Contacted                     : boolean;
  Approaching                   : boolean =FALSE;


implementation

{$IFNDEF LCL}
{$R *.DFM}
{$ELSE}
{$R *.lfm}
{$ENDIF}

uses
  GlobalVariables, ScanTubeFunctions, WalkerFunctions, DAQFunctions,
  GlobalFunctions, rtai_comedi_types;

const
  MaxCoarseApproachSteps = 10000; //Maximum number of coarse approach steps
  CoarseApproachWaitTime = 10; //msecs to wait between each coarse approach step

var
  ChannelUpdateTime   : integer = 1000; //period at which Channel reading are taken
  WalkerTimedMoveTime : integer = 50; //time in milliseconds walkers should move
  FeedbackChannelReading  : real;
  NumbAverages            : integer = 100;  //averages to take in averaged reading
  CoarseApproachStepSize  : integer = 15; //Step size to take on coarse approach
  StartReading            : real;
  FeedbackCondition       : integer;
{-----------------------------------------------------------------------------}

function CheckContact: boolean;
begin
  FeedbackChannelReading:=ReadFeedbackChannel;
    if (FeedbackCondition*(CoarseSP-FeedbackChannelReading)<=0) then
        CheckContact:=TRUE
       else CheckContact:=FALSE;
end;

function AveragedCheckContact(NumbReadings: integer): boolean;
begin
  FeedbackChannelReading:=ReadAveragedFeedbackChannel(NumbReadings);
  if (FeedbackCondition*(CoarseSP-FeedbackChannelReading)<=0) then
    AveragedCheckContact:=TRUE else AveragedCheckContact:=FALSE;
end;


procedure TCoarseApproachTool.WalkerApproachMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  WalkerPlusZMove;
end;

procedure TCoarseApproachTool.WalkerMinusYBtnClick(Sender: TObject);
begin
  WalkerTimedAxisMinusMove(YAxis, WalkerTimedMoveTime);
end;

procedure TCoarseApproachTool.SetPointEditKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key=Chr(13) then CoarseSP:=StrToFloat(SetPointEdit.Text);
   ProbeSignal.LeftAxis.Range.Max:=2*abs(CoarseSP);
   ProbeSignal.LeftAxis.Range.Min:=-2*abs(CoarseSP);
end;

procedure TCoarseApproachTool.SetXEditKeyPress(Sender: TObject; var Key: Char);
  var SetCaption : string;
begin
  if Key=chr(13) then
    begin
      SetCaption:=SetXEdit.Text;
      RespondToAxisKeyPress(SetX, SetXVoltage, SetCaption, XAxis);
      SetXEdit.Text:=SetCaption;
      MoveToX(SetX,StepX, StepDelay);
      UpdateXYPositionIndicators;
    end;
end;

procedure TCoarseApproachTool.SetYEditKeyPress(Sender: TObject; var Key: Char);
var
  SetCaption: string;
begin
  if Key=chr(13) then
    begin
      SetCaption:=SetYEdit.Text;
      RespondToAxisKeyPress(SetY, SetYVoltage, SetCaption, YAxis);
      SetYEdit.Text:=SetCaption;
      MoveToY(SetY,StepY, StepDelay);
      UpdateXYPositionIndicators;
    end;
end;

procedure TCoarseApproachTool.SetZEditKeyPress(Sender: TObject; var Key: Char);
var
  SetCaption: string;
begin
  if Key=chr(13) then
    begin
      SetCaption:=SetZEdit.Text;
      RespondToAxisKeyPress(SetZ, SetZVoltage, SetCaption, ZAxis);
      SetZEdit.Text:=SetCaption;
      MoveToZ(SetZ,StepZ, StepDelay);
      UpdateZPositionIndicators;
    end;
end;

procedure TCoarseApproachTool.StepByStepBtnClick(Sender: TObject);
  var
    InContact, FullyExtended : boolean;
    Direction
                       : real;
    MaxVoltage, MinVoltage    : real;


begin
      //For this procedure, we use voltages throughout, rather than position of the
      //Z piezo in microns
      //However, we need to first figure out which direction we ramp the voltage
      //as the high voltage amplifiers may have a negative gain with respect to the DACs
      //MaxZPosition is the full extension of the tube in microns, always
      //defined to be positive.  MinZPosition is the corresponding negative retraction
  if MaxZVoltage>MinZVoltage then
    begin
      Direction:=-1;
      MaxVoltage:=MaxZVoltage;
      MinVoltage:=MinZVoltage;
    end
      else
        begin
          Direction:=1;
          MaxVoltage:=MinZVoltage;
          MinVoltage:=MaxZVoltage;
        end;
  if Approaching then //stop the approach
    begin
      StepByStepBtn.Caption:='Start Step-by-Step approach';
      Approaching:=FALSE;
      DataTimer.Enabled:=TRUE;
      StatusBar.SimpleText:='Idle';
      AcquireCurveBtn.Enabled:=TRUE;
    end
   else
    begin
      DataTimer.Enabled:=FALSE;
      AcquireCurveBtn.Enabled:=FALSE;
      StatusBar.SimpleText:='Starting coarse approach';
      CoarseApproachStepNumber:=0;      //Initialize stepnumber
      StepNumberLabel.Caption:=IntToStr(CoarseApproachStepNumber);

      //Clear the data from the graph
      ProbeSignalLineSeries1.Clear;
      ProbeSignalLineSeries2.Clear;

      //Series1.Draw;
      StepByStepBtn.Caption:='Stop Approach';
      Approaching:=TRUE;

      //First, retract the tube all the way
      StatusBar.SimpleText:='Retracting';
      MoveToZVoltage(MaxZVoltage, 100*MinZVoltageStep);
      FullyExtended:= FALSE;
      InContact:=CheckContact;
      FeedbackOutputLabel.Caption:=FloatToStrF(FeedbackChannelReading, ffFixed, 6, 3);
      //FeedbackCondition determines the sign condition to see whether we have approached
      if ((CoarseSP-ReadAveragedFeedbackChannel(100))>0) then
        FeedbackCondition:=1
       else FeedbackCondition:=-1;
      StatusBar.SimpleText:='Approaching';
      while ((not InContact) and Approaching) do
        begin
          CurrentZVoltage:=CurrentZVoltage + CoarseApproachStepSize*Direction*MinZVoltageStep;
          if CurrentZVoltage>MaxVoltage then CurrentZVoltage:=MaxVoltage;
          if CurrentZVoltage<MinVoltage then CurrentZVoltage:=MinVoltage;
          RapidZVoltage(CurrentZVoltage);
          CurrentZ:=ZVoltageToMicrons(CurrentZVoltage);
          UpdateZPositionIndicators;
          ProbeSignalLineSeries1.AddXY(CurrentZ, FeedbackChannelReading, '',clRed);
          Application.ProcessMessages; // Process any events from the program
          //Check if we are in contact
          InContact:=CheckContact;
          FeedbackOutputLabel.Caption:=FloatToStrF(FeedbackChannelReading, ffFixed, 6, 3);
          if (((Direction=1) and (CurrentZVoltage>=MinZVoltage)) or
             ((Direction=-1) and (CurrentZVoltage<=MinZVoltage))) then FullyExtended:=TRUE;
          if (FullyExtended and (not InContact)) then
            begin
              StatusBar.SimpleText:='Retracting';
              MoveToZVoltage(MaxZVoltage, 100*MinZVoltageStep);   //Retract piezo
              FullyExtended:=FALSE;
              WalkerTimedZApproach(200); //Approach for 200 msec
              fastdelay(350);  //wait for 10 msecs for things to settle
              Inc(CoarseApproachStepNumber);
              StepNumberLabel.Caption:=IntToStr(CoarseApproachStepNumber);
              ProbeSignalLineSeries1.Clear; //Need to clear only line series 1
            end;
        end;
        Approaching:=FALSE;         //reset
        StepByStepBtn.Caption:='Start Step-by-Step approach';
        DataTimer.Enabled:=TRUE;
        StatusBar.SimpleText:='Idle';
        AcquireCurveBtn.Enabled:=TRUE;
  end;
end;
procedure TCoarseApproachTool.StepXEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then StepX:=StrToFloat(StepXEdit.Text);
end;

procedure TCoarseApproachTool.StepYEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then StepY:=StrToFloat(StepYEdit.Text);
end;

procedure TCoarseApproachTool.StepZEditKeyPress(Sender: TObject; var Key: Char);
begin
 if Key=Chr(13) then StepZ:=StrToFloat(StepZEdit.Text);
end;

procedure TCoarseApproachTool.TimedApproachBtnClick(Sender: TObject);
begin
  WalkerTimedApproach(WalkerTimedMoveTime);
end;

procedure TCoarseApproachTool.TimedRetracBtnClick(Sender: TObject);
begin
  WalkerTimedRetract(WalkerTimedMoveTime);
end;

procedure TCoarseApproachTool.WalkerRetractMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  WalkerMinusZMove;
end;

procedure TCoarseApproachTool.WalkerRetractMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  WalkerStop(ZAxis);
end;

procedure TCoarseApproachTool.WalkerStepMinusXBtnClick(Sender: TObject);
begin
  WalkerTimedAxisMinusMove(XAxis, WalkerTimedMoveTime);
end;

procedure TCoarseApproachTool.WalkerStepPlusXBtnClick(Sender: TObject);
begin
  WalkerTimedAxisPlusMove(XAxis, WalkerTimedMoveTime);
end;

procedure TCoarseApproachTool.WalkerStepPlusYBtnClick(Sender: TObject);
begin
  WalkerTimedAxisPlusMove(YAxis, WalkerTimedMoveTime);
end;

procedure TCoarseApproachTool.WalkerTimeEditKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key=Chr(13) then
    WalkerTimedMoveTime:=StrToInt(WalkerTimeEdit.Text);
end;

{-----------------------------------------------------------------------------}


procedure TCoarseApproachTool.ApprCriterionEditKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key=Chr(13) then ApproachCriterion:=StrToFloat(ApprCriterionEdit.Text);
end;



procedure TCoarseApproachTool.CoarseApproachStepSizeEditChange(Sender: TObject);
begin
  CoarseApproachStepSize:=CoarseApproachStepSizeEdit.Value;
end;

procedure TCoarseApproachTool.DataTimerTimer(Sender: TObject);
  var
    Ch0Reading,
    Ch1Reading      : real;
begin
    Ch0Reading:=ReadChannel(Ch0Input);
    FeedbackChannelReading:=ReadAveragedFeedbackChannel(100);
    Ch1Reading:=ReadChannel(Ch1Input);
    Ch0OutputLabel.Caption:=FloatToStrF(Ch0Reading, ffFixed, 10, 4);
    Ch1OutputLabel.Caption:=FloatToStrF(Ch1Reading, ffFixed, 10, 4);
    FeedbackOutputLabel.Caption:=FloatToStrF(FeedbackChannelReading, ffFixed, 10, 4);
end;

procedure TCoarseApproachTool.AcquireCurveBtnClick(Sender: TObject);
var
  InContact,
  FullyExtended,
  StartingPointReached
                            : boolean;
  Direction                 : integer;
  MaxVoltage, MinVoltage    : real;
begin
  //Assume that we have already approached, and we want to take a slow approach
  //curve
  //As in the coarse approach curve, MaxZVoltage and MinZVoltage are the voltages
  //that correspond to the maximum (fully retracted, MaxZPosition) and minimum (fully extended
  //MinZPosition)
  //values of the z scan piezo
  if MaxZVoltage>MinZVoltage then
    begin
      Direction:=-1;
      MaxVoltage:=MaxZVoltage;
      MinVoltage:=MinZVoltage;
    end
      else
        begin
          Direction:=1;
          MaxVoltage:=MinZVoltage;
          MinVoltage:=MaxZVoltage;
        end;
if Approaching then //stop the acquisition
  begin
    Approaching:=FALSE;
    AcquireCurveBtn.Caption:='Acquire approach curve';
    //retract scan tube completely
    MoveToZVoltage(MaxZVoltage, 100*MinZVoltageStep);
    UpdateZPositionIndicators;
    StatusBar.SimpleText:='Idle';
    DataTimer.Enabled:=TRUE;
    StepByStepBtn.Enabled:=TRUE;
  end
 else
  begin
    StepByStepBtn.Enabled:=FALSE;
    Approaching:=TRUE;
    StatusBar.SimpleText:='Acquiring approach curve';
    DataTimer.Enabled:=FALSE;
    AcquireCurveBtn.Caption:='Stop acquisition';

    //Clear the data from the graph
    ProbeSignalLineSeries1.Clear;
    ProbeSignalLineSeries2.Clear;

    //retract scan tube completely
    MoveToZVoltage(MaxZVoltage, 100*MinZVoltageStep);
    NumbAverages:=100; //Number of readings to average
    InContact:=AveragedCheckContact(NumbAverages);
    FeedbackOutputLabel.Caption:=FloatToStrF(FeedbackChannelReading, ffFixed, 10, 4);
    //FeedbackCondition determines the sign condition to see whether we have approached
    if ((CoarseSP-ReadAveragedFeedbackChannel(100))>0) then
      FeedbackCondition:=1
     else FeedbackCondition:=-1;
    FullyExtended:=FALSE;
    while (Approaching and (not InContact) and (not FullyExtended)) do
      begin
        if (((Direction=1) and (CurrentZVoltage>=MinZVoltage)) or
             ((Direction=-1) and (CurrentZVoltage<=MinZVoltage))) then FullyExtended:=TRUE;
        CurrentZVoltage:=CurrentZVoltage + CoarseApproachStepSize*Direction*MinZVoltageStep;
        if CurrentZVoltage>MaxVoltage then CurrentZVoltage:=MaxVoltage;
        if CurrentZVoltage<MinVoltage then CurrentZVoltage:=MinVoltage;
        RapidZVoltage(CurrentZVoltage);
        CurrentZ:=ZVoltageToMicrons(CurrentZVoltage);
        UpdateZPositionIndicators;
        //Check if we are in contact
        InContact:=AveragedCheckContact(NumbAverages);
        FeedbackOutputLabel.Caption:=FloatToStrF(FeedbackChannelReading, ffFixed, 10, 4);
        ProbeSignalLineSeries1.AddXY(CurrentZ, FeedbackChannelReading, '', clRed);
        fastdelay(CoarseApproachWaitTime);
        Application.ProcessMessages; // Process any events from the program
      end;
    //After we have reached this point, we slowly retract
    StartingPointReached:=FALSE;
    while (Approaching and (not StartingPointReached))do
      begin
        if (((Direction=1) and (CurrentZVoltage<=MaxZVoltage)) or
             ((Direction=-1) and (CurrentZVoltage>=MaxZVoltage))) then
                                            StartingPointReached:=TRUE;

        CurrentZVoltage:=CurrentZVoltage - CoarseApproachStepSize*Direction*MinZVoltageStep;
        if CurrentZVoltage>MaxVoltage then CurrentZVoltage:=MaxVoltage;
        if CurrentZVoltage<MinVoltage then CurrentZVoltage:=MinVoltage;
        RapidZVoltage(CurrentZVoltage);
        CurrentZ:=ZVoltageToMicrons(CurrentZVoltage);
        UpdateZPositionIndicators;
        //This is just to get a reading
        AveragedCheckContact(NumbAverages);
        FeedbackOutputLabel.Caption:=FloatToStrF(FeedbackChannelReading, ffFixed, 10, 4);
        ProbeSignalLineSeries2.AddXY(CurrentZ, FeedbackChannelReading, '', clBlue);
        Application.ProcessMessages; // Process any events from the program
      end;
    //Finish and bring us back to where we were
    Approaching:=FALSE;
    AcquireCurveBtn.Caption:='Acquire approach curve';
    //retract scan tube completely
    MoveToZVoltage(MaxZVoltage, MinZVoltageStep);
    UpdateZPositionIndicators;
    StatusBar.SimpleText:='Idle';
    DataTimer.Enabled:=TRUE;
    StepByStepBtn.Enabled:=TRUE;
  end;
end;

procedure TCoarseApproachTool.FormShow(Sender: TObject);

begin
   ProbeSignal.BottomAxis.Range.Min:=MinZPosition;
   ProbeSignal.BottomAxis.Range.Max:=MaxZPosition;
   ProbeSignalLineSeries1.Clear;
   ProbeSignalLineSeries2.Clear;


   CoarseSP:=0.5;
   ProbeSignal.LeftAxis.Range.Max:=2*abs(CoarseSP);
   ProbeSignal.LeftAxis.Range.Min:=-2*abs(CoarseSP);

   CoarseApproachStepNumber:=0;
   SetPointEdit.Text:=FloatToStrF(CoarseSP, ffFixed, 10, 4);
   ApprCriterionEdit.Text:=FloatToStrF(ApproachCriterion, ffFixed, 10, 4);
   WalkerTimeEdit.Text:=IntToStr(WalkerTimedMoveTime);
   DataTimer.Interval:=ChannelUpdateTime;
   UpdateTimeEditBox.Text:=IntToStr(ChannelUpdateTime);
   CoarseApproachStepSizeEdit.Value:=CoarseApproachStepSize;
   DataTimer.Enabled:=TRUE;
   ZApproachBar.Max:=65535;
   ZApproachBar.Min:=0;
   ZApproachBar.Position:=MicronsToProgressBar(CurrentZ);
   Contacted:=FALSE;
   Approaching:=FALSE;
   //Retract the z piezo roughly by half
   MoveToZVoltage(MaxZVoltage/2, 0.005);
   UpdateXYPositionIndicators;
   UpdateZPositionIndicators;
end;
{------------------------------------------------------------------------}
  function TCoarseApproachTool.UpdateDataChannelIndicators: boolean;
  begin
    UpdateDataChannelIndicators:=TRUE;
  end;
procedure TCoarseApproachTool.UpdateTimeEditBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key=Chr(13) then
    begin
      ChannelUpdateTime:=StrToInt(UpdateTimeEditBox.Text);
      DataTimer.Interval:=ChannelUpdateTime;
    end;
end;

{----------------------------------------------------------------------------------}
function TCoarseApproachTool.UpdateZPositionIndicators: boolean;
begin
  ZApproachBar.Position:=MicronsToProgressBar(CurrentZ);
  //SetZEdit.Text:=FloatToStrF(CurrentZ, ffFixed, 10, 4);
  ZPositionText.Caption:='Z: '+ FloatToStrF(CurrentZ, ffFixed, 10, 4);
  UpdateZPositionIndicators:=TRUE;
end;

function TCoarseApproachTool.UpdateXYPositionIndicators: boolean;
begin
  //SetXEdit.Text:=FloatToStrF(CurrentX, ffFixed, 10, 4);
  //SetYEdit.Text:=FloatToStrF(CurrentY, ffFixed, 10, 4);
  XPositionText.Caption:='X: '+ FloatToStrF(CurrentX, ffFixed, 10, 4);
  YPositionText.Caption:='Y: '+ FloatToStrF(CurrentY, ffFixed, 10, 4);
  UpdateXYPositionIndicators:=TRUE;
end;

initialization
  {$I TipCoarseApproach.lrs}

end.
