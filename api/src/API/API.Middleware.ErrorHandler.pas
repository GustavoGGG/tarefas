unit API.Middleware.ErrorHandler;

interface

uses
  Horse, API.Response;

type
  { Middleware para centralizar tratamento de erros }
  TMiddlewareErrorHandler = class sealed
  public
    class procedure ExecutarMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

uses
  System.SysUtils, Shared.Exceptions;

{ TMiddlewareErrorHandler }

class procedure TMiddlewareErrorHandler.ExecutarMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  try
    if Assigned(Next) then
      Next;
  except
    on E: ETarefaNaoEncontrada do
      TFormatadorRespostas.EnviarErro(Res, 404, E.Message, E.CodigoErro);

    on E: EValidacaoTarefa do
      TFormatadorRespostas.EnviarErro(Res, 400, E.Message, E.CodigoErro);

    on E: EAPIKeyInvalida do
      TFormatadorRespostas.EnviarErro(Res, 401, E.Message, E.CodigoErro);

    on E: EConexaoBancoDados do
      TFormatadorRespostas.EnviarErro(Res, 500, E.Message, E.CodigoErro);

    on E: EAplicacao do
      TFormatadorRespostas.EnviarErro(Res, 500, E.Message, E.CodigoErro);

    on E: Exception do
    begin
      WriteLn('[ERRO] Exceção não tratada: ' + E.Message);
      TFormatadorRespostas.EnviarErro(Res, 500, 'Erro interno do servidor', 'ERRO_INTERNO');
    end;
  end;
end;

end.
