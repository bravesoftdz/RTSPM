unit CoarseApproachver2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, TeeProcs, TeEngine, Chart, StdCtrls, Buttons;

type
  TCoarseApproach = class(TForm)
    Bevel1: TBevel;
    StaticText1: TStaticText;
    ScanMinusX: TBitBtn;
    CoarseApproachCurve: TChart;
    ScanMinusZ: TBitBtn;
    ScanPlusZ: TBitBtn;
    ScanMinusY: TBitBtn;
    ScanPlusY: TBitBtn;
    ScanPlusX: TBitBtn;
    StaticText2: TStaticText;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CoarseApproach: TCoarseApproach;

implementation

{$R *.dfm}

end.
