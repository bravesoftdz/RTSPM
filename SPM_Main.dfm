object SPM_MainForm: TSPM_MainForm
  Left = 388
  Top = 275
  Caption = 'Scanning Probe Microscope-Main Panel'
  ClientHeight = 169
  ClientWidth = 461
  Color = clBtnFace
  DefaultMonitor = dmMainForm
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 40
    Top = 104
    Width = 385
    Height = 9
  end
  object Label1: TLabel
    Left = 24
    Top = 5
    Width = 32
    Height = 13
    Caption = 'Label1'
    Visible = False
  end
  object Label2: TLabel
    Left = 209
    Top = 5
    Width = 32
    Height = 13
    Caption = 'Label2'
    Visible = False
  end
  object Label3: TLabel
    Left = 361
    Top = 5
    Width = 32
    Height = 13
    Caption = 'Label3'
    Visible = False
  end
  object CoarseApproachBtn: TBitBtn
    Left = 24
    Top = 24
    Width = 129
    Height = 25
    Caption = 'Coarse Approach Tool'
    TabOrder = 0
    OnClick = CoarseApproachBtnClick
  end
  object AFMBtn: TBitBtn
    Left = 168
    Top = 24
    Width = 129
    Height = 25
    Caption = 'AFM'
    TabOrder = 1
    OnClick = AFMBtnClick
  end
  object STMBtn: TBitBtn
    Left = 304
    Top = 24
    Width = 129
    Height = 25
    Caption = 'STM'
    TabOrder = 2
  end
  object MFM_Lift_Btn: TBitBtn
    Left = 24
    Top = 64
    Width = 129
    Height = 25
    Caption = 'MFM Lift Phase mode'
    TabOrder = 3
  end
  object PIDTuning_Btn: TBitBtn
    Left = 168
    Top = 64
    Width = 129
    Height = 25
    Caption = 'PID Tuning'
    TabOrder = 4
  end
  object EFM_Btn: TBitBtn
    Left = 304
    Top = 64
    Width = 129
    Height = 25
    Caption = 'EFM phase mode'
    TabOrder = 5
  end
  object ExitProgram: TBitBtn
    Left = 256
    Top = 119
    Width = 137
    Height = 32
    Caption = 'Exit'
    TabOrder = 6
  end
  object SystemConfiguration: TBitBtn
    Left = 64
    Top = 119
    Width = 137
    Height = 32
    Caption = 'System Configuration'
    TabOrder = 7
    OnClick = SystemConfigurationClick
  end
  object AttocubeComPort: TComPort
    BaudRate = br9600
    Port = 'COM1'
    Parity.Bits = prNone
    StopBits = sbOneStopBit
    DataBits = dbEight
    Events = [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full]
    FlowControl.OutCTSFlow = False
    FlowControl.OutDSRFlow = False
    FlowControl.ControlDTR = dtrDisable
    FlowControl.ControlRTS = rtsDisable
    FlowControl.XonXoffOut = False
    FlowControl.XonXoffIn = False
    Left = 413
    Top = 123
  end
  object FeedbackTimer: TMultimediaTimer
    Resolution = 1
    OnTimer = FeedbackTimerTimer
    Left = 20
    Top = 121
  end
end
