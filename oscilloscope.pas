unit Oscilloscope;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, TAGraph, TASeries, LResources, Forms, Controls,
  Graphics, Dialogs, Plotpanel;

type

  { TOscilloscopeForm }

  TOscilloscopeForm = class(TForm)
    OscilloscopeChart: TChart;
    OscilloscopeChartLineSeries1: TLineSeries;
    OscilloscopeChartLineSeries2: TLineSeries;
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  OscilloscopeForm: TOscilloscopeForm;

implementation

{ TOscilloscopeForm }



initialization
  {$I oscilloscope.lrs}

end.

