unit API.Controllers;

interface

uses
  Horse, System.JSON, Application.Services, Application.DTOs, API.Response;

type
  TControladorTarefas = class sealed
  private
    FServico: IServicoTarefas;

    function LerBody(Req: THorseRequest): TJSONObject;
    function FormatarDataHora(const aData: TDateTime): string;
    function TarefaParaJSON(const aDTO: TTarefaDTO): TJSONObject;
    function ExtrairInt(aJSON: TJSONObject; const aKey: string; aValorPadrao: Integer): Integer;
    function ExtrairString(aJSON: TJSONObject; const aKey: string): string;
    function ExtrairDataHora(aJSON: TJSONObject; const aKey: string): TDateTime;
    function ObterIdDaRota(Req: THorseRequest; Res: THorseResponse; out aId: Integer): Boolean;
  public
    constructor Create(aServico: IServicoTarefas);

    procedure ListarTarefas(Req: THorseRequest; Res: THorseResponse);
    procedure ObterTarefaPorId(Req: THorseRequest; Res: THorseResponse);
    procedure CriarTarefa(Req: THorseRequest; Res: THorseResponse);
    procedure AtualizarStatusTarefa(Req: THorseRequest; Res: THorseResponse);
    procedure RemoverTarefa(Req: THorseRequest; Res: THorseResponse);
    procedure ObterStats(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

uses
  System.SysUtils, Shared.Result;

{ TControladorTarefas }

constructor TControladorTarefas.Create(aServico: IServicoTarefas);
begin
  inherited Create;
  FServico := aServico;
end;

function TControladorTarefas.LerBody(Req: THorseRequest): TJSONObject;
var
  LValor: TJSONValue;
begin
  Result := nil;
  try
    LValor := TJSONObject.ParseJSONValue(Req.Body);
  except
    { JSON inválido }
    on E: Exception do
      Exit;
  end;

  if LValor is TJSONObject then
    Result := TJSONObject(LValor)
  else
    LValor.Free;
end;

function TControladorTarefas.FormatarDataHora(const aData: TDateTime): string;
begin
  { 0 = sem data (ex.: tarefa ainda não finalizada) }
  if aData > 0 then
    Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', aData)
  else
    Result := '';
end;

function TControladorTarefas.TarefaParaJSON(const aDTO: TTarefaDTO): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('id', TJSONNumber.Create(aDTO.Id));
    Result.AddPair('titulo', aDTO.Titulo);
    Result.AddPair('descricao', aDTO.Descricao);
    Result.AddPair('prioridade', TJSONNumber.Create(aDTO.Prioridade));
    Result.AddPair('status', aDTO.Status);
    Result.AddPair('dataCriacao', FormatarDataHora(aDTO.DataCriacao));
    Result.AddPair('dataFinalizacao', FormatarDataHora(aDTO.DataFinalizacao));
    Result.AddPair('dataPrevisaoFinalizacao', FormatarDataHora(aDTO.DataPrevisaoFinalizacao));
    Result.AddPair('responsavel', aDTO.Responsavel);
  except
    Result.Free;
    raise;
  end;
end;

function TControladorTarefas.ExtrairInt(aJSON: TJSONObject; const aKey: string; aValorPadrao: Integer): Integer;
var
  LValor: TJSONValue;
  LNumero: Double;
begin
  Result := aValorPadrao;
  if not Assigned(aJSON) then
    Exit;
  LValor := aJSON.GetValue(aKey);
  if not Assigned(LValor) then
    Exit;

  if LValor is TJSONNumber then
  begin
    LNumero := TJSONNumber(LValor).AsDouble;
    if (Frac(LNumero) = 0) and (Abs(LNumero) < MaxInt) then
      Exit(Trunc(LNumero));
  end;
  Result := Low(Integer);
end;

function TControladorTarefas.ExtrairString(aJSON: TJSONObject; const aKey: string): string;
begin
  if not (Assigned(aJSON) and aJSON.TryGetValue<string>(aKey, Result)) then
    Result := '';
end;

function TControladorTarefas.ExtrairDataHora(aJSON: TJSONObject; const aKey: string): TDateTime;
var
  LValor: TJSONValue;
  LTexto: string;
  LFormato: TFormatSettings;
begin
  { Chave ausente, null ou texto vazio = sem data (0). Texto que não é data
    'yyyy-mm-dd' ou 'yyyy-mm-dd hh:nn:ss' = -1, que o validador rejeita com 400. }
  Result := 0;
  if not Assigned(aJSON) then
    Exit;
  LValor := aJSON.GetValue(aKey);
  if (not Assigned(LValor)) or (LValor is TJSONNull) then
    Exit;

  if not (LValor is TJSONString) then
    Exit(-1);

  LTexto := LValor.Value.Trim.Replace('T', ' ');
  if LTexto.IsEmpty then
    Exit;

  LFormato := TFormatSettings.Create;
  LFormato.DateSeparator := '-';
  LFormato.TimeSeparator := ':';
  LFormato.ShortDateFormat := 'yyyy-mm-dd';
  LFormato.ShortTimeFormat := 'hh:nn:ss';
  if not TryStrToDateTime(LTexto, Result, LFormato) then
    Result := -1;
end;

function TControladorTarefas.ObterIdDaRota(Req: THorseRequest; Res: THorseResponse; out aId: Integer): Boolean;
begin
  aId := StrToIntDef(Req.Params['id'], -1);
  Result := aId > 0;
  if not Result then
    TFormatadorRespostas.EnviarErro(Res, 400, 'ID deve ser um número positivo', 'ID_INVALIDO');
end;

procedure TControladorTarefas.ListarTarefas(Req: THorseRequest; Res: THorseResponse);
var
  LLimit, LOffset: Integer;
  LResultado: TResult<TTarefasListaDTO>;
  LListaDTO: TTarefasListaDTO;
  LItems: TJSONArray;
  LTarefaDTO: TTarefaDTO;
begin
  { Padrão e teto de paginação são aplicados pelo serviço (-1 = não informado) }
  LLimit := StrToIntDef(Req.Query['limit'], -1);
  LOffset := StrToIntDef(Req.Query['offset'], 0);

  LResultado := FServico.Listar(LLimit, LOffset);

  if not LResultado.EhSucesso then
  begin
    TFormatadorRespostas.EnviarErro(Res, LResultado.MensagemErro, LResultado.CodigoErro);
    Exit;
  end;

  LListaDTO := LResultado.Valor;
  LItems := TJSONArray.Create;
  try
    for LTarefaDTO in LListaDTO.Items do
      LItems.AddElement(TarefaParaJSON(LTarefaDTO));
  except
    LItems.Free;
    raise;
  end;

  TFormatadorRespostas.EnviarListaSucesso(Res, LItems, LListaDTO.Total, LListaDTO.Limit, LListaDTO.Offset);
end;

procedure TControladorTarefas.ObterTarefaPorId(Req: THorseRequest; Res: THorseResponse);
var
  LId: Integer;
  LResultado: TResult<TTarefaDTO>;
begin
  if not ObterIdDaRota(Req, Res, LId) then
    Exit;

  LResultado := FServico.ObterPorId(LId);

  if not LResultado.EhSucesso then
  begin
    TFormatadorRespostas.EnviarErro(Res, LResultado.MensagemErro, LResultado.CodigoErro);
    Exit;
  end;

  TFormatadorRespostas.EnviarSucesso(Res, 200, TarefaParaJSON(LResultado.Valor));
end;

procedure TControladorTarefas.CriarTarefa(Req: THorseRequest; Res: THorseResponse);
var
  LBody: TJSONObject;
  LRequest: TCriarTarefaRequest;
  LResultado: TResult<TTarefaDTO>;
begin
  LBody := LerBody(Req);
  if not Assigned(LBody) then
  begin
    TFormatadorRespostas.EnviarErro(Res, 400, 'Corpo da requisição deve ser um JSON válido', 'JSON_INVALIDO');
    Exit;
  end;

  try
    LRequest.Titulo := ExtrairString(LBody, 'titulo');
    LRequest.Descricao := ExtrairString(LBody, 'descricao');
    LRequest.Prioridade := ExtrairInt(LBody, 'prioridade', 1);
    LRequest.Responsavel := ExtrairString(LBody, 'responsavel');
    LRequest.DataPrevisaoFinalizacao := ExtrairDataHora(LBody, 'dataPrevisaoFinalizacao');
    LResultado := FServico.Criar(LRequest);
  finally
    LBody.Free;
  end;

  if not LResultado.EhSucesso then
  begin
    TFormatadorRespostas.EnviarErro(Res, LResultado.MensagemErro, LResultado.CodigoErro);
    Exit;
  end;

  TFormatadorRespostas.EnviarSucesso(Res, 201, TarefaParaJSON(LResultado.Valor));
end;

procedure TControladorTarefas.AtualizarStatusTarefa(Req: THorseRequest; Res: THorseResponse);
var
  LId: Integer;
  LBody: TJSONObject;
  LRequest: TAtualizarTarefaRequest;
  LResultado: TResult<TTarefaDTO>;
begin
  if not ObterIdDaRota(Req, Res, LId) then
    Exit;

  LBody := LerBody(Req);
  if not Assigned(LBody) then
  begin
    TFormatadorRespostas.EnviarErro(Res, 400, 'Corpo da requisição deve ser um JSON válido', 'JSON_INVALIDO');
    Exit;
  end;

  try
    LRequest.Status := ExtrairString(LBody, 'status');
    LResultado := FServico.AtualizarStatus(LId, LRequest);
  finally
    LBody.Free;
  end;

  if not LResultado.EhSucesso then
  begin
    TFormatadorRespostas.EnviarErro(Res, LResultado.MensagemErro, LResultado.CodigoErro);
    Exit;
  end;

  TFormatadorRespostas.EnviarSucesso(Res, 200, TarefaParaJSON(LResultado.Valor));
end;

procedure TControladorTarefas.RemoverTarefa(Req: THorseRequest; Res: THorseResponse);
var
  LId: Integer;
  LResultado: TResult;
begin
  if not ObterIdDaRota(Req, Res, LId) then
    Exit;

  LResultado := FServico.Remover(LId);

  if LResultado.EhSucesso then
    Res.Status(204).Send('')
  else
    TFormatadorRespostas.EnviarErro(Res, LResultado.MensagemErro, LResultado.CodigoErro);
end;

procedure TControladorTarefas.ObterStats(Req: THorseRequest; Res: THorseResponse);
var
  LResultado: TResult<TStatisticaTarefasDTO>;
  LStats: TStatisticaTarefasDTO;
  LJSON: TJSONObject;
begin
  LResultado := FServico.ObterEstatisticas;

  if not LResultado.EhSucesso then
  begin
    TFormatadorRespostas.EnviarErro(Res, LResultado.MensagemErro, LResultado.CodigoErro);
    Exit;
  end;

  LStats := LResultado.Valor;
  LJSON := TJSONObject.Create;
  LJSON.AddPair('total', TJSONNumber.Create(LStats.Total));
  LJSON.AddPair('mediaPrioridade', TJSONNumber.Create(LStats.MediaPrioridade));
  LJSON.AddPair('concluidasUltimos7Dias', TJSONNumber.Create(LStats.ConcluidasÚltimo7Dias));
  TFormatadorRespostas.EnviarSucesso(Res, 200, LJSON);
end;

end.
