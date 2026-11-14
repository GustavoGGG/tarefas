unit Application.Services.Tests;

interface

uses
  DUnitX.TestFramework, Domain.Interfaces, Domain.Interfaces.Fakes,
  Application.Services;

type
  [TestFixture]
  TServicoTarefasTests = class
  private
    FRepositorioTarefasFake: TRepositorioTarefasFake;
    FRepositorioTarefas: IRepositorioTarefas;
    FServico: IServicoTarefas;
    function CriarTarefa(const aTitulo: string; aPrioridade: Integer): Integer;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Criar_Valido_Retorna201ComId;
    [Test] procedure Criar_Invalido_Retorna400;
    [Test] procedure Criar_FalhaNoRepositorio_Retorna500;
    [Test] procedure ObterPorId_Existente_Retorna200;
    [Test] procedure ObterPorId_Inexistente_Retorna404;
    [Test] procedure AtualizarStatus_Concluida_PreencheDataFinalizacao;
    [Test] procedure AtualizarStatus_VoltaParaPendente_LimpaDataFinalizacao;
    [Test] procedure AtualizarStatus_Invalido_Retorna400;
    [Test] procedure AtualizarStatus_Inexistente_Retorna404;
    [Test] procedure Remover_Existente_Retorna204;
    [Test] procedure Remover_Inexistente_Retorna404;
    [Test] procedure Listar_RespeitaLimitEOffset;
    [Test] procedure Listar_LimitNaoInformado_UsaPadraoDoConfig;
    [Test] procedure Listar_LimitAcimaDoMaximo_UsaMaximoDoConfig;
    [Test] procedure ObterEstatisticas_CalculaTotalMediaEConcluidas;
  end;

implementation

uses
  System.SysUtils, Application.DTOs, Shared.Result;

procedure TServicoTarefasTests.Setup;
begin
  FRepositorioTarefasFake := TRepositorioTarefasFake.Create;
  FRepositorioTarefas := FRepositorioTarefasFake;
  FServico := TServicoTarefas.Create(FRepositorioTarefas);
end;

procedure TServicoTarefasTests.TearDown;
begin
  FServico := nil;
  FRepositorioTarefas := nil;
  FRepositorioTarefasFake := nil;
end;

function TServicoTarefasTests.CriarTarefa(const aTitulo: string; aPrioridade: Integer): Integer;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
  LResultadoTarefaDTO: TResult<TTarefaDTO>;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := aTitulo;
  LCriarTarefaRequest.Prioridade := aPrioridade;
  LCriarTarefaRequest.Responsavel := 'Ana';
  LResultadoTarefaDTO := FServico.Criar(LCriarTarefaRequest);

  Result := LResultadoTarefaDTO.Valor.Id;
end;

procedure TServicoTarefasTests.Criar_Valido_Retorna201ComId;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
  LResultadoTarefaDTO: TResult<TTarefaDTO>;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := 'Nova';
  LCriarTarefaRequest.Descricao := 'Desc';
  LCriarTarefaRequest.Prioridade := 3;
  LCriarTarefaRequest.Responsavel := '  Ana  ';
  LCriarTarefaRequest.DataPrevisaoFinalizacao := Now + 5;
  LResultadoTarefaDTO := FServico.Criar(LCriarTarefaRequest);

  Assert.IsTrue(LResultadoTarefaDTO.EhSucesso);
  Assert.IsTrue(LResultadoTarefaDTO.Valor.Id > 0, 'Id deve ser preenchido');
  Assert.AreEqual('Pendente', LResultadoTarefaDTO.Valor.Status);
  Assert.AreEqual('Ana', LResultadoTarefaDTO.Valor.Responsavel);
  Assert.IsTrue(LResultadoTarefaDTO.Valor.DataPrevisaoFinalizacao > Now, 'Previsão deve ser preservada');
end;

procedure TServicoTarefasTests.Criar_Invalido_Retorna400;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
  LResultadoTarefaDTO: TResult<TTarefaDTO>;
begin
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := '';
  LCriarTarefaRequest.Prioridade := 1;
  LResultadoTarefaDTO := FServico.Criar(LCriarTarefaRequest);

  Assert.IsFalse(LResultadoTarefaDTO.EhSucesso);
  Assert.AreEqual('TITULO_OBRIGATORIO', LResultadoTarefaDTO.CodigoErro);
  Assert.AreEqual('TITULO_OBRIGATORIO', LResultadoTarefaDTO.CodigoErro);
  Assert.AreEqual(0, FRepositorioTarefasFake.ContarTodas);
end;

procedure TServicoTarefasTests.Criar_FalhaNoRepositorio_Retorna500;
var
  LCriarTarefaRequest: TCriarTarefaRequest;
  LResultadoTarefaDTO: TResult<TTarefaDTO>;
begin
  FRepositorioTarefasFake.FalharEmTodas := True;
  LCriarTarefaRequest := Default(TCriarTarefaRequest);
  LCriarTarefaRequest.Titulo := 'Falha';
  LCriarTarefaRequest.Prioridade := 1;
  LCriarTarefaRequest.Responsavel := 'Ana';
  LResultadoTarefaDTO := FServico.Criar(LCriarTarefaRequest);

  Assert.IsFalse(LResultadoTarefaDTO.EhSucesso);
  Assert.AreEqual('ERRO_CRIACAO', LResultadoTarefaDTO.CodigoErro);
end;

procedure TServicoTarefasTests.ObterPorId_Existente_Retorna200;
var
  LId: Integer;
  LResultadoTarefaDTO: TResult<TTarefaDTO>;
begin
  LId := CriarTarefa('Buscar', 2);
  LResultadoTarefaDTO := FServico.ObterPorId(LId);
  Assert.IsTrue(LResultadoTarefaDTO.EhSucesso);
  Assert.AreEqual('Buscar', LResultadoTarefaDTO.Valor.Titulo);
end;

procedure TServicoTarefasTests.ObterPorId_Inexistente_Retorna404;
var
  LResultadoTarefaDTO: TResult<TTarefaDTO>;
begin
  LResultadoTarefaDTO := FServico.ObterPorId(999);
  Assert.IsFalse(LResultadoTarefaDTO.EhSucesso);
  Assert.AreEqual('TAREFA_NAO_ENCONTRADA', LResultadoTarefaDTO.CodigoErro);
  Assert.AreEqual('TAREFA_NAO_ENCONTRADA', LResultadoTarefaDTO.CodigoErro);
end;

procedure TServicoTarefasTests.AtualizarStatus_Concluida_PreencheDataFinalizacao;
var
  LId: Integer;
  LAtualizarTarefaRequest: TAtualizarTarefaRequest;
  LResultadoTarefaDTO: TResult<TTarefaDTO>;
begin
  LId := CriarTarefa('Concluir', 2);
  LAtualizarTarefaRequest := Default(TAtualizarTarefaRequest);
  LAtualizarTarefaRequest.Status := 'Concluída';
  LResultadoTarefaDTO := FServico.AtualizarStatus(LId, LAtualizarTarefaRequest);

  Assert.IsTrue(LResultadoTarefaDTO.EhSucesso);
  Assert.AreEqual('Concluída', LResultadoTarefaDTO.Valor.Status);
  Assert.IsTrue(LResultadoTarefaDTO.Valor.DataFinalizacao > 0, 'DataFinalizacao deve ser preenchida');
end;

procedure TServicoTarefasTests.AtualizarStatus_VoltaParaPendente_LimpaDataFinalizacao;
var
  LId: Integer;
  LAtualizarTarefaRequest: TAtualizarTarefaRequest;
  LResultadoTarefaDTO: TResult<TTarefaDTO>;
begin
  LId := CriarTarefa('Reabrir', 2);
  LAtualizarTarefaRequest := Default(TAtualizarTarefaRequest);
  LAtualizarTarefaRequest.Status := 'Concluída';
  FServico.AtualizarStatus(LId, LAtualizarTarefaRequest);
  LAtualizarTarefaRequest.Status := 'Pendente';
  LResultadoTarefaDTO := FServico.AtualizarStatus(LId, LAtualizarTarefaRequest);

  Assert.IsTrue(LResultadoTarefaDTO.EhSucesso);
  Assert.AreEqual(0.0, LResultadoTarefaDTO.Valor.DataFinalizacao, 0.0001);
end;

procedure TServicoTarefasTests.AtualizarStatus_Invalido_Retorna400;
var
  LId: Integer;
  LAtualizarTarefaRequest: TAtualizarTarefaRequest;
  LResultadoTarefaDTO: TResult<TTarefaDTO>;
begin
  LId := CriarTarefa('Invalido', 2);
  LAtualizarTarefaRequest := Default(TAtualizarTarefaRequest);
  LAtualizarTarefaRequest.Status := 'Nada';
  LResultadoTarefaDTO := FServico.AtualizarStatus(LId, LAtualizarTarefaRequest);

  Assert.IsFalse(LResultadoTarefaDTO.EhSucesso);
  Assert.AreEqual('STATUS_INVALIDO', LResultadoTarefaDTO.CodigoErro);
end;

procedure TServicoTarefasTests.AtualizarStatus_Inexistente_Retorna404;
var
  LAtualizarTarefaRequest: TAtualizarTarefaRequest;
  LResultadoTarefaDTO: TResult<TTarefaDTO>;
begin
  LAtualizarTarefaRequest := Default(TAtualizarTarefaRequest);
  LAtualizarTarefaRequest.Status := 'Pendente';
  LResultadoTarefaDTO := FServico.AtualizarStatus(999, LAtualizarTarefaRequest);

  Assert.IsFalse(LResultadoTarefaDTO.EhSucesso);
  Assert.AreEqual('TAREFA_NAO_ENCONTRADA', LResultadoTarefaDTO.CodigoErro);
end;

procedure TServicoTarefasTests.Remover_Existente_Retorna204;
var
  LId: Integer;
  LResultado: TResult;
begin
  LId := CriarTarefa('Remover', 1);
  LResultado := FServico.Remover(LId);
  Assert.IsTrue(LResultado.EhSucesso);
  Assert.AreEqual(0, FRepositorioTarefasFake.ContarTodas);
end;

procedure TServicoTarefasTests.Remover_Inexistente_Retorna404;
var
  LResultado: TResult;
begin
  LResultado := FServico.Remover(999);
  Assert.IsFalse(LResultado.EhSucesso);
  Assert.AreEqual('TAREFA_NAO_ENCONTRADA', LResultado.CodigoErro);
end;

procedure TServicoTarefasTests.Listar_RespeitaLimitEOffset;
var
  LIndice: Integer;
  LResultadoTarefasListaDTO: TResult<TTarefasListaDTO>;
begin
  for LIndice := 1 to 5 do
    CriarTarefa('T' + IntToStr(LIndice), 1);

  LResultadoTarefasListaDTO := FServico.Listar(2, 1);
  Assert.IsTrue(LResultadoTarefasListaDTO.EhSucesso);
  Assert.AreEqual(5, LResultadoTarefasListaDTO.Valor.Total);
  Assert.AreEqual(2, Length(LResultadoTarefasListaDTO.Valor.Items));
  Assert.AreEqual(2, LResultadoTarefasListaDTO.Valor.Limit);
  Assert.AreEqual(1, LResultadoTarefasListaDTO.Valor.Offset);
end;

procedure TServicoTarefasTests.Listar_LimitNaoInformado_UsaPadraoDoConfig;
var
  LResultadoTarefasListaDTO: TResult<TTarefasListaDTO>;
begin
  FServico := TServicoTarefas.Create(FRepositorioTarefas, 3, 5);
  LResultadoTarefasListaDTO := FServico.Listar(-1, 0);
  Assert.IsTrue(LResultadoTarefasListaDTO.EhSucesso);
  Assert.AreEqual(3, LResultadoTarefasListaDTO.Valor.Limit);
end;

procedure TServicoTarefasTests.Listar_LimitAcimaDoMaximo_UsaMaximoDoConfig;
var
  LResultadoTarefasListaDTO: TResult<TTarefasListaDTO>;
begin
  FServico := TServicoTarefas.Create(FRepositorioTarefas, 3, 5);
  LResultadoTarefasListaDTO := FServico.Listar(1000, 0);
  Assert.IsTrue(LResultadoTarefasListaDTO.EhSucesso);
  Assert.AreEqual(5, LResultadoTarefasListaDTO.Valor.Limit);
end;

procedure TServicoTarefasTests.ObterEstatisticas_CalculaTotalMediaEConcluidas;
var
  LId: Integer;
  LAtualizarTarefaRequest: TAtualizarTarefaRequest;
  LResultadoStatisticaTarefasDTO: TResult<TStatisticaTarefasDTO>;
begin
  { Prioridades válidas são 1..3; média das pendentes (A e B) = 3,0 }
  CriarTarefa('A', 3);
  CriarTarefa('B', 3);
  LId := CriarTarefa('C', 1);

  LAtualizarTarefaRequest := Default(TAtualizarTarefaRequest);
  LAtualizarTarefaRequest.Status := 'Concluída';
  FServico.AtualizarStatus(LId, LAtualizarTarefaRequest);

  LResultadoStatisticaTarefasDTO := FServico.ObterEstatisticas;
  Assert.IsTrue(LResultadoStatisticaTarefasDTO.EhSucesso);
  Assert.AreEqual(3, LResultadoStatisticaTarefasDTO.Valor.Total);
  Assert.AreEqual(3.0, LResultadoStatisticaTarefasDTO.Valor.MediaPrioridade, 0.001);
  Assert.AreEqual(1, LResultadoStatisticaTarefasDTO.Valor.ConcluidasÚltimo7Dias);
end;

initialization
  TDUnitX.RegisterTestFixture(TServicoTarefasTests);

end.
