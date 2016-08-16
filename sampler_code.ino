// Constants
#define BAUD            (57600)
#define MAX_BUF         (64)
#define STEPS_PER_TURN  (200)
#define MICROSTEPS      (16)
#define NUM_AXES        (4)
#define MAX_FEEDRATE    (1000000)
#define MIN_FEEDRATE    (1)

// Structs
typedef struct {
  int step_pin;
  int dir_pin;
  int enable_pin;
  int switch_pin;
  float steps_per_mm;
  long pos;           // position in microsteps
  long min_pos;       // minimum position on axis in microsteps (usually 0)
  long max_pos;       // maximum position on axis in microsteps
  int dir;            // used for movement
  bool invert;        // flips the motor direction
} Motor;

// Vars
Motor motors[NUM_AXES];
char buffer[MAX_BUF];
int sofar;
boolean abs_mode;
boolean mm_mode;

// speeds
long fr = 0;
long step_delay;

// Methods

/**
 * Set the feedrate (speed motors will move)
 * @input nfr the new speed in steps/second
 */
void set_feedrate(long nfr) {
  if(fr == nfr) return;  // same as last time?  quit now.

  if(nfr > MAX_FEEDRATE || nfr < MIN_FEEDRATE) {  // don't allow crazy feed rates
    Serial.print(F("New feedrate must be greater than "));
    Serial.print(MIN_FEEDRATE);
    Serial.print(F("steps/s and less than "));
    Serial.print(MAX_FEEDRATE);
    Serial.println(F("steps/s."));
    return;
  }
  step_delay = MAX_FEEDRATE / nfr;
  fr = nfr;
}

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
  Serial.println(F("G00 [X/Y/Z/E(microsteps)] [F(steps/sec)]; - rapid move"));
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
 * set up the motor pins and variables
 */
void motor_setup() {
  motors[0].step_pin = 54;
  motors[0].dir_pin = 55;
  motors[0].enable_pin = 38;
  motors[0].switch_pin = 3;
  motors[0].steps_per_mm = STEPS_PER_TURN * MICROSTEPS / 50;
  motors[0].pos = 1;  // ensures it will zero on startup
  motors[0].min_pos = 0;
  motors[0].max_pos = 220 * motors[0].steps_per_mm;
  motors[0].invert = true;

  motors[1].step_pin = 60;
  motors[1].dir_pin = 61;
  motors[1].enable_pin = 56;
  motors[1].switch_pin = 14;
  motors[1].steps_per_mm = STEPS_PER_TURN * MICROSTEPS / 50;
  motors[1].pos = 1;  // ensures it will zero on startup
  motors[1].min_pos = 0;
  motors[1].max_pos = 200 * motors[1].steps_per_mm;
  motors[1].invert = false;

  motors[2].step_pin = 46;
  motors[2].dir_pin = 48;
  motors[2].enable_pin = 63;
  motors[2].switch_pin = 18;
  motors[2].steps_per_mm = STEPS_PER_TURN * MICROSTEPS / 1.2;
  motors[2].pos = 1;  // ensures it will zero on startup
  motors[2].min_pos = 0;
  motors[2].max_pos = 200 * motors[2].steps_per_mm;
  motors[2].invert = false;

  motors[3].step_pin = 26;
  motors[3].dir_pin = 28;
  motors[3].enable_pin = 24;
  motors[3].switch_pin = -1;
  motors[3].steps_per_mm = STEPS_PER_TURN * MICROSTEPS / 14;
  motors[3].pos = 0;
  motors[3].min_pos = 0;
  motors[3].max_pos = 57 * motors[3].steps_per_mm;
  motors[3].invert = true;

  for(int i = 0; i < NUM_AXES; i++) {  
    // set the motor pin & scale
    pinMode(motors[i].step_pin, OUTPUT);
    pinMode(motors[i].dir_pin, OUTPUT);
    pinMode(motors[i].enable_pin, OUTPUT);
    if (motors[i].switch_pin > 0){
      pinMode(motors[i].switch_pin, INPUT_PULLUP);
    }
  }
}

/**
 * 
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
    case 0:  // move
      set_feedrate(parseNumber('F', fr));
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
    case 90:
      abs_mode = true;
      Serial.println("mode set to absolute, enter positions to move to them"); 
      break;
    case 91:
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
 * enables all motors
 */
void motor_enable() {
  for(int i = 0 ; i < NUM_AXES; i++) {  
    digitalWrite(motors[i].enable_pin,LOW);
  }
}

/**
 * disables all motors
 */
void motor_disable() {
  for(int i = 0 ; i < NUM_AXES; i++) {  
    digitalWrite(motors[i].enable_pin,HIGH);
  }
}

/**
 * reposition without linear interpolation
 */
void rapid_move(long newX, long newY, long newZ, long newE) {
  // store new position
  long new_pos[NUM_AXES];
  new_pos[0] = newX;
  new_pos[1] = newY;
  new_pos[2] = newZ;
  new_pos[3] = newE;
  
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

  // loop till all positions correct
  int check;
  do {
    check = 0;
    // loop through motors
    for(int i = 0; i < NUM_AXES; i++){
      // move motor if it isn't at new position
      if (motors[i].pos != new_pos[i]){
        digitalWrite(motors[i].step_pin, HIGH);
        digitalWrite(motors[i].step_pin, LOW);
        check++;
        motors[i].pos += motors[i].dir;
      }
    }
    delayMicroseconds(step_delay);
  } while(check != 0);
  where();
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

  // loop until no more moves are necessary
  int check;
  do {
    check = 0;
    for(int i = 0; i < NUM_AXES; i++) {
      if(motors[i].pos > 0){
        if (motors[i].switch_pin > 0){              // if there is a switch, move until it triggers then set that position to zero
          if (digitalRead(motors[i].switch_pin)){   // check if switch is triggered
            motors[i].pos = 0;          
          } else{
            digitalWrite(motors[i].step_pin, HIGH);
            digitalWrite(motors[i].step_pin, LOW);
          }
        } else {                                    // if there is no switch, just reset the position to what it thinks is zero
          digitalWrite(motors[i].step_pin, HIGH);
          digitalWrite(motors[i].step_pin, LOW);
          motors[i].pos--;
        }
        check++;
      }
    }
    delayMicroseconds(step_delay);
  } while(check != 0);
  where();
}

/**
 * runs once on startup
 */
void setup() {
  Serial.begin(BAUD);
  
  motor_setup();
  motor_enable();
  
  help();
  //zero_position();
  set_feedrate(1000);
  abs_mode = true;
  mm_mode = false;
  ready();
}

/**
 * loops forever
 */
void loop() {
  while( Serial.available() > 0) {  // if something is there
    char c = Serial.read();         // get it 
    Serial.print(c);                // repeat it back

    if(sofar < MAX_BUF) {           // store it
      buffer[sofar++] = c;
    }
    if(c == '\n') {
      // entire message recieved
      Serial.print(F("\r\n"));
      buffer[sofar] = 0;
      processCommand();             // perform the command
      ready();
    }
  }
}

