
//
//  ORIpeMtcaCrateController.m
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
#import "ORIpeMtcaCrateController.h"
#import "ORIpeMtcaCrateModel.h"

@implementation ORIpeMtcaCrateController

- (id) init
{
    self = [super initWithWindowNibName:@"IpeMtcaCrate"];
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
  [[self window] setTitle:[NSString stringWithFormat:@"IPE-MTCA Crate %d",[model crateNumber]]];

}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
	
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
	
    [notifyCenter addObserver : self
                     selector : @selector(connectionChanged:)
                         name : ORIpeMtcaCrateConnectedChanged
                       object : nil];


    [notifyCenter addObserver : self
                     selector : @selector(snmpPowerSupplyIPChanged:)
                         name : ORIpeMtcaCrateModelSnmpPowerSupplyIPChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(unlockedStopButtonChanged:)
                         name : ORIpeMtcaCrateModelUnlockedStopButtonChanged
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


#pragma mark •••Interface Management

- (void) unlockedStopButtonChanged:(NSNotification*)aNote
{
	[unlockedStopButtonCB setIntValue: [model unlockedStopButton]];
    [stopButton setEnabled: [model unlockedStopButton]];
}

- (void) snmpPowerSupplyIPChanged:(NSNotification*)aNote
{
	[snmpPowerSupplyIPTextField setStringValue: [model snmpPowerSupplyIP]];
}

#pragma mark •••Actions

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
