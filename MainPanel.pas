unit MainPanel;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, Menus, ComCtrls, StdCtrls, Spin;

type
  TCoarseApproachPanel = class(TForm)
    ApproachDirection: TSpeedButton;
    Start: TSpeedButton;
    NumberSteps: TSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    ProgressBar1: TProgressBar;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CoarseApproachPanel: TCoarseApproachPanel;

implementation

{$R *.DFM}

end.
