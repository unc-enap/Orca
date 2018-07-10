//
//  ORMacController.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
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



#pragma mark ¥¥¥Forward Declarations
@class ORGroup;
@class ORGroupView;

@interface ORMacController : OrcaObjectController
{
    IBOutlet ORGroupView*	groupView;
    IBOutlet NSTextField*	lockDocField;
    IBOutlet NSTableView*	serialPortView;
    IBOutlet NSTableView*	usbDevicesView;
    IBOutlet NSTabView*		tabView;	
    IBOutlet NSTextField*	selectedPortNameField;
    IBOutlet NSButton*		openPortButton;
    IBOutlet NSPopUpButton* speedPopUp;
    IBOutlet NSPopUpButton* parityPopUp;
    IBOutlet NSPopUpButton* stopBitsPopUp;
    IBOutlet NSPopUpButton* dataBitsPopUp;
    IBOutlet NSTextField*	cmdField;
    IBOutlet NSTextView*	outputView;
    IBOutlet NSButton*		sendCmdButton;
    IBOutlet NSButton*		sendCntrlCButton;
    IBOutlet NSButton*		clearDisplayButton;
	IBOutlet NSMatrix*		eolTypeMatrix;
    IBOutlet NSButton*		listFireWireDevicesButton;
    IBOutlet NSTextView*	usbDetailsView;
  
    NSSize pciSize;
    NSSize serialSize;
    NSSize usbSize;
    NSView *blankView;
}

#pragma mark *Accessors
- (ORGroupView *)groupView;
- (NSTabView*) tabView;
- (void) selectPortAtIndex:(int)index;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) updateUSBView;

#pragma mark ***Interface Management
- (void) eolTypeChanged:(NSNotification*)aNote;
- (void) documentLockChanged:(NSNotification*)aNotification;
- (void) groupChanged:(NSNotification*)note;
- (void) tableViewSelectionDidChange:(NSNotification*)aNote;
- (void) dataReceived:(NSNotification*)note;
- (void) serialPortListChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) listSupportedUSBDevices:(id)sender;
- (IBAction) eolTypeAction:(id)sender;
- (IBAction) openPortAction:(id)sender;
- (IBAction) optionAction:(id)sender;
- (IBAction) sendAction:(id)sender;
- (IBAction) sendCntrlCAction:(id)sender;
- (IBAction) clearDisplayAction:(id)sender;

@end

