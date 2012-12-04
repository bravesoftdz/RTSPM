unit AttocubeFunctions;

{$MODE Delphi}

interface
  uses GlobalVariables;

  procedure InitializeAttocube;
  procedure AttocubePlusMove(WhichAxis: Axis);
  procedure AttocubeMinusMove(WhichAxis: Axis);
  procedure AttocubeStop(WhichAxis:Axis);
  procedure AttocubeTimedPlusMove(WhichAxis:Axis; MoveTime:integer);
  procedure AttocubeTimedMinusMove(WhichAxis:Axis; MoveTime: integer);
  procedure AttocubeTimedZApproach(MoveTime:integer);
  procedure AttocubeTimedZRetract(MoveTime:integer);

implementation
 uses SPM_Main, SysUtils, GlobalFunctions,SdpoSerial;
{ --------------------------------------------------------------------------}
procedure InitializeAttocube;
begin
  //Set the Com Port
  With SPM_MainForm.AttocubeComPort do
  begin
    BaudRate:=br__9600;
    Device:='/dev/ttyS'+IntToStr(AttocubeComPortNumber-1);
    DataBits:=db8bits;
    Parity:=pNone;
    StopBits:=sbOne;
    if not Active then Active:=TRUE;
    if Active then  //set each axis in step mode
      begin
        WriteData('setm 1 stp'+Chr(13));
        WriteData('setm 2 stp'+Chr(13));
        WriteData('setm 3 stp'+Chr(13));
      end;
  end;
end;
{----------------------------------------------------------------------------}
procedure AttocubePlusMove(WhichAxis: Axis);
  begin
    With SPM_MainForm.AttocubeComPort do
    begin
      if WhichAxis=XAxis then
        begin
          WriteData('setm 1 stp'+Chr(13));
          WriteData('stepu 1 c'+Chr(13));
        end
       else if WhichAxis=YAxis then
        begin
          WriteData('setm 2 stp'+Chr(13));
          WriteData('stepu 2 c'+Chr(13));
        end
       else if WhichAxis=ZAxis then
        begin
          WriteData('setm 3 stp'+Chr(13));
          WriteData('stepu 3 c'+Chr(13));
        end;

    end;
  end;
{-----------------------------------------------------------------------------}
procedure AttocubeMinusMove(WhichAxis: Axis);
  begin
    With SPM_MainForm.AttocubeComPort do
    begin
      if WhichAxis=XAxis then
        begin
          WriteData('setm 1 stp'+Chr(13));
          WriteData('stepd 1 c'+Chr(13));
        end
       else if WhichAxis=YAxis then
        begin
          WriteData('setm 2 stp'+Chr(13));
          WriteData('stepd 2 c'+Chr(13));
        end
       else if WhichAxis=ZAxis then
        begin
          WriteData('setm 3 stp'+Chr(13));
          WriteData('stepd 3 c'+Chr(13));
        end;

    end;
  end;
{------------------------------------------------------------------------------}
procedure AttocubeStop(WhichAxis:Axis);
  begin
    With SPM_MainForm.AttocubeComPort do
    begin
      if WhichAxis=XAxis then
        begin
          WriteData('stop 1'+Chr(13));
          WriteData('setm 1 gnd'+Chr(13));
        end
       else if WhichAxis=YAxis then
        begin
          WriteData('stop 2'+Chr(13));
          WriteData('setm 2 gnd'+Chr(13));
        end
       else if WhichAxis=ZAxis then
        begin
          WriteData('stop 3'+Chr(13));
          WriteData('setm 3 gnd'+Chr(13));
        end;

    end;
  end;
{---------------------------------------------------------------------------}
procedure AttocubeTimedPlusMove(WhichAxis:Axis; MoveTime:integer);
  begin
    AttocubePlusMove(WhichAxis);
    delay(MoveTime);
    AttocubeStop(WhichAxis);
  end;
{---------------------------------------------------------------------------}
procedure AttocubeTimedMinusMove(WhichAxis:Axis; MoveTime: integer);
  begin
    AttocubeMinusMove(WhichAxis);
    delay(MoveTime);
    AttocubeStop(WhichAxis);
  end;
{---------------------------------------------------------------------------}
procedure AttocubeTimedZApproach(MoveTime:integer);
  begin
    With SPM_MainForm.AttocubeComPort do
      begin
        WriteData('setm 3 stp'+Chr(13));
        WriteData('stepu 3 c'+Chr(13));
        delay(MoveTime);
        WriteData('stop 3'+Chr(13));
        WriteData('setm 3 gnd'+Chr(13));
      end;
  end;
{---------------------------------------------------------------------------}
procedure AttocubeTimedZRetract(MoveTime:integer);
  begin
    With SPM_MainForm.AttocubeComPort do
      begin
        WriteData('setm 3 stp'+Chr(13));
        WriteData('stepd 3 c'+Chr(13));
        delay(MoveTime);
        WriteData('stop 3'+Chr(13));
        WriteData('setm 3 gnd'+Chr(13));
      end;
  end;
end.
