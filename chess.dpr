program chess;

uses
  Forms,
  main in 'main.pas' {MainForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'CHESS';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
