//
//  ORLabJackModel.h
//  Orca
//
//  Created by Mark Howe on Tues Nov 09,2010.
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
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
#import "ORUSB.h"
#import "ORAdcProcessing.h"
#import "ORBitProcessing.h"

@class ORUSBInterface;
@class ORAlarm;


@interface ORLabJackModel : OrcaObject <USBDevice,ORAdcProcessing,ORBitProcessing> {
	NSLock* localLock;
	ORUSBInterface* usbInterface;
    NSString* serialNumber;
	ORAlarm*  noUSBAlarm;
	ORAlarm*  noDriverAlarm;
	int adc[8];
	int gain[4];
	float lowLimit[8];
	float hiLimit[8];
	float minValue[8];
	float maxValue[8];
	float slope[8];
	float intercept[8];
	NSString* channelName[8];   //adc names
	NSString* channelUnit[8];   //adc names
	uint32_t timeMeasured;
	NSString* doName[16];		//the D connector on the side
	NSString* ioName[4];		//on top
	unsigned short adcDiff;
	unsigned short doDirection;
	unsigned short ioDirection;
	unsigned short ioValueOut;
	unsigned short doValueOut;
	unsigned short ioValueIn;
	unsigned short doValueIn;
    unsigned short aOut0;
    unsigned short aOut1;
	BOOL	led;
	BOOL	doResetOfCounter;
    uint32_t counter;
    BOOL digitalOutputEnabled;
    int pollTime;
	uint32_t	dataId;
    BOOL shipData;
    BOOL readOnce;
	NSTimeInterval lastTime;
	NSOperationQueue* queue;
	
	//bit processing variables
	uint32_t processInputValue;  //snapshot of the inputs at start of process cycle
	uint32_t processOutputValue; //outputs to be written at end of process cycle
	uint32_t processOutputMask;  //controlls which bits are written
    BOOL involvedInProcess;
    uint32_t deviceSerialNumber;
}

#pragma mark ***Accessors
- (uint32_t) deviceSerialNumber;
- (void) setDeviceSerialNumber:(uint32_t)aDeviceSerialNumber;
- (BOOL) involvedInProcess;
- (void) setInvolvedInProcess:(BOOL)aInvolvedInProcess;
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
- (BOOL) digitalOutputEnabled;
- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled;
- (uint32_t) counter;
- (void) setCounter:(uint32_t)aCounter;
- (NSString*) channelName:(int)i;
- (void) setChannel:(int)i name:(NSString*)aName;
- (NSString*) channelUnit:(int)i;
- (void) setChannel:(int)i unit:(NSString*)aName;
- (NSString*) doName:(int)i;
- (void) setDo:(int)i name:(NSString*)aName;
- (NSString*) ioName:(int)i;
- (void) setIo:(int)i name:(NSString*)aName;
- (int) adc:(int)i;
- (void) setAdc:(int)i withValue:(int)aValue;
- (int) gain:(int)i;
- (void) setGain:(int)i withValue:(int)aValue;
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

- (unsigned short) doDirection;
- (void) setDoDirection:(unsigned short)aMask;
- (void) setDoDirectionBit:(int)bit withValue:(BOOL)aValue;

- (unsigned short) ioDirection;
- (void) setIoDirection:(unsigned short)aMask;
- (void) setIoDirectionBit:(int)bit withValue:(BOOL)aValue;

- (unsigned short) doValueOut;
- (void) setDoValueOut:(unsigned short)aMask;
- (void) setDoValueOutBit:(int)bit withValue:(BOOL)aValue;

- (unsigned short) ioValueOut;
- (void) setIoValueOut:(unsigned short)aMask;
- (void) setIoValueOutBit:(int)bit withValue:(BOOL)aValue;

- (unsigned short) doValueIn;
- (void) setDoValueIn:(unsigned short)aMask;
- (void) setDoValueInBit:(int)bit withValue:(BOOL)aValue;
- (NSString*) doInString:(int)bit;
- (NSColor*) doInColor:(int)i;

- (unsigned short) ioValueIn;
- (void) setIoValueIn:(unsigned short)aMask;
- (void) setIoValueInBit:(int)bit withValue:(BOOL)aValue;
- (NSString*) ioInString:(int)bit;
- (NSColor*) ioInColor:(int)i;
- (uint32_t) timeMeasured;

- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherLakeShore210;
- (void) readSerialNumber;

#pragma mark ***USB Stuff
- (id) getUSBController;
- (ORUSBInterface*) usbInterface;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (NSUInteger) vendorID;
- (NSUInteger) productID;
- (NSString*) usbInterfaceDescription;
- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;
- (void) checkUSBAlarm;

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
- (void) resetCounter;
- (void) queryAll;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORLabJackModelDeviceSerialNumberChanged;
extern NSString* ORLabJackModelInvolvedInProcessChanged;
extern NSString* ORLabJackModelAOut1Changed;
extern NSString* ORLabJackModelAOut0Changed;
extern NSString* ORLabJackShipDataChanged;
extern NSString* ORLabJackPollTimeChanged;
extern NSString* ORLabJackDigitalOutputEnabledChanged;
extern NSString* ORLabJackCounterChanged;
extern NSString* ORLabJackSerialNumberChanged;
extern NSString* ORLabJackUSBInterfaceChanged;
extern NSString* ORLabJackRelayChanged;
extern NSString* ORLabJackLock;
extern NSString* ORLabJackChannelNameChanged;
extern NSString* ORLabJackChannelUnitChanged;
extern NSString* ORLabJackAdcChanged;
extern NSString* ORLabJackDoNameChanged;
extern NSString* ORLabJackIoNameChanged;
extern NSString* ORLabJackDoDirectionChanged;
extern NSString* ORLabJackIoDirectionChanged;
extern NSString* ORLabJackDoValueOutChanged;
extern NSString* ORLabJackIoValueOutChanged;
extern NSString* ORLabJackDoValueInChanged;
extern NSString* ORLabJackIoValueInChanged;
extern NSString* ORLabJackHiLimitChanged;
extern NSString* ORLabJackLowLimitChanged;
extern NSString* ORLabJackAdcDiffChanged;
extern NSString* ORLabJackGainChanged;
extern NSString* ORLabJackSlopeChanged;
extern NSString* ORLabJackInterceptChanged;
extern NSString* ORLabJackMinValueChanged;
extern NSString* ORLabJackMaxValueChanged;

@interface ORLabJackQuery : NSOperation
{
	id delegate;
}
- (id) initWithDelegate:(id)aDelegate;
- (void) main;
@end

