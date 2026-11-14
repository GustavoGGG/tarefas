unit Infra.Connection;

interface

uses
  FireDAC.Comp.Client;

type
  { Conexão com o SQLite via pool do FireDAC.
    Inicializar registra a definição (Pooled=True) no FDManager; cada CriarConexao
    devolve uma conexão própria, e o chamador é dono dela (Free devolve ao pool). }
  TConexaoBancoDados = class sealed
  public
    class procedure Inicializar(const aArquivo: string);
    class procedure GarantirEsquema;
    class function CriarConexao: TFDConnection;
  end;

implementation

uses
  System.Classes, System.SysUtils, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Stan.Param, FireDAC.Phys, FireDAC.Phys.Intf, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.ConsoleUI.Wait, FireDAC.DApt,
  FireDAC.Comp.DataSet, Data.DB, Shared.Exceptions;
  
const
  CONNECTION_DEF_NAME = 'TarefasDB';

  SQL_CRIAR_TABELA =
    'CREATE TABLE IF NOT EXISTS Tarefas (' +
    '  Id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  Titulo TEXT NOT NULL,' +
    '  Descricao TEXT NULL,' +
    '  Prioridade INTEGER NOT NULL DEFAULT 1,' +
    '  Status TEXT NOT NULL DEFAULT ''Pendente'',' +
    '  DataCriacao DATETIME NOT NULL,' +
    '  DataFinalizacao DATETIME NULL,' +
    '  DataPrevisaoFinalizacao DATETIME NULL,' +
    '  Responsavel TEXT NOT NULL)';

{ TConexaoBancoDados }

class procedure TConexaoBancoDados.Inicializar(const aArquivo: string);
var
  LParams: TStringList;
begin
  ForceDirectories(ExtractFilePath(aArquivo));

  LParams := TStringList.Create;
  try
    LParams.Add('Database=' + aArquivo);
    LParams.Add('OpenMode=CreateUTF8');
    LParams.Add('LockingMode=Normal');
    LParams.Add('JournalMode=WAL');
    LParams.Add('Synchronous=Normal');
    LParams.Add('BusyTimeout=10000');
    LParams.Add('Pooled=True');
    LParams.Add('POOL_MaximumItems=20');

    FDManager.AddConnectionDef(CONNECTION_DEF_NAME, 'SQLite', LParams);
  finally
    LParams.Free;
  end;
end;

class function TConexaoBancoDados.CriarConexao: TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.ConnectionDefName := CONNECTION_DEF_NAME;
    Result.LoginPrompt := False;
    Result.ResourceOptions.CmdExecTimeout := 60000;
  except
    Result.Free;
    raise;
  end;
end;

class procedure TConexaoBancoDados.GarantirEsquema;
var
  LConexao: TFDConnection;
begin
  LConexao := CriarConexao;
  try
    try
      LConexao.ExecSQL(SQL_CRIAR_TABELA);
      WriteLn('[INFO] Banco SQLite pronto');
    except
      on E: Exception do
        raise EConexaoBancoDados.Create('Erro ao preparar o banco: ' + E.Message);
    end;
  finally
    LConexao.Free;
  end;
end;

end.
