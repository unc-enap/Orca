//
//  ORLabJackT7Model.h
//  Orca
//
//  Created by Mark Howe on Fri Jan 20,2017.
//  Updated by Jan Behrens on Dec 21, 2020.
//  Copyright (c) 2017-2020 University of North Carolina. All rights reserved.
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

#include "orca_t7.h"

/* T7 specs:
 *   - Analog I/O
 *     - 14 analog inputs (16-18 bit)
 *     - 14x single-ended or 7x differential
 *     - software gain x1, x10, x100, x1000
 *     - input range 10V, 1V, 0.1V, 0.01V
 *     - 2 analog outputs (12 bit, 0-5V)
 *     - user-defined slope + offset
 *   - Digital I/O
 *     - 23 digital I/O
 *     - maximum input rate 100 kHz
 *     - PWM output w/ phase (1-32 bit)
 *     - Pulse output w/ phase
 *     - Edge capture + compare
 *     - PWM measure
 *     - High-speed counters
 */

#define kNumT7DacChannels 2
#define kNumT7AdcChannels (14+2)  // two extra channels (temp+noise)
#define kNumT7IOChannels  23
#define kNumT7Counters    4
#define kNumT7Clocks      3

#define kLabJackT7DataSize 34  // see ORLabJackT7Decoders.m


@interface ORLabJackT7Model : OrcaObject <ORAdcProcessing,ORBitProcessing> {
    NSLock* localLock;
    BOOL  enabled[kNumT7AdcChannels];
    double adc[kNumT7AdcChannels];
    int    adcRange[kNumT7AdcChannels];
    int    adcRes[kNumT7AdcChannels];
    float  lowLimit[kNumT7AdcChannels];
    float  hiLimit[kNumT7AdcChannels];
    float  minValue[kNumT7AdcChannels];
    float  maxValue[kNumT7AdcChannels];
    float  slope[kNumT7AdcChannels];
    float  intercept[kNumT7AdcChannels];
    NSString* channelName[kNumT7AdcChannels];   //adc names
    NSString* channelUnit[kNumT7AdcChannels];   //adc names
    uint32_t timeMeasured;
    NSString* doName[kNumT7IOChannels];  //dio names
    uint32_t adcDiff;  // bitmask
    uint32_t doDirection;  // bitmask
    uint32_t doValueOut;  // bitmask
    uint32_t doValueIn;  // bitmask
    unsigned short aOut0;
    unsigned short aOut1;
    BOOL	led;
    BOOL    counterEnabled[kNumT7Counters];
    BOOL	doResetOfCounter[kNumT7Counters];
    //BOOL    clockEnabled[kNumT7Clocks];
    uint64_t counter[kNumT7Counters];
    BOOL digitalOutputEnabled;
    BOOL pwmOutputEnabled;
    uint32_t rtcTime;
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
    int   deviceHandle;
    int   deviceSerialNumber;
    DeviceCalibrationT7 caliInfo;

}

#pragma mark ***Accessors
- (int) deviceSerialNumber;
- (void) setDeviceSerialNumber:(int)aDeviceSerialNumber;
- (int)  deviceHandle;
- (BOOL) deviceOpen;
- (void) openDevice;
- (void) closeDevice;
- (void) setDeviceHandle:(int)aDeviceHandle;
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
- (uint64_t) counter:(unsigned short)chan;
- (void) setCounter:(unsigned short)chan withValue:(uint64_t)aCounter;
- (NSString*) channelName:(unsigned short)chan;
- (void) setChannel:(unsigned short)chan name:(NSString*)aName;
- (NSString*) channelUnit:(unsigned short)chan;
- (void) setChannel:(unsigned short)chan unit:(NSString*)aName;
- (NSString*) doName:(unsigned short)chan;
- (void) setDo:(unsigned short)chan name:(NSString*)aName;
- (double) adc:(unsigned short)chan;
- (void) setAdc:(unsigned short)chan withValue:(double)aValue;
- (float)adcConvertedRange:(unsigned short)chan;
- (int) adcRange:(unsigned short)chan;
- (void) setAdcRange:(unsigned short)chan withValue:(int)aValue;
- (int)adcConvertedRes:(unsigned short)chan;
- (int) adcRes:(unsigned short)chan;
- (void) setAdcRes:(unsigned short)chan withValue:(int)aValue;
- (float) lowLimit:(unsigned short)chan;
- (void) setLowLimit:(unsigned short)chan withValue:(float)aValue;
- (float) hiLimit:(unsigned short)chan;
- (void) setHiLimit:(unsigned short)chan withValue:(float)aValue;
- (float) slope:(unsigned short)chan;
- (void) setSlope:(unsigned short)chan withValue:(float)aValue;
- (float) intercept:(unsigned short)chan;
- (void) setIntercept:(unsigned short)chan withValue:(float)aValue;
- (float) minValue:(unsigned short)chan;
- (void) setMinValue:(unsigned short)chan withValue:(float)aValue;
- (float) maxValue:(unsigned short)chan;
- (void) setMaxValue:(unsigned short)chan withValue:(float)aValue;

- (unsigned short) adcDiff;
- (void) setAdcDiff:(unsigned short)aMask;
- (void) setAdcDiffBit:(int)bit withValue:(BOOL)aValue;

- (uint32_t) doDirection;
- (void) setDoDirection:(uint32_t)aMask;
- (void) setDoDirectionBit:(int)bit withValue:(BOOL)aValue;

- (uint32_t) doValueOut;
- (void) setDoValueOut:(uint32_t)aMask;
- (void) setDoValueOutBit:(int)bit withValue:(BOOL)aValue;

- (uint32_t) doValueIn;
- (void) setDoValueIn:(uint32_t)aMask;
- (void) setDoValueInBit:(int)bit withValue:(BOOL)aValue;
- (NSString*) doInString:(int)bit;
- (NSColor*) doInColor:(int)bit;

- (uint32_t) rtcTime;
- (void) setRtcTime:(uint32_t)aValue;

- (uint32_t) timeMeasured;

- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherLakeShore210;
- (int) readSerialNumbers;
- (void) shipTheData;

- (BOOL) pwmOutputEnabled;
- (void) setPwmOutputEnabled:(BOOL)aValue;

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

extern NSString* ORLabJackT7ModelDeviceSerialNumberChanged;
extern NSString* ORLabJackT7ModelDeviceHandleChanged;
extern NSString* ORLabJackT7ModelInvolvedInProcessChanged;
extern NSString* ORLabJackT7ModelAOut1Changed;
extern NSString* ORLabJackT7ModelAOut0Changed;
extern NSString* ORLabJackT7ShipDataChanged;
extern NSString* ORLabJackT7PollTimeChanged;
extern NSString* ORLabJackT7EnabledChanged;
extern NSString* ORLabJackT7DigitalOutputEnabledChanged;
extern NSString* ORLabJackT7DigitalOutputCounterEnabledChanged;
extern NSString* ORLabJackT7PwmOutputEnabledChanged;
extern NSString* ORLabJackT7CounterChanged;
extern NSString* ORLabJackT7RelayChanged;
extern NSString* ORLabJackT7Lock;
extern NSString* ORLabJackT7ChannelNameChanged;
extern NSString* ORLabJackT7ChannelUnitChanged;
extern NSString* ORLabJackT7AdcChanged;
extern NSString* ORLabJackT7DoNameChanged;
extern NSString* ORLabJackT7DoDirectionChanged;
extern NSString* ORLabJackT7DoValueOutChanged;
extern NSString* ORLabJackT7DoValueInChanged;
extern NSString* ORLabJackT7HiLimitChanged;
extern NSString* ORLabJackT7LowLimitChanged;
extern NSString* ORLabJackT7AdcDiffChanged;
extern NSString* ORLabJackT7AdcRangeChanged;
extern NSString* ORLabJackT7AdcResChanged;
extern NSString* ORLabJackT7SlopeChanged;
extern NSString* ORLabJackT7InterceptChanged;
extern NSString* ORLabJackT7MinValueChanged;
extern NSString* ORLabJackT7MaxValueChanged;
extern NSString* ORLabJackT7CounterEnabledChanged;
extern NSString* ORLabJackT7RtcTimeChanged;
extern NSString* ORLabJackT7CalibrationInfoChanged;

@interface ORLabJackT7Query : NSOperation
{
    id delegate;
}
- (id) initWithDelegate:(id)aDelegate;
- (void) main;
@end
