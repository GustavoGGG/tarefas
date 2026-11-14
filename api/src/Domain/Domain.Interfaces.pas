unit Domain.Interfaces;

interface

uses
  System.Generics.Collections, Domain.Entities, Shared.Result;

type

  IRepositorioTarefas = interface(IInterface)
    ['{F1E2D3C4-B5A6-4978-9C8D-7E6F5A4B3C2D}']

    function ObterPorId(const aId: Integer): TTarefa;
    procedure Adicionar(const aTarefa: TTarefa);
    procedure Atualizar(const aTarefa: TTarefa);
    procedure Remover(const aId: Integer);

    function ObterTodos(aLimit: Integer = 10; aOffset: Integer = 0): TList<TTarefa>;
    function ContarTodas: Integer;
    function ExistePorId(const aId: Integer): Boolean;

    function ObterTotalTarefas: Integer;
    function ObterMediaPrioridadePendentes: Double;
    function ObterQuantidadeConcluidas7Dias: Integer;
  end;

implementation

end.
