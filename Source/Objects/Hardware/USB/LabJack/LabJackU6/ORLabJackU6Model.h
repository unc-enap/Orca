//
//  ORLabJackU6Model.h
//  Orca
//
//  Created by Mark Howe on Fri Jan 20,2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files

#import "ORHPPulserModel.h"
#import "ORAdcProcessing.h"
#import "ORBitProcessing.h"
#include "u6.h"


#define kNumU6AdcChannels 14
#define kNumU6IOChannels  20

@interface ORLabJackU6Model : OrcaObject <ORAdcProcessing,ORBitProcessing> {
	NSLock* localLock;
    BOOL  enabled[kNumU6AdcChannels];
	double adc[kNumU6AdcChannels];
	int    adcRange[kNumU6AdcChannels];
	float  lowLimit[kNumU6AdcChannels];
	float  hiLimit[kNumU6AdcChannels];
	float  minValue[kNumU6AdcChannels];
	float  maxValue[kNumU6AdcChannels];
	float  slope[kNumU6AdcChannels];
	float  intercept[kNumU6AdcChannels];
	NSString* channelName[kNumU6AdcChannels];   //adc names
	NSString* channelUnit[kNumU6AdcChannels];   //adc names
	unsigned long timeMeasured;
    NSString* doName[kNumU6IOChannels];
	unsigned short adcDiff;
	unsigned long doDirection;
	unsigned long doValueOut;
	unsigned long doValueIn;
    unsigned short aOut0;
    unsigned short aOut1;
	BOOL	led;
    BOOL    counterEnabled[2];
	BOOL	doResetOfCounter[2];
    unsigned long long counter[2];
    BOOL digitalOutputEnabled;
    int pollTime;
	unsigned long	dataId;
    BOOL shipData;
    BOOL readOnce;
	NSTimeInterval lastTime;
	NSOperationQueue* queue;
	
	//bit processing variables
	unsigned long processInputValue;  //snapshot of the inputs at start of process cycle
	unsigned long processOutputValue; //outputs to be written at end of process cycle
	unsigned long processOutputMask;  //controlls which bits are written
    BOOL involvedInProcess;
    HANDLE          deviceHandle;
    unsigned long   deviceSerialNumber;
    u6CalibrationInfo caliInfo;

}

#pragma mark ***Accessors
- (unsigned long) deviceSerialNumber;
- (void) setDeviceSerialNumber:(unsigned long)aDeviceSerialNumber;
- (HANDLE) deviceHandle;
- (BOOL) deviceOpen;
- (void) openDevice;
- (void) closeDevice;
- (void) setDeviceHandle:(HANDLE)aDeviceHandle;
- (BOOL) involvedInProcess;
- (void) setInvolvedInProcess:(BOOL)aInvolvedInProcess;
- (BOOL) enabled:(unsigned short)chan;
- (void) setEnabled:(unsigned short)chan withValue:(BOOL)aValue;
- (BOOL) counterEnabled:(unsigned short)chan;
- (void) setCounterEnabled:(unsigned short)chan withValue:(BOOL)aValue;
- (BOOL) digitalOutputEnabled;
- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled;
- (void) setAOut0Voltage:(float)aValue;
- (void) setAOut1Voltage:(float)aValue;
- (unsigned short) aOut1;
- (void) setAOut1:(unsigned short)aAOut1;
- (unsigned short) aOut0;
- (void) setAOut0:(unsigned short)aAOut0;
- (BOOL) shipData;
- (void) setShipData:(BOOL)aShipData;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (unsigned long long) counter:(int)i;
- (void) setCounter:(int)i withValue:(unsigned long long)aCounter;
- (NSString*) channelName:(int)i;
- (void) setChannel:(int)i name:(NSString*)aName;
- (NSString*) channelUnit:(int)i;
- (void) setChannel:(int)i unit:(NSString*)aName;
- (NSString*) doName:(int)i;
- (void) setDo:(int)i name:(NSString*)aName;
- (double) adc:(int)i;
- (void) setAdc:(int)i withValue:(double)aValue;
- (int)adcConvertedRange:(int)i;
- (int) adcRange:(int)i;
- (void) setAdcRange:(int)i withValue:(int)aValue;
- (float) lowLimit:(int)i;
- (void) setLowLimit:(int)i withValue:(float)aValue;
- (float) hiLimit:(int)i;
- (void) setHiLimit:(int)i withValue:(float)aValue;
- (float) slope:(int)i;
- (void) setSlope:(int)i withValue:(float)aValue;
- (float) intercept:(int)i;
- (void) setIntercept:(int)i withValue:(float)aValue;
- (float) minValue:(int)i;
- (void) setMinValue:(int)i withValue:(float)aValue;
- (float) maxValue:(int)i;
- (void) setMaxValue:(int)i withValue:(float)aValue;

- (unsigned short) adcDiff;
- (void) setAdcDiff:(unsigned short)aMask;
- (void) setAdcDiffBit:(int)bit withValue:(BOOL)aValue;

- (unsigned long) doDirection;
- (void) setDoDirection:(unsigned long)aMask;
- (void) setDoDirectionBit:(int)bit withValue:(BOOL)aValue;

- (unsigned long) doValueOut;
- (void) setDoValueOut:(unsigned long)aMask;
- (void) setDoValueOutBit:(int)bit withValue:(BOOL)aValue;

- (unsigned long) doValueIn;
- (void) setDoValueIn:(unsigned long)aMask;
- (void) setDoValueInBit:(int)bit withValue:(BOOL)aValue;
- (NSString*) doInString:(int)bit;
- (NSColor*) doInColor:(int)i;

- (unsigned long) timeMeasured;

- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherLakeShore210;
- (void) readSerialNumbers;
- (void) shipTheData;

#pragma mark •••Adc Processing Protocol
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

#pragma mark ***HW Access
- (void) toggleOpen;
- (void) resetCounter:(int)i;
- (void) queryAll;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORLabJackU6ModelDeviceSerialNumberChanged;
extern NSString* ORLabJackU6ModelDeviceHandleChanged;
extern NSString* ORLabJackU6ModelInvolvedInProcessChanged;
extern NSString* ORLabJackU6ModelAOut1Changed;
extern NSString* ORLabJackU6ModelAOut0Changed;
extern NSString* ORLabJackU6ShipDataChanged;
extern NSString* ORLabJackU6PollTimeChanged;
extern NSString* ORLabJackU6EnabledChanged;
extern NSString* ORLabJackU6DigitalOutputEnabledChanged;
extern NSString* ORLabJackU6DigitalOutputCounterEnabledChanged;
extern NSString* ORLabJackU6CounterChanged;
extern NSString* ORLabJackU6RelayChanged;
extern NSString* ORLabJackU6Lock;
extern NSString* ORLabJackU6ChannelNameChanged;
extern NSString* ORLabJackU6ChannelUnitChanged;
extern NSString* ORLabJackU6AdcChanged;
extern NSString* ORLabJackU6DoNameChanged;
extern NSString* ORLabJackU6DoDirectionChanged;
extern NSString* ORLabJackU6DoValueOutChanged;
extern NSString* ORLabJackU6DoValueInChanged;
extern NSString* ORLabJackU6HiLimitChanged;
extern NSString* ORLabJackU6LowLimitChanged;
extern NSString* ORLabJackU6AdcDiffChanged;
extern NSString* ORLabJackU6AdcRangeChanged;
extern NSString* ORLabJackU6SlopeChanged;
extern NSString* ORLabJackU6InterceptChanged;
extern NSString* ORLabJackU6MinValueChanged;
extern NSString* ORLabJackU6MaxValueChanged;
extern NSString* ORLabJackU6CounterEnabledChanged;

@interface ORLabJackU6Query : NSOperation
{
	id delegate;
}
- (id) initWithDelegate:(id)aDelegate;
- (void) main;
@end

