unit API.Middleware.Security;

interface

uses
  Horse, API.Security;

type
  TMiddlewareValidarAPIKey = class sealed
  public
    class function Criar(aValidador: ISecurityValidator): THorseCallback;
  end;

implementation

uses
  System.SysUtils, Shared.Exceptions, Shared.Result, API.Response, API.Swagger;

{ TMiddlewareValidarAPIKey }

class function TMiddlewareValidarAPIKey.Criar(aValidador: ISecurityValidator): THorseCallback;
begin
  if not Assigned(aValidador) then
    raise EConfiguracaoInvalida.Create('Security validator não pode ser nulo');

  Result :=
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      LValidacaoResult: TResult;
    begin
      { Documentação Swagger é pública }
      if not TSwagger.EhRotaPublica(Req.PathInfo) then
      begin
        LValidacaoResult := aValidador.ValidarAPIKey(Req.Headers['X-API-Key']);

        if not LValidacaoResult.EhSucesso then
        begin
          TFormatadorRespostas.EnviarErro(Res, LValidacaoResult.MensagemErro, LValidacaoResult.CodigoErro);
          Exit;
        end;
      end;

      { Liberado: segue para o próximo middleware/controller }
      if Assigned(Next) then
        Next;
    end;
end;

end.
