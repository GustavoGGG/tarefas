unit Domain.Interfaces.Fakes;

interface

uses
  System.Generics.Collections, Domain.Entities, 
  Domain.Interfaces, Domain.ValueObjects;
type

  TRepositorioTarefasFake = class(TInterfacedObject, IRepositorioTarefas)
  private
    FTarefas: TObjectList<TTarefa>;
    FProximoId: Integer;
    function ParaInput(const aTarefa: TTarefa): TTarefaInput;
    function Copiar(const aTarefa: TTarefa): TTarefa;
    function Localizar(const aId: Integer): TTarefa;
  public
    FalharEmTodas: Boolean;

    constructor Create;
    destructor Destroy; override;

    function ObterPorId(const aId: Integer): TTarefa;
    procedure Adicionar(const aTarefa: TTarefa);
    procedure Atualizar(const aTarefa: TTarefa);
    procedure Remover(const aId: Integer);
    function ObterTodos(aLimit: Integer = 10; aOffset: Integer = 0): TList<TTarefa>;
    function ContarTodas: Integer;
    function ExistePorId(const aId: Integer): Boolean;
    function ObterTotalTarefas: Integer;
    function ObterMediaPrioridadePendentes: Double;
    function ObterQuantidadeConcluidas7Dias: Integer;
  end;

implementation

uses
  System.SysUtils, Shared.Exceptions;

{ TRepositorioTarefasFake }

constructor TRepositorioTarefasFake.Create;
begin
  inherited Create;
  FTarefas := TObjectList<TTarefa>.Create(True);
  FProximoId := 1;
end;

destructor TRepositorioTarefasFake.Destroy;
begin
  FTarefas.Free;
  inherited Destroy;
end;

function TRepositorioTarefasFake.ParaInput(const aTarefa: TTarefa): TTarefaInput;
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

function TRepositorioTarefasFake.Copiar(const aTarefa: TTarefa): TTarefa;
begin
  Result := TTarefa.Create(ParaInput(aTarefa));
end;

function TRepositorioTarefasFake.Localizar(const aId: Integer): TTarefa;
var
  LTarefa: TTarefa;
begin
  for LTarefa in FTarefas do
    if LTarefa.Id = aId then
      Exit(LTarefa);
  Result := nil;
end;

function TRepositorioTarefasFake.ObterPorId(const aId: Integer): TTarefa;
var
  LExistente: TTarefa;
begin
  if FalharEmTodas then
    raise Exception.Create('falha simulada');

  LExistente := Localizar(aId);
  if not Assigned(LExistente) then
    raise ETarefaNaoEncontrada.Create;

  Result := Copiar(LExistente);
end;

procedure TRepositorioTarefasFake.Adicionar(const aTarefa: TTarefa);
begin
  if FalharEmTodas then
    raise Exception.Create('falha simulada');

  aTarefa.Validar;
  aTarefa.Id := FProximoId;
  Inc(FProximoId);
  FTarefas.Add(Copiar(aTarefa));
end;

procedure TRepositorioTarefasFake.Atualizar(const aTarefa: TTarefa);
var
  LExistente: TTarefa;
begin
  LExistente := Localizar(aTarefa.Id);
  if not Assigned(LExistente) then
    raise ETarefaNaoEncontrada.Create;

  LExistente.Titulo := aTarefa.Titulo;
  LExistente.Descricao := aTarefa.Descricao;
  LExistente.Prioridade := aTarefa.Prioridade;
  LExistente.Status := aTarefa.Status;
  LExistente.DataFinalizacao := aTarefa.DataFinalizacao;
  LExistente.DataPrevisaoFinalizacao := aTarefa.DataPrevisaoFinalizacao;
  LExistente.Responsavel := aTarefa.Responsavel;
end;

procedure TRepositorioTarefasFake.Remover(const aId: Integer);
var
  LExistente: TTarefa;
begin
  LExistente := Localizar(aId);
  if not Assigned(LExistente) then
    raise ETarefaNaoEncontrada.Create;

  FTarefas.Remove(LExistente);
end;

function TRepositorioTarefasFake.ObterTodos(aLimit: Integer; aOffset: Integer): TList<TTarefa>;
var
  LIndice: Integer;
begin
  if FalharEmTodas then
    raise Exception.Create('falha simulada');

  Result := TList<TTarefa>.Create;
  for LIndice := aOffset to FTarefas.Count - 1 do
  begin
    if Result.Count >= aLimit then
      Break;
    Result.Add(Copiar(FTarefas[LIndice]));
  end;
end;

function TRepositorioTarefasFake.ContarTodas: Integer;
begin
  Result := FTarefas.Count;
end;

function TRepositorioTarefasFake.ExistePorId(const aId: Integer): Boolean;
begin
  Result := Assigned(Localizar(aId));
end;

function TRepositorioTarefasFake.ObterTotalTarefas: Integer;
begin
  Result := FTarefas.Count;
end;

function TRepositorioTarefasFake.ObterMediaPrioridadePendentes: Double;
var
  LTarefa: TTarefa;
  LSoma, LQuantidade: Integer;
begin
  LSoma := 0;
  LQuantidade := 0;
  for LTarefa in FTarefas do
    if LTarefa.Status = 'Pendente' then
    begin
      Inc(LSoma, LTarefa.Prioridade);
      Inc(LQuantidade);
    end;

  if LQuantidade = 0 then
    Result := 0
  else
    Result := LSoma / LQuantidade;
end;

function TRepositorioTarefasFake.ObterQuantidadeConcluidas7Dias: Integer;
var
  LTarefa: TTarefa;
begin
  Result := 0;
  for LTarefa in FTarefas do
    if (LTarefa.Status = 'Concluída') and (LTarefa.DataFinalizacao >= Now - 7) then
      Inc(Result);
end;

end.
