unit rtai_comedi_functions;

{$mode objfpc}{$H+}
{$linklib libRTAILazarusCInterface.a}

interface

uses
  Classes, SysUtils, daq_comedi_types, rtai_comedi_types;

  var
     SineProcedureThreadID : TThreadID;
     PIDProcedureThreadID  : TThreadID;

  function sinefunction: boolean; cdecl; external;

  function StartSineOutput : boolean;

  function EndSineOutput: boolean;

  function Call_sineoutput(f: pointer): ptrint;

  procedure sineoutput; cdecl; external;

  procedure pid_loop; cdecl; external;

  function Call_pid_loop(f: pointer): ptrint;

  function StartMainTask(priority: integer):boolean; cdecl; external;

  function EndMainTask:boolean; cdecl; external;

  function StartFeedback: boolean;

  function EndFeedback: boolean;


implementation

uses rtai_functions;


function StartSineOutput: boolean;

begin
   StartSineOutput:=FALSE;
   SineProcedureThreadID:=0;
   //check  if hard timer is running, else start it
   hard_timer_running:=rt_is_hard_timer_running;
   if hard_timer_running then stop_rt_timer;
   rt_set_oneshot_mode;
   start_rt_timer(0);
   //sampling_interval:=nano2count(sample_time);
   //start the thread here
   SineProcedureThreadID:=BeginThread(@Call_sineoutput,nil);
   StartSineOutput:=TRUE;
end;

function StartFeedback: boolean;

begin
   StartFeedback:=FALSE;
   PIDProcedureThreadID:=0;
   //check  if hard timer is running, else start it
   //hard_timer_running:=rt_is_hard_timer_running;
   //if hard_timer_running then stop_rt_timer;
   //rt_set_oneshot_mode;
   //start_rt_timer(0);
   //sampling_interval:=nano2count(sample_time);
   //start the thread here
   PIDProcedureThreadID:=BeginThread(@Call_pid_loop,nil);
   StartFeedback:=TRUE;
end;
function EndSineOutput: boolean;
begin
  //if SineProcedureThreadID <> 0 then EndThread(SineProcedureThreadID);
  EndSineOutput:=TRUE;
end;
function EndFeedback: boolean;
begin
  //if SineProcedureThreadID <> 0 then EndThread(SineProcedureThreadID);
  EndFeedback:=TRUE;
end;

function Call_sineoutput(f: pointer): ptrint;
begin
   sineoutput;
   Call_sineoutput:=0;
end;

function Call_pid_loop(f: pointer): ptrint;
begin
   pid_loop;
   Call_pid_loop:=0;
end;

end.

