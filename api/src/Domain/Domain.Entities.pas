unit Domain.Entities;

interface

uses
  System.SysUtils, System.Generics.Collections, Domain.ValueObjects;

type
  
  TTarefa = class
  private
    FId: Integer;
    FTitulo: string;
    FDescricao: string;
    FPrioridade: Integer;
    FStatus: string;
    FDataCriacao: TDateTime;
    FDataFinalizacao: TDateTime;
    FDataPrevisaoFinalizacao: TDateTime;
    FResponsavel: string;

    procedure ValidarTitulo;
    procedure ValidarPrioridade;
    procedure ValidarStatus;
    procedure ValidarResponsavel;
  public
    constructor Create; overload;
    constructor Create(const aInput: TTarefaInput); overload;

    procedure Validar;
    property Id: Integer read FId write FId;
    property Titulo: string read FTitulo write FTitulo;
    property Descricao: string read FDescricao write FDescricao;
    property Prioridade: Integer read FPrioridade write FPrioridade;
    property Status: string read FStatus write FStatus;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataFinalizacao: TDateTime read FDataFinalizacao write FDataFinalizacao;
    property DataPrevisaoFinalizacao: TDateTime read FDataPrevisaoFinalizacao write FDataPrevisaoFinalizacao;
    property Responsavel: string read FResponsavel write FResponsavel;
    procedure MarcarComoConcluída;
    procedure MarcarComoPendente;
    procedure MarcarComoEmProgresso;
    function EstaVencida: Boolean;
    function EstaPendente: Boolean;
    function EstaConcluida: Boolean;
  end;

implementation

uses
  Shared.Exceptions;

{ TTarefa }

constructor TTarefa.Create;
begin
  inherited Create;
  FId := 0;
  FTitulo := '';
  FDescricao := '';
  FPrioridade := 1;
  FStatus := 'Pendente';
  FDataCriacao := Now;
  FDataFinalizacao := 0;
  FDataPrevisaoFinalizacao := 0;
  FResponsavel := '';
end;

constructor TTarefa.Create(const aInput: TTarefaInput);
begin
  inherited Create;
  FId := aInput.Id;
  FTitulo := aInput.Titulo;
  FDescricao := aInput.Descricao;
  FPrioridade := aInput.Prioridade;
  FStatus := aInput.Status;
  FDataCriacao := aInput.DataCriacao;
  FDataFinalizacao := aInput.DataFinalizacao;
  FDataPrevisaoFinalizacao := aInput.DataPrevisaoFinalizacao;
  FResponsavel := aInput.Responsavel;
end;

procedure TTarefa.ValidarTitulo;
begin
  if FTitulo.Trim.IsEmpty then
    raise EValidacaoTarefa.Create('Título é obrigatório');

  if FTitulo.Length > TLimitesTarefa.TITULO_MAX then
    raise EValidacaoTarefa.Create(
      Format('Título não pode ter mais de %d caracteres', [TLimitesTarefa.TITULO_MAX]));
end;

procedure TTarefa.ValidarPrioridade;
begin
  if (FPrioridade < 1) or (FPrioridade > 3) then
    raise EValidacaoTarefa.Create('Prioridade deve ser 1 (Baixa), 2 (Média) ou 3 (Alta)');
end;

procedure TTarefa.ValidarStatus;
begin
  if not TStatus.IsValido(FStatus) then
    raise EValidacaoTarefa.Create('Status inválido. Use: Pendente, Em Progresso ou Concluída');
end;

procedure TTarefa.ValidarResponsavel;
begin
  if FResponsavel.Trim.IsEmpty then
    raise EValidacaoTarefa.Create('Responsável é obrigatório');

  if FResponsavel.Length > TLimitesTarefa.RESPONSAVEL_MAX then
    raise EValidacaoTarefa.Create(
      Format('Responsável não pode ter mais de %d caracteres', [TLimitesTarefa.RESPONSAVEL_MAX]));
end;

procedure TTarefa.Validar;
begin
  ValidarTitulo;
  ValidarPrioridade;
  ValidarStatus;
  ValidarResponsavel;
end;

procedure TTarefa.MarcarComoConcluída;
begin
  FStatus := 'Concluída';
  FDataFinalizacao := Now;
end;

procedure TTarefa.MarcarComoPendente;
begin
  FStatus := 'Pendente';
  FDataFinalizacao := 0;
end;

procedure TTarefa.MarcarComoEmProgresso;
begin
  FStatus := 'Em Progresso';
  FDataFinalizacao := 0;
end;

function TTarefa.EstaVencida: Boolean;
begin
  Result := (FStatus = 'Pendente') and (Now > FDataCriacao + 7);
end;

function TTarefa.EstaPendente: Boolean;
begin
  Result := FStatus = 'Pendente';
end;

function TTarefa.EstaConcluida: Boolean;
begin
  Result := FStatus = 'Concluída';
end;

end.
