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
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"

NSString* ORFlashCamADCModelChanEnabledChanged  = @"ORFlashCamADCModelChanEnabledChanged";
NSString* ORFlashCamADCModelBaselineChanged     = @"ORFlashCamADCModelBaselineChanged";
NSString* ORFlashCamADCModelBaseCalibChanged    = @"ORFlashCamADCModelBaseCalibChanged";
NSString* ORFlashCamADCModelThresholdChanged    = @"ORFlashCamADCModelThresholdChanged";
NSString* ORFlashCamADCModelADCGainChanged      = @"ORFlashCamADCModelADCGainChanged";
NSString* ORFlashCamADCModelTrigGainChanged     = @"ORFlashCamADCModelTrigGainChanged";
NSString* ORFlashCamADCModelShapeTimeChanged    = @"ORFlashCamADCModelShapeTimeChanged";
NSString* ORFlashCamADCModelFilterTypeChanged   = @"ORFlashCamADCModelFilterTypeChanged";
NSString* ORFlashCamADCModelPoleZeroTimeChanged = @"ORFlashCamADCModelPoleZeroTimeChanged";
NSString* ORFlashCamADCModelRateGroupChanged    = @"ORFlashCamADCModelRateGroupChanged";
NSString* ORFlashCamADCModelBufferFull          = @"ORFlashCamADCModelBufferFull";

@implementation ORFlashCamADCModel

- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    cardAddress = 0;
    for(int i=0; i<kMaxFlashCamADCChannels; i++){
        [self setChanEnabled:i  withValue:NO];
        [self setBaseline:i     withValue:-1];
        [self setBaseCalib:i    withValue:0.0];
        [self setThreshold:i    withValue:5000];
        [self setADCGain:i      withValue:0];
        [self setTrigGain:i     withValue:0.0];
        [self setShapeTime:i    withValue:5000];
        [self setFilterType:i   withValue:0.0];
        [self setPoleZeroTime:i withValue:58000];
        [self setShapeTime:i    withValue:5000];
        wfCount[i] = 0;
    }
    trigConnector = nil;
    isRunning = false;
    wfBuffer = NULL;
    bufferIndex = 0;
    takeDataIndex = 0;
    bufferedWFcount = 0;
    wfRates = nil;
    dataRecord = NULL;
    [self setWFsamples:0];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(ethConnector)  [ethConnector  release];
    if(trigConnector) [trigConnector release];
    [self setWFsamples:0];
    [wfRates release];
    [super dealloc];
}

- (void) setUpImage
{
    NSImage* cimage = [NSImage imageNamed:@"flashcam_adc"];
    NSSize size = [cimage size];
    NSSize newsize;
    newsize.width  = 0.1675*size.width;
    newsize.height = 0.1475*size.height;
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
    [trigConnector setSameGuardianIsOK:YES];
    [trigConnector setOffColor:[NSColor colorWithCalibratedRed:1 green:0.3 blue:1 alpha:1]];
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
    [ethConnector disconnect];
    [trigConnector disconnect];
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

- (unsigned int) nChanEnabled
{
    unsigned int n=0;
    for(unsigned int i=0; i<kMaxFlashCamADCChannels; i++) if(chanEnabled[i]) n++;
    return n;
}

- (bool) chanEnabled:(unsigned int)chan
{
    if(chan >= kMaxFlashCamADCChannels) return false;
    return chanEnabled[chan];
}

- (int) baseline:(unsigned int)chan
{
    if(chan >= kMaxFlashCamADCChannels) return 0;
    return baseline[chan];
}

- (float) baseCalib:(unsigned int)chan
{
    if(chan >= kMaxFlashCamADCChannels) return 0.0;
    return baseCalib[chan];
}

- (int) threshold:(unsigned int)chan{
    if(chan >= kMaxFlashCamADCChannels) return 0;
    return threshold[chan];
}

- (int) adcGain:(unsigned int)chan
{
    if(chan >= kMaxFlashCamADCChannels) return 0;
    return adcGain[chan];
}

- (float) trigGain:(unsigned int)chan
{
    if(chan >= kMaxFlashCamADCChannels) return 0.0;
    return trigGain[chan];
}

- (int) shapeTime:(unsigned int)chan
{
    if(chan >= kMaxFlashCamADCChannels) return 0;
    return shapeTime[chan];
}

- (float) filterType:(unsigned int)chan
{
    if(chan >= kMaxFlashCamADCChannels) return 0.0;
    return filterType[chan];
}

- (float) poleZeroTime:(unsigned int)chan
{
    if(chan >= kMaxFlashCamADCChannels) return 0.0;
    return poleZeroTime[chan];
}

- (ORConnector*) ethConnector
{
    return ethConnector;
}

- (ORConnector*) trigConnector
{
    return trigConnector;
}

- (ORRateGroup*) wfRates
{
    return wfRates;
}

- (id) rateObject:(short)channel
{
    return [wfRates rateObject:channel];
}

- (uint32_t) wfCount:(int)channel
{
    return wfCount[channel];
}

- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
    if(groupTag == 0){
        if(counterTag>=0 && counterTag<kMaxFlashCamADCChannels) return wfCount[counterTag];
        else return 0;
    }
    else return 0;
}

- (float) getRate:(short)channel
{
    if(channel>=0 && channel<kMaxFlashCamADCChannels){
        return [[self rateObject:channel] rate];
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
    if(chan >= kMaxFlashCamADCChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setChanEnabled:chan withValue:chanEnabled[chan]];
    chanEnabled[chan] = enabled;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelChanEnabledChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setBaseline:(unsigned int)chan withValue:(int)base
{
    if(chan >= kMaxFlashCamADCChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setBaseline:chan withValue:baseline[chan]];
    baseline[chan] = base;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelBaselineChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setBaseCalib:(unsigned int)chan withValue:(float)calib
{
    if(chan >= kMaxFlashCamADCChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setBaseCalib:chan withValue:baseCalib[chan]];
    baseCalib[chan] = calib;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelBaseCalibChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setThreshold:(unsigned int)chan withValue:(int)thresh
{
    if(chan >= kMaxFlashCamADCChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:chan withValue:threshold[chan]];
    threshold[chan] = thresh;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelThresholdChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setADCGain:(unsigned int)chan withValue:(int)gain
{
    if(chan >= kMaxFlashCamADCChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setADCGain:chan withValue:adcGain[chan]];
    adcGain[chan] = gain;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelADCGainChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setTrigGain:(unsigned int)chan withValue:(float)gain
{
    if(chan >= kMaxFlashCamADCChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigGain:chan withValue:trigGain[chan]];
    trigGain[chan] = gain;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelTrigGainChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setShapeTime:(unsigned int)chan withValue:(int)time
{
    if(chan >= kMaxFlashCamADCChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setShapeTime:chan withValue:shapeTime[chan]];
    shapeTime[chan] = time;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelShapeTimeChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setFilterType:(unsigned int)chan withValue:(float)type
{
    if(chan >= kMaxFlashCamADCChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setFilterType:chan withValue:filterType[chan]];
    filterType[chan] = type;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelFilterTypeChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setPoleZeroTime:(unsigned int)chan withValue:(float)time
{
    if(chan >= kMaxFlashCamADCChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPoleZeroTime:chan withValue:poleZeroTime[chan]];
    poleZeroTime[chan] = time;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelPoleZeroTimeChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setEthConnector:(ORConnector*)connector
{
    [connector retain];
    [ethConnector release];
    ethConnector = connector;
}

- (void) setTrigConnector:(ORConnector*)connector
{
    [connector retain];
    [trigConnector release];
    trigConnector = connector;
}

- (void) setWFsamples:(int)samples
{
    wfSamples = samples;
    if(wfBuffer){
        free(wfBuffer);
        wfBuffer = NULL;
    }
    if(dataRecord) free(dataRecord);
    dataRecordLength = 0;
    if(wfSamples > 0){
        wfBuffer = (unsigned short*) malloc(kFlashCamADCBufferLength * (wfSamples + 2));
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

- (void) setRateIntTime:(double)intTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntTime:[wfRates integrationTime]];
    [wfRates setIntegrationTime:intTime];
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

- (unsigned int) chanMask{
    unsigned int mask = 0;
    for(unsigned int i=0; i<kMaxFlashCamADCChannels; i++)
        if(chanEnabled[i]) mask += 1 << i;
    return mask;
}

- (NSMutableArray*) runFlagsForChannelOffset:(unsigned int)offset
{
    NSMutableArray* flags = [NSMutableArray array];
    [flags addObjectsFromArray:@[@"-am", [NSString stringWithFormat:@"%x,%x,1", [self chanMask], [self cardAddress]]]];
    for(unsigned int i=0; i<kMaxFlashCamADCChannels; i++){
        unsigned int j = i + offset;
        [flags addObjectsFromArray:@[@"-athr",  [self chFlag:j withInt:threshold[i]]]];
        if(![self chanEnabled:i]) continue;
        [flags addObjectsFromArray:@[@"-bldac", [self chFlag:j withInt:baseline[i]]]];
        [flags addObjectsFromArray:@[@"-bl",    [self chFlag:j withInt:baseCalib[i]]]];
        //[flags addObjectsFromArray:@[@"-ag",    [self chFlag:j withInt:adcGain[i]]]];
        //[flags addObjectsFromArray:@[@"-tgm",   [self chFlag:j withFloat:trigGain[i]]]];
        [flags addObjectsFromArray:@[@"-gs",    [self chFlag:j withInt:shapeTime[i]]]];
        //[flags addObjectsFromArray:@[@"-gf",    [self chFlag:j withFloat:filterType[i]]]];
        [flags addObjectsFromArray:@[@"-gpz",   [self chFlag:j withFloat:poleZeroTime[i]]]];
    }
    return flags;
}

- (void) printRunFlagsForChannelOffset:(unsigned int)offset
{
    NSLog(@"%@\n", [[self runFlagsForChannelOffset:offset] componentsJoinedByString:@" "]);
}


#pragma mark •••Data taker methods

- (void) event:(fcio_event*)event withIndex:(int)index andChannel:(unsigned int)channel
{
    if(channel >= kMaxFlashCamADCChannels){
        NSLog(@"ORFlashCamADCModel: invalid channel passed to event:withIndex:andChannel:, skipping packet\n");
        return;
    }
    else wfCount[channel] ++;
    // set the channel number and index to pass to takeData
    uint32_t hindex = bufferIndex * kFlashCamADCWFHeaderLength;
    wfHeaderBuffer[hindex] = (int) channel;
    wfHeaderBuffer[hindex+1] = index;
    // get the waveform header information from the fcio_event structure
    wfHeaderBuffer[hindex+2] = event->type;
    unsigned int offset = hindex + 3;
    for(unsigned int i=0; i<kFlashCamADCTimeOffsetLength; i++) wfHeaderBuffer[offset+i] = event->timeoffset[i];
    offset += kFlashCamADCTimeOffsetLength;
    for(unsigned int i=0; i<kFlashCamADCDeadRegionLength; i++) wfHeaderBuffer[offset+i] = event->deadregion[i];
    offset += kFlashCamADCDeadRegionLength;
    for(unsigned int i=0; i<kFlashCamADCTimeStampLength; i++)  wfHeaderBuffer[offset+i] = event->timestamp[i];
    // get the waveform for this channel at the index provided from the fcio_event structure
    memcpy(wfBuffer+bufferIndex*(wfSamples+2), event->theader[index], (wfSamples+2)*sizeof(unsigned short));
    // increment the buffer index
    bufferIndex = (bufferIndex + 1) % kFlashCamADCBufferLength;
    bufferedWFcount ++;
    if(bufferedWFcount == kFlashCamDefaultBuffer){
        NSLog(@"ORFlashCamADCModel: buffer full for card ID 0x%x crate %d slot %d\n",
              [self cardAddress], [self crate], [self slot]);
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamADCModelBufferFull object:self];
    }
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    @try{
        if(wfSamples == 0) return;
        else if(bufferIndex == takeDataIndex) return;
        else{
            isRunning = true;
            uint32_t hindex = takeDataIndex * kFlashCamADCWFHeaderLength;
            dataRecord[0] = dataId | (dataRecordLength&0x3ffff);
            dataRecord[1] = dataLengths | (wfHeaderBuffer[hindex+2]&0x3f);
            dataRecord[2] = location | ((wfHeaderBuffer[hindex]&0xf) << 10) | (wfHeaderBuffer[hindex+1]&0x3ff);
            for(unsigned int i=3; i<kFlashCamADCWFHeaderLength; i++){
                dataRecord[i] = (uint32_t) wfHeaderBuffer[hindex+i];
            }
            uint32_t windex = takeDataIndex * (wfSamples + 2);
            dataRecord[kFlashCamADCWFHeaderLength] = (wfBuffer[windex+1] << 16) | wfBuffer[windex];
            memcpy(dataRecord+kFlashCamADCWFHeaderLength+1, wfBuffer+windex+2, wfSamples*sizeof(unsigned short));
            [aDataPacket addLongsToFrameBuffer:dataRecord length:dataRecordLength];
            takeDataIndex = (takeDataIndex + 1) % kFlashCamADCBufferLength;
            bufferedWFcount --;
        }
    }
    @catch(NSException* localException){
        NSLogError(@"", @"ORFlashCamADCModel error", @"", nil);
        [self incExceptionCount];
        [localException raise];
    }
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORFlashCamADCModel"];
    location = (([self crateNumber]&0x1f) << 25) | (([self slot]&0x1f) << 22);
    location = (([self cardAddress]&0xff) << 14);
    [self startRates];
    isRunning = false;
    takeDataIndex = 0;
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    // finish reading out buffer first
    isRunning = false;
    [wfRates stop];
    [self setWFsamples:0];
    takeDataIndex = 0;
}

- (void) reset
{
}

-(void) startRates
{
    [self clearWFcounts];
    [wfRates start:self];
}

- (void) clearWFcounts
{
    for(int i=0;i<kMaxFlashCamADCChannels;i++) wfCount[i] = 0;
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"ORFlashCamADCWaveformDecoder",  @"decoder",
                       [NSNumber numberWithLong:dataId], @"dataId",
                       [NSNumber numberWithBool:YES],    @"variable",
                       [NSNumber numberWithLong:-1],     @"length", nil];
    [dict setObject:d forKey:@"FlashCamADC"];
    return dict;
}


#pragma mark •••Archival

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setCardAddress:[[decoder decodeObjectForKey:@"cardAddress"] unsignedIntValue]];
    for(int i=0; i<kMaxFlashCamADCChannels; i++){
        [self setChanEnabled:i
                   withValue:[decoder decodeBoolForKey:[NSString stringWithFormat:@"chanEnabled%i", i]]];
        [self setBaseline:i
                withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"baseline%i", i]]];
        [self setBaseCalib:i
                 withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"baseCalib%i", i]]];
        [self setThreshold:i
                 withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"threshold%i", i]]];
        [self setADCGain:i
               withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"adcGain%i", i]]];
        [self setTrigGain:i
                withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"trigGain%i", i]]];
        [self setShapeTime:i
                 withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"shapeTime%i", i]]];
        [self setFilterType:i
                  withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"filterType%i", i]]];
        [self setPoleZeroTime:i
                    withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"poleZeroTime%i",  i]]];
    }
    [self setEthConnector: [decoder decodeObjectForKey:@"ethConnector"]];
    [self setTrigConnector:[decoder decodeObjectForKey:@"trigConnector"]];
    firmwareVer = [[[NSArray alloc] init] retain];
    isRunning = NO;
    wfBuffer = NULL;
    bufferIndex = 0;
    takeDataIndex = 0;
    taskdata = nil;
    dataRecord = NULL;
    [self setWFsamples:0];
    [self setWFrates:[decoder decodeObjectForKey:@"wfRates"]];
    if(!wfRates){
        [self setWFrates:[[[ORRateGroup alloc] initGroup:kMaxFlashCamADCChannels groupTag:0] autorelease]];
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
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:cardAddress] forKey:@"cardAddress"];
    for(int i=0; i<kMaxFlashCamADCChannels; i++){
        [encoder encodeBool:chanEnabled[i] forKey:[NSString stringWithFormat:@"chanEnabled%i", i]];
        [encoder encodeInt:baseline[i] forKey:[NSString stringWithFormat:@"baseline%i", i]];
        [encoder encodeFloat:baseCalib[i] forKey:[NSString stringWithFormat:@"baseCalib%i", i]];
        [encoder encodeInt:threshold[i] forKey:[NSString stringWithFormat:@"threshold%i", i]];
        [encoder encodeInt:adcGain[i] forKey:[NSString stringWithFormat:@"adcGain%i", i]];
        [encoder encodeFloat:trigGain[i] forKey:[NSString stringWithFormat:@"trigGain%i", i]];
        [encoder encodeInt:shapeTime[i] forKey:[NSString stringWithFormat:@"shapeTime%i", i]];
        [encoder encodeFloat:filterType[i] forKey:[NSString stringWithFormat:@"filterType%i", i]];
        [encoder encodeFloat:poleZeroTime[i] forKey:[NSString stringWithFormat:@"poleZeroTime%i", i]];
    }
    [encoder encodeObject:ethConnector  forKey:@"ethConnector"];
    [encoder encodeObject:trigConnector forKey:@"trigConnector"];
    [encoder encodeObject:wfRates       forKey:@"wfRates"];
}

#pragma mark •••HW Wizard

- (bool) hasParametersToRamp
{
    return YES;
}

- (int) numberOfChannels
{
    return kMaxFlashCamADCChannels;
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
    [p setName:@"BaseCalib"];
    [p setFormat:@"##0" upperLimit:4000.0 lowerLimit:0.0 stepSize:0.1 units:@""];
    [p setSetMethod:@selector(setBaseCalib:withValue:) getMethod:@selector(baseCalib:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Channel Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setChanEnabled:withValue:) getMethod:@selector(chanEnabled:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Filter Type"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:0.01 units:@""];
    [p setSetMethod:@selector(setFilterType:withValue:) getMethod:@selector(filterType:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pole Zero Time"];
    [p setFormat:@"##0" upperLimit:200000 lowerLimit:0 stepSize:0.1 units:@""];
    [p setSetMethod:@selector(setPoleZeroTime:withValue:) getMethod:@selector(poleZeroTime:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Shaping Time"];
    [p setFormat:@"##0" upperLimit:1<<16 lowerLimit:0 stepSize:1 units:@""];
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
