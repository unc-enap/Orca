//
//  MJDPreAmpModel.m
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
#import "ORMJDPreAmpModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"
#import "ORAlarm.h"
#import "ORMJDSegmentGroup.h"
#import "MajoranaModel.h"
#import "ORCard.h"
#import "ORRunningAverageGroup.h"
#import "SynthesizeSingleton.h"


#pragma mark ¥¥¥Notification Strings
NSString* ORMJDPreAmpModelBoardRevChanged   = @"ORMJDPreAmpModelBoardRevChanged";
NSString* ORMJDPreAmpModelAdcEnabledMaskChanged = @"ORMJDPreAmpModelAdcEnabledMaskChanged";
NSString* ORMJDPreAmpModelPollTimeChanged	= @"ORMJDPreAmpModelPollTimeChanged";
NSString* ORMJDPreAmpModelShipValuesChanged = @"ORMJDPreAmpModelShipValuesChanged";
NSString* ORMJDPreAmpLoopForeverChanged		= @"ORMJDPreAmpLoopForeverChanged";
NSString* ORMJDPreAmpPulseCountChanged		= @"ORMJDPreAmpPulseCountChanged";
NSString* ORMJDPreAmpEnabledChanged			= @"ORMJDPreAmpEnabledChanged";
NSString* ORMJDPreAmpAttenuatedChanged		= @"ORMJDPreAmpAttenuatedChanged";
NSString* ORMJDPreAmpFinalAttenuatedChanged	= @"ORMJDPreAmpFinalAttenuatedChanged";
NSString* ORMJDPreAmpPulserMaskChanged		= @"ORMJDPreAmpPulserMaskChanged";
NSString* ORMJDPreAmpPulseHighTimeChanged	= @"ORMJDPreAmpPulseHighTimeChanged";
NSString* ORMJDPreAmpPulseLowTimeChanged	= @"ORMJDPreAmpPulseLowTimeChanged";
NSString* ORMJDPreAmpDacArrayChanged		= @"ORMJDPreAmpDacArrayChanged";
NSString* ORMJDPreAmpDacChanged				= @"ORMJDPreAmpDacChanged";
NSString* ORMJDPreAmpAmplitudeArrayChanged	= @"ORMJDPreAmpAmplitudeArrayChanged";
NSString* ORMJDPreAmpAmplitudeChanged		= @"ORMJDPreAmpAmplitudeChanged";
NSString* MJDPreAmpSettingsLock				= @"MJDPreAmpSettingsLock";
NSString* ORMJDPreAmpAdcChanged				= @"ORMJDPreAmpAdcChanged";
NSString* ORMJDFeedBackResistorArrayChanged = @"ORMJDFeedBackResistorArrayChanged";
NSString* ORMJDBaselineVoltageArrayChanged  = @"ORMJDBaselineVoltageArrayChanged";
NSString* ORMJDFeedBackResistorChanged      = @"ORMJDFeedBackResistorChanged";
NSString* ORMJDBaselineVoltageChanged		= @"ORMJDBaselineVoltageChanged";
NSString* ORMJDPreAmpModelDetectorNameChanged	= @"ORMJDPreAmpModelDetectorNameChanged";
NSString* ORMJDPreAmpModelConnectionChanged		= @"ORMJDPreAmpModelConnectionChanged";
NSString* ORMJDPreAmpModelDoNotUseHWMapChanged  = @"ORMJDPreAmpModelDoNotUseHWMapChanged";
NSString* ORMJDPreAmpModelFirmwareRevChanged    = @"ORMJDPreAmpModelFirmwareRevChanged";
NSString* ORMJDPreAmpModelRateSpiked        = @"ORMJDPreAmpModelRateSpiked";

#pragma mark ¥¥¥Local Strings
static NSString* MJDPreAmpInputConnector     = @"MJDPreAmpInputConnector";

#pragma mark ¥¥¥Local Definitions
#define kDAC1 0x80000000
#define kDAC2 0x81000000
#define kDAC3 0x82000000
#define kDAC4 0x83000000

#define kDACA_H_Base		0x00200000
#define kPulserLowTimeMask	0xC0000000
#define kPulserHighTimeMask	0xC1000000
#define kAttnPatternMask	0xC2000000
#define kPulserStartMask	0xC3000000
#define kPulserLoopForever  (0x1<<23)
#define kPulserUseLoopCount (0x1<<22)

#define kADC1		 0xE0000000
#define kADC2		 0xE1000000

#define kControlReg  0x4
#define kRangeReg1   0x5
#define kRangeReg2   0x6

#define kBipolar10V  0x0
#define kBipolar5V   0x1
#define kBipolar2_5V 0x2
#define kUniploar10V 0x3

#define kSingleEnded 0x0
#define kPseudoDiff  0x3

#define kTwosComplement 0x0
#define kStraightBinary 0x1

struct {
    uint32_t adcSelection;
    BOOL calculateLeakageCurrent;
    int leakageCurrentIndex;
    uint32_t mode;
	BOOL  conversionType;
    float slope;
    float intercept;
    int32_t adcOffset;
} mjdPreAmpTable[16] = {
    {kADC1,YES, 0, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //0,0
    {kADC1,YES, 1, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //0,1
    {kADC1,YES, 2, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //0,2
    {kADC1,YES, 3, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //0,3
    {kADC1,YES, 4, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //0,4
    {kADC1,NO, -1, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //0,5
    {kADC1,NO, -1, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //0,6
    {kADC1,NO, -1, kPseudoDiff,  kTwosComplement,-0.47,2498, 4096},	  //0,7
    {kADC2,YES, 5, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //1,0
    {kADC2,YES, 6, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //1,1
    {kADC2,YES, 7, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //1,2
    {kADC2,YES, 8, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //1,3
    {kADC2,YES, 9, kSingleEnded, kTwosComplement,2*20/8192., 0, 0},   //1,4
    {kADC2,NO, -1, kSingleEnded, kTwosComplement,4*20/8192., 0, 0},   //1,5
    {kADC2,NO, -1, kSingleEnded, kTwosComplement,4*20/8192., 0, 0},   //1,6
    {kADC2,NO, -1, kPseudoDiff,  kTwosComplement,-0.47,2498, 4096}	  //1,7
};

#pragma mark ¥¥¥Private Implementation
@interface ORMJDPreAmpModel (private)
- (void) updateTrends;
- (void) calculateLeakageCurrentForAdc:(int) aChan;
- (void) postCouchDBRecord;
- (void) clearAllAlarms;
@end

#pragma mark ¥¥¥Implementation
@implementation ORMJDPreAmpModel
#pragma mark ¥¥¥initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self setUpArrays];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[ORMjdPreAmpPollQueue sharedMjdPreAmpPollQueue] cancelAllOperations];
    [lastDataBaseUpdate release];
    [dacs release];
	int i;
	for(i=0;i<kMJDPreAmpAdcChannels;i++){
		[adcHistory[i] release];
		[detectorName[i] release];
	}
    
    for(i=0;i<kMJDPreAmpLeakageCurrentChannels;i++){
		[leakageCurrentHistory[i] release];
	}
    for(i=0;i<2;i++){
        [temperatureAlarm[i] clearAlarm];
        [temperatureAlarm[i] release];
    }
    for(i=0;i<kMJDPreAmpAdcChannels;i++){
        [adcAlarm[i] clearAlarm];
        [adcAlarm[i] release];
    }
    [baselineRunningAverages release];
    [super dealloc];
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[ORMjdPreAmpPollQueue sharedMjdPreAmpPollQueue] cancelAllOperations];
}

- (void) wakeUp
{
    [super wakeUp];
    if(pollTime){
        [self requestPoll];
    }
    [self registerNotificationObservers];
}

- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[ORMjdPreAmpPollQueue sharedMjdPreAmpPollQueue] cancelAllOperations];
    [super sleep];
}

- (void) awakeAfterDocumentLoaded
{
    [self hardwareMapChanged:nil];
}

- (int) nMaxChannels
{
    return kMJDPreAmpAdcChannels;
}

- (ORRunningAverageGroup*) baselineRunningAverages
{
    return baselineRunningAverages;
}

- (void) setBaselineRunningAverages:(ORRunningAverageGroup*)newRunningAverageGroup
{
    [newRunningAverageGroup retain];
    [baselineRunningAverages release];
    baselineRunningAverages = newRunningAverageGroup;
}
//-----------------------------------------------------
//----for testing some of the rate spike logic
- (void) fakeASpike:(int) channel started:(BOOL)start
{
    ORRunningAveSpike* aSpike = [[[ORRunningAveSpike alloc] init] autorelease];
    aSpike.spiked       = start;
    aSpike.tag          = channel;
    aSpike.ave          = 2;
    aSpike.spikeValue   = 10;
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:aSpike forKey:@"SpikeObject"];
    NSNotification* aNote  = [NSNotification notificationWithName:ORSpikeStateChangedNotification object:self userInfo:userInfo];
    [self baselineSpikeChanged:aNote];
    
}
//-----------------------------------------------------

- (void) baselineSpikeChanged:(NSNotification*)aNote
{
    //spike
    ORRunningAveSpike* spikeObj = [[aNote userInfo] objectForKey:@"SpikeObject"];
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              spikeObj,@"spikeInfo",
                              [NSNumber numberWithInt:[self connectedGretinaCrate]],@"crate",
                              [NSNumber numberWithInt:[self connectedGretinaSlot]], @"card",
                              [NSNumber numberWithInteger:[spikeObj tag]],              @"adcChannel",
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelRateSpiked object:self userInfo:userInfo];
}

- (NSString*) identifier
{
    return @"MJDPreAmp";
}

- (void) setUpArrays
{
	if(!dacs){
		[self setDacs:[NSMutableArray arrayWithCapacity:kMJDPreAmpDacChannels]];
		int i;
		for(i=0;i<kMJDPreAmpDacChannels;i++){
			[dacs addObject:[NSNumber numberWithInt:0]];
		}	
	}
	if(!amplitudes){
		[self setAmplitudes:[NSMutableArray arrayWithCapacity:kMJDPreAmpDacChannels]];
		int i;
		for(i=0;i<kMJDPreAmpDacChannels;i++){
			[amplitudes addObject:[NSNumber numberWithInt:0]];
		}	
	}

    if(!feedBackResistors){
		[self setFeedBackResistors:[NSMutableArray arrayWithCapacity:kMJDPreAmpAdcChannels]];
		int i;
		for(i=0;i<kMJDPreAmpAdcChannels;i++){
			[feedBackResistors addObject:[NSNumber numberWithInt:0]];
		}
	}
    if(!baselineVoltages){
		[self setBaselineVoltages:[NSMutableArray arrayWithCapacity:kMJDPreAmpAdcChannels]];
		int i;
		for(i=0;i<kMJDPreAmpAdcChannels;i++){
			[baselineVoltages addObject:[NSNumber numberWithInt:0]];
		}
	}
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width/2- kConnectorSize/2,[self frame].size.height-kConnectorSize) withGuardian:self withObjectLink:self];
	[aConnector setConnectorType: 'SPII' ];
	[aConnector addRestrictedConnectionType: 'SPIO' ]; 
	[aConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];
    [[self connectors] setObject:aConnector forKey:MJDPreAmpInputConnector];
    [aConnector release];
}

- (void) connectionChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelConnectionChanged object:self];
    id connectedObj = [self objectConnectedTo:MJDPreAmpInputConnector];
    if(connectedObj){
        connected = YES;
        connectedToANLCard = [connectedObj isKindOfClass:NSClassFromString(@"ORGretina4AModel")];
    }
    else {
        connected = NO;
        connectedToANLCard = NO;
        [self clearAllAlarms];
    }
}

- (NSString*) connectedObjectName
{
    NSString* name = @"";
    ORConnector* inputConnector = [[self connectors] objectForKey:MJDPreAmpInputConnector];
    ORConnector* otherObjConnector = [inputConnector connector];
    OrcaObject* digitizerObj = [otherObjConnector objectLink];
    name = [digitizerObj fullID];
    name = [name stringByReplacingOccurrencesOfString:@"OR" withString:@""];
    name = [name stringByReplacingOccurrencesOfString:@"Model" withString:@""];
    return name;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MJDPreAmp"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORMJDPreAmpController"];
}
#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(hardwareMapChanged:)
                         name : ORSegmentGroupConfiguationChanged
                       object : nil];

    [notifyCenter addObserver : self
                         selector : @selector(baselineSpikeChanged:)
                             name : ORSpikeStateChangedNotification
                           object : baselineRunningAverages];
}

- (void) hardwareMapChanged:(NSNotification*)aNote
{
    if(aNote == nil || [[aNote object] class] == NSClassFromString(@"ORMJDSegmentGroup")){
        NSArray* segments = nil;
        if(aNote)segments = [[aNote object] segments];
        else {
            NSArray* mjdObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsWithClassName:@"MajoranaModel"];
            if([mjdObjects count]){
                MajoranaModel* mjdObject = [mjdObjects objectAtIndex:0];
                segments = [[mjdObject segmentGroup:0] segments];
            }
        }
        ORConnector* inputConnector     = [[self connectors] objectForKey:MJDPreAmpInputConnector];
        ORConnector* otherObjConnector  = [inputConnector connector];
        OrcaObject*  digitizerObj       = [otherObjConnector objectLink];
        if(digitizerObj){
            NSString* digitizerID = [digitizerObj fullID];
            NSArray* parts = [digitizerID componentsSeparatedByString:@","];
            if([parts count] == 3){
                int ourVmeCrate = [[parts objectAtIndex: 1]intValue];
                int ourVmeSlot  = [[parts objectAtIndex: 2]intValue];
                NSString* newNames[kMJDPreAmpAdcChannels];
                int i;
                for(i=0;i<kMJDPreAmpAdcChannels;i++){
                    newNames[i] = @"";
                }
                for(ORDetectorSegment* aSegment in segments){
                    NSString* vmeString     = [aSegment objectForKey:@"kVME"];
                    NSString* digString     = [aSegment objectForKey:@"kPreAmpDigitizer"];
                    NSString* preAmpChan    = [aSegment objectForKey:@"kPreAmpChan"];
                    NSString* detName       = [aSegment objectForKey:@"kDetectorName"];
                    if([self validMapName:vmeString]  &&
                       [self validMapName:digString]  &&
                       [self validMapName:preAmpChan]){
                        
                        int vmeCrate    = [vmeString intValue];
                        int slot        = [digString intValue];
                        int chan        = [preAmpChan intValue];
                        if((vmeCrate == ourVmeCrate) && (slot == ourVmeSlot)){
                            if([detName length]){
                                if(chan>=0 && chan<=4 || chan>=8 && chan<=12){
                                    newNames[chan] = detName;
                                }
                            }
                        }
                    }
                }
                for(i=0;i<kMJDPreAmpAdcChannels;i++){
                    [[self undoManager] disableUndoRegistration];
                    [self setDetector:i name:newNames[i]];
                    [[self undoManager] enableUndoRegistration];
                }
            }
        }
    }
}

- (int) connectedGretinaCrate
{
    ORConnector* inputConnector     = [[self connectors] objectForKey:MJDPreAmpInputConnector];
    ORConnector* otherObjConnector  = [inputConnector connector];
    OrcaObject*  digitizerObj       = [otherObjConnector objectLink];
    if(digitizerObj){
        NSString* digitizerID = [digitizerObj fullID];
        NSArray* parts = [digitizerID componentsSeparatedByString:@","];
        if([parts count] == 3){
            int ourVmeCrate = [[parts objectAtIndex: 1]intValue];
            return ourVmeCrate;
        }
        else return -1;
    }
    else return -1;
}

- (int) connectedGretinaSlot //the same as above, excpet for slot
{
    ORConnector* inputConnector     = [[self connectors] objectForKey:MJDPreAmpInputConnector];
    ORConnector* otherObjConnector  = [inputConnector connector];
    OrcaObject*  digitizerObj       = [otherObjConnector objectLink];
    if(digitizerObj){
        NSString* digitizerID = [digitizerObj fullID];
        NSArray* parts = [digitizerID componentsSeparatedByString:@","];
        if([parts count] == 3){
            int ourVmeSlot  = [[parts objectAtIndex: 2]intValue];
            return ourVmeSlot;
        }
        else return -1;
    }
    else return -1;
}


- (BOOL) validMapName:(NSString*)aName
{
    if([aName length]>0 && ![aName hasPrefix:@"-"])return YES;
    else return NO;
}

#pragma mark ¥¥¥Accessors
- (BOOL) doNotUseHWMap
{
    return doNotUseHWMap;
}

- (void) setDoNotUseHWMap:(BOOL)aDoNotUseHWMap
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoNotUseHWMap:doNotUseHWMap];
    doNotUseHWMap = aDoNotUseHWMap;
    if(!doNotUseHWMap){
        [self hardwareMapChanged:nil];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelDoNotUseHWMapChanged object:self];
}

- (int) boardRev
{
    return boardRev;
}

- (void) setBoardRev:(int)aBoardRev
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBoardRev:boardRev];
    
    boardRev = aBoardRev;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelBoardRevChanged object:self];
}

- (int) firmwareRev
{
    return firmwareRev;
}

- (void) setFirmwareRev:(int)aFirmwareRev
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFirmwareRev:firmwareRev];
    
    firmwareRev = aFirmwareRev;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelFirmwareRevChanged object:self];
}



- (NSString*) detectorName:(int)i
{
    if(i>=0 && i<kMJDPreAmpAdcChannels){
        switch(i){
            case 5:  return (supplyErrors[0] == 0)?@"+12V":[NSString stringWithFormat:@"+12V (%u Error%@)",supplyErrors[0],supplyErrors[0]>1?@"s":@""];
            case 6:  return (supplyErrors[1] == 0)?@"-12V":[NSString stringWithFormat:@"-12V (%u Error%@)",supplyErrors[1],supplyErrors[1]>1?@"s":@""];
            case 7:  return @"Temp Chip 1";
            case 13: return (supplyErrors[2] == 0)?@"+24V":[NSString stringWithFormat:@"+24V (%u Error%@)",supplyErrors[2],supplyErrors[2]>1?@"s":@""];
            case 14: return (supplyErrors[3] == 0)?@"-24V":[NSString stringWithFormat:@"-24V (%u Error%@)",supplyErrors[3],supplyErrors[3]>1?@"s":@""];
            case 15: return @"Temp Chip 2";
            default: if(!detectorName[i].length)return @"";
                     else return detectorName[i];

        }
    }
    else return @"";
}
- (void) setDetector:(int)i name:(NSString*)aName
{
    if(i>=0 && i<kMJDPreAmpAdcChannels){
        [[[self undoManager] prepareWithInvocationTarget:self] setDetector: i name:detectorName[i]];
        
        [detectorName[i] autorelease];
        detectorName[i] = [aName copy];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelDetectorNameChanged object:self];
    }
}

- (ORTimeRate*)adcHistory:(int)index
{
    if(index>=0 && index<kMJDPreAmpAdcChannels)return adcHistory[index];
    else return nil;
}

- (ORTimeRate*)leakageCurrentHistory:(int)index
{
    if(index>=0 && index<kMJDPreAmpLeakageCurrentChannels)return leakageCurrentHistory[index];
    else return nil;
}


- (uint32_t) adcEnabledMask
{
    return adcEnabledMask;
}

- (void) setAdcEnabledMask:(uint32_t)aAdcEnabledMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcEnabledMask:adcEnabledMask];
    
    adcEnabledMask = aAdcEnabledMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelAdcEnabledMaskChanged object:self];
}

- (BOOL) shipValues
{
    return shipValues;
}

- (void) setShipValues:(BOOL)aShipValues
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipValues:shipValues];
    
    shipValues = aShipValues;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelShipValuesChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:aPollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelPollTimeChanged object:self];
	
	if(pollTime){
		[self performSelector:@selector(requestPoll) withObject:nil afterDelay:2];
        NSLog(@"new poll time%d seconds\n",pollTime);

	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestPoll) object:nil];
        [self clearAllAlarms];
        [baselineRunningAverages reset];
	}
}

- (void) pollRequestIsFinished
{
    pollRequestInFlight = NO;
}

- (NSMutableArray*) feedBackResistors
{
    return feedBackResistors;
}
- (void) setFeedBackResistors:(NSMutableArray*)anArray
{
    [anArray retain];
    [feedBackResistors release];
    feedBackResistors = anArray;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDFeedBackResistorArrayChanged object:self];

}
- (float) feedBackResistor:(unsigned short) aChan
{
    if(aChan<kMJDPreAmpAdcChannels){
        return [[feedBackResistors objectAtIndex:aChan] floatValue];
	}
	else return 0.0;

}
- (void) setFeedBackResistor:(int) aChan value:(float) aValue
{
    if(aChan<kMJDPreAmpAdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setFeedBackResistor:aChan value:[self feedBackResistor:aChan]];
		[feedBackResistors replaceObjectAtIndex:aChan withObject:[NSNumber numberWithFloat:aValue]];
        
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithFloat:aChan] forKey: @"Channel"];
        
        //update leakage current for relevant channels
        if(mjdPreAmpTable[aChan].calculateLeakageCurrent){
            [self calculateLeakageCurrentForAdc:aChan];
        }
        
 		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDFeedBackResistorChanged
															object:self
														  userInfo: userInfo];
       
	}

}
- (NSMutableArray*) baselineVoltages
{
    return baselineVoltages;

}
- (void) setBaselineVoltages:(NSMutableArray*)anArray
{
    [anArray retain];
    [baselineVoltages release];
    baselineVoltages = anArray;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDBaselineVoltageArrayChanged object:self];
  
}

- (float) baselineVoltage:(unsigned short) aChan
{
    if(aChan<[baselineVoltages count]){
        return [[baselineVoltages objectAtIndex:aChan] floatValue];
	}
	else return 0.0;
 
}

- (void) setBaselineVoltage:(int) aChan value:(float) aValue
{
    if(aChan<[baselineVoltages count]){
		[[[self undoManager] prepareWithInvocationTarget:self] setBaselineVoltage:aChan value:[self baselineVoltage:aChan]];
		[baselineVoltages replaceObjectAtIndex:aChan withObject:[NSNumber numberWithFloat:aValue]];
        
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithFloat:aChan] forKey: @"Channel"];
        
        if(mjdPreAmpTable[aChan].calculateLeakageCurrent){
            [self calculateLeakageCurrentForAdc:aChan];
        }
        
 		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDBaselineVoltageChanged
															object:self
														  userInfo: userInfo];
        
	}
}

#pragma mark ¥¥¥ Instance rates
- (float) adc:(unsigned short) aChan
{
	if(aChan<kMJDPreAmpAdcChannels){
		if(adcEnabledMask & (0x1<<aChan))return adcs[aChan];
		else return 0.0;
	}
	else return 0.0;
}

- (float) leakageCurrent:(unsigned short) aChan
{
	if(aChan<kMJDPreAmpLeakageCurrentChannels){
		if(adcEnabledMask & (0x1<<aChan))return leakageCurrents[aChan];
		else return 0.0;
	}
	else return 0.0;
}


- (void) setAdc:(int) aChan value:(float) aValue
{
	if(aChan>=0 && aChan<kMJDPreAmpAdcChannels){
        
		adcs[aChan] = aValue;
        
        if((aChan>=0 && aChan<=4) || (aChan >=8 && aChan<=12)){
            if(adcEnabledMask & (0x1<<aChan)){
                [baselineRunningAverages addNewValue:aValue toIndex:aChan];
            }
        }

		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithFloat:aChan] forKey: @"Channel"];

         
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpAdcChanged
															object:self
														  userInfo: userInfo];
	}
}

- (void) setLeakageCurrent:(int) aChan value:(float) aValue
{
    leakageCurrents[aChan] = aValue;
}

- (BOOL) loopForever
{
    return loopForever;
}

- (void) setLoopForever:(BOOL)aLoopForever
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLoopForever:loopForever];
    
    loopForever = aLoopForever;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpLoopForeverChanged object:self];
}

- (unsigned short) pulseCount
{
    return pulseCount;
}

- (void) setPulseCount:(unsigned short)aPulseCount
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseCount:pulseCount];
    
    pulseCount = aPulseCount;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpPulseCountChanged object:self];
}

- (BOOL) enabled:(int)index
{
	if(index>=0 && index<2) return enabled[index];
    else return NO;
}

- (void) setEnabled:(int)index value:(BOOL)aEnabled
{
	if(index<0 || index>1) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:index value:enabled[index]];
    enabled[index] = aEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpEnabledChanged object:self];
}

- (BOOL) attenuated:(int)index
{
	if(index>=0 && index<2) return attenuated[index];
    else return NO;
}

- (void) setAttenuated:(int)index value:(BOOL)aAttenuated
{
	if(index<0 || index>1) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setAttenuated:index value:attenuated[index]];
    attenuated[index] = aAttenuated;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpAttenuatedChanged object:self];
}

- (BOOL) finalAttenuated:(int)index
{
	if(index>=0 && index<2) return finalAttenuated[index];
    else return NO;
}

- (void) setFinalAttenuated:(int)index value:(BOOL)aAttenuated
{
	if(index<0 || index>1) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setFinalAttenuated:index value:finalAttenuated[index]];
    finalAttenuated[index] = aAttenuated;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpFinalAttenuatedChanged object:self];
}


- (unsigned short) pulserMask
{
    return pulserMask;
}

- (void) setPulserMask:(unsigned short)aPulserMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserMask:pulserMask];
    pulserMask = aPulserMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpPulserMaskChanged object:self];
}

- (int) pulseHighTime
{
	return pulseHighTime;
}

- (void) setPulseHighTime:(int)aPulseHighTime
{
    // Firmware Rev 1
    if( firmwareRev==0 )
    {
        if(aPulseHighTime<2)			aPulseHighTime=0;
        else if(aPulseHighTime>0x10000)	aPulseHighTime = 0xFFFF;
    }
    else // Firmware Rev 2
    {
        if(aPulseHighTime<2)			aPulseHighTime=0;
        else if(aPulseHighTime>0x200000)	aPulseHighTime = 0xFFFFF8>>3;
    }
    
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseHighTime:pulseHighTime];
    pulseHighTime = aPulseHighTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpPulseHighTimeChanged object:self];
}

- (int) pulseLowTime
{
	return pulseLowTime;
}

- (void) setPulseLowTime:(int)aPulseLowTime
{
    // Firmware Rev 1
    if( firmwareRev==0 )
    {
        if(aPulseLowTime<2)			aPulseLowTime=0;
        else if(aPulseLowTime>0x10000)	aPulseLowTime = 0xFFFF;
    }
    else // Firmware Rev 2
    {
        if(aPulseLowTime<2)			aPulseLowTime=0;
        else if(aPulseLowTime>0x200000)	aPulseLowTime = 0xFFFFF8>>3;
    }
    
	[[[self undoManager] prepareWithInvocationTarget:self] setPulseLowTime:pulseLowTime];
    pulseLowTime = aPulseLowTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpPulseLowTimeChanged object:self];
}

- (NSMutableArray*) dacs
{
    return dacs;
}

- (void) setDacs:(NSMutableArray*)anArray
{
    [anArray retain];
    [dacs release];
    dacs = anArray;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpDacArrayChanged object:self];
}

- (uint32_t) dac:(unsigned short) aChan
{
    return [[dacs objectAtIndex:aChan] unsignedShortValue];
}

- (void) setDac:(unsigned short) aChan withValue:(uint32_t) aValue
{
	if(aValue>0xffff) aValue = 0xffff;
    [[[self undoManager] prepareWithInvocationTarget:self] setDac:aChan withValue:[self dac:aChan]];
	[dacs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInteger:aValue]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: @"Channel"];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpDacChanged
														object:self
													  userInfo: userInfo];
}

- (uint32_t) timeMeasured
{
	return timeMeasured;
}
- (NSMutableArray*) amplitudes
{
    return amplitudes;
}

- (void) setAmplitudes:(NSMutableArray*)anArray
{
    [anArray retain];
    [amplitudes release];
    amplitudes = anArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpAmplitudeArrayChanged object:self];
}

- (uint32_t) amplitude:(int) aChan
{
    return [[amplitudes objectAtIndex:aChan] unsignedShortValue];
}

- (void) setAmplitude:(int) aChan withValue:(uint32_t) aValue
{
	if(aValue>0xffff) aValue = 0xffff;
    [[[self undoManager] prepareWithInvocationTarget:self] setAmplitude:aChan withValue:[self amplitude:aChan]];
	[amplitudes replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInteger:aValue]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithUnsignedShort:aChan] forKey: @"Channel"];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpAmplitudeChanged
														object:self
													  userInfo: userInfo];
}

- (NSString*) helpURL
{
	return nil;
}

#pragma mark ¥¥¥HW Access
- (void) writeFetVdsToHW
{
	int i;
	for(i=0;i<kMJDPreAmpDacChannels;i++){
		[self writeFetVds:i];
	}
}

- (void) writeFetVds:(int)index
{
	if(index>=0 && index<16){
		uint32_t theValue;
		//set up the Octal chip mask first
		if(index<8)	theValue = kDAC3;
		else		theValue = kDAC4;
		
		//set up which of eight DAC on that octal chip
		theValue |= (kDACA_H_Base | (index%8 << 16));
		
		//set up the value
		theValue |= [self dac:index];
		[self writeAuxIOSPI:theValue];
	}
}

- (void) writeAmplitudes
{
	int i;
	for(i=0;i<kMJDPreAmpDacChannels;i++){
		[self writeAmplitude:i];
	}
}

- (void) writeAmplitude:(int)index
{
	if(index>=0 && index<16){
		uint32_t theValue;
		//set up the Octal chip mask first
		if(index<8)	theValue = kDAC1;
		else		theValue = kDAC2;
		
		//set up which of eight DAC on that octal chip
		theValue |= (kDACA_H_Base | (index%8 << 16));
		
		//set up the value
		theValue |= [self amplitude:index];
		[self writeAuxIOSPI:theValue];
	}
}

- (void) zeroAmplitudes
{
    uint32_t zeroAllOctalChips = 0x2F0000;
	[self writeAuxIOSPI:(kDAC1 | zeroAllOctalChips)];
	[self writeAuxIOSPI:(kDAC2 | zeroAllOctalChips)];
}

- (void) writeAdcRanges
{
    rangesHaveBeenSet = YES;
    //the control word is mapped to bits 23 - bit 8 of the 32 bit word sent to the
    //controller
    
    //both chips are set up the same. so we only have to 
    uint32_t controlWord;    
    controlWord =   (kRangeReg1      << 13)  |
                    (kBipolar10V     << 11)  |       //chan 0
                    (kBipolar10V     << 9)   |       //chan 1
                    (kBipolar10V     << 7)   |       //chan 2
                    (kBipolar10V     << 5);           //chan 3
    [self writeAuxIOSPI:kADC1 | (controlWord<<8)];   //shift to bit 8 + add the adc sel
    [self writeAuxIOSPI:kADC2 | (controlWord<<8)];   //shift to bit 8 + add the adc sel
    
    controlWord =   (kRangeReg2      << 13)  |
                    (kBipolar10V     << 11)  |        //chan 4
                    (kBipolar10V     << 9)   |        //chan 5
                    (kBipolar10V     << 7)   |        //chan 6
                    (kBipolar2_5V    << 5);           //chan 7 -- temperature
    [self writeAuxIOSPI:kADC1 | (controlWord<<8)];    //shift to bit 8 + add the adc sel
    [self writeAuxIOSPI:kADC2 | (controlWord<<8)];    //shift to bit 8 + add the adc sel
}

- (void) readAllAdcs
{
    [self readAllAdcs:NO];
}


- (void) readAllAdcs:(BOOL)verbose
{
    if(!connected)return;
    if(!rangesHaveBeenSet)[self writeAdcRanges];
    uint32_t rawAdcValue[16];
    int chan;
    if([self controllerIsSBC] ){
        
        uint32_t cmdType;
        if(connectedToANLCard)cmdType = kMJDReadPreampsANL;
        else                  cmdType = kMJDReadPreamps;
        
        //if an SBC is available we pass the request to read the adcs
        //to it.
        int chip;
        for(chip=0;chip<2;chip++){
            SBC_Packet aPacket;
            aPacket.cmdHeader.destination	= kMJD;
            aPacket.cmdHeader.cmdID			= (uint32_t)cmdType;
            aPacket.cmdHeader.numberBytesinPayload	= (8 + 3)*sizeof(int32_t);
            
            GRETINA4_PreAmpReadStruct* p = (GRETINA4_PreAmpReadStruct*) aPacket.payload;
            p->baseAddress      = (uint32_t)[self baseAddress];
            p->chip             = chip;
            p->readEnabledMask  = (uint32_t)adcEnabledMask;
            for(chan=0;chan<8;chan++){
                int adcIndex = chan + (chip*8);
                if(adcEnabledMask & (0x1<<adcIndex)){
                    uint32_t controlWord = (kControlReg << 13)    |             //sel the chan set
                    (chan<<10)         |             //set chan
                    (0x1 << 4)         |             //use internal voltage reference for conversion
                    (mjdPreAmpTable[adcIndex].conversionType << 5)   |
                    (mjdPreAmpTable[adcIndex].mode << 8);    //set mode, other bits are zero
                    p->adc[chan] = (uint32_t)((mjdPreAmpTable[adcIndex].adcSelection | (controlWord<<8)));
                }
                else p->adc[chan] = 0;
            }
            @try {
                [[[[self objectConnectedTo:MJDPreAmpInputConnector] adapter] sbcLink] send:&aPacket receive:&aPacket];
                GRETINA4_PreAmpReadStruct* p = (GRETINA4_PreAmpReadStruct*) aPacket.payload;
                for(chan=0;chan<8;chan++){
                    int adcIndex = chan + (chip*8);
                    if(adcEnabledMask & (0x1<<adcIndex))rawAdcValue[adcIndex] = p->adc[chan];
                    else                               rawAdcValue[adcIndex] = 0;
                }
            }
            @catch(NSException* e){
                
            }
        }
        
    }

    for(chan=0;chan<kMJDPreAmpAdcChannels;chan++){
        if(adcEnabledMask & (0x1<<chan)){
            //int decodedChannel = (~rawAdcValue[chan] & 0xE000) >> 13;                      //use the whichever chan was converted, may be diff than the one selected above.
            //if(mjdPreAmpTable[decodedChannel].adcSelection & 0x1000000) decodedChannel += 8;  //two adc chips, so the second chip is offset by 8 to get the right adc index
            
            
            // Firmware Rev 2: controller firmware rev2_3 => 16 data bits shifted by one bit
            if(firmwareRev == 1)
                rawAdcValue[chan] = ((rawAdcValue[chan]&0x1FFFE)>>1);
            
            
            int32_t adcValue;
            if(mjdPreAmpTable[chan].conversionType == kTwosComplement){
                
                if(rawAdcValue[chan] & 0x1000){ // negative bit sign
                //if(((rawAdcValue[chan]&0x1FFFE)>>1) & 0x1000){ // negative bit sign
                    
                    //adcValue = rawAdcValue[chan] ^ 0x1000; // kick bit sign out
                    //adcValue = -((adcValue ^ 0xFFF) + 0x1); // revert two's complement (flip, add one, take negative)
                    
                    adcValue = -(~rawAdcValue[chan] & 0x1FFF) + 1;
                    //adcValue = -(~((rawAdcValue[chan]&0x1FFFE)>>1) & 0x1FFF) + 1;
                }
                else{

                    //adcValue = (rawAdcValue[chan] ^ 0xFFF) + 0x1; // revert two's complement (flip, add one)
                    
                    adcValue = rawAdcValue[chan] & 0x1FFF;
                    //adcValue = ((rawAdcValue[chan]&0x1FFFE)>>1) & 0x1FFF;
                }
            }
            else {
                adcValue = rawAdcValue[chan] & 0x1FFF;
            }
            
            float convertedValue = (-adcValue+mjdPreAmpTable[chan].adcOffset)*mjdPreAmpTable[chan].slope + mjdPreAmpTable[chan].intercept;
			
            if(verbose)NSLog(@"[%d], raw: %d, converted:%.2f, raw: %#x\n",chan,adcValue,convertedValue,rawAdcValue[chan]);
            
            
            // Hardware Rev 1: original boards (CC-BXX series, XX =< 05)
            if(boardRev == 0){
                [self setAdc:chan value:convertedValue];
            }
            else {
                // Hardware Rev 2: new boards (CC-BXX series, XX >= 06)
                //----------------------------------------------------------
                // Fix for controller rev2 + mother board rev2 configuration
                // Ground and signal connector pins swapped on board
                // --> Order of channels 0-4 inverted on ribbon cable - niko
                if( (chan%8) < 5 ){
                    int swapChan;
                    if( chan < 5 )
                        swapChan = 4 - chan;
                    else swapChan = 20 - chan;
                    
                    [self setAdc:swapChan value:convertedValue];
                }
                else [self setAdc:chan value:convertedValue];
                //----------------------------------------------------------
            }
            [self checkAdcIsWithinLimits:chan];	
            if(mjdPreAmpTable[chan].calculateLeakageCurrent){
                [self calculateLeakageCurrentForAdc:chan];
            }
        }
        else [self setAdc:chan value:0.0];
    }
    
    [self checkTempIsWithinLimits];
    
    //get the time(UT!) for the data record.
    time_t	ut_Time;
    time(&ut_Time);
    timeMeasured = (uint32_t)ut_Time;
}
         
- (BOOL) controllerIsSBC
{
    id connectedObj = [self objectConnectedTo:MJDPreAmpInputConnector];
	if([connectedObj respondsToSelector:@selector(adapter)]){
		id theController =  [connectedObj adapter];
        if([theController isKindOfClass:NSClassFromString(@"ORVmecpuModel")])return YES;
        else return NO;
	}
    else return NO;
}
    
- (uint32_t) baseAddress
{
    id connectedObj = [self objectConnectedTo:MJDPreAmpInputConnector];
    if([connectedObj respondsToSelector:@selector(baseAddress)]){
        return [connectedObj baseAddress];
    }
    else return 0;
}

- (void) requestPoll
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestPoll) object:nil];
    if(connected){
        @try {
            if(!pollRequestInFlight){
                pollRequestInFlight = YES;
                MjdPreAmpPollRequest* aRequest = [[MjdPreAmpPollRequest alloc] initWithDelegate:self];
                [[ORMjdPreAmpPollQueue sharedMjdPreAmpPollQueue] addRequest:aRequest];
                [aRequest release];
            }
        }
        @catch(NSException* e){
            
        }
        [self updateTrends];
        [self postCouchDBRecord];
        if(shipValues)[self shipRecords];
    }
    if(pollTime){
        [self performSelector:@selector(requestPoll) withObject:nil afterDelay:pollTime];
    }
}



- (void) pollValues
{
    if(connected){
        @try {
            if(!pollRequestInFlight)pollRequestInFlight = YES;
            [self readAllAdcs];
            pollRequestInFlight = NO;
        }
        @catch(NSException* e){
            
        }
        [self updateTrends];
        [self postCouchDBRecord];
        if(shipValues)[self shipRecords];
    }
}


- (void) stopPulser
{
    // stop pulsing: write nothing to kPulserStartMask
	[self writeAuxIOSPI:kPulserStartMask];
	//[self writeAuxIOSPI:(kPulserStartMask | kPulserUseLoopCount)];

    //Now park it! First zero all pulse amplitudes
    [self zeroAmplitudes];
	//write zeros to the pattern, enable the attenuators, and disable the pulser outputs
	[self writeAuxIOSPI:(kAttnPatternMask | 0x22)];
	NSLog(@"PreAmp(%d) Disabled Pulser\n",[self uniqueIdNumber]);
}	

- (void) startPulser
{
    if(pulseCount == 0 && !loopForever) {
	  NSLog(@"PreAmp(%d)::startPulser() -- pulseCount = 0 but not looping forever, returning...\n",[self uniqueIdNumber]);
      return;
    }

	//set the pulser amplitudes
    [self writeAmplitudes];

	uint32_t aValue = 0;
	//set the high and low times (frequency)
    
    // Firmware Rev 1
    if( firmwareRev==0 )
    {
        aValue = kPulserLowTimeMask | ((pulseLowTime&0xFFFF)<<8);
        [self writeAuxIOSPI:aValue];
        
        aValue = kPulserHighTimeMask | ((pulseHighTime&0xFFFF)<<8);
        [self writeAuxIOSPI:aValue];
    }
    else // Firmware Rev 2
    {
        aValue = kPulserLowTimeMask | ((pulseLowTime<<3)&0xFFFFF8);
        [self writeAuxIOSPI:aValue];
        
        aValue = kPulserHighTimeMask | ((pulseHighTime<<3)&0xFFFFF8);
        [self writeAuxIOSPI:aValue];
    }

        
	
	//set the bit pattern and global attenuators / enables
	aValue =  kAttnPatternMask | 
		((pulserMask		 & 0xFF00)) | 
		((pulserMask		 & 0x00FF) << 16) | 
		((attenuated[0]      & 0x1) << 7)  |
		((finalAttenuated[0] & 0x1) << 6)  | 
		((enabled[0]         & 0x1) << 5) |
		((attenuated[1]	     & 0x1) << 3)  | 
		((finalAttenuated[1] & 0x1) << 2)  | 
		((enabled[1]         & 0x1) << 1) ;
	[self writeAuxIOSPI:aValue];
	
    // start pulsing
	aValue = kPulserStartMask | ((pulseCount-1) & 0xffff);
	if(loopForever) aValue |= kPulserLoopForever;
	else			aValue |= kPulserUseLoopCount;
	[self writeAuxIOSPI:aValue];
	NSLog(@"PreAmp(%d) Started Pulser\n",[self uniqueIdNumber]);
}

- (uint32_t)  writeAuxIOSPI:(uint32_t)aValue
{
	id connectedObj = [self objectConnectedTo:MJDPreAmpInputConnector];
	if([connectedObj respondsToSelector:@selector(writeAuxIOSPI:)]){
		return [connectedObj writeAuxIOSPI:aValue];
	}
    return 0;
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setBoardRev:      [decoder decodeIntForKey:   @"boardRev"]];
    [self setAdcEnabledMask:[decoder decodeIntForKey: @"adcEnabledMask"]];
    [self setShipValues:	[decoder decodeBoolForKey:  @"shipValues"]];
	[self setPollTime:		[decoder decodeIntForKey:   @"pollTime"]];
    [self setFirmwareRev:   [decoder decodeIntForKey:   @"firmwareRev"]];

    
	int i;
	for(i=0;i<2;i++){
		[self setEnabled:i		   value:[decoder decodeBoolForKey:[NSString stringWithFormat: @"enabled%d",i]]];
		[self setAttenuated:i      value:[decoder decodeBoolForKey:[NSString stringWithFormat: @"attenuated%d",i]]];
		[self setFinalAttenuated:i value:[decoder decodeBoolForKey:[NSString stringWithFormat: @"finalAttenuated%d",i]]];
	}
    

    [self setLoopForever:	[decoder decodeBoolForKey:   @"loopForever"]];
    [self setPulseCount:	[decoder decodeIntegerForKey:    @"pulseCount"]];
	[self setPulseHighTime:	[decoder decodeIntForKey:    @"pulseHighTime"]];
	[self setPulseLowTime:	[decoder decodeIntForKey:    @"pulseLowTime"]];
	[self setPulserMask:	[decoder decodeIntegerForKey:    @"pulserMask"]];
    [self setDacs:			[decoder decodeObjectForKey: @"dacs"]];
    [self setAmplitudes:	[decoder decodeObjectForKey: @"amplitudes"]];
    [self setFeedBackResistors:	[decoder decodeObjectForKey: @"feedBackResistors"]];
    [self setBaselineVoltages:	[decoder decodeObjectForKey: @"baselineVoltages"]];
    [self setDoNotUseHWMap:[decoder decodeBoolForKey:@"doNotUseHWMap"]];
	
    if(!dacs || !amplitudes || !feedBackResistors || !baselineVoltages)	[self setUpArrays];

    if(!baselineRunningAverages){
        [self setBaselineRunningAverages:[[[ORRunningAverageGroup alloc] initGroup:kMJDPreAmpAdcChannels groupTag:0 withLength:4] autorelease]];
    }
    
    [baselineRunningAverages setVerbose:false];
    [baselineRunningAverages setTriggerValue:1];
    [baselineRunningAverages setTriggerType:kRASpikeOnThreshold];
    
    [self registerNotificationObservers];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:doNotUseHWMap   forKey:@"doNotUseHWMap"];
	[encoder encodeInteger:boardRev         forKey:@"boardRev"];
	[encoder encodeInt:adcEnabledMask forKey:@"adcEnabledMask"];
	[encoder encodeBool:shipValues		forKey:@"shipValues"];
	[encoder encodeInteger:pollTime			forKey:@"pollTime"];
    [encoder encodeInteger:firmwareRev      forKey:@"firmwareRev"];
    
	int i;
	for(i=0;i<2;i++){
		[encoder encodeBool:enabled[i]			forKey:[NSString stringWithFormat:@"enabled%d",i]];
		[encoder encodeBool:attenuated[i]		forKey:[NSString stringWithFormat:@"attenuated%d",i]];
		[encoder encodeBool:finalAttenuated[i]	forKey:[NSString stringWithFormat:@"finalAttenuated%d",i]];
	}
    for(i=0;i<kMJDPreAmpAdcChannels;i++){
		[encoder encodeObject:detectorName[i]	forKey:[NSString stringWithFormat:@"detectorName%d",i]];
    }

	[encoder encodeBool:loopForever		forKey:@"loopForever"];
	[encoder encodeInteger:pulseCount		forKey:@"pulseCount"];
	[encoder encodeInteger:pulseHighTime	forKey:@"pulseHighTime"];
	[encoder encodeInteger:pulseLowTime		forKey:@"pulseLowTime"];
	[encoder encodeInteger:pulserMask		forKey:@"pulserMask"];
	[encoder encodeObject:dacs			forKey:@"dacs"];
	[encoder encodeObject:amplitudes	forKey:@"amplitudes"];
	[encoder encodeObject:feedBackResistors			forKey:@"feedBackResistors"];
	[encoder encodeObject:baselineVoltages			forKey:@"baselineVoltages"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    
    ORConnector* inputConnector = [[self connectors] objectForKey:MJDPreAmpInputConnector];
    ORConnector* otherObjConnector = [inputConnector connector];
    ORCard* digitizerObj = (ORCard*)([otherObjConnector objectLink]);
    int crate = [digitizerObj crateNumber];
    int slot = [digitizerObj slot];

    id connectedObj = [self connectedObjectName];
    
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class])                forKey:@"Class Name"];
    if(connectedObj!=nil)[objDictionary setObject:connectedObj              forKey:@"ConnectedTo"];
    [objDictionary setObject:[NSNumber numberWithInt:crate]                 forKey:@"crate"];
    [objDictionary setObject:[NSNumber numberWithInt:slot]                  forKey:@"slot"];

    [objDictionary setObject:[NSNumber numberWithInteger:[self uniqueIdNumber]] forKey:@"preampID"];
    [objDictionary setObject:[NSNumber numberWithInt:[self boardRev]]       forKey:@"boardRev"];
    [objDictionary setObject:[NSNumber numberWithLong:adcEnabledMask]       forKey:@"adcEnabledMask"];
    [objDictionary setObject:[NSNumber numberWithInt:pollTime]              forKey:@"pollTime"];
    [objDictionary setObject:[NSNumber numberWithInt:firmwareRev]           forKey:@"firmwareRev"];
    
    int i;
    for(i=0;i<2;i++){
        [objDictionary setObject:[NSNumber numberWithInt:enabled[i]] forKey:[NSString stringWithFormat:@"enabled%d",i]];
        [objDictionary setObject:[NSNumber numberWithInt:attenuated[i]] forKey:[NSString stringWithFormat:@"attenuated%d",i]];
        [objDictionary setObject:[NSNumber numberWithInt:finalAttenuated[i]] forKey:[NSString stringWithFormat:@"finalAttenuated%d",i]];
    }
    for(i=0;i<kMJDPreAmpAdcChannels;i++){
        NSString* detName = detectorName[i];
        if([detName length]==0)detName = @"";
        [objDictionary setObject:detName forKey:[NSString stringWithFormat:@"detectorName%d",i]];
    }
    [objDictionary setObject:[NSNumber numberWithInt:loopForever]   forKey:@"loopForever"];
    [objDictionary setObject:[NSNumber numberWithInt:pulseCount]    forKey:@"pulseCount"];
    [objDictionary setObject:[NSNumber numberWithInt:pulseHighTime] forKey:@"pulseHighTime"];
    [objDictionary setObject:[NSNumber numberWithInt:pulseLowTime]  forKey:@"pulseLowTime"];
    [objDictionary setObject:[NSNumber numberWithInt:pulserMask]    forKey:@"pulserMask"];
    [objDictionary setObject:dacs               forKey:@"dacs"];
    [objDictionary setObject:amplitudes         forKey:@"amplitudes"];
    [objDictionary setObject:feedBackResistors  forKey:@"feedBackResistors"];
    [objDictionary setObject:baselineVoltages   forKey:@"baselineVoltages"];
    
    [dictionary setObject:objDictionary forKey:[self identifier]];
    return objDictionary;
}

#pragma mark ¥¥¥Data Records
- (uint32_t) dataId					{ return dataId;   }
- (void) setDataId: (uint32_t) DataId	{ dataId = DataId; }
- (void) setDataIds:(id)assigner			{ dataId = [assigner assignDataIds:kLongForm]; }
- (void) syncDataIdsWith:(id)anotherTPG262	{ [self setDataId:[anotherTPG262 dataId]]; }

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"MJDPreAmpModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORMJDPreAmpDecoderForAdc",						@"decoder",
								 [NSNumber numberWithLong:dataId],					@"dataId",
								 [NSNumber numberWithBool:NO],						@"variable",
								 [NSNumber numberWithLong:kMJDPreAmpDataRecordLen],	@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"Adcs"];
    
    return dataDictionary;
}

- (void) shipRecords
{
	
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		uint32_t data[kMJDPreAmpDataRecordLen];
		
		data[0] = dataId | kMJDPreAmpDataRecordLen;
		data[1] = [self uniqueIdNumber]&0xfff;
		data[2] = timeMeasured;
		data[3] = adcEnabledMask;
		
		union {
			float asFloat;
			uint32_t asLong;
		} theData;
		
		int index = 4;
		int i;
		for(i=0;i<kMJDPreAmpDacChannels;i++){
			theData.asFloat = [self adc:i];
			data[index]     = theData.asLong;
			index++;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName: ORQueueRecordForShippingNotification 
                                object: [NSData dataWithBytes:data length:sizeof(int32_t)*kMJDPreAmpDataRecordLen]];
	}
}


#pragma mark ¥¥¥Alarms
- (void) checkTempIsWithinLimits
{
    if(!connected)return;
    
    return; //temps don't work -- don't alarm
//    
//    float maxAllowedTemperature = 1000; //temporarily set high because the temp readout isn't working right
//    int aChip;
//    float aTemperature;
//    for(aChip=0;aChip<2;aChip++){
//        if(aChip == 0)  aTemperature = [self adc:7];
//        else            aTemperature = [self adc:15];
//        if(aTemperature >= maxAllowedTemperature){
//             if(!temperatureAlarm[aChip]){
//                temperatureAlarm[aChip] = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Controller %u Temperature",[self uniqueIdNumber]] severity:kRangeAlarm];
//                [temperatureAlarm[aChip] setHelpString:[NSString stringWithFormat:@"Controller %u has exceeded %.1f C. This alarm will be in effect until the temperature returns to normal limits. It can be silenced by acknowledging it.",[self uniqueIdNumber],maxAllowedTemperature]];
//                [temperatureAlarm[aChip] setSticky:YES];
//                [temperatureAlarm[aChip] postAlarm];
//            }
//        }
//        else {
//            [temperatureAlarm[aChip] clearAlarm];
//            [temperatureAlarm[aChip] release];
//            temperatureAlarm[aChip] = nil;
//        }
//    }
}

- (void) checkLeakageCurrentIsWithinLimits:(int)aChan
{
    if(!connected)return;

    float maxAllowedLeakageCurrent = 50;//pA
    NSString* alarmName  = [NSString stringWithFormat:@"Preamp %d of Controller %u: Leakage Current Alarm",aChan,[self uniqueIdNumber]];
    float aLeakageCurrent = [self leakageCurrent:aChan];
    
    if(aLeakageCurrent >= maxAllowedLeakageCurrent){
        if(!leakageCurrentAlarm[aChan]){
            leakageCurrentAlarm[aChan] = [[ORAlarm alloc] initWithName:alarmName severity:kRangeAlarm];
            [leakageCurrentAlarm[aChan] setHelpString:[NSString stringWithFormat:@"Preamp %d of Controller %u: leakage current value exceeded limits. This alarm will be in effect until the leakage current returns to normal limits. It can be silenced by acknowledging it.",aChan,[self uniqueIdNumber]]];
            [leakageCurrentAlarm[aChan] setSticky:YES];
        }
        [leakageCurrentAlarm[aChan] postAlarm];
    }
    else {
        [leakageCurrentAlarm[aChan] clearAlarm];
        [leakageCurrentAlarm[aChan] release];
        leakageCurrentAlarm[aChan] = nil;
    }
}

- (void) checkAdcIsWithinLimits:(int)anIndex
{
    if(!connected)return;

    if(anIndex != 5 && anIndex!=6 && anIndex!= 13 && anIndex!= 14)return;
    float aValue = [self adc:anIndex];
    BOOL postAlarm = NO;
   // NSString* alarmName = nil;
    switch(anIndex){
        case 5:
            if(fabs(aValue - 12)/12. >= 0.1){ //set range to 10% - niko
               // alarmName  = [NSString stringWithFormat:@"Controller %u +12V Supply",[self uniqueIdNumber]];
                postAlarm  = YES;
            }
            [self checkSupplyError:0 postAlarm:postAlarm];
       break;
            
        case 6:
            if(fabs(aValue + 12)/12. >= 0.1){ //set range to 10% - niko
               // alarmName = [NSString stringWithFormat:@"Controller %u -12V Supply",[self uniqueIdNumber]];
                postAlarm  = YES;
            }
            [self checkSupplyError:1 postAlarm:postAlarm];
       break;
            
        case 13:
            if(fabs(aValue - 24)/24. >= 0.1){ //set range to 10% - niko
             //   alarmName = [NSString stringWithFormat:@"Controller %u +24V Supply",[self uniqueIdNumber]];
                postAlarm  = YES;
            }
            [self checkSupplyError:2 postAlarm:postAlarm];
       break;
            
        case 14:
            if(fabs(aValue + 24)/24. >= 0.1){ //set range to 10% - niko
             //   alarmName = [NSString stringWithFormat:@"Controller %u -24V Supply",[self uniqueIdNumber]];
                postAlarm  = YES;
           }
           [self checkSupplyError:3 postAlarm:postAlarm];

        break;
    }
    
    /* Turn off the alarms for now
    if(postAlarm){
        if(!adcAlarm[anIndex]){
            adcAlarm[anIndex] = [[ORAlarm alloc] initWithName:alarmName severity:kRangeAlarm];
            [adcAlarm[anIndex] setHelpString:[NSString stringWithFormat:@"Controller %u adc value exceeded limits (was at %.2f). This alarm will be in effect until the adc value returns to normal limits. It can be silenced by acknowledging it.",[self uniqueIdNumber],aValue]];
            [adcAlarm[anIndex] setSticky:YES];
            [adcAlarm[anIndex] postAlarm];
        }
    }
    else {
        [adcAlarm[anIndex] clearAlarm];
        [adcAlarm[anIndex] release];
        adcAlarm[anIndex] = nil;
    }
     */
}

- (void) checkSupplyError:(int)anIndex postAlarm:(BOOL)aState
{
    if((anIndex>=0) && (anIndex<4)){
        if(aState && !supplyOutOfBounds[anIndex]){
            supplyErrors[anIndex]++;
            [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelDetectorNameChanged object:self];
        }
        supplyOutOfBounds[anIndex] = aState;
     }
}

- (void) clearSupplyErrors;
{
    int i;
    for(i=0;i<4;i++){
        supplyErrors[i]        = 0;
        supplyOutOfBounds[i]   = NO;
    }
     [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPreAmpModelDetectorNameChanged object:self];
}

@end

#pragma mark ¥¥¥Private Implementation
@implementation ORMJDPreAmpModel (private)

- (void) clearAllAlarms
{
    int i;
    for(i=0;i<2;i++){
        [temperatureAlarm[i] clearAlarm];
        [temperatureAlarm[i] release];
        temperatureAlarm[i] = nil;
    }
    for(i=0;i<kMJDPreAmpAdcChannels;i++){
        [adcAlarm[i] clearAlarm];
        [adcAlarm[i] release];
        adcAlarm[i] = nil;
        [self setAdc:i value:0];
    }
}

- (void) updateTrends
{
    int chan;
	for(chan=0;chan<kMJDPreAmpAdcChannels;chan++){
        
        if(!adcHistory[chan]) adcHistory[chan] = [[ORTimeRate alloc] init];
        [adcHistory[chan] addDataToTimeAverage:[self adc:chan]];
        
        if(mjdPreAmpTable[chan].calculateLeakageCurrent){
            int     leakageIndex = mjdPreAmpTable[chan].leakageCurrentIndex;
            float   aValue       = [self leakageCurrent:leakageIndex];
            if(!leakageCurrentHistory[leakageIndex]) leakageCurrentHistory[leakageIndex] = [[ORTimeRate alloc] init];
            [leakageCurrentHistory[leakageIndex] addDataToTimeAverage:aValue];
        }
    }
}
- (void) calculateLeakageCurrentForAdc:(int) adcChan
{
    //value returned in picoamps
    float nanoToPico = 1000.;
    
    int currentChan = mjdPreAmpTable[adcChan].leakageCurrentIndex;
    if(currentChan>=0){
        if([self feedBackResistor:adcChan] != 0){
            //leakage current is (first stage output voltage - baseline voltage)/feedback resistance
            float leakageCurrent = -nanoToPico*([self adc:adcChan] - [self baselineVoltage:adcChan])/ [self feedBackResistor:adcChan];//in picoamps
            [self setLeakageCurrent:currentChan value:leakageCurrent];
            //[self setLeakageCurrent:adcChan value:leakageCurrent];
            [self checkLeakageCurrentIsWithinLimits:currentChan];
            
            //NSLog(@"leakage adc channel %d, preamp %d = %f pA\n",adcChan,mjdPreAmpTable[adcChan].leakageCurrentIndex,leakageCurrent);
        }
        else  [self setLeakageCurrent:currentChan value:0];
    }
    
}

- (void) postCouchDBRecord
{    
    NSDate* now = [NSDate date];
    int detectorToAdc[10]   = {0,1,2,3,4,8,9,10,11,12};
    int tempChanToUse[10]   = {7,7,7,7,7,15,15,15,15,15};
    NSString* machineName = computerName();
    if(!lastDataBaseUpdate || [now timeIntervalSinceDate:lastDataBaseUpdate] >= 60){
        
        [lastDataBaseUpdate release];
        lastDataBaseUpdate = [now retain];
 
 
        
        //just ten detectors per preamp
        int i;
        for(i=0;i<10;i++){
            int detectorAdcChannel = detectorToAdc[i];
            int tempAdcChannel     = tempChanToUse[i];
            if((detectorName[detectorAdcChannel].length!=0) && (adcEnabledMask & (0x1 << detectorAdcChannel))){
                NSDictionary* historyRecord = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSString stringWithFormat:@"PreAmp%d",[self uniqueIdNumber]], @"preamp",
                    detectorName[detectorAdcChannel],                               @"title",
                    machineName,                                                    @"machine",
                    [NSNumber numberWithInt:detectorAdcChannel],                    @"adcIndex",
                    [NSArray arrayWithObjects:
                        [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:adcs[detectorAdcChannel]] forKey:@"Baseline Voltage"] ,
                        [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:leakageCurrents[i]]       forKey:@"Leakage Current"],
                        [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:adcs[tempAdcChannel]]     forKey:@"Adc Temperature"],
                         nil
                    ],@"adcs",
                    nil
                    ];
                
                NSDictionary* dataBaseRecord = [NSDictionary dictionaryWithObjectsAndKeys:
                                                @"mjd_detectors",@"CustomDataBase",
                                                historyRecord,   @"DataBaseRecord",
                                                nil];

                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddHistoryAdcRecord" object:self userInfo:dataBaseRecord];
            }
        }
    }
    
    //we also post a snapshot to the machine database
    NSMutableDictionary* theRecord = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      [NSString stringWithFormat:@"%@",[self fullID]], @"object",
                                      machineName,                                     @"machine",
                                      nil];
    NSMutableArray* detectorArray = [NSMutableArray array];
    
    int i;
    for(i=0;i<10;i++){
        int detectorAdcChannel = detectorToAdc[i];
        if((detectorName[detectorAdcChannel].length!=0) && (adcEnabledMask & (0x1 << detectorAdcChannel))){
            NSDictionary* detectorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:detectorAdcChannel],          @"channel",
                                          [NSNumber numberWithFloat:adcs[detectorAdcChannel]],  @"baselineVoltage",
                                          [feedBackResistors objectAtIndex:i],                  @"feedBackResistors",
                                          [baselineVoltages objectAtIndex:i],                   @"baselineAtZeroVolts",
                                          [NSNumber numberWithFloat:leakageCurrents[i]],        @"leakageCurrent",
                                          [self detectorName:detectorAdcChannel],               @"detectorName",
                                          nil];
            [detectorArray addObject:detectorInfo];
        }
    }
    
    NSArray* temperatures = [NSArray arrayWithObjects:
                         [NSNumber numberWithFloat:adcs[7]],
                         [NSNumber numberWithFloat:adcs[15]],
                         nil];
  
    if([detectorArray count])[theRecord setObject:detectorArray forKey:@"detectors"];
    
    [theRecord setObject:temperatures                        forKey:@"temperatures"];
    [theRecord setObject:[NSNumber numberWithFloat:adcs[5]]  forKey:@"+12V"];
    [theRecord setObject:[NSNumber numberWithFloat:adcs[6]]  forKey:@"-12V"];
    [theRecord setObject:[NSNumber numberWithFloat:adcs[13]] forKey:@"+24V"];
    [theRecord setObject:[NSNumber numberWithFloat:adcs[14]] forKey:@"-24V"];
    [theRecord setObject:[NSNumber numberWithInt:pollTime]   forKey:@"pollTime"];
    [theRecord setObject:[NSNumber numberWithLong:supplyErrors[0]] forKey:@"+12VErrors"];
    [theRecord setObject:[NSNumber numberWithLong:supplyErrors[1]] forKey:@"-12VErrors"];
    [theRecord setObject:[NSNumber numberWithLong:supplyErrors[2]] forKey:@"+24VErrors"];
    [theRecord setObject:[NSNumber numberWithLong:supplyErrors[3]] forKey:@"-24VErrors"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:theRecord];
    
    NSString* s =  [NSString stringWithFormat:@"PreAmpSupply%u",[self uniqueIdNumber]];
    NSDictionary* historyRecord = [NSDictionary dictionaryWithObjectsAndKeys:
                                   s,       @"name",
                                   s,       @"title",
                                   [NSArray arrayWithObjects:
                                    [NSDictionary dictionaryWithObject: [NSNumber numberWithLong: supplyErrors[0]]        forKey:@"+12VErrors"],
                                    [NSDictionary dictionaryWithObject: [NSNumber numberWithLong: supplyErrors[1]]        forKey:@"-12VErrors"],
                                    [NSDictionary dictionaryWithObject: [NSNumber numberWithLong: supplyErrors[2]]        forKey:@"+24VErrors"],
                                    [NSDictionary dictionaryWithObject: [NSNumber numberWithLong: supplyErrors[3]]        forKey:@"-24VErrors"],
                                     nil
                                    ],
                                   @"adcs",
                                   nil
                                   ];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddHistoryAdcRecord" object:self userInfo:historyRecord];

    
    
}

@end

@implementation ORMjdPreAmpPollQueue
SYNTHESIZE_SINGLETON_FOR_ORCLASS(MjdPreAmpPollQueue);
+ (NSOperationQueue*)   queue                   { return [[ORMjdPreAmpPollQueue sharedMjdPreAmpPollQueue] queue];  }
+ (void)                cancelAllOperations     { [[ORMjdPreAmpPollQueue sharedMjdPreAmpPollQueue] cancelAllOperations]; }
+ (void) addRequest:(MjdPreAmpPollRequest*)aRequest
{
   [[ORMjdPreAmpPollQueue sharedMjdPreAmpPollQueue] addRequest:aRequest];
}
- (id) init
{
    self = [super init];
    queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:1];
    return self;
}

- (NSOperationQueue*) queue                 { return queue;                 }
- (void) cancelAllOperations                { [queue cancelAllOperations];  }
- (void) addRequest:(MjdPreAmpPollRequest*)anOp      {
    [queue addOperation:anOp];
}
@end

@implementation MjdPreAmpPollRequest
- (id) initWithDelegate:(id)aDelegate
{
    self = [super init];
    delegate = aDelegate;
    return self;
}
     
-(void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
    if(![self isCancelled]){
        [delegate performSelectorOnMainThread:@selector(readAllAdcs) withObject:nil waitUntilDone:YES];
        int i;
        for(i=0;i<25;i++){
            [NSThread sleepForTimeInterval:.2];
            if([self isCancelled])break;
        }

    }
    [delegate pollRequestIsFinished];
    [thePool release];
}
@end


