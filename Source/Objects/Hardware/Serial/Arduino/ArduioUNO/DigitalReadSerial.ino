
#include <CmdMessenger.h> //https://github.com/dreamcat4/cmdmessenger
#include <Streaming.h>    //http://arduiniana.org/libraries/streaming/

char field_separator      = ',';
char command_separator    = ';';
char eol				  = '\r';
unsigned short inputMask  = 0x0; 
unsigned short oldInputs  = 0x0;
unsigned short controlValue[10]    = {0,0,0,0,0,0,0,0,0,0};

// Attach a new CmdMessenger object to the default Serial port
CmdMessenger cmdMessenger = CmdMessenger(Serial, field_separator, command_separator);

//Commands from ORCA (never sent unsolicited)
short kCmdVerison			= 1;  //1;
short kCmdReadAdcs			= 2;  //2;             --read all adcs
short kCmdReadInputs		= 3;  //3,mask;        --read input pins using mask
short kCmdWriteAnalog		= 4;  //4,pin,value;   --set pin pwm to value
short kCmdWriteOutput		= 5;  //5,pin,value;   --set output pin to value
short kCmdWriteOutputs		= 6;  //6,mask;        --set outputs based on mask
short kCmdSetControlValue	= 7;  //7,chan,value;  --set control value. chan 0-9. value is unsigned short

//Messages which can be sent unsolicited to ORCA.
short kInputsChanged		= 20; //20,i0,i1,i2,...i13;
short kCustomValueChanged   = 21; //21,chan,value
short kAdcValueChanged		= 22; //22,chan,value
short kArduinoStarted		= 23;
short kUnKnownCmd			= 99;

float kSketchVersion = 1.1; //change whenever command formats change

// ------------------ C A L L B A C K  M E T H O D S -------------------------
void readAnalogValues()
{
    Serial<<2;
    for(char i=0;i<6;i++) Serial << "," << analogRead(i);
    Serial<< eol;
}

void readInputPins()
{
    inputMask = cmdMessenger.readInt();
    Serial << kCmdReadInputs;
    for (char i=0;i<14;i++) {
      if(inputMask & (1<<i)) {
        if(i>=2){
           pinMode(i, INPUT_PULLUP);
           Serial << "," << digitalRead(i);
        }
        else Serial<<",0"; //return 0 for the serial lines
      }
      else   Serial<<",0";
    }
    Serial<<eol;
}

void writeOutputPin()
{
      short pin   = cmdMessenger.readInt();  
      short state = cmdMessenger.readInt();
      if(pin>=2 && (~inputMask & (1<<pin))){
         pinMode(pin,OUTPUT);  
         if( state)  digitalWrite(pin,HIGH);
         else        digitalWrite(pin,LOW);
      }
      Serial<< kCmdWriteOutput << "," << pin << "," << state << eol;
}
  

void writeOutputs()
{
    short pin;
    short outputTypeMask  = cmdMessenger.readInt() & ~inputMask; //don't write inputs
    short writeMask       = cmdMessenger.readInt() & ~inputMask;  
    if(outputTypeMask){
      for(pin=2;pin<14;pin++){
        if(outputTypeMask & (1<<pin)){
           pinMode(pin,OUTPUT);
           if( writeMask & (1<<pin))  digitalWrite(pin,HIGH);
           else                       digitalWrite(pin,LOW);
        }
      }
    }
    else writeMask = 0;
    //echo the command back
    Serial << kCmdWriteOutputs << "," << outputTypeMask << "," << writeMask << eol;
}

void writeAnalog()
{
     short pin   = cmdMessenger.readInt(); 
     short state = cmdMessenger.readInt();
      if(pin>=2 && (~inputMask & (1<<pin))){
        pinMode(pin, OUTPUT);
        analogWrite(pin, state); //Sets the PWM value of the pin 
      }
      //echo the command back
      Serial<< kCmdWriteAnalog << "," << pin << "," << state << eol;
}

void setControlValue()
{
	//users can use this value in their custom code as needed.
    short chan  = cmdMessenger.readInt();
    unsigned short value = cmdMessenger.readInt(); 
    if(chan>=0 && chan<10){
		controlValue[chan] = value;
    }
    //echo the command back
    Serial << kCmdSetControlValue << "," << chan << "," << value << eol;
}


void sketchVersion()  { Serial << kCmdVerison<<","<< kSketchVersion << eol;   }
void unKnownCmd()     { Serial << kUnKnownCmd << eol;  }

// ------------------ E N D  C A L L B A C K  M E T H O D S ------------------

void setup() 
{
  Serial.begin(115200); // Arduino Uno, Mega, with AT8u2 USB

  cmdMessenger.print_LF_CR();
  cmdMessenger.attach(kCmdVerison,     sketchVersion);
  cmdMessenger.attach(kCmdReadAdcs,    readAnalogValues);
  cmdMessenger.attach(kCmdReadInputs,  readInputPins);
  cmdMessenger.attach(kCmdWriteAnalog, writeAnalog);
  cmdMessenger.attach(kCmdWriteOutput, writeOutputPin);
  cmdMessenger.attach(kCmdWriteOutputs,writeOutputs);
  cmdMessenger.attach(kCmdSetControlValue,setControlValue);

  cmdMessenger.attach(unKnownCmd);
  
  //Tell the world we had a reset
  Serial << kArduinoStarted << ",Reset"<< eol;
  
}

void loop() 
{
  cmdMessenger.feedinSerialData(); //process incoming commands
  scanInputsForChange();
  customMethod(); //users can put custom code in here
}

void scanInputsForChange()
{
  if(inputMask){
      unsigned short inputs = 0;
      if(inputMask){
        for (char i=2;i<14;i++) {
          if(inputMask & (1<<i)){
            inputs |= ((unsigned short)debouncedDigitalRead(i) << i);
          }
        }
        if(inputs != oldInputs){
          oldInputs = inputs;
          Serial << kInputsChanged << "," << inputs <<  eol;
        }
      }
  }
}

boolean         lastPinState[14];
boolean         pinState[14];
unsigned long   lastDebounceTime[14];
unsigned long   debounceDelay = 50;

boolean debouncedDigitalRead(int aPin)
{
  boolean currentValue = digitalRead(aPin);
  if (currentValue != lastPinState[aPin]) lastDebounceTime[aPin] = millis();
  if ((millis() - lastDebounceTime[aPin]) > debounceDelay) pinState[aPin] = currentValue;
  lastPinState[aPin] = currentValue;
  return pinState[aPin];
}

//--------------------------------------------------------------
void customMethod()
{
	//default is to do nothing
	//Users can put specialized code here if needed.
	//customValues can be sent back to ORCA with the customValue commands
	//example:  kCustomValueChanged,channelNumber,value;
	//Serial << kCustomValueChanged << "," << 0 << "," << 123 << eol;
}
