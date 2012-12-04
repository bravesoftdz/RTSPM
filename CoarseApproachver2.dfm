object CoarseApproach: TCoarseApproach
  Left = 0
  Top = 0
  Caption = 'Coarse Approach'
  ClientHeight = 614
  ClientWidth = 1138
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 72
    Top = 384
    Width = 497
    Height = 222
  end
  object StaticText1: TStaticText
    Left = 88
    Top = 352
    Width = 179
    Height = 27
    Caption = 'Scan Tube Control'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object ScanMinusX: TBitBtn
    Left = 464
    Top = 408
    Width = 75
    Height = 41
    Caption = '-X'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object CoarseApproachCurve: TChart
    Left = 88
    Top = 48
    Width = 400
    Height = 250
    BackWall.Brush.Color = clWhite
    BackWall.Brush.Style = bsClear
    Title.Text.Strings = (
      'TChart')
    TabOrder = 2
  end
  object ScanMinusZ: TBitBtn
    Left = 464
    Top = 502
    Width = 75
    Height = 41
    Caption = '-Z'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
  end
  object ScanPlusZ: TBitBtn
    Left = 368
    Top = 502
    Width = 75
    Height = 41
    Caption = '+Z'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
  object ScanMinusY: TBitBtn
    Left = 464
    Top = 455
    Width = 75
    Height = 41
    Caption = '-Y'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
  end
  object ScanPlusY: TBitBtn
    Left = 368
    Top = 455
    Width = 75
    Height = 41
    Caption = '+Y'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
  end
  object ScanPlusX: TBitBtn
    Left = 368
    Top = 408
    Width = 75
    Height = 41
    Caption = '+X'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 7
  end
  object StaticText2: TStaticText
    Left = 368
    Top = 385
    Width = 120
    Height = 20
    Caption = 'Step x-y-z motion'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 8
  end
end
