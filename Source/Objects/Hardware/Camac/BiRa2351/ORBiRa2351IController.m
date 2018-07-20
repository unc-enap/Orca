/*
 *  ORBiRa2351IModelController.cpp
 *  Orca
 *
 *  Created by Mark Howe on Fri Aug 4, 2006.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
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
#import "ORBiRa2351IController.h"

#import "ORCamacExceptions.h"

// methods
@implementation ORBiRa2351IController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"BiRa2351I"];
	
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[inputRegisterMatrix setEnabled:NO];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(lastReadChanged:)
                         name : ORBiRa2351IModelLastReadChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORCamacCardSlotChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(inputRegisterChanged:)
                         name : ORBiRa2351IModelInputRegisterChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingStateChanged:)
                         name : ORBiRa2351IModelPollingStateChanged
						object: model];
}

#pragma mark ¥¥¥Interface Management

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
	[self inputRegisterChanged:nil];
	[self lastReadChanged:nil];
	[self pollingStateChanged:nil];
}

- (void) lastReadChanged:(NSNotification*)aNote
{
	[lastReadTextField setStringValue: [model lastRead]];
}
- (void) pollingStateChanged:(NSNotification*)aNote
{
	[pollingStatePopup selectItemAtIndex: [model pollingState]];
}

- (void) inputRegisterChanged:(NSNotification*)aNote
{
	unsigned short theMask = [model inputRegister];
	int i;
	for(i=0;i<12;i++){
		[[inputRegisterMatrix cellWithTag:i] setState: (theMask & (1<<i))!=0];
	}
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"BiRa2351I (Station %u)",(int)[model stationNumber]]];
}

#pragma mark ¥¥¥Actions
- (void) pollingStatePopupAction:(id)sender
{
	int index = (int)[(NSPopUpButton*)sender indexOfSelectedItem];
	if(index == 0) [model setPollingState:0];	
	else [model setPollingState:[[sender titleOfSelectedItem] intValue]]; 
}

- (IBAction) readRegisterAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model readInputRegister:YES];
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read Input Register"];
    }
}


- (void) showError:(NSException*)anException name:(NSString*)name
{
    NSLog(@"Failed Cmd: %@\n",name);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [[model crate]  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@",name]];
    }
    else {
        ORRunAlertPanel([anException name], @"%@\n%@", @"OK", nil, nil,
                        [anException name],name);
    }
}
@end



