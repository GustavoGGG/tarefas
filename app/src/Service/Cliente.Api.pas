unit Cliente.Api;

interface

uses
  System.SysUtils, System.JSON, REST.Types, Cliente.Config, Cliente.Modelos;

type
  ETarefasApiErro = class(Exception)
  private
    FCodigo: string;
    FStatusHttp: Integer;
  public
    constructor Create(const aMensagem, aCodigo: string; aStatusHttp: Integer);
    property Codigo: string read FCodigo;
    property StatusHttp: Integer read FStatusHttp;
  end;

  ITarefasApi = interface
    ['{4A9D3F10-6B2E-4C57-8E31-0D5B7A2C9E48}']
    function Listar(aLimite, aDeslocamento: Integer): TPaginaTarefas;
    function Criar(const aTitulo, aDescricao: string; aPrioridade: Integer;
      const aResponsavel: string; aPrevisaoFinalizacao: TDateTime): TTarefa;
    function AtualizarStatus(aId: Integer; const aStatus: string): TTarefa;
    procedure Remover(aId: Integer);
    function ObterEstatisticas: TEstatisticas;
    function UrlBase: string;
  end;

  TTarefasApi = class(TInterfacedObject, ITarefasApi)
  private
    FConfig: TClienteConfig;
    function Enviar(aMetodo: TRESTRequestMethod; const aRecurso, aCorpo: string;
      const aParametros: array of string): TJSONObject;
    function LerTarefa(aObj: TJSONObject): TTarefa;
  public
    constructor Create(const aConfig: TClienteConfig);
    function Listar(aLimite, aDeslocamento: Integer): TPaginaTarefas;
    function Criar(const aTitulo, aDescricao: string; aPrioridade: Integer;
      const aResponsavel: string; aPrevisaoFinalizacao: TDateTime): TTarefa;
    function AtualizarStatus(aId: Integer; const aStatus: string): TTarefa;
    procedure Remover(aId: Integer);
    function ObterEstatisticas: TEstatisticas;
    function UrlBase: string;
  end;

implementation

uses
  REST.Client;

const
  TIMEOUT_MS = 10000;
  RECURSO_TAREFAS = 'api/tarefas';

{ ETarefasApiErro }

constructor ETarefasApiErro.Create(const aMensagem, aCodigo: string; aStatusHttp: Integer);
begin
  inherited Create(aMensagem);
  FCodigo := aCodigo;
  FStatusHttp := aStatusHttp;
end;

{ TTarefasApi }

constructor TTarefasApi.Create(const aConfig: TClienteConfig);
begin
  inherited Create;
  FConfig := aConfig;
end;

function TTarefasApi.UrlBase: string;
begin
  Result := FConfig.UrlBase;
end;

function TTarefasApi.Enviar(aMetodo: TRESTRequestMethod; const aRecurso, aCorpo: string;
  const aParametros: array of string): TJSONObject;
var
  LCliente: TRESTClient;
  LRequisicao: TRESTRequest;
  LResposta: TRESTResponse;
  LJson: TJSONValue;
  LMensagem, LCodigo: string;
  LI: Integer;
begin
  Result := nil;
  LCliente := TRESTClient.Create(FConfig.UrlBase);
  LRequisicao := TRESTRequest.Create(nil);
  LResposta := TRESTResponse.Create(nil);
  try
    LCliente.Accept := 'application/json';
    LCliente.ConnectTimeout := TIMEOUT_MS;
    LCliente.ReadTimeout := TIMEOUT_MS;
    { HTTP 5xx não vira exceção: o corpo JSON de erro da API é tratado abaixo }
    LCliente.RaiseExceptionOn500 := False;
    LRequisicao.Client := LCliente;
    LRequisicao.Response := LResposta;
    LRequisicao.Resource := aRecurso;
    LRequisicao.Params.AddItem('X-API-Key', FConfig.ApiKey, pkHTTPHEADER, [poDoNotEncode]);

    LI := 0;
    while LI < Length(aParametros) - 1 do
    begin
      LRequisicao.Params.AddItem(aParametros[LI], aParametros[LI + 1], pkGETorPOST);
      Inc(LI, 2);
    end;

    LRequisicao.Method := aMetodo;

    if aCorpo <> '' then
      LRequisicao.AddBody(aCorpo, ctAPPLICATION_JSON);

    try
      LRequisicao.Execute;
    except
      on E: Exception do
        raise ETarefasApiErro.Create(
          'API indisponível em ' + FConfig.UrlBase + '. Verifique se ela está em execução.',
          'API_INDISPONIVEL', 0);
    end;

    if LResposta.StatusCode = 204 then
      Exit;

    LJson := TJSONObject.ParseJSONValue(LResposta.Content);
    if (LJson <> nil) and not (LJson is TJSONObject) then
      FreeAndNil(LJson);

    if (LResposta.StatusCode < 200) or (LResposta.StatusCode >= 300) then
    begin
      LMensagem := 'Erro HTTP ' + IntToStr(LResposta.StatusCode);
      LCodigo := 'ERRO_HTTP';
      if LJson <> nil then
      try
        TJSONObject(LJson).TryGetValue<string>('error', LMensagem);
        TJSONObject(LJson).TryGetValue<string>('code', LCodigo);
      finally
        LJson.Free;
      end;
      raise ETarefasApiErro.Create(LMensagem, LCodigo, LResposta.StatusCode);
    end;

    if LJson = nil then
      raise ETarefasApiErro.Create('Resposta inválida da API.', 'RESPOSTA_INVALIDA',
        LResposta.StatusCode);
    Result := TJSONObject(LJson);
  finally
    LResposta.Free;
    LRequisicao.Free;
    LCliente.Free;
  end;
end;

function TTarefasApi.LerTarefa(aObj: TJSONObject): TTarefa;
var
  LTexto: string;
begin
  Result := Default(TTarefa);
  aObj.TryGetValue<Integer>('id', Result.Id);
  aObj.TryGetValue<string>('titulo', Result.Titulo);
  aObj.TryGetValue<string>('descricao', Result.Descricao);
  aObj.TryGetValue<Integer>('prioridade', Result.Prioridade);
  aObj.TryGetValue<string>('status', Result.Status);
  if aObj.TryGetValue<string>('dataCriacao', LTexto) then
    Result.DataCriacao := ParseDataApi(LTexto);
  if aObj.TryGetValue<string>('dataFinalizacao', LTexto) then
    Result.DataFinalizacao := ParseDataApi(LTexto);
  if aObj.TryGetValue<string>('dataPrevisaoFinalizacao', LTexto) then
    Result.DataPrevisaoFinalizacao := ParseDataApi(LTexto);
  aObj.TryGetValue<string>('responsavel', Result.Responsavel);
end;

function TTarefasApi.Listar(aLimite, aDeslocamento: Integer): TPaginaTarefas;
var
  LJson: TJSONObject;
  LItens: TJSONArray;
  LI: Integer;
begin
  Result := Default(TPaginaTarefas);
  LJson := Enviar(rmGET, RECURSO_TAREFAS, '',
    ['limit', IntToStr(aLimite), 'offset', IntToStr(aDeslocamento)]);
  try
    LJson.TryGetValue<Integer>('total', Result.Total);
    LJson.TryGetValue<Integer>('limit', Result.Limite);
    LJson.TryGetValue<Integer>('offset', Result.Deslocamento);
    if LJson.TryGetValue<TJSONArray>('items', LItens) then
    begin
      SetLength(Result.Itens, LItens.Count);
      for LI := 0 to LItens.Count - 1 do
        Result.Itens[LI] := LerTarefa(LItens.Items[LI] as TJSONObject);
    end;
  finally
    LJson.Free;
  end;
end;

function TTarefasApi.Criar(const aTitulo, aDescricao: string; aPrioridade: Integer;
  const aResponsavel: string; aPrevisaoFinalizacao: TDateTime): TTarefa;
var
  LCorpo, LJson: TJSONObject;
  LDados: TJSONObject;
begin
  LCorpo := TJSONObject.Create;
  try
    LCorpo.AddPair('titulo', aTitulo);
    LCorpo.AddPair('descricao', aDescricao);
    LCorpo.AddPair('prioridade', TJSONNumber.Create(aPrioridade));
    LCorpo.AddPair('responsavel', aResponsavel);
    if aPrevisaoFinalizacao > 0 then
      LCorpo.AddPair('dataPrevisaoFinalizacao',
        FormatDateTime('yyyy-mm-dd hh:nn:ss', aPrevisaoFinalizacao));
    LJson := Enviar(rmPOST, RECURSO_TAREFAS, LCorpo.ToJSON, []);
  finally
    LCorpo.Free;
  end;
  try
    LDados := LJson.GetValue('data') as TJSONObject;
    Result := LerTarefa(LDados);
  finally
    LJson.Free;
  end;
end;

function TTarefasApi.AtualizarStatus(aId: Integer; const aStatus: string): TTarefa;
var
  LCorpo, LJson: TJSONObject;
begin
  LCorpo := TJSONObject.Create;
  try
    LCorpo.AddPair('status', aStatus);
    LJson := Enviar(rmPUT, RECURSO_TAREFAS + '/' + IntToStr(aId), LCorpo.ToJSON, []);
  finally
    LCorpo.Free;
  end;
  try
    Result := LerTarefa(LJson.GetValue('data') as TJSONObject);
  finally
    LJson.Free;
  end;
end;

procedure TTarefasApi.Remover(aId: Integer);
var
  LJson: TJSONObject;
begin
  LJson := Enviar(rmDELETE, RECURSO_TAREFAS + '/' + IntToStr(aId), '', []);
  LJson.Free; { nil em caso de 204 }
end;

function TTarefasApi.ObterEstatisticas: TEstatisticas;
var
  LJson, LDados: TJSONObject;
begin
  Result := Default(TEstatisticas);
  LJson := Enviar(rmGET, RECURSO_TAREFAS + '/stats/resumo', '', []);
  try
    LDados := LJson.GetValue('data') as TJSONObject;
    LDados.TryGetValue<Integer>('total', Result.Total);
    LDados.TryGetValue<Double>('mediaPrioridade', Result.MediaPrioridade);
    LDados.TryGetValue<Integer>('concluidasUltimos7Dias', Result.ConcluidasUltimos7Dias);
  finally
    LJson.Free;
  end;
end;

end.
