unit SystemConfiguration;

{$MODE Delphi}
//{$mode objfpc}{$H+}

interface

uses
  {$IFNDEF LCL} Windows, Messages, {$ELSE} LclIntf, LMessages, LclType, {$ENDIF}
  SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, LResources, ExtCtrls;

type

  { TSysConfig }

  TSysConfig = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox6: TGroupBox;
    Device1Edit: TLabeledEdit;
    Device3Edit: TLabeledEdit;
    Device2Edit: TLabeledEdit;
    GroupBox7: TGroupBox;
    LockInGPIBAddressSpinEdit: TSpinEdit;
    Label2: TLabel;
    LockInCheckBox: TCheckBox;
    GroupBox2: TGroupBox;
    NanosurfCheckBox: TCheckBox;
    GroupBox3: TGroupBox;
    Label4: TLabel;
    AttocubeComPortSpinEdit: TSpinEdit;
    AttocubeCheckBox: TCheckBox;
    GroupBox4: TGroupBox;
    ScanXComboBox: TComboBox;
    Label5: TLabel;
    ScanYComboBox: TComboBox;
    Label6: TLabel;
    Label7: TLabel;
    ScanZComboBox: TComboBox;
    Ch0ComboBox: TComboBox;
    Ch1ComboBox: TComboBox;
    Ch2ComboBox: TComboBox;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    ScannerConfigGroupBox: TGroupBox;
    Button1: TButton;
    ScannerConfigFileLabel: TLabel;
    ScannerFileOpenDialog: TOpenDialog;
    GroupBox5: TGroupBox;
    FeedbackComboBox: TComboBox;
    LogCheckBox: TCheckBox;
    SampleVoltageComboBox: TComboBox;
    procedure LogCheckBoxClick(Sender: TObject);
    procedure FeedbackComboBoxSelect(Sender: TObject);
    procedure Ch2ComboBoxSelect(Sender: TObject);
    procedure Ch1ComboBoxSelect(Sender: TObject);
    procedure Ch0ComboBoxSelect(Sender: TObject);
    procedure SampleVoltageComboBoxSelect(Sender: TObject);
    procedure ScanZComboBoxSelect(Sender: TObject);
    procedure ScanYComboBoxSelect(Sender: TObject);
    procedure ScanXComboBoxSelect(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure LockInGPIBAddressSpinEditChange(Sender: TObject);
    procedure AttocubeComPortSpinEditChange(Sender: TObject);
    procedure LockInCheckBoxClick(Sender: TObject);
    procedure NanosurfCheckBoxClick(Sender: TObject);
    procedure AttocubeCheckBoxClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SysConfig: TSysConfig;

implementation

{$IFNDEF LCL}
{$R *.dfm}
{$ELSE}
{$R *.lfm}
{$ENDIF}
uses GlobalVariables, FileFunctions, daq_comedi_functions, daq_comedi_types, rtai_comedi_types, SPM_Main,
     AttocubeFunctions;

var
   OutputChannelNames     : TStringList;
   InputChannelNames      : TStringList;
   SomethingChanged       : boolean=FALSE;

procedure TSysConfig.AttocubeCheckBoxClick(Sender: TObject);
begin
  if AttocubeCheckBox.State=cbChecked then begin
    UseAttocube:=TRUE;
    InitializeAttocube;
  end
    else UseAttocube:=FALSE;
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.AttocubeComPortSpinEditChange(Sender: TObject);
begin
  AttoCubeComPortNumber:=AttoCubeComPortSpinEdit.Value;
  SPM_MainForm.AttocubeComPort.Device:='/dev/ttyS'+IntToStr(AttocubeComPortNumber-1);
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.Button1Click(Sender: TObject);
begin
  ScannerFileOpenDialog.Execute;
  ScannerConfig_File:=ScannerFileOpenDialog.FileName;
  ScannerConfigFileLabel.Caption:=ScannerConfig_File;
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.Ch0ComboBoxSelect(Sender: TObject);
begin
  Ch0InputName:=Ch0ComboBox.Text;
  Ch0Input:=InputChannels[Ch0ComboBox.ItemIndex];
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.SampleVoltageComboBoxSelect(Sender: TObject);
begin
  SampleVoltageChannelName:=SampleVoltageComboBox.Text;
  SampleVoltageChannel:=OutputChannels[SampleVoltageComboBox.ItemIndex];
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.Ch1ComboBoxSelect(Sender: TObject);
begin
  Ch1InputName:=Ch1ComboBox.Text;
  Ch1Input:=InputChannels[Ch1ComboBox.ItemIndex];
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.Ch2ComboBoxSelect(Sender: TObject);
begin
  Ch2InputName:=Ch2ComboBox.Text;
  Ch2Input:=InputChannels[Ch2ComboBox.ItemIndex];
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.FeedbackComboBoxSelect(Sender: TObject);
begin
  FeedbackChannelName:=FeedbackComboBox.Text;
  FeedbackChannel:=InputChannels[FeedbackComboBox.ItemIndex];
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //Define the various channels
  //first output channels
  if ScanXComboBox.ItemIndex>=0 then ScanXOut:=OutputChannels[ScanXComboBox.ItemIndex];
  if ScanYComboBox.ItemIndex>=0 then ScanYOut:=OutputChannels[ScanYComboBox.ItemIndex];
  if ScanZComboBox.ItemIndex>=0 then ScanZOut:=OutputChannels[ScanZComboBox.ItemIndex];
  if ScanZComboBox.ItemIndex>=0 then ControlChannel:=OutputChannels[ScanZComboBox.ItemIndex];
  if SampleVoltageComboBox.ItemIndex>=0 then SampleVoltageChannel:=OutputChannels[SampleVoltageComboBox.ItemIndex];

  //then input channels
  if Ch0ComboBox.ItemIndex>=0 then Ch0Input:=InputChannels[Ch0ComboBox.ItemIndex];
  if Ch1ComboBox.ItemIndex>=0 then Ch1Input:=InputChannels[Ch1ComboBox.ItemIndex];
  if Ch2ComboBox.ItemIndex>=0 then Ch2Input:=InputChannels[Ch2ComboBox.ItemIndex];
  if Ch0ComboBox.ItemIndex>=0 then FeedbackChannel:=InputChannels[Ch0ComboBox.ItemIndex];

  OutputChannelNames.Destroy;
  InputChannelNames.Destroy;
  if SomethingChanged then WriteSysConfigFile;

  //If this is the first time the program has been started, enable the other
  //buttons on the SPM_Main Window
  if StartingUpProgram then
    begin
      StartingUpProgram:=FALSE;
      SPM_MainForm.CoarseApproachBtn.Enabled:=TRUE;
      SPM_MainForm.AFMBtn.Enabled:=TRUE;
      SPM_MainForm.EFM_Btn.Enabled:=TRUE;
      SPM_MainForm.STMBtn.Enabled:=TRUE;
      SPM_MainForm.MFM_Lift_Btn.Enabled:=TRUE;
      SPM_MainForm.Oscilloscope_Btn.Enabled:=TRUE;
    end;
end;

procedure TSysConfig.FormShow(Sender: TObject);
var
  n_subdevices, subdevtype, n_chans : longint;
  type_str      : string;
  i,j,k,
  InputChannelIndex,
  OutputChannelIndex
             : integer;

begin

//  initialize the values of the three instrument boxes
// If the system configuration file exists, then read the parameters from that
   if FileExists(SysConfig_File) then ReadSysConfigFile
     else WriteSysConfigFile; //using default values
   if UseAttocube then
            AttocubeCheckBox.State:=cbChecked else AttocubeCheckBox.State:=cbUnChecked;
   AttocubeComPortSpinEdit.Value:=AttocubeComPortNumber;
   SPM_MainForm.AttocubeComPort.Device:='/dev/ttyS'+IntToStr(AttocubeComPortNumber-1);
   if UseNanosurf then
            NanosurfCheckBox.State:=cbChecked else NanosurfCheckBox.State:=cbUnChecked;
   if UseLockIn then
            LockInCheckBox.State:=cbChecked else LockinCheckBox.State:=cbUnChecked;
   LockInGPIBAddressSpinEdit.Value:=LockInGPIBAddress;

   if Logarithmic=1 then
            LogCheckBox.State:=cbChecked else LogCheckBox.State:=cbUnChecked;

   //Now get information about what boards and channels are available
   OutputChannelNames:=TStringList.Create;
   InputChannelNames:=TStringList.Create;
   //OutputChannelNames.Clear;
   //InputChannelNames.Clear;

   //Fill in the Editboxes that refer to the DAQ card names at the bottom of the form
   //Change the background color from red to green if the card is present
   if MaxBoards > 2   then Device3Edit.Text:=device_names[2];
   if MaxBoards > 1   then Device2Edit.Text:=device_names[1];
   if MaxBoards > 0   then Device1Edit.Text:=device_names[0];
   //Now check to see if the boards are actually there
   get_board_names(board_it,device_names, board_names);

   //if the board was not present, then its corresponding board_it should still be nil
   if board_it[2]<>nil then Device3Edit.Color:=clGreen;
   if board_it[1]<>nil then Device2Edit.Color:=clGreen;
   if board_it[0]<>nil then Device1Edit.Color:=clGreen;

   //Fill both the input and output channel list
   InputChannelIndex:=0;
   OutputChannelIndex:=0;
   for i:=0 to MaxBoards-1 do
      begin
      if (board_it[i] <> nil) then  //board is present
        begin
           //check to see whether we have an analog input device
           //first check the number of subdevices
           n_subdevices:=comedi_get_n_subdevices(board_it[i]);
           for j:=0 to n_subdevices-1 do
             begin
               subdevtype:=comedi_get_subdevice_type(board_it[i], j);
               if subdevtype<MaxDevTypes-1 then
                 begin
                   type_str:=subdevice_types[subdevtype];
                   //First if it is an analog input channel
                   if type_str = 'ai' then
                     begin
                      n_chans:=comedi_get_n_channels(board_it[i],j);
                      for k:=0 to (n_chans div 2)-1 do  //note we have div 2 because of diff input
                        begin
                         InputChannelNames.Add(board_names[i]+'/'+type_str+IntToStr(k));
                         InputChannels[InputChannelIndex].boardname:= board_names[i];
                         InputChannels[InputChannelIndex].devicename:= device_names[i];
                         InputChannels[InputChannelIndex].board_id := board_it[i];
                         InputChannels[InputChannelIndex].board_number := i;
                         InputChannels[InputChannelIndex].subdevice := j;
                         InputChannels[InputChannelIndex].channel := k;
                         Inc(InputChannelIndex);
                        end;
                     end;
                   //or an analog output channel
                   if type_str = 'ao' then
                     begin
                      n_chans:=comedi_get_n_channels(board_it[i],j);
                      for k:=0 to n_chans-1 do
                        begin
                         OutputChannelNames.Add(board_names[i]+'/'+type_str+IntToStr(k));
                         OutputChannels[OutputChannelIndex].boardname:= board_names[i];
                         OutputChannels[OutputChannelIndex].devicename:= device_names[i];
                         OutputChannels[OutputChannelIndex].board_id := board_it[i];
                         OutputChannels[OutputChannelIndex].board_number := i;
                         OutputChannels[OutputChannelIndex].subdevice := j;
                         OutputChannels[OutputChannelIndex].channel := k;
                         Inc(OutputChannelIndex);
                        end;
                     end;

                 end;
             end;
        end;
    end;

   ScanXComboBox.Items:=OutputChannelNames;
   ScanYComboBox.Items:=OutputChannelNames;
   ScanZComboBox.Items:=OutputChannelNames;
   SampleVoltageComboBox.Items:=OutputChannelNames;

   //Populate the combo boxes from the values already assigned
   ScanXComboBox.ItemIndex:=ScanXComboBox.Items.IndexOf(ScanXOutName);
   if ScanXComboBox.ItemIndex>=0 then
                   ScanXOut:=OutputChannels[ScanXComboBox.ItemIndex];

   ScanYComboBox.ItemIndex:=ScanYComboBox.Items.IndexOf(ScanYOutName);
   if ScanYComboBox.ItemIndex>=0 then
                   ScanYOut:=OutputChannels[ScanYComboBox.ItemIndex];

   ScanZComboBox.ItemIndex:=ScanZComboBox.Items.IndexOf(ScanZOutName);
   if ScanZComboBox.ItemIndex>=0 then
                   ScanZOut:=OutputChannels[ScanZComboBox.ItemIndex];

   SampleVoltageComboBox.ItemIndex:=SampleVoltageComboBox.Items.IndexOf(SampleVoltageChannelName);

   //Need to put in correction here so that it is not mixed with XYZ channels!!!!!
   if SampleVoltageComboBox.ItemIndex>=0 then
       SampleVoltageChannel:=OutputChannels[SampleVoltageComboBox.ItemIndex]
    else SampleVoltageChannelName:='';

   Ch0ComboBox.Items:=InputChannelNames;
   Ch1ComboBox.Items:=InputChannelNames;
   Ch2ComboBox.Items:=InputChannelNames;
   FeedbackComboBox.Items:=InputChannelNames;

   //Populate the combo boxes from the values already assigned
   Ch0ComboBox.ItemIndex:=Ch0ComboBox.Items.IndexOf(Ch0InputName);
   k:=Ch0ComboBox.ItemIndex;
   if Ch0ComboBox.ItemIndex>=0 then
                   Ch0Input:=InputChannels[Ch0ComboBox.ItemIndex];

   Ch1ComboBox.ItemIndex:=Ch1ComboBox.Items.IndexOf(Ch1InputName);
   if Ch1ComboBox.ItemIndex>=0 then
                   Ch1Input:=InputChannels[Ch1ComboBox.ItemIndex];

   Ch2ComboBox.ItemIndex:=Ch2ComboBox.Items.IndexOf(Ch2InputName);
   if Ch2ComboBox.ItemIndex>=0 then
                   Ch2Input:=InputChannels[Ch2ComboBox.ItemIndex];

   FeedbackComboBox.ItemIndex:=FeedbackComboBox.Items.IndexOf(FeedbackChannelName);
   if FeedbackComboBox.ItemIndex>=0 then
                   FeedbackChannel:=InputChannels[FeedbackComboBox.ItemIndex];

   ScannerConfigFileLabel.Caption:=ScannerConfig_file;

   SomethingChanged:=FALSE;

end;

procedure TSysConfig.LockInCheckBoxClick(Sender: TObject);
begin
  if LockInCheckBox.State=cbChecked then UseLockIn:=TRUE else UseLockIn:=FALSE;
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.LockInGPIBAddressSpinEditChange(Sender: TObject);
begin
 LockInGPIBAddress:=LockInGPIBAddressSpinEdit.Value;
 SomethingChanged:=TRUE;
end;

procedure TSysConfig.LogCheckBoxClick(Sender: TObject);
begin
  if LogCheckBox.State=cbChecked then Logarithmic:=1 else Logarithmic:=0;
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.NanosurfCheckBoxClick(Sender: TObject);
begin
  if NanosurfCheckBox.State=cbChecked then UseNanosurf:=TRUE else UseNanosurf:=FALSE;
  SomethingChanged:=TRUE;
end;


procedure TSysConfig.ScanXComboBoxSelect(Sender: TObject);
begin
  ScanXOutName:=ScanXComboBox.Text;
  ScanXOut:=OutputChannels[ScanXComboBox.ItemIndex];
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.ScanYComboBoxSelect(Sender: TObject);
begin
  ScanYOutName:=ScanYComboBox.Text;
  ScanYOut:=OutputChannels[ScanYComboBox.ItemIndex];
  SomethingChanged:=TRUE;
end;

procedure TSysConfig.ScanZComboBoxSelect(Sender: TObject);
begin
  ScanZOutName:=ScanZComboBox.Text;
  ScanZOut:=OutputChannels[ScanZComboBox.ItemIndex];
  ControlChannel:=OutputChannels[ScanZComboBox.ItemIndex];
  SomethingChanged:=TRUE;
end;

initialization
  {$I SystemConfiguration.lrs}
  //{$i SystemConfiguration.lrs}
  //{$i SystemConfiguration.lrs}
  //{$i SystemConfiguration.lrs}
  //OutputChannelNames:=TStringList.Create;
  //InputChannelNames:=TStringList.Create;

finalization
  //OutputChannelNames.Destroy;
  //InputChannelNames.Destroy;

end.
