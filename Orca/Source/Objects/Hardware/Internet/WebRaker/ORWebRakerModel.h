//
//  ORWebRakerModel.h
//  Orca
//
//  Created by Mark Howe on Mon Jan 11 2016
//  Copyright (c) 2016 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States
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

#define kWebRakerPollTime       60

@class ORAlarm;
@class ORTimeRate;

@interface ORWebRakerModel : OrcaObject <ORAdcProcessing>
{
    NSString*            ipAddress;
    NSDate*              lastTimePolled;
    NSDate*              nextPollScheduled;
    BOOL                 dataValid;
    ORAlarm*             dataInValidAlarm;
    NSArray*             data;
    NSMutableArray*      lowLimits;
    NSMutableArray*      hiLimits;
    NSMutableArray*      minValues;
    NSMutableArray*      maxValues;
    NSMutableArray*      timeRates;
    unsigned int         pollTime;
}

#pragma mark ***Accessors
- (unsigned int) pollTime;
- (void) setPollTime:(unsigned int)aPollTime;
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;
- (ORTimeRate*)timeRate:(int)aChannel;
- (void) setDataValid:(BOOL)aState;

#pragma mark ***Utilities
- (void) pollHardware;
- (void) processData:(NSData*)theData;
- (NSInteger) numDataItems;
- (NSDictionary*) dataAtIndex:(int)index;

- (void) checkAlarms;

#pragma mark •••Process Limits
- (float) lowLimit:(int)i;
- (void)  setLowLimit:(int)i value:(float)aValue;
- (float) hiLimit:(int)i;
- (void)  setHiLimit:(int)i value:(float)aValue;

- (float) minValue:(int)i;
- (void)  setMinValue:(int)i value:(float)aValue;
- (float) maxValue:(int)i;
- (void)  setMaxValue:(int)i value:(float)aValue;

#pragma mark •••Bit Processing Protocol
- (void) startProcessCycle;
- (void) endProcessCycle;
- (void) processIsStarting;
- (void) processIsStopping;
- (NSString*) identifier;
- (NSString*) processingTitle;
- (BOOL) processValue:(int)channel;
- (double) convertedValue:(int)aChan;
- (void) setProcessOutput:(int)aChan value:(int)aValue;
- (double) maxValueForChan:(int)aChan;
- (double) minValueForChan:(int)aChan;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@property (assign,nonatomic) BOOL dataValid;
@property (retain,nonatomic) NSDate* lastTimePolled;
@property (retain,nonatomic) NSDate* nextPollScheduled;
@end

extern NSString* ORWebRakerIpAddressChanged;
extern NSString* ORWebRakerPollingTimesChanged;
extern NSString* ORWebRakerDataValidChanged;
extern NSString* ORWebRakerLock;
extern NSString* ORWebRakerHiLimitChanged;
extern NSString* ORWebRakerLowLimitChanged;
extern NSString* ORWebRakerValueChanged;
extern NSString* ORWebRakerMinValueChanged;
extern NSString* ORWebRakerMaxValueChanged;

