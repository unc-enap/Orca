//
//  ORFec32Model.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORFec32Model.h"
#import "ORXL1Model.h"
#import "ORXL2Model.h"
#import "ORXL3Model.h"
#import "ORSNOCrateModel.h"
#import "ORFecDaughterCardModel.h"
#import "ORSNOConstants.h"
#import "OROrderedObjManager.h"
#import "ObjectFactory.h"
#import "ORSNOCrateModel.h"
#import "ORVmeReadWriteCommand.h"
#import "ORCommandList.h"
#import "OROrderedObjManager.h"
#import "ORHWWizSelection.h"
#import "ORHWWizParam.h"
#import "ORHWWizardController.h"
#import "ORPQModel.h"

//#define VERIFY_CMOS_SHIFT_REGISTER	// uncomment this to verify CMOS shift register loads - PH 09/17/99

// the bottom 16 and upper 16 FEC32 channels
#define BOTTOM_CHANNELS	0
#define UPPER_CHANNELS	1


NSString* ORFec32ModelEverythingChanged             = @"ORFec32ModelEverythingChanged";
NSString* ORFec32ModelCmosRateChanged				= @"ORFec32ModelCmosRateChanged";
NSString* ORFec32ModelBaseCurrentChanged			= @"ORFec32ModelBaseCurrentChanged";
NSString* ORFec32ModelVariableDisplayChanged		= @"ORFec32ModelVariableDisplayChanged";
NSString* ORFecShowVoltsChanged						= @"ORFecShowVoltsChanged";
NSString* ORFecCommentsChanged						= @"ORFecCommentsChanged";
NSString* ORFecCmosChanged							= @"ORFecCmosChanged";
NSString* ORFecVResChanged							= @"ORFecVResChanged";
NSString* ORFecHVRefChanged							= @"ORFecHVRefChanged";
NSString* ORFecLock									= @"ORFecLock";
NSString* ORFecOnlineMaskChanged					= @"ORFecOnlineMaskChanged";
NSString* ORFecPedEnabledMaskChanged				= @"ORFecPedEnabledMaskChanged";
NSString* ORFecSeqDisabledMaskChanged				= @"ORFecSeqDisabledMaskChanged";
NSString* ORFecTrigger100nsDisabledMaskChanged		= @"ORFecTrigger100nsDisabledMaskChanged";
NSString* ORFecTrigger20nsDisabledMaskChanged		= @"ORFecTrigger20nsDisabledMaskChanged";
NSString* ORFecCmosReadDisabledMaskChanged          = @"ORFecCmosReadDisabledMaskChanged";
NSString* ORFecQllEnabledChanged					= @"ORFecQllEnabledChanged";
NSString* ORFec32ModelAdcVoltageChanged				= @"ORFec32ModelAdcVoltageChanged";
NSString* ORFec32ModelAdcVoltageStatusChanged		= @"ORFec32ModelAdcVoltageStatusChanged";
NSString* ORFec32ModelAdcVoltageStatusOfCardChanged	= @"ORFec32ModelAdcVoltageStatusOfCardChanged";

// mask for crates that need updating after Hardware Wizard action
static uint32_t crateInitMask; // crates that need to be initialized
static uint32_t cratePedMask;  // crates that need their pedestals set

static int              sDetectorDbState = 0; // (0=not loaded, 1=loading, 2=loaded (or not), 3=stale (or none))
static ORPQDetectorDB*  sDetectorDbData = nil;
static NSAlert *        sReadingHvdbAlert = nil;
static int              sChannelsNotChangedCount = 0;

@interface ORFec32Model (private)
- (ORCommandList*) cmosShiftLoadAndClock:(unsigned short) registerAddress cmosRegItem:(unsigned short) cmosRegItem bitMaskStart:(short) bit_mask_start;
- (void) cmosShiftLoadAndClockBit3:(unsigned short) registerAddress cmosRegItem:(unsigned short) cmosRegItem bitMaskStart:(short) bit_mask_start;
- (void) loadCmosShiftRegData:(unsigned short)whichChannels triggersDisabled:(BOOL)aTriggersDisabled;
- (void) loadCmosShiftRegisters:(BOOL) aTriggersDisabled;
@end

@interface ORFec32Model (SBC)
- (void) loadAllDacsUsingSBC;
- (NSString*) performBoardIDReadUsingSBC:(short) boardIndex;
@end

@interface ORFec32Model (LocalAdapter)
- (void) loadAllDacsUsingLocalAdapter;
- (NSString*) performBoardIDReadUsingLocalAdapter:(short) boardIndex;
@end

@interface ORFec32Model (XL2)
-(BOOL) readVoltagesUsingXL2;
-(short) readVoltageValue:(uint32_t) aMask;
-(BOOL) readCMOSCountsUsingXL2:(BOOL)calcRates channelMask:(uint32_t) aChannelMask;
@end

@interface ORFec32Model (XL3)
- (uint32_t) relayChannelMask;
-(BOOL) parseVoltagesUsingXL3:(VMonResults*)result;
-(BOOL) readVoltagesUsingXL3;
-(void) readCMOSCountsUsingXL3:(uint32_t)aChannelMask;
-(void) readCMOSRatesUsingXL3:(uint32_t)aChannelMask;
@end

@implementation ORFec32Model

#pragma mark •••Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
	[self setComments:@""];
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
   
    return self;
}
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [comments release];
    [super dealloc];
}

- (void) objectCountChanged
{
	int i;
	for(i=0;i<4;i++){
		dcPresent[i] =  NO;
		dc[i] = nil;
	}
	
    for (id aCard in [self orcaObjects]) { 
		if([aCard isKindOfClass:[ORFecDaughterCardModel class]]){
			dcPresent[[(ORFecDaughterCardModel*)aCard slot]] = YES;
			dc[[(ORFecDaughterCardModel*)aCard slot]] = aCard;
		}
	}
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"Fec32 (%d,%u)",(int)[self crateNumber],(int)[self stationNumber]];
}

- (NSComparisonResult)	slotCompare:(id)otherCard
{
    return [self stationNumber] - [otherCard stationNumber];
}

#pragma mark ***Accessors

- (int32_t) cmosRate:(short)index
{
    return cmosRate[index];
}

- (void) setCmosRate:(short)index withValue:(int32_t)aCmosRate
{
    cmosRate[index] = aCmosRate;

    [self postNotificationName:ORFec32ModelCmosRateChanged];
}

- (float) baseCurrent:(short)index
{
    return baseCurrent[index];
}

- (void) setBaseCurrent:(short)index withValue:(float)aBaseCurrent
{
    baseCurrent[index] = aBaseCurrent;

    [self postNotificationName:ORFec32ModelBaseCurrentChanged];
}

- (int) variableDisplay
{
    return variableDisplay;
}

- (void) setVariableDisplay:(int)aVariableDisplay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVariableDisplay:variableDisplay];
    
    variableDisplay = aVariableDisplay;

    [self postNotificationName:ORFec32ModelVariableDisplayChanged];
}

- (float) adcVoltage:(int)index
{
	if(index>=0 && index<kNumFecMonitorAdcs) return adcVoltage[index];
	else return -1;
}

- (void) setAdcVoltage:(int)index withValue:(float)aValue
{
	if(index>=0 && index<kNumFecMonitorAdcs){
		adcVoltage[index] = aValue;
        NSNumber* aNum = [[NSNumber alloc] initWithInt:index];
		NSDictionary* userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  aNum, @"index",
                                  nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelAdcVoltageChanged object:self userInfo:userInfo];
        [aNum release]; aNum = nil;
        [userInfo release]; userInfo = nil;
	}
}

- (eFecMonitorState) adcVoltageStatusOfCard
{
	return adcVoltageStatusOfCard;
}

- (void) setAdcVoltageStatusOfCard:(eFecMonitorState)aState
{
	adcVoltageStatusOfCard = aState;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelAdcVoltageStatusOfCardChanged object:self userInfo:nil];
}

- (eFecMonitorState) adcVoltageStatus:(int)index
{
	if(index>=0 && index<kNumFecMonitorAdcs) return adcVoltageStatus[index];
	else return kFecMonitorNeverMeasured;
}

- (void) setAdcVoltageStatus:(int)index withValue:(eFecMonitorState)aState
{
	if(index>=0 && index<kNumFecMonitorAdcs){
		adcVoltageStatus[index] = aState;
        NSNumber* aNum = [[NSNumber alloc] initWithInt:index];
		NSDictionary* userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   aNum, @"index",
                                   nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORFec32ModelAdcVoltageStatusChanged object:self userInfo:userInfo];
        [aNum release]; aNum = nil;
        [userInfo release]; userInfo = nil;      
	}
}

- (BOOL) dcPresent:(unsigned short)index
{
	if(index<4)return dcPresent[index];
	else return NO;
}

- (ORFecDaughterCardModel*) dc:(unsigned short)index
{
    if (index<4) return dc[index];
    else return nil;
}

- (BOOL) qllEnabled
{
	return qllEnabled;
}

- (void) setQllEnabled:(BOOL) state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setQllEnabled:qllEnabled];
	qllEnabled = state;
	[self postNotificationName:ORFecQllEnabledChanged];
}

- (BOOL) pmtOnline:(unsigned short)index
{
	if(index<32) return [self dcPresent:index/8] && (onlineMask & (1UL<<index));
	else return NO;
}

- (uint32_t) pedEnabledMask
{
	return pedEnabledMask;
}

- (void) setPedEnabledMask:(uint32_t) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPedEnabledMask:pedEnabledMask];
    pedEnabledMask = aMask;
    [self postNotificationName:ORFecPedEnabledMaskChanged];
}

- (void) setPed:(short)chan enabled:(short)state
{
    if(state) pedEnabledMask |= (1<<chan);
    else      pedEnabledMask &= ~(1<<chan);
}
- (BOOL) pedEnabled:(short)chan
{
    return (pedEnabledMask & (1<<chan)) != 0;
}

#pragma mark Sequencer enable/disable methods
- (uint32_t) seqDisabledMask
{
	return seqDisabledMask;
}

- (void) setSeqDisabledMask:(uint32_t) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSeqDisabledMask:seqDisabledMask];
    seqDisabledMask = aMask;
    [self postNotificationName:ORFecSeqDisabledMaskChanged];
}

- (BOOL) seqEnabled:(short)chan
{
    return (seqDisabledMask & (1<<chan))==0;
}

- (void) setSeq:(short)chan enabled:(short)state
{
    uint32_t aMask = seqDisabledMask;
    if(state) aMask &= ~(1<<chan);
    else      aMask |= (1<<chan);
    [self setSeqDisabledMask:aMask];
}

- (BOOL) seqDisabled:(short)chan
{
    return (seqDisabledMask & (1<<chan))!=0;
}

- (uint32_t) seqPendingDisabledMask
{
    return seqPendingDisabledMask;
}

- (void) setSeqPendingDisabledMask:(uint32_t) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSeqPendingDisabledMask:seqPendingDisabledMask];
    seqPendingDisabledMask = aMask;
    [self postNotificationName:ORFecSeqDisabledMaskChanged];
}

- (BOOL) seqPendingEnabled:(short)chan
{
    return (seqPendingDisabledMask & (1<<chan))==0;
}

- (BOOL) seqPendingDisabled:(short)chan
{
    return (seqPendingDisabledMask & (1<<chan))!=0;
}

- (void) togglePendingSeq:(short)chan
{
    uint32_t aMask = seqPendingDisabledMask;
    aMask ^= (1<<chan);
    [self setSeqPendingDisabledMask:aMask];
}

- (void) makeAllSeqPendingStatesSameAs:(short)chan
{
    uint32_t newMask;
    if((seqPendingDisabledMask & (1<<chan))==0) newMask = 0x00000000;
    else                                        newMask = 0xFFFFFFFF;
    [self setSeqPendingDisabledMask:newMask];
}

#pragma mark Trigger 20ns enable/disable methods
- (uint32_t) trigger20nsDisabledMask
{
    return trigger20nsDisabledMask;
}

- (void) setTrigger20nsDisabledMask:(uint32_t) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger20nsDisabledMask:trigger20nsDisabledMask];
    trigger20nsDisabledMask = aMask;
    [self postNotificationName:ORFecTrigger20nsDisabledMaskChanged];
}

- (BOOL) trigger20nsDisabled:(short)chan
{
    return (trigger20nsDisabledMask & (1<<chan))!=0;
}

- (BOOL) trigger20nsEnabled:(short)chan
{
    return (trigger20nsDisabledMask & (1<<chan))==0;
}

- (void) setTrigger20ns:(short) chan disabled:(short)state
{
    uint32_t aMask = trigger20nsDisabledMask;
    if(state) aMask |= (1<<chan);
    else      aMask &= ~(1<<chan);
    [self setTrigger20nsDisabledMask:aMask];
}

- (void) setTrigger20ns:(short) chan enabled:(short)state
{
    uint32_t aMask = trigger20nsDisabledMask;
    if(state) aMask &= ~(1<<chan);
    else      aMask |= (1<<chan);
    [self setTrigger20nsDisabledMask:aMask];
}

- (uint32_t) trigger20nsPendingDisabledMask
{
    return trigger20nsPendingDisabledMask;
}

- (void) setTrigger20nsPendingDisabledMask:(uint32_t) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger20nsPendingDisabledMask:trigger20nsPendingDisabledMask];
    trigger20nsPendingDisabledMask = aMask;
    [self postNotificationName:ORFecTrigger20nsDisabledMaskChanged];
}

- (BOOL) trigger20nsPendingEnabled:(short)chan
{
    return (trigger20nsPendingDisabledMask & (1<<chan))==0;
}

- (BOOL) trigger20nsPendingDisabled:(short)chan
{
    return (trigger20nsPendingDisabledMask & (1<<chan))!=0;
}

- (void) togglePendingTrigger20ns:(short)chan
{
    uint32_t aMask = trigger20nsPendingDisabledMask;
    aMask ^= (1<<chan);
    [self setTrigger20nsPendingDisabledMask:aMask];
}

- (void) makeAll20nsPendingStatesSameAs:(short)chan
{
    uint32_t newMask;
    if((trigger20nsPendingDisabledMask & (1<<chan))==0) newMask = 0x00000000;
    else                                                newMask = 0xFFFFFFFF;
    [self setTrigger20nsPendingDisabledMask:newMask];
}

#pragma mark Trigger 100ns enable/disable methods
- (uint32_t) trigger100nsDisabledMask
{
    return trigger100nsDisabledMask;
}

- (void) setTrigger100nsDisabledMask:(uint32_t) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger100nsDisabledMask:trigger100nsDisabledMask];
    trigger100nsDisabledMask = aMask;
    [self postNotificationName:ORFecTrigger100nsDisabledMaskChanged];
}

- (BOOL) trigger100nsDisabled:(short)chan
{
    return (trigger100nsDisabledMask & (1<<chan))!=0;
}

- (BOOL) trigger100nsEnabled:(short)chan
{
    return (trigger100nsDisabledMask & (1<<chan))==0;
}

- (void) setTrigger100ns:(short) chan disabled:(short)state
{
    uint32_t aMask = trigger100nsDisabledMask;
    if(state) aMask |= (1<<chan);
    else      aMask &= ~(1<<chan);
    [self setTrigger100nsDisabledMask:aMask];
}

- (void) setTrigger100ns:(short) chan enabled:(short)state
{
    uint32_t aMask = trigger100nsDisabledMask;
    if(state) aMask &= ~(1<<chan);
    else      aMask |= (1<<chan);
    [self setTrigger100nsDisabledMask:aMask];
}

- (uint32_t) trigger100nsPendingDisabledMask
{
    return trigger100nsPendingDisabledMask;
}

- (void) setTrigger100nsPendingDisabledMask:(uint32_t) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger100nsPendingDisabledMask:trigger100nsPendingDisabledMask];
    trigger100nsPendingDisabledMask = aMask;
    [self postNotificationName:ORFecTrigger100nsDisabledMaskChanged];
}
- (BOOL) trigger100nsPendingDisabled:(short)chan
{
    return (trigger100nsPendingDisabledMask & (1<<chan))!=0;
}

- (BOOL) trigger100nsPendingEnabled:(short)chan
{
    return (trigger100nsPendingDisabledMask & (1<<chan))==0;
}

- (void) togglePendingTrigger100ns:(short)chan
{
    uint32_t aMask = trigger100nsPendingDisabledMask;
    aMask ^= (1<<chan);
    [self setTrigger100nsPendingDisabledMask:aMask];
}
- (void) makeAll100nsPendingStatesSameAs:(short)chan
{
    uint32_t newMask;
    if((trigger100nsPendingDisabledMask & (1<<chan))==0) newMask = 0x00000000;
    else                                                 newMask = 0xFFFFFFFF;
    [self setTrigger100nsPendingDisabledMask:newMask];
}
#pragma mark CMOS enable/disable methods
- (uint32_t) cmosReadDisabledMask
{
    return cmosReadDisabledMask;
}

- (void) setCmosReadDisabledMask:(uint32_t) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmosReadDisabledMask:cmosReadDisabledMask];
    cmosReadDisabledMask = aMask;
    [self postNotificationName:ORFecCmosReadDisabledMaskChanged];
}

- (BOOL) cmosReadDisabled:(short)chan
{
    return (cmosReadDisabledMask & (1<<chan))!=0;
}

- (BOOL) cmosReadEnabled:(short)chan
{
    return (cmosReadDisabledMask & (1<<chan))==0;
}

- (void) setCmosRead:(short) chan disabled:(short)state
{
    uint32_t aMask = cmosReadDisabledMask;
    if(state) cmosReadDisabledMask |= (1<<chan);
    else      cmosReadDisabledMask &= ~(1<<chan);
    [self setCmosReadDisabledMask:aMask];
}

- (void) setCmosRead:(short) chan enabled:(short)state
{
    uint32_t aMask = cmosReadDisabledMask;
    if(state) aMask &= ~(1<<chan);
    else      aMask |= (1<<chan);
    [self setCmosReadDisabledMask:aMask];
}

- (uint32_t) cmosReadPendingDisabledMask
{
    return cmosReadPendingDisabledMask;
}

- (void) setCmosReadPendingDisabledMask:(uint32_t) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmosReadPendingDisabledMask:cmosReadPendingDisabledMask];
    cmosReadPendingDisabledMask = aMask;
    [self postNotificationName:ORFecCmosReadDisabledMaskChanged];
}
- (BOOL) cmosReadPendingDisabled:(short)chan
{
    return (cmosReadPendingDisabledMask & (1<<chan))!=0;
}

- (BOOL) cmosReadPendingEnabled:(short)chan
{
    return (cmosReadPendingDisabledMask & (1<<chan))==0;
}

- (void) togglePendingCmosRead:(short)chan
{
    uint32_t aMask = cmosReadPendingDisabledMask;
    aMask ^= (1<<chan);
    [self setCmosReadPendingDisabledMask:aMask];
}

- (void) makeAllCmosPendingStatesSameAs:(short)chan
{
    uint32_t newMask;
    if((cmosReadPendingDisabledMask & (1<<chan))==0) newMask = 0x00000000;
    else                                             newMask = 0xFFFFFFFF;
    [self setCmosReadPendingDisabledMask:newMask];
}

// load hardware from pending state
- (void) loadHardware
{
    /* save these in case the init fails, then we can restore the current
     * state of the hardware */
    lastSeqDisabledMask = [self seqDisabledMask];
    lastTrigger100nsDisabledMask = [self trigger100nsDisabledMask];
    lastTrigger20nsDisabledMask = [self trigger20nsDisabledMask];
    lastCmosReadDisabledMask = [self cmosReadDisabledMask];

    [[self undoManager] disableUndoRegistration];
    [self setSeqDisabledMask:[self seqPendingDisabledMask]];
    [self setTrigger20nsDisabledMask:[self trigger20nsPendingDisabledMask]];
    [self setTrigger100nsDisabledMask:[self trigger100nsPendingDisabledMask]];
    [self setCmosReadDisabledMask:[self cmosReadPendingDisabledMask]];
    [[[self guardian] adapter]
         loadHardwareWithSlotMask: (1 << [self stationNumber])
         withCallback:@selector(loadHardwareDone:)
         target:self];
    [[self undoManager] enableUndoRegistration];
}

- (uint32_t) boardIDAsInt
{
    return (uint32_t)strtoul([[self boardID] UTF8String], NULL, 16);
}

- (void) checkConfig: (FECConfiguration *) config
{
    int i;
    ORFecDaughterCardModel *db;

    if (config->mbID == 0) {
        NSLogColor([NSColor redColor],
            @"crate %02d slot %02d is not plugged in according to XL3\n",
            [self crateNumber], [self stationNumber]);
        return;
    }

    if (config->mbID != [self boardIDAsInt]) {
        NSLogColor([NSColor redColor],
             @"crate %02d slot %02d mismatching board id. updating ORCA...\n",
             [self crateNumber], [self stationNumber]);
        [self setBoardID:[NSString stringWithFormat:@"%x", config->mbID]];
    }

    for (i = 0; i < 4; i++) {
        if ([self dcPresent:i]) {
            db = [self dc:i];

            if (config->dbID[i] != [db boardIDAsInt]) {
                NSLogColor([NSColor redColor], @"crate %02d slot %02d db %d mismatching board id. updating ORCA...\n", [self crateNumber], [self stationNumber], i);
                [db setBoardID:[NSString stringWithFormat:@"%x", config->dbID[i]]];
            }
        } else {
            if (config->dbID[i] != 0) {
                NSLogColor([NSColor redColor], @"crate %02d slot %02d db %d exists accoring to XL3. Adding to ORCA...\n", [self crateNumber], [self stationNumber], i);
                db = [ObjectFactory makeObject:@"ORFecDaughterCardModel"];
                [db setBoardID:[NSString stringWithFormat:@"%x", config->dbID[i]]];

                [self addObject:db];
                [self place:db intoSlot:i];
            }
        }
    }
}
            
- (void) loadHardwareDone: (CrateInitResults *) r
{
    if (r == NULL) {
        NSLogColor([NSColor redColor], @"crate %d slot %d failed to load hardware!\n", [self crateNumber], [self stationNumber]);
        [[self undoManager] disableUndoRegistration];
        [self setSeqDisabledMask:lastSeqDisabledMask];
        [self setTrigger20nsDisabledMask:lastTrigger20nsDisabledMask];
        [self setTrigger100nsDisabledMask:lastTrigger100nsDisabledMask];
        [self setCmosReadDisabledMask:lastCmosReadDisabledMask];
        [[self undoManager] enableUndoRegistration];
    } else {
        NSLog(@"crate %d slot %d hardware loaded!\n", [self crateNumber], [self stationNumber]);
        free(r);
    }
}

#pragma mark Trigger 20/100ns enable/disable methods
- (BOOL) trigger20ns100nsEnabled:(short)chan
{
    return (trigger20nsDisabledMask & (1<<chan))==0 && (trigger100nsDisabledMask & (1<<chan))==0;
}
- (void) setTrigger20ns100ns:(short) chan enabled:(short)state
{
    if(state) {
        trigger20nsDisabledMask &= ~(1<<chan);
        trigger100nsDisabledMask &= ~(1<<chan);
    }
    else {
        trigger20nsDisabledMask |= (1<<chan);
        trigger100nsDisabledMask |= (1<<chan);
    }
}

- (uint32_t) onlineMask
{
	return onlineMask;
}

// set online mask and init the crate registers
- (void) setOnlineMask:(uint32_t) aMask
{
    [self setOnlineMaskNoInit:aMask];
    [[[self guardian] adapter] loadHardware];
    cardChangedFlag = false;
}

// set online mask but don't do a crate init
- (void) setOnlineMaskNoInit:(uint32_t) aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:onlineMask];
    onlineMask = aMask;
    [self postNotificationName:ORFecOnlineMaskChanged];
    cardChangedFlag = true;
}
- (BOOL) getOnline:(short)chan
{
    return (onlineMask & (1<<chan))==0;
}
- (void) setOnline:(short)chan enabled:(short)state
{
    if(state) onlineMask |= (1<<chan);
    else      onlineMask &= ~(1<<chan);
}

// all of these Vth get/set routines deal with the daughtercard ecal+corr thresholds
- (short) getVth:(short)chan
{
    short dcNum = chan/8;
    if (dcNum<4 && dcPresent[dcNum]) {
        short dcChan = chan - dcNum*8;
        return [dc[dcNum] vt_ecal:dcChan] + [dc[dcNum] vt_corr:dcChan];
    } else {
        return -1;
    }
}
- (void) setVth:(short)chan withValue:(short)aValue
{
    short dcNum = chan/8;
    if (dcNum<4 && dcPresent[dcNum]) {
        short dcChan = chan - dcNum*8;
        [dc[dcNum] setVt_corr:dcChan withValue:(aValue - [dc[dcNum] vt_ecal:dcChan])];
        cardChangedFlag = true;
    }
}
- (short) getVthEcal:(short)chan
{
    short dcNum = chan/8;
    if (dcNum<4 && dcPresent[dcNum]) {
        short dcChan = chan - dcNum*8;
        return [dc[dcNum] vt_ecal:dcChan];
    } else {
        return -1;
    }
}
- (void) setVthToEcal:(short)chan
{
    short dcNum = chan/8;
    if (dcNum<4 && dcPresent[dcNum]) {
        short dcChan = chan - dcNum*8;
        [dc[dcNum] setVt_corr:dcChan withValue:0];
        cardChangedFlag = true;
    }
}
- (void) setVthToMax:(short)chan
{
    short dcNum = chan/8;
    if (dcNum<4 && dcPresent[dcNum]) {
        short dcChan = chan - dcNum*8;
        [dc[dcNum] setVt_corr:dcChan withValue:(255 - [dc[dcNum] vt_ecal:dcChan])];
        cardChangedFlag = true;
    }
}
- (short) getVThAboveZero:(short)chan
{
    short dcNum = chan/8;
    if (dcNum<4 && dcPresent[dcNum]) {
        short dcChan = chan - dcNum*8;
        return [dc[dcNum] vt_ecal:dcChan] + [dc[dcNum] vt_corr:dcChan] - [dc[dcNum] vt_zero:dcChan];
    } else {
        return -1;
    }
}
- (void) setVThAboveZero:(short)chan withValue:(unsigned char)aValue
{
    short dcNum = chan/8;
    if (dcNum<4 && dcPresent[dcNum]) {
        short dcChan = chan - dcNum*8;
        [dc[dcNum] setVt_corr:dcChan withValue:([dc[dcNum] vt_zero:dcChan] + aValue - [dc[dcNum] vt_ecal:dcChan])];
        cardChangedFlag = true;
    }
}

- (int) globalCardNumber
{
	//return ([guardian crateNumber] * 16) + [self stationNumber];
	return (int)(([[[self guardian] adapter] crateNumber] * 16) + [self stationNumber]);
}

- (NSComparisonResult) globalCardNumberCompare:(id)aCard
{
	return [self globalCardNumber] - [aCard globalCardNumber];
}


- (BOOL) showVolts
{
    return showVolts;
}

- (void) setShowVolts:(BOOL)aShowVolts
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowVolts:showVolts];
    
    showVolts = aShowVolts;
	
    [self postNotificationName:ORFecShowVoltsChanged];
}

- (NSString*) comments
{
    return comments;
}

- (void) setComments:(NSString*)aComments
{
	if(!aComments) aComments = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setComments:comments];
    
    [comments autorelease];
    comments = [aComments copy];    
	
    [self postNotificationName:ORFecCommentsChanged];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Fec32Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORFec32Controller"];
}
- (unsigned char) cmos:(short)anIndex
{
	return cmos[anIndex];
}

- (void) setCmos:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmos:anIndex withValue:cmos[anIndex]];
	cmos[anIndex] = aValue;
    [self postNotificationName:ORFecCmosChanged];
}

- (float) vRes
{
	return vRes;
}

- (void) setVRes:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVRes:vRes];
	vRes = aValue;
    [self postNotificationName:ORFecVResChanged];
}

- (float) hVRef
{
	return hVRef;
}

- (void) setHVRef:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHVRef:hVRef];
	hVRef = aValue;
    [self postNotificationName:ORFecHVRefChanged];
}

#pragma mark •••Converted Data Methods
- (void) setCmosVoltage:(short)n withValue:(float) value
{
	if(value>kCmosMax)		value = kCmosMax;
	else if(value<kCmosMin)	value = kCmosMin;
	
	[self setCmos:n withValue:255.0*(value-kCmosMin)/(kCmosMax-kCmosMin)+0.5];
}

- (float) cmosVoltage:(short) n
{
	return ((kCmosMax-kCmosMin)/255.0)*cmos[n]+kCmosMin;
}

- (void) setVResVoltage:(float) value
{
	if(value>kVResMax)		value = kVResMax;
	else if(value<kVResMin)	value = kVResMin;
	[self setVRes:255.0*(value-kVResMin)/(kVResMax-kVResMin)+0.5];
}

- (float) vResVoltage
{
	return ((kVResMax-kVResMin)/255.0)*vRes+kVResMin;
}

- (void) setHVRefVoltage:(float) value
{
	if(value>kHVRefMax)		 value = kHVRefMax;
	else if(value<kHVRefMin) value = kHVRefMin;
	[self setHVRef:(255.0*(value-kHVRefMin)/(kHVRefMax-kHVRefMin)+0.5)];
}

- (float) hVRefVoltage
{
	return ((kHVRefMax-kHVRefMin)/255.0)*hVRef+kHVRefMin;
}

- (void) readVoltages
{
    /* Read the voltage and temp adcs for a crate and card. Assumes that bus
     * access has already been granted. */
    [self readVoltagesUsingXL3];
}

- (void) parseVoltages:(VMonResults*)result;
{
    [self parseVoltagesUsingXL3:result];
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setVariableDisplay:               [decoder decodeIntForKey:	@"variableDisplay"]];
    [self setShowVolts:                     [decoder decodeBoolForKey:  @"showVolts"]];
    [self setComments:                      [decoder decodeObjectForKey:@"comments"]];
    [self setVRes:                          [decoder decodeFloatForKey: @"vRes"]];
    [self setHVRef:                         [decoder decodeFloatForKey: @"hVRef"]];
	[self setOnlineMask:                    [decoder decodeIntForKey: @"onlineMask"]];
	[self setPedEnabledMask:                [decoder decodeIntForKey: @"pedEnableMask"]];
    [self setAdcVoltageStatusOfCard:        [decoder decodeIntForKey:	@"adcVoltageStatusOfCard"]];
    [self setSeqDisabledMask:               [decoder decodeIntForKey: @"seqDisabledMask"]];
    [self setCmosReadDisabledMask:              [decoder decodeIntForKey: @"cmosReadDisabledMask"]];
    [self setTrigger20nsDisabledMask:           [decoder decodeIntForKey: @"trigger20nsDisabledMask"]];
    [self setTrigger100nsDisabledMask:          [decoder decodeIntForKey: @"trigger100nsDisabledMask"]];
    [self setSeqPendingDisabledMask:            [decoder decodeIntForKey: @"seqPendingDisabledMask"]];
    [self setTrigger20nsPendingDisabledMask:    [decoder decodeIntForKey: @"trigger20nsPendingDisabledMask"]];
    [self setTrigger100nsPendingDisabledMask:   [decoder decodeIntForKey: @"trigger100nsPendingDisabledMask"]];
    [self setCmosReadPendingDisabledMask:       [decoder decodeIntForKey: @"cmosReadPendingDisabledMask"]];
    
	int i;
	for(i=0;i<6;i++){
		[self setCmos:i withValue: [decoder decodeFloatForKey: [NSString stringWithFormat:@"cmos%d",i]]];
	}	
	for(i=0;i<kNumFecMonitorAdcs;i++){
		[self setAdcVoltage:i withValue: [decoder decodeFloatForKey: [NSString stringWithFormat:@"adcVoltage%d",i]]];
		[self setAdcVoltageStatus:i withValue: (eFecMonitorState)[decoder decodeIntegerForKey: [NSString stringWithFormat:@"adcStatus%d",i]]];
	}
	for(i=0;i<32;i++){
		[self setCmosRate:i withValue:[decoder decodeIntForKey:		[NSString stringWithFormat:@"cmosRate%d",i]]];
		[self setBaseCurrent:i withValue:[decoder decodeFloatForKey:	[NSString stringWithFormat:@"baseCurrent%d",i]]];
	}
	[[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    int i;

    [super encodeWithCoder:encoder];

    [encoder encodeInteger:variableDisplay              forKey: @"variableDisplay"];
    [encoder encodeBool:showVolts                   forKey: @"showVolts"];
    [encoder encodeObject:comments                  forKey: @"comments"];
    [encoder encodeFloat:vRes                       forKey: @"vRes"];
    [encoder encodeFloat:hVRef                      forKey: @"hVRef"];
    [encoder encodeInt:onlineMask                 forKey: @"onlineMask"];
    [encoder encodeInteger:adcVoltageStatusOfCard       forKey: @"adcVoltageStatusOfCard"];
    [encoder encodeInt:pedEnabledMask             forKey: @"pedEnabledMask"];
    [encoder encodeInt:seqDisabledMask                    forKey: @"seqDisabledMask"];
    [encoder encodeInt:cmosReadDisabledMask               forKey: @"cmosReadDisabledMask"];
    [encoder encodeInt:trigger20nsDisabledMask            forKey: @"trigger20nsDisabledMask"];
    [encoder encodeInt:trigger100nsDisabledMask           forKey: @"trigger100nsDisabledMask"];
    [encoder encodeInt:seqPendingDisabledMask             forKey: @"seqDisabledPendingMask"];
    [encoder encodeInt:cmosReadPendingDisabledMask        forKey: @"cmosReadPendingDisabledMask"];
    [encoder encodeInt:trigger20nsPendingDisabledMask     forKey: @"trigger20nsPendingDisabledMask"];
    [encoder encodeInt:trigger100nsPendingDisabledMask    forKey: @"trigger100nsPendingDisabledMask"];

    for(i = 0; i < 6; i++) {
        [encoder encodeFloat:cmos[i] forKey:[NSString stringWithFormat:@"cmos%d",i]];
    }

    for(i = 0; i < kNumFecMonitorAdcs; i++) {
        [encoder encodeFloat:adcVoltage[i] forKey:[NSString stringWithFormat:@"adcVoltage%d",i]];
        [encoder encodeInteger:adcVoltageStatus[i] forKey:[NSString stringWithFormat:@"adcStatus%d",i]];
    }

    for(i = 0; i < 32; i++){
        [encoder encodeInt:cmosRate[i] forKey: [NSString stringWithFormat:@"cmosRate%d",i]];
        [encoder encodeFloat:baseCurrent[i] forKey: [NSString stringWithFormat:@"baseCurrent%d",i]];
    }
}

#pragma mark •••Hardware Access

- (id) adapter
{
	id anAdapter = [[self guardian] adapter]; //should be the XL2 for this objects crate
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No XL2" format:@"Check that the crate has an XL2"];
	return nil;
}
- (id) xl1
{
	return [[self xl2] xl1];
}
- (id) xl2
{
	id anAdapter = [[self guardian] adapter]; //should be the XL2 for this objects crate
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No XL2" format:@"Check that the crate has an XL2"];
	return nil;
}

- (void) readBoardIds
{
	id xl2 = [self xl2];
	@try {
		[xl2 select:self];
		
		// Read the Daughter Cards for their ids
        for (id aCard in [[self guardian] orcaObjects]) { 
			if([aCard isKindOfClass:[ORSNOCard class]]){
				[aCard readBoardIds];
			}
		}	
		// Read the PMTIC for its id
        //
		//PerformBoardIDRead(HV_BOARD_ID_INDEX,&dataValue);
		
		//read the Mother Card for its id
		@try {
			[self setBoardID:[self performBoardIDRead:MC_BOARD_ID_INDEX]];
		}
		@catch(NSException* localException) {
			[self setBoardID:@"0000"];	
			[localException raise];
		}
		[xl2 deselectCards];
	}
	@catch(NSException* localException) {
		[xl2 deselectCards];
		[localException raise];
	}
}

- (void) scan:(SEL)aResumeSelectorInGuardian 
{
	workingSlot = 0;
	working = YES;
	[self performSelector:@selector(scanWorkingSlot)withObject:nil afterDelay:0];
	resumeSelectorInGuardian = aResumeSelectorInGuardian;
}

- (void) scanWorkingSlot
{
	BOOL xl2OK = YES;
	@try {
		[[self xl2] selectCards:(uint32_t)(1L<<[self slot])];
	}
	@catch(NSException* localException) {
		xl2OK = NO;
		NSLog(@"Unable to reach XL2 in crate: %d (Not inited?)\n",[self crateNumber]);
	}
	if(!xl2OK) working = NO;
	if(working) {
		@try {
			
			ORFecDaughterCardModel* proxyDC = [ObjectFactory makeObject:@"ORFecDaughterCardModel"];
			[proxyDC setGuardian:self];
			
			NSString* aBoardID = [proxyDC performBoardIDRead:workingSlot];
			if(![aBoardID isEqual: @"0000"]){
				NSLog(@"\tDC Slot: %d BoardID: %@\n",workingSlot,aBoardID);
				ORFecDaughterCardModel* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
				if(!theCard){
					[self addObject:proxyDC];
					[self place:proxyDC intoSlot:workingSlot];
					theCard = proxyDC;
				}
				[theCard setBoardID:aBoardID];
			}
			else {
				NSLog(@"\tDC Slot: %d BoardID: BAD\n",workingSlot);
				ORFecDaughterCardModel* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
				if(theCard)[self removeObject:theCard];
			}
		}
		@catch(NSException* localException) {
			NSLog(@"\tDC Slot: %d BoardID: ----\n",workingSlot);
			ORFecDaughterCardModel* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
			if(theCard)[self removeObject:theCard];
		}
	}
	
	workingSlot++;
	if(working && (workingSlot<kNumSNODaughterCards)){
		[self performSelector:@selector(scanWorkingSlot) withObject:nil afterDelay:0];
	}
	else {
		[[self xl2] deselectCards];
		if(resumeSelectorInGuardian){
			[[self guardian] performSelector:resumeSelectorInGuardian withObject:nil afterDelay:0];
			resumeSelectorInGuardian = nil;

		}
	}
}

- (NSString*) performBoardIDRead:(short) boardIndex
{
	if([[self xl2] adapterIsSBC])	return [self performBoardIDReadUsingSBC:boardIndex];
	else				return [self performBoardIDReadUsingLocalAdapter:boardIndex];
}


- (void) executeCommandList:(ORCommandList*)aList
{
	[[self xl2] executeCommandList:aList];		
}

- (uint32_t) fec32RegAddress:(uint32_t)aRegOffset
{
	return [[self guardian] registerBaseAddress] + aRegOffset;
}

- (id) writeToFec32RegisterCmd:(uint32_t) aRegister value:(uint32_t) aBitPattern
{
	uint32_t theAddress = [self fec32RegAddress:aRegister];
	return [[self xl2] writeHardwareRegisterCmd:theAddress value:aBitPattern];		
}

- (id) readFromFec32RegisterCmd:(uint32_t) aRegister
{
	uint32_t theAddress = [self fec32RegAddress:aRegister];
	return [[self xl2] readHardwareRegisterCmd:theAddress]; 		
}

- (id) delayCmd:(uint32_t) milliSeconds
{
	return [[self xl2] delayCmd:milliSeconds]; 		
}
								
- (void) writeToFec32Register:(uint32_t) aRegister value:(uint32_t) aBitPattern
{
	uint32_t theAddress = [self fec32RegAddress:aRegister];
	[[self xl2] writeHardwareRegister:theAddress value:aBitPattern];		
}

- (uint32_t) readFromFec32Register:(uint32_t) aRegister
{
	uint32_t theAddress = [self fec32RegAddress:aRegister];
	return [[self xl2] readHardwareRegister:theAddress]; 		
}
- (uint32_t) readFromFec32Register:(uint32_t) aRegister offset:(uint32_t)anO
{
	uint32_t theAddress = [self fec32RegAddress:aRegister];
	return [[self xl2] readHardwareRegister:theAddress]; 		
}
- (void) setFec32RegisterBits:(uint32_t) aRegister bitMask:(uint32_t) bits_to_set
{
	//set some bits in a register without destroying other bits
	uint32_t old_value = [self readFromFec32Register:aRegister];
	uint32_t new_value = (old_value & ~bits_to_set) | bits_to_set;
	[self writeToFec32Register:aRegister value:new_value]; 		
}

- (void) clearFec32RegisterBits:(uint32_t) aRegister bitMask:(uint32_t) bits_to_clear
{
	//Clear some bits in a register without destroying other bits
	uint32_t old_value = [self readFromFec32Register:aRegister];
	uint32_t new_value = (old_value & ~bits_to_clear);
	[self writeToFec32Register:aRegister value:new_value]; 		
}


- (void) boardIDOperation:(uint32_t)theDataValue boardSelectValue:(uint32_t) boardSelectVal beginIndex:(short) beginIndex
{
	uint32_t writeValue = 0UL;
	// load and clock in the instruction code

	
	ORCommandList* aList = [ORCommandList commandList];
	short index;
	for (index = beginIndex; index >= 0; index--){
		if ( theDataValue & (1U << index) ) writeValue = (boardSelectVal | BOARD_ID_DI);
		else								writeValue = boardSelectVal;
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:writeValue]];					// load data value
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)]];	// now clock in value
	}
	[self executeCommandList:aList];
}

- (void) autoInit
{
	@try {
		
		[self readBoardIds];	//Find out if the HW is there...
		if(![boardID isEqualToString:@"0000"]  && ![boardID isEqualToString:@"FFFF"]){
			[self setOnlineMask:0xFFFFFFFF];
		}
		
		//Do standard Board Init Things
		[self fullResetOfCard];
		[self loadAllDacs];
		//LoadCmosShiftRegisters(true); //always disable TR20 and TR100 on autoinit - as per JFW instructions 07/23/98 PH
		[self setPedestals];			// set up the hardware according to the ConfigDB	//MAH 3/22/98
		[self performPMTSetup:YES];		// now setup the PMT's wrt online/offline status - added 8/20/98 PMT
		
	}
	@catch(NSException* localException) {	
		// set the flags for the off-line status
		//theConfigDB -> SlotOnline(GetTheSnoCrateNumber(),itsFec32SlotNumber,FALSE);
		[self setOnlineMask:0x00000000];
		@throw;
	}
}

- (void) initTheCard:(BOOL) flgAutoInit
{
	@try {
		
		[self setOnlineMask:0xFFFFFFFF];
		//Do standard Board Init Things
		[self fullResetOfCard];
		[self loadAllDacs];
		//LoadCmosShiftRegisters(true); //always disable TR20 and TR100 on autoinit - as per JFW instructions 07/23/98 PH
		[self setPedestals];			// set up the hardware according to the ConfigDB	//MAH 3/22/98
		[self performPMTSetup:flgAutoInit?YES:NO];		// now setup the PMT's wrt online/offline status - added 8/20/98 PMT
		
	}
	@catch(NSException* localException) {	
		// set the flags for the off-line status
		//theConfigDB -> SlotOnline(GetTheSnoCrateNumber(),itsFec32SlotNumber,FALSE);
		[self setOnlineMask:0x00000000];
		@throw;
	}
}


- (void) fullResetOfCard
{	
	@try {
		[[self xl2] select:self];
		[self setFec32RegisterBits:FEC32_GENERAL_CS_REG bitMask:FEC32_CSR_FULL_RESET]; // STEP 1: Master Reset the FEC32
		[self loadCrateAddress];													// STEP 2: Perform load of crate address
		
		// additional effect is to disable all the triggers
		short i;
		for(i=0;i<32;i++) {
			//theConfigDB->Pmt20nsTriggerDisabled(itsSNOCrate->Get_SC_Number(),itsFec32SlotNumber,i,true);
			//theConfigDB->Pmt100nsTriggerDisabled(itsSNOCrate->Get_SC_Number(),itsFec32SlotNumber,i,true);
		}
		
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];
		NSLog(@"Failure during full reset of FEC32 (%d,%d).\n", [self crateNumber], [self stationNumber]);	
		@throw;
	}		
}

- (void) loadCrateAddress
{
	@try {	
		[[self xl2] select:self];
		uint32_t theOldCSRValue = [self readFromFec32Register:FEC32_GENERAL_CS_REG];
		// create new crate number in proper bit positions
		uint32_t crateNumber = (uint32_t) ( ( [self crateNumber] << FEC32_CSR_CRATE_BITSIFT ) & FEC32_CSR_CRATE_ADD );
		// clear old crate number, then mask in new.
		uint32_t theNewCSRValue = crateNumber | (theOldCSRValue & ~FEC32_CSR_CRATE_ADD);
		[self writeToFec32Register:FEC32_GENERAL_CS_REG value:theNewCSRValue];
		[[self xl2] deselectCards];
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];
		NSLog(@"Failure during load of crate address on FEC32 Crate %d Slot %d\n", [self crateNumber], [self stationNumber]);
		@throw;
	}
}

-(NSMutableDictionary*)pullFecForOrcaDB
{
    //This information is pulled for every Fec for DQXX
    //NSLog(@"hello...is is me you're are looking for?");
    NSMutableDictionary * output = [NSMutableDictionary dictionaryWithCapacity:200];
    
    NSMutableDictionary * pmtOnlineArray = [NSMutableDictionary dictionaryWithCapacity:20];
    
    //Look to see which PMTs are online
    int k;
    for(k=0;k<32;k++){
		NSNumber * pmtState = [NSNumber numberWithBool:[self pmtOnline:k]];
        [pmtOnlineArray setObject:pmtState forKey:[NSString stringWithFormat:@"%i",k]];
    }
    
    [output setObject:pmtOnlineArray forKey:@"pmt_online_array"];
    
    //motherBoard Id
    [output setObject:[self boardID] forKey:@"mother_board_id"];
    //NSString * motherboardId = [NSString stringWithFormat:[self boardID]];
    
    //Crate number
    NSNumber * crateNumberObj = [NSNumber numberWithInt:[self crateNumber]];
    [output setObject:crateNumberObj forKey:@"crate_number"];
    
    //Slot Number 
    NSNumber *slotNumber = [NSNumber numberWithInt:[self slot]];
    [output setObject:slotNumber forKey:@"slot"];
    
    //sequencer value for DQXX
    NSNumber * sequencerValue = [NSNumber numberWithFloat:[self seqDisabledMask]];
    [output setObject:sequencerValue forKey:@"sequencer_mask"];
    
    //These functions require NSObject values and cannot deal with anything else
    NSNumber * trigger20nsMaskValue = [NSNumber numberWithFloat:[self trigger20nsDisabledMask]];
    [output setObject:trigger20nsMaskValue forKey:@"trigger_20ns_mask"];
    
    NSNumber * trigger100nsMaskValue = [NSNumber numberWithFloat:[self trigger20nsDisabledMask]];
    [output setObject:trigger100nsMaskValue forKey:@"trigger_100ns_mask"];
    
    //TODO: PMTIC information
    //TODO: Cable information
    //TODO: Not Operational (Need to query Noel's PMT DB??)
    return output;
}

- (void) resetFifo
{
	BOOL selected = NO;
	@try {	
		[[self xl2] select:self];
		selected = YES;
		//Reset the fifo 
		uint32_t theSequencerDisableMask = 0;
		//set the specified offline channels to max threshold
		short chan;
		for(chan=0;chan<32;chan++){
			//set up a sequencer disable mask, all chan that are offline and have the sequencer disable bit set.
			if([self seqDisabled:chan]) {
				theSequencerDisableMask |= (1UL<<chan); 
			}
			
		}	
		
		ORCommandList* aList = [ORCommandList commandList];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_CMOS_CHIP_DISABLE_REG value:0xFFFFFFFFUL]];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_GENERAL_CS_REG value:FEC32_CSR_FIFO_RESET]];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_GENERAL_CS_REG value:FEC32_CSR_ZERO]];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_CMOS_CHIP_DISABLE_REG value:theSequencerDisableMask]];
		[self executeCommandList:aList];
		
		[self loadCrateAddress]; 
	}
	@catch(NSException* localException) {
		if(!selected){
			NSLog(@"Could not select the XL2 for FEC32 Crate %d!\n", [self crateNumber]);	
		}
		else {
			[[self xl2] deselectCards];
			NSLog(@"Failure during fifo reset of FEC32 (%d,%d)\n",[self crateNumber], [self stationNumber]);
		}
		@throw;
	}
}

// ResetFec32Cmos : Reset the CMOS chips on the mother card
- (void) resetCmos
{
	BOOL selected = NO;
	@try {	
		[[self xl2] select:self];
		selected = YES;
				
		//Reset the FEC32 cmos chips
		[self setFec32RegisterBits:FEC32_GENERAL_CS_REG bitMask:FEC32_CSR_CMOS_RESET];
		[self clearFec32RegisterBits:FEC32_GENERAL_CS_REG bitMask:FEC32_CSR_CMOS_RESET];
		
		// additional effect is to disable all the triggers
		[self setTrigger20nsDisabledMask:0xFFFFFFFF];
		[self setTrigger100nsDisabledMask:0xFFFFFFFF];
		
	}
	@catch(NSException* localException) {
		if(!selected){
			NSLog(@"Could not select the XL2 for FEC32 Crate %d!\n", [self crateNumber]);	
		}
		else {
			[[self xl2] deselectCards];
			NSLog(@"Failure during CMOS reset of FEC32 (%d,%d)\n",[self crateNumber], [self stationNumber]);
		}
		@throw;
	}
}

- (void) resetSequencer
{
	BOOL selected = NO;
	@try {	
		[[self xl2] select:self];
		selected = YES;
		
		//Reset the FEC32 cmos chips
		[self setFec32RegisterBits:FEC32_GENERAL_CS_REG bitMask:FEC32_CSR_SEQ_RESET];
		[self clearFec32RegisterBits:FEC32_GENERAL_CS_REG bitMask:FEC32_CSR_SEQ_RESET];
	}
	@catch(NSException* localException) {
		if(!selected){
			NSLog(@"Could not select the XL2 for FEC32 Crate %d!\n", [self crateNumber]);	
		}
		else {
			[[self xl2] deselectCards];
			NSLog(@"Failure during Sequencer reset of FEC32 (%d,%d)\n",[self crateNumber], [self stationNumber]);
		}
		@throw;
	}
}


- (void) loadAllDacs
{
	
	if([[self xl2] adapterIsSBC])	[self loadAllDacsUsingSBC];
	else				[self loadAllDacsUsingLocalAdapter];
}


- (void) setPedestals
{
	@try {
		[[self xl2] select:self];
		[self writeToFec32Register:FEC32_PEDESTAL_ENABLE_REG value:pedEnabledMask];
		[[self xl2] deselectCards];
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];
		NSLog(@"Failure during Pedestal set of FEC32(%d,%d)\n", [self crateNumber], [self stationNumber]);
		
	}	
	
}

-(void) performPMTSetup:(BOOL) aTriggersDisabled
{
	@try {
		
		[[self xl2] select:self];
		
		[self writeToFec32Register:FEC32_CMOS_CHIP_DISABLE_REG value:seqDisabledMask];
		
		//MAH 7/2/98
		uint32_t value = [self readFromFec32Register:FEC32_CMOS_LGISEL_SET_REG];
		if(qllEnabled)	value |= 0x00000001;
		else			value &= 0xfffffffe;	// JR 1999/06/04 Changed from 0xfffffff7
		[self writeToFec32Register:FEC32_CMOS_LGISEL_SET_REG value:value];
		
		//do the triggers
		[self loadCmosShiftRegisters:aTriggersDisabled];
		[[self xl2] deselectCards];
		
		
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];
		NSLog(@"Error during taking channel(s) off-line on  FEC32 (%d,%d)!\n", [self crateNumber], [self stationNumber]);
		@throw;
	}
}

- (float) readPmtCurrent:(short) aChannel
{
	float theAveCurrent = 0.0;	
	
	BOOL selected = NO;
	@try {	
		[[self xl2] select:self];
		selected = YES;
		
		ORCommandList* aList = [ORCommandList commandList];
		uint32_t word;
		//shift in the channel selection first 5 bits
		short aBit;
		for(aBit=4; aBit >=0 ; aBit--) {
		    if( (0x1UL << aBit) & aChannel ) word = HV_CSR_DATIN;
			else							 word = 0x0UL;
			[aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:word]];				// write data bit
			[aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:word | HV_CSR_CLK]];	// toggle clock
		}
		
		//shift 0's into the next 32 bits for a total of 37 bits
		for(aBit=31; aBit >= 0; aBit--) {
		    word = 0x0UL;
		   	[aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:word]];
		    [aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:word | HV_CSR_CLK]];   // toggle clock
		}
		
		// finally, toggle HVLOAD
		[aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:0]];
		[aList addCommand:[self writeToFec32RegisterCmd:FEC32_HVC_CS_REG value:HV_CSR_LOAD]];
		[self executeCommandList:aList];
		
		theAveCurrent = ((float)[self readVoltageValue:fecVoltageAdc[0].mask] - 128.0)*fecVoltageAdc[0].multiplier;
		[self setBaseCurrent:aChannel withValue:theAveCurrent];
	}
	@catch(NSException* localException) {
		if(!selected){
			NSLog(@"Could not select the XL2 for FEC32 Crate %d!\n", [self crateNumber]);	
		}
		else {
			[[self xl2] deselectCards];
			NSLog(@"Failure during Pmt Current read for FEC32 (%d,%d)\n",[self crateNumber], [self stationNumber]);
		}
		@throw;
	}
		
	return theAveCurrent;
}

- (int) stationNumber
{
	//we have a weird mapping because fec cards can only be in slots 1-16 and they are mapped to 0 - 15
	return [[self crate] maxNumberOfObjects] - [self slot] - 2;
}

#pragma mark •••OROrderedObjHolding Protocol
- (int) maxNumberOfObjects	{ return 4; }
- (int) objWidth			{ return 39; }
- (int) groupSeparation		{ return 37; }
- (NSString*) nameForSlot:(int)aSlot	{ return [NSString stringWithFormat:@"Slot %d",aSlot]; }
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj {return NO;}

- (NSRange) legalSlotsForObj:(id)anObj
{
	return NSMakeRange(0,[self maxNumberOfObjects]);
}

- (int)slotAtPoint:(NSPoint)aPoint 
{
	//what really screws us up is the space in the middle
	float y = aPoint.y;
	int objWidth = [self objWidth];
	float w = objWidth * [self maxNumberOfObjects] + [self groupSeparation];
	
	if(y>=0 && y<objWidth)						return 0;
	else if(y>objWidth && y<objWidth*2)			return 1;
	else if(y>=w-objWidth*2 && y<w-objWidth)	return 2;
	else if(y>=w-objWidth && y<w)				return 3;
	else										return -1;
}

- (NSPoint) pointForSlot:(int)aSlot 
{
	int objWidth = [self objWidth];
	float w = objWidth * [self maxNumberOfObjects] + [self groupSeparation];
	if(aSlot == 0)		return NSMakePoint(0,0);
	else if(aSlot == 1)	return NSMakePoint(0,objWidth+1);
	else if(aSlot == 2) return NSMakePoint(0,w-2*objWidth+1);
	else return NSMakePoint(0,w-objWidth+1);
}


- (void) place:(id)aCard intoSlot:(int)aSlot
{
	[aCard setSlot: aSlot];
	[aCard moveTo:[self pointForSlot:aSlot]];
}

- (int) slotForObj:(id)anObj
{
	return [anObj slot];
}

- (int) numberSlotsNeededFor:(id)anObj
{
	return [anObj numberSlotsUsed];
}

//--Read_CMOS_Counts
//PH 03/09/98. Read the CMOS totals counter and calculate rates if calcRates is true
// otherwise sets rates to zero.  a negative rate indicates a CMOS or VME read error.
// returns true if rates were calculated
- (BOOL) readCMOSCounts:(BOOL)calcRates channelMask:(uint32_t) aChannelMask
{
    
    if (calcRates) {
        [self readCMOSRatesUsingXL3:aChannelMask];
    } else {
        [self readCMOSCountsUsingXL3:aChannelMask];            
    }
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORFec32ModelCmosRateChanged" object:self userInfo:nil];
	
	return calcRates;
}

//XL3 reads the counts for half the crate and pushes them here
//returns YES if the cmos rates were updated
- (BOOL) processCMOSCounts:(uint32_t*)rates calcRates:(BOOL)aCalcRates withChannelMask:(uint32_t) aChannelMask
{
    
    int32_t		   	theRate = kCMOSRateUnmeasured;
	uint32_t  	theCount;
	
	NSDate* thisTime = [[NSDate alloc] init];
	NSTimeInterval timeDiff = [thisTime timeIntervalSinceDate:cmosCountTimeStamp];
    
	float sampleFreq = 0.;
    BOOL calcRates = aCalcRates;
    
	if ((calcRates && (timeDiff<0 || timeDiff>kMaxTimeDiff)) || timeDiff==0) {
		calcRates = 0;	// don't calculate rates if time diff is silly
	}
	if(timeDiff){
        sampleFreq = 1 / timeDiff;
    }
	
	[cmosCountTimeStamp release];
	cmosCountTimeStamp = [thisTime copy];
    [thisTime release];
    thisTime = nil;
	
	//uint32_t theOnlineMask = [self onlineMask];
    //add disabled channels
    unsigned char ch;
    for (ch=0; ch<32; ch++) {
        if (aChannelMask & 1UL << ch) {
            theCount = rates[ch];
			if (calcRates) { //only good CMOS count reads get here
					theRate = (theCount - cmosCount[ch]) * sampleFreq;
					if (theRate > 1e9) theRate = kCMOSRateCorruptRead;			//MAH 3/19/98
			}
            else {
                theRate = kCMOSRateUnmeasured;
            }
            cmosCount[ch] = theCount;
            cmosRate[ch] = theRate;
        }
        else {
            cmosCount[ch] = 0;
            cmosRate[ch] = kCMOSRateUnmeasured;
        }
    }
    //[self postNotificationName:ORFec32ModelCmosRateChanged];
    return calcRates;
}

- (uint32_t) channelsWithCMOSRateHigherThan:(uint32_t)cmosRateLimit
{
    //todo: add a goodforcmosrate mask on top
    unsigned char ch;
    uint32_t count = 0;
    for (ch=0; ch<32; ch++) {
        if (cmosRate[ch] > cmosRateLimit) count++;
    }
    return count;
}

- (uint32_t) channelsWithErrorCMOSRate
{
    unsigned char ch;
    uint32_t count = 0;
    for (ch=0; ch<32; ch++) {
        if (cmosRate[ch] < 0) count++;
    }
    return count;    
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(hwWizardActionBegin:)
                         name : ORHWWizGroupActionStarted
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(hwWizardActionEnd:)
                         name : ORHWWizGroupActionFinished
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(hwWizardActionFinal:)
                         name : ORHWWizActionFinalNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(detectorStateChanged:)
                         name : ORPQDetectorStateChanged
                       object : nil];
}

// sync FEC/DC settings from the specified hardware state
// (the note object should be a NSMutableData object containing
//  a full array of PQ_FEC structures in crate/card order)
- (void) detectorStateChanged:(NSNotification*)aNote
{
    uint32_t valid;
    ORPQDetectorDB *detDB = [aNote object];

    if (!detDB) return;

    PQ_FEC *fec = (PQ_FEC *)[detDB getFEC:(int)[self stationNumber] crate:[self crateNumber] ];

    if (!fec || !fec->valid[kFEC_exists]) return;  // nothing to do if fec doesn't exist in the current detector state

    @try {
        // PH - The disableNotifications hack stops ORCA from throwing around notifications like feces
        // in a chimpanzee exhibit (ref https://davidnix.io/post/stop-using-nsnotificationcenter/ ).
        // Without this, each GUI element in the daughtercard window would be set more than 1000 times!
        // Instead we send "EverythingChanged" notifications after all of the settings have been updated,
        // and use a bit of sense before acting on these messages in the controller objects.
        [ORSNOCard disableNotifications];

        [[self undoManager] disableUndoRegistration];

        if ((valid = fec->valid[kFEC_seqDisabled]) != 0) {
            [self setSeqDisabledMask: (fec->seqDisabled & valid) | ((uint32_t)seqDisabledMask & ~valid)];
            startSeqDisabledMask = seqDisabledMask;
        }
        if ((valid = fec->valid[kFEC_pedEnabled]) != 0) {
            [self setPedEnabledMask: (fec->pedEnabled & valid) | ((uint32_t)pedEnabledMask & ~valid)];
            startPedEnabledMask = pedEnabledMask;
        }
        if ((valid = fec->valid[kFEC_nhit100enabled]) != 0) {
            [self setTrigger100nsDisabledMask: (~fec->nhit100enabled & valid) | ((uint32_t)trigger100nsDisabledMask & ~valid)];
            startTrigger100nsDisabledMask = trigger100nsDisabledMask;
        }
        if ((valid = fec->valid[kFEC_nhit20enabled]) != 0) {
            [self setTrigger20nsDisabledMask: (~fec->nhit20enabled & valid) | ((uint32_t)trigger20nsDisabledMask & ~valid)];
            startTrigger20nsDisabledMask = trigger20nsDisabledMask;
        }
        for (int ch=0; ch<32; ++ch) {
            uint32_t chMask = (1 << ch);
            if (fec->valid[kFEC_vthr] & chMask) {
                [self setVth:ch withValue:fec->vthr[ch]];
            }
            short dcNum = ch / 8;
            if (dcPresent[dcNum]) {
                ORFecDaughterCardModel *theDc = dc[dcNum];
                short dcChan = ch - dcNum * 8;
                if (fec->valid[kFEC_nhit100delay] & chMask) {
                    // (there is some inconsistency between ORFecDaughterCardModel and ORXL3Model
                    // as to whether this is a width or delay, but they are both the same setting)
                    [theDc setNs100width:dcChan withValue:fec->nhit100delay[ch]];
                }
                if (fec->valid[kFEC_nhit20width] & chMask) {
                    [theDc setNs20width:dcChan withValue:fec->nhit20width[ch]];
                }
                if (fec->valid[kFEC_nhit20delay] & chMask) {
                    [theDc setNs20delay:dcChan withValue:fec->nhit20delay[ch]];
                }
                if (fec->valid[kFEC_vbal0] & chMask) {
                    [theDc setVb:dcChan withValue:fec->vbal0[ch]];
                }
                if (fec->valid[kFEC_vbal1] & chMask) {
                    [theDc setVb:(dcChan+8) withValue:fec->vbal1[ch]];
                }
                if (fec->valid[kFEC_tac0trim] & chMask) {
                    [theDc setTac0trim:dcChan withValue:fec->tac0trim[ch]];
                }
                if (fec->valid[kFEC_tac1trim] & chMask) {
                    [theDc setTac1trim:dcChan withValue:fec->tac1trim[ch]];
                }
            }
        }
        for (int i=0; i<8; ++i) {
            uint32_t msk = (1 << i);
            short dcNum = i / 2;
            if (dcPresent[dcNum]) {
                short j = i - dcNum * 2;
                ORFecDaughterCardModel *theDc = dc[dcNum];
                if (fec->valid[kFEC_tdiscRp1] & msk) {
                    [theDc setRp1:j withValue:fec->tdiscRp1[i]];
                }
                if (fec->valid[kFEC_tdiscRp2] & msk) {
                    [theDc setRp2:j withValue:fec->tdiscRp2[i]];
                }
                if (fec->valid[kFEC_tdiscVsi] & msk) {
                    [theDc setVsi:j withValue:fec->tdiscVsi[i]];
                }
                if (fec->valid[kFEC_tdiscVli] & msk) {
                    [theDc setVli:j withValue:fec->tdiscVli[i]];
                }
            }
        }
        if (fec->valid[kFEC_tcmosVmax]) {
            [self setCmos:kVMax withValue:fec->tcmosVmax];
        }
        if (fec->valid[kFEC_tcmosTacref]) {
            [self setCmos:kTACRef withValue:fec->tcmosTacref];
        }
        if (fec->valid[kFEC_tcmosIseta] & 0x01) {
            [self setCmos:kISetA0 withValue:fec->tcmosIseta[0]];
        }
        if (fec->valid[kFEC_tcmosIseta] & 0x02) {
            [self setCmos:kISetA1 withValue:fec->tcmosIseta[1]];
        }
        if (fec->valid[kFEC_tcmosIsetm] & 0x01) {
            [self setCmos:kISetM0 withValue:fec->tcmosIsetm[0]];
        }
        if (fec->valid[kFEC_tcmosIsetm] & 0x02) {
            [self setCmos:kISetM1 withValue:fec->tcmosIsetm[1]];
        }
        if (fec->valid[kFEC_vres]) {
            [self setVRes:fec->vres];
        }
        if (fec->valid[kFEC_hvref]) {
            [self setHVRef:fec->hvref];
        }
        if (fec->valid[kFEC_mbid]) {
            [self setBoardID:[NSString stringWithFormat:@"%x", fec->mbid]];
        }
        for (int i=0; i<kNumDbPerFec; ++i) {
            if ((fec->valid[kFEC_dbid] & (1 << i)) && dcPresent[i]) {
                [dc[i] setBoardID:[NSString stringWithFormat:@"%x", fec->dbid[i]]];
            }
        }
        //TODO: set PMTIC ID's
    }
    @finally {
        [ORSNOCard enableNotifications];
        [self postNotificationName:ORFec32ModelEverythingChanged];
        for (int i=0; i<4; ++i) {
            if (dcPresent[i]) {
                [dc[i] postNotificationName:ORDCModelEverythingChanged];
            }
        }
        [[self undoManager] enableUndoRegistration];
    }
}

- (void) _continueHWWizard:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if (returnCode == NSAlertFirstButtonReturn) {
        sDetectorDbState = 0;
        NSLog(@"Hardware Wizard action cancelled.\n");
    } else {
        sDetectorDbState = 3;
        if (sDetectorDbData) {
            NSLog(@"Running Hardware Wizard with stale database!\n");
        } else {
            NSLog(@"Running Hardware Wizard with no detector database!\n");
        }
        [self _continueHWWizard];
    }
}

- (void) _continueHWWizard
{
    // all done loading database, so we can continue with our hwWizard execution now
    if (hwWizard && [hwWizard respondsToSelector:@selector(continueExecuteControlStruct)]) {
        [hwWizard performSelector:@selector(continueExecuteControlStruct)];
    } else {
        NSLog(@"Error calling continueExecuteControlStruct\n");
    }
}

// continue HWWizard execution after reading detector database
- (void) _detDbCallback:(ORPQDetectorDB*)data
{
    sDetectorDbState = 2;
    
    if (sReadingHvdbAlert) {
        NSWindow *hwWindow = [hwWizard performSelector:@selector(window)];
        [hwWindow endSheet:[hwWindow attachedSheet] returnCode:NSAlertSecondButtonReturn];
        //[NSApp endSheet:[sReadingHvdbAlert window]];
        sReadingHvdbAlert = nil;
    }
    
    NSString *s = nil;  // short message for dialog box
    NSString *m = nil;  // message details
    NSString *w = nil;  // warning for status log
    
    if (data) {
        [sDetectorDbData release];
        sDetectorDbData = [data retain];
        [self _continueHWWizard];
    } else if (sDetectorDbData) {
        NSLog(@"Error reloading detector database\n");
        s = [NSString stringWithFormat:@"Error reloading detector database!\n\nContinue with stale data?"];
        m = [NSString stringWithFormat:@"This should be OK as int32_t as the detector has not changed"];
        w = [NSString stringWithFormat:@"Running Hardware Wizard with stale database!\n"];
    } else {
        s = [NSString stringWithFormat:@"Error loading detector database!\n\nContinue anyway?"];
        m = [NSString stringWithFormat:@"This runs the risk of enabling channels which have HV disabled!"];
        w = [NSString stringWithFormat:@"Running Hardware Wizard with no detector database!\n"];
    }
    if (s) {
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:s];
        [alert setInformativeText:m];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"OK, Continue"];
        [alert setAlertStyle:NSAlertStyleWarning];
        [alert beginSheetModalForWindow:[hwWizard performSelector:@selector(window)] completionHandler:^(NSModalResponse result){
            if (result == NSAlertSecondButtonReturn) {
                sDetectorDbState = 3;
                NSLog(w);
                [self performSelector:@selector(_continueHWWizard) withObject:nil afterDelay:.1];
            } else {
                sDetectorDbState = 0;
                NSLog(@"Hardware Wizard action cancelled.\n");
            }
        }];
#else
        NSBeginAlertSheet(s,
                          @"Cancel",
                          @"OK, Continue",
                          nil,[hwWizard window],
                          self,
                          @selector(_continueHWWizard:returnCode:contextInfo:),
                          nil,
                          nil,m);
#endif
    }
}

- (void) hwWizardWaitingForDatabase
{
    if (sDetectorDbState == 1) {
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
        NSString* s = [NSString stringWithFormat:@"Reading PMT database..."];
        sReadingHvdbAlert = [[[NSAlert alloc] init] autorelease];
        [sReadingHvdbAlert setMessageText:s];
        [sReadingHvdbAlert addButtonWithTitle:@"Cancel"];
        [sReadingHvdbAlert setAlertStyle:NSAlertStyleInformational];
        [sReadingHvdbAlert beginSheetModalForWindow:[hwWizard performSelector:@selector(window)] completionHandler:^(NSModalResponse result){
            if (result == NSAlertFirstButtonReturn) {
                // cancel any queued database operations
                [[ORPQModel getCurrent] cancelDbQueries];
                sReadingHvdbAlert = nil;
            }
        }];
#endif
    }
}

- (void) hwWizardActionBegin:(NSNotification*)aNote
{
    [[self undoManager] disableUndoRegistration];

    sChannelsNotChangedCount      = 0;
    startSeqDisabledMask          = seqDisabledMask;
    startPedEnabledMask           = pedEnabledMask;
    startTrigger20nsDisabledMask  = trigger20nsDisabledMask;
    startTrigger100nsDisabledMask = trigger100nsDisabledMask;
    startOnlineMask               = onlineMask;
    cardChangedFlag = false;
    crateInitMask = 0;
    cratePedMask  = 0;

    // interrupt hardwardWizard execution to allow time to load pmtdb if necessary
    if (sDetectorDbState == 0 && [aNote object] && [[aNote object] respondsToSelector:@selector(notOkToContinue)]) {
        sDetectorDbState = 1;
        hwWizard = [aNote object];
        // (we will continue after our detector database is loaded)
        [hwWizard performSelector:@selector(notOkToContinue)];
        // initiate the PostgreSQL DB query to get the current detector state
        [[ORPQModel getCurrent] detectorDbQuery:self selector:@selector(_detDbCallback:)];
        // post a modal dialog after 1 sec if the database operation hasn't completed yet
        [self performSelector:@selector(hwWizardWaitingForDatabase) withObject:nil afterDelay:1];
    }
}

- (void) hwWizardActionEnd:(NSNotification*)aNote
{
    // make sure channels with HV disabled aren't enabled
    // (note: we do this even if the database is stale)
    PQ_FEC *fec = [sDetectorDbData getPmthv:(int)[self stationNumber] crate:[self crateNumber]];
    if (fec) {
        uint32_t notChanged = 0;
        // sequencer must be disabled on channels with HV disabled
        uint32_t wanted = seqDisabledMask;
        seqDisabledMask |= (seqDisabledMask ^ startSeqDisabledMask) & fec->hvDisabled;
        notChanged |= (wanted ^ seqDisabledMask);
        // pedestals must be disabled on channels with HV disabled
        wanted = pedEnabledMask;
        pedEnabledMask &= ~((pedEnabledMask ^ startPedEnabledMask) & fec->hvDisabled);
        notChanged |= (wanted ^ pedEnabledMask);
        // triggers must be disabled on channels with HV disabled or if the
        // relay is open
        wanted = trigger20nsDisabledMask;
        trigger20nsDisabledMask |= (trigger20nsDisabledMask ^ startTrigger20nsDisabledMask) & (fec->hvDisabled | ~[self relayChannelMask]);
        notChanged |= (wanted ^ trigger20nsDisabledMask);
        wanted = trigger100nsDisabledMask;
        trigger100nsDisabledMask |= (trigger100nsDisabledMask ^ startTrigger100nsDisabledMask) & (fec->hvDisabled | ~[self relayChannelMask]);
        notChanged |= (wanted ^ trigger100nsDisabledMask);
        // can't be online if HV is disabled
        wanted = onlineMask;
        onlineMask &= ~((onlineMask ^ startOnlineMask) & fec->hvDisabled);
        notChanged |= (wanted ^ onlineMask);
        // keep count of the number of channels we didn't change due to HV disabled
        if (notChanged) {
            for (uint32_t mask=1; mask; mask<<=1) {
                if (mask & notChanged) ++sChannelsNotChangedCount;
            }
        }
    }
    // go ahead and "officially" change the masks, sending the appropriate notifications
    if (seqDisabledMask != startSeqDisabledMask) {
        uint32_t mask = seqDisabledMask;
        seqDisabledMask = startSeqDisabledMask;
        [self setSeqDisabledMask: mask];
        cardChangedFlag = true;
    }
    if (pedEnabledMask != startPedEnabledMask) {
        uint32_t mask = pedEnabledMask;
        pedEnabledMask = startPedEnabledMask;
        [self setPedEnabledMask: mask];
        // pedestals are set differently, not by a crate init, so handle these separately
        cratePedMask |= (1UL << [self crateNumber]);
    }
    if (trigger20nsDisabledMask != startTrigger20nsDisabledMask) {
        uint32_t mask = trigger20nsDisabledMask;
        trigger20nsDisabledMask = startTrigger20nsDisabledMask;
        [self setTrigger20nsDisabledMask: mask];
        cardChangedFlag = true;
    }
    if (trigger100nsDisabledMask != startTrigger100nsDisabledMask) {
        uint32_t mask = trigger100nsDisabledMask;
        trigger100nsDisabledMask = startTrigger100nsDisabledMask;
        [self setTrigger100nsDisabledMask: mask];
        cardChangedFlag = true;
    }
    if (onlineMask != startOnlineMask) {
        uint32_t mask = onlineMask;
        onlineMask = startOnlineMask;
        [self setOnlineMaskNoInit: mask];
        cardChangedFlag = true;
    }
    if (cardChangedFlag) {
        // set bit in crateInitMask to init this crate as the final step
        crateInitMask |= (1UL << [self crateNumber]);
        cardChangedFlag = false;  // clear this temporary flag
    }
    // set pmthv state to reload the database on the next hwWizard action
    sDetectorDbState = 0;
}

- (void) hwWizardActionFinal:(NSNotification*)aNote
{
    // now that we have updated all settings, finally go ahead and
    // set pedestals and/or initialize this crate if we haven't done so already
    if (cratePedMask & (1UL << [self crateNumber])) {
        [[[self guardian] adapter] setPedestalInParallel];
        // make sure we don't do this crate again
        cratePedMask &= ~(1UL << [self crateNumber]);
    }
    if (crateInitMask & (1UL << [self crateNumber])) {
        // initialize the crate registers from our current settings
        [[[self guardian] adapter] loadHardware];
        // make sure we don't do this crate again
        crateInitMask &= ~(1UL << [self crateNumber]);
    }
    if (sChannelsNotChangedCount) {
        NSLog(@"Warning: Settings for %d channels not made because they have HV disabled\n", sChannelsNotChangedCount);
        sChannelsNotChangedCount = 0;
    }

    [[self undoManager] enableUndoRegistration];
}

#pragma mark •••HWWizard
- (int) numberOfChannels
{
    return 32;
}
- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:255 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setVth:withValue:) getMethod:@selector(getVth:)];
    //[p setInitMethodSelector:@selector(writeThresholds)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold above Zero"];
    [p setFormat:@"##0" upperLimit:255 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setVThAboveZero:withValue:) getMethod:@selector(getVThAboveZero:)];
    //[p setInitMethodSelector:@selector(writeThresholds)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold to Max"];
    [p setUseValue:NO];
    [p setSetMethodSelector:@selector(setVthToMax:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold to ECAL"];
    [p setUseValue:NO];
    [p setSetMethodSelector:@selector(setVthToEcal:)];
    [a addObject:p];

    p = [ORHWWizParam boolParamWithName:@"FEC Online" setter:@selector(setOnline:enabled:) getter:@selector(getOnline:)];
    [a addObject:p];
    
    p = [ORHWWizParam boolParamWithName:@"Sequencer Enable" setter:@selector(setSeq:enabled:) getter:@selector(seqEnabled:)];
    [a addObject:p];
    
    p = [ORHWWizParam boolParamWithName:@"Pedestal Enable" setter:@selector(setPed:enabled:) getter:@selector(pedEnabled:)];
    [a addObject:p];

    p = [ORHWWizParam boolParamWithName:@"100ns Enable" setter:@selector(setTrigger100ns:enabled:) getter:@selector(trigger100nsEnabled:)];
    [a addObject:p];

    p = [ORHWWizParam boolParamWithName:@"20ns Enable" setter:@selector(setTrigger20ns:enabled:) getter:@selector(trigger20nsEnabled:)];
    [a addObject:p];

    p = [ORHWWizParam boolParamWithName:@"20ns+100ns Enable" setter:@selector(setTrigger20ns100ns:enabled:) getter:@selector(trigger20ns100nsEnabled:)];
    [a addObject:p];

    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORSNOCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:NSStringFromClass([self class])]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:NSStringFromClass([self class])]];
    return a;
}

@end

@implementation ORFec32Model (private)

- (void) loadCmosShiftRegisters:(BOOL) aTriggersDisabled
{
#ifdef VERIFY_CMOS_SHIFT_REGISTER
	int retry_cmos_load = 0;
#endif			
	
	@try {
		//	NSLog(@"Loading all CMOS Shift Registers for FEC32 (%d,%d)\n",[self crateNumber],[self stationNumber]);
		[[self xl2] select:self];
		
		short channel_index;
		uint32_t registerAddress=0;
		unsigned short whichChannels=0;
		for( channel_index = 0; channel_index < 2; channel_index++){
			
			switch (channel_index){
				case BOTTOM_CHANNELS:
					whichChannels = BOTTOM_CHANNELS;
					registerAddress = FEC32_CMOS_1_16_REG;
					break;
				case UPPER_CHANNELS:				
					whichChannels = UPPER_CHANNELS;
					registerAddress = FEC32_CMOS_17_32_REG;
					break;	
			}
			
			// load data into structure from database
			[self loadCmosShiftRegData:whichChannels triggersDisabled:aTriggersDisabled];
			
			// serially shift in 35 bits of data, the top 10 bits are shifted in as zero
			//STEP 1: first shift in the top 10 bits: the bottom 0-15 channels first
			//todo: split into two implementations
			if([[self xl2] adapterIsSBC]) {
				ORCommandList* aList = [ORCommandList commandList];
				short i;
				for (i = 0; i < 10; i++){
					[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:FEC32_CMOS_SHIFT_SERSTROB]];
					[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:FEC32_CMOS_SHIFT_SERSTROB | FEC32_CMOS_SHIFT_CLOCK]];
				}
				
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:TAC_TRIM1 bitMaskStart:TACTRIM_BITS]];		// STEP 2: tacTrim1
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:TAC_TRIM0 bitMaskStart:TACTRIM_BITS]];		// STEP 3: tacTrim0
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:NS20_MASK bitMaskStart:NS20_MASK_BITS]];		// STEP 4: ns20Mask
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:NS20_WIDTH bitMaskStart:NS20_WIDTH_BITS]];	// STEP 5: ns20Width
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:NS20_DELAY bitMaskStart:NS20_DELAY_BITS]];	// STEP 6: ns20Delay
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:NS100_MASK bitMaskStart:NS_MASK_BITS]];		// STEP 7: ns100Mask
				[aList addCommands:[self cmosShiftLoadAndClock:registerAddress cmosRegItem:NS100_DELAY bitMaskStart:NS100_DELAY_BITS]];	// STEP 8: ns100Delay
				[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:0x3FFFF]];										// FINAL STEP: SERSTOR
				[self executeCommandList:aList]; //send out the list (blocks until reply or timeout)
			}
			else {
				short i;
				for (i = 0; i < 10; i++){
					[self writeToFec32Register:registerAddress value:FEC32_CMOS_SHIFT_SERSTROB];
					[self writeToFec32Register:registerAddress value:FEC32_CMOS_SHIFT_SERSTROB | FEC32_CMOS_SHIFT_CLOCK];
				}
				
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:TAC_TRIM1 bitMaskStart:TACTRIM_BITS];		// STEP 2: tacTrim1
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:TAC_TRIM0 bitMaskStart:TACTRIM_BITS];		// STEP 3: tacTrim0
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:NS20_MASK bitMaskStart:NS20_MASK_BITS];		// STEP 4: ns20Mask
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:NS20_WIDTH bitMaskStart:NS20_WIDTH_BITS];	// STEP 5: ns20Width
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:NS20_DELAY bitMaskStart:NS20_DELAY_BITS];	// STEP 6: ns20Delay
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:NS100_MASK bitMaskStart:NS_MASK_BITS];		// STEP 7: ns100Mask
				[self cmosShiftLoadAndClockBit3:registerAddress cmosRegItem:NS100_DELAY bitMaskStart:NS100_DELAY_BITS];	// STEP 8: ns100Delay
				[self writeToFec32RegisterCmd:registerAddress value:0x3FFFF];										// FINAL STEP: SERSTOR
			}
			
				
#ifdef VERIFY_CMOS_SHIFT_REGISTER
			//-----VERIFY that we have set the shift register properly for the 16 channels just loaded - PH 09/17/99
			const short	kMaxCmosLoadAttempts = 2;	// maximum number of times to attempt loading the CMOS shift register before throwing an exception
			const short kMaxCmosReadAttempts = 3;	// maximum number of times to check the busy bit on the CMOS read before using the value
			
			int theChannel;
			for (theChannel=0; theChannel<16; ++theChannel) {		// verify each of the 16 channels that we just loaded
				uint32_t actualShiftReg;
				short retry_read;
				for (retry_read=0; retry_read<kMaxCmosReadAttempts; ++retry_read) {
					actualShiftReg = [self readFromFec32Register:FEC32_CMOS_SHIFT_REG_OFFSET + 32*(theChannel+16*channel_index)];	// read back the CMOS shift register
					if( !(actualShiftReg & 0x80000000) ) break;		//done if busy bit not set. Otherwise: busy, so try to read again
				}
				uint32_t expectedShiftReg = ((cmosShiftRegisterValue[theChannel].cmos_shift_item[TAC_TRIM1]   & 0x0fUL) << 20) |
				((cmosShiftRegisterValue[theChannel].cmos_shift_item[TAC_TRIM0]   & 0x0fUL) << 16) |
				((cmosShiftRegisterValue[theChannel].cmos_shift_item[NS100_DELAY] & 0x3fUL) << 10) |
				((cmosShiftRegisterValue[theChannel].cmos_shift_item[NS20_MASK]   & 0x01UL) <<  9) |
				((cmosShiftRegisterValue[theChannel].cmos_shift_item[NS20_WIDTH]  & 0x1fUL) <<  4) |
				((cmosShiftRegisterValue[theChannel].cmos_shift_item[NS20_DELAY]  & 0x0fUL));
				
				// check the shift register value, ignoring upper 8 bits (write address and read error flag)
				if ((actualShiftReg & 0x00ffffffUL) == expectedShiftReg) {
					if (retry_cmos_load) {	// success!
						// print a message if we needed to retry the load
						NSLog(@"Verified CMOS Shift Registers for Fec32 (%d,%d,%d) after %d attempts\n", [self crateNumber], [self stationNumber], theChannel + 16 * channel_index, retry_cmos_load+1);
						retry_cmos_load = 0;	// reset retry counter
					}		
				} 
				else if (++retry_cmos_load < kMaxCmosLoadAttempts) theChannel--;	//verification error but we still want to keep trying -- read the same channel again
				else {
					// verification error after maximum number of retries
					NSLog(@"Error verifying CMOS Shift Register for Crate %d, Card %d, Channel %d:\n",
						  [self crateNumber], [self stationNumber], theChannel + 16 * channel_index);
					uint32_t badBits = (actualShiftReg ^ expectedShiftReg);
					if (actualShiftReg == 0UL) {
						NSLog(@"  - all shift register bits read back as zero\n");
					} 
					else {
						if ((badBits >> 20) & 0x0fUL)	NSLog(@"Loaded TAC1 trim   0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 20) & 0x0fUL,(actualShiftReg >> 20) & 0x0fUL);
						if ((badBits >> 16) & 0x0fUL)	NSLog(@"Loaded TAC0 trim   0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 16) & 0x0fUL,(actualShiftReg >> 16) & 0x0fUL);
						if ((badBits >> 10) & 0x3fUL)	NSLog(@"Loaded 100ns width 0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 10) & 0x3fUL,(actualShiftReg >> 10) & 0x3fUL);
						if ((badBits >> 9) & 0x01UL)	NSLog(@"Loaded 20ns enable 0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 9)  & 0x01UL,(actualShiftReg >> 9) & 0x01UL);
						if ((badBits >> 4) & 0x1fUL)	NSLog(@"Loaded 20ns width  0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 4)  & 0x1fUL,(actualShiftReg  >> 4) & 0x1fUL);
						if ((badBits >> 0) & 0x0fUL)	NSLog(@"Loaded 20ns delay  0x%.2lx (read back 0x%.2lx)\n",(expectedShiftReg >> 0)  & 0x0fUL,(actualShiftReg >> 0)  & 0x0fUL);
					}
					retry_cmos_load = 0;	// reset retry counter
				}
			}
#endif // VERIFY_CMOS_SHIFT_REGISTER
		}
		
		[[self xl2] deselectCards];
		
		//NSLog(@"CMOS Shift Registers for FEC32(%d,%d) have been loaded\n",[selfcrateNumber],[self stationNumber]);
		
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];
		NSLog(@"Could not load the CMOS Shift Registers for FEC32 (%d,%d)!\n", [self crateNumber], [self stationNumber]);	 		
		
	}
}


- (ORCommandList*) cmosShiftLoadAndClock:(unsigned short) registerAddress cmosRegItem:(unsigned short) cmosRegItem bitMaskStart:(short) bit_mask_start
{
	
	short bit_mask;
	ORCommandList* aList = [ORCommandList commandList];
	
	// bit_mask_start : the number of bits to peel off from cmosRegItem
	for(bit_mask = bit_mask_start; bit_mask >= 0; bit_mask--){
		
		uint32_t writeValue = 0UL;
		short channel_index;
		for(channel_index = 0; channel_index < 16; channel_index++){
			if ( cmosShiftRegisterValue[channel_index].cmos_shift_item[cmosRegItem] & (1UL << bit_mask) ) {
				writeValue |= (1UL << channel_index + 2);
			}
		}
		
		// place data on line
		[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:writeValue | FEC32_CMOS_SHIFT_SERSTROB]];
		// now clock in data without SERSTROB for bit_mask = 0 and cmosRegItem = NS100_DELAY
		if( (cmosRegItem == NS100_DELAY) && (bit_mask == 0) ){
			[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:writeValue | FEC32_CMOS_SHIFT_CLOCK]];
		}
		// now clock in data
		[aList addCommand: [self writeToFec32RegisterCmd:registerAddress value:writeValue | FEC32_CMOS_SHIFT_SERSTROB | FEC32_CMOS_SHIFT_CLOCK]];
	}
	return aList;
}


- (void) cmosShiftLoadAndClockBit3:(unsigned short) registerAddress cmosRegItem:(unsigned short) cmosRegItem bitMaskStart:(short) bit_mask_start
{
	
	short bit_mask;
	
	// bit_mask_start : the number of bits to peel off from cmosRegItem
	for(bit_mask = bit_mask_start; bit_mask >= 0; bit_mask--){
		
		uint32_t writeValue = 0UL;
		short channel_index;
		for(channel_index = 0; channel_index < 16; channel_index++){
			if ( cmosShiftRegisterValue[channel_index].cmos_shift_item[cmosRegItem] & (1UL << bit_mask) ) {
				writeValue |= (1UL << channel_index + 2);
			}
		}
		
		// place data on line
		[self writeToFec32Register:registerAddress value:writeValue | FEC32_CMOS_SHIFT_SERSTROB];
		// now clock in data without SERSTROB for bit_mask = 0 and cmosRegItem = NS100_DELAY
		if( (cmosRegItem == NS100_DELAY) && (bit_mask == 0) ){
			[self writeToFec32Register:registerAddress value:writeValue | FEC32_CMOS_SHIFT_CLOCK];
		}
		// now clock in data
		[self writeToFec32Register:registerAddress value:writeValue | FEC32_CMOS_SHIFT_SERSTROB | FEC32_CMOS_SHIFT_CLOCK];
	}
}


-(void) loadCmosShiftRegData:(unsigned short)whichChannels triggersDisabled:(BOOL)aTriggersDisabled
{
	unsigned short dc_offset=0;
	
	switch (whichChannels){
		case BOTTOM_CHANNELS:	dc_offset = 0;	break;
		case UPPER_CHANNELS:	dc_offset = 2;	break;
	}
	
	// initialize cmosShiftRegisterValue structure	
	unsigned short i;
	for (i = 0; i < 16 ; i++){
		unsigned short j;
		for (j = 0; j < 7 ; j++){
			cmosShiftRegisterValue[i].cmos_shift_item[j] = 0;
		}
	}
	
	// load the data from the database into theCmosShiftRegUnion
	//temp.....CHVStatus theHVStatus;
	unsigned short dc_index;
	for ( dc_index= 0; dc_index < 2 ; dc_index++){
		
		unsigned short offset_index = dc_index*8;
		
		unsigned short regIndex;
		for (regIndex = 0; regIndex < 8 ; regIndex++){
			unsigned short channel = 8*(dc_offset+dc_index) + regIndex;
			cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[TAC_TRIM1] = [dc[dc_index + dc_offset]  tac1trim:regIndex];
			cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[TAC_TRIM0] = [dc[dc_index + dc_offset]  tac0trim:regIndex];
			cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS20_WIDTH] = ([dc[dc_index + dc_offset]  ns20width:regIndex]) >> 1;	 // since bit 1 is the LSB
			cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS20_DELAY] = ([dc[dc_index + dc_offset]  ns20delay:regIndex]) >> 1;    // since bit 1 is the LSB
			cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS100_DELAY] = ([dc[dc_index + dc_offset] ns100width:regIndex]) >> 1;   // since bit 1 is the LSB
			
			if (aTriggersDisabled /*|| !theHVStatus.IsHVOnThisChannel(itsSNOCrate->Get_SC_Number(),itsFec32SlotNumber,channel)*/ ) {
				cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS20_MASK] = 0;
				cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS100_MASK] = 0;
				[self setTrigger20ns:channel disabled:YES];
				[self setTrigger100ns:channel disabled:YES];
			} else {
				cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS20_MASK]  = ![self trigger20nsDisabled:channel];
				cmosShiftRegisterValue[offset_index + regIndex].cmos_shift_item[NS100_MASK] = ![self trigger100nsDisabled:channel];
			}
		}
		
	}		
}


@end

@implementation ORFec32Model (SBC)
- (void) loadAllDacsUsingSBC
{
	//-------------- variables -----------------
	uint32_t	i,j,k;								
	short			theIndex;
	const short		numChannels = 8;
	uint32_t	writeValue  = 0;
	uint32_t	dacValues[8][17];
	//------------------------------------------
	
	NSLog(@"Setting all DACs for FEC32 (%d,%d)....\n", [self crateNumber],[self stationNumber]);
	
	@try {
		[[self xl2] select:self];
		
		// Need to do Full Buffer mode before and after the DACs are loaded the first time
		// Full Buffer Mode of DAC loading, before the DACs are loaded -- this works 1/20/97
		
		ORCommandList* aList = [ORCommandList commandList];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x0]];  // set DACSEL
		
		for ( i = 1; i<= 16 ; i++) {
			if ( ( i<9 ) || ( i == 10) ){
				writeValue = 0UL;
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];
			}
			else {
				writeValue = 0x0007FFFC;
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];	// address value, enable this channel					
			}
			[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue+1]];
		}
		
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x2]];// remove DACSEL
		
		// now clock in the address and data values
		for ( i = numChannels; i >= 1 ; i--) {			// 8 channels, i.e. there are 8 lines of data values
			
			[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x0]];  // set DACSEL
			
			// clock in the address values
			for ( j = 1; j<= 8; j++){					
				if ( j == i) {
					// enable all 17 DAC address lines for a particular channel
					writeValue = 0x0007FFFC;
					[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];
				}
				else{
					writeValue = 0UL;
					[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]]; //disable channel
				}
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue+1]];	// clock in
			}
			
			// first load the DAC values from the database into a 8x17 matirx
			short cIndex;
			for (cIndex = 0; cIndex <= 16; cIndex++){
				short rIndex;
				for (rIndex = 0; rIndex <= 7; rIndex++){
					switch( cIndex ){
							
						case 0:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] rp2:0];
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] rp2:1];
							}	
							break;
							
						case 1:
							if ( rIndex%2 == 0)	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] vli:0];					
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] vli:1];	
							}	
							break;
							
						case 2:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] vsi:0];					
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] vsi:1];		
							}	
							break;
							
						case 15:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] rp1:0];						
								dacValues[rIndex + 1][cIndex]   = [dc[theIndex] rp1:0];		
							}	
							break;
					}
					
					if ( (cIndex >= 3) && (cIndex <= 6) ) {
						dacValues[rIndex][cIndex] = [dc[cIndex - 3] vt:rIndex];
					}
					
					else if ( (cIndex >= 7) && (cIndex <= 14) ) {
						if ( (cIndex - 7)%2 == 0)	{
							theIndex = ( (cIndex - 7) / 2 );
							
							uint32_t theGain;
							if (rIndex/4)	theGain = 1;
							else			theGain = 0;
							dacValues[rIndex][cIndex]	= [dc[theIndex] vb:rIndex%4    egain:theGain];
							dacValues[rIndex][cIndex+1] = [dc[theIndex] vb:(rIndex%4)+4 egain:theGain];
						}
					}
					else if ( cIndex == 16) {
						switch( rIndex){
							case 6:  dacValues[rIndex][cIndex] = [self vRes];			break;
							case 7:  dacValues[rIndex][cIndex] = [self hVRef];			break;
							default: dacValues[rIndex][cIndex] = [self cmos:rIndex];	break;
						}		
					}
				}
			}
			// load data values, 17 DAC values at a time, from the electronics database
			// there are a total of 8x17 = 136 DAC values
			// load the data values
			for (j = 8; j >= 1; j--){					// 8 bits of data per channel
				writeValue = 0UL;
				for (k = 2; k<= 18; k++){				// 17 octal DACs
					if ( (1UL << j-1 ) & dacValues[numChannels - i][k-2] ) {
						writeValue |= 1UL << k;
					}
				}
				
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue+1]];	// clock in
			}
			
			[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x2]]; // remove DACSEL
		}
		// Full Buffer Mode of DAC loading, after the DACs are loaded -- this works 1/13/97
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x0]]; // set DACSEL
		
		for ( i = 1; i<= 16 ; i++){
			if ( ( i<9 ) || ( i == 10) ){
				writeValue = 0UL;
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];
			}
			else{
				writeValue = 0x0007FFFC;
				[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue]];
			}
			[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue + 1]];	// clock in with bit 0 high
		}
		
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:0x2]]; // remove DACSEL
		[self executeCommandList:aList];
		
		[[self xl2] deselectCards];		
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];		
		NSLog(@"Could not load the DACs for FEC32(%d,%d)!\n", [self crateNumber], [self stationNumber]);			
	}	
}


- (NSString*) performBoardIDReadUsingSBC:(short) boardIndex
{
	unsigned short 	dataValue = 0;
	uint32_t	writeValue = 0UL;
	uint32_t	theRegister = BOARD_ID_REG_NUMBER;
	// first select the board (XL2 must already be selected)
	uint32_t boardSelectVal = 0;
	boardSelectVal |= (1UL << boardIndex);
	
	ORCommandList* aList = [ORCommandList commandList];		//start a command list.
	
	[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:boardSelectVal]];
	
	//-------------------------------------------------------------------------------------------
	// load and clock in the first 9 bits instruction code and register address
	//[self boardIDOperation:(BOARD_ID_READ | theRegister) boardSelectValue:boardSelectVal beginIndex: 8];
	//moved here so we could combine all the commands into one list for speed.
	uint32_t theDataValue = (BOARD_ID_READ | theRegister);
	short index;
	for (index = 8; index >= 0; index--){
		if ( theDataValue & (1U << index) ) writeValue = (boardSelectVal | BOARD_ID_DI);
		else								writeValue = boardSelectVal;
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:writeValue]];					// load data value
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)]];	// now clock in value
	}
	//-------------------------------------------------------------------------------------------
	
	// now read the data value; 17 reads, the last data bit is a dummy bit
	writeValue = boardSelectVal;
	
	int cmdRef[16];
	for (index = 15; index >= 0; index--){
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:writeValue]];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)]];	// now clock in value
		cmdRef[index] = [aList addCommand: [self readFromFec32RegisterCmd:FEC32_BOARD_ID_REG]];											// read the data bit
	}
	
	[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:writeValue]];					// read out the dummy bit
	[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)]];	// now clock in value
	[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:0UL]];						// Now de-select all and clock
	[aList addCommand: [self writeToFec32RegisterCmd:FEC32_BOARD_ID_REG value:BOARD_ID_SK]];				// now clock in value
	
	[self executeCommandList:aList]; //send out the list (blocks until reply or timeout)
	
	//OK, assemble the result
	for (index = 15; index >= 0; index--){
		int32_t readValue = [aList longValueForCmd:cmdRef[index]];
		if ( readValue & BOARD_ID_DO)dataValue |= (1U << index);
	}
	
	return hexToString(dataValue);
}

@end

@implementation ORFec32Model (LocalAdapter)
- (void) loadAllDacsUsingLocalAdapter
{
	//-------------- variables -----------------
	uint32_t	i,j,k;								
	short			theIndex;
	const short		numChannels = 8;
	uint32_t	writeValue  = 0;
	uint32_t	dacValues[8][17];
	//------------------------------------------
	
	NSLog(@"Setting all DACs for FEC32 (%d,%d)....\n", [self crateNumber],[self stationNumber]);
	
	@try {
		[[self xl2] select:self];
		[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x0];  // set DACSEL
		
		for ( i = 1; i<= 16 ; i++) {
			if ( ( i<9 ) || ( i == 10) ){
				writeValue = 0UL;
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];
			}
			else {
				writeValue = 0x0007FFFC;
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];	// address value, enable this channel					
			}
			[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue+1];
		}
		
		[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x2];// remove DACSEL
		
		// now clock in the address and data values
		for ( i = numChannels; i >= 1 ; i--) {			// 8 channels, i.e. there are 8 lines of data values
			[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x0];  // set DACSEL
			// clock in the address values
			for ( j = 1; j<= 8; j++){					
				if ( j == i) {
					// enable all 17 DAC address lines for a particular channel
					writeValue = 0x0007FFFC;
					[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];
				}
				else{
					writeValue = 0UL;
					[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue]; //disable channel
				}
				[self writeToFec32RegisterCmd:FEC32_DAC_PROGRAM_REG value:writeValue+1]; // clock in
			}
			
			// first load the DAC values from the database into a 8x17 matirx
			short cIndex;
			for (cIndex = 0; cIndex <= 16; cIndex++){
				short rIndex;
				for (rIndex = 0; rIndex <= 7; rIndex++){
					switch( cIndex ){
						case 0:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] rp2:0];
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] rp2:1];
							}	
							break;
						case 1:
							if ( rIndex%2 == 0)	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] vli:0];					
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] vli:1];	
							}	
							break;
						case 2:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] vsi:0];					
								dacValues[rIndex + 1][cIndex]	= [dc[theIndex] vsi:1];		
							}	
							break;
						case 15:
							if ( rIndex%2 == 0 )	{
								theIndex = (rIndex/2);
								dacValues[rIndex][cIndex]		= [dc[theIndex] rp1:0];						
								dacValues[rIndex + 1][cIndex]   = [dc[theIndex] rp1:0];		
							}	
							break;
					}
					if ( (cIndex >= 3) && (cIndex <= 6) ) {
						dacValues[rIndex][cIndex] = [dc[cIndex - 3] vt:rIndex];
					}
					else if ( (cIndex >= 7) && (cIndex <= 14) ) {
						if ( (cIndex - 7)%2 == 0)	{
							theIndex = ( (cIndex - 7) / 2 );
							
							uint32_t theGain;
							if (rIndex/4)	theGain = 1;
							else			theGain = 0;
							dacValues[rIndex][cIndex]	= [dc[theIndex] vb:rIndex%4    egain:theGain];
							dacValues[rIndex][cIndex+1] = [dc[theIndex] vb:(rIndex%4)+4 egain:theGain];
						}
					}
					else if ( cIndex == 16) {
						switch( rIndex){
							case 6:  dacValues[rIndex][cIndex] = [self vRes];			break;
							case 7:  dacValues[rIndex][cIndex] = [self hVRef];			break;
							default: dacValues[rIndex][cIndex] = [self cmos:rIndex];	break;
						}		
					}
				}
			}
			// load data values, 17 DAC values at a time, from the electronics database
			// there are a total of 8x17 = 136 DAC values
			// load the data values
			for (j = 8; j >= 1; j--){					// 8 bits of data per channel
				writeValue = 0UL;
				for (k = 2; k<= 18; k++){				// 17 octal DACs
					if ( (1UL << j-1 ) & dacValues[numChannels - i][k-2] ) {
						writeValue |= 1UL << k;
					}
				}
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue+1];	// clock in
			}
			[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x2]; // remove DACSEL
		}
		// Full Buffer Mode of DAC loading, after the DACs are loaded -- this works 1/13/97
		[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x0]; // set DACSEL
		
		for ( i = 1; i<= 16 ; i++){
			if ( ( i<9 ) || ( i == 10) ){
				writeValue = 0UL;
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];
			}
			else{
				writeValue = 0x0007FFFC;
				[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue];
			}
			[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:writeValue + 1];	// clock in with bit 0 high
		}
		
		[self writeToFec32Register:FEC32_DAC_PROGRAM_REG value:0x2]; // remove DACSEL
		[[self xl2] deselectCards];		
	}
	@catch(NSException* localException) {
		[[self xl2] deselectCards];		
		NSLog(@"Could not load the DACs for FEC32(%d,%d)!\n", [self crateNumber], [self stationNumber]);			
	}	
}


- (NSString*) performBoardIDReadUsingLocalAdapter:(short) boardIndex
{
	unsigned short 	dataValue = 0;
	uint32_t	writeValue = 0UL;
	uint32_t	theRegister = BOARD_ID_REG_NUMBER;
	// first select the board (XL2 must already be selected)
	uint32_t boardSelectVal = 0;
	boardSelectVal |= (1UL << boardIndex);
	
	[self writeToFec32Register:FEC32_BOARD_ID_REG value:boardSelectVal];
	
	//-------------------------------------------------------------------------------------------
	// load and clock in the first 9 bits instruction code and register address
	//[self boardIDOperation:(BOARD_ID_READ | theRegister) boardSelectValue:boardSelectVal beginIndex: 8];
	//moved here so we could combine all the commands into one list for speed.
	uint32_t theDataValue = (BOARD_ID_READ | theRegister);
	short index;
	for (index = 8; index >= 0; index--){
		if (theDataValue & (1U << index))	writeValue = (boardSelectVal | BOARD_ID_DI);
		else					writeValue = boardSelectVal;
		[self writeToFec32Register:FEC32_BOARD_ID_REG value:writeValue];			// load data value
		[self writeToFec32Register:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)];	// now clock in value
	}
	//-------------------------------------------------------------------------------------------
	
	// now read the data value; 17 reads, the last data bit is a dummy bit
	writeValue = boardSelectVal;
	
	uint32_t cmdRef[16];
	for (index = 15; index >= 0; index--){
		[self writeToFec32Register:FEC32_BOARD_ID_REG value:writeValue];
		[self writeToFec32Register:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)];	// now clock in value
		cmdRef[index] = [self readFromFec32Register:FEC32_BOARD_ID_REG];			// read the data bit
	}
	
	[self writeToFec32Register:FEC32_BOARD_ID_REG value:writeValue];				// read out the dummy bit
	[self writeToFec32Register:FEC32_BOARD_ID_REG value:(writeValue | BOARD_ID_SK)];		// now clock in value
	[self writeToFec32Register:FEC32_BOARD_ID_REG value:0UL];					// Now de-select all and clock
	[self writeToFec32Register:FEC32_BOARD_ID_REG value:BOARD_ID_SK];				// now clock in value
		
	//OK, assemble the result
	for (index = 15; index >= 0; index--){
		int32_t readValue = cmdRef[index];
		if (readValue & BOARD_ID_DO) dataValue |= (1U << index);
	}
	
	return hexToString(dataValue);
}
@end

@implementation ORFec32Model (XL2)

-(BOOL) readVoltagesUsingXL2
{
    short whichADC;
    BOOL statusChanged = false;

    @try {
        [[self xl2] select:self];
        
        for(whichADC=0;whichADC<kNumFecMonitorAdcs;whichADC++){
            short theValue = [self readVoltageValue:fecVoltageAdc[whichADC].mask];
            eFecMonitorState old_channel_status = [self adcVoltageStatus:whichADC];
            eFecMonitorState new_channel_status;
            if( theValue != -1) {
                float convertedValue = ((float)theValue-128.0)*fecVoltageAdc[whichADC].multiplier;
                [self setAdcVoltage:whichADC withValue:convertedValue];
                if(fecVoltageAdc[whichADC].check_expected_value){
                    float expected = fecVoltageAdc[whichADC].expected_value;
                    float delta = fabs(expected*[[self xl1] adcAllowedError:whichADC]);
                    if(fabs(convertedValue-expected) < delta)	new_channel_status = kFecMonitorInRange;
                    else										new_channel_status = kFecMonitorOutOfRange;
                }
                else new_channel_status = kFecMonitorInRange;
            }
            else new_channel_status = kFecMonitorReadError;
            
            [self setAdcVoltageStatus:whichADC withValue:new_channel_status];
            
            if(old_channel_status != new_channel_status){
                statusChanged = true;
            }
        }
    }
    @catch(NSException* localException) {
		short whichADC;
		[self setAdcVoltageStatusOfCard:kFecMonitorReadError];
		for(whichADC=0;whichADC<kNumFecMonitorAdcs;whichADC++){
			[self setAdcVoltageStatus:whichADC withValue:kFecMonitorReadError];
		}
		[[self xl2] deselectCards];
	}
	[[self xl2] deselectCards];
    return statusChanged;
}

const short kVoltageADCMaximumAttempts = 10;

-(short) readVoltageValue:(uint32_t) aMask
{
	short theValue = -1;
	
	@try {
		ORCommandList* aList = [ORCommandList commandList];
		
		// write the ADC mask keeping bits 14,15 high  i.e. CS,RD
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_VOLTAGE_MONITOR_REG value:aMask | 0x0000C000UL]];
		// write the ADC mask keeping bits 14,15 low -- this forces conversion
		[aList addCommand:[self delayCmd:0.001]];
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_VOLTAGE_MONITOR_REG value:aMask]];
		[aList addCommand:[self delayCmd:0.002]];
		int adcValueCmdIndex = [aList addCommand: [self readFromFec32RegisterCmd:FEC32_VOLTAGE_MONITOR_REG]];
		
		//MAH 8/30/99 leave the voltage register connected to a ground address.
		[aList addCommand: [self writeToFec32RegisterCmd:FEC32_VOLTAGE_MONITOR_REG value:groundMask | 0x0000C000UL]];
		[self executeCommandList:aList];
        
		//pull out the result
		uint32_t adcReadValue = [aList longValueForCmd:adcValueCmdIndex];
		if(adcReadValue & 0x100UL){
			theValue = adcReadValue & 0x000000ff; //keep only the lowest 8 bits.
		}
	}
	@catch(NSException* localException) {
	}
	return theValue;
}

- (BOOL) readCMOSCountsUsingXL2:(BOOL)calcRates channelMask:(uint32_t) aChannelMask
{
	int32_t		   	theRate = kCMOSRateUnmeasured;
	int32_t		   	maxRate = kCMOSRateUnmeasured;
	uint32_t  	theCount;
	unsigned short 	channel;
	unsigned short	maxRateChannel = 0;
	
	NSDate* lastTime = cmosCountTimeStamp;
	NSDate* thisTime = [[NSDate alloc] init];
	NSTimeInterval timeDiff = [thisTime timeIntervalSinceDate:lastTime];
	float sampleFreq;
    
	if ((calcRates && (timeDiff<0 || timeDiff>kMaxTimeDiff)) || timeDiff==0) {
		calcRates = 0;	// don't calculate rates if time diff is silly
	}
	if(timeDiff){
        sampleFreq = 1 / timeDiff;
    }
	
	[cmosCountTimeStamp release];
	cmosCountTimeStamp = [thisTime copy];
    [thisTime release];
    thisTime = nil;
	
	//uint32_t theOnlineMask = [self onlineMask];
	
	BOOL selected = NO;
	@try {	
		[[self xl2] select:self];
		selected = YES;
		
		ORCommandList* aList = [ORCommandList commandList];
		uint32_t resultIndex[32];
		for (channel=0; channel<32; ++channel) {
			if(aChannelMask & (1UL<<channel) && ![self cmosReadDisabled:channel]){
				resultIndex[channel] = [aList addCommand:[self readFromFec32RegisterCmd:FEC32_CMOS_TOTALS_COUNTER_OFFSET+32*channel]];
			}
		}
		[self executeCommandList:aList];
		//pull the results
		for (channel=0; channel<32; ++channel) {
			if(aChannelMask & (1UL<<channel) && ![self cmosReadDisabled:channel]){
				theCount = [aList longValueForCmd:(int)resultIndex[channel]];
				//if( (theCount & 0x80000000) == 0x80000000 ){
				//busy... TBD put out error or something MAH 12/19/08
				//}
			}
			else {
				theCount = kCMOSRateUnmeasured;
			}
			
			if (calcRates) {
				if (aChannelMask & (1UL<<channel) && ![self cmosReadDisabled:channel]) {
					// get value of last totals counter read
					if ((theCount | cmosCount[channel]) & 0x80000000UL) {	// test for CMOS read error
						if( (cmosCount[channel] == 0x8000deadUL) || (theCount == 0x8000deadUL) ) theRate = kCMOSRateBusError;
						else															theRate = kCMOSRateBusyRead;
					} 
					else theRate = (theCount - cmosCount[channel]) * sampleFreq;
					
					// keep track of maximum count rate
					if (maxRate < theRate) {
						maxRate = theRate;
						maxRateChannel = channel;
					}
					if (theRate > 1e9) theRate = kCMOSRateCorruptRead;			//MAH 3/19/98
				} 
				else theRate = kCMOSRateUnmeasured;								//PH 04/07/99
			}
			
			cmosCount[channel] = theCount;	// save the new CMOS totals counter and rate
			cmosRate[channel]  = theRate;	// this will be kCMOSRateUnmeasured if not calculating rates
		}
	}
	@catch (NSException* localException){
	}	
	return calcRates;
}

@end //ORFec32Model (XL2)


@implementation ORFec32Model (XL3)

- (uint32_t) relayChannelMask
{
    /* Returns a 32 bit mask indicating which channels are connected to a
     * closed relay. */
    int i;
    uint32_t hv = 0;

    for (i = 0; i < 4; i++) {
        if (([[[self guardian] adapter] relayMask] >> ([self stationNumber]*4 + (3-i))) & 0x1) {
            hv |= 0xff << i*8;
        }
    }

    return hv;
}


-(BOOL) parseVoltagesUsingXL3:(VMonResults*) result
{
    BOOL statusChanged = false;
    short whichADC;

    unsigned char sharc_to_xl3[21] = {20,13,12,3,2,4,1,0,19,18,14,15,5,16,6,17,9,10,11,7,8};
    
    for(whichADC=0;whichADC<kNumFecMonitorAdcs;whichADC++){
        eFecMonitorState old_channel_status = [self adcVoltageStatus:whichADC];
        eFecMonitorState new_channel_status;
        float convertedValue = result->voltages[sharc_to_xl3[whichADC]];
        [self setAdcVoltage:whichADC withValue:convertedValue];
        if(fecVoltageAdc[whichADC].check_expected_value){
            float expected = fecVoltageAdc[whichADC].expected_value;
            //float delta = fabs(expected*[[self xl1] adcAllowedError:whichADC]);
            float delta = fabs(expected * kAllowedFecMonitorError);
            if(fabs(convertedValue-expected) < delta)	new_channel_status = kFecMonitorInRange;
            else										new_channel_status = kFecMonitorOutOfRange;
        }
        else new_channel_status = kFecMonitorInRange;
        //unless read error (XL3 doesn't provide)
        //else new_channel_status = kFecMonitorReadError;
        
        if(old_channel_status != new_channel_status){
            [self setAdcVoltageStatus:whichADC withValue:new_channel_status];
            statusChanged = true;
        }
    }
    return statusChanged;
}

-(BOOL) readVoltagesUsingXL3
{
    BOOL statusChanged = false;
    VMonResults result;
    [[guardian adapter] readVMONForSlot:[self stationNumber] voltages:&result];

    statusChanged = [self parseVoltagesUsingXL3:&result];
    
    return statusChanged;
}

-(void) readCMOSCountsUsingXL3:(uint32_t)aChannelMask
{
    CheckTotalCountArgs args;
    CheckTotalCountResults results;
    
    args.slotMask |= 0x1 << [self stationNumber];
    args.channelMasks[[self stationNumber]] = (uint32_t)aChannelMask;
    //what about disabled??? [self cmosReadDisabled:channel]
    
    @try {
        [guardian readCMOSCountWithArgs:&args counts:&results];
    }
    @catch (NSException *exception) {
        ;
    }
    
    //if (results.errorFlags != 0); ???
    unsigned char ch;
    for (ch=0; ch<32; ch++) {
        cmosCount[ch]  = results.count[ch];
    }
}

-(void) readCMOSRatesUsingXL3:(uint32_t)aChannelMask
{
    CrateNoiseRateArgs args;
    CrateNoiseRateResults results;

    args.slotMask |= 0x1 << [self stationNumber];
    args.channelMask[[self stationNumber]] = (uint32_t)aChannelMask;
    args.period = 1; //usec according to doc, msec according to code
    
    @try {
        [guardian readCMOSRateWithArgs:&args rates:&results];
    }
    @catch (NSException *exception) {
        ;
    }

    //if (results.errorFlags != 0) {    }
    unsigned char ch;
    for (ch=0; ch<32; ch++) {
        cmosRate[ch]  = results.rates[ch];
    }

    //bizzarre rates are encoded:
    //if (rates[j] < 0){rates[j] = -9999;} //unphysical result
    //if (rates[j] > 3e6){rates[j] = -7777;} //unphysical result
    //if (eflag[j] == 1){rates[j] = -5555;} //error flag set
}

@end //ORFec32Model (XL3)
