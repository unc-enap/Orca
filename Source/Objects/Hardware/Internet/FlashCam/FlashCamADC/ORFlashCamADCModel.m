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

NSString* ORFlashCamADCModelChanEnabledChanged           = @"ORFlashCamADCModelChanEnabledChanged";
NSString* ORFlashCamADCModelTrigOutEnabledChanged        = @"ORFlashCamADCModelTrigOutEnabledChanged";
NSString* ORFlashCamADCModelBaselineChanged              = @"ORFlashCamADCModelBaselineChanged";
NSString* ORFlashCamADCModelBaseBiasChanged              = @"ORFlashCamADCModelBaseBiasChanged";
NSString* ORFlashCamADCModelThresholdChanged             = @"ORFlashCamADCModelThresholdChanged";
NSString* ORFlashCamADCModelADCGainChanged               = @"ORFlashCamADCModelADCGainChanged";
NSString* ORFlashCamADCModelTrigGainChanged              = @"ORFlashCamADCModelTrigGainChanged";
NSString* ORFlashCamADCModelShapeTimeChanged             = @"ORFlashCamADCModelShapeTimeChanged";
NSString* ORFlashCamADCModelFilterTypeChanged            = @"ORFlashCamADCModelFilterTypeChanged";
NSString* ORFlashCamADCModelFlatTopTimeChanged           = @"ORFlashCamADCModelFlatTopTimeChanged";
NSString* ORFlashCamADCModelPoleZeroTimeChanged          = @"ORFlashCamADCModelPoleZeroTimeChanged";
NSString* ORFlashCamADCModelPostTriggerChanged           = @"ORFlashCamADCModelPostTriggerChanged";
NSString* ORFlashCamADCModelBaselineSlewChanged          = @"ORFlashCamADCModelBaselineSlewChanged";
NSString* ORFlashCamADCModelSWTrigIncludeChanged         = @"ORFlashCamADCModelSWTrigIncludeChanged";
NSString* ORFlashCamADCModelMajorityLevelChanged         = @"ORFLashCamADCModelMajorityLevelChanged";
NSString* ORFlashCamADCModelMajorityWidthChanged         = @"ORFlashCamADCModelMajorityWidthChanged";
NSString* ORFlashCamADCModelRateGroupChanged             = @"ORFlashCamADCModelRateGroupChanged";
NSString* ORFlashCamADCModelEnableBaselineHistoryChanged = @"ORFlashCamADCModelEnableBaselineHistoryChanged";
NSString* ORFlashCamADCModelBaselineHistoryChanged       = @"ORFlashCamADCModelBaselineHistoryChanged";
NSString* ORFlashCamADCModelBaselineSampleTimeChanged    = @"ORFlashCamADCModelBaselineSampleTimeChanged";

@implementation ORFlashCamADCModel

- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setCardAddress:0];
    wfRates   = nil;
    trigRates = nil;
    enableBaselineHistory = true;
    baselineSampleTime = 10.0;
    for(int i=0; i<[self numberOfChannels]; i++){
        [self setChanEnabled:i    withValue:false];
        [self setTrigOutEnabled:i withValue:false];
        [self setBaseline:i       withValue:-1];
        [self setThreshold:i      withValue:5000];
        [self setADCGain:i        withValue:0];
        [self setTrigGain:i       withValue:0.0];
        [self setShapeTime:i      withValue:16*256];
        [self setFilterType:i     withValue:1];
        [self setFlatTopTime:i    withValue:16.0*128];
        [self setPoleZeroTime:i   withValue:16.0*4096*6];
        [self setPostTrigger:i    withValue:0.0];
        [self setBaselineSlew:i   withValue:0];
        [self setSWTrigInclude:i  withValue:false];
        wfCount[i]   = 0;
        trigCount[i] = 0;
        baselineHistory[i] = [[ORTimeRate alloc] init];
        [baselineHistory[i] setLastAverageTime:[NSDate date]];
        [baselineHistory[i] setSampleTime:baselineSampleTime];
    }
    for(int i=[self numberOfChannels]; i<kMaxFlashCamADCChannels; i++) baselineHistory[i] = nil;
    baseBias      = 0;
    majorityLevel = 1;
    majorityWidth = 1;
    trigOutEnable = false;
    trigConnector = nil;
    isRunning     = false;
    dataRecord    = NULL;
    [self setWFsamples:0];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self setWFsamples:0];
    [wfRates release];
    [trigRates release];
    for(int i=0; i<[self numberOfChannels]; i++) [baselineHistory[i] release];
    [inFlux release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
    @try{
        [self performSelector:@selector(postConfig) withObject:nil afterDelay:3];
        [self registerNotificationObservers];
        inFlux = [[[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORInFluxDBModel,1"]retain];
    }
    @catch(NSException* localException){ }
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
           
    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
}

- (void) configurationChanged:(NSNotification*)aNote
{
    [inFlux release];
    inFlux = [[[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORInFluxDBModel,1"]retain];
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
    [image release];
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

- (int) baselineSlew:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return 0;
    return baselineSlew[chan];
}

- (bool) swTrigInclude:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return false;
    return swTrigInclude[chan];
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

- (bool) isRunning
{
    return isRunning;
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

- (bool) enableBaselineHistory
{
    return enableBaselineHistory;
}

- (double) baselineSampleTime
{
    return baselineSampleTime;
}

- (ORTimeRate*) baselineHistory:(unsigned int)chan
{
    if(chan >= [self numberOfChannels]) return nil;
    return baselineHistory[chan];
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
    shapeTime[chan] = MIN(MAX(1.0, time), 40000.0);
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
    poleZeroTime[chan] = MAX(0.0, time);
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

- (void) setBaselineSlew:(unsigned int)chan withValue:(int)slew
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineSlew:chan withValue:baselineSlew[chan]];
    baselineSlew[chan] = MIN(MAX(-8, slew), 8);
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelBaselineSlewChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setSWTrigInclude:(unsigned int)chan withValue:(bool)include
{
    if(chan >= [self numberOfChannels]) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setSWTrigInclude:chan withValue:swTrigInclude[chan]];
    swTrigInclude[chan] = include;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelSWTrigIncludeChanged
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
    if(dataRecord){
        free(dataRecord);
        dataRecord = NULL;
    }
    dataRecordLength = 0;
    if(wfSamples > 0){
        // first 3 items in WF header get put into Orca header, then trace header gets moved to WF header
        dataLengths = ((wfSamples&0xffff) << 6) | (((kFlashCamADCWFHeaderLength-3+1)&0x3f) << 22);
        dataLengths = dataLengths | ((kFlashCamADCOrcaHeaderLength&0xf) << 28);
        dataRecordLength = kFlashCamADCOrcaHeaderLength + (kFlashCamADCWFHeaderLength - 3 + 1) + wfSamples/2;
        dataRecord = (uint32_t*) malloc(dataRecordLength * sizeof(uint32_t));
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

- (void) setEnableBaselineHistory:(bool)enable
{
    if(enable == enableBaselineHistory) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableBaselineHistory:enableBaselineHistory];
    enableBaselineHistory = enable;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelEnableBaselineHistoryChanged object:self];
}

- (void) setBaselineSampleTime:(double)time
{
    if(time == baselineSampleTime) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineSampleTime:baselineSampleTime];
    baselineSampleTime = MAX(1.0, time);
    for(unsigned int i=0; i<[self numberOfChannels]; i++) if(baselineHistory[i]) [baselineHistory[i] setSampleTime:time];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelBaselineSampleTimeChanged object:self];
}

- (void) setBaselineHistory:(unsigned int)chan withTimeRate:(ORTimeRate*)baseHist
{
    if(chan >= [self numberOfChannels]) return;
    if(baseHist == baselineHistory[chan]) return;
    [baseHist retain];
    [baselineHistory[chan] release];
    baselineHistory[chan] = baseHist;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelBaselineHistoryChanged object:self];
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
    [flags addObjectsFromArray:@[@"-amajl", [NSString stringWithFormat:@"%d,%d,1", [self majorityLevel], index]]];
    [flags addObjectsFromArray:@[@"-amajw", [NSString stringWithFormat:@"%d,%d,1", [self majorityWidth], index]]];
    for(unsigned int i=0; i<[self numberOfChannels]; i++){
        unsigned int j = i + offset;
        if(trigAll || [self chanEnabled:i]) [flags addObjectsFromArray:@[@"-athr",  [self chFlag:j withInt:threshold[i]]]];
        if(![self chanEnabled:i]) continue;
        [flags addObjectsFromArray:@[@"-bldac",  [self chFlag:j withInt:baseline[i]]]];
        [flags addObjectsFromArray:@[@"-ag",     [self chFlag:j withInt:adcGain[i]]]];
        [flags addObjectsFromArray:@[@"-tgm",    [self chFlag:j withFloat:trigGain[i]]]];
        [flags addObjectsFromArray:@[@"-pthr",   [self chFlag:j withFloat:postTrigger[i]]]];
        if([self fwType] == 1){
            [flags addObjectsFromArray:@[@"-gs",     [self chFlag:j withInt:shapeTime[i]]]];
            [flags addObjectsFromArray:@[@"-gpz",    [self chFlag:j withFloat:poleZeroTime[i]]]];
            [flags addObjectsFromArray:@[@"-gbs",    [self chFlag:j withInt:baselineSlew[i]]]];
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
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //nothing to yet. A call from the Listener ships the data.
}

- (void) shipEvent:(fcio_event*)event withIndex:(int)index andChannel:(unsigned int)channel use:(ORDataPacket*)aDataPacket includeWF:(bool)includeWF;
{
    if(channel >= [self numberOfChannels]){
        NSLog(@"ORFlashCamADCModel: invalid channel passed to event:withIndex:andChannel:, skipping packet\n");
        return;
    }
    else{
        if(includeWF) wfCount[channel] ++;
        int fpgaEnergy = event->theader[index][1];
        if(fpgaEnergy > 0){
            trigCount[channel]++;
            [self shipToInflux:channel energy:fpgaEnergy baseline:event->theader[index][0]];
        }
    }
    
    //ship the data
    uint32_t lengths = dataLengths;
    if(!includeWF) lengths &= 0xFFFC0003F;
    dataRecord[0] = dataId   | (dataRecordLength&0x3ffff);
    dataRecord[1] = lengths  | (event->type&0x3f);
    dataRecord[2] = location | ((channel&0x1f) << 9) | (index&0x1ff);
    int offset = 3;
    for(unsigned int i=0; i<kFlashCamADCTimeOffsetLength; i++) dataRecord[offset++] = event->timeoffset[i];
    for(unsigned int i=0; i<kFlashCamADCDeadRegionLength; i++) dataRecord[offset++] = event->deadregion[i];
    for(unsigned int i=0; i<kFlashCamADCTimeStampLength;  i++) dataRecord[offset++] = event->timestamp[i];
    dataRecord[kFlashCamADCWFHeaderLength]  = (unsigned int)(*(event->theader[index]+1) << 16);
    dataRecord[kFlashCamADCWFHeaderLength] |= (unsigned int)(*event->theader[index]);
    if(includeWF)
        memcpy(dataRecord+kFlashCamADCWFHeaderLength+1, event->theader[index]+2, wfSamples*sizeof(unsigned short));
    [aDataPacket addLongsToFrameBuffer:dataRecord length:dataRecordLength];
}

- (void) shipToInflux:(int)aChan energy:(int)anEnergy baseline:(int)aBaseline
{
    if(inFlux){
        //don't send to inFlux for a few seconds to avoid 'start of run' zeros
        NSTimeInterval dt = [startTime timeIntervalSinceNow];
        if(fabs(dt) < kDeadBandTime)return;
        
        ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement measurementForBucket:@"L200" org:[inFlux org]];
        [aCmd start   : @"flashCamADC"];
        [aCmd addTag  : @"location"     withString:[NSString stringWithFormat:@"%02d_%02d_%02d",[self crateNumber],[self slot],aChan]];
        [aCmd addField: @"fpgaEnergy"   withLong:anEnergy];
        [aCmd addField: @"fpgaBaseline" withLong:aBaseline];
        [aCmd setTimeStamp:[NSDate timeIntervalSinceReferenceDate]];
        [inFlux executeDBCmd:aCmd];
    }
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [startTime release];
    startTime = [[NSDate date]retain];
    if([self fwType] == 0)
        [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORFlashCamADCStdModel"];
    else
        [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORFlashCamADCModel"];
    location = (([self crateNumber] & 0x1f) << 27) | (([self slot] & 0x1f) << 22);
    location = location | ((([self cardAddress] & 0xff0) >> 4) << 14);
    [self startRates];
    isRunning = true;
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    isRunning = false;
    [wfRates   stop];
    [trigRates stop];
    [self setWFsamples:0];
    [startTime release];
    startTime = nil;
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
                       @"ORFlashCamWaveformDecoder",     @"decoder",
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
        [self setBaselineSlew:i
                    withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"baselineSlew%i", i]]];
        [self setSWTrigInclude:i
                     withValue:[decoder decodeBoolForKey:[NSString stringWithFormat:@"swTrigInclude%i", i]]];
        if(!baselineHistory[i]){
            baselineHistory[i] = [[ORTimeRate alloc] init];
            [baselineHistory[i] setLastAverageTime:[NSDate date]];
            [baselineHistory[i] setSampleTime:baselineSampleTime];
        }
    }
    [self setBaseBias:[decoder decodeIntForKey:@"baseBias"]];
    [self setMajorityLevel:[decoder decodeIntForKey:@"majorityLevel"]];
    [self setMajorityWidth:[decoder decodeIntForKey:@"majorityWidth"]];
    [self setTrigOutEnable:[decoder decodeBoolForKey:@"trigOutEnable"]];
    [self setEnableBaselineHistory:[decoder decodeBoolForKey:@"enableBaselineHistory"]];
    [self setBaselineSampleTime:[decoder decodeDoubleForKey:@"baselineSampleTime"]];
    [self setWFsamples:0];
    isRunning = false;
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
        [encoder encodeBool:trigOutEnabled[i] forKey:[NSString stringWithFormat:@"trigOutEnabled%i", i]];
        [encoder encodeInt:baseline[i]        forKey:[NSString stringWithFormat:@"baseline%i",        i]];
        [encoder encodeInt:threshold[i]       forKey:[NSString stringWithFormat:@"threshold%i",       i]];
        [encoder encodeInt:adcGain[i]         forKey:[NSString stringWithFormat:@"adcGain%i",         i]];
        [encoder encodeFloat:trigGain[i]      forKey:[NSString stringWithFormat:@"trigGain%i",        i]];
        [encoder encodeInt:shapeTime[i]       forKey:[NSString stringWithFormat:@"shapeTime%i",       i]];
        [encoder encodeInt:filterType[i]      forKey:[NSString stringWithFormat:@"filterType%i",      i]];
        [encoder encodeFloat:flatTopTime[i]   forKey:[NSString stringWithFormat:@"flatTopTime%i",     i]];
        [encoder encodeFloat:poleZeroTime[i]  forKey:[NSString stringWithFormat:@"poleZeroTime%i",    i]];
        [encoder encodeFloat:postTrigger[i]   forKey:[NSString stringWithFormat:@"postTrigger%i",     i]];
        [encoder encodeInt:baselineSlew[i]    forKey:[NSString stringWithFormat:@"baselineSlew%i",    i]];
        [encoder encodeBool:swTrigInclude[i]  forKey:[NSString stringWithFormat:@"swTrigInclude%i",   i]];
    }
    [encoder encodeInt:baseBias               forKey:@"baseBias"];
    [encoder encodeInt:majorityLevel          forKey:@"majorityLevel"];
    [encoder encodeInt:majorityWidth          forKey:@"majorityWidth"];
    [encoder encodeBool:trigOutEnable         forKey:@"trigOutEnable"];
    [encoder encodeObject:wfRates             forKey:@"wfRates"];
    [encoder encodeObject:trigRates           forKey:@"trigRates"];
    [encoder encodeBool:enableBaselineHistory forKey:@"enableBaselineHistory"];
    [encoder encodeDouble:baselineSampleTime  forKey:@"baselineSampleTime"];
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
    [self addCurrentState:dict intArray:baselineSlew         forKey:@"BaselineSlew"];
    [self addCurrentState:dict boolArray:swTrigInclude       forKey:@"SWTrigInclude"];
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
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Baseline Slew"];
    [p setFormat:@"##0" upperLimit:8 lowerLimit:-8 stepSize:1 units:@""];
    [p setSetMethod:@selector(setBaselineSlew:withValue:) getMethod:@selector(baselineSlew:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"SW Trigger Include"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setSWTrigInclude:withValue:) getMethod:@selector(swTrigInclude:)];
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


@implementation ORFlashCamADCModel (private)

- (void) postConfig
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(postConfig) object:nil];
    [self postCouchDBRecord];
    [self performSelector:@selector(postConfig) withObject:nil afterDelay:60];
}

- (void) postCouchDBRecord
{
    NSMutableDictionary* values = [NSMutableDictionary dictionary];
    [values setObject:[NSNumber numberWithInt:[self crateNumber]]          forKey:@"crate"];
    [values setObject:[NSNumber numberWithInt:[self slot]]                 forKey:@"slot"];
    [values setObject:[NSNumber numberWithUnsignedInt:[self cardAddress]]  forKey:@"cardAddress"];
    [values setObject:[NSNumber numberWithUnsignedInt:[self fcioID]]       forKey:@"fcioID"];
    [values setObject:[NSNumber numberWithUnsignedInt:[self status]]       forKey:@"status"];
    [values setObject:[NSNumber numberWithUnsignedInt:[self totalErrors]]  forKey:@"totalErrors"];
    [values setObject:[NSNumber numberWithInt:[self baseBias]]             forKey:@"baseBias"];
    [values setObject:[NSNumber numberWithInt:[self majorityLevel]]        forKey:@"majorityLevel"];
    [values setObject:[NSNumber numberWithInt:[self majorityWidth]]        forKey:@"majorityWidth"];
    [values setObject:[NSNumber numberWithBool:[self trigOutEnable]]       forKey:@"trigOutEnable"];
    [values setObject:[NSNumber numberWithBool:isRunning]                  forKey:@"isRunning"];
    for(int i=0; i<[self numberOfChannels]; i++){
        NSMutableDictionary* chval = [NSMutableDictionary dictionary];
        [chval setObject:[NSNumber numberWithBool:[self chanEnabled:i]]    forKey:@"chanEnabled"];
        [chval setObject:[NSNumber numberWithBool:[self trigOutEnabled:i]] forKey:@"trigOutEnabled"];
        [chval setObject:[NSNumber numberWithInt:[self baseline:i]]        forKey:@"baseline"];
        [chval setObject:[NSNumber numberWithInt:[self threshold:i]]       forKey:@"threshold"];
        [chval setObject:[NSNumber numberWithInt:[self shapeTime:i]]       forKey:@"shapeTime"];
        [chval setObject:[NSNumber numberWithInt:[self filterType:i]]      forKey:@"filterType"];
        [chval setObject:[NSNumber numberWithInt:[self adcGain:i]]         forKey:@"adcGain"];
        [chval setObject:[NSNumber numberWithFloat:[self trigGain:i]]      forKey:@"trigGain"];
        [chval setObject:[NSNumber numberWithFloat:[self flatTopTime:i]]   forKey:@"flatTopTime"];
        [chval setObject:[NSNumber numberWithFloat:[self poleZeroTime:i]]  forKey:@"poleZeroTime"];
        [chval setObject:[NSNumber numberWithFloat:[self postTrigger:i]]   forKey:@"postTrigger"];
        [chval setObject:[NSNumber numberWithInt:[self baselineSlew:i]]    forKey:@"baselineSlew"];
        [chval setObject:[NSNumber numberWithBool:[self swTrigInclude:i]]  forKey:@"swTrigInclude:"];
        if([self enableBaselineHistory]){
            NSArray* baselines = [[self baselineHistory:i] ratesAsArray];
            int start = MAX(0, (int) [baselines count]-1024);
            int length = MIN((int) [baselines count], 1024);
            [chval setObject:[baselines subarrayWithRange:NSMakeRange(start, length)]
                      forKey:@"baselineHistory"];
        }
        [values setObject:chval forKey:[NSString stringWithFormat:@"channel_%d", i]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord"
                                                        object:self
                                                      userInfo:values];
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

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel  name:@"Crate"   className:@"ORFlashCamCrate"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel     name:@"Card"    className:@"ORFlashCamADCStdModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel    name:@"Channel" className:@"ORFlashCamADCStdModel"]];
    return a;
}

@end
