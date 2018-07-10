/*
 *  ORJADCLModel.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORCamacIOCard.h"
#import "ORAdcProcessing.h"
#import "ORHWWizard.h"

@class ORDataPacket;
@class ORAlarm;
@class ORTimeRate;

#define kAdcLRangeOK	0
#define kAdcLRangeLow	1
#define kAdcLRangeHigh	2


@interface ORJADCLModel : ORCamacIOCard <ORHWWizard, ORAdcProcessing> {	
	@private
		float lowLimits[16];
		float highLimits[16];
		float adcValue[16];
		int adcRange[16];
		ORAlarm* highAlarms[16];
		ORAlarm* lowAlarms[16];
		ORTimeRate* timeRates[16];
		
		NSString* lastRead;
		unsigned short enabledMask;
		unsigned short alarmsEnabledMask;
		
        //place to cache some stuff for alittle more speed.
		int rangeIndex;
		int pollingState;
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;
        
#pragma mark ¥¥¥Accessors
- (int) pollingState;
- (void) setPollingState:(int)aPollingState;
- (NSString*) lastRead;
- (void) setLastRead:(NSString*)aLastRead;
- (int) rangeIndex;
- (void) setRangeIndex:(int)aRangeIndex;
- (unsigned short) enabledMask;
- (void) setEnabledMask:(unsigned short)aEnabledMask;
- (BOOL)enabledBit:(int)bit;
- (void) setEnabledBit:(int)bit withValue:(BOOL)aValue;
- (unsigned short) alarmsEnabledMask;
- (void) setAlarmsEnabledMask:(unsigned short)aEnabledMask;
- (BOOL)alarmsEnabledBit:(int)bit;
- (void) setAlarmsEnabledBit:(int)bit withValue:(BOOL)aValue;

- (float) highLimit:(unsigned short)aChan;
- (void) setHighLimit:(unsigned short) aChan withValue:(float) aLowLimit;
- (float) lowLimit:(unsigned short)aChan;
- (void) setLowLimit:(unsigned short) aChan withValue:(float) aLowLimit;
- (float) adcValue:(unsigned short)aChan;
- (void) setAdcValue:(unsigned short) aChan withValue:(float) aValue;
- (float) adcRange:(unsigned short)aChan;
- (void) setAdcRange:(unsigned short) aChan withValue:(int) aValue;
- (ORTimeRate*)timeRate:(int)index;

#pragma mark ¥¥¥Hardware functions
- (void) initBoard;
- (void) readLimits;
- (void) readAdcs:(BOOL)verbose;
- (void) readAdcChannel:(int)aChan;
- (float) convertRawLimitToVolts:(unsigned short)rawValue;
- (unsigned short) convertVoltsToRawLimit:(float)volts;
- (float) convertRawAdcToVolts:(unsigned short)rawValue;
- (BOOL) adcTooLow:(unsigned long) aRawValue;
- (BOOL) adcTooHigh:(unsigned long) aRawValue;
- (void) postNotification:(NSNotification*)aNote;

#pragma mark ¥¥¥Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ¥¥¥Adc Processing Protocol
- (void)processIsStarting;
- (void)processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel;
- (double) convertedValue:(int)channel;
- (double) maxValueForChan:(int)channel;

#pragma mark ¥¥¥HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
@end

extern NSString* ORJADCLModelPollingStateChanged;
extern NSString* ORJADCLModelLastReadChanged;
extern NSString* ORJADCLModelRangeIndexChanged;
extern NSString* ORJADCLModelEnabledMaskChanged;
extern NSString* ORJADCLModelAlarmsEnabledMaskChanged;
extern NSString* ORJADCLSettingsLock;
extern NSString* ORJADCLModelHighLimitChanged;
extern NSString* ORJADCLModelLowLimitChanged;
extern NSString* ORJADCLModelAdcValueChanged;
extern NSString* ORJADCLChan;