//  Orca
//  ORFlashCamADCModel.m
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

#import "ORFlashCamADCModel.h"
#import "ORCrate.h"
#import "ORFlashCamEthLinkModel.h"
#import "ORFlashCamReadoutModel.h"
#import "FlashCamUtils.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"

NSString* ORFlashCamADCModelChanEnabledChanged    = @"ORFlashCamADCModelChanEnabledChanged";
NSString* ORFlashCamADCModelTrigOutEnabledChanged = @"ORFlashCamADCModelTrigOutEnabledChanged";
NSString* ORFlashCamADCModelBaselineChanged       = @"ORFlashCamADCModelBaselineChanged";
NSString* ORFlashCamADCModelBaseBiasChanged       = @"ORFlashCamADCModelBaseBiasChanged";
NSString* ORFlashCamADCModelThresholdChanged      = @"ORFlashCamADCModelThresholdChanged";
NSString* ORFlashCamADCModelADCGainChanged        = @"ORFlashCamADCModelADCGainChanged";
NSString* ORFlashCamADCModelTrigGainChanged       = @"ORFlashCamADCModelTrigGainChanged";
NSString* ORFlashCamADCModelShapeTimeChanged      = @"ORFlashCamADCModelShapeTimeChanged";
NSString* ORFlashCamADCModelFilterTypeChanged     = @"ORFlashCamADCModelFilterTypeChanged";
NSString* ORFlashCamADCModelFlatTopTimeChanged    = @"ORFlashCamADCModelFlatTopTimeChanged";
NSString* ORFlashCamADCModelPoleZeroTimeChanged   = @"ORFlashCamADCModelPoleZeroTimeChanged";
NSString* ORFlashCamADCModelPostTriggerChanged    = @"ORFlashCamADCModelPostTriggerChanged";
NSString* ORFlashCamADCModelMajorityLevelChanged  = @"ORFLashCamADCModelMajorityLevelChanged";
NSString* ORFlashCamADCModelMajorityWidthChanged  = @"ORFlashCamADCModelMajorityWidthChanged";
NSString* ORFlashCamADCModelRateGroupChanged      = @"ORFlashCamADCModelRateGroupChanged";
NSString* ORFlashCamADCModelBufferFull            = @"ORFlashCamADCModelBufferFull";

@implementation ORFlashCamADCModel

- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setCardAddress:0];
    wfRates   = nil;
    trigRates = nil;
    for(int i=0; i<[self numberOfChannels]; i++){
        [self setChanEnabled:i    withValue:NO];
        [self setTrigOutEnabled:i withValue:NO];
        [self setBaseline:i       withValue:-1];
        [self setThreshold:i      withValue:5000];
        [self setADCGain:i        withValue:0];
        [self setTrigGain:i       withValue:0.0];
        [self setShapeTime:i      withValue:16*256];
        [self setFilterType:i     withValue:1];
        [self setFlatTopTime:i    withValue:16.0*128];
        [self setPoleZeroTime:i   withValue:16.0*4096*6];
        [self setPostTrigger:i    withValue:0.0];
        wfCount[i]   = 0;
        trigCount[i] = 0;
    }
    baseBias      = 0;
    majorityLevel = 1;
    majorityWidth = 1;
    trigOutEnable = false;
    trigConnector = nil;
    isRunning = false;
    wfBuffer = NULL;
    bufferIndex = 0;
    takeDataIndex = 0;
    bufferedWFcount = 0;
    dataRecord = NULL;
    [self setWFsamples:0];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self setWFsamples:0];
    [wfRates release];
    [trigRates release];
    [super dealloc];
}

- (void) setUpImage
{
    NSImage* cimage = [NSImage imageNamed:@"flashcam_adc"];
    NSSize size = [cimage size];
    NSSize newsize;
    newsize.width  = 0.155*5*size.width;
    newsize.height = 0.135*5*size.height;
    NSImage* image = [[NSImage alloc] initWithSize:newsize];
    [image lockFocus];
    NSRect rect;
    rect.origin = NSZeroPoint;
    rect.size.width = newsize.width;
    rect.size.height = newsize.height;
    [cimage drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [image unlockFocus];
    [self setImage:image];
}

- (void) makeMainController
{
    [self linkToController:@"ORFlashCamADCController"];
}

- (void) makeConnectors
{
    [self setEthConnector:[[[ORConnector alloc] initAt:NSZeroPoint
                                   withGuardian:self
                                 withObjectLink:self] autorelease]];
    [ethConnector setConnectorImageType:kSmallDot];
    [ethConnector setConnectorType:'FCEO'];
    [ethConnector addRestrictedConnectionType:'FCEI'];
    [ethConnector setSameGuardianIsOK:YES];
    [ethConnector setOffColor:[NSColor colorWithCalibratedRed:1 green:1 blue:0.3 alpha:1]];
    [ethConnector setOnColor:[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:1 alpha:1]];
    [self setTrigConnector:[[[ORConnector alloc] initAt:NSZeroPoint
                                    withGuardian:self
                                  withObjectLink:self] autorelease]];
    [trigConnector setConnectorImageType:kSmallDot];
    [trigConnector setConnectorType:'FCTI'];
    [trigConnector addRestrictedConnectionType:'FCTO'];
    [trigConnector addRestrictedConnectionType:'FCGO'];
    [trigConnector setSameGuardianIsOK:YES];
    [trigConnector setOffColor:[NSColor colorWithCalibratedRed:1 green:0.3 blue:1 alpha:1]];
    [trigConnector setOnColor:[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:1 alpha:1]];
}

- (void) positionConnector:(ORConnector*)aConnector
{
    float xoff = 0.0;
    float yoff = 0.0;
    float xscale = 1.0;
    float yscale = 1.0;
    if([[guardian className] isEqualToString:@"ORFlashCamCrateModel"]){
        xoff = 30;
        yoff = 18;
        xscale = 0.595;
        yscale = 0.5;
    }
    else if([[guardian className] isEqualToString:@"ORFlashCamMiniCrateModel"]){
        xoff = 3;
        yoff = 10;
        xscale = 0.6;
        yscale = 0.522;
    }
    NSRect frame = [aConnector localFrame];
    float x = (xoff + ([self slot] + 0.5) * 25) * xscale - kConnectorSize/4;
    float y = 0.0;
    if(aConnector == ethConnector)       y = yoff + [self frame].size.height * yscale * 0.9;
    else if(aConnector == trigConnector) y = yoff + [self frame].size.height * yscale * 0.855;
    else return;
    frame.origin = NSMakePoint(x, y);
    [aConnector setLocalFrame:frame];
}

- (void) disconnect
{
    if(ethConnector)  [ethConnector  disconnect];
    if(trigConnector) [trigConnector disconnect];
    [super disconnect];
}

- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    if(oldGuardian != aGuardian) [self guardianRemovingDisplayOfConnectors:oldGuardian];
    [self guardianAssumingDisplayOfConnectors:aGuardian];
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:ethConnector  forCard:self];
    [aGuardian positionConnector:trigConnector forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:ethConnector];
    [aGuardian removeDisplayOf:trigConnector];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:ethConnector];
    [aGuardian assumeDisplayOf:trigConnector];
}


#pragma mark •••Accessors

- (unsigned int) fwType
{
    return 1;
}

- (unsigned int) nChanEnabled
{
    unsigned int n=0;
    for(unsigned int i=0; i<[self numberOfChannels]; i++) if(chanEnabled[i]) n++;
    return n;
}

- (bool) chanEnabled:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return false;
    return chanEnabled[chan];
}

- (bool) trigOutEnable
{
    return trigOutEnable;
}

- (bool) trigOutEnabled:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return false;
    return trigOutEnabled[chan];
}

- (int) baseline:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return 0;
    return baseline[chan];
}

- (int) threshold:(unsigned int)chan{
    if(chan >= [self numberOfChannels]) return 0;
    return threshold[chan];
}

- (int) adcGain:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return 0;
    return adcGain[chan];
}

- (float) trigGain:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return 0.0;
    return trigGain[chan];
}

- (int) shapeTime:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return 0;
    return shapeTime[chan];
}

- (int) filterType:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return 0;
    return filterType[chan];
}

- (float) flatTopTime:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return 0.0;
    return flatTopTime[chan];
}

- (float) poleZeroTime:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return 0.0;
    return poleZeroTime[chan];
}

- (float) postTrigger:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return 0.0;
    return postTrigger[chan];
}

- (int) baseBias
{
    return baseBias;
}

- (int) majorityLevel
{
    return majorityLevel;
}

- (int) majorityWidth
{
    return majorityWidth;
}

- (ORRateGroup*) wfRates
{
    return wfRates;
}

- (id) wfRateObject:(short)channel
{
    return [wfRates rateObject:channel];
}

- (uint32_t) wfCount:(int)channel
{
    return wfCount[channel];
}

- (float) getWFrate:(short)channel
{
    if(channel>=0 && channel<[self numberOfChannels]){
        return [[self wfRateObject:channel] rate];
    }
    return 0;
}

- (ORRateGroup*) trigRates
{
    return trigRates;
}

- (id) rateObject:(short)channel
{
    return [trigRates rateObject:channel];
}

- (uint32_t) trigCount:(int)channel
{
    return trigCount[channel];
}

- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
    if(counterTag >= 0 && counterTag < [self numberOfChannels]){
        if(groupTag == 0)      return trigCount[counterTag];
        else if(groupTag == 1) return wfCount[counterTag];
    }
    return 0;
}

- (float) getRate:(short)channel forGroup:(int)groupTag
{
    if(channel>=0 && channel<[self numberOfChannels]){
        if(groupTag == 0)      return [[self rateObject:channel]   rate];
        else if(groupTag == 1) return [[self wfRateObject:channel] rate];
    }
    return 0;
}

- (uint32_t) dataId
{
    return dataId;
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardSlotChangedNotification object:self];
}

- (void) setChanEnabled:(unsigned int)chan withValue:(bool)enabled
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setChanEnabled:chan withValue:chanEnabled[chan]];
    chanEnabled[chan] = enabled;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelChanEnabledChanged
                                                        object:self
                                                      userInfo:info];
    [self postAdcInfoProvidingValueChanged];
}

- (void) setTrigOutEnabled:(unsigned int)chan withValue:(bool)enabled
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigOutEnabled:chan withValue:trigOutEnabled[chan]];
    trigOutEnabled[chan] = enabled;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelTrigOutEnabledChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setBaseline:(unsigned int)chan withValue:(int)base
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setBaseline:chan withValue:baseline[chan]];
    baseline[chan] = MAX(-1, MIN(4096, base));
    if(baseline[chan] == 0) baseline[chan] = -1;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelBaselineChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setThreshold:(unsigned int)chan withValue:(int)thresh
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:chan withValue:threshold[chan]];
    threshold[chan] = MAX(0, thresh);
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelThresholdChanged
                                                        object:self
                                                      userInfo:info];
    [self postAdcInfoProvidingValueChanged];
}

- (void) setADCGain:(unsigned int)chan withValue:(int)gain
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setADCGain:chan withValue:adcGain[chan]];
    adcGain[chan] = MAX(-15, MIN(16, gain));
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelADCGainChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setTrigGain:(unsigned int)chan withValue:(float)gain
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigGain:chan withValue:trigGain[chan]];
    trigGain[chan] = MIN(MAX(0.0, gain), 1.0);
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelTrigGainChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setShapeTime:(unsigned int)chan withValue:(int)time
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setShapeTime:chan withValue:shapeTime[chan]];
    shapeTime[chan] = MAX(1.0, 40000.0);
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelShapeTimeChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setFilterType:(unsigned int)chan withValue:(int)type
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setFilterType:chan withValue:filterType[chan]];
    filterType[chan] = MIN(MAX(0, type), 2);
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelFilterTypeChanged
                                                        object:self
                                                      userInfo:info];
    if(filterType == 0) [self setFlatTopTime:chan withValue:0.0];
}

- (void) setFlatTopTime:(unsigned int)chan withValue:(float)time
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setFlatTopTime:chan withValue:flatTopTime[chan]];
    if([self filterType:chan] == 0) flatTopTime[chan] = 0.0;
    else flatTopTime[chan] = MAX(0.0, time);
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelFlatTopTimeChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setPoleZeroTime:(unsigned int)chan withValue:(float)time
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPoleZeroTime:chan withValue:poleZeroTime[chan]];
    poleZeroTime[chan] = MAX(1.0, time);
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelPoleZeroTimeChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setPostTrigger:(unsigned int)chan withValue:(float)time
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTrigger:chan withValue:postTrigger[chan]];
    postTrigger[chan] = MAX(0.0, time);
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelPostTriggerChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setBaseBias:(int)bias
{
    if(bias == baseBias) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setBaseBias:baseBias];
    baseBias = MAX(-2047, MIN(2048, bias));
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelBaseBiasChanged object:self];
}

- (void) setMajorityLevel:(int)level
{
    if(level == majorityLevel) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setMajorityLevel:majorityLevel];
    majorityLevel = MIN(MAX(1, level), [self numberOfChannels]);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelMajorityLevelChanged object:self];
}

- (void) setMajorityWidth:(int)width
{
    if(width == majorityWidth) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setMajorityWidth:majorityWidth];
    if(width > 0) majorityWidth = width;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelMajorityWidthChanged object:self];
}

- (void) setTrigOutEnable:(bool)enabled
{
    if(enabled == trigOutEnable) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigOutEnable:trigOutEnable];
    trigOutEnable = enabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelTrigOutEnabledChanged object:self];
}

- (void) setWFsamples:(int)samples
{
    wfSamples = samples;
    if(wfBuffer){
        free(wfBuffer);
        wfBuffer = NULL;
    }
    if(dataRecord){
        free(dataRecord);
        dataRecord = NULL;
    }
    dataRecordLength = 0;
    if(wfSamples > 0){
        wfBuffer = (unsigned short*) malloc(kFlashCamADCBufferLength * (wfSamples+2) * sizeof(unsigned short));
        // first 3 items in WF header get put into Orca header, then trace header gets moved to WF header
        dataLengths = ((wfSamples&0xffff) << 6) | (((kFlashCamADCWFHeaderLength-3+1)&0x3f) << 22);
        dataLengths = dataLengths | ((kFlashCamADCOrcaHeaderLength&0xf) << 28);
        dataRecordLength = kFlashCamADCOrcaHeaderLength + (kFlashCamADCWFHeaderLength - 3 + 1) + wfSamples/2;
        dataRecord = (uint32_t*) malloc(dataRecordLength * sizeof(uint32_t));
        bufferIndex = 0;
    }
}

- (void) setWFrates:(ORRateGroup*)rateGroup
{
    [rateGroup retain];
    [wfRates release];
    wfRates = rateGroup;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelRateGroupChanged object:self];
}

- (void) setTrigRates:(ORRateGroup*)rateGroup
{
    [rateGroup retain];
    [trigRates release];
    trigRates = rateGroup;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelRateGroupChanged object:self];
}

- (void) setRateIntTime:(double)intTime
{
    [wfRates setIntegrationTime:intTime];
    [trigRates setIntegrationTime:intTime];
}

- (void) setDataId:(uint32_t)dId
{
    dataId = dId;
}

- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}


#pragma mark •••Run control flags

- (NSString*) chFlag:(unsigned int)ch withInt:(int)value
{
    return [NSString stringWithFormat:@"%i,%d,1", value, ch];
}

- (NSString*) chFlag:(unsigned int)ch withFloat:(float)value
{
    return [NSString stringWithFormat:@"%.2f,%d,1", value, ch];
}

- (unsigned int) chanMask
{
    unsigned int mask = 0;
    for(unsigned int i=0; i<[self numberOfChannels]; i++) if(chanEnabled[i]) mask += 1 << i;
    return mask;
}

- (unsigned int) trigOutMask
{
    unsigned int mask = 0;
    for(unsigned int i=0; i<[self numberOfChannels]; i++) if(trigOutEnabled[i]) mask += 1 << i;
    return mask;
}

- (NSMutableArray*) runFlagsForCardIndex:(unsigned int)index andChannelOffset:(unsigned int)offset withTrigAll:(BOOL)trigAll
{
    NSMutableArray* flags = [NSMutableArray array];
    [flags addObjectsFromArray:@[@"-am",    [NSString stringWithFormat:@"%x,%d,1", [self chanMask],      index]]];
    [flags addObjectsFromArray:@[@"-blbias",[NSString stringWithFormat:@"%d,%d,1", [self baseBias],      index]]];
    if(trigOutEnable)
        [flags addObjectsFromArray:@[@"-altm", [NSString stringWithFormat:@"%x,%d,1",[self trigOutMask], index]]];
    else
        [flags addObjectsFromArray:@[@"-altm", [NSString stringWithFormat:@"-1,%d,1", index]]];
    [flags addObjectsFromArray:@[@"-amajl", [NSString stringWithFormat:@"%x,%d,1", [self majorityLevel], index]]];
    [flags addObjectsFromArray:@[@"-amajw", [NSString stringWithFormat:@"%x,%d,1", [self majorityWidth], index]]];
    for(unsigned int i=0; i<[self numberOfChannels]; i++){
        unsigned int j = i + offset;
        if(trigAll || [self chanEnabled:i]) [flags addObjectsFromArray:@[@"-athr",  [self chFlag:j withInt:threshold[i]]]];
        if(![self chanEnabled:i]) continue;
        [flags addObjectsFromArray:@[@"-bldac",  [self chFlag:j withInt:baseline[i]]]];
        [flags addObjectsFromArray:@[@"-ag",     [self chFlag:j withInt:adcGain[i]]]];
        [flags addObjectsFromArray:@[@"-tgm",    [self chFlag:j withFloat:trigGain[i]]]];
        [flags addObjectsFromArray:@[@"-pthr",   [self chFlag:j withFloat:postTrigger[i]]]];
        if([self fwType] == 0){
            [flags addObjectsFromArray:@[@"-fs", [self chFlag:j withInt:shapeTime[i]]]];
            [flags addObjectsFromArray:@[@"-ss", [self chFlag:j withInt:flatTopTime[i]]]];
            [flags addObjectsFromArray:@[@"-pz", [self chFlag:j withFloat:poleZeroTime[i]]]];
        }
        else if([self fwType] == 1){
            [flags addObjectsFromArray:@[@"-gs",     [self chFlag:j withInt:shapeTime[i]]]];
            [flags addObjectsFromArray:@[@"-gpz",    [self chFlag:j withFloat:poleZeroTime[i]]]];
            if([self filterType:i] == 0)
                [flags addObjectsFromArray:@[@"-gf", [self chFlag:j withFloat:0.0]]];
            else
                [flags addObjectsFromArray:@[@"-gf", [self chFlag:j withFloat:flatTopTime[i]*pow(-1, 1+[self filterType:i])]]];
        }
    }
    mergeRunFlags(flags);
    return flags;
}

- (void) printRunFlagsForChannelOffset:(unsigned int)offset
{
    NSLog(@"%@\n", [[self runFlagsForCardIndex:0 andChannelOffset:offset withTrigAll:YES] componentsJoinedByString:@" "]);
}


#pragma mark •••Data taker methods

- (void) event:(fcio_event*)event withIndex:(int)index andChannel:(unsigned int)channel
{
    @synchronized(self){
        if(channel >= [self numberOfChannels]){
            NSLog(@"ORFlashCamADCModel: invalid channel passed to event:withIndex:andChannel:, skipping packet\n");
            return;
        }
        else{
            wfCount[channel] ++;
            if(event->theader[index][1] > 0) trigCount[channel] ++;
        }
        // increment the buffer index
        unsigned int bindex = bufferIndex;
        bufferIndex = (bufferIndex + 1) % kFlashCamADCBufferLength;
        bufferedWFcount ++;
        // set the channel number and index to pass to takeData
        uint32_t hindex = bindex * kFlashCamADCWFHeaderLength;
        wfHeaderBuffer[hindex] = (int) channel;
        wfHeaderBuffer[hindex+1] = index;
        // get the waveform header information from the fcio_event structure
        wfHeaderBuffer[hindex+2] = event->type;
        unsigned int offset = hindex + 3;
        for(unsigned int i=0; i<kFlashCamADCTimeOffsetLength; i++) wfHeaderBuffer[offset++] = event->timeoffset[i];
        for(unsigned int i=0; i<kFlashCamADCDeadRegionLength; i++) wfHeaderBuffer[offset++] = event->deadregion[i];
        for(unsigned int i=0; i<kFlashCamADCTimeStampLength;  i++) wfHeaderBuffer[offset++] = event->timestamp[i];
        // get the waveform for this channel at the index provided from the fcio_event structure
        memcpy(wfBuffer+bindex*(wfSamples+2), event->theader[index], (wfSamples+2)*sizeof(unsigned short));
        if(bufferedWFcount == kFlashCamADCBufferLength){
            NSLogColor([NSColor redColor], @"ORFlashCamADCModel: buffer full for card ID 0x%x crate %d slot %d\n",
                       [self cardAddress], [self crate], [self slot]);
            [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelBufferFull object:self];
        }
    }
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    @synchronized(self){
        @try{
            if(wfSamples == 0 || !wfBuffer || !dataRecord) return;
            else if(bufferIndex == takeDataIndex) return;
            else{
                unsigned int index = takeDataIndex;
                takeDataIndex = (takeDataIndex + 1) % kFlashCamADCBufferLength;
                bufferedWFcount --;
                isRunning = true;
                uint32_t hindex = index * kFlashCamADCWFHeaderLength;
                dataRecord[0] = dataId | (dataRecordLength&0x3ffff);
                dataRecord[1] = dataLengths | (wfHeaderBuffer[hindex+2]&0x3f);
                dataRecord[2] = location | ((wfHeaderBuffer[hindex]&0xf) << 10) | (wfHeaderBuffer[hindex+1]&0x3ff);
                memcpy(dataRecord+3, wfHeaderBuffer+hindex+3, (kFlashCamADCWFHeaderLength-3)*sizeof(uint32_t));
                uint32_t windex = index * (wfSamples + 2);
                dataRecord[kFlashCamADCWFHeaderLength] = (wfBuffer[windex+1] << 16) | wfBuffer[windex];
                memcpy(dataRecord+kFlashCamADCWFHeaderLength+1, wfBuffer+windex+2, wfSamples*sizeof(unsigned short));
                [aDataPacket addLongsToFrameBuffer:dataRecord length:dataRecordLength];
            }
        }
        @catch(NSException* localException){
            NSLogError(@"", @"ORFlashCamADCModel error", @"", nil);
            [self incExceptionCount];
            [localException raise];
        }
    }
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORFlashCamADCModel"];
    location = (([self crateNumber] & 0x1f) << 27) | (([self slot] & 0x1f) << 22);
    location = location | (([self cardAddress] & 0xff) << 14);
    [self startRates];
    isRunning = false;
    takeDataIndex   = 0;
    bufferIndex     = 0;
    bufferedWFcount = 0;
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    while(bufferedWFcount > 0) [self takeData:aDataPacket userInfo:userInfo];
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    isRunning = false;
    [wfRates   stop];
    [trigRates stop];
    [self setWFsamples:0];
    takeDataIndex = 0;
}

- (void) reset
{
}

-(void) startRates
{
    [self clearCounts];
    [wfRates   start:self];
    [trigRates start:self];
}

- (void) clearCounts
{
    for(int i=0;i<kMaxFlashCamADCChannels;i++){
        wfCount[i]   = 0;
        trigCount[i] = 0;
    }
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"ORFlashCamADCWaveformDecoder",  @"decoder",
                       [NSNumber numberWithLong:dataId], @"dataId",
                       [NSNumber numberWithBool:YES],    @"variable",
                       [NSNumber numberWithLong:-1],     @"length", nil];
    if([self fwType] == 0)      [dict setObject:d forKey:@"FlashCamADCStd"];
    else if([self fwType] == 1) [dict setObject:d forKey:@"FlashCamADC"];
    return dict;
}


#pragma mark •••AdcProviding Protocol
- (BOOL) onlineMaskBit:(int)bit
{
    return [self chanEnabled:bit];
}

- (BOOL) partOfEvent:(unsigned short)aChannel
{
    return NO;
}

- (uint32_t) eventCount:(int)aChannel
{
    if(aChannel >= 0 && aChannel<[self numberOfChannels]) return trigCount[aChannel];
    else return 0;
}

- (void) clearEventCounts
{
    [self clearCounts];
}

- (uint32_t) thresholdForDisplay:(unsigned short)aChan
{
    return [self threshold:aChan];
}

- (unsigned short) gainForDisplay:(unsigned short)aChan
{
    return [self adcGain:aChan];
}

- (void) initBoard
{
}

- (void) postAdcInfoProvidingValueChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcInfoProvidingValueChanged
                                                        object:self
                                                      userInfo: nil];
}


#pragma mark •••Archival

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    for(int i=0; i<[self numberOfChannels]; i++){
        [self setChanEnabled:i
                   withValue:[decoder decodeBoolForKey:[NSString stringWithFormat:@"chanEnabled%i", i]]];
        [self setTrigOutEnabled:i
                      withValue:[decoder decodeBoolForKey:[NSString stringWithFormat:@"trigOutEnabled%i", i]]];
        [self setBaseline:i
                withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"baseline%i", i]]];
        [self setThreshold:i
                 withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"threshold%i", i]]];
        [self setADCGain:i
               withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"adcGain%i", i]]];
        [self setTrigGain:i
                withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"trigGain%i", i]]];
        [self setShapeTime:i
                 withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"shapeTime%i", i]]];
        [self setFilterType:i
                  withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"filterType%i", i]]];
        [self setFlatTopTime:i
                   withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"flatTopTime%i", i]]];
        [self setPoleZeroTime:i
                    withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"poleZeroTime%i",  i]]];
        [self setPostTrigger:i
                   withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"postTrigger%i", i]]];
    }
    [self setBaseBias:[decoder decodeIntForKey:@"baseBias"]];
    [self setMajorityLevel:[decoder decodeIntForKey:@"majorityLevel"]];
    [self setMajorityWidth:[decoder decodeIntForKey:@"majorityWidth"]];
    [self setTrigOutEnable:[decoder decodeBoolForKey:@"trigOutEnable"]];
    [self setWFsamples:0];
    isRunning = NO;
    wfBuffer = NULL;
    bufferIndex = 0;
    takeDataIndex = 0;
    dataRecord = NULL;
    [self setTrigRates:[decoder decodeObjectForKey:@"trigRates"]];
    if(!trigRates){
        [self setTrigRates:[[[ORRateGroup alloc] initGroup:[self numberOfChannels] groupTag:0] autorelease]];
        [trigRates setIntegrationTime:5];
    }
    [trigRates resetRates];
    [trigRates calcRates];
    [self setWFrates:[decoder decodeObjectForKey:@"wfRates"]];
    if(!wfRates){
        [self setWFrates:[[[ORRateGroup alloc] initGroup:[self numberOfChannels] groupTag:1] autorelease]];
        [wfRates setIntegrationTime:5];
    }
    [wfRates resetRates];
    [wfRates calcRates];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    for(int i=0; i<[self numberOfChannels]; i++){
        [encoder encodeBool:chanEnabled[i]    forKey:[NSString stringWithFormat:@"chanEnabled%i",     i]];
        [encoder encodeBool:trigOutEnabled[i] forKey:[NSString stringWithFormat:@"trigOutEnabled:%i", i]];
        [encoder encodeInt:baseline[i]        forKey:[NSString stringWithFormat:@"baseline%i",        i]];
        [encoder encodeInt:threshold[i]       forKey:[NSString stringWithFormat:@"threshold%i",       i]];
        [encoder encodeInt:adcGain[i]         forKey:[NSString stringWithFormat:@"adcGain%i",         i]];
        [encoder encodeFloat:trigGain[i]      forKey:[NSString stringWithFormat:@"trigGain%i",        i]];
        [encoder encodeInt:shapeTime[i]       forKey:[NSString stringWithFormat:@"shapeTime%i",       i]];
        [encoder encodeInt:filterType[i]      forKey:[NSString stringWithFormat:@"filterType%i",      i]];
        [encoder encodeFloat:flatTopTime[i]   forKey:[NSString stringWithFormat:@"flatTopTime%i",     i]];
        [encoder encodeFloat:poleZeroTime[i]  forKey:[NSString stringWithFormat:@"poleZeroTime%i",    i]];
        [encoder encodeFloat:postTrigger[i]   forKey:[NSString stringWithFormat:@"postTrigger%i",     i]];
    }
    [encoder encodeInt:baseBias       forKey:@"baseBias"];
    [encoder encodeInt:majorityLevel  forKey:@"majorityLevel"];
    [encoder encodeInt:majorityWidth  forKey:@"majorityWidth"];
    [encoder encodeBool:trigOutEnable forKey:@"trigOutEnable"];
    [encoder encodeObject:wfRates     forKey:@"wfRates"];
    [encoder encodeObject:trigRates   forKey:@"trigRates"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* dict = [super addParametersToDictionary:dictionary];
    [self addCurrentState:dict boolArray:chanEnabled         forKey:@"Enabled"];
    [self addCurrentState:dict boolArray:trigOutEnabled      forKey:@"TrigOutEnabled"];
    [self addCurrentState:dict intArray:baseline             forKey:@"Baseline"];
    [self addCurrentState:dict intArray:threshold            forKey:@"Threshold"];
    [self addCurrentState:dict intArray:adcGain              forKey:@"ADCGain"];
    [self addCurrentState:dict floatArray:trigGain           forKey:@"TrigGain"];
    [self addCurrentState:dict intArray:shapeTime            forKey:@"ShapeTime"];
    [self addCurrentState:dict intArray:filterType           forKey:@"FilterType"];
    [self addCurrentState:dict floatArray:flatTopTime        forKey:@"FlatTopTime"];
    [self addCurrentState:dict floatArray:poleZeroTime       forKey:@"PoleZeroTime"];
    [self addCurrentState:dict floatArray:postTrigger        forKey:@"PostTrigger"];
    [dict setObject:[NSNumber numberWithInt:baseBias]        forKey:@"BaseBias"];
    [dict setObject:[NSNumber numberWithInt:majorityLevel]   forKey:@"MajorityLevel"];
    [dict setObject:[NSNumber numberWithInt:majorityWidth]   forKey:@"MajorityWidth"];
    [dict setObject:[NSNumber numberWithBool:trigOutEnable]  forKey:@"TrigOutEnable"];
    return dict;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary intArray:(int*)array forKey:(NSString*)key
{
    NSMutableArray* a = [NSMutableArray array];
    for(int i=0; i<[self numberOfChannels]; i++) [a addObject:[NSNumber numberWithInt:array[i]]];
    [dictionary setObject:a forKey:key];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(bool*)array forKey:(NSString*)key
{
    NSMutableArray* a = [NSMutableArray array];
    for(int i=0; i<[self numberOfChannels]; i++) [a addObject:[NSNumber numberWithBool:array[i]]];
    [dictionary setObject:a forKey:key];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary floatArray:(float*)array forKey:(NSString*)key
{
    NSMutableArray* a = [NSMutableArray array];
    for(int i=0; i<[self numberOfChannels]; i++) [a addObject:[NSNumber numberWithFloat:array[i]]];
    [dictionary setObject:a forKey:key];
}

#pragma mark •••HW Wizard

- (bool) hasParametersToRamp
{
    return YES;
}

- (int) numberOfChannels
{
    return kFlashCamADCChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"ADC Gain"];
    [p setFormat:@"##0" upperLimit:1<<16 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setADCGain:withValue:) getMethod:@selector(adcGain:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Baseline"];
    [p setFormat:@"##0" upperLimit:1<<16 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setBaseline:withValue:) getMethod:@selector(baseline:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Channel Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setChanEnabled:withValue:) getMethod:@selector(chanEnabled:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trig Out Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTrigOutEnabled:withValue:) getMethod:@selector(trigOutEnabled:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Filter Type"];
    [p setFormat:@"##0" upperLimit:2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFilterType:withValue:) getMethod:@selector(filterType:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Flat Top Time"];
    [p setFormat:@"##0" upperLimit:1<<16 lowerLimit:0 stepSize:1 units:@"ns"];
    [p setSetMethod:@selector(setFlatTopTime:withValue:) getMethod:@selector(flatTopTime:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pole Zero Time"];
    [p setFormat:@"##0" upperLimit:1000000 lowerLimit:0 stepSize:0.1 units:@"ns"];
    [p setSetMethod:@selector(setPoleZeroTime:withValue:) getMethod:@selector(poleZeroTime:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Shaping Time"];
    [p setFormat:@"##0" upperLimit:1<<16 lowerLimit:0 stepSize:1 units:@"ns"];
    [p setSetMethod:@selector(setShapeTime:withValue:) getMethod:@selector(shapeTime:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:1<<16 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trig Gain"];
    [p setFormat:@"##0" upperLimit:1000 lowerLimit:0 stepSize:0.1 units:@""];
    [p setSetMethod:@selector(setTrigGain:withValue:) getMethod:@selector(trigGain:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Post Trigger"];
    [p setFormat:@"##@" upperLimit:1000000 lowerLimit:0 stepSize:0.1 units:@"ns"];
    [p setSetMethod:@selector(setPostTrigger:withValue:) getMethod:@selector(postTrigger:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel  name:@"Crate"   className:@"ORFlashCamCrate"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel     name:@"Card"    className:@"ORFlashCamADCModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel    name:@"Channel" className:@"ORFlashCamADCModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
    NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Enabled"]) return [[cardDictionary objectForKey:@"chanEnabled"] objectAtIndex:aChannel];
    else return nil;
}

@end


@implementation ORFlashCamADCStdModel

- (void) makeMainController
{
    [self linkToController:@"ORFlashCamADCStdController"];
}

- (int) numberOfChannels
{
    return kFlashCamADCStdChannels;
}

- (unsigned int) fwType
{
    return 0;
}

@end
