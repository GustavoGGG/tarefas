unit API.Routes;

interface

uses
  System.SysUtils, Horse, Application.Services;

type
  TRegistradorRotas = class sealed
  public
    class procedure RegistrarRotas(aFabricaServico: TFunc<IServicoTarefas>);
  end;

implementation

uses
  API.Controllers;

type
  TAcaoControlador = reference to procedure(aControlador: TControladorTarefas; Req: THorseRequest; Res: THorseResponse);

function CriarHandler(aFabricaServico: TFunc<IServicoTarefas>; aAcao: TAcaoControlador): THorseCallback;
begin
  Result :=
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LControlador: TControladorTarefas;
    begin
      LControlador := TControladorTarefas.Create(aFabricaServico());
      try
        aAcao(LControlador, Req, Res);
      finally
        LControlador.Free;
      end;
    end;
end;

{ TRegistradorRotas }

class procedure TRegistradorRotas.RegistrarRotas(aFabricaServico: TFunc<IServicoTarefas>);
begin
  { Rota de stats antes de /:id para não ser capturada como id }
  THorse.Get('/api/tarefas/stats/resumo',
    CriarHandler(aFabricaServico,
      procedure(C: TControladorTarefas; Req: THorseRequest; Res: THorseResponse)
      begin
        C.ObterStats(Req, Res);
      end));

  THorse.Get('/api/tarefas',
    CriarHandler(aFabricaServico,
      procedure(C: TControladorTarefas; Req: THorseRequest; Res: THorseResponse)
      begin
        C.ListarTarefas(Req, Res);
      end));

  THorse.Get('/api/tarefas/:id',
    CriarHandler(aFabricaServico,
      procedure(C: TControladorTarefas; Req: THorseRequest; Res: THorseResponse)
      begin
        C.ObterTarefaPorId(Req, Res);
      end));

  THorse.Post('/api/tarefas',
    CriarHandler(aFabricaServico,
      procedure(C: TControladorTarefas; Req: THorseRequest; Res: THorseResponse)
      begin
        C.CriarTarefa(Req, Res);
      end));

  THorse.Put('/api/tarefas/:id',
    CriarHandler(aFabricaServico,
      procedure(C: TControladorTarefas; Req: THorseRequest; Res: THorseResponse)
      begin
        C.AtualizarStatusTarefa(Req, Res);
      end));

  THorse.Delete('/api/tarefas/:id',
    CriarHandler(aFabricaServico,
      procedure(C: TControladorTarefas; Req: THorseRequest; Res: THorseResponse)
      begin
        C.RemoverTarefa(Req, Res);
      end));

  WriteLn('[INFO] Rotas registradas');
end;

end.
