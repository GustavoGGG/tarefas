unit Infra.Repository;

interface

uses
  System.Generics.Collections, FireDAC.Comp.Client, FireDAC.Stan.Param,
  Domain.Entities, Domain.Interfaces;

type
  TRepositorioTarefas = class (TInterfacedObject, IRepositorioTarefas)
  private
    FConnection: TFDConnection;

    function CriarQuery(const aSQL: string): TFDQuery;
    function MapearDataSetParaTarefa(aQuery: TFDQuery): TTarefa;
    function ContarPorSQL(const aSQL: string): Integer;
    procedure DefinirDataOuNulo(aParam: TFDParam; const aData: TDateTime);
  public
    constructor Create(aConnection: TFDConnection);
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
  System.SysUtils, Data.DB, Domain.ValueObjects, Shared.Exceptions;

{ TRepositorioTarefas }

constructor TRepositorioTarefas.Create(aConnection: TFDConnection);
begin
  inherited Create;
  if not Assigned(aConnection) then
    raise EConexaoBancoDados.Create('Conexão não pode ser nula');

  FConnection := aConnection;
end;

destructor TRepositorioTarefas.Destroy;
begin
  FConnection.Free;
  inherited Destroy;
end;

function TRepositorioTarefas.CriarQuery(const aSQL: string): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  try
    Result.Connection := FConnection;
    Result.SQL.Text := aSQL;
  except
    Result.Free;
    raise;
  end;
end;

function TRepositorioTarefas.MapearDataSetParaTarefa(aQuery: TFDQuery): TTarefa;
var
  LInput: TTarefaInput;
begin
  LInput.Id := aQuery.FieldByName('Id').AsInteger;
  LInput.Titulo := aQuery.FieldByName('Titulo').AsString;
  LInput.Descricao := aQuery.FieldByName('Descricao').AsString;
  LInput.Prioridade := aQuery.FieldByName('Prioridade').AsInteger;
  LInput.Status := aQuery.FieldByName('Status').AsString;
  LInput.DataCriacao := aQuery.FieldByName('DataCriacao').AsDateTime;
  LInput.DataFinalizacao := aQuery.FieldByName('DataFinalizacao').AsDateTime;
  LInput.DataPrevisaoFinalizacao := aQuery.FieldByName('DataPrevisaoFinalizacao').AsDateTime;
  LInput.Responsavel := aQuery.FieldByName('Responsavel').AsString;

  Result := TTarefa.Create(LInput);
end;

procedure TRepositorioTarefas.DefinirDataOuNulo(aParam: TFDParam; const aData: TDateTime);
begin
  if aData > 0 then
    aParam.AsDateTime := aData
  else
  begin
    aParam.DataType := ftDateTime;
    aParam.Clear;
  end;
end;

function TRepositorioTarefas.ContarPorSQL(const aSQL: string): Integer;
var
  LQuery: TFDQuery;
begin
  LQuery := CriarQuery(aSQL);
  try
    LQuery.Open;
    Result := LQuery.Fields[0].AsInteger;
  finally
    LQuery.Free;
  end;
end;

function TRepositorioTarefas.ObterPorId(const aId: Integer): TTarefa;
var
  LQuery: TFDQuery;
begin
  LQuery := CriarQuery('SELECT * FROM Tarefas WHERE Id = :Id');
  try
    LQuery.ParamByName('Id').AsInteger := aId;
    LQuery.Open;

    if LQuery.Eof then
      raise ETarefaNaoEncontrada.Create;

    Result := MapearDataSetParaTarefa(LQuery);
  finally
    LQuery.Free;
  end;
end;

procedure TRepositorioTarefas.Adicionar(const aTarefa: TTarefa);
var
  LQuery: TFDQuery;
begin
  aTarefa.Validar;

  LQuery := CriarQuery(
    'INSERT INTO Tarefas (Titulo, Descricao, Prioridade, Status, DataCriacao, ' +
    'DataPrevisaoFinalizacao, Responsavel) ' +
    'VALUES (:Titulo, :Descricao, :Prioridade, :Status, :DataCriacao, ' +
    ':DataPrevisaoFinalizacao, :Responsavel)');
  try
    LQuery.ParamByName('Titulo').AsString := aTarefa.Titulo;
    LQuery.ParamByName('Descricao').AsString := aTarefa.Descricao;
    LQuery.ParamByName('Prioridade').AsInteger := aTarefa.Prioridade;
    LQuery.ParamByName('Status').AsString := aTarefa.Status;
    LQuery.ParamByName('DataCriacao').AsDateTime := aTarefa.DataCriacao;
    LQuery.ParamByName('Responsavel').AsString := aTarefa.Responsavel;
    DefinirDataOuNulo(LQuery.ParamByName('DataPrevisaoFinalizacao'), aTarefa.DataPrevisaoFinalizacao);

    FConnection.StartTransaction;
    try
      LQuery.ExecSQL;
      aTarefa.Id := FConnection.ExecSQLScalar('SELECT last_insert_rowid()');

      FConnection.Commit;
    except
      FConnection.Rollback;
      raise;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TRepositorioTarefas.Atualizar(const aTarefa: TTarefa);
var
  LQuery: TFDQuery;
  LAfetadas: Integer;
begin
  aTarefa.Validar;

  LQuery := CriarQuery(
    'UPDATE Tarefas SET Titulo = :Titulo, Descricao = :Descricao, ' +
    'Prioridade = :Prioridade, Status = :Status, DataFinalizacao = :DataFinalizacao, ' +
    'DataPrevisaoFinalizacao = :DataPrevisaoFinalizacao, Responsavel = :Responsavel ' +
    'WHERE Id = :Id');
  try
    LQuery.ParamByName('Id').AsInteger := aTarefa.Id;
    LQuery.ParamByName('Titulo').AsString := aTarefa.Titulo;
    LQuery.ParamByName('Descricao').AsString := aTarefa.Descricao;
    LQuery.ParamByName('Prioridade').AsInteger := aTarefa.Prioridade;
    LQuery.ParamByName('Status').AsString := aTarefa.Status;
    LQuery.ParamByName('Responsavel').AsString := aTarefa.Responsavel;
    DefinirDataOuNulo(LQuery.ParamByName('DataFinalizacao'), aTarefa.DataFinalizacao);
    DefinirDataOuNulo(LQuery.ParamByName('DataPrevisaoFinalizacao'), aTarefa.DataPrevisaoFinalizacao);

    FConnection.StartTransaction;
    try
      LQuery.ExecSQL;
      LAfetadas := LQuery.RowsAffected;
      FConnection.Commit;
    except
      FConnection.Rollback;
      raise;
    end;
  finally
    LQuery.Free;
  end;

  if LAfetadas = 0 then
    raise ETarefaNaoEncontrada.Create;
end;

procedure TRepositorioTarefas.Remover(const aId: Integer);
var
  LQuery: TFDQuery;
  LAfetadas: Integer;
begin
  LQuery := CriarQuery('DELETE FROM Tarefas WHERE Id = :Id');
  try
    LQuery.ParamByName('Id').AsInteger := aId;

    FConnection.StartTransaction;
    try
      LQuery.ExecSQL;
      LAfetadas := LQuery.RowsAffected;
      FConnection.Commit;
    except
      FConnection.Rollback;
      raise;
    end;
  finally
    LQuery.Free;
  end;

  if LAfetadas = 0 then
    raise ETarefaNaoEncontrada.Create;
end;

function TRepositorioTarefas.ObterTodos(aLimit: Integer; aOffset: Integer): TList<TTarefa>;
var
  LQuery: TFDQuery;
  LTarefas: TList<TTarefa>;
  LTarefa: TTarefa;
begin
  LTarefas := TList<TTarefa>.Create;
  try
    LQuery := CriarQuery(
      'SELECT * FROM Tarefas ORDER BY DataCriacao DESC, Id DESC ' +
      'LIMIT :Limit OFFSET :Offset');
    try
      LQuery.ParamByName('Offset').AsInteger := aOffset;
      LQuery.ParamByName('Limit').AsInteger := aLimit;
      LQuery.Open;

      while not LQuery.Eof do
      begin
        LTarefas.Add(MapearDataSetParaTarefa(LQuery));
        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;

    Result := LTarefas;
  except
    for LTarefa in LTarefas do
      LTarefa.Free;
    LTarefas.Free;
    raise;
  end;
end;

function TRepositorioTarefas.ContarTodas: Integer;
begin
  Result := ContarPorSQL('SELECT COUNT(*) AS Total FROM Tarefas');
end;

function TRepositorioTarefas.ExistePorId(const aId: Integer): Boolean;
var
  LQuery: TFDQuery;
begin
  LQuery := CriarQuery('SELECT COUNT(*) AS Total FROM Tarefas WHERE Id = :Id');
  try
    LQuery.ParamByName('Id').AsInteger := aId;
    LQuery.Open;
    Result := LQuery.Fields[0].AsInteger > 0;
  finally
    LQuery.Free;
  end;
end;

function TRepositorioTarefas.ObterTotalTarefas: Integer;
begin
  Result := ContarTodas;
end;

function TRepositorioTarefas.ObterMediaPrioridadePendentes: Double;
var
  LQuery: TFDQuery;
begin
  LQuery := CriarQuery(
    'SELECT ROUND(AVG(CAST(Prioridade AS REAL)), 2) AS MediaPrioridade ' +
    'FROM Tarefas WHERE Status = :Status');
  try
    LQuery.ParamByName('Status').AsString := 'Pendente';
    LQuery.Open;

    if LQuery.Fields[0].IsNull then
      Result := 0
    else
      Result := LQuery.Fields[0].AsFloat;
  finally
    LQuery.Free;
  end;
end;

function TRepositorioTarefas.ObterQuantidadeConcluidas7Dias: Integer;
var
  LQuery: TFDQuery;
begin
  LQuery := CriarQuery(
    'SELECT COUNT(*) AS Total FROM Tarefas ' +
    'WHERE Status = :Status AND DataFinalizacao >= :Limite');
  try
    LQuery.ParamByName('Status').AsString := 'Concluída';
    LQuery.ParamByName('Limite').AsDateTime := Now - 7;
    LQuery.Open;
    Result := LQuery.Fields[0].AsInteger;
  finally
    LQuery.Free;
  end;
end;

end.
