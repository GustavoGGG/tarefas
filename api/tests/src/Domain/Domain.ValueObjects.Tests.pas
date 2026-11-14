unit Domain.ValueObjects.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TStatusTests = class
  public
    [Test] procedure Validos_SaoAceitos;
    [Test] procedure Invalidos_SaoRejeitados;
  end;

  [TestFixture]
  TPrioridadeTests = class
  public
    [Test] procedure Entre1e3_EhValida;
    [Test] procedure Fora_EhInvalida;
  end;

implementation

uses
  Domain.ValueObjects;

{ TStatusTests }

procedure TStatusTests.Validos_SaoAceitos;
begin
  Assert.IsTrue(TStatus.IsValido('Pendente'));
  Assert.IsTrue(TStatus.IsValido('Em Progresso'));
  Assert.IsTrue(TStatus.IsValido('Concluída'));
end;

procedure TStatusTests.Invalidos_SaoRejeitados;
begin
  Assert.IsFalse(TStatus.IsValido(''));
  Assert.IsFalse(TStatus.IsValido('Em'));
  Assert.IsFalse(TStatus.IsValido('pendente'));
  Assert.IsFalse(TStatus.IsValido('Pendente,Em Progresso'));
end;

{ TPrioridadeTests }

procedure TPrioridadeTests.Entre1e3_EhValida;
var
  LIndice: Integer;
begin
  for LIndice := 1 to 3 do
    Assert.IsTrue(TPrioridade.IsValida(LIndice));
end;

procedure TPrioridadeTests.Fora_EhInvalida;
begin
  Assert.IsFalse(TPrioridade.IsValida(0));
  Assert.IsFalse(TPrioridade.IsValida(4));
  Assert.IsFalse(TPrioridade.IsValida(5));
  Assert.IsFalse(TPrioridade.IsValida(6));
  Assert.IsFalse(TPrioridade.IsValida(-1));
end;

initialization
  TDUnitX.RegisterTestFixture(TStatusTests);
  TDUnitX.RegisterTestFixture(TPrioridadeTests);

end.
