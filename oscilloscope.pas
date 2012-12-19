unit Oscilloscope;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, TAGraph, TASeries, LResources, Forms, Controls,
  Graphics, Dialogs, StdCtrls, Spin, Plotpanel, types, TACustomSeries;

type

  { TOscilloscopeForm }

  TOscilloscopeForm = class(TForm)
    OscilloscopeChart: TChart;
    OscilloscopeChartLineSeries1: TLineSeries;
    OscilloscopeChartLineSeries2: TLineSeries;
    OscilloscopeChartLineSeries3: TLineSeries;
    OscilloscopeChartLineSeries4: TLineSeries;

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

