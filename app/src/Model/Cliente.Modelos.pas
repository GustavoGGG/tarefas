unit Cliente.Modelos;


interface

type
  TTarefa = record
    Id: Integer;
    Titulo: string;
    Descricao: string;
    Prioridade: Integer;
    Status: string;
    DataCriacao: TDateTime;
    DataFinalizacao: TDateTime; { 0 = sem data }
    DataPrevisaoFinalizacao: TDateTime; { 0 = sem previsão }
    Responsavel: string;
  end;

  TPaginaTarefas = record
    Itens: TArray<TTarefa>;
    Total: Integer;
    Limite: Integer;
    Deslocamento: Integer;
  end;

  TEstatisticas = record
    Total: Integer;
    MediaPrioridade: Double; { média somente das tarefas pendentes }
    ConcluidasUltimos7Dias: Integer;
  end;

const
  STATUS_PENDENTE = 'Pendente';
  STATUS_EM_PROGRESSO = 'Em Progresso';
  STATUS_CONCLUIDA = 'Concluída';

  PRIORIDADE_MIN = 1;
  PRIORIDADE_MAX = 3;
  TITULO_MAX = 100;
  DESCRICAO_MAX = 500;
  RESPONSAVEL_MAX = 100;

  TODOS_STATUS: array[0..2] of string = (STATUS_PENDENTE, STATUS_EM_PROGRESSO, STATUS_CONCLUIDA);

function NomePrioridade(aPrioridade: Integer): string;

{ Converte 'yyyy-mm-dd hh:nn:ss' (formato da API) em TDateTime; vazio ou inválido = 0. }
function ParseDataApi(const aValor: string): TDateTime;

implementation

uses
  System.SysUtils, System.DateUtils;

function NomePrioridade(aPrioridade: Integer): string;
begin
  case aPrioridade of
    1: Result := 'Baixa';
    2: Result := 'Média';
    3: Result := 'Alta';
  else
    Result := IntToStr(aPrioridade);
  end;
end;

function ParseDataApi(const aValor: string): TDateTime;
var
  LAno, LMes, LDia, LHora, LMinuto, LSegundo: Integer;
begin
  Result := 0;
  if Length(aValor) < 19 then
    Exit;
  if not (TryStrToInt(Copy(aValor, 1, 4), LAno) and
          TryStrToInt(Copy(aValor, 6, 2), LMes) and
          TryStrToInt(Copy(aValor, 9, 2), LDia) and
          TryStrToInt(Copy(aValor, 12, 2), LHora) and
          TryStrToInt(Copy(aValor, 15, 2), LMinuto) and
          TryStrToInt(Copy(aValor, 18, 2), LSegundo)) then
    Exit;
  if not TryEncodeDateTime(LAno, LMes, LDia, LHora, LMinuto, LSegundo, 0, Result) then
    Result := 0;
end;

end.
