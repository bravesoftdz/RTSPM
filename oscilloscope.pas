unit Oscilloscope;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  Plotpanel;

type

  { TOscilloscopeForm }

  TOscilloscopeForm = class(TForm)
    OscilloscopePlot: TPlotPanel;
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

