//
//  ORKatrinHgfAmcRegisters.h
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
#define kRead    0x1
#define kWrite   0x2
#define kChanReg 0x4
#define kReadOnly  kRead
#define kWriteOnly kWrite
#define kReadWrite kRead|kWrite

@class ORKatrinHgfAmcRegisters;

#define KatrinHgfAmcRegisters [ORKatrinHgfAmcRegisters sharedRegSet]

#define kKatrinV4HitRunRateAlways    1
#define kKatrinV4HitRunRateWithRun   0

static ORKatrinHgfAmcRegisters* sharedKatrinHgfAmcRegisters;

typedef enum eKatrinHgfAmcRegEnum {
    kFLTV4StatusReg,
    kFLTV4ControlReg,
    kFLTV4CommandReg,
    kFLTV4VersionReg,
    kFLTV4BoardIDLsbReg,
    kFLTV4BoardIDMsbReg,
    kFLTV4InterruptMaskReg,
    kFLTV4HrMeasEnableReg,
    kFLTV4EventFifoStatusReg,
    kFLTV4PixelSettings1Reg,
    kFLTV4PixelSettings2Reg,
    kFLTV4RunControlReg,
    kFLTV4HistgrSettingsReg,
    kFLTV4AccessTestReg,
    kFLTV4SecondCounterReg,
    kFLTV4HrControlReg,
    kFLTV4HistMeasTimeReg,
    kFLTV4HistRecTimeReg,
    kFLTV4HistNumMeasReg,
    kFLTV4PostTriggerReg,
    kFLTV4EnergyOffsetReg,
    kFLTV4FIFOLostCounterLsbReg,
    kFLTV4FIFOLostCounterMsbReg,
    kFLTV4FIFOLostCounterTrLsbReg,
    kFLTV4FIFOLostCounterTrMsbReg,
    kFLTV4ThresholdReg,
    kFLTV4pStatusAReg,
    kFLTV4pStatusBReg,
    kFLTV4pStatusCReg,
    kFLTV4AnalogOffsetReg,
    kFLTV4GainReg,
    kFLTV4HitRateReg,
    kFLTV4EventFifo1Reg,
    kFLTV4EventFifo2Reg,
    kFLTV4EventFifo3Reg,
    kFLTV4EventFifo4Reg,
    kFLTV4HistPageNReg,
    kFLTV4HistLastFirstReg,
    kFLTV4TestPatternReg,
    kFLTV4NumRegs //must be last
} eKatrinHgfAmcRegEnum;

@interface ORKatrinHgfAmcRegisters : NSObject
{
    BOOL printedOnce;
}

+ (ORKatrinHgfAmcRegisters*) sharedRegSet;
- (id) init;
- (void) dealloc;
- (BOOL) checkRegisterTable;

- (int)           numRegisters;
- (NSString*)     registerName: (short) anIndex;
- (short) addressOffset: (short) anIndex;
- (short)         accessType: (short) anIndex;
- (uint32_t) addressForStation:(int)aStation registerIndex:(int)aReg chan:(int)aChannel;
- (uint32_t) addressForStation:(int)aStation registerIndex:(int)aReg;

@end
