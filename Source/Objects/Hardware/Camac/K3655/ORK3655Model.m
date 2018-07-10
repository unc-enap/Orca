/*
 *  ORK3655Model.cpp
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
#import "ORK3655Model.h"

#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORCamacCrateModel.h"
#import "ORAxis.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"

NSString* ORK3655ModelEnableChanged				= @"ORK3655ModelEnableChanged";
NSString* ORK3655UseExtClockChanged				= @"ORK3655UseExtClockChanged";
NSString* ORK3655PulseNumberToSetChanged		= @"ORK3655PulseNumberToSetChanged";
NSString* ORK3655PulseNumberToClearChanged		= @"ORK3655PulseNumberToClearChanged";
NSString* ORK3655ClockFreqChanged				= @"ORK3655ClockFreqChanged";
NSString* ORK3655NumChansToUseChanged			= @"ORK3655NumChansToUseChanged";
NSString* ORK3655ContinousChanged				= @"ORK3655ContinousChanged";
NSString* ORK3655SettingsLock					= @"ORK3655SettingsLock";
NSString* ORK3655SetPointChangedNotification	= @"ORK3655SetPointChangedNotification";
NSString* ORK3655SetPointsChangedNotification	= @"ORK3655SetPointsChangedNotification";
NSString* ORK3655InhibitEnabledChanged			= @"ORK3655InhibitEnabledChanged";
NSString* ORK3655Chan							= @"ORK3655Chan";

@implementation ORK3655Model

#pragma mark ¥¥¥Initialization
- (id) init
{		
    self = [super init];
    return self;
}

- (void) dealloc
{
    [setPoints release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"K3655Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORK3655Controller"];
}

- (NSString*) helpURL
{
	return @"CAMAC/k3655.html";
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
}

- (void) runStarted:(NSNotification*)aNote
{
	[self initBoard];
}

- (void) runStopped:(NSNotification*)aNote
{
}



#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"K3655";
}
- (BOOL) useExtClock
{
    return useExtClock;
}

- (void) setUseExtClock:(BOOL)aUseExtClock
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseExtClock:useExtClock];
    
    useExtClock = aUseExtClock;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORK3655UseExtClockChanged object:self];
}

- (int) pulseNumberToSet
{
    return pulseNumberToSet;
}

- (void) setPulseNumberToSet:(int)aPulseNumberToSet
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseNumberToSet:pulseNumberToSet];
    
	if(aPulseNumberToSet<0)aPulseNumberToSet = 0;
	else if(aPulseNumberToSet>7)aPulseNumberToSet = 0;
	
    pulseNumberToSet = aPulseNumberToSet;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORK3655PulseNumberToSetChanged object:self];
}

- (int) pulseNumberToClear
{
    return pulseNumberToClear;
}

- (void) setPulseNumberToClear:(int)aPulseNumberToClear
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseNumberToClear:pulseNumberToClear];
    
	if(aPulseNumberToClear<0)aPulseNumberToClear = 0;
	else if(aPulseNumberToClear>7)aPulseNumberToClear = 0;
	
    pulseNumberToClear = aPulseNumberToClear;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORK3655PulseNumberToClearChanged object:self];
}

- (int) clockFreq
{
    return clockFreq;
}

- (void) setClockFreq:(int)aClockFreq
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockFreq:clockFreq];

	if(aClockFreq == 0)aClockFreq = 1;
    if(aClockFreq > 1000000)aClockFreq = 1000000;
	
	int roundedClkFreq = pow(10.,(double)(round(log10((double) aClockFreq))));
    clockFreq = roundedClkFreq;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORK3655ClockFreqChanged object:self];
}

- (int) numChansToUse
{
    return numChansToUse;
}

- (void) setNumChansToUse:(int)aNumChansToUse
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNumChansToUse:numChansToUse];
    
	if(aNumChansToUse<1)aNumChansToUse = 1;
	else if(aNumChansToUse>8)aNumChansToUse = 8;
    numChansToUse = aNumChansToUse;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORK3655NumChansToUseChanged object:self];
}

- (BOOL) inhibitEnabled
{
	return inhibitEnabled;
}
- (void) setInhibitEnabled:(BOOL)aState;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInhibitEnabled:inhibitEnabled];
    
    inhibitEnabled = aState;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORK3655InhibitEnabledChanged object:self];
}

- (BOOL) continous
{
    return continous;
}

- (void) setContinous:(BOOL)aContinous
{
    [[[self undoManager] prepareWithInvocationTarget:self] setContinous:continous];
    
    continous = aContinous;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORK3655ContinousChanged object:self];
}

- (NSMutableArray*) setPoints
{
    return setPoints;
}

- (void) setSetPoints:(NSMutableArray*)aSetPoints
{
    [aSetPoints retain];
    [setPoints release];
    setPoints = aSetPoints;

    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORK3655SetPointsChangedNotification
						  object:self];

}

- (void) setSetPoint:(unsigned short) aChan withValue:(unsigned short) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSetPoint:aChan withValue:[self setPoint:aChan]];
	[setPoints replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORK3655Chan];
	
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORK3655SetPointChangedNotification
						  object:self
						userInfo: userInfo];
	
}

-(unsigned short) setPoint:(unsigned short) aChan
{
    return [[setPoints objectAtIndex:aChan] unsignedShortValue];
}

#pragma mark ¥¥¥Hardware Test functions
- (void) initBoard
{

	@try {
		
		int i;
		for(i=0;i<8;i++){
			unsigned short aSetPoint = [[setPoints objectAtIndex:i] unsignedShortValue];
			[[self adapter] camacShortNAF:[self stationNumber] a:i f:16 data:&aSetPoint];
		}
		
		//cycle control reg
		unsigned short freq;
		if(useExtClock) freq = 7;
		else freq = log10((double)clockFreq);
		unsigned short controlValue = (((unsigned short)continous & 0x1) << 6) |
									  (((numChansToUse-1) & 0x7) << 3)	  |
									  (freq & 0x7);
		[[self adapter] camacShortNAF:[self stationNumber] a:0 f:17 data:&controlValue];
		
		//Inhibit Control reg
		unsigned short regValue = ((pulseNumberToClear & 0x7) << 3) |
								  (pulseNumberToSet & 0x7);
		[[self adapter] camacShortNAF:[self stationNumber] a:9 f:17 data:&regValue];


		
		
		if(inhibitEnabled){
			[[self adapter] camacShortNAF:[self stationNumber] a:9 f:26];	//enables the ability to assert inhibit
		}
		else {
			[[self adapter] camacShortNAF:[self stationNumber] a:9 f:24];	//disable the ability to assert inhibit
		}
		//clear LAM
		[[self adapter] camacShortNAF:[self stationNumber] a:12 f:11];
		
		//executes start of counting cycle (clears and enables counter)
		[[self adapter] camacShortNAF:[self stationNumber] a:0 f:25];

	}
@catch(NSException* localException) {
		NSLogError(@"Init Error",@"K3655",[NSString stringWithFormat:@"Station %d",[self stationNumber]],nil);
        [localException raise];
}

}

- (void) readSetPoints
{
	@try {
		int i;
		unsigned short value;
		NSLog(@"Set Points for K3655 station %d:\n",[self stationNumber]);
		for(i=0;i<8;i++){
			[[self adapter] camacShortNAF:[self stationNumber] a:i f:0 data:&value];
			NSLog(@"%d: %d\n",[self stationNumber],value);
		}
	}
@catch(NSException* localException) {
		NSLog(@"Error during read\n");
	}
}

- (void) testLAM;
{
    unsigned short status = [[self adapter] camacShortNAF:[self stationNumber] a:15 f:8 data:nil];
    NSLog(@"LAM %@ set\n",isQbitSet(status)?@"is":@"is not");
}

- (void) clearLAM
{
    [[self adapter] camacShortNAF:[self stationNumber] a:12 f:11 data:nil];
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setInhibitEnabled:	[decoder decodeBoolForKey:	@"ORK3655InhibitEnabled"]];
    [self setUseExtClock:		[decoder decodeBoolForKey:	@"ORK3655UseExtClock"]];
    [self setPulseNumberToSet:	[decoder decodeIntForKey:	@"ORK3655PulseNumberToSet"]];
    [self setPulseNumberToClear:[decoder decodeIntForKey:	@"ORK3655PulseNumberToClear"]];
    [self setClockFreq:			[decoder decodeIntForKey:	@"ORK3655ClockFreq"]];
    [self setNumChansToUse:		[decoder decodeIntForKey:	@"ORK3655NumChansToUse"]];
    [self setContinous:			[decoder decodeBoolForKey:	@"ORK3655Continous"]];
    [self setSetPoints:			[decoder decodeObjectForKey:@"ORK3655SetPoints"]];
    [[self undoManager] enableUndoRegistration];
	
	if(!setPoints){
		[self setSetPoints:[NSMutableArray array]];
		int i;
		for(i=0;i<8;i++){
			[setPoints addObject:[NSNumber numberWithInt:1]];
		}
	}
	
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:useExtClock			forKey:@"ORK3655UseExtClock"];
    [encoder encodeBool:inhibitEnabled		forKey:@"ORK3655InhibitEnabled"];
    [encoder encodeInt:pulseNumberToSet		forKey:@"ORK3655PulseNumberToSet"];
    [encoder encodeInt:pulseNumberToClear	forKey:@"ORK3655PulseNumberToClear"];
    [encoder encodeInt:clockFreq			forKey:@"ORK3655ClockFreq"];
    [encoder encodeInt:numChansToUse		forKey:@"ORK3655NumChansToUse"];
    [encoder encodeBool:continous			forKey:@"ORK3655Continous"];
    [encoder encodeObject:setPoints			forKey:@"ORK3655SetPoints"];
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithBool:inhibitEnabled] forKey:@"InhibitEnabled"];
    [objDictionary setObject:[NSNumber numberWithBool:continous] forKey:@"Continous"];
    [objDictionary setObject:[NSNumber numberWithBool:useExtClock] forKey:@"UseExtClock"];
    [objDictionary setObject:[NSNumber numberWithUnsignedShort:numChansToUse] forKey:@"NumChansToUse"];
    [objDictionary setObject:[NSNumber numberWithUnsignedShort:clockFreq] forKey:@"ClockFreq"];
    [objDictionary setObject:[NSNumber numberWithUnsignedShort:pulseNumberToClear] forKey:@"PulseNumberToClear"];
    [objDictionary setObject:[NSNumber numberWithUnsignedShort:pulseNumberToSet] forKey:@"PulseNumberToSet"];
    [objDictionary setObject:setPoints forKey:@"setPoints"];
                
	return objDictionary;
}


#pragma mark ¥¥¥HW Wizard

- (int) numberOfChannels
{
    return 8;
}
- (BOOL) hasParmetersToRamp
{
	return YES;
}
- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Set Point"];
    [p setFormat:@"##0" upperLimit:65535 lowerLimit:1 stepSize:1 units:@""];
    [p setSetMethod:@selector(setSetPoint:withValue:) getMethod:@selector(setPoint:)];
    [p setActionMask:kAction_Set_Mask|kAction_Restore_Mask];
    [a addObject:p];
	
    [a addObject:[ORHWWizParam boolParamWithName:@"Continous"  setter:@selector(setContinous:)  getter:@selector(continous)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"Use Ext Clk"  setter:@selector(setUseExtClock:)  getter:@selector(useExtClock)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"Inhibit Enabled"  setter:@selector(setInhibitEnabled:)  getter:@selector(inhibitEnabled)]];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Num Chans"];
    [p setFormat:@"##0" upperLimit:8 lowerLimit:1 stepSize:1 units:@""];
    [p setSetMethod:@selector(setNumChansToUse:) getMethod:@selector(numChansToUse)];
    [a addObject:p];


    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Freq"];
    [p setFormat:@"##0" upperLimit:1000000 lowerLimit:1 stepSize:1 units:@"Hz"];
    [p setSetMethod:@selector(setClockFreq:) getMethod:@selector(clockFreq)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pulse # to Clr"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPulseNumberToClear:) getMethod:@selector(pulseNumberToClear)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pulse # to Set"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPulseNumberToSet:) getMethod:@selector(pulseNumberToSet)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
	[p setSetMethodSelector:@selector(initBoard)];
	[a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORCamacCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"ORK3655Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORK3655Model"]];
    return a;
	
}
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"SetPoint"])return [[cardDictionary objectForKey:@"setPoints"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"InhibitEnabled"]) return [cardDictionary objectForKey:@"inhibitEnabled"];
    else if([param isEqualToString:@"Continous"]) return [cardDictionary objectForKey:@"continous"];
    else if([param isEqualToString:@"Use Ext Clk"]) return [cardDictionary objectForKey:@"useExtClock"];
    else if([param isEqualToString:@"Num Chans"]) return [cardDictionary objectForKey:@"numChansToUse"];
    else if([param isEqualToString:@"Clock Freq"]) return [cardDictionary objectForKey:@"clockFreq"];
    else if([param isEqualToString:@"Pulse # to Clr"]) return [cardDictionary objectForKey:@"pulseNumberToClear"];
    else if([param isEqualToString:@"Pulse # to Set"]) return [cardDictionary objectForKey:@"pulseNumberToSet"];

	else return nil;
}


@end
