//
//  ORBootBarController.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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

#import "OrcaObjectController.h"
#import "ORBootBarController.h"

@class BootBarStateView;
@class ORDotImage;

@interface ORBootBarController : OrcaObjectController 
{
	IBOutlet NSButton*		lockButton;
	IBOutlet NSButton*		clrHistoryButton;
	IBOutlet NSSecureTextField* passwordField;
	IBOutlet NSComboBox*	ipNumberComboBox;
	IBOutlet BootBarStateView* stateView;
	IBOutlet NSTextField*   busyField;
    IBOutlet NSMatrix*		outletNameMatrix;
    IBOutlet NSMatrix*		stateMatrix;
    IBOutlet NSMatrix*		turnOnOffMatrix;
}

#pragma mark •••Initialization
- (id)	 init;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) passwordChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) ipNumberChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (void) outletStatusChanged:(NSNotification*)aNote;
- (void) busyStateChanged:(NSNotification*)aNote;
- (void) outletNameChanged:(NSNotification*)aNotification;

#pragma mark •••Actions
- (IBAction) passwordFieldAction:(id)sender;
- (IBAction) ipNumberAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) clearHistoryAction:(id)sender;
- (IBAction) outletNameAction:(id)sender;
- (IBAction) turnOnOffAction:(id)sender;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) confirmDidFinish:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
@end


@interface BootBarStateView : NSView {
    ORDotImage* onLight;
    ORDotImage* offLight;
    int stateMask;
}

- (id)   initWithFrame:(NSRect)frame;
- (void) dealloc;
- (void) setStateMask:(unsigned char)aState;
- (void) drawRect:(NSRect)rect;
@end
