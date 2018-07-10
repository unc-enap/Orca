//
//  ORHPTDS2024Controller.h
//  Orca
//  Created by Mark Howe on Mon, May 9, 2018.
//  Copyright (c) 2018 University of North Carolina. All rights reserved.
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

@class ORUSB;
@class ORCompositePlotView;

@interface ORTDS2024Controller : OrcaObjectController 
{
    IBOutlet NSButton* 		readIdButton;
    IBOutlet NSButton*		lockButton;
    IBOutlet NSProgressIndicator* busyIndicator;
    IBOutlet NSPopUpButton* serialNumberPopup;
    IBOutlet NSMatrix*      chanEnabledMatrix;
    IBOutlet NSTextField*   commandField;
    IBOutlet NSButton*		sendCommandButton;
	IBOutlet NSPopUpButton* pollTimePopup;
    IBOutlet ORCompositePlotView*    plotter;
}

#pragma mark •••Notifications

#pragma mark ***Interface Management
- (void) chanEnabledChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) busyChanged:(NSNotification*)aNote;
- (void) setButtonStates;

#pragma mark •••Actions
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) readIdAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;
- (IBAction) readIdAction:(id)sender;
- (IBAction) chanEnabledAction:(id)sender;
- (void) validateInterfacePopup;

- (NSColor*) colorForDataSet:(int)set;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
@end

