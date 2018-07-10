//
//  ORProcessController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORContainerController.h"

@interface ORProcessController : ORContainerController
{
    IBOutlet NSTabView*     tabView;
	IBOutlet NSButton*      masterProcessCB;
	IBOutlet NSButton*      sendOnStopCB;
	IBOutlet NSButton*      sendOnStartCB;
	IBOutlet NSPopUpButton* heartBeatIndexPU;
	IBOutlet NSTableView*   emailListTable;
	IBOutlet NSTextField*   historyFileTextField;
	IBOutlet NSButton*      keepHistoryCB;
	IBOutlet NSTextField*   sampleRateField;
    IBOutlet NSTableView*   tableView;
    IBOutlet NSButton*      testModeButton;
    IBOutlet NSButton*      startButton;
    IBOutlet NSTextField*   statusTextField;
    IBOutlet NSTextView*    detailsTextView;
    IBOutlet NSTextField*   shortNameField;
    IBOutlet NSButton*      altViewButton;
	IBOutlet NSButton*      addAddressButton;
	IBOutlet NSButton*      removeAddressButton;
	IBOutlet NSTextField*   nextHeartbeatField;
    IBOutlet NSImageView*	heartbeatImage;
    IBOutlet NSButton*      pollNowButton;
	IBOutlet NSTextField*   processRunNumberField;
	IBOutlet NSTextField*   masterInfoField;

    NSImage* descendingSortingImage;
    NSImage* ascendingSortingImage;
    NSString *_sortColumn;
    BOOL _sortIsDescending;
	BOOL scheduledForUpdate;
}

#pragma mark ¥¥¥Initialization
- (id) init;
-(void) awakeFromNib;

#pragma mark ¥¥¥Interface Management
- (void) masterProcessChanged:(NSNotification*)aNote;
- (void) sendOnStopChanged:(NSNotification*)aNote;
- (void) sendOnStartChanged:(NSNotification*)aNote;
- (void) heartBeatIndexChanged:(NSNotification*)aNote;
- (void) emailListChanged:(NSNotification*)aNote;
- (void) historyFileChanged:(NSNotification*)aNote;
- (void) keepHistoryChanged:(NSNotification*)aNote;
- (void) sampleRateChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) testModeChanged:(NSNotification*)aNote;
- (void) elementStateChanged:(NSNotification*)aNote;
- (void) processRunningChanged:(NSNotification*)aNote;
- (void) commentChanged:(NSNotification*)aNote;
- (void) shortNameChanged:(NSNotification*)aNote;
- (void) detailsChanged:(NSNotification*)aNote;
- (void) useAltViewChanged:(NSNotification*)aNote;
- (void) objectsChanged:(NSNotification*)aNote;
- (void) doUpdate:(NSNotification*)aNote;
- (void) nextHeartBeatChanged:(NSNotification*)aNote;
- (void) setHeartbeatImage;
- (void) updatePollingButton;
- (void) processRunNumberChanged:(NSNotification*)aNote;
- (void) updateButtons;

#pragma mark ¥¥¥Actions
- (IBAction) masterProcessAction:(id)sender;
- (IBAction) sendOnStopAction:(id)sender;
- (IBAction) sendOnStartAction:(id)sender;
- (IBAction) heartBeatIndexAction:(id)sender;
- (IBAction) historyFileSelectionAction:(id)sender;
- (IBAction) keepHistoryAction:(id)sender;
- (IBAction) useAltViewAction:(id)sender;
- (IBAction) sampleRateAction:(id)sender;
- (IBAction) startProcess:(id)sender;
- (IBAction) testModeAction:(id)sender;
- (IBAction) shortNameAction:(id)sender;
- (IBAction) doubleClick:(id)sender;
- (IBAction) viewProcessCenter:(id)sender;
- (IBAction) addAddress:(id)sender;
- (IBAction) removeAddress:(id)sender;
- (IBAction) pollNow:(id)sender;

#pragma mark ¥¥¥Data Source
- (id)  tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex;
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item;
- (void) setSortColumn:(NSString *)identifier;
- (NSString *)sortColumn;
- (void) setSortIsDescending:(BOOL)whichWay;
- (BOOL) sortIsDescending;
- (void) sort;
- (void) updateTableHeaderToMatchCurrentSort;

@end
