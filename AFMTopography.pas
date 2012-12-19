unit AFMTopography;

{$MODE Delphi}
//{$mode objfpc}{$H+}

interface

uses
  {$IFNDEF LCL} Windows, Messages, {$ELSE} LclIntf, LMessages, LclType, {$ENDIF}
SysUtils, Classes, Graphics, Controls, Forms, Dialogs, ExtCtrls, StdCtrls,
Buttons, ComCtrls, Spin, LResources, GlobalVariables, Plotpanel;

type

  { TAFMTopograph }

TAFMTopograph = class(TForm)
  LevelImageCheckBox: TCheckBox;
  LogarithmicCheckBox: TCheckBox;
DescriptionEdit: TEdit;
Label20: TLabel;
SaveAsGSFFileButton: TButton;
SaveAsTextFileButton: TButton;
FileSaveGroupBox: TGroupBox;
RescaleButton: TButton;
Label19: TLabel;
FileSaveDialog: TSaveDialog;
ScaleMaxEdit: TEdit;
ScaleMinEdit: TEdit;
IndicatorImage: TImage;
Label14: TLabel;
Label18: TLabel;
ScanDirectionComboBox: TComboBox;
ScanRangeComboBox: TComboBox;
ForwardImage: TImage;
Label17: TLabel;
ReverseImage: TImage;
Label1: TLabel;
Label2: TLabel;
Scan_Tube_GroupBox: TGroupBox;
SetXLabel: TLabel;
Label8: TLabel;
Label9: TLabel;
Label10: TLabel;
Bevel1: TBevel;
Bevel3: TBevel;
Label12: TLabel;
Bevel2: TBevel;
SetXEdit: TEdit;
SetYEdit: TEdit;
SetZEdit: TEdit;
StatusBar: TStatusBar;
StepXEdit: TLabeledEdit;
StepYEdit: TLabeledEdit;
StepZEdit: TLabeledEdit;
DataTimer: TTimer;
XPositionText: TStaticText;
ZPositionText: TStaticText;
YPositionText: TStaticText;
ZApproachBar: TProgressBar;
ScanStartGroupBox: TGroupBox;
Label3: TLabel;
Label4: TLabel;
Ch0OutputLabel: TLabel;
Ch1OutputLabel: TLabel;
Bevel6: TBevel;
Bevel8: TBevel;
Label7: TLabel;
FeedbackOutputLabel: TLabel;
SetPointEdit: TLabeledEdit;
ScanStartBtn: TBitBtn;
GroupBox1: TGroupBox;
EngageFeedbackBtn: TButton;
ErrorCorrectionSpinEdit: TSpinEdit;
Label5: TLabel;
ScanResolutionComboBox: TComboBox;
Label6: TLabel;
PID: TLabel;
Bevel4: TBevel;
PropEdit: TLabeledEdit;
IntEdit: TLabeledEdit;
DiffEdit: TLabeledEdit;
Label11: TLabel;
ErrorSignalLabel: TLabel;
Label13: TLabel;
DwellTimeEdit: TSpinEdit;
AveragesEdit: TSpinEdit;
Label15: TLabel;
Label16: TLabel;
procedure AveragesEditChange(Sender: TObject);
procedure DwellTimeEditChange(Sender: TObject);
procedure DataTimerTimer(Sender: TObject);
procedure LevelImageRadioButtonClick(Sender: TObject);
procedure LogarithmicCheckBoxClick(Sender: TObject);
procedure RescaleButtonClick(Sender: TObject);
procedure SaveAsGSFFileButtonClick(Sender: TObject);
procedure SaveAsTextFileButtonClick(Sender: TObject);
procedure ScaleMaxEditKeyPress(Sender: TObject; var Key: char);
procedure ScaleMinEditKeyPress(Sender: TObject; var Key: char);
procedure ScanDirectionComboBoxChange(Sender: TObject);
procedure ScanRangeComboBoxSelect(Sender: TObject);
procedure ScanResolutionComboBoxSelect(Sender: TObject);
procedure ScanStartBtnClick(Sender: TObject);
procedure EngageFeedbackBtnClick(Sender: TObject);
procedure DiffEditKeyPress(Sender: TObject; var Key: Char);
procedure IntEditKeyPress(Sender: TObject; var Key: Char);
procedure PropEditKeyPress(Sender: TObject; var Key: Char);
procedure ErrorCorrectionSpinEditChange(Sender: TObject);
procedure SetPointEditKeyPress(Sender: TObject; var Key: Char);
    //procedure DataTimer(Sender: TObject);
procedure StepZEditKeyPress(Sender: TObject; var Key: Char);
procedure StepYEditKeyPress(Sender: TObject; var Key: Char);
procedure StepXEditKeyPress(Sender: TObject; var Key: Char);
procedure SetZEditKeyPress(Sender: TObject; var Key: Char);
procedure SetYEditKeyPress(Sender: TObject; var Key: Char);
procedure SetXEditKeyPress(Sender: TObject; var Key: Char);
procedure FormClose(Sender: TObject; var Action: TCloseAction);
procedure FormShow(Sender: TObject);
private
    { Private declarations }
public
    { Public declarations }
function UpdateZPositionIndicators: boolean;
function UpdateXYPositionIndicators: boolean;
function UpdateScanImages(ScanAxis: Axis; i, j: integer): boolean;
procedure ReplotImages(ScanAxis: Axis; ScannedLines: integer);

end;

var
AFMTopograph: TAFMTopograph;

implementation
uses ScanTubeFunctions, GlobalFunctions, FileFunctions, Oscilloscope,
     DAQFunctions, rtai_comedi_functions, rtai_comedi_types, BGRABitmap, BGRABitmapTypes;
var
  ForwardImageBitmap,
  ReverseImageBitmap,
  StretchedForwardBitmap,
  StretchedReverseBitmap    : TBGRABitmap;
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
  RescaleImage        : boolean = FALSE;
  LevelImage          : boolean = FALSE;


{$IFNDEF LCL}
{$R *.dfm}
{$ELSE}
{$R *.lfm}
{$ENDIF}

procedure TAFMTopoGraph.ReplotImages(ScanAxis: Axis; ScannedLines: integer);
var
   p, q: PBGRAPixel;
   x, y, i, j: integer;

begin
case ScanAxis of
  XAxis:  //this is the default case:  j corresponds to the y iteration and i to
            //the x-iteration
    begin
    //forward bitmap
      for j:=0 to ScannedLines do
        begin
          p:=ForwardImageBitMap.ScanLine[j];
          q:=ReverseImageBitMap.ScanLine[j];
          for x:=0 to ForwardImageBitMap.Width-1 do
            begin
              if LevelImage then
                begin
                  p^:= ZMicronsToRGBColor(ForwardLeveledData[x,j],
                       TopoIntegerScaleMin, TopoIntegerScaleMax);
                  q^:= ZMicronsToRGBColor(ReverseLeveledData[x,j],
                       TopoIntegerScaleMin, TopoIntegerScaleMax);
                end
               else
                begin
                  p^:= ZMicronsToRGBColor(ForwardData[x,j],
                       TopoIntegerScaleMin, TopoIntegerScaleMax);
                  q^:= ZMicronsToRGBColor(ReverseData[x,j],
                       TopoIntegerScaleMin, TopoIntegerScaleMax);
                end;
              inc(p);
              inc(q);
            end;
        end;
    end;

YAxis: //Along the y axis.
  begin
    for y:=0 to ForwardImageBitMap.Height-1 do
      begin
        p:=ForwardImageBitMap.ScanLine[y];
        q:=ReverseImageBitMap.ScanLine[y];
        for i:=0 to ScannedLines do
          begin
            if LevelImage then
              begin
                p^:= ZMicronsToRGBColor(ForwardLeveledData[j,y],
                     TopoIntegerScaleMin, TopoIntegerScaleMax);
                q^:= ZMicronsToRGBColor(ReverseLeveledData[j,y],
                     TopoIntegerScaleMin, TopoIntegerScaleMax);
              end
             else
               begin
                 p^:= ZMicronsToRGBColor(ForwardData[j,y],
                      TopoIntegerScaleMin, TopoIntegerScaleMax);
                 q^:= ZMicronsToRGBColor(ReverseData[j,y],
                      TopoIntegerScaleMin, TopoIntegerScaleMax);
               end;
            inc(q);
            inc(p);
          end;
      end;
    end;
end;

ForwardImageBitMap.InvalidateBitmap;
ReverseImageBitMap.InvalidateBitmap;
StretchedForwardBitmap:=ForwardImageBitmap.Resample(ForwardImage.ClientWidth,
ForwardImage.ClientHeight)as TBGRABitmap;
StretchedForwardBitmap.Draw(ForwardImage.Canvas, 0, 0, True);
StretchedForwardBitmap.Free;
ForwardImage.Invalidate;
StretchedReverseBitmap:=ReverseImageBitmap.Resample(ReverseImage.ClientWidth,
ReverseImage.ClientHeight)as TBGRABitmap;
StretchedReverseBitmap.Draw(ReverseImage.Canvas, 0, 0, True);
StretchedReverseBitmap.Free;
ReverseImage.Invalidate;
GenerateScale(IndicatorImage, TopoIntegerScaleMin, TopoIntegerScaleMax);
RescaleImage:=FALSE;
end;

procedure TAFMTopograph.EngageFeedbackBtnClick(Sender: TObject);
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

procedure TAFMTopograph.AveragesEditChange(Sender: TObject);
begin
  PID_averages:=AveragesEdit.Value;
end;

procedure TAFMTopograph.DataTimerTimer(Sender: TObject);
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
      ErrorSignalLabel.Caption:=FloatToStrF(PIDOutputVariance, ffFixed, 10, 4);
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
      ErrorSignalLabel.Caption:=FloatToStrF(PIDOutputVariance, ffFixed, 10, 4);
    end;

  UpdateXYPositionIndicators;
  UpdateZPositionIndicators;

end;

procedure TAFMTopograph.LevelImageRadioButtonClick(Sender: TObject);
begin
  if LevelImage then
    begin
      LevelImage:=FALSE;
      LevelImageCheckBox.State:=cbUnChecked;
    end
   else
    begin
     LevelImage:=TRUE;
     LevelImageCheckBox.State:=cbChecked;
   end;
 //ReplotImages;
end;

procedure TAFMTopograph.LogarithmicCheckBoxClick(Sender: TObject);
begin
  if LogarithmicCheckBox.State=cbChecked then Logarithmic:=1 else Logarithmic:=0;
end;

procedure TAFMTopograph.RescaleButtonClick(Sender: TObject);
begin
  RescaleImage:=TRUE;
end;

procedure TAFMTopograph.SaveAsGSFFileButtonClick(Sender: TObject);
var
  ForwardFileName,
  ReverseFileName,
  BaseFileName: string;
begin
  if FileSaveDialog.Execute then
    begin
      if (LowerCase(ExtractFileExt(FileSaveDialog.FileName))='.gsf') then
        begin
          //Set the working directory to the directory of the file
          FileSaveDialog.InitialDir:=ExtractFilePath(FileSaveDialog.FileName);
          BaseFileName:=Copy(ExtractFileName(FileSaveDialog.FileName), 1,
                                           Length(FileSaveDialog.Filename)-4);
          ForwardFileName:=BaseFileName+'-for.gsf';
          ReverseFileName:=BaseFileName+'-rev.gsf';
          WriteGwyddionSimpleFieldFile( ForwardFileName,
                                        DescriptionEdit.Text,
                                        ScanResolution, ScanResolution,
                                        ScanRange, ScanRange,
                                        'm', 'm',
                                        ForwardData);

          WriteGwyddionSimpleFieldFile( ReverseFileName,
                                        DescriptionEdit.Text,
                                        ScanResolution, ScanResolution,
                                        ScanRange, ScanRange,
                                        'm', 'm',
                                        ReverseData);

        end;
    end;
end;

procedure TAFMTopograph.SaveAsTextFileButtonClick(Sender: TObject);
var
  ForwardFileName,
  ReverseFileName,
  BaseFileName: string;
begin
  if FileSaveDialog.Execute then
    begin
      if (LowerCase(ExtractFileExt(FileSaveDialog.FileName))='.dat') then
        begin
          //Set the working directory to the directory of the file
          FileSaveDialog.InitialDir:=ExtractFilePath(FileSaveDialog.FileName);

          BaseFileName:=Copy(ExtractFileName(FileSaveDialog.FileName), 1,
                                           Length(FileSaveDialog.Filename)-4);
          ForwardFileName:=BaseFileName+'-for.dat';
          ReverseFileName:=BaseFileName+'-rev.dat';
          WriteTextDataFile( ForwardFileName,
                             DescriptionEdit.Text,
                             ScanResolution, ScanResolution,
                             ScanRange, ScanRange,
                             'm', 'm',
                             ForwardData);

                             WriteTextDataFile( ReverseFileName,
                             DescriptionEdit.Text,
                             ScanResolution, ScanResolution,
                             ScanRange, ScanRange,
                             'm', 'm',
                             ReverseData);
        end;
    end;
end;



procedure TAFMTopograph.ScaleMaxEditKeyPress(Sender: TObject; var Key: char);
var
  Value : Real;
begin
  if Key=Chr(13) then
    begin
      Value:=StrToFloat(ScaleMaxEdit.Text);
      TopoIntegerScaleMax:=MicronsToProgressBar(Value);
      If ((TopoIntegerScaleMax<TopoIntegerScaleMin) and (TopoIntegerScaleMax<65535)) then
                          TopoIntegerScaleMax:=TopoIntegerScaleMin+1;
      OscilloscopeForm.OscilloscopeChart.LeftAxis.Range.Max:=Value;
      RescaleImage:=TRUE;
    end;
end;

procedure TAFMTopograph.ScaleMinEditKeyPress(Sender: TObject; var Key: char);
var
  Value : Real;
begin
  if Key=Chr(13) then
    begin
      Value:=StrToFloat(ScaleMinEdit.Text);
      TopoIntegerScaleMin:=MicronsToProgressBar(Value);
      If ((TopoIntegerScaleMin>TopoIntegerScaleMax) and (TopoIntegerScaleMin>0)) then
                TopoIntegerScaleMin:=TopoIntegerScaleMax-1;
      OscilloscopeForm.OscilloscopeChart.LeftAxis.Range.Min:=Value;
      RescaleImage:=TRUE;
    end;
end;


procedure TAFMTopograph.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ForwardImageBitMap.Free;
  ReverseImageBitMap.Free;
  if InFeedback then
    begin  //stop the feedback
      InFeedback:=FALSE;
      EngageFeedbackBtn.Caption:='Start Feedback';
      pid_loop_running:=0;
      EndFeedback;
    end;
end;

procedure TAFMTopograph.FormShow(Sender: TObject);

begin
  TopoIntegerScaleMax:=MicronsToProgressBar(MaxZPosition);
  TopoIntegerScaleMin:=MicronsToProgressBar(MinZPosition);
  if (Logarithmic=1) then LogarithmicCheckBox.State:=cbChecked else LogarithmicCheckBox.State:=cbUnchecked;
  //TopoIntegerScaleMax:=40000;
  //TopoIntegerScaleMin:=32000;
  ScaleMaxEdit.Text:=FloatToStr(MaxZPosition);
  ScaleMinEdit.Text:=FloatToStr(MinZPosition);
  ForwardImageBitMap:=TBGRABitMap.Create(ScanResolution, ScanResolution, BGRABlack);
  ReverseImageBitMap:=TBGRABitMap.Create(ScanResolution, ScanResolution, BGRABlack);

  StretchedForwardBitmap:=ForwardImageBitmap.Resample(ForwardImage.ClientWidth,
  ForwardImage.ClientHeight)as TBGRABitmap;
  StretchedForwardBitmap.Draw(ForwardImage.Canvas, 0, 0, True);
  StretchedForwardBitmap.Free;
  StretchedReverseBitmap:=ReverseImageBitmap.Resample(ReverseImage.ClientWidth,
  ReverseImage.ClientHeight)as TBGRABitmap;
  StretchedReverseBitmap.Draw(ReverseImage.Canvas, 0, 0, True);
  StretchedReverseBitmap.Free;

  //Now generate the indicator bar
  GenerateScale(IndicatorImage, TopoIntegerScaleMin, TopoIntegerScaleMax);

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

  if ScanAxis = XAxis then
    ScanDirectionComboBox.ItemIndex:=0
   else if ScanAxis = YAxis then
    ScanDirectionComboBox.ItemIndex:=1;



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
 LevelImage:=FALSE;
 LevelImageCheckBox.State:=cbUnchecked;
end;

procedure TAFMTopograph.IntEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then
    begin
      IntTime:=round(1E6*StrToFloat(IntEdit.Text));
      PIDParametersChanged:=1;
    end;
end;

procedure TAFMTopograph.PropEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then
    begin
      PropCoff:=StrToFloat(PropEdit.Text);
      PIDParametersChanged:=1;
    end;
end;

procedure TAFMTopograph.SetPointEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then SetPoint:=StrToFloat(SetPointEdit.Text);
end;

procedure TAFMTopograph.SetXEditKeyPress(Sender: TObject; var Key: Char);
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

procedure TAFMTopograph.SetYEditKeyPress(Sender: TObject; var Key: Char);
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

procedure TAFMTopograph.SetZEditKeyPress(Sender: TObject; var Key: Char);
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


procedure TAFMTopograph.ScanResolutionComboBoxSelect(Sender: TObject);
begin
  case ScanResolutionComboBox.ItemIndex of
    0: ScanResolution:=128;
    1: ScanResolution:=256;
    2: ScanResolution:=512;
    3: ScanResolution:=1024;
  end;
  ForwardImageBitMap.SetSize(ScanResolution, ScanResolution);
  ReverseImageBitMap.SetSize(ScanResolution, ScanResolution);
end;

procedure TAFMTopograph.ScanStartBtnClick(Sender: TObject);
  var
    ScanXStep,
    ScanYStep     : real; //step size of x and y points in the scan
    i, j
                  : integer;
    ForwardLineScanData,
    ReverseLineScanData,
    XPoints, XPointsReversed,
    LeveledSingleLineForwardData,
    LeveledSingleLineReverseData  : TScanData;
    StartX, StartY   : real;
begin
  if Scanning then //stop the scan
    begin
      Scanning:=FALSE;
      ScanStartBtn.Caption:='Start Scan';
      DataTimer.Interval:=1000;
      StatusBar.SimpleText:='Idle';

      //Need to re-enable a bunch of things
      EngageFeedbackBtn.Enabled:=TRUE;
      SetXEdit.Enabled:=TRUE;
      SetYEdit.Enabled:=TRUE;
      SetZEdit.Enabled:=TRUE;
      StepXEdit.Enabled:=TRUE;
      StepYEdit.Enabled:=TRUE;
      StepZEdit.Enabled:=TRUE;
      ErrorCorrectionSpinEdit.Enabled:=TRUE;
      ScanResolutionComboBox.Enabled:=TRUE;
      ScanRangeComboBox.Enabled:=TRUE;
      DwellTimeEdit.Enabled:=TRUE;
      AveragesEdit.Enabled:=TRUE;
      ScanDirectionComboBox.Enabled:=TRUE;
    end
   else
    begin
      //Need to disable a number of things!
      //Need to re-enable a bunch of things
      EngageFeedbackBtn.Enabled:=FALSE;
      SetXEdit.Enabled:=FALSE;
      SetYEdit.Enabled:=FALSE;
      SetZEdit.Enabled:=FALSE;
      StepXEdit.Enabled:=FALSE;
      StepYEdit.Enabled:=FALSE;
      StepZEdit.Enabled:=FALSE;
      ErrorCorrectionSpinEdit.Enabled:=FALSE;
      ScanResolutionComboBox.Enabled:=FALSE;
      ScanRangeComboBox.Enabled:=FALSE;
      DwellTimeEdit.Enabled:=FALSE;
      AveragesEdit.Enabled:=FALSE;
      ScanDirectionComboBox.Enabled:=FALSE;

      DataTimer.Interval:=100;
      StatusBar.SimpleText:='Starting Scan';
      Scanning:=TRUE;
      ScanStartBtn.Caption:='Stop Scan';

      //Now calculate some scan parameters based on chosen values
      ScanXPlusLimit:=ScanRange/2;
      ScanXMinusLimit:=-ScanRange/2;
      ScanYPlusLimit:=ScanRange/2;
      ScanYMinusLimit:=-ScanRange/2;
      ScanXStep:=ScanRange/ScanResolution;
      ScanYStep:=ScanRange/ScanResolution;
      StartY:=ScanYPlusLimit;

      //Set the dimensions of the data arrays
      //first index corresponds to X, second index to y
      SetLength(ForwardData, ScanResolution, ScanResolution);
      SetLength(ReverseData, ScanResolution, ScanResolution);
      SetLength(ForwardLeveledData, ScanResolution, ScanResolution);
      SetLength(ReverseLeveledData, ScanResolution, ScanResolution);
      SetLength(ForwardLineScanData, ScanResolution);
      SetLength(ReverseLineScanData, ScanResolution);
      SetLength(XPoints, ScanResolution);
      SetLength(XPointsReversed, ScanResolution);
      SetLength(LeveledSingleLineForwardData, ScanResolution);
      SetLength(LeveledSingleLineReverseData, ScanResolution);

      //In order to get rid of hysteresis effects, we first move to the corner
      //opposite to the corner that we wish to start the scan
      //Scan will start from X=ScanMinusLimit and Y=ScanPlusLimit
      //so we move to X=ScanPlusLimit and Y=ScanMinusLimit first
      StatusBar.SimpleText:='Moving to opposite corner from scan start';
      MoveToX(ScanXPlusLimit, StepX, 0);
      MoveToY(ScanYMinusLimit, StepY, 0); //Set StepDelay to 0
      //MoveToX(ScanXPlusLimit, StepX, StepDelay);
      //MoveToY(ScanYMinusLimit, StepY, StepDelay);

      //determine what the Feedbackreading is at this point
      //This is in order to level the scan for plotting
      fastdelay(10); //wait for 10 msec

      StatusBar.SimpleText:='Moving to scan start position';
      MoveToX(ScanXMinusLimit, StepX, 0);
      MoveToY(ScanYPlusLimit, StepY, 0);
      //MoveToX(ScanXMinusLimit, StepX, StepDelay);
      //MoveToY(ScanYPlusLimit, StepY, StepDelay);

      //read the initial scan point
      fastdelay(10); //wait for 10 msec

      j:=0;
      //Now start the scan
      case ScanAxis of

        XAxis:
          begin
            //Set the limits of the Oscilloscope
            OscilloscopeForm.OscilloscopeChart.BottomAxis.Range.Min:=ScanXMinusLimit;
            OscilloscopeForm.OscilloscopeChart.BottomAxis.Range.Max:=ScanXPlusLimit;
            //Fill in XPoints with the X positions of the scan
            //This is for the line by line leveling, and could also apply to
            //scanning along the y direction
            for i:=0 to ScanResolution-1 do XPoints[i]:=ScanXMinusLimit + i*ScanXStep;
            for i:=0 to ScanResolution-1 do XPointsReversed[i]:=Xpoints[ScanResolution-1-i];

            while ((j<ScanResolution) and Scanning) do //this is the y iteration
              begin
                //initialize the Oscilloscope Plot
                OscilloscopeForm.OscilloscopeChartLineSeries1.Clear;
                OscilloscopeForm.OscilloscopeChartLineSeries2.Clear;
                OscilloscopeForm.OscilloscopeChartLineSeries3.Clear;
                OscilloscopeForm.OscilloscopeChartLineSeries4.Clear;
                fastdelay(10*DwellTime); //Delay at beginning of scan to relax
                StartX:=ScanXMinusLimit;
                StatusBar.SimpleText:='Scanning forward line '+ IntToStr(j+1);
                ForwardLineScanData:= XLineScan(ScanResolution, StartX, ScanXStep,
                                      DwellTime, PID_Averages);  //Forward direction
                fastdelay(10*DwellTime); //Delay at beginning of scan to relax
                StartX:=ScanXPlusLimit;
                StatusBar.SimpleText:='Scanning reverse line '+ IntToStr(j+1);
                ReverseLineScanData:= XLineScan(ScanResolution, StartX, -ScanXStep,
                                      DwellTime, PID_Averages);  //Reverse direction

                //Generate the leveled data
                LeveledSingleLineForwardData:=LeveledScanData(XPoints, ForwardLineScanData);
                LeveledSingleLineReverseData:=LeveledScanData(XPointsReversed, ReverseLineScanData);

                i:=0;
                while ((i<ScanResolution) and Scanning) do  //this is the X iteration
                  begin
                    ForwardData[i,j]:=ForwardLineScanData[i];
                    ReverseData[i,j]:=ReverseLineScanData[ScanResolution-1-i];//Need to reverse
                    ForwardLeveledData[i,j]:=LeveledSingleLineForwardData[i];
                    //Manan changed to see if it helps in giving identical forward and reverse images
                    //ReverseData[i,j]:=LeveledSingleLineReverseData[ScanResolution-1-i];//Need to reverse
                    ReverseLeveledData[i,j]:=LeveledSingleLineReverseData[ScanResolution-1-i];//Need to reverse
                    inc(i);
                  end;

                StartY:=StartY - ScanYStep;
                MoveToY(StartY, StepY, 0);
                if RescaleImage then ReplotImages(ScanAxis, j);
                UpdateScanImages(ScanAxis, i, j);
                UpdateXYPositionIndicators;
                UpdateZPositionIndicators;
                inc(j);
              end;
          end;

        YAxis:
          begin
            //Set the limits of the Oscilloscope
            OscilloscopeForm.OscilloscopeChart.BottomAxis.Range.Min:=ScanYPlusLimit;
            OscilloscopeForm.OscilloscopeChart.BottomAxis.Range.Max:=ScanYMinusLimit;
            //Fill in XPoints with the Y positions of the scan
            //This is for the line by line leveling, and could also apply to
            //scanning along the y direction

            for i:=0 to ScanResolution-1 do XPoints[i]:=ScanYPlusLimit - i*ScanYStep;
            for i:=0 to ScanResolution-1 do XPointsReversed[i]:=Xpoints[ScanResolution-1-i];
            while ((j<ScanResolution) and Scanning) do //this is the x iteration
              begin
                //initialize the Oscilloscope Plot
                OscilloscopeForm.OscilloscopeChartLineSeries1.Clear;
                OscilloscopeForm.OscilloscopeChartLineSeries2.Clear;
                OscilloscopeForm.OscilloscopeChartLineSeries3.Clear;
                OscilloscopeForm.OscilloscopeChartLineSeries4.Clear;
                fastdelay(10*DwellTime); //Delay at beginning of scan to relax
                StartY:=ScanYPlusLimit;
                StatusBar.SimpleText:='Scanning downward line '+ IntToStr(j+1);
                ForwardLineScanData:= YLineScan(ScanResolution, StartY, -ScanYStep,
                                      DwellTime, PID_Averages);  //Downward direction
                fastdelay(10*DwellTime); //Delay at beginning of scan to relax
                StartY:=ScanYMinusLimit;
                StatusBar.SimpleText:='Scanning downward line '+ IntToStr(j+1);
                ReverseLineScanData:= YLineScan(ScanResolution, StartY, +ScanXStep,
                                      DwellTime, PID_Averages);  //Upward direction

                //Generate the leveled data
                LeveledSingleLineForwardData:=LeveledScanData(XPoints, ForwardLineScanData);
                LeveledSingleLineReverseData:=LeveledScanData(XPointsReversed, ReverseLineScanData);

                i:=0;
                while ((i<ScanResolution) and Scanning) do  //this is the Y iteration
                  begin
                    ForwardData[j,i]:=ForwardLineScanData[i];
                    ReverseData[j,i]:=ReverseLineScanData[ScanResolution-1-i];//Need to reverse
                    ForwardLeveledData[j,i]:=LeveledSingleLineForwardData[i];
                    //Manan changed to see if it helps in giving identical forward and reverse images
                    //ReverseData[j,i]:=LeveledSingleLineReverseData[ScanResolution-1-i];//Need to reverse
                    ReverseLeveledData[i,j]:=LeveledSingleLineReverseData[ScanResolution-1-i];//Need to reverse
                    inc(i);
                  end;
                StartX:=StartX + ScanXStep;
                MoveToX(StartX, StepX, 0);
                if RescaleImage then ReplotImages(ScanAxis, j);
                UpdateScanImages(ScanAxis, i, j);
                UpdateXYPositionIndicators;
                UpdateZPositionIndicators;
                inc(j);
              end;
          end;
      end;
      StatusBar.SimpleText:='Idle';
      Scanning:=FALSE;
      ScanStartBtn.Caption:='Start Scan';

      //Need to re-enable a bunch of things
      EngageFeedbackBtn.Enabled:=TRUE;
      SetXEdit.Enabled:=TRUE;
      SetYEdit.Enabled:=TRUE;
      SetZEdit.Enabled:=TRUE;
      StepXEdit.Enabled:=TRUE;
      StepYEdit.Enabled:=TRUE;
      StepZEdit.Enabled:=TRUE;
      ErrorCorrectionSpinEdit.Enabled:=TRUE;
      ScanResolutionComboBox.Enabled:=TRUE;
      ScanRangeComboBox.Enabled:=TRUE;
      DwellTimeEdit.Enabled:=TRUE;
      AveragesEdit.Enabled:=TRUE;
      ScanDirectionComboBox.Enabled:=TRUE;

    end;
end;

procedure TAFMTopograph.StepXEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then StepX:=StrToFloat(StepXEdit.Text);
end;

procedure TAFMTopograph.StepYEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then StepY:=StrToFloat(StepYEdit.Text);
end;

procedure TAFMTopograph.StepZEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then StepZ:=StrToFloat(StepZEdit.Text);
end;

{-----------------------------------------------------------------------------}
function TAFMTopoGraph.UpdateZPositionIndicators: boolean;
begin
  ZApproachBar.Position:=MicronsToProgressBar(CurrentZ);
  //SetZEdit.Text:=FloatToStrF(CurrentZ, ffFixed, 10, 4);
  ZPositionText.Caption:='Z: '+ FloatToStrF(CurrentZ, ffFixed, 10, 4);
  UpdateZPositionIndicators:=TRUE;
end;

function TAFMTopoGraph.UpdateXYPositionIndicators: boolean;
begin
  //SetXEdit.Text:=FloatToStrF(CurrentX, ffFixed, 10, 4);
  //SetYEdit.Text:=FloatToStrF(CurrentY, ffFixed, 10, 4);
  XPositionText.Caption:='X: '+ FloatToStrF(CurrentX, ffFixed, 10, 4);
  YPositionText.Caption:='Y: '+ FloatToStrF(CurrentY, ffFixed, 10, 4);
  UpdateXYPositionIndicators:=TRUE;
end;

function TAFMTopoGraph.UpdateScanImages(ScanAxis: Axis; i, j: integer): boolean;
//updates the scan as appropriate, depending on the ScanAxis parameter
  var
    p, q: PBGRAPixel;
    x, y: integer;

begin
  UpdateScanImages:=FALSE;
  case ScanAxis of
    XAxis:  //this is the default case:  j corresponds to the y iteration and i to
            //the x-iteration
      begin
        //forward bitmap
        p:=ForwardImageBitMap.ScanLine[j];
        q:=ReverseImageBitMap.ScanLine[j];
        for x:=0 to ForwardImageBitMap.Width-1 do
          begin
            if LevelImage then
              begin
                p^:= ZMicronsToRGBColor(ForwardLeveledData[x,j],
                     TopoIntegerScaleMin, TopoIntegerScaleMax);
                q^:= ZMicronsToRGBColor(ReverseLeveledData[x,j],
                     TopoIntegerScaleMin, TopoIntegerScaleMax);
              end
             else
              begin
                p^:= ZMicronsToRGBColor(ForwardData[x,j],
                     TopoIntegerScaleMin, TopoIntegerScaleMax);
                q^:= ZMicronsToRGBColor(ReverseData[x,j],
                     TopoIntegerScaleMin, TopoIntegerScaleMax);
              end;
            inc(q);
            inc(p);
          end;
      end;

    YAxis: //Along the y axis.
      begin
        //forward bitmap
        p:=ForwardImageBitMap.ScanLine[i];
        q:=ReverseImageBitMap.ScanLine[i];
        for y:=0 to ForwardImageBitMap.Height-1 do
          begin
            p:=ForwardImageBitMap.ScanLine[y];
            inc(p,j);
            q:=ReverseImageBitMap.ScanLine[y];
            inc(q,j);
            if LevelImage then
              begin
                p^:= ZMicronsToRGBColor(ForwardLeveledData[j,y],
                     TopoIntegerScaleMin, TopoIntegerScaleMax);
                q^:= ZMicronsToRGBColor(ReverseLeveledData[j,y],
                     TopoIntegerScaleMin, TopoIntegerScaleMax);
              end
             else
              begin
                p^:= ZMicronsToRGBColor(ForwardData[j,y],
                     TopoIntegerScaleMin, TopoIntegerScaleMax);
                q^:= ZMicronsToRGBColor(ReverseData[j,y],
                TopoIntegerScaleMin, TopoIntegerScaleMax);
              end;
            inc(q);
          end;
      end;
  end;

  ForwardImageBitMap.InvalidateBitmap;
  ReverseImageBitMap.InvalidateBitmap;
  StretchedForwardBitmap:=ForwardImageBitmap.Resample(ForwardImage.ClientWidth,
  ForwardImage.ClientHeight)as TBGRABitmap;
  StretchedForwardBitmap.Draw(ForwardImage.Canvas, 0, 0, True);
  StretchedForwardBitmap.Free;
  ForwardImage.Invalidate;
  StretchedReverseBitmap:=ReverseImageBitmap.Resample(ReverseImage.ClientWidth,
  ReverseImage.ClientHeight)as TBGRABitmap;
  StretchedReverseBitmap.Draw(ReverseImage.Canvas, 0, 0, True);
  StretchedReverseBitmap.Free;
  ReverseImage.Invalidate;
  UpdateScanImages:=TRUE;
end;

{-----------------------------------------------------------------------------}
procedure TAFMTopograph.DiffEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then
    begin
      DiffTime:=round(1E6*StrToFloat(DiffEdit.Text));
      PIDParametersChanged:=1;
    end;
end;

procedure TAFMTopograph.DwellTimeEditChange(Sender: TObject);
begin
  DwellTime:=DwellTimeEdit.Value;
  AveragesEdit.MaxValue:=round((DwellTime*1E6)/(2*PIDLoop_time));
  if PID_averages>AveragesEdit.MaxValue then
     PID_averages:=AveragesEdit.MaxValue;
  AveragesEdit.Value:=PID_averages;
end;


procedure TAFMTopograph.ScanDirectionComboBoxChange(Sender: TObject);
begin
  if ScanDirectionComboBox.ItemIndex = 0 then
     ScanAxis:=XAxis
   else if ScanDirectionComboBox.ItemIndex=1 then
     ScanAxis:=YAxis;
end;

procedure TAFMTopograph.ScanRangeComboBoxSelect(Sender: TObject);
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

procedure TAFMTopograph.ErrorCorrectionSpinEditChange(Sender: TObject);
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


initialization
  {$I AFMTopography.lrs}
  ScanResolution:=256;
  //XScanRange:=VoltageToMicrons(DAQVoltageRange, XAxis);
  //YScanRange:=VoltageToMicrons(DAQVoltageRange, YAxis);
end.

