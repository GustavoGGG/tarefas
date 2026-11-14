unit Application.Services;

interface

uses
  System.Generics.Collections, Domain.Entities, Domain.Interfaces,
  Application.DTOs, Shared.Result;

type
  IServicoTarefas = interface(IInterface)
    ['{B5A4C3D2-E1F0-4B6C-9D8E-7F6A5B4C3D2E}']

    function Listar(aLimit, aOffset: Integer): TResult<TTarefasListaDTO>;
    function ObterPorId(aId: Integer): TResult<TTarefaDTO>;
    function Criar(const aRequest: TCriarTarefaRequest): TResult<TTarefaDTO>;
    function AtualizarStatus(aId: Integer; const aRequest: TAtualizarTarefaRequest): TResult<TTarefaDTO>;
    function Remover(aId: Integer): TResult;

    function ObterEstatisticas: TResult<TStatisticaTarefasDTO>;
  end;

  TServicoTarefas = class (TInterfacedObject, IServicoTarefas)
  private
    FRepositorio: IRepositorioTarefas;
    FLimitePadrao: Integer;
    FLimiteMaximo: Integer;

    function MapearTarefaParaDTO(const aTarefa: TTarefa): TTarefaDTO;
    procedure LiberarTarefas(var aTarefas: TList<TTarefa>);
  public
    constructor Create(aRepositorio: IRepositorioTarefas; aLimitePadrao: Integer = 10;
      aLimiteMaximo: Integer = 100);

    function Listar(aLimit, aOffset: Integer): TResult<TTarefasListaDTO>;
    function ObterPorId(aId: Integer): TResult<TTarefaDTO>;
    function Criar(const aRequest: TCriarTarefaRequest): TResult<TTarefaDTO>;
    function AtualizarStatus(aId: Integer; const aRequest: TAtualizarTarefaRequest): TResult<TTarefaDTO>;
    function Remover(aId: Integer): TResult;

    function ObterEstatisticas: TResult<TStatisticaTarefasDTO>;
  end;

implementation

uses
  System.SysUtils, Application.Validators, Domain.ValueObjects,
  Shared.Exceptions;

const
  MSG_ERRO_INTERNO = 'Erro interno do servidor';

function MensagemSegura(const aContexto: string; E: Exception): string;
begin
  { Sem console (ex.: runner de testes GUI) WriteLn falharia com I/O error 105 }
  if IsConsole then
    WriteLn('[ERRO] ' + aContexto + ': ' + E.ClassName + ': ' + E.Message);
  Result := MSG_ERRO_INTERNO;
end;

{ TServicoTarefas }

constructor TServicoTarefas.Create(aRepositorio: IRepositorioTarefas; aLimitePadrao: Integer;
  aLimiteMaximo: Integer);
begin
  inherited Create;

  if not Assigned(aRepositorio) then
    raise EConfiguracaoInvalida.Create('Repositório não pode ser nulo');

  FRepositorio := aRepositorio;
  FLimiteMaximo := aLimiteMaximo;
  if FLimiteMaximo < 1 then
    FLimiteMaximo := 1;
  FLimitePadrao := aLimitePadrao;
  if FLimitePadrao < 1 then
    FLimitePadrao := 1;
  if FLimitePadrao > FLimiteMaximo then
    FLimitePadrao := FLimiteMaximo;
end;

function TServicoTarefas.MapearTarefaParaDTO(const aTarefa: TTarefa): TTarefaDTO;
begin
  Result.Id := aTarefa.Id;
  Result.Titulo := aTarefa.Titulo;
  Result.Descricao := aTarefa.Descricao;
  Result.Prioridade := aTarefa.Prioridade;
  Result.Status := aTarefa.Status;
  Result.DataCriacao := aTarefa.DataCriacao;
  Result.DataFinalizacao := aTarefa.DataFinalizacao;
  Result.DataPrevisaoFinalizacao := aTarefa.DataPrevisaoFinalizacao;
  Result.Responsavel := aTarefa.Responsavel;
end;

procedure TServicoTarefas.LiberarTarefas(var aTarefas: TList<TTarefa>);
var
  LTarefa: TTarefa;
begin
  if not Assigned(aTarefas) then
    Exit;

  for LTarefa in aTarefas do
    LTarefa.Free;
  FreeAndNil(aTarefas);
end;

function TServicoTarefas.Listar(aLimit, aOffset: Integer): TResult<TTarefasListaDTO>;
var
  LTarefas: TList<TTarefa>;
  LI: Integer;
  LListaDTO: TTarefasListaDTO;
begin
  { ALimit < 0 = não informado -> padrão; acima do teto -> teto }
  if aLimit < 0 then
    aLimit := FLimitePadrao
  else if aLimit < 1 then
    aLimit := 1
  else if aLimit > FLimiteMaximo then
    aLimit := FLimiteMaximo;
  if aOffset < 0 then
    aOffset := 0;

  LTarefas := nil;
  try
    try
      LTarefas := FRepositorio.ObterTodos(aLimit, aOffset);

      LListaDTO.Total := FRepositorio.ContarTodas;
      LListaDTO.Limit := aLimit;
      LListaDTO.Offset := aOffset;
      SetLength(LListaDTO.Items, LTarefas.Count);
      for LI := 0 to LTarefas.Count - 1 do
        LListaDTO.Items[LI] := MapearTarefaParaDTO(LTarefas[LI]);

      Result := TResult<TTarefasListaDTO>.CriarSucesso(LListaDTO);
    except
      on E: Exception do
        Result := TResult<TTarefasListaDTO>.CriarErro(MensagemSegura('Listar', E), 'ERRO_LISTAGEM');
    end;
  finally
    LiberarTarefas(LTarefas);
  end;
end;

function TServicoTarefas.ObterPorId(aId: Integer): TResult<TTarefaDTO>;
var
  LTarefa: TTarefa;
begin
  LTarefa := nil;
  try
    try
      LTarefa := FRepositorio.ObterPorId(aId);
      Result := TResult<TTarefaDTO>.CriarSucesso(MapearTarefaParaDTO(LTarefa));
    except
      on E: ETarefaNaoEncontrada do
        Result := TResult<TTarefaDTO>.CriarErro(E.Message, E.CodigoErro);
      on E: Exception do
        Result := TResult<TTarefaDTO>.CriarErro(MensagemSegura('ObterPorId', E), 'ERRO_OBTENCAO');
    end;
  finally
    LTarefa.Free;
  end;
end;

function TServicoTarefas.Criar(const aRequest: TCriarTarefaRequest): TResult<TTarefaDTO>;
var
  LValidacaoResult: TResult;
  LTarefa: TTarefa;
begin
  LValidacaoResult := TValidadorTarefas.ValidarCriarTarefa(aRequest);

  if not LValidacaoResult.EhSucesso then
    Exit(TResult<TTarefaDTO>.CriarErro(LValidacaoResult.MensagemErro, LValidacaoResult.CodigoErro));

  LTarefa := nil;
  try
    try
      LTarefa := TTarefa.Create;
      LTarefa.Titulo := aRequest.Titulo;
      LTarefa.Descricao := aRequest.Descricao;
      LTarefa.Prioridade := aRequest.Prioridade;
      LTarefa.Responsavel := aRequest.Responsavel.Trim;
      LTarefa.DataPrevisaoFinalizacao := aRequest.DataPrevisaoFinalizacao;
      LTarefa.Status := TStatus.PENDENTE;
      LTarefa.DataCriacao := Now;

      FRepositorio.Adicionar(LTarefa);

      Result := TResult<TTarefaDTO>.CriarSucesso(MapearTarefaParaDTO(LTarefa));
    except
      on E: EValidacaoTarefa do
        Result := TResult<TTarefaDTO>.CriarErro(E.Message, E.CodigoErro);
      on E: Exception do
        Result := TResult<TTarefaDTO>.CriarErro(MensagemSegura('Criar', E), 'ERRO_CRIACAO');
    end;
  finally
    LTarefa.Free;
  end;
end;

function TServicoTarefas.AtualizarStatus(aId: Integer; const aRequest: TAtualizarTarefaRequest): TResult<TTarefaDTO>;
var
  LValidacaoResult: TResult;
  LTarefa: TTarefa;
begin
  LValidacaoResult := TValidadorTarefas.ValidarAtualizarStatus(aRequest);

  if not LValidacaoResult.EhSucesso then
    Exit(TResult<TTarefaDTO>.CriarErro(LValidacaoResult.MensagemErro, LValidacaoResult.CodigoErro));

  LTarefa := nil;
  try
    try
      LTarefa := FRepositorio.ObterPorId(aId);

      { Preserva a data original se a tarefa já estava concluída }
      if (aRequest.Status = TStatus.CONCLUIDA) and (LTarefa.Status <> TStatus.CONCLUIDA) then
        LTarefa.DataFinalizacao := Now
      else if aRequest.Status <> TStatus.CONCLUIDA then
        LTarefa.DataFinalizacao := 0;
      LTarefa.Status := aRequest.Status;

      FRepositorio.Atualizar(LTarefa);

      Result := TResult<TTarefaDTO>.CriarSucesso(MapearTarefaParaDTO(LTarefa));
    except
      on E: ETarefaNaoEncontrada do
        Result := TResult<TTarefaDTO>.CriarErro(E.Message, E.CodigoErro);
      on E: EValidacaoTarefa do
        Result := TResult<TTarefaDTO>.CriarErro(E.Message, E.CodigoErro);
      on E: Exception do
        Result := TResult<TTarefaDTO>.CriarErro(MensagemSegura('AtualizarStatus', E), 'ERRO_ATUALIZACAO');
    end;
  finally
    LTarefa.Free;
  end;
end;

function TServicoTarefas.Remover(aId: Integer): TResult;
begin
  try
    FRepositorio.Remover(aId);
    Result := TResult.Sucesso;
  except
    on E: ETarefaNaoEncontrada do
      Result := TResult.Erro(E.Message, E.CodigoErro);
    on E: Exception do
      Result := TResult.Erro(MensagemSegura('Remover', E), 'ERRO_REMOCAO');
  end;
end;

function TServicoTarefas.ObterEstatisticas: TResult<TStatisticaTarefasDTO>;
var
  LStats: TStatisticaTarefasDTO;
begin
  try
    LStats.Total := FRepositorio.ObterTotalTarefas;
    LStats.MediaPrioridade := FRepositorio.ObterMediaPrioridadePendentes;
    LStats.ConcluidasÚltimo7Dias := FRepositorio.ObterQuantidadeConcluidas7Dias;

    Result := TResult<TStatisticaTarefasDTO>.CriarSucesso(LStats);
  except
    on E: Exception do
      Result := TResult<TStatisticaTarefasDTO>.CriarErro(MensagemSegura('ObterEstatisticas', E), 'ERRO_STATS');
  end;
end;

end.
