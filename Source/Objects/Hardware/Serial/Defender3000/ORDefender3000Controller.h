//--------------------------------------------------------
// ORDefender3000Controller
//  Orca
//
//  Created by Mark Howe on 05/14/2024.
//  Copyright 2024 CENPA, University of North Carolina. All rights reserved.
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
#pragma mark ***Imported Files

@class ORCompositeTimeLineView;

@interface ORDefender3000Controller : OrcaObjectController
{
    IBOutlet NSTextField*   lockDocField;
	IBOutlet NSButton*		shipWeightButton;
    IBOutlet NSButton*      lockButton;
    IBOutlet NSButton*      sendCmdButton;
    IBOutlet NSTextField*   portStateField;
    IBOutlet NSPopUpButton* portListPopup;
    IBOutlet NSPopUpButton* pollTimePopup;
    IBOutlet NSPopUpButton* commandPopup;
    IBOutlet NSPopUpButton* unitsPopup;
    IBOutlet NSButton*      openPortButton;
    IBOutlet NSButton*      sendAllButton;
    IBOutlet NSTextField*   weightField;
    IBOutlet NSTextField*   timeField;
    IBOutlet NSTextField*   unitsField;
    IBOutlet NSTextField*   printIntervalField;
    IBOutlet NSTextField*   tareField;
	IBOutlet ORCompositeTimeLineView*   plotter0;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) shipWeightChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) portNameChanged:(NSNotification*)aNote;
- (void) portStateChanged:(NSNotification*)aNote;
- (void) weightChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) unitsChanged:(NSNotification*)aNote;
- (void) commandChanged:(NSNotification*)aNote;
- (void) updateButtonStates;

#pragma mark ***Actions
- (IBAction) shipWeightAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) portListAction:(id) sender;
- (IBAction) openPortAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) printIntervalAction:(id)sender;
- (IBAction) tareAction:(id)sender;
- (IBAction) unitsAction:(id)sender;
- (IBAction) commandAction:(id)sender;
- (IBAction) sendAllAction:(id)sender;

- (int)      numberPointsInPlot:(id)aPlotter;
- (void)     plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end


