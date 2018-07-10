
//
//  ORTristanFLTController.h
//  Orca
//
//  Created by Mark Howe on 1/23/18.
//  Copyright 2018, University of North Carolina. All rights reserved.
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
#import "ORTristanFLTModel.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORTristanFLTController : OrcaObjectController {
	@private
		IBOutlet NSTabView*		tabView;	
        IBOutlet NSTextField*   gapLengthField;
        IBOutlet NSTextField*   shapingLengthField;
        IBOutlet NSMatrix*      thresholdMatrix;
        IBOutlet NSMatrix*      enabledMatrix;
        IBOutlet NSTextField*   udpFrameSizeField;
		IBOutlet NSTextField*   postTriggerTimeField;
        IBOutlet NSTextField*   slotNumField;
		IBOutlet NSButton*		initBoardButton;
		IBOutlet NSButton*		defaultsButton;
        IBOutlet NSButton*      settingLockButton;
        IBOutlet NSButton*      connectButton;
        IBOutlet NSTextField*   hostNameField;
        IBOutlet NSTextField*   portField;
        IBOutlet NSTextField*   udpConnectedField;

		//rate page
		IBOutlet NSMatrix*		            rateTextFields;
		IBOutlet ORValueBarGroupView*		rate0;
		IBOutlet ORValueBarGroupView*		totalRate;
		IBOutlet NSButton*					rateLogCB;
		IBOutlet ORCompositeTimeLineView*	timeRatePlot;
		IBOutlet NSButton*		            timeRateLogCB;
		IBOutlet NSButton*		            totalRateLogCB;
		IBOutlet NSTextField*	            totalHitRateField;
		IBOutlet NSView*		            totalView;
		
		NSNumberFormatter*		rateFormatter;
		NSSize					settingSize;
		NSSize					rateSize;
		NSView*					blankView;
 };

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (void) shapingLengthChanged:(NSNotification*)aNote;
- (void) gapLengthChanged:(NSNotification*)aNote;
- (void) postTriggerTimeChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) enabledChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) hostNameChanged:(NSNotification*)aNote;
- (void) portChanged:(NSNotification*)aNote;

#pragma mark ***Security
- (void) checkGlobalSecurity;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) updateButtons;

#pragma mark ***Actions
- (IBAction) shapingLengthAction:(id)sender;
- (IBAction) gapLengthAction:(id)sender;
- (IBAction) postTriggerTimeAction:(id)sender;
- (IBAction) setDefaultsAction: (id) sender;
- (IBAction) writeThresholds:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) enableAction:(id)sender;
- (IBAction) initBoardAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) resetAction: (id) sender;
- (IBAction) loadThresholdsAction: (id) sender;
- (IBAction) udpFrameSizeAction:(id)sender;
- (IBAction) hostNameAction:(id)sender;
- (IBAction) portAction:(id)sender;
- (IBAction) connectAction:(id)sender;

#pragma mark ***Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
@end




