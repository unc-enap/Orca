//
//  MJDPreAmpModel.h
//  Orca
//
//  Created by Mark Howe on Wed Jan 18 2012.
//  Copyright © 2012 University of North Carolina. All rights reserved.
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

#pragma mark ¥¥¥Imported Files
#import "ORHWWizard.h"
#import "MJDCmds.h"
#import "ORAuxHw.h"
#import "ORRunningAverageGroup.h"

@class ORTimeRate;
@class ORAlarm;
@class ORRunningAverageGroup;

#define kMJDPreAmpDacChannels               16	//if this ever changes, change the record length also
#define kMJDPreAmpAdcChannels               16
#define kMJDPreAmpLeakageCurrentChannels    10
#define kMJDPreAmpDataRecordLen             20

@interface ORMJDPreAmpModel : ORAuxHw {
    NSString*       detectorName[kMJDPreAmpAdcChannels];
    float           adcs[kMJDPreAmpAdcChannels];
    float           leakageCurrents[kMJDPreAmpLeakageCurrentChannels];
    NSMutableArray* feedBackResistors;
    NSMutableArray* baselineVoltages;
    NSMutableArray* dacs;
    NSMutableArray* amplitudes;
    unsigned short  pulserMask;
    int             pulseLowTime;
    int             pulseHighTime;
    BOOL            attenuated[2];
    BOOL            finalAttenuated[2];
    BOOL            enabled[2];
    unsigned short  pulseCount;
    BOOL            loopForever;
    int             pollTime;
    BOOL            shipValues;
	unsigned long	dataId;
	unsigned long   timeMeasured;
    unsigned long   adcEnabledMask;
    ORTimeRate*		adcHistory[kMJDPreAmpAdcChannels];
    ORTimeRate*		leakageCurrentHistory[kMJDPreAmpLeakageCurrentChannels];
    ORRunningAverageGroup* baselineRunningAverages;
    ORAlarm*		temperatureAlarm[2];
    ORAlarm*		leakageCurrentAlarm[kMJDPreAmpLeakageCurrentChannels];
    ORAlarm*		adcAlarm[kMJDPreAmpAdcChannels];
    BOOL            rangesHaveBeenSet;
    NSDate*         lastDataBaseUpdate;
    int             boardRev;
    BOOL            connected;
    BOOL            doNotUseHWMap;
    int             firmwareRev;
    BOOL            pollRequestInFlight;
    BOOL            connectedToANLCard;
    
    //error counting
    BOOL            supplyOutOfBounds[4]; //only count if this goes from low to high
    unsigned long   supplyErrors[4];
}

- (void) setUpArrays;
- (NSString*) connectedObjectName;
- (void) registerNotificationObservers;
- (void) hardwareMapChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (int) nMaxChannels;
- (int)  firmwareRev;
- (void) setFirmwareRev:(int)aFirmwareRev;
- (int)  boardRev;
- (void) setBoardRev:(int)aBoardRev;
- (NSString*) detectorName:(int)i;
- (void) setDetector:(int)i name:(NSString*)aName;
- (NSMutableArray*) feedBackResistors;
- (void) setFeedBackResistors:(NSMutableArray*)anArray;
- (float) feedBackResistor:(unsigned short) aChan;
- (void) setFeedBackResistor:(int) aChan value:(float) aValue;
- (NSMutableArray*) baselineVoltages;
- (void) setBaselineVoltages:(NSMutableArray*)anArray;
- (float) baselineVoltage:(unsigned short) aChan;
- (void) setBaselineVoltage:(int) aChan value:(float) aValue;
- (void) checkSupplyError:(int)anIndex postAlarm:(BOOL)aState;
- (void) clearSupplyErrors;
- (ORTimeRate*)adcHistory:(int)index;
- (ORTimeRate*)leakageCurrentHistory:(int)index;

//running averages
- (void) fakeASpike:(int) channel started:(BOOL)start;
- (void) baselineSpikeChanged:(NSNotification*)aNote;
- (void)  setBaselineRunningAverages:(ORRunningAverageGroup*)newRunningAverageGroup;

- (unsigned long) adcEnabledMask;
- (void) setAdcEnabledMask:(unsigned long)aAdcEnabledMask;
- (BOOL) shipValues;
- (void) setShipValues:(BOOL)aShipValues;
- (void) pollRequestIsFinished;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (float) adc:(unsigned short) aChan;
- (void) setAdc:(int) aChan value:(float) aValue;
- (void) setLeakageCurrent:(int) aChan value:(float) aValue;
- (BOOL) loopForever;
- (void) setLoopForever:(BOOL)aLoopForever;
- (unsigned short) pulseCount;
- (void) setPulseCount:(unsigned short)aPulseCount;
- (BOOL) enabled:(int)index;
- (void) setEnabled:(int)index value:(BOOL)aEnabled;
- (unsigned long) timeMeasured;

- (BOOL) attenuated:(int)index;
- (void) setAttenuated:(int)index value:(BOOL)aAttenuated;
- (BOOL) finalAttenuated:(int)index;
- (void) setFinalAttenuated:(int)index value:(BOOL)aAttenuated;
- (unsigned short) pulserMask;
- (void) setPulserMask:(unsigned short)aPulserMask;
- (int) pulseHighTime;
- (void) setPulseHighTime:(int)aPulseHighTime;
- (int) pulseLowTime;
- (void) setPulseLowTime:(int)aPulseLowTime;
- (NSMutableArray*) dacs;
- (void) setAmplitudes:(NSMutableArray*)anArray;
- (NSMutableArray*) amplitudes;
- (void) setDacs:(NSMutableArray*)anArray;
- (unsigned long) dac:(unsigned short) aChan;
- (void) setDac:(unsigned short) aChan withValue:(unsigned long) aValue;
- (unsigned long) amplitude:(int) aChan;
- (void) setAmplitude:(int) aChan withValue:(unsigned long) aValue;
- (BOOL) doNotUseHWMap;
- (void) setDoNotUseHWMap:(BOOL)aDoNotUseHWMap;

#pragma mark ¥¥¥Data Records
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSDictionary*) dataRecordDescription;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObject;
- (void) shipRecords;

#pragma mark ¥¥¥HW Access
- (BOOL) controllerIsSBC;
- (void) startPulser;
- (void) stopPulser;
- (void) writeFetVds:(int)index;
- (void) writeFetVdsToHW;
- (void) writeAmplitude:(int)index;
- (void) writeAmplitudes;
- (void) zeroAmplitudes;
- (void) writeAdcRanges;
- (void) readAllAdcs;
- (void) readAllAdcs:(BOOL)verbose;
- (void) pollValues;
- (unsigned long) writeAuxIOSPI:(unsigned long)aValue;
- (int) connectedGretinaCrate;
- (int) connectedGretinaSlot;

#pragma mark ¥¥¥Alarms
- (void) checkTempIsWithinLimits;
- (void) checkLeakageCurrentIsWithinLimits:(int)aChan;
- (void) checkAdcIsWithinLimits:(int)anIndex;

#pragma mark ¥¥¥Archival
- (id)      initWithCoder:(NSCoder*)aDecoder;
- (void)    encodeWithCoder:(NSCoder*)anEncoder;
@end

#pragma mark ¥¥¥External Strings
extern NSString* ORMJDPreAmpModelFirmwareRevChanged;
extern NSString* ORMJDPreAmpModelDoNotUseHWMapChanged;
extern NSString* ORMJDPreAmpModelBoardRevChanged;
extern NSString* ORMJDPreAmpModelAdcEnabledMaskChanged;
extern NSString*  ORMJDPreAmpModelPollTimeChanged;
extern NSString* ORMJDPreAmpModelShipValuesChanged;
extern NSString* ORMJDPreAmpLoopForeverChanged;
extern NSString* ORMJDPreAmpPulseCountChanged;
extern NSString* ORMJDPreAmpEnabledChanged;
extern NSString* ORMJDPreAmpAttenuatedChanged;
extern NSString* ORMJDPreAmpFinalAttenuatedChanged;
extern NSString* ORMJDPreAmpPulserMaskChanged;
extern NSString* ORMJDPreAmpPulseHighTimeChanged;
extern NSString* ORMJDPreAmpPulseLowTimeChanged;
extern NSString* ORMJDPreAmpDacArrayChanged;
extern NSString* ORMJDPreAmpAmplitudeArrayChanged;
extern NSString* MJDPreAmpSettingsLock;
extern NSString* ORMJDPreAmpDacChanged;
extern NSString* ORMJDPreAmpAmplitudeChanged;
extern NSString* ORMJDPreAmpAdcChanged;
extern NSString* ORMJDFeedBackResistorArrayChanged;
extern NSString* ORMJDBaselineVoltageArrayChanged;
extern NSString* ORMJDFeedBackResistorChanged;
extern NSString* ORMJDBaselineVoltageChanged;
extern NSString* ORMJDPreAmpModelDetectorNameChanged;
extern NSString* ORMJDPreAmpModelConnectionChanged;
extern NSString* ORMJDPreAmpModelDoNotUseHWMapChanged;
extern NSString* ORMJDPreAmpModelFirmwareRevChanged;
extern NSString* ORMJDPreAmpModelRateSpiked;

@interface NSObject (ORMJDPreAmpModel)
- (unsigned long) writeAuxIOSPI:(unsigned long)spiData;
- (id) adapter;
- (id) sbcLink;
- (unsigned long) baseAddress;
- (void) send:(SBC_Packet*)aSendPacket receive:(SBC_Packet*)aReceivePacket;
@end

@class MjdPreAmpPollRequest;

@interface ORMjdPreAmpPollQueue : NSObject
{
    NSOperationQueue* queue;
}
+ (ORMjdPreAmpPollQueue*) sharedMjdPreAmpPollQueue;
+ (NSOperationQueue*) queue;
+ (void) cancelAllOperations;
+ (void) addRequest:(MjdPreAmpPollRequest*)anOp;
- (NSOperationQueue*) queue;
- (void) addRequest:(MjdPreAmpPollRequest*)anOp;
- (void) cancelAllOperations;

@end
@interface MjdPreAmpPollRequest : NSOperation
{
    ORMJDPreAmpModel* delegate;
}
- (id) initWithDelegate:(id)aDelegate;
- (void) main;
@end
