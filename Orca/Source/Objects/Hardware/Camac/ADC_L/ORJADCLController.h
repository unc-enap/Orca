
/*
 *  ORJADCLModelController.h
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

#pragma mark ¥¥¥Imported Files
#import "ORJADCLModel.h"

@class ORCompositeTimeLineView;

@interface ORJADCLController : OrcaObjectController {
	@private
        IBOutlet NSButton*		settingLockButton;
		IBOutlet NSPopUpButton* pollingStatePopup;
		IBOutlet NSTextField*	lastReadTextField;
		IBOutlet NSPopUpButton* rangeIndexPopup;
		IBOutlet NSMatrix*		enabledMaskMatrix;
		IBOutlet NSMatrix*		alarmsEnabledMaskMatrix;
		IBOutlet NSMatrix*		lowLimitsMatrix;
		IBOutlet NSMatrix*		highLimitsMatrix;
		IBOutlet NSMatrix*		adcValueMatrix;
        IBOutlet NSTextField*   settingLockDocField;
        IBOutlet ORCompositeTimeLineView*	plotter0;
        IBOutlet ORCompositeTimeLineView*	plotter1;
        IBOutlet ORCompositeTimeLineView*	plotter2;
        IBOutlet ORCompositeTimeLineView*	plotter3;
 };

- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
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

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions
- (IBAction) pollingStatePopupAction:(id)sender;
- (IBAction) readAdcsAction:(id)sender;
- (IBAction) initAction:(id)sender;
- (IBAction) rangeIndexPopupAction:(id)sender;
- (IBAction) enabledMaskMatrixAction:(id)sender;
- (IBAction) alarmsEnabledMaskMatrixAction:(id)sender;
- (IBAction) lowLimitsMatrixAction:(id)sender;
- (IBAction) highLimitsMatrixAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) readLimitsAction:(id)sender;

 - (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i;
 - (void) showError:(NSException*)anException name:(NSString*)name;

- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end