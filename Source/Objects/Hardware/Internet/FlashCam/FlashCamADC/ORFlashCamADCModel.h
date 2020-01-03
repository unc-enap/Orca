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
//#import "ORDataTaker.h"
#import "ORHWWizard.h"

//@class ORRateGroup;

#define kMaxFlashCamADCChannels 6

@interface ORFlashCamADCModel : ORFlashCamCard <ORHWWizard> //<ORDataTaker, ORHWWizard>
{
    @private
    unsigned int boardAddress;
    bool chanEnabled[kMaxFlashCamADCChannels];
    int baseline[kMaxFlashCamADCChannels];       // bldac
    int threshold[kMaxFlashCamADCChannels];      // athr
    int adcGain[kMaxFlashCamADCChannels];        // ag
    float trigGain[kMaxFlashCamADCChannels];     // tgm
    int shapeTime[kMaxFlashCamADCChannels];      // gs
    float filterType[kMaxFlashCamADCChannels];   // gf
    float poleZeroTime[kMaxFlashCamADCChannels]; // gpz
    ORConnector* ethConnector;
    ORConnector* trigConnector;
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
- (unsigned int) boardAddress;
- (unsigned int) nChanEnabled;
- (bool) chanEnabled:(unsigned int)chan;
- (int) baseline:(unsigned int)chan;
- (int) threshold:(unsigned int)chan;
- (int) adcGain:(unsigned int)chan;
- (float) trigGain:(unsigned int)chan;
- (int) shapeTime:(unsigned int)chan;
- (float) filterType:(unsigned int)chan;
- (float) poleZeroTime:(unsigned int)chan;
- (ORConnector*) ethConnector;
- (ORConnector*) trigConnector;

- (void) setBoardAddress:(unsigned int)address;
- (void) setChanEnabled:(unsigned int)chan  withValue:(bool)enabled;
- (void) setBaseline:(unsigned int)chan     withValue:(int)base;
- (void) setThreshold:(unsigned int)chan    withValue:(int)thresh;
- (void) setADCGain:(unsigned int)chan      withValue:(int)gain;
- (void) setTrigGain:(unsigned int)chan     withValue:(float)gain;
- (void) setShapeTime:(unsigned int)chan    withValue:(int)time;
- (void) setFilterType:(unsigned int)chan   withValue:(float)type;
- (void) setPoleZeroTime:(unsigned int)chan withValue:(float)time;
- (void) setEthConnector:(ORConnector*)connector;
- (void) setTrigConnector:(ORConnector*)connector;

#pragma mark •••Run control flags
- (NSString*) chFlag:(unsigned int)ch withInt:(int)value;
- (NSString*) chFlag:(unsigned int)ch withFloat:(float)value;
- (unsigned int) chanMask;
- (NSMutableArray*) runFlagsForChannelOffset:(unsigned int)offset;
- (void) printRunFlagsForChannelOffset:(unsigned int)offset;

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
extern NSString* ORFlashCamADCModelBoardAddressChanged;
extern NSString* ORFlashCamADCModelChanEnabledChanged;
extern NSString* ORFlashCamADCModelBaselineChanged;
extern NSString* ORFlashCamADCModelThresholdChanged;
extern NSString* ORFlashCamADCModelADCGainChanged;
extern NSString* ORFlashCamADCModelTrigGainChanged;
extern NSString* ORFlashCamADCModelShapeTimeChanged;
extern NSString* ORFlashCamADCModelFilterTypeChanged;
extern NSString* ORFlashCamADCModelPoleZeroTimeChanged;

