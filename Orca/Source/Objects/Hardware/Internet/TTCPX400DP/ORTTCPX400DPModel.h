//
//  ORTTCPX400DPModel.h
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

#import "ORTcpIpProtocol.h"
#import "OrcaObject.h"

typedef enum {
  kSetVoltage,
  kSetVoltageAndVerify,
  kSetOverVoltageProtectionTripPoint,
  kSetCurrentLimit,
  kSetOverCurrentProtectionTripPoint,
  kGetVoltageSet,
  kGetCurrentSet,
  kGetVoltageTripSet,
  kGetCurrentTripSet,
  kGetVoltageReadback,
  kGetCurrentReadback,
  kSetVoltageStepSize,
  kSetCurrentStepSize,
  kGetVoltageStepSize,
  kGetCurrentStepSize,
  kIncrementVoltage,
  kIncrementVoltageAndVerify,
  kDecrementCurrent,
  kDecrementVoltage,
  kDecrementVoltageAndVerify,
  kIncrementCurrent,
  kSetOutput,
  kSetAllOutput,
  kGetOutputStatus,
  kClearTrip,
  kLocal,
  kRequestLock,
  kCheckLock,
  kReleaseLock,
  kQueryAndClearLSR,
  kSetEventStatusRegister,
  kGetEventStatusRegister,
  kSaveCurrentSetup,
  kRecallSetup,
  kSetOperatingMode,
  kGetOperatingMode,
  kSetRatio,
  kGetRatio,
  kClearStatus,
  kQueryAndClearEER,
  kSetESE,
  kGetESE,
  kQueryAndClearESR,
  kGetISTLocalMsg,
  kSetOPCBit,
  kGetOPCBit,
  kSetParallelPollRegister,
  kGetParallelPollRegister,
  kQueryAndClearQER,
  kResetToRemoteDflt,
  kSetSRE,
  kGetSRE,
  kGetSTB,
  kGetID,
  kGetBusAddress,
  kNumTTCPX400Cmds
} ETTCPX400DPCmds;

#define kORTTCPX400DPOutputChannels 2

#define ORTTCPX_GEN_NOTIFY_FORM(PREPENDVAR, CMD) \
ORTTCPX400DP ## PREPENDVAR ## CMD ## IsChanged

#define ORTTCPX_NOTIFY_READ_FORM(CMD) \
ORTTCPX_GEN_NOTIFY_FORM(ReadBack, CMD)
#define ORTTCPX_NOTIFY_WRITE_FORM(CMD) \
ORTTCPX_GEN_NOTIFY_FORM(WriteTo, CMD)

#define ORTTCPX_NOTIFY_WRITE_DEFINE(CMD) \
extern NSString* ORTTCPX_NOTIFY_WRITE_FORM(CMD);

#define ORTTCPX_NOTIFY_READ_DEFINE(CMD) \
extern NSString* ORTTCPX_NOTIFY_READ_FORM(CMD);

#define ORTTCPX_GEN_DEFINE_VAR(PREPENDVAR, CMD, TYPE) \
TYPE PREPENDVAR ## CMD[kORTTCPX400DPOutputChannels];

#define ORTTCPX_DEFINE_READ_VAR(CMD, TYPE) \
ORTTCPX_GEN_DEFINE_VAR(readBack, CMD, TYPE)

#define ORTTCPX_DEFINE_WRITE_VAR(CMD, TYPE) \
ORTTCPX_GEN_DEFINE_VAR(writeTo, CMD, TYPE)

#define ORTTCPX_DEFINE_WRITE_FUNCTIONS(CMD, TYPE)                      \
- (void) setWriteTo ## CMD:(TYPE)val withOutput:(unsigned int) output; \
- (TYPE) writeTo ## CMD ## WithOutput:(unsigned int) output;           \
- (void) sendCommandWriteTo ## CMD ## WithOutput:(unsigned int) output;

#define ORTTCPX_DEFINE_READ_FUNCTIONS(CMD, TYPE)                        \
- (TYPE) readBack ## CMD ## WithOutput:(unsigned int) output;           \
- (TYPE) readAndBlock ## CMD ## WithOutput:(unsigned int) output;       \
- (void) sendCommandReadBack ## CMD ## WithOutput:(unsigned int) output;


@interface ORTTCPX400DPModel : OrcaObject<ORTcpIpProtocol> {
	NetSocket* socket;
	NSString* ipAddress;
    NSString* serialNumber;
	BOOL isConnected;
	id delegate;
    NSUInteger port;
    NSString* generalReadback;
    NSMutableArray* dataQueue;
    NSMutableArray* writeQueue;
    NSCondition* readConditionLock;
    BOOL verbose;
    BOOL isProcessingCommands;
    NSString* userLocked;
    NSThread* readoutThread;
    
    
    ORTTCPX_DEFINE_WRITE_VAR(SetVoltage, float)
    ORTTCPX_DEFINE_WRITE_VAR(SetVoltageAndVerify, float)
    ORTTCPX_DEFINE_WRITE_VAR(SetOverVoltageProtectionTripPoint, float)
    ORTTCPX_DEFINE_WRITE_VAR(SetCurrentLimit, float)
    ORTTCPX_DEFINE_WRITE_VAR(SetOverCurrentProtectionTripPoint, float)
    ORTTCPX_DEFINE_READ_VAR(GetVoltageSet, float)
    ORTTCPX_DEFINE_READ_VAR(GetCurrentSet, float)
    ORTTCPX_DEFINE_READ_VAR(GetVoltageTripSet, float)
    ORTTCPX_DEFINE_READ_VAR(GetCurrentTripSet, float)
    ORTTCPX_DEFINE_READ_VAR(GetVoltageReadback, float)
    ORTTCPX_DEFINE_READ_VAR(GetCurrentReadback, float)
    ORTTCPX_DEFINE_WRITE_VAR(SetVoltageStepSize, float)
    ORTTCPX_DEFINE_WRITE_VAR(SetCurrentStepSize, float)
    ORTTCPX_DEFINE_READ_VAR(GetVoltageStepSize, float)
    ORTTCPX_DEFINE_READ_VAR(GetCurrentStepSize, float)
    ORTTCPX_DEFINE_READ_VAR(GetOutputStatus, int)
    ORTTCPX_DEFINE_WRITE_VAR(SetOutput, int)
    ORTTCPX_DEFINE_READ_VAR(QueryAndClearLSR, int)
    ORTTCPX_DEFINE_READ_VAR(QueryAndClearEER, int)
    ORTTCPX_DEFINE_READ_VAR(QueryAndClearESR, int)
    ORTTCPX_DEFINE_READ_VAR(QueryAndClearQER, int)
    ORTTCPX_DEFINE_READ_VAR(GetSTB, int)
    
    //ORTTCPX_DEFINE_WRITE_VAR(IncrementVoltage, float)
    //ORTTCPX_DEFINE_WRITE_VAR(IncrementVoltageAndVerify, float)
    //ORTTCPX_DEFINE_WRITE_VAR(DecrementCurrent, float)
    //ORTTCPX_DEFINE_WRITE_VAR(DecrementVoltage, float)
    //ORTTCPX_DEFINE_WRITE_VAR(DecrementVoltageAndVerify, float)
    //ORTTCPX_DEFINE_WRITE_VAR(IncrementCurrent, float)
    //ORTTCPX_DEFINE_WRITE_VAR(SetAllOutput, float)
    //ORTTCPX_DEFINE_WRITE_VAR(ClearTrip, float)
    //ORTTCPX_DEFINE_WRITE_VAR(Local, float)
    //ORTTCPX_DEFINE_WRITE_VAR(RequestLock, float)
    //ORTTCPX_DEFINE_WRITE_VAR(CheckLock, float)
    //ORTTCPX_DEFINE_WRITE_VAR(ReleaseLock, float)

    //ORTTCPX_DEFINE_WRITE_VAR(SetEventStatusRegister, float)
    //ORTTCPX_DEFINE_WRITE_VAR(GetEventStatusRegister, float)
    //ORTTCPX_DEFINE_WRITE_VAR(SaveCurrentSetup, float)
    //ORTTCPX_DEFINE_WRITE_VAR(RecallSetup, float)
    //ORTTCPX_DEFINE_WRITE_VAR(SetOperatingMode, float)
    //ORTTCPX_DEFINE_WRITE_VAR(GetOperatingMode, float)
    //ORTTCPX_DEFINE_WRITE_VAR(SetRatio, float)
    //ORTTCPX_DEFINE_WRITE_VAR(GetRatio, float)
    //ORTTCPX_DEFINE_WRITE_VAR(ClearStatus, float)

    //ORTTCPX_DEFINE_WRITE_VAR(SetESE, float)
    //ORTTCPX_DEFINE_WRITE_VAR(GetESE, float)

    //ORTTCPX_DEFINE_WRITE_VAR(GetISTLocalMsg, float)
    //ORTTCPX_DEFINE_WRITE_VAR(SetOPCBit, float)
    //ORTTCPX_DEFINE_WRITE_VAR(GetOPCBit, float)
    //ORTTCPX_DEFINE_WRITE_VAR(SetParallelPollRegister, float)
    //ORTTCPX_DEFINE_WRITE_VAR(GetParallelPollRegister, float)

    //ORTTCPX_DEFINE_WRITE_VAR(ResetToRemoteDflt, float)
    //ORTTCPX_DEFINE_WRITE_VAR(SetSRE, float)
    //ORTTCPX_DEFINE_WRITE_VAR(GetSRE, float)
    //ORTTCPX_DEFINE_WRITE_VAR(GetID, float)
    //ORTTCPX_DEFINE_WRITE_VAR(GetBusAddress, float)
}

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;


- (BOOL) verbose;
- (void) setVerbose:(BOOL)aVerb;

- (BOOL) userLocked;
- (NSString*) userLockedString;
- (BOOL) setUserLock:(BOOL)lock withString:(NSString*)lockString;

- (void) setSerialNumber:(NSString*)aSerial;
- (NSString*) serialNumber;

- (void) writeCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNumber:(int)output;

- (NSString*) commandStringForCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNumber:(int)output;

- (void) waitUntilCommandsDone;

#pragma mark ***Guardian
- (BOOL) acceptsGuardian:(OrcaObject *)aGuardian;

#pragma mark ***General Querying
- (NSString*) generalReadback;
- (int) numberOfCommands;
- (void) toggleConnection;
- (void) setAllOutputToBeOn:(BOOL)on;
- (void) setOutput:(unsigned int)output toBeOn:(BOOL)on;
- (NSString*) commandName:(ETTCPX400DPCmds)cmd;
- (BOOL) commandTakesInput:(ETTCPX400DPCmds)cmd;
- (BOOL) commandTakesOutputNumber:(ETTCPX400DPCmds)cmd;

- (void) readback;
- (void) readback:(BOOL)block;
- (void) reset;
- (void) resetTrips;
- (void) clearStatus;
- (BOOL) checkAndClearErrors;
- (BOOL) checkAndClearErrors:(BOOL)block;
- (BOOL) currentErrorCondition;

- (unsigned int) readBackValueLSR:(int)outputNum;
- (unsigned int) readBackValueEER;
- (unsigned int) readBackValueESR;
- (unsigned int) readBackValueQER;

- (NSArray*) explainStringsForLSRBits:(unsigned int)bits;
- (NSString*) explainStringForEERBits:(unsigned int)bits;
- (NSArray*) explainStringsForESRBits:(unsigned int)bits;
- (NSString*) explainStringForQERBits:(unsigned int)bits;

ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetVoltage, float)
ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetVoltageAndVerify, float)
ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetOverVoltageProtectionTripPoint, float)
ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetCurrentLimit, float)
ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetOverCurrentProtectionTripPoint, float)
ORTTCPX_DEFINE_READ_FUNCTIONS(GetVoltageSet, float)
ORTTCPX_DEFINE_READ_FUNCTIONS(GetCurrentSet, float)
ORTTCPX_DEFINE_READ_FUNCTIONS(GetVoltageTripSet, float)
ORTTCPX_DEFINE_READ_FUNCTIONS(GetCurrentTripSet, float)
ORTTCPX_DEFINE_READ_FUNCTIONS(GetVoltageReadback, float)
ORTTCPX_DEFINE_READ_FUNCTIONS(GetCurrentReadback, float)
ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetVoltageStepSize, float)
ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetCurrentStepSize, float)
ORTTCPX_DEFINE_READ_FUNCTIONS(GetVoltageStepSize, float)
ORTTCPX_DEFINE_READ_FUNCTIONS(GetCurrentStepSize, float)
ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetOutput, int)
ORTTCPX_DEFINE_READ_FUNCTIONS(GetOutputStatus, int)
ORTTCPX_DEFINE_READ_FUNCTIONS(QueryAndClearLSR, int)
ORTTCPX_DEFINE_READ_FUNCTIONS(QueryAndClearEER, int)
ORTTCPX_DEFINE_READ_FUNCTIONS(QueryAndClearESR, int)
ORTTCPX_DEFINE_READ_FUNCTIONS(QueryAndClearQER, int)
ORTTCPX_DEFINE_READ_FUNCTIONS(GetSTB, int)

// The following are for later implementation (if at all)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(IncrementVoltage, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(IncrementVoltageAndVerify, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(DecrementCurrent, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(DecrementVoltage, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(DecrementVoltageAndVerify, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(IncrementCurrent, float)

//ORTTCPX_DEFINE_WRITE_FUNCTIONS(ClearTrip, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(Local, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(RequestLock, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(CheckLock, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(ReleaseLock, float)

//ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetEventStatusRegister, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(GetEventStatusRegister, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(SaveCurrentSetup, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(RecallSetup, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetOperatingMode, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(GetOperatingMode, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetRatio, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(GetRatio, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(ClearStatus, float)

//ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetESE, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(GetESE, float)

//ORTTCPX_DEFINE_WRITE_FUNCTIONS(GetISTLocalMsg, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetOPCBit, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(GetOPCBit, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetParallelPollRegister, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(GetParallelPollRegister, float)

//ORTTCPX_DEFINE_WRITE_FUNCTIONS(ResetToRemoteDflt, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(SetSRE, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(GetSRE, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(GetID, float)
//ORTTCPX_DEFINE_WRITE_FUNCTIONS(GetBusAddress, float)


@end

extern NSString* ORTTCPX400DPDataHasArrived;
extern NSString* ORTTCPX400DPConnectionHasChanged;
extern NSString* ORTTCPX400DPModelLock;
extern NSString* ORTTCPX400DPIpHasChanged;
extern NSString* ORTTCPX400DPSerialNumberHasChanged;
extern NSString* ORTTCPX400DPGeneralReadbackHasChanged;
extern NSString* ORTTCPX400DPVerbosityHasChanged;
extern NSString* ORTTCPX400DPErrorSeen;

ORTTCPX_NOTIFY_WRITE_DEFINE(SetVoltage)
ORTTCPX_NOTIFY_WRITE_DEFINE(SetVoltageAndVerify)
ORTTCPX_NOTIFY_WRITE_DEFINE(SetOverVoltageProtectionTripPoint)
ORTTCPX_NOTIFY_WRITE_DEFINE(SetCurrentLimit)
ORTTCPX_NOTIFY_WRITE_DEFINE(SetOverCurrentProtectionTripPoint)
ORTTCPX_NOTIFY_READ_DEFINE(GetVoltageSet)
ORTTCPX_NOTIFY_READ_DEFINE(GetCurrentSet)
ORTTCPX_NOTIFY_READ_DEFINE(GetVoltageTripSet)
ORTTCPX_NOTIFY_READ_DEFINE(GetCurrentTripSet)
ORTTCPX_NOTIFY_READ_DEFINE(GetVoltageReadback)
ORTTCPX_NOTIFY_READ_DEFINE(GetCurrentReadback)
ORTTCPX_NOTIFY_WRITE_DEFINE(SetVoltageStepSize)
ORTTCPX_NOTIFY_WRITE_DEFINE(SetCurrentStepSize)
ORTTCPX_NOTIFY_READ_DEFINE(GetVoltageStepSize)
ORTTCPX_NOTIFY_READ_DEFINE(GetCurrentStepSize)
ORTTCPX_NOTIFY_WRITE_DEFINE(SetOutput)
ORTTCPX_NOTIFY_READ_DEFINE(GetOutputStatus)
ORTTCPX_NOTIFY_READ_DEFINE(QueryAndClearLSR)
ORTTCPX_NOTIFY_READ_DEFINE(QueryAndClearEER)
ORTTCPX_NOTIFY_READ_DEFINE(QueryAndClearESR)
ORTTCPX_NOTIFY_READ_DEFINE(QueryAndClearQER)
ORTTCPX_NOTIFY_READ_DEFINE(GetSTB)

//ORTTCPX_NOTIFY_WRITE_DEFINE(ResetToRemoteDflt)

//ORTTCPX_NOTIFY_WRITE_DEFINE(IncrementVoltage)
//ORTTCPX_NOTIFY_WRITE_DEFINE(IncrementVoltageAndVerify)
//ORTTCPX_NOTIFY_WRITE_DEFINE(DecrementCurrent)
//ORTTCPX_NOTIFY_WRITE_DEFINE(DecrementVoltage)
//ORTTCPX_NOTIFY_WRITE_DEFINE(DecrementVoltageAndVerify)
//ORTTCPX_NOTIFY_WRITE_DEFINE(IncrementCurrent)
//ORTTCPX_NOTIFY_WRITE_DEFINE(SetAllOutput)
//ORTTCPX_NOTIFY_WRITE_DEFINE(ClearTrip)
//ORTTCPX_NOTIFY_WRITE_DEFINE(Local)
//ORTTCPX_NOTIFY_WRITE_DEFINE(RequestLock)
//ORTTCPX_NOTIFY_WRITE_DEFINE(CheckLock)
//ORTTCPX_NOTIFY_WRITE_DEFINE(ReleaseLock)

//ORTTCPX_NOTIFY_WRITE_DEFINE(SetEventStatusRegister)
//ORTTCPX_NOTIFY_WRITE_DEFINE(GetEventStatusRegister)
//ORTTCPX_NOTIFY_WRITE_DEFINE(SaveCurrentSetup)
//ORTTCPX_NOTIFY_WRITE_DEFINE(RecallSetup)
//ORTTCPX_NOTIFY_WRITE_DEFINE(SetOperatingMode)
//ORTTCPX_NOTIFY_WRITE_DEFINE(GetOperatingMode)
//ORTTCPX_NOTIFY_WRITE_DEFINE(SetRatio)
//ORTTCPX_NOTIFY_WRITE_DEFINE(GetRatio)
//ORTTCPX_NOTIFY_WRITE_DEFINE(ClearStatus)

//ORTTCPX_NOTIFY_WRITE_DEFINE(SetESE)
//ORTTCPX_NOTIFY_WRITE_DEFINE(GetESE)
//ORTTCPX_NOTIFY_WRITE_DEFINE(GetISTLocalMsg)
//ORTTCPX_NOTIFY_WRITE_DEFINE(SetOPCBit)
//ORTTCPX_NOTIFY_WRITE_DEFINE(GetOPCBit)
//ORTTCPX_NOTIFY_WRITE_DEFINE(SetParallelPollRegister)
//ORTTCPX_NOTIFY_WRITE_DEFINE(GetParallelPollRegister)


//ORTTCPX_NOTIFY_WRITE_DEFINE(SetSRE)
//ORTTCPX_NOTIFY_WRITE_DEFINE(GetSRE)
//ORTTCPX_NOTIFY_WRITE_DEFINE(GetID)
//ORTTCPX_NOTIFY_WRITE_DEFINE(GetBusAddress)


