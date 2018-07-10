//
//  ORHistoController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 23 2002.
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



@interface ORHistoController : OrcaObjectController  {
    IBOutlet NSSplitView*	splitView;
	IBOutlet NSButton*		accumulateCB;
	IBOutlet NSButton*		shipFinalHistogramsButton;
    IBOutlet NSOutlineView* outlineView;
    IBOutlet NSOutlineView* multiPlotView;
    IBOutlet NSButton* 		chooseDirButton;
    IBOutlet NSTextField* 	involvedInRunField;
    IBOutlet NSTextField* 	dirTextField;
    IBOutlet NSTextField* 	fileTextField;
    IBOutlet NSButton* 		writeFileButton;
    IBOutlet NSButton* 		clearAllButton;
    IBOutlet NSButton* 		plotGroupButton;
    IBOutlet NSButton* 		disableDecodingButton;
    IBOutlet NSTextField*   decodingDisabledField;
    BOOL                    scheduledToUpdate;
}

#pragma mark ¥¥¥Interface Management
- (void) decodingDisabledChanged:(NSNotification *)aNote;
- (void) accumulateChanged:(NSNotification*)aNote;
- (void) involvedInCurrentRunChanged:(NSNotification *)aNote;
- (void) shipFinalHistogramsChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) modelChanged:(NSNotification*)aNotification;
- (void) dirChanged:(NSNotification*)note;
- (void) fileChanged:(NSNotification*)note;
- (void) writeFileChanged:(NSNotification*)note;
- (void) dataChanged:(NSNotification*)aNotification;
- (void) setButtonStates;
- (void) doUpdate;
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem;
- (void) multiPlotsChanged:(NSNotification*)aNotification;
- (void) outlineViewSelectionDidChange:(NSNotification *)notification;
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) decodingDisabledAction:(id)sender;
- (IBAction) accumulateAction:(id)sender;
- (IBAction) getInfo:(id)sender;
- (IBAction) shipFinalHistogramsAction:(id)sender;
- (IBAction) doubleClick:(id)sender;
- (IBAction) chooseDir:(id)sender;
- (IBAction) writeFileAction:(id)sender;
- (IBAction) clearAllAction:(id)sender;
- (IBAction) removeItemAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) plotGroupAction:(id)sender;
- (IBAction) doubleClickMultiPlot:(id)sender;

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void)_clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif

#pragma mark ¥¥¥Data Source Methods
- (BOOL) outlineView:(NSOutlineView*)ov isItemExpandable:(id)item;
- (int)  outlineView:(NSOutlineView*)ov numberOfChildrenOfItem:(id)item;
- (id)   outlineView:(NSOutlineView*)ov child:(NSUInteger)index ofItem:(id)item;
- (id)   outlineView:(NSOutlineView*)ov objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item;

@end
