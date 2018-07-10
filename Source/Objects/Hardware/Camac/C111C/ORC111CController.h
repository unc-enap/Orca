/*
 *  ORC111CController.h
 *  Orca
 *
 *  Created by Mark Howe on Mon Dec 10, 2007.
 *  Copyright (c) 2007 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORCC32Controller.h"

#pragma mark •••Forward Declarations
@class ORCompositePlotView;

@interface ORC111CController : ORCC32Controller {
	@private
		IBOutlet NSTextField*	ipConnectedTextField;
		IBOutlet NSButton*		trackTransactionsCB;
		IBOutlet NSTextField*	stationToTestTextField;
		IBOutlet NSTextField*	ipAddressTextField;
		IBOutlet NSButton*		ipConnectButton;
		IBOutlet NSButton*		sendAsciiCmdButton;
		IBOutlet NSTextField*	asciiCmdTextField;
		IBOutlet ORCompositePlotView*	plotter;
};

#pragma mark •••Initialization
-(id)init;
- (void) updatePlot;
- (BOOL) control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command;

#pragma mark •••Interface Management
- (void) trackTransactionsChanged:(NSNotification*)aNote;
- (void) stationToTestChanged:(NSNotification*)aNote;
- (void) setButtonStates;
- (void) registerNotificationObservers;
- (void) isConnectedChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) commandChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) trackTransactionsAction:(id)sender;
- (IBAction) testLAMForStationAction:(id)sender;
- (IBAction) stationToTestTextFieldAction:(id)sender;
- (IBAction) ipAddressTextFieldAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) sendAsciiCmd:(id)sender;
- (IBAction) clearTransactions:(id)sender;

- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end