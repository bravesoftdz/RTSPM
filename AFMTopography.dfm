object AFMTopograph: TAFMTopograph
  Left = 0
  Top = 0
  Caption = 'AFM Topography'
  ClientHeight = 624
  ClientWidth = 796
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ForwardImage: TImage
    Left = 21
    Top = 33
    Width = 350
    Height = 350
  end
  object ReverseImage: TImage
    Left = 435
    Top = 33
    Width = 350
    Height = 350
  end
  object Label1: TLabel
    Left = 21
    Top = 8
    Width = 124
    Height = 19
    Caption = 'Forward Image'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 435
    Top = 8
    Width = 123
    Height = 19
    Caption = 'Reverse Image'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Scan_Tube_GroupBox: TGroupBox
    Left = 11
    Top = 427
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
    TabOrder = 0
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
  object ZApproachBar: TProgressBar
    Left = 435
    Top = 399
    Width = 350
    Height = 22
    Hint = 'Z Position of the scan tube'
    Max = 65535
    ParentShowHint = False
    Position = 32768
    Smooth = True
    Step = 8
    ShowHint = True
    TabOrder = 1
  end
  object ScanStartGroupBox: TGroupBox
    Left = 227
    Top = 427
    Width = 311
    Height = 190
    Caption = 'Scan Control'
    Color = clYellow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 2
    object Label3: TLabel
      Left = 16
      Top = 47
      Width = 25
      Height = 13
      Caption = 'Ch. 0'
    end
    object Label4: TLabel
      Left = 65
      Top = 47
      Width = 25
      Height = 13
      Caption = 'Ch. 1'
    end
    object Ch0OutputLabel: TLabel
      Left = 16
      Top = 66
      Width = 15
      Height = 13
      Caption = '0.0'
    end
    object Ch1OutputLabel: TLabel
      Left = 62
      Top = 66
      Width = 15
      Height = 13
      Caption = '0.0'
    end
    object Bevel6: TBevel
      Left = 19
      Top = 126
      Width = 286
      Height = 2
    end
    object Bevel8: TBevel
      Left = 104
      Top = 18
      Width = 2
      Height = 159
    end
    object Label7: TLabel
      Left = 16
      Top = 91
      Width = 48
      Height = 13
      Caption = 'Feedback'
    end
    object FeedbackOutputLabel: TLabel
      Left = 19
      Top = 110
      Width = 15
      Height = 13
      Caption = '0.0'
    end
    object Label5: TLabel
      Left = 112
      Top = 38
      Width = 46
      Height = 13
      Caption = 'Error Sign'
    end
    object Label6: TLabel
      Left = 16
      Top = 20
      Width = 34
      Height = 13
      Caption = 'Signals'
    end
    object PID: TLabel
      Left = 112
      Top = 19
      Width = 74
      Height = 13
      Caption = 'PID Parameters'
    end
    object Bevel4: TBevel
      Left = 212
      Top = 21
      Width = 4
      Height = 107
    end
    object Label11: TLabel
      Left = 228
      Top = 134
      Width = 54
      Height = 13
      Caption = 'Error Signal'
    end
    object ErrorSignalLabel: TLabel
      Left = 228
      Top = 153
      Width = 15
      Height = 13
      Caption = '0.0'
    end
    object Label14: TLabel
      Left = 112
      Top = 85
      Width = 102
      Height = 13
      Caption = 'Feedback period (ms)'
    end
    object SetPointEdit: TLabeledEdit
      Left = 164
      Top = 55
      Width = 42
      Height = 21
      EditLabel.Width = 43
      EditLabel.Height = 13
      EditLabel.Caption = 'Set Point'
      TabOrder = 0
      Text = '3.5'
      OnKeyPress = SetPointEditKeyPress
    end
    object ScanStartBtn: TBitBtn
      Left = 16
      Top = 134
      Width = 74
      Height = 44
      Caption = 'Start scan'
      TabOrder = 1
      OnClick = ScanStartBtnClick
    end
    object EngageFeedbackBtn: TButton
      Left = 112
      Top = 134
      Width = 110
      Height = 41
      Caption = 'Engage Feedback'
      TabOrder = 2
      OnClick = EngageFeedbackBtnClick
    end
    object ErrorCorrectionSpinEdit: TSpinEdit
      Left = 112
      Top = 57
      Width = 45
      Height = 22
      Increment = 2
      MaxValue = 1
      MinValue = -1
      TabOrder = 3
      Value = -1
      OnChange = ErrorCorrectionSpinEditChange
    end
    object PropEdit: TLabeledEdit
      Left = 231
      Top = 24
      Width = 47
      Height = 21
      EditLabel.Width = 56
      EditLabel.Height = 13
      EditLabel.Caption = 'Proportional'
      TabOrder = 4
      Text = '1'
      OnKeyPress = PropEditKeyPress
    end
    object IntEdit: TLabeledEdit
      Left = 231
      Top = 62
      Width = 47
      Height = 21
      EditLabel.Width = 35
      EditLabel.Height = 13
      EditLabel.Caption = 'Integral'
      TabOrder = 5
      Text = '1'
      OnKeyPress = IntEditKeyPress
    end
    object DiffEdit: TLabeledEdit
      Left = 231
      Top = 101
      Width = 47
      Height = 21
      EditLabel.Width = 50
      EditLabel.Height = 13
      EditLabel.Caption = 'Differential'
      TabOrder = 6
      Text = '0'
      OnKeyPress = DiffEditKeyPress
    end
    object FeedbackTimeSpinEdit: TSpinEdit
      Left = 112
      Top = 98
      Width = 62
      Height = 22
      MaxValue = 50
      MinValue = 1
      TabOrder = 7
      Value = 5
      OnChange = FeedbackTimeSpinEditChange
    end
  end
  object GroupBox1: TGroupBox
    Left = 544
    Top = 427
    Width = 241
    Height = 188
    Caption = 'Scan Parameters'
    Color = clRed
    ParentColor = False
    TabOrder = 3
    object Label13: TLabel
      Left = 18
      Top = 17
      Width = 76
      Height = 13
      Caption = 'Scan Resolution'
    end
    object Label15: TLabel
      Left = 16
      Top = 119
      Width = 75
      Height = 13
      Caption = 'Dwell time  (ms)'
    end
    object Label16: TLabel
      Left = 130
      Top = 119
      Width = 46
      Height = 13
      Caption = 'Averages'
    end
    object ScanResolutionComboBox: TComboBox
      Left = 16
      Top = 36
      Width = 114
      Height = 21
      ItemHeight = 13
      TabOrder = 0
      Text = 'Select a scan resolution'
      OnSelect = ScanResolutionComboBoxSelect
      Items.Strings = (
        '128'
        '256'
        '512'
        '1024')
    end
    object ScanRangeEdit: TLabeledEdit
      Left = 14
      Top = 81
      Width = 116
      Height = 21
      EditLabel.Width = 82
      EditLabel.Height = 13
      EditLabel.Caption = 'Scan Range (um)'
      TabOrder = 1
      Text = '1'
      OnKeyPress = ScanRangeEditKeyPress
    end
    object DwellTimeEdit: TSpinEdit
      Left = 16
      Top = 138
      Width = 62
      Height = 22
      MaxValue = 50
      MinValue = 1
      TabOrder = 2
      Value = 5
      OnChange = DwellTimeEditChange
    end
    object AveragesEdit: TSpinEdit
      Left = 130
      Top = 138
      Width = 62
      Height = 22
      MaxValue = 50
      MinValue = 1
      TabOrder = 3
      Value = 5
      OnChange = AveragesEditChange
    end
  end
  object DataTimer: TTimer
    Enabled = False
    OnTimer = DataTimerTimer
    Left = 583
    Top = 32
  end
end
