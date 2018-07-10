//
//  ORCARootServiceController.m
//  Orca
//
//  Created by Mark Howe on Thu Nov 06 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORCARootServiceController.h"
#import "ORCARootService.h"
#import "ORCARootServiceDefs.h"
#import "SynthesizeSingleton.h"

@implementation ORCARootServiceController

SYNTHESIZE_SINGLETON_FOR_CLASS(ORCARootServiceController);

-(id)init
{
    self = [super initWithWindowNibName:@"ORCARootService"];
    [self setWindowFrameAutosaveName:@"ORCARootService"];
	RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h 
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    [self updateWindow];
	[hostComboBox reloadData];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[self orcaRootService]  undoManager];
}

#pragma mark ¥¥¥Accessors
- (ORCARootService*) orcaRootService
{
    return [ORCARootService sharedORCARootService];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(portChanged:)
                         name : ORCARootServicePortChanged
                       object : [self orcaRootService]];

    [notifyCenter addObserver : self
                     selector : @selector(portChanged:)
                         name : ORDocumentLoadedNotification
                       object : nil];
					   
    [notifyCenter addObserver : self
                     selector : @selector(connectedChanged:)
                         name : ORCARootServiceConnectionChanged
                       object : [self orcaRootService]];
    						
    [notifyCenter addObserver : self
                     selector : @selector(timeConnectedChanged:)
                         name : ORCARootServiceTimeConnectedChanged
                       object : [self orcaRootService]];

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORORCARootServiceLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
					   
    [notifyCenter addObserver : self
                     selector : @selector(securityStateChanged:)
                         name : ORGlobalSecurityStateChanged
                        object: nil];

	[notifyCenter addObserver : self
                      selector: @selector(connectAtStartChanged:)
                          name: ORCARootServiceConnectAtStartChanged
                       object : [self orcaRootService]];
    
	[notifyCenter addObserver : self
                      selector: @selector(autoReconnectChanged:)
                          name: ORCARootServiceAutoReconnectChanged
                       object : [self orcaRootService]];
					   
	[notifyCenter addObserver : self
                      selector: @selector(hostNameChanged:)
                          name: ORCARootServiceHostNameChanged
                       object : [self orcaRootService]];
	
	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];

}
- (void) endEditing
{
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}
}

#pragma mark ¥¥¥Actions
- (void) securityStateChanged:(NSNotification*)aNotification
{
    [self checkGlobalSecurity];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORORCARootServiceLock to:secure];
    [lockButton setEnabled:secure];
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORORCARootServiceLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) setPortAction:(id) sender;
{
    if([sender intValue] != [[self orcaRootService] socketPort]){
        [[self orcaRootService] setSocketPort:[sender intValue]];
    }
}
- (IBAction) setHostNameAction:(id) sender
{
	[[self orcaRootService] setHostName:[sender stringValue]];
}

- (IBAction) clearHistory:(id) sender
{
	[[self orcaRootService] clearHistory];
}

- (IBAction) saveDocument:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocumentAs:sender];
}


- (IBAction) connectAction:(id)sender
{
	[self endEditing];
    if([[self orcaRootService] isConnected]){
        [[self orcaRootService] connectSocket:NO];
    }
    else {
        [[self orcaRootService] connectSocket:YES];
    }
}
- (IBAction) connectAtStartAction:(id)sender
{
	[[self orcaRootService] setConnectAtStart:[sender state]];
}

- (IBAction) autoReconnectAction:(id)sender
{
	[[self orcaRootService] setAutoReconnect:[sender state]];
}


#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [self portChanged:nil];
    [self connectedChanged:nil];
    [self timeConnectedChanged:nil];
    [self hostNameChanged:nil];
	[self connectAtStartChanged:nil];
	[self autoReconnectChanged:nil];
	
	[self securityStateChanged:nil];
}

- (void) connectAtStartChanged:(NSNotification*)aNote
{
	[connectAtStartButton setState:[[self orcaRootService] connectAtStart]];
}

- (void) autoReconnectChanged:(NSNotification*)aNote
{
	[autoReconnectButton setState:[[self orcaRootService] autoReconnect]];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORORCARootServiceLock];
    [lockButton setState: locked];
    
    [portField setEnabled:!locked];   
    [hostComboBox setEnabled:!locked];   
    [connectAtStartButton setEnabled:!locked];   
    [autoReconnectButton setEnabled:!locked];   
}


- (void) portChanged:(NSNotification*)aNotification
{
	[portField setIntValue: [[self orcaRootService] socketPort]];
}

- (void) hostNameChanged:(NSNotification*)aNotification
{
	NSUInteger index = [[self orcaRootService] hostNameIndex];
    [hostComboBox reloadData];
	if(index!=NSNotFound)[hostComboBox selectItemAtIndex: index];
}

- (void) connectedChanged:(NSNotification*)aNotification
{
	BOOL connected = [[self orcaRootService] isConnected];
	[statusField setStringValue: connected?@"YES":@"NO"];
	[connectButton setTitle:connected?@"Disconnect":@"Connect"];
	[hostComboBox setEnabled:!connected];
	[portField setEnabled:!connected];
	[clearHistoryButton setEnabled:!connected];
}

- (void) timeConnectedChanged:(NSNotification*)aNotification
{
	if([[self orcaRootService] isConnected]){
        NSDate* timeConnected = [[self orcaRootService] timeConnected];
        [timeField setStringValue: [NSString stringWithFormat:@"At: %@",[timeConnected stdDescription]]];

    }
	else {
		[timeField setStringValue: @""];
	}
}

- (NSInteger ) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	return  [[self orcaRootService] connectionHistoryCount];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	return [[self orcaRootService] connectionHistoryItem:index];
}


@end

