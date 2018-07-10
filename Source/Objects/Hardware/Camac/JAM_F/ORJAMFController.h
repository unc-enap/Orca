
/*
 *  ORJAMFModelController.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORJAMFModel.h"

@class ORCompositeTimeLineView;

@interface ORJAMFController : OrcaObjectController {
	@private
        IBOutlet NSButton*		settingLockButton;
		IBOutlet NSButton*		shipRecordsButton;
		IBOutlet NSButton*		scanEnabledCB;
		IBOutlet NSMatrix*		scanLimitMatrix;
		IBOutlet NSPopUpButton* pollingStatePopup;
		IBOutlet NSTextField*	lastReadTextField;
		IBOutlet NSPopUpButton* rangeIndexPopup0; //...because you can't have a matrix of popup's. argghhhhh!
		IBOutlet NSPopUpButton* rangeIndexPopup1;
		IBOutlet NSPopUpButton* rangeIndexPopup2;
		IBOutlet NSPopUpButton* rangeIndexPopup3;
		IBOutlet NSPopUpButton* rangeIndexPopup4;
		IBOutlet NSPopUpButton* rangeIndexPopup5;
		IBOutlet NSPopUpButton* rangeIndexPopup6;
		IBOutlet NSPopUpButton* rangeIndexPopup7;
		IBOutlet NSPopUpButton* rangeIndexPopup8;
		IBOutlet NSPopUpButton* rangeIndexPopup9;
		IBOutlet NSPopUpButton* rangeIndexPopup10;
		IBOutlet NSPopUpButton* rangeIndexPopup11;
		IBOutlet NSPopUpButton* rangeIndexPopup12;
		IBOutlet NSPopUpButton* rangeIndexPopup13;
		IBOutlet NSPopUpButton* rangeIndexPopup14;
		IBOutlet NSPopUpButton* rangeIndexPopup15;
		IBOutlet NSMatrix*		enabledMaskMatrix;
		IBOutlet NSMatrix*		alarmsEnabledMaskMatrix;
		IBOutlet NSMatrix*		lowLimitsMatrix;
		IBOutlet NSMatrix*		highLimitsMatrix;
		IBOutlet NSMatrix*		adcValueMatrix;
        IBOutlet NSButton*		initButton;
        IBOutlet NSButton*		readIdButton;
        IBOutlet NSTextField*   settingLockDocField;
        IBOutlet ORCompositeTimeLineView*	plotter0;
        IBOutlet ORCompositeTimeLineView*	plotter1;
        IBOutlet ORCompositeTimeLineView*	plotter2;
        IBOutlet ORCompositeTimeLineView*	plotter3;
 };

- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) shipRecordsChanged:(NSNotification*)aNote;
- (void) scanEnabledChanged:(NSNotification*)aNote;
- (void) scanLimitChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) pollingStateChanged:(NSNotification*)aNote;
- (void) lastReadChanged:(NSNotification*)aNote;
- (void) rangeIndexChanged:(NSNotification*)aNote;
- (void) enabledMaskChanged:(NSNotification*)aNote;
- (void) alarmsEnabledMaskChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) lowLimitChanged:(NSNotification*)aNote;
- (void) highLimitChanged:(NSNotification*)aNote;
- (void) adcValueChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;

#pragma mark •••Accessors

#pragma mark •••Actions
- (IBAction) shipRecordsAction:(id)sender;
- (IBAction) scanEnabledAction:(id)sender;
- (IBAction) scanLimitAction:(id)sender;
- (IBAction) pollingStatePopupAction:(id)sender;
- (IBAction) readAdcsAction:(id)sender;
- (IBAction) initAction:(id)sender;
- (IBAction) rangeIndexPopupAction:(id)sender;
- (IBAction) enabledMaskMatrixAction:(id)sender;
- (IBAction) alarmsEnabledMaskMatrixAction:(id)sender;
- (IBAction) lowLimitsMatrixAction:(id)sender;
- (IBAction) highLimitsMatrixAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) readID:(id) sender;

 - (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i;
 - (void) showError:(NSException*)anException name:(NSString*)name;

- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;


@end