//
//  ORRemoteRunController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 23 2002.
//  Copyright(c)2002 CENPA, University of Washington. All rights reserved.
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
#import "ORRemoteRunController.h"
#import "ORRemoteRunModel.h"

@implementation ORRemoteRunController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"RemoteRunControl"];
    return self;
}
-(void)dealloc
{
    [super dealloc];
}


-(void)awakeFromNib
{
   // [[self window] setBackgroundColor:[NSColor colorWithDeviceRed:240/255. green:235/255. blue:191/255. alpha:1]];
    [runProgress setStyle:NSProgressIndicatorSpinningStyle];
	[runProgress setControlSize:NSSmallControlSize];
    [runBar setIndeterminate:NO];
    [super awakeFromNib];
    [self updateButtons];
}

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Interface Management
-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRemoteRunLock
                       object : nil];
                       
    [notifyCenter addObserver: self
                     selector: @selector(timedRunChanged:)
                         name: ORRemoteRunTimedRunChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(repeatRunChanged:)
                         name: ORRemoteRunRepeatRunChanged
                       object: model];
    
    
    [notifyCenter addObserver: self
                     selector: @selector(timeLimitStepperChanged:)
                         name: ORRemoteRunTimeLimitChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(elapsedTimeChanged:)
                         name: ORRemoteRunElapsedTimeChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(startTimeChanged:)
                         name: ORRemoteRunStartTimeChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(timeToGoChanged:)
                         name: ORRemoteRunTimeToGoChanged
                       object: model];
    
    
    [notifyCenter addObserver: self
                     selector: @selector(runStatusChanged:)
                         name: ORRemoteRunStatusChanged
                       object: model];
    
     [notifyCenter addObserver: self
                     selector: @selector(runStatusChanged:)
                         name: ORRemoteRunIsConnectedChanged
                       object: model];
   
    [notifyCenter addObserver: self
                     selector: @selector(runNumberChanged:)
                         name: ORRemoteRunNumberChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(quickStartChanged:)
                         name: ORRemoteRunQuickStartChanged
                       object: model];

   [notifyCenter addObserver: self
                     selector: @selector(offlineChanged:)
                         name: ORRemoteRunModelOfflineChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(remoteHostChanged:)
                         name: ORRemoteRunRemoteHostChanged
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(remotePortChanged:)
                         name: ORRemoteRunRemotePortChanged
                       object: model];


	[notifyCenter addObserver : self
                      selector: @selector(connectAtStartChanged:)
                          name: ORRemoteRunConnectAtStartChanged
                       object : [self model]];
    
	[notifyCenter addObserver : self
                      selector: @selector(autoReconnectChanged:)
                          name: ORRemoteRunAutoReconnectChanged
                       object : [self model]];

	[notifyCenter addObserver : self
                      selector: @selector(isConnectedChanged:)
                          name: ORRemoteRunIsConnectedChanged
                       object : model];

	[notifyCenter addObserver : self
                      selector: @selector(scriptNamesChanged:)
                          name: ORRemoteRunModelScriptNamesChanged
                       object : model];
	
	[notifyCenter addObserver : self
                      selector: @selector(startScriptNameChanged:)
                          name: ORRemoteRunStartScriptNameChanged
                       object : model];
	
	[notifyCenter addObserver : self
                      selector: @selector(shutDownScriptNameChanged:)
                          name: ORRemoteRunShutDownScriptNameChanged
                       object : model];
}



-(void)updateWindow
{
    [super updateWindow];
    [self runStatusChanged:nil];
    [self timeLimitStepperChanged:nil];
    [self timedRunChanged:nil];
    [self repeatRunChanged:nil];
    [self elapsedTimeChanged:nil];
    [self startTimeChanged:nil];
    [self runNumberChanged:nil];
    [self quickStartChanged:nil];
    [self offlineChanged:nil];
    [self remoteHostChanged:nil];
    [self remotePortChanged:nil];
	[self connectAtStartChanged:nil];
	[self autoReconnectChanged:nil];
	[self isConnectedChanged:nil];
	[self scriptNamesChanged:nil];
	[self startScriptNameChanged:nil];
	[self shutDownScriptNameChanged:nil];
}



-(void)updateButtons;
{
    if(![model isConnected]){
        [startRunButton setEnabled:NO];
        [restartRunButton setEnabled:NO];
        [stopRunButton setEnabled:NO];
        [timedRunCB setEnabled:NO];
        [timeLimitField setEnabled:NO];
        [timeLimitStepper setEnabled:NO];
        [repeatRunCB setEnabled:NO];
		[endSubRunButton setEnabled:NO];
		[startSubRunButton setEnabled:NO];
    }
    else {
        if([model runningState] == eRunInProgress){
            [startRunButton setEnabled:NO];
            [restartRunButton setEnabled:YES];
            [stopRunButton setEnabled:YES];
            [timedRunCB setEnabled:NO];
            [timeLimitField setEnabled:NO];
            [timeLimitStepper setEnabled:NO];
            [repeatRunCB setEnabled:[model timedRun]];
            [endSubRunButton setEnabled:YES];
            [startSubRunButton setEnabled:NO];
        }
        else if([model runningState] == eRunStopped){
            [startRunButton setEnabled:YES];
            [restartRunButton setEnabled:NO];
            [stopRunButton setEnabled:NO];
            [timedRunCB setEnabled:YES];
            [timeLimitField setEnabled:[model timedRun]];
            [timeLimitStepper setEnabled:[model timedRun]];
            [repeatRunCB setEnabled:[model timedRun]];
            [endSubRunButton setEnabled:NO];
			[startSubRunButton setEnabled:NO];
			[endSubRunButton setEnabled:NO];
            [startSubRunButton setEnabled:NO];
        }
        else if([model runningState] == eRunStarting || [model runningState] == eRunStopping){
            [startRunButton setEnabled:NO];
            [restartRunButton setEnabled:NO];
            [stopRunButton setEnabled:NO];
            [timedRunCB setEnabled:NO];
            [timeLimitField setEnabled:NO];
            [timeLimitStepper setEnabled:NO];
            [repeatRunCB setEnabled:NO];
			[endSubRunButton setEnabled:NO];
            [startSubRunButton setEnabled:NO];
        }
		else if([model runningState] == eRunBetweenSubRuns){
			[endSubRunButton setEnabled:NO];
            [startSubRunButton setEnabled:YES];
		}
    }
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORRemoteRunLock];
    [lockButton setState: locked];
    
    [remotePortField setEnabled:!locked];
    [remoteHostField setEnabled:!locked];
    [connectAtStartButton setEnabled:!locked];
    [autoReconnectButton setEnabled:!locked];
}

- (void) scriptNamesChanged:(NSNotification*)aNote
{
	[startUpScripts removeAllItems];
	[shutDownScripts removeAllItems];
	[startUpScripts addItemWithTitle:@"---"];
	[shutDownScripts addItemWithTitle:@"---"];
	NSEnumerator* e = [[model scriptNames] objectEnumerator];
	NSString* aScriptName;
	while(aScriptName = [e nextObject]){
		[startUpScripts addItemWithTitle:aScriptName]; 
		[shutDownScripts addItemWithTitle:aScriptName]; 
	}
}

- (void) startScriptNameChanged:(NSNotification*)aNote
{
	[startUpScripts selectItemWithTitle:[model selectedStartScriptName]];
}

- (void) shutDownScriptNameChanged:(NSNotification*)aNote
{
	[shutDownScripts selectItemWithTitle:[model selectedShutDownScriptName]];
}

- (void) isConnectedChanged:(NSNotification*)aNote
{
	[connectionStatusField setStringValue:[model isConnected]?@"Connected":@"---"];
	[connectButton setTitle:[model isConnected]?@"Disconnect":@"Connect"];
}

- (void) connectAtStartChanged:(NSNotification*)aNote
{
	[connectAtStartButton setState:[model connectAtStart]];
}

- (void) autoReconnectChanged:(NSNotification*)aNote
{
	[autoReconnectButton setState:[model autoReconnect]];
}


- (void) remoteHostChanged:(NSNotification*)aNotification
{
	[remoteHostField setStringValue:[model remoteHost]];
}

- (void) remotePortChanged:(NSNotification*)aNotification
{
	[remotePortField setIntValue:[model remotePort]];
}

-(void)runStatusChanged:(NSNotification*)aNotification
{
	if([model runningState] == eRunInProgress){
		[runProgress startAnimation:self];
		[statusField setStringValue:[model isConnected]?@"Running":@"???"];
		[runBar setIndeterminate:!([model timedRun])];
		[runBar setDoubleValue:0];
		[runBar startAnimation:self];
	}
	else if([model runningState] == eRunStopped){
		[runProgress stopAnimation:self];
		[runBar setDoubleValue:0];
		[runBar stopAnimation:self];
		[runBar setIndeterminate:NO];
		[statusField setStringValue:[model isConnected]?@"Stopped":@"???"];
	}
	else if([model runningState] == eRunStarting || [model runningState] == eRunStopping){
		[runProgress startAnimation:self];
		if([model runningState] == eRunStarting)[statusField setStringValue:[model isConnected]?@"Starting..":@"???"];
		else [statusField setStringValue:[model isConnected]?@"Stopping..":@"???"];
	}
    [self updateButtons];
    
}

-(void)timeToGoChanged:(NSNotification*)aNotification
{
	if([model timedRun]){
		int hr,min,sec;
		NSTimeInterval timeToGo = [model timeToGo];
		hr = timeToGo/3600;
		min =(timeToGo - hr*3600)/60;
		sec = timeToGo - hr*3600 - min*60;
		[timeToGoField setStringValue:[NSString stringWithFormat:@"%02d:%02d:%02d",hr,min,sec]];
	}
	else {
		[timeToGoField setStringValue:@"---"];
	}
}

- (void) runNumberChanged:(NSNotification*)aNotification
{
	[runNumberField setStringValue:[model fullRunNumberString]];
}

- (void) timeLimitStepperChanged:(NSNotification*)aNotification
{
	[self updateStepper:timeLimitStepper setting:[model timeLimit]];
	[self updateIntText:timeLimitField setting:[model timeLimit]];
}


- (void) repeatRunChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:repeatRunCB setting:[model repeatRun]];
}

- (void) timedRunChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:timedRunCB setting:[model timedRun]];
	[repeatRunCB setEnabled: [model timedRun]];
	[timeLimitField setEnabled:[model timedRun]];
	[timeLimitStepper setEnabled:[model timedRun]];
}


- (void) elapsedTimeChanged:(NSNotification*)aNotification
{
	int hr,min,sec;
	NSTimeInterval elapsedTime = [model elapsedTime];
	hr = elapsedTime/3600;
	min =(elapsedTime - hr*3600)/60;
	sec = elapsedTime - hr*3600 - min*60;
	[elapsedTimeField setStringValue:[NSString stringWithFormat:@"%02d:%02d:%02d",hr,min,sec]];
	
	if([model timedRun]){
		double timeLimit = [model timeLimit];
		double elapsedTime = [model elapsedTime];
		if([model isRunning]){
			[runBar setDoubleValue:100*elapsedTime/timeLimit];
		}
		else {
			[runBar setDoubleValue:0];
		}
	}
	
	elapsedTime = [model elapsedSubRunTime];
	hr = elapsedTime/3600;
	min =(elapsedTime - hr*3600)/60;
	sec = elapsedTime - hr*3600 - min*60;
	[elapsedSubRunTimeField setStringValue:[NSString stringWithFormat:@"%02d:%02d:%02d",hr,min,sec]];

	if([model runningState] == eRunBetweenSubRuns){
		elapsedTime = [model elapsedBetweenSubRunTime];
		hr = elapsedTime/3600;
		min =(elapsedTime - hr*3600)/60;
		sec = elapsedTime - hr*3600 - min*60;
		[elapsedBetweenSubRunTimeField setStringValue:[NSString stringWithFormat:@"%02d:%02d:%02d",hr,min,sec]];
	}
	else {
		[elapsedBetweenSubRunTimeField setStringValue:@"---"];
	}
}

-(void) startTimeChanged:(NSNotification*)aNotification
{
	[timeStartedField setObjectValue:[model startTime]];
}

-(void) quickStartChanged:(NSNotification *)notification
{
	[self updateTwoStateCheckbox:quickStartCB setting:[model quickStart]];
	[self updateButtons];
}

-(void) offlineChanged:(NSNotification *)notification
{
	[self updateTwoStateCheckbox:offlineCB setting:[model offline]];
	[self updateButtons];
}

#pragma  mark ¥¥¥Actions
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORRemoteRunLock to:secure];
    [lockButton setEnabled:secure];
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORRemoteRunLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) connectAction:(id)sender
{
    [self endEditing];
    if([model isConnected]){
        [model connectSocket:NO];
    }
    else {
        [model connectSocket:YES];
    }
}

- (IBAction) prepareForSubRunAction:(id)sender
{
    [self endEditing];
    [model performSelector:@selector(prepareForNewSubRun)withObject:nil afterDelay:.1];
}

- (IBAction) startNewSubRunAction:(id)sender
{
    [self endEditing];
    [model performSelector:@selector(startNewSubRun)withObject:nil afterDelay:.1];
}

-(IBAction)startRunAction:(id)sender
{
    [self endEditing];
    [statusField setStringValue:[model isConnected]?@"Starting...":@"???"];
    [startRunButton setEnabled:NO];
    [restartRunButton setEnabled:NO];
    [stopRunButton setEnabled:NO];
    [model performSelector:@selector(startRun)withObject:nil afterDelay:.1];
}

-(IBAction)newRunAction:(id)sender
{
    [self endEditing];
    [statusField setStringValue:[model isConnected]?@"Restart...":@"???"];
    [startRunButton setEnabled:NO];
    [restartRunButton setEnabled:NO];
    [stopRunButton setEnabled:NO];
    [model performSelector:@selector(restartRun)withObject:nil afterDelay:0];
}

-(IBAction)stopRunAction:(id)sender
{
    [self endEditing];
    [statusField setStringValue:[model isConnected]?@"Stopping...":@"???"];
    [model performSelector:@selector(haltRun)withObject:nil afterDelay:.1];
}


-(IBAction)quickStartCBAction:(id)sender
{
    if([model quickStart] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Quick Start"];
        [model setQuickStart:[sender intValue]];
    }
}

-(IBAction)offlineCBAction:(id)sender
{
    if([model offline] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Offline"];
        [model setOffline:[sender intValue]];
    }
}

-(IBAction)timeLimitStepperAction:(id)sender
{
    if([model timeLimit] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Run Time Limit"];
        [model setTimeLimit:[sender intValue]];
    }
}

-(IBAction)timeLimitTextAction:(id)sender
{
    if([model timeLimit] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Run Time Limit"];
        [model setTimeLimit:[sender intValue]];
    }
}


-(IBAction)timedRunCBAction:(id)sender
{
    if([model timedRun] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Timed Run"];
        [model setTimedRun:[sender intValue]];
    }
}

-(IBAction)repeatRunCBAction:(id)sender
{
    if([model repeatRun] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Repeat Run"];
        [model setRepeatRun:[sender intValue]];
    }
}

- (IBAction) remoteHostAction:(id)sender
{
    [model setRemoteHost:[sender stringValue]];    
}

- (IBAction) remotePortAction:(id)sender
{
    [model setRemotePort:[sender intValue]];    
    
}

- (IBAction) connectAtStartAction:(id)sender
{
	[[self model] setConnectAtStart:[sender state]];
}

- (IBAction) autoReconnectAction:(id)sender
{
	[[self model] setAutoReconnect:[sender state]];
}

- (IBAction) selectStartUpScript:(id)sender
{
	[model setSelectedStartScriptName:[sender titleOfSelectedItem]];
}

- (IBAction) selectShutDownScript:(id)sender
{
	[model setSelectedShutDownScriptName:[sender titleOfSelectedItem]];
}

- (IBAction) resynce:(id)sender
{
	[model fullUpdate];
}

@end

