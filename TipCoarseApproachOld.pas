unit TipCoarseApproachOld;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, TeeProcs, TeEngine, Chart, Series;

type
  TCoarseApproachTool = class(TForm)
    TipSignal: TChart;
    ZApproachBar: TProgressBar;
    Label1: TLabel;
    Label3: TLabel;
    StatusLabel: TLabel;
    StepNumberLabel: TLabel;
    SignalControlGroupBox: TGroupBox;
    Label2: TLabel;
    Label4: TLabel;
    Chan0Reading: TLabel;
    Label5: TLabel;
    Chan1Reading: TLabel;
    SetPointEdit: TEdit;
    WalkerControlGroupBox: TGroupBox;
    WalkerRetractBtn: TButton;
    WalkerApproachBtn: TButton;
    StepByStepBtn: TButton;
    AcquireBtn: TButton;
    SaveBtn: TButton;
    JiggleBtn: TButton;
    Panel1: TPanel;
    Time_Retract_Btn: TButton;
    Time_approach_Btn: TButton;
    WalkerTimeEdit: TEdit;
    Label6: TLabel;
    Scan_Tube_GroupBox: TGroupBox;
    Label8: TLabel;
    Label9: TLabel;
    SetXEdit: TEdit;
    SetYEdit: TEdit;
    SetZEdit: TEdit;
    DataTimer: TTimer;
    Series1: TFastLineSeries;
    Series2: TFastLineSeries;
    SaveDialog: TSaveDialog;
    UpdatingCheckBox: TCheckBox;
    Label7: TLabel;
    CriticalStepNumberLabel: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    procedure WalkerRetractBtnMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure WalkerRetractBtnMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure WalkerApproachBtnMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure StepByStepBtnClick(Sender: TObject);
    procedure DataTimerTimer(Sender: TObject);
    procedure AcquireBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
    procedure Time_Retract_BtnClick(Sender: TObject);
    procedure JiggleBtnClick(Sender: TObject);
    procedure SetPointEditKeyPress(Sender: TObject; var Key: Char);
    procedure WalkerTimeEditKeyPress(Sender: TObject; var Key: Char);
    procedure SetXEditKeyPress(Sender: TObject; var Key: Char);
    procedure SetYEditKeyPress(Sender: TObject; var Key: Char);
    procedure SetZEditKeyPress(Sender: TObject; var Key: Char);
    procedure FormHide(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
    function Stop_approach: boolean;
    function UpdateXYPositionIndicators: boolean;
    function UpdateZPositionIndicators: boolean;
    function UpdateDataChannelIndicators: boolean;
    function Check_tip: boolean;
    function zScan: boolean;
    function In_Contact: boolean;

  end;

var
  CoarseApproachTool: TCoarseApproachTool;


  ReadingAverages     : integer = 10; //the number of averages to take on a analog reading
  CoarseApproachStepNumber       : integer = 0; //current coarse approach step number
  CriticalStepNumber             : integer = 0; //Step number at which contact occurs
  PrimaryChannelNumber           : integer = 0 ; //Analog channel for feedback signal
  SecondaryChannelNumber         : integer = 1 ; //Analog Channel for additional signal
  ShortAverage                   : integer = 3; //Rapid reading
  Chan0Points,
  Chan1Points                   : array[0..4095] of real;
  Contacted                     : boolean;
  Jiggle                        : boolean;
  
implementation

{$R *.DFM}

uses
    NI6733, ScanTubeFunctions, WalkerFunctions, GlobalVariables,
    SPMUtilities, SPM_Main;

const
  MaxCoarseApproachSteps = 10000; //Maximum number of coarse approach steps



procedure TCoarseApproachTool.WalkerRetractBtnMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //this procedure continuously retracts the walker while the mouse is
  //depressed over the button
  StatusLabel.Caption:='Retracting Walker';
  Retract_Walker;
end;

procedure TCoarseApproachTool.WalkerRetractBtnMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Stop_Walker;
  StatusLabel.Caption:='Ready';
end;

procedure TCoarseApproachTool.WalkerApproachBtnMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //this procedure continuously approaches the walker while the mouse is
  //depressed over the button
  StatusLabel.Caption:='Walker Approaching';
  Approach_Walker;
end;

procedure TCoarseApproachTool.StepByStepBtnClick(Sender: TObject);
  var
    StepNumber     : integer;


  //This procedure does a coarse approach step(s), checks
  //for contact, then repeats
  begin
    if Approaching then
      begin
       Approaching := FALSE;
       StepByStepBtn.Caption:='Auto Approach';
      end
     else
      begin
        Approaching := True;
        StepByStepBtn.Caption:= 'Cancel';
        AcquireBtn.Enabled := False;
        //CommandExit.Enabled = False
        DataTimer.Enabled := FALSE;
        Initial_reading := ReadAveragedAnalogChannel(PrimaryChannelNumber, ReadingAverages);
        FreqShift:=Initial_reading*FreqOutputScaleFact;
        //Set the center frequency so that the
        CenterFrequency:=SPM_MainForm.EasyPLL.PLLCenterFrq;
        CenterFrequency:=CenterFrequency+FreqShift;
        SPM_MainForm.EasyPLL.PLLCenterFrq:=CenterFrequency;
        InitialFrequency:=CenterFrequency;
        //Take another initial reading
        Initial_reading := ReadAveragedAnalogChannel(PrimaryChannelNumber, ReadingAverages);
        if (abs(Initial_reading)>9) then
            StatusLabel.Caption := 'Signal out of range'
         else
          begin
            StepNumber:=0;
            StatusLabel.Caption := 'Auto Approach';
            Contacted:=FALSE;
            while (StepNumber<MaxCoarseApproachSteps) and (not Contacted)
                                                        and Approaching do
              begin
                inc(StepNumber);
                Check_Tip; //Extend the tip and see if we are in contact
                // If we are in contact, this will set the global variable Contacted to True
                if Contacted then
                  begin
                    //if the number of iterations is less than 1, we stop
                    delay(300); //wait for 300 msec
                    if (StepNumber<1) then
                      begin
                        StatusLabel.Caption := 'Contacted';
                        CriticalStepNumber:=CoarseApproachStepNumber;
                        CriticalStepNumberLabel.Caption:=IntToStr(CriticalStepNumber);
                      end
                     else //Check if contact has truly been made once more
                       begin
                         Contacted:=FALSE;
                         if Check_Tip then
                           begin
                             StatusLabel.Caption := 'Contacted';
                             CriticalStepNumber:=CoarseApproachStepNumber;
                             CriticalStepNumberLabel.Caption:=IntToStr(CriticalStepNumber);
                           end;
                       end; //of else i<10
                  end; //of if Contacted
                {trap any buttons the operator has pressed, especially
                              the same button, which sets Approaching to FALSE}
                Application.ProcessMessages;

                if Approaching then //if we are still approaching, then take a step
                  begin
                    Walker_Down_Step(200);
                    delay (300);
                  end; //of if approaching
                StepNumberLabel.Caption:=IntToStr(CoarseApproachStepNumber);
              end; // of while
          end; //of if abs(initial_reading...
      end; // of if Approaching else
      Stop_approach;
  end;

{-----------------------------------------------------------------------------}

function TCoarseApproachTool.Stop_approach: boolean;

  begin
    Approaching := FALSE;
    StepByStepBtn.Caption := 'Auto Approach';
    AcquireBtn.Enabled := True;
    Stop_Approach:=TRUE;
    DataTimer.Enabled:=TRUE;
  end;

procedure TCoarseApproachTool.DataTimerTimer(Sender: TObject);
begin
  Current_Z_Label.Caption:=FloatToStr(Current_z);
  Chan0Reading.Caption:=FloatToStrF(ReadAveragedAnalogChannel(PrimaryChannelNumber, 1), ffFixed, 10, 4);
  Chan1Reading.Caption:=FloatToStrF(ReadAveragedAnalogChannel(SecondaryChannelNumber, 1), ffFixed, 10, 4);
end;

procedure TCoarseApproachTool.AcquireBtnClick(Sender: TObject);
begin
  if Approaching then
    begin
      Approaching := FALSE;
      AcquireBtn.Caption:= 'Acquire Curve';
      StepByStepBtn.Enabled:=TRUE;
      StatusLabel.Caption:=  'Ready';
      DataTimer.Enabled:=TRUE;
    end
    else
      begin
        Approaching := TRUE;
        AcquireBtn.Caption := 'Cancel';
        StepByStepBtn.Enabled := FALSE;
        StatusLabel.Caption := 'Approach';
        DataTimer.Enabled:=FALSE;
        Chan0Reading.Caption:=FloatToStrF(ReadAveragedAnalogChannel(PrimaryChannelNumber, 1), ffFixed, 10, 4);
        zScan;
        StatusLabel.Caption := 'Done';
        AcquireBtn.Caption := 'Acquire';
        StepByStepBtn.Enabled := TRUE;
        Approaching := FALSE;
        DataTimer.Enabled:=TRUE;
      end;
end;

procedure TCoarseApproachTool.FormShow(Sender: TObject);
begin
   Series1.Clear;
   Series1.Repaint;
   Series2.Clear;
   Series2.Repaint;
   SetPoint:=1;
   CoarseApproachStepNumber:=0;
   SetPointEdit.Text:=FloatToStrF(SetPoint, ffFixed, 10, 4);
   WalkerTimeEdit.Text:=IntToStr(WalkerMovingTime);
   UpdateXYPositionIndicators;
   UpdateZPositionIndicators;
   Contacted:=FALSE;
   Jiggle:=FALSE;
   UpdatingCheckBox.Checked:=FALSE;
   DataTimer.Enabled:=TRUE;
end;

procedure TCoarseApproachTool.SaveBtnClick(Sender: TObject);
var
  FileExt,
  TempString,
  PathName

             : string;
  j          : integer;
  WriteFile  : boolean;
  OutputFile : TextFile;

begin
  WriteFile:=TRUE;
  SaveDialog.InitialDir:=PathName;
  SaveDialog.FileName:='*.txt';
  if SaveDialog.Execute then
  begin
    FileExt:=ExtractFileExt(SaveDialog.FileName);
    PathName:=ExtractFilePath(SaveDialog.FileName);
    SaveDialog.InitialDir:=PathName;
    TempString:=ExtractFileName(SaveDialog.FileName);
    if FileExists(SaveDialog.FileName) then
      if MessageDlg('File already exists! Overwrite?',
           mtWarning, [mbYes,mbNo], 0)=mrNo then WriteFile:=FALSE;
    if WriteFile then
      begin
        AssignFile(OutputFile, SaveDialog.FileName);
        Rewrite(OutputFile);
        // #9 is the tab charcter
        Writeln(OutputFile, ' Z  '#9'  Chan 0 '#9'  Chan  ');
        for j:=0 to NumbDataPts-1 do
          WriteLn(OutputFile, Series1.XValues.Value[j],#9, Chan0Points[j],#9, Chan1Points[j]);
        CloseFile(OutputFile);
      end;
  end;
end;

procedure TCoarseApproachTool.Time_Retract_BtnClick(Sender: TObject);
var
  t1, t2  : integer;
  ExitLoop : boolean;
begin
  if WalkerOn Then
    begin
      Stop_Walker; //Stop the walker
      WalkerOn := FALSE;
      Time_Retract_Btn.Caption := 'Timed Retract';
    end
   else
    begin
      WalkerOn := TRUE;
      Time_Retract_Btn.Caption := 'Stop';
      t1 := GetTickCount;
      Retract_walker;
      StatusLabel.Caption:= 'Walker Retracting';
      ExitLoop:=FALSE;
      repeat
        begin
          t2 := GetTickCount;
          Application.ProcessMessages;
          if not WalkerOn then ExitLoop:=TRUE;
        end;
      until ExitLoop or ((t2-t1)>WalkerMovingTime);
      Stop_Walker;
      Time_Retract_Btn.Caption := 'Timed Retract';
      StatusLabel.Caption:= 'Ready';
      WalkerOn:=FALSE;
    end;
end;

function TCoarseApproachTool.UpdateZPositionIndicators: boolean;
begin
  ZApproachBar.Position:=Current_Z;
  SetZEdit.Text:=IntToStr(Current_Z);
  Current_Z_Label.Caption:=SetZEdit.Text;
  UpdateZPositionIndicators:=TRUE;
end;

function TCoarseApproachTool.UpdateXYPositionIndicators: boolean;
begin
  SetXEdit.Text:=IntToStr(Current_x);
  SetYEdit.Text:=IntToStr(Current_y);
  UpdateXYPositionIndicators:=TRUE;
end;

{------------------------------------------------------------------------}
  function TCoarseApproachTool.Check_tip: boolean;
  var
    i    : integer;
    Current_value : real;

  begin
    Check_tip:=FALSE;
    Contacted := FALSE;
    Series1.Clear;
    Series1.Repaint;
    Series2.Clear;
    Series2.Repaint;
    i:=0;
    while (i<=Board_resolution) and (not Contacted) do
      begin
        MoveZ(i, ZStepSize);
        UpdateZPositionIndicators;
        //UpdateDataChannelIndicators;
        if In_Contact or (not Approaching) then
          begin
            Check_tip := TRUE;
            Contacted := TRUE;
            MoveZ(0, ZStepSize);
            UpdateZPositionIndicators;
            SPM_MainForm.EasyPLL.PLLCenterFrq:=InitialFrequency;
          end;
        Inc(i, ZStepSize);
      end;
    if not Contacted then
      begin
        Application.ProcessMessages;
        //move back the entire length so that we can start another coarse approach step
        MoveZ(0, LargeStepSize);
        UpdateZPositionIndicators;
        UpdateDataChannelIndicators;
      end;
  end;
{----------------------------------------------------------------------------------}
  function TCoarseApproachTool.zScan: boolean;
  var
     j                   : integer;
     EndApproach         : boolean;
  begin
    //Clear the plots for Channels 0 and 1
    Series1.Clear;
    Series1.Repaint;
    Series2.Clear;
    Series2.Repaint;
    //Take an initial reading for feedback purposes
    Initial_reading := ReadAveragedAnalogChannel(PrimaryChannelNumber, ReadingAverages);
    EndApproach:=FALSE;
    j:=0;
    //Completely retract the tip
    MoveZ(0, LargeStepSize);
    UpdateZPositionIndicators;
    UpdateDataChannelIndicators;
    while not EndApproach do
      begin
        MoveZ(Current_Z + ZStepSize, ZStepSize);
        UpdateZPositionIndicators;
        //Note that MoveZ defines Current_z to be its first argument
        //Read the two channels
        Chan0Points[j]:= ReadAveragedAnalogChannel(PrimaryChannelNumber, ReadingAverages);
        Chan1Points[j]:= ReadAveragedAnalogChannel(SecondaryChannelNumber, ReadingAverages);
        //Display them on the form
        Chan0Reading.Caption:=FloatToStrF(Chan0Points[j], ffFixed, 10, 4);
        Chan1Reading.Caption:=FloatToStrF(Chan1Points[j], ffFixed, 10, 4);
        //add them to the plot
        Series1.AddXY(Current_Z, Chan0Points[j], '', -1);
        Series2.AddXY(Current_Z, Chan1Points[j], '', -1);
        Application.ProcessMessages;
        //set a condition to end the approach
        EndApproach := (abs(Chan0Points[j]-Initial_reading)>SetPoint) or
              (not Approaching) or (Current_Z>Board_resolution) or (j>2047);
        Inc(j);
      end;
    NumbDataPts:=j;
      //Now reverse the process, but do not take any data
    while (j>0) and Approaching do
      begin
        MoveZ(Current_Z - ZStepSize, ZStepSize);
        UpdateZPositionIndicators;
        Application.ProcessMessages;
        Dec(j);
      end;
    zScan:=TRUE;
  end;
{----------------------------------------------------------------------------}
  function TCoarseApproachTool.In_Contact: boolean;
  var
    Current_value : real;
  begin
    In_Contact:=FALSE;
    Current_Value := ReadAveragedAnalogChannel(PrimaryChannelNumber, ShortAverage);
    Chan0Reading.Caption := FloatToStrF(Current_Value, ffFixed, 10, 4);

    if abs(Current_Value - Initial_reading)>Noise then
      begin
        //Change the center frequency
        CenterFrequency:=CenterFrequency+(Current_value-Initial_reading)*FreqOutputScaleFact;
        Initial_reading:=Current_Value;
        FreqShift:=CenterFrequency-InitialFrequency;
        SPM_MainForm.EasyPLL.PLLCenterFrq:=CenterFrequency;
      end;
    if Current_Z > ZStepSize then
       Series1.AddXY(Current_Z, FreqShift, '', -1);       
    if abs(FreqShift) > SetPoint then In_Contact:=TRUE;
    //  if UpdatingCheckBox.Checked then  Application.ProcessMessages;
  end;

{-----------------------------------------------------------------------------}
  function TCoarseApproachTool.UpdateDataChannelIndicators: boolean;
  begin
    Chan0Reading.Caption:=FloatToStrF(ReadAveragedAnalogChannel(PrimaryChannelNumber, 1), ffFixed, 10, 4);
    Chan1Reading.Caption:=FloatToStrF(ReadAveragedAnalogChannel(SecondaryChannelNumber, 1), ffFixed, 10, 4);
    UpdateDataChannelIndicators:=TRUE;
  end;

procedure TCoarseApproachTool.JiggleBtnClick(Sender: TObject);
begin
  if not Jiggle then
    begin
      //disable the other buttons
      WalkerRetractBtn.Enabled:=FALSE;
      WalkerApproachBtn.Enabled:=FALSE;
      StepByStepBtn.Enabled:=FALSE;
      AcquireBtn.Enabled:=FALSE;
      SaveBtn.Enabled:=FALSE;
      Time_Retract_Btn.Enabled:=FALSE;
      Time_Approach_Btn.Enabled:=FALSE;
      JiggleBtn.Caption:='Cancel';
      StatusLabel.Caption:='Jiggling Walker';

      //Now start Jiggling
      Jiggle:=TRUE;
      while Jiggle do
        begin
          Retract_Walker;
          Delay(200);
          Stop_Walker;
          Approach_Walker;
          Delay(200);
          Stop_Walker;
          Application.ProcessMessages;
        end;
    end
   else
    begin
      //enable the other buttons
      WalkerRetractBtn.Enabled:=TRUE;
      WalkerApproachBtn.Enabled:=TRUE;
      StepByStepBtn.Enabled:=TRUE;
      AcquireBtn.Enabled:=TRUE;
      SaveBtn.Enabled:=TRUE;
      Time_Retract_Btn.Enabled:=TRUE;
      Time_Approach_Btn.Enabled:=TRUE;
      JiggleBtn.Caption:='Jiggle';
      Jiggle:=FALSE;
      StatusLabel.Caption:='Ready';
      //Now start Jiggling
      Jiggle:=TRUE;
    end;

end;

procedure TCoarseApproachTool.SetPointEditKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key=Chr(13) then //if the user has pressed the enter key
    SetPoint:=StrToFloat(SetPointEdit.Text);
end;

procedure TCoarseApproachTool.WalkerTimeEditKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key=Chr(13) then WalkerMovingTime:=StrToInt(WalkerTimeEdit.Text);
end;

procedure TCoarseApproachTool.SetXEditKeyPress(Sender: TObject;
  var Key: Char);

var
  X_position   : integer;
begin
 if Key=Chr(13) then
   begin
     X_position:= StrToInt(SetXEdit.Text);
     Tip_GoTo(X_position, Current_y, XYStepSize);
     UpdateXYPositionIndicators;
   end;
end;

procedure TCoarseApproachTool.SetYEditKeyPress(Sender: TObject;
  var Key: Char);
var
  Y_position   : integer;
begin
  if Key=Chr(13) then
    begin
      Y_position:= StrToInt(SetYEdit.Text);
      Tip_GoTo(Current_x, Y_position, XYStepSize);
      UpdateXYPositionIndicators;
    end;
end;
procedure TCoarseApproachTool.SetZEditKeyPress(Sender: TObject;
  var Key: Char);
var
  Z_position : integer;
begin
  if Key=Chr(13) then
    begin
      Z_position := StrToInt(SetZEdit.Text);
      MoveZ(Z_position, ZStepSize);
      UpdateZPositionIndicators;
    end;
end;
procedure TCoarseApproachTool.FormHide(Sender: TObject);
begin
   DataTimer.Enabled:=FALSE;
end;

procedure TCoarseApproachTool.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  DataTimer.Enabled:=FALSE;
  //Retract_Walker;
  //Stop_Walker;
  //MoveZ(Half_Resolution, ZStepSize);
end;

end.
