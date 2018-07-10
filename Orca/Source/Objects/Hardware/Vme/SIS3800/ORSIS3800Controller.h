//-------------------------------------------------------------------------
//  ORSIS3800Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORSIS3800Model.h"
@class ORValueBar;
@class ORPlotView;

@interface ORSIS3800Controller : OrcaObjectController 
{
	IBOutlet NSPopUpButton* pollTimePU;
	IBOutlet NSMatrix*		showDeadTimeMatrix;
	IBOutlet NSTextField*	deadTimeRefChannelField;
	IBOutlet NSButton*		shipAtRunEndOnlyCB;
	IBOutlet NSButton*		syncWithRunButton;
	IBOutlet NSButton*		clearOnRunStartButton;
	IBOutlet NSPopUpButton* lemoInModePU;
	IBOutlet NSButton*		enableReferencePulserButton;
	IBOutlet NSButton*		enableInputTestModeButton;
	IBOutlet NSButton*		enable25MHzPulsesButton;
	IBOutlet NSTextField*	lemoInText;
	
	IBOutlet NSMatrix*		countEnableMatrix0;
	IBOutlet NSMatrix*		countEnableMatrix1;

	IBOutlet NSMatrix*		countMatrix0;
	IBOutlet NSMatrix*		countMatrix1;
	
	IBOutlet NSMatrix*		nameMatrix0;
	IBOutlet NSMatrix*		nameMatrix1;
	
	//base address
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
    IBOutlet NSTextField*   statusText;
	
	IBOutlet NSTextField*	moduleIDField;
    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      enableAllInGroupButton0;
    IBOutlet NSButton*      enableAllInGroupButton1;
	
    IBOutlet NSButton*      disableAllInGroupButton0;
    IBOutlet NSButton*      disableAllInGroupButton1;
	
    IBOutlet NSButton*      disableAllButton;
    IBOutlet NSButton*      enableAllButton;
    IBOutlet NSButton*      clearAllButton;
    IBOutlet NSButton*      startCountingButton;
    IBOutlet NSButton*      stopCountingButton;
	
	IBOutlet NSButton*      readNow;
    IBOutlet NSButton*      readAndClearButton;
    IBOutlet NSButton*      probeButton;
    IBOutlet NSButton*      clearOverFlowButton;
    IBOutlet NSButton*      resetButton;
    IBOutlet NSButton*      dumpButton;
	
	IBOutlet NSTextField*	pollDescriptionTextField;
	IBOutlet NSTextField*	count0DisplayTypeTextField;
	IBOutlet NSTextField*	count1DisplayTypeTextField;

}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) showDeadTimeChanged:(NSNotification*)aNote;
- (void) deadTimeRefChannelChanged:(NSNotification*)aNote;
- (void) shipAtRunEndOnlyChanged:(NSNotification*)aNote;
- (void) isCountingChanged:(NSNotification*)aNote;
- (void) syncWithRunChanged:(NSNotification*)aNote;
- (void) clearOnRunStartChanged:(NSNotification*)aNote;
- (void) overFlowMaskChanged:(NSNotification*)aNote;
- (void) enableReferencePulserChanged:(NSNotification*)aNote;
- (void) enableInputTestModeChanged:(NSNotification*)aNote;
- (void) enable25MHzPulsesChanged:(NSNotification*)aNote;
- (void) lemoInModeChanged:(NSNotification*)aNote;
- (void) countEnableMaskChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) moduleIDChanged:(NSNotification*)aNote;
- (void) countersChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) channelNameChanged:(NSNotification*)aNote;


#pragma mark •••Actions
- (IBAction) showDeadTimeAction:(id)sender;
- (IBAction) deadTimeRefChannelAction:(id)sender;
- (IBAction) shipAtRunEndOnlyAction:(id)sender;
- (IBAction) resetBoard:(id)sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) dumpBoard:(id)sender;

- (IBAction) syncWithRunAction:(id)sender;
- (IBAction) clearOnRunStartAction:(id)sender;
- (IBAction) enableReferencePulserAction:(id)sender;
- (IBAction) enableInputTestModeAction:(id)sender;
- (IBAction) enable25MHzPulsesAction:(id)sender;
- (IBAction) lemoInModeAction:(id)sender;
- (IBAction) countEnableMask1Action:(id)sender;
- (IBAction) countEnableMask2Action:(id)sender;

- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) probeBoardAction:(id)sender;
- (IBAction) readNoClear:(id)sender;
- (IBAction) readAndClear:(id)sender;
- (IBAction) clearAll:(id)sender;
- (IBAction) enableAllInGroup:(id)sender;
- (IBAction) disableAllInGroup:(id)sender;
- (IBAction) enableAll:(id)sender;
- (IBAction) disableAll:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) startAction:(id)sender;
- (IBAction) stopAction:(id)sender;
- (IBAction) clearAllOverFlowFlags:(id)sender;
- (IBAction) channelNameAction:(id)sender;

@end
