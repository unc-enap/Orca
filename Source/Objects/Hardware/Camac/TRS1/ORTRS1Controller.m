/*
 
 File:		ORTRS1Controller.m
 
 Usage:		Test PCI Basic I/O Kit Kernel Extension (KEXT) Functions
 for the Camac TRS1 VME Bus Controller
 
 Author:		FM
 
 Copyright:		Copyright 2001-2002 F. McGirt.  All rights reserved.
 
 Change History:	1/22/02, 2/2/02, 2/12/02
 2/13/02 MAH CENPA. converted to Objective-C
 */
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
#import "ORTRS1Controller.h"
#import "ORCamacExceptions.h"

// methods
@implementation ORTRS1Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"TRS1"];
	
    return self;
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	[notifyCenter addObserver : self
					 selector : @selector(runStatusChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(controlRegisterChanged:)
                         name : ORTRS1ModelControlRegisterChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(offsetRegisterChanged:)
                         name : ORTRS1ModelOffsetRegisterChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORCamacCardSlotChangedNotification
                       object : model];
}

#pragma mark ¥¥¥Interface Management
- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"TR8818 (Station %d",[model stationNumber]+1]];
}

- (void) offsetRegisterChanged:(NSNotification*)aNote
{
	[offsetRegisterTextField setIntValue: [model offsetRegister]];
}

- (void) controlRegisterChanged:(NSNotification*)aNote
{
	[controlRegisterTextField setIntValue: [model controlRegister]];
}

- (void) updateWindow
{
	[super updateWindow];
	[self runStatusChanged:nil];
	[self controlRegisterChanged:nil];
	[self offsetRegisterChanged:nil];
	[self slotChanged:nil];
}

- (void) runStatusChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
	
	[moduleIDButton setEnabled:!runInProgress];
	[testLAMButton setEnabled:!runInProgress];
	[clearLAMButton setEnabled:!runInProgress];
	[triggerButton setEnabled:!runInProgress];
	[initButton setEnabled:!runInProgress];
	
}

#pragma mark ¥¥¥Actions

- (void) offsetRegisterAction:(id)sender
{
	[model setOffsetRegister:[sender intValue]];	
}

- (void) controlRegisterAction:(id)sender
{
	[model setControlRegister:[sender intValue]];	
}

- (IBAction) initAction:(id)sender
{
    @try {
		[self endEditing];
        [model checkCratePower];
        [model initBoard];
		NSLog(@"8818A (station %d) Init\n",[model stationNumber]+1);
    }
	@catch(NSException* localException) {
		NSLog(@"Failed Cmd: Init\n");
		if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) {
			[[model crate]  doNoPowerAlert:localException action:[NSString stringWithFormat:@"Init"]];
		}
		else {
			ORRunAlertPanel([localException name], @"%@\n", @"OK", nil, nil,
							[localException name]);
		}
    }
}

- (IBAction) moduleIDAction:(id)sender
{
    @try {
        [model checkCratePower];
		NSLog(@"8818A (station %d) module ID: %d\n",[model stationNumber]+1, [model readModuleID]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read ModuleID" fCode:3];
    }
}

- (IBAction) testLAMAction:(id)sender
{
    @try {
        [model checkCratePower];
        unsigned char state = [model testLAM];
		NSLog(@"8818A (station %d) LAM %@ set.\n",[model stationNumber]+1,state?@"is":@"is NOT");
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read ModuleID" fCode:27];
    }
}

- (IBAction) clearLAMAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model clearLAM];
		NSLog(@"8818A (station %d) LAM Cleared.\n",[model stationNumber]+1);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Clear LAM" fCode:10];
    }
}
- (IBAction) triggerAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model internalTrigger];
		NSLog(@"8818A (station %d) Triggered.\n",[model stationNumber]+1);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Internal Trigger" fCode:25];
    }
}

- (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i
{
    NSLog(@"Failed Cmd: %@ (F%d)\n",name,i);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [[model crate]  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@ (F%d)",name,i]];
    }
    else {
        ORRunAlertPanel([anException name], @"%@\n%@ (F%d)", @"OK", nil, nil,
                        [anException name],name,i);
    }
}

@end



