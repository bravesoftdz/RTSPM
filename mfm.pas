unit MFM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, ComCtrls, Buttons, Spin, GlobalVariables;

type

  { TMFMForm }

  TMFMForm = class(TForm)
    AveragesEdit: TSpinEdit;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    Bevel6: TBevel;
    Bevel8: TBevel;
    Ch0OutputLabel: TLabel;
    Ch1OutputLabel: TLabel;
    DataTimer: TTimer;
    DescriptionEdit: TEdit;
    DiffEdit: TLabeledEdit;
    DwellTimeEdit: TSpinEdit;
    EngageFeedbackBtn: TButton;
    ErrorCorrectionSpinEdit: TSpinEdit;
    ErrorSignalLabel: TLabel;
    FeedbackOutputLabel: TLabel;
    FileSaveDialog: TSaveDialog;
    FileSaveGroupBox: TGroupBox;
    ForwardTopoImage: TImage;
    ForwardMFMImage: TImage;
    ReverseMFMImage: TImage;
    GroupBox1: TGroupBox;
    TopoIndicatorImage: TImage;
    MFMIndicatorImage: TImage;
    IntEdit: TLabeledEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    PID: TLabel;
    PropEdit: TLabeledEdit;
    RescaleButton: TButton;
    ReverseTopoImage: TImage;
    SaveAsGSFFileButton: TButton;
    SaveAsTextFileButton: TButton;
    ScaleMaxEdit: TEdit;
    ScaleMinEdit: TEdit;
    ScanDirectionComboBox: TComboBox;
    ScanRangeComboBox: TComboBox;
    ScanResolutionComboBox: TComboBox;
    ScanStartBtn: TBitBtn;
    ScanStartGroupBox: TGroupBox;
    Scan_Tube_GroupBox: TGroupBox;
    SetPointEdit: TLabeledEdit;
    SetXEdit: TEdit;
    SetXLabel: TLabel;
    SetYEdit: TEdit;
    SetZEdit: TEdit;
    StatusBar: TStatusBar;
    StepXEdit: TLabeledEdit;
    StepYEdit: TLabeledEdit;
    StepZEdit: TLabeledEdit;
    XPositionText: TStaticText;
    YPositionText: TStaticText;
    ZApproachBar: TProgressBar;
    ZPositionText: TStaticText;
    procedure AveragesEditChange(Sender: TObject);
    procedure DataTimerTimer(Sender: TObject);
    procedure DwellTimeEditChange(Sender: TObject);
    procedure EngageFeedbackBtnClick(Sender: TObject);
    procedure ErrorCorrectionSpinEditChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure IntEditKeyPress(Sender: TObject; var Key: char);
    procedure PropEditKeyPress(Sender: TObject; var Key: char);
    procedure ScaleMaxEditKeyPress(Sender: TObject; var Key: char);
    procedure ScaleMinEditKeyPress(Sender: TObject; var Key: char);
    procedure ScanDirectionComboBoxChange(Sender: TObject);
    procedure ScanRangeComboBoxSelect(Sender: TObject);
    procedure ScanResolutionComboBoxSelect(Sender: TObject);
    procedure SetPointEditKeyPress(Sender: TObject; var Key: char);
    procedure SetXEditKeyPress(Sender: TObject; var Key: char);
    procedure StepXEditKeyPress(Sender: TObject; var Key: char);
    procedure StepYEditKeyPress(Sender: TObject; var Key: char);
    procedure StepZEditKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
    function UpdateZPositionIndicators: boolean;
    function UpdateXYPositionIndicators: boolean;
  end; 

var
  MFMForm: TMFMForm;

implementation
  uses ScanTubeFunctions, GlobalFunctions, FileFunctions,
  DAQFunctions, rtai_comedi_functions, rtai_comedi_types, BGRABitmap, BGRABitmapTypes;
  var
    ForwardTopoImageBitmap,
    ReverseTopoImageBitmap,
    ForwardMFMImageBitmap,
    ReverseMFMImageBitmap,
    StretchedForwardTopoBitmap,
    StretchedReverseTopoBitmap,
    StretchedForwardMFMBitmap,
    StretchedReverseMFMBitmap        : TBGRABitmap;
    FeedbackChannelReading  : real;
    //PointAverages           : integer = 10;
    DwellTime               : integer = 10; //number of points to average
                                //and dwell time per scan point

    ScanXPlusLimit,
    ScanXMinusLimit,
    ScanYPlusLimit,
    ScanYMinusLimit         : real;//extent of scans for a particular scan range

    TopoIntegerScaleMax : Word = 33000; //maximum and minimum of color scaling
    TopoIntegerScaleMin : Word = 32000;
    MFMIntegerScaleMax : Word = 33000; //maximum and minimum of color scaling
    MFMIntegerScaleMin : Word = 32000;
    RescaleTopoImage        : boolean = FALSE;
    RescaleMFMImage         : boolean = FALSE;


{ TMFMForm }

procedure TMFMForm.FormShow(Sender: TObject);
begin
  TopoIntegerScaleMax:=MicronsToProgressBar(MaxZPosition);
  TopoIntegerScaleMin:=MicronsToProgressBar(MinZPosition);
  //TopoIntegerScaleMax:=40000;
  //TopoIntegerScaleMin:=32000;
  ScaleMaxEdit.Text:=FloatToStr(MaxZPosition);
  ScaleMinEdit.Text:=FloatToStr(MinZPosition);
  ForwardTopoImageBitMap:=TBGRABitMap.Create(ScanResolution, ScanResolution, BGRABlack);
  ReverseTopoImageBitMap:=TBGRABitMap.Create(ScanResolution, ScanResolution, BGRABlack);
  ForwardMFMImageBitMap:=TBGRABitMap.Create(ScanResolution, ScanResolution, BGRABlack);
  ReverseMFMImageBitMap:=TBGRABitMap.Create(ScanResolution, ScanResolution, BGRABlack);

  StretchedForwardTopoBitmap:=ForwardTopoImageBitmap.Resample(ForwardTopoImage.ClientWidth,
                                    ForwardTopoImage.ClientHeight)as TBGRABitmap;
  StretchedForwardTopoBitmap.Draw(ForwardTopoImage.Canvas, 0, 0, True);
  StretchedForwardTopoBitmap.Free;
  StretchedReverseTopoBitmap:=ReverseTopoImageBitmap.Resample(ReverseTopoImage.ClientWidth,
                                    ReverseTopoImage.ClientHeight)as TBGRABitmap;
  StretchedReverseTopoBitmap.Draw(ReverseTopoImage.Canvas, 0, 0, True);
  StretchedReverseTopoBitmap.Free;

  StretchedForwardMFMBitmap:=ForwardMFMImageBitmap.Resample(ForwardMFMImage.ClientWidth,
                                    ForwardMFMImage.ClientHeight)as TBGRABitmap;
  StretchedForwardMFMBitmap.Draw(ForwardMFMImage.Canvas, 0, 0, True);
  StretchedForwardMFMBitmap.Free;
  StretchedReverseMFMBitmap:=ReverseMFMImageBitmap.Resample(ReverseMFMImage.ClientWidth,
                                    ReverseMFMImage.ClientHeight)as TBGRABitmap;
  StretchedReverseMFMBitmap.Draw(ReverseMFMImage.Canvas, 0, 0, True);
  StretchedReverseMFMBitmap.Free;

  //Now generate the indicator bars
  GenerateScale(TopoIndicatorImage, TopoIntegerScaleMin, TopoIntegerScaleMax);
  GenerateScale(MFMIndicatorImage, MFMIntegerScaleMin, MFMIntegerScaleMax);



  if ScanResolution=128 then
     ScanResolutionComboBox.ItemIndex:=0
    else if ScanResolution=256 then
      ScanResolutionComboBox.ItemIndex:=1
    else if ScanResolution=512 then
      ScanResolutionComboBox.ItemIndex:=2
    else if ScanResolution=1024 then
      ScanResolutionComboBox.ItemIndex:=3
     else ScanResolutionComboBox.ItemIndex:=-1;
  InFeedback:=FALSE;
  ErrorReading:=0;
  LastErrorReading:=0;
  DataTimer.Interval:=1000; //in milliseconds..fixed
  DataTimer.Enabled:=TRUE;
  ZApproachBar.Max:=65535;
  ZApproachBar.Min:=0;
  ZApproachBar.Position:=MicronsToProgressBar(CurrentZ);
  ScanRangeComboBox.Items:=ScanRangeStringList;
  ScanRangeComboBox.ItemIndex:=ScanRangeIndex;
  ScanRange:=ScanRanges[ScanRangeIndex].Range;  //in microns
  ScanRangeVoltage:=ScanRanges[ScanRangeIndex].Voltage;
  GenerateLUT(ScanRangeIndex);
  Scanning:=FALSE;
  PropEdit.Text:=FloatToStr(PropCoff);
  IntEdit.Text:=FloatToStr(IntTime/1E6);  //IntTime and DiffTime are specified in nanoseconds
  DiffEdit.Text:=FloatToStr(DiffTime/1E6);//while the user input is in milliseconds

  if OutputPhase>0 then
    ErrorCorrectionSpinEdit.Value:=1
   else ErrorCorrectionSpinEdit.Value:=-1;

  SetPointEdit.Text:=FloatToStr(SetPoint);

  if ScanAxis = XAxis then ScanDirectionComboBox.ItemIndex:=0
              else if ScanAxis = YAxis then ScanDirectionComboBox.ItemIndex:=1;



  //Next, we specify that the number of PID_averages is consistent with half
  //of the DwellTime
  AveragesEdit.MaxValue:=round((DwellTime*1E6)/(2*PIDLoop_time));
  PID_Averages:=AveragesEdit.MaxValue;
  AveragesEdit.Value:=PID_averages;
  DwellTimeEdit.MinValue:=round((2*PIDLoop_time)/1000000);  //in msec
  if DwellTimeEdit.MinValue<1 then DwellTimeEdit.MinValue:=1;
  DwellTimeEdit.Value:=DwellTime;
  StepXEdit.Caption:=FloatToStr(StepX);
  StepYEdit.Caption:=FloatToStr(StepY);
  StepZEdit.Caption:=FloatToStr(StepY);
end;

procedure TMFMForm.IntEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then
    begin
      IntTime:=round(1E6*StrToFloat(IntEdit.Text));
      PIDParametersChanged:=1;
    end;
end;

procedure TMFMForm.PropEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then
    begin
      PropCoff:=StrToFloat(PropEdit.Text);
      PIDParametersChanged:=1;
    end;
end;

procedure TMFMForm.ScaleMaxEditKeyPress(Sender: TObject; var Key: char);
var
  Value : Real;
begin
  if Key=Chr(13) then
    begin
      Value:=StrToFloat(ScaleMaxEdit.Text);
      TopoIntegerScaleMax:=MicronsToProgressBar(Value);
      If ((TopoIntegerScaleMax<TopoIntegerScaleMin) and (TopoIntegerScaleMax<65535)) then
          TopoIntegerScaleMax:=TopoIntegerScaleMin+1;
      RescaleTopoImage:=TRUE;
    end;
end;

procedure TMFMForm.ScaleMinEditKeyPress(Sender: TObject; var Key: char);
var
  Value : Real;
begin
  if Key=Chr(13) then
    begin
      Value:=StrToFloat(ScaleMinEdit.Text);
      TopoIntegerScaleMin:=MicronsToProgressBar(Value);
      If ((TopoIntegerScaleMin>TopoIntegerScaleMax) and (TopoIntegerScaleMin>0)) then
          TopoIntegerScaleMin:=TopoIntegerScaleMax-1;
      RescaleTopoImage:=TRUE;
    end;
end;

procedure TMFMForm.ScanDirectionComboBoxChange(Sender: TObject);
begin
  if ScanDirectionComboBox.ItemIndex = 0 then ScanAxis:=XAxis
     else if ScanDirectionComboBox.ItemIndex=1 then ScanAxis:=YAxis;
end;

procedure TMFMForm.ScanRangeComboBoxSelect(Sender: TObject);
var Target: real;
begin
  //We need to first move to 0, 0 in order not to be beyond the scan range
  //first X
  Target:= ScanRanges[ScanRangeComboBox.ItemIndex].Range/2;
  if CurrentX>Target then MoveToX(Target, StepX, 0);
  Target:= -ScanRanges[ScanRangeComboBox.ItemIndex].Range/2;
  if CurrentX<Target then MoveToX(Target, StepX, 0);

  //now Y
  Target:= ScanRanges[ScanRangeComboBox.ItemIndex].Range/2;
  if CurrentY>Target then MoveToY(Target, StepX, 0);
  Target:= -ScanRanges[ScanRangeComboBox.ItemIndex].Range/2;
  if CurrentY<Target then MoveToY(Target, StepX, 0);

  //Now we can change the range
  ScanRangeIndex:=ScanRangeComboBox.ItemIndex;
  ScanRange:=ScanRanges[ScanRangeIndex].Range;  //in microns
  ScanRangeVoltage:=ScanRanges[ScanRangeIndex].Voltage;
  GenerateLUT(ScanRangeIndex);

end;

procedure TMFMForm.ScanResolutionComboBoxSelect(Sender: TObject);
begin
    case ScanResolutionComboBox.ItemIndex of
    0: ScanResolution:=128;
    1: ScanResolution:=256;
    2: ScanResolution:=512;
    3: ScanResolution:=1024;
  end;
  ForwardTopoImageBitMap.SetSize(ScanResolution, ScanResolution);
  ReverseTopoImageBitMap.SetSize(ScanResolution, ScanResolution);
  ForwardMFMImageBitMap.SetSize(ScanResolution, ScanResolution);
  ReverseMFMImageBitMap.SetSize(ScanResolution, ScanResolution);
end;

procedure TMFMForm.SetPointEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then SetPoint:=StrToFloat(SetPointEdit.Text);
end;

procedure TMFMForm.SetXEditKeyPress(Sender: TObject; var Key: char);
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

procedure TMFMForm.StepXEditKeyPress(Sender: TObject; var Key: char);
begin
    if Key=Chr(13) then StepX:=StrToFloat(StepXEdit.Text);
end;

procedure TMFMForm.StepYEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then StepY:=StrToFloat(StepYEdit.Text);
end;

procedure TMFMForm.StepZEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then StepZ:=StrToFloat(StepZEdit.Text);
end;

procedure TMFMForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ForwardTopoImageBitMap.Free;
  ReverseTopoImageBitMap.Free;
  ForwardMFMImageBitMap.Free;
  ReverseMFMImageBitMap.Free;
  If InFeedback then EngageFeedbackBtnClick(Sender);  // stop if we are in feedback
end;

procedure TMFMForm.EngageFeedbackBtnClick(Sender: TObject);
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
      FirstPIDPass := 1; //This is the first PID pass
      PIDParametersChanged:=0; //PID parameters have not changed (yet)
      pid_loop_running:=1;
      StartFeedback;
    end;
end;

procedure TMFMForm.ErrorCorrectionSpinEditChange(Sender: TObject);
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

procedure TMFMForm.AveragesEditChange(Sender: TObject);
begin
  PID_averages:=AveragesEdit.Value;
end;

procedure TMFMForm.DataTimerTimer(Sender: TObject);
var
    Ch0Reading,
    Ch1Reading      : real;
begin
  if InFeedback then
    begin
      //DataTimer.Interval:=100; //in msec
      FeedbackChannelReading:=ReadFeedbackChannel;
      FeedbackOutputLabel.Caption:=FloatToStrF(FeedbackChannelReading, ffFixed, 10, 4);
      CurrentZ:=ZVoltageToMicrons(AveragedPIDOutput);
      ErrorSignalLabel.Caption:=FloatToStrF(PIDOutputVariance, ffExponent, 10, 4);
    end
   else
     begin
       //DataTimer.Interval:=1000;
       Ch0Reading:=ReadChannel(Ch0Input);
       FeedbackChannelReading:=ReadFeedbackChannel;
       Ch1Reading:=ReadChannel(Ch1Input);
       Ch0OutputLabel.Caption:=FloatToStrF(Ch0Reading, ffFixed, 10, 4);
       Ch1OutputLabel.Caption:=FloatToStrF(Ch1Reading, ffFixed, 10, 4);
       FeedbackOutputLabel.Caption:=FloatToStrF(FeedbackChannelReading, ffFixed, 10, 4);
       ErrorSignalLabel.Caption:=FloatToStrF(PIDOutputVariance, ffExponent, 10, 4);
     end;

      UpdateXYPositionIndicators;
      UpdateZPositionIndicators;
end;

procedure TMFMForm.DwellTimeEditChange(Sender: TObject);
begin
  DwellTime:=DwellTimeEdit.Value;
  AveragesEdit.MaxValue:=round((DwellTime*1E6)/(2*PIDLoop_time));
  if PID_averages>AveragesEdit.MaxValue then PID_averages:=AveragesEdit.MaxValue;
  AveragesEdit.Value:=PID_averages;
end;

function TMFMForm.UpdateZPositionIndicators: boolean;
begin
  ZApproachBar.Position:=MicronsToProgressBar(CurrentZ);
  //SetZEdit.Text:=FloatToStrF(CurrentZ, ffFixed, 10, 4);
  ZPositionText.Caption:='Z: '+ FloatToStrF(CurrentZ, ffFixed, 10, 4);
  UpdateZPositionIndicators:=TRUE;
end;

function TMFMForm.UpdateXYPositionIndicators: boolean;
begin
  //SetXEdit.Text:=FloatToStrF(CurrentX, ffFixed, 10, 4);
  //SetYEdit.Text:=FloatToStrF(CurrentY, ffFixed, 10, 4);
  XPositionText.Caption:='X: '+ FloatToStrF(CurrentX, ffFixed, 10, 4);
  YPositionText.Caption:='Y: '+ FloatToStrF(CurrentY, ffFixed, 10, 4);
  UpdateXYPositionIndicators:=TRUE;
end;

initialization
  {$I mfm.lrs}
  ScanResolution:=256;

end.

