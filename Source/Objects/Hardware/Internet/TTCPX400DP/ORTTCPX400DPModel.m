//
//  ORTTCPX400DPModel.m
//  Orca
//
//  Created by Michael Marino on Thurs Nov 10 2011.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORTTCPX400DPModel.h"
#import "NetSocket.h"
#import "ORVXI11HardwareFinder.h"

#define ORTTCPX400DPPort 9221

NSString* ORTTCPX400DPDataHasArrived = @"ORTTCPX400DPDataHasArrived";
NSString* ORTTCPX400DPConnectionHasChanged = @"ORTTCPX400DPConnectionHasChanged";
NSString* ORTTCPX400DPIpHasChanged = @"ORTTCPX400DPIpHasChanged";
NSString* ORTTCPX400DPSerialNumberHasChanged = @"ORTTCPX400DPSerialNumberHasChanged";
NSString* ORTTCPX400DPModelLock = @"ORTTCPX400DPModelLock";
NSString* ORTTCPX400DPGeneralReadbackHasChanged = @"ORTTCPX400DPGeneralReadbackHasChanged";
NSString* ORTTCPX400DPVerbosityHasChanged = @"ORTTCPX400DPVerbosityHasChanged";
NSString* ORTTCPX400DPErrorSeen = @"ORTTCPX400DPErrorSeen";

struct ORTTCPX400DPCmdInfo;

@interface ORTTCPX400DPModel (private)
- (void) _connectIP;
- (void) _readoutThreadSocketSend:(NSString*) data;
- (void) _setIsConnected:(BOOL)connected;
- (void) _addCommandToDataProcessingQueue:(struct ORTTCPX400DPCmdInfo*)theCmd 
                           withSendString:(NSString*)cmdStr 
                   withReturnSelectorName:(NSString*)selName
                        withOutputNumber:(unsigned int)output;    
- (void) _processNextReadCommandInQueueWithInputString:(NSString *)input;
- (void) _processNextWriteCommandInQueue;
- (void) _writeCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNum:(int)output withSelectorName:(NSString*)selName;
- (void) _processGeneralReadback:(NSNumber*)aFloat withOutputNum:(NSNumber*) anInt;
- (void) _processGeneralReadback:(NSNumber*)aFloat;
- (void) _setGeneralReadback:(NSString*)read;
- (void) _socketThread:(NSString*)anIpAddress;
- (void) _connectSocket:(NSString*)anIpAddress;
- (void) _setSocket:(NetSocket*)aSocket;
- (void) _syncReadoutSetToModel;
- (void) _registerNotificationObservers;
- (void) _hwFinderChanged:(NSNotification*)aNote;

@end

#define STRINGIFY2( x) #x
#define STRINGIFY(x) STRINGIFY2(x)
#define NSSTRINGIFY(b) @b

#define ORTTCPX400DP_NOTIFY_STRING(X)     \
NSString* X = NSSTRINGIFY( STRINGIFY(X));

#define ORTTCPX_READ_IMPLEMENT_NOTIFY(CMD)  \
ORTTCPX400DP_NOTIFY_STRING( ORTTCPX_NOTIFY_READ_FORM(CMD) )

#define ORTTCPX_WRITE_IMPLEMENT_NOTIFY(CMD) \
ORTTCPX400DP_NOTIFY_STRING( ORTTCPX_NOTIFY_WRITE_FORM(CMD) )

#define ORTTCPX_GEN_IMPLEMENT(CMD, TYPE, PREPENDFUNC, UC, LC, PREPENDVAR)   \
- (void) PREPENDFUNC##setAndNotify##UC##PREPENDVAR##CMD:(TYPE)aVal          \
withOutput:(unsigned int)output sendCommand:(BOOL)cmd                       \
{                                                                           \
    assert(output < kORTTCPX400DPOutputChannels);                           \
    LC ## PREPENDVAR ## CMD[output] = aVal;                                 \
    if (cmd) [self sendCommand ## UC ## PREPENDVAR ## CMD ## WithOutput:output];     \
    [[NSNotificationCenter defaultCenter]                                   \
 postNotificationOnMainThreadWithName:ORTTCPX400DP ##UC##PREPENDVAR ## CMD ## IsChanged \
     object:self];                                                          \
}                                                                           \
                                                                            \
- (void) PREPENDFUNC##set##UC##PREPENDVAR##CMD:(TYPE)aVal                   \
    withOutput:(unsigned int)output                                         \
{                                                                           \
    [self PREPENDFUNC##setAndNotify##UC##PREPENDVAR##CMD:aVal               \
     withOutput:output sendCommand:YES];                                    \
}                                                                           \
                                                                            \
- (void) _processCmd ## CMD ## WithFloat:(NSNumber*)theFloat                \
   withOutput:(NSNumber*)theOutput                                          \
{                                                                           \
    assert(gORTTCPXCmds[k ## CMD].responds);                                \
    [self                                                                   \
     PREPENDFUNC##setAndNotify##UC##PREPENDVAR##CMD:[theFloat TYPE ## Value]\
     withOutput:([theOutput intValue]-1) sendCommand:NO];                   \
}                                                                           \
                                                                            \
- (void) PREPENDFUNC ## write ## CMD ## WithOutput:(unsigned int)output     \
{                                                                           \
    assert(output < kORTTCPX400DPOutputChannels);                           \
    NSString* temp = nil;                                                   \
    if (gORTTCPXCmds[k ## CMD].responds) {                                  \
        temp = NSStringFromSelector(                                        \
                     @selector(_processCmd ## CMD ## WithFloat:withOutput:));\
    }                                                                       \
    [self _writeCommand:k ## CMD withInput:LC ## PREPENDVAR ## CMD[output]  \
          withOutputNum:output+1                                            \
       withSelectorName:temp];                                              \
}                                                                           \
                                                                            \
- (TYPE) LC ## PREPENDVAR ## CMD ## WithOutput:(unsigned int)output         \
{                                                                           \
    return LC ## PREPENDVAR ## CMD[output];                                 \
}                                                                           \
- (void) sendCommand ## UC ## PREPENDVAR ## CMD ## WithOutput:              \
    (unsigned int) output                                                   \
{                                                                           \
    [self PREPENDFUNC ## write ## CMD ## WithOutput:output];                \
}                                                                           

#define ORTTCPX_WRITE_IMPLEMENT(CMD, TYPE)                                  \
ORTTCPX_GEN_IMPLEMENT(CMD, TYPE, , W, w, riteTo)

#define ORTTCPX_READ_IMPLEMENT(CMD, TYPE)                                   \
ORTTCPX_GEN_IMPLEMENT(CMD, TYPE,_, R, r, eadBack)                           \
- (TYPE) readAndBlock ## CMD ## WithOutput:(unsigned int)output             \
{                                                                           \
    assert(gORTTCPXCmds[k ## CMD].responds);                                \
    [self waitUntilCommandsDone];                                           \
    if (![self isConnected]) return (TYPE)0;                                \
    [self _write ## CMD ## WithOutput:output];                              \
    [self waitUntilCommandsDone];                                           \
    return [self readBack ## CMD ## WithOutput:output];                     \
}
                                                                 
 
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetVoltage)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetVoltageAndVerify)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetOverVoltageProtectionTripPoint)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetCurrentLimit)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetOverCurrentProtectionTripPoint)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetVoltageSet)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetCurrentSet)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetVoltageTripSet)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetCurrentTripSet)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetVoltageReadback)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetCurrentReadback)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetVoltageStepSize)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetCurrentStepSize)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetVoltageStepSize)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetCurrentStepSize)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetOutput)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetOutputStatus)
ORTTCPX_READ_IMPLEMENT_NOTIFY(QueryAndClearLSR)
ORTTCPX_READ_IMPLEMENT_NOTIFY(QueryAndClearEER)
ORTTCPX_READ_IMPLEMENT_NOTIFY(QueryAndClearESR)
ORTTCPX_READ_IMPLEMENT_NOTIFY(QueryAndClearQER)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetSTB)

//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(IncrementVoltage)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(IncrementVoltageAndVerify)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(DecrementCurrent)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(DecrementVoltage)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(DecrementVoltageAndVerify)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(IncrementCurrent)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetAllOutput)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(ClearTrip)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(Local)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(RequestLock)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(CheckLock)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(ReleaseLock)

//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetEventStatusRegister)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetEventStatusRegister)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SaveCurrentSetup)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(RecallSetup)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetOperatingMode)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetOperatingMode)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetRatio)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetRatio)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(ClearStatus)

//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetESE)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetESE)

//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetISTLocalMsg)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetOPCBit)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetOPCBit)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetParallelPollRegister)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetParallelPollRegister)

//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(ResetToRemoteDflt)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetSRE)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetSRE)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetID)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetBusAddress)


@implementation ORTTCPX400DPModel

struct ORTTCPX400DPCmdInfo {
    NSString* name;
    NSString* cmd;
    BOOL responds;
    BOOL takesOutputNum;
    BOOL takesInput;
    NSString* responseFormat;
};
                                                                
    
static struct ORTTCPX400DPCmdInfo gORTTCPXCmds[kNumTTCPX400Cmds] = {
    {@"Set Voltage", @"V%i %f", NO, YES, YES, @""}, //kSetVoltage,
    {@"Set Voltage/Verify", @"V%iV %f", NO, YES, YES, @""}, //kSetVoltageAndVerify,
    {@"Set Over Voltage Protection", @"OVP%i %f", NO, YES, YES, @""}, //kSetOverVoltageProtectionTripPoint,
    {@"Set Current Limit", @"I%i %f", NO, YES, YES, @""}, //kSetCurrentLimit,
    {@"Set Over Current Protection", @"OCP%i %f", NO, YES, YES, @""}, //kSetOverCurrentProtectionTripPoint,
    {@"Get Voltage Set Point", @"V%i?", YES, YES, NO, @"V%i %f"}, //kGetVoltageSet,
    {@"Get Current Set Point", @"I%i?", YES, YES, NO, @"I%i %f"}, //kGetCurrentSet,
    // These next two should be the following
    
    //{@"Get Voltage Trip Point", @"OVP%i?", YES, YES, NO, @"VP%i %f"}, //kGetVoltageTripSet,
    //{@"Get Current Trip Point", @"OCP%i?", YES, YES, NO, @"CP%i %f"}, //kGetCurrentTripSet,
    
    // But I have instead found them to be:
    {@"Get Voltage Trip Point", @"OVP%i?", YES, YES, NO, @"%f"}, //kGetVoltageTripSet,
    {@"Get Current Trip Point", @"OCP%i?", YES, YES, NO, @"%f"}, //kGetCurrentTripSet,
    
    // This is a bit of a problem, because it means we have to specially handle these two cases.
    
    {@"Get Voltage Readback", @"V%iO?", YES, YES, NO, @"%fV"}, //kGetVoltageReadback,
    {@"Get Current Readback", @"I%iO?", YES, YES, NO, @"%fA"}, //kGetCurrentReadback,
    {@"Set Voltage Step Size", @"DELTAV%i %f", NO, YES, YES, @""}, //kSetVoltageStepSize,
    {@"Set Current Step Size", @"DELTAI%i %f", NO, YES, YES, @""}, //kSetCurrentStepSize,
    {@"Get Voltage Step Size", @"DELTAV%i?", YES, YES, NO, @"DELTAV%i %f"}, //kGetVoltageStepSize,
    {@"Get Current Step Size", @"DELTAI%i?", YES, YES, NO, @"DELTAI%i %f"}, //kGetCurrentStepSize,
    {@"Increment Voltage", @"INCV%i", NO, YES, NO, @""}, //kIncrementVoltage,
    {@"Increment Voltage and Verify", @"INCV%iV", NO, YES, NO, @""}, //kIncrementVoltageAndVerify,
    {@"Decrement Voltage", @"DECV%i", NO, YES, NO, @""}, //kDecrementVoltage,
    {@"Decrement Voltage and Verify", @"DECV%iV", NO, YES, NO, @""}, //kDecrementVoltageAndVerify,
    {@"Increment Current", @"INCI%i", NO, YES, NO, @""}, //kIncrementCurrent,
    {@"Decrement Current", @"DECI%i", NO, YES, NO, @""}, //kDecrementCurrent,
    {@"Set Output", @"OP%i %f", NO, YES, YES, @""}, //kSetOutput,
    {@"Set All Output", @"OPALL %f", NO, NO, YES, @""}, //kSetAllOutput,
    {@"Get Output Status", @"OP%i?", YES, YES, NO, @"%f"}, //kGetOutputStatus,
    {@"Clear Trip", @"TRIPRST", NO, NO, NO, @""}, //kClearTrip,
    {@"Go Local", @"LOCAL", NO, NO, NO, @""}, //kLocal,
    {@"Request Lock", @"IFLOCK", YES, NO, NO, @"%f"}, //kRequestLock,
    {@"Check Lock", @"IFLOCK?", YES, NO, NO, @"%f"}, //kCheckLock,
    {@"Release Lock", @"IFUNLOCK", YES, NO, NO, @"%f"}, //kReleaseLock,
    {@"Query and Clear LSR", @"LSR%i?", YES, YES, NO, @"%f"}, //kQueryAndClearLSR,
    {@"Set LSE", @"LSE%i %f", NO, YES, YES, @""}, //kSetEventStatusRegister,
    {@"Get LSE", @"LSE%i?", YES, YES, NO, @"%f"}, //kGetEventStatusRegister,
    {@"Save Setup", @"SAV%i %f", NO, YES, YES, @""}, //kSaveCurrentSetup,
    {@"Recall Setup", @"RCL%i %f", NO, YES, YES, @""}, //kRecallSetup,
    {@"Set Operating Mode", @"CONFIG %f", NO, NO, YES, @""}, //kSetOperatingMode,
    {@"Get Operating Mode", @"CONFIG?", YES, NO, NO, @"%f"}, //kGetOperatingMode,
    {@"Set Ratio", @"RATIO %f", NO, NO, YES, @""}, //kSetRatio,
    {@"Get Ratio", @"RATIO?", YES, NO, NO, @"%f"}, //kGetRatio,
    {@"Clear Status", @"*CLS", NO, NO, NO, @""}, //kClearStatus,
    {@"Query and Clear EER", @"EER?", YES, NO, NO, @"%f"}, //kQueryAndClearEER,
    {@"Set ESE", @"*ESE %f", NO, NO, YES, @""}, //kSetESE,
    {@"Get ESE", @"*ESE?", YES, NO, NO, @"%i"}, //kGetESE,
    {@"Get and clear ESR", @"*ESR?", YES, NO, NO, @"%f"}, //kQueryAndClearESR,
    {@"Get IST Local", @"*IST?", YES, NO, NO, @"%f"}, //kGetISTLocalMsg,
    {@"Set Operation Complete Bit", @"*OPC", NO, NO, NO, @""}, //kSetOPCBit,
    {@"Get Operation Complete Bit", @"*OPC?", YES, NO, NO, @"%f"}, //kGetOPCBit,
    {@"Set Parallel Poll Enable", @"*PRE %f", NO, NO, YES, @""}, //kSetParallelPollRegister,
    {@"Get Parallel Poll Enable", @"*PRE?", YES, NO, NO, @"%f"}, //kGetParallelPollRegister,
    {@"Query and Clear QER", @"QER?", YES, NO, NO, @"%f"}, //kQueryAndClearQER,
    {@"Reset", @"*RST", NO, NO, NO, @""}, //kResetToRemoteDflt,
    {@"Set Service Rqst Enable", @"*SRE%f", NO, NO, YES, @""}, //kSetSRE,
    {@"Get Service Rqst Enable", @"*SRE?", YES, NO, NO, @"%f"}, //kGetSRE,
    {@"Get Status Byte", @"*STB?", YES, NO, NO, @"%f"}, //kGetSTB,
    {@"Get Identity", @"*IDN?", YES, NO, NO, @"%s"}, //kGetID,
    {@"Get Address", @"ADDRESS?", YES, NO, NO, @"%s"} //kGetBusAddress
};


ORTTCPX_WRITE_IMPLEMENT(SetVoltage, float)
ORTTCPX_WRITE_IMPLEMENT(SetVoltageAndVerify, float)
ORTTCPX_WRITE_IMPLEMENT(SetOverVoltageProtectionTripPoint, float)
ORTTCPX_WRITE_IMPLEMENT(SetCurrentLimit, float)
ORTTCPX_WRITE_IMPLEMENT(SetOverCurrentProtectionTripPoint, float)
ORTTCPX_READ_IMPLEMENT(GetVoltageSet, float)
ORTTCPX_READ_IMPLEMENT(GetCurrentSet, float)
ORTTCPX_READ_IMPLEMENT(GetVoltageTripSet, float)
ORTTCPX_READ_IMPLEMENT(GetCurrentTripSet, float)
ORTTCPX_READ_IMPLEMENT(GetVoltageReadback, float)
ORTTCPX_READ_IMPLEMENT(GetCurrentReadback, float)
ORTTCPX_WRITE_IMPLEMENT(SetVoltageStepSize, float)
ORTTCPX_WRITE_IMPLEMENT(SetCurrentStepSize, float)
ORTTCPX_READ_IMPLEMENT(GetVoltageStepSize, float)
ORTTCPX_READ_IMPLEMENT(GetCurrentStepSize, float)
ORTTCPX_WRITE_IMPLEMENT(SetOutput, int)
ORTTCPX_READ_IMPLEMENT(GetOutputStatus, int)
ORTTCPX_READ_IMPLEMENT(QueryAndClearEER, int)
ORTTCPX_READ_IMPLEMENT(QueryAndClearQER, int)
ORTTCPX_READ_IMPLEMENT(QueryAndClearLSR, int)
ORTTCPX_READ_IMPLEMENT(QueryAndClearESR, int)
ORTTCPX_READ_IMPLEMENT(GetSTB, int)

//ORTTCPX_WRITE_IMPLEMENT(IncrementVoltage, float)
//ORTTCPX_WRITE_IMPLEMENT(IncrementVoltageAndVerify, float)
//ORTTCPX_WRITE_IMPLEMENT(DecrementCurrent, float)
//ORTTCPX_WRITE_IMPLEMENT(DecrementVoltage, float)
//ORTTCPX_WRITE_IMPLEMENT(DecrementVoltageAndVerify, float)
//ORTTCPX_WRITE_IMPLEMENT(IncrementCurrent, float)
//ORTTCPX_WRITE_IMPLEMENT(SetAllOutput, float)
//ORTTCPX_WRITE_IMPLEMENT(ClearTrip, float)
//ORTTCPX_WRITE_IMPLEMENT(Local, float)
//ORTTCPX_WRITE_IMPLEMENT(RequestLock, float)
//ORTTCPX_WRITE_IMPLEMENT(CheckLock, float)
//ORTTCPX_WRITE_IMPLEMENT(ReleaseLock, float)

//ORTTCPX_WRITE_IMPLEMENT(SetEventStatusRegister, float)
//ORTTCPX_WRITE_IMPLEMENT(GetEventStatusRegister, float)
//ORTTCPX_WRITE_IMPLEMENT(SaveCurrentSetup, float)
//ORTTCPX_WRITE_IMPLEMENT(RecallSetup, float)
//ORTTCPX_WRITE_IMPLEMENT(SetOperatingMode, float)
//ORTTCPX_WRITE_IMPLEMENT(GetOperatingMode, float)
//ORTTCPX_WRITE_IMPLEMENT(SetRatio, float)
//ORTTCPX_WRITE_IMPLEMENT(GetRatio, float)
//ORTTCPX_WRITE_IMPLEMENT(ClearStatus, float)

//ORTTCPX_WRITE_IMPLEMENT(SetESE, float)
//ORTTCPX_WRITE_IMPLEMENT(GetESE, float)

//ORTTCPX_WRITE_IMPLEMENT(GetISTLocalMsg, float)
//ORTTCPX_WRITE_IMPLEMENT(SetOPCBit, float)
//ORTTCPX_WRITE_IMPLEMENT(GetOPCBit, float)
//ORTTCPX_WRITE_IMPLEMENT(SetParallelPollRegister, float)
//ORTTCPX_WRITE_IMPLEMENT(GetParallelPollRegister, float)

//ORTTCPX_WRITE_IMPLEMENT(ResetToRemoteDflt, float)
//ORTTCPX_WRITE_IMPLEMENT(SetSRE, float)
//ORTTCPX_WRITE_IMPLEMENT(GetSRE, float)
//ORTTCPX_WRITE_IMPLEMENT(GetID, float)
//ORTTCPX_WRITE_IMPLEMENT(GetBusAddress, float)

@synthesize socket;
@synthesize ipAddress;
@synthesize port;

- (id) init
{
    self = [super init];
    [self setIpAddress:@""];
    [self setSerialNumber:@""];
    readConditionLock = [[NSCondition alloc] init];
    [self _registerNotificationObservers];
    return self;
}

- (void) dealloc
{
    [self _setSocket:nil];
    [ipAddress release];
    [serialNumber release];
    [dataQueue release];  
    [generalReadback release];
    [readConditionLock release];
	[super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"TTCPX400DP"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORTTCPX400DPController"];
}

- (void) setIpAddress:(NSString *)anIp
{
    [[[self undoManager] prepareWithInvocationTarget:self] 
     setIpAddress:ipAddress];
    
    [anIp retain];
    [ipAddress release];
    ipAddress = anIp;
    [[NSNotificationCenter defaultCenter] 
          postNotificationOnMainThreadWithName:ORTTCPX400DPIpHasChanged
     object:self];   
}

- (void) toggleConnection 
{
    if (![self isConnected]) [self connect];
    else {
        [self _setSocket:nil];
        [self _setIsConnected:NO];
    }
}

- (void) connect
{
	if(!isConnected && !socket) [self _connectIP]; 
}

- (void) setAllOutputToBeOn:(BOOL)on
{
    [self writeCommand:kSetAllOutput
             withInput:on
      withOutputNumber:1];
    
    writeToSetOutput[0] = on;
    writeToSetOutput[1] = on;    
    [[NSNotificationCenter defaultCenter]
          postNotificationOnMainThreadWithName:ORTTCPX400DPWriteToSetOutputIsChanged
     object:self];
}
- (void) setOutput:(unsigned int)output toBeOn:(BOOL)on
{
    [self setWriteToSetOutput:on withOutput:output];
}

- (BOOL) isConnected
{
    return isConnected;
}

- (NSString*) generalReadback
{
    if (generalReadback == nil) return @"";
    return generalReadback;
}

#pragma mark ***General Querying
- (int) numberOfCommands
{
    return kNumTTCPX400Cmds;
}
- (NSString*) commandName:(ETTCPX400DPCmds)cmd
{
    return gORTTCPXCmds[cmd].name;        
}
- (BOOL) commandTakesInput:(ETTCPX400DPCmds)cmd
{
    return gORTTCPXCmds[cmd].takesInput;    
}
- (BOOL) commandTakesOutputNumber:(ETTCPX400DPCmds)cmd
{
    return gORTTCPXCmds[cmd].takesOutputNum;
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
	if(inNetSocket != socket) return;
	[self _setIsConnected:[socket isConnected]];
    [self reset];
    [self clearStatus];
    [self readback];
    
    // Make sure the error registers are set properly.
    [self writeCommand:kSetESE
              withInput:(float)0x3C
         withOutputNumber:0];
    
    [self writeCommand:kSetEventStatusRegister
              withInput:(float)0x4C
         withOutputNumber:0];
    
    [self writeCommand:kSetEventStatusRegister
              withInput:(float)0x4C
         withOutputNumber:1];
    
    [self writeCommand:kSetSRE
             withInput:(float)0x33
      withOutputNumber:0];
    
    [self performSelectorInBackground:@selector(_syncReadoutSetToModel) withObject:nil];
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
	//if(inNetSocket != socket) return;
    
	NSString* theString = [[inNetSocket readString:NSASCIIStringEncoding]
                           stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (verbose) {
        NSLog(@"IP,SN(%@,%@) reading: %@\n", [self ipAddress], [self serialNumber],theString);
    }
	[self _processNextReadCommandInQueueWithInputString:theString];
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
	if(inNetSocket == socket){
		[self _setIsConnected:[socket isConnected]];
		[self _setIsConnected:NO];
		[socket autorelease];
		socket = nil;
	}
}

#pragma mark ***Guardian
- (BOOL) acceptsGuardian:(OrcaObject *)aGuardian
{
    return [super acceptsGuardian:aGuardian] || 
    [aGuardian isKindOfClass:NSClassFromString(@"ORnEDMCoilModel")];
}

- (short) numberSlotsUsed
{
    // Allows us to use only one slot
    return 1;
}

#pragma mark ***Comm methods

- (void) writeCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNumber:(int)output
{

    [self _writeCommand:cmd withInput:input withOutputNum:output+1 withSelectorName:nil];
}

- (NSString*) commandStringForCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNumber:(int)output
{
    if (cmd >= kNumTTCPX400Cmds) {
        // Throw an exception?
        return @"";
    }
    struct ORTTCPX400DPCmdInfo* theCmd = &gORTTCPXCmds[cmd];
    NSString* cmdStr;
    if (theCmd->takesOutputNum) {
        if (output != 1 && output != 2) {
            // Throw an exception?
            return @"";
        }
        if (theCmd->takesInput) {
            cmdStr = [NSString stringWithFormat:theCmd->cmd,output,input];
        } else {
            cmdStr = [NSString stringWithFormat:theCmd->cmd,output];
        }
    } else {
        if (theCmd->takesInput) {
            cmdStr = [NSString stringWithFormat:theCmd->cmd,input];
        } else {
            cmdStr = [NSString stringWithString:theCmd->cmd];
        }        
    }  
    return cmdStr;
}

- (int) read:(void*)data maxLengthInBytes:(NSUInteger)len
{
    return 0;
}

- (void) write: (NSString*) aCommand
{
    // This function is disabled for now.
}

- (void) waitUntilCommandsDone
{
    assert([NSThread currentThread] != readoutThread);
    [readConditionLock lock];
    while (isProcessingCommands) {
        [readConditionLock wait];
    }
    [readConditionLock unlock];
}

- (void) setSerialNumber:(NSString *)aSerial
{
    [aSerial retain];
    [serialNumber release];
    serialNumber = aSerial;
    
    [[NSNotificationCenter defaultCenter] 
          postNotificationOnMainThreadWithName:ORTTCPX400DPSerialNumberHasChanged
     object:self];      
    
}

- (NSString*) serialNumber
{
    if (serialNumber == nil) return @"";
    return serialNumber;
}

- (BOOL) verbose
{
    return verbose;
}
- (void) setVerbose:(BOOL)aVerb
{
    if (verbose == aVerb) return;
    verbose = aVerb;
    [[NSNotificationCenter defaultCenter]
          postNotificationOnMainThreadWithName:ORTTCPX400DPVerbosityHasChanged
     object:self];
}

- (BOOL) userLocked
{
    return userLocked != nil;
}

- (NSString*) userLockedString
{
    if (userLocked == nil) return @"";
    return userLocked;
}

- (BOOL) setUserLock:(BOOL)lock withString:(NSString *)lockString
{
    // Tries to set or unset lock, returns YES on success, NO on failure.
    
    // am I locked?
    if (userLocked != nil) {
        if ([userLocked isEqualToString:lockString]) {
            // Means we are already locked, can only unlock
            if (!lock) {
                [userLocked release];
                userLocked = nil;
                [[NSNotificationCenter defaultCenter]
                      postNotificationOnMainThreadWithName:ORTTCPX400DPModelLock
                 object:self];
            }
            return YES;
        }
        return NO;
    }
    if (!lock) {
        // Trying to unlock without a already having a lock?
        return YES;
    }
    
    [lockString retain];
    [userLocked release];
    userLocked = lockString;
    
    [[NSNotificationCenter defaultCenter]
          postNotificationOnMainThreadWithName:ORTTCPX400DPModelLock
     object:self];
    
    return YES;
}

- (void) readback
{
    [self readback:YES];
}

- (void) readback:(BOOL)block
{
    if (![self isConnected]) return;
    int output;
    for (output=0; output<kORTTCPX400DPOutputChannels; output++) {
        [self sendCommandReadBackGetCurrentReadbackWithOutput:output];
        [self sendCommandReadBackGetCurrentTripSetWithOutput:output];
        [self sendCommandReadBackGetVoltageReadbackWithOutput:output];
        [self sendCommandReadBackGetVoltageTripSetWithOutput:output];
    }
    if (block && readoutThread != [NSThread currentThread]) {
        [self waitUntilCommandsDone];
    }
}

- (void) reset
{
    [self writeCommand:kResetToRemoteDflt withInput:0 withOutputNumber:0];
}

- (void) clearStatus
{
    [self writeCommand:kClearStatus withInput:0 withOutputNumber:0];
}

- (void) resetTrips
{
    [self writeCommand:kClearTrip withInput:0 withOutputNumber:0];
}

- (BOOL) checkAndClearErrors
{
    return [self checkAndClearErrors:YES];
}

- (BOOL) checkAndClearErrors:(BOOL)block
{
    assert(readoutThread !=[NSThread currentThread]);
    [self sendCommandReadBackGetSTBWithOutput:0];
    if (!block) return NO;
    
    [self waitUntilCommandsDone];
    
    int stbStatus = [self readBackGetSTBWithOutput:0];
    BOOL retValue = NO;
    if ((stbStatus & 0x33) == 0) return NO;
    if ((stbStatus & 0x20) != 0) {
        retValue = YES;
        [self sendCommandReadBackQueryAndClearESRWithOutput:0];
    }
    if ((stbStatus & 0x2) != 0) {
        retValue = YES;
        [self sendCommandReadBackQueryAndClearLSRWithOutput:1];
    }
    if ((stbStatus & 0x1) != 0) {
        retValue = YES;
        [self sendCommandReadBackQueryAndClearLSRWithOutput:0];
    }
    [self waitUntilCommandsDone];
    if ([self currentErrorCondition]) {
        [[NSNotificationCenter defaultCenter]
              postNotificationOnMainThreadWithName:ORTTCPX400DPErrorSeen
         object:self];
        return YES;
    }
    return retValue;
}

- (BOOL) currentErrorCondition
{
    // returns if there is a current error condition.
    if (([self readBackGetSTBWithOutput:0] & 0x33) == 0) return NO;
    BOOL retVal =
    (([self readBackValueESR] & 0x3c) != 0 ||
     ([self readBackValueEER] != 0)        ||
     (([self readBackValueLSR:0] & 0xFC) != 0)      ||
     (([self readBackValueLSR:1] & 0xFC) != 0)      ||
     ([self readBackValueQER] != 0));
    return retVal;
}

- (unsigned int) readBackValueLSR:(int)outputNum
{
    return [self readBackQueryAndClearLSRWithOutput:outputNum];
}
- (unsigned int) readBackValueEER
{
    return [self readBackQueryAndClearEERWithOutput:0];
}
- (unsigned int) readBackValueESR
{
    return [self readBackQueryAndClearESRWithOutput:0];
}
- (unsigned int) readBackValueQER
{
    return [self readBackQueryAndClearQERWithOutput:0];
}

- (NSArray*) explainStringsForLSRBits:(unsigned int)bits
{
    NSMutableArray *retArray = [NSMutableArray array];
    if (bits & 0x1) [retArray addObject:@"Output at Voltage Limit (CV mode)"];
    if (bits & 0x2) [retArray addObject:@"Output at Current Limit (CC mode)"];
    if (bits & 0x4) [retArray addObject:@"Output over Voltage Trip"];
    if (bits & 0x8) [retArray addObject:@"Output over Current Trip"];
    if (bits & 0x10) [retArray addObject:@"Output over Power Limit"];
    if (bits & 0x40) [retArray addObject:@"Trip, Requires panel reset and power cycle"];
    if ([retArray count] == 0) [retArray addObject:@"No Errors"];
    return retArray;
}

- (NSString*) explainStringForEERBits:(unsigned int)bits
{
    if (bits == 0) return @"No Errors";
    if (bits < 10) return [NSString stringWithFormat:@"(%i) Internal Hardware Error",bits];
    switch (bits) {
        case 100: return @"(100) Range Error";
        case 101: return @"(101) Corrupted Memory by Recall";
        case 102: return @"(102) No data by Recall";
        case 103: return @"(103) Second output not available";
        case 104: return @"(104) Command not valid with output on";
        case 200: return @"(200) Device read only";
        default:  return @"(?) Unknown";
    }
}

- (NSArray*) explainStringsForESRBits:(unsigned int)bits
{
    NSMutableArray *retArray = [NSMutableArray array];
    if (bits & 0x4) {
        [retArray addObject:@"(0x4) Query Error"];
    }
    if (bits & 0x8) {
        [retArray addObject:@"(0x8) Verify Timeout Error"];
    }
    if (bits & 0x10) {
        [retArray addObject:@"(0x10) Execution Error"];
    }
    if (bits & 0x20) {
        [retArray addObject:@"(0x20) Command Error"];
    }
    if ([retArray count] == 0) [retArray addObject:@"No Errors"];
    return retArray;
}

- (NSString*) explainStringForQERBits:(unsigned int)bits
{
    switch(bits) {
        case 0: return @"No Error";
        case 1: return @"Interrupted";
        case 2: return @"Deadlock";
        case 3: return @"Unterminated";
        default: return @"Unknown QER Error";
    }
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
    readConditionLock = [[NSCondition alloc] init];
    [self _registerNotificationObservers];
	
	[self setIpAddress:[decoder decodeObjectForKey:@"ipAddress"]];
	[self setSerialNumber:[decoder decodeObjectForKey:@"serialNumber"]];    
    [self setPort:[decoder decodeIntForKey:@"portNumber"]];
    [self setVerbose:[decoder decodeIntForKey:@"verbose"]];
    NSString* ul = [decoder decodeObjectForKey:@"kORTTCPX400DPUL"];
    if (ul != nil) [self setUserLock:YES withString:ul];
    
	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
 	[encoder encodeObject:ipAddress	forKey:@"ipAddress"];
 	[encoder encodeObject:serialNumber	forKey:@"serialNumber"];    
    [encoder encodeInt:port forKey:@"portNumber"];
    [encoder encodeInt:verbose forKey:@"verbose"];
    [encoder encodeObject:userLocked forKey:@"kORTTCPX400DPUL"];
}



@end

@implementation ORTTCPX400DPModel (private)

- (void) _setSocket:(NetSocket*)aSocket
{
	if(aSocket == socket) return;
    @synchronized(self) {
        [socket close];
        [aSocket retain];
        [socket release];
        socket = aSocket;
        [socket setDelegate:self];
    }
}

- (void) _readoutThreadSocketSend:(NSString*)aCommand
{
    // This *must* be called on the readout thread.  We want to ensure that it is impossible for
    // any commands sent not to block the run loop which is handling readbacks.
	if(!aCommand)aCommand = @"";
    if(verbose) {
        NSLog(@"IP,SN(%@,%@) writing: %@\n", [self ipAddress], [self serialNumber],aCommand);
    }
	[socket writeString:[NSString stringWithFormat:@"%@;",aCommand] encoding:NSASCIIStringEncoding];
}


- (void) _connectIP
{
	if(!isConnected){
		[self _connectSocket:ipAddress];
	}
}

- (void) _setIsConnected:(BOOL)connected
{
    if (isConnected == connected) return;
    isConnected = connected;
    [[NSNotificationCenter defaultCenter]
     postNotificationOnMainThreadWithName:ORTTCPX400DPConnectionHasChanged
     object:self];
    
}
- (void) _addCommandToDataProcessingQueue:(struct ORTTCPX400DPCmdInfo*)theCmd
                           withSendString:(NSString*)cmdStr
                   withReturnSelectorName:(NSString*)selName
                         withOutputNumber:(unsigned int)output
{
    // We take pointers, but we know the pointers always exist.
    
    [readConditionLock lock];
    
    // First add the write command
    [dataQueue addObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLong:(unsigned long)theCmd],cmdStr,@"",[NSNumber numberWithUnsignedInt:output],nil]];
    // If there's a read command, add it as well.
    if (selName != nil) {
        [dataQueue addObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLong:(unsigned long)theCmd],@"",selName,[NSNumber numberWithUnsignedInt:output],nil]];
    }
    // We only call the next write command if we are not doing any processing.
    BOOL callProcessing = !isProcessingCommands;
    isProcessingCommands = YES;
    [readConditionLock unlock];
    if (callProcessing) {
        [self performSelector:@selector(_processNextWriteCommandInQueue)
                     onThread:readoutThread
                   withObject:nil
                waitUntilDone:NO];
    }
}

- (void) _processNextWriteCommandInQueue
{
    // This function processes the next write command in the queue.
    // It *only* must be called if a command is to be processed and only on the readoutThread.
    
    [readConditionLock lock];
    assert(readoutThread == [NSThread currentThread] && isProcessingCommands);
    assert([dataQueue count] != 0 && [[[dataQueue objectAtIndex:0] objectAtIndex:1] length] != 0);
    
    // The queue to receive something is empty.
    // We have to copy it, because removing it gets rid of it.
    NSString* nextCmdToWrite = [NSString stringWithString:[[dataQueue objectAtIndex:0] objectAtIndex:1]];
    struct ORTTCPX400DPCmdInfo* theCmd = (struct ORTTCPX400DPCmdInfo*)[[[dataQueue objectAtIndex:0] objectAtIndex:0] longValue];
    [dataQueue removeObjectAtIndex:0];
    
    if(!theCmd->responds) [self _setGeneralReadback:@"N/A"];
    [self _readoutThreadSocketSend:nextCmdToWrite];
    
    // We signal if someone is waiting on the count to reach zero
    if ([dataQueue count] == 0) {
        isProcessingCommands = NO;
        [readConditionLock broadcast];
        [readConditionLock unlock];
        return;
    }
    
    BOOL callNextWriteCommand = ([[[dataQueue objectAtIndex:0] objectAtIndex:1] length] != 0);
    [readConditionLock unlock];
    
    if (callNextWriteCommand)[self _processNextWriteCommandInQueue];
}

- (void) _processNextReadCommandInQueueWithInputString:(NSString *)input
{
    
    [readConditionLock lock];
    
    // This can happen if the socket is opened and closed quickly, just ignore.
    if (readoutThread == nil || !isProcessingCommands ||
        [dataQueue count] == 0) {
        [readConditionLock unlock];
        return;
    }
    assert(readoutThread == [NSThread currentThread]);    
    
    struct ORTTCPX400DPCmdInfo* cmd = (struct ORTTCPX400DPCmdInfo*)[[[dataQueue objectAtIndex:0] objectAtIndex:0] longValue];
    SEL callSelector = NSSelectorFromString([[dataQueue objectAtIndex:0] objectAtIndex:2]);
    // We unfortunately have to do this, because some output numbers are not set by the returned strings.
    int outputNum = [[[dataQueue objectAtIndex:0] objectAtIndex:3] unsignedIntValue];
    [dataQueue removeObjectAtIndex:0];
    
    assert(cmd != nil && cmd->responds);
    
    float readBackValue = 0;
    int numberOfOutputs = [[cmd->responseFormat componentsSeparatedByString:@"%"] count] - 1;
    @try {
        switch (numberOfOutputs) {
            case 1:
                if (sscanf([input cStringUsingEncoding:NSASCIIStringEncoding],
                           [cmd->responseFormat cStringUsingEncoding:NSASCIIStringEncoding],&readBackValue) != 1) {
                    [NSException raise:@"Error in TTCPX400DP"
                                format:@"parsing input string (%@) with format (%@)",input,cmd->responseFormat];
                }
                break;
            case 2:
                
                if (sscanf([input cStringUsingEncoding:NSASCIIStringEncoding],
                           [cmd->responseFormat cStringUsingEncoding:NSASCIIStringEncoding],&outputNum,&readBackValue) != 2) {
                    [NSException raise:@"Error in TTCPX400DP"
                                format:@"parsing input string (%@) with format (%@)",input,cmd->responseFormat];
                }
                break;
            default:
                assert((numberOfOutputs != 1 && numberOfOutputs != 2));
                break;
        }
        
    } @catch (NSException *e) {
        [readConditionLock unlock];
        [e raise];
    }
    if (callSelector) {
        numberOfOutputs = [[NSStringFromSelector(callSelector) componentsSeparatedByString:@":"] count] - 1;
        switch (numberOfOutputs) {
            case 1:
                [self performSelector:callSelector
                           withObject:[NSNumber numberWithFloat:readBackValue]];
                break;
            case 2:
                [self performSelector:callSelector
                           withObject:[NSNumber numberWithFloat:readBackValue]
                           withObject:[NSNumber numberWithInt:outputNum] ];
                break;
            default:
                assert((numberOfOutputs != 1 && numberOfOutputs != 2));
                break;
        }
    }
    // We signal if someone is waiting on the count to reach zero
    if ([dataQueue count] == 0) {
        isProcessingCommands = NO;
        [readConditionLock broadcast];
        [readConditionLock unlock];
        return;
    }
    
    BOOL callNextWriteCommand = ([[[dataQueue objectAtIndex:0] objectAtIndex:1] length] != 0);
    [readConditionLock unlock];
    
    if (callNextWriteCommand) [self _processNextWriteCommandInQueue];
}

- (void) _processGeneralReadback:(NSNumber*)aFloat withOutputNum:(NSNumber*) anInt
{
    [self _setGeneralReadback:[NSString stringWithFormat:@"Output %i: %f",[anInt intValue],[aFloat floatValue]]];
}

- (void) _processGeneralReadback:(NSNumber*)aFloat
{
    [self _setGeneralReadback:[NSString stringWithFormat:@"%f",[aFloat floatValue]]];
}

- (void) _setGeneralReadback:(NSString *)read
{
    [read retain];
    [generalReadback release];
    generalReadback = read;
    [[NSNotificationCenter defaultCenter]
          postNotificationOnMainThreadWithName:ORTTCPX400DPGeneralReadbackHasChanged
     object:self];
}

- (void) _socketThread:(NSString*)currentIPAddress
{
    NSRunLoop* rl = [NSRunLoop currentRunLoop];
    NetSocket* currentSocket = [NetSocket netsocketConnectedToHost:currentIPAddress
                                                              port:ORTTCPX400DPPort];
    if (currentSocket == nil) return;
    
    // schedule the socket on the current run loop.
    [currentSocket scheduleOnCurrentRunLoop];
    [self _setSocket:currentSocket];
    
    [readConditionLock lock];
    readoutThread = [NSThread currentThread];
    // Also release the dataQueue
    [dataQueue release];
    dataQueue = [[NSMutableArray array] retain];
    isProcessingCommands = NO;
    [readConditionLock broadcast];    
    [readConditionLock unlock];
    
    // perform the run loop
    // This ends whenever the socket changes
    @try{
        while( socket == currentSocket ) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            if (![rl runMode:NSDefaultRunLoopMode
             beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]) {
               [pool drain];
               break;
            }
            [pool drain];
        }

    } @catch (NSException* e) {
        [self _setSocket:nil];
        [self _setIsConnected:NO];
        NSLogColor([NSColor redColor], @"Exception at (%@, %@, %@) readout thread, disconnected.\n",
                   [self objectName],[self ipAddress],[self serialNumber]);
        NSLogColor([NSColor redColor], @"%@\n",e);
    }

    [readConditionLock lock];
    readoutThread = nil;    
    [dataQueue release];
    dataQueue = nil;
    isProcessingCommands = NO;
    [readConditionLock broadcast];
    [readConditionLock unlock];
}

- (void) _connectSocket:(NSString*)anIpAddress
{
    // Detach the thread to perform the run loop
    [NSThread detachNewThreadSelector:@selector(_socketThread:)
                             toTarget:self
                           withObject:anIpAddress];
}

- (void) _writeCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNum:(int)output withSelectorName:(NSString*)selName
{
    if (![self isConnected]) {
        NSLog(@"CPX400DP must be connected to write command\n");
        return;
    }
    NSString* cmdStr = [self commandStringForCommand:cmd
                                           withInput:input
                                    withOutputNumber:output];
    
    if ([cmdStr isEqualToString:@""]) {
        return;
    }
    struct ORTTCPX400DPCmdInfo* theCmd = &gORTTCPXCmds[cmd];
    if (theCmd->responds) {
        if (selName == nil){
            int numberOfOutputs = [[theCmd->responseFormat componentsSeparatedByString:@"%"] count] - 1;
            switch (numberOfOutputs) {
                case 1:
                    selName = NSStringFromSelector(@selector(_processGeneralReadback:));
                    break;
                case 2:
                    selName = NSStringFromSelector(@selector(_processGeneralReadback:withOutputNum:));
                    break;
                default:
                    assert((numberOfOutputs != 1 && numberOfOutputs != 2));
                    break;
            }
        }
        
    }
    [self _addCommandToDataProcessingQueue:theCmd
                            withSendString:cmdStr
                    withReturnSelectorName:selName
                          withOutputNumber:output];
}

#define SYNC_MODEL_VARS(setVar, readBackVar)   \
    if( ![self isConnected]) return;           \
[self setAndNotifyWriteTo ## setVar:[self readAndBlock ## readBackVar ## WithOutput:0]  \
    withOutput:0 sendCommand:NO];                                                       \
    if( ![self isConnected]) return;           \
[self setAndNotifyWriteTo ## setVar:[self readAndBlock ## readBackVar ## WithOutput:1]  \
    withOutput:1 sendCommand:NO];

#define SYNC_MODEL_NORMALVARS(var) \
SYNC_MODEL_VARS(Set ## var, Get ## var ## Set)

- (void) _syncReadoutSetToModel
{
    // Because this uses block commands, it must *not* be run on the readout thread.
    SYNC_MODEL_VARS(SetVoltage,GetVoltageSet); // Voltage Get/Set
    SYNC_MODEL_VARS(SetOverVoltageProtectionTripPoint, GetVoltageTripSet); // Current Trip
    SYNC_MODEL_VARS(SetOverCurrentProtectionTripPoint, GetCurrentTripSet); // Current Trip
    SYNC_MODEL_VARS(SetCurrentLimit, GetCurrentSet); // Current Trip
    SYNC_MODEL_VARS(SetOutput, GetOutputStatus); // Current Trip
}

- (void) _registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];
	[notifyCenter addObserver : self
					 selector : @selector(_hwFinderChanged:)
						 name : ORHardwareFinderAvailableHardwareChanged
					   object : nil];
}

- (void) _hwFinderChanged:(NSNotification*)aNote
{
    if ([serialNumber isEqualToString:@""]) {
        if([ipAddress isEqualToString:@""]) return;
        // Otherwise try to set the serial Number
        NSDictionary* dict = [[ORVXI11HardwareFinder sharedVXI11HardwareFinder] availableHardware];
        for (NSString* key in dict) {
            ORVXI11IPDevice* dev = [dict objectForKey:key];
            if ([[dev ipAddress] isEqualToString:ipAddress]) {
                [self setSerialNumber:[dev serialNumber]];
                break;
            }
        }
    } else {
        // Otherwise try to change the IP address
        NSDictionary* dict = [[ORVXI11HardwareFinder sharedVXI11HardwareFinder] availableHardware];
        for (NSString* key in dict) {
            ORVXI11IPDevice* dev = [dict objectForKey:key];
            if ([[dev serialNumber] isEqualToString:serialNumber]) {
                if ([ipAddress isEqualToString:[dev ipAddress]]) return;
                
                // Otherwise we need to ask for confirmation
                if (ORRunAlertPanel(@"IP Address changed",
                                    @"%@",
                                    @"OK",
                                    @"Cancel",
                                    nil,
                                    [NSString stringWithFormat:@"The IP (%@) of %@,%@ has changed to %@.  Do you wish to allow this?",
                                                          [self ipAddress],[self objectName],[self serialNumber],[dev ipAddress]])) {
                    [self setIpAddress:[dev ipAddress]];
                }
                break;
            }
        }
    }
}

@end
