//
//  ORDataTaskContoller.h
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
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


#pragma mark ¥¥¥Forward Declarations
@class ORValueBar;
@class ORCompositePlotView;
@class ORValueBarGroupView;

@interface ORDataTaskController : OrcaObjectController {
    IBOutlet NSDrawer*      totalListViewDrawer;
    IBOutlet NSOutlineView* totalListView;
    IBOutlet NSOutlineView* readoutListView;
    IBOutlet NSButton*      removeButton;
    IBOutlet NSButton*      removeAllButton;
    IBOutlet NSTabView*     tabView;
	IBOutlet NSTextField*   cycleRateField;
    IBOutlet NSButton*      listLockButton;
    IBOutlet NSButton*      viewListButton;
    IBOutlet NSButton*      saveAsButton;
    IBOutlet NSButton*      loadListButton;
	IBOutlet NSMatrix*		timeScaleMatrix;
	IBOutlet NSPopUpButton* refreshRatePU;
    IBOutlet NSButton*      refreshButton;
    IBOutlet NSButton*      clearButton;
	IBOutlet NSTextField*	timerEnabledWarningField;
	IBOutlet ORCompositePlotView*		plotter;
    IBOutlet ORValueBarGroupView*    queueBarGraph;
    NSMutableArray*         draggedNodes;
	float					refreshDelay;
}

- (NSArray*)draggedNodes;
- (void) dragDone;
- (void) setButtonStates;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) reloadObjects:(NSNotification*)aNote;
- (void) listLockChanged:(NSNotification*)aNotification;
- (void) timeScalerChanged:(NSNotification*)aNotification;
- (void) cycleRateChanged:(NSNotification*)aNote;
- (void) queueCountChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) clearAction:(id)sender;
- (IBAction) refreshRateAction:(id)sender;
- (IBAction) tableClick:(id)sender;
- (IBAction) tableDoubleClick:(id)sender;
- (IBAction) removeItemAction:(id)sender;
- (IBAction) removeAllAction:(id)sender;
- (IBAction) listLockAction:(id)sender;
- (IBAction) saveAsAction:(id)sender;
- (IBAction) loadListAction:(id)sender;
- (IBAction) timeScaleAction:(id)sender;
- (IBAction) refreshTimeAction:(id)sender;
- (IBAction) enableTimer:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;

- (void) doTimedRefresh;

#pragma mark ¥¥¥Data Source Methods
- (BOOL) outlineView:(NSOutlineView*)ov isItemExpandable:(id)item;
- (int)  outlineView:(NSOutlineView*)ov numberOfChildrenOfItem:(id)item;
- (id)   outlineView:(NSOutlineView*)ov child:(int)index ofItem:(id)item;
- (id)   outlineView:(NSOutlineView*)ov objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item;

#pragma mark ¥¥¥Delegate Methods
- (void) drawerWillOpen:(NSNotification*)aNote;
- (double) doubleValue;

#pragma mark ¥¥¥Interface Management
- (void) refreshRateChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item;
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem;

#pragma mark ¥¥¥Data Source
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
@end

@interface NSObject (ORDataTaskController)
- (void) removeFromOwner;
@end
