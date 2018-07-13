//
//  NcdPulseChannelsTask.m
//  Orca
//
//  Created by Mark Howe on June 5, 2006.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "NcdPulseChannelsTask.h"
#import "ORPulserDistribModel.h"
#import "NcdModel.h"
#import "NcdDetector.h"
#import "NcdTube.h"
#import "ORHPPulserModel.h"
#import "ORShaperModel.h"
#import "StatusLog.h"

enum {
	kTimePerChannelIndex,
	kVoltageIndex,
	kWidthIndex,
	kNumItems
};

@interface NcdPulseChannelsTask (private)
- (BOOL) _doWork;
- (BOOL) tubeIsOnline:(id)currentTube cards:(id)shaperCards;
@end

@implementation NcdPulseChannelsTask
-(id)	init
{
    if( self = [super init] ){
#if !defined(MAC_OS_X_VERSION_10_9)
        [NSBundle loadNibNamed:@"NcdPulseChannelsTask" owner:self];
#else
        [[NSBundle mainBundle] loadNibNamed:@"NcdPulseChannelsTask" owner:self topLevelObjects:&ncdPulseChannelsTaskObjects];
#endif
        
        [ncdPulseChannelsTaskObjects retain];

        [self setTitle:@"NRE TASK"];
        [self setDefaults];
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self addExtraPanel:extraView];
}


- (BOOL) okToRun
{
    return [[ORGlobal sharedGlobal] runInProgress];
}

#pragma mark ¥¥¥Accessors
- (void) setPulseOneOnly:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseOneOnly:pulseOneOnly];
	pulseOneOnly = state;
	[pulseOneOnlyButton setState:pulseOneOnly];
}

- (void) setCardToPulse:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCardToPulse:cardToPulse];
	cardToPulse = state;
	[cardToPulseField setIntValue:cardToPulse];
}

- (void) setChannelToPulse:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannelToPulse:channelToPulse];
	channelToPulse = state;
	[channelToPulseField setIntValue:channelToPulse];
}

- (void) setAutoStart:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoStart:autoStart];
	autoStart = state;
	[autoStartButton setState:autoStart];
}

- (BOOL) autoStart
{
	return autoStart;
}

- (void) setAutoStartForSourceRun:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoStartForSourceRun:autoStartForSourceRun];
	autoStartForSourceRun = state;
	[autoStartForSourceRunButton setState:autoStartForSourceRun];
}

- (BOOL) autoStartForSourceRun
{
	return autoStartForSourceRun;
}


- (void) setUseNeutrinoRun:(BOOL)state
{
	useNeutrinoRun = state;
}

- (BOOL) useNeutrinoRun
{
	return useNeutrinoRun;
}

- (float) neutrinoParam:(int)index 
{
    return neutrinoParam[index];
}

- (void)setNeutrinoParam:(int)index value:(float)aValue 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNeutrinoParam:index value:neutrinoParam[index]];
    neutrinoParam[index] = aValue;
    [[neutrinoTextMatrix cellWithTag:index] setFloatValue:aValue];
    [[neutrinoStepperMatrix cellWithTag:index] setFloatValue:aValue];
}

- (float) sourceParam:(int)index 
{
    return sourceParam[index];
}

- (void)setSourceParam:(int)index value:(float)aValue 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSourceParam:index value:sourceParam[index]];
    sourceParam[index] = aValue;
    [[sourceTextMatrix cellWithTag:index] setFloatValue:aValue];
    [[sourceStepperMatrix cellWithTag:index] setFloatValue:aValue];
}

- (int) neutrinoWaveform
{
    return neutrinoWaveform;
}

- (void) setNeutrinoWaveform:(int)aWaveform
{
    [[[self undoManager] prepareWithInvocationTarget: self] setNeutrinoWaveform: neutrinoWaveform];
    neutrinoWaveform = aWaveform;
    
    [neutrinoWaveformPopUpButton selectItemAtIndex:neutrinoWaveform];
}

- (int) sourceWaveform
{
    return sourceWaveform;
}

- (void) setSourceWaveform:(int)aWaveform
{
    [[[self undoManager] prepareWithInvocationTarget: self] setSourceWaveform: sourceWaveform];
    sourceWaveform = aWaveform;
    
    [sourceWaveformPopUpButton selectItemAtIndex:sourceWaveform];
}


#pragma mark ¥¥¥Actions
- (void) pulseOneOnlyAction:(id)sender
{
	[self setPulseOneOnly:[sender intValue]];
	[self enableGUI:YES];
}

- (void) channelToPulseAction:(id)sender
{
	[self setChannelToPulse:[sender intValue]];
}
- (void) cardToPulseAction:(id)sender
{
	[self setCardToPulse:[sender intValue]];
}

- (void) neutrinoMatrixAction:(id)sender
{
	[self setNeutrinoParam:(int)[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];
}

- (void) sourceMatrixAction:(id)sender
{
	[self setSourceParam:(int)[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];
}

- (IBAction) neutrinoWaveformAction:(id)sender;
{
    if([sender indexOfSelectedItem] != neutrinoWaveform){ 	
        [[self undoManager] setActionName: @"Selected Neutrino Waveform"];
        [self setNeutrinoWaveform:(int)[neutrinoWaveformPopUpButton indexOfSelectedItem]];
    }
}

- (IBAction) sourceWaveformAction:(id)sender;
{
    if([sender indexOfSelectedItem] != sourceWaveform){ 	
        [[self undoManager] setActionName: @"Selected Source Waveform"];
        [self setSourceWaveform:(int)[sourceWaveformPopUpButton indexOfSelectedItem]];
    }
}

- (IBAction) autoStartAction:(id)sender
{
	[self setAutoStart:[sender state]]; 
}

- (IBAction) autoStartForSourceRunAction:(id)sender
{
	[self setAutoStartForSourceRun:[sender state]]; 
}

- (void) updateWindow
{
    [neutrinoWaveformPopUpButton selectItemAtIndex:neutrinoWaveform];
    [sourceWaveformPopUpButton selectItemAtIndex:sourceWaveform];
    
	int i;
	for(i=0;i<kNumItems;i++){
		[[neutrinoTextMatrix cellWithTag:i] setFloatValue:neutrinoParam[i]];
		[[sourceTextMatrix cellWithTag:i] setFloatValue:sourceParam[i]];
		[[neutrinoStepperMatrix cellWithTag:i] setFloatValue:neutrinoParam[i]];
		[[sourceStepperMatrix cellWithTag:i] setFloatValue:sourceParam[i]];
	}
	
}

- (void) enableGUI:(BOOL)state
{    
    [neutrinoTextMatrix setEnabled:state];
    [sourceTextMatrix setEnabled:state];
    [neutrinoStepperMatrix setEnabled:state];
    [sourceStepperMatrix setEnabled:state];
    [neutrinoWaveformPopUpButton setEnabled:state];
    [sourceWaveformPopUpButton setEnabled:state];
    [autoStartButton setEnabled:state];
    [autoStartForSourceRunButton setEnabled:state];
	[pulseOneOnlyButton setEnabled:state];
	[cardToPulseField setEnabled:state && pulseOneOnly];
	[channelToPulseField setEnabled:state && pulseOneOnly];
}


#pragma mark ¥¥¥Task Methods
- (void) prepare
{
    [super prepare];
    [[self undoManager] disableUndoRegistration];
    
	
    NSArray* objects = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORPulserDistribModel")];
    if([objects count]){
        thePDSModel = [objects objectAtIndex:0];
        pdsMemento = [[thePDSModel memento] retain];  //save the old values
        [thePDSModel setDisableForPulser:YES];
		NSMutableArray* zeroArray = [NSMutableArray arrayWithObjects:
									 [NSNumber numberWithLong:0],	//board 0
									 [NSNumber numberWithLong:0],	//board 1
									 [NSNumber numberWithLong:0],	//board 2
									 [NSNumber numberWithLong:0],	//board 3
									 nil];
		
		@try {
			[thePDSModel setPatternArray:zeroArray];
			[thePDSModel loadHardware:zeroArray];
		}
		@catch(NSException* localException) {
		}
		
    }
	
    objects = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORHPPulserModel")];
    if([objects count]){
        thePulserModel = [objects objectAtIndex:0];
        pulserMemento = [[thePulserModel memento] retain];  //save the old values
        
        [self setMessage:@"Set up Pulser"];
		[thePulserModel setLockGUI:YES];
		[thePulserModel resetAndClear];
		if(useNeutrinoRun){
			[thePulserModel setVoltage:neutrinoParam[kVoltageIndex]];
			[thePulserModel setTotalWidth:neutrinoParam[kWidthIndex]];
			[thePulserModel setSelectedWaveform:neutrinoWaveform];
		}
		else {
			[thePulserModel setVoltage:sourceParam[kVoltageIndex]];
			[thePulserModel setTotalWidth:sourceParam[kWidthIndex]];
			[thePulserModel setSelectedWaveform:sourceWaveform];
		}
		[thePulserModel setTriggerSource:kSoftwareTrigger];
		[thePulserModel downloadWaveform];
		[delegate shipPulserRecord:thePulserModel];
		
		//get the online tubes
		tubeIndex = 0;
		lastTime = [[NSDate date] retain];
		onlineTubes       = [[NSMutableArray array] retain];
		NSArray* allTubes = [[[delegate detector] tubes] retain];
		NSArray* shaperCards = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")];
		NSEnumerator* e = [allTubes objectEnumerator];
		id tube;
		while(tube = [e nextObject]){
			if([self tubeIsOnline:tube cards:shaperCards]){
				[onlineTubes addObject:tube];
			}
		}
    }
    else {
        [self hardHaltTask];
    }
    [[self undoManager] enableUndoRegistration];
}


- (BOOL)  doWork
{
    BOOL isThereMoreToDo;
    [[self undoManager] disableUndoRegistration];
    if(doingFinishUpWork){
        isThereMoreToDo = [thePulserModel loading];
    }
    else {
        isThereMoreToDo = [self _doWork];
    }
    [[self undoManager] enableUndoRegistration];
    return isThereMoreToDo;
}


- (void) finishUp
{
    [super finishUp];
	[lastTime release];
	lastTime = nil;
    [self setMessage:@"Idle"];
    if(thePulserModel){
		@try {
			[thePulserModel restoreFromMemento:pulserMemento];
		}
		@catch(NSException* localException) {
        }
        [pulserMemento release];
        pulserMemento = nil;
		[thePulserModel setLockGUI:NO];
    }
    if(thePDSModel){
        @try {
            [thePDSModel restoreFromMemento:pdsMemento];
		}
		@catch(NSException* localException) {
        }
        [pdsMemento release];
        pdsMemento = nil;
    }
	[onlineTubes release];
	onlineTubes = nil;
}

- (void) cleanUp
{
    //we don't retain these, but we are done with them.
    thePulserModel = nil; 
    [self setMessage:@"Idle"];
}

- (NSString*) description
{
	NSString* s = @"\n";
	if(useNeutrinoRun){
		s = [s stringByAppendingFormat:@"Time/chan: %.0f  Waveform: %d\n",neutrinoParam[kTimePerChannelIndex],neutrinoWaveform];
		s = [s stringByAppendingFormat:@"Amp: %.2f Width : %.2f\n",neutrinoParam[kVoltageIndex],neutrinoParam[kWidthIndex]];
	}
	else {
		s = [s stringByAppendingFormat:@"Time/chan: %.0f  Waveform: %d\n",sourceParam[kTimePerChannelIndex],sourceWaveform];
		s = [s stringByAppendingFormat:@"Amp: %.2f Width : %.2f\n",sourceParam[kVoltageIndex],sourceParam[kWidthIndex]];
	}
	
    return s;
}


- (void) setDefaults
{
    [[self undoManager] disableUndoRegistration];
    
	[self setNeutrinoParam:kTimePerChannelIndex value:5];
	[self setNeutrinoParam:kVoltageIndex value:250];
	[self setNeutrinoParam:kWidthIndex value:7.8];
	[self setNeutrinoWaveform:0];
	
	[self setSourceParam:kTimePerChannelIndex value:5];
	[self setSourceParam:kVoltageIndex value:250];
	[self setSourceParam:kWidthIndex value:7.8];
	[self setSourceWaveform:0];
	
    [[self undoManager] enableUndoRegistration];    
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"NcdPulseChannelsTask" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"NcdPulseChannelsTask" owner:self topLevelObjects:&ncdPulseChannelsTaskObjects];
#endif
        
    [ncdPulseChannelsTaskObjects retain];
    
    [[self undoManager] disableUndoRegistration];
	
	int i;
	for(i=0;i<kNumItems;i++){
		[self setNeutrinoParam:i value:[decoder decodeFloatForKey:   [NSString stringWithFormat:@"NcdPulseChannelsNeutrinoParam%d",i]]];    
		[self setSourceParam:i   value:[decoder decodeFloatForKey:    [NSString stringWithFormat:@"NcdPulseChannelsSourceParam%d",i]]];    
	}
	if(neutrinoParam[0] == 0)[self setDefaults];
	
	[self setNeutrinoWaveform:[decoder decodeIntForKey:	@"neutrinoWaveform"]];
	[self setSourceWaveform:[decoder decodeIntForKey:	@"sourceWaveform"]];
	[self setAutoStart:[decoder decodeIntegerForKey:		@"autoStart"]];
	[self setAutoStartForSourceRun:[decoder decodeIntegerForKey:@"autoStartForSourceRun"]];
	[self setPulseOneOnly:[decoder decodeIntegerForKey:		@"pulseOneOnly"]];
	[self setCardToPulse:[decoder decodeIntegerForKey:		@"cardToPulse"]];
	[self setChannelToPulse:[decoder decodeIntegerForKey:	@"channelToPulse"]];
	
    [[self undoManager] enableUndoRegistration];    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
    int i;
	for(i=0;i<kNumItems;i++){
        [encoder encodeFloat:neutrinoParam[i] forKey:  [NSString stringWithFormat:@"NcdPulseChannelsNeutrinoParam%d",i]];    
        [encoder encodeFloat:sourceParam[i] forKey:  [NSString stringWithFormat:@"NcdPulseChannelsSourceParam%d",i]];    
    }
	
	[encoder encodeInteger:neutrinoWaveform forKey: @"neutrinoWaveform"];
	[encoder encodeInteger:sourceWaveform forKey:	@"sourceWaveform"];
	[encoder encodeInteger:autoStart forKey:		@"autoStart"];
	[encoder encodeInteger:autoStartForSourceRun forKey:  @"autoStartForSourceRun"];
	[encoder encodeInteger:pulseOneOnly forKey:		@"pulseOneOnly"];
	[encoder encodeInteger:cardToPulse forKey:		@"cardToPulse"];
	[encoder encodeInteger:channelToPulse forKey:	@"channelToPulse"];
    
    [self updateWindow];
    
}
@end

@implementation NcdPulseChannelsTask (private)

- (BOOL) _doWork
{
    if(!thePulserModel){
        NSLogColor([NSColor redColor],@"NCD Pulse Channel Task:No Pulser object in config, so nothing to do!\n");
        NSLogColor([NSColor redColor],@"NCD Pulse Channel Task:Start of <%@> aborted!\n",[self title]);
        [self hardHaltTask];
        [self finishUp];
        return NO; //can not run if no pulser object in config
    }
    if(!thePDSModel){
        NSLogColor([NSColor redColor],@"NCD Pulse Channel Task:No PDS object in config, so nothing to do!\n");
        NSLogColor([NSColor redColor],@"NCD Pulse Channel Task:Start of <%@> aborted!\n",[self title]);
        [self hardHaltTask];
        [self finishUp];
        return NO; //can not run if no pulser object in config
    }
    
	if(![onlineTubes count]){
        NSLogColor([NSColor redColor],@"NCD Pulse Channel Task:No online channels, so nothing to do!\n");
        NSLogColor([NSColor redColor],@"NCD Pulse Channel Task:Start of <%@> aborted!\n",[self title]);
        [self hardHaltTask];
        [self finishUp];
		return NO;
	}
    //must wait for the pulser to load waveform
	if(![thePulserModel loading]){
		NSDate* now = [NSDate date];
		NSTimeInterval delta = [now timeIntervalSinceDate:lastTime];
		if(delta  >= (useNeutrinoRun ? neutrinoParam[kTimePerChannelIndex] : sourceParam[kTimePerChannelIndex])){
			[lastTime release];
			lastTime = [now retain];
			NcdTube* currentTube = [onlineTubes objectAtIndex:tubeIndex];
			int pdsBoard = [[currentTube objectForKey:@"kPdsBoardNum"] intValue];
			int pdsChan  = [[currentTube objectForKey:@"kPdsChan"] intValue];
			
			NSMutableArray* patternArray = [NSMutableArray arrayWithObjects:
											[NSNumber numberWithLong:(pdsBoard==0)?(0x01<<pdsChan):0],	//board 0
											[NSNumber numberWithLong:(pdsBoard==1)?(0x01<<pdsChan):0],	//board 1
											[NSNumber numberWithLong:(pdsBoard==2)?(0x01<<pdsChan):0],	//board 2
											[NSNumber numberWithLong:(pdsBoard==3)?(0x01<<pdsChan):0],	//board 3
											nil];
			
			[self setMessage:[NSString stringWithFormat:@"Pulsing: %@",[currentTube objectForKey:@"kLabel"]]];
			@try {
				[thePDSModel setPatternArray:patternArray];
				[thePDSModel loadHardware:patternArray];
			}
			@catch(NSException* localException) {
			}
			@try {
				[thePulserModel trigger];
			}
			@catch(NSException* localException) {
				NSLogError(@"Pulser Trigger Error",@"Pulse Channels Task",nil);
			}
			tubeIndex = (tubeIndex + 1)%[onlineTubes count];
		}
    }
    return YES;
}

- (BOOL) tubeIsOnline:(id)currentTube cards:(id)shaperCards
{
	short slot	  = [[currentTube objectForKey:@"kAdcSlot"] intValue];
	short channel = [[currentTube objectForKey:@"kAdcChannel"] intValue];
	if(pulseOneOnly){
		if(slot == cardToPulse && channel == channelToPulse){
			int i;
			for(i=0;i<[shaperCards count];i++){
				id card = [shaperCards objectAtIndex:i];
				if([card slot] == slot){
					if([card onlineMaskBit:channel])return YES;
					else return NO;
				}
			}
		}
		else return NO;
	}
	else {
		int i;
		for(i=0;i<[shaperCards count];i++){
			id card = [shaperCards objectAtIndex:i];
			if([card slot] == slot){
				if([card onlineMaskBit:channel])return YES;
				else return NO;
			}
		}
	}
	return NO;
}

@end
