unit WalkerFunctions;

interface
var
    Approaching      : boolean = FALSE;
    
function Retract_Walker: boolean;
function Stop_Walker: boolean;
function Approach_Walker: boolean;
function Walker_Down_Step(time: integer):boolean;
function Walker_Up_Step(time: integer):boolean;

implementation
uses NI6733, SPMUtilities, TipCoarseApproach;

const
//Frequency of square wave for walker flip-flops
  Square_wave_frequency = 10000;
//Delay time after which the counter sends out the pulse to the flip-flops
  Pulse_delay_time = 12.5; //in msec
//Pulse width, also in msec
  Pulse_width = 1;


{----------------------------------------------------------------------------}
function Retract_Walker: boolean;
begin
  //call the routine that generates the square wave for the flip-flops
  //Frequency is 10 kHz
  Generate_square_wave(Square_wave_frequency);
  //Then call the routine that sends a pulse to the start the walker
  //the first parameter is the delay, the second is the pulse width, both
  //in msec
  Send_retract_pulse(Pulse_delay_time, Pulse_width);
  Dec(CoarseApproachStepNumber);
  Retract_Walker:=TRUE;
end;

{----------------------------------------------------------------------------}
function Approach_Walker: boolean;
begin
  //call the routine that generates the square wave for the flip-flops
  //Frequency is 10 kHz
  Generate_square_wave(Square_wave_frequency);
  //Then call the routine that sends a pulse to the start the walker
  //the first parameter is the delay, the second is the pulse width, both
  //in msec
  Send_approach_pulse(Pulse_delay_time, Pulse_width);
  Inc(CoarseApproachStepNumber);
  Approach_Walker:=TRUE;
end;
{----------------------------------------------------------------------------}
function Stop_Walker: boolean;
begin
  //call the routine that generates the square wave for the flip-flops
  Reset_Counters; //reset both counters
  Stop_Walker:=TRUE;
end;

{-----------------------------------------------------------------------------}
function Walker_Down_Step(time: integer):boolean;
begin
  Approach_Walker;
  delay(time);
  Stop_Walker;
  Walker_down_Step:=TRUE;
end;

function Walker_Up_Step(time: integer):boolean;
begin
  Retract_Walker;
  delay(time);
  Stop_Walker;
  Walker_Up_Step:=TRUE;
end;
end.
