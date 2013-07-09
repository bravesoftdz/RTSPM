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
    LevelTopoImageCheckBox: TCheckBox;
    LevelMFMImageCheckBox: TCheckBox;
    LiftModeHeightSpinEdit: TFloatSpinEdit;
    ForwardImage: TImage;
    MFMForwardImage: TImage;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    MFMRescaleButton: TButton;
    MFMReverseImage: TImage;
    GroupBox1: TGroupBox;
    MFMScaleMaxEdit: TEdit;
    MFMScaleMinEdit: TEdit;
    IndicatorImage: TImage;
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
    MFMModeRadioGroup: TRadioGroup;
    TopoRescaleButton: TButton;
    ReverseImage: TImage;
    SaveAsGSFFileButton: TButton;
    SaveAsTextFileButton: TButton;
    TopoScaleMaxEdit: TEdit;
    TopoScaleMinEdit: TEdit;
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
    procedure DiffEditKeyPress(Sender: TObject; var Key: char);
    procedure DwellTimeEditChange(Sender: TObject);
    procedure EngageFeedbackBtnClick(Sender: TObject);
    procedure ErrorCorrectionSpinEditChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure IntEditKeyPress(Sender: TObject; var Key: char);
    procedure LevelMFMImageCheckBoxClick(Sender: TObject);
    procedure LevelTopoImageCheckBoxClick(Sender: TObject);
    procedure LiftModeHeightSpinEditChange(Sender: TObject);
    procedure MFMModeRadioGroupClick(Sender: TObject);
    procedure MFMRescaleButtonClick(Sender: TObject);
    procedure MFMScaleMaxEditKeyPress(Sender: TObject; var Key: char);
    procedure MFMScaleMinEditKeyPress(Sender: TObject; var Key: char);
    procedure PropEditKeyPress(Sender: TObject; var Key: char);
    procedure SaveAsGSFFileButtonClick(Sender: TObject);
    procedure SaveAsTextFileButtonClick(Sender: TObject);
    procedure ScanStartBtnClick(Sender: TObject);
    procedure SetYEditKeyPress(Sender: TObject; var Key: char);
    procedure SetZEditKeyPress(Sender: TObject; var Key: char);
    procedure TopoRescaleButtonClick(Sender: TObject);
    procedure TopoScaleMaxEditKeyPress(Sender: TObject; var Key: char);
    procedure TopoScaleMinEditKeyPress(Sender: TObject; var Key: char);
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
    procedure ReplotImages(ScanAxis: Axis; ScannedLines: integer);
    procedure ReplotMFMImages(ScanAxis: Axis; ScannedLines: integer);
    function UpdateZPositionIndicators: boolean;
    function UpdateXYPositionIndicators: boolean;
    function UpdateScanImages(ScanAxis: Axis; i, j: integer): boolean;
    function UpdateMFMScanImages(ScanAxis: Axis; i, j: integer): boolean;
  end; 

var
  MFMForm: TMFMForm;

implementation
  uses ScanTubeFunctions, GlobalFunctions, FileFunctions, Oscilloscope,
  DAQFunctions, rtai_comedi_functions, rtai_comedi_types, BGRABitmap, BGRABitmapTypes;
  var
    ForwardImageBitmap,
    ReverseImageBitmap,
    MFMForwardImageBitmap,
    MFMReverseImageBitmap,
    StretchedForwardBitmap,
    StretchedReverseBitmap,
    MFMStretchedForwardBitmap,
    MFMStretchedReverseBitmap        : TBGRABitmap;
    FeedbackChannelReading  : real;
    //PointAverages           : integer = 10;
    DwellTime               : integer = 10; //number of points to average
                                //and dwell time per scan point

    ScanXPlusLimit,
    ScanXMinusLimit,
    ScanYPlusLimit,
    ScanYMinusLimit         : real;//extent of scans for a particular scan range

    //Since we now have four plots, we have two different scaling parameters
    TopoIntegerScaleMax : Word = 33000; //maximum and minimum of color scaling
    TopoIntegerScaleMin : Word = 32000;
    MFMIntegerScaleMax : Word = 33000; //maximum and minimum of color scaling
    MFMIntegerScaleMin : Word = 32000;
    RescaleImage        : boolean = FALSE;
    RescaleMFMImage         : boolean = FALSE;
    LevelImage          : boolean = FALSE;
    LevelMFMImage           : boolean = FALSE;

    MaxMFMSignal            : real = 1.0; //Maximum MFM signal, in volts
    MinMFMSignal            : real = -1.0; //Minimum MFM signal, in volts
    UseLiftMode             : boolean = TRUE; //if false, then using constant height mode


{ TMFMForm }


procedure TMFMForm.ReplotImages(ScanAxis: Axis; ScannedLines: integer);
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

{-------------------------------------------------------------------------------}
procedure TMFMForm.ReplotMFMImages(ScanAxis: Axis; ScannedLines: integer);
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
          p:=MFMForwardImageBitMap.ScanLine[j];
          q:=MFMReverseImageBitMap.ScanLine[j];
          for x:=0 to MFMForwardImageBitMap.Width-1 do
            begin
              if LevelMFMImage then
                begin
                  p^:= ZMicronsToRGBColor(MFMForwardLeveledData[x,j],
                       MFMIntegerScaleMin, MFMIntegerScaleMax);
                  q^:= ZMicronsToRGBColor(MFMReverseLeveledData[x,j],
                       MFMIntegerScaleMin, MFMIntegerScaleMax);
                end
               else
                begin
                  p^:= ZMicronsToRGBColor(MFMForwardData[x,j],
                       MFMIntegerScaleMin, MFMIntegerScaleMax);
                  q^:= ZMicronsToRGBColor(MFMReverseData[x,j],
                       MFMIntegerScaleMin, MFMIntegerScaleMax);
                end;
              inc(p);
              inc(q);
            end;
        end;
    end;

YAxis: //Along the y axis.
  begin
    for y:=0 to MFMForwardImageBitMap.Height-1 do
      begin
        p:=MFMForwardImageBitMap.ScanLine[y];
        q:=MFMReverseImageBitMap.ScanLine[y];
        for i:=0 to ScannedLines do
          begin
            if LevelMFMImage then
              begin
                p^:= ZMicronsToRGBColor(MFMForwardLeveledData[j,y],
                     MFMIntegerScaleMin, MFMIntegerScaleMax);
                q^:= ZMicronsToRGBColor(MFMReverseLeveledData[j,y],
                     MFMIntegerScaleMin, MFMIntegerScaleMax);
              end
             else
               begin
                 p^:= ZMicronsToRGBColor(MFMForwardData[j,y],
                      MFMIntegerScaleMin, MFMIntegerScaleMax);
                 q^:= ZMicronsToRGBColor(MFMReverseData[j,y],
                      MFMIntegerScaleMin, MFMIntegerScaleMax);
               end;
            inc(q);
            inc(p);
          end;
      end;
    end;
end;

MFMForwardImageBitMap.InvalidateBitmap;
MFMReverseImageBitMap.InvalidateBitmap;
MFMStretchedForwardBitmap:=MFMForwardImageBitmap.Resample(MFMForwardImage.ClientWidth,
MFMForwardImage.ClientHeight)as TBGRABitmap;
MFMStretchedForwardBitmap.Draw(MFMForwardImage.Canvas, 0, 0, True);
MFMStretchedForwardBitmap.Free;
MFMForwardImage.Invalidate;
MFMStretchedReverseBitmap:=MFMReverseImageBitmap.Resample(MFMReverseImage.ClientWidth,
MFMReverseImage.ClientHeight)as TBGRABitmap;
MFMStretchedReverseBitmap.Draw(MFMReverseImage.Canvas, 0, 0, True);
MFMStretchedReverseBitmap.Free;
MFMReverseImage.Invalidate;
GenerateScale(MFMIndicatorImage, MFMIntegerScaleMin, MFMIntegerScaleMax);
RescaleMFMImage:=FALSE;
end;
{-------------------------------------------------------------------------------}
function TMFMForm.UpdateScanImages(ScanAxis: Axis; i, j: integer): boolean;
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

{-------------------------------------------------------------------------------}
function TMFMForm.UpdateMFMScanImages(ScanAxis: Axis; i, j: integer): boolean;
//updates the scan as appropriate, depending on the ScanAxis parameter
  var
    p, q: PBGRAPixel;
    x, y: integer;

begin
  UpdateMFMScanImages:=FALSE;
  case ScanAxis of
    XAxis:  //this is the default case:  j corresponds to the y iteration and i to
            //the x-iteration
      begin
        //forward bitmap
        p:=MFMForwardImageBitMap.ScanLine[j];
        q:=MFMReverseImageBitMap.ScanLine[j];
        for x:=0 to MFMForwardImageBitMap.Width-1 do
          begin
            if LevelMFMImage then
              begin
                p^:= ZMicronsToRGBColor(MFMForwardLeveledData[x,j],
                     MFMIntegerScaleMin, MFMIntegerScaleMax);
                q^:= ZMicronsToRGBColor(MFMReverseLeveledData[x,j],
                     MFMIntegerScaleMin, MFMIntegerScaleMax);
              end
             else
              begin
                p^:= ZMicronsToRGBColor(MFMForwardData[x,j],
                     MFMIntegerScaleMin, MFMIntegerScaleMax);
                q^:= ZMicronsToRGBColor(MFMReverseData[x,j],
                     MFMIntegerScaleMin, MFMIntegerScaleMax);
              end;
            inc(q);
            inc(p);
          end;
      end;

    YAxis: //Along the y axis.
      begin
        //forward bitmap
        p:=MFMForwardImageBitMap.ScanLine[i];
        q:=MFMReverseImageBitMap.ScanLine[i];
        for y:=0 to MFMForwardImageBitMap.Height-1 do
          begin
            p:=MFMForwardImageBitMap.ScanLine[y];
            inc(p,j);
            q:=MFMReverseImageBitMap.ScanLine[y];
            inc(q,j);
            if LevelMFMImage then
              begin
                p^:= ZMicronsToRGBColor(MFMForwardLeveledData[j,y],
                     MFMIntegerScaleMin, MFMIntegerScaleMax);
                q^:= ZMicronsToRGBColor(MFMReverseLeveledData[j,y],
                     MFMIntegerScaleMin, MFMIntegerScaleMax);
              end
             else
              begin
                p^:= ZMicronsToRGBColor(MFMForwardData[j,y],
                     MFMIntegerScaleMin, MFMIntegerScaleMax);
                q^:= ZMicronsToRGBColor(MFMReverseData[j,y],
                MFMIntegerScaleMin, MFMIntegerScaleMax);
              end;
            inc(q);
          end;
      end;
  end;

  MFMForwardImageBitMap.InvalidateBitmap;
  MFMReverseImageBitMap.InvalidateBitmap;
  MFMStretchedForwardBitmap:=MFMForwardImageBitmap.Resample(MFMForwardImage.ClientWidth,
  MFMForwardImage.ClientHeight)as TBGRABitmap;
  MFMStretchedForwardBitmap.Draw(MFMForwardImage.Canvas, 0, 0, True);
  MFMStretchedForwardBitmap.Free;
  MFMForwardImage.Invalidate;
  MFMStretchedReverseBitmap:=MFMReverseImageBitmap.Resample(MFMReverseImage.ClientWidth,
  MFMReverseImage.ClientHeight)as TBGRABitmap;
  MFMStretchedReverseBitmap.Draw(MFMReverseImage.Canvas, 0, 0, True);
  MFMStretchedReverseBitmap.Free;
  MFMReverseImage.Invalidate;
  UpdateMFMScanImages:=TRUE;
end;

{-------------------------------------------------------------------------------}

procedure TMFMForm.FormShow(Sender: TObject);
begin
  //First topography
  TopoIntegerScaleMax:=MicronsToProgressBar(MaxZPosition);
  TopoIntegerScaleMin:=MicronsToProgressBar(MinZPosition);
  TopoScaleMaxEdit.Text:=FloatToStr(MaxZPosition);
  TopoScaleMinEdit.Text:=FloatToStr(MinZPosition);

  //For the MFM signal, we really have no idea what the signal range is
  //but we assume it is between MaxMFMSignal and MinMFMSignal
  MFMIntegerScaleMax:=MicronsToProgressBar(MaxMFMSignal);
  MFMIntegerScaleMin:=MicronsToProgressBar(MinMFMSignal);
  MFMScaleMaxEdit.Text:=FloatToStr(MaxZPosition);
  MFMScaleMinEdit.Text:=FloatToStr(MinZPosition);



  ForwardImageBitMap:=TBGRABitMap.Create(ScanResolution, ScanResolution, BGRABlack);
  ReverseImageBitMap:=TBGRABitMap.Create(ScanResolution, ScanResolution, BGRABlack);
  MFMForwardImageBitMap:=TBGRABitMap.Create(ScanResolution, ScanResolution, BGRABlack);
  MFMReverseImageBitMap:=TBGRABitMap.Create(ScanResolution, ScanResolution, BGRABlack);

  StretchedForwardBitmap:=ForwardImageBitmap.Resample(ForwardImage.ClientWidth,
                                    ForwardImage.ClientHeight)as TBGRABitmap;
  StretchedForwardBitmap.Draw(ForwardImage.Canvas, 0, 0, True);
  StretchedForwardBitmap.Free;
  StretchedReverseBitmap:=ReverseImageBitmap.Resample(ReverseImage.ClientWidth,
                                    ReverseImage.ClientHeight)as TBGRABitmap;
  StretchedReverseBitmap.Draw(ReverseImage.Canvas, 0, 0, True);
  StretchedReverseBitmap.Free;

  MFMStretchedForwardBitmap:=MFMForwardImageBitmap.Resample(MFMForwardImage.ClientWidth,
                                    MFMForwardImage.ClientHeight)as TBGRABitmap;
  MFMStretchedForwardBitmap.Draw(MFMForwardImage.Canvas, 0, 0, True);
  MFMStretchedForwardBitmap.Free;
  MFMStretchedReverseBitmap:=MFMReverseImageBitmap.Resample(MFMReverseImage.ClientWidth,
                                    MFMReverseImage.ClientHeight)as TBGRABitmap;
  MFMStretchedReverseBitmap.Draw(MFMReverseImage.Canvas, 0, 0, True);
  MFMStretchedReverseBitmap.Free;

  //Now generate the indicator bars
  GenerateScale(IndicatorImage, TopoIntegerScaleMin, TopoIntegerScaleMax);
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
  LiftModeHeight:=0.020; //Default Lift mode height, in um
  LiftModeHeightSpinEdit.Value:=LiftModeHeight*1000;

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
  LevelImage:=FALSE;
  LevelTopoImageCheckBox.State:=cbUnchecked;
  LevelMFMImage:=FALSE;
  LevelMFMImageCheckBox.State:=cbUnchecked;
end;

procedure TMFMForm.IntEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then
    begin
      IntTime:=round(1E6*StrToFloat(IntEdit.Text));
      PIDParametersChanged:=1;
    end;
end;

procedure TMFMForm.LevelMFMImageCheckBoxClick(Sender: TObject);
begin
  if LevelMFMImage then
    begin
      LevelMFMImage:=FALSE;
      LevelMFMImageCheckBox.State:=cbUnChecked;
    end
   else
    begin
     LevelMFMImage:=TRUE;
     LevelMFMImageCheckBox.State:=cbChecked;
   end;
 //ReplotImages;
end;

procedure TMFMForm.LevelTopoImageCheckBoxClick(Sender: TObject);
begin
  if LevelImage then
    begin
      LevelImage:=FALSE;
      LevelTopoImageCheckBox.State:=cbUnChecked;
    end
   else
    begin
     LevelImage:=TRUE;
     LevelTopoImageCheckBox.State:=cbChecked;
   end;
 //ReplotImages;
end;

procedure TMFMForm.LiftModeHeightSpinEditChange(Sender: TObject);
begin
  LiftModeHeight:=0.001*(LiftModeHeightSpinEdit.Value);
end;

procedure TMFMForm.MFMModeRadioGroupClick(Sender: TObject);
begin
  If MFMModeRadioGroup.ItemIndex=0 //ItemIndex 0 corresponds to LiftMode
    then UseLiftMode:=TRUE
   else UseLiftMode:=FALSE;
end;

procedure TMFMForm.MFMRescaleButtonClick(Sender: TObject);
begin
  RescaleMFMImage:=TRUE;
end;

procedure TMFMForm.MFMScaleMaxEditKeyPress(Sender: TObject; var Key: char);
var
  Value : Real;
begin
  if Key=Chr(13) then
    begin
      Value:=StrToFloat(MFMScaleMaxEdit.Text);
      MFMIntegerScaleMax:=MicronsToProgressBar(Value);
      If ((MFMIntegerScaleMax<MFMIntegerScaleMin) and (MFMIntegerScaleMax<65535)) then
          MFMIntegerScaleMax:=MFMIntegerScaleMin+1;
      RescaleMFMImage:=TRUE;
    end;
end;

procedure TMFMForm.MFMScaleMinEditKeyPress(Sender: TObject; var Key: char);
var
  Value : Real;
begin
  if Key=Chr(13) then
    begin
      Value:=StrToFloat(MFMScaleMinEdit.Text);
      MFMIntegerScaleMin:=MicronsToProgressBar(Value);
      If ((MFMIntegerScaleMin>MFMIntegerScaleMax) and (MFMIntegerScaleMin>0)) then
          MFMIntegerScaleMin:=MFMIntegerScaleMax-1;
      RescaleMFMImage:=TRUE;
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

procedure TMFMForm.SaveAsGSFFileButtonClick(Sender: TObject);
var
  ForwardFileName,
  ReverseFileName,
  MFMForwardFileName,
  MFMReverseFileName,
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
          ForwardFileName:=BaseFileName+'-for-topo.gsf';
          ReverseFileName:=BaseFileName+'-rev-topo.gsf';
          MFMForwardFileName:=BaseFileName+'-for-mfm.gsf';
          MFMReverseFileName:=BaseFileName+'-rev-mfm.gsf';
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
          WriteGwyddionSimpleFieldFile( ForwardFileName,
                                        DescriptionEdit.Text,
                                        ScanResolution, ScanResolution,
                                        ScanRange, ScanRange,
                                        'm', 'm',
                                        MFMForwardData);

          WriteGwyddionSimpleFieldFile( ReverseFileName,
                                        DescriptionEdit.Text,
                                        ScanResolution, ScanResolution,
                                        ScanRange, ScanRange,
                                        'm', 'm',
                                        MFMReverseData);

        end;
    end;
end;

procedure TMFMForm.SaveAsTextFileButtonClick(Sender: TObject);
var
  ForwardFileName,
  ReverseFileName,
  MFMForwardFileName,
  MFMReverseFileName,
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
          ForwardFileName:=BaseFileName+'-for-topo.dat';
          ReverseFileName:=BaseFileName+'-rev-topo.dat';
          MFMForwardFileName:=BaseFileName+'-for-mfm.dat';
          MFMReverseFileName:=BaseFileName+'-rev-mfm.dat';
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
          WriteTextDataFile( MFMForwardFileName,
                             DescriptionEdit.Text,
                             ScanResolution, ScanResolution,
                             ScanRange, ScanRange,
                             'm', 'm',
                             MFMForwardData);

          WriteTextDataFile( MFMReverseFileName,
                             DescriptionEdit.Text,
                             ScanResolution, ScanResolution,
                             ScanRange, ScanRange,
                             'm', 'm',
                             MFMReverseData);
        end;
    end;
end;

procedure TMFMForm.ScanStartBtnClick(Sender: TObject);
var
  ScanXStep,
  ScanYStep     : real; //step size of x and y points in the scan
  i, j
                : integer;
  XPoints, XPointsReversed,
  ForwardLineScanData,
  ReverseLineScanData,
  LeveledSingleLineForwardData,
  LeveledSingleLineReverseData,
  MFMForwardLineScanData,
  MFMReverseLineScanData,
  MFMLeveledSingleLineForwardData,
  MFMLeveledSingleLineReverseData  : TScanData;
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
    LiftModeHeightSpinEdit.Enabled:=TRUE;
    ScanResolutionComboBox.Enabled:=TRUE;
    ScanRangeComboBox.Enabled:=TRUE;
    DwellTimeEdit.Enabled:=TRUE;
    AveragesEdit.Enabled:=TRUE;
    ScanDirectionComboBox.Enabled:=TRUE;
  end
 else
  begin
    //Need to disable a number of things!
    EngageFeedbackBtn.Enabled:=FALSE;
    SetXEdit.Enabled:=FALSE;
    SetYEdit.Enabled:=FALSE;
    SetZEdit.Enabled:=FALSE;
    StepXEdit.Enabled:=FALSE;
    StepYEdit.Enabled:=FALSE;
    StepZEdit.Enabled:=FALSE;
    ErrorCorrectionSpinEdit.Enabled:=FALSE;
    LiftModeHeightSpinEdit.Enabled:=FALSE;
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
    SetLength(MFMForwardData, ScanResolution, ScanResolution);
    SetLength(MFMReverseData, ScanResolution, ScanResolution);
    SetLength(MFMForwardLeveledData, ScanResolution, ScanResolution);
    SetLength(MFMReverseLeveledData, ScanResolution, ScanResolution);
    SetLength(ForwardLineScanData, ScanResolution);
    SetLength(ReverseLineScanData, ScanResolution);
    SetLength(MFMForwardLineScanData, ScanResolution);
    SetLength(MFMReverseLineScanData, ScanResolution);
    SetLength(XPoints, ScanResolution);
    SetLength(XPointsReversed, ScanResolution);
    SetLength(LeveledSingleLineForwardData, ScanResolution);
    SetLength(LeveledSingleLineReverseData, ScanResolution);
    SetLength(MFMLeveledSingleLineForwardData, ScanResolution);
    SetLength(MFMLeveledSingleLineReverseData, ScanResolution);

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
              StatusBar.SimpleText:='Scanning forward topography '+ IntToStr(j+1);
              ForwardLineScanData:= XLineScan(ScanResolution, StartX, ScanXStep,
                                    DwellTime, PID_Averages);  //Forward direction
              fastdelay(10*DwellTime); //Delay at beginning of scan to relax
              StartX:=ScanXPlusLimit;
              StatusBar.SimpleText:='Scanning reverse topography '+ IntToStr(j+1);
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
                  Application.ProcessMessages;
                end;

              //Now do this for the MFM scan
              //First turn off Feedback!
              EngageFeedbackBtnClick(Self);  //Use the button to click it
              fastdelay(10*DwellTime); //Delay at beginning of scan to relax
              StartX:=ScanXMinusLimit;
              StatusBar.SimpleText:='Scanning forward MFM '+ IntToStr(j+1);

              if UseLiftMode then
                MFMForwardLineScanData:= LiftModeXLineScan(ScanResolution, StartX, ScanXStep,
                                    DwellTime, PID_Averages, ForwardLineScanData)  //Forward direction
               else //we are using constant height mode, which is taken care of by the normal XLineScan
                begin
                  MoveToZ(CurrentZ+LiftModeHeight, StepZ, 0);  //Lift to constant height above current height
                  MFMForwardLineScanData:= XLineScan(ScanResolution, StartX, ScanXStep,
                                    DwellTime, PID_Averages);
                end;

              fastdelay(10*DwellTime); //Delay at beginning of scan to relax
              StartX:=ScanXPlusLimit;
              StatusBar.SimpleText:='Scanning reverse MFM '+ IntToStr(j+1);

              if UseLiftMode then
                MFMReverseLineScanData:= LiftModeXLineScan(ScanResolution, StartX, -ScanXStep,
                                    DwellTime, PID_Averages, ReverseLineScanData)  //Reverse direction
               else
                MFMReverseLineScanData:= XLineScan(ScanResolution, StartX, -ScanXStep,
                                    DwellTime, PID_Averages);  //Reverse direction

              //Generate the leveled data
              MFMLeveledSingleLineForwardData:=LeveledScanData(XPoints, MFMForwardLineScanData);
              MFMLeveledSingleLineReverseData:=LeveledScanData(XPointsReversed, MFMReverseLineScanData);

              i:=0;
              while ((i<ScanResolution) and Scanning) do  //this is the X iteration
                begin
                  MFMForwardData[i,j]:=MFMForwardLineScanData[i];
                  MFMReverseData[i,j]:=MFMReverseLineScanData[ScanResolution-1-i];//Need to reverse
                  MFMForwardLeveledData[i,j]:=MFMLeveledSingleLineForwardData[i];
                  //Manan changed to see if it helps in giving identical forward and reverse images
                  //ReverseData[i,j]:=LeveledSingleLineReverseData[ScanResolution-1-i];//Need to reverse
                  MFMReverseLeveledData[i,j]:=MFMLeveledSingleLineReverseData[ScanResolution-1-i];//Need to reverse
                  inc(i);
                  //Application.ProcessMessages;
                end;

              //end of the MFM part of the scan

              //Re-engage feedback, then wait for it to settle, based on the integral time of the PID
              EngageFeedbackBtnClick(Self);
              fastdelay(DwellTime);

              StartY:=StartY - ScanYStep;
              MoveToY(StartY, StepY, 0);

              if RescaleImage then ReplotImages(ScanAxis, j);
              if RescaleMFMImage then ReplotMFMImages(ScanAxis, j);

              UpdateScanImages(ScanAxis, i, j);
              UpdateMFMScanImages(ScanAxis, i, j);
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
          while ((j<ScanResolution) and Scanning) do //this is the x iteration
            begin
              //initialize the Oscilloscope Plot
              OscilloscopeForm.OscilloscopeChartLineSeries1.Clear;
              OscilloscopeForm.OscilloscopeChartLineSeries2.Clear;
              OscilloscopeForm.OscilloscopeChartLineSeries3.Clear;
              OscilloscopeForm.OscilloscopeChartLineSeries4.Clear;
              fastdelay(10*DwellTime); //Delay at beginning of scan to relax
              StartY:=ScanYPlusLimit;
              StatusBar.SimpleText:='Scanning downward topo line '+ IntToStr(j+1);
              ForwardLineScanData:= YLineScan(ScanResolution, StartY, -ScanYStep,
                                    DwellTime, PID_Averages);  //Downward direction
              fastdelay(10*DwellTime); //Delay at beginning of scan to relax
              StartY:=ScanYMinusLimit;
              StatusBar.SimpleText:='Scanning upward topo line '+ IntToStr(j+1);
              ReverseLineScanData:= YLineScan(ScanResolution, StartY, +ScanXStep,
                                    DwellTime, PID_Averages);  //Upward direction

              //Fill in XPoints with the X positions of the scan
              //This is for the line by line leveling, and could also apply to
              //scanning along the y direction
              for i:=0 to ScanResolution-1 do XPoints[i]:=ScanYPlusLimit - i*ScanYStep;
              for i:=0 to ScanResolution-1 do XPointsReversed[i]:=Xpoints[ScanResolution-1-i];

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
                  Application.ProcessMessages;
                end;

              //Now do this for the MFM scan
              //First turn off Feedback!
              EngageFeedbackBtnClick(Self);  //Use the button to click it
              fastdelay(10*DwellTime); //Delay at beginning of scan to relax
              StartY:=ScanYPlusLimit;
              StatusBar.SimpleText:='Scanning downward MFM line '+ IntToStr(j+1);

              if UseLiftMode then
                MFMForwardLineScanData:= LiftModeYLineScan(ScanResolution, StartY, -ScanYStep,
                                    DwellTime, PID_Averages, ForwardLineScanData)
               else
                begin
                  MoveToZ(CurrentZ+LiftModeHeight, StepZ, 0);  //Lift to constant height above current height
                  MFMForwardLineScanData:= YLineScan(ScanResolution, StartY, -ScanYStep,
                                    DwellTime, PID_Averages);  //Downward direction
                end;

              fastdelay(10*DwellTime); //Delay at beginning of scan to relax
              StartY:=ScanYMinusLimit;
              StatusBar.SimpleText:='Scanning upward MFM line '+ IntToStr(j+1);

              if UseLiftMode then
                MFMReverseLineScanData:= LiftModeYLineScan(ScanResolution, StartY, +ScanXStep,
                                    DwellTime, PID_Averages, ReverseLineScanData)
               else
                MFMReverseLineScanData:= YLineScan(ScanResolution, StartY, +ScanXStep,
                                    DwellTime, PID_Averages);  //Upward direction

              //Fill in XPoints with the X positions of the scan
              //This is for the line by line leveling, and could also apply to
              //scanning along the y direction
              for i:=0 to ScanResolution-1 do XPoints[i]:=ScanYPlusLimit - i*ScanYStep;
              for i:=0 to ScanResolution-1 do XPointsReversed[i]:=Xpoints[ScanResolution-1-i];

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
                  Application.ProcessMessages;
                end;

              //end of MFM part for YScan axis

              //Re-engage feedback, then wait for it to settle, based on the integral time of the PID
              EngageFeedbackBtnClick(Self);
              fastdelay(DwellTime);

              StartX:=StartX + ScanXStep;
              MoveToX(StartX, StepX, 0);
              if RescaleImage then ReplotImages(ScanAxis, j);
              if RescaleMFMImage then ReplotMFMImages(ScanAxis, j);
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

procedure TMFMForm.SetYEditKeyPress(Sender: TObject; var Key: char);
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

procedure TMFMForm.SetZEditKeyPress(Sender: TObject; var Key: char);
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

procedure TMFMForm.TopoRescaleButtonClick(Sender: TObject);
begin
  RescaleImage:=TRUE;
end;

procedure TMFMForm.TopoScaleMaxEditKeyPress(Sender: TObject; var Key: char);
var
  Value : Real;
begin
  if Key=Chr(13) then
    begin
      Value:=StrToFloat(TopoScaleMaxEdit.Text);
      TopoIntegerScaleMax:=MicronsToProgressBar(Value);
      If ((TopoIntegerScaleMax<TopoIntegerScaleMin) and (TopoIntegerScaleMax<65535)) then
          TopoIntegerScaleMax:=TopoIntegerScaleMin+1;
      RescaleImage:=TRUE;
    end;
end;

procedure TMFMForm.TopoScaleMinEditKeyPress(Sender: TObject; var Key: char);
var
  Value : Real;
begin
  if Key=Chr(13) then
    begin
      Value:=StrToFloat(TopoScaleMinEdit.Text);
      TopoIntegerScaleMin:=MicronsToProgressBar(Value);
      If ((TopoIntegerScaleMin>TopoIntegerScaleMax) and (TopoIntegerScaleMin>0)) then
          TopoIntegerScaleMin:=TopoIntegerScaleMax-1;
      RescaleImage:=TRUE;
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
  ForwardImageBitMap.SetSize(ScanResolution, ScanResolution);
  ReverseImageBitMap.SetSize(ScanResolution, ScanResolution);
  MFMForwardImageBitmap.SetSize(ScanResolution, ScanResolution);
  MFMReverseImageBitmap.SetSize(ScanResolution, ScanResolution);
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
  ForwardImageBitMap.Free;
  ReverseImageBitMap.Free;
  MFMForwardImageBitmap.Free;
  MFMReverseImageBitmap.Free;
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
      if Sender=EngageFeedbackBtn then FirstPIDPass := 1; //This is the first PID pass
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
      ErrorSignalLabel.Caption:=FloatToStrF(AveragedFeedbackReading-SetPoint, ffExponent, 10, 4);
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
       ErrorSignalLabel.Caption:=FloatToStrF(AveragedFeedbackReading-SetPoint, ffExponent, 10, 4);
     end;

      UpdateXYPositionIndicators;
      UpdateZPositionIndicators;
end;

procedure TMFMForm.DiffEditKeyPress(Sender: TObject; var Key: char);
begin
  if Key=Chr(13) then
    begin
      DiffTime:=round(1E6*StrToFloat(DiffEdit.Text));
      PIDParametersChanged:=1;
    end;
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

