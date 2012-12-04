program SPM;

uses
{$IFDEF LCL}
  Interfaces,
{$ENDIF}
  Forms,
  SPM_Main in 'SPM_Main.pas' {SPM_MainForm},
  TipCoarseApproach in 'TipCoarseApproach.pas' {CoarseApproachTool},
  GlobalVariables in 'GlobalVariables.pas',
  nidaqmx in 'nidaqmx.pas',
  EasyPLL_TLB in 'c:\program files\borland\bds\4.0\Imports\EasyPLL_TLB.pas',
  SystemConfiguration in 'SystemConfiguration.pas' {SysConfig},
  FileFunctions in 'FileFunctions.pas',
  DAQFunctions in 'DAQFunctions.pas',
  ScanTubeFunctions in 'ScanTubeFunctions.pas',
  AttocubeFunctions in 'AttocubeFunctions.pas',
  WalkerFunctions in 'WalkerFunctions.pas',
  AFMTopography in 'AFMTopography.pas' {AFMTopograph},
  GraphicsRoutines in 'GraphicsRoutines.pas',
  GlobalFunctions in 'GlobalFunctions.pas';

{$IFDEF MSWINDOWS}
{$R *.RES}
{$ENDIF}

begin
  Application.Initialize;
  Application.Title := 'SPM';
  Application.CreateForm(TSPM_MainForm, SPM_MainForm);
  Application.CreateForm(TCoarseApproachTool, CoarseApproachTool);
  Application.CreateForm(TSysConfig, SysConfig);
  Application.CreateForm(TAFMTopograph, AFMTopograph);
  Application.Run;
end.
