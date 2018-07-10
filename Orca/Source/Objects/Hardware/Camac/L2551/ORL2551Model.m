/*
 *  ORL2551Model.cpp
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ¥¥¥Imported Files
#import "ORL2551Model.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORCamacCrateModel.h"
#import "ORAxis.h"
#import "TimedWorker.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"

NSString* ORL2551OnlineMaskChangedNotification   = @"ORL2551OnlineMaskChangedNotification";
NSString* ORL2551SettingsLock                    = @"ORL2551SettingsLock";
NSString* ORL2551RateChangedNotification         = @"ORL2551RateChangedNotification";
NSString* ORL2551ScalerCountChangedNotification  = @"ORL2551ScalerCountChangedNotification";
NSString* ORL2551PollRateChangedNotification     = @"ORL2551PollRateChangedNotification";
NSString* ORL2551ShipScalersChangedNotification  = @"ORL2551ShipScalersChangedNotification";
NSString* ORL2551ClearOnStartChangedNotification = @"ORL2551ClearOnStartChangedNotification";
NSString* ORL2551PollWhenRunningChangedNotification = @"ORL2551PollWhenRunningChangedNotification";

@implementation ORL2551Model

#pragma mark ¥¥¥Initialization
- (id) init
{		
    self = [super init];
	rateAttributes = [[NSMutableDictionary dictionary] retain];
	[rateAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
	[rateAttributes setObject:[NSNumber numberWithDouble:500000000] forKey:ORAxisMaxValue];
	[rateAttributes setObject:[NSNumber numberWithBool:NO] forKey:ORAxisUseLog];
    [self makePoller:0];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [poller stop];
    [poller release];
    [lastTime release];
    [rateAttributes release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"L2551Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORL2551Controller"];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    if(pollWhenRunning && [gOrcaGlobals runInProgress]){
        [poller runWithTarget:self selector:@selector(readAllScalers)];
    }
}

- (void) sleep
{
    [super sleep];
    [poller stop];
}

- (NSString*) helpURL
{
	return @"CAMAC/L2551.html";
}

#pragma mark ¥¥¥Notifications
-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStopped:)
                         name: ORRunStoppedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runAboutToStart:)
                         name: ORRunAboutToStartNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStarted:)
                         name: ORRunAboutToStartNotification
                       object: nil];
    
    
}

- (void) runAboutToStart:(NSNotification*)aNote
{
    if(clearOnStart)[self clearAll];
	[self setPollingInterval:[poller timeInterval]];
}

- (void) runStarted:(NSNotification*)aNote
{
    if(pollWhenRunning){
        [poller runWithTarget:self selector:@selector(readAllScalers)];
    }
}

- (void) runStopped:(NSNotification*)aNote
{
    if(!doNotShipScalers){
		[self readAllScalers];
        [self shipScalerRecords];
        if(onlineMask){
            NSLog(@"L2551 Scaler Counts (Station %d)\n",[self stationNumber]);
            int i;
            for(i=0;i<12;i++){
                if(onlineMask & (0x0001<<i)){
                    NSLog(@"%2d: %d\n",i,scalerCount[i]);
                }
            }
        }
    }
    
    if(pollWhenRunning){
        [poller stop];
        int i;
        for(i=0;i<12;i++){
            [self setScalerRate:i value:0];
            lastScalerCount[i] = scalerCount[i];
        }
        [self setLastTime:[NSDate date]];
    }
    else {
        //if(clearOnStart)[self clearAll];
    }
}


#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"L2551";
}
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (unsigned short)onlineMask {
	
    return onlineMask;
}

- (void)setOnlineMask:(unsigned short)anOnlineMask {
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:onlineMask];
	
    onlineMask = anOnlineMask;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORL2551OnlineMaskChangedNotification
	 object:self];
    
}

- (BOOL)onlineMaskBit:(int)bit
{
	return (onlineMask&(0x1L<<bit))!=0;
}

- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = onlineMask;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setOnlineMask:aMask];
}

- (NSMutableDictionary*) rateAttributes
{
	return rateAttributes;
}

- (void) setRateAttributes:(NSMutableDictionary*)newRateAttributes
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRateAttributes:rateAttributes];
	
	[rateAttributes autorelease];
	rateAttributes=[newRateAttributes retain];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORL2551RateChangedNotification
	 object:self];    
}

- (void) setScalerCount:(unsigned short)chan value:(unsigned long)aValue
{
	NSAssert(chan < 12,@"setScalerCount index out of range");
    if(aValue != scalerCount[chan]){
        scalerCount[chan] = aValue;
        [[NSNotificationCenter defaultCenter]
		 postNotificationName:ORL2551ScalerCountChangedNotification
		 object:self
		 userInfo: [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"]];    
    }
}

- (unsigned long) scalerCount:(unsigned short)chan
{
	NSAssert(chan < 12,@"scalerCount index out of range");
    return scalerCount[chan];
}

- (void) setScalerRate:(unsigned short)chan value:(float)aValue
{
	NSAssert(chan < 12,@"setScalerRate index out of range");
    if(aValue != scalerRate[chan]){
        scalerRate[chan] = aValue;
        [[NSNotificationCenter defaultCenter]
		 postNotificationName:ORL2551RateChangedNotification
		 object:self
		 userInfo: [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"]];    
    }
}

- (float) scalerRate:(unsigned short)chan
{
	NSAssert(chan < 12,@"scalerRate index out of range");
    return scalerRate[chan];
}

- (NSDate *) lastTime
{
    return lastTime; 
}

- (void) setLastTime: (NSDate *) aLastTime
{
    [aLastTime retain];
    [lastTime release];
    lastTime = aLastTime;
}

- (BOOL) clearOnStart
{
    return clearOnStart;
}

- (void) setClearOnStart: (BOOL) flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClearOnStart:clearOnStart];
	
    clearOnStart = flag;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORL2551ClearOnStartChangedNotification
	 object:self];    
}

- (BOOL) doNotShipScalers
{
    return doNotShipScalers;
}

- (void) setDoNotShipScalers: (BOOL) flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoNotShipScalers:doNotShipScalers];
    doNotShipScalers = flag;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORL2551ShipScalersChangedNotification
	 object:self];    
}

- (BOOL) pollWhenRunning
{
    return pollWhenRunning;
}

- (void) setPollWhenRunning: (BOOL) flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollWhenRunning:pollWhenRunning];
    pollWhenRunning = flag;
    
    if(pollWhenRunning)[poller stop];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORL2551PollWhenRunningChangedNotification
	 object:self];    
}

#pragma mark ¥¥¥DataTaker

- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORL2551DecoderForScalers",         @"decoder",
								 [NSNumber numberWithLong:dataId],    @"dataId",
								 [NSNumber numberWithBool:NO],        @"variable",
								 [NSNumber numberWithLong:2],         @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Scalers"];
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"L2551"];
}

- (void) shipScalerRecords 
{  
    unsigned long data[14];
    int i;
    data[0] = dataId | 14;  //id and size
    data[1] = ([self crateNumber]&0xf)<<16 | ([self stationNumber]& 0x0000001f); //crate and card
    for(i=0;i<12;i++){
        data[2+i] = ((i&0xf)<<28) | (scalerCount[i]&0x00ffffff);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
                                                        object:[NSData dataWithBytes:data length:sizeof(long)*14]];
}

- (void) readAllScalers
{
    @try {
        if(onlineMask){
            int i;
            for(i=0;i<12;i++){
                if([self onlineMaskBit:i]){
                    unsigned long theValue;
                    unsigned short theStatus = [[self adapter] camacLongNAF:[self stationNumber] a:i f:0 data:&theValue];
                    [self decodeStatus:theStatus];
                    if(cmdAccepted){
                        [self setScalerCount:i value:theValue&0x00ffffff];
                    }
                }
            }
            [self calcRates];
        }
	}
	@catch(NSException* localException) {
	}
}

- (void) calcRates
{
    int i;
    if(lastTime){
        NSTimeInterval deltaTime = [[NSDate date] timeIntervalSinceDate:lastTime];
        for(i=0;i<12;i++){
            float diff = scalerCount[i] - lastScalerCount[i];
            if(diff>=0 && deltaTime>=1){
                [self setScalerRate:i value:diff/deltaTime];
            }
            lastScalerCount[i] = scalerCount[i];
        }
    }
    else {
        for(i=0;i<12;i++){
            scalerRate[i] = 0;
        }
    }
    
    [self setLastTime:[NSDate date]];
}

- (TimedWorker *) poller
{
    return poller; 
}

- (void) setPoller: (TimedWorker *) aPoller
{
    if(aPoller == nil){
        [poller stop];
    }
    [aPoller retain];
    [poller release];
    poller = aPoller;
}

- (void) setPollingInterval:(float)anInterval
{
    [self performSelector:@selector(readAllScalers)];
    if(!poller){
        [self makePoller:(float)anInterval];
    }
    else [poller setTimeInterval:anInterval];
    
    if(anInterval == 0){
        int i;
        for(i=0;i<12;i++){
            [self setScalerRate:i value:0];
        }
    }
	[poller stop];
    [poller runWithTarget:self selector:@selector(readAllScalers)];
}


- (void) makePoller:(float)anInterval
{
    [self setPoller:[TimedWorker TimeWorkerWithInterval:anInterval]];
}

#pragma mark ¥¥¥Hardware Test functions

- (void) readReset
{
    [self readAllScalers];
    unsigned long theValue;

    [[self adapter] camacLongNAF:[self stationNumber] a:11 f:2 data:&theValue]; //force reset
}

- (void) testLAM;
{
    unsigned short status = [[self adapter] camacShortNAF:[self stationNumber] a:0 f:8 data:nil];
    NSLog(@"LAM %@ set\n",isQbitSet(status)?@"is":@"is not");
}
- (void) clearAll
{
	[self readReset];
	//    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:9 data:nil];
	//    [self readAllScalers];
}

- (void) disableLAM
{
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:24 data:nil];
}

- (void) enableLAM
{
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:26 data:nil];
}

- (void) incAll
{
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:25 data:nil];
    [self readAllScalers];
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setOnlineMask:		[decoder decodeIntForKey:   @"L2551OnlineMask"]];
    [self setRateAttributes:	[decoder decodeObjectForKey:@"L2551RateAttributes"]];
    [self setPoller:			[decoder decodeObjectForKey:@"L2551Poller"]];
    [self setDoNotShipScalers:	[decoder decodeBoolForKey:  @"L2551DoNotShipScalers"]];
    [self setClearOnStart:		[decoder decodeBoolForKey:  @"L2551ClearOnStart"]];
    [self setPollWhenRunning:   [decoder decodeBoolForKey:  @"L2551PollWhenRunning"]];
    [[self undoManager] enableUndoRegistration];
	
    if (!poller)[self makePoller:0];
    
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:onlineMask        forKey:@"L2551OnlineMask"];
    [encoder encodeObject:rateAttributes forKey:@"L2551RateAttributes"];
    [encoder encodeObject:poller         forKey:@"L2551Poller"];
    [encoder encodeBool:doNotShipScalers forKey:@"L2551DoNotShipScalers"];
    [encoder encodeBool:clearOnStart     forKey:@"L2551ClearOnStart"];
    [encoder encodeBool:pollWhenRunning  forKey:@"L2551PollWhenRunning"];
}

#pragma mark ¥¥¥HW Wizard
- (int) numberOfChannels
{
    return 12;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Online"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setOnlineMaskBit:withValue:) getMethod:@selector(onlineMaskBit:)];
    [p setActionMask:kAction_Set_Mask|kAction_Restore_Mask];
    [a addObject:p];
	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Clear"];
    [p setSetMethodSelector:@selector(clearAll)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORCamacCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"ORL2551Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORL2551Model"]];
    return a;
	
}
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"OnlineMask"]) return [cardDictionary objectForKey:@"onlineMask"];
    else return nil;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithInt:onlineMask] forKey:@"onlineMask"];
    return objDictionary;
}

@end
