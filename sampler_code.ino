/**
* G-code interpreter for the Delwiche-Sampler project
*   
* Copyright 2016 Chas Parr <cxp2265@rit.edu>
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
* Some of the following code is derived from the GcodeCNCDemo project
* http://www.github.com/MarginallyClever/GcodeCNCDemo
*/

/**
 * This sketch allows the sampler to interpret g-code commands sent to it via serial port.
 * 
 * In the Arduino IDE under 'tools' set the board to "Arduino/Genuino Mega or Mega 2560", 
 * and the port to whichever one the Arduino is connected to.
 * 
 * While uploading to the arduino, hold a screwdriver between the prongs on the port labeled "JPROG" 
 * until the upload is complete
 * 
 * The Serial Monitor tool in the IDE can be used to send G-code directly to the machine for testing purposes
 */

//------------------------------------------------------------
// Constants
//------------------------------------------------------------
#define BAUD            (57600)   // communication rate
#define MAX_BUF         (64)      // how long of a message can be stored
#define STEPS_PER_TURN  (200)     // the number of full steps for one revolution of a stepper motor
#define MICROSTEPS      (16)      // the number of microsteps each step is divided into
#define NUM_AXES        (4)       // the number of axes that can be moved along (X, Y, Z, E)
#define MAX_FEEDRATE    (1000000) // the highest speed (no delay between steps)
#define MIN_FEEDRATE    (1)

//------------------------------------------------------------
// Structs
//------------------------------------------------------------
/**
 * Motor struct
 * stores pin locations, motor/axis settings, and positional information
 */
typedef struct {
  int step_pin;       // this pin makes the motor step
  int dir_pin;        // this pin controls the motor direction
  int enable_pin;     // this pin enables the motor
  int switch_pin;     // this pin reads from an end stop if there is one, otherwise set it to -1
  float steps_per_mm; // the number of microsteps it takes to move the axis linearly one mm
  bool invert;        // flips the motor direction
  long pos;           // absolute position in microsteps
  long min_pos;       // minimum position on axis in microsteps (usually 0)
  long max_pos;       // maximum position on axis in microsteps
  int dir;            // set to 1 or -1 when moving, used to increment position
} Motor;

//------------------------------------------------------------
// Vars
//------------------------------------------------------------
Motor motors[NUM_AXES]; // stores the motors
char buffer[MAX_BUF];   // stores command till it hits a ';'
int sofar;              // position in buffer
boolean abs_mode;     
  // absolute mode (true): move commands are given as a position to move to
  // relative mode (false): move commands are given as a distance to move

boolean mm_mode;
  // (true): distances are read as millimeters
  // (false): distances are read as micro steps

// speeds
long fr = 0;            // feed rate
long step_delay;        // the delay between steps, derived from the feed rate

//------------------------------------------------------------
// Methods
//------------------------------------------------------------
/**
 * Set the feedrate (speed motors will move)
 * @input nfr the new speed in steps/second
 */
void set_feedrate(long nfr) {
  if(fr == nfr) return;  // quit if no change

  if(nfr > MAX_FEEDRATE || nfr < MIN_FEEDRATE) {  // don't allow crazy feed rates
    Serial.print(F("New feedrate must be greater than "));
    Serial.print(MIN_FEEDRATE);
    Serial.print(F("steps/s and less than "));
    Serial.print(MAX_FEEDRATE);
    Serial.println(F("steps/s."));
    return;
  }
  step_delay = MAX_FEEDRATE / nfr;  // calculate the delay between steps
  fr = nfr;
}

/**
 * provide positional information
 */
void where() {
  Serial.print("X ");
  Serial.print(motors[0].pos / motors[0].steps_per_mm);
  Serial.print("mm ");
  Serial.print(motors[0].pos);
  Serial.println(" micro steps");
  Serial.print("Y ");
  Serial.print(motors[1].pos / motors[1].steps_per_mm);
  Serial.print("mm ");
  Serial.print(motors[1].pos);
  Serial.println(" micro steps");
  Serial.print("Z ");
  Serial.print(motors[2].pos / motors[2].steps_per_mm);
  Serial.print("mm ");
  Serial.print(motors[2].pos);
  Serial.println(" micro steps");
  Serial.print("E ");
  Serial.print(motors[3].pos / motors[3].steps_per_mm);
  Serial.print("mm ");
  Serial.print(motors[3].pos);
  Serial.println(" micro steps");
  Serial.print("F ");
  Serial.println(fr);
}

/**
 * print helpful info
 */
void help() {
  Serial.println(F("Commands:"));
  Serial.println(F("G00 [X/Y/Z/E(steps or mm)] [F(steps/sec)]; - rapid move"));
  Serial.println(F("G21; - set units to mm"));  
  Serial.println(F("G24; - set units to micro steps"));  
  Serial.println(F("G28; - zero position"));  
  Serial.println(F("G90; - absolute mode"));
  Serial.println(F("G91; - relative mode"));
  Serial.println(F("M17; - enable motors"));
  Serial.println(F("M18; - disable motors"));
  Serial.println(F("M100; - this help message"));
  Serial.println(F("M114; - report position and feedrate"));
  
}

/**
 * set up the motor pins and settings
 */
void motor_setup() {
  // x-axis
  motors[0].step_pin = 54;
  motors[0].dir_pin = 55;
  motors[0].enable_pin = 38;
  motors[0].switch_pin = 3;
  motors[0].steps_per_mm = STEPS_PER_TURN * MICROSTEPS / 50;  // one full revolution moves 50mm
  motors[0].pos = 1;  // ensures it can zero on startup
  motors[0].min_pos = 0;
  motors[0].max_pos = 220 * motors[0].steps_per_mm; // max position is 220mm from zero
  motors[0].invert = true;

  // y-axis
  motors[1].step_pin = 60;
  motors[1].dir_pin = 61;
  motors[1].enable_pin = 56;
  motors[1].switch_pin = 14;
  motors[1].steps_per_mm = STEPS_PER_TURN * MICROSTEPS / 50;  // one full revolution moves 50mm
  motors[1].pos = 1;  // ensures it can zero on startup
  motors[1].min_pos = 0;
  motors[1].max_pos = 200 * motors[1].steps_per_mm; // max position is 200mm from zero
  motors[1].invert = false;

  // z-axis
  motors[2].step_pin = 46;
  motors[2].dir_pin = 48;
  motors[2].enable_pin = 63;
  motors[2].switch_pin = 18;
  motors[2].steps_per_mm = STEPS_PER_TURN * MICROSTEPS / 1.2;  // one full revolution moves 1.2mm
  motors[2].pos = 1;  // ensures it can zero on startup
  motors[2].min_pos = 0;
  motors[2].max_pos = 200 * motors[2].steps_per_mm; // max position is 200mm from zero
  motors[2].invert = false;

  // extruder
  motors[3].step_pin = 26;
  motors[3].dir_pin = 28;
  motors[3].enable_pin = 24;
  motors[3].switch_pin = -1;
  motors[3].steps_per_mm = STEPS_PER_TURN * MICROSTEPS / 14;  // one full revolution moves 14mm
  motors[3].pos = 0;  // prevent it from trying to zero on startup
  motors[3].min_pos = 0;
  motors[3].max_pos = 57 * motors[3].steps_per_mm; // max position is 57mm from zero
  motors[3].invert = true;

  for(int i = 0; i < NUM_AXES; i++) {  
    
    // set up the motor pins
    pinMode(motors[i].step_pin, OUTPUT);
    pinMode(motors[i].dir_pin, OUTPUT);
    pinMode(motors[i].enable_pin, OUTPUT);
    
    // set up the switch pin if there is an endstop
    if (motors[i].switch_pin > 0){
      pinMode(motors[i].switch_pin, INPUT_PULLUP);
    }
  }
}

/**
 * prepare for the next command
 */
void ready() {
  sofar = 0;
  Serial.print(F("> "));
}

/**
 * Look for character /code/ in the buffer and read the float that immediately follows it.
 * @return the value found.  If nothing is found, /val/ is returned.
 * @input code the character to look for.
 * @input val the return value if /code/ is not found.
 */
float parseNumber(char code, float val) {
  char *ptr = buffer;
  while(ptr && *ptr && ptr < buffer + sofar) {
    if(*ptr == code) {
      return atof(ptr + 1);
    }
    ptr = strchr(ptr, ' ') + 1;
  }
  return val;
}

/**
 * Read the input buffer and find any recognized commands.  One G or M command per line.
 */
void processCommand() {
  int cmd = parseNumber('G', -1);
  switch(cmd) {
    case 0:  // rapid move command
      set_feedrate(parseNumber('F', fr));
      
      // read positions into rapid_move
      // if a position is unspecified it defaults to no movement
      // in mm mode the input is multiplied by 100 to preserve decimals
      if (!abs_mode){
        if (mm_mode){
          rapid_move( parseNumber('X', 0) * 100,
                      parseNumber('Y', 0) * 100,
                      parseNumber('Z', 0) * 100,
                      parseNumber('E', 0) * 100);
        } else{
          rapid_move( parseNumber('X', 0),
                      parseNumber('Y', 0),
                      parseNumber('Z', 0),
                      parseNumber('E', 0) );
        }
      } else {
        if (mm_mode){
          rapid_move( parseNumber('X', motors[0].pos / motors[0].steps_per_mm) * 100,
                      parseNumber('Y', motors[1].pos / motors[1].steps_per_mm) * 100,
                      parseNumber('Z', motors[2].pos / motors[2].steps_per_mm) * 100,
                      parseNumber('E', motors[3].pos / motors[3].steps_per_mm) * 100);
          
        } else{
          rapid_move( parseNumber('X', motors[0].pos),
                      parseNumber('Y', motors[1].pos),
                      parseNumber('Z', motors[2].pos),
                      parseNumber('E', motors[3].pos) );
        }
      }
      break;
    case 21:  // set units to mm
      mm_mode = true;
      Serial.println("input set to mm"); 
      break;
    case 24:  // set units to micro steps
      mm_mode = false;
      Serial.println("input set to micro steps"); 
      break;
    case 28:  // zero position
      zero_position();
      break;
    case 90:  // set to absolute mode
      abs_mode = true;
      Serial.println("mode set to absolute, enter positions to move to them"); 
      break;
    case 91:  // set to relative mode
      abs_mode = false;
      Serial.println("mode set to relative, enter distances to move"); 
      break;
    default: break;
    }
  
  cmd = parseNumber('M',-1);
  switch(cmd) {
    case  17:  motor_enable();  break;
    case  18:  motor_disable();  break;
    case 100:  help();  break;
    case 114:  where(); break;
    default:  break;
  }
}

/**
 * enable all motors
 */
void motor_enable() {
  for(int i = 0 ; i < NUM_AXES; i++) {  
    digitalWrite(motors[i].enable_pin,LOW);
  }
}

/**
 * disable all motors
 */
void motor_disable() {
  for(int i = 0 ; i < NUM_AXES; i++) {  
    digitalWrite(motors[i].enable_pin,HIGH);
  }
}

/**
 * reposition without linear interpolation
 * @input newX the new x position (abs mode) or the distance to move along the x axis (rel mode)
 * @input newY the new y position (abs mode) or the distance to move along the y axis (rel mode)
 * @input newZ the new z position (abs mode) or the distance to move along the z axis (rel mode)
 * @input newE the new e position (abs mode) or the distance to move along the e axis (rel mode)
 * if in mm mode, the inputs are expected to be multiplied by 100 to preserve decimal places
 */
void rapid_move(long newX, long newY, long newZ, long newE) {
  
  // store new positions
  long new_pos[NUM_AXES];
  new_pos[0] = newX;
  new_pos[1] = newY;
  new_pos[2] = newZ;
  new_pos[3] = newE;

  // if in mm mode, convert the input (mm to move * 100) into microsteps
  if (mm_mode){
    for(int i = 0; i < NUM_AXES; i++){
      new_pos[i] *= (motors[i].steps_per_mm / 100);
    }
  }
  
  // add curent positions if in relative mode
  if (!abs_mode) {
    for(int i = 0; i < NUM_AXES; i++){
      new_pos[i] += motors[i].pos;
    }
  }
  
  
  for(int i = 0; i < NUM_AXES; i++){
    
    // check position validity and prevent illegal moves
    if (new_pos[i] > motors[i].max_pos){
      Serial.println("Move out of bounds, position now set to max");
      new_pos[i] = motors[i].max_pos;
    } else if (new_pos[i] < motors[i].min_pos){
      Serial.println("Move out of bounds, position now set to min");
      new_pos[i] = motors[i].min_pos;
    }
    
    // set direction
    if (new_pos[i] > motors[i].pos){
      motors[i].dir = 1;
      if (motors[i].invert){
        digitalWrite(motors[i].dir_pin, LOW);
      } else{
        digitalWrite(motors[i].dir_pin, HIGH);
      }
    } else{
      motors[i].dir = -1;
      if (motors[i].invert){
        digitalWrite(motors[i].dir_pin, HIGH);
      } else{
        digitalWrite(motors[i].dir_pin, LOW);
      }
    }
  }

  int check;
  do {                                    // loop until all motors have finished moving
    check = 0;
    for(int i = 0; i < NUM_AXES; i++){      // loop through motors
      if (motors[i].pos != new_pos[i]){       // check if motor in correct position
        digitalWrite(motors[i].step_pin, HIGH); // step motor
        digitalWrite(motors[i].step_pin, LOW);
        check++;                                // indicate that a move was made
        motors[i].pos += motors[i].dir;         // update position
      }
    }
    delayMicroseconds(step_delay);          // delay to control speed
  } while(check != 0);                    // check if any moves were made
  where();                                // report position
}

/**
 * move to endstops, 
 */
void zero_position(){
  
  // set direction
  for (int i = 0; i < NUM_AXES; i++){
    if (motors[i].invert){
      digitalWrite(motors[i].dir_pin, HIGH);
    } else{
      digitalWrite(motors[i].dir_pin, LOW);
    }
  }


  int check;
  do {
    check = 0;                                // loop until all axes are at zero
    for(int i = 0; i < NUM_AXES; i++) {         // loop through motors
      if(motors[i].pos > 0){                      // only move if not already at zero
        if (motors[i].switch_pin > 0){              // check if there is a switch
          if (digitalRead(motors[i].switch_pin)){     // check if switch is triggered
            motors[i].pos = 0;                          // set position to zero 
          } else{                                     // otherwise
            digitalWrite(motors[i].step_pin, HIGH);     // step motor
            digitalWrite(motors[i].step_pin, LOW);
          }
        } else {                                    // if there is no switch, just reset the position to what it thinks is zero
          digitalWrite(motors[i].step_pin, HIGH);
          digitalWrite(motors[i].step_pin, LOW);
          motors[i].pos--;
        }
        check++;                                  // indicate that a move was made
      }
    }
    delayMicroseconds(step_delay);              // delay to control speed
  } while(check != 0);                        // check if any moves were made
  where();                                    // report position
}

/**
 * runs once on startup
 */
void setup() {
  Serial.begin(BAUD);
  
  motor_setup();
  motor_disable();  // motors should be turned on when the control software is run
  
  help();
  //zero_position();
  set_feedrate(1000);
  abs_mode = true;
  mm_mode = true;
  ready();
}

/**
 * loops forever
 */
void loop() {
  while( Serial.available() > 0) {  // if something is there
    char c = Serial.read();           // get it 
    Serial.print(c);                  // repeat it back
    if(sofar < MAX_BUF - 1) {         // check if there is room in the buffer
      buffer[sofar++] = c;              // store it
    }
    if(c == '\n') {                   // check if the line ends
      Serial.print(F("\r\n"));          // display a line end
      buffer[sofar] = 0;                // end the buffer
      processCommand();                 // perform the command
      ready();                          // prepare to recieve the next command
    }
  }
}

