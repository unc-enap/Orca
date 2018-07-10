//
//  ORKatrinV4SLTRegisters.h
//  Orca
//
//  Created by Mark Howe on Sun June 4, 2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina  sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------
#define kNoAccess   0x0
#define kRead       0x1
#define kWrite      0x2
#define kChanReg    0x4
#define kReadOnly  kRead
#define kWriteOnly kWrite
#define kReadWrite kRead|kWrite

@class ORKatrinV4SLTRegisters;

#define katrinV4SLTRegisters [ORKatrinV4SLTRegisters sharedRegSet]

static ORKatrinV4SLTRegisters* sharedKatrinV4SLTRegisters;

//IPE V4 register definitions
typedef enum eKatriV4SLTEnum {
    kKatrinV4SLTControlReg,
    kKatrinV4SLTStatusReg,
    kKatrinV4SLTCommandReg,
    kKatrinV4SLTInterruptReguestReg,
    kKatrinV4SLTInterruptMaskReg,
    kKatrinV4SLTRequestSemaphoreReg,
    kKatrinV4SLTHWRevisionReg,
    kKatrinV4SLTPixelBusErrorReg,
    kKatrinV4SLTPixelBusEnableReg,
    kKatrinV4SLTVetoCounterHiReg,
    kKatrinV4SLTVetoCounterLoReg,
    kKatrinV4SLTDeadTimeCounterHiReg,
    kKatrinV4SLTDeadTimeCounterLoReg,
    kKatrinV4SLTRunCounterHiReg,
    kKatrinV4SLTRunCounterLoReg,
    kKatrinV4SLTLostEventsCountHiReg,
    kKatrinV4SLTLostEventsCountLoReg,
    kKatrinV4SLTSecondSetReg,
    kKatrinV4SLTSecondCounterReg,
    kKatrinV4SLTSubSecondCounterReg,
    kKatrinV4SLTPageSelectReg,
    kKatrinV4SLTTPTimingReg,
    kKatrinV4SLTTPShapeReg,
    kKatrinV4SLTi2cCommandReg,
    kKatrinV4SLTepcsCommandReg,
    kKatrinV4SLTBoardIDLoReg,
    kKatrinV4SLTBoardIDHiReg,
    kKatrinV4SLTPROMsControlReg,
    kKatrinV4SLTPROMsBufferReg,
    kKatrinV4SLTDataFIFOReg,
    kKatrinV4SLTFIFOModeReg,
    kKatrinV4SLTFIFOStatusReg,
    kKatrinV4SLTPAEOffsetReg,
    kKatrinV4SLTPAFOffsetReg,
    kKatrinV4SLTFIFOCsrReg,
    kKatrinV4SLTFIFOxRequestReg,
    kKatrinV4SLTFIFOMaskReg,
    kKatrinV4SLTNumRegs //must be last
} eKatriV4SLTEnum;


@interface ORKatrinV4SLTRegisters : NSObject
{
    BOOL printedOnce;
}

+ (ORKatrinV4SLTRegisters*) sharedRegSet;
- (id) init;
- (void) dealloc;
- (BOOL) checkRegisterTable;

- (int)           numRegisters;
- (NSString*)     registerName: (short) anIndex;
- (short)         accessType:   (short) anIndex;
- (unsigned long) address:      (short) anIndex;
- (BOOL)          isWritable:   (short) anIndex;
- (BOOL)          isReadable:   (short) anIndex;
@end
