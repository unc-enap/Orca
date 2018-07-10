//
//  ORDocumentController.h
//  Orca
//
//  Created by Mark Howe on Tue Dec 03 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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


@interface ORDocumentController : NSWindowController 
{
    IBOutlet ORGroupView*   groupView;
    IBOutlet NSTextField*   statusTextField;
    IBOutlet NSTextField*   lockStatusTextField;
    IBOutlet NSButton*      lockAllButton;
    IBOutlet NSOutlineView* outlineView;
    IBOutlet NSTextField*   scaleFactorField;
    IBOutlet NSTextField*   logStatusField;
    IBOutlet NSTextField*   debuggingStatusField;
    IBOutlet NSButton*      documentLockButton;
    IBOutlet NSButton*      openProductionModeButton;
    IBOutlet NSMatrix*      productionModeMatrix;
    IBOutlet NSPanel*       productionModePanel;
    IBOutlet NSTextField*   productionModeField;
	IBOutlet id             templates;
    
    NSImage* descendingSortingImage;
    NSImage* ascendingSortingImage;
    NSString *_sortColumn;
    BOOL _sortIsDescending;
    NSMutableArray*         draggedNodes;
}

- (void) preloadCatalog;

#pragma mark *Accessors
- (ORGroup *)group;
- (ORGroupView *)groupView;
- (NSTextField*) statusTextField;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) statusTextChanged:(NSNotification*)aNotification;
- (void) securityStateChanged:(NSNotification*)aNotification;
- (void) documentLockChanged:(NSNotification*)aNotification;
- (void) scaleFactorChanged:(NSNotification*)aNotification;
- (void) remoteScaleFactorChanged:(NSNotification*)aNotification;
- (void) numberLockedPagesChanged:(NSNotification*)aNotification;
- (void) windowOrderChanged:(NSNotification*)aNotification;
- (void) showTemplates:(NSNotification*)aNotification;
- (void) postLogChanged:(NSNotification*)aNotification;
- (void) debuggingSessionChanged:(NSNotification*)aNotification;
- (void) lostFocus:(NSNotification*)aNotification;
- (void) productionModeChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) openArchive:(NSToolbarItem*)item;
- (IBAction) statusLog:(NSToolbarItem*)item;
- (IBAction) printDocument:(id)sender;
- (IBAction) alarmMaster:(NSToolbarItem*)item;
- (IBAction) openCatalog:(NSToolbarItem*)item;
- (IBAction) openHWWizard:(NSToolbarItem*)item;
- (IBAction) openPreferences:(NSToolbarItem*)item;
- (IBAction) hardwareFinder:(NSToolbarItem*)item;
- (IBAction) documentLockAction:(id)sender;
- (IBAction) scaleFactorAction:(id)sender;
- (IBAction) lockAllAction:(id)sender;
- (IBAction) openCommandCenter:(NSToolbarItem*)item;
- (IBAction) openTaskMaster:(NSToolbarItem*)item; 
- (IBAction) openORCARootService:(NSToolbarItem*)item;
- (IBAction) openHelp:(NSToolbarItem*)item;
- (IBAction) doubleClick:(id)sender;
- (IBAction) openProductionModePanel:(id)sender;
- (IBAction) closeProductionModePanel:(id)sender;
- (IBAction) setProductionMode:(id)sender;

#pragma mark ¥¥¥Data Source
- (id)   outlineView:(NSOutlineView *)outlineView child:(NSUInteger)index ofItem:(id)item;
- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (int)  outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)  outlineView:(NSOutlineView *)outlineView  objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item;
- (void) outlineView:(NSOutlineView*)tv didClickTableColumn:(NSTableColumn *)tableColumn;
- (void) updateTableHeaderToMatchCurrentSort;
- (void)setSortColumn:(NSString *)identifier; 
- (NSString *)sortColumn;
- (void)setSortIsDescending:(BOOL)whichWay;
- (BOOL)sortIsDescending;
- (void)sort;
- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray*)writeItems toPasteboard:(NSPasteboard*)pboard;
- (NSArray*)draggedNodes;
- (void) dragDone;

@end
