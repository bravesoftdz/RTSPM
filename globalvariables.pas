unit GlobalVariables;

{$MODE Delphi}

interface
 uses
   Forms, daq_comedi_types, Classes {, Windows};


const
  MaxBoards = 3; //maximum number of data acquisition boards
  MaxChannels = 32; //Maximum number of input or output channels
  MaxDevTypes =13;  //maximum number of subdevice types in comedi (currently)
  MaxDAQVoltage=10.0;  // Max and Min voltage output of D/A cards in
  MinDAQVoltage=-10.0;  //volts
  DAQVoltageRange=20.0; //in volts
  MaxBits = 65535; //resolution of boards in bits
  MaxFeedbackCorrection = DAQVoltageRange/50;  //maximum correction term
  MaxRanges = 10; //Maximum number of scan ranges for a scanner
  LUTPoints = 2048; //Twice the maximum scan resolution of 1024
  RGB_GreenColor = 32; //Used for generating Color from integers
  RGB_Alpha = 255; //fully opaque


type
   ErrorSign = (Positive, negative);
   Axis      = (XAxis, YAxis, ZAxis);
   TScanData  = array of real;
   TXYData    = array of array of real;
   board_it_type = array[0..MaxBoards-1] of Pcomedi_t;
   device_name_type = array[0..MaxBoards-1] of PChar;
   Channel_array = array[0..MaxChannels-1] of Acquisition_channel;
   InterpolationArray = array[0..LUTPoints-1] of real;

   ScanRangeParameters = record
     Range             : real; //the range in microns
     Voltage           : real; //voltage span required to get this range
     Description       : string;
    end;
   HysteresisFactors = record  //factor that determine conversion from voltage to displacement
     A               : real; //constant term
     B               : real; //linear term
     C               : real; //quadratic term
     D               : real; //cubic term
    end;

var
//General variables
  StartingUpProgram     : Boolean = TRUE;  //starting up the program for the first time
  CoarseSP              : real = 0.5;   //Set point to use during Coarse approach, in volts
  SetPoint              : real = 0.5;   //Set point to use during
  ApproachCriterion     : real = 0.15; //Value to use to see whether we have approached
  //Logarithmic           : boolean = FALSE; //no logarithmic feedback   Changed Jan 10, 2012, this is now a real time variable
  GlobalTaskStarted     : boolean = FALSE;

//variables associated with the chosen scanner
  ScannerName          :string; //descriptive name of the scanner
  ZPiezoRange          : real; //range in microns of Z piezo
  ZPiezoVRange         : real; //voltage required to obtain the above range
  NumberOfScanRanges   : integer; //Number of scan ranges
  ScanRanges           : array[0..MaxRanges-1] of ScanRangeParameters;
  UpScanXFactors        : array[0..MaxRanges-1] of HysteresisFactors;
  DownScanXFactors      : array[0..MaxRanges-1] of HysteresisFactors; //for the X direction
  UpScanYFactors        : array[0..MaxRanges-1] of HysteresisFactors;
  DownScanYFactors      : array[0..MaxRanges-1] of HysteresisFactors; //for the Y direction
  ScanRangeStringList   : TStringList; //String enumerating scan ranges to populate relevant combo boxes
  ScanRangeIndex        : integer = 0; //Number specifying which scan range to use
  V                     : InterpolationArray; //array to hold points generated for the voltage scans LUT
  XUp                   : InterpolationArray; //array to hold points generated for the voltage scans LUT
  XDown                 : InterpolationArray; //array to hold points generated for the voltage scans LUT
  Yup                   : InterpolationArray; //array to hold points generated for the voltage scans LUT
  YDown                 : InterpolationArray; //array to hold points generated for the voltage scans LUT
  ScanAxis              : Axis;


// Variables associated with the Attocube
  UseAttocube : boolean = TRUE; //whether or not we are using the attocube
  AttocubeComPortNumber : integer = 1; //Attocube Com Port number

//Variables associated with the Nanosurf
  UseNanosurf  : boolean = FALSE;
  NanosurfComPort : integer = 4; //Nanosurf Com Port number

//Variable associated with the lockin amplifier, usually a EGG7260
  UseLockIn : boolean = TRUE;
  LockInGPIBAddress : integer = 12;

//Variables associated with the DAQ cards
  BoardsPresent       : boolean = FALSE;
  Ch0InputName        : string = 'NI6014/ai0';
  Ch1InputName        : string = 'NI6014/ai1';
  Ch2InputName        : string = 'NI6014/ai2';
  ScanXOutName        : string = 'NI6733/ao0';
  ScanYOutName        : string = 'NI6733/ao1';
  ScanZOutName        : string = 'NI6733/ao2';
  FeedbackChannelName : string = 'NI6014/ai0'; //input channel on which to perform feedback
  //Now the actual channels
  Ch0Input,
  Ch1Input,
  Ch2Input,
  ScanXOut,
  ScanYOut,
  ScanZOut            : Acquisition_channel;

  board_it        : board_it_type;
  device_names    : device_name_type;   //filenames of the boards, e.g., /dev/comedi0
  board_names     : device_name_type;  //actual descriptions of the boards
  InputChannels   : Channel_array;
  OutputChannels  : Channel_array;



//Variables associated with the Scan tube
  CurrentX                : real =0.0;
  CurrentY                : real = 0.0;
  CurrentZ                : real = 0.0;    //current positions of x, y, and z scan tube, in microns
  CurrentXVoltage         : real =0.0;     //corresponding values in DAQ voltages
  CurrentYVoltage         : real = 0.0;
  CurrentZVoltage         : real = 0.0;

  SetX                    : real = 0.0;
  SetY                    : real = 0.0;
  SetZ                    : real = 0.0;  //desired position of x, y and z scan tube, in microns
  SetXVoltage             : real = 0.0;
  SetYVoltage             : real = 0.0;
  SetZVoltage             : real = 0.0;  //desired position of x, y and z scan tube, in DAQ voltages
  StepX                   : real = 0.001;  //Scan tube in microns
  StepY                   : real = 0.001;
  StepZ                   : real = 0.0003;

  XAxisMicronsToVoltage        : real = 1.0; //linear scale factors to convert microns to voltage
  YAxisMicronsToVoltage        : real = 1.0; //defaults are 1.0.  Should be read from scanner file
  ZAxisMicronsToVoltage        : real = 1.0;
  StepDelay                    : real = 1.0; //delay between steps in milliseconds


  PropGain             : real =1.0;
  IntGain               : real = 0.0005;
  DiffGain              : real = 0.0;
  IntegralOutput,                   //this is the cumulative gain output
  OverallPIDGain,
  ErrorReading,
  LastErrorReading            : real; //gain parameters for PID control
  FeedBackSign            : integer = 1;
  FreqOutputScaleFact     : real;
  FreqShift               : real; //self evident
  InitialFrequency        : real; //Center frequency of the PLL when far from the surface
  CenterFrequency         : real; //current center frequency
  Frequency               : real; //actual frequency
  Noise                   : real = 0.2; //noise level for readings in volts, ignore changes if below this


  //Pixels sets the pixel resolution

  ScanResolution          : integer  = 256;
  Pixels                  : integer = 128;  //number of pixels in scan
  Mag                     : integer = 1;    //magnification, StepSize=Board_resolution/mag/pixels

  ScanRange               : real = 1.0; //in microns
  ScanRangeVoltage        : real;
  Scanning                : boolean = FALSE;

  //Parameters for the scan tube
  XScanRange,
  YScanRange                  : real; //total range of x and y piezos in um
  MinZPosition,
  MaxZPosition                   : real;

  //Feedback Timer parameters
  FirstFeedbackRun        : boolean = TRUE;
  INFeedback              : boolean = FALSE;
  startTime64,
  endTime64,
  frequency64             : Int64;  //for use with the getperformance functions
  elapsedSeconds          : single;

  ForwardData,
  ReverseData             : TXYData;   //to hold forward
                              //and reverse scan data
  ForwardLeveledData,
  ReverseLeveledData      : TXYData;  //these are leveled versions of the two arrays above

  //To hold MFM, EFM or some other data
  //MFM stands in for any type of secondary data
  MFMForwardData,
  MFMReverseData,
  MFMForwardLeveledData,
  MFMReverseLeveledData : TXYData;

  //Other variables for MFM, EFM, STM etc
  LiftModeHeight          :real = 20; // lift mode height, in nm


implementation

initialization
   device_names[0]:='/dev/comedi0';
   device_names[1]:='/dev/comedi1';
   device_names[2]:='/dev/comedi2';
   //New(board_it[2]);
   board_it[2]:=nil;
   //New(board_it[0]);
   board_it[0]:= nil;
   //New(board_it[1]);
   board_it[1]:=nil;
   ScanRangeStringList:=TStringList.Create;
   ScanAxis:=XAxis;


finalization
   ScanRangeStringList.Destroy;
   //Dispose(board_it[0]);
   //Dispose(board_it[1]);
   //Dispose(board_it[2]);

end.
