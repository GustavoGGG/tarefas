unit Shared.Result;

interface

uses
  System.SysUtils;

type

  { Versão não-genérica para operações sem retorno }
  TResult = record
  private
    FEhSucesso: Boolean;
    FMensagemErro: string;
    FCodigoErro: string;
  public
    property EhSucesso: Boolean read FEhSucesso;
    property MensagemErro: string read FMensagemErro;
    property CodigoErro: string read FCodigoErro;

    class function Sucesso: TResult; static;
    class function Erro(const aMensagemErro: string; const aCodigoErro: string = 'ERRO_GENERICO'): TResult; static;
  end;

  { Result<T> como record: tipo de valor, sem necessidade de Free.
    Não conhece HTTP: o mapeamento CodigoErro -> status fica na camada API. }
  TResult<T> = record
  private
    FEhSucesso: Boolean;
    FValor: T;
    FMensagemErro: string;
    FCodigoErro: string;
  public
    constructor CriarSucesso(const aValor: T);
    constructor CriarErro(const aMensagemErro: string; const aCodigoErro: string = 'ERRO_GENERICO');

    property EhSucesso: Boolean read FEhSucesso;
    property Valor: T read FValor;
    property MensagemErro: string read FMensagemErro;
    property CodigoErro: string read FCodigoErro;

    function ObterValorOuPadrao(const aDefault: T): T;
  end;

implementation

{ TResult }

class function TResult.Sucesso: TResult;
begin
  Result.FEhSucesso := True;
  Result.FMensagemErro := '';
  Result.FCodigoErro := '';
end;

class function TResult.Erro(const aMensagemErro: string; const aCodigoErro: string): TResult;
begin
  Result.FEhSucesso := False;
  Result.FMensagemErro := aMensagemErro;
  Result.FCodigoErro := aCodigoErro;
end;


{ TResult<T> }

constructor TResult<T>.CriarSucesso(const aValor: T);
begin
  FEhSucesso := True;
  FValor := aValor;
  FMensagemErro := '';
  FCodigoErro := '';
end;

constructor TResult<T>.CriarErro(const aMensagemErro: string; const aCodigoErro: string);
begin
  FEhSucesso := False;
  FValor := Default(T);
  FMensagemErro := aMensagemErro;
  FCodigoErro := aCodigoErro;
end;

function TResult<T>.ObterValorOuPadrao(const aDefault: T): T;
begin
  if FEhSucesso then
    Result := FValor
  else
    Result := aDefault;
end;

end.
