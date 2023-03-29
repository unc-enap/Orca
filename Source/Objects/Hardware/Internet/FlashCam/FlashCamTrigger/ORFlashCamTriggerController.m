//  Orca
//  ORFlashCamTriggerController.m
//
//  Created by Tom Caldwell on Monday Jan 1, 2020
//  Copyright (c) 2020 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORFlashCamTriggerController.h"
#import "ORFlashCamTriggerModel.h"
#import "ORFlashCamADCModel.h"

@implementation ORFlashCamTriggerController

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamTrigger"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam Trigger (0x%x, Crate %d, Slot %d)", [model cardAddress], [model crateNumber], [model slot]]];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(connectionChanged:)
                         name : ORFlashCamCardAddressChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(connectionChanged:)
                         name : ORConnectionChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(majorityLevelChanged:)
                         name : ORFlashCamTriggerModelMajorityLevelChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(majorityWidthChanged:)
                         name : ORFlashCamTriggerModelMajorityWidthChanged
                       object : model];

}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) updateWindow
{
    [super updateWindow];
    [self connectionChanged:nil];
    [self statusChanged:nil];
    [self majorityLevelChanged:nil];
    [self majorityWidthChanged:nil];

}

#pragma mark •••Interface management

- (void) settingsLock:(bool)lock
{
    lock |= [gOrcaGlobals runInProgress] || [gSecurity isLocked:ORFlashCamCardSettingsLock];
    [super settingsLock:lock];
    [majorityLevelPU setEnabled:!lock];
    [majorityWidthTextField setEnabled:!lock];
}

- (void) majorityLevelChanged:(NSNotification*)note
{
    [majorityLevelPU selectItemAtIndex:[model majorityLevel]-1];
}

- (void) majorityWidthChanged:(NSNotification*)note
{
    [majorityWidthTextField setIntValue:[model majorityWidth]];
}

- (void) cardAddressChanged:(NSNotification*)note
{
    [super cardAddressChanged:note];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam Trigger (0x%x, Crate %d, Slot %d)", [model cardAddress], [model crateNumber], [model slot]]];
}

- (void) cardSlotChanged:(NSNotification*)note
{
    [super cardSlotChanged:note];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam Trigger (0x%x, Crate %d, Slot %d)", [model cardAddress], [model crateNumber], [model slot]]];
}

- (void) connectionChanged:(NSNotification*)note
{
    NSMutableDictionary* addresses = [model connectedAddresses];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++){
        NSNumber* a = [addresses objectForKey:[NSString stringWithFormat:@"trigConnection%d",i]];
        if(a) [[connectedADCMatrix cellWithTag:i] setIntValue:[a intValue]];
        else [[connectedADCMatrix cellWithTag:i] setIntValue:0];
    }
}

- (void) statusChanged:(NSNotification*)note
{
    [super statusChanged:note];
    [fcioIDTextField1      setIntValue:[fcioIDTextField      intValue]];
    [statusEventTextField1 setIntValue:[statusEventTextField intValue]];
    [statusPPSTextField1   setIntValue:[statusPPSTextField   intValue]];
    [statusTicksTextField1 setIntValue:[statusTicksTextField intValue]];
    [totalErrorsTextField1 setIntValue:[totalErrorsTextField intValue]];
    [envErrorsTextField1   setIntValue:[envErrorsTextField   intValue]];
    [ctiErrorsTextField1   setIntValue:[ctiErrorsTextField   intValue]];
    [linkErrorsTextField1  setIntValue:[linkErrorsTextField  intValue]];
}


#pragma mark •••Actions

- (IBAction) printFlagsAction:(id)sender
{
    [super printFlagsAction:sender];
    [model printRunFlagsForCardIndex:0];
}
- (IBAction) majorityLevelAction:(id)sender
{
    [model setMajorityLevel:(int)[sender indexOfSelectedItem]+1];
}

- (IBAction) majorityWidthAction:(id)sender
{
    [model setMajorityWidth:[sender intValue]];
}
@end
