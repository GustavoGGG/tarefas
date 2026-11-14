unit Application.Validators;

interface

uses
  Application.DTOs, Shared.Result;

type
  TValidadorTarefas = class
  strict private
    class function ValidarTitulo(const aTitulo: string): TResult; static;
    class function ValidarResponsavel(const aResponsavel: string): TResult; static;
  public
    class function ValidarCriarTarefa(const aRequest: TCriarTarefaRequest): TResult;
    class function ValidarAtualizarStatus(const aRequest: TAtualizarTarefaRequest): TResult;
  end;

implementation

uses
  System.SysUtils, Domain.ValueObjects;

{ TValidadorTarefas }

class function TValidadorTarefas.ValidarTitulo(const aTitulo: string): TResult;
begin
  if aTitulo.Trim.IsEmpty then
    Exit(TResult.Erro('Título é obrigatório', 'TITULO_OBRIGATORIO'));

  if aTitulo.Length > TLimitesTarefa.TITULO_MAX then
    Exit(TResult.Erro(
      Format('Título não pode ter mais de %d caracteres', [TLimitesTarefa.TITULO_MAX]),
      'TITULO_MUITO_LONGO'));

  Result := TResult.Sucesso;
end;

class function TValidadorTarefas.ValidarResponsavel(const aResponsavel: string): TResult;
begin
  if aResponsavel.Trim.IsEmpty then
    Exit(TResult.Erro('Responsável é obrigatório', 'RESPONSAVEL_OBRIGATORIO'));

  if aResponsavel.Length > TLimitesTarefa.RESPONSAVEL_MAX then
    Exit(TResult.Erro(
      Format('Responsável não pode ter mais de %d caracteres', [TLimitesTarefa.RESPONSAVEL_MAX]),
      'RESPONSAVEL_MUITO_LONGO'));

  Result := TResult.Sucesso;
end;

class function TValidadorTarefas.ValidarCriarTarefa(const aRequest: TCriarTarefaRequest): TResult;
begin
  Result := ValidarTitulo(aRequest.Titulo);
  if not Result.EhSucesso then
    Exit;

  if Length(aRequest.Descricao) > TLimitesTarefa.DESCRICAO_MAX then
    Exit(TResult.Erro(
      Format('Descrição não pode ter mais de %d caracteres', [TLimitesTarefa.DESCRICAO_MAX]),
      'DESCRICAO_MUITO_LONGA'));

  if not TPrioridade.IsValida(aRequest.Prioridade) then
    Exit(TResult.Erro('Prioridade deve ser 1 (Baixa), 2 (Média) ou 3 (Alta)', 'PRIORIDADE_INVALIDA'));

  Result := ValidarResponsavel(aRequest.Responsavel);
  if not Result.EhSucesso then
    Exit;

  { Validar data de previsão (opcional; < 0 = formato inválido) }
  if aRequest.DataPrevisaoFinalizacao < 0 then
    Exit(TResult.Erro('Data de previsão inválida. Use yyyy-mm-dd ou yyyy-mm-dd hh:nn:ss', 'DATA_PREVISAO_INVALIDA'));

  Result := TResult.Sucesso;
end;

class function TValidadorTarefas.ValidarAtualizarStatus(const aRequest: TAtualizarTarefaRequest): TResult;
begin
  if aRequest.Status.Trim.IsEmpty then
    Exit(TResult.Erro('Status é obrigatório', 'STATUS_OBRIGATORIO'));

  if not TStatus.IsValido(aRequest.Status) then
    Exit(TResult.Erro('Status inválido. Use: Pendente, Em Progresso ou Concluída', 'STATUS_INVALIDO'));

  Result := TResult.Sucesso;
end;

end.
