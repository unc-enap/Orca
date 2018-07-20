//
//  ORLabJackUE9Model.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 11,2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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

#import "ORAdcProcessing.h"
#import "ORBitProcessing.h"
#import "OROrderedObjHolding.h"
#import "ORGroup.h"

@class ORSafeQueue;
@class NetSocket;
@class ORLabJackUE9Cmd;
@class ORAlarm;

#define kUE9NumAdcs		84
#define kUE9NumTimers	6
#define kUE9NumIO		20

#define kUE9ReadCounters	0x0
#define kUE9UpdateCounters  0x1
#define kUE9ResetCounters	0x2

@interface ORLabJackUE9Model : ORGroup <OROrderedObjHolding,ORAdcProcessing,ORBitProcessing> {
    ORAlarm* socketClosedAlarm;
	NSOperationQueue* queue;
	ORSafeQueue*   cmdQueue;
	ORLabJackUE9Cmd*  lastRequest;
	NSString*		  ipAddress;
    BOOL			  isConnected;
	NetSocket*		  socket;
	NSLock*			  localLock;
    NSString*		  serialNumber;
	float             adc[kUE9NumAdcs];
	int               gain[kUE9NumAdcs];
	BOOL              bipolar[kUE9NumAdcs];
	float             lowLimit[kUE9NumAdcs];
	float             hiLimit[kUE9NumAdcs];
	float             minValue[kUE9NumAdcs];
	float             maxValue[kUE9NumAdcs];
	float             slope[kUE9NumAdcs];
	float             intercept[kUE9NumAdcs];
	NSString*         channelName[kUE9NumAdcs];   //adc names
	NSString*         channelUnit[kUE9NumAdcs];   //adc names
	NSString*         doName[kUE9NumIO];		//the D connector on the side
	uint32_t     timeMeasured;
	uint32_t     doDirection;
	uint32_t     doValueOut;
	uint32_t     doValueIn;
    unsigned short    aOut0;
    unsigned short    aOut1;
    uint32_t     adcEnabledMask[3];
    uint32_t     counter[2];
    uint32_t     timer[kUE9NumTimers];
    uint32_t     timerResult[kUE9NumTimers];
    BOOL              digitalOutputEnabled;
    int               pollTime;
	uint32_t	  dataId;
    BOOL              shipData;
	NSTimeInterval    lastTime;
    uint32_t     timerOption[kUE9NumTimers];
    unsigned short    timerEnableMask;
    unsigned short    counterEnableMask;
    int               clockSelection;
    int               clockDivisor;
    int				  localID;
	
	double unipolarSlope[4];
	double unipolarOffset[4];
	double bipolarSlope;
	double bipolarOffset;
	double DACSlope[2];
	double DACOffset[2];
	double tempSlope;
	double tempSlopeLow;
	double calTemp;
	double Vref;
	double VrefDiv2;
	double VsSlope;
	double hiResUnipolarSlope;
	double hiResUnipolarOffset;
	double hiResBipolarSlope;
	double hiResBipolarOffset;
	BOOL verbose;
    
	//bit processing variables
    BOOL            readOnce;
	uint32_t   processInputValue;  //snapshot of the inputs at start of process cycle
	uint32_t   processOutputValue; //outputs to be written at end of process cycle
	uint32_t   processOutputMask;  //controlls which bits are written
    BOOL            involvedInProcess;
    BOOL			wasConnected;
}

#pragma mark ***Accessors
- (int) localID;
- (void) setLocalID:(int)aLocalID;
- (int)  clockDivisor;
- (void) setClockDivisor:(int)aClockDivisor;
- (int)  clockSelection;
- (void) setClockSelection:(int)aClockSelection;
- (unsigned short) counterEnableMask;
- (void) setCounterEnableMask:(unsigned short)anEnableMask;
- (void) setCounterEnableBit:(int)bit value:(BOOL)aValue;
- (unsigned short) timerEnableMask;
- (void) setTimerEnableMask:(unsigned short)anEnableMask;
- (void) setTimerEnableBit:(int)bit value:(BOOL)aValue;
- (unsigned short) timerOption:(int)index;
- (void) setTimer:(int)index option:(unsigned short)aTimerOption;
- (ORLabJackUE9Cmd*) lastRequest;
- (void) setLastRequest:(ORLabJackUE9Cmd*)aRequest;
- (BOOL) involvedInProcess;
- (void) setInvolvedInProcess:(BOOL)aInvolvedInProcess;
- (unsigned short) aOut1;
- (void) setAOut1:(unsigned short)aAOut1;
- (unsigned short) aOut0;
- (void) setAOut0:(unsigned short)aAOut0;
- (BOOL) shipData;
- (void) setShipData:(BOOL)aShipData;
- (int)  pollTime;
- (void) setPollTime:(int)aPollTime;
- (BOOL) digitalOutputEnabled;
- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled;
- (uint32_t) counter:(int)i;
- (void) setCounter:(int)i value:(uint32_t)aValue;
- (uint32_t) timer:(int)i;
- (uint32_t) timerResult:(int)i;
- (void) setTimerResult:(int)i value:(uint32_t)aValue;
- (void) setTimer:(int)i value:(uint32_t)aValue;
- (NSString*) channelName:(int)i;
- (void) setChannel:(int)i name:(NSString*)aName;
- (NSString*) channelUnit:(int)i;
- (void) setChannel:(int)i unit:(NSString*)aName;
- (NSString*) doName:(int)i;
- (void)  setDo:(int)i name:(NSString*)aName;
- (float) adc:(int)i;
- (void)  setAdc:(int)i value:(float)aValue;
- (int)   gain:(int)i;
- (void)  setGain:(int)i value:(int)aValue;
- (BOOL)  bipolar:(int)i;
- (void)  setBipolar:(int)i value:(BOOL)aValue;
- (float) lowLimit:(int)i;
- (void)  setLowLimit:(int)i value:(float)aValue;
- (float) hiLimit:(int)i;
- (void)  setHiLimit:(int)i value:(float)aValue;
- (float) slope:(int)i;
- (void)  setSlope:(int)i value:(float)aValue;
- (float) intercept:(int)i;
- (void)  setIntercept:(int)i value:(float)aValue;
- (float) minValue:(int)i;
- (void)  setMinValue:(int)i value:(float)aValue;
- (float) maxValue:(int)i;
- (void)  setMaxValue:(int)i value:(float)aValue;

- (uint32_t) doDirection;
- (void) setDoDirection:(uint32_t)aMask;
- (void) setDoDirectionBit:(int)bit value:(BOOL)aValue;

- (uint32_t) doValueOut;
- (void) setDoValueOut:(uint32_t)aMask;
- (void) setDoValueOutBit:(int)bit value:(BOOL)aValue;
- (void) setOutputBit:(int)bit value:(BOOL) aValue;

- (unsigned short) doValueIn;
- (void) setDoValueIn:(uint32_t)aMask;
- (void) setDoValueInBit:(int)bit value:(BOOL)aValue;
- (NSString*) doInString:(int)bit;
- (NSColor*) doInColor:(int)i;

- (uint32_t) adcEnabledMask:(int)aGroup;
- (BOOL) adcEnabled:(int)adcChan;
- (void) setAdcEnabled:(int)aGroup mask:(uint32_t)anEnableMask;
- (void) setAdcEnabled:(int)bit value:(BOOL)aValue;
- (int) muxIndexFromAdcIndex:(int)adcIndex;
- (int) adcIndexFromMuxIndex:(int)muxIndex;

- (uint32_t) timeMeasured;

- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherLakeShore210;

#pragma mark ***IP Stuff
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aFlag;
- (void) connect;
- (void) netsocketConnected:(NetSocket*)inNetSocket;
- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount;
- (void) netsocketDisconnected:(NetSocket*)inNetSocket;

#pragma mark ***HW Access
- (void) resetCounter;
- (void) sendComCmd:(BOOL)aVerbose;
- (void) getCalibrationInfo:(int)block;
- (void) readAllValues;
- (void) sendTimerCounter:(int)opt;
- (void) queryAll;
- (void) pollHardware;
- (void) pollHardware:(BOOL)force;
- (void) changeIPAddress:(NSString*)aNewAddress;
- (void) changeLocalID:(unsigned char)newLocalID;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

- (void) goToNextCommand;
- (void) processOneCommandFromQueue;
- (void) startTimeOut;

#pragma mark •••Adc Processing Protocol
- (void) processIsStarting;
- (void) processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel;
- (double) convertedValue:(int)channel;
- (double) maxValueForChan:(int)channel;
- (BOOL) CB37Exists:(int)aSlot;
- (void) printChannelLocations;

#pragma mark •••OROrderedObjHolding Protocol
- (int) maxNumberOfObjects;
- (int) objWidth;	
- (int) groupSeparation;
- (NSString*) nameForSlot:(int)aSlot;
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj;
- (NSRange) legalSlotsForObj:(id)anObj;
- (int) slotAtPoint:(NSPoint)aPoint; 
- (NSPoint) pointForSlot:(int)aSlot; 
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;

@end

extern NSString* ORLabJackUE9ModelLocalIDChanged;
extern NSString* ORLabJackUE9ModelClockDivisorChanged;
extern NSString* ORLabJackUE9ModelClockSelectionChanged;
extern NSString* ORLabJackUE9ModelTimerEnableMaskChanged;
extern NSString* ORLabJackUE9ModelTimerOptionChanged;
extern NSString* ORLabJackUE9ModelInvolvedInProcessChanged;
extern NSString* ORLabJackUE9ModelAOut1Changed;
extern NSString* ORLabJackUE9ModelAOut0Changed;
extern NSString* ORLabJackUE9ShipDataChanged;
extern NSString* ORLabJackUE9PollTimeChanged;
extern NSString* ORLabJackUE9DigitalOutputEnabledChanged;
extern NSString* ORLabJackUE9CounterChanged;
extern NSString* ORLabJackUE9RelayChanged;
extern NSString* ORLabJackUE9Lock;
extern NSString* ORLabJackUE9ChannelNameChanged;
extern NSString* ORLabJackUE9ChannelUnitChanged;
extern NSString* ORLabJackUE9AdcChanged;
extern NSString* ORLabJackUE9DoNameChanged;
extern NSString* ORLabJackUE9DoDirectionChanged;
extern NSString* ORLabJackUE9DoValueOutChanged;
extern NSString* ORLabJackUE9DoValueInChanged;
extern NSString* ORLabJackUE9IoValueInChanged;
extern NSString* ORLabJackUE9HiLimitChanged;
extern NSString* ORLabJackUE9LowLimitChanged;
extern NSString* ORLabJackUE9GainChanged;
extern NSString* ORLabJackUE9SlopeChanged;
extern NSString* ORLabJackUE9InterceptChanged;
extern NSString* ORLabJackUE9MinValueChanged;
extern NSString* ORLabJackUE9MaxValueChanged;
extern NSString* ORLabJackUE9IpAddressChanged;
extern NSString* ORLabJackUE9IsConnectedChanged;
extern NSString* ORLabJackUE9TimerChanged;
extern NSString* ORLabJackUE9BipolarChanged;
extern NSString* ORLabJackUE9ModelCounterEnableMaskChanged;
extern NSString* ORLabJackUE9ModelTimerResultChanged;
extern NSString* ORLabJackUE9ModelAdcEnableMaskChanged;

@interface ORLabJackUE9Cmd : NSObject
{
	int tag;
	NSData* cmdData;
}
@property (nonatomic,assign) int tag;
@property (nonatomic,retain) NSData* cmdData;
@end

