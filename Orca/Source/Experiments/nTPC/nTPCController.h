//
//  nTPCController.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 15 2007.
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

@class ORColorScale;
@class ORSegmentGroup;
@class ORAxis;

@interface nTPCController : ORExperimentController {

    IBOutlet NSTextField*	secondaryRateField;
	IBOutlet NSMatrix*		planeMaskMatrix;
    IBOutlet NSTextField*	tertiaryRateField;
    IBOutlet NSTextField*	detectorTitle;
    IBOutlet ORAxis*		xAxis;
    IBOutlet ORAxis*		colorAxis;
   
	//items in the  HW map tab view
	IBOutlet NSPopUpButton* secondaryAdcClassNamePopup;
	IBOutlet NSTextField*	secondaryMapFileTextField;
    IBOutlet NSButton*		readSecondaryMapFileButton;
    IBOutlet NSButton*		saveSecondaryMapFileButton;
    IBOutlet NSTableView*	secondaryTableView;	
	
	//items in the  HW map tab view
	IBOutlet NSPopUpButton* tertiaryAdcClassNamePopup;
	IBOutlet NSTextField*	tertiaryMapFileTextField;
    IBOutlet NSButton*		readTertiaryMapFileButton;
    IBOutlet NSButton*		saveTertiaryMapFileButton;
    IBOutlet NSTableView*	tertiaryTableView;
	
	
    IBOutlet NSButton*		clrSelectionButton;
    IBOutlet NSButton*		showDialogButton;

	//items in the  details tab view
    IBOutlet NSTableView*	secondaryValuesView;
    IBOutlet NSTableView*	tertiaryValuesView;
}

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ¥¥¥HW Map Actions
- (IBAction) planeMaskAction:(id)sender;
- (IBAction) secondaryAdcClassNameAction:(id)sender;
- (IBAction) readSecondaryMapFileAction:(id)sender;
- (IBAction) saveSecondaryMapFileAction:(id)sender;
- (IBAction) tertiaryAdcClassNameAction:(id)sender;
- (IBAction) readTertiaryMapFileAction:(id)sender;
- (IBAction) saveTertiaryMapFileAction:(id)sender;
- (IBAction) clrSelectionAction:(id)sender;
- (IBAction) viewDialogAction:(id)sender;

#pragma mark ¥¥¥HW Map Interface Management
- (void) planeMaskChanged:(NSNotification*)aNote;
- (void) secondaryAdcClassNameChanged:(NSNotification*)aNote;
- (void) secondaryMapFileChanged:(NSNotification*)aNote;
- (void) selectionChanged:(NSNotification*)aNote;
- (void) tertiaryAdcClassNameChanged:(NSNotification*)aNote;
- (void) tertiaryMapFileChanged:(NSNotification*)aNote;
- (void) selectionChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Details Interface Management
- (void) setDetectorTitle;

#pragma mark ¥¥¥Table Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn 
                                row:(int) rowIndex;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject 
            forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void) tableView:(NSTableView*)tv didClickTableColumn:(NSTableColumn *)tableColumn;
//- (void) updateTableHeaderToMatchCurrentSort;
 

@end
