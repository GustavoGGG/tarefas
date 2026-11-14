unit Cliente.Config;

interface

type
  TClienteConfig = record
    UrlBase: string;
    ApiKey: string;
  end;

function CarregarConfig: TClienteConfig;

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON;

const
  URL_PADRAO = 'http://localhost:9000';
  ENV_URL = 'TAREFAS_API_URL';
  ENV_API_KEY = 'TAREFAS_API_KEY';

function LocalizarConfigJson: string;
var
  LPasta, LCandidato: string;
  LNivel: Integer;
begin
  Result := '';
  LPasta := ExtractFilePath(ParamStr(0));
  for LNivel := 1 to 8 do
  begin
    LCandidato := TPath.Combine(LPasta, 'config.json');
    if TFile.Exists(LCandidato) then
      Exit(LCandidato);
    LPasta := ExtractFilePath(ExcludeTrailingPathDelimiter(LPasta));
    if LPasta = '' then
      Break;
  end;
end;

function CarregarConfig: TClienteConfig;
var
  LArquivo, LUrl: string;
  LRaiz, LApi: TJSONValue;
  LPorta: Integer;
begin
  Result.UrlBase := URL_PADRAO;
  Result.ApiKey := ''; 

  LArquivo := LocalizarConfigJson;
  if LArquivo <> '' then
  begin
    try
      LRaiz := TJSONObject.ParseJSONValue(TFile.ReadAllText(LArquivo, TEncoding.UTF8));
      try
        if LRaiz is TJSONObject then
        begin
          LApi := TJSONObject(LRaiz).GetValue('api');
          if LApi is TJSONObject then
          begin
            if TJSONObject(LApi).TryGetValue<Integer>('port', LPorta) then
              Result.UrlBase := 'http://localhost:' + IntToStr(LPorta);
            TJSONObject(LApi).TryGetValue<string>('apiKey', Result.ApiKey);
          end;
        end;
      finally
        LRaiz.Free;
      end;
    except
      { config.json ilegível: mantém os padrões }
    end;
  end;

  LUrl := GetEnvironmentVariable(ENV_API_KEY);
  if LUrl <> '' then
    Result.ApiKey := LUrl;

  LUrl := GetEnvironmentVariable(ENV_URL);
  if LUrl <> '' then
    Result.UrlBase := LUrl;
  Result.UrlBase := Result.UrlBase.TrimRight(['/']);
end;

end.
