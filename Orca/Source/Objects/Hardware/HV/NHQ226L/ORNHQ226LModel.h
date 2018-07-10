// ORNHQ226LModel.h
// Orca
//
//  Created by Mark Howe on Tues Sept 14,2010.
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

@class ORSerialPort;

#pragma mark •••Register Definitions
enum {
    kStatusRegister1,		//0 	
    kSetVoltageA,			//1 	
    kSetVoltageB,			//2 	
    kRampSpeedA,			//3 	
    kRampSpeedB,			//4     
    kActVoltageA,			//5 	
    kActVoltageB,			//6 	
    kActCurrentA,			//7 	
    kActCurrentB,			//8 	
    kLimitsA,				//9 	
    kLimitsB,				//10 	
    kStatusRegister2,		//11 	
    kStartVoltA,			//12 	
    kStartVoltB,			//13 	
    kModID,					//14 	
    kSetCurrTripA,			//15 	
    kSetCurrTripB,			//16 	
    kNumberOfNHQ226LSRegisters			//must be last
};

#define kNumNHQ226LChannels 2

//status 1 word bits
#define kQuality 	0x80
#define kError		0x40
#define kInhibit	0x20
#define kKillSwitch 0x10
#define kHVSwitch	0x08
#define kHVPolarity	0x04
#define kHVControl	0x02
#define kDailed		0x01

//status 2 word values
#define kHVIsOn     0x1
#define kHVIsOff    0x2
#define kLowToHigh  0x3
#define kHighToLow  0x4
#define kManual     0x5
#define kErr        0x6
#define kInh        0x7
#define kTrip       0x8

typedef enum eNHQ226LRampingState {
	kHVOff,     
	kHVStableLow,     
	kHVStableHigh,     
	kHVRampingUp,  
	kHVRampingDn 
}eNHQ226LRampingState;

@interface ORNHQ226LModel :  OrcaObject
{
    @private
		NSString*			portName;
		BOOL				portWasOpen;
		ORSerialPort*		serialPort;
		NSString*			lastRequest;
		NSMutableArray*		cmdQueue;
		NSMutableData*		inComingData;
		NSMutableString*    buffer;		
		int pollTime;
		unsigned long dataId;
		float voltage[2];
		float actVoltage[2];
		float actCurrent[2];
		float maxCurrent[2];
		float maxVoltage[2];
		unsigned short rampRate[2];
		unsigned short statusReg1Chan[2];
		unsigned short statusReg2Chan[2];
		BOOL timeOutError;
		BOOL useStatusReg1Anyway[2];
		BOOL statusChanged; 
		BOOL pollingError;
		BOOL doSync[2];
}

#pragma mark •••Accessors
- (BOOL) pollingError;
- (void) setPollingError:(BOOL)aPollingError;
- (void) setTimeErrorState:(BOOL)aState;
- (unsigned short) statusReg1Chan:(unsigned short)aChan;
- (void) setStatusReg1Chan:(unsigned short)aChan withValue:(unsigned short)aStatusWord;
- (unsigned short) statusReg2Chan:(unsigned short)aChan;
- (void) setStatusReg2Chan:(unsigned short)aChan withValue:(unsigned short)aStatusWord;
- (float) voltage:(unsigned short) aChan;
- (void)  setVoltage:(unsigned short) aChan withValue:(float) aVoltage;
- (float) actVoltage:(unsigned short) aChan;
- (void)  setActVoltage:(unsigned short) aChan withValue:(float) aVoltage;
- (float) actCurrent:(unsigned short) aChan;
- (void)  setActCurrent:(unsigned short) aChan withValue:(float) aCurrent;
- (unsigned short) rampRate:(unsigned short) aChan;
- (void) setRampRate:(unsigned short) aChan withValue:(unsigned short) aRampRate;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (float) maxCurrent:(unsigned short) aChan;
- (void)  setMaxCurrent:(unsigned short) aChan withValue:(float) aValue;
- (float) maxVoltage:(unsigned short) aChan;
- (void)  setMaxVoltage:(unsigned short) aChan withValue:(float) aValue;
- (NSString*) status2String:(unsigned short)aChan;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;

#pragma mark •••Serial Port
- (ORSerialPort*) serialPort;
- (void) setSerialPort:(ORSerialPort*)aSerialPort;
- (BOOL) portWasOpen;
- (void) setPortWasOpen:(BOOL)aPortWasOpen;
- (NSString*) portName;
- (void) setPortName:(NSString*)aPortName;
- (NSString*) lastRequest;
- (void) setLastRequest:(NSString*)aRequest;
- (void) openPort:(BOOL)state;
- (void) serialPortWriteProgress:(NSDictionary *)dataDictionary;
- (void) dataReceived:(NSNotification*)note;
- (void) timeout;
- (void) processOneCommandFromQueue;
- (void) syncDialog;
- (void) getAllValues;
- (void) sendCmd:(NSString*)aCommand;
- (void) decode:(NSArray*)parts;
- (void) decodeStatus:(NSString*)s channel:(int)aChan;

#pragma mark •••HW Access
- (void) initBoard;
- (void) readModuleID;
- (void) readStatusWord:(unsigned short)aChan;
- (void) readModuleStatus:(unsigned short)aChan;
- (void) pollHardware;
- (void) readActVoltage:(unsigned short)aChan;
- (void) readActCurrent:(unsigned short)aChan;
- (void) stopRamp:(unsigned short)aChan;

#pragma mark •••RecordShipper
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) shipVoltageRecords;

#pragma mark •••Helpers
- (NSString*) rampStateString:(unsigned short)aChannel;
- (eNHQ226LRampingState) rampingState:(unsigned short)aChan;
- (BOOL) polarity:(unsigned short)aChannel;
- (BOOL) hvPower:(unsigned short)aChannel;
- (BOOL) controlState:(unsigned short)aChannel;
- (void) loadValues:(unsigned short)aChannel;
- (void) panicToZero:(unsigned short)aChannel;
- (BOOL) killSwitch:(unsigned short)aChannel;
- (BOOL) currentTripped:(unsigned short)aChannel;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

#pragma mark •••External String Definitions
extern NSString* ORNHQ226LModelPollingErrorChanged;
extern NSString* ORNHQ226LModelStatusReg1Changed;
extern NSString* ORNHQ226LModelStatusReg2Changed;
extern NSString* ORNHQ226LChan;
extern NSString* ORNHQ226LSettingsLock;
extern NSString* ORNHQ226LSetVoltageChanged;
extern NSString* ORNHQ226LActVoltageChanged;
extern NSString* ORNHQ226LRampRateChanged;
extern NSString* ORNHQ226LPollTimeChanged;
extern NSString* ORNHQ226LModelTimeOutErrorChanged;
extern NSString* ORNHQ226LActCurrentChanged;
extern NSString* ORNHQ226LMaxCurrentChanged;
extern NSString* ORNHQ226LModelSerialPortChanged;
extern NSString* ORNHQ226LModelPortNameChanged;
extern NSString* ORNHQ226LModelPortStateChanged;
extern NSString* ORNHQ226LModelTimeout;
extern NSString* ORNHQ226LMaxVoltageChanged;

