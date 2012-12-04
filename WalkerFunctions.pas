unit WalkerFunctions;

{$MODE Delphi}

interface
  uses GlobalVariables;

  procedure WalkerApproach;
  procedure WalkerRetract;
  procedure WalkerTimedApproach(MoveTime:integer);
  procedure WalkerTimedRetract(MoveTime: integer);
  procedure WalkerStop(WhichAxis: Axis);
  procedure WalkerPlusXMove;
  procedure WalkerMinusXMove;
  procedure WalkerPlusYMove;
  procedure WalkerMinusYMove;
  procedure WalkerPlusZMove;
  procedure WalkerMinusZMove;
  procedure WalkerTimedAxisMinusMove(WhichAxis: Axis; MoveTime: integer);
  procedure WalkerTimedAxisPlusMove(WhichAxis: Axis; MoveTime: integer);
  procedure WalkerTimedZApproach(MoveTime:integer);
  procedure WalkerTimedZRetract(MoveTime:integer);

implementation
  uses AttocubeFunctions;

{-------------------------------------------------------------------------}
  procedure WalkerApproach;
  begin
    AttocubePlusMove(ZAxis);
  end;
{-------------------------------------------------------------------------}
  procedure WalkerRetract;
  begin
    AttocubeMinusMove(ZAxis);
  end;
{------------------------------------------------------------------------}
  procedure WalkerTimedApproach(MoveTime: integer);
  begin
    AttocubeTimedPlusMove(ZAxis, MoveTime);
  end;
{------------------------------------------------------------------------}
  procedure WalkerTimedRetract(MoveTime: integer);
  begin
    AttocubeTimedMinusMove(ZAxis, MoveTime);
  end;
{------------------------------------------------------------------------}
  procedure WalkerStop(WhichAxis: Axis);
  begin
    AttocubeStop(WhichAxis);
  end;
{------------------------------------------------------------------------}
  procedure WalkerPlusXMove;
  begin
    AttocubePlusMove(XAxis);
  end;
{------------------------------------------------------------------------}
  procedure WalkerMinusXMove;
  begin
    AttocubeMinusMove(XAxis);
  end;
{------------------------------------------------------------------------}
  procedure WalkerPlusYMove;
  begin
    AttocubePlusMove(YAxis);
  end;
{-----------------------------------------------------------------------}
  procedure WalkerMinusYMove;
  begin
    AttocubeMinusMove(YAxis);
  end;
{------------------------------------------------------------------------}
  procedure WalkerPlusZMove;
  begin
    AttocubePlusMove(ZAxis);
  end;
{-----------------------------------------------------------------------}
  procedure WalkerMinusZMove;
  begin
    AttocubeMinusMove(ZAxis);
  end;
{------------------------------------------------------------------------}
  procedure WalkerTimedAxisMinusMove(WhichAxis: Axis; MoveTime: integer);
  begin
    AttocubeTimedMinusMove(WhichAxis, MoveTime);
  end;
{------------------------------------------------------------------------}
  procedure WalkerTimedAxisPlusMove(WhichAxis: Axis; MoveTime: integer);
  begin
    AttocubeTimedPlusMove(WhichAxis, MoveTime);
  end;
{--------------------------------------------------------------------------}
  procedure WalkerTimedZApproach(MoveTime:integer);
  begin
    AttocubeTimedZApproach(MoveTime);
  end;
{--------------------------------------------------------------------------}
  procedure WalkerTimedZRetract(MoveTime:integer);
  begin
    AttocubeTimedZRetract(MoveTime);
  end;


  end.
