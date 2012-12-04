unit SPMUtilities;

interface
uses Windows;
  var
    IntegratedError : real; //Integrated error for the PID Integral function
    NewPIDLoop      : boolean; //Set to true if a new pid loop

procedure delay(msecs:Dword);
function PID(prop, int, diff, error : real): real;


implementation

uses Forms;
var
    LastTime  : DWord;
    LastError : real;
{-------------------------------------------------------------------------}
procedure delay(msecs:dword);
  var
    FirstTickCount:Dword;
  begin
    FirstTickCount:=GetTickCount;
    repeat
      Application.ProcessMessages; {allowing access to other
                                      controls, etc.}
    until ((GetTickCount-FirstTickCount) >= msecs);
  end;

{-------------------------------------------------------------------------}
function PID(prop, int, diff, error : real): real;
var
  PropTerm,
  IntTerm,
  DiffTerm         : real;
  TimeDifference   : DWord;

begin
  if NewPIDLoop then
    begin
      NewPIDLoop:=FALSE;
      LastTime:=GetTickCount;
      PID:=prop*error;
      LastError:=error;
      IntegratedError:=0;
    end
   else
    begin
      TimeDifference:=GetTickCount-LastTime;
      IntegratedError:=IntegratedError +(Error*TimeDifference);
      PropTerm:=prop*error;
      IntTerm:=IntegratedError/int;
      DiffTerm:=diff*(error-LastError)/TimeDifference;
      PID:=PropTerm + IntTerm + DiffTerm;
      LastError:=error;
      LastTime:=LastTime+TimeDifference;
    end;
end;
end.
