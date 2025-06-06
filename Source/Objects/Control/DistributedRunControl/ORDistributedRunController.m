//
//  ORDistributedRunController.m
//  Orca
//
//  Created by Mark Howe on Apr 22, 2025.
//  Copyright (c) 2025 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Physics Department sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#pragma mark ¥¥¥Imported Files
#import "ZFlowLayout.h"
#import "ORDistributedRunController.h"
#import "ORDistributedRunModel.h"
#import "ORRemoteRunItem.h"
#import "ORRemoteRunItemController.h"
#import "StopLightView.h"

@implementation ORDistributedRunController

#pragma mark ¥¥¥Initialization
- (id) init
{
    self = [super initWithWindowNibName:[self windowNibName]];
    return self;
}

- (void) dealloc
{
    NSArray* allViews = [remoteRunItemContentView subviews];
    [allViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [remoteRunItemControllers release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}
- (NSString*) windowNibName
{
    return @"DistributedRunControl";
}
-(void) awakeFromNib
{
    [super awakeFromNib];

//  [self securityStateChanged:nil];
    NSMutableArray* remoteItems = [model remoteRunItems];
    NSEnumerator* e = [remoteItems objectEnumerator];
    ORRemoteRunItem* anItem;
    while(anItem = [e nextObject]){
        [self addRemoteRunItem:anItem];
    }

    [runBar setIndeterminate:NO];
    
    [self updateView:nil];
}


#pragma mark ¥¥¥Accessors
- (NSView*) remoteRunItemContentView
{
    return remoteRunItemContentView;
}

#pragma mark ¥¥¥Interface Management
-(void)registerNotificationObservers
{

    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(runNumberLockChanged:)
                         name : ORDistributedRunNumberLock
                       object : nil];
                       
    [notifyCenter addObserver: self
                     selector: @selector(timedRunChanged:)
                         name: ORDistributedRunTimedRunChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(repeatRunChanged:)
                         name: ORDistributedRunRepeatRunChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(elapsedTimeChanged:)
                         name: ORDistributedRunElapsedTimeChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(startTimeChanged:)
                         name: ORDistributedRunStartTimeChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(timeToGoChanged:)
                         name: ORDistributedRunTimeToGoChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStatusChanged:)
                         name: ORDistributedRunStatusChanged
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(runTimeLimitChanged:)
                         name: ORDistributedRunTimeLimitChanged
                       object: model];

    [notifyCenter addObserver : self
                     selector : @selector(remoteRunItemAdded:)
                         name : ORRemoteRunItemAdded
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(remoteRunItemRemoved:)
                         name : ORRemoteRunItemRemoved
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(numberConnectedChanged:)
                         name : ORDistributedRunNumberConnectedChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(numberRunningChanged:)
                         name : ORDistributedRunNumberRunningChanged
                       object : model];
 
    [notifyCenter addObserver : self
                     selector : @selector(runNumberChanged:)
                         name : ORDistributedRunNumberChanged
                       object : model];
 
    [notifyCenter addObserver : self
                     selector : @selector(runNumberDirChanged:)
                         name : ORDistributedRunNumberDirChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(scanAndUpdate:)
                         name : ORRemoteRunItemStateChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(scanAndUpdate:)
                         name : ORRemoteRunItemIsConnectedChanged
                       object : nil];
}


-(void) updateWindow
{
    [super updateWindow];
    [self runStatusChanged:nil];
    [self timedRunChanged:nil];
    [self repeatRunChanged:nil];
    [self elapsedTimeChanged:nil];
    [self startTimeChanged:nil];
    [self numberConnectedChanged:nil];
    [self numberRunningChanged:nil];
    [self scanAndUpdate:nil];
    [self runTimeLimitChanged:nil];
    [self runNumberChanged:nil];
    [self runNumberDirChanged:nil];
    [self runNumberLockChanged:nil];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"Distributed Run Control %u",[model uniqueIdNumber]]];
}

- (void) scanAndUpdate:(NSNotification*)aNote
{
    [model scanAndUpdate];
}

- (void) runNumberChanged:(NSNotification*)aNotification
{
    uint32_t aNumber = [model runNumber];
    [runNumberText  setIntegerValue:aNumber]; //in drawer
    [runNumberField setIntegerValue:aNumber]; //in main dialog
}

- (void) numberConnectedChanged:(NSNotification*)aNote
{
    [numberConnectedField setStringValue:[NSString stringWithFormat:@"%ld/%ld Connected",[model numberConnected],(long)[model numberRemoteSystems]]];
    [self updateButtons];
}

- (void) numberRunningChanged:(NSNotification*)aNote
{
    [numberRunningField setStringValue:[NSString stringWithFormat:@"%ld/%ld Running",[model numberRunning],[model numberRemoteSystems]]];
    if([model numberRunning] && ![model timedRun]){
        [runBar startAnimation:self];
    }
    else {
        [runBar stopAnimation:self];
    }
    [self updateButtons];
}

- (void) updateView:(NSNotification*)aNote
{
    [remoteRunItemContentView setNeedsDisplay:YES];
}

-(void) updateButtons
{
    if([model numberConnected] > 0){
        [repeatRunCB setEnabled:YES];
        if([model numberRunning]){
            [startRunButton   setEnabled:NO];
            [stopRunButton    setEnabled:YES];
            [timeLimitField   setEnabled:NO];
            [timedRunCB       setEnabled:NO];
            [lightBoardView setState:kGoLight];
            [connectAllButton    setEnabled:NO];
            [disConnectAllButton setEnabled:NO];

        }
        else {
            [startRunButton   setEnabled:YES];
            [stopRunButton    setEnabled:NO];
            [timeLimitField   setEnabled:YES];
            [timedRunCB       setEnabled:YES];
            [lightBoardView setState:kStoppedLight];
            [connectAllButton    setEnabled:[model numberConnected] != [model numberRemoteSystems]];
            [disConnectAllButton setEnabled:[model numberConnected] <= [model numberRemoteSystems]];

        }
    }
    else {
        [connectAllButton setEnabled:YES];
        [disConnectAllButton setEnabled:NO];
        [startRunButton   setEnabled:NO];
        [stopRunButton    setEnabled:NO];
        [timedRunCB       setEnabled:NO];
        [timeLimitField   setEnabled:NO];
        [repeatRunCB      setEnabled:NO];
    }
}

- (void) remoteRunItemAdded:(NSNotification*)aNote
{
    ORRemoteRunItem* anItem = [[aNote userInfo] objectForKey:@"RemoteRunItem"];
    [self addRemoteRunItem:anItem];
}

- (void) remoteRunItemRemoved:(NSNotification*)aNote
{
    ORRemoteRunItem* anItem = [[aNote userInfo] objectForKey:@"RemoteRunItem"];
    [self removeRemoteRunItem:anItem];
}

- (void) runStatusChanged:(NSNotification*)aNotification
{
    if([model isRunning] && [model timedRun]){
        [runBar startAnimation:self];
    }
    else {
        [runBar stopAnimation:self];
    }
}

- (void) runTimeLimitChanged:(NSNotification*)aNotification
{
    [timeLimitField setIntValue:[model timeLimit]];
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

- (void) repeatRunChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:repeatRunCB setting:[model repeatRun]];
}

- (void) timedRunChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:timedRunCB setting:[model timedRun]];
	[repeatRunCB setEnabled: [model timedRun]];
	[timeLimitField setEnabled:[model timedRun]];
}

- (void) elapsedTimeChanged:(NSNotification*)aNotification
{
	NSTimeInterval elapsedTime = [model elapsedTime];
	int hr = elapsedTime/3600;
	int min =(elapsedTime - hr*3600)/60;
	int sec = elapsedTime - hr*3600 - min*60;
	[elapsedTimeField setStringValue:[NSString stringWithFormat:@"%02d:%02d:%02d",hr,min,sec]];
	
	if([model timedRun]){
		double timeLimit = [model timeLimit];
		double elapsedTime = [model elapsedTime];
		if([model isRunning]){
            [runBar setIndeterminate:NO];
			[runBar setDoubleValue:100*elapsedTime/timeLimit];
		}
		else {
			[runBar setDoubleValue:0];
		}
	}
    else {
        [runBar setIndeterminate:YES];
    }
}

-(void) startTimeChanged:(NSNotification*)aNotification
{
    [timeStartedField setObjectValue:[[model startTime] descriptionFromTemplate:@"MM/dd/yy HH:mm:ss"]];
    
}
//----------------------------------------------------
//drawer delegate methods
- (void) drawerWillOpen:(NSNotification *)notification
{
    [self updateWindow];
}

- (void) drawerDidOpen:(NSNotification *)notification
{
    if([notification object] == runNumberDrawer){
        [runNumberButton setTitle:@"Close"];
    }
}
- (void) drawerDidClose:(NSNotification *)notification
{
    if([notification object] == runNumberDrawer){
        [runNumberButton setTitle:@"Run Number..."];
    }
}
//----------------------------------------------------

- (void) runNumberLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORDistributedRunNumberLock];
    [runNumberLockButton  setState: locked];
    [runNumberText        setEnabled: !locked];
    [runNumberDirButton   setEnabled: !locked];
    [runNumberApplyButton setEnabled: !locked];
}

- (void) runNumberDirChanged:(NSNotification*)aNotification
{
    if([model dirName]!=nil)[runNumberDirField setStringValue: [model dirName]];
}

#pragma  mark ¥¥¥Actions
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORDistributedRunNumberLock to:secure];
    [lockButton setEnabled:secure];
}

- (IBAction) startRunAction:(id)sender
{
    [self endEditing];
    [startRunButton setEnabled:NO];
    [stopRunButton setEnabled:NO];
    [model performSelector:@selector(startRun)withObject:nil afterDelay:.1];
}

- (IBAction)stopRunAction:(id)sender
{
    [self endEditing];
    [model performSelector:@selector(haltRun)withObject:nil afterDelay:.1];
}

- (IBAction)timeLimitTextAction:(id)sender
{
    if([model timeLimit] != [sender intValue]){
        [model setTimeLimit:[sender intValue]];
    }
}

- (IBAction)timedRunCBAction:(id)sender
{
    if([model timedRun] != [sender intValue]){
        [model setTimedRun:[sender intValue]];
    }
}

- (IBAction)repeatRunCBAction:(id)sender
{
    if([model repeatRun] != [sender intValue]){
        [model setRepeatRun:[sender intValue]];
    }
}

- (void) addRemoteRunItem:(ORRemoteRunItem*)anItem
{
    if(!remoteRunItemControllers)remoteRunItemControllers = [[NSMutableArray alloc] init];

    ORRemoteRunItemController* itemController = [anItem makeController:self];
    NSView* newView = [itemController view];
    [remoteRunItemControllers addObject:itemController];
    [remoteRunItemContentView setSizing:ZMakeFlowLayoutSizing( [newView frame].size, 5, ZSpringRight, YES )];
    [remoteRunItemContentView addSubview: newView];
}

- (void) removeRemoteRunItem:(ORRemoteRunItem*)anItem
{
    NSEnumerator* e = [remoteRunItemControllers objectEnumerator];
    ORRemoteRunItemController* itemController;
    while(itemController = [e nextObject]){
        if([itemController model] == anItem){
            [itemController retain];
            [remoteRunItemControllers removeObject:itemController];
            NSView* aView = [itemController view];
            [remoteRunItemContentView setSizing:ZMakeFlowLayoutSizing( [aView frame].size, 5,ZSpringRight, YES )];
            [aView removeFromSuperview];
            [itemController release];
            break;
        }
    }
}

- (IBAction) connectAllAction:(id)sender
{
    [model connectAll];
}

- (IBAction) disConnectAllAction:(id)sender
{
    [model disConnectAll];
}

- (IBAction) runNumberAction:(id)sender
{
    [self endEditing];
    if([runNumberText intValue] != [model runNumber]){
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:    @"Do you REALLY want to change the Run Number?"];
        [alert setInformativeText:@"Having a unique run number is important for most experiments. If you change it you may end up with data with duplicate run numbers."];
        [alert addButtonWithTitle:@"Yes/Change It"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setAlertStyle:NSAlertStyleWarning];
        
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
            if(result == NSAlertFirstButtonReturn){
                //have to do this after the alert actually closes, hence the delay to the next cycle of the event loop
                [self performSelector:@selector(deferredRunNumberChange) withObject:nil afterDelay:0];
            }
            else {
                [model setRunNumber:[runNumberText intValue]];
                [runNumberText setIntegerValue:[model runNumber]];
                [runNumberField setIntegerValue:[model runNumber]];
            }
        }];

    }
}

- (IBAction) chooseDir:(id)sender
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Do you REALLY want to change the Run Number Folder?"];
    [alert setInformativeText:@"Having a unique run number is important for most experiments. If you change the run number folder you may end up with duplicate run numbers."];
    [alert addButtonWithTitle:@"Yes/Select New Location"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if(result == NSAlertFirstButtonReturn){
            //have to do this after the alert actually closes, hence the delay to the next cycle of the event loop
            [self performSelector:@selector(deferredChooseDir) withObject:nil afterDelay:0];
        }
    }];
}

- (IBAction) runNumberLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORDistributedRunNumberLock to:[sender intValue] forWindow:[runNumberDrawer parentWindow]];
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

- (void) deferredRunNumberChange
{
    [model setRunNumber:[runNumberText intValue]];
}

- (NSUndoManager*)windowWillReturnUndoManager:(NSWindow*)window
{
    return [self  undoManager];
}

@end


