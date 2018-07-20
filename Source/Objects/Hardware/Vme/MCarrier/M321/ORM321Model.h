//
//  ORM321Model.h
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORVmeMCard.h"

#pragma mark ¥¥¥Forward Definitions
@class ORAlarm;

#pragma mark ¥¥¥Struct Definitions
typedef struct {
    unsigned short cmd;
    unsigned short result;
    unsigned short paramList[32];
    unsigned short irqstat;
}m321Cmd;

#pragma mark ¥¥¥ Definitions
enum {
    
    kM361_DualPortMemory  = 0x00,
    kM361_PageRegister    = 0x80,
    kM361_ControlRegister = 0x82,
    kM361_EEPROMRegister  = 0xFE,
    
    kM361_CmdPage         = 0x0004,
    
    kM361_HostIRQBit      = 0x0001,
    kM361_LocalIRQBit     = 0x0002,
    kM361_ResetBit        = 0x0004,
    kM361_PollBit         = 0x0008,
    
    kM361_CmdOffset       = kM361_DualPortMemory + 0x00,
    kM361_ResultOffset    = kM361_DualPortMemory + 0x02,
    kM361_ParamListOffset = kM361_DualPortMemory + 0x04,
    kM361_IrqOffset       = kM361_DualPortMemory + sizeof(m321Cmd)-2
    
};


enum {
    //read commands
    kM361_NoError            = 0x0000,  //No error   
    kM361_Violation          = 0x8888,  //Protocal Violation   
    kM361_UnknownCmd         = 0x8001,  //Unknown Cmd   
    kM361_PRange             = 0x8002,  //Param out of range
    kM361_ExcpError          = 0x8003,  //General Exception Error
    kM361_LocalBusError      = 0x8004,  //Local Bus Error
    kM361_LocalAddError      = 0x8005,  //Local Address Error
    kM361_LocIll             = 0x8006,  //Illegal Instruction
    kM361_SpurInt            = 0x8007,  //Spurious Interrupt
    kM361_InvReq             = 0x8008,  //Invalid Request
    kM361_Busy               = 0x8009,  //Waiting for External Triggering
    kM361_ProfError          = 0x800A,  //Error in Motion Profile
    kM361_FlashError         = 0x800B,  //Flash program Error
    kM361_TimeOut            = 0xFFFF   //locally defined timeout
};

enum {
    //read commands
    kM361_IrqBlank          = 0x0000,  //Nothing to report   
    kM361_IrqCmdDone        = 0x0001,  //command executed  
    kM361_IrqBreakPtA       = 0x0002,  //Breakpoint motor A   
    kM361_IrqBreakPtB       = 0x0004,  //Breakpoint motor B
    kM361_IrqTrajA          = 0x0008,  //Trajectory Complete motor A
    kM361_IrqTrajB          = 0x0010,  //Trajectory Complete motor B
    kM361_IrqHomeA          = 0x0020,  //Home Detected Motor A
    kM361_IrqHomeB          = 0x0040,  //Home Detected Motor B
    kM361_IrqException      = 0x0080  //Internal Exception Error
};

enum {
    //read commands
    kM361_Done               = 0x0000,  //command completed   
    kM361_Sync               = 0x5a5a,  //sync firmware, sign of live
    kM361_Version            = 0x0001,  //returns verion information
    kM361_MSKI               = 0x0020,  //mask/unmask interrupts    
    kM361_IAKC               = 0x0030,  //acknowledge interrupts    
    kM361_SetModeA           = 0x0200,  //set driving mode (full,half,micro) motor A   
    kM361_SetModeB           = 0x0201,  //set driving mode (full,half,micro) motor B   
    kM361_ProfileAbsA        = 0x0300,  //abs trapezoidal movement motor A   
    kM361_ProfileAbsB        = 0x0301,  //abs trapezoidal movement motor B
    kM361_ProfileRelA        = 0x0400,  //rel trapezoidal movement motor A   
    kM361_ProfileRelB        = 0x0401,  //rel trapezoidal movement motor B
    kM361_GetPosA            = 0x0500,  //get position motor A
    kM361_GetPosB            = 0x0501,  //get position motor B
    kM361_SetPosA            = 0x0600,  //set home position motor A
    kM361_SetPosB            = 0x0601,  //set home position  motor B
    kM361_SetBrkAbsA         = 0x0700,  //set abs breakpoint motor A
    kM361_SetBrkAbsB         = 0x0701,  //set abs breakpoint motor B
    kM361_SetBrkRelA         = 0x0800,  //set rel breakpoint motor A
    kM361_SetBrkRelB         = 0x0801,  //set rel breakpoint motor B
    kM361_BrakeA             = 0x0900,  //break motor A
    kM361_BrakeB             = 0x0901,  //break motor B
    kM361_SetHoldCurrA       = 0x0A00,  //set hold current reduction factor motor A
    kM361_SetHoldCurrB       = 0x0A01,  //set hold current reduction factor motor B
    kM361_SeekHomeA          = 0x0B00,  //seek home motor A
    kM361_SeekHomeB          = 0x0B01,  //seek home motor B
    kM361_ReadHomeA          = 0x0C00,  //read home sensor A status
    kM361_ReadHomeB          = 0x0C01,  //read home sensor B status
    kM361_SignalHomeA        = 0x0D00,  //signal transition on home input A
    kM361_SignalHomeB        = 0x0D01,  //signal transition on home input B
    kM361_SyncA              = 0x0E00,  //enable sync motion A
    kM361_SyncB              = 0x0E01,  //enable sync motion B
    kM361_SwSyncA            = 0x0E10,  //enable software sync motion A
    kM361_SwSyncB            = 0x0E11,  //enable software sync motion B
    kM361_GoA                = 0x0E20,  //start pending motion A
    kM361_GoB                = 0x0E21,  //start pending motion B
    kM361_AbortA             = 0x0F00,  //abort motion A
    kM361_AbortB             = 0x0F01  //abort motion B
};

enum {
    kMotorA = 0,
    kMotorB = 1
};

@interface ORM321Model :  ORVmeMCard
{
    @private
        NSLock* hwLock;
        BOOL fourPhase; 
        NSTimeInterval lastPollTime;
    
}

#pragma mark ¥¥¥Initialization
- (void) makeConnector2;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) checkHardwareConfig:(NSNotification*)aNote;
- (void)assignTag:(id)aMotor;

#pragma mark ¥¥¥Accessors
- (BOOL) fourPhase;
- (void) setFourPhase:(BOOL)flag;

#pragma mark ¥¥¥Hardware Access
- (NSString*) translatedErrorCode:(unsigned short)aCode;
- (void) probe;
- (void) sync;

- (BOOL) isMotorMoving:(id)aMotor;
- (void)  readHome:(id)aMotor;
- (void) seekHome:(int32_t)amount motor:(id)aMotor;
- (void) readMotor:(id)aMotor;
- (void) startMotor:(id)aMotor;
- (void) stopMotor:(id)aMotor;
- (void) loadStepMode:(int)mode motor:(id)aMotor;
- (void) loadHoldCurrent:(int32_t)amount motor:(id)aMotor;
- (void) loadStepCount:(int32_t)amount motor:(id)aMotor;
- (void) loadBreakPoint:(int)amount absolute:(BOOL)useAbs motor:(id)aMotor;
- (void) moveMotor:(id)aMotor amount:(int32_t)amount;
- (void) moveMotor:(id)aMotor to:(int32_t)position;
- (void) status;

- (void) executeMotorCmd:(unsigned short) theCommand 
                   motor:(id)aMotor
                riseFreq:(uint32_t) theRiseFreq 
               driveFreq:(uint32_t) theDriveFreq
            acceleration:(uint32_t) theAcceleration
                   steps:(int32_t)thePosition;

- (void) resetIRQ:(id)aMotor;
- (unsigned short) readIRQ;
@end

extern NSString* ORM321FourPhaseChangedNotification;
