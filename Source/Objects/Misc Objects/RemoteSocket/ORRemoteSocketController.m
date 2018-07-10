//
//  ORRemoteSocketController.m
//  Orca
//
//  Created by Mark Howe on 10/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORRemoteSocketController.h"
#import "ORRemoteSocketModel.h"

@implementation ORRemoteSocketController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"RemoteSocket"];
    return self;
}

#pragma mark •••Registration
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(remoteHostNameChanged:)
                         name : ORRSRemoteHostChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(remoteSocketLockChanged:)
                         name : ORRemoteSocketLock
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(remotePortChanged:)
                         name : ORRSRemotePortChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(connectionChanged:)
                         name : ORRSRemoteConnectedChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(queueCountChanged:)
                         name : ORRemoteSocketQueueCountChanged
                       object : model];
    
    
}

- (void) updateWindow
{
	[super updateWindow];
	[self remoteHostNameChanged:nil];
	[self remotePortChanged:nil];
    [self remoteSocketLockChanged:nil];
    [self connectionChanged:nil];
    [self queueCountChanged:nil];
}

- (void) queueCountChanged:(NSNotification*)aNote
{
    [queueCountField setIntValue:[model queueCount]];
}

- (void) connectionChanged:(NSNotification*)aNote
{
    [connectedField setStringValue:[model isConnected]?@"Connected":@""];
}


- (void) remoteHostNameChanged:(NSNotification*)aNote
{
	[remoteHostField setStringValue:[model remoteHost]];
}

- (void) remotePortChanged:(NSNotification*)aNote
{
	[remotePortField setIntValue:[model remotePort]];
}


- (void) remoteSocketLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORRemoteSocketLock];
    [remoteSocketLockButton setState: locked];
    
    [remoteHostField setEnabled:!locked];
    [remotePortField setEnabled:!locked];
    
}
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORRemoteSocketLock to:secure];
    [remoteSocketLockButton setEnabled: secure];
}

#pragma mark •••Actions

- (IBAction) remoteSocketLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORRemoteSocketLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) remoteHostNameAction:(id)sender
{
	[model setRemoteHost:[sender stringValue]];
}

- (IBAction) remotePortAction:(id)sender
{
	[model setRemotePort:[sender intValue]];
}


- (IBAction) connectionAction:(id)sender
{
	[self endEditing];
	[model connect];
}

@end
