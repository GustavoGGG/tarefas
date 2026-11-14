unit Startup.Application;

interface

uses
  Startup.Configuration, API.Security, Application.Services;

type
  TStartupApplication = class
  private
    FConfiguracao: TConfiguracao;
    FValidador: ISecurityValidator;

    procedure ConfigurarDependencias;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Inicializar;
    function ObterServico: IServicoTarefas;
    function ObterPorta: Integer;
    function ObterHost: string;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, Horse, API.Routes, API.Swagger,
  API.Middleware.ErrorHandler, API.Middleware.Security, 
  FireDAC.Comp.Client, Infra.Connection, Infra.Repository, Shared.Exceptions;

function LocalizarConfig: string;
var
  LDir: string;
  LCandidato: string;
begin
  LDir := TPath.GetDirectoryName(ParamStr(0));
  while LDir <> '' do
  begin
    LCandidato := TPath.Combine(LDir, 'config.json');
    if FileExists(LCandidato) then
      Exit(LCandidato);
    LDir := TPath.GetDirectoryName(LDir);
  end;

  Result := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'config.json');
end;

{ TStartupApplication }

constructor TStartupApplication.Create;
begin
  inherited Create;
  FConfiguracao := nil;
  FValidador := nil;
end;

destructor TStartupApplication.Destroy;
begin
  FValidador := nil;

  if Assigned(FConfiguracao) then
    FreeAndNil(FConfiguracao);

  inherited Destroy;
end;

procedure TStartupApplication.Inicializar;
var
  LConfigPath: string;
begin
  WriteLn('');
  try
    WriteLn('[FASE 1] Carregando configuração...');
    LConfigPath := LocalizarConfig;

    FConfiguracao := TConfiguracao.Create(LConfigPath);

    WriteLn('[FASE 2] Configurando injeção de dependências...');
    ConfigurarDependencias;

    WriteLn('[FASE 3] Registrando middlewares...');
    WriteLn('[INFO] Registrando middleware de tratamento de erros...');
    THorse.Use(TMiddlewareErrorHandler.ExecutarMiddleware);
    WriteLn('[INFO] Registrando middleware de segurança (API Key)...');
    THorse.Use(TMiddlewareValidarAPIKey.Criar(FValidador));


    WriteLn('[FASE 4] Registrando rotas...');
    TRegistradorRotas.RegistrarRotas(
      function: IServicoTarefas
      begin
        Result := ObterServico;
      end);

    TSwagger.RegistrarRotas;

    WriteLn('');
    WriteLn(' Sistema pronto para iniciar');
    WriteLn('');

  except
    on E: Exception do
    begin
      WriteLn(' ERRO AO TENTAR INICIALIZAR: ' + E.Message);
      WriteLn('');
      raise;
    end;
  end;
end;

procedure TStartupApplication.ConfigurarDependencias;
var
  LChaveAPI: string;
begin
  WriteLn('[INFO] Inicializando conexão com banco de dados...');
  TConexaoBancoDados.Inicializar(FConfiguracao.ObterArquivoBD);
  TConexaoBancoDados.GarantirEsquema;

  WriteLn('[INFO] Configurando Security Validator...');
  LChaveAPI := FConfiguracao.ObterAPIKey;
  if LChaveAPI = '' then
    raise EConfiguracaoInvalida.Create(
      'API Key não configurada: defina "api.apiKey" no config.json ou a variável TAREFAS_API_KEY');
  FValidador := TSecurityValidator.Create(LChaveAPI);
end;

function TStartupApplication.ObterServico: IServicoTarefas;
begin
  if not Assigned(FConfiguracao) then
    raise EConfiguracaoInvalida.Create('Configuração não foi carregada');

  { Composição: novo serviço (com repositório e conexão próprios) a cada chamada }
  Result := TServicoTarefas.Create(
    TRepositorioTarefas.Create(TConexaoBancoDados.CriarConexao),
    FConfiguracao.ObterLimitPaginacaoPadrao,
    FConfiguracao.ObterLimitPaginacaoMaximo);
end;

function TStartupApplication.ObterPorta: Integer;
begin
  if not Assigned(FConfiguracao) then
    raise EConfiguracaoInvalida.Create('Configuração não foi carregada');

  Result := FConfiguracao.ObterPortaAPI;
end;

function TStartupApplication.ObterHost: string;
begin
  if not Assigned(FConfiguracao) then
    raise EConfiguracaoInvalida.Create('Configuração não foi carregada');

  Result := FConfiguracao.ObterHostAPI;
end;

end.
