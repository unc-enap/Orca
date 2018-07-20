//
//  ORDataExplorerController.h
//  Orca
//
//  Created by Mark Howe on Sun Dec 05 2004.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


@class ORDataSet;
@class ORTimedTextField;

@interface ORDataExplorerController : OrcaObjectController  {
    @private
        IBOutlet NSButton*          selectFileButton;
		IBOutlet NSButton*			headerOnlyCB;
		IBOutlet NSButton*			multiCatalogCB;
        IBOutlet NSButton*          parseButton;
        IBOutlet NSButton*          clearCountsButton;
        IBOutlet NSButton*          scanNextButton;
        IBOutlet NSButton*          stopScanButton;
        IBOutlet NSButton*          scanPreviousButton;
        IBOutlet NSButton*          catalogAllButton;
        IBOutlet NSButton*          flushButton;
        IBOutlet NSTextField*		fileNameField;
        IBOutlet NSOutlineView*		headerView;
        IBOutlet NSTableView*		dataView;
        IBOutlet NSTextView*		detailsView;
        IBOutlet NSOutlineView*     dataCatalogView;
        IBOutlet NSProgressIndicator*     parseProgressBar;
        IBOutlet NSTextField*		multiCatalogWarningField;
		
        BOOL                        scheduledToUpdate;
        int32_t                        currentSearchIndex;
        BOOL                        stopScan;
        BOOL                        scanInProgress;

}

#pragma mark ¥¥¥Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ¥¥¥Accessors
- (void) setScanInProgress:(BOOL)state;

#pragma  mark ¥¥¥Actions
- (IBAction) headerOnlyAction:(id)sender;
- (IBAction) multiCatalogAction:(id)sender;
- (IBAction) catalogAllAction:(id)sender;
- (IBAction) scanNextButtonAction:(id)sender;
- (IBAction) stopScanButtonAction:(id)sender;
- (IBAction) scanPreviousButtonAction:(id)sender;
- (IBAction) selectFileButtonAction:(id)sender;
- (IBAction) clearCountsButtonAction:(id)sender;
- (IBAction) parseButtonAction:(id)sender;
- (IBAction) flushButtonAction:(id)sender;
- (IBAction) removeItemAction:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction) doubleClick:(id)sender;

#pragma mark ¥¥¥Timer Methods
- (void) scanForNext:(id)currentDataName;
- (void) scanForPrevious:(id)currentDataName;
- (void) catalogAll;
- (void) updateProgress;

#pragma mark ¥¥¥Interface Management
- (void) headerOnlyChanged:(NSNotification*)aNote;
- (void) histoErrorFlagChanged:(NSNotification*)aNote;
- (void) multiCatalogChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) updateWindow;

- (void) fileNameChanged:(NSNotification*)note;
- (void) fileParseStarted:(NSNotification*)note;
- (void) fileParseEnded:(NSNotification*)note;
- (void) dataChanged:(NSNotification*)note;
- (void) updateButtons;
- (void) doUpdate;
- (void) process:(uint32_t)row;


#pragma mark ¥¥¥Data Source Methods
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification;
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item; 
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item; 
- (NSUInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;

#pragma mark ¥¥¥Delegate Methods
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item;
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

@end
