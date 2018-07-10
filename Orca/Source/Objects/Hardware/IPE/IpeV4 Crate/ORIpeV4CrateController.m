
//
//  ORIpeV4CrateController.m
//  Orca
//
//  Created by Mark Howe on Fri Aug 5, 2005.
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


#pragma mark •••Imported Files
#import "ORIpeV4CrateController.h"
#import "ORIpeV4CrateModel.h"

@implementation ORIpeV4CrateController

- (id) init
{
    self = [super initWithWindowNibName:@"IpeV4Crate"];
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	// Set title of crate window, ak 15.6.07
    [[self window] setTitle:[NSString stringWithFormat:@"IPE-DAQ-V4 Crate %d",[model crateNumber]]];

}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
	
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
	
    [notifyCenter addObserver : self
                     selector : @selector(connectionChanged:)
                         name : ORIpeV4CrateConnectedChanged
                       object : nil];


    [notifyCenter addObserver : self
                     selector : @selector(snmpPowerSupplyIPChanged:)
                         name : ORIpeV4CrateModelSnmpPowerSupplyIPChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(unlockedStopButtonChanged:)
                         name : ORIpeV4CrateModelUnlockedStopButtonChanged
						object: model];

}


- (void) updateWindow
{
	[super updateWindow];
	[self connectionChanged:nil];
	[self snmpPowerSupplyIPChanged:nil];
	[self unlockedStopButtonChanged:nil];
}

- (void) connectionChanged:(NSNotification*)aNotification
{
	[connectedField setStringValue:[model isConnected]?@"Connected":@"Not Connected"];
}


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Interface Management

- (void) unlockedStopButtonChanged:(NSNotification*)aNote
{
	[unlockedStopButtonCB setIntValue: [model unlockedStopButton]];
    [stopButton setEnabled: [model unlockedStopButton]];
}

- (void) snmpPowerSupplyIPChanged:(NSNotification*)aNote
{
	[snmpPowerSupplyIPTextField setStringValue: [model snmpPowerSupplyIP]];
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Actions

- (void) unlockedStopButtonCBAction:(id)sender
{
	[model setUnlockedStopButton:[sender intValue]];	
}

- (void) snmpPowerSupplyIPTextFieldAction:(id)sender
{
	[model setSnmpPowerSupplyIP:[sender stringValue]];	
}


- (IBAction) snmpStartCrateAction:(id)sender
{
    [self endEditing];
        //DEBUG OUTPUT:                 NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO : DEBUG testing ...-tb-
        
    [model snmpWriteStartCrateCommand];
}

- (IBAction) snmpStopCrateAction:(id)sender
{
    [self endEditing];
    [model setUnlockedStopButton: false];
        //DEBUG OUTPUT:                 NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO : DEBUG testing ...-tb-
        
    [model snmpWriteStopCrateCommand];
}



@end
