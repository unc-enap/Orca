//
//  ORRunController.m
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
#import "ORRunController.h"
#import "ORRunModel.h"
#import "StopLightView.h"
#import "ORRunScriptModel.h"
#import "ORCardContainerView.h"

@interface ORRunController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _changeRunNumberDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _chooseDirAlertDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;

#endif
- (void) populatePopups;
@end

@implementation ORRunController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"RunControl"];
    return self;
}
- (void) dealloc
{
    if(retainingRunNotice)[runModeNoticeView release];
    [super dealloc];
}


- (void) awakeFromNib
{
    [runProgress setStyle:NSProgressIndicatorSpinningStyle];
    [runBar setIndeterminate:NO];
	[groupView setGroup:model];
    
    [super awakeFromNib];
    [self performSelector:@selector(updateWithCurrentRunNumber)withObject:self afterDelay:0];
    [self updateButtons];
    

    NSPoint newScrollOrigin=NSMakePoint(0.0,NSMaxY([[scriptScrollView documentView] frame])
                                    -NSHeight([[scriptScrollView contentView] bounds]));
        
    [[scriptScrollView contentView] scrollToPoint: newScrollOrigin];
    [scriptScrollView reflectScrolledClipView: [scriptScrollView contentView]];

    int i=0;
	int row;
    int column;
	for(row=0;row<4;row++){
        for(column=0;column<4;column++){
            [[runTypeMatrix cellAtRow:row column:column] setTag:i];
            i++;
        }
	}
}

- (ORGroupView *)groupView
{
    return [self groupView];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [groupView setDrawSlotNumbers:YES];
    [groupView setDrawSlots:YES];
    [groupView setGroup:(ORGroup*)aModel];
}

#pragma mark ¥¥¥Accessors


#pragma mark ¥¥¥Interface Management

- (void) selectedRunTypeScriptChanged:(NSNotification*)aNote
{
	[runTypeScriptPU selectItemAtIndex: [model selectedRunTypeScript]];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];
   
    [notifyCenter addObserver: self
                     selector: @selector(timedRunChanged:)
                         name: ORRunTimedRunChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(repeatRunChanged:)
                         name: ORRunRepeatRunChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(elapsedTimesChanged:)
                         name: ORRunElapsedTimesChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(startTimeChanged:)
                         name: ORRunStartTimeChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(timeToGoChanged:)
                         name: ORRunTimeToGoChangedNotification
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(runStatusChanged:)
                         name: ORRunStatusChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(runNumberChanged:)
                         name: ORRunNumberChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(runNumberDirChanged:)
                         name: ORRunNumberDirChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(runModeChanged:)
                         name: ORRunModeChangedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runTypeChanged:)
                         name: ORRunTypeChangedNotification
                       object: model];
 
	[notifyCenter addObserver: self
                     selector: @selector(runTypeChanged:)
                         name: ORRunTypeChangedNotification
                       object: model];
	
	
    [notifyCenter addObserver: self
                     selector: @selector(remoteControlChanged:)
                         name: ORRunRemoteControlChangedNotification
                       object: [self document]];
    
    [notifyCenter addObserver: self
                     selector: @selector(runNumberLockChanged:)
                         name: ORRunNumberLock
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runTypeLockChanged:)
                         name: ORRunTypeLock
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(quickStartChanged:)
                         name: ORRunQuickStartChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(definitionsFileChanged:)
                         name: ORRunDefinitionsFileChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(vetosChanged:)
                         name: ORRunVetosChanged
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(populatePopups)
                         name: ORGroupObjectsAdded
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(populatePopups)
                         name: ORGroupObjectsRemoved
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(populatePopups)
                         name: ORScriptIDEModelNameChanged
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(startUpScriptStateChanged:)
                         name: ORRunModelStartScriptStateChanged
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(shutDownScriptStateChanged:)
                         name: ORRunModelShutDownScriptStateChanged
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(startUpScriptChanged:)
                         name: ORRunModelStartScriptChanged
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(shutDownScriptChanged:)
                         name: ORRunModelShutDownScriptChanged
                       object: nil];	

    [notifyCenter addObserver: self
                     selector: @selector(timeLimitChanged:)
                         name: ORRunTimeLimitChangedNotification
                       object: nil];	

    [notifyCenter addObserver: self
                     selector: @selector(drawerDidOpen:)
                         name: NSDrawerDidOpenNotification
                       object: nil];	
	
    [notifyCenter addObserver: self
                     selector: @selector(drawerDidClose:)
                         name: NSDrawerDidCloseNotification
                       object: nil];	
    
    [notifyCenter addObserver: self
                     selector: @selector(numberOfWaitsChanged:)
                         name: ORRunModelNumberOfWaitsChanged
                       object: nil];    
	
    [notifyCenter addObserver : self
                     selector : @selector(selectedRunTypeScriptChanged:)
                         name : ORRunModelSelectedRunTypeScriptChanged
						object: model];

}



- (void) updateWindow
{
    [super updateWindow];
	[self populatePopups];
    [self runStatusChanged:nil];
    [self timedRunChanged:nil];
    [self repeatRunChanged:nil];
    [self elapsedTimesChanged:nil];
    [self startTimeChanged:nil];
    [self runNumberChanged:nil];
    [self runNumberDirChanged:nil];
    [self runModeChanged:nil];
    [self runTypeChanged:nil];
    [self remoteControlChanged:nil];
    [self runNumberLockChanged:nil];
    [self runTypeLockChanged:nil];
    [self quickStartChanged:nil];
    [self definitionsFileChanged:nil];
	[self startUpScriptStateChanged:nil];
	[self shutDownScriptStateChanged:nil];
	[self startUpScriptChanged:nil];
	[self shutDownScriptChanged:nil];
	[self vetosChanged:nil];
	[self timeLimitChanged:nil];
    [self numberOfWaitsChanged:nil];
    [groupView setNeedsDisplay:YES];
	[self selectedRunTypeScriptChanged:nil];
}


- (void) groupChanged:(NSNotification*)note
{
	[self updateWindow];
}

- (void) updateButtons
{
	BOOL anyVetos = [[ORGlobal sharedGlobal] anyVetosInPlace];
	BOOL running  = ([model runningState] == eRunInProgress);
	
	[startUpScripts setEnabled:!running];
	[shutDownScripts setEnabled:!running];
	[openStartScriptButton setEnabled:[model startScript]!=nil]; 
	[openShutDownScriptButton setEnabled:[model shutDownScript]!=nil]; 
	
	[runModeMatrix setEnabled:![model remoteControl] && !running && [model runningState] != eRunStarting && [model runningState] != eRunStopping];

    if([model remoteControl]){
        [startRunButton setEnabled:NO];
        [restartRunButton setEnabled:NO];
        [stopRunButton setEnabled:NO];
        [timedRunCB setEnabled:NO];
        [repeatRunCB setEnabled:NO];
        [timeLimitField setEnabled:NO];
		[quickStartCB setEnabled:NO];
		[startUpScripts setEnabled:NO];
		[shutDownScripts setEnabled:NO];
    }
    else {
	
		[quickStartCB setEnabled:YES];
        int n = [model waitRequestersCount];
        if(n>0){
            [startRunButton setEnabled:NO];
            [endSubRunButton setEnabled:NO];
            [startSubRunButton setEnabled:NO];
            [restartRunButton setEnabled:NO];
            [stopRunButton setEnabled:NO];
       
        }
        else {
            if([model runningState] == eRunInProgress){
                [startRunButton setEnabled:NO];
                [endSubRunButton setEnabled:YES];
                [startSubRunButton setEnabled:NO];
                [restartRunButton setEnabled:YES];
                [stopRunButton setEnabled:YES];
                [timedRunCB setEnabled:NO];
                [timeLimitField setEnabled:NO];
                [repeatRunCB setEnabled:[model timedRun]];
                [startUpScripts setEnabled:NO];
                [shutDownScripts setEnabled:NO];
            }
            else if([model runningState] == eRunStopped){
                [startRunButton setEnabled:anyVetos?NO:YES];
                [endSubRunButton setEnabled:NO];
                [startSubRunButton setEnabled:NO];
                [restartRunButton setEnabled:NO];
                [stopRunButton setEnabled:NO];
                [timedRunCB setEnabled:YES];
                [timeLimitField setEnabled:[model timedRun]];
                [repeatRunCB setEnabled:[model timedRun]];
                [startUpScripts setEnabled:YES];
                [shutDownScripts setEnabled:YES];
            }
            else if([model runningState] == eRunStarting || [model runningState] == eRunStopping){
                [startRunButton setEnabled:NO];
                [endSubRunButton setEnabled:NO];
                [startSubRunButton setEnabled:NO];
                [restartRunButton setEnabled:NO];
                [stopRunButton setEnabled:NO];
                [timedRunCB setEnabled:NO];
                [timeLimitField setEnabled:NO];
                [repeatRunCB setEnabled:NO];
                [startUpScripts setEnabled:NO];
                [shutDownScripts setEnabled:NO];
            }
            else if([model runningState] == eRunBetweenSubRuns){
                [endSubRunButton setEnabled:NO];
                [startSubRunButton setEnabled:YES];
                [restartRunButton setEnabled:YES];
                [stopRunButton setEnabled:YES];
            }
        }
    }
}

- (void) numberOfWaitsChanged:(NSNotification*)aNote
{
    int n = [model waitRequestersCount];
    [showWaitRequestersButton setHidden:n==0 && ([waitRequestersDrawer state] == NSDrawerClosedState)];
    [forceClearWaitsButton setEnabled:n>0];
    [abortRunFromWaitButton setEnabled:n>0];
    [waitCountField setIntValue:n];
    [waitCountField1 setIntValue:n];
    [waitCountField2 setStringValue:n==0?@"":@"Waits In Place"];
    [waitRequestersTableView reloadData];
    [self updateButtons];
}

- (void) timeLimitChanged:(NSNotification*)aNotification
{
	[timeLimitField setIntValue:[model timeLimit]];
}

- (void) startUpScriptChanged:(NSNotification*)aNotification
{
	NSString* selectedItemName = [[model startScript] identifier];
	if(!selectedItemName || ![startUpScripts itemWithTitle:selectedItemName])selectedItemName = @"---";
	[startUpScripts selectItemWithTitle:selectedItemName]; 
	[self updateButtons];
}

- (void) shutDownScriptChanged:(NSNotification*)aNotification
{
	NSString* selectedItemName = [[model shutDownScript] identifier];
	if(!selectedItemName || ![shutDownScripts itemWithTitle:selectedItemName])selectedItemName = @"---";
	[shutDownScripts selectItemWithTitle:selectedItemName]; 
	[self updateButtons];
}

- (void) startUpScriptStateChanged:(NSNotification*)aNotification
{
	[startUpScriptStateField setStringValue:[model startScriptState]];
	[self updateButtons];
}

- (void) shutDownScriptStateChanged:(NSNotification*)aNotification
{
	[shutDownScriptStateField setStringValue:[model shutDownScriptState]];
	[self updateButtons];
}


- (void) runStatusChanged:(NSNotification*)aNotification
{
	if([model runningState] == eRunInProgress){
		[runProgress startAnimation:self];
		if(![model runPaused])[statusField setStringValue:[[ORGlobal sharedGlobal] runModeString]];
		else [statusField setStringValue:@"Paused"];
		[runBar setIndeterminate:!([model timedRun] && ![model remoteControl])];
		[runBar setDoubleValue:0];
		[runBar startAnimation:self];
		[lightBoardView setState:kGoLight];
	}
	else if([model runningState] == eRunStopped){
		[runProgress stopAnimation:self];
		[runBar setDoubleValue:0];
		[runBar stopAnimation:self];
		[runBar setIndeterminate:NO];
		[statusField setStringValue:@"Stopped"];
		[remoteControlCB setEnabled:YES];
		[lightBoardView setState:kStoppedLight];
	}
	else if([model runningState] == eRunStarting || [model runningState] == eRunStopping || [model runningState] == eRunBetweenSubRuns){
		[runProgress startAnimation:self];
		if([model runningState] == eRunStarting)[statusField setStringValue:[self getStartingString]];
		else {
			if([model runningState] == eRunBetweenSubRuns)	[statusField setStringValue:[self getBetweenSubrunsString]];
			else											[statusField setStringValue:[self getStoppingString]];
		}
		[lightBoardView setState:kCautionLight];
	}
    [self updateButtons];
	[endOfRunStateField setStringValue:[model endOfRunState]];
    
}

- (void) vetosChanged:(NSNotification*)aNotification
{
	int vetoCount = [[ORGlobal sharedGlobal] vetoCount];
	[vetoCountField setIntValue: vetoCount]; 
	[listVetosButton setHidden:vetoCount==0];
	[vetoedTextField setStringValue:vetoCount?@"Vetoed":@""];
	[self updateButtons];
}

- (void) timeToGoChanged:(NSNotification*)aNotification
{
	if([model timedRun] && ![model remoteControl]){
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
	[runNumberText setIntValue:[model runNumber]];
	if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
		[runNumberField setStringValue:[model fullRunNumberString]];
	}
	else {
		[runNumberField setStringValue: @"Offline"];
	}
}

- (void) runNumberDirChanged:(NSNotification*)aNotification
{
	if([model dirName]!=nil)[runNumberDirField setStringValue: [model dirName]];
}


- (void) repeatRunChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:repeatRunCB setting:[model repeatRun]];
	[endOfRunStateField setStringValue:[model endOfRunState]];
}



- (void) timedRunChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:timedRunCB setting:[model timedRun]];
	[repeatRunCB setEnabled: [model timedRun]];
	[timeLimitField setEnabled:[model timedRun]];
	[endOfRunStateField setStringValue:[model endOfRunState]];
}


- (void) elapsedTimesChanged:(NSNotification*)aNotification
{
	[elapsedRunTimeField setStringValue:[model elapsedTimeString:[model elapsedRunTime]]];
	[elapsedSubRunTimeField setStringValue:[model elapsedTimeString:[model elapsedSubRunTime]]];
	if([model runningState] == eRunBetweenSubRuns){
		[elapsedBetweenSubRunTimeField setStringValue:[model elapsedTimeString:[model elapsedBetweenSubRunTime]]];
	}
	else {
		[elapsedBetweenSubRunTimeField setStringValue:@"---"];
	}
	[endOfRunStateField setStringValue:[model endOfRunState]];
	if([model timedRun]){
		double timeLimit = [model timeLimit];
		double elapsedRunTime = [model elapsedRunTime];
		[runBar setDoubleValue:100*elapsedRunTime/timeLimit];
	}
	
}

- (void) startTimeChanged:(NSNotification*)aNotification
{
	[timeStartedField setObjectValue:[[model startTime] descriptionFromTemplate:@"MM/dd/yy HH:mm:ss"]];
}

- (void) runModeChanged:(NSNotification *)notification
{
    [runModeMatrix selectCellWithTag: [[ORGlobal sharedGlobal] runMode]];
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [runModeNoticeView selectTabViewItemAtIndex:1];
    }
    else {
        [runModeNoticeView selectTabViewItemAtIndex:0];
    }
    [self runNumberChanged:nil];
}

- (void) runTypeChanged:(NSNotification *)notification
{
	unsigned long runType = [model runType];
	int i;
	for(i=0;i<32;i++){
		[[runTypeMatrix cellWithTag:i] setState:(runType &(1UL<<i))!=0];
	}
}

- (void) remoteControlChanged:(NSNotification *)notification
{
	[self updateTwoStateCheckbox:remoteControlCB setting:[model remoteControl]];
	[self updateButtons];
}

- (void) quickStartChanged:(NSNotification *)notification
{
	[self updateTwoStateCheckbox:quickStartCB setting:[model quickStart]];
	[self updateButtons];
}

- (void) definitionsFileChanged:(NSNotification *)notification
{
	NSString* path = [[model definitionsFilePath]stringByAbbreviatingWithTildeInPath];
	if(path == nil){
		path = @"---";
	}
	[definitionsFileTextField setStringValue:path];
	
	[self setupRunTypeNames];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORRunNumberLock to:secure];
    [gSecurity setLock:ORRunTypeLock to:secure];
    [runNumberLockButton setEnabled:secure];
    [runTypeLockButton setEnabled:secure];
}

- (void) runNumberLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORRunNumberLock];
    [runNumberLockButton setState: locked];
    [runNumberText setEnabled: !locked];
    [runNumberDirButton setEnabled: !locked];
}

- (void) runTypeLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORRunTypeLock];
    [runTypeLockButton setState: locked];
    //[runTypeMatrix setEnabled: !locked];
    [runDefinitionsButton setEnabled:!locked];
    [clearAllTypesButton setEnabled:!locked];
}

#pragma  mark ¥¥¥Actions
- (IBAction) selectedRunTypeScriptPUAction:(id)sender
{
    [model setSelectedRunTypeScript:[sender indexOfSelectedItem]];
}
- (IBAction) startNewSubRunAction:(id)sender
{
	if(!wasInMaintenance){
		[model setMaintenanceRuns:NO];
	}
	[model startNewSubRun];
}

- (IBAction) prepareForSubRunAction:(id)sender
{
	if([model runType] & eMaintenanceRunType){
		wasInMaintenance = YES;
	}
	else {
		wasInMaintenance = NO;
		[model setMaintenanceRuns:YES];
	}
	[model prepareForNewSubRun];
}

- (IBAction) openStartScript:(id)sender
{
	[[model startScript] makeMainController];
}

- (IBAction) openShutDownScript:(id)sender
{
	[[model shutDownScript] makeMainController];
}


- (IBAction) startRunAction:(id)sender
{
	if([[model document] isDocumentEdited]){
		[[model document] afterSaveDo:@selector(startRun) withTarget:self];
        [[model document] saveDocument:nil];
    }
	else [self startRun];
}

- (NSString*) getStartingString
{
    NSString* s;
    if([model waitRequestersCount]==0)s = @"Starting...";
    else s = @"Starting (Waiting)";
    return s;
}

- (NSString*) getRestartingString
{
    NSString* s;
    if([model waitRequestersCount]==0)s = @"Restart...";
    else s = @"Restarting (Waiting)";
    return s;
}
- (NSString*) getStoppingString
{
    NSString* s;
    if([model waitRequestersCount]==0)s = @"Stopping...";
    else s = @"Stopping (Waiting)";
    return s;
}
- (NSString*) getBetweenSubrunsString
{
    NSString* s;
    if([model waitRequestersCount]==0)s = @"Between Sub Runs..";
    else s = @"'TweenSubRuns (Waiting)";
    return s;
}

- (void) startRun
{
	[self endEditing];
	[statusField setStringValue:[self getStartingString]];
	[startRunButton setEnabled:NO];
	[endSubRunButton setEnabled:NO];
	[startSubRunButton setEnabled:NO];
	[restartRunButton setEnabled:NO];
	[stopRunButton setEnabled:NO];
    [model setIgnoreSelectedScript:NO];
	[model performSelector:@selector(startRun)withObject:nil afterDelay:.1];
}

- (IBAction) newRunAction:(id)sender
{
    [self endEditing];
    [statusField setStringValue:[self getRestartingString]];
    [startRunButton setEnabled:NO];
    [restartRunButton setEnabled:NO];
	[stopRunButton setEnabled:NO];
	[endSubRunButton setEnabled:YES];
	[startSubRunButton setEnabled:NO];
    [model setForceRestart:YES];
    [model performSelector:@selector(stopRun) withObject:nil afterDelay:0];
}

- (IBAction) stopRunAction:(id)sender
{
    [model quitSelectedRunScript];
    [self endEditing];
    [statusField setStringValue:[self getStoppingString]];
    [model performSelector:@selector(haltRun)withObject:nil afterDelay:.1];
}

- (IBAction) remoteControlAction:(id)sender
{
    if([model remoteControl] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Run Remote Control"];
        [model setRemoteControl:[sender intValue]];
        if(![model remoteControl]){
            [model setRemoteInterface:NO];
        }
    }
}

- (IBAction) quickStartCBAction:(id)sender
{
    if([model quickStart] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Quick Start"];
        [model setQuickStart:[sender intValue]];
    }
}


- (IBAction) timeLimitTextAction:(id)sender
{
    if([model timeLimit] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Run Time Limit"];
        [model setTimeLimit:[sender intValue]];
    }
}


- (IBAction) timedRunCBAction:(id)sender
{
    if([model timedRun] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Timed Run"];
        [model setTimedRun:[sender intValue]];
    }
}

- (IBAction) repeatRunCBAction:(id)sender
{
    if([model repeatRun] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Repeat Run"];
        [model setRepeatRun:[sender intValue]];
    }
}

- (IBAction) runNumberAction:(id)sender
{
    [self endEditing];
    if([runNumberText intValue] != [model runNumber]){
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:    @"Do you REALLY want to change the Run Number?"];
        [alert setInformativeText:@"Having a unique run number is important for most experiments. If you change it you may end up with data with duplicate run numbers."];
        [alert addButtonWithTitle:@"Yes/Change It"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
            if(result == NSAlertFirstButtonReturn){
                //have to do this after the alert actually closes, hence the delay to the next cycle of the event loop
                [self performSelector:@selector(deferredRunNumberChange) withObject:nil afterDelay:0];
            }
            else {
                [runNumberText setIntValue:[model runNumber]];
            }
        }];
#else
        NSBeginAlertSheet(@"Do you REALLY want to change the Run Number?",
                          @"Cancel",
                          @"Yes/Change It",
                          nil,[self window],
                          self,
                          @selector(_changeRunNumberDidEnd:returnCode:contextInfo:),
                          nil,
                          nil,@"Having a unique run number is important for most experiments. If you change it you may end up with data with duplicate run numbers.");
#endif
    }
}


- (void) deferredRunNumberChange
{
    [model setRunNumber:[runNumberText intValue]];
}

- (IBAction) runModeAction:(id)sender
{
    int tag = [[runModeMatrix selectedCell] tag];
    if(tag != [[ORGlobal sharedGlobal] runMode]){
        [[self undoManager] setActionName: @"Set Run Mode"];
		[model setOfflineRun:tag];
    }
}

- (IBAction) chooseDir:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Do you REALLY want to change the Run Number Folder?"];
    [alert setInformativeText:@"Having a unique run number is important for most experiments. If you change the run number folder you may end up with duplicate run numbers."];
    [alert addButtonWithTitle:@"Yes/Select New Location"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if(result == NSAlertFirstButtonReturn){
            //have to do this after the alert actually closes, hence the delay to the next cycle of the event loop
            [self performSelector:@selector(deferredChooseDir) withObject:nil afterDelay:0];
        }
    }];
#else
    NSBeginAlertSheet(@"Do you REALLY want to change the Run Number Folder?",
                      @"Cancel",
                      @"Yes/Select New Location",
                      nil,[self window],
                      self,
                      @selector(_chooseDirAlertDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Having a unique run number is important for most experiments. If you change the run number folder you may end up with duplicate run numbers.");
#endif

}


- (void) deferredChooseDir
{
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model definitionsFilePath]){
        startDir = [[model definitionsFilePath]stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* dirName = [[[openPanel URL]path] stringByAbbreviatingWithTildeInPath];
            [model setDirName:dirName];
        }
    }];
}

- (IBAction) definitionsFileAction:(id)sender
{
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model definitionsFilePath]){
        startDir = [[model definitionsFilePath]stringByDeletingLastPathComponent];
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
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setDefinitionsFilePath:[[openPanel URL]path]];
            if(![model readRunTypeNames]){
                NSLogColor([NSColor redColor],@"Unable to parse <%@> as a run type def file.\n",[[[[openPanel URLs] objectAtIndex:0]path] stringByAbbreviatingWithTildeInPath]);
                NSLogColor([NSColor redColor],@"File must be list of items of the form: itemNumber,itemName\n");	
                [model setDefinitionsFilePath:nil];
            }
            else {
                [self definitionsFileChanged:nil];
            }
        }
    }];
}

- (IBAction) runTypeAction:(id)sender
{
    short i     = [[sender selectedCell] tag];
    BOOL state  = [[sender selectedCell] state];
    unsigned long currentRunMask = [model runType];
    if(state) currentRunMask |= (1L<<i);
    else      currentRunMask &= ~(1L<<i);
    
    [model setRunTypeAndModifySavedRunType:currentRunMask];
}

- (IBAction) clearRunTypeAction:(id)sender
{
    [model setRunType:[model runType] & (eMaintenanceRunType)];
}

- (IBAction) runNumberLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORRunNumberLock to:[sender intValue] forWindow:[runNumberDrawer parentWindow]];
}

- (IBAction) runTypeLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORRunTypeLock to:[sender intValue] forWindow:[runTypeDrawer parentWindow]];
}

- (IBAction) listVetoAction:(id)sender
{
	[[ORGlobal sharedGlobal] listVetoReasons];
}

- (IBAction) selectStartUpScript:(id)sender
{
	NSString* name = [sender titleOfSelectedItem];
	NSArray* runScripts = [[model document] collectObjectsOfClass:[ORRunScriptModel class]];
	ORRunScriptModel* obj;
	NSEnumerator* e = [runScripts objectEnumerator];
	ORRunScriptModel* selectedObj = nil;
	while(obj = [e nextObject]){
		if([name isEqualToString:[obj identifier]]){
			selectedObj = obj;
			break;
		}
	}
	[model setStartScript:selectedObj];
}

- (IBAction) selectShutDownScript:(id)sender
{
	NSString* name = [sender titleOfSelectedItem];
	NSArray* runScripts = [[model document] collectObjectsOfClass:[ORRunScriptModel class]];
	ORRunScriptModel* obj;
	NSEnumerator* e = [runScripts objectEnumerator];
	ORRunScriptModel* selectedObj = nil;
	while(obj = [e nextObject]){
		if([name isEqualToString:[obj identifier]]){
			selectedObj = obj;
			break;
		}
	}
	[model setShutDownScript:selectedObj];
}

- (IBAction) forceClearWaitsAction:(id)sender
{
    [model forceClearWaits];
}
- (IBAction) abortRunFromWaitAction:(id)sender
{
    [model abortRunFromWait];
}

- (void) updateWithCurrentRunNumber
{
    [model getCurrentRunNumber];
    [self updateWindow];
}

- (void) drawerWillOpen:(NSNotification *)notification
{
    [model getCurrentRunNumber];
    [self updateWindow];
}

- (void) drawerDidOpen:(NSNotification *)notification
{
	
    if([notification object] == runNumberDrawer){
        [runNumberButton setTitle:@"Close"];
        [runTypeDrawer close];
    }
    else if([notification object] == runTypeDrawer){
        [runTypeButton setTitle:@"Close"];
        [runNumberDrawer close];
    }
    else if([notification object] == waitRequestersDrawer){
        [showWaitRequestersButton setTitle:@"Close"];
    }
    else if([notification object] == scriptsDrawer){
        [showScriptsButton setTitle:@"Close"];
    }

}

- (void) drawerDidClose:(NSNotification *)notification
{
    if([notification object] == runNumberDrawer){
        [runNumberButton setTitle:@"Run Number..."];
    }
    else if([notification object] == runTypeDrawer){
        [runTypeButton setTitle:@"Run Type..."];
    }
    else if([notification object] == waitRequestersDrawer){
        [showWaitRequestersButton setTitle:@"Show Waits..."];
        [self numberOfWaitsChanged:nil];
    }
    else if([notification object] == scriptsDrawer){
        [showScriptsButton setTitle:@"Scripts..."];
    }
}

- (void) setupRunTypeNames
{
    NSArray* theNames = [model runTypeNames];
    int n = [theNames count];
    int i;
    if(n){
        for(i=1;i<n;i++){
            [[runTypeMatrix cellWithTag:i] setTitle:[theNames objectAtIndex:i]];
        }
    }
    else {
        for(i=1;i<32;i++){
            [[runTypeMatrix cellWithTag:i] setTitle:[NSString stringWithFormat:@"Bit %d",i]];
        }
    }
}
#pragma mark Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    
	if(aTableView == waitRequestersTableView){
		id addressObj = [model waitRequesterAtIdex:rowIndex];
		return [addressObj valueForKey:[aTableColumn identifier]]; 
	}
	else return nil;
}

// just returns the number of items we have.
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == waitRequestersTableView){
		return [model waitRequestersCount];
	}
	else return 0;
}

@end

@implementation ORRunController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _changeRunNumberDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
        //have to do this after the alert actually closes, hence the delay to the next cycle of the event loop
        [self performSelector:@selector(deferredRunNumberChange) withObject:nil afterDelay:0];
    }
    else {
        [runNumberText setIntValue:[model runNumber]];
    }
}
- (void) _chooseDirAlertDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
        //have to do this after the alert actually closes, hence the delay to the next cycle of the event loop
        [self performSelector:@selector(deferredChooseDir) withObject:nil afterDelay:0];
    }
}
#endif
- (void) populatePopups
{
	[[model undoManager] disableUndoRegistration];
	
	[startUpScripts removeAllItems];
	[shutDownScripts removeAllItems];
	[startUpScripts addItemWithTitle:@"---"];
	[shutDownScripts addItemWithTitle:@"---"];
	[runTypeScriptPU removeAllItems];
    [runTypeScriptPU addItemWithTitle:@"Standard (Manual)"];

	NSArray* runScripts = [[model document] collectObjectsOfClass:[ORRunScriptModel class]];
	for(ORRunScriptModel* obj in runScripts){
		[startUpScripts addItemWithTitle:[obj identifier]]; 
		[shutDownScripts addItemWithTitle:[obj identifier]];
	}
	
    NSArray* runTypeScripts = [model collectObjectsOfClass:[ORRunScriptModel class]];
    NSArray* runTypeSortedBySlot = [runTypeScripts sortedArrayUsingSelector:@selector(compare:)];

    int index = 1;
    for(ORRunScriptModel* obj in runTypeSortedBySlot){
		[runTypeScriptPU addItemWithTitle:[obj identifier]];
        [obj setSelectionIndex:index];
        index++;
    }
    
	NSString* selectedItemName = [[model startScript] identifier];
	if(!selectedItemName || ![startUpScripts itemWithTitle:selectedItemName])selectedItemName = @"---";
	[startUpScripts selectItemWithTitle:selectedItemName]; 
	[self selectStartUpScript:startUpScripts];
	
	selectedItemName = [[model shutDownScript] identifier];
	if(!selectedItemName || ![shutDownScripts itemWithTitle:selectedItemName])selectedItemName = @"---";
	[shutDownScripts selectItemWithTitle:selectedItemName]; 
	[self selectShutDownScript:shutDownScripts];

	[[model undoManager] enableUndoRegistration];
}


@end


