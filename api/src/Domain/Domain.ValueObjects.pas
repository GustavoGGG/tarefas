unit Domain.ValueObjects;

interface

uses
  System.SysUtils;

type

  TPrioridade = record
    Value: Integer;
    class function Baixa: Integer; static;
    class function Média: Integer; static;
    class function Alta: Integer; static;
    class function ToString(aPrioridade: Integer): string; static;
    class function IsValida(aPrioridade: Integer): Boolean; static;
  end;

  TStatus = record
    const
      PENDENTE = 'Pendente';
      EM_PROGRESSO = 'Em Progresso';
      CONCLUIDA = 'Concluída';

    class function Todos: TArray<string>; static;
    class function IsValido(const aStatus: string): Boolean; static;
  end;

  { Limites de tamanho: fonte única para a entidade e para o validador da API }
  TLimitesTarefa = record
    const
      TITULO_MAX = 100;
      DESCRICAO_MAX = 500;
      RESPONSAVEL_MAX = 100;
  end;

  TTarefaInput = record
    Id: Integer;
    Titulo: string;
    Descricao: string;
    Prioridade: Integer;
    Status: string;
    DataCriacao: TDateTime;
    DataFinalizacao: TDateTime;
    DataPrevisaoFinalizacao: TDateTime;
    Responsavel: string;
  end;

  TDataTarefa = record
    DataCriacao: TDateTime;
    DataFinalizacao: TDateTime;
    class function CriarAgora: TDataTarefa; static;
    function EstaVencida(aDias: Integer = 7): Boolean;
  end;

implementation

{ TPrioridade }

class function TPrioridade.Baixa: Integer;
begin
  Result := 1;
end;

class function TPrioridade.Média: Integer;
begin
  Result := 2;
end;

class function TPrioridade.Alta: Integer;
begin
  Result := 3;
end;

class function TPrioridade.ToString(aPrioridade: Integer): string;
begin
  case aPrioridade of
    1: Result := 'Baixa';
    2: Result := 'Média';
    3: Result := 'Alta';
  else
    Result := 'Desconhecida';
  end;
end;

class function TPrioridade.IsValida(aPrioridade: Integer): Boolean;
begin
  Result := (aPrioridade >= 1) and (aPrioridade <= 3);
end;

{ TStatus }

class function TStatus.Todos: TArray<string>;
begin
  SetLength(Result, 3);
  Result[0] := PENDENTE;
  Result[1] := EM_PROGRESSO;
  Result[2] := CONCLUIDA;
end;

class function TStatus.IsValido(const aStatus: string): Boolean;
var
  LItem: string;
begin
  Result := False;
  for LItem in TStatus.Todos do
    if LItem = aStatus then
      Exit(True);
end;

{ TDataTarefa }

class function TDataTarefa.CriarAgora: TDataTarefa;
begin
  Result.DataCriacao := Now;
  Result.DataFinalizacao := 0;
end;

function TDataTarefa.EstaVencida(aDias: Integer): Boolean;
begin
  Result := (DataCriacao < Now - aDias) and (DataFinalizacao = 0);
end;

end.
