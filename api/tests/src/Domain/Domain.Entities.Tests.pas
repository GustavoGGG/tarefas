unit Domain.Entities.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTarefaTests = class
  public
    [Test] procedure TarefaValida_NaoLancaExcecao;
    [Test] procedure TituloVazio_Lanca;
    [Test] procedure TituloComApenasEspacos_Lanca;
    [Test] procedure TituloMaiorQue100_Lanca;
    [Test] procedure PrioridadeForaDoIntervalo_Lanca;
    [Test] procedure StatusInvalido_Lanca;
    [Test] procedure StatusParcial_NaoPassa;
    [Test] procedure ResponsavelMaiorQue100_Lanca;
    [Test] procedure ResponsavelVazio_Lanca;
    [Test] procedure ResponsavelComApenasEspacos_Lanca;
  end;

implementation

uses
  System.SysUtils,  Domain.Entities, Domain.ValueObjects, Shared.Exceptions;

function NovaTarefa: TTarefa;
var
  LInput: TTarefaInput;
begin
  LInput := Default(TTarefaInput);
  LInput.Titulo := 'Titulo';
  LInput.Descricao := 'Descricao';
  LInput.Prioridade := 2;
  LInput.Status := 'Pendente';
  LInput.DataCriacao := Now;
  LInput.Responsavel := 'Ana';
  Result := TTarefa.Create(LInput);
end;

procedure TTarefaTests.TarefaValida_NaoLancaExcecao;
var
  LTarefa: TTarefa;
begin
  LTarefa := NovaTarefa;
  try
    LTarefa.Validar;
    Assert.Pass;
  finally
    LTarefa.Free;
  end;
end;

procedure TTarefaTests.TituloVazio_Lanca;
var
  LTarefa: TTarefa;
begin
  LTarefa := NovaTarefa;
  try
    LTarefa.Titulo := '';
    Assert.WillRaise(procedure begin LTarefa.Validar; end, EValidacaoTarefa);
  finally
    LTarefa.Free;
  end;
end;

procedure TTarefaTests.TituloComApenasEspacos_Lanca;
var
  LTarefa: TTarefa;
begin
  LTarefa := NovaTarefa;
  try
    LTarefa.Titulo := '   ';
    Assert.WillRaise(procedure begin LTarefa.Validar; end, EValidacaoTarefa);
  finally
    LTarefa.Free;
  end;
end;

procedure TTarefaTests.TituloMaiorQue100_Lanca;
var
  LTarefa: TTarefa;
begin
  LTarefa := NovaTarefa;
  try
    LTarefa.Titulo := StringOfChar('a', 101);
    Assert.WillRaise(procedure begin LTarefa.Validar; end, EValidacaoTarefa);
  finally
    LTarefa.Free;
  end;
end;

procedure TTarefaTests.PrioridadeForaDoIntervalo_Lanca;
var
  LTarefa: TTarefa;
begin
  LTarefa := NovaTarefa;
  try
    LTarefa.Prioridade := 0;
    Assert.WillRaise(procedure begin LTarefa.Validar; end, EValidacaoTarefa);
    LTarefa.Prioridade := 4;
    Assert.WillRaise(procedure begin LTarefa.Validar; end, EValidacaoTarefa);
  finally
    LTarefa.Free;
  end;
end;

procedure TTarefaTests.StatusInvalido_Lanca;
var
  LTarefa: TTarefa;
begin
  LTarefa := NovaTarefa;
  try
    LTarefa.Status := 'Inexistente';
    Assert.WillRaise(procedure begin LTarefa.Validar; end, EValidacaoTarefa);
  finally
    LTarefa.Free;
  end;
end;

procedure TTarefaTests.StatusParcial_NaoPassa;
var
  LTarefa: TTarefa;
begin
  LTarefa := NovaTarefa;
  try
    LTarefa.Status := 'Em';
    Assert.WillRaise(procedure begin LTarefa.Validar; end, EValidacaoTarefa);
  finally
    LTarefa.Free;
  end;
end;

procedure TTarefaTests.ResponsavelMaiorQue100_Lanca;
var
  LTarefa: TTarefa;
begin
  LTarefa := NovaTarefa;
  try
    LTarefa.Responsavel := StringOfChar('a', 101);
    Assert.WillRaise(procedure begin LTarefa.Validar; end, EValidacaoTarefa);
  finally
    LTarefa.Free;
  end;
end;

procedure TTarefaTests.ResponsavelVazio_Lanca;
var
  LTarefa: TTarefa;
begin
  LTarefa := NovaTarefa;
  try
    LTarefa.Responsavel := '';
    Assert.WillRaise(procedure begin LTarefa.Validar; end, EValidacaoTarefa);
  finally
    LTarefa.Free;
  end;
end;

procedure TTarefaTests.ResponsavelComApenasEspacos_Lanca;
var
  LTarefa: TTarefa;
begin
  LTarefa := NovaTarefa;
  try
    LTarefa.Responsavel := '   ';
    Assert.WillRaise(procedure begin LTarefa.Validar; end, EValidacaoTarefa);
  finally
    LTarefa.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTarefaTests);

end.
