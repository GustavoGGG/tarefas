unit API.Security;

interface

uses
  Shared.Result;

type
  ISecurityValidator = interface(IInterface)
    ['{A1B2C3D4-E5F6-47A8-B9C0-D1E2F3A4B5C6}']
   function ValidarAPIKey(const aAPIKey: string): TResult;
  end;

  TSecurityValidator = class(TInterfacedObject, ISecurityValidator)
  private
    FAPIKeyValida: string;
  public
    constructor Create(const aAPIKey: string);
    function ValidarAPIKey(const aAPIKey: string): TResult;
  end;

implementation

uses
  System.SysUtils;

function ChavesIguais(const A, B: string): Boolean;
var
  LBytesA, LBytesB: TBytes;
  LI, LDiferenca: Integer;
begin
  LBytesA := TEncoding.UTF8.GetBytes(A);
  LBytesB := TEncoding.UTF8.GetBytes(B);
  LDiferenca := Length(LBytesA) xor Length(LBytesB);
  for LI := 0 to Length(LBytesA) - 1 do
    if LI < Length(LBytesB) then
      LDiferenca := LDiferenca or (LBytesA[LI] xor LBytesB[LI])
    else
      LDiferenca := LDiferenca or 1;
  Result := LDiferenca = 0;
end;

{ TSecurityValidator }

constructor TSecurityValidator.Create(const aAPIKey: string);
begin
  inherited Create;
  FAPIKeyValida := aAPIKey;
end;

function TSecurityValidator.ValidarAPIKey(const aAPIKey: string): TResult;
begin
  if aAPIKey.IsEmpty then
    Result := TResult.Erro('API Key não fornecida', 'API_KEY_AUSENTE')
  else if not ChavesIguais(aAPIKey, FAPIKeyValida) then
    Result := TResult.Erro('API Key inválida', 'API_KEY_INVALIDA')
  else
    Result := TResult.Sucesso;
end;

end.
