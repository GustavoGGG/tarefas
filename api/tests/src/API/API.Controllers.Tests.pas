unit API.Controllers.Tests;

{ Testa os endpoints do TControladorTarefas via HTTP: exige a API rodando (padrão
  http://localhost:9000, ou a variável de ambiente TAREFAS_API_URL). Sem servidor,
  cada teste termina com Pass e a mensagem "PULADO", pois este DUnitX não tem
  Assert.Ignore. }

interface

uses
  System.JSON, System.Net.HttpClient, DUnitX.TestFramework;

type
  [TestFixture]
  TControladorTarefasTests = class
  private
    FClient: THTTPClient;
    FBaseUrl: string;
    FApiKey: string;
    FDisponivel: Boolean;

    function Chamar(const aMetodo, aCaminho: string; const aCorpo: string = '';
      aComChave: Boolean = True; const aChave: string = ''): IHTTPResponse;
    function LerJson(const aResposta: IHTTPResponse): TJSONObject;
    function CriarTarefaNaApi(const aTitulo: string): Integer;
    procedure RemoverTarefaNaApi(aId: Integer);
    procedure ExigirServidor;
  public
    [SetupFixture] procedure SetupFixture;
    [TearDownFixture] procedure TearDownFixture;

    [Test] procedure SemApiKey_Retorna401;
    [Test] procedure ApiKeyInvalida_Retorna401;
    [Test] procedure ListarTarefas_Retorna200EJson;
    [Test] procedure CriarTarefa_Retorna201ComId;
    [Test] procedure CriarTarefa_SemTitulo_Retorna400;
    [Test] procedure CriarTarefa_SemResponsavel_Retorna400;
    [Test] procedure CriarTarefa_DataPrevisaoInvalida_Retorna400;
    [Test] procedure CriarTarefa_JsonInvalido_Retorna400;
    [Test] procedure CriarTarefa_CorpoNaoUtf8_Retorna400;
    [Test] procedure ObterTarefaPorId_RetornaDados;
    [Test] procedure ObterTarefaPorId_IdInvalido_Retorna400;
    [Test] procedure ObterTarefaPorId_Inexistente_Retorna404;
    [Test] procedure AtualizarStatusTarefa_Concluida_Retorna200;
    [Test] procedure AtualizarStatusTarefa_Invalido_Retorna400;
    [Test] procedure ObterStats_Retorna200ComCampos;
    [Test] procedure ListarTarefas_LimitAcimaDeCem_UsaCem;
    [Test] procedure RemoverTarefa_Retorna204EDepois404;
  end;

implementation

uses
  System.Classes, System.IOUtils, System.Net.URLClient,  System.SysUtils;

function LocalizarConfig: string;
var
  LDir: string;
begin
  LDir := TPath.GetDirectoryName(ParamStr(0));
  while LDir <> '' do
  begin
    Result := TPath.Combine(LDir, 'config.json');
    if FileExists(Result) then
      Exit;
    LDir := TPath.GetDirectoryName(LDir);
  end;
  Result := '';
end;

function LerChaveDoConfig: string;
var
  LCaminho: string;
  LValor: TJSONValue;
begin
  Result := '';
  LCaminho := LocalizarConfig;
  if LCaminho = '' then
    Exit;

  LValor := TJSONObject.ParseJSONValue(TFile.ReadAllText(LCaminho, TEncoding.UTF8));
  try
    if LValor is TJSONObject then
      TJSONObject(LValor).TryGetValue<string>('api.apiKey', Result);
  finally
    LValor.Free;
  end;
end;

{ TControladorTarefasTests }

procedure TControladorTarefasTests.SetupFixture;
var
  LResposta: IHTTPResponse;
begin
  FBaseUrl := GetEnvironmentVariable('TAREFAS_API_URL');
  if FBaseUrl = '' then
    FBaseUrl := 'http://localhost:9000';
  FApiKey := LerChaveDoConfig;

  FClient := THTTPClient.Create;
  FClient.ConnectionTimeout := 3000;
  FClient.ResponseTimeout := 10000;

  try
    LResposta := Chamar('GET', '/api/tarefas');
    FDisponivel := LResposta.StatusCode = 200;
  except
    FDisponivel := False;
  end;
end;

procedure TControladorTarefasTests.TearDownFixture;
begin
  FClient.Free;
end;

procedure TControladorTarefasTests.ExigirServidor;
begin
  if not FDisponivel then
    Assert.Pass('PULADO: API indisponível em ' + FBaseUrl + ' (suba o servidor para rodar este teste)');
end;

function TControladorTarefasTests.Chamar(const aMetodo, aCaminho: string; const aCorpo: string;
  aComChave: Boolean; const aChave: string): IHTTPResponse;
var
  LHeaders: TNetHeaders;
  LCorpo: TStringStream;
  LUrl, LChave: string;
begin
  LUrl := FBaseUrl + aCaminho;

  LHeaders := [TNameValuePair.Create('Content-Type', 'application/json')];
  if aComChave then
  begin
    LChave := aChave;
    if LChave = '' then
      LChave := FApiKey;
    LHeaders := LHeaders + [TNameValuePair.Create('X-API-Key', LChave)];
  end;

  if aMetodo = 'GET' then
    Exit(FClient.Get(LUrl, nil, LHeaders));
  if aMetodo = 'DELETE' then
    Exit(FClient.Delete(LUrl, nil, LHeaders));

  LCorpo := TStringStream.Create(aCorpo, TEncoding.UTF8);
  try
    if aMetodo = 'POST' then
      Result := FClient.Post(LUrl, LCorpo, nil, LHeaders)
    else
      Result := FClient.Put(LUrl, LCorpo, nil, LHeaders);
  finally
    LCorpo.Free;
  end;
end;

function TControladorTarefasTests.LerJson(const aResposta: IHTTPResponse): TJSONObject;
var
  LValor: TJSONValue;
begin
  LValor := TJSONObject.ParseJSONValue(aResposta.ContentAsString(TEncoding.UTF8));
  if not (LValor is TJSONObject) then
  begin
    LValor.Free;
    Assert.Fail('Resposta não é um objeto JSON: ' + aResposta.ContentAsString(TEncoding.UTF8));
  end;
  Result := TJSONObject(LValor);
end;

function TControladorTarefasTests.CriarTarefaNaApi(const aTitulo: string): Integer;
var
  LResposta: IHTTPResponse;
  LJson: TJSONObject;
begin
  LResposta := Chamar('POST', '/api/tarefas', '{"titulo":"' + aTitulo + '","prioridade":2,"responsavel":"Ana"}');
  Assert.AreEqual(201, LResposta.StatusCode, 'criação da tarefa de apoio');
  LJson := LerJson(LResposta);
  try
    Result := LJson.GetValue<Integer>('data.id');
  finally
    LJson.Free;
  end;
end;

procedure TControladorTarefasTests.RemoverTarefaNaApi(aId: Integer);
begin
  Chamar('DELETE', '/api/tarefas/' + IntToStr(aId));
end;

procedure TControladorTarefasTests.SemApiKey_Retorna401;
begin
  ExigirServidor;
  Assert.AreEqual(401, Chamar('GET', '/api/tarefas', '', False).StatusCode);
end;

procedure TControladorTarefasTests.ApiKeyInvalida_Retorna401;
begin
  ExigirServidor;
  Assert.AreEqual(401, Chamar('GET', '/api/tarefas', '', True, 'chave-errada').StatusCode);
end;

procedure TControladorTarefasTests.ListarTarefas_Retorna200EJson;
var
  LResposta: IHTTPResponse;
begin
  ExigirServidor;
  LResposta := Chamar('GET', '/api/tarefas');
  Assert.AreEqual(200, LResposta.StatusCode);
  Assert.IsTrue(LResposta.MimeType.StartsWith('application/json'), 'Content-Type: ' + LResposta.MimeType);
end;

procedure TControladorTarefasTests.CriarTarefa_Retorna201ComId;
var
  LResposta: IHTTPResponse;
  LJson: TJSONObject;
  LId: Integer;
begin
  ExigirServidor;
  LResposta := Chamar('POST', '/api/tarefas', '{"titulo":"Teste criar","descricao":"d","prioridade":3,' +
    '"responsavel":"Ana","dataPrevisaoFinalizacao":"2030-01-15"}');
  Assert.AreEqual(201, LResposta.StatusCode);
  LJson := LerJson(LResposta);
  try
    LId := LJson.GetValue<Integer>('data.id');
    Assert.IsTrue(LId > 0, 'id deve ser > 0');
    Assert.AreEqual('Pendente', LJson.GetValue<string>('data.status'));
    Assert.AreEqual('Ana', LJson.GetValue<string>('data.responsavel'));
    Assert.AreEqual('2030-01-15 00:00:00', LJson.GetValue<string>('data.dataPrevisaoFinalizacao'));
  finally
    LJson.Free;
  end;
  RemoverTarefaNaApi(LId);
end;

procedure TControladorTarefasTests.CriarTarefa_SemTitulo_Retorna400;
begin
  ExigirServidor;
  Assert.AreEqual(400, Chamar('POST', '/api/tarefas', '{"descricao":"sem titulo"}').StatusCode);
end;

procedure TControladorTarefasTests.CriarTarefa_SemResponsavel_Retorna400;
begin
  ExigirServidor;
  Assert.AreEqual(400, Chamar('POST', '/api/tarefas', '{"titulo":"Sem responsável"}').StatusCode);
end;

procedure TControladorTarefasTests.CriarTarefa_DataPrevisaoInvalida_Retorna400;
begin
  ExigirServidor;
  Assert.AreEqual(400, Chamar('POST', '/api/tarefas',
    '{"titulo":"Data ruim","responsavel":"Ana","dataPrevisaoFinalizacao":"amanhã"}').StatusCode);
end;

procedure TControladorTarefasTests.CriarTarefa_JsonInvalido_Retorna400;
begin
  ExigirServidor;
  Assert.AreEqual(400, Chamar('POST', '/api/tarefas', 'isso não é json').StatusCode);
end;

procedure TControladorTarefasTests.CriarTarefa_CorpoNaoUtf8_Retorna400;
var
  LCorpo: TBytesStream;
  LBytes: TBytes;
  LResposta: IHTTPResponse;
  LJson: TJSONObject;
begin
  ExigirServidor;
  { "Conclu" + 0xED + "da": o í em Latin-1 é um byte solto, UTF-8 inválido }
  LBytes := TEncoding.UTF8.GetBytes('{"titulo":"Conclu') + [$ED] +
    TEncoding.UTF8.GetBytes('da","prioridade":1}');
  LCorpo := TBytesStream.Create(LBytes);
  try
    LResposta := FClient.Post(FBaseUrl + '/api/tarefas', LCorpo, nil,
      [TNameValuePair.Create('Content-Type', 'application/json'),
       TNameValuePair.Create('X-API-Key', FApiKey)]);
  finally
    LCorpo.Free;
  end;

  Assert.AreEqual(400, LResposta.StatusCode);
  LJson := LerJson(LResposta);
  try
    Assert.AreEqual('JSON_INVALIDO', LJson.GetValue<string>('code'));
  finally
    LJson.Free;
  end;
end;

procedure TControladorTarefasTests.ObterTarefaPorId_RetornaDados;
var
  LId: Integer;
  LResposta: IHTTPResponse;
  LJson: TJSONObject;
begin
  ExigirServidor;
  LId := CriarTarefaNaApi('Teste obter');
  try
    LResposta := Chamar('GET', '/api/tarefas/' + IntToStr(LId));
    Assert.AreEqual(200, LResposta.StatusCode);
    LJson := LerJson(LResposta);
    try
      Assert.AreEqual('Teste obter', LJson.GetValue<string>('data.titulo'));
    finally
      LJson.Free;
    end;
  finally
    RemoverTarefaNaApi(LId);
  end;
end;

procedure TControladorTarefasTests.ObterTarefaPorId_IdInvalido_Retorna400;
begin
  ExigirServidor;
  Assert.AreEqual(400, Chamar('GET', '/api/tarefas/abc').StatusCode);
end;

procedure TControladorTarefasTests.ObterTarefaPorId_Inexistente_Retorna404;
begin
  ExigirServidor;
  Assert.AreEqual(404, Chamar('GET', '/api/tarefas/999999999').StatusCode);
end;

procedure TControladorTarefasTests.AtualizarStatusTarefa_Concluida_Retorna200;
var
  LId: Integer;
  LResposta: IHTTPResponse;
  LJson: TJSONObject;
begin
  ExigirServidor;
  LId := CriarTarefaNaApi('Teste atualizar');
  try
    LResposta := Chamar('PUT', '/api/tarefas/' + IntToStr(LId), '{"status":"Concluída"}');
    Assert.AreEqual(200, LResposta.StatusCode);
    LJson := LerJson(LResposta);
    try
      Assert.AreEqual('Concluída', LJson.GetValue<string>('data.status'));
      Assert.IsTrue(LJson.GetValue<string>('data.dataFinalizacao') <> '', 'dataFinalizacao preenchida');
    finally
      LJson.Free;
    end;
  finally
    RemoverTarefaNaApi(LId);
  end;
end;

procedure TControladorTarefasTests.AtualizarStatusTarefa_Invalido_Retorna400;
var
  LId: Integer;
begin
  ExigirServidor;
  LId := CriarTarefaNaApi('Teste status invalido');
  try
    Assert.AreEqual(400, Chamar('PUT', '/api/tarefas/' + IntToStr(LId), '{"status":"Inexistente"}').StatusCode);
  finally
    RemoverTarefaNaApi(LId);
  end;
end;

procedure TControladorTarefasTests.ObterStats_Retorna200ComCampos;
var
  LResposta: IHTTPResponse;
  LJson: TJSONObject;
begin
  ExigirServidor;
  LResposta := Chamar('GET', '/api/tarefas/stats/resumo');
  Assert.AreEqual(200, LResposta.StatusCode);
  LJson := LerJson(LResposta);
  try
    Assert.IsTrue(LJson.GetValue<Integer>('data.total') >= 0);
    Assert.IsNotNull(LJson.FindValue('data.mediaPrioridade'), 'mediaPrioridade');
    Assert.IsNotNull(LJson.FindValue('data.concluidasUltimos7Dias'), 'concluidasUltimos7Dias');
  finally
    LJson.Free;
  end;
end;

procedure TControladorTarefasTests.ListarTarefas_LimitAcimaDeCem_UsaCem;
var
  LResposta: IHTTPResponse;
  LJson: TJSONObject;
begin
  ExigirServidor;
  LResposta := Chamar('GET', '/api/tarefas?limit=500&offset=0');
  Assert.AreEqual(200, LResposta.StatusCode);
  LJson := LerJson(LResposta);
  try
    Assert.AreEqual(100, LJson.GetValue<Integer>('limit'));
  finally
    LJson.Free;
  end;
end;

procedure TControladorTarefasTests.RemoverTarefa_Retorna204EDepois404;
var
  LId: Integer;
begin
  ExigirServidor;
  LId := CriarTarefaNaApi('Teste remover');
  Assert.AreEqual(204, Chamar('DELETE', '/api/tarefas/' + IntToStr(LId)).StatusCode);
  Assert.AreEqual(404, Chamar('GET', '/api/tarefas/' + IntToStr(LId)).StatusCode);
end;

initialization
  TDUnitX.RegisterTestFixture(TControladorTarefasTests);

end.
