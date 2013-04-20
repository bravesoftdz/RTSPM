//Instead of writing an interface function to the RTAI functions in pascal,
//it is easier to write a simple library that uses the functions I need.
//This avoids the problem of working out the C definitions for the RTAI
//header files
//Started March 16, 2011
//Last updated March 29, 2011


//August 3, 2012
//Trying a loop that will generate a reference signal for a PLL


//The standard  libraries
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/io.h>
#include <math.h>



//The RTAI libraries
#include <rtai_lxrt.h>
#include <rtai_msg.h>
#include <rtai_comedi.h>
#include <rtai_spm.h>


//define some constants
#define CPUMAP 0xF
#define NCHAN 1
#define PID_cutoff_N 20
#define MaxvOutput 1000
#define MinvOutput -1000


//the queue.ch file
#include <queue.c>

//some types


// The functions contained in this file are pretty dummy
// and are included only as a placeholder. Nevertheless,
// they *will* get included in the shared library if you
// don't remove them :)
//
// Obviously, you 'll have to write yourself the super-duper
// functions to include in the resulting library...
// Also, it's not necessary to write every function in this file.
// Feel free to add more files in this project. They will be
// included in the resulting library.



//static pthread_t pid_thread; // Points to where the thread ID will be stored
static RT_TASK *PIDloop_Task; // Pid  task

static RT_TASK *PLLRefGen_Task; // Real time task to generate the PLL reference

//static pthread_t sine_thread; // Points to where the thread ID will be stored
static RT_TASK *Sinewaveloop_Task; // Pid  task
static RTIME expected;
static double start_time;
static double old_time;
static double current_time;
static RT_TASK *GlobalTask;


//*****************************************************************************

int StartMainTask( int priority)
{
 //function to start a real time task with the given priority
 //StartMainTask is designed to be called from the Pascal Program to start the Main (i.e., Pascal) rt program
    int hard_timer_running = 1;
    int j=0;
    rt_allow_nonroot_hrt();

     if(!(GlobalTask = rt_task_init_schmod(nam2num( "SomeTask" ), // Name
                                        priority, // Priority
                                        0, // Stack Size
                                        0, //, // max_msg_size
                                        SCHED_FIFO, // Policy
                                        1 ))) // cpus_allowed
        {
            return 1;
        }
       else {
                if ( (hard_timer_running == rt_is_hard_timer_running() ))
                    {
                     stop_rt_timer();
                     rt_set_oneshot_mode();
                     start_rt_timer(0);
                     //sampling_interval = nano2count(TICK_TIME);  //Converts a value from
                                                //nanoseconds to internal count units.
                    }
                else
                    {
                     rt_set_oneshot_mode();
                     start_rt_timer(0);
                     //sampling_interval = nano2count(TICK_TIME); // Sets the period of the concurrent task
                    // that will be launched later.
                    }
                mlockall(MCL_CURRENT | MCL_FUTURE);
           return 0;
       }
}


//***************************************************************************************
int EndMainTask()
{
    //EndMainTask is designed to be called from the Pascal Program to end the Main (i.e., Pascal) rt program
    rt_make_soft_real_time();
    rt_task_delete(GlobalTask);
   return 0;
}


//*****************************************************************************************




void dds_init(double waveform_frequency, double update_frequency)  //initializes the sinewave lookup table
{
    //This combines the dds_init and dds_sine_init functions in the example program
    int i;
    double amp = 0.5 * amplitude;
    double ofs = amp;

    adder = waveform_frequency / update_frequency*(1<<16)*(1<<WAVEFORM_SHIFT);

    for (i=0; i<WAVEFORM_LEN;i++){
      waveform[i]=rint(ofs+amp*cos(i*2*M_PI/WAVEFORM_LEN));
    }
}

void dds_output(lsampl_t *buf, int n)  // this is the function that looks up the values in the lookup table, and puts them into buf
{
    //This takes data from the pregenerated lookup table and puts it into buffer
    int i;
    lsampl_t *p=buf;
    for(i=0;i<n;i++){
    *p=waveform[(acc>>16)&WAVEFORM_MASK];
    p++;
    acc+=adder;
    }
}







//****************************************************************************************

int PLLReferenceGeneration()
 {
    //Initial test function to try out Real time stuff.
    int m, i=0, err, n;
    lsampl_t data_to_card;
    static comedi_t * dev;
    static int OutputFIFOBufferSize;
    static int PLLGenerationBufferSize;
	unsigned int maxdata;
	unsigned int chanlist[16];
	int ret;
    static lsampl_t data[PLLGenerationBufferNPoints]; //this is the buffer used to send data points out
    comedi_cmd cmd;

    dev = comedi_open(device_names[PLLReferenceGenerationChannel.board_number]);

    //Check the size of the output buffer
    OutputFIFOBufferSize = comedi_get_buffer_size(dev, PLLReferenceGenerationChannel.subdevice);
    rt_printk("OutputFIFO Buffer size is %i\n", OutputFIFOBufferSize);

    //Set the actual buffer size that we will be using to half this and the number of data points to one fourth
    //Now configure the output channel using a Comedi instruction
    //BufferSize is initially set to be double the number of PLLGenerationBufferNPoints
    PLLGenerationBufferSize = 2*PLLGenerationBufferNPoints;


	maxdata = comedi_get_maxdata(dev, PLLReferenceGenerationChannel.subdevice, PLLReferenceGenerationChannel.channel);
	rt_printk("PLL Reference channel max data is %i\n", maxdata);

	offset = maxdata / 2;
	amplitude = maxdata - offset;

	memset(&cmd,0,sizeof(cmd));
	cmd.subdev = PLLReferenceGenerationChannel.subdevice;
	cmd.flags = CMDF_WRITE;
	cmd.start_src = TRIG_INT;
	cmd.start_arg = 0;
	cmd.scan_begin_src = TRIG_TIMER;
	cmd.scan_begin_arg = PLLGenMinPulseTime;  //minimum update time for the
	cmd.convert_src = TRIG_NOW;
	cmd.convert_arg = 0;
	cmd.scan_end_src = TRIG_COUNT;
	cmd.scan_end_arg = NCHAN; //only one channel
	cmd.stop_src = TRIG_NONE;
	cmd.stop_arg = 0;

	cmd.chanlist = chanlist;
	cmd.chanlist_len = NCHAN;

	chanlist[0] = CR_PACK(PLLReferenceGenerationChannel.channel, AO_RANGE, AREF_GROUND);

	dds_init(PLLWaveformFrequency, PLLUpdateFrequency);

	err = comedi_command_test(dev, &cmd);
	if (err < 0) {
		comedi_perror("comedi_command_test");
		exit(1);
	}

	err = comedi_command_test(dev, &cmd);
	if (err < 0) {
		comedi_perror("comedi_command_test");
		exit(1);
	}

	if ((err = comedi_command(dev, &cmd)) < 0) {
		comedi_perror("comedi_command");
		exit(1);
	}

	dds_output(data,PLLGenerationBufferNPoints);
	n = PLLGenerationBufferNPoints * sizeof(sampl_t);
	m = write(comedi_fileno(dev), (void *)data, n);
	if(m < 0){
		perror("write");
		exit(1);
	}else if(m < n)
	{
		fprintf(stderr, "failed to preload output buffer with %i bytes, is it too small?\n"
			"See the --write-buffer option of comedi_config\n", n);
		exit(1);
	}

    if(!(PLLRefGen_Task = rt_task_init_schmod(nam2num( "PLLReferenceGeneration" ), // Name
                                        2, // Priority
                                        0, // Stack Size
                                        0, //, // max_msg_size
                                        SCHED_FIFO, // Policy
                                        CPUMAP ))) // cpus_allowed
        {
            printf("ERROR: Cannot initialize pll reference generation task\n");
            exit(1);
        }

    //specify that this is to run on one CPU
    rt_set_runnable_on_cpuid(PLLRefGen_Task, 1);
    //Convert samp_time, which is in nanoseconds, to tick time
    //sampling_interval = nano2count(SAMP_TIME);  //Converts a value from
                                                //nanoseconds to internal count units.
    mlockall(MCL_CURRENT|MCL_FUTURE);
    rt_make_hard_real_time();
    PLLUpdateTime = nano2count(PLLGenerationLoopTime);
    rt_printk("PLL generation update time is %f12 \n",count2nano((float) PLLUpdateTime));
    // Let's make this task periodic..
    expected = rt_get_time() + 100*PLLUpdateTime;



    rt_task_make_periodic(PLLRefGen_Task, expected, PLLUpdateTime); //period in counts
    //rt_task_resume(Sinewaveloop_Task);
    PLLGenerationOn = TRUE;



    // Concurrent function Loop


     //rt_printk("SineWaveAmplitude is is %f \n",SineWaveAmplitude);
     //rt_printk("SineWaveFrequency is %f \n",SineWaveFrequency);
     //rt_printk("sine_loop_running is %d \n",sine_loop_running);
     //rt_printk("SAMP_TIME is %d \n",SAMP_TIME);
     start_time = (float)rt_get_time_ns()/1E9; //in seconds
     old_time = start_time;
     rt_printk("PLLReferenceGenerationChannel board_it is %p \n",PLLReferenceGenerationChannel.board_id);
     rt_printk("PLLReferenceGenerationChannel devicename is %p \n",*(PLLReferenceGenerationChannel.devicename));
     rt_printk("PLLReferenceGenerationChannel boardname is %p \n",*(PLLReferenceGenerationChannel.boardname));
     rt_printk("PLLReferenceGenerationChannel subdevice is %d \n",PLLReferenceGenerationChannel.subdevice);
     rt_printk("PLLReferenceGenerationChannel channel is %d \n",PLLReferenceGenerationChannel.channel);
     OutputValue = 1;
     PLLGenerationBufferSize = comedi_get_buffer_size(dev, PLLReferenceGenerationChannel.subdevice);
     //sine_loop_running = 0;  //set this to 0 for testing
     while(PLLGenerationOn)
     {
        i++; // Count Loops.
        current_time = (float)rt_get_time_ns()/1E9;
        //rt_printk("LOOP %d,-- Period time: %f12 %f12\n",i, current_time - old_time,count2nano((float)sampling_interval)/1E9);
        OutputValue = SineWaveAmplitude*sin(2*PI*SineWaveFrequency*(current_time-start_time));
        //OutputValue = -1*OutputValue;
        //rt_printk("OutputValue is %f12 \n",OutputValue);
        data_to_card = (lsampl_t) nearbyint(((OutputValue - MinOutputVoltage)/OutputRange)*MaxOutputBits);
        //m=rt_comedi_command_data_write(AnalogOutputChannel.board_id, AnalogOutputChannel.subdevice, NCHAN, data_to_card);
        comedi_lock(dev, AnalogOutputChannel.subdevice);
        m=comedi_data_write(dev, AnalogOutputChannel.subdevice, AnalogOutputChannel.channel, AO_RANGE, AREF_DIFF, data_to_card);
        comedi_unlock(dev, AnalogOutputChannel.subdevice);
//        m=comedi_data_write(AnalogOutputChannel.board_id, AnalogOutputChannel.subdevice,
//               AnalogOutputChannel.channel, AO_RANGE, AREF_GROUND, data_to_card);
        //rt_printk("Data_to_card is %d; result from rt_comedi_command_data_write is %d \n",data_to_card, m);
        //rt_printk("LOOP %d,-- AO Out time: %f12 \n",i, (float)rt_get_time_ns()/1E9 - current_time);
        //rt_printk("Data_to_card is %d \n",data_to_card);
        //old_time = current_time;
/*        if (i== 100000)
        {
            sine_loop_running = 0;
            //printf("LOOP -- run: %d %d\n ",keep_on_running,&keep_on_running);
            //printf("RTAI LOOP -- run: %d \n ",i);
            break;
        }
*/
        rt_task_wait_period(); // And waits until the end of the period.

    }
    rt_make_soft_real_time();
    comedi_close(dev);
    rt_task_delete(Sinewaveloop_Task); //Self termination at end.

    pthread_exit(NULL);
    return 0;
 }

//****************************************************************************************

int sineoutput()
 {
    //Initial test function to try out Real time stuff.
    int m, i=0;
    lsampl_t data_to_card;
    static comedi_t * dev;
    RTIME ElapsedTime;

    dev = comedi_open(device_names[AnalogOutputChannel.board_number]);

    if(!(Sinewaveloop_Task = rt_task_init_schmod(nam2num( "Sinewave" ), // Name
                                        2, // Priority
                                        0, // Stack Size
                                        0, //, // max_msg_size
                                        SCHED_FIFO, // Policy
                                        CPUMAP ))) // cpus_allowed
        {
            printf("ERROR: Cannot initialize sinewave task\n");
            exit(1);
        }

    //specify that this is to run on one CPU
    //rt_set_runnable_on_cpuid(Sinewaveloop_Task, 0);
    //Convert samp_time, which is in nanoseconds, to tick time
    //sampling_interval = nano2count(SAMP_TIME);  //Converts a value from
                                                //nanoseconds to internal count units.
    mlockall(MCL_CURRENT|MCL_FUTURE);
    rt_make_hard_real_time();
    sampling_interval =nano2count_cpuid(SAMP_TIME, 0);
     rt_printk("Sampling interval is %f12 \n",count2nano((float) sampling_interval));
    // Let's make this task periodic..
    expected = rt_get_time_cpuid(0) + 100*sampling_interval;

    //Manan changed all the timer commands to _couid version on 10/22/2012 to see if it helps
    //sampling_interval =nano2count_cpuid(SAMP_TIME,0);
    // rt_printk("Sampling interval is %f12 \n",count2nano_cpuid((float) sampling_interval,0));
    // Let's make this task periodic..
    //expected = rt_get_time_cpuid(0) + 100*sampling_interval;

    rt_task_make_periodic(Sinewaveloop_Task, expected, sampling_interval); //period in counts
    //rt_task_resume(Sinewaveloop_Task);
    sine_loop_running=1;



    // Concurrent function Loop


     rt_printk("SineWaveAmplitude is is %f \n",SineWaveAmplitude);
     rt_printk("SineWaveFrequency is %f \n",SineWaveFrequency);
     rt_printk("sine_loop_running is %d \n",sine_loop_running);
     rt_printk("SAMP_TIME is %d \n",SAMP_TIME);
     //start_time = (float)rt_get_time_ns_cpuid(0)/1E9; //in seconds
     start_time = (float)rt_get_time_ns_cpuid(0)/1E9;
     old_time = start_time;
     rt_printk("AnalogOutputChannel board_it is %p \n",AnalogOutputChannel.board_id);
     rt_printk("AnalogOutputChannel devicename is %p \n",*(AnalogOutputChannel.devicename));
     rt_printk("AnalogOutputChannel boardname is %p \n",*(AnalogOutputChannel.boardname));
     rt_printk("AnalogOutputChannel subdevice is %d \n",AnalogOutputChannel.subdevice);
     rt_printk("AnalogOutputChannel channel is %d \n",AnalogOutputChannel.channel);
     //OutputValue = 1;
     //ElapsedTime = 0;
     OutputValue = 0;
     //sine_loop_running = 0;  //set this to 0 for testing
     while(sine_loop_running)
     {
        i++; // Count Loops.
        current_time = (float)rt_get_time_ns_cpuid(0)/1E9;
        //current_ticks = rt_get_time_cpuid(0);
        //current_time = (float) (count2nano_cpuid(current_ticks,0)/1E9);
        //current_time = (float)rt_get_time_ns_cpuid(0)/1E9;
        //rt_printk("LOOP %d,-- Period time: %f12 %f12\n",i, current_time - old_time,count2nano((float)sampling_interval)/1E9);
        OutputValue = SineWaveAmplitude*sin(2*PI*SineWaveFrequency*(current_time-start_time));
        //OutputValue+=((SAMP_TIME*PI*2*SineWaveFrequency)/1E9)*cos(2*PI*SineWaveFrequency*((float)SAMP_TIME)/1E9);
        //if (OutputValue>10.0)
        //{OutputValue =  -10;
        //}
        //OutputValue = SineWaveAmplitude*sin(2*PI*SineWaveFrequency*((float)ElapsedTime)/1E9);
        ElapsedTime+=SAMP_TIME;
        //OutputValue = -1*OutputValue;
        //rt_printk("OutputValue is %f12 \n",OutputValue);
        data_to_card = (lsampl_t) nearbyint(((OutputValue - MinOutputVoltage)/OutputRange)*MaxOutputBits);
        //m=rt_comedi_command_data_write(AnalogOutputChannel.board_id, AnalogOutputChannel.subdevice, NCHAN, data_to_card);
        comedi_lock(dev, AnalogOutputChannel.subdevice);
        m=comedi_data_write(dev, AnalogOutputChannel.subdevice, AnalogOutputChannel.channel, AO_RANGE, AREF_DIFF, data_to_card);
        comedi_unlock(dev, AnalogOutputChannel.subdevice);
//        m=comedi_data_write(AnalogOutputChannel.board_id, AnalogOutputChannel.subdevice,
//               AnalogOutputChannel.channel, AO_RANGE, AREF_GROUND, data_to_card);
        //rt_printk("Data_to_card is %d; result from rt_comedi_command_data_write is %d \n",data_to_card, m);
        //rt_printk("LOOP %d,-- Loop time: %f12 \n",i, (float)(current_time-old_time));
        //rt_printk("LOOP %d,-- AO Out time: %f12 \n",i, (float)rt_get_time_ns()/1E9 - current_time);
        //rt_printk("LOOP %d,-- AO Out time: %f12 \n",i, (float)rt_get_cpu_time_ns()/1E9 - current_time);
        //rt_printk("Data_to_card is %d \n",data_to_card);
        old_time = current_time;
/*        if (i== 100000)
        {
            sine_loop_running = 0;
            //printf("LOOP -- run: %d %d\n ",keep_on_running,&keep_on_running);
            //printf("RTAI LOOP -- run: %d \n ",i);
            break;
        }
*/
        rt_task_wait_period(); // And waits until the end of the period.

    }
    rt_make_soft_real_time();
    comedi_close(dev);
    rt_task_delete(Sinewaveloop_Task); //Self termination at end.

    pthread_exit(NULL);
    return 0;
 }


//*******************************************************************************
int pid_loop()

//Modified on May 8 to take into account a moving average, and a moving variance
//and also to remove the retraction of the piezo except on the first pass.

{
//This is the function to output a PID loop
//PID algorithm taken from Control System Desgin, by Karl Johan Astrom
//Chapter 6
//This algorithm is supposed to include integral wind-up and bumpless transition

    int m;
    lsampl_t data_to_card, data_from_card;
    static comedi_t * dev_output, * dev_input, * dev_chan1, * dev_chan2;
    static double bi, ad, bd; //PID coefficients
    static double Pcontrib, Icontrib, Dcontrib; //individual PID contributions
    static double FeedbackReading; //Readings of the error chann
    static double v; //u is the actuator output, and v is the calculated output
    static int j = 0;
    static double LastDiffContrib;
    static double Error;
    static double LastError =0;
    static double SecondLastError =0;
    static double LastOutput =0;
    //static double SummedPIDOutput; //Summed PID Output
    static double SummedFeedbackReading; //Summed FeedbackReading
    //static double SummedVariance;
    static double SummedChan1Reading, SummedChan2Reading;
    static double M2_n;
    static double delta;
    static double alpha;
    static struct queue PIDOutput_queue;//these are two queues to calculate the moving mean and variance
    static struct queue FeedbackReadingVar_queue;
    static struct queue FeedbackReading_queue;
    static struct queue Chan1Input_queue;
    static struct queue Chan2Input_queue;
    static int NumbFirstSteps;
    static double InitialStepSizeVoltage = 0.1;
    static double InitialVoltageStep;
    double last_mean, last_var, new_var, Chan1_mean, Chan2_mean; //popped values of mean and variance



    //Initialize the queues
    init_queue(&PIDOutput_queue);
    init_queue(&FeedbackReadingVar_queue);
    init_queue(&FeedbackReading_queue);
    init_queue(&Chan1Input_queue);
    init_queue(&Chan2Input_queue);

    //rt_printk("Control channel device name is %s \n",device_names[ControlChannel.board_number]);
    //rt_printk("Control channel subdevice %d and channel %d \n", ControlChannel.subdevice, ControlChannel.channel);

    //rt_printk("Feedback channel device name is %s \n",device_names[FeedbackChannel.board_number]);
    //rt_printk("Feedback channel subdevice %d and channel %d \n", FeedbackChannel.subdevice, FeedbackChannel.channel);

    //dev_output is the channel that is to be controlled
    dev_output = comedi_open(device_names[ControlChannel.board_number]);
    //dev_input is the channel from which the error signal is read
    dev_input = comedi_open(device_names[FeedbackChannel.board_number]);


    //Open channels 1 and 2 only if we are going to use them
    if(DoChan1Average){dev_chan1=comedi_open(device_names[Chan1Input.board_number]);}
    if(DoChan2Average){dev_chan1=comedi_open(device_names[Chan2Input.board_number]);}


    //initialize the task
    if(!(PIDloop_Task = rt_task_init_schmod(nam2num( "PIDLoop" ), // Name
                                        0, // Priority
                                        0, // Stack Size
                                        0, //, // max_msg_size
                                        SCHED_FIFO, // Policy
                                        0 ))) // cpus_allowed
        {
            rt_printk("ERROR: Cannot initialize PIDLoop task\n");
            exit(1);
        }

    //specify that this is to run on one CPU
    rt_set_runnable_on_cpuid(PIDloop_Task, 0);


    //lock memory and make hard real time
    mlockall(MCL_CURRENT|MCL_FUTURE);
    rt_make_hard_real_time();

    //Convert PIDLoop_time, which is in nanoseconds, to tick time (sampling_interval, in counts)
    sampling_interval =nano2count(PIDLoop_Time);
    //sampling_interval =nano2count_cpuid(PIDLoop_Time, 0);

    // Let's make this task periodic..
    expected = rt_get_time() + 100*sampling_interval;
    //expected = rt_get_time_cpuid(0) + 100*sampling_interval;
    rt_task_make_periodic(PIDloop_Task, expected, sampling_interval); //period in counts


    pid_loop_running = 1; //set the pid loop running flag to FALSE

    //retract the tip completely, if it is the first PID pass
    if(FirstPIDPass)
      {
        //data_to_card = (lsampl_t) 0;
        //MaxZVoltage corresponds to the fully retracted piezo
        //rt_printk("MaxZVoltage is %f \n", MaxZVoltage);
        //rt_printk("MinZVoltage is %f \n", MinZVoltage);
        //rt_printk("MinOutputVoltage is %f \n", MinOutputVoltage);
        //rt_printk("PIDOutput is %f \n", PIDOutput);
        //rt_printk("AmplifierGainSign is %i \n", AmplifierGainSign);
        //rt_printk("OutputPhase is %i \n", OutputPhase);
        NumbFirstSteps = (nearbyint((MaxZVoltage-PIDOutput)/InitialStepSizeVoltage))-1;
        //rt_printk("NumbFirstSteps is %i \n", NumbFirstSteps);
       //NumbFirstSteps = ((MaxZVoltage - PIDOutput)/InitialStepSizeVoltage)); //-1 to  be safe
        //Set the direction of the voltage step
        //PIDOutput = CurrentZVoltage;
        if (MaxZVoltage>=PIDOutput)
          {InitialVoltageStep=InitialStepSizeVoltage;}
         else {InitialVoltageStep=-InitialStepSizeVoltage;};

        if (NumbFirstSteps>1)
          {
            for(j=0;j<NumbFirstSteps;j++)
              {  PIDOutput+=InitialVoltageStep;
                 data_to_card = (lsampl_t) nearbyint(((PIDOutput - MinOutputVoltage)/OutputRange)*MaxOutputBits);
                 //rt_printk("Data_to_card is %i \n", data_to_card);
                 comedi_lock(dev_output, ControlChannel.subdevice);
                 m=comedi_data_write(dev_output, ControlChannel.subdevice, ControlChannel.channel, AO_RANGE, AREF_DIFF, data_to_card);
                 comedi_unlock(dev_output, ControlChannel.subdevice);
                // And wait until the end of the period.
                rt_task_wait_period();
              }
          }
        //Initialize the errors
        LastError = 0;
        SecondLastError = 0;
        LastOutput = PIDOutput;
        LastDiffContrib =0;
        Dcontrib = 0;
        Icontrib = 0;
        AveragedPIDOutput=LastOutput;  //This is what the main program will actually read
        FirstPIDPass = 0;
      }




    //rt_printk("AntiWindup time is %f \n", AntiWindup_Time);
    bi = PropCoff*PIDLoop_Time/IntTime;  //integral gain
    //rt_printk("PropCoff is %f \n", PropCoff);
    //rt_printk("IntTime is %f \n", IntTime);
    //in Astrom's article, ad is defined as below in the code, but the actual
    //derivation gives the coefficient we actually use
    //ad = (2*DiffTime- PID_cutoff_N*PIDLoop_Time)/(2*DiffTime+PID_cutoff_N*PIDLoop_Time);
    ad = (DiffTime)/(DiffTime+PID_cutoff_N*PIDLoop_Time);
    //rt_printk("DiffTime is %f \n", DiffTime);
    //same comment about bd
    //bd = 2*PropCoff*PID_cutoff_N*DiffTime/(2*DiffTime + PID_cutoff_N*PIDLoop_Time);    //derivative gain
    bd = PropCoff*PID_cutoff_N*DiffTime/(DiffTime + PID_cutoff_N*PIDLoop_Time);
    //rt_printk("MaxZVoltage is %f \n", MaxZVoltage);


    //Now calculate the initial means and variances
    //SummedPIDOutput = 0; //initialize parameters if we take averages
    //First means
    SummedFeedbackReading =0;
    //j=1;
    alpha =  ((float) 1)/(PID_averages+1);
    for (j=0;j<PID_averages;j++)
      {

        //make a first reading
        comedi_lock(dev_input, FeedbackChannel.subdevice);
        m = comedi_data_read(dev_input, FeedbackChannel.subdevice, FeedbackChannel.channel, AI_RANGE, AREF_DIFF, &data_from_card);
        comedi_unlock(dev_input, FeedbackChannel.subdevice);

        //Convert to a voltage reading
        SummedFeedbackReading += ((((float) data_from_card)/MaxInputBits)*InputRange + MinInputVoltage);
      }
    AveragedFeedbackReading =SummedFeedbackReading/PID_averages;

    if(DoChan1Average) {
      SummedChan1Reading = 0;
      for (j=0;j<PID_averages;j++)
        {

        //make a first reading
        comedi_lock(dev_chan1, Chan1Input.subdevice);
        m = comedi_data_read(dev_chan1, Chan1Input.subdevice, Chan1Input.channel, AI_RANGE, AREF_DIFF, &data_from_card);
        comedi_unlock(dev_chan1, Chan1Input.subdevice);

        //Convert to a voltage reading
        SummedChan1Reading += ((((float) data_from_card)/MaxInputBits)*InputRange + MinInputVoltage);
        }
      AveragedChan1Reading=SummedChan1Reading/PID_averages;
    }

    if(DoChan2Average) {
      SummedChan2Reading = 0;
      for (j=0;j<PID_averages;j++)
        {

        //make a first reading
        comedi_lock(dev_chan2, Chan2Input.subdevice);
        m = comedi_data_read(dev_chan2, Chan2Input.subdevice, Chan2Input.channel, AI_RANGE, AREF_DIFF, &data_from_card);
        comedi_unlock(dev_chan2, Chan2Input.subdevice);

        //Convert to a voltage reading
        SummedChan2Reading += ((((float) data_from_card)/MaxInputBits)*InputRange + MinInputVoltage);
        }
      AveragedChan2Reading=SummedChan2Reading/PID_averages;
    }

    //Since we are not changing the output, the mean has not changed, and the variance is 0
    M2_n = 0;
    PIDOutputVariance = 0;

    //Initialize the circular buffers
    for (j=0; j<PID_averages; j++)
      {
        push_queue(&FeedbackReading_queue, AveragedFeedbackReading);
        push_queue(&FeedbackReadingVar_queue, PIDOutputVariance);
        push_queue(&PIDOutput_queue, LastOutput);
        push_queue(&Chan1Input_queue, AveragedChan1Reading);
        push_queue(&Chan2Input_queue, AveragedChan2Reading);
      }

    //Now do the regular loop
    while(pid_loop_running)
      {
      //rt_printk("Got here 1 \n");
      //check to see if the PID parameters have changed
      if(PIDParametersChanged)
        {
          //update the PID coefficients
          bi = PropCoff*PIDLoop_Time/IntTime;  //integral gain
          ad = (DiffTime)/(DiffTime+PID_cutoff_N*PIDLoop_Time);
          bd = PropCoff*PID_cutoff_N*DiffTime/(DiffTime + PID_cutoff_N*PIDLoop_Time);
          PIDParametersChanged = 0;
        } //end of if(PIDParametersChanged)

      //continue with the rest of the loop

      //Read the input reading
      comedi_lock(dev_input, FeedbackChannel.subdevice);
      m = comedi_data_read(dev_input, FeedbackChannel.subdevice, FeedbackChannel.channel, AI_RANGE, AREF_DIFF, &data_from_card);
      comedi_unlock(dev_input, FeedbackChannel.subdevice);

      //Convert to a voltage reading
      FeedbackReading = ((((float) data_from_card)/MaxInputBits)*InputRange + MinInputVoltage);
      //rt_printk("Data from card is %d \n", data_from_card);
      //rt_printk("Feedback reading is %f \n", FeedbackReading);
      //rt_printk("Input m is %d \n", m);
      delta = (FeedbackReading - AveragedFeedbackReading);
      //AveragedFeedbackReading = alpha*FeedbackReading+(1-alpha)*AveragedFeedbackReading;  //running averange
      //PIDOutputVariance = alpha*(delta*delta) + (1-alpha)*PIDOutputVariance;
      //Venkat changed the following line to add logarithmic averaging on January 10, 2012
      if(Logarithmic){
        Error = AmplifierGainSign*OutputPhase*log10(fabs(FeedbackReading/SetPoint));
        }
       else {
         Error = AmplifierGainSign*OutputPhase*(SetPoint - FeedbackReading);//multiply by OutputPhase+AmplifierGainSign
       }
      //Error = AmplifierGainSign*OutputPhase*(SetPoint - FeedbackReading);//multiply by OutputPhase+AmplifierGainSign
      Pcontrib = PropCoff*(Error - LastError);
      //Not sure of sign of second contribution in line below...should it be - ?
      Dcontrib = ad*LastDiffContrib - bd*(Error - 2*LastError + SecondLastError);
      v = LastOutput + Pcontrib + Icontrib + Dcontrib;

      //next, take care of saturation of the output....anti-windup
      PIDOutput = v;
      PIDOutput =(PIDOutput>MaxOutputVoltage)? MaxOutputVoltage:PIDOutput;
      PIDOutput =(PIDOutput<MinOutputVoltage)? MinOutputVoltage:PIDOutput;

      //Calculate the averaged quantities
      pop_queue(&FeedbackReading_queue, &last_mean);
      AveragedFeedbackReading += (FeedbackReading - last_mean)/PID_averages;
      push_queue(&FeedbackReading_queue, FeedbackReading);

      pop_queue(&FeedbackReadingVar_queue, &last_var);
      new_var = delta*delta;
      PIDOutputVariance += (new_var - last_var)/PID_averages;
      push_queue(&FeedbackReadingVar_queue, new_var);

      //Now read and average Chan1 and Chan2 inputs only if we need to
      if(DoChan1Average) {
        comedi_lock(dev_chan1, Chan1Input.subdevice);
        m = comedi_data_read(dev_chan1, Chan1Input.subdevice, Chan1Input.channel, AI_RANGE, AREF_DIFF, &data_from_card);
        comedi_unlock(dev_chan1, Chan1Input.subdevice);

      //Convert to a voltage reading
      Chan1Reading = ((((float) data_from_card)/MaxInputBits)*InputRange + MinInputVoltage);

      //Calculate the averaged quantities
      pop_queue(&Chan1Input_queue, &Chan1_mean);
      AveragedChan1Reading += (Chan1Reading - Chan1_mean)/PID_averages;
      push_queue(&Chan1Input_queue, Chan1Reading);
      }

      if(DoChan2Average) {
        comedi_lock(dev_chan2, Chan2Input.subdevice);
        m = comedi_data_read(dev_chan2, Chan2Input.subdevice, Chan2Input.channel, AI_RANGE, AREF_DIFF, &data_from_card);
        comedi_unlock(dev_chan2, Chan2Input.subdevice);

      //Convert to a voltage reading
      Chan2Reading = ((((float) data_from_card)/MaxInputBits)*InputRange + MinInputVoltage);

      //Calculate the averaged quantities
      pop_queue(&Chan2Input_queue, &Chan2_mean);
      AveragedChan2Reading += (Chan2Reading - Chan2_mean)/PID_averages;
      push_queue(&Chan2Input_queue, Chan2Reading);
      }
      //send the control signal
      //rt_printk("FeedbackReading is %f \n", FeedbackReading);
      //rt_printk("v is %f \n", v);
      //rt_printk("PID output should be %f \n", PIDOutput);
      data_to_card = (lsampl_t) nearbyint(((PIDOutput - MinOutputVoltage)/OutputRange)*MaxOutputBits);
      //data_to_card = (lsampl_t) 0;
      comedi_lock(dev_output, ControlChannel.subdevice);
      m=comedi_data_write(dev_output, ControlChannel.subdevice, ControlChannel.channel, AO_RANGE, AREF_DIFF, data_to_card);
      comedi_unlock(dev_output, ControlChannel.subdevice);
      //rt_printk("Output m is %d \n", m);

      //Update the integral contribution after the loop
      Icontrib = bi*Error;

      //Update parameters
      LastError = Error;
      SecondLastError = LastError;
      LastDiffContrib = Dcontrib;
      LastOutput = PIDOutput;


      //rt_printk("PContrib is %f \n", Pcontrib);
      //rt_printk("IContrib is %f \n", Icontrib);
      //rt_printk("DContrib is %f \n", Dcontrib);
      //rt_printk("PIDOutput is %f \n", PIDOutput);

      //Next part is to take the averaged PID output for recording if j>PID_averages and PID_averages>1
      //SummedPIDOutput+=PIDOutput;
      //SummedFeedbackReading += FeedbackReading;
      //j++;
      //AveragedPIDOutput=((PID_averages>1)&&(j>PID_averages))?(SummedPIDOutput/PID_averages):AveragedPIDOutput;
      //AveragedFeedbackReading=((PID_averages>1)&&(j>PID_averages))?(SummedFeedbackReading/PID_averages):AveragedFeedbackReading;
      //SummedPIDOutput=(j>PID_averages)? 0:SummedPIDOutput;
      //SummedFeedbackReading=(j>PID_averages)? 0:SummedFeedbackReading;
      //j=(j>PID_averages)? 1:j;

      //Calculate moving exponential averages and variance
      //delta = PIDOutput - AveragedPIDOutput;
      //AveragedPIDOutput = alpha*PIDOutput + (1-alpha)*AveragedPIDOutput;
      //PIDOutputVariance = alpha*(delta*delta) + (1-alpha)*PIDOutputVariance;
      //PIDOutputVariance = alpha*abs(delta) + (1-alpha)*PIDOutputVariance;

      pop_queue(&PIDOutput_queue, &last_mean);
      AveragedPIDOutput += (PIDOutput - last_mean)/PID_averages;
      push_queue(&PIDOutput_queue, PIDOutput);
         // And wait until the end of the period.
        rt_task_wait_period();

       }

    //rt_printk("Got here 3 \n");
    //rt_printk("pid_loop_running is %d \n", pid_loop_running);
    rt_make_soft_real_time();
    comedi_close(dev_input);
    comedi_close(dev_output);
    rt_task_delete(PIDloop_Task); //Self termination at end.

    //pthread_exit(NULL);
    return 0;


}

