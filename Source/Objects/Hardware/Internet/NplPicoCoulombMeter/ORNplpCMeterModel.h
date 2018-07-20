//
//  ORNplpCMeterModel.h
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORAdcProcessing.h"

#define kNplpCMeterPort 5000
#define kNplpCNumChannels 4
#define kNplpCStart  "B"
#define kNplpCStop	 "Q"

@class NetSocket;
@class ORAlarm;
@class ORQueue;

@interface ORNplpCMeterModel : OrcaObject <ORAdcProcessing>
{
	NSLock* localLock;
    NSString* ipAddress;
    BOOL isConnected;
	NetSocket* socket;
    uint32_t dataId;
	NSMutableData* meterData;
	int frameError;
	ORQueue* dataStack[kNplpCNumChannels];
	float meterAverage[kNplpCNumChannels];
    unsigned short receiveCount;
    
    float           lowLimit[kNplpCNumChannels];
    float           hiLimit[kNplpCNumChannels];
    float           minValue[kNplpCNumChannels];
    float           maxValue[kNplpCNumChannels];

}

#pragma mark ***Accessors
- (unsigned short) receiveCount;
- (void) setReceiveCount:(unsigned short)aCount;
- (unsigned int) frameError;
- (void) setFrameError:(unsigned int)aValue;
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aFlag;
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) aDataId;
- (void) appendMeterData:(NSData*)someData;
- (BOOL) validateMeterData;
- (void) averageMeterData;
- (void) setMeter:(int)chan average:(float)aValue;
- (float) meterAverage:(unsigned short)aChannel;
- (void) restart;
- (float) lowLimit:(int)i;
- (void)  setLowLimit:(int)i value:(float)aValue;
- (float) hiLimit:(int)i;
- (void)  setHiLimit:(int)i value:(float)aValue;
- (float) minValue:(int)i;
- (void)  setMinValue:(int)i value:(float)aValue;
- (float) maxValue:(int)i;
- (void)  setMaxValue:(int)i value:(float)aValue;

#pragma mark ***Utilities
- (void) connect;
- (void) start;
- (void) stop;

#pragma mark •••DataRecords
- (NSDictionary*) dataRecordDescription;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (void) shipValues;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Bit Processing Protocol
- (void) processIsStarting;
- (void) processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;

- (NSString*) identifier;
- (NSString*) processingTitle;
- (double) convertedValue:(int)aChan;
- (double) maxValueForChan:(int)aChan;
- (double) minValueForChan:(int)aChan;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel;
- (void) setProcessOutput:(int)aChan value:(int)aValue;
- (BOOL) processValue:(int)channel;

@end

extern NSString* ORNplpCMeterReceiveCountChanged;
extern NSString* ORNplpCMeterIsConnectedChanged;
extern NSString* ORNplpCMeterIpAddressChanged;
extern NSString* ORNplpCMeterAverageChanged;
extern NSString* ORNplpCMeterFrameError;
extern NSString* ORNplpCMeterMinValueChanged;
extern NSString* ORNplpCMeterMaxValueChanged;
extern NSString* ORNplpCMeterHiLimitChanged;
extern NSString* ORNplpCMeterLowLimitChanged;
extern NSString* ORNplpCMeterLock;