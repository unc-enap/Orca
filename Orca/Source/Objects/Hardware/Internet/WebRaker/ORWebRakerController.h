//
//  ORWebRakerController.h
//  Orca
//
//  Created by Mark Howe on Mon Jan 11 2016
//  Copyright (c) 2016 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "OrcaObjectController.h"
@class ORCompositeTimeLineView;

@interface ORWebRakerController : OrcaObjectController 
{
	IBOutlet NSTextField*	ipAddressField;
	IBOutlet NSButton*		dialogLock;
	IBOutlet NSTextField*   lastPolledField;
	IBOutlet NSTextField*	nextPollField;
    IBOutlet NSTableView*   processTableView;
    IBOutlet NSTextField*   dataValidField;
    IBOutlet NSTableView*   dataTableView;
    IBOutlet NSTextView*    detailsView;

	IBOutlet ORCompositeTimeLineView*   plotter0;
}

#pragma mark ***Interface Management
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) pollingTimesChanged:(NSNotification*)aNote;
- (void) dataValidChanged:(NSNotification*)aNote;
- (void) refreshProcessTable:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) ipAddressAction:(id)sender;
- (IBAction) dialogLockAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end

