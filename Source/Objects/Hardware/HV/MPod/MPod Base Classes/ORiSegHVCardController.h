//-------------------------------------------------------------------------
//  ORiSegHVCardController.h
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
#import "OrcaObjectController.h"

@class ORCompositeTimeLineView;
@class ORTimedTextField;

@interface ORiSegHVCardController : OrcaObjectController 
{
	IBOutlet NSTextField*	selectedChannelField;
	IBOutlet NSButton*		shipRecordsButton;
	IBOutlet NSTextField*	maxCurrentField;
	IBOutlet NSTextField*	eventField;
	IBOutlet NSTextField*	riseRateField;
    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      syncButton;
	IBOutlet NSTextField*	powerField;
	IBOutlet NSTableView*	hvTableView;
	IBOutlet NSImageView*	hvStatusImage;
	IBOutlet NSTextField*   temperatureField;
	IBOutlet NSTextField*   slotField;
	IBOutlet NSTextField*	hwGoalField;
	IBOutlet NSButton*      hvConstraintImage;
	IBOutlet NSTextField*   chanNameField;
    IBOutlet NSTextField*   maxVoltageField;
    IBOutlet NSTextField*   customInfoField;
	//details 
	IBOutlet NSTextField*	targetField;
	IBOutlet NSTextField*	voltageField;
	IBOutlet NSTextField*	stateField;
    IBOutlet NSButton*      powerOnButton;
    IBOutlet NSButton*      powerOffButton;
    IBOutlet NSButton*      stopRampButton;
    IBOutlet NSButton*      loadButton;
    IBOutlet NSButton*      rampToZeroButton;
    IBOutlet NSButton*      panicButton;
    IBOutlet NSButton*      clearPanicButton;
	
	//all channels
	IBOutlet NSTextField*	channelCountField;
    IBOutlet NSButton*      powerAllOnButton;
    IBOutlet NSButton*      powerAllOffButton;
    IBOutlet NSButton*      stopAllRampButton;
    IBOutlet NSButton*      loadAllButton;
    IBOutlet NSButton*      rampAllToZeroButton;
    IBOutlet NSButton*      panicAllButton;
    IBOutlet NSButton*      clearAllPanicButton;
    
    //module status
    IBOutlet NSTextField*   moduleStatusField;
    IBOutlet NSButton*      moduleClearButton;
    IBOutlet NSButton*      doNotPostSafetyLoopAlarmCB;
	
	IBOutlet ORCompositeTimeLineView*   currentPlotter;
	IBOutlet ORCompositeTimeLineView*   voltagePlotter;
	IBOutlet ORTimedTextField*    timeoutField;
}

#pragma mark •••Interface Management
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) updateButtons;
- (void) doNotPostSafetyLoopAlarmChanged:(NSNotification*)aNote;
- (void) constraintsChanged:(NSNotification*)aNote;
- (void) timeoutHappened:(NSNotification*)aNote;
- (void) shipRecordsChanged:(NSNotification*)aNote;
- (void) maxCurrentChanged:(NSNotification*)aNote;
- (void) selectedChannelChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) riseRateChanged:(NSNotification*)aNote;
- (void) targetChanged:(NSNotification*)aNote;
- (void) channelReadParamsChanged:(NSNotification*)aNote;
- (void) powerFailed:(NSNotification*)aNote;
- (void) powerRestored:(NSNotification*)aNote;
- (void) updateHistoryPlots:(NSNotification*)aNote;
- (void) outputStatusChanged:(NSNotification*)aNote;
- (void) maxVoltageChanged:(NSNotification*)aNote;
- (void) chanNameChanged:(NSNotification*)aNote;
- (void) customInfoChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) shipRecordsAction:(id)sender;
- (IBAction) maxCurrentAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) riseRateAction:(id)sender;
- (IBAction) targetAction:(id)sender;
- (IBAction) syncAction:(id)sender;
- (IBAction) loadAction:(id)sender;
- (IBAction) powerOnAction:(id)sender;
- (IBAction) powerOffAction:(id)sender;
- (IBAction) stopRampAction:(id)sender;
- (IBAction) rampToZeroAction:(id)sender;
- (IBAction) panicAction:(id)sender;
- (IBAction) clearPanicAction:(id)sender;
- (IBAction) incChannelAction:(id)sender;
- (IBAction) decChannelAction:(id)sender;
- (IBAction) listConstraintsAction:(id)sender;
- (IBAction) doNotPostSafetyLoopAlarmAction:(id)sender;

#pragma mark •••Actions for All
- (IBAction) powerAllOnAction:(id)sender;
- (IBAction) powerAllOffAction:(id)sender;
- (IBAction) stopAllRampAction:(id)sender;
- (IBAction) rampAllToZeroAction:(id)sender;
- (IBAction) panicAllAction:(id)sender;
- (IBAction) clearAllPanicAction:(id)sender;
- (IBAction) loadAllAction:(id)sender;
- (IBAction) cleadModuleAction:(id)sender;

#pragma mark •••Table Data Source Methods
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView;
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex;
- (void) tableView: (NSTableView*) aTableView setObjectValue: (id) anObject forTableColumn: (NSTableColumn*) aTableColumn row: (NSInteger) aRowIndex;

#pragma mark •••Plot Data Source
- (int)	numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
@end

@interface NSObject (ORiSegHVCardController)
- (BOOL) power;
@end
