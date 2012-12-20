unit SPM_Main;
//Checking git changes:  This version is on the PlotPanelReplacement Branch

{$MODE Delphi}
//{$mode objfpc}{$H+}

interface

uses
  {$IFNDEF LCL}
  Windows, Messages,
  {$ELSE}
  LclIntf, LMessages, LclType,
  {$ENDIF}
  SysUtils, Classes, Graphics, Controls, Forms, Dialogs, Buttons,
  ExtCtrls, LResources, SdpoSerial, EpikTimer;

type

  { TSPM_MainForm }

  TSPM_MainForm = class(TForm)
    CoarseApproachBtn: TBitBtn;
    AFMBtn: TBitBtn;
    AttocubeComPort: TSdpoSerial;
    FastTimer: TEpikTimer;
    STMBtn: TBitBtn;
    MFM_Lift_Btn: TBitBtn;
    Oscilloscope_Btn: TBitBtn;
    EFM_Btn: TBitBtn;
    Bevel1: TBevel;
    ExitProgram: TBitBtn;
    SystemConfiguration: TBitBtn;
    procedure EFM_BtnClick(Sender: TObject);
    procedure MFM_Lift_BtnClick(Sender: TObject);
    procedure Oscilloscope_BtnClick(Sender: TObject);
    procedure STMBtnClick(Sender: TObject);
    procedure SystemConfigurationClick(Sender: TObject);
    procedure CoarseApproachBtnClick(Sender: TObject);
    procedure AFMBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    {EasyPLL :   IEasyPLL;}
  end;

var
  SPM_MainForm: TSPM_MainForm;
  //ExclusiveReadData       : TCriticalSection;
  //ExclusiveMoveZ          : TCriticalSection;
  //ExclusiveWriteData      : TCriticalSection;
  FirstRun                  : boolean = TRUE;


implementation

uses TipCoarseApproach, GlobalVariables, SystemConfiguration, DAQFunctions,
     FileFunctions, AttocubeFunctions, AFMTopography, Oscilloscope, MFM, EFM, STM,
     rtai_comedi_functions, rtai_comedi_types, rtai_functions;

{$IFNDEF LCL}
{$R *.DFM}
{$ELSE}
{$R *.lfm}
{$ENDIF}

type
  tc = class(TThread)
    procedure execute; override;
  end;
  procedure tc.execute;
  begin
  end;
procedure TSPM_MainForm.CoarseApproachBtnClick(Sender: TObject);
begin
  CoarseApproachTool.Show;
end;

procedure TSPM_MainForm.AFMBtnClick(Sender: TObject);
begin
  AFMTopograph.Show;
end;


procedure TSPM_MainForm.FormCreate(Sender: TObject);
begin
  with tc.create(False) do
    begin
      waitfor;
      free;
    end;

  //PID parameters
  SAMP_TIME := 50000; // 70 us, in nanoseconds
  PIDLoop_time := SAMP_TIME;
  PropCoff:=0.001;
  DiffTime:= 1E3;// 1 usec, in nanoseconds
  IntTime:= 1E6; // 1 msec, in nanoseconds
  pid_loop_running := 1;
  SetPoint:=0.5;
  OutputPhase:=1;


  //Initialize all the channel names
  Ch0Input.devicename:='';
  Ch1Input.devicename:='';
  Ch2Input.devicename:='';
  FeedbackChannel.devicename:='';
  ScanXOut.devicename:='';
  ScanYOut.devicename:='';
  ScanZOut.devicename:='';
  ControlChannel.devicename:='';
  if FileExists(SysConfig_file) then ReadSysConfigFile;
  InitializeBoards;
  if UseAttocube then InitializeAttocube;
  //QueryPerformanceFrequency(frequency64);
  ScanResolution:=256;

  //allow nonroot access
  rt_allow_nonroot_hrt;
  //start the main task as a soft real time task with a priority of 10, lower
  //than any other real-time task
  GlobalTaskStarted:=StartMainTask(10);
  //SysConfig.Show;
end;

procedure TSPM_MainForm.FormDestroy(Sender: TObject);
begin
  //ExclusiveReadData.Free;
  //ExclusiveReadData:=nil;
  //ExclusiveWriteData.Free;
  //ExclusiveWriteData:=nil;
  //ExclusiveMoveZ.Free;
  //ExclusiveMoveZ:=nil;
  ReleaseBoards;
  if AttocubeComPort.Active then AttocubeComPort.Active:=FALSE;
  if GlobalTaskStarted then EndMainTask;
  GlobalTaskStarted:=FALSE;
end;


procedure TSPM_MainForm.SystemConfigurationClick(Sender: TObject);
begin
  SysConfig.Show;
end;

procedure TSPM_MainForm.Oscilloscope_BtnClick(Sender: TObject);
begin
  OscilloscopeForm.Show;
end;

procedure TSPM_MainForm.MFM_Lift_BtnClick(Sender: TObject);
begin
  MFMForm.Show;
end;

procedure TSPM_MainForm.EFM_BtnClick(Sender: TObject);
begin
  EFMForm.Show;
end;

procedure TSPM_MainForm.STMBtnClick(Sender: TObject);
begin
  STMForm.Show;
end;

initialization
  {$I SPM_Main.lrs}
  //{$i SPM_Main.lrs}
  //{$i SPM_Main.lrs}
  //{$i SPM_Main.lrs}

end.
