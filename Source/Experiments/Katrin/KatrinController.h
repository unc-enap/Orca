//
//  KatrinController.h
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORExperimentController.h"
#import "KatrinDetectorView.h"

@class ORColorScale;
@class ORSegmentGroup;
@class ORBasicOpenGLView;

@interface KatrinController : ORExperimentController {
 
    IBOutlet ORBasicOpenGLView*  openGlView;
    IBOutlet ORColorScale*	secondaryColorScale;
	IBOutlet NSTextField*   fpdOnlyModeField;
	IBOutlet NSButton*      fpdOnlyModeButton;
	IBOutlet NSTextField*	slowControlNameField;
	IBOutlet NSTextField*	slowControlIsConnectedField;
	IBOutlet NSTextField*	slowControlIsConnectedField1;
    IBOutlet NSButton*		secondaryColorAxisLogCB;
    IBOutlet NSTextField*	secondaryRateField;
    IBOutlet NSTextField*	detectorTitle;
    
	//items in the  HW map tab view
	IBOutlet NSPopUpButton* secondaryAdcClassNamePopup;
	IBOutlet NSTextField*	secondaryMapFileTextField;
    IBOutlet NSButton*		readSecondaryMapFileButton;
    IBOutlet NSButton*		saveSecondaryMapFileButton;
    IBOutlet NSTableView*	secondaryTableView;

	//SN tables
	IBOutlet NSTableView*	fltSNTableView;
	IBOutlet NSTableView*	preAmpSNTableView;
	IBOutlet NSTableView*	osbSNTableView;
	IBOutlet NSTableView*	otherSNTableView;

	//items in the  details tab view
    IBOutlet NSTableView*	secondaryValuesView;
    IBOutlet NSPopUpButton*	viewTypePU;
    IBOutlet NSTabView*     viewTabView;

	IBOutlet NSTextField*	fltOrbSNField;
	IBOutlet NSTextField*	osbSNField;
	IBOutlet NSTextField*	preampSNField;
	IBOutlet NSTextField*	sltWaferSNField;

	IBOutlet NSMatrix*		lowLimitMatrix;
	IBOutlet NSMatrix*		hiLimitMatrix;
	IBOutlet NSMatrix*		maxValueMatrix;
    
	IBOutlet NSButton*		vetoMapLockButton;
    IBOutlet ORColorScale*  focalPlaneColorScale;
	
	NSView *blankView;
    NSSize detectorSize;
    NSSize slowControlsSize;
    NSSize detailsSize;
    NSSize focalPlaneSize;
    NSSize vetoSize;	
}

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ¥¥¥HW Map Actions
- (IBAction) fpdOnlyModeAction:(id)sender;
- (IBAction) slowControlNameAction:(id)sender;
- (IBAction) secondaryAdcClassNameAction:(id)sender;
- (IBAction) readSecondaryMapFileAction:(id)sender;
- (IBAction) saveSecondaryMapFileAction:(id)sender;
- (IBAction) viewTypeAction:(id)sender;
- (IBAction) maxValueAction:(id)sender;
- (IBAction) lowLimitAction:(id)sender;
- (IBAction) hiLimitAction:(id)sender;
- (IBAction) vetoMapLockAction:(id)sender;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) toggleSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
#pragma mark ¥¥¥Detector Interface Management
- (void) fpdOnlyModeChanged:(NSNotification*)aNote;
- (void) slowControlNameChanged:(NSNotification*)aNote;
- (void) slowControlIsConnectedChanged:(NSNotification*)aNote;
- (void) secondaryColorAxisAttributesChanged:(NSNotification*)aNote;
- (void) snTablesChanged:(NSNotification*)aNote;
- (void) maxValueChanged:(NSNotification*)aNote;
- (void) lowLimitChanged:(NSNotification*)aNote;
- (void) hiLimitChanged:(NSNotification*)aNote;
- (IBAction) autoscaleSecondayColorScale:(id)sender;

#pragma mark ¥¥¥HW Map Interface Management
- (void) secondaryAdcClassNameChanged:(NSNotification*)aNote;
- (void) secondaryMapFileChanged:(NSNotification*)aNote;
- (void) vetoMapLockChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Details Interface Management
- (void) setDetectorTitle;
- (void) viewTypeChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Table Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn 
                                row:(int) rowIndex;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject 
            forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem;

- (ORSegmentGroup*) segmentGroup:(int)aSet;


@end
@interface ORDetectorView (Katrin)
- (void) setViewType:(int)aState;
@end
