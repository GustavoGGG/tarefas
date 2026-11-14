unit API.Swagger;

interface

uses
  Horse;

type
  { Documentação OpenAPI 3 (Swagger UI).
    - GET /docs          interface Swagger UI
    - GET /openapi.json  especificação OpenAPI
    Ambas as rotas são públicas (não exigem X-API-Key); a chave é informada
    pelo botão "Authorize" da interface. }
  TSwagger = class sealed
  public
    const
      ROTA_DOCS = '/docs';
      ROTA_SPEC = '/openapi.json';

    class procedure RegistrarRotas;
    class function EhRotaPublica(const aPath: string): Boolean;
  end;

implementation

uses
  System.SysUtils, System.IOUtils;

const
  ARQUIVO_SPEC = 'openapi.json';

  HTML_SWAGGER_UI = '''
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>API de Tarefas - Swagger</title>
      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.17.14/swagger-ui.css">
    </head>
    <body>
      <div id="swagger-ui"></div>
      <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.17.14/swagger-ui-bundle.js"></script>
      <script>
        window.onload = function () {
          window.ui = SwaggerUIBundle({
            url: '/openapi.json',
            dom_id: '#swagger-ui',
            persistAuthorization: true
          });
        };
      </script>
    </body>
    </html>
    ''';

{ TSwagger }

class function TSwagger.EhRotaPublica(const aPath: string): Boolean;
var
  LCaminho: string;
begin
  LCaminho := aPath;
  if (Length(LCaminho) > 1) and LCaminho.EndsWith('/') then
    LCaminho := Copy(LCaminho, 1, Length(LCaminho) - 1);
  Result := SameText(LCaminho, ROTA_DOCS) or SameText(LCaminho, ROTA_SPEC);
end;

// Procura o arquivo a partir da pasta do executável, subindo os diretórios
// (mesma lógica do config.json).
function LocalizarArquivo(const aNome: string): string;
var
  LDir: string;
begin
  LDir := TPath.GetDirectoryName(ParamStr(0));
  while LDir <> '' do
  begin
    Result := TPath.Combine(LDir, aNome);
    if FileExists(Result) then
      Exit;
    LDir := TPath.GetDirectoryName(LDir);
  end;
  Result := '';
end;

class procedure TSwagger.RegistrarRotas;
var
  LCaminho: string;
  LSpec: string;
begin
  LCaminho := LocalizarArquivo(ARQUIVO_SPEC);
  if LCaminho <> '' then
    LSpec := TFile.ReadAllText(LCaminho, TEncoding.UTF8)
  else
    WriteLn('[AVISO] ' + ARQUIVO_SPEC + ' não encontrado; ' + ROTA_SPEC + ' responderá 404');

  THorse.Get(ROTA_DOCS,
    procedure(Req: THorseRequest; Res: THorseResponse)
    begin
      Res.ContentType('text/html; charset=UTF-8').Send(HTML_SWAGGER_UI);
    end);

  THorse.Get(ROTA_SPEC,
    procedure(Req: THorseRequest; Res: THorseResponse)
    begin
      if LSpec = '' then
        Res.Status(404).ContentType('application/json; charset=UTF-8')
          .Send('{"success":false,"statusCode":404,"error":"openapi.json não encontrado","code":"SPEC_NAO_ENCONTRADA"}')
      else
        Res.ContentType('application/json; charset=UTF-8').Send(LSpec);
    end);

  WriteLn('[INFO] Swagger registrado em ' + ROTA_DOCS);
end;

end.
