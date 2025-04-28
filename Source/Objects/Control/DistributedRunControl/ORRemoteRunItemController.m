//
//  ORRemoteRunItemController.m
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

#import "ORRemoteRunItemController.h"
#import "ORRemoteRunItem.h"
#import "ORDistributedRunModel.h"
#import "StopLightView.h"

@implementation ORRemoteRunItemController
- (id) initWithNib:(NSString*)aNibName
{
    if( self = [super init] ){
        [[NSBundle mainBundle] loadNibNamed:aNibName owner:self topLevelObjects:&topLevelObjects];
        [topLevelObjects retain];
    }
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [topLevelObjects release];
	[super dealloc];
}

- (void) awakeFromNib { [self updateWindow]; }
- (NSView*) view      { return view; }

- (void) setOwner:(ORRemoteRunItemController*)anOwner
{
	owner = anOwner;
}


- (id)   model { return model; }
- (void) setModel:(id)aModel
{
	model = aModel;
	[self registerNotificationObservers];
	[self updateWindow];
}

#pragma mark •••Interface Management
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipNumberChanged:)
                         name : ORRemoteRunItemIpNumberChanged
                       object : nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(remotePortChanged:)
                         name: ORRemoteRunItemPortChanged
                       object: model];
    
    [notifyCenter addObserver : self
                      selector : @selector(isConnectionChanged:)
                          name : ORRemoteRunItemIsConnectedChanged
                        object : model];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStateChanged:)
                         name: ORRemoteRunItemStateChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(systemNameChanged:)
                         name: ORRemoteRunItemSystemNameChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(ignoreChanged:)
                         name: ORRemoteRunItemIgnoreChanged
                       object: model];
  
    [notifyCenter addObserver: self
                     selector: @selector(runNumberChanged:)
                         name: ORRemoteRunItemRunNumberChanged
                       object: model];
    
    [notifyCenter addObserver: self
                        selector: @selector(isConnectionChanged:)
                            name: ORRemoteRunItemRunNumberChanged
                          object: model];
}

- (void) updateWindow
{
    [self ipNumberChanged:nil];
    [self isConnectionChanged:nil];
    [self remotePortChanged:nil];
    [self runStateChanged:nil];
    [self systemNameChanged:nil];
    [self ignoreChanged:nil];
    [self runNumberChanged:nil];
}

- (void) setButtonStates
{
	BOOL lockedOrRunning = [model isRunning];
	[minusButton  setEnabled:!lockedOrRunning];
}

- (void) reloadObjects:(NSNotification*)aNote
{
    [self setButtonStates];
}

- (void) systemNameChanged:(NSNotification*)aNote
{
    if(model){
        [systemNameField setStringValue:[model systemName]];
    }
}

- (void) ipNumberChanged:(NSNotification*)aNote
{
    if(model) {
        [ipNumberField setStringValue:[model ipNumber]];
    }
}
- (void) ignoreChanged:(NSNotification*)aNote
{
    [ignoreCB setIntValue:[model ignore]];
}

- (void) remotePortChanged:(NSNotification*)aNote
{
    if(model) [remotePortField setIntegerValue:[(ORRemoteRunItem*)model remotePort]];
}

- (void) runNumberChanged:(NSNotification*)aNote
{
    if([model isConnected]) [runNumberField setIntegerValue:[model runNumber]];
    else                    [runNumberField setStringValue:@"?"];
}

- (void) isConnectionChanged:(NSNotification*)aNote
{
    if(!model){
        [connectedField setStringValue:@"?"];
        [connectButton setTitle:@"Connect"];
    }
    else {
        if([model isConnected]){
            [connectedField setStringValue:@"Connected"];
            [connectButton setTitle:@"Disconnect"];
        }
        else {
            [connectedField setStringValue:@"--"];
            [connectButton setTitle:@"Connect"];
        }
    }
}

- (void) runStateChanged:(NSNotification*)aNote { [self updateButtons]; }

- (void) updateButtons;
{
    if([model runningState] == eRunInProgress){
        [lightBoardView setState:kGoLight];
        [runStatusField setStringValue:@"Running"];
        [plusButton setEnabled:NO];
        [minusButton setEnabled:NO];
        [connectButton setEnabled:NO];
        [ipNumberField setEnabled:NO];
        [remotePortField setEnabled:NO];
    }
    else if([model runningState] == eRunStopped){
        [lightBoardView setState:kStoppedLight];
        [runStatusField setStringValue:@"Stopped"];
        [plusButton setEnabled:YES];
        [minusButton setEnabled:YES];
        [connectButton setEnabled:YES];
        [ipNumberField setEnabled:YES];
        [remotePortField setEnabled:YES];
    }
    else if([model runningState] == eRunStarting || [model runningState] == eRunStopping){
        [lightBoardView setState:kCautionLight];
        [runStatusField setStringValue:@"Starting"];
        [plusButton setEnabled:NO];
        [minusButton setEnabled:NO];
        [connectButton setEnabled:NO];
        [ipNumberField setEnabled:NO];
        [remotePortField setEnabled:NO];
    }
}

- (IBAction) insertRemoteRunItem:(id)sender
{
	ORRemoteRunItem* anItem = [model copy];
	[[model owner] addRemoteRunItem:anItem afterItem:model];
	[anItem release];
}

- (IBAction) removeRemoteRunItem:(id)sender { [model removeSelf]; }

- (IBAction) connectAction:(id)sender
{
    [self endEditing];
    [model connectSocket:![model isConnected]];
}

- (IBAction) ipNumberAction:(id)sender   { [model setIpNumber:[ipNumberField stringValue]]; }
- (IBAction) systemNameAction:(id)sender { [model setSystemName:[systemNameField stringValue]]; }
- (IBAction) remotePortAction:(id)sender { [model setRemotePort:[sender intValue]]; }
- (IBAction) ignoreAction:(id)sender     { [model setIgnore:[sender intValue]]; }

- (void) endEditing
{
	if(![[owner window] makeFirstResponder:[owner window]]){
		[[owner window] endEditingFor:nil];
	}
}
@end

