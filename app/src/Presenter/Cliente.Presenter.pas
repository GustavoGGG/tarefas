unit Cliente.Presenter;

interface

uses
  Cliente.Modelos, Cliente.Api;

const
  LIMITE_PADRAO = 10;

type
  TCarga = record
    Pagina: TPaginaTarefas;
    Stats: TEstatisticas;
    Deslocamento: Integer;
  end;

  TTarefasPresenter = class
  private
    FApi: ITarefasApi;
    FLimite: Integer;
    FDeslocamento: Integer;
    FPagina: TPaginaTarefas;
  public
    constructor Create(aApi: ITarefasApi);

    { Thread de trabalho: não alteram o estado }
    function Buscar(aLimite, aDeslocamento: Integer): TCarga;
    function Criar(const aTitulo, aDescricao: string; aPrioridade: Integer;
      const aResponsavel: string; aPrevisaoFinalizacao: TDateTime): TTarefa;
    function AtualizarStatus(aId: Integer; const aStatus: string): TTarefa;
    procedure Remover(aId: Integer);

    { Thread principal: alteram o estado }
    procedure Aplicar(const aCarga: TCarga);
    procedure Proxima;
    procedure Anterior;
    procedure IrParaPrimeira;
    procedure DefinirLimite(aLimite: Integer);

    function TarefaEm(aIndice: Integer; out aTarefa: TTarefa): Boolean;
    function TemAnterior: Boolean;
    function TemProxima: Boolean;
    function TextoPagina: string;
    function UrlBase: string;

    property Limite: Integer read FLimite;
    property Deslocamento: Integer read FDeslocamento;
    property Pagina: TPaginaTarefas read FPagina;
  end;

implementation

uses
  System.SysUtils;

{ TTarefasPresenter }

constructor TTarefasPresenter.Create(aApi: ITarefasApi);
begin
  inherited Create;
  FApi := aApi;
  FLimite := LIMITE_PADRAO;
end;

function TTarefasPresenter.Buscar(aLimite, aDeslocamento: Integer): TCarga;
begin
  Result.Deslocamento := aDeslocamento;
  Result.Pagina := FApi.Listar(aLimite, Result.Deslocamento);

  { página ficou vazia (ex.: removeu o último item dela): volta para a última existente }
  if (Length(Result.Pagina.Itens) = 0) and (Result.Pagina.Total > 0) and (Result.Deslocamento > 0) then
  begin
    Result.Deslocamento := ((Result.Pagina.Total - 1) div aLimite) * aLimite;
    Result.Pagina := FApi.Listar(aLimite, Result.Deslocamento);
  end;

  Result.Stats := FApi.ObterEstatisticas;
end;

function TTarefasPresenter.Criar(const aTitulo, aDescricao: string; aPrioridade: Integer;
  const aResponsavel: string; aPrevisaoFinalizacao: TDateTime): TTarefa;
begin
  Result := FApi.Criar(aTitulo, aDescricao, aPrioridade, aResponsavel, aPrevisaoFinalizacao);
end;

function TTarefasPresenter.AtualizarStatus(aId: Integer; const aStatus: string): TTarefa;
begin
  Result := FApi.AtualizarStatus(aId, aStatus);
end;

procedure TTarefasPresenter.Remover(aId: Integer);
begin
  FApi.Remover(aId);
end;

procedure TTarefasPresenter.Aplicar(const aCarga: TCarga);
begin
  FPagina := aCarga.Pagina;
  FDeslocamento := aCarga.Deslocamento;
end;

procedure TTarefasPresenter.Proxima;
begin
  FDeslocamento := FDeslocamento + FLimite;
end;

procedure TTarefasPresenter.Anterior;
begin
  FDeslocamento := FDeslocamento - FLimite;
  if FDeslocamento < 0 then
    FDeslocamento := 0;
end;

procedure TTarefasPresenter.IrParaPrimeira;
begin
  FDeslocamento := 0;
end;

procedure TTarefasPresenter.DefinirLimite(aLimite: Integer);
begin
  if aLimite < 1 then
    aLimite := LIMITE_PADRAO;
  FLimite := aLimite;
  FDeslocamento := 0;
end;

function TTarefasPresenter.TarefaEm(aIndice: Integer; out aTarefa: TTarefa): Boolean;
begin
  Result := (aIndice >= 0) and (aIndice < Length(FPagina.Itens));
  if Result then
    aTarefa := FPagina.Itens[aIndice]
  else
    aTarefa := Default(TTarefa);
end;

function TTarefasPresenter.TemAnterior: Boolean;
begin
  Result := FDeslocamento > 0;
end;

function TTarefasPresenter.TemProxima: Boolean;
begin
  Result := FDeslocamento + Length(FPagina.Itens) < FPagina.Total;
end;

function TTarefasPresenter.TextoPagina: string;
begin
  if FPagina.Total = 0 then
    Result := 'Nenhuma tarefa'
  else
    Result := Format('%d–%d de %d',
      [FDeslocamento + 1, FDeslocamento + Length(FPagina.Itens), FPagina.Total]);
end;

function TTarefasPresenter.UrlBase: string;
begin
  Result := FApi.UrlBase;
end;

end.
