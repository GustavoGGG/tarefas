program Tarefas.API;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, Horse, Startup.Application;

var
  App: TStartupApplication;
  ApiPort: Integer;
  ApiHost: string;

begin
  ReportMemoryLeaksOnShutdown := True;
  App := nil;

  try
    { Criar e inicializar o App }
    App := TStartupApplication.Create;
    App.Inicializar;

    { Obter porta da configuração }
    ApiPort := App.ObterPorta;
    ApiHost := App.ObterHost;

    { Iniciar servidor HTTP }
    WriteLn('');
    WriteLn('Iniciando servidor HTTP na porta ' + IntToStr(ApiPort) + '...');
    WriteLn('');

    THorse.Listen(ApiPort, ApiHost,
      procedure
      begin
        WriteLn('Servidor rodando em http://' + ApiHost + ':' + IntToStr(ApiPort));
        WriteLn('');
        WriteLn('Swagger UI: http://localhost:' + IntToStr(ApiPort) + '/docs');
        WriteLn('');
      end);
  except
    on E: Exception do
    begin
      WriteLn('Erro: ' + E.Message);
      WriteLn('');
      WriteLn('Pressione ENTER para sair...');
      ReadLn;
    end;
  end;

  if Assigned(App) then
    FreeAndNil(App);
end.
