unit Shared.Exceptions;

interface

uses
  System.SysUtils;

type
  EAplicacao = class(Exception)
  private
    FCodigoErro: string;
  public
    constructor Create(const aMensagem: string; const aCodigoErro: string = 'ERRO_GENERICO');
    property CodigoErro: string read FCodigoErro;
  end;

  { Exceções de negócio }
  ETarefaNaoEncontrada = class(EAplicacao)
  public
    constructor Create;
  end;

  EValidacaoTarefa = class(EAplicacao)
  public
    constructor Create(const aMensagem: string);
  end;

  EConexaoBancoDados = class(EAplicacao)
  public
    constructor Create(const aMensagem: string);
  end;

  EConfiguracaoInvalida = class(EAplicacao)
  public
    constructor Create(const aMensagem: string);
  end;

  EAPIKeyInvalida = class(EAplicacao)
  public
    constructor Create;
  end;

  ETarefaJaExiste = class(EAplicacao)
  public
    constructor Create;
  end;

  EOperacaoNaoPermitida = class(EAplicacao)
  public
    constructor Create(const aMensagem: string);
  end;

implementation

{ EAplicacao }

constructor EAplicacao.Create(const aMensagem: string; const aCodigoErro: string);
begin
  inherited Create(aMensagem);
  FCodigoErro := aCodigoErro;
end;

{ ETarefaNaoEncontrada }

constructor ETarefaNaoEncontrada.Create;
begin
  inherited Create('Tarefa não encontrada', 'TAREFA_NAO_ENCONTRADA');
end;

{ EValidacaoTarefa }

constructor EValidacaoTarefa.Create(const aMensagem: string);
begin
  inherited Create(aMensagem, 'ERRO_VALIDACAO');
end;

{ EConexaoBancoDados }

constructor EConexaoBancoDados.Create(const aMensagem: string);
begin
  inherited Create(aMensagem, 'ERRO_CONEXAO_BD');
end;

{ EConfiguracaoInvalida }

constructor EConfiguracaoInvalida.Create(const aMensagem: string);
begin
  inherited Create(aMensagem, 'ERRO_CONFIGURACAO');
end;

{ EAPIKeyInvalida }

constructor EAPIKeyInvalida.Create;
begin
  inherited Create('API Key inválida ou ausente', 'API_KEY_INVALIDA');
end;

{ ETarefaJaExiste }

constructor ETarefaJaExiste.Create;
begin
  inherited Create('Tarefa já existe', 'TAREFA_JA_EXISTE');
end;

{ EOperacaoNaoPermitida }

constructor EOperacaoNaoPermitida.Create(const aMensagem: string);
begin
  inherited Create(aMensagem, 'OPERACAO_NAO_PERMITIDA');
end;

end.
