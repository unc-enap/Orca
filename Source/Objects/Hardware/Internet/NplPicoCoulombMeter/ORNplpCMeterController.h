//
//  ORHPNplpCMeterController.h
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#import "OrcaObjectController.h"

@interface ORNplpCMeterController : OrcaObjectController 
{
	IBOutlet NSTabView*		tabView;
	IBOutlet NSView*		totalView;
	IBOutlet NSTextField*	ipConnectedTextField;
	IBOutlet NSTextField*	ipConnected2TextField;
	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSButton*		ipConnectButton;
	IBOutlet NSTextField*	frameErrorField;
	IBOutlet NSTextField*	receiveCountField;
	IBOutlet NSMatrix*		averageValueMatrix;
	IBOutlet NSButton*		dialogLock;
    IBOutlet NSMatrix*		lowLimitMatrix;
	IBOutlet NSMatrix*		hiLimitMatrix;
	IBOutlet NSMatrix*		minValueMatrix;
	IBOutlet NSMatrix*		maxValueMatrix;

	NSSize					ipConnectionSize;
	NSSize					statusSize;
	NSSize					processSize;
	NSView*					blankView;

}

#pragma mark ***Interface Management
- (void) receiveCountChanged:(NSNotification*)aNote;
- (void) isConnectedChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) frameErrorChanged:(NSNotification*)aNote;
- (void) averageChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) minValueChanged:(NSNotification*)aNote;
- (void) maxValueChanged:(NSNotification*)aNote;
- (void) lowLimitChanged:(NSNotification*)aNote;
- (void) hiLimitChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) ipAddressTextFieldAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) dialogLockAction:(id)sender;
- (IBAction) minValueAction:(id)sender;
- (IBAction) maxValueAction:(id)sender;
- (IBAction) lowLimitAction:(id)sender;
- (IBAction) hiLimitAction:(id)sender;

@end

