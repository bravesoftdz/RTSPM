object CoarseApproachTool: TCoarseApproachTool
  Left = 305
  Top = 179
  Caption = 'Tip Coarse Approach Tool'
  ClientHeight = 614
  ClientWidth = 661
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label3: TLabel
    Left = 16
    Top = 24
    Width = 25
    Height = 13
    Caption = 'Ch. 0'
  end
  object Label4: TLabel
    Left = 16
    Top = 40
    Width = 15
    Height = 13
    Caption = '0.0'
  end
  object TipSignal: TChart
    Left = 8
    Top = 0
    Width = 651
    Height = 234
    BackWall.Brush.Color = clWhite
    BackWall.Brush.Style = bsClear
    MarginBottom = 2
    MarginTop = 1
    Title.Font.Charset = DEFAULT_CHARSET
    Title.Font.Color = clBlue
    Title.Font.Height = -16
    Title.Font.Name = 'Arial'
    Title.Font.Style = [fsBold]
    Title.Text.Strings = (
      'Tip Approach Signal')
    BottomAxis.Automatic = False
    BottomAxis.AutomaticMaximum = False
    BottomAxis.AutomaticMinimum = False
    BottomAxis.Maximum = 10
    BottomAxis.Minimum = -10
    BottomAxis.Title.Caption = 'Z Position'
    Chart3DPercent = 1
    LeftAxis.Automatic = False
    LeftAxis.AutomaticMaximum = False
    LeftAxis.AutomaticMinimum = False
    LeftAxis.Maximum = 10
    LeftAxis.Minimum = -10
    LeftAxis.MinorTicks.Visible = False
    LeftAxis.TicksInner.Visible = False
    LeftAxis.Title.Caption = 'Feedback Signal'
    Legend.Visible = False
    TopAxis.Grid.Color = clWhite
    TopAxis.Grid.Style = psSolid
    TopAxis.GridCentered = True
    TopAxis.Title.Caption = 'Feedback channel signal'
    TopAxis.Title.Font.Charset = DEFAULT_CHARSET
    TopAxis.Title.Font.Color = clBlack
    TopAxis.Title.Font.Height = -16
    TopAxis.Title.Font.Name = 'Arial'
    TopAxis.Title.Font.Style = []
    View3D = False
    BevelInner = bvLowered
    Color = clWhite
    TabOrder = 1
    object Series1: TFastLineSeries
      Marks.ArrowLength = 8
      Marks.Visible = False
      SeriesColor = clRed
      LinePen.Color = clGreen
      XValues.DateTime = False
      XValues.Name = 'X'
      XValues.Multiplier = 1
      XValues.Order = loAscending
      YValues.DateTime = False
      YValues.Name = 'Y'
      YValues.Multiplier = 1
      YValues.Order = loNone
    end
  end
  object ZApproachBar: TProgressBar
    Left = 8
    Top = 240
    Width = 651
    Height = 22
    Hint = 'Z Position of the scan tube'
    Max = 65535
    ParentShowHint = False
    Position = 32768
    Smooth = True
    Step = 32
    ShowHint = True
    TabOrder = 2
  end
  object SignalControlGroupBox: TGroupBox
    Left = 8
    Top = 268
    Width = 651
    Height = 133
    Caption = 'Coarse Approach'
    Color = clYellow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 3
    object Label1: TLabel
      Left = 16
      Top = 24
      Width = 25
      Height = 13
      Caption = 'Ch. 0'
    end
    object Label2: TLabel
      Left = 64
      Top = 24
      Width = 25
      Height = 13
      Caption = 'Ch. 1'
    end
    object Ch0OutputLabel: TLabel
      Left = 16
      Top = 40
      Width = 15
      Height = 13
      Caption = '0.0'
    end
    object Ch1OutputLabel: TLabel
      Left = 62
      Top = 40
      Width = 15
      Height = 13
      Caption = '0.0'
    end
    object Bevel6: TBevel
      Left = 208
      Top = 17
      Width = 2
      Height = 46
    end
    object Bevel7: TBevel
      Left = 15
      Top = 64
      Width = 347
      Height = 2
    end
    object Bevel8: TBevel
      Left = 377
      Top = 27
      Width = 2
      Height = 46
    end
    object Label5: TLabel
      Left = 302
      Top = 84
      Width = 60
      Height = 13
      Caption = 'Step number'
    end
    object StepNumberLabel: TLabel
      Left = 302
      Top = 100
      Width = 6
      Height = 13
      Caption = '0'
    end
    object Label7: TLabel
      Left = 16
      Top = 72
      Width = 133
      Height = 13
      Caption = 'Feedback Channel Reading'
    end
    object FeedbackOutputLabel: TLabel
      Left = 19
      Top = 91
      Width = 15
      Height = 13
      Caption = '0.0'
    end
    object Label11: TLabel
      Left = 224
      Top = 72
      Width = 43
      Height = 13
      Caption = 'Step size'
    end
    object SetPointEdit: TLabeledEdit
      Left = 224
      Top = 37
      Width = 58
      Height = 21
      EditLabel.Width = 43
      EditLabel.Height = 13
      EditLabel.Caption = 'Set Point'
      TabOrder = 0
      Text = '3.5'
      OnKeyPress = SetPointEditKeyPress
    end
    object ApprCriterionEdit: TLabeledEdit
      Left = 299
      Top = 37
      Width = 63
      Height = 21
      EditLabel.Width = 63
      EditLabel.Height = 13
      EditLabel.Caption = 'App. Criterion'
      TabOrder = 1
      Text = '0.75'
      OnKeyPress = ApprCriterionEditKeyPress
    end
    object UpdateTimeEditBox: TLabeledEdit
      Left = 128
      Top = 37
      Width = 40
      Height = 21
      EditLabel.Width = 76
      EditLabel.Height = 13
      EditLabel.Caption = 'Update time(ms)'
      EditLabel.Color = clYellow
      EditLabel.ParentColor = False
      TabOrder = 2
      Text = '1000'
      OnKeyPress = UpdateTimeEditBoxKeyPress
    end
    object StepByStepBtn: TBitBtn
      Left = 436
      Top = 18
      Width = 191
      Height = 52
      Caption = 'Start Step-by-Step approach'
      TabOrder = 3
      OnClick = StepByStepBtnClick
    end
    object AcquireCurveBtn: TBitBtn
      Left = 436
      Top = 76
      Width = 191
      Height = 44
      Caption = 'Acquire approach curve'
      TabOrder = 4
      OnClick = AcquireCurveBtnClick
    end
    object CoarseApproachStepSizeEdit: TSpinEdit
      Left = 224
      Top = 91
      Width = 45
      Height = 22
      MaxValue = 100
      MinValue = 1
      TabOrder = 5
      Value = 15
      OnChange = CoarseApproachStepSizeEditChange
    end
  end
  object WalkerControlGroupBox: TGroupBox
    Left = 224
    Top = 407
    Width = 435
    Height = 190
    Caption = 'Walker Control'
    Color = clRed
    ParentColor = False
    TabOrder = 0
    TabStop = True
    object Bevel4: TBevel
      Left = 105
      Top = 32
      Width = 1
      Height = 145
    end
    object Bevel5: TBevel
      Left = 233
      Top = 32
      Width = 1
      Height = 145
    end
    object Label13: TLabel
      Left = 120
      Top = 16
      Width = 63
      Height = 13
      Caption = 'Timed motion'
    end
    object Label14: TLabel
      Left = 240
      Top = 13
      Width = 47
      Height = 13
      Caption = 'x-y motion'
    end
    object WalkerStepPlusXBtn: TButton
      Left = 248
      Top = 52
      Width = 75
      Height = 53
      Hint = 'Continuously retract walker'
      Caption = '+X'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = WalkerStepPlusXBtnClick
    end
    object WalkerStepPlusYBtn: TButton
      Left = 248
      Top = 120
      Width = 75
      Height = 49
      Caption = '+Y'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = WalkerStepPlusYBtnClick
    end
    object WalkerRetract: TButton
      Left = 16
      Top = 56
      Width = 75
      Height = 49
      Caption = 'Walker Retr'
      TabOrder = 2
      OnMouseDown = WalkerRetractMouseDown
      OnMouseUp = WalkerRetractMouseUp
    end
    object WalkerStepMinusXBtn: TButton
      Left = 336
      Top = 52
      Width = 75
      Height = 53
      Caption = '-X'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = WalkerStepMinusXBtnClick
    end
    object WalkerMinusYBtn: TButton
      Left = 336
      Top = 120
      Width = 75
      Height = 49
      Caption = '-Y'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      OnClick = WalkerMinusYBtnClick
    end
    object WalkerApproach: TButton
      Left = 16
      Top = 120
      Width = 75
      Height = 49
      Caption = 'Walker Appr'
      TabOrder = 5
      OnMouseDown = WalkerApproachMouseDown
      OnMouseUp = WalkerRetractMouseUp
    end
    object Panel1: TPanel
      Left = 120
      Top = 51
      Width = 97
      Height = 118
      BevelInner = bvLowered
      TabOrder = 6
      object Label6: TLabel
        Left = 8
        Top = 8
        Width = 45
        Height = 13
        Caption = 'Time (ms)'
      end
      object TimedRetracBtn: TButton
        Left = 6
        Top = 54
        Width = 83
        Height = 25
        Caption = 'Timed Retract'
        TabOrder = 0
        OnClick = TimedRetracBtnClick
      end
      object TimedApproachBtn: TButton
        Left = 6
        Top = 85
        Width = 83
        Height = 25
        Caption = 'Timed Approach'
        TabOrder = 1
        OnClick = TimedApproachBtnClick
      end
      object WalkerTimeEdit: TEdit
        Left = 8
        Top = 27
        Width = 65
        Height = 21
        TabOrder = 2
        Text = '50'
        OnKeyPress = WalkerTimeEditKeyPress
      end
    end
  end
  object Scan_Tube_GroupBox: TGroupBox
    Left = 8
    Top = 407
    Width = 210
    Height = 190
    Caption = 'Scan Tube Control'
    Color = clSilver
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 4
    object SetXLabel: TLabel
      Left = 8
      Top = 56
      Width = 26
      Height = 13
      Caption = 'Set X'
    end
    object Label8: TLabel
      Left = 8
      Top = 80
      Width = 26
      Height = 13
      Caption = 'Set Y'
    end
    object Label9: TLabel
      Left = 8
      Top = 104
      Width = 26
      Height = 13
      Caption = 'Set Z'
    end
    object Label10: TLabel
      Left = 16
      Top = 24
      Width = 77
      Height = 13
      Caption = 'Change Position'
    end
    object Bevel1: TBevel
      Left = 121
      Top = 24
      Width = 1
      Height = 105
    end
    object Bevel3: TBevel
      Left = 15
      Top = 128
      Width = 184
      Height = 2
    end
    object Label12: TLabel
      Left = 125
      Top = 24
      Width = 74
      Height = 13
      Caption = 'Current Position'
    end
    object Bevel2: TBevel
      Left = 208
      Top = 24
      Width = 2
      Height = 142
    end
    object SetXEdit: TEdit
      Left = 48
      Top = 52
      Width = 57
      Height = 21
      TabOrder = 0
      Text = '0'
      OnKeyPress = SetXEditKeyPress
    end
    object SetYEdit: TEdit
      Left = 48
      Top = 76
      Width = 57
      Height = 21
      TabOrder = 1
      Text = '0'
      OnKeyPress = SetYEditKeyPress
    end
    object SetZEdit: TEdit
      Left = 48
      Top = 101
      Width = 57
      Height = 21
      TabOrder = 2
      Text = '0'
      OnKeyPress = SetZEditKeyPress
    end
    object StepXEdit: TLabeledEdit
      Left = 9
      Top = 153
      Width = 47
      Height = 21
      EditLabel.Width = 32
      EditLabel.Height = 13
      EditLabel.Caption = 'Step X'
      TabOrder = 3
      Text = '0.1'
      OnKeyPress = StepXEditKeyPress
    end
    object StepYEdit: TLabeledEdit
      Left = 80
      Top = 152
      Width = 47
      Height = 21
      EditLabel.Width = 32
      EditLabel.Height = 13
      EditLabel.Caption = 'Step Y'
      TabOrder = 4
      Text = '0.1'
      OnKeyPress = StepYEditKeyPress
    end
    object StepZEdit: TLabeledEdit
      Left = 155
      Top = 153
      Width = 47
      Height = 21
      EditLabel.Width = 32
      EditLabel.Height = 13
      EditLabel.Caption = 'Step Z'
      TabOrder = 5
      Text = '0.0003'
      OnKeyPress = StepZEditKeyPress
    end
    object XPositionText: TStaticText
      Left = 128
      Top = 56
      Width = 17
      Height = 17
      Caption = 'X: '
      TabOrder = 6
    end
    object ZPositionText: TStaticText
      Left = 128
      Top = 105
      Width = 17
      Height = 17
      Caption = 'Z: '
      TabOrder = 7
    end
    object YPositionText: TStaticText
      Left = 128
      Top = 82
      Width = 17
      Height = 17
      Caption = 'Y: '
      TabOrder = 8
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 595
    Width = 661
    Height = 19
    Panels = <>
    SimpleText = 'Idle'
  end
  object DataTimer: TTimer
    Enabled = False
    OnTimer = DataTimerTimer
    Left = 583
    Top = 32
  end
  object SaveDialog: TSaveDialog
    DefaultExt = '*.txt'
    Filter = 'Text Files|*.TXT;*.txt'
    Left = 259
    Top = 126
  end
  object MainMenu1: TMainMenu
    Left = 498
    Top = 14
    object File1: TMenuItem
      Caption = 'File'
      object SaveApproachCurve1: TMenuItem
        Caption = 'Save Approach Curve'
      end
      object Exit1: TMenuItem
        Caption = 'Exit'
      end
    end
  end
end
