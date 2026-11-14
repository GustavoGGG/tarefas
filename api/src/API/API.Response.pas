unit API.Response;

interface

uses
  System.JSON, Horse;

type
  { Formatador de respostas JSON estruturadas.
    Os métodos Enviar* assumem a posse dos objetos JSON recebidos. }
  TFormatadorRespostas = class 
  private
    class procedure Enviar(aResponse: THorseResponse; aStatusCode: Integer; aBody: TJSONObject);
  public
    class procedure EnviarSucesso(aResponse: THorseResponse; aStatusCode: Integer; aData: TJSONValue);
    class procedure EnviarListaSucesso(aResponse: THorseResponse; aItems: TJSONArray; aTotal, aLimit, aOffset: Integer);
    class procedure EnviarErro(aResponse: THorseResponse; aStatusCode: Integer; const aMessage, aCode: string); overload;
    { Deriva o status HTTP do código de erro (ver StatusDoCodigo) }
    class procedure EnviarErro(aResponse: THorseResponse; const aMessage, aCode: string); overload;
    class function StatusDoCodigo(const aCode: string): Integer;
  end;

implementation

uses
  System.SysUtils;

const
  CODIGOS_VALIDACAO: array[0..12] of string = (
    'ERRO_VALIDACAO', 'REQUISICAO_INVALIDA', 'TITULO_OBRIGATORIO', 'TITULO_MUITO_LONGO',
    'DESCRICAO_MUITO_LONGA', 'PRIORIDADE_INVALIDA', 'STATUS_OBRIGATORIO', 'STATUS_INVALIDO',
    'ID_INVALIDO', 'JSON_INVALIDO', 'RESPONSAVEL_OBRIGATORIO', 'RESPONSAVEL_MUITO_LONGO',
    'DATA_PREVISAO_INVALIDA');

{ TFormatadorRespostas }

class procedure TFormatadorRespostas.Enviar(aResponse: THorseResponse; aStatusCode: Integer; aBody: TJSONObject);
begin
  try
    aResponse.ContentType('application/json; charset=UTF-8').Status(aStatusCode).Send(aBody.ToJSON);
  finally
    aBody.Free;
  end;
end;

class procedure TFormatadorRespostas.EnviarSucesso(aResponse: THorseResponse; aStatusCode: Integer; aData: TJSONValue);
var
  LBody: TJSONObject;
begin
  LBody := TJSONObject.Create;
  LBody.AddPair('data', aData);
  LBody.AddPair('success', TJSONTrue.Create);
  LBody.AddPair('statusCode', TJSONNumber.Create(aStatusCode));
  Enviar(aResponse, aStatusCode, LBody);
end;

class procedure TFormatadorRespostas.EnviarListaSucesso(aResponse: THorseResponse; aItems: TJSONArray;
  aTotal, aLimit, aOffset: Integer);
var
  LBody: TJSONObject;
begin
  LBody := TJSONObject.Create;
  LBody.AddPair('items', aItems);
  LBody.AddPair('success', TJSONTrue.Create);
  LBody.AddPair('statusCode', TJSONNumber.Create(200));
  LBody.AddPair('total', TJSONNumber.Create(aTotal));
  LBody.AddPair('limit', TJSONNumber.Create(aLimit));
  LBody.AddPair('offset', TJSONNumber.Create(aOffset));
  Enviar(aResponse, 200, LBody);
end;

class procedure TFormatadorRespostas.EnviarErro(aResponse: THorseResponse; aStatusCode: Integer;
  const aMessage, aCode: string);
var
  LBody: TJSONObject;
begin
  LBody := TJSONObject.Create;
  LBody.AddPair('success', TJSONFalse.Create);
  LBody.AddPair('statusCode', TJSONNumber.Create(aStatusCode));
  LBody.AddPair('error', aMessage);
  LBody.AddPair('code', aCode);
  Enviar(aResponse, aStatusCode, LBody);
end;

class procedure TFormatadorRespostas.EnviarErro(aResponse: THorseResponse; const aMessage, aCode: string);
begin
  EnviarErro(aResponse, StatusDoCodigo(aCode), aMessage, aCode);
end;

class function TFormatadorRespostas.StatusDoCodigo(const aCode: string): Integer;
var
  LCodigo: string;
begin
  if SameText(aCode, 'TAREFA_NAO_ENCONTRADA') then
    Exit(404);
  if SameText(aCode, 'API_KEY_AUSENTE') or SameText(aCode, 'API_KEY_INVALIDA') then
    Exit(401);
  for LCodigo in CODIGOS_VALIDACAO do
    if SameText(aCode, LCodigo) then
      Exit(400);
  Result := 500;
end;

end.
