program CoarseApproach;

uses
  Forms,
  MainPanel in 'MainPanel.pas' {CoarseApproachPanel},
  NI6733 in 'NI6733.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TCoarseApproachPanel, CoarseApproachPanel);
  Application.Run;
end.
