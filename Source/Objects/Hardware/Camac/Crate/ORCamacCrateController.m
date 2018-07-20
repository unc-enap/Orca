
//
//  ORCamacCrateController.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORCamacCrateController.h"
#import "ORCamacCrateModel.h"
#import "ORCamacBusProtocol.h"
#import "ORCamacExceptions.h"

@implementation ORCamacCrateController

- (id) init
{
    self = [super initWithWindowNibName:@"CamacCrate"];
    return self;
}

- (void) setCrateTitle
{
	[[self window] setTitle:[NSString stringWithFormat:@"CAMAC crate %u",[model uniqueIdNumber]]];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    [notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"CamacPowerFailedNotification"
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"CamacPowerRestoredNotification"
                       object : nil];
	
}

#pragma mark ¥¥¥Interface Management


#pragma mark ¥¥¥Actions
- (IBAction) showHideAction:(id)sender
{
    NSRect aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
											styleMask:[[self window] styleMask]];
    if([showHideButton state] == NSOnState)aFrame.size.height = 375;
    else aFrame.size.height = 305;
    [self resizeWindowToSize:aFrame.size];
}

- (IBAction) executeZCycleAction:(id)sender
{
    @try {
        [[model adapter]  checkCratePower];
        [[model adapter]  executeZCycle];
        NSLog(@"Execute Z-Cycle Crate %d\n",[model crateNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Execute Z-Cycle"];
    }
}

- (IBAction) executeCCycleAction:(id)sender
{
    @try {
        [[model adapter]  checkCratePower];
        [[model adapter]  executeCCycle];
        NSLog(@"Execute C-Cycle Crate %d\n",[model crateNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Execute C-Cycle"];
    }
}
- (IBAction) setInhibitOnAction:(id)sender
{
	@try {
        [[model adapter]  checkCratePower];
        [[model adapter]  setCrateInhibit:YES];
        NSLog(@"Set Crate Inhibit ON for Crate %d\n",[model crateNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Set Crate Inhibit ON"];
    }
}
- (IBAction) setInhibitOffAction:(id)sender
{
	@try {
        [[model adapter]  checkCratePower];
        [[model adapter]  setCrateInhibit:NO];
        NSLog(@"Set Crate Inhibit OFF for Crate %d\n",[model crateNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Set Crate Inhibit OFF"];
    }
}

- (void) showError:(NSException*)anException name:(NSString*)name
{
    NSLog(@"Failed Cmd: %@ \n",name);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [model  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@",name]];
    }
    else {
        ORRunAlertPanel([anException name], @"%@\n%@", @"OK", nil, nil,
                        [anException name],name);
    }
}


@end
