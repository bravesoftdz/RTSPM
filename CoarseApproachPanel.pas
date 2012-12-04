unit CoarseApproachPanel;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, Menus;

type
  TCoarseApproachPanel = class(TForm)
    MainMenu1: TMainMenu;
    ApproachDirection: TSpeedButton;
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
