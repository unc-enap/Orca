//
//  ORAmrelHVModel.h
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark •••Imported Files

#import "OrcaObject.h"

#define kNumAmrelHVChannels 2

#define kAmrelHVNotRamping		0
#define kAmrelHVRampStarting	1
#define kAmrelHVRampingUp		2
#define kAmrelHVRampingDn		3

@class ORSerialPort;

@interface ORAmrelHVModel : OrcaObject
{
	uint32_t		dataValidMask[2];
	NSString*			portName;
	BOOL				portWasOpen;
	ORSerialPort*		serialPort;
	NSString*			lastRequest;
	NSMutableArray*		cmdQueue;
	NSMutableData*		inComingData;
	NSMutableString*    buffer;
	uint32_t		dataId;
	int					pollTime;
    BOOL				outputState[2];
	float				voltage[2];
	float				actVoltage[2];
	float				actCurrent[2];
	float				maxCurrent[2];
	BOOL				polarity[2];
	float				rampRate[2];
	BOOL				statusChanged[2]; 
    int					numberOfChannels;
    BOOL				rampEnabled[2];
    int					rampState[2];
	NSDate*				lastRampStep[2];
	BOOL				doSync[2];
	
	//used for calculating percent of ramp done only.
	float				targetVoltage[2];
	float				startVoltage[2];
	float				startDelta[2];
}

#pragma mark ***Accessors
- (BOOL) allDataIsValid:(unsigned short)aChan;

- (BOOL) channelIsValid:(unsigned short)aChan;
- (int)  rampState:(unsigned short)aChan;
- (BOOL) rampEnabled:(unsigned short)aChan;
- (void) setRampEnabled:(unsigned short)aChan withValue:(BOOL)aRampEnabled;
- (BOOL) outputState:(unsigned short)aChan;
- (void) setOutputState:(unsigned short)aChan withValue:(BOOL)aOutputState;
- (float) rampRate:(unsigned short)aChan;
- (void) setRampRate:(unsigned short)aChan withValue:(float)aRate;
- (int) numberOfChannels;
- (void) setNumberOfChannels:(int)aNumberOfChannels;
- (float) voltage:(unsigned short) aChan;
- (void)  setVoltage:(unsigned short) aChan withValue:(float) aVoltage;
- (float) actVoltage:(unsigned short) aChan;
- (float) actCurrent:(unsigned short) aChan;
- (void)  setActCurrent:(unsigned short) aChan withValue:(float) aCurrent;
- (BOOL) polarity:(unsigned short) aChan;
- (void)  setPolarity:(unsigned short) aChan withValue:(BOOL) aState;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (float) maxCurrent:(unsigned short) aChan;
- (void) setMaxCurrent:(unsigned short) aChan withValue:(float) aCurrent;

- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherSupply;

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
- (void) syncDialog;
- (float) rampProgress:(unsigned short)aChannel;

#pragma mark •••Header Stuff
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSDictionary*) dataRecordDescription;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark •••HW Commands
- (void) togglePower:(unsigned short)aChannel;
- (void) clearCurrentTrip:(unsigned short)aChannel;
- (void) getID;
- (void) getActualVoltage:(unsigned short)aChannel;
- (void) getActualCurrent:(unsigned short)aChannel;
- (void) getOutput:(unsigned short)aChannel;
- (void) setOutput:(unsigned short)aChannel withValue:(BOOL)aState;
- (void) dataReceived:(NSNotification*)note;
- (void) loadHardware:(unsigned short)aChannel;
- (void) pollHardware;
- (void) getAllValues;
- (void) clearCurrentTrip:(unsigned short)aChannel;

- (void) shipVoltageRecords;
- (void) stopRamp:(unsigned short)aChan;
- (void) panicToZero:(unsigned short)aChan;

#pragma mark ***Utilities
- (void) sendCmd:(NSString*)aCommand;
- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel;
- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel value:(float)aValue;
- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel boolValue:(BOOL)aValue;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORAmrelHVModelRampStateChanged;
extern NSString* ORAmrelHVModelRampEnabledChanged;
extern NSString* ORAmrelHVModelOutputStateChanged;
extern NSString* ORAmrelHVModelNumberOfChannelsChanged;
extern NSString* ORAmrelHVSetVoltageChanged;
extern NSString* ORAmrelHVActVoltageChanged;
extern NSString* ORAmrelHVPollTimeChanged;
extern NSString* ORAmrelHVActCurrentChanged;
extern NSString* ORAmrelHVMaxCurrentChanged;
extern NSString* ORAmrelHVModelDataIsValidChanged;

extern NSString* ORAmrelHVLock;
extern NSString* ORAmrelHVModelSerialPortChanged;
extern NSString* ORAmrelHVModelPortStateChanged;
extern NSString* ORAmrelHVModelPortNameChanged;
extern NSString* ORAmrelHVModelPolarityChanged;
extern NSString* ORAmrelHVModelRampRateChanged;
extern NSString* ORAmrelHVModelTimeout;

