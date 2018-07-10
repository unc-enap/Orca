//
//  ORHPLakeShore336Controller.h
//  Orca
//  Created by Mark Howe on Mon, May 6, 2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
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
@class ORCompositeTimeLineView;
@class ORLakeShore336LinkView;

@interface ORLakeShore336Controller : OrcaObjectController 
{
    IBOutlet NSButton* 		readIdButton;
    IBOutlet NSButton* 		resetButton;
	IBOutlet NSMatrix*		connectionProtocolMatrix;
	IBOutlet NSTextField*	ipConnectedTextField;
	IBOutlet NSTextField*	usbConnectedTextField;
	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSTabView*		connectionProtocolTabView;
	IBOutlet NSTextField*	connectionNoteTextField;
    IBOutlet NSButton* 		testButton;
    IBOutlet NSTextField*   lockDocField;
    IBOutlet NSButton*		lockButton;
    
	IBOutlet NSPopUpButton* serialNumberPopup;
	IBOutlet NSButton*		ipConnectButton;
	IBOutlet NSButton*		usbConnectButton;
    IBOutlet NSTextField*   commandField;
    IBOutlet NSButton*		sendCommandButton;
    IBOutlet NSButton*		loadParamsButton;
    IBOutlet ORCompositeTimeLineView*	plotter;
	IBOutlet NSPopUpButton* pollTimePopup;
    IBOutlet ORLakeShore336LinkView* linkView;
}

#pragma mark •••Notifications
- (void) connectionProtocolChanged:(NSNotification*)aNote;

#pragma mark ***Interface Management
- (void) canChangeConnectionProtocolChanged:(NSNotification*)aNote;
- (void) ipConnectedChanged:(NSNotification*)aNote;
- (void) usbConnectedChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) setButtonStates;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) updateLinkView:(NSNotification*)aNote;
- (NSColor*) colorForDataSet:(int)set;
- (NSMutableArray*) inputs;
- (NSMutableArray*) heaters;

#pragma mark •••Actions
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) ipAddressTextFieldAction:(id)sender;
- (IBAction) connectionProtocolAction:(id)sender;
- (IBAction) readIdAction:(id)sender;
- (IBAction) testAction:(id)sender;
- (IBAction) resetAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;
- (IBAction) connectAction: (id) aSender;
- (IBAction) loadParamsAction:(id)sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;

- (void) populateInterfacePopup;
- (void) validateInterfacePopup;
- (void) systemTest;

@end

@interface ORLakeShore336LinkView : NSView
{
}

@end
