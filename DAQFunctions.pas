unit DAQFunctions;

{$MODE Delphi}

interface
  uses GlobalVariables, daq_comedi_types;

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
function ReadChannel(Channel: Acquisition_channel): real;
function ReadFeedbackChannel: real;
function ReadAveragedFeedbackChannel(NumbReadings:integer): real;

implementation
  uses daq_comedi_functions,  Forms, rtai_comedi_types;


{-----------------------------------------------------------}
procedure DisplayErrorMessage(TheMessage:string);
  begin
    Application.MessageBox(PChar(TheMessage+'.  Configure system!'), 'Error!', 0);
  end;

{-------------------------------------------------------------------------------}
procedure InitializeBoards;

begin
  //Create the three output channels
   get_board_names(board_it,device_names, board_names);
end;
{-------------------------------------------------------------------------------}
procedure ReleaseBoards;
  var i: integer;
begin
   //set scan voltages to 0
   WriteChannel(XAxis, 0);
   WriteChannel(YAxis, 0);
   WriteChannel(ZAxis, 0);
   for i:=0 to MaxBoards-1 do
     begin
       if board_it[i]<>nil then comedi_close(board_it[i]);
       board_it[i]:=nil;
     end;
end;
{------------------------------------------------------------------}
procedure WriteChannel(Channel: Axis; Voltage: double);
  var  data : lsampl_t;
       OutChannel : Acquisition_channel;
begin
  //First convert the voltage into an integer
  data :=  round(((voltage - MinDAQVoltage)/DAQVoltageRange)*MaxBits);
  if Channel=XAxis then
      OutChannel:= ScanXOut
   else if Channel=YAxis then
      OutChannel:= ScanYOut
   else if Channel=ZAxis then
      OutChannel:= ScanZOut;
   comedi_data_write(OutChannel.board_id, OutChannel.subdevice, OutChannel.channel, 0, AREF_DIFF, data);

end;
{------------------------------------------------------------------}
procedure WriteZChannel(Voltage: double);
  var
       data : lsampl_t;
begin
  data :=  round(((voltage - MinDAQVoltage)/DAQVoltageRange)*MaxBits);
  comedi_data_write(ScanZOut.board_id, ScanZOut.subdevice, ScanZOut.channel, 0, AREF_DIFF, data);
end;
{------------------------------------------------------------------}
function ReadChannel(Channel: Acquisition_channel): real;
  var
    j : integer;
    data : Plsampl_t;
begin
  new(data);
  j:= comedi_data_read(Channel.board_id, Channel.subdevice, Channel.channel, 0, AREF_DIFF, data);
  if j>= 0 then
   begin
     ReadChannel:= MinDAQVoltage + (integer(data^)/MaxBits)*DAQVoltageRange;
   end
    else ReadChannel:=0;
  dispose(data);
end;
{----------------------------------------------------------------------}
function ReadFeedbackChannel: real;
  //Fast version of ReadAveragedFeedbackChannel
  var
    j : integer;
    data : Plsampl_t;
    data_read : lsampl_t;
begin
  new(data);
  if InFeedback then
    ReadFeedbackChannel:=AveragedFeedbackReading
   else
    begin
      j:= comedi_data_read(FeedbackChannel.board_id, FeedbackChannel.subdevice, FeedbackChannel.channel, 0, AREF_DIFF, data);
      data_read:=data^;
      if j>= 0 then
        begin
          ReadFeedbackChannel:= MinDAQVoltage + (integer(data^)/MaxBits)*DAQVoltageRange;
        end
       else ReadFeedbackChannel:=0;
    end;
  dispose(data);
end;

{----------------------------------------------------------------------}
function ReadAveragedFeedbackChannel(NumbReadings:integer): real;
  //Averaged version of ReadFeedbackChannel
  var
    sum: longint;
    j,k          : integer;
    data : Plsampl_t;
  begin
    new(data);
    if InFeedback then
      ReadAveragedFeedbackChannel:=AveragedFeedbackReading
     else
      begin
        sum := 0;
        for k:= 0 to NumbReadings-1 do
          begin
            j:= comedi_data_read(FeedbackChannel.board_id, FeedbackChannel.subdevice, FeedbackChannel.channel, 0, AREF_DIFF, data);
            if j>= 0 then sum:=sum+integer(data^);
          end;
        ReadAveragedFeedbackChannel:= MinDAQVoltage + (sum/(NumbReadings*MaxBits))*DAQVoltageRange;
      end;
    dispose(data);
  end;

end.
