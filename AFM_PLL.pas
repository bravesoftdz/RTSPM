unit AFM_PLL;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, ComCtrls, Spin;

const
   MaxPixels = 512;

type
   PlotColor = (Red, Blue, Green, BW);

type
   AFM_Mode  = (Frequency, Phase, Amplitude);

type
   pRGBTripleArray = ^TRGBTripleArray;
   TRGBTripleArray = array[0..MaxPixels-1] of TRGBTriple;

type
  TAFMPLL = class(TForm)
    ZApproachBar: TProgressBar;
    ForwardImageGroupBox: TGroupBox;
    ForwardImage: TImage;
    ReverseImageGroupBox: TGroupBox;
    ReverseImage: TImage;
    PixelComboBox: TComboBox;
    MagComboBox: TComboBox;
    SignalControlGroupBox: TGroupBox;
    Label2: TLabel;
    Label4: TLabel;
    Chan0Reading: TLabel;
    Label5: TLabel;
    Chan1Reading: TLabel;
    SetPointEdit: TEdit;
    PiezoControlBox: TGroupBox;
    Label7: TLabel;
    CurrentZLabel: TLabel;
    Label9: TLabel;
    PropControlEdit: TEdit;
    Label10: TLabel;
    IntControlEdit: TEdit;
    Label11: TLabel;
    DiffControlEdit: TEdit;
    Bevel1: TBevel;
    ScanControlBox: TGroupBox;
    Bevel2: TBevel;
    SetXEdit: TEdit;
    Label1: TLabel;
    SetYEdit: TEdit;
    Label12: TLabel;
    SetStepEdit: TEdit;
    Label14: TLabel;
    Label3: TLabel;
    CurrentYLabel: TLabel;
    Label13: TLabel;
    CurrentXLabel: TLabel;
    ScanBtn: TButton;
    SaveFileBtn: TButton;
    FeedbackOnBtn: TButton;
    StatusLabel: TLabel;
    Label6: TLabel;
    InitialReadingLabel: TLabel;
    ModeRadioGroup: TRadioGroup;
    ColorRadioGroup: TRadioGroup;
    ErrorSignRadioGroup: TRadioGroup;
    ScanTypeRadioGroup: TRadioGroup;
    Label8: TLabel;
    WaitTimeSpinEdit: TSpinEdit;
    DataTimer: TTimer;
    procedure FeedbackOnBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure PixelComboBoxChange(Sender: TObject);
    procedure MagComboBoxChange(Sender: TObject);
    procedure ErrorSignRadioGroupClick(Sender: TObject);
    procedure ModeRadioGroupClick(Sender: TObject);
    procedure ColorRadioGroupClick(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure ScanTypeRadioGroupClick(Sender: TObject);
    procedure ScanBtnClick(Sender: TObject);
    procedure WaitTimeSpinEditChange(Sender: TObject);
    procedure SetPointEditKeyPress(Sender: TObject; var Key: Char);
    procedure PropControlEditKeyPress(Sender: TObject; var Key: Char);
    procedure IntControlEditKeyPress(Sender: TObject; var Key: Char);
    procedure DiffControlEditKeyPress(Sender: TObject; var Key: Char);
    procedure SetXEditKeyPress(Sender: TObject; var Key: Char);
    procedure SetYEditKeyPress(Sender: TObject; var Key: Char);
    procedure SetStepEditKeyPress(Sender: TObject; var Key: Char);
    procedure DataTimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function UpdateXYPositionIndicators: boolean;
    function UpdateZPositionIndicators: boolean;
    function ColorScheme(Color: PlotColor; DataValue:integer):TRGBTriple;
  end;

var
  AFMPLL: TAFMPLL;
  AFMFeedbackMode : AFM_Mode;
  AFM_PlotColor   : PlotColor;
  ForwardBitMap,
  ReverseBitMap   : TBitmap;
  WaitTime        : integer = 50; //wait time per pixel, in ms
  ForwardData,
  ReverseData     : array of array of integer;

implementation
   uses
       GlobalVariables, WalkerFunctions, ScanTubeFunctions, NI6733,
       TipCoarseApproach, SPMUtilities, FeedbackThread, SPM_Main;
{$R *.DFM}

var
  PFeedbackThread        : TFeedbackThread;
  OffsetScan             : boolean = FALSE;

function TAFMPLL.UpdateXYPositionIndicators: boolean;
begin
  SetXEdit.Text:=IntToStr(Current_x);
  SetYEdit.Text:=IntToStr(Current_y);
  CurrentXLabel.Caption:=SetXEdit.Text;
  CurrentYLabel.Caption:=SetYEdit.Text;
  UpdateXYPositionIndicators:=TRUE;
end;

procedure TAFMPLL.FeedbackOnBtnClick(Sender: TObject);

var
  EndApproach : Boolean;
  CurrentValue: real;

begin
  //if we are already under feedback, then stop feedback
  if feedback Then
    begin
      DataTimer.Enabled:=TRUE;
      feedback := FALSE;
      if Assigned(PFeedbackThread) then
        begin
          PFeedbackThread.Terminate;
          PFeedbackThread.WaitFor;
          PFeedbackThread.Free;
          PFeedbackThread:=nil;
        end;
      StatusLabel.Caption:='Feedback OFF';
      //retract the tip
      MoveZ(0, LargeStepSize); // retract the tip
      UpdateZPositionIndicators;
      FeedbackOnBtn.Caption := 'Start Feedback Control';
      ScanBtn.Enabled := FALSE;
      ErrorSignRadioGroup.Enabled:=TRUE;
    end //of if feedback
   else
     begin
       DataTimer.Enabled:=FALSE;
       FeedbackOnBtn.Caption := 'Stop Feedback Control';
       with CoarseApproachTool do
         begin
           Show;
           StepByStepBtn.Click;
           Hide;
         end; //of with CoarseApproach Tool
        //Retract the walker a bit until we are below the set point
       MoveZ(0, ZStepSize);
       while (abs(ReadAveragedAnalogChannel(PrimaryChannelNumber, 3)-Initial_reading)>SetPoint) do
                Walker_Up_Step(200);

       Initial_reading := ReadAveragedAnalogChannel(PrimaryChannelNumber, 100); //large averaging
       InitialReadingLabel.Caption := FloatToStrF(Initial_reading, ffFixed, 10, 4);
       feedback := TRUE;
       StatusLabel.Caption:='Starting Feedback';
       ErrorSignRadioGroup.Enabled:=FALSE;
       //Do a first slow approach to half the feedback point
       //Set the PLL to be at the least sensitive scale
       //SPM_MainForm.EasyPLL.PLLLockRangeSel:=2; //732 Hz per volt
       EndApproach:=FALSE;
       while not EndApproach do
         begin
           MoveZ(Current_Z + ZStepSize, ZStepSize);    //single steps
           //UpdateZPositionIndicators;
           CurrentValue:=ReadAveragedAnalogChannel(PrimaryChannelNumber, ReadingAverages);
           Chan0Reading.Caption:=FloatToStrF(CurrentValue, ffFixed, 10, 4);
           Application.ProcessMessages;
           //set a condition to end the approach
           EndApproach := (abs(CurrentValue-Initial_reading)>(0.1*SetPoint)) or
              (not Feedback) or (Current_Z>Board_resolution);
           UpdateZPositionIndicators;
         end;
       //Now switch back to full sensitivity
       //SPM_MainForm.EasyPLL.PLLLockRangeSel:=0; //183 Hz per volt
       if Assigned(PFeedbackThread) then
         begin
           PFeedbackThread.Terminate;
           PFeedbackThread.WaitFor;
           PFeedbackThread.Free;
           PFeedbackThread:=nil;
         end;
       PFeedbackThread:=TFeedbackThread.Create(TRUE);
       PFeedbackThread.Resume;
       StatusLabel.Caption:='Feedback On';
       DataTimer.Enabled:=TRUE;       
       //Continuous_Feedback(Self);
       Tip_GoTo(X_Set, Y_Set, StepSize);
       UpdateXYPositionIndicators;
       ScanBtn.Enabled := TRUE;
     end;
end;

{---------------------------------------------------------------------------}
function TAFMPLL.UpdateZPositionIndicators: boolean;
begin
  ZApproachBar.Position:=Current_Z;
  CurrentZLabel.Caption:=IntToStr(Current_Z);
  UpdateZPositionIndicators:=TRUE;
end;
procedure TAFMPLL.FormShow(Sender: TObject);
var
  TestMag, j : integer;
begin
   //PFeedbackThread:=TFeedbackThread.Create(TRUE); //create a suspended version
   feedback:=FALSE;
   ScanBtn.Enabled:=FALSE;
   Scanning:=FALSE;
   SaveFileBtn.Enabled:=FALSE;
   SetPointEdit.Text:=FloatToStrF(SetPoint, ffFixed, 10, 4);
   PropControlEdit.Text:= FloatToStrF(PropGain, ffFixed, 10, 4);
   IntControlEdit.Text:= FloatToStrF(IntGain, ffFixed, 10, 4);
   DiffControlEdit.Text:= FloatToStrF(DiffGain, ffFixed, 10, 4);
   CurrentXLabel.Caption:=IntToStr(Current_X);
   CurrentYLabel.Caption:=IntToStr(Current_Y);
   CurrentZLabel.Caption:=IntToStr(Current_Z);
   SetXEdit.Text:=CurrentXLabel.Caption;
   SetYEdit.Text:=CurrentYLabel.Caption;
   StatusLabel.Caption:='Ready';
   WaitTimeSpinEdit.Value:=WaitTime;
   if Pixels=128 then PixelComboBox.ItemIndex:=0
     else if Pixels=256 then PixelComboBox.ItemIndex:=1
     else if Pixels=512 then PixelComboBox.ItemIndex:=2
     else
       begin
         Pixels:=128;
         PixelComboBox.ItemIndex:=0;
       end;
   TestMag:=Mag;
   j:=0;
   while TestMag<64 do
     begin
       TestMag:=TestMag*2;
       Inc(j);
     end;
   MagComboBox.ItemIndex:=6-j; //largest scan range
   ScanStepSize:=trunc(Board_resolution/Mag/Pixels)+ 1;
   SetStepEdit.Text:=IntToStr(ScanStepSize);
   if AFMFeedbackMode = Frequency then
       ModeRadioGroup.ItemIndex:=0
     else if AFMFeedbackMode = Phase then
       ModeRadioGroup.ItemIndex:=1
     else if AFMFeedbackMode = Amplitude then
       ModeRadioGroup.ItemIndex:=2
     else
       begin
        AFMFeedbackMode := Frequency;
        ModeRadioGroup.ItemIndex:=0;
       end;

   if FeedbackSign = 1 then
       ErrorSignRadioGroup.ItemIndex:=0
     else if FeedbackSign = -1 then
       ErrorSignRadioGroup.ItemIndex:=1
     else
       begin
        FeedbackSign := 1;
        ErrorSignRadioGroup.ItemIndex:=0;
       end;

   if AFM_PlotColor = Red then
       ColorRadioGroup.ItemIndex:=0
     else if AFM_PlotColor = Green then
       ColorRadioGroup.ItemIndex:=1
     else if AFM_PlotColor = Blue then
       ColorRadioGroup.ItemIndex:=2
     else if AFM_PlotColor = BW then
       ColorRadioGroup.ItemIndex:=2
     else
       begin
        AFM_PlotColor := Red;
        ColorRadioGroup.ItemIndex:=0;
       end;

   if OffsetScan then ScanTypeRadioGroup.ItemIndex:=1 else ScanTypeRadioGroup.ItemIndex:=0;

   Initial_Reading:=0;
   InitialReadingLabel.Caption:=FloatToStrF(Initial_Reading, ffFixed, 10, 4);

  ForwardBitMap:=TBitMap.Create;
  ForwardBitMap.PixelFormat:=pf24bit;
  ReverseBitMap:=TBitMap.Create;
  ReverseBitMap.PixelFormat:=pf24bit;
  ForwardBitMap.Height:=Pixels;
  ForwardBitMap.Width:=Pixels;
  ReverseBitMap.Height:=Pixels;
  ReverseBitMap.Width:=Pixels;

  DataTimer.Enabled:=TRUE;
end;

procedure TAFMPLL.PixelComboBoxChange(Sender: TObject);
begin
  if PixelComboBox.ItemIndex=0 then Pixels:=128
    else if PixelComboBox.ItemIndex=1 then Pixels:=256
    else if PixelComboBox.ItemIndex=2 then Pixels:=512
    else
      begin
        Pixels:=128;
        PixelComboBox.ItemIndex:=0;
      end;
   ForwardBitMap.Height:=Pixels;
   ForwardBitMap.Width:=Pixels;
   ReverseBitMap.Height:=Pixels;
   ReverseBitMap.Width:=Pixels;
   ScanStepSize:=trunc(Board_resolution/Mag/Pixels)+ 1;
   SetStepEdit.Text:=IntToStr(ScanStepSize);
end;

procedure TAFMPLL.MagComboBoxChange(Sender: TObject);
begin
  if (MagComboBox.ItemIndex>0) and (MagComboBox.ItemIndex<6) then
    Mag:=1 shl MagComboBox.ItemIndex
   else
     begin
       MagComboBox.ItemIndex:=0;
       Mag:=1;
     end;
  ScanStepSize:=trunc(Board_resolution/Mag/Pixels)+ 1;
  SetStepEdit.Text:=IntToStr(ScanStepSize);
end;

procedure TAFMPLL.ErrorSignRadioGroupClick(Sender: TObject);
begin
  if ErrorSignRadioGroup.ItemIndex = 0 then
    FeedbackSign:=1
   else if ErrorSignRadioGroup.ItemIndex = 1 then
    FeedbackSign:= -1
   else
     begin
       FeedbackSign:=1;
       ErrorSignRadioGroup.ItemIndex:=0;
     end;
end;

procedure TAFMPLL.ModeRadioGroupClick(Sender: TObject);
begin
  if ModeRadioGroup.ItemIndex = 0 then
    AFMFeedbackMode:=Frequency
   else if ModeRadioGroup.ItemIndex = 1 then
    AFMFeedbackMode:=Phase
   else if ModeRadioGroup.ItemIndex = 2 then
    AFMFeedbackMode:=Amplitude
   else
     begin
       AFMFeedbackMode:=Frequency;
       ModeRadioGroup.ItemIndex:=0;
     end;

end;

procedure TAFMPLL.ColorRadioGroupClick(Sender: TObject);
begin
  if ColorRadioGroup.ItemIndex = 0 then
    AFM_PlotColor:=Red
   else if ColorRadioGroup.ItemIndex = 1 then
    AFM_PlotColor:=Green
   else if ColorRadioGroup.ItemIndex = 2 then
    AFM_PlotColor:=Blue
   else if ColorRadioGroup.ItemIndex = 3 then
    AFM_PlotColor:=BW
   else
     begin
       ColorRadioGroup.ItemIndex:=0;
       AFM_PlotColor:=Red;
     end;
end;

procedure TAFMPLL.FormHide(Sender: TObject);
begin
  if Assigned(PFeedbackThread) then
    begin
      PFeedbackThread.Terminate;
      PFeedbackThread.Free;
      PFeedbackThread:=nil;
    end;
  ForwardBitMap.Free;
  ReverseBitMap.Free;
  DataTimer.Enabled:=FALSE;
end;

procedure TAFMPLL.ScanTypeRadioGroupClick(Sender: TObject);
begin
  if ScanTypeRadioGroup.ItemIndex = 0 then OffsetScan:=FALSE else OffsetScan:=TRUE;
end;

procedure TAFMPLL.ScanBtnClick(Sender: TObject);
var
  StartX, StartY    : integer;
  i, j              : integer;
  P, Q              : PRGBTripleArray;
  x_value         : integer;
  DrawingRect       : TRect;

begin
  if scanning then  //stop scanning
    begin
      ScanBtn.Caption := 'Scan';
      scanning := FALSE;
      StatusLabel.Caption:='Ready';
    end
   else
     begin
       ScanBtn.Caption := 'Cancel';
       FeedbackOnBtn.Enabled := FALSE;
       scanning := TRUE;
       StatusLabel.Caption:='Scanning';
       if OffsetScan then //we take the start points from the form, as well
                          // as the step size
         begin
           StartX:=X_Set;
           StartY:=Y_Set;
           ScanStepSize:=StrToInt(SetStepEdit.Text);
         end
        else  // do a centered scan
         begin
           ScanStepSize:=trunc(Board_resolution/Mag/Pixels)+ 1;
           SetStepEdit.Text:=IntToStr(ScanStepSize);
           StartX:= Half_resolution - trunc((Pixels*ScanStepSize)/2)-1;
           StartY:= Half_resolution - trunc((Pixels*ScanStepSize)/2)-1;
         end;
       Tip_GoTo(StartX, StartY, SingleStepSize);
       UpdateXYPositionIndicators;
       delay(WaitTime); //wait for things to settle
       // Now start the scan
       SetLength(ForwardData, Pixels, Pixels); //Forward data array
       SetLength(ReverseData, Pixels, Pixels); //same for reverse data
       Current_x:=Current_x-ScanStepSize;
       Current_y:=Current_y-ScanStepSize;
       i:=0;
       while scanning and (i<=Pixels-1) do
         begin
           P:=ForwardBitMap.ScanLine[i]; //Bitmap scan lines
           Q:=ReverseBitMap.ScanLine[i];
           Current_y:=Current_y+ScanStepSize;
           //first the forward scan
           j:=0;
           while scanning and (j<=Pixels-1) do
             begin
               //note that Tip_GoTo updates Current_x
               x_value:=Current_x+ScanStepSize;
               Tip_GoTo(x_value, Current_y, SingleStepSize);
               UpdateXYPositionIndicators;
               UpdateZPositionIndicators;
               delay(WaitTime);
               ForwardData[i,j]:=Current_z;
               P[j]:=ColorScheme(AFM_PlotColor, Current_z);
               Application.ProcessMessages;
               inc(j);
             end;
           //Draw the bitmap on the screen
           DrawingRect:=Rect(0,0, ForwardImage.Height, ForwardImage.Width);
           ForwardImage.Canvas.StretchDraw(DrawingRect, ForwardBitMap);
           //reset parameters for reverse sweep
           Current_x:=Current_x + ScanStepSize;
           j:=Pixels-1;
           while scanning and (j>=0) do
             begin
               x_value:=Current_x - ScanStepSize;
               Tip_GoTo(x_value, Current_y, SingleStepSize);
               UpdateXYPositionIndicators;
               UpdateZPositionIndicators;
               delay(WaitTime);
               ReverseData[i,j]:=Current_z;
               Q[j]:=ColorScheme(AFM_PlotColor, Current_z);
               Application.ProcessMessages;
               dec(j);
             end;
           //Draw the bitmap on the screen  
           DrawingRect:=Rect(0,0, ReverseImage.Height, ReverseImage.Width);
           ReverseImage.Canvas.StretchDraw(DrawingRect, ForwardBitMap);
         end;
       //Update the interfaces
       ScanBtn.Caption := 'Scan';
       scanning := FALSE;
       StatusLabel.Caption:='Ready';
     end;

end;

procedure TAFMPLL.WaitTimeSpinEditChange(Sender: TObject);
begin
  WaitTime:=WaitTimeSpinEdit.Value;
end;

function TAFMPLL.ColorScheme(Color: PlotColor; DataValue:integer):TRGBTriple;
var
  TempResult : TRGBTriple;

begin
  TempResult.rgbtBlue:=0;
  TempResult.rgbtRed:=0;
  TempResult.rgbtGreen:=0;
  if Color = Red then
    TempResult.rgbtRed:= Word(DataValue)
   else if Color = Blue then
    TempResult.rgbtBlue:= Word(DataValue)
   else if Color = Green then
    TempResult.rgbtGreen:= Word(DataValue)
   else   //we assume a BW representation
      with TempResult do
        begin
          rgbtBlue:=Word(DataValue);
          rgbtRed:=rgbtBlue;
          rgbtGreen:=rgbtBlue;
        end;
  ColorScheme:=TempResult;
end;  
procedure TAFMPLL.SetPointEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then SetPoint:=StrToFloat(SetPointEdit.Text);
end;

procedure TAFMPLL.PropControlEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then PropGain:=StrToFloat(PropControlEdit.Text);
end;

procedure TAFMPLL.IntControlEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then IntGain:=StrToFloat(IntControlEdit.Text);
end;

procedure TAFMPLL.DiffControlEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then DiffGain:=StrToFloat(DiffControlEdit.Text);
end;

procedure TAFMPLL.SetXEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then
    begin
      X_Set := StrToInt(SetXEdit.Text);
      Tip_GoTo(X_Set, Current_Y, SingleStepSize);
      UpdateXYPositionIndicators;
    end;
end;

procedure TAFMPLL.SetYEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then
    begin
      Y_Set := StrToInt(SetYEdit.Text);
      Tip_GoTo(Current_X, Y_Set, SingleStepSize);
      UpdateXYPositionIndicators;
    end;
end;

procedure TAFMPLL.SetStepEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=Chr(13) then   ScanStepSize := StrToInt(SetStepEdit.Text);
end;


procedure TAFMPLL.DataTimerTimer(Sender: TObject);
begin
  if feedback then UpdateZPositionIndicators;
  Chan0Reading.Caption:=FloatToStrF(ReadAveragedAnalogChannel(PrimaryChannelNumber, 1), ffFixed, 10, 4);
  Chan1Reading.Caption:=FloatToStrF(ReadAveragedAnalogChannel(SecondaryChannelNumber, 1), ffFixed, 10, 4);
end;

end.
