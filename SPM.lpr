program SPM;

{$mode objfpc}{$H+}
//{$linklib stdc++}
//{$MODE Delphi}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads, cmem,
  {$ENDIF}{$ENDIF}
//{$IFDEF LCL}
  Interfaces,
//{$ENDIF}
  Forms, LResources, TAChartLazarusPkg,
  SPM_Main in 'SPM_Main.pas' {SPM_MainForm},
  TipCoarseApproach in 'TipCoarseApproach.pas' {CoarseApproachTool},
  {EasyPLL_TLB in 'c:\program files\borland\bds\4.0\Imports\EasyPLL_TLB.pas',}
  SystemConfiguration in 'SystemConfiguration.pas' {SysConfig},
  FileFunctions in 'FileFunctions.pas', DAQFunctions in 'DAQFunctions.pas',
  ScanTubeFunctions in 'ScanTubeFunctions.pas',
  AttocubeFunctions in 'AttocubeFunctions.pas',
  WalkerFunctions in 'WalkerFunctions.pas',
  GraphicsRoutines in 'GraphicsRoutines.pas',
  GlobalFunctions in 'GlobalFunctions.pas', daq_comedi_functions,
  daq_comedi_types, GlobalVariables, rtai_comedi_functions, rtai_comedi_types,
  rtai_functions, rtai_types, AFMTopography, plot, etpackage, SdpoSerialLaz,
  MFM, Oscilloscope, bgrabitmappack, EFM, STM, PIDTuning;

{$IFDEF MSWINDOWS}
{$R *.RES}
{$ENDIF}

{$IFDEF WINDOWS}{$R SPM.rc}{$ENDIF}

begin
  {$I SPM.lrs}
  Application.Initialize;
  Application.CreateForm(TSPM_MainForm, SPM_MainForm);
  Application.CreateForm(TCoarseApproachTool, CoarseApproachTool);
  Application.CreateForm(TSysConfig, SysConfig);
  Application.CreateForm(TMFMForm, MFMForm);
  Application.CreateForm(TOscilloscopeForm, OscilloscopeForm);
  Application.CreateForm(TAFMTopograph, AFMTopograph);
  Application.CreateForm(TEFMForm, EFMForm);
  Application.CreateForm(TSTMForm, STMForm);
  Application.CreateForm(TPIDTuningForm, PIDTuningForm);
  Application.Run;
end.
