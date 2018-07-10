//
//  ORMJDVacuumController.h
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright © 2012 CENPA, University of North Carolina. All rights reserved.
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


#pragma mark •••Forward Declarations
@class ORMJDVacuumView;

@interface ORMJDVacuumController : OrcaObjectController
{
    IBOutlet ORMJDVacuumView*   vacuumView;
	IBOutlet NSPopUpButton* coolerModePU;
	IBOutlet NSTextField*   noHVInfoField;
	IBOutlet NSTextField*   nextHvUpdateTimeField;
	IBOutlet NSTextField*   lastHvUpdateTimeField;
	IBOutlet NSTextField*   hvUpdateTimeField;
	IBOutlet NSButton*		setShowGridCB;
	IBOutlet NSPanel*		gvControlPanel;
	IBOutlet NSPanel*		gvConstraintPanel;
	IBOutlet NSButton*      gvControlButton;
	IBOutlet NSTextField*   gvControlField;
	IBOutlet NSTextField*   gvControlValveState;
	IBOutlet NSTextField*   gvControlPressureSide1;
	IBOutlet NSTextField*   gvOpenToText1;
	IBOutlet NSTextField*   gvControlPressureSide2;
	IBOutlet NSTextField*   gvOpenToText2;
	IBOutlet NSTableView*   valueTableView;
	IBOutlet NSTableView*   statusTableView;
	IBOutlet NSTableView*   gvTableView;
	IBOutlet NSTextField*   gvHwObjectName;
    IBOutlet NSButton*      lockButton;
	IBOutlet ORGroupView*   subComponentsView;
	IBOutlet NSTextView*    gvConstraintView;
	IBOutlet NSTextField*   constraintTitleField;
	IBOutlet NSTextField*   detectorStatusField;
	IBOutlet NSTextField*   constraintStatusField;
	IBOutlet NSTextField*   constraintOverrideField;
    IBOutlet NSButton*      overRideButton;
    IBOutlet NSTextField*   spikeValueField;

	BOOL					updateScheduled;
}

- (id) init;
- (void) awakeFromNib;

#pragma mark *Accessors
- (BOOL) showGrid;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) showGridChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) groupChanged:(NSNotification*)aNote;
- (void) toggleGrid;

#pragma mark ***Interface Management
- (void) coolerModeChanged:(NSNotification*)aNote;
- (void) nextHvUpdateTimeChanged:(NSNotification*)aNote;
- (void) lastHvUpdateTimeChanged:(NSNotification*)aNote;
- (void) hvUpdateTimeChanged:(NSNotification*)aNote;
- (void) detectorsBiasedChanged:(NSNotification*)aNote;
- (void) localConstraintsChanged:(NSNotification*)aNote;
- (void) vetoMaskChanged:(NSNotification*)aNote;
- (void) stateChanged:(NSNotification*)aNote;
- (void) delayedRefresh;
- (void) constraintsDisabledChanged:(NSNotification*)aNote;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) toggleSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
#pragma mark •••Actions
- (IBAction) coolerModeAction:(id)sender;
- (IBAction) showGridAction:(id)sender;
- (IBAction) openGVControlPanel:(id)sender;
- (IBAction) closeGVChangePanel:(id)sender;
- (IBAction) changeGVAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) closeGVConstraintPanel:(id)sender;
- (IBAction) overRideAction:(id)sender;
- (IBAction) reportConstraints:(id)sender;
- (IBAction) spikeValueAction:(id)sender;

#pragma mark •••Data Source For Tables
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn 
			 row:(NSInteger) rowIndex;

@end

