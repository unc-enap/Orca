//
//  ORBurstMonitorController.h
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

@class ORValueBarGroupView;

@interface ORBurstMonitorController : OrcaObjectController {

    IBOutlet NSTextField*           timeWindowField;
    IBOutlet NSTextField*           nHitField;
    IBOutlet NSTextField*           minimumEnergyAllowedField;
    IBOutlet NSTextField*           numBurstsNeededField;
    IBOutlet NSButton*              lockButton;
    IBOutlet NSTableView*           emailListTable;
    IBOutlet NSButton*              removeAddressButton;
    
    IBOutlet NSMatrix*              channelGroup0Matrix;
    IBOutlet NSMatrix*              channelGroup1Matrix;
    
    IBOutlet NSMatrix*              queueLowChannelMatrix;
    IBOutlet NSMatrix*              queueHiChannelMatrix;
    IBOutlet ORValueBarGroupView*	queue0Holdings;
    IBOutlet ORValueBarGroupView*	queue1Holdings;
    
    BOOL                            updateScheduled;
}

#pragma mark •••Initialization
- (void) registerNotificationObservers;
- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) timeWindowChanged:(NSNotification*)aNotification;
- (void) nHitChanged:(NSNotification*)aNotification;
- (void) numBurstsNeededChanged:(NSNotification*)aNotification;
- (void) minimumEnergyAllowedChanged:(NSNotification*)aNotification;
- (void) queueChanged:(NSNotification*)aNotification;
- (void) delayedQueueUpdate;
- (void) emailListChanged:(NSNotification*)aNotification;

#pragma mark •••Actions
- (IBAction) timeWindowAction:(id)sender;
- (IBAction) nHitAction:(id)sender;
- (IBAction) numBurstsNeededAction:(id)sender;
- (IBAction) minimumEnergyAllowedAction:(id)sender;
- (IBAction) addAddress:(id)sender;
- (IBAction) removeAddress:(id)sender;

#pragma mark •••Table Data Source
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView;
- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aCol row:(NSInteger)aRow;

@end
