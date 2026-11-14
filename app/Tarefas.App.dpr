program Tarefas.App;

uses
  Vcl.Forms,
  Cliente.Config in 'src\Config\Cliente.Config.pas',
  Cliente.Modelos in 'src\Model\Cliente.Modelos.pas',
  Cliente.Api in 'src\Service\Cliente.Api.pas',
  Cliente.Presenter in 'src\Presenter\Cliente.Presenter.pas',
  Principal.Form in 'src\UI\Principal.Form.pas' {FormPrincipal};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormPrincipal, FormPrincipal);
  Application.Run;
end.
