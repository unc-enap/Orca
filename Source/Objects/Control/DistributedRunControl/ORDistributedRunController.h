//
//  ORDistributedRunController.h
//  Orca
//
//  Created by Mark Howe on Apr 22, 2025.
//  Copyright (c) 2025 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics Department sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
@class ORRemoteRunItem;
#import "OrcaObjectController.h"

@class ZFlowLayout;
@class StopLightView;

@interface ORDistributedRunController : OrcaObjectController
{
        
    IBOutlet NSButton*  startRunButton;
    IBOutlet NSButton*  stopRunButton;

    IBOutlet NSProgressIndicator* 	runBar;
    IBOutlet NSButton*      timedRunCB;
    IBOutlet NSButton*      repeatRunCB;
    IBOutlet NSTextField*   timeLimitField;
    IBOutlet NSButton*      connectAllButton;
    IBOutlet NSButton*      disConnectAllButton;
    
    IBOutlet NSTextField* numberConnectedField;
    IBOutlet NSTextField* numberRunningField;
    IBOutlet NSTextField* timeStartedField;
    IBOutlet NSTextField* elapsedTimeField;
    IBOutlet NSTextField* timeToGoField;
    IBOutlet StopLightView* lightBoardView;

    IBOutlet NSTextField* runNumberField; //in main dialog
    IBOutlet NSTextField* runNumberText;  //in run number drawer
    IBOutlet NSButton*    runNumberDirButton;
    IBOutlet NSTextField* runNumberDirField;
    IBOutlet NSDrawer*    runNumberDrawer;
    IBOutlet NSButton*    runNumberLockButton;
    IBOutlet NSButton*    runNumberButton;
    IBOutlet NSButton*    runNumberApplyButton;

    IBOutlet NSButton*    lockButton;
    
    IBOutlet ZFlowLayout* remoteRunItemContentView;
    NSMutableArray*       remoteRunItemControllers;
}

#pragma  mark ¥¥¥Initialization
- (id)  init;
- (void)dealloc;
- (void) setModel:(id)aModel;
- (NSView*) remoteRunItemContentView;

#pragma mark ¥¥¥Interface Management
- (NSView*) remoteRunItemContentView;
- (void) updateButtons;
- (void) isConnectedChanged:(NSNotification*)note;
- (void) runNumberLockChanged:(NSNotification*)aNotification;
- (void) registerNotificationObservers;
- (void) runStatusChanged:(NSNotification*)aNotification;
- (void) timedRunChanged:(NSNotification*)aNotification;
- (void) repeatRunChanged:(NSNotification*)aNotification;
- (void) elapsedTimeChanged:(NSNotification*)aNotification;
- (void) startTimeChanged:(NSNotification*)aNotification;
- (void) timeToGoChanged:(NSNotification*)aNotification;
- (void) runNumberChanged:(NSNotification*)aNote;
- (void) runNumberDirChanged:(NSNotification*)aNote;
- (void) updateView:(NSNotification*)aNote;
- (void) runNumberLockChanged:(NSNotification *)aNote;
- (void) deferredRunNumberChange;
- (void) deferredChooseDir;

- (void) addRemoteRunItem:(ORRemoteRunItem*)anItem;
- (void) removeRemoteRunItem:(ORRemoteRunItem*)anItem;
- (void) remoteRunItemAdded:(NSNotification*)aNote;
- (void) remoteRunItemRemoved:(NSNotification*)aNote;

#pragma  mark ¥¥¥Actions
- (IBAction) startRunAction:(id)sender;
- (IBAction) stopRunAction:(id)sender;
- (IBAction) timeLimitTextAction:(id)sender;
- (IBAction) timedRunCBAction:(id)sender;
- (IBAction) repeatRunCBAction:(id)sender;
- (IBAction) connectAllAction:(id)sender;
- (IBAction) disConnectAllAction:(id)sender;
- (IBAction) runNumberAction:(id)sender;
- (IBAction) chooseDir:(id)sender;
- (IBAction) runNumberLockAction:(id)sender;

@end
