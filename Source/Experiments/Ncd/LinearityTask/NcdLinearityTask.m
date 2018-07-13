//
//  NcdLinearityTask.m
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


#import "NcdLinearityTask.h"
#import "ORPulserDistribModel.h"
#import "NcdModel.h"
#import "ORHPPulserModel.h"
#import "NcdPDSStepTask.h"

@interface NcdLinearityTask (private)

- (void) setPulserAmp:(float)amp width:(float)width;
- (BOOL) advanceStep;
- (BOOL) setPulserFromFileLine:(int)aLineNumber;
- (BOOL) _doWork;
@end

@implementation NcdLinearityTask
-(id)	init
{
    if( self = [super init] ){
#if !defined(MAC_OS_X_VERSION_10_9)
        [NSBundle loadNibNamed:@"NcdLinearityTask" owner:self];
#else
        [[NSBundle mainBundle] loadNibNamed:@"NcdLinearityTask" owner:self topLevelObjects:&ncdLinearityTaskObjects];
#endif
        [ncdLinearityTaskObjects retain];

        [self setTitle:@"Gain & Linearity"];
        [self setDefaults];
    }
    return self;
}

- (void) dealloc
{
    [fileLines release];
    [ncdLinearityTaskObjects release];
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

- (NSArray*) fileLines
{
    return fileLines;
}

- (void) setFileLines:(NSArray*)someLines
{
    [someLines retain];
    [fileLines release];
    fileLines = someLines;
}

- (NSString*) fileName
{
	return fileName[extendedLinearity];
}
- (void) setFileName:(NSString*)aFileName
{
    if(!aFileName)aFileName = @"";
    
	[[[self undoManager] prepareWithInvocationTarget:self] setFileName:fileName[extendedLinearity]];
    
	[fileName[extendedLinearity] autorelease];
	fileName[extendedLinearity] = [aFileName copy];
    
    [fileNameField setStringValue:fileName[extendedLinearity]];
}

- (BOOL) useFile
{
	return useFile[extendedLinearity];
}
- (void) setUseFile:(BOOL)aUseFile
{
	[[[self undoManager] prepareWithInvocationTarget:self] setUseFile:useFile[extendedLinearity]];
    
	useFile[extendedLinearity] = aUseFile;
    
    [useFileButton setState:useFile[extendedLinearity]];
}

- (BOOL) cycleWidth
{
	return cycleWidth[extendedLinearity];
}
- (void) setCycleWidth:(BOOL)aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setCycleWidth:cycleWidth[extendedLinearity]];
    
	cycleWidth[extendedLinearity] = aState;
    
    [cycleWidthButton setState:cycleWidth[extendedLinearity]];
}

- (int) numWidthValues
{
	return numWidthValues[extendedLinearity];
}
- (void) setNumWidthValues:(int)aNumWidthValues
{
	[[[self undoManager] prepareWithInvocationTarget:self] setNumWidthValues:numWidthValues[extendedLinearity]];
    
	numWidthValues[extendedLinearity] = aNumWidthValues;
    
    [numWidthValuesField setIntValue:numWidthValues[extendedLinearity]];
    [numWidthValuesStepper setIntValue:numWidthValues[extendedLinearity]];
}

- (float) endWidth
{
	return endWidth[extendedLinearity];
}
- (void) setEndWidth:(float)aEndWidth
{
	[[[self undoManager] prepareWithInvocationTarget:self] setEndWidth:endWidth[extendedLinearity]];
    
	endWidth[extendedLinearity] = aEndWidth;
    
    [endWidthField setFloatValue:endWidth[extendedLinearity]];
    [endWidthStepper setFloatValue:endWidth[extendedLinearity]];
}

- (float) startWidth
{
	return startWidth[extendedLinearity];
}
- (void) setStartWidth:(float)aStartWidth
{
	[[[self undoManager] prepareWithInvocationTarget:self] setStartWidth:startWidth[extendedLinearity]];
    
	startWidth[extendedLinearity] = aStartWidth;
    
    [startWidthField setFloatValue:startWidth[extendedLinearity]];
    [startWidthStepper setFloatValue:startWidth[extendedLinearity]];
}

- (int)timeOnOneChannel 
{
    return timeOnOneChannel[extendedLinearity];
}

- (void)setTimeOnOneChannel:(int)aTimeOnOneChannel {
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeOnOneChannel:timeOnOneChannel[extendedLinearity]];
    timeOnOneChannel[extendedLinearity] = aTimeOnOneChannel;
    if(timeOnOneChannel[extendedLinearity]<1)timeOnOneChannel[extendedLinearity]=1;
    [timeField setIntValue:timeOnOneChannel[extendedLinearity]];
    [timeStepper setIntValue:timeOnOneChannel[extendedLinearity]];
}

- (float)startAmplitude {
    
    return startAmplitude[extendedLinearity];
}

- (void)setStartAmplitude:(float)anAmplitude 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartAmplitude:startAmplitude[extendedLinearity]];
    startAmplitude[extendedLinearity] = anAmplitude;
    [startAmplitudeField setFloatValue:startAmplitude[extendedLinearity]];
    [startAmplitudeStepper setFloatValue:startAmplitude[extendedLinearity]];
}

- (float)burstRate 
{
    return burstRate[extendedLinearity];
}

- (void)setBurstRate:(float)aBurstRate 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBurstRate:burstRate[extendedLinearity]];
    burstRate[extendedLinearity] = aBurstRate;
    [burstRateField setFloatValue:burstRate[extendedLinearity]];
    [burstRateStepper setFloatValue:burstRate[extendedLinearity]];
}

- (float)width
{
    return width[extendedLinearity];
}

- (void)setWidth:(CGFloat)aWidth 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWidth:width[extendedLinearity]];
    width[extendedLinearity] = aWidth;
    [widthField setFloatValue:width[extendedLinearity]];
    [widthStepper setFloatValue:width[extendedLinearity]];
}

- (int)numAmpValues 
{
    return numAmpValues[extendedLinearity];
}


- (void)setNumAmpValues:(int)aNumAmpValues 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNumAmpValues:numAmpValues[extendedLinearity]];
    numAmpValues[extendedLinearity] = aNumAmpValues;
    [numAmpValuesField setIntValue:numAmpValues[extendedLinearity]];
    [numAmpValuesStepper setIntValue:numAmpValues[extendedLinearity]];
}

- (float)endAmplitude 
{
    return endAmplitude[extendedLinearity];
}

- (void)setEndAmplitude:(float)aEndAmplitude 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEndAmplitude:endAmplitude[extendedLinearity]];
    endAmplitude[extendedLinearity] = aEndAmplitude;
    [endAmplitudeField setFloatValue:endAmplitude[extendedLinearity]];
    [endAmplitudeStepper setFloatValue:endAmplitude[extendedLinearity]];
}

- (int) selectedWaveform
{
    return selectedWaveform[extendedLinearity];
}

- (void) setSelectedWaveform:(int)newSelectedWaveform
{
    [[[self undoManager] prepareWithInvocationTarget: self] setSelectedWaveform: selectedWaveform[extendedLinearity]];
    selectedWaveform[extendedLinearity] = newSelectedWaveform;
    
    [selectionPopUpButton selectItemAtIndex:selectedWaveform[extendedLinearity]];
    
}

- (BOOL) extendedLinearity
{
    return extendedLinearity;
}

- (void) setExtendedLinearity: (BOOL) flag
{
    [[[self undoManager] prepareWithInvocationTarget: self] setExtendedLinearity: extendedLinearity];
    extendedLinearity = flag;
    [extendedLinearityButton setState:extendedLinearity];
    
    [self updateWindow];
    
}


#pragma mark ¥¥¥Actions
- (IBAction) timeAction:(id)sender
{
    [self setTimeOnOneChannel:[sender intValue]];
}

- (IBAction) startAmplitudeAction:(id)sender
{
    [self setStartAmplitude:[sender floatValue]];
}
- (IBAction) burstRateAction:(id)sender
{
    [self setBurstRate:[sender floatValue]];
}
- (IBAction) widthAction:(id)sender
{
    [self setWidth:[sender floatValue]];
}
- (IBAction) numAmpValuesAction:(id)sender
{
    [self setNumAmpValues:[sender intValue]];
}
- (IBAction) endAmplitudeAction:(id)sender
{
    [self setEndAmplitude:[sender floatValue]];
}

- (IBAction) cycleWidthAction:(id)sender
{
    [self setCycleWidth:[sender state]];
    [self updateButtons];
}

- (IBAction) useFileAction:(id)sender
{
    [self setUseFile:[sender state]];
    [self updateButtons];
}

- (IBAction) selectFileAction:(id)sender
{
	
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if(fileName[extendedLinearity]){
        startDir = [fileName[extendedLinearity] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
	
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[[self view]window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSString* name = [[[openPanel URL]path] stringByAbbreviatingWithTildeInPath];
            [self setFileName:name];
        }
    }];

}

- (IBAction) startWidthAction:(id)sender
{
    [self setStartWidth:[sender floatValue]];
}

- (IBAction) endWidthAction:(id)sender
{
    [self setEndWidth:[sender floatValue]];
}

- (IBAction) numWidthValuesAction:(id)sender
{
    [self setNumWidthValues:[sender floatValue]];
}


-(IBAction) selectWaveformAction:(id)sender;
{
    if([sender indexOfSelectedItem] != selectedWaveform[extendedLinearity]){ 	
        [[self undoManager] setActionName: @"Selected Waveform"];
        [self setSelectedWaveform:(int)[selectionPopUpButton indexOfSelectedItem]];
    }
}

- (IBAction) extendedLinearityAction:(id)sender
{
    [self setExtendedLinearity:[sender state]];
    [self updateWindow];
    [self updateButtons];
    
}

- (void) updateWindow
{
    [startAmplitudeField setFloatValue:startAmplitude[extendedLinearity]];
    [startAmplitudeStepper setFloatValue:startAmplitude[extendedLinearity]];
    
    [endAmplitudeField setFloatValue:endAmplitude[extendedLinearity]];
    [endAmplitudeStepper setFloatValue:endAmplitude[extendedLinearity]];
    
    [selectionPopUpButton selectItemAtIndex:selectedWaveform[extendedLinearity]];
    
    [timeField setIntValue:timeOnOneChannel[extendedLinearity]];
    [timeStepper setIntValue:timeOnOneChannel[extendedLinearity]];
    
    [numAmpValuesField setIntValue:numAmpValues[extendedLinearity]];
    [numAmpValuesStepper setIntValue:numAmpValues[extendedLinearity]];
    
    [widthField setFloatValue:width[extendedLinearity]];
    [widthStepper setFloatValue:width[extendedLinearity]];
    
    [burstRateField setFloatValue:burstRate[extendedLinearity]];
    [burstRateStepper setFloatValue:burstRate[extendedLinearity]];
	
    [startWidthField setFloatValue:startWidth[extendedLinearity]];
    [startWidthStepper setFloatValue:startWidth[extendedLinearity]];
	
    [endWidthField setFloatValue:endWidth[extendedLinearity]];
    [endWidthStepper setFloatValue:endWidth[extendedLinearity]];
	
    [numWidthValuesField setFloatValue:numWidthValues[extendedLinearity]];
    [numWidthValuesStepper setFloatValue:numWidthValues[extendedLinearity]];
	
    [cycleWidthButton setState:cycleWidth[extendedLinearity]];
    [useFileButton setState:useFile[extendedLinearity]];
    if(fileName[extendedLinearity]){
        [fileNameField setStringValue:fileName[extendedLinearity]];
    }
    else {
        [fileNameField setStringValue:@""];
    }
}



- (void) enableGUI:(BOOL)state
{
    BOOL dependsOnNotUsingFile = state && !useFile[extendedLinearity];
    BOOL dependsOnUsingFile = state && useFile[extendedLinearity];
    
    [timeField setEnabled:dependsOnNotUsingFile];
    [timeStepper setEnabled:dependsOnNotUsingFile];
    [startAmplitudeField setEnabled:dependsOnNotUsingFile];
    [startAmplitudeStepper setEnabled:dependsOnNotUsingFile];
    [endAmplitudeField setEnabled:dependsOnNotUsingFile];
    [endAmplitudeStepper setEnabled:dependsOnNotUsingFile];
    [burstRateField setEnabled:dependsOnNotUsingFile];
    [burstRateStepper setEnabled:dependsOnNotUsingFile];
    [widthField setEnabled:dependsOnNotUsingFile && !cycleWidth[extendedLinearity]];
    [widthStepper setEnabled:dependsOnNotUsingFile && !cycleWidth[extendedLinearity]];
    [numAmpValuesField setEnabled:dependsOnNotUsingFile];
    [numAmpValuesStepper setEnabled:dependsOnNotUsingFile];
    [selectionPopUpButton setEnabled:dependsOnNotUsingFile];
	
    [cycleWidthButton setEnabled:dependsOnNotUsingFile];
    [startWidthField setEnabled:dependsOnNotUsingFile && cycleWidth[extendedLinearity]];
    [startWidthStepper setEnabled:dependsOnNotUsingFile && cycleWidth[extendedLinearity]];
    [endWidthField setEnabled:dependsOnNotUsingFile && cycleWidth[extendedLinearity]];
    [endWidthStepper setEnabled:dependsOnNotUsingFile && cycleWidth[extendedLinearity]];
    [numWidthValuesField setEnabled:dependsOnNotUsingFile && cycleWidth[extendedLinearity]];
    [numWidthValuesStepper setEnabled:dependsOnNotUsingFile && cycleWidth[extendedLinearity]];
    
    [useFileButton setEnabled:state];
    [chooseFileButton setEnabled:dependsOnUsingFile];
	
}


#pragma mark ¥¥¥Task Methods
- (void) prepare
{
    [super prepare];
    [[self undoManager] disableUndoRegistration];
    
    currentAmpStep   = 0;
    currentWidthStep = 0;
    currentFileStep = 0;
    lastWaveForm = -1;
    
    if([delegate respondsToSelector:@selector(dependentTask:)]){
        stepTask = [delegate dependentTask:self];
        [stepTask setIsSlave:YES];
        stepTaskMemento = [[stepTask memento] retain];      //save the old values
        [stepTask setTimeOnOneChannel:timeOnOneChannel[extendedLinearity]];
        [stepTask setWillRepeat:NO];
        [stepTask setStartIsDelayed:NO];
    }       
    
    NSArray* objects = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORPulserDistribModel")];
    if([objects count]){
        thePDSModel = [objects objectAtIndex:0];
        pdsMemento = [[thePDSModel memento] retain];  //save the old values
        [thePDSModel setDisableForPulser:YES];
    }
    
	if(!numAmpValues[extendedLinearity])  [self setNumAmpValues:1];
	if(!numWidthValues[extendedLinearity])[self setNumWidthValues:1];
    
    startedStepTask = NO;
    objects = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORHPPulserModel")];
    if([objects count]){
        thePulserModel = [objects objectAtIndex:0];
        pulserMemento = [[thePulserModel memento] retain];  //save the old values
        
        [self setMessage:@"Set up Pulser"];
		[thePulserModel resetAndClear];
        if(!useFile[extendedLinearity]){
            [thePulserModel setVoltage:startAmplitude[extendedLinearity]];
            [thePulserModel setBurstRate:burstRate[extendedLinearity]];
            if(cycleWidth[extendedLinearity]){
                [thePulserModel setTotalWidth:startWidth[extendedLinearity]];
            }
            else {
                [thePulserModel setTotalWidth:width[extendedLinearity]];
            }
            [thePulserModel setSelectedWaveform:selectedWaveform[extendedLinearity]];
            [thePulserModel downloadWaveform];
            [delegate shipPulserRecord:thePulserModel];
		}
        else {
			NSString* theFile = [fileName[extendedLinearity] stringByExpandingTildeInPath];
			NSLog(@"Linearity task will use file: <%@>\n",theFile);
            NSString* fileContents = [NSString stringWithContentsOfFile:theFile encoding:NSASCIIStringEncoding error:nil];
            if(fileContents){
                [self setFileLines:[fileContents lines]];
                if(![self setPulserFromFileLine:currentFileStep]){
                    [self hardHaltTask];
                }
            }
            else {
                [self hardHaltTask];
                NSLog(@"NcdLinearityTask didn't start because file: <%@> was empty\n",[fileName[extendedLinearity] stringByExpandingTildeInPath]);
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
    if(stepTask){
        [stepTask hardHaltTask];
        [stepTask setIsSlave:NO];
    }
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
    
    if(stepTask){
        [stepTask restoreFromMemento:stepTaskMemento];
        [stepTaskMemento release];
        stepTaskMemento = nil;
    }
    [self setMessage:@"Idle"];
}

- (void) cleanUp
{
    //we don't retain these, but we are done with them.
    thePulserModel = nil; 
    stepTask = nil;
    [self setMessage:@"Idle"];
            
}

- (NSString*) description
{
    NSString* s = @"\n";
    s = [s stringByAppendingFormat:@"Time/chan: %d  Waveform: %d\n",timeOnOneChannel[extendedLinearity],selectedWaveform[extendedLinearity]];
    s = [s stringByAppendingFormat:@"Amp1: %.2f Amp2 : %.2f Num: %d\n",startAmplitude[extendedLinearity],endAmplitude[extendedLinearity],numAmpValues[extendedLinearity]];
    s = [s stringByAppendingFormat:@"Rate: %.2f Width: %.2f",burstRate[extendedLinearity],width[extendedLinearity]];
    if(cycleWidth[extendedLinearity]){
        s = [s stringByAppendingFormat:@"Width1: %.2f Width2: %.2f Num: %d",startWidth[extendedLinearity],endWidth[extendedLinearity],numWidthValues[extendedLinearity]];
    }
    return s;
}


- (void) setDefaults
{
    [[self undoManager] disableUndoRegistration];
    
    int i;
    for(i=0;i<1;i++){
        timeOnOneChannel[i]  = 5;
        selectedWaveform[i]  = 0;
        startAmplitude[i]    = 250;
        endAmplitude[i]      = 5;
        burstRate[i]         = 10;
        width[i]             = 8.2;
        numAmpValues[i]       = 10;
        
        useFile[i]       = NO;
        fileName[i]      = @"";
        startWidth[i]    = 8.2;
        endWidth[i]      = 18.2;
        numWidthValues[i] = 10;
    }
	
    [self setTimeOnOneChannel:timeOnOneChannel[extendedLinearity]];    
    [self setStartAmplitude:startAmplitude[extendedLinearity]];
    [self setEndAmplitude:endAmplitude[extendedLinearity]];
    [self setBurstRate:burstRate[extendedLinearity]];
    [self setWidth:width[extendedLinearity]];
    [self setNumAmpValues:numAmpValues[extendedLinearity]];
	
    [self setUseFile:useFile[extendedLinearity]];
    [self setFileName:fileName[extendedLinearity]];
    [self setStartWidth:startWidth[extendedLinearity]];
    [self setEndWidth:endWidth[extendedLinearity]];
    [self setNumWidthValues:numWidthValues[extendedLinearity]];
    
    [[self undoManager] enableUndoRegistration];    
}

#pragma mark ¥¥¥Archival
static NSString* NcdLinearityExtendedLinearity= @"NcdLinearityExtendedLinearity";
static NSString* NcdLinearityTaskTime         = @"NcdLinearityTaskTime";
static NSString* NcdLinearityStartAmplitude   = @"NcdLinearityStartAmplitude";
static NSString* NcdLinearityBurstRate        = @"NcdLinearityBurstRate";
static NSString* NcdLinearityWidth            = @"NcdLinearityWidth";
static NSString* NcdLinearityNumOfValues      = @"NcdLinearityNumOfValues";
static NSString* NcdLinearityEndAmplitude     = @"NcdLinearityEndAmplitude";
static NSString* NcdLinearitySelectedWaveform = @"NcdLinearitySelectedWaveform";

+ (void) initialize
{
    [NcdLinearityTask setVersion:1]; 
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"NcdLinearityTask" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"NcdLinearityTask" owner:self topLevelObjects:&ncdLinearityTaskObjects];
#endif
    [ncdLinearityTaskObjects retain];
    
    [[self undoManager] disableUndoRegistration];
    [self setDefaults];
    
    
    if([decoder versionForClassName:@"NcdLinearityTask"] < 1){
        [self setTimeOnOneChannel:[decoder decodeIntForKey:NcdLinearityTaskTime]];
        [self setStartAmplitude:[decoder decodeFloatForKey:NcdLinearityStartAmplitude]];
        [self setBurstRate:[decoder decodeFloatForKey:NcdLinearityBurstRate]];
        [self setWidth:[decoder decodeFloatForKey:NcdLinearityWidth]];
        [self setNumAmpValues:[decoder decodeIntForKey:NcdLinearityNumOfValues]];
        [self setEndAmplitude:[decoder decodeFloatForKey:NcdLinearityEndAmplitude]];
        [self setSelectedWaveform:[decoder decodeIntForKey:NcdLinearitySelectedWaveform]];
    }
    else {
        int i;
        for(i=0;i<2;i++){
            timeOnOneChannel[i]    =[decoder decodeIntForKey:    [NSString stringWithFormat:@"NcdLinearityTaskTime%d",i]];
            startAmplitude[i]      =[decoder decodeFloatForKey:  [NSString stringWithFormat:@"NcdLinearityStartAmplitude%d",i]];
            burstRate[i]           =[decoder decodeFloatForKey:  [NSString stringWithFormat:@"NcdLinearityBurstRate%d",i]];
            width[i]               =[decoder decodeFloatForKey:  [NSString stringWithFormat:@"NcdLinearityWidth%d",i]];
            numAmpValues[i]        =[decoder decodeIntForKey:    [NSString stringWithFormat:@"NcdLinearityNumOfValues%d",i]];
            endAmplitude[i]        =[decoder decodeFloatForKey:  [NSString stringWithFormat:@"NcdLinearityEndAmplitude%d",i]];
            selectedWaveform[i]    =[decoder decodeIntForKey:    [NSString stringWithFormat:@"NcdLinearitySelectedWaveform%d",i]];
            startWidth[i]          =[decoder decodeFloatForKey:  [NSString stringWithFormat:@"NcdLinearityStartWidth%d",i]];
            endWidth[i]            =[decoder decodeFloatForKey:  [NSString stringWithFormat:@"NcdLinearityEndWidth%d",i]];
            numWidthValues[i]      =[decoder decodeIntForKey:    [NSString stringWithFormat:@"NcdLinearityNumWidthValues%d",i]];
            useFile[i]             =[decoder decodeIntegerForKey:    [NSString stringWithFormat:@"NcdLinearityUseFile%d",i]];
            fileName[i]            =[[decoder decodeObjectForKey: [NSString stringWithFormat:@"NcdLinearityFileName%d",i]] retain];
			if(fileName[i] == nil)fileName[i] = @"";
        }
    }
    
    [self setExtendedLinearity:[decoder decodeBoolForKey:NcdLinearityExtendedLinearity]];    
    
    [[self undoManager] enableUndoRegistration];    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeBool:extendedLinearity forKey:NcdLinearityExtendedLinearity];
    
    int i;
    for(i=0;i<2;i++){
        [encoder encodeInteger:timeOnOneChannel[i] forKey:  [NSString stringWithFormat:@"NcdLinearityTaskTime%d",i]];    
        [encoder encodeFloat:startAmplitude[i] forKey:  [NSString stringWithFormat:@"NcdLinearityStartAmplitude%d",i]];
        [encoder encodeFloat:burstRate[i] forKey:       [NSString stringWithFormat:@"NcdLinearityBurstRate%d",i]];
        [encoder encodeFloat:width[i]  forKey:          [NSString stringWithFormat:@"NcdLinearityWidth%d",i]];
        [encoder encodeInteger:numAmpValues[i] forKey:      [NSString stringWithFormat:@"NcdLinearityNumOfValues%d",i]];
        [encoder encodeFloat:endAmplitude[i] forKey:    [NSString stringWithFormat:@"NcdLinearityEndAmplitude%d",i]];
        [encoder encodeInteger:selectedWaveform[i] forKey:  [NSString stringWithFormat:@"NcdLinearitySelectedWaveform%d",i]];
		
        [encoder encodeFloat:startWidth[i] forKey:      [NSString stringWithFormat:@"NcdLinearityStartWidth%d",i]];
        [encoder encodeFloat:endWidth[i] forKey:        [NSString stringWithFormat:@"NcdLinearityEndWidth%d",i]];
        [encoder encodeInteger:numWidthValues[i] forKey:    [NSString stringWithFormat:@"NcdLinearityNumWidthValues%d",i]];
        [encoder encodeInteger:useFile[i] forKey:           [NSString stringWithFormat:@"NcdLinearityUseFile%d",i]];
        [encoder encodeObject:fileName[i] forKey:       [NSString stringWithFormat:@"NcdLinearityFileName%d",i]];
    }
    
    [self updateWindow];
    
}
@end

@implementation NcdLinearityTask (private)

- (BOOL) _doWork
{
    if(!stepTask){
        NSLogColor([NSColor redColor],@"NCD Linearity Task: No PDS stepper task defined, so nothing to do!\n");
        [self finishUp];
        return NO;
    }
    if(!thePulserModel){
        NSLogColor([NSColor redColor],@"NCD Linearity Task:No Pulser object in config, so nothing to do!\n");
        NSLogColor([NSColor redColor],@"NCD Linearity Task:Start of <%@> aborted!\n",[self title]);
        [self hardHaltTask];
        [self finishUp];
        return NO; //can not run if no pulser object in config
    }
    
    //must wait for the pulser to load waveform
    if(!startedStepTask){
        if(![thePulserModel loading]){
            if([stepTask numberEnabledChannels] == 0){
                NSLogColor([NSColor redColor],@"NCD PDS Step Task: No Channels selected, so nothing to do!\n");
                [self finishUp];
                return NO;
            }
			//ready to go, so start the pulser
			[thePulserModel writeTriggerSource:kInternalTrigger];
            [stepTask startTask];
            startedStepTask = YES;
        }
    }
    else {
        if([[self message]rangeOfString:[stepTask message]].location == NSNotFound){
            [self setMessage:[[stepTask message] stringByAppendingFormat: @" (%d/%d)",currentAmpStep,numAmpValues[extendedLinearity]]];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORTaskDidStepNotification object:self];
        }
        //make sure the pds step task is done...
        if([stepTask taskState] == eTaskStopped){
            if([self advanceStep]) {
				if(!useFile[extendedLinearity]){
					//go to the next amp step
					float anAmp   = (startAmplitude[extendedLinearity] + currentAmpStep*(endAmplitude[extendedLinearity]-startAmplitude[extendedLinearity])/(float)numAmpValues[extendedLinearity]);
					
					float aWidth;
					if(cycleWidth[extendedLinearity]){
						aWidth = (startWidth[extendedLinearity] + currentWidthStep*(endWidth[extendedLinearity]-startWidth[extendedLinearity])/(float)numWidthValues[extendedLinearity]);
					}
					else aWidth = width[extendedLinearity];
					
					[self setPulserAmp:anAmp width:aWidth];
				}
				else {
					if(![self setPulserFromFileLine:currentFileStep]){
                        [self finishUp];
						return NO;
					}
				}
                startedStepTask = NO;
            }
            else {
				[thePulserModel writeTriggerSource:kSoftwareTrigger];
                [self finishUp];
				return NO;
			}
		}
    }
    return YES;
}



- (void) setPulserAmp:(float)anAmp width:(float)aWidth
{
    [thePulserModel setVoltage:anAmp];
    [thePulserModel setTotalWidth:aWidth];
    [thePulserModel outputWaveformParams];
    [delegate shipPulserRecord:thePulserModel];
}

- (BOOL) advanceStep
{
    BOOL moreToDo = YES;
    if(!useFile[extendedLinearity]){
        ++currentAmpStep;
        if(currentAmpStep > numAmpValues[extendedLinearity]){
            if(cycleWidth[extendedLinearity]){
                currentAmpStep = 0;
                ++currentWidthStep;
                if(currentWidthStep > numWidthValues[extendedLinearity]){
					moreToDo = NO;
                }
            }
            else moreToDo = NO;
        }
    }
    else {
        ++currentFileStep;
        if(currentFileStep >= [fileLines count]){
            moreToDo = NO;
        }
    }
    return moreToDo;
}

//---------------------------------------------
// file format, space delimited values:
// time amp width burstRate waveform
//---------------------------------------------
- (BOOL) setPulserFromFileLine:(int)aLineNumber
{
    BOOL setPulser = YES;
    if(aLineNumber >= [fileLines count]){
        setPulser = NO;
    }
    else {
        NSCharacterSet* delimiters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSArray* parts = [[fileLines objectAtIndex:aLineNumber] tokensSeparatedByCharactersFromSet:delimiters];
        
        if([parts count]){
            [stepTask setTimeOnOneChannel:  [[parts objectAtIndex:0] intValue]];
            [thePulserModel setVoltage:     [[parts objectAtIndex:1] floatValue]];
            [thePulserModel setTotalWidth:  [[parts objectAtIndex:2] floatValue]];
            [thePulserModel setBurstRate:   [[parts objectAtIndex:3] floatValue]];
            int aWaveForm =                 [[parts objectAtIndex:4] intValue];
            if(lastWaveForm != aWaveForm){
                [thePulserModel setSelectedWaveform:aWaveForm];
                lastWaveForm = aWaveForm;
                [thePulserModel downloadWaveform];      
            }
            
            else [thePulserModel outputWaveformParams];
            
            [delegate shipPulserRecord:thePulserModel];
		}
        else {
            setPulser = NO;
        }
    }
    if(!setPulser){
        NSLog(@"Failed reading line: %d of file <%@>\n",aLineNumber,[fileName[extendedLinearity] stringByAbbreviatingWithTildeInPath]);
    }
	return setPulser;
}

@end
