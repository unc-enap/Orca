//
//  ORTristanFLTModel.h
//  Orca
//
//  Created by Mark Howe on 1/23/18.
//  Copyright 2018, University of North Carolina. All rights reserved.
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


#pragma mark ***Imported Files
#import "ORIpeCard.h"
#import "ORHWWizard.h"
#import "ORDataTaker.h"
#import "SBC_Config.h"
#import "ORUDPConnection.h"

#pragma mark ***Forward Definitions
@class ORDataPacket;
@class ORTimeRate;
@class ORRateGroup;

#define kNumTristanFLTChannels      8

#define kTristanFltControl        0x0
#define kTristanFltFilterSet      0x1
#define kTristanFltTriggerDisable 0x2
#define kTristanFltTraceCntrl     0x3
#define kTristanFltCommand        0x4
#define kTristanFltRtmDacCntrl    0x5
#define kTristanFltRtmAdcCntrl    0x6
#define kTristanFltIICCntrl       0x7
#define kTristanFltThreshold      0x8

#define kTristanFLTSW             0x1

@interface ORTristanFLTModel : ORIpeCard <ORUDPConnectionDelegate,ORDataTaker,ORHWWizard>
{
    BOOL            firstTime;
    unsigned short  shapingLength;
    unsigned short  gapLength;
    unsigned short  postTriggerTime;
    unsigned short  udpFrameSize;
    ORTimeRate*     totalRate;
    uint32_t   dataId;
    BOOL            enabled[kNumTristanFLTChannels];
    uint32_t   threshold[kNumTristanFLTChannels];
    uint32_t   eventCount[kNumTristanFLTChannels];
    ORUDPConnection*    client;
    NSString*       hostName;
    NSUInteger             port;
    BOOL            udpConnected;

}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) sleep;
- (void) wakeUp;
- (void) setUpImage;
- (void) makeMainController;
- (Class) guardianClass;
- (int) stationNumber;
- (ORTimeRate*) totalRate;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) runIsAboutToStop:(NSNotification*)aNote;
- (void) reset;

#pragma mark ***Accessors
- (unsigned short) shapingLength;
- (void) setShapingLength:(unsigned short)aValue;
- (int) gapLength;
- (void) setGapLength:(int)aValue;
- (unsigned short) postTriggerTime;
- (void) setPostTriggerTime:(unsigned short)aValue;
- (unsigned short) udpFrameSize;
- (void) setUdpFrameSize:(unsigned short)aValue;
-(BOOL) enabled:(unsigned short) aChan;
-(void) setEnabled:(unsigned short) aChan withValue:(BOOL) aState;
- (uint32_t) threshold:(unsigned short)aChan;
-(void) setThreshold:(unsigned short) aChan withValue:(uint32_t) aValue;
- (void) setTotalRate:(ORTimeRate*)newTimeRate;
- (void) setToDefaults;
- (void) initBoard;
- (ORUDPConnection*) client;
- (void) setClient:(ORUDPConnection*)aSocket;
- (NSString*) hostName;
- (void) setHostName:(NSString*)aString;
- (NSUInteger) port;
- (void) setPort:(NSUInteger)aValue;
- (BOOL) udpConnected;
- (void) setUpdConnected:(BOOL)aState;
- (void) sendData:(NSData*)someData;

#pragma mark ***HW Access
- (void) loadThresholds;
- (void) startClient;

#pragma mark ***Data Taking
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) aDataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;
- (NSDictionary*) dataRecordDescription;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (BOOL) bumpRateFromDecodeStage:(short)channel;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

#pragma mark ***HW Wizard
- (BOOL) hasParmetersToRamp;
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark ***Communication
- (void) loadThresholds;
- (void) forceTrigger;
- (void) loadFilterParameters;
- (void) enableChannels;
- (void) disableAllChannels;
- (void) loadTraceControl;

#pragma mark ***archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORTristanFLTModelEnabledChanged;
extern NSString* ORTristanFLTModelShapingLengthChanged;
extern NSString* ORTristanFLTModelGapLengthChanged;
extern NSString* ORTristanFLTModelThresholdsChanged;
extern NSString* ORTristanFLTModelPostTriggerTimeChanged;
extern NSString* ORTristanFLTModelFrameSizeChanged;
extern NSString* ORTristanFLTModelRunningChanged;
extern NSString* ORTristanFLTModelUdpFrameSizeChanged;
extern NSString* ORTristanFLTSettingsLock;
extern NSString* ORTristanFLTModelHostNameChanged;
extern NSString* ORTristanFLTModelPortChanged;
extern NSString* ORTristanFLTModelUdpConnectedChanged;
