//
//  ORRunController.h
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

@class StopLightView;
@class ORCardContainerView;

@interface ORRunController : OrcaObjectController  {
    
    IBOutlet NSScrollView*	scriptScrollView;
    IBOutlet ORCardContainerView*	groupView;
    IBOutlet NSDrawer*  runTypeDrawer;
    IBOutlet NSDrawer*  runNumberDrawer;
    IBOutlet NSDrawer*  waitRequestersDrawer;
    IBOutlet NSDrawer*  scriptsDrawer;
    IBOutlet NSButton*  showWaitRequestersButton;
    IBOutlet NSButton*  showScriptsButton;
    IBOutlet NSButton*  runNumberButton;
    IBOutlet NSButton*  runTypeButton;
    
    IBOutlet NSButton*  startRunButton;
    IBOutlet NSButton*  restartRunButton;
    IBOutlet NSButton*  stopRunButton;
    IBOutlet NSButton*  remoteControlCB;
    IBOutlet NSButton*  quickStartCB;

	IBOutlet NSButton*  endSubRunButton;
	IBOutlet NSButton*  startSubRunButton;
	
    IBOutlet NSProgressIndicator* 	runProgress;
    IBOutlet NSProgressIndicator* 	runBar;
    IBOutlet NSTextField*			runNumberField;
    
    IBOutlet NSButton*      timedRunCB;
    IBOutlet NSButton*      repeatRunCB;
    IBOutlet NSTextField*   timeLimitField;
    IBOutlet NSMatrix*      runModeMatrix;
    
    IBOutlet NSTextField* statusField;
    IBOutlet NSTextField* timeStartedField;
    IBOutlet NSTextField* elapsedRunTimeField;
    IBOutlet NSTextField* elapsedSubRunTimeField;
    IBOutlet NSTextField* elapsedBetweenSubRunTimeField;
    IBOutlet NSTextField* endOfRunStateField;
    IBOutlet NSTextField* timeToGoField;
    IBOutlet NSTextField* vetoCountField;
    IBOutlet NSTextField* vetoedTextField;
    IBOutlet NSButton*	  listVetosButton;
    
    IBOutlet NSButton*    runNumberDirButton;
    IBOutlet NSTextField* runNumberDirField;
    IBOutlet NSTextField* runNumberText;
    
    IBOutlet NSMatrix*      runTypeMatrix;
    IBOutlet NSTabView*     runModeNoticeView;
    IBOutlet NSTextField*   definitionsFileTextField;
    IBOutlet NSButton*      runDefinitionsButton;
    IBOutlet NSButton*      clearAllTypesButton;
    IBOutlet NSButton*      runNumberLockButton;
    IBOutlet NSButton*      runTypeLockButton;
    IBOutlet StopLightView* lightBoardView;
    
    IBOutlet NSButton*      openStartScriptButton;
    IBOutlet NSButton*      openShutDownScriptButton;
	IBOutlet NSPopUpButton* startUpScripts;
	IBOutlet NSPopUpButton* shutDownScripts;
    IBOutlet NSTextField*   startUpScriptStateField;
    IBOutlet NSTextField*   shutDownScriptStateField;
    IBOutlet NSTextField*   waitCountField;
    IBOutlet NSTextField*   waitCountField1;
    IBOutlet NSTextField*   waitCountField2;
    IBOutlet NSTableView*   waitRequestersTableView;
    IBOutlet NSButton*      forceClearWaitsButton;
    IBOutlet NSButton*      abortRunFromWaitButton;

    IBOutlet ORGroupView*   scriptsView;
	IBOutlet NSPopUpButton* runTypeScriptPU;

    BOOL retainingRunNotice;
	BOOL wasInMaintenance;
    
}

- (ORGroupView *)groupView;

#pragma  mark ¥¥¥Actions
- (IBAction) selectedRunTypeScriptPUAction:(id)sender;
- (IBAction) startRunAction:(id)sender;
- (IBAction) newRunAction:(id)sender;
- (IBAction) stopRunAction:(id)sender;
- (IBAction) remoteControlAction:(id)sender;
- (IBAction) timeLimitTextAction:(id)sender;
- (IBAction) timedRunCBAction:(id)sender;
- (IBAction) repeatRunCBAction:(id)sender;
- (IBAction) quickStartCBAction:(id)sender;
- (IBAction) runNumberAction:(id)sender;
- (IBAction) runModeAction:(id)sender;
- (IBAction) runTypeAction:(id)sender;
- (IBAction) clearRunTypeAction:(id)sender;
- (IBAction) runNumberLockAction:(id)sender;
- (IBAction) runTypeLockAction:(id)sender;
- (IBAction) definitionsFileAction:(id)sender;
- (IBAction) listVetoAction:(id)sender;
- (IBAction) selectStartUpScript:(id)sender;
- (IBAction) selectShutDownScript:(id)sender;
- (IBAction) openStartScript:(id)sender;
- (IBAction) openShutDownScript:(id)sender;
- (IBAction) startNewSubRunAction:(id)sender;
- (IBAction) prepareForSubRunAction:(id)sender;
- (IBAction) forceClearWaitsAction:(id)sender;
- (IBAction) abortRunFromWaitAction:(id)sender;
- (IBAction) chooseDir:(id)sender;
- (void) deferredRunNumberChange;
- (void) deferredChooseDir;

#pragma mark ¥¥¥Interface Management
- (void) selectedRunTypeScriptChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (void) registerNotificationObservers;
- (void) timeLimitChanged:(NSNotification*)aNote;
- (void) startUpScriptStateChanged:(NSNotification*)aNote;
- (void) shutDownScriptStateChanged:(NSNotification*)aNote;
- (void) runStatusChanged:(NSNotification*)aNote;
- (void) timedRunChanged:(NSNotification*)aNote;
- (void) repeatRunChanged:(NSNotification*)aNote;
- (void) elapsedTimesChanged:(NSNotification*)aNote;
- (void) startTimeChanged:(NSNotification*)aNote;
- (void) timeToGoChanged:(NSNotification*)aNote;
- (void) runNumberChanged:(NSNotification*)aNote;
- (void) runNumberDirChanged:(NSNotification*)aNote;
- (void) runModeChanged:(NSNotification *)aNote;
- (void) drawerWillOpen:(NSNotification *)aNote;
- (void) runTypeChanged:(NSNotification *)aNote;
- (void) remoteControlChanged:(NSNotification *)aNote;
- (void) runNumberLockChanged:(NSNotification *)aNote;
- (void) runTypeLockChanged:(NSNotification *)aNote;
- (void) quickStartChanged:(NSNotification *)aNote;
- (void) definitionsFileChanged:(NSNotification *)aNote;
- (void) vetosChanged:(NSNotification*)aNote;
- (void) startUpScriptChanged:(NSNotification*)aNote;
- (void) shutDownScriptChanged:(NSNotification*)aNote;
- (void) numberOfWaitsChanged:(NSNotification*)aNote;
- (void) groupChanged:(NSNotification*)aNote;
- (NSString*) getStartingString;
- (NSString*) getRestartingString;
- (NSString*) getStoppingString;
- (NSString*) getBetweenSubrunsString;

- (void) updateWithCurrentRunNumber;
- (void) setupRunTypeNames;
- (void) startRun;

@end
