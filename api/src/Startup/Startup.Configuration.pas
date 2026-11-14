unit Startup.Configuration;

interface

uses
  System.JSON;

type
  TConfiguracao = class 
  private
    FConfigJSON: TJSONObject;
    FConfigDir: string;
  public
    constructor Create(const aConfigPath: string);
    destructor Destroy; override;

    function ObterArquivoBD: string;
    function ObterPortaAPI: Integer;
    function ObterHostAPI: string;
    function ObterAPIKey: string;
    function ObterEnvironment: string;
    function ObterLimitPaginacaoPadrao: Integer;
    function ObterLimitPaginacaoMaximo: Integer;

    function CarregarDoJSON(const aArquivo: string): Boolean;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, Shared.Exceptions;

{ TConfiguracao }

constructor TConfiguracao.Create(const aConfigPath: string);
begin
  inherited Create;
  FConfigJSON := nil;
  FConfigDir := TPath.GetDirectoryName(aConfigPath);

  if not CarregarDoJSON(aConfigPath) then
    raise EConfiguracaoInvalida.Create('Erro ao carregar configuração de: ' + aConfigPath);
end;

destructor TConfiguracao.Destroy;
begin
  if Assigned(FConfigJSON) then
    FConfigJSON.Free;
  inherited Destroy;
end;

function TConfiguracao.CarregarDoJSON(const aArquivo: string): Boolean;
var
  LJSONText: string;
begin
  Result := False;

  try
    if not FileExists(aArquivo) then
    begin
      WriteLn('[ERRO] Arquivo de configuração não encontrado: ' + aArquivo);
      Exit;
    end;

    LJSONText := TFile.ReadAllText(aArquivo);
    FConfigJSON := TJSONObject.ParseJSONValue(LJSONText) as TJSONObject;

    if not Assigned(FConfigJSON) then
    begin
      WriteLn('[ERRO] Configuração JSON inválida');
      Exit;
    end;

    Result := True;
    WriteLn('[INFO] Configuração carregada com sucesso');
  except
    on E: Exception do
    begin
      WriteLn('[ERRO] Exceção ao carregar config: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TConfiguracao.ObterArquivoBD: string;
begin
  if not (Assigned(FConfigJSON) and FConfigJSON.TryGetValue<string>('database.file', Result)) then
    Result := 'database/tarefas.db';

  if TPath.IsRelativePath(Result) then
    Result := TPath.Combine(FConfigDir, Result);

  Result := TPath.GetFullPath(Result);
end;

function TConfiguracao.ObterPortaAPI: Integer;
begin
  if Assigned(FConfigJSON) and FConfigJSON.TryGetValue<Integer>('api.port', Result) then
    Exit;

  Result := 9000;
end;

function TConfiguracao.ObterHostAPI: string;
begin
  if Assigned(FConfigJSON) and FConfigJSON.TryGetValue<string>('api.host', Result) then
    Exit;

  Result := '0.0.0.0';
end;

function TConfiguracao.ObterAPIKey: string;
begin
  Result := GetEnvironmentVariable('TAREFAS_API_KEY');
  if Result <> '' then
    Exit;

  if not (Assigned(FConfigJSON) and FConfigJSON.TryGetValue<string>('api.apiKey', Result)) then
    Result := '';
end;

function TConfiguracao.ObterEnvironment: string;
begin
  if Assigned(FConfigJSON) and FConfigJSON.TryGetValue<string>('api.environment', Result) then
    Exit;

  Result := 'development';
end;

function TConfiguracao.ObterLimitPaginacaoPadrao: Integer;
begin
  if Assigned(FConfigJSON) and FConfigJSON.TryGetValue<Integer>('pagination.defaultLimit', Result) then
    Exit;

  Result := 10;
end;

function TConfiguracao.ObterLimitPaginacaoMaximo: Integer;
begin
  if Assigned(FConfigJSON) and FConfigJSON.TryGetValue<Integer>('pagination.maxLimit', Result) then
    Exit;

  Result := 100;
end;

end.
