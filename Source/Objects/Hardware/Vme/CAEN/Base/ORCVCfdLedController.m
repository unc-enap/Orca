/*
 *  ORCVCfdLedController.m
 *  Orca
 *
 *  Created by Mark Howe on Tuesday, June 7, 2011.
 *  Copyright (c) 2011 CENPA, University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sonsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORCVCfdLedController.h"
#import "ORCVCfdLedModel.h"

@implementation ORCVCfdLedController

#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"CV812" ];
    return self;
}
- (void) awakeFromNib 
{
	int i;
	for(i=0;i<16;i++){
		[[inhibitMaskMatrix cellAtRow:i column:0] setTag:i];
		[[thresholdMatrix cellAtRow:i column:0] setTag:i];
	}
	[super awakeFromNib];
}

- (NSString*) dialogLockName
{
	return @"CAENGenericLock"; //subclasses should override
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [ super registerNotificationObservers ];
	
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

	[notifyCenter addObserver:self
					 selector:@selector(baseAddressChanged:)
						 name:ORVmeIOCardBaseAddressChangedNotification
					   object:model];	
	
	[notifyCenter addObserver:self
					 selector:@selector(thresholdChanged:)
						 name:ORCVCfdLedModelThresholdChanged
					   object:model];
	
    [notifyCenter addObserver : self
                     selector : @selector(thresholdLockChanged:)
                         name : [self dialogLockName]
						object: nil];

	[notifyCenter addObserver : self
					 selector : @selector(thresholdLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(testPulseChanged:)
                         name : ORCVCfdLedModelTestPulseChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(patternInhibitChanged:)
                         name : ORCVCfdLedModelPatternInhibitChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(majorityThresholdChanged:)
                         name : ORCVCfdLedModelMajorityThresholdChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(outputWidth0_7Changed:)
                         name : ORCVCfdLedModelOutputWidth0_7Changed
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(outputWidth8_15Changed:)
                         name : ORCVCfdLedModelOutputWidth8_15Changed
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(autoInitWithRunChanged:)
                         name : ORCVCfdLedModelAutoInitWithRunChanged
						object: model];
	
}

#pragma mark ***Interface Management

- (void) autoInitWithRunChanged:(NSNotification*)aNote
{
	[autoInitWithRunCB setIntValue: [model autoInitWithRun]];
}

- (void) updateWindow
{
	[super updateWindow];
    [self baseAddressChanged:nil];
	[self testPulseChanged:nil];
	[self patternInhibitChanged:nil];
	[self majorityThresholdChanged:nil];
	[self outputWidth0_7Changed:nil];
	[self outputWidth8_15Changed:nil];
    [self thresholdLockChanged:nil];
    [self thresholdChanged:nil];

	[self autoInitWithRunChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:[self dialogLockName] to:secure];
    [dialogLockButton setEnabled:secure];
}



- (void) baseAddressChanged:(NSNotification*)aNote
{
	[baseAddressField setIntegerValue: [model baseAddress]];
}

- (void) thresholdLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self dialogLockName]];
    //BOOL locked = [gSecurity isLocked:[self dialogLockName]];
	
    [thresholdMatrix setEnabled:!lockedOrRunningMaintenance];
    [testPulseField setEnabled:!lockedOrRunningMaintenance]; 
    [patternInhibitField setEnabled:!lockedOrRunningMaintenance]; 
    [majorityThresholdField setEnabled:!lockedOrRunningMaintenance]; 
    [outputWidth0_7Field setEnabled:!lockedOrRunningMaintenance]; 
    [outputWidth8_15Field setEnabled:!lockedOrRunningMaintenance]; 

	[initHWButton setEnabled:!lockedOrRunningMaintenance];
    [probeButton setEnabled:!runInProgress]; 
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:[self dialogLockName]])s = @"Not in Maintenance Run.";
    }
    [dialogLockDocField setStringValue:s];
	
}	
- (void) thresholdChanged:(NSNotification*) aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<16;i++){
			[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
		}
	}
	else {
		// Get the channel that changed and then set the GUI value using the model value.
		int chnl = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		[[thresholdMatrix cellWithTag:chnl] setIntValue:[model threshold:chnl]];
	}
}
- (void) testPulseChanged:(NSNotification*)aNote
{
	[testPulseField setIntValue:[model testPulse]];	
}

- (void) patternInhibitChanged:(NSNotification*)aNote
{
	[patternInhibitField setIntValue:[model patternInhibit]];		
	short i;
	uint32_t theMask = [model patternInhibit];
	for(i=0;i<16;i++){
		[[inhibitMaskMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
}

- (void) majorityThresholdChanged:(NSNotification*)aNote
{
	[majorityThresholdField setIntValue:[model majorityThreshold]];		

}

- (void) outputWidth0_7Changed:(NSNotification*)aNote
{
	[outputWidth0_7Field setIntValue:[model outputWidth0_7]];			
}

- (void) outputWidth8_15Changed:(NSNotification*)aNote
{
	[outputWidth8_15Field setIntValue:[model outputWidth8_15]];			
}

#pragma mark •••Actions

- (void) autoInitWithRunAction:(id)sender
{
	[model setAutoInitWithRun:[sender intValue]];	
}

- (IBAction) testPulseAction:(id)sender
{
	[model setTestPulse:[sender intValue]];
}

- (IBAction) patternInhibitAction:(id)sender
{
	[model setPatternInhibit:[sender intValue]];
}

- (IBAction) inhibitAction:(id)sender
{
	[model setInhibitMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) majorityThresholdAction:(id)sender
{
	[model setMajorityThreshold:[sender intValue]];
}

- (IBAction) outputWidth0_7Action:(id)sender
{
	[model setOutputWidth0_7:[sender intValue]];
}

- (IBAction) outputWidth8_15Action:(id)sender
{
	[model setOutputWidth8_15:[sender intValue]];
}

- (IBAction) thresholdAction:(id) aSender
{
    if ([aSender intValue] != [model threshold:[[aSender selectedCell] tag]]){
        [model setThreshold:[[aSender selectedCell] tag] threshold:[aSender intValue]];
    }
}

- (IBAction) initHWAction:(id) aSender
{
	@try {
		[self endEditing];
		[model initBoard];
	}
	@catch(NSException* e){
        NSLog(@"Init of %@ FAILED.\n",[self className]);
        ORRunAlertPanel([e name], @"%@\nInit Failed", @"OK", nil, nil, e);
	}
}

- (IBAction) baseAddressAction: (id)aSender
{
	[model setBaseAddress:[aSender intValue]];
}

- (IBAction) probeAction:(id) aSender
{
	@try {
		[model probeBoard];
	}
	@catch(NSException* e){
        NSLog(@"Probe of %@ FAILED.\n",[self className]);
        ORRunAlertPanel([e name], @"%@\nProbe Failed", @"OK", nil, nil, e);	
	}
}

- (IBAction) dialogLockAction:(id)sender
{
    [gSecurity tryToSetLock:[self dialogLockName] to:[sender intValue] forWindow:[self window]];
}

@end
