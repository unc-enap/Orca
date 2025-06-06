
//
//  ORSNOCrateController.m
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
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
#import "ORSNOCrateController.h"
#import "ORSNOCrateModel.h"
#import "ORSNOCard.h"
#import "SBC_Link.h"
#import "ORXL3Model.h"

@implementation ORSNOCrateController

- (id) init
{
    self = [super initWithWindowNibName:@"SNOCrate"];
    return self;
}

- (void) setCrateTitle
{
	[[self window] setTitle:[NSString stringWithFormat:@"SNO crate %u",[model uniqueIdNumber]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORSNOCardSlotChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(updateWindow)
						 name : ORXL3ModelStateChanged
					   object : [model adapter]];

    [notifyCenter addObserver : self
					 selector : @selector(updateWindow)
						 name : ORXL3ModelHvStatusChanged
					   object : [model adapter]];
}

- (void) updateWindow
{
    [super updateWindow];
	[self slotChanged:nil];

    ORXL3Model *xl3 = [model adapter];

    if ([[xl3 xl3Link] isConnected] && [xl3 stateUpdated]) {
        if ([xl3 initialized]) {
            /* The Xilinx has been loaded, so we need to enable the load
             * hardware button. */
            [loadHardwareButton setEnabled:TRUE];

            if ([xl3 hvSwitchEverUpdated]) {
                if (![xl3 hvASwitch] && ![xl3 hvBSwitch]) {
                    /* HV is off, so enable crate reset button. */
                    [resetCrateButton setEnabled:TRUE];
                } else {
                    [resetCrateButton setEnabled:FALSE];
                }
            } else {
                /* HV switch isn't known, so disable the reset crate button. */
                [resetCrateButton setEnabled:FALSE];
            }
        } else {
            /* The Xilinx hasn't been loaded, so we disable the load hardware
             * button, and enable the reset crate button. */
            [loadHardwareButton setEnabled:FALSE];
            [resetCrateButton setEnabled:TRUE];
        }
    } else {
        /* XL3 isn't connected, so don't enable any buttons. */
        [loadHardwareButton setEnabled:FALSE];
        [resetCrateButton setEnabled:FALSE];
    }
}

#pragma mark •••Interface Management
- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
	[memBaseAddressField setIntegerValue:[model memoryBaseAddress]];
	[regBaseAddressField setIntegerValue:[model registerBaseAddress]];
	[iPBaseAddressField setStringValue:[model iPAddress]];
	[crateNumberField setIntValue:[model crateNumber]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
	[memBaseAddressField setIntegerValue:[model memoryBaseAddress]];
	[regBaseAddressField setIntegerValue:[model registerBaseAddress]];
	[iPBaseAddressField setStringValue:[model iPAddress]];
	[crateNumberField setIntValue:[model crateNumber]];
}

- (void) keyDown:(NSEvent*)event {
    NSString* keys = [event charactersIgnoringModifiers];
    if([keys length] == 0) {
        return;
    }
    if([keys length] == 1) {
        unichar key = [keys characterAtIndex:0];
        //Arrow keys already taken by GroupView
        if(key == 'l' || key == 'L') {
            [self incCrateAction:self];
            return;
        }
        if(key == 'h' || key == 'H') {
            [self decCrateAction:self];
            return;
        }
    }
    [super keyDown:event];
}
#pragma mark •••Actions
- (IBAction) incCrateAction:(id)sender
{
	[self incModelSortedBy:@selector(crateNumberCompare:)];
}

- (IBAction) decCrateAction:(id)sender
{
	[self decModelSortedBy:@selector(crateNumberCompare:)];
}

- (IBAction) resetCrateAction:(id)sender
{
	@try {
		[model resetCrate];
	} @catch (NSException* localException) {
		NSLogColor([NSColor redColor], @"Crate %d reset failed.\n",
                   [model crateNumber]);
	}
}

- (IBAction) fetchECALSettingsAction:(id)sender
{
    [model fetchECALSettings];
}

- (IBAction) loadHardwareAction:(id)sender
{
    [model loadHardware];
}

@end
