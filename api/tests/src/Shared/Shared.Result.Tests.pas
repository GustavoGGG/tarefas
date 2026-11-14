unit Shared.Result.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TResultTests = class
  public
    [Test] procedure Generico_Sucesso_GuardaValor;
    [Test] procedure Generico_Erro_TemValorPadraoEDadosDoErro;
    [Test] procedure Generico_ObterValorOuPadrao;
    [Test] procedure NaoGenerico_Sucesso;
    [Test] procedure NaoGenerico_Erro;
  end;

implementation

uses
  Shared.Result;

procedure TResultTests.Generico_Sucesso_GuardaValor;
var
  LResultadoInteger: TResult<Integer>;
begin
  LResultadoInteger := TResult<Integer>.CriarSucesso(42);
  Assert.IsTrue(LResultadoInteger.EhSucesso);
  Assert.AreEqual(42, LResultadoInteger.Valor);
  Assert.AreEqual('', LResultadoInteger.MensagemErro);
end;

procedure TResultTests.Generico_Erro_TemValorPadraoEDadosDoErro;
var
  LResultadoInteger: TResult<Integer>;
begin
  LResultadoInteger := TResult<Integer>.CriarErro('falhou', 'CODIGO');
  Assert.IsFalse(LResultadoInteger.EhSucesso);
  Assert.AreEqual(0, LResultadoInteger.Valor);
  Assert.AreEqual('falhou', LResultadoInteger.MensagemErro);
  Assert.AreEqual('CODIGO', LResultadoInteger.CodigoErro);
end;

procedure TResultTests.Generico_ObterValorOuPadrao;
begin
  Assert.AreEqual(7, TResult<Integer>.CriarSucesso(7).ObterValorOuPadrao(99));
  Assert.AreEqual(99, TResult<Integer>.CriarErro('x').ObterValorOuPadrao(99));
end;

procedure TResultTests.NaoGenerico_Sucesso;
var
  LResultado: TResult;
begin
  LResultado := TResult.Sucesso;
  Assert.IsTrue(LResultado.EhSucesso);
end;

procedure TResultTests.NaoGenerico_Erro;
var
  LResultado: TResult;
begin
  LResultado := TResult.Erro('erro', 'ERRO_X');
  Assert.IsFalse(LResultado.EhSucesso);
  Assert.AreEqual('ERRO_X', LResultado.CodigoErro);
end;

initialization
  TDUnitX.RegisterTestFixture(TResultTests);

end.
