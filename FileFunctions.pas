unit FileFunctions;

{$MODE Delphi}

interface
 uses GlobalVariables;

var
  PathName : string = 'c:\spm\';
  SysConfig_file      : string= 'spm_parameters.cfg';
  ScannerConfig_file  : string= 'default.scn';
  WinDir                : array[0..255] of char;
  SystemDir             : array[0..255] of char;
  ProgramDir            : string;
  CurrentDirectory      : string;
  ConfigDirectory       : string; //directory with configuration files

procedure ReadSysConfigFile;
procedure WriteSysConfigFile;
procedure ReadScannerFile;
procedure WriteGwyddionSimpleFieldFile( FileName,    //obvious
                                        Title: string; //Title of plot
                                        XRes, YRes  : integer; //resolution of the scan
                                        XReal, YReal : real; //horizontal and vertical size in um
                                        XYUnits, ZUnits : string; //units of XY and Z with no prefix, e.g., m for meters
                                        DataArray: TXYData  //the actual data to be written..dimensions should match!
                                        );
 procedure WriteTextDataFile( FileName,    //obvious
                                         Title: string; //Title of plot
                                         XRes, YRes  : integer; //resolution of the scan
                                         XReal, YReal : real; //horizontal and vertical size in um
                                         XYUnits, ZUnits : string; //units of XY and Z with no prefix, e.g., m for meters
                                         DataArray: TXYData  //the actual data to be written..dimensions should match!
                                         );

function BlankorTabPosition(InputString:string):integer;
function CommaPosition(InputString:string):integer;
function ColonOrDashPosition(InputString:string):integer;

procedure ReadFreeFormLineValue(var F: TextFile; var RealValue: real); overload;
procedure ReadFreeFormLineValue(var F: TextFile; var IntValue: integer); overload;
procedure ReadFreeFormLineValue(var F: TextFile; var read_string:string); overload;
function ReadFirstString(read_string: string): string;
function StripFirstString(read_string:string): string;
function ReadStringWithComma(read_string: string): string;
function StripStringWithComma(read_string:string): string;
function ReadStringWithColon(read_string: string): string;
function StripStringWithColon(read_string:string): string;

implementation
 uses  SysUtils, Forms, rtai_comedi_types, SPM_Main;


 procedure WriteTextDataFile( FileName,    //obvious
                                         Title: string; //Title of plot
                                         XRes, YRes  : integer; //resolution of the scan
                                         XReal, YReal : real; //horizontal and vertical size in um
                                         XYUnits, ZUnits : string; //units of XY and Z with no prefix, e.g., m for meters
                                         DataArray: TXYData  //the actual data to be written..dimensions should match!
                                         );

 var
   TextFileVersion: TextFile;
   i, j    : integer;

 begin
   AssignFile(TextFileVersion, FileName);
   Rewrite(TextFileVersion);
   //First write the magic file header
   //Note that writeln on Linux systesms does not write the CR character, so we are ok
   writeln(TextFileVersion, 'SPM Text Data File');
   //next the date
   writeln(TextFileVersion, 'Date = '+DateTimeToStr(Now));
   //title
   writeln(TextFileVersion, 'Title = '+Title);
   //XRes
   writeln(TextFileVersion, 'XRes = '+IntToStr(XRes));
   //YRes
   writeln(TextFileVersion, 'YRes = '+IntToStr(YRes));
   //XYUnits and ZUnits
   writeln(TextFileVersion, 'XYUnits = '+XYUnits);
   writeln(TextFileVersion, 'ZUnits = '+ZUnits);
   //XReal and YReal
   writeln(TextFileVersion, 'XReal = '+FloatToStrF(XReal, ffExponent, 10, 4));
   writeln(TextFileVersion, 'YReal = '+FloatToStrF(YReal, ffExponent, 10, 4));
   //one line buffer before the real data
   writeln(TextFileVersion, '***DATA***');
   //now write the data
   for j:=0 to YRes-1 do
     for i:=0 to XRes-1 do
       writeln(TextFileVersion, DataArray[i,j]);

   //close the file and we are done!
   CloseFile(TextFileVersion);


 end;

 procedure WriteGwyddionSimpleFieldFile( FileName,    //obvious
                                         Title: string; //Title of plot
                                         XRes, YRes  : integer; //resolution of the scan
                                         XReal, YReal : real; //horizontal and vertical size in um
                                         XYUnits, ZUnits : string; //units of XY and Z with no prefix, e.g., m for meters
                                         DataArray: TXYData  //the actual data to be written..dimensions should match!
                                         );

 var
   TextFileVersion: TextFile;
   BinaryFileVersion: file;
   SizeOfFile, NBuf,
   i, j    : integer;
   Value   : single;
   StringValue : string;
   SingleByteBuf: Byte;

 begin
   AssignFile(TextFileVersion, FileName);
   Rewrite(TextFileVersion);
   //First write the magic file header
   //Note that writeln on Linux systesms does not write the CR character, so we are ok
   writeln(TextFileVersion, 'Gwyddion Simple Field 1.0');
   //next the date
   writeln(TextFileVersion, 'Date = '+DateTimeToStr(Now));
   //title
   writeln(TextFileVersion, 'Title = '+Title);
   //XRes
   writeln(TextFileVersion, 'XRes = '+IntToStr(XRes));
   //YRes
   writeln(TextFileVersion, 'YRes = '+IntToStr(YRes));
   //XYUnits and ZUnits
   writeln(TextFileVersion, 'XYUnits = '+XYUnits);
   writeln(TextFileVersion, 'ZUnits = '+ZUnits);
   //XReal and YReal
   writeln(TextFileVersion, 'XReal = '+FloatToStrF(XReal*1E-6, ffExponent, 10, 4));
   writeln(TextFileVersion, 'YReal = '+FloatToStrF(YReal*1E-6, ffExponent, 10, 4));

   //since the rest of the file needs to be written in binary format, with a buffer of NUL
   //characters, we now close the file, open it again as a binary file, and determine the file size
   CloseFile(TextFileVersion);
   AssignFile(BinaryFileVersion, Filename);
   Rewrite(BinaryFileVersion, 1); //one byte writes
   SizeOfFile:=FileSize(BinaryFileVersion);
   //Determine the number of NUL characters we must write;
   NBuf:=4 - (SizeOfFile mod 4);
   //set the position to the end of the file
   seek(BinaryFileVersion, SizeOfFile);
   //write NBuf NUL characters, as per Gwyddion gsf specification
   for i:=0 to NBuf-1 do
     begin
       SingleByteBuf:=Byte(Chr(0));
       BlockWrite(BinaryFileVersion, SingleByteBuf,1);
     end;

   //now write the data
   for j:=0 to YRes-1 do
     for i:=0 to XRes-1 do
       begin
         //This is a hack so we can write single values to the data file
         StringValue:=FloatToStr(1.0E-9*DataArray[i,j]);
         Value:=StrToFloat(StringValue);
         BlockWrite(BinaryFileVersion, Value, 4);
       end;

   //close the file and we are done!
   CloseFile(BinaryFileVersion);


 end;
{--------------------------------------------------------------------------}
procedure ReadScannerFile;
var
  Scanner_file: TextFile;
  read_string, TempString: string;
  command_string, ValueString: string;
  j: integer;
  Value : double;

begin
  //Read the scanner file, if it exists
  if FileExists(ScannerConfig_file) then
    begin
      //Assign the file name and reset to the top
      AssignFile(Scanner_file, ScannerConfig_file);
      reset(Scanner_file);

      //Now starting reading the file.  If the first character is a
      //hash (#), ignore the line
      while not eof(Scanner_file) do
        begin
          readln(Scanner_file, TempString);
          if  (TempString<>'') then
            begin
              if TempString[1]<>'#' then  //the line is not a comment
                begin
                  read_string:=Trim(TempString); //strip leading and trailing spaces
                  //read the first part before the colon
                  command_string:=LowerCase(ReadStringWithColon(read_string));
                  //Now, depending on what was read, we do different things
                  if command_string = 'scanner' then
                    ScannerName:=StripStringWithColon(read_string)

                   else if command_string = 'z piezo range' then
                    //in this case, we need to read two parameters from the line
                    begin
                      TempString:=StripStringWithColon(read_string);
                      ZPiezoRange:=StrToFloat(ReadFirstString(TempString));
                      TempString:=StripFirstString(TempString);
                      ZPiezoVRange:=StrToFloat(TempString);
                      ZAxisMicronsToVoltage:=ZPiezoVRange/ZPiezoRange;
                      MaxZPosition:=ZPiezoRange/2;
                      MinZPosition:=-MaxZPosition;
                      MaxZVoltage:=-(AmplifierGainSign*ZPiezoVRange)/2;
                      Value:=MaxZVoltage; //this is simply a diagnostic, since we can't debug MaxZVoltage directly
                      MinZVoltage:=-MaxZVoltage;
                      Value:=MinZVoltage;

                    end

                   else if command_string = 'number of xy ranges' then
                    //read the number of ranges and their parameters
                    begin
                      NumberOfScanRanges:=StrToInt(StripStringWithColon(read_string));
                      //Now read the range parameters for each of the ranges
                      ScanRangeStringList.Clear;  //Clear the string list
                      for j:=0 to NumberOfScanRanges-1 do
                        begin
                          readln(Scanner_file, read_string);
                          TempString:=StripStringWithColon(read_string);
                          ValueString:=ReadFirstString(TempString);
                          ScanRanges[j].Range:= StrToFloat(ValueString);
                          ScanRanges[j].Description:=ValueString  + ' um';
                          ScanRangeStringList.Add(ScanRanges[j].Description);
                          TempString:=StripFirstString(TempString);
                          ScanRanges[j].Voltage:=StrToFloat(TempString);
                        end;
                    end

                   else if command_string = 'x hysteresis' then
                    //read the x-range hysteresis parameters
                    begin
                      for j:=0 to NumberOfScanRanges-1 do
                        begin
                          //read the next line, this corresponds to the up scan
                          readln(Scanner_file, read_string);
                          TempString:=StripStringWithColon(read_string);
                          ValueString:=ReadFirstString(TempString);
                          UpScanXFactors[j].A:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          ValueString:=ReadFirstString(TempString);
                          UpScanXFactors[j].B:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          ValueString:=ReadFirstString(TempString);
                          UpScanXFactors[j].C:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          UpScanXFactors[j].D:=StrToFloat(TempString);

                          //The next line corresponds to the down scan
                          readln(Scanner_file, read_string);
                          TempString:=StripStringWithColon(read_string);
                          ValueString:=ReadFirstString(TempString);
                          DownScanXFactors[j].A:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          ValueString:=ReadFirstString(TempString);
                          DownScanXFactors[j].B:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          ValueString:=ReadFirstString(TempString);
                          DownScanXFactors[j].C:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          DownScanXFactors[j].D:=StrToFloat(TempString);
                        end;
                    end

                   else if command_string = 'y hysteresis' then
                    //read the y-range hysteresis parameters
                    begin
                      for j:=0 to NumberOfScanRanges-1 do
                        begin
                          //read the next line, this corresponds to the up scan
                          readln(Scanner_file, read_string);
                          TempString:=StripStringWithColon(read_string);
                          ValueString:=ReadFirstString(TempString);
                          UpScanYFactors[j].A:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          ValueString:=ReadFirstString(TempString);
                          UpScanYFactors[j].B:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          ValueString:=ReadFirstString(TempString);
                          UpScanYFactors[j].C:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          UpScanYFactors[j].D:=StrToFloat(TempString);

                          //The next line corresponds to the down scan
                          readln(Scanner_file, read_string);
                          TempString:=StripStringWithColon(read_string);
                          ValueString:=ReadFirstString(TempString);
                          DownScanYFactors[j].A:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          ValueString:=ReadFirstString(TempString);
                          DownScanYFactors[j].B:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          ValueString:=ReadFirstString(TempString);
                          DownScanYFactors[j].C:=StrToFloat(ValueString);
                          TempString:=StripFirstString(TempString);
                          DownScanYFactors[j].D:=StrToFloat(TempString);
                        end;
                    end;
               end;
            end;
        end;
      Close(Scanner_file);
      ScanRangeIndex:=0; //set the scan range to be the first one defined
    end
       else Application.MessageBox(PChar('Unable to open scanner file'), 'Error!', 0);
end;

{--------------------------------------------------------------------------}
procedure ReadSysConfigFile;
var
     Config_file: TextFile;
     read_string, TempString: string;

begin
//Read the system configuration file, if it exists....if not, create it
if FileExists(SysConfig_file) then
  begin
  //Assign the file name and reset it to the top
     AssignFile(Config_file, SysConfig_file);
     reset(Config_File);
     {read and skip the first three lines, which just contain
              information about the file itself}
     readln(Config_file, read_string);
     readln(Config_file, read_string);
     readln(Config_file, read_string);

     //Next line deals with the attocube
     ReadFreeFormLineValue(Config_file, read_string);
     TempString:=ReadStringWithComma(read_string);
     if (Lowercase(TempString[1])='y') then UseAttocube:=TRUE else UseAttocube:=FALSE;
     TempString:=StripStringWithComma(read_string);
     AttocubeComPortNumber:=StrToInt(TempString);
     SPM_MainForm.AttocubeComPort.Device:='/dev/ttyS'+IntToStr(AttocubeComPortNumber-1);


     //Next line deals with the Nanosurf
     ReadFreeFormLineValue(Config_file, read_string);
     TempString:=ReadStringWithComma(read_string);
     if (Lowercase(TempString[1])='y') then UseNanoSurf:=TRUE else UseNanoSurf:=FALSE;


     //Next line deals with the LockIn amplifier
     ReadFreeFormLineValue(Config_file, read_string);
     TempString:=ReadStringWithComma(read_string);
     if (Lowercase(TempString[1])='y') then UseLockIn:=TRUE else UseLockIn:=FALSE;
     TempString:=StripStringWithComma(read_string);
     LockInGPIBAddress:=StrToInt(TempString);

     //Channel 0 input
     ReadFreeFormLineValue(Config_file, Ch0InputName);
     //Channel 1 input
     ReadFreeFormLineValue(Config_file, Ch1InputName);
      //Channel 2 input
     ReadFreeFormLineValue(Config_file, Ch2InputName);
     //Scan X Output
     ReadFreeFormLineValue(Config_file, ScanXOutName);
     //Scan Y Out
     ReadFreeFormLineValue(Config_file, ScanYOutName);
      //Scan Z Out
     ReadFreeFormLineValue(Config_file, ScanZOutName);
     //Sample Voltage Channel
     ReadFreeFormLineValue(Config_file, SampleVoltageChannelName);
     //Feedback channel
     ReadFreeFormLineValue(Config_file, FeedbackChannelName);

     //Next line deals with logarithmic feedback, primarily for STM
     ReadFreeFormLineValue(Config_file, read_string);
     TempString:=ReadStringWithComma(read_string);
     if (Lowercase(TempString[1])='y') then Logarithmic:=1 else Logarithmic:=0;


     //scanner configuration file name
     ReadFreeFormLineValue(Config_file, ScannerConfig_file);
     if FileExists(ScannerConfig_file) then ReadScannerFile;

     Close(Config_file);

  end
 else Application.MessageBox(PChar('Unable to open System configuration file'), 'Error!', 0);
end;
{---------------------------------------------------------------------------}
procedure WriteSysConfigFile;
  var
    F: TextFile;
  begin
    AssignFile(F, SysConfig_file);
    Rewrite(F);
    //Write the first two lines, which should identify the file and the date
    writeln(F, 'SPM program configuration file');
    writeln(F, 'Last updated ' + DateTimeToStr(Date));
    writeln(F, '******************************************');
    if UseAttocube then
       writeln(F, 'UseAttocube? (y,n), Attocube Com Port number (integer): y, '+ IntToStr(AttocubeComPortNumber))
      else
       writeln(F, 'UseAttocube? (y,n), Attocube Com Port number (integer): n, '+ IntToStr(AttocubeComPortNumber));
    if UseNanoSurf then
       writeln(F, 'UseNanoSurf? (y,n)): y ')
      else
       writeln(F, 'UseNanoSurf? (y,n)): n ');
    if UseLockIn then
       writeln(F, 'UseLockIn? (y,n), LockIn GPIB address (integer): y, '+ IntToStr(LockInGPIBAddress))
      else
       writeln(F, 'UseLockIn? (y,n), LockIn GPIB address (integer): n, '+ IntToStr(LockInGPIBAddress));
    writeln(F, 'Channel 0 input: '+ Ch0InputName);  // Channel 0 input, etc
    writeln(F, 'Channel 1 input: '+ Ch1InputName);
    writeln(F, 'Channel 2 input: '+ Ch2InputName);
    writeln(F, 'Scan X output: '+ ScanXOutName);
    writeln(F, 'Scan Y output: '+ ScanYOutName);
    writeln(F, 'Scan Z output: '+ ScanZOutName);
    writeln(F, 'Sample voltage channel: '+ SampleVoltageChannelName);
    writeln(F, 'Feedback channel: '+ FeedbackChannelName);
    if Logarithmic=1 then
       writeln(F, 'Logarithmic feedback? (y,n)): y ')
      else
       writeln(F, 'Logarithmic feedback? (y,n)): n ');
    writeln(F, 'Scanner configuration file name: '+ ScannerConfig_file);
    Close(F);
  end;

{--------------------------------------------------------------------------}
function CommaPosition(InputString:string):integer;
begin
  CommaPosition:=Pos(',',InputString);
 end;

{--------------------------------------------------------------------------}

function BlankorTabPosition(InputString:string):integer;
var
  BlankPos, TabPos: integer;
begin
  BlankPos:=Pos(' ',InputString);
  TabPos:=Pos(#9,InputString);
  if (BlankPos=0) and (TabPos>0) then
     BlankorTabPosition:=TabPos
   else if (TabPos=0) and (BlankPos>0) then
     BlankorTabPosition:=BlankPos
   else
   if (TabPos<>0) and (TabPos<BlankPos) then
     BlankorTabPosition:=TabPos
   else
     BlankorTabPosition:=BlankPos;
 end;
{---------------------------------------------------------------------}
function ColonOrDashPosition(InputString:string):integer;
var
  ColonPos, DashPos: integer;
begin
  ColonPos:=Pos(':',InputString);
  DashPos:=Pos('-',InputString);
  if (ColonPos=0) and (DashPos>0) then
     ColonOrDashPosition:=DashPos
   else if (DashPos=0) and (ColonPos>0) then
     ColonOrDashPosition:=ColonPos
   else
   if (DashPos<>0) and (DashPos<ColonPos) then
     ColonOrDashPosition:=DashPos
   else
     ColonOrDashPosition:=ColonPos;
 end;
{---------------------------------------------------------------------}
  procedure ReadFreeFormLineValue(var F: TextFile; var RealValue: real);overload;
  var
    TempString :string;
    BlankPos, code        :integer;
    TempValue             : real;
  begin
    ReadLn(F, TempString);
    BlankPos:=ColonOrDashPosition(TempString);
    TempString:=Copy(TempString, BlankPos+1, 300);
    Val(TempString, TempValue, code);
    RealValue:=TempValue;
  end;

{---------------------------------------------------------------------}
  procedure ReadFreeFormLineValue(var F: TextFile; var IntValue:integer); overload;
  var
    TempString :string;
    BlankPos        :integer;

  begin
    ReadLn(F, TempString);
    BlankPos:=ColonOrDashPosition(TempString);
    TempString:=Copy(TempString, BlankPos+1, 300);
    IntValue:=StrToInt(TempString);
  end;
{--------------------------------------------------------------}
{---------------------------------------------------------------------}
{This overloaded procedure added on 17/1/07}
  procedure ReadFreeFormLineValue(var F: TextFile; var read_string:string); overload;
  var
    TempString :string;
    BlankPos        :integer;

  begin
    ReadLn(F, TempString);
    BlankPos:=ColonOrDashPosition(TempString);
    TempString:=Copy(TempString, BlankPos+1, 300);
    read_string:=Trim(TempString);
  end;

{---------------------------------------------------------------------}
  function ReadFirstString(read_string:string): string;
  {New function added on 17/1/07 to read new Microscope line of SEM
  Parameters file.  This reads the first substring in a string.}
  var
    BlankPos        :integer;
    TempString      :string;
  begin
    BlankPos := BlankorTabPosition(read_string);
    TempString:=Copy(read_string,1,BlankPos);
    ReadFirstString:=Trim(TempString);
  end;

{---------------------------------------------------------------------}
  function StripFirstString(read_string:string): string;
  {New function added on 17/1/07 to read new Microscope line of SEM
  Parameters file.  This function strips the first substring in a string.}
  var
    BlankPos        :integer;
    TempString      :string;
  begin
    BlankPos := BlankorTabPosition(read_string);
    TempString:=Copy(read_string,BlankPos+1, 300);
    StripFirstString:=Trim(TempString);
  end;

{---------------------------------------------------------------------}
  function ReadStringWithColon(read_string:string): string;
  //equivalent of ReadFirstString when we have a colon delimiter
  var
    ColonPos        :integer;
    TempString      :string;
    StringLength    : integer;
  begin
    ColonPos := ColonOrDashPosition(read_string);
    StringLength:=Length(read_string);
    if ((ColonPos=0) and (StringLength>0)) then
       //this is the last item, which may not have a colon behind it
       TempString:=read_string
      else if ((ColonPos=0) and (StringLength=0)) then
      // we have an empty string
        TempString:=''
      else  //we have a real string
          TempString:=Copy(read_string,1,ColonPos-1);
    ReadStringWithColon:=Trim(TempString);
  end;

{---------------------------------------------------------------------}
  function StripStringWithColon(read_string:string): string;
  var
    ColonPos        :integer;
    TempString      :string;
    StringLength    : integer;
  begin
    ColonPos := ColonOrDashPosition(read_string);
    StringLength:=Length(read_string);
    if ((ColonPos=0) and (StringLength>0)) then
      TempString:=''
     else
       TempString:=Copy(read_string,ColonPos+1, 300);
    StripStringWithColon:=Trim(TempString);
  end;
{--------------------------------------------------------------}
{---------------------------------------------------------------------}
  function ReadStringWithComma(read_string:string): string;

  var
    CommaPos        :integer;
    TempString      :string;
    StringLength    : integer;
  begin
    CommaPos := CommaPosition(read_string);
    StringLength:=Length(read_string);
    if ((CommaPos=0) and (StringLength>0)) then
       //this is the last item, which may not have a comma behind it
       TempString:=read_string
      else if ((CommaPos=0) and (StringLength=0)) then
      // we have an empty string
        TempString:=''
      else  //we have a real string
          TempString:=Copy(read_string,1,CommaPos-1);
    ReadStringWithComma:=Trim(TempString);
  end;

{---------------------------------------------------------------------}
  function StripStringWithComma(read_string:string): string;
  var
    CommaPos        :integer;
    TempString      :string;
    StringLength    : integer;
  begin
    CommaPos := CommaPosition(read_string);
    StringLength:=Length(read_string);
    if ((CommaPos=0) and (StringLength>0)) then
      TempString:=''
     else
       TempString:=Copy(read_string,CommaPos+1, 300);
    StripStringWithComma:=Trim(TempString);
  end;
{--------------------------------------------------------------}




initialization
  //find the current directory
  ProgramDir:=GetCurrentDir;
  PathName:=ProgramDir+'/';
  CurrentDirectory:=ProgramDir+'/patterns/';
  ConfigDirectory:=ProgramDir+'/conf/';
  SysConfig_file:=ConfigDirectory+'spm_parameters.cfg';

end.
