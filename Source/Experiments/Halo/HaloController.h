//
//  HaloController.h
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
#import "HaloDetectorView.h"

@class ORColorScale;
@class ORSegmentGroup;

@interface HaloController : ORExperimentController {
    
    IBOutlet NSTextField*	detectorTitle;
    IBOutlet NSButton*      startButton;
	IBOutlet NSButton*      stealthMode2CB;
	IBOutlet NSButton*      stealthMode1CB;
	IBOutlet NSButton*      toggleButton;
    IBOutlet NSTextField*	ip1Field;
    IBOutlet NSTextField*	ip2Field;
    IBOutlet NSTextField*	sentryTypeField;
    IBOutlet NSTextField*	stateField;
    IBOutlet NSTextField*	remoteMachineRunningField;
    IBOutlet NSTextField*	connectedField;
    IBOutlet NSTextField*	remoteRunInProgressField;
    IBOutlet NSTextField*	localRunInProgressField;
    IBOutlet NSSecureTextField*	sbcPasswordField;
    IBOutlet NSPopUpButton*	viewTypePU;
    IBOutlet NSButton*      sentryLockButton;
    IBOutlet NSButton*      secondaryMapLockButton;
	IBOutlet NSTableView*   emailListTable;
	IBOutlet NSPopUpButton* heartBeatIndexPU;
	IBOutlet NSTextField*   nextHeartbeatField;
	IBOutlet NSButton*      removeAddressButton;
    IBOutlet NSTextField*   dropSBCConnectionCountField;
    IBOutlet NSTextField*   restartCountField;
    IBOutlet NSTextField*   sbcPingFailedCountField;
    IBOutlet NSTextField*   macPingFailedCountField;
    IBOutlet NSTextField*   missedHeartBeatsCountField;
    IBOutlet NSTextField*   sbcRebootCountField;
    IBOutlet NSTextField*   sentryRunningField;
	IBOutlet NSButton*      updateShapersButton;
    IBOutlet NSPopUpButton* schedulerSetupPU;
    IBOutlet NSTextField*   nextToggleField;

    //items in the  HW map tab view
    IBOutlet NSTableView*	secondaryValuesView;
	IBOutlet NSPopUpButton* secondaryAdcClassNamePopup;
	IBOutlet NSTextField*	secondaryMapFileTextField;
    IBOutlet NSButton*		readSecondaryMapFileButton;
    IBOutlet NSButton*		saveSecondaryMapFileButton;
    IBOutlet NSTableView*	secondaryTableView;

    
	NSView *blankView;
    NSSize detectorSize;
    NSSize detailsSize;
    NSSize focalPlaneSize;
    NSSize sentrySize;
    NSSize testDectorSize;
}

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) setDetectorTitle;

- (NSString*) defaultSecondaryMapFilePath;
- (void) stealthMode2Changed:(NSNotification*)aNote;
- (void) stealthMode1Changed:(NSNotification*)aNote;
- (void) viewTypeChanged:(NSNotification*)aNote;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem;
- (void) sentryTypeChanged:(NSNotification*)aNote;
- (void) ipNumberChanged:(NSNotification*)aNote;
- (void) stateChanged:(NSNotification*)aNote;
- (void) remoteStateChanged:(NSNotification*)aNote;
- (void) specialUpdate:(NSNotification*)aNote;
- (void) sentryLockChanged:(NSNotification*)aNote;
- (void) secondaryMapLockChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (void) sbcPasswordChanged:(NSNotification*)aNote;
- (void) emailListChanged:(NSNotification*)aNote;
- (void) heartBeatIndexChanged:(NSNotification*)aNote;
- (void) runStateChanged:(NSNotification*)aNote;
- (void) sentryIsRunningChanged:(NSNotification*)aNote;
- (void) secondaryAdcClassNameChanged:(NSNotification*)aNote;
- (void) secondaryMapFileChanged:(NSNotification*)aNote;
- (void) nextHeartBeatChanged:(NSNotification*)aNote;
- (void) toggleIntervalChanged:(NSNotification*)aNotification;


#pragma mark ¥¥¥Actions
- (IBAction) clearStatsAction:(id)sender;
- (IBAction) stealthMode2Action:(id)sender;
- (IBAction) stealthMode1Action:(id)sender;
- (IBAction) viewTypeAction:(id)sender;
- (IBAction) ip1Action:(id)sender;
- (IBAction) ip2Action:(id)sender;
- (IBAction) toggleSystems:(id)sender;
- (IBAction) startStopSentry:(id)sender;
- (IBAction) sentryLockAction:(id)sender;
- (IBAction) secondaryMapLockAction:(id)sender;
- (IBAction) sbcPasswordAction:(id)sender;
- (IBAction) updateRemoteShapersAction:(id)sender;
- (IBAction) secondaryAdcClassNameAction:(id)sender;
- (IBAction) readSecondaryMapFileAction:(id)sender;
- (IBAction) saveSecondaryMapFileAction:(id)sender;
- (IBAction) schedulerSetupChanged:(id)sender; //SV
- (IBAction) heartBeatIndexAction:(id)sender;

#pragma mark ¥¥¥Test Detector Map Actions
- (IBAction) secondaryAdcClassNameAction:(id)sender;
- (IBAction) readSecondaryMapFileAction:(id)sender;
- (IBAction) saveSecondaryMapFileAction:(id)sender;

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _updateShaperSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _toggleSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif

@end
@interface ORDetectorView (Halo)
- (void) setViewType:(int)aState;
@end
