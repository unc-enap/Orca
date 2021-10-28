//  Orca
//  ORFlashCamADCModel.h
//
//  Created by Tom Caldwell on Monday Dec 17,2019
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORFlashCamCard.h"
#import "ORConnector.h"
#import "ORRateGroup.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "fcio.h"

#define kMaxFlashCamADCChannels 6
#define kFlashCamADCBufferLength 300
#define kFlashCamADCOrcaHeaderLength 3
#define kFlashCamADCTimeOffsetLength 5
#define kFlashCamADCDeadRegionLength 5
#define kFlashCamADCTimeStampLength 4
#define kFlashCamADCWFHeaderLength 17

@interface ORFlashCamADCModel : ORFlashCamCard <ORDataTaker, ORHWWizard>
{
    @private
    bool chanEnabled[kMaxFlashCamADCChannels];    // am
    bool trigOutEnabled[kMaxFlashCamADCChannels]; // altm
    int baseline[kMaxFlashCamADCChannels];        // bldac
    int threshold[kMaxFlashCamADCChannels];       // athr
    int adcGain[kMaxFlashCamADCChannels];         // ag
    float trigGain[kMaxFlashCamADCChannels];      // tgm
    int shapeTime[kMaxFlashCamADCChannels];       // gs
    int filterType[kMaxFlashCamADCChannels];
    float flatTopTime[kMaxFlashCamADCChannels];   // gf
    float poleZeroTime[kMaxFlashCamADCChannels];  // gpz
    float postTrigger[kMaxFlashCamADCChannels];   // pthr
    int majorityLevel;                            // majl
    int majorityWidth;                            // majw
    bool trigOutEnable;
    bool isRunning;
    unsigned int wfSamples;
    int wfHeaderBuffer[kFlashCamADCBufferLength*kFlashCamADCWFHeaderLength];
    unsigned short* wfBuffer;
    unsigned int bufferIndex;
    unsigned int takeDataIndex;
    unsigned int bufferedWFcount;
    ORRateGroup* wfRates;
    uint32_t wfCount[kMaxFlashCamADCChannels];
    uint32_t dataId;
    uint32_t location;
    uint32_t dataLengths;
    uint32_t* dataRecord;
    uint32_t  dataRecordLength;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;

#pragma mark •••Accessors
- (unsigned int) nChanEnabled;
- (bool) chanEnabled:(unsigned int)chan;
- (bool) trigOutEnable;
- (bool) trigOutEnabled:(unsigned int)chan;
- (int) baseline:(unsigned int)chan;
- (int) threshold:(unsigned int)chan;
- (int) adcGain:(unsigned int)chan;
- (float) trigGain:(unsigned int)chan;
- (int) shapeTime:(unsigned int)chan;
- (int) filterType:(unsigned int)chan;
- (float) flatTopTime:(unsigned int)chan;
- (float) poleZeroTime:(unsigned int)chan;
- (float) postTrigger:(unsigned int)chan;
- (int) majorityLevel;
- (int) majorityWidth;
- (ORRateGroup*) wfRates;
- (id) rateObject:(short)channel;
- (uint32_t) wfCount:(int)channel;
- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag;
- (float) getRate:(short)channel;
- (uint32_t) dataId;

- (void) setChanEnabled:(unsigned int)chan    withValue:(bool)enabled;
- (void) setTrigOutEnabled:(unsigned int)chan withValue:(bool)enabled;
- (void) setBaseline:(unsigned int)chan       withValue:(int)base;
- (void) setThreshold:(unsigned int)chan      withValue:(int)thresh;
- (void) setADCGain:(unsigned int)chan        withValue:(int)gain;
- (void) setTrigGain:(unsigned int)chan       withValue:(float)gain;
- (void) setShapeTime:(unsigned int)chan      withValue:(int)time;
- (void) setFilterType:(unsigned int)chan     withValue:(int)type;
- (void) setFlatTopTime:(unsigned int)chan    withValue:(float)time;
- (void) setPoleZeroTime:(unsigned int)chan   withValue:(float)time;
- (void) setPostTrigger:(unsigned int)chan    withValue:(float)time;
- (void) setMajorityLevel:(int)level;
- (void) setMajorityWidth:(int)width;
- (void) setTrigOutEnable:(bool)enabled;
- (void) setWFsamples:(int)samples;
- (void) setWFrates:(ORRateGroup*)rateGroup;
- (void) setRateIntTime:(double)intTime;
- (void) setDataId:(uint32_t)dId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;

#pragma mark •••Run control flags
- (NSString*) chFlag:(unsigned int)ch withInt:(int)value;
- (NSString*) chFlag:(unsigned int)ch withFloat:(float)value;
- (unsigned int) chanMask;
- (unsigned int) trigOutMask;
- (NSMutableArray*) runFlagsForCardIndex:(unsigned int) index andChannelOffset:(unsigned int)offset withTrigAll:(BOOL)trigAll;
- (void) printRunFlagsForChannelOffset:(unsigned int)offset;

#pragma mark •••Data taker methods
- (void) event:(fcio_event*)event withIndex:(int)index andChannel:(unsigned int)channel;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) reset;
- (void) startRates;
- (void) clearWFcounts;
- (void) syncDataIdsWith:(id)aCard;
- (NSDictionary*) dataRecordDescription;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

@end

#pragma mark •••Externals
extern NSString* ORFlashCamADCModelChanEnabledChanged;
extern NSString* ORFlashCamADCModelTrigOutEnabledChanged;
extern NSString* ORFlashCamADCModelBaselineChanged;
extern NSString* ORFlashCamADCModelThresholdChanged;
extern NSString* ORFlashCamADCModelADCGainChanged;
extern NSString* ORFlashCamADCModelTrigGainChanged;
extern NSString* ORFlashCamADCModelShapeTimeChanged;
extern NSString* ORFlashCamADCModelFilterTypeChanged;
extern NSString* ORFlashCamADCModelFlatTopTimeChanged;
extern NSString* ORFlashCamADCModelPoleZeroTimeChanged;
extern NSString* ORFlashCamADCModelPostTriggerChanged;
extern NSString* ORFlashCamADCModelMajorityLevelChanged;
extern NSString* ORFlashCamADCModelMajorityWidthChanged;
extern NSString* ORFlashCamADCModelRateGroupChanged;
extern NSString* ORFlashCamADCModelBufferFull;

