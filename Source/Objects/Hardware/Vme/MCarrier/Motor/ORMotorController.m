//
//  ORMotorController.m
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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
#import "ORMotorController.h"
#import "ORMotorModel.h"
#import "ORMotorSweeper.h"
#import "ORAxis.h"
#import "ORQueueView.h"

#pragma mark ¥¥¥Definitions

enum {
    kPatternStartTag    = 0,
    kPatternEndTag      = 1,
    kPatternDeltaTag    = 2,
    kDwellTimeTag       = 3,
    kNSweepsTag         = 4	
};

enum {
    kPatternRunningTag    = 0,
    kPatternPositionTag   = 1
};

@implementation ORMotorController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Motor"];
    
    return self;
}

- (void) awakeFromNib
{
	if([model patternStartCount] < [model patternEndCount]){
		[xAxis setRngLimitsLow:[model patternStartCount] withHigh:[model patternEndCount] withMinRng:abs([model patternEndCount] - [model patternStartCount])];
	}
	else {
		[xAxis setRngLimitsLow:[model patternEndCount] withHigh:[model patternStartCount] withMinRng:abs([model patternEndCount] - [model patternStartCount])];
	}
	[xAxis setLabel:@"Motor Position (Pattern Range)"];
    [queueView setUseSignedValues:YES];
    [queueView setNeedsDisplay:YES];
    [super awakeFromNib];
}

#pragma mark ¥¥¥Notifications
-(void)registerNotificationObservers
{
    [super registerNotificationObservers];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(riseFreqChanged:)
                         name : ORMotorRiseFreqChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(driveFreqChanged:)
                         name : ORMotorDriveFreqChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accelerationChanged:)
                         name : ORMotorAccelerationChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(positionChanged:)
                         name : ORMotorPositionChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(multiplierChanged:)
                         name : ORMotorMultiplierChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(absRelChanged:)
                         name : ORMotorAbsoluteMotionChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(risingEdgeChanged:)
                         name : ORMotorRisingEdgeChangedNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(stepModeChanged:)
                         name : ORMotorStepModeChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(holdCurrentChanged:)
                         name : ORMotorHoldCurrentChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(breakPointChanged:)
                         name : ORMotorBreakPointChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(absBreakPointChanged:)
                         name : ORMotorAbsoluteBrkPtChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(stepCountChanged:)
                         name : ORMotorStepCountChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(motorRunningChanged:)
                         name : ORMotorMotorRunningChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(motorPositionChanged:)
                         name : ORMotorMotorPositionChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(homeDetectedChanged:)
                         name : ORMotorHomeDetectedChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(seekAmountChanged:)
                         name : ORMotorSeekAmountChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(patternChanged:)
                         name : ORMotorPatternChangedNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(patternFileNameChanged:)
                         name : ORMotorPatternFileNameChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(usePatternFileNameChanged:)
                         name : ORMotorUsePatternFileChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(optionMaskChanged:)
                         name : ORMotorOptionsMaskChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(patternTypeChanged:)
                         name : ORMotorPatternTypeChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateButtons:)
                         name : ORMotorMotorWorkerChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(motorNameChanged:)
                         name : ORMotorMotorNameChangedNotification
                       object : model];
    
    [notifyCenter addObserver: self
                     selector: @selector(connectionChanged:)
                         name: ORConnectionChanged
                       object: nil];
    
}


#pragma mark ¥¥¥Accessors


#pragma mark ¥¥¥Interface Management
- (void) connectionChanged:(NSNotification*)aNote
{
    if([aNote object] == model){
		[[self window] setTitle:[NSString stringWithFormat:@"Stepper Motor (%d)",(int32_t)[model tag]]];
	}
}
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if([menuItem tag] >=32 && [model fourPhase]){
        return NO;
    }
    return YES;
}


-(void)updateWindow
{
    [super updateWindow];
    [self riseFreqChanged:nil];
    [self driveFreqChanged:nil];
    [self accelerationChanged:nil];
    [self positionChanged:nil];
    [self multiplierChanged:nil];
    [self absRelChanged:nil];
    [self risingEdgeChanged:nil];
    [self stepModeChanged:nil];
    [self holdCurrentChanged:nil];
    [self breakPointChanged:nil];
    [self absBreakPointChanged:nil];
    [self stepCountChanged:nil];
    [self motorRunningChanged:nil];
    [self motorPositionChanged:nil];
    [self homeDetectedChanged:nil];
    [self seekAmountChanged:nil];
    
    [self usePatternFileNameChanged:nil];
    [self patternFileNameChanged:nil];
    [self patternChanged:nil];
    [self patternTypeChanged:nil];
    [self optionMaskChanged:nil];
    [self motorNameChanged:nil];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"Stepper Motor (%d)",(int)[model tag]]];
}

- (void) updateButtons:(NSNotification*)aNote
{
    BOOL motorIsRunning = ([model motorRunning]);
    
    BOOL patternIsRunning = [model patternInProgress];
    
    BOOL okToEnable = (!patternIsRunning && !motorIsRunning);
    
    BOOL patternNotRunning = !patternIsRunning;
    
    
    BOOL manualRunning = (motorIsRunning && !patternIsRunning);
    
    [startRunningPatternButton setTitle:patternIsRunning?@"Stop":@"Start"];
    [startRunningPatternButton setEnabled:![model optionSet:kSyncWithRunOption]];
    
    
    if(manualRunning){
        [motorRunningProgress startAnimation:nil];
    }
    else {
        [motorRunningProgress stopAnimation:nil];
    }
    
    [incButton setEnabled:okToEnable];
    [decButton setEnabled:okToEnable];
    [setStepCountButton setEnabled:okToEnable];
    [goButton setEnabled:okToEnable];
    
    [stopButton setEnabled:manualRunning];
    
    [homeButton setEnabled:okToEnable];
    [absRelStepPopUp setEnabled:okToEnable];
    [risingEdgePopUp setEnabled:okToEnable];
    [holdCurrentPopUp setEnabled:okToEnable];
    [stepModePopUp setEnabled:okToEnable];
    [absRelBrkPtPopUp setEnabled:okToEnable];
    [seekAmountField setEnabled:okToEnable];
    [targetField setEnabled:okToEnable];
    [multiplierMatrix setEnabled:okToEnable];
    [breakPointField setEnabled:okToEnable];
    [stepCountField setEnabled:okToEnable];
    
    [motorPatternMatrix setEnabled:patternNotRunning];
    [patternTypeMatrix setEnabled:patternNotRunning];
    [usePatternFileCB setEnabled:patternNotRunning];
    [optionMatrix setEnabled:!patternIsRunning];
    [setPatternFileButton setEnabled:patternNotRunning];
    
    [[statusMatrix cellWithTag:kPatternRunningTag] setStringValue:patternIsRunning?@"Running":@"--"];
}

- (void) motorNameChanged:(NSNotification*)aNote
{
	[motorNameField setStringValue:[model motorName]];
}


- (void) motorWorkerChanged:(NSNotification*)aNote
{
	[self updateButtons:nil];
}

- (void) optionMaskChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<[optionMatrix numberOfRows];i++){
		[[optionMatrix cellWithTag:i] setState: [model optionSet:i]];	
	}
	[self updateButtons:nil];
}

- (void) patternChanged:(NSNotification*)aNote
{
	[[motorPatternMatrix cellWithTag:kPatternStartTag] setIntValue:[model patternStartCount]];
	[[motorPatternMatrix cellWithTag:kPatternEndTag] setIntValue:[model patternEndCount]];
	[[motorPatternMatrix cellWithTag:kPatternDeltaTag] setIntValue:[model patternDeltaSteps]];
	[[motorPatternMatrix cellWithTag:kDwellTimeTag] setFloatValue:[model patternDwellTime]];
	[[motorPatternMatrix cellWithTag:kNSweepsTag] setIntValue:[model patternNumSweeps]];
	
	if([model patternStartCount] < [model patternEndCount]){
		[xAxis setRngLimitsLow:[model patternStartCount] withHigh:[model patternEndCount] withMinRng:abs([model patternEndCount] - [model patternStartCount])];
	}
	else {
		[xAxis setRngLimitsLow:[model patternEndCount] withHigh:[model patternStartCount] withMinRng:abs([model patternEndCount] - [model patternStartCount])];
	}
	
	//[xAxis setRngLimitsLow:[model patternStartCount] withHigh:[model patternEndCount] withMinRng:abs([model patternEndCount] - [model patternStartCount])];
	[queueView setNeedsDisplay:YES];
}

- (void) patternTypeChanged:(NSNotification*)aNote
{
	[patternTypeMatrix selectCellWithTag:[model patternType]];
}

- (void) usePatternFileNameChanged:(NSNotification*)aNote
{
	[usePatternFileCB setState:[model useFileForPattern]];
}

- (void) patternFileNameChanged:(NSNotification*)aNote
{
	[patternFileName setStringValue:[model patternFileName]];
}

- (void) motorRunningChanged:(NSNotification*)aNote
{
	[self updateButtons:nil];		
}

- (void) motorPositionChanged:(NSNotification*)aNote
{
	[motorPositionField setIntegerValue:[model motorPosition]];
	[[statusMatrix cellWithTag:kPatternPositionTag] setIntegerValue:[model motorPosition]];
	[queueView setNeedsDisplay:YES];
}

- (void) homeDetectedChanged:(NSNotification*)aNote
{
	if([model homeDetected]){
		[homeDetectedField setStringValue:@"Home Detected"];
	}
	else {
		[homeDetectedField setStringValue:@""];
	}
}

- (void) seekAmountChanged:(NSNotification*)aNote
{
	[seekAmountField setIntValue:[model seekAmount]];
}


- (void) fourPhaseChanged:(NSNotification*)aNote
{
	[self updateButtons:nil];
}

- (void) stepCountChanged:(NSNotification*)aNote
{
	[stepCountField setIntValue:[model stepCount]];
}

- (void) breakPointChanged:(NSNotification*)aNote
{
	[breakPointField setIntValue:[model breakPoint]];
}

- (void) absBreakPointChanged:(NSNotification*)aNote
{
	[absRelBrkPtPopUp selectItemAtIndex:[absRelBrkPtPopUp indexOfItemWithTag:[model absoluteBrkPt]]];
}

- (void) holdCurrentChanged:(NSNotification*)aNote
{
	[holdCurrentPopUp selectItemAtIndex:[model holdCurrent]];
}

- (void) stepModeChanged:(NSNotification*)aNote
{
	[stepModePopUp selectItemAtIndex:[stepModePopUp indexOfItemWithTag:[model stepMode]]];
}


- (void) riseFreqChanged:(NSNotification*)aNote
{
	[[motorProfileFields cellWithTag:0] setIntValue:[model riseFreq]];
}

- (void) risingEdgeChanged:(NSNotification*)aNote
{
	[risingEdgePopUp selectItemAtIndex:[risingEdgePopUp indexOfItemWithTag:[model risingEdge]]];
}
- (void) driveFreqChanged:(NSNotification*)aNote
{
	[[motorProfileFields cellWithTag:1] setIntValue:[model driveFreq]];
}
- (void) accelerationChanged:(NSNotification*)aNote
{
	[[motorProfileFields cellWithTag:2] setIntValue:[model acceleration]];
}
- (void) positionChanged:(NSNotification*)aNote
{
	[targetField setIntValue:[model xyPosition]];
}

- (void) multiplierChanged:(NSNotification*)aNote
{
	[multiplierMatrix selectCellWithTag:[model multiplierX]];
}

- (void) absRelChanged:(NSNotification*)aNote
{
	[absRelStepPopUp selectItemAtIndex:[absRelStepPopUp indexOfItemWithTag:[model absoluteMotion]]];
	[goButton setTitle:[model absoluteMotion]?@"Go To":@"Go"];
	[stepTargetField setStringValue:[model absoluteMotion]?@"Move To":@"Move"];
}

#pragma mark ¥¥¥Actions
- (IBAction) setProfileAction:(id)sender
{
    [model setRiseFreq:     [[motorProfileFields cellWithTag:0] intValue]];
    [model setDriveFreq:    [[motorProfileFields cellWithTag:1] intValue]];
    [model setAcceleration: [[motorProfileFields cellWithTag:2] intValue]];
}


- (IBAction) readMotorAction:(id)sender
{
    @try {
        int32_t thePosition = [model readMotor];
        
        NSString* movingState;
        if([model motorRunning])  movingState = @"Moving";
        else					  movingState = @"Stopped";
        NSLog(@"%@ Pos: %d <%@>\n",[model motorName],thePosition,movingState);
        
	}
	@catch(NSException* localException) {
        NSLog(@"Exception on Read Motor: %@\n",localException);
    }
}

- (IBAction) goAction:(id)sender
{
    @try {
        [self endEditing];
        [model startMotor];
	}
	@catch(NSException* localException) {
        NSLog(@"Exception on Motor Start: %@\n",localException);
    }
}

- (IBAction) stopAction:(id)sender
{
    @try {
        [model stopMotor];
	}
	@catch(NSException* localException) {
        NSLog(@"Exception on Stop Motor: %@\n",localException);
    }
}

- (IBAction) incAction:(id)sender
{
    @try {
        [self endEditing];
        [model incMotor];
	}
	@catch(NSException* localException) {
        NSLog(@"Exception on Motor Increment: %@\n",[model motorName],localException);
    }
}

- (IBAction) decAction:(id)sender
{
    @try {
        [self endEditing];
        [model decMotor];
	}
	@catch(NSException* localException) {
        NSLog(@"Exception on %@ Decrement: %@\n",[model motorName],localException);
    }
}

- (IBAction) stepModeAction:(id)sender
{
    [model setStepMode:(int)[[sender selectedCell] tag]];
}

- (IBAction) holdCurrentAction:(id)sender
{
    [model setHoldCurrent:(int)[sender indexOfSelectedItem]];
}


- (IBAction) multiplierAction:(id)sender
{
    [model setMultiplierX:(int)[[sender selectedCell] tag]];
}

- (IBAction) risingEdgeAction:(id)sender
{
    [model setRisingEdge:(int)[[sender selectedCell] tag]];
}

- (IBAction) readHomeAction:(id)sender
{
    @try {
        [model readHome];
        NSLog(@"Home switch %@: %@\n",[model motorName],[model homeDetected]==0?@"Low":@"High");
	}
	@catch(NSException* localException) {
        NSLog(@"Exception on %@ Read Home: %@\n",[model motorName],localException);
    }
    
}


- (IBAction) targetAction:(id)sender
{
    [model setXyPosition:[sender intValue]];
}

- (IBAction) absRelAction:(id)sender
{
    [model setAbsoluteMotion:[[sender selectedCell] tag]];
}

- (IBAction) seekHomeAction:(id)sender
{
    [model seekHome];
}

- (IBAction) breakPointAction:(id)sender
{
    [model setBreakPoint:[sender intValue]];
}

- (IBAction) stepCountAction:(id)sender
{
    [model setStepCount:[sender intValue]];
}


- (IBAction) absBreakPointAction:(id)sender
{
    [model setAbsoluteBrkPt:[[sender selectedCell] tag]];
}

- (IBAction) seekAmountAction:(id)sender
{
    [model setSeekAmount:[sender intValue]];
}


- (IBAction) setStepCountAction:(id)sender
{
    [self endEditing];
    BOOL cancel = ORRunAlertPanel(@"You are setting the step count WITHOUT moving the motor!",@"Is this really what you want?",@"Cancel",@"YES/Change Count",nil);
    if(!cancel){
        @try {
            [model loadStepCount];	
            [model readMotor];
            NSLog(@"Loaded Step Count %@ to: %d\n",[model motorName],[model stepCount]);
		}
		@catch(NSException* localException) {
            NSLog(@"Exception on %@ Load Step Count: %@\n",[model motorName],localException);
        }
    }
}

- (IBAction) patternAction:(id)sender
{
    switch([[sender selectedCell]tag]){
        case kPatternStartTag: [model setPatternStartCount:[sender intValue]];  break;
        case kPatternEndTag  : [model setPatternEndCount:[sender intValue]];    break;
        case kPatternDeltaTag: [model setPatternDeltaSteps:[sender intValue]];  break;
        case kDwellTimeTag   : [model setPatternDwellTime:[sender floatValue]]; break;
        case kNSweepsTag     : [model setPatternNumSweeps:[sender intValue]];   break;
        default: break;
    }
    [model roundPatternEnd];
}

- (IBAction) patternTypeAction:(id)sender
{
    [model setPatternType:(int)[[patternTypeMatrix selectedCell] tag]];
}

- (IBAction) optionMaskAction:(id)sender
{
    int  whichOption = (int)[[sender selectedCell]tag];
    if([[sender cellWithTag:whichOption] state])[model setOption:whichOption];
    else [model clearOption:whichOption];
}


- (IBAction) usePatternFileAction:(id)sender
{
    [model setUseFileForPattern:[usePatternFileCB state]];
}


- (IBAction) patternFileAction:(id)sender
{
    [model setPatternFileName:[sender stringValue]];
}


- (IBAction) selectPatternFileAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* filename = [[[openPanel URL] path] stringByAbbreviatingWithTildeInPath];
            [model setPatternFileName:filename];  
        }
    }];
}

- (IBAction) startPatternRunAction:(id)sender
{
    [self endEditing];
    if([model patternInProgress])[model stopPatternRun:model];
    else [model startPatternRun:model];
}

- (IBAction) motorNameAction:(id)sender
{
    [model setMotorName:[sender stringValue]];
    [[self window] setTitle:[NSString stringWithFormat:@"Stepper Motor (%@)",[model motorName]]];
}

- (void) getQueMinValue:(uint32_t*)aMinValue maxValue:(uint32_t*)aMaxValue head:(uint32_t*)aHeadValue tail:(uint32_t*)aTailValue
{
    *aMinValue = [model patternStartCount];
    *aMaxValue = [model patternEndCount];
    int32_t thePosition = [model motorPosition];
    *aHeadValue = thePosition+1;
    *aTailValue = thePosition-1;
}


@end

