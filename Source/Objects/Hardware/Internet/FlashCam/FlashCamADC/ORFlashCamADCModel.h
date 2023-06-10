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
#import "ORAdcInfoProviding.h"
#import "fcio.h"
#import "ORInFluxDBModel.h"

#define kMaxFlashCamADCChannels 24
#define kFlashCamADCChannels 6
#define kFlashCamADCStdChannels 24
#define kFlashCamADCBufferLength 300
#define kFlashCamADCOrcaHeaderLength 3
#define kFlashCamADCTimeOffsetLength 7
#define kFlashCamADCDeadRegionLength 5
#define kFlashCamADCTimeStampLength 4
#define kFlashCamADCWFHeaderLength 19

#define kDeadBandTime 5

@interface ORFlashCamADCModel : ORFlashCamCard <ORDataTaker, ORHWWizard, ORAdcInfoProviding>
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
    int baselineSlew[kMaxFlashCamADCChannels];    // gbs
    bool swTrigInclude[kMaxFlashCamADCChannels];
    int baseBias;                                 // blbias
    int majorityLevel;                            // majl
    int majorityWidth;                            // majw
    bool trigOutEnable;
    bool isRunning;
    unsigned int wfSamples;
    ORRateGroup* wfRates;
    ORRateGroup* trigRates;
    uint32_t wfCount[kMaxFlashCamADCChannels];
    uint32_t trigCount[kMaxFlashCamADCChannels];
    uint32_t dataId;
    uint32_t location;
    uint32_t dataLengths;
    uint32_t* dataRecord;
    uint32_t  dataRecordLength;
    bool enableBaselineHistory;
    double baselineSampleTime;
    ORTimeRate* baselineHistory[kMaxFlashCamADCChannels];
    ORInFluxDBModel* inFlux;
    NSDate* startTime; 
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
- (unsigned int) fwType;
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
- (int) baselineSlew:(unsigned int)chan;
- (bool) swTrigInclude:(unsigned int)chan;
- (int) baseBias;
- (int) majorityLevel;
- (int) majorityWidth;
- (bool) isRunning;
- (ORRateGroup*) wfRates;
- (id) wfRateObject:(short)channel;
- (uint32_t) wfCount:(int)channel;
- (float) getWFrate:(short)channel;
- (ORRateGroup*) trigRates;
- (id) rateObject:(short)channel;
- (uint32_t) trigCount:(int)channel;
- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag;
- (float) getRate:(short)channel forGroup:(int)groupTag;
- (uint32_t) dataId;
- (bool) enableBaselineHistory;
- (double) baselineSampleTime;
- (ORTimeRate*) baselineHistory:(unsigned int)chan;
- (void) shipToInflux:(int)aChan energy:(int)anEnergy baseline:(int)aBaseline;

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
- (void) setBaselineSlew:(unsigned int)chan   withValue:(int)slew;
- (void) setSWTrigInclude:(unsigned int)chan  withValue:(bool)include;
- (void) setBaseBias:(int)bias;
- (void) setMajorityLevel:(int)level;
- (void) setMajorityWidth:(int)width;
- (void) setTrigOutEnable:(bool)enabled;
- (void) setWFsamples:(int)samples;
- (void) setWFrates:(ORRateGroup*)rateGroup;
- (void) setTrigRates:(ORRateGroup*)rateGroup;
- (void) setRateIntTime:(double)intTime;
- (void) setDataId:(uint32_t)dId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;
- (void) setEnableBaselineHistory:(bool)enable;
- (void) setBaselineSampleTime:(double)time;
- (void) setBaselineHistory:(unsigned int)chan withTimeRate:(ORTimeRate*)baseHist;

#pragma mark •••Run control flags
- (NSString*) chFlag:(unsigned int)ch withInt:(int)value;
- (NSString*) chFlag:(unsigned int)ch withFloat:(float)value;
- (unsigned int) chanMask;
- (unsigned int) trigOutMask;
- (NSMutableArray*) runFlagsForCardIndex:(unsigned int) index andChannelOffset:(unsigned int)offset withTrigAll:(BOOL)trigAll;
- (void) printRunFlagsForChannelOffset:(unsigned int)offset;

#pragma mark •••Data taker methods
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) shipEvent:(fcio_event*)event withIndex:(int)index
        andChannel:(unsigned int)channel    use:(ORDataPacket*)aDataPacket includeWF:(bool) includeWF;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) reset;
- (void) startRates;
- (void) clearCounts;
- (NSDictionary*) dataRecordDescription;

#pragma mark •••AdcProviding Protocol
- (BOOL) onlineMaskBit:(int)bit;
- (BOOL) partOfEvent:(unsigned short)aChannel;
- (uint32_t) eventCount:(int)aChannel;
- (void) clearEventCounts;
- (uint32_t) thresholdForDisplay:(unsigned short)aChan;
- (unsigned short) gainForDisplay:(unsigned short)aChan;
- (void) initBoard;
- (void) postAdcInfoProvidingValueChanged;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addCurrentState:(NSMutableDictionary*)dictionary intArray:(int*)array forKey:(NSString*)key;
- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(bool*)array forKey:(NSString*)key;
- (void) addCurrentState:(NSMutableDictionary*)dictionary floatArray:(float*)array forKey:(NSString*)key;

#pragma mark •••HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

@end


@interface ORFlashCamADCModel (private)
- (void) postConfig;
- (void) postCouchDBRecord;
@end


@interface ORFlashCamADCStdModel : ORFlashCamADCModel { }
@end


#pragma mark •••Externals
extern NSString* ORFlashCamADCModelChanEnabledChanged;
extern NSString* ORFlashCamADCModelTrigOutEnabledChanged;
extern NSString* ORFlashCamADCModelBaselineChanged;
extern NSString* ORFlashCamADCModelBaseBiasChanged;
extern NSString* ORFlashCamADCModelThresholdChanged;
extern NSString* ORFlashCamADCModelADCGainChanged;
extern NSString* ORFlashCamADCModelTrigGainChanged;
extern NSString* ORFlashCamADCModelShapeTimeChanged;
extern NSString* ORFlashCamADCModelFilterTypeChanged;
extern NSString* ORFlashCamADCModelFlatTopTimeChanged;
extern NSString* ORFlashCamADCModelPoleZeroTimeChanged;
extern NSString* ORFlashCamADCModelPostTriggerChanged;
extern NSString* ORFlashCamADCModelBaselineSlewChanged;
extern NSString* ORFlashCamADCModelSWTrigIncludeChanged;
extern NSString* ORFlashCamADCModelMajorityLevelChanged;
extern NSString* ORFlashCamADCModelMajorityWidthChanged;
extern NSString* ORFlashCamADCModelRateGroupChanged;
extern NSString* ORFlashCamADCModelEnableBaselineHistoryChanged;
extern NSString* ORFlashCamADCModelBaselineHistoryChanged;
extern NSString* ORFlashCamADCModelBaselineSampleTimeChanged;
