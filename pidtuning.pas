unit PIDTuning;

{$mode delphi}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, Buttons, Spin, EpikTimer;

type

  { TPIDTuningForm }

  TPIDTuningForm = class(TForm)
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    Bevel6: TBevel;
    Bevel8: TBevel;
    SquareWaveBtn: TButton;
    Ch0OutputLabel: TLabel;
    Ch1OutputLabel: TLabel;
    DiffEdit: TLabeledEdit;
    EngageFeedbackBtn: TButton;
    ErrorCorrectionSpinEdit: TSpinEdit;
    Label1: TLabel;
    PeriodSpinEdit: TSpinEdit;
    ErrorSignalLabel: TLabel;
    FeedbackOutputLabel: TLabel;
    SPMaxEdit: TLabeledEdit;
    SPMinEdit: TLabeledEdit;
    SquareWaveBox: TGroupBox;
    IntEdit: TLabeledEdit;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LogarithmicCheckBox: TCheckBox;
    PID: TLabel;
    PropEdit: TLabeledEdit;
    PIDGroupBox: TGroupBox;
    Scan_Tube_GroupBox: TGroupBox;
    SetPointEdit: TLabeledEdit;
    SetXEdit: TEdit;
    SetXLabel: TLabel;
    SetYEdit: TEdit;
    SetZEdit: TEdit;
    StepXEdit: TLabeledEdit;
    StepYEdit: TLabeledEdit;
    StepZEdit: TLabeledEdit;
    SquareWaveTimer: TTimer;
    XPositionText: TStaticText;
    YPositionText: TStaticText;
    ZPositionText: TStaticText;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure PeriodSpinEditChange(Sender: TObject);
    procedure SetYEditKeyPress(Sender: TObject; var Key: char);
    procedure SetZEditKeyPress(Sender: TObject; var Key: char);
    procedure SPMaxEditKeyPress(Sender: TObject; var Key: char);
    procedure SPMinEditKeyPress(Sender: TObject; var Key: char);
    procedure SquareWaveBtnClick(Sender: TObject);
    procedure SquareWaveTimerTimer(Sender: TObject);
    procedure StepXEditKeyPress(Sender: TObject; var Key: char);
    procedure StepYEditKeyPress(Sender: TObject; var Key: char);
    procedure StepZEditKeyPress(Sender: TObject; var Key: char);
    function UpdateXYPositionIndicators: boolean;
    function UpdateZPositionIndicators: boolean;
    procedure DiffEditKeyPress(Sender: TObject; var Key: char);
    procedure EngageFeedbackBtnClick(Sender: TObject);
    procedure ErrorCorrectionSpinEditChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure IntEditKeyPress(Sender: TObject; var Key: char);
    procedure PropEditKeyPress(Sender: TObject; var Key: char);
    procedure SetPointEditKeyPress(Sender: TObject; var Key: char);
    procedure SetXEditKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  PIDTuningForm: TPIDTuningForm;

implementation

uses
   GlobalVariables, ScanTubeFunctions, GlobalFunctions,
          rtai_comedi_types, rtai_comedi_functions;

var
    OldSetPoint              : real;
    SetPointMax,             //Max setpoint
    SetPointMin,             //Min setpoint
    Period                   : real;

    AtMinSetPoint,
    SquareWaveOn             : boolean;

{ TPIDTuningForm }

procedure TPIDTuningForm.FormShow(Sender: TObject);
begin
  if (Logarithmic=1) then LogarithmicCheckBox.State:=cbChecked else LogarithmicCheckBox.State:=cbUnchecked;
  if InFeedback then
    EngageFeedbackBtn.Caption:='Stop Feedback'
   else
     EngageFeedbackBtn.Caption:='Start Feedback';
  PropEdit.Text:=FloatToStr(PropCoff);
  IntEdit.Text:=FloatToStr(IntTime/1E6);  //IntTime and DiffTime are specified in nanoseconds
  DiffEdit.Text:=FloatToStr(DiffTime/1E6);//while the user input is in milliseconds

  if OutputPhase>0 then
    ErrorCorrectionSpinEdit.Value:=1
   else ErrorCorrectionSpinEdit.Value:=-1;

  SetPointEdit.Text:=FloatToStr(SetPoint);
  OldSetPoint:=SetPoint;
  StepXEdit.Caption:=FloatToStr(StepX);
  StepYEdit.Caption:=FloatToStr(StepY);
  StepZEdit.Caption:=FloatToStr(StepY);
  UpdateXYPositionIndicators;
  UpdateZPositionIndicators;
  AtMinSetPoint:= TRUE;
  SetPointMax:=SetPoint*1.10; //10% over the SetPoint
  SetPointMin:=SetPoint*0.90; //10% under the SetPoint
  SPMaxEdit.Caption:=FloatToStr(SetPointMax);
  SPMinEdit.Caption:=FloatToStr(SetPointMin);
  Period:=1; // in milliseconds
  PeriodSpinEdit.Value:=Period;
  SquareWaveOn:=FALSE;
end;

procedure TPIDTuningForm.IntEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then
    begin
      IntTime:=round(1E6*StrToFloat(IntEdit.Text));
      PIDParametersChanged:=1;
    end;
end;

procedure TPIDTuningForm.PropEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then
    begin
      PropCoff:=StrToFloat(PropEdit.Text);
      PIDParametersChanged:=1;
    end;
end;

procedure TPIDTuningForm.SetPointEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then
    begin
      SetPoint:=StrToFloat(SetPointEdit.Text);
      OldSetPoint:=SetPoint;
    end;
end;

procedure TPIDTuningForm.SetXEditKeyPress(Sender: TObject; var Key: char);
var EditCaption: string;
begin
  if Key=chr(13) then
    begin
      EditCaption:=SetXEdit.Text;
      RespondToAxisKeyPress(SetX, SetXVoltage, EditCaption, XAxis);
      SetXEdit.Text:=EditCaption;
      MoveToX(SetX,StepX, StepDelay);
      UpdateXYPositionIndicators;
    end;
end;

procedure TPIDTuningForm.EngageFeedbackBtnClick(Sender: TObject);
begin
  if InFeedback then
    begin  //stop the feedback
      InFeedback:=FALSE;
      EngageFeedbackBtn.Caption:='Start Feedback';
      pid_loop_running:=0;
      EndFeedback;
    end
   else
    begin  //start Feedback timer
      PIDOutput:=CurrentZVoltage; //set this so that the C program knows where we are
      InFeedback:=TRUE;
      EngageFeedbackBtn.Caption:='Stop Feedback';
      //PID_averages :=1; //Set the number of averages = 1
      //if Sender=EngageFeedbackBtn then FirstPIDPass := 1; //This is the first PID pass
      PIDParametersChanged:=0; //PID parameters have not changed (yet)
      pid_loop_running:=1;
      StartFeedback;
    end;
end;


procedure TPIDTuningForm.DiffEditKeyPress(Sender: TObject; var Key: char);
begin
    if Key=Chr(13) then
    begin
      DiffTime:=round(1E6*StrToFloat(DiffEdit.Text));
      PIDParametersChanged:=1;
    end;
end;

procedure TPIDTuningForm.ErrorCorrectionSpinEditChange(Sender: TObject);
begin
    if ErrorCorrectionSpinEdit.Value>0 then
    begin
      OutputPhase:=1;
      ErrorCorrectionSpinEdit.Value:=1;
    end
   else
    begin
      OutputPhase:=-1;
      ErrorCorrectionSpinEdit.Value:=-1;
    end;
end;

function TPIDTuningForm.UpdateXYPositionIndicators: boolean;
begin
  XPositionText.Caption:='X: '+ FloatToStrF(CurrentX, ffFixed, 10, 4);
  YPositionText.Caption:='Y: '+ FloatToStrF(CurrentY, ffFixed, 10, 4);
  UpdateXYPositionIndicators:=TRUE;
end;

procedure TPIDTuningForm.SetYEditKeyPress(Sender: TObject; var Key: char);
var EditCaption: string;
begin
if Key=chr(13) then
  begin
    EditCaption:=SetYEdit.Text;
    RespondToAxisKeyPress(SetY, SetYVoltage, EditCaption, YAxis);
    SetYEdit.Text:=EditCaption;
    MoveToY(SetY,StepY, StepDelay);
    UpdateXYPositionIndicators;
  end;
end;

procedure TPIDTuningForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  SetPoint:=OldSetPoint;
end;

procedure TPIDTuningForm.PeriodSpinEditChange(Sender: TObject);
begin
  Period:=PeriodSpinEdit.Value;
  SquareWaveTimer.Interval:=round(Period);
end;

procedure TPIDTuningForm.SetZEditKeyPress(Sender: TObject; var Key: char);
var EditCaption: string;
begin
if Key=chr(13) then
  begin
    EditCaption:=SetZEdit.Text;
    RespondToAxisKeyPress(SetZ, SetZVoltage, EditCaption, ZAxis);
    SetZEdit.Text:=EditCaption;
    MoveToZ(SetZ,StepZ, StepDelay);
    UpdateZPositionIndicators;
  end;
end;

procedure TPIDTuningForm.SPMaxEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then SetPointMax:=StrToFloat(SPMaxEdit.Text);
end;

procedure TPIDTuningForm.SPMinEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then SetPointMin:=StrToFloat(SPMinEdit.Text);
end;

procedure TPIDTuningForm.SquareWaveBtnClick(Sender: TObject);
begin
  if SquareWaveOn then // stop the square wave
    begin
      SquareWaveTimer.Enabled:=FALSE;
      SquareWaveOn:=FALSE;
      SquareWaveBtn.Caption:='Start';
      SetPoint:=OldSetPoint;
    end
   else //start the square wave
    begin
      AtMinSetPoint:=TRUE;
      SetPoint:=SetPointMin;
      SquareWaveOn:=TRUE;
      SquareWaveBtn.Caption:='Stop';
      SquareWaveTimer.Enabled:=TRUE;
    end;

end;

procedure TPIDTuningForm.SquareWaveTimerTimer(Sender: TObject);
begin
  if AtMinSetPoint then //we are at the minimum set point, switch to max
    begin
      SetPoint:=SetPointMax;
      AtMinSetPoint:=FALSE;
    end
   else
    begin
      SetPoint:=SetPointMin;
      AtMinSetPoint:=TRUE;
    end;
end;

procedure TPIDTuningForm.StepXEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then StepX:=StrToFloat(StepXEdit.Text);
end;

procedure TPIDTuningForm.StepYEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then StepY:=StrToFloat(StepYEdit.Text);
end;


procedure TPIDTuningForm.StepZEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then StepZ:=StrToFloat(StepZEdit.Text);
end;

function TPIDTuningForm.UpdateZPositionIndicators: boolean;
begin
  ZPositionText.Caption:='Z: '+ FloatToStrF(CurrentZ, ffFixed, 10, 4);
  UpdateZPositionIndicators:=TRUE;
end;

initialization
  {$I pidtuning.lrs}

end.

