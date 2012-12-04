object SysConfig: TSysConfig
  Left = 0
  Top = 0
  Caption = 'Scanning Probe Microscope - Global System Configuration'
  ClientHeight = 315
  ClientWidth = 711
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
  object GroupBox4: TGroupBox
    Left = 200
    Top = 18
    Width = 486
    Height = 148
    Caption = 'Analog Input/Output Configuration'
    Color = clTeal
    ParentColor = False
    TabOrder = 3
    object Label5: TLabel
      Left = 15
      Top = 27
      Width = 96
      Height = 13
      Caption = 'Scan tube X  control'
    end
    object Label6: TLabel
      Left = 178
      Top = 27
      Width = 93
      Height = 13
      Caption = 'Scan tube Y control'
    end
    object Label7: TLabel
      Left = 337
      Top = 27
      Width = 93
      Height = 13
      Caption = 'Scan tube Z control'
    end
    object Label8: TLabel
      Left = 15
      Top = 81
      Width = 75
      Height = 13
      Caption = 'Channel 0 input'
    end
    object Label9: TLabel
      Left = 178
      Top = 81
      Width = 75
      Height = 13
      Caption = 'Channel 1 input'
    end
    object Label10: TLabel
      Left = 337
      Top = 81
      Width = 75
      Height = 13
      Caption = 'Channel 2 input'
    end
    object ScanXComboBox: TComboBox
      Left = 15
      Top = 46
      Width = 138
      Height = 21
      ItemHeight = 0
      TabOrder = 0
      Text = 'Choose output channel'
      OnSelect = ScanXComboBoxSelect
    end
    object ScanYComboBox: TComboBox
      Left = 178
      Top = 46
      Width = 138
      Height = 21
      ItemHeight = 0
      TabOrder = 1
      Text = 'Choose output channel'
      OnSelect = ScanYComboBoxSelect
    end
    object ScanZComboBox: TComboBox
      Left = 337
      Top = 46
      Width = 138
      Height = 21
      ItemHeight = 0
      TabOrder = 2
      Text = 'Choose output channel'
      OnSelect = ScanZComboBoxSelect
    end
    object Ch0ComboBox: TComboBox
      Left = 15
      Top = 100
      Width = 138
      Height = 21
      ItemHeight = 0
      TabOrder = 3
      Text = 'Choose input channel'
      OnSelect = Ch0ComboBoxSelect
    end
    object Ch1ComboBox: TComboBox
      Left = 178
      Top = 100
      Width = 138
      Height = 21
      ItemHeight = 0
      TabOrder = 4
      Text = 'Choose input channel'
      OnSelect = Ch1ComboBoxSelect
    end
    object Ch2ComboBox: TComboBox
      Left = 337
      Top = 100
      Width = 138
      Height = 21
      ItemHeight = 0
      TabOrder = 5
      Text = 'Choose input channel'
      OnSelect = Ch2ComboBoxSelect
    end
  end
  object GroupBox1: TGroupBox
    Left = 17
    Top = 205
    Width = 162
    Height = 105
    Caption = 'Lock in amplifier configuration'
    Color = clSilver
    ParentColor = False
    TabOrder = 0
    object Label2: TLabel
      Left = 18
      Top = 72
      Width = 65
      Height = 13
      Caption = 'GPIB Address'
    end
    object LockInGPIBAddressSpinEdit: TSpinEdit
      Left = 92
      Top = 68
      Width = 39
      Height = 22
      MaxValue = 50
      MinValue = 1
      TabOrder = 0
      Value = 12
      OnChange = LockInGPIBAddressSpinEditChange
    end
    object LockInCheckBox: TCheckBox
      Left = 18
      Top = 26
      Width = 130
      Height = 17
      Caption = 'Use Lock in amplifier'
      Checked = True
      State = cbChecked
      TabOrder = 1
      OnClick = LockInCheckBoxClick
    end
  end
  object GroupBox2: TGroupBox
    Left = 17
    Top = 129
    Width = 162
    Height = 70
    Caption = 'Nanosurf PLL Configuration'
    Color = clSilver
    ParentColor = False
    TabOrder = 1
    object NanosurfCheckBox: TCheckBox
      Left = 18
      Top = 26
      Width = 130
      Height = 17
      Caption = 'Use Nanosurf PLL'
      TabOrder = 0
      OnClick = NanosurfCheckBoxClick
    end
  end
  object GroupBox3: TGroupBox
    Left = 17
    Top = 18
    Width = 162
    Height = 105
    Caption = 'Attocube Configuration'
    Color = clSilver
    ParentColor = False
    TabOrder = 2
    object Label4: TLabel
      Left = 18
      Top = 72
      Width = 44
      Height = 13
      Caption = 'Com Port'
    end
    object AttocubeComPortSpinEdit: TSpinEdit
      Left = 92
      Top = 68
      Width = 39
      Height = 22
      MaxValue = 4
      MinValue = 1
      TabOrder = 0
      Value = 2
      OnChange = AttocubeComPortSpinEditChange
    end
    object AttocubeCheckBox: TCheckBox
      Left = 18
      Top = 26
      Width = 130
      Height = 17
      Caption = 'Use Attocube'
      Checked = True
      State = cbChecked
      TabOrder = 1
      OnClick = AttocubeCheckBoxClick
    end
  end
  object ScannerConfigGroupBox: TGroupBox
    Left = 200
    Top = 248
    Width = 486
    Height = 61
    Caption = 'Scanner Configuration File'
    Color = clYellow
    ParentColor = False
    TabOrder = 4
    object ScannerConfigFileLabel: TLabel
      Left = 15
      Top = 31
      Width = 73
      Height = 13
      Caption = 'No file selected'
    end
    object Button1: TButton
      Left = 375
      Top = 21
      Width = 91
      Height = 25
      Caption = 'Select'
      TabOrder = 0
      OnClick = Button1Click
    end
  end
  object GroupBox5: TGroupBox
    Left = 200
    Top = 172
    Width = 316
    Height = 51
    Caption = 'Feedback Channel'
    Color = clRed
    ParentColor = False
    TabOrder = 5
    object FeedbackComboBox: TComboBox
      Left = 15
      Top = 18
      Width = 145
      Height = 21
      ItemHeight = 0
      TabOrder = 0
      Text = 'Choose feedback channel'
      OnSelect = FeedbackComboBoxSelect
    end
    object LogCheckBox: TCheckBox
      Left = 190
      Top = 22
      Width = 97
      Height = 17
      Caption = 'Logarithmic'
      TabOrder = 1
      OnClick = LogCheckBoxClick
    end
  end
  object ScannerFileOpenDialog: TOpenDialog
    Left = 627
    Top = 201
  end
end
