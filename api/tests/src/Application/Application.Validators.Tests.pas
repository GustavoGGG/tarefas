unit Application.Validators.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TValidadorTarefasTests = class
  public
    [Test] procedure Criar_Valido;
    [Test] procedure Criar_TituloVazio;
    [Test] procedure Criar_TituloLongo;
    [Test] procedure Criar_DescricaoLonga;
    [Test] procedure Criar_PrioridadeInvalida;
    [Test] procedure Criar_ResponsavelVazio;
    [Test] procedure Criar_ResponsavelLongo;
    [Test] procedure Criar_DataPrevisaoInvalida;
    [Test] procedure Criar_DataPrevisaoInformada;
    [Test] procedure Status_Valido;
    [Test] procedure Status_Vazio;
    [Test] procedure Status_Invalido;
  end;

implementation

uses
  System.SysUtils,  Application.DTOs,  Application.Validators;

procedure TValidadorTarefasTests.Criar_Valido;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := 'Ok';
  LCriarTarefaRequest.Prioridade := 3;
  LCriarTarefaRequest.Responsavel := 'Ana';
  Assert.IsTrue(TValidadorTarefas.ValidarCriarTarefa(LCriarTarefaRequest).EhSucesso);
end;

procedure TValidadorTarefasTests.Criar_TituloVazio;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := '  ';
  LCriarTarefaRequest.Prioridade := 1;
  Assert.AreEqual('TITULO_OBRIGATORIO', TValidadorTarefas.ValidarCriarTarefa(LCriarTarefaRequest).CodigoErro);
end;

procedure TValidadorTarefasTests.Criar_TituloLongo;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := StringOfChar('a', 101);
  LCriarTarefaRequest.Prioridade := 1;
  Assert.AreEqual('TITULO_MUITO_LONGO', TValidadorTarefas.ValidarCriarTarefa(LCriarTarefaRequest).CodigoErro);
end;

procedure TValidadorTarefasTests.Criar_DescricaoLonga;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := 'Ok';
  LCriarTarefaRequest.Descricao := StringOfChar('a', 501);
  LCriarTarefaRequest.Prioridade := 1;
  Assert.AreEqual('DESCRICAO_MUITO_LONGA', TValidadorTarefas.ValidarCriarTarefa(LCriarTarefaRequest).CodigoErro);
end;

procedure TValidadorTarefasTests.Criar_PrioridadeInvalida;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := 'Ok';
  LCriarTarefaRequest.Prioridade := 9;
  Assert.AreEqual('PRIORIDADE_INVALIDA', TValidadorTarefas.ValidarCriarTarefa(LCriarTarefaRequest).CodigoErro);
end;

procedure TValidadorTarefasTests.Criar_ResponsavelVazio;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := 'Ok';
  LCriarTarefaRequest.Prioridade := 1;
  LCriarTarefaRequest.Responsavel := '   ';
  Assert.AreEqual('RESPONSAVEL_OBRIGATORIO', TValidadorTarefas.ValidarCriarTarefa(LCriarTarefaRequest).CodigoErro);
end;

procedure TValidadorTarefasTests.Criar_ResponsavelLongo;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := 'Ok';
  LCriarTarefaRequest.Prioridade := 1;
  LCriarTarefaRequest.Responsavel := StringOfChar('a', 101);
  Assert.AreEqual('RESPONSAVEL_MUITO_LONGO', TValidadorTarefas.ValidarCriarTarefa(LCriarTarefaRequest).CodigoErro);
end;

procedure TValidadorTarefasTests.Criar_DataPrevisaoInvalida;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := 'Ok';
  LCriarTarefaRequest.Prioridade := 1;
  LCriarTarefaRequest.Responsavel := 'Ana';
  LCriarTarefaRequest.DataPrevisaoFinalizacao := -1;
  Assert.AreEqual('DATA_PREVISAO_INVALIDA', TValidadorTarefas.ValidarCriarTarefa(LCriarTarefaRequest).CodigoErro);
end;

procedure TValidadorTarefasTests.Criar_DataPrevisaoInformada;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := 'Ok';
  LCriarTarefaRequest.Prioridade := 1;
  LCriarTarefaRequest.Responsavel := 'Ana';
  LCriarTarefaRequest.DataPrevisaoFinalizacao := Now + 3;
  Assert.IsTrue(TValidadorTarefas.ValidarCriarTarefa(LCriarTarefaRequest).EhSucesso);
end;

procedure TValidadorTarefasTests.Status_Valido;
var
  LAtualizarTarefaRequest: TAtualizarTarefaRequest;
begin
  LAtualizarTarefaRequest := Default(TAtualizarTarefaRequest);
  LAtualizarTarefaRequest.Status := 'Concluída';
  Assert.IsTrue(TValidadorTarefas.ValidarAtualizarStatus(LAtualizarTarefaRequest).EhSucesso);
end;

procedure TValidadorTarefasTests.Status_Vazio;
var
  LAtualizarTarefaRequest: TAtualizarTarefaRequest;
begin
  LAtualizarTarefaRequest := Default(TAtualizarTarefaRequest);
  LAtualizarTarefaRequest.Status := '';
  Assert.AreEqual('STATUS_OBRIGATORIO', TValidadorTarefas.ValidarAtualizarStatus(LAtualizarTarefaRequest).CodigoErro);
end;

procedure TValidadorTarefasTests.Status_Invalido;
var
  LAtualizarTarefaRequest: TAtualizarTarefaRequest;
begin
  LAtualizarTarefaRequest := Default(TAtualizarTarefaRequest);
  LAtualizarTarefaRequest.Status := 'Qualquer';
  Assert.AreEqual('STATUS_INVALIDO', TValidadorTarefas.ValidarAtualizarStatus(LAtualizarTarefaRequest).CodigoErro);
end;

initialization
  TDUnitX.RegisterTestFixture(TValidadorTarefasTests);

end.
