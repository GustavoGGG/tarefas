object FormPrincipal: TFormPrincipal
  Left = 0
  Top = 0
  Caption = 'Tarefas - Cliente VCL'
  ClientHeight = 640
  ClientWidth = 900
  Color = clBtnFace
  Constraints.MinHeight = 560
  Constraints.MinWidth = 820
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  TextHeight = 15
  object gpEstatisticas: TGridPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    ColumnCollection = <
      item
        Value = 33.333333333333340000
      end
      item
        Value = 33.333333333333340000
      end
      item
        Value = 33.333333333333330000
      end>
    ControlCollection = <
      item
        Column = 0
        Control = pnlTotal
        Row = 0
      end
      item
        Column = 1
        Control = pnlMedia
        Row = 0
      end
      item
        Column = 2
        Control = pnlConcluidas
        Row = 0
      end>
    RowCollection = <
      item
        Value = 100.000000000000000000
      end>
    TabOrder = 0
    object pnlTotal: TPanel
      AlignWithMargins = True
      Left = 8
      Top = 8
      Width = 284
      Height = 48
      Margins.Left = 8
      Margins.Top = 8
      Margins.Right = 4
      Margins.Bottom = 8
      Align = alClient
      BevelOuter = bvNone
      BorderStyle = bsSingle
      Color = clWindow
      ParentBackground = False
      TabOrder = 0
      object lblTotalTit: TLabel
        Left = 0
        Top = 0
        Width = 91
        Height = 13
        Align = alTop
        Alignment = taCenter
        Caption = 'TOTAL DE TAREFAS'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblTotalVal: TLabel
        Left = 0
        Top = 15
        Width = 12
        Height = 32
        Align = alClient
        Alignment = taCenter
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Segoe UI Light'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
    end
    object pnlMedia: TPanel
      AlignWithMargins = True
      Left = 300
      Top = 8
      Width = 292
      Height = 48
      Margins.Left = 4
      Margins.Top = 8
      Margins.Right = 4
      Margins.Bottom = 8
      Align = alClient
      BevelOuter = bvNone
      BorderStyle = bsSingle
      Color = clWindow
      ParentBackground = False
      TabOrder = 1
      object lblMediaTit: TLabel
        Left = 0
        Top = 0
        Width = 186
        Height = 13
        Align = alTop
        Alignment = taCenter
        Caption = 'M'#201'DIA DE PRIORIDADE (PENDENTES)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblMediaVal: TLabel
        Left = 0
        Top = 15
        Width = 41
        Height = 32
        Align = alClient
        Alignment = taCenter
        Caption = '0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Segoe UI Light'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
    end
    object pnlConcluidas: TPanel
      AlignWithMargins = True
      Left = 600
      Top = 8
      Width = 292
      Height = 48
      Margins.Left = 4
      Margins.Top = 8
      Margins.Right = 8
      Margins.Bottom = 8
      Align = alClient
      BevelOuter = bvNone
      BorderStyle = bsSingle
      Color = clWindow
      ParentBackground = False
      TabOrder = 2
      object lblConcTit: TLabel
        Left = 0
        Top = 0
        Width = 178
        Height = 13
        Align = alTop
        Alignment = taCenter
        Caption = 'CONCLU'#205'DAS NOS '#218'LTIMOS 7 DIAS'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblConcVal: TLabel
        Left = 0
        Top = 15
        Width = 12
        Height = 32
        Align = alClient
        Alignment = taCenter
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Segoe UI Light'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
      end
    end
  end
  object gbNova: TGroupBox
    AlignWithMargins = True
    Left = 8
    Top = 64
    Width = 884
    Height = 176
    Margins.Left = 8
    Margins.Top = 0
    Margins.Right = 8
    Margins.Bottom = 4
    Align = alTop
    Caption = ' Nova tarefa '
    TabOrder = 1
    DesignSize = (
      884
      176)
    object lblTitulo: TLabel
      Left = 12
      Top = 28
      Width = 31
      Height = 15
      Caption = 'T'#237'tulo'
    end
    object lblDescricao: TLabel
      Left = 12
      Top = 58
      Width = 51
      Height = 15
      Caption = 'Descri'#231#227'o'
    end
    object lblPrioridade: TLabel
      Left = 12
      Top = 112
      Width = 54
      Height = 15
      Caption = 'Prioridade'
    end
    object lblResponsavel: TLabel
      Left = 12
      Top = 144
      Width = 65
      Height = 15
      Caption = 'Respons'#225'vel'
    end
    object lblPrevisao: TLabel
      Left = 420
      Top = 144
      Width = 44
      Height = 15
      Caption = 'Previs'#227'o'
    end
    object lblContTitulo: TLabel
      Left = 841
      Top = 28
      Width = 29
      Height = 15
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      Caption = '0/100'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblContDesc: TLabel
      Left = 841
      Top = 58
      Width = 29
      Height = 15
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      Caption = '0/500'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object edTitulo: TEdit
      Left = 84
      Top = 24
      Width = 732
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      MaxLength = 100
      TabOrder = 0
      OnChange = edTituloChange
    end
    object mmDescricao: TMemo
      Left = 84
      Top = 54
      Width = 732
      Height = 48
      Anchors = [akLeft, akTop, akRight]
      MaxLength = 500
      ScrollBars = ssVertical
      TabOrder = 1
      OnChange = mmDescricaoChange
    end
    object cbPrioridade: TComboBox
      Left = 84
      Top = 108
      Width = 160
      Height = 23
      Style = csDropDownList
      TabOrder = 2
    end
    object edResponsavel: TEdit
      Left = 84
      Top = 140
      Width = 320
      Height = 23
      MaxLength = 100
      TabOrder = 3
    end
    object dtPrevisao: TDateTimePicker
      Left = 480
      Top = 140
      Width = 140
      Height = 23
      Date = 46000.000000000000000000
      Time = 0.500000000000000000
      ShowCheckbox = True
      TabOrder = 4
    end
    object btnAdicionar: TButton
      Left = 716
      Top = 138
      Width = 100
      Height = 27
      Anchors = [akTop, akRight]
      Caption = '+ Adicionar'
      TabOrder = 5
      OnClick = btnAdicionarClick
    end
  end
  object pnlBarra: TPanel
    Left = 0
    Top = 244
    Width = 900
    Height = 36
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      900
      36)
    object lblPorPagina: TLabel
      Left = 700
      Top = 11
      Width = 88
      Height = 15
      Anchors = [akTop, akRight]
      Caption = 'Itens por p'#225'gina:'
    end
    object btnAtualizar: TButton
      Left = 8
      Top = 5
      Width = 120
      Height = 26
      Caption = 'Atualizar (F5)'
      TabOrder = 0
      OnClick = btnAtualizarClick
    end
    object cbPorPagina: TComboBox
      Left = 794
      Top = 7
      Width = 90
      Height = 23
      Style = csDropDownList
      Anchors = [akTop, akRight]
      TabOrder = 1
      OnChange = cbPorPaginaChange
      Items.Strings = (
        '10'
        '25'
        '50'
        '100')
    end
  end
  object sbRodape: TStatusBar
    Left = 0
    Top = 621
    Width = 900
    Height = 19
    Panels = <
      item
        Style = psOwnerDraw
        Width = 130
      end
      item
        Width = 50
      end>
    OnDrawPanel = sbRodapeDrawPanel
  end
  object pnlPaginacao: TPanel
    Left = 0
    Top = 585
    Width = 900
    Height = 36
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    object lblPagina: TLabel
      Left = 120
      Top = 11
      Width = 140
      Height = 15
      Alignment = taCenter
      AutoSize = False
      Caption = 'Nenhuma tarefa'
    end
    object btnAnterior: TButton
      Left = 8
      Top = 5
      Width = 100
      Height = 26
      Caption = '< Anterior'
      TabOrder = 0
      OnClick = btnAnteriorClick
    end
    object btnProxima: TButton
      Left = 272
      Top = 5
      Width = 100
      Height = 26
      Caption = 'Pr'#243'xima >'
      TabOrder = 1
      OnClick = btnProximaClick
    end
  end
  object pnlAcoes: TPanel
    Left = 0
    Top = 541
    Width = 900
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 5
    DesignSize = (
      900
      44)
    object lblStatus: TLabel
      Left = 8
      Top = 14
      Width = 32
      Height = 15
      Caption = 'Status'
    end
    object cbStatus: TComboBox
      Left = 56
      Top = 10
      Width = 150
      Height = 23
      Style = csDropDownList
      TabOrder = 0
    end
    object btnStatus: TButton
      Left = 214
      Top = 8
      Width = 120
      Height = 27
      Caption = 'Atualizar status'
      TabOrder = 1
      OnClick = btnStatusClick
    end
    object btnRemover: TButton
      Left = 764
      Top = 8
      Width = 120
      Height = 27
      Anchors = [akTop, akRight]
      Caption = 'Remover (Del)'
      TabOrder = 2
      OnClick = btnRemoverClick
    end
  end
  object lvTarefas: TListView
    AlignWithMargins = True
    Left = 8
    Top = 280
    Width = 884
    Height = 261
    Margins.Left = 8
    Margins.Top = 0
    Margins.Right = 8
    Margins.Bottom = 0
    Align = alClient
    Columns = <
      item
        Caption = 'Id'
      end
      item
        Caption = 'T'#237'tulo'
        Width = 180
      end
      item
        Caption = 'Prioridade'
        Width = 80
      end
      item
        Caption = 'Status'
        Width = 100
      end
      item
        Caption = 'Respons'#225'vel'
        Width = 110
      end
      item
        Caption = 'Criada em'
        Width = 120
      end
      item
        Caption = 'Previs'#227'o'
        Width = 120
      end
      item
        Caption = 'Finalizada em'
        Width = 120
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 3
    ViewStyle = vsReport
    OnCustomDrawSubItem = lvTarefasCustomDrawSubItem
    OnSelectItem = lvTarefasSelectItem
  end
end
