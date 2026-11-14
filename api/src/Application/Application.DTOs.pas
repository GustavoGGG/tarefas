unit Application.DTOs;

interface

type

  TTarefaDTO = record
    Id: Integer;
    Titulo: string;
    Descricao: string;
    Prioridade: Integer;
    Status: string;
    DataCriacao: TDateTime;
    DataFinalizacao: TDateTime;
    DataPrevisaoFinalizacao: TDateTime;
    Responsavel: string;
  end;

  TTarefasListaDTO = record
    Total: Integer;
    Limit: Integer;
    Offset: Integer;
    Items: TArray<TTarefaDTO>;
  end;

  TStatisticaTarefasDTO = record
    Total: Integer;
    MediaPrioridade: Double;
    ConcluidasÚltimo7Dias: Integer;
  end;

  TCriarTarefaRequest = record
    Titulo: string;
    Descricao: string;
    Prioridade: Integer;
    Responsavel: string;
    DataPrevisaoFinalizacao: TDateTime;
  end;

  TAtualizarTarefaRequest = record
    Status: string;
  end;

implementation

end.
