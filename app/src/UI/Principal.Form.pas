unit Principal.Form;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.CommCtrl, System.SysUtils, System.Classes,
  System.Threading, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Cliente.Config, Cliente.Modelos, Cliente.Api, Cliente.Presenter;

type
  TFormPrincipal = class(TForm)
    gpEstatisticas: TGridPanel;
    pnlTotal: TPanel;
    lblTotalTit: TLabel;
    lblTotalVal: TLabel;
    pnlMedia: TPanel;
    lblMediaTit: TLabel;
    lblMediaVal: TLabel;
    pnlConcluidas: TPanel;
    lblConcTit: TLabel;
    lblConcVal: TLabel;
    gbNova: TGroupBox;
    lblTitulo: TLabel;
    lblDescricao: TLabel;
    lblPrioridade: TLabel;
    lblResponsavel: TLabel;
    lblPrevisao: TLabel;
    lblContTitulo: TLabel;
    lblContDesc: TLabel;
    edTitulo: TEdit;
    mmDescricao: TMemo;
    cbPrioridade: TComboBox;
    edResponsavel: TEdit;
    dtPrevisao: TDateTimePicker;
    btnAdicionar: TButton;
    pnlBarra: TPanel;
    btnAtualizar: TButton;
    lblPorPagina: TLabel;
    cbPorPagina: TComboBox;
    sbRodape: TStatusBar;
    pnlPaginacao: TPanel;
    btnAnterior: TButton;
    lblPagina: TLabel;
    btnProxima: TButton;
    pnlAcoes: TPanel;
    lblStatus: TLabel;
    cbStatus: TComboBox;
    btnStatus: TButton;
    btnRemover: TButton;
    lvTarefas: TListView;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edTituloChange(Sender: TObject);
    procedure mmDescricaoChange(Sender: TObject);
    procedure btnAdicionarClick(Sender: TObject);
    procedure btnAtualizarClick(Sender: TObject);
    procedure btnStatusClick(Sender: TObject);
    procedure btnRemoverClick(Sender: TObject);
    procedure btnAnteriorClick(Sender: TObject);
    procedure btnProximaClick(Sender: TObject);
    procedure cbPorPaginaChange(Sender: TObject);
    procedure lvTarefasResize(Sender: TObject);
    procedure lvTarefasSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvTarefasCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure sbRodapeDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel;
      const Rect: TRect);
  private
    FPresenter: TTarefasPresenter;
    FOcupado: Boolean;
    FConectado: Boolean;
    FCarregouInicial: Boolean;
    procedure Executar(aTrabalho, aAoConcluir: TProc);
    procedure CapturarErro(aTrabalho: TProc; out aMensagem, aCodigo: string);
    procedure Finalizar(const aMensagem, aCodigo: string; aAoConcluir: TProc);
    procedure RestaurarPrevisao;
    procedure Recarregar;
    procedure ExibirTarefas;
    procedure ExibirEstatisticas(const aStats: TEstatisticas);
    procedure AtualizarBotoes;
    procedure DefinirOcupado(aOcupado: Boolean);
    procedure DestacarCampo(const aCodigo: string);
    function TarefaSelecionada(out aTarefa: TTarefa): Boolean;
  public
    destructor Destroy; override;
  end;

var
  FormPrincipal: TFormPrincipal;

implementation

{$R *.dfm}

const
  COR_PENDENTE = $00807A6B;     { cinza }
  COR_EM_PROGRESSO = $00D16F1F; { azul }
  COR_CONCLUIDA = $003E8E1E;    { verde }
  COR_ERRO = $002B39C0;         { vermelho }
  COLUNA_STATUS = 3;

function FormatarData(aData: TDateTime): string;
begin
  if aData = 0 then
    Result := '—'
  else
    Result := FormatDateTime('dd/mm/yyyy hh:nn', aData);
end;

{ TFormPrincipal }

procedure TFormPrincipal.FormCreate(Sender: TObject);
var
  LI: Integer;
  LConfig: TClienteConfig;
begin
  LConfig := CarregarConfig;
  FPresenter := TTarefasPresenter.Create(TTarefasApi.Create(LConfig));
  FConectado := True;

  for LI := PRIORIDADE_MIN to PRIORIDADE_MAX do
    cbPrioridade.Items.Add(IntToStr(LI) + ' - ' + NomePrioridade(LI));
  cbPrioridade.ItemIndex := 1;

  RestaurarPrevisao;

  for LI := Low(TODOS_STATUS) to High(TODOS_STATUS) do
    cbStatus.Items.Add(TODOS_STATUS[LI]);
  cbStatus.ItemIndex := 0;

  cbPorPagina.ItemIndex := 0;
  sbRodape.Panels[1].Text := FPresenter.UrlBase;
  edTituloChange(nil);
  mmDescricaoChange(nil);
  AtualizarBotoes;
end;

destructor TFormPrincipal.Destroy;
begin
  FPresenter.Free;
  inherited Destroy;
end;

procedure TFormPrincipal.FormShow(Sender: TObject);
begin
  if not FCarregouInicial then
  begin
    FCarregouInicial := True;
    Recarregar;
  end;
end;

procedure TFormPrincipal.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FOcupado;
end;

procedure TFormPrincipal.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FOcupado then
    Exit;
  if Key = VK_F5 then
  begin
    Key := 0;
    Recarregar;
  end
  else if (Key = VK_DELETE) and (ActiveControl = lvTarefas) and btnRemover.Enabled then
  begin
    Key := 0;
    btnRemoverClick(nil);
  end;
end;

{ Executa ATrabalho fora da thread principal e, ao terminar, ou mostra o erro
  ou chama AAoConcluir na thread principal. }
procedure TFormPrincipal.Executar(aTrabalho, aAoConcluir: TProc);
begin
  DefinirOcupado(True);
  TTask.Run(
    procedure
    var
      LMensagem, LCodigo: string;
    begin
      CapturarErro(aTrabalho, LMensagem, LCodigo);
      TThread.Queue(nil,
        procedure
        begin
          Finalizar(LMensagem, LCodigo, aAoConcluir);
        end);
    end);
end;

procedure TFormPrincipal.CapturarErro(aTrabalho: TProc; out aMensagem, aCodigo: string);
begin
  aMensagem := '';
  aCodigo := '';
  try
    aTrabalho();
  except
    on E: Exception do
    begin
      aMensagem := E.Message;
      if E is ETarefasApiErro then
        aCodigo := ETarefasApiErro(E).Codigo;
    end;
  end;
end;

{ Executa na thread principal: libera a tela e mostra o erro ou segue o fluxo. }
procedure TFormPrincipal.Finalizar(const aMensagem, aCodigo: string; aAoConcluir: TProc);
begin
  DefinirOcupado(False);
  FConectado := (aMensagem = '') or (aCodigo <> 'API_INDISPONIVEL');
  sbRodape.Invalidate;

  if aMensagem <> '' then
  begin
    MessageDlg(aMensagem, mtError, [mbOK], 0);
    DestacarCampo(aCodigo);
  end
  else if Assigned(aAoConcluir) then
    aAoConcluir();
end;

procedure TFormPrincipal.RestaurarPrevisao;
begin
  dtPrevisao.Date := Date + 1;
  dtPrevisao.Checked := True;
end;

procedure TFormPrincipal.Recarregar;
var
  LLimite, LDeslocamento: Integer;
  LCarga: TCarga;
begin
  { captura na thread principal; a thread de trabalho não toca no estado do presenter }
  LLimite := FPresenter.Limite;
  LDeslocamento := FPresenter.Deslocamento;
  Executar(
    procedure
    begin
      LCarga := FPresenter.Buscar(LLimite, LDeslocamento);
    end,
    procedure
    begin
      FPresenter.Aplicar(LCarga);
      ExibirTarefas;
      ExibirEstatisticas(LCarga.Stats);
      AtualizarBotoes;
    end);
end;

procedure TFormPrincipal.ExibirTarefas;
var
  LTarefa: TTarefa;
  LItem: TListItem;
  LIdSelecionado: Integer;
begin
  LIdSelecionado := 0;
  if lvTarefas.Selected <> nil then
    LIdSelecionado := StrToIntDef(lvTarefas.Selected.Caption, 0);

  lvTarefas.Items.BeginUpdate;
  try
    lvTarefas.Items.Clear;
    for LTarefa in FPresenter.Pagina.Itens do
    begin
      LItem := lvTarefas.Items.Add;
      LItem.Caption := IntToStr(LTarefa.Id);
      LItem.SubItems.Add(LTarefa.Titulo);
      LItem.SubItems.Add(NomePrioridade(LTarefa.Prioridade));
      LItem.SubItems.Add(LTarefa.Status);
      LItem.SubItems.Add(LTarefa.Responsavel);
      LItem.SubItems.Add(FormatarData(LTarefa.DataCriacao));
      LItem.SubItems.Add(FormatarData(LTarefa.DataPrevisaoFinalizacao));
      LItem.SubItems.Add(FormatarData(LTarefa.DataFinalizacao));
      if LTarefa.Id = LIdSelecionado then
        LItem.Selected := True;
    end;
  finally
    lvTarefas.Items.EndUpdate;
  end;

  lblPagina.Caption := FPresenter.TextoPagina;
  lvTarefasResize(nil);
end;

procedure TFormPrincipal.ExibirEstatisticas(const aStats: TEstatisticas);
begin
  lblTotalVal.Caption := IntToStr(aStats.Total);
  lblMediaVal.Caption := FormatFloat('0.00', aStats.MediaPrioridade);
  lblConcVal.Caption := IntToStr(aStats.ConcluidasUltimos7Dias);
end;

procedure TFormPrincipal.DefinirOcupado(aOcupado: Boolean);
begin
  FOcupado := aOcupado;
  if aOcupado then
  begin
    Screen.Cursor := crAppStart;
    sbRodape.Panels[1].Text := FPresenter.UrlBase + '  —  processando...';
  end
  else
  begin
    Screen.Cursor := crDefault;
    sbRodape.Panels[1].Text := FPresenter.UrlBase;
  end;
  AtualizarBotoes;
end;

procedure TFormPrincipal.DestacarCampo(const aCodigo: string);
var
  LCampo: TWinControl;
begin
  if aCodigo.StartsWith('TITULO') then
    LCampo := edTitulo
  else if aCodigo.StartsWith('DESCRICAO') then
    LCampo := mmDescricao
  else if aCodigo.StartsWith('PRIORIDADE') then
    LCampo := cbPrioridade
  else if aCodigo.StartsWith('RESPONSAVEL') then
    LCampo := edResponsavel
  else if aCodigo.StartsWith('DATA_PREVISAO') then
    LCampo := dtPrevisao
  else
    Exit;

  if LCampo.CanFocus then
    LCampo.SetFocus;
end;

procedure TFormPrincipal.AtualizarBotoes;
var
  LTarefa: TTarefa;
  LLivre, LTemSelecao: Boolean;
begin
  LLivre := not FOcupado;
  LTemSelecao := TarefaSelecionada(LTarefa);
  gbNova.Enabled := LLivre;
  btnAtualizar.Enabled := LLivre;
  cbPorPagina.Enabled := LLivre;
  cbStatus.Enabled := LLivre and LTemSelecao;
  btnStatus.Enabled := LLivre and LTemSelecao;
  btnRemover.Enabled := LLivre and LTemSelecao;
  btnAnterior.Enabled := LLivre and FPresenter.TemAnterior;
  btnProxima.Enabled := LLivre and FPresenter.TemProxima;
end;

function TFormPrincipal.TarefaSelecionada(out aTarefa: TTarefa): Boolean;
begin
  if lvTarefas.Selected <> nil then
    Result := FPresenter.TarefaEm(lvTarefas.Selected.Index, aTarefa)
  else
  begin
    aTarefa := Default(TTarefa);
    Result := False;
  end;
end;

procedure TFormPrincipal.edTituloChange(Sender: TObject);
begin
  lblContTitulo.Caption := Format('%d/%d', [Length(edTitulo.Text), TITULO_MAX]);
end;

procedure TFormPrincipal.mmDescricaoChange(Sender: TObject);
begin
  lblContDesc.Caption := Format('%d/%d', [Length(mmDescricao.Text), DESCRICAO_MAX]);
end;

procedure TFormPrincipal.btnAdicionarClick(Sender: TObject);
var
  LTitulo, LDescricao, LResponsavel: string;
  LPrioridade: Integer;
  LPrevisao: TDateTime;
begin
  LTitulo := Trim(edTitulo.Text);
  LDescricao := Trim(mmDescricao.Text);
  LResponsavel := Trim(edResponsavel.Text);
  LPrioridade := cbPrioridade.ItemIndex + 1;
  if dtPrevisao.Checked then
    LPrevisao := dtPrevisao.Date
  else
    LPrevisao := 0;

  if LTitulo = '' then
  begin
    MessageDlg('Informe o título da tarefa.', mtWarning, [mbOK], 0);
    edTitulo.SetFocus;
    Exit;
  end;

  if LResponsavel = '' then
  begin
    MessageDlg('Informe o responsável pela tarefa.', mtWarning, [mbOK], 0);
    edResponsavel.SetFocus;
    Exit;
  end;

  Executar(
    procedure
    begin
      FPresenter.Criar(LTitulo, LDescricao, LPrioridade, LResponsavel, LPrevisao);
    end,
    procedure
    begin
      edTitulo.Clear;
      mmDescricao.Clear;
      edResponsavel.Clear;
      RestaurarPrevisao;
      FPresenter.IrParaPrimeira;
      Recarregar;
    end);
end;

procedure TFormPrincipal.btnAtualizarClick(Sender: TObject);
begin
  Recarregar;
end;

procedure TFormPrincipal.btnStatusClick(Sender: TObject);
var
  LTarefa: TTarefa;
  LId: Integer;
  LStatus: string;
begin
  if not TarefaSelecionada(LTarefa) then
    Exit;
  LId := LTarefa.Id;
  LStatus := cbStatus.Text;
  if LStatus = LTarefa.Status then
  begin
    MessageDlg('A tarefa já está com o status "' + LStatus + '".', mtInformation, [mbOK], 0);
    Exit;
  end;

  Executar(
    procedure
    begin
      FPresenter.AtualizarStatus(LId, LStatus);
    end,
    procedure
    begin
      Recarregar;
    end);
end;

procedure TFormPrincipal.btnRemoverClick(Sender: TObject);
var
  LTarefa: TTarefa;
  LId: Integer;
begin
  if not TarefaSelecionada(LTarefa) then
    Exit;
  if MessageDlg(Format('Remover a tarefa %d - "%s"?', [LTarefa.Id, LTarefa.Titulo]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  LId := LTarefa.Id;

  Executar(
    procedure
    begin
      FPresenter.Remover(LId);
    end,
    procedure
    begin
      Recarregar;
    end);
end;

procedure TFormPrincipal.btnAnteriorClick(Sender: TObject);
begin
  FPresenter.Anterior;
  Recarregar;
end;

procedure TFormPrincipal.btnProximaClick(Sender: TObject);
begin
  FPresenter.Proxima;
  Recarregar;
end;

procedure TFormPrincipal.cbPorPaginaChange(Sender: TObject);
begin
  FPresenter.DefinirLimite(StrToIntDef(cbPorPagina.Text, LIMITE_PADRAO));
  Recarregar;
end;

procedure TFormPrincipal.lvTarefasResize(Sender: TObject);
const
  LARGURA_MINIMA = 110;
var
  LI, LSoma, LLargura: Integer;
begin
  { a última coluna ocupa o espaço que sobrar na largura da lista }
  LSoma := 0;
  for LI := 0 to lvTarefas.Columns.Count - 2 do
    Inc(LSoma, lvTarefas.Columns[LI].Width);
  LLargura := lvTarefas.ClientWidth - LSoma;
  if LLargura < LARGURA_MINIMA then
    LLargura := LARGURA_MINIMA;
  lvTarefas.Columns[lvTarefas.Columns.Count - 1].Width := LLargura;
end;
procedure TFormPrincipal.lvTarefasSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  LTarefa: TTarefa;
  LIndice: Integer;
begin
  if Selected and TarefaSelecionada(LTarefa) then
  begin
    LIndice := cbStatus.Items.IndexOf(LTarefa.Status);
    if LIndice >= 0 then
      cbStatus.ItemIndex := LIndice;
  end;
  AtualizarBotoes;
end;

procedure TFormPrincipal.lvTarefasCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  LStatus: string;
  LCorPonto, LCorFundo, LCorTexto: TColor;
  LR: TRect;
  LMeio: Integer;
begin
  { o Canvas é compartilhado entre as colunas: sempre restaura a fonte padrão }
  Sender.Canvas.Font.Color := clWindowText;
  Sender.Canvas.Font.Style := [];
  if SubItem <> COLUNA_STATUS then
    Exit;

  LStatus := Item.SubItems[2];
  if LStatus = STATUS_CONCLUIDA then
    LCorPonto := COR_CONCLUIDA
  else if LStatus = STATUS_EM_PROGRESSO then
    LCorPonto := COR_EM_PROGRESSO
  else
    LCorPonto := COR_PENDENTE;

  if not ListView_GetSubItemRect(Sender.Handle, Item.Index, SubItem, LVIR_BOUNDS, @LR) then
    Exit;
  Dec(LR.Right);
  Dec(LR.Bottom);

  if cdsSelected in State then
  begin
    LCorFundo := clHighlight;
    LCorTexto := clHighlightText;
  end
  else
  begin
    LCorFundo := clWindow;
    LCorTexto := clWindowText;
  end;

  with Sender.Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := LCorFundo;
    FillRect(LR);
    LMeio := (LR.Top + LR.Bottom) div 2;
    Brush.Color := LCorPonto;
    Pen.Color := LCorPonto;
    Ellipse(LR.Left + 6, LMeio - 4, LR.Left + 15, LMeio + 5);
    Brush.Style := bsClear;
    Font.Color := LCorTexto;
    TextOut(LR.Left + 22, LMeio - TextHeight(LStatus) div 2, LStatus);
  end;
  DefaultDraw := False;
end;
procedure TFormPrincipal.sbRodapeDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel;
  const Rect: TRect);
var
  LTexto: string;
  LCor: TColor;
begin
  if FConectado then
  begin
    LTexto := 'Conectado';
    LCor := COR_CONCLUIDA;
  end
  else
  begin
    LTexto := 'Desconectado';
    LCor := COR_ERRO;
  end;
  with StatusBar.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(Rect);
    Brush.Color := LCor;
    Pen.Color := LCor;
    Ellipse(Rect.Left + 6, Rect.Top + 5, Rect.Left + 15, Rect.Top + 14);
    Brush.Style := bsClear;
    TextOut(Rect.Left + 22, Rect.Top + 2, LTexto);
  end;
end;

end.
