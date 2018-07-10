//
//  NcdMuxBoxModel.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "NcdMuxBoxModel.h"
#import "NcdMuxModel.h"
#import "NcdMuxHWModel.h"
#import "ORRateGroup.h"
#import "ORAxis.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "OHexFormatter.h"
#import "ORDataTaker.h"

#pragma mark ¥¥¥Notification Strings
NSString* NcdMuxChan							= @"Ncd Mux Channel Value";
NSString* NcdThresholdDacChangedNotification    = @"Ncd Mux Box Dac Changed";
NSString* NcdMuxDacArrayChangedNotification 	= @"Ncd Mux Box Dac Threshold Array Changed";
NSString* NcdMuxAdcThresChangedNotification 	= @"Ncd Mux Box Adc Threshold Array Changed";
NSString* ORMuxBoxRateChangedNotification       = @"ORMuxBoxRateChangedNotification";
NSString* ORMuxBoxTotalRateChangedNotification	= @"ORMuxBoxTotalRateChangedNotification";
NSString* ORMuxBoxTimeRateXChangedNotification	= @"ORMuxBoxTimeRateXChangedNotification";
NSString* ORMuxBoxTimeRateYChangedNotification	= @"ORMuxBoxTimeRateYChangedNotification";
NSString* ORMuxBoxRateGroupChangedNotification  = @"ORMuxBoxRateGroupChangedNotification";
NSString* ORMuxBoxBusNumberChangedNotification = @"ORMuxBoxBusNumberChangedNotification";
NSString* ORMuxBoxChannelSelectionChangedNotification = @"ORMuxBoxChannelSelectionChangedNotification";
NSString* ORMuxBoxDacValueChangedNotification   = @"ORMuxBoxDacValueChangedNotification";
NSString* ORNcdMuxBoxScopeChanChangedNotification = @"ORNcdMuxBoxScopeChanChangedNotification";
NSString* ORMuxBoxCalibrationEnabledMaskChanged =@"ORMuxBoxCalibrationEnabledMaskChanged";
NSString* ORMuxBoxCalibrationFinalDeltaChanged  = @"ORMuxBoxCalibrationFinalDeltaChanged";
NSString* ORMuxBoxCalibrationTaskChanged	= @"ORMuxBoxCalibrationTaskChanged";
NSString* NcdMuxCalibrationStateChanged		=@"NcdMuxCalibrationStateChanged";

NSString* NcdMuxBoxSettingsLock			= @"NcdMuxBoxSettingsLock";
NSString* NcdMuxBoxCalibrationLock		= @"NcdMuxBoxCalibrationLock";
NSString* NcdMuxBoxTestLock			= @"NcdMuxBoxTestLock";
NSString* NcdMuxStateChannel			= @"NcdMuxStateChannel";

#pragma mark ¥¥¥Local Strings
static NSString* MuxBoxToControllerConnect      = @"Ncd Mux Box to Mux Controller Connector";

#define kLogChannel 12

@implementation NcdMuxBoxModel

#pragma mark ¥¥¥initialization
- (id) init //designated initializer
{
    short i;
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    
    [self setThresholdDacs:[NSMutableArray arrayWithCapacity:kNumMuxChannels]];
    [self setThresholdAdcs:[NSMutableArray arrayWithCapacity:kNumMuxChannels]];
    
    for(i=0;i<kNumMuxChannels;i++){
        [thresholdDacs insertObject:[NSNumber numberWithInt:10] atIndex:i];
        [thresholdAdcs insertObject:[NSNumber numberWithInt:0] atIndex:i];
    }
    
    [self setScopeChan:-1];
    
    [self setRateGroup:[[[ORRateGroup alloc] initGroup:kNumMuxChannels groupTag:0] autorelease]];
    [rateGroup setIntegrationTime:5];
    
    rateAttributes = [[NSMutableDictionary dictionary] retain];
    [rateAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
    [rateAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
    [rateAttributes setObject:[NSNumber numberWithBool:NO] forKey:ORAxisUseLog];
    
    totalRateAttributes = [[NSMutableDictionary dictionary] retain];
    [totalRateAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
    [totalRateAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
    [totalRateAttributes setObject:[NSNumber numberWithBool:NO] forKey:ORAxisUseLog];
    
    timeRateXAttributes = [[NSMutableDictionary dictionary] retain];
    [timeRateXAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
    [timeRateXAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
    [timeRateXAttributes setObject:[NSNumber numberWithBool:NO] forKey:ORAxisUseLog];
    
    timeRateYAttributes = [[NSMutableDictionary dictionary] retain];
    [timeRateYAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
    [timeRateYAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
    [timeRateYAttributes setObject:[NSNumber numberWithBool:YES] forKey:ORAxisUseLog];
    
    [self setThresholdCalibrationStates:[NSMutableArray arrayWithCapacity:kNumMuxChannels]];
    
	calibrationFinalDelta = 10;
	calibrationEnabledMask = 0xff;
    
    
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [rateGroup quit];
    [calibrationTask abort];
    
	[calibrationTask setDelegate:nil];
    [calibrationTask release];
    [thresholdDacs release];
    [thresholdAdcs release];
    [rateGroup release];
    [rateAttributes release];
    [totalRateAttributes release];
    [timeRateXAttributes release];
    [timeRateYAttributes release];
    [thresholdCalibrationStates release];
    [super dealloc];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(2,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:MuxBoxToControllerConnect];
	[aConnector setConnectorType: 'MuxI' ];
	[aConnector addRestrictedConnectionType: 'MuxO' ]; //can only connect to Mux outputs
	[aConnector setIoType:kInputConnector];
    [aConnector release];
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"NcdMuxBox"]];
}

- (void) makeMainController
{
    [self linkToController:@"NcdMuxBoxController"];
}


#pragma mark ¥¥¥Accessors
- (NSMutableArray*) thresholdDacs
{
    return thresholdDacs;
}

- (NSString*) helpURL
{
	return @"NCD/Mux_Box.html";
}

- (void) setThresholdDacs:(NSMutableArray*)someThresholds
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThresholdDacs:[self thresholdDacs]];
    
    [someThresholds retain];
    [thresholdDacs release];
    thresholdDacs = someThresholds;
    
    if(someThresholds)[[NSNotificationCenter defaultCenter]
					   postNotificationName:NcdMuxDacArrayChangedNotification
					   object:self];
    
}

- (NSMutableArray*) thresholdAdcs;
{
    return thresholdAdcs;
}

- (unsigned short) thresholdDac:(unsigned short) aChan
{
    return [[thresholdDacs objectAtIndex:aChan] shortValue];
}

- (unsigned short) thresholdAdc:(unsigned short) aChan
{
    return [[thresholdAdcs objectAtIndex:aChan] shortValue];
}

- (void) setThresholdAdc:(unsigned short) aChan withValue:(short) aValue
{
    //not undoable
    
    [thresholdAdcs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithShort:aValue]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NcdMuxAdcThresChangedNotification
                                                        object:self];
}

- (void) setThresholdAdcs:(NSMutableArray*)someThresholds;
{
    //not undoable
    
    [someThresholds retain];
    [thresholdAdcs release];
    thresholdAdcs = someThresholds;
    
    if(someThresholds)[[NSNotificationCenter defaultCenter] postNotificationName:NcdMuxAdcThresChangedNotification
                                                                          object:self];
}


-(void) setThresholdDac:(unsigned short) aChan withValue:(unsigned short) aThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThresholdDac:aChan withValue:[self thresholdDac:aChan]];
    
    [thresholdDacs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aThreshold]];
    
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey:NcdMuxChan];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NcdThresholdDacChangedNotification
                                                        object:self
                                                      userInfo:userInfo];
}


- (ORRateGroup*) rateGroup
{
    return rateGroup;
}
- (void) setRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [rateGroup release];
    rateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMuxBoxRateGroupChangedNotification
	 object:self];
}

- (unsigned long) rateCount:(unsigned short)index
{
    if(index<kNumMuxChannels)return rateCount[index];
    else return 0;
}

- (void) setIntegrationTime:(double)newIntegrationTime
{
    //we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setIntegrationTime:[rateGroup integrationTime]];
    [rateGroup setIntegrationTime:newIntegrationTime];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"mux %d",[self muxID]];
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
	 postNotificationName:ORMuxBoxRateChangedNotification
	 object:self];
}

- (NSMutableDictionary*) totalRateAttributes
{
    return totalRateAttributes;
}
- (void) setTotalRateAttributes:(NSMutableDictionary*)newTotalRateAttributes
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTotalRateAttributes:totalRateAttributes];
    
    [totalRateAttributes autorelease];
    totalRateAttributes=[newTotalRateAttributes retain];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMuxBoxTotalRateChangedNotification
	 object:self];
}


- (NSMutableDictionary*) timeRateXAttributes
{
    return timeRateXAttributes;
}
- (void) setTimeRateXAttributes:(NSMutableDictionary*)newTimeRateXAttributes
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeRateXAttributes:timeRateXAttributes];
    
    [timeRateXAttributes autorelease];
    timeRateXAttributes=[newTimeRateXAttributes retain];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMuxBoxTimeRateXChangedNotification
	 object:self];
}

- (NSMutableDictionary*) timeRateYAttributes
{
    return timeRateYAttributes;
}
- (void) setTimeRateYAttributes:(NSMutableDictionary*)newTimeRateYAttributes
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeRateYAttributes:timeRateYAttributes];
    
    [timeRateYAttributes autorelease];
    timeRateYAttributes=[newTimeRateYAttributes retain];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMuxBoxTimeRateYChangedNotification
	 object:self];
}

- (unsigned short) busNumber
{
    return busNumber;
}

- (void) setBusNumber:(unsigned short)newBusNumber
{
    busNumber=newBusNumber;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMuxBoxBusNumberChangedNotification
	 object:self];
}

- (int) scopeChan
{
    return scopeChan;
}
- (void) setScopeChan:(int)aNewScopeChan
{
    [[[self undoManager] prepareWithInvocationTarget:self] setScopeChan:scopeChan];
    
    scopeChan = aNewScopeChan;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORNcdMuxBoxScopeChanChangedNotification
	 object:self];
}

- (NSMutableArray *)thresholdCalibrationStates {
    return thresholdCalibrationStates; 
}

- (void)setThresholdCalibrationStates:(NSMutableArray *)aThresholdCalibrationStates {
    [aThresholdCalibrationStates retain];
    [thresholdCalibrationStates release];
    thresholdCalibrationStates = aThresholdCalibrationStates;
}


- (unsigned short) calibrationEnabledMask {
    
    return calibrationEnabledMask;
}

- (void) setCalibrationEnabledMask:(unsigned short)aCalibrationEnabledMask 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCalibrationEnabledMask:calibrationEnabledMask];
    calibrationEnabledMask = aCalibrationEnabledMask;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMuxBoxCalibrationEnabledMaskChanged
	 object:self];
}


- (int) calibrationFinalDelta 
{
    return calibrationFinalDelta;
}

- (void) setCalibrationFinalDelta:(int)aCalibrationFinalDelta
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCalibrationFinalDelta:calibrationFinalDelta];
    calibrationFinalDelta = aCalibrationFinalDelta;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMuxBoxCalibrationFinalDeltaChanged
	 object:self];
}

- (ThresholdCalibrationTask *) calibrationTask 
{
    return calibrationTask; 
}

- (void) setCalibrationTask:(ThresholdCalibrationTask *)aCalibrationTask 
{
    [aCalibrationTask retain];
    [calibrationTask release];
    calibrationTask = aCalibrationTask;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMuxBoxCalibrationTaskChanged
	 object:self];
}


#pragma mark ¥¥¥Testing
- (unsigned short) dacValue
{
    return dacValue;
}
- (void) setDacValue:(unsigned short)aDacValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDacValue:dacValue];
    
    dacValue = aDacValue;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMuxBoxDacValueChangedNotification
	 object:self];
}

// ===========================================================
// - selectedChannel:
// ===========================================================
- (unsigned short)selectedChannel
{
    return selectedChannel;
}

// ===========================================================
// - setSelectedChannel:
// ===========================================================
- (void)setSelectedChannel:(unsigned short)aSelectedChannel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannel:selectedChannel];
    selectedChannel = aSelectedChannel;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMuxBoxChannelSelectionChangedNotification
	 object:self];
}



- (void) loadThresholdDacs
{
    @try {
		short chan;
		for(chan = 0;chan<kNumMuxChannels;chan++){
			[self writeThresholdDac:chan withValue:[[thresholdDacs objectAtIndex:chan] shortValue]];
			
		}
	}
	@catch(NSException* localException) {
		[localException raise];
	}
}

- (void) writeThresholdDac:(unsigned short)chan withValue:(unsigned short)aValue
{
    ORConnector* aConnection = [self connectorOn:MuxBoxToControllerConnect];
    int muxBox = [aConnection identifer];
    [[aConnection objectLink] writeDACValue:aValue mux:muxBox channel:chan];
}

-(void) readThresholds
{
    @try {
		short chan;
		for(chan = 0;chan<kNumMuxChannels;chan++){
			[self readThreshold:chan];
		}
		//if the adc reads back 0xff then the adcs need to be reset.
		if([self  thresholdAdc:0] == 0xff){
			[[self objectConnectedTo:MuxBoxToControllerConnect]  resetAdcs];
			for(chan = 0;chan<kNumMuxChannels;chan++){
				[self readThreshold:chan];
			}
		}    
	}
	@catch(NSException* localException) {
		[localException raise];
	}
}

-(void) readThreshold:(unsigned short) aChannel
{
    ORConnector* aConnection = [self connectorOn:MuxBoxToControllerConnect];
    int muxBox = [aConnection identifer];
    
    unsigned short theDrValue = -1;
    if((muxBox>=0) && (muxBox<8)){
        if([[aConnection objectLink] getADCValue:&theDrValue mux:muxBox channel:aChannel] != kAdcToDr){
            [self setThresholdAdc:aChannel withValue:-1];
        }
        else [self setThresholdAdc:aChannel withValue:(kDataByteMask & theDrValue)];
    }
}

- (void) saveAllThresholds
{
    short chan;
    for(chan = 0;chan<kNumMuxChannels;chan++){
        oldThresholdDacs[chan] = [[thresholdDacs objectAtIndex:chan] shortValue];
    }
}

- (void) restoreAllThresholds
{
    short chan;
    for(chan = 0;chan<kNumMuxChannels;chan++){
		[self setThresholdDac:chan withValue:oldThresholdDacs[chan]];
    }
}

- (void) setAllThresholdsTo:(NSNumber*)aThresholdNumber
{
    short chan;
    for(chan = 0;chan<kNumMuxChannels;chan++){
		[self setThresholdDac:chan withValue:[aThresholdNumber shortValue]];
    }
}

#pragma mark ¥¥¥Calibration
- (void) loadCalibrationValues
{
	[self initMux];
}

- (void) calibrate
{
    if(![self calibrationTask]){
		[self setCalibrationTask:[[[ThresholdCalibrationTask alloc] init] autorelease]];
		[calibrationTask setDelegate:self];
		[calibrationTask setName:@"Mux Calibration"];
		[calibrationTask start:kNumMuxChannels-1 enabledMask:[self calibrationEnabledMask] rateGroup:rateGroup tag:[self muxID]];
    }
    else {
		[calibrationTask abort];
		[self setCalibrationTask:nil];
    }
}


- (void) setThresholdCalibration:(int)channel state:(NSString*)aString
{
    [thresholdCalibrationStates replaceObjectAtIndex:channel withObject:aString];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NcdMuxCalibrationStateChanged
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:channel] forKey:NcdMuxStateChannel]];
}

- (NSString*) thresholdCalibration:(int)channel
{
    return  [thresholdCalibrationStates objectAtIndex:channel];
}


- (int) muxID
{
    ORConnector* aConnection = [[[self connectors] objectForKey:MuxBoxToControllerConnect] connector];
    if(aConnection) return [aConnection identifer];
    else return -1;
}

- (void) statusQuery
{
    ORConnector* aConnection = [self connectorOn:MuxBoxToControllerConnect];
    int muxBox = [aConnection identifer];
    
    unsigned short theDrValue = -1;
    if((muxBox>=0) && (muxBox<8)){
        [[aConnection objectLink] getStatusQuery:&theDrValue mux:muxBox];
        [self setBusNumber:theDrValue];
    }
}

- (void) ping
{
    [self statusQuery];
    NSLog(@"Mux Box Number:%d\n",busNumber);
}


-(void) initMux
{
    [self loadThresholdDacs];
    [self readThresholds];
}

- (void) checkThresholds
{
    NSMutableArray* diffArray = [NSMutableArray arrayWithCapacity:[thresholdDacs count]];
    int i;
    bool passedDiffTest = YES;
    for(i=0;i<[thresholdDacs count];i++){
        int diff = [[thresholdDacs objectAtIndex:i]intValue]-[[thresholdAdcs objectAtIndex:i]intValue];
        if(abs(diff)>3)passedDiffTest = NO;
        [diffArray addObject:[NSNumber numberWithInt:diff]];
    }
    if(!passedDiffTest){
        NSBeep();
        NSLog(@"Mux <0x%x mux %d> thres/adc mismatch <deltas=%@>.\n",
              [self busNumber],[self muxID], diffArray);
    }
    
}


-(void) runMuxBitTest
{
    unsigned char aValue;
    long aChanHighBitStruct[8];  	//number of times incorrect when a 1 is written to the bit
    long aChanLowBitStruct[8];  	//number of times incorrect when a 0 is written to the bit
    short i,thebit,numTests;
    bool anError = false;
    unsigned short kMaxTests = 50;
    ORConnector* aConnection = [[[self connectors] objectForKey:MuxBoxToControllerConnect] connector];
    int muxBox = [aConnection identifer];
    
    NSLog(@"DAC bit test for Mux %d.\n",muxBox);
    NSLog(@"This test will perform %d write attempts\n",8*kMaxTests);
    NSLog(@"There will be %d writes of 1 and 0 to each bit on each channel.\n",kMaxTests/2);
    
    NSMutableArray* oldValues = [NSMutableArray arrayWithCapacity:13];
    [oldValues addObjectsFromArray:thresholdDacs];
    
    for(i=0;i<kNumMuxChannels;i++){
        memset(aChanHighBitStruct,0,sizeof(long)*8);
        memset(aChanLowBitStruct,0,sizeof(long)*8);
        NSLog(@"Testing channel:%d\n",i);
        for(thebit=0;thebit<8;thebit++){
            for(numTests=0;numTests<kMaxTests;numTests++){
                switch(thebit){
                    case 0:
                        if(numTests & 1) aValue = 0x20 + (1<<thebit);
                        else aValue = 0x20;
                        break;
                    case 1:
                        if(numTests & 1) aValue = 0x20 + (1<<thebit);
                        else aValue = 0x20;
                        break;
                    case 2:
                        if(numTests & 1) aValue = 0x22  + (1<<thebit);
                        else aValue = 0x22;
                        break;
                    case 3:
                        if(numTests & 1) aValue = 0x5c;
                        else aValue= 0x54;
                        break;
                    default:
                        if(numTests & 1) aValue = 0x0a + (1<<thebit);
                        else aValue = 0x0a;
                        break;
                }
                @try {
                    [self setThresholdDac:i withValue:aValue];
                    unsigned short theDrValue;
                    if([[aConnection objectLink] getADCValue:&theDrValue mux:muxBox channel:i] == kAdcToDr){
                        [self setThresholdAdc:i withValue:(kDataByteMask & theDrValue)];
                    }
                    
				}
				@catch(NSException* localException) {
					anError = true;
				}
				if(anError)break;
				if(([self thresholdAdc:i] & (1<<thebit)) != (aValue & (1<<thebit))){
					if(aValue & (1<<thebit)){
						aChanHighBitStruct[thebit]++;
					}
					else{
						aChanLowBitStruct[thebit]++;
					}
				}
            }
			if(anError) break;
        }
		NSLog(@"Channel %d...\n",i);
		short l;
		for(l=0;l<8;l++){
			if(aChanHighBitStruct[l] != 0 | aChanLowBitStruct[l] != 0){
				NSLog(@"Errors on Bit %d\n",l);
				NSLog(@"read a 0 when wrote a 1:%d\n",aChanHighBitStruct[l]);
				NSLog(@"read a 1 when wrote a 0:%d\n",aChanLowBitStruct[l]);
			}
		}
		if(anError) break;
    }
	
	[self setThresholdDacs:oldValues];
	
}


#pragma mark ¥¥¥Archival
static NSString* NcdMuxThresholdDacs	    = @"Ncd Mux Threshold Dacs";
static NSString* NcdMuxThresholdAdcs	    = @"Ncd Mux Threshold Adcs";
static NSString *ORMuxBoxRateAttributes     = @"ORMuxBox RateAttributes";
static NSString *ORMuxBoxTotalRateAttributes= @"ORMuxBox TotalRateAttributes";
static NSString *ORMuxBoxTimeRateXAttributes= @"ORMuxBox TimeRateXAttributes";
static NSString *ORMuxBoxTimeRateYAttributes= @"ORMuxBox TimeRateYAttributes";
static NSString *ORMuxBoxRateGroup          = @"MuxBox Rate Group";
static NSString *ORMuxBoxSelectedChannel    = @"ORMuxBoxSelectedChannel";
static NSString *ORMuxBoxDacValue           = @"ORMuxBoxDacValue";
static NSString* ORNcdMuxBoxScopeChan       = @"ORNcdMuxBoxScopeChan";
static NSString* ORMuxBoxCalibrationEnabledMask =@"ORMuxBoxCalibrationEnabledMask";
static NSString* ORMuxBoxCalibrationFinalDelta  = @"ORMuxBoxCalibrationFinalDelta";
static NSString* ORMuxCalibrationStates     = @"ORMuxCalibrationStates";
static NSString* ORMuxBoxBusNumber          = @"ORMuxBoxBusNumber";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    
    scopeChan = -1;
    
    [self loadMemento:decoder];
    [self setThresholdAdcs:[decoder decodeObjectForKey:NcdMuxThresholdAdcs]];
    
    [self setRateGroup:[decoder decodeObjectForKey:ORMuxBoxRateGroup]];
    [self setRateAttributes:[decoder decodeObjectForKey:ORMuxBoxRateAttributes]];
    [self setTotalRateAttributes:[decoder decodeObjectForKey:ORMuxBoxTotalRateAttributes]];
    [self setTimeRateXAttributes:[decoder decodeObjectForKey:ORMuxBoxTimeRateXAttributes]];
    [self setTimeRateYAttributes:[decoder decodeObjectForKey:ORMuxBoxTimeRateYAttributes]];
    
    [self setSelectedChannel:[decoder decodeIntForKey:ORMuxBoxSelectedChannel]];
    [self setDacValue:[decoder decodeIntForKey:ORMuxBoxDacValue]];
    [self setBusNumber:[decoder decodeIntForKey:ORMuxBoxBusNumber]];
    
    
    id scopeChanObj = [decoder decodeObjectForKey:ORNcdMuxBoxScopeChan];
    if(scopeChanObj!=nil)[self setScopeChan:[scopeChanObj intValue]];
    else [self setScopeChan:-1];
    
	calibrationFinalDelta = 10;
	calibrationEnabledMask = 0xff;
	
    [self setCalibrationEnabledMask:[decoder decodeIntForKey:ORMuxBoxCalibrationEnabledMask]];
    [self setCalibrationFinalDelta:[decoder decodeIntForKey:ORMuxBoxCalibrationFinalDelta]];
    
    [self setThresholdCalibrationStates:[decoder decodeObjectForKey:ORMuxCalibrationStates]];
    
    if(!rateGroup){
        [self setRateGroup:[[[ORRateGroup alloc] initGroup:kNumMuxChannels groupTag:0] autorelease]];
        [rateGroup setIntegrationTime:5];
    }
    [self startRates];
    [rateGroup resetRates];
    [rateGroup calcRates];
    
    //what follows is temp... in case old object are being restored.
    
    if(!thresholdCalibrationStates){
        [self setThresholdCalibrationStates:[NSMutableArray array]];
        int i;
        for(i=0;i<kNumMuxChannels;i++){
            [thresholdCalibrationStates addObject:@"idle"];
        }
    }
    
    if(!rateAttributes){
        rateAttributes = [[NSMutableDictionary dictionary] retain];
        [rateAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
        [rateAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
        [rateAttributes setObject:[NSNumber numberWithBool:NO] forKey:ORAxisUseLog];
		[self setRateAttributes:rateAttributes];
    }
    if(!totalRateAttributes){
        totalRateAttributes = [[NSMutableDictionary dictionary] retain];
        [totalRateAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
        [totalRateAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
        [totalRateAttributes setObject:[NSNumber numberWithBool:NO] forKey:ORAxisUseLog];
		[self setTotalRateAttributes:totalRateAttributes];
    }
    
    if(!timeRateXAttributes){
        timeRateXAttributes = [[NSMutableDictionary dictionary] retain];
        [timeRateXAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
        [timeRateXAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
        [timeRateXAttributes setObject:[NSNumber numberWithBool:NO] forKey:ORAxisUseLog];
		[self setTimeRateXAttributes:timeRateXAttributes];
    }
    
    if(!timeRateYAttributes){
        timeRateYAttributes = [[NSMutableDictionary dictionary] retain];
        [timeRateYAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
        [timeRateYAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
        [timeRateYAttributes setObject:[NSNumber numberWithBool:YES] forKey:ORAxisUseLog];
		[self setTimeRateYAttributes:timeRateYAttributes];
    }
    
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [self saveMemento:encoder];
    [encoder encodeObject:[self thresholdAdcs] forKey:NcdMuxThresholdAdcs];
    [encoder encodeObject:[self rateGroup] forKey:ORMuxBoxRateGroup];
    
    [encoder encodeObject:[self rateAttributes] forKey:ORMuxBoxRateAttributes];
    [encoder encodeObject:[self totalRateAttributes] forKey:ORMuxBoxTotalRateAttributes];
    [encoder encodeObject:[self timeRateXAttributes] forKey:ORMuxBoxTimeRateYAttributes];
    [encoder encodeObject:[self timeRateYAttributes] forKey:ORMuxBoxTimeRateXAttributes];
    
    [encoder encodeInt:[self selectedChannel] forKey:ORMuxBoxSelectedChannel];
    [encoder encodeInt:[self dacValue] forKey:ORMuxBoxDacValue];
    [encoder encodeObject:[NSNumber numberWithInt:scopeChan] forKey:ORNcdMuxBoxScopeChan];
    
    [encoder encodeInt:[self calibrationEnabledMask] forKey:ORMuxBoxCalibrationEnabledMask];
    [encoder encodeInt:[self calibrationFinalDelta] forKey:ORMuxBoxCalibrationFinalDelta];
    [encoder encodeInt:[self busNumber] forKey:ORMuxBoxBusNumber];
    
    [encoder encodeObject:[self thresholdCalibrationStates] forKey:ORMuxCalibrationStates];
    
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithInt:[self muxID]] forKey:@"busNumber"];
    [objDictionary setObject:[NSNumber numberWithInt:[self busNumber]] forKey:@"muxID"];
    [objDictionary setObject:thresholdAdcs forKey:@"thresholdsAdcs"];
    [objDictionary setObject:thresholdDacs forKey:@"thresholds"];
    
    [dictionary setObject:objDictionary forKey:[self identifier]];
    return objDictionary;
}

- (void)loadMemento:(NSCoder*)aDecoder
{
    [[self undoManager] disableUndoRegistration];
    [self setThresholdDacs:[aDecoder decodeObjectForKey:NcdMuxThresholdDacs]];
    [[self undoManager] enableUndoRegistration];
}

- (void)saveMemento:(NSCoder*)anEncoder
{
    [anEncoder encodeObject:[self thresholdDacs] forKey:NcdMuxThresholdDacs];
}

- (NSData*) memento
{
    NSMutableData* memento = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:memento];
    [self saveMemento:archiver];
    [archiver finishEncoding];
	[archiver release];    
    return memento;
}

- (void) restoreFromMemento:(NSData*)aMemento
{
	if(aMemento){
		NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:aMemento];
		[self loadMemento:unarchiver];
		[unarchiver finishDecoding];
		[unarchiver release];
		@try {
			[self initMux];
		}
		@catch(NSException* localException) {
		}
	}
}


#pragma mark ¥¥¥Rates
- (void) startRates
{
    short i;
    for(i=0;i<kNumMuxChannels;i++){
        rateCount[i]=0;
    }
    [rateGroup start:self];
}

- (void) stopRates
{
    [rateGroup stop];
}

- (void) incChanCounts:(unsigned short)chanMask
{
    short i;
    for(i=0;i<kNumMuxChannels;i++){
        if(chanMask & (1L<<i)){
            ++rateCount[i];
        }
    }
}

#pragma mark ¥¥¥Rates
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
    if(groupTag == 0){
        if(counterTag>=0 && counterTag<kNumMuxChannels){
            return rateCount[counterTag];
        }
        else return 0;
    }
    else return 0;
}


- (void) reArm
{
    ORConnector* aConnection = [[[self connectors] objectForKey:MuxBoxToControllerConnect] connector];
    [[aConnection guardian] reArm];
}

- (void) readEventReg
{
    ORConnector* aConnection = [[[self connectors] objectForKey:MuxBoxToControllerConnect] connector];
    
    [[aConnection guardian] readAndDumpEvent];
}

- (void) readAdcValue
{
    [self readThreshold:[self selectedChannel]];
    NSLog(@"Read Threshold Adc channel:%d value:0x%0x\n",[self selectedChannel],[self thresholdAdc:[self selectedChannel]]);
}

- (void) writeDacValue
{
    [self writeThresholdDac:[self selectedChannel] withValue:[self dacValue]];
    NSLog(@"Loaded Threshold Channel:%d  with:0x%0x\n",[self selectedChannel],[self dacValue]);
}

#pragma mark ¥¥¥Threshold Calibration


- (int) tag
{
    ORConnector* aConnection = [[[self connectors] objectForKey:MuxBoxToControllerConnect] connector];
    return [aConnection identifer];
}

- (int) numberOfChannels
{
    return kNumMuxChannels-1; //don't count the log threshold
}

#pragma mark ¥¥¥HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormatter:[[[OHexFormatter alloc] init] autorelease]];
    [p setFormat:@"##0.00" upperLimit:255 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setThresholdDac:withValue:) getMethod:@selector(thresholdDac:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Log Threshold"];
    [p setFormatter:[[[OHexFormatter alloc] init] autorelease]];
    [p setFormat:@"##0.00" upperLimit:255 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setUseFixedChannel:kLogChannel]; //very, very special case.
    [p setSetMethod:@selector(setThresholdDac:withValue:) getMethod:@selector(thresholdDac:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initMux)];
    
    [a addObject:p];
    
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
    NSDictionary* muxDictionary =   [fileHeader objectForKey: [self identifier]];
    if([param isEqualToString:@"Threshold"])return [[muxDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else return nil;
}


- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Box" className:@"NcdMuxBoxModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"NcdMuxBoxModel"]];
    return a;
}

@end
