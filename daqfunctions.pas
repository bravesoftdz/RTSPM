unit DAQFunctions;

{$MODE Delphi}

interface
  uses GlobalVariables, daq_comedi_types, daq_comedi_functions;

  var
    ScanXTaskHandle,
    ScanYTaskHandle,
    ScanZTaskHandle,
    ScanXYTaskHandle,
    Ch0TaskHandle,
    Ch1TaskHandle,
    Ch2TaskHandle,
    FeedbackInputTaskHandle
                        : longint;

procedure InitializeBoards;
procedure ReleaseBoards;
procedure WriteChannel(Channel: Axis; Voltage: double);
procedure WriteZChannel(Voltage: double);
function ReadChannel(Channel: String): real;
function ReadFeedbackChannel: real;
function ReadAveragedFeedbackChannel(NumbReadings:integer): real;

implementation
  uses daq_comedi_types, daq_comedi_functions, Forms;
  var
     DAQError : boolean;
     status   : integer;


{-----------------------------------------------------------}
procedure DisplayErrorMessage(TheMessage:string);
  begin
    Application.MessageBox(PChar(TheMessage+'.  Configure system!'), 'Error!');
  end;
{------------------------------------------------------------------------------}
{procedure CreateOutputChannel(var ChannelTaskHandle:longint; Channel:string);
  //Define a task handle for the output
begin
  if Channel='' then DisplayErrorMessage('Output channel invalid')
    else
      begin
        DAQError:=FALSE;
        status:=DAQmxCreateTask('', @ChannelTaskHandle);
        if status=0 then
            status:=DAQmxCreateAOVoltageChan(ChannelTaskHandle, PChar(Channel), '', -10.0, 10.0,
                                               DAQmx_Val_VoltageUnits2_Volts, nil);
        if status<>0 then DisplayErrorMessage('Channel '+Channel+' does not exist');
      end;
end;}
{-------------------------------------------------------------------------------}
{procedure CreateInputChannel(var ChannelTaskHandle:longint; Channel:string);
  //Define a task handle for the output
begin
  if Channel='' then DisplayErrorMessage('Input channel invalid')
    else
      begin
        DAQError:=FALSE;
        status:=DAQmxCreateTask('', @ChannelTaskHandle);
        if status=0 then
            status:=DAQmxCreateAIVoltageChan(ChannelTaskHandle, PChar(Channel), '',DAQmx_Val_InputTermCfg_Diff ,
                                                          -10.0, 10.0,DAQmx_Val_VoltageUnits2_Volts, nil);
        if status<>0 then DisplayErrorMessage('Channel '+Channel+' does not exist');
      end;
end;}
{-------------------------------------------------------------------------------}
procedure InitializeBoards;

begin
  //Get the board names from their Linux descriptors
    get_board_names(board_it, device_names, board_names);
end;
{-------------------------------------------------------------------------------}
procedure ReleaseBoards;
begin
   //set scan voltages to 0
   WriteChannel(XAxis, 0);
   WriteChannel(YAxis, 0);
   WriteChannel(ZAxis, 0);
   {status:=DAQmxClearTask(ScanXTaskHandle);
   status:=DAQmxClearTask(ScanYTaskHandle);
   status:=DAQmxClearTask(ScanZTaskHandle);
   status:=DAQmxClearTask(Ch0TaskHandle);
   status:=DAQmxClearTask(Ch1TaskHandle);
   status:=DAQmxClearTask(Ch2TaskHandle);}
end;
{------------------------------------------------------------------}
procedure WriteChannel(Channel: Axis; Voltage: double);
begin
  if Channel=XAxis then
    status:=DAQmxWriteAnalogScalarF64(ScanXTaskHandle, TRUE, 1.0,
      Voltage, nil)
   else if Channel=YAxis then
    status:=DAQmxWriteAnalogScalarF64(ScanYTaskHandle, TRUE, 1.0,
      Voltage, nil)
   else if Channel=ZAxis then
    status:=DAQmxWriteAnalogScalarF64(ScanZTaskHandle, TRUE, 1.0,
      Voltage, nil);
end;
{------------------------------------------------------------------}
procedure WriteZChannel(Voltage: double);
begin
  status:=DAQmxWriteAnalogScalarF64(ScanZTaskHandle, TRUE, 1.0,
      Voltage, nil);
end;
{------------------------------------------------------------------}
function ReadChannel(Channel: String): real;
  var
    Voltage : double;
begin
  if Channel=Ch0Input then
    status:=DAQmxReadAnalogScalarF64(Ch0TaskHandle, 1.0, @Voltage, nil)
   else if Channel=Ch1Input then
    status:=DAQmxReadAnalogScalarF64(Ch1TaskHandle, 1.0, @Voltage, nil)
   else if Channel=Ch2Input then
    status:=DAQmxReadAnalogScalarF64(Ch2TaskHandle, 1.0, @Voltage, nil);
    if status=0 then ReadChannel:=real(Voltage)else ReadChannel:=0.0;
end;
{----------------------------------------------------------------------}
function ReadFeedbackChannel: real;
  //Fast version of ReadChannel
  var
    Voltage: real;
  begin
    status:=DAQmxReadAnalogScalarF64(FeedbackInputTaskHandle, 1.0, @Voltage, nil);
    if status=0 then
        ReadFeedbackChannel:=Voltage
    else ReadFeedbackChannel:=0.0;
  end;

{----------------------------------------------------------------------}
function ReadAveragedFeedbackChannel(NumbReadings:integer): real;
  //Averaged version of ReadFeedbackChannel
  var
    sum: real;
    ReadArray  : array of double;
    j          : integer;
    SamplesRead   : Longint;
  begin
    SetLength(ReadArray, NumbReadings);
    status:=DAQmxReadAnalogF64(FeedbackInputTaskHandle, NumbReadings, 1.0, DAQmx_Val_GroupByChannel,
       @ReadArray[0], NumbReadings, @SamplesRead, nil);
    if status=0 then
      begin
        sum:=0;
        for j:=0 to NumbReadings-1 do sum:=sum+ReadArray[j];
        ReadAveragedFeedbackChannel:=sum/NumbReadings;
      end
    else ReadAveragedFeedbackChannel:=0.0;
  end;

end.
