//
//  ORFecDaughterCardController.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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
#import "ORFecDaughterCardModel.h"

@interface ORFecDaughterCardController : OrcaObjectController  {
	@private
    IBOutlet NSImageView* imgView;
    IBOutlet NSButton *lockButton;
    IBOutlet NSButton* setAllCmosButton;
	IBOutlet NSMatrix* rp1Matrix;
	IBOutlet NSMatrix* rp2Matrix;
	IBOutlet NSMatrix* vliMatrix;
	IBOutlet NSMatrix* vsiMatrix;
    IBOutlet NSMatrix* vt_ecalMatrix;
    IBOutlet NSMatrix* vt_zeroMatrix;
    IBOutlet NSMatrix* vt_corrMatrix;
    IBOutlet NSTextField* vtSaferyField;
	IBOutlet NSMatrix* vbMatrix;
	IBOutlet NSTextField* ns100widthField;
	IBOutlet NSTextField* ns20widthField;
	IBOutlet NSTextField* ns20delayField;
	IBOutlet NSTextField* tac0trimField;
	IBOutlet NSTextField* tac1trimField;
	IBOutlet NSTextField* cmosRegShownField;
	IBOutlet NSTextField* cmosRegShownField1;
    IBOutlet NSButton*	  showVoltsCB;
    IBOutlet NSTextField* commentsTextField;
    IBOutlet NSTextField* cardLabelField;
    IBOutlet NSTextField* dcNumberField;
    IBOutlet NSTextField* fecNumberField;
    IBOutlet NSTextField* crateNumberField;
    IBOutlet NSTextField* boardIdField;
    IBOutlet NSButton *setThresCorrButton;
    IBOutlet NSButton *zeroCorrButton;
		
    NSNumberFormatter*		valueFormatter;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) checkGlobalSecurity;

#pragma mark •••Interface Management
- (void) everythingChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNotification;
- (void) commentsChanged:(NSNotification*)aNote;
- (void) showVoltsChanged:(NSNotification*)aNote;
- (void) setAllCmosChanged:(NSNotification*)aNote;
- (void) cmosRegShownChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) rp1Changed:(NSNotification*)aNote;
- (void) rp2Changed:(NSNotification*)aNote; 
- (void) vliChanged:(NSNotification*)aNote; 
- (void) vsiChanged:(NSNotification*)aNote; 
- (void) vtChanged:(NSNotification*)aNote; 
- (void) vbChanged:(NSNotification*)aNote; 	   
- (void) ns100widthChanged:(NSNotification*)aNote; 			   
- (void) ns20widthChanged:(NSNotification*)aNote; 
- (void) ns20delayChanged:(NSNotification*)aNote; 
- (void) tac0trimChanged:(NSNotification*)aNote; 	   
- (void) tac1trimChanged:(NSNotification*)aNote;
- (void) boardIdChanged:(NSNotification*)aNote;
- (void) keyDown:(NSEvent*)event;
- (void) cancelOperation:(id)sender;

#pragma mark •••Actions
- (IBAction) lockAction:(id)sender;
- (IBAction) showVoltsAction:(id)sender;
- (IBAction) setAllCmosAction:(id)sender;
- (IBAction) incCmosRegAction:(id)sender;
- (IBAction) decCmosRegAction:(id)sender;
- (IBAction) incCardAction:(id)sender;
- (IBAction) decCardAction:(id)sender;
- (IBAction) rp1Action:(id)sender;
- (IBAction) rp2Action:(id)sender; 
- (IBAction) vliAction:(id)sender; 
- (IBAction) vsiAction:(id)sender; 
- (IBAction) vt_ecalAction:(id)sender;
- (IBAction) vt_corrAction:(id)sender;
- (IBAction) vtSetAction:(id)sender;
- (IBAction) vtZeroCorrAction:(id)sender;
- (IBAction) vtSafetyAction:(id)sender;
- (IBAction) vbAction:(id)sender;
- (IBAction) ns100widthAction:(id)sender; 			   
- (IBAction) ns20widthAction:(id)sender; 
- (IBAction) ns20delayAction:(id)sender; 
- (IBAction) tac0trimAction:(id)sender; 	   
- (IBAction) tac1trimAction:(id)sender;

@end
