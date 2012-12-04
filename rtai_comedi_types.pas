unit rtai_comedi_types;

{$mode objfpc}{$H+}
{$linklib libRTAILazarusCInterface.a}

interface

uses
  Classes, SysUtils, rtai_types, daq_comedi_types;

type
 TCdeclThreadFunc = function (user_data:Pointer):Pointer;cdecl;

 PCdeclThreadFuncData = ^TCdeclThreadFuncData;
 TCdeclThreadFuncData = record
   Func: TCdeclThreadFunc;  //cdecl function
   Data: Pointer;           //original data
 end;
var
  SineWaveFrequency  : double; external name 'SineWaveFrequency';
  SineWaveAmplitude  : double; external name 'SineWaveAmplitude';

  sine_loop_running  : integer; external name 'sine_loop_running';
  OutputValue        : double; external name 'OutputValue';
  hard_timer_running : boolean;
  SAMP_TIME          : RTIME; external name 'SAMP_TIME';
  sample_time        : RTIME; external name 'sample_time';
  AnalogInputChannel : Acquisition_channel; external name 'AnalogInputChannel';
  AnalogOutputChannel: Acquisition_channel; external name 'AnalogOutputChannel';
  dev1               : Pcomedi_t; external name 'dev1';

  //Variables associated with real-time PID control
  FeedbackChannel    : Acquisition_channel; external name 'FeedbackChannel';
  ControlChannel     : Acquisition_channel; external name 'ControlChannel';
  pid_loop_running   : integer; external name 'pid_loop_running';
  Logarithmic        : integer; external name 'Logarithmic';  //Flag to set logarithmic feedback control
  PIDParametersChanged  : integer; external name 'PIDParametersChanged'; //Flag to signal that PID parameters have changed
  PropCoff           : double; external name 'PropCoff'; //PID proportional coefficient
  IntTime            : double; external name 'IntTime'; //PID integral time constant
  DiffTime           : double; external name 'DiffTime'; //PID differential time constant
  PIDLoop_Time       : RTIME; external name 'PIDLoop_Time'; //cycling time of the PID loop
  PID_averages       : integer; external name 'PID_averages'; //number of averages to perform
  PIDOutput          : double; external name 'PIDOutput'; //output in volts of the PID
  AveragedPIDOutput  : double; external name 'AveragedPIDOutput'; //output in volts of the PID
  FeedbackReading    : double; external name 'FeedbackReading'; //Feedback channel reading during PID operation
  AveragedFeedbackReading  : double; external name 'AveragedFeedbackReading'; //
  SetPoint           : double; external name 'SetPoint';  //SetPoint for the PID
  FirstPIDPass       : integer; external name 'FirstPIDPass'; //this tells us if this is the first pass, set to FALSE
  OutputPhase        : integer; external name 'OutputPhase'; //sign of the control signal..depends on response
  PIDOutputVariance  : double; external name 'PIDOutputVariance'; //variance of pid output
  //sampling_interval: RTIME; external name 'sampling_interval';

  //Variables associated with the scan tube z axis
  //z coordinate is measured with respect to surface.  Hence, if the tube is completey retracted, this is the
  //MaxZposition, which would correspond to -10V, if the AmplifierGainSign were 1.
  //Since it is -1 currently, this means that MaxZVoltage is +10V.
  MinZVoltage         : double; external name 'MinZVoltage'; //Voltage corresponding to the minimum Z position
  MaxZVoltage         : double; external name 'MaxZVoltage'; // name 'MaxZVoltage'; //Voltage corresponding to the maximum Z position
  AmplifierGainSign   : integer; external name 'AmplifierGainSign'; // name 'AmplifierGainSign'; //Sign of the Z amplifier gain



implementation

initialization
 AmplifierGainSign:=-1;


end.

