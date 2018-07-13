//
//  NcdThresholdTask.m
//  Orca
//
//  Created by Mark Howe on July 1, 2004.
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


#import "NcdThresholdTask.h"
#import "ORPulserDistribModel.h"
#import "NcdModel.h"
#import "ORHPPulserModel.h"

#import "NcdPDSStepTask.h"

@interface NcdThresholdTask (private)
- (BOOL)  _doWork;
@end

@implementation NcdThresholdTask
+ (void) initialize
{
    [NcdThresholdTask setVersion:1]; 
}

-(id)	init
{
    if( self = [super init] ){
#if !defined(MAC_OS_X_VERSION_10_9)
        [NSBundle loadNibNamed:@"NcdThresholdTask" owner:self];
#else
        [[NSBundle mainBundle] loadNibNamed:@"NcdThresholdTask" owner:self topLevelObjects:&ncdThresholdTaskObjects];
#endif
        
        [ncdThresholdTaskObjects retain];

        [self setTitle:@"Threshold Check"];
        [self setDefaults];
    }
    return self;
}

- (void) dealloc
{
    [ncdThresholdTaskObjects release];
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

- (int) selectedWaveform
{
    return selectedWaveform;
}

- (void) setSelectedWaveform:(int)newSelectedWaveform
{
    [[[self undoManager] prepareWithInvocationTarget: self] setSelectedWaveform: selectedWaveform];
    selectedWaveform = newSelectedWaveform;
    
    [selectionPopUpButton selectItemAtIndex:selectedWaveform];
    
}

- (int) doAllChannels
{
    return doAllChannels;
}

- (void) setDoAllChannels:(int)state
{
    [[[self undoManager] prepareWithInvocationTarget: self] setDoAllChannels: doAllChannels];
    doAllChannels = state;
    [doAllButton setState:doAllChannels];
}

- (int)timeOnOneChannel 
{
    return timeOnOneChannel;
}

- (void)setTimeOnOneChannel:(int)aTimeOnOneChannel {
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeOnOneChannel:timeOnOneChannel];
    timeOnOneChannel = aTimeOnOneChannel;
    if(timeOnOneChannel<1)timeOnOneChannel=1;
    [timeField setIntValue:timeOnOneChannel];
    [timeStepper setIntValue:timeOnOneChannel];
}

- (float)startAmplitude {
    
    return startAmplitude;
}

- (void)setStartAmplitude:(float)anAmplitude 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartAmplitude:startAmplitude];
    startAmplitude = anAmplitude;
    [startAmplitudeField setFloatValue:startAmplitude];
    [startAmplitudeStepper setFloatValue:startAmplitude];
}

- (float)endAmplitude 
{
    return endAmplitude;
}

- (void)setEndAmplitude:(float)aendAmplitude 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEndAmplitude:endAmplitude];
    endAmplitude = aendAmplitude;
    [endAmplitudeField setFloatValue:endAmplitude];
    [endAmplitudeStepper setFloatValue:endAmplitude];
}


- (float)burstRate 
{
    return burstRate;
}

- (void)setBurstRate:(float)aBurstRate 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBurstRate:burstRate];
    burstRate = aBurstRate;
    [burstRateField setFloatValue:burstRate];
    [burstRateStepper setFloatValue:burstRate];
}

- (float)width
{
    return width;
}

- (void)setWidth:(CGFloat)aWidth 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWidth:width];
    width = aWidth;
    [widthField setFloatValue:width];
    [widthStepper setFloatValue:width];
}

- (int)numOfValues 
{
    return numOfValues;
}


- (void)setNumOfValues:(int)aNumOfValues 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNumOfValues:numOfValues];
    numOfValues = aNumOfValues;
    [numValuesField setIntValue:numOfValues];
    [numValuesStepper setIntValue:numOfValues];
}




#pragma mark ¥¥¥Actions

- (IBAction) doAllChannelsAction:(id)sender
{
    [self setDoAllChannels:[sender state]];
}

-(IBAction) selectWaveformAction:(id)sender;
{
    if([sender indexOfSelectedItem] != selectedWaveform){ 	
        [[self undoManager] setActionName: @"Selected Waveform"];
        [self setSelectedWaveform:(int)[selectionPopUpButton indexOfSelectedItem]];
    }
}


- (IBAction) timeAction:(id)sender
{
    [self setTimeOnOneChannel:[sender intValue]];
}

- (IBAction) startAmplitudeAction:(id)sender
{
    [self setStartAmplitude:[sender floatValue]];
}
- (IBAction) endAmplitudeAction:(id)sender
{
    [self setEndAmplitude:[sender floatValue]];
}
- (IBAction) burstRateAction:(id)sender
{
    [self setBurstRate:[sender floatValue]];
}
- (IBAction) widthAction:(id)sender
{
    [self setWidth:[sender floatValue]];
}
- (IBAction) numOfValuesAction:(id)sender
{
    [self setNumOfValues:[sender intValue]];
}


#pragma mark ¥¥¥Task Methods
- (void) prepare
{
    [super prepare];
    lastTime = [[NSDate date] retain];
    currentStep = 1;
    NSArray* objects = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORPulserDistribModel")];
    if([objects count]){
        @try {
            thePDSModel = [objects objectAtIndex:0];
            pdsMemento = [[thePDSModel memento] retain];  //save the old values
            
            if(doAllChannels){
                [thePDSModel setPatternArray:[NSMutableArray arrayWithObjects:
											  [NSNumber numberWithLong:0xffff],
											  [NSNumber numberWithLong:0xffff],
											  [NSNumber numberWithLong:0xffff],
											  [NSNumber numberWithLong:0xffff],
											  nil]];
            }
            else {
                if([delegate respondsToSelector:@selector(dependentTask:)]){
                    stepTask = [delegate dependentTask:self];
                    [thePDSModel setPatternArray:[stepTask patternArray]];
                }
            }
            
            [thePDSModel loadHardware:[thePDSModel patternArray]];
            [thePDSModel setDisableForPulser:YES];
            
        }
		@catch(NSException* localException) {
            NSLog(@"\n");
            NSLogColor([NSColor redColor],@"NCD Threshold Task: Exception thrown! %@\n",localException);
            NSLogColor([NSColor redColor],@"NCD Threshold Task: couldn't set up PDS!\n");
            //abort = YES;
        }
		if(!numOfValues)[self setNumOfValues:1];
    }
    
    objects = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORHPPulserModel")];
    if([objects count]){
        thePulserModel = [objects objectAtIndex:0];
        pulserMemento = [[thePulserModel memento] retain];  //save the old values
        [thePulserModel setSelectedWaveform:selectedWaveform];
        //[thePulserModel setSelectedWaveform:kSingleSinWave1];
        [thePulserModel setVoltage:startAmplitude];
        [thePulserModel setBurstRate:burstRate];
        [thePulserModel setTotalWidth:width];
        [thePulserModel setTriggerSource:kInternalTrigger];
        [thePulserModel downloadWaveform];
        [delegate shipPulserRecord:thePulserModel];
        [self setMessage:@"Set up Pulser"];
    }
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


- (BOOL)  _doWork
{
    if(!thePDSModel){
        NSLogColor([NSColor redColor],@"NCD Threshold Task: No PDS object in config, so nothing to do!\n");
        [self finishUp];
        return NO;
    }
    if(!thePulserModel){
        NSLogColor([NSColor redColor],@"NCD Threshold Task: No Pulser object in config, so nothing to do!\n");
        NSLogColor([NSColor redColor],@"NCD Threshold Task: Start of <%@> aborted!\n",[self title]);
        [self finishUp];
        return NO; //can not run if no pulser object in config
    }
    
    //must wait for the pulser to load waveform
    if([thePulserModel loading])return YES;
    NSDate* now = [NSDate date];
    if([now timeIntervalSinceDate:lastTime] >= [self timeOnOneChannel]){
        [lastTime release];
        lastTime = [now retain];
        [self setMessage:[NSString stringWithFormat:@" Working (%d)",currentStep+1]];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORTaskDidStepNotification object:self];
        float newAmplitude = startAmplitude - currentStep*fabs(startAmplitude-endAmplitude)/numOfValues;
        if(newAmplitude<endAmplitude)return NO;
        else {
            [thePulserModel setVoltage:newAmplitude];
			
			//disable PDS while loading pulser values 06/16/05
			[thePDSModel loadHardware:[NSMutableArray arrayWithObjects:
									   [NSNumber numberWithLong:0x0],
									   [NSNumber numberWithLong:0x0],
									   [NSNumber numberWithLong:0x0],
									   [NSNumber numberWithLong:0x0],
									   nil]];
			[thePulserModel outputWaveformParams];
            [thePDSModel loadHardware:[thePDSModel patternArray]];
			
            [delegate shipPulserRecord:thePulserModel];
            currentStep++;
			if(currentStep > numOfValues){
                [self finishUp];
                return NO;
            }
        }
    }
    
    return YES;
}

- (void) finishUp
{    
	[super finishUp];
    [lastTime release];
    lastTime = nil;
    
    if(thePulserModel){
		@try {
			[thePulserModel restoreFromMemento:pulserMemento];
		}
		@catch(NSException* localException) {
        }
        [pulserMemento release];
        pulserMemento = nil;
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
    [self setMessage:@"Idle"];
}

- (void) cleanUp
{    
    //we don't retain these, but we are done with them.
    thePulserModel = nil; 
    thePDSModel = nil;
    [self setMessage:@"Idle"];
}

- (NSString*) description
{
    NSString* s = @"\n";
    s = [s stringByAppendingFormat:@"Time/chan: %d  Waveform: %d\n",timeOnOneChannel,selectedWaveform];
    s = [s stringByAppendingFormat:@"Amp1: %.2f Amp2 : %.2f Num: %d\n",startAmplitude,endAmplitude,numOfValues];
    s = [s stringByAppendingFormat:@"Rate: %.2f Width: %.2f\n",burstRate,width];
    return s;
}


- (void) setDefaults
{
    [[self undoManager] disableUndoRegistration];
    [self setTimeOnOneChannel:5];    
    [self setStartAmplitude:250];
    [self setEndAmplitude:5];
    [self setBurstRate:10];
    [self setWidth:8.2];
    [self setNumOfValues:10];
    [[self undoManager] enableUndoRegistration];    
}


- (void) enableGUI:(BOOL)state
{
    [timeField setEnabled:state];
    [timeStepper setEnabled:state];
    [startAmplitudeField setEnabled:state];
    [startAmplitudeStepper setEnabled:state];
    [endAmplitudeField setEnabled:state];
    [endAmplitudeStepper setEnabled:state];
    [burstRateField setEnabled:state];
    [burstRateStepper setEnabled:state];
    [widthField setEnabled:state];
    [widthStepper setEnabled:state];
    [numValuesField setEnabled:state];
    [numValuesStepper setEnabled:state];
    [selectionPopUpButton setEnabled:state];
    [doAllButton setEnabled:state];
}

#pragma mark ¥¥¥Archival
static NSString* NcdThresholdTaskTime       = @"NcdThresholdTaskTime";
static NSString* NcdThresholdStartAmplitude = @"NcdThresholdStartAmplitude";;
static NSString* NcdThresholdEndAmplitude   = @"NcdThresholdEndAmplitude";;
static NSString* NcdThresholdBurstRate      = @"NcdThresholdBurstRate";;
static NSString* NcdThresholdWidth          = @"NcdThresholdWidth";;
static NSString* NcdThresholdNumOfValues    = @"NcdThresholdNumOfValues";;
static NSString* NcdThresholdSelectedWaveform = @"NcdThresholdSelectedWaveform";
static NSString* NcdThresholdDoAll          = @"NcdThresholdDoAll";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"NcdThresholdTask" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"NcdThresholdTask" owner:self topLevelObjects:&ncdThresholdTaskObjects];
#endif
    
    [ncdThresholdTaskObjects retain];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setDefaults];
    
    [self setTimeOnOneChannel:[decoder decodeIntForKey:NcdThresholdTaskTime]];
    [self setStartAmplitude:[decoder decodeFloatForKey:NcdThresholdStartAmplitude]];
    [self setEndAmplitude:[decoder decodeFloatForKey:NcdThresholdEndAmplitude]];
    [self setBurstRate:[decoder decodeFloatForKey:NcdThresholdBurstRate]];
    [self setWidth:[decoder decodeFloatForKey:NcdThresholdWidth]];
    [self setNumOfValues:[decoder decodeIntForKey:NcdThresholdNumOfValues]];
    [self setDoAllChannels:[decoder decodeIntForKey:NcdThresholdDoAll]];
    if([decoder versionForClassName:@"NcdThresholdTask"] < 1){
        [thePulserModel setSelectedWaveform:kSingleSinWave1];
    }
    else {
        [self setSelectedWaveform:[decoder decodeIntForKey:NcdThresholdSelectedWaveform]];
    }
    
    [[self undoManager] enableUndoRegistration];    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:timeOnOneChannel forKey:NcdThresholdTaskTime];
    [encoder encodeFloat:startAmplitude forKey:NcdThresholdStartAmplitude];
    [encoder encodeFloat:endAmplitude forKey:NcdThresholdEndAmplitude];
    [encoder encodeFloat:burstRate forKey:NcdThresholdBurstRate];
    [encoder encodeFloat:width forKey:NcdThresholdWidth];
    [encoder encodeInteger:numOfValues forKey:NcdThresholdNumOfValues];
    [encoder encodeInteger:selectedWaveform forKey:NcdThresholdSelectedWaveform];
    [encoder encodeInteger:doAllChannels forKey:NcdThresholdDoAll];
}
@end
