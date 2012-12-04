//header file for the real time programs for the SPM C library

typedef struct  {
    //This is to define data acquisition channels for easy access
    char *devicename;                       //Definition corresponds to Pascal DAQ-Comedi-types
    char *boardname;
    comedi_t *board_id;
    int board_number;
    int subdevice;
    int channel;
}  Acquisition_channel;


#define TRUE 1
#define FALSE 0
#define PLLGenMinPulseTime 500 //Update time of DAC for PLL generation, in nanoseconds (0.5 usec= 2MHz)
#define PLLUpdateFrequency 1.0E9/PLLGenMinPulseTime
#define PLLGenerationLoopTime 1000000 //Loop time of the PLL reference generation loop, in nanoseconds (1 ms)
#define PLLGenerationBufferNPoints 2048 //Number of points to put out per PLL loop generation
#define WAVEFORM_SHIFT 16
#define WAVEFORM_LEN (1<<WAVEFORM_SHIFT)
#define WAVEFORM_MASK (WAVEFORM_LEN -1)

volatile RTIME sample_time;

//define input and output channels to use
volatile Acquisition_channel AnalogOutputChannel; //Channel for a test sine wave output
volatile Acquisition_channel PLLReferenceGenerationChannel; //Channel for generating a PLL reference signal
volatile Acquisition_channel AnalogInputChannel; //Channel for a test sine wave output
volatile Acquisition_channel PLLPhaseReferenceInChannel; //channel for phase input for phase locked loop
volatile Acquisition_channel PLLAmplitudeChannel; //channel for amplitude detection for amplitude control


volatile int hard_timer_running = TRUE; //flag to check if hard timer is running.  Set initially to TRUE (1, not 0)
static RTIME sampling_interval;

volatile int AmplifierGainSign =-1;//Sign of the Amplifier Gain on the z axis
volatile double MaxZVoltage =-10;
volatile double MinZVoltage = 10;
//volatile double CurrentZVoltage;


//PID parameters
volatile Acquisition_channel FeedbackChannel; //Channel for reading the input signal
volatile Acquisition_channel ControlChannel; //Channel for controlling the system
volatile int PIDParametersChanged = TRUE; //Flag to signal that PID parameters have changed
volatile double PropCoff; //PID proportional coefficient
volatile double IntTime; //PID integral time constant
volatile double DiffTime; //PID differential time constant
RTIME PIDLoop_Time;
volatile int PID_averages =1; //number of averages to perform
volatile int pid_loop_running =  TRUE;  //Set to TRUE (non zero value)
volatile int PLLGenerationOn = TRUE;  //Set to TRUE (non zero value)
volatile double PIDOutput; //output in volts of the PID
volatile double AveragedPIDOutput; //PID output averaged over PID_averagess
volatile double AveragedFeedbackReading; //Averaged Feedback reading
volatile double FeedbackReading;
volatile double SetPoint; //SetPoint for the PID
volatile int FirstPIDPass =  TRUE ; //this tells us if this is the first pass, set to TRUE
volatile int OutputPhase = -1; //Sets the sign of the output, depending on response
volatile double PIDOutputVariance; //variance of the pid output
volatile int Logarithmic = TRUE; //Flag to signal that feedback should be done on a logarithmic scale (set to TRUE)


//PLL parameters
static RTIME PLLPulseUpdateTime;//nano2count version of PLLGenMinPulseTime
static RTIME PLLUpdateTime; //nano2count version of PLLGenerationLoopTime
volatile double PLLWaveformFrequency =32768; //Free running frequency of the PLL
volatile double PLLSinewaveAmplitude = 10.0; //Amplitude of the PLL
static unsigned int acc;  //dds accumulator integer
static unsigned int adder;  //dds adder integer
static lsampl_t waveform[WAVEFORM_LEN];  //lookup table to hold the dds waveform
double amplitude = 65536; //maximum amplitude of the waveform
double offset = 32768; //corresponding to zero voltage




//RTAI test definitions
double SineWaveFrequency;
double SineWaveAmplitude;
int N_PNT;
volatile double OutputValue;
#define RUN_TIME  5
#define PI 3.14156


//Hardware related paramters
#define AO_RANGE  0
#define AI_RANGE 0
char *device_names[2] = {"/dev/comedi0", "/dev/comedi1"};
int MaxOutputBits = 65535;  //changed from 65536
int MaxInputBits = 65535;
double MaxOutputVoltage = 10.0; //in volts;
double OutputRange = 20.0; //in volts;
double InputRange = 20.0; //in volts
double MaxInputVoltage = 10.0; //in volts
double MinInputVoltage = -10.0;
double MinOutputVoltage = -10.0;


volatile float SAMP_FREQ;
RTIME SAMP_TIME;
#define TRIGSAMP  2048

int sine_loop_running;


//functions defined in queue.c

//functions that can be called;
double comedi_to_real(lsampl_t *data);
lsampl_t *real_to_comedi(double output);
int sineoutput();
int StartMainTask(int priority);
int EndMainTask();
int pid_loop();
int PLLReferenceGeneration();
