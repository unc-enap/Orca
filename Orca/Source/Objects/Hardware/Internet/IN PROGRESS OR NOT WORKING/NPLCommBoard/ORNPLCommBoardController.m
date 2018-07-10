//
//  ORHPNPLCommBoardController.m
//  Orca
//
//  Created by Mark Howe on Fri Jun 13 2008
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


#import "ORNPLCommBoardController.h"
#import "ORNPLCommBoardModel.h"

@implementation ORNPLCommBoardController
- (id) init
{
    self = [ super initWithWindowNibName: @"NPLCommBoard" ];
    return self;
}


- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORNPLCommBoardModelIpAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isConnectedChanged:)
                         name : ORNPLCommBoardModelIsConnectedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(boardChanged:)
                         name : ORNPLCommBoardModelBoardChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(blocChanged:)
                         name : ORNPLCommBoardModelBlocChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(functionChanged:)
                         name : ORNPLCommBoardModelFunctionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(writeValueChanged:)
                         name : ORNPLCommBoardModelWriteValueChanged
						object: model];

	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORNPLCommBoardLock
						object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(numBytesToSendChanged:)
                         name : ORNPLCommBoardModelNumBytesToSendChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cmdStringChanged:)
                         name : ORNPLCommBoardModelCmdStringChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(controlRegChanged:)
                         name : ORNPLCommBoardModelControlRegChanged
						object: model];

}


- (void) updateWindow
{
    [ super updateWindow ];
    
	[self ipAddressChanged:nil];
	[self isConnectedChanged:nil];
	[self boardChanged:nil];
	[self blocChanged:nil];
	[self functionChanged:nil];
	[self writeValueChanged:nil];
    [self lockChanged:nil];
	[self numBytesToSendChanged:nil];
	[self cmdStringChanged:nil];
	[self controlRegChanged:nil];
}

- (void) controlRegChanged:(NSNotification*)aNote
{
	[controlRegTextField setIntValue: [model controlReg]];
}

- (void) cmdStringChanged:(NSNotification*)aNote
{
	[cmdStringTextField setStringValue: [model cmdString]];
}

- (void) numBytesToSendChanged:(NSNotification*)aNote
{
	[numBytesToSendPU selectItemAtIndex: [model numBytesToSend]-3];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORNPLCommBoardLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self setButtonStates];
}

- (void) updateButtons
{
	[writeValueField setEnabled:[model functionNumber] >= 2];
}

- (void) writeValueChanged:(NSNotification*)aNote
{
	[writeValueField setIntValue: [model writeValue]];
}

- (void) functionChanged:(NSNotification*)aNote
{
	[functionPU selectItemAtIndex: [model functionNumber]];
	[self updateButtons];
}

- (void) blocChanged:(NSNotification*)aNote
{
	[blocPU selectItemAtIndex: [model bloc]];
}

- (void) boardChanged:(NSNotification*)aNote
{
	[boardPU selectItemAtIndex: [model board]];
}

#pragma mark •••Notifications
- (void) isConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model isConnected]?@"Connected":@"Not Connected"];
	[ipConnectButton setTitle:[model isConnected]?@"Disconnect":@"Connect"];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

- (void) setButtonStates
{
    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORNPLCommBoardLock];

    [lockButton setState: locked];
	[ipConnectButton setEnabled:!runInProgress || !locked];
	[ipAddressTextField setEnabled:!locked];
	[writeValueField setEnabled:!locked];
	[functionPU setEnabled:!locked ];
	[blocPU setEnabled:!locked];
	[boardPU setEnabled:!locked];
	[controlRegTextField setEnabled:!locked];
	[numBytesToSendPU setEnabled:!locked];
	[sendButton setEnabled:!locked];
}

- (NSString*) windowNibName
{
	return @"NPLCommBoard";
}

- (NSString*) rampItemNibFileName
{
	//subclasses can specify a differant RampItem nib file if needed.
	return @"HVRampItem";
}

#pragma mark •••Actions
- (void) controlRegAction:(id)sender
{
	[model setControlReg:[sender intValue]];	
}

- (void) numBytesToSendAction:(id)sender
{
	[model setNumBytesToSend:[sender indexOfSelectedItem]+3];	
}

- (void) writeValueAction:(id)sender
{
	[model setWriteValue:[sender intValue]];	
}

- (void) functionAction:(id)sender
{
	[model setFunctionNumber:[sender indexOfSelectedItem]];	
}

- (void) blocAction:(id)sender
{
	[model setBloc:[sender indexOfSelectedItem]];	
}

- (void) boardAction:(id)sender
{
	[model setBoard:[sender indexOfSelectedItem]];	
}

- (IBAction) ipAddressTextFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) connectAction:(id)sender
{
	[self endEditing];
	[model connect];
}

- (IBAction) sendCmdAction:(id)sender
{
	[self endEditing];
	[model sendCmd];
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORNPLCommBoardLock to:[sender intValue] forWindow:[self window]];
}

@end
