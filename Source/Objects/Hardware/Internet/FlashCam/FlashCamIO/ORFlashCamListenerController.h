//  Orca
//  ORFlashCamListenerController.h
//
//  Created by Tom Caldwell on Mar 1, 2023
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
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

@interface ORFlashCamListenerController : OrcaObjectController
{
    IBOutlet NSTabView*   tabView;
    IBOutlet NSTextView*  historyView;
    IBOutlet NSTextView*  cycleView;
    IBOutlet NSTextView*  errorView;
    IBOutlet NSButton*    saveHistoryButton;
    IBOutlet NSButton*    clearHistoryButton;
    IBOutlet NSTextField* nlinesLabel;
    IBOutlet NSTextField* nlinesTextField;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark •••Interface management
- (void) fcLogChanged:(NSNotification*)note;
- (void) fcRunLogChanged:(NSNotification*)note;
- (void) fcRunLogFlushed:(NSNotification*)note;
- (void) listenerConfigChanged:(NSNotification*)note;

#pragma mark •••Actions
- (IBAction) saveHistoryAction:(id)sender;
- (IBAction) clearHistoryAction:(id)sender;
- (IBAction) nlinesAction:(id)sender;

@end
