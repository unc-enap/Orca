//
//  ORVHSC040nController.h
//  Orca
//
//  Created by Mark Howe on Mon Sept 13,2010.
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
@interface ORVHSC040nController : OrcaObjectController {

    IBOutlet NSTextField*   slotField;
	IBOutlet NSButton*		fineAdjustEnabledCB;
	IBOutlet NSButton*		killEnabledCB;
	IBOutlet NSTextField*   temperatureField;
	IBOutlet NSTextField*   supplyN12Field;
	IBOutlet NSTextField*   supplyP12Field;
	IBOutlet NSTextField*   supplyP5Field;
	IBOutlet NSTextField*   currentMaxField;
	IBOutlet NSTextField*   voltageMaxField;
	
	IBOutlet NSTextField*   voltageRampSpeedField;
	IBOutlet NSTextField*   moduleStatusField;
	IBOutlet NSTextField*	pollingErrorField;
    IBOutlet NSTextField* 	addressText;
	IBOutlet NSButton*		clearButton;
	IBOutlet NSButton*		settingLockButton;
	IBOutlet NSButton*		systemPanicButton;
	IBOutlet NSTextField*	settingLockDocField;
	
	IBOutlet NSMatrix*		moduleStatusMatrix;
	
	IBOutlet NSMatrix*		onOffMatrix;
	IBOutlet NSMatrix*		loadStartButtonMatrix;
	IBOutlet NSMatrix*		stopButtonMatrix;
	IBOutlet NSMatrix*		panicButtonMatrix;
	IBOutlet NSMatrix*		hvStateMatrix;
	IBOutlet NSMatrix*		voltageSetMatrix;
	IBOutlet NSMatrix*		currentSetMatrix;
	IBOutlet NSMatrix*		voltageMeasureMatrix;
	IBOutlet NSMatrix*		currentMeasureMatrix;
	IBOutlet NSMatrix*		voltageBoundsMatrix;
	IBOutlet NSMatrix*		currentBoundsMatrix;
	IBOutlet NSMatrix*		iErrorMatrix;
		
	IBOutlet NSPopUpButton* pollTimePopup;
	IBOutlet NSProgressIndicator*	pollingProgress;
	IBOutlet NSButton*      systemPanicBButton;
}

- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) fineAdjustEnabledChanged:(NSNotification*)aNote;
- (void) killEnabledChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;

- (void) temperatureChanged:(NSNotification*)aNote;
- (void) supplyN12Changed:(NSNotification*)aNote;
- (void) supplyP12Changed:(NSNotification*)aNote;
- (void) supplyP5Changed:(NSNotification*)aNote;
- (void) voltageMaxChanged:(NSNotification*)aNote;
- (void) currentMaxChanged:(NSNotification*)aNote;
- (void) currentSetChanged:(NSNotification*)aNote;
- (void) voltageRampSpeedChanged:(NSNotification*)aNote;
- (void) voltageBoundsChanged:(NSNotification*)aNote;
- (void) currentBoundsChanged:(NSNotification*)aNote;

- (void) moduleStatusChanged:(NSNotification*)aNote;
- (void) moduleEventStatusChanged:(NSNotification*)aNote;
- (void) moduleEventMaskChanged:(NSNotification*)aNote;
- (void) moduleControlChanged:(NSNotification*)aNote;

- (void) channelStatusChanged:(NSNotification*)aNote;
- (void) channelEventStatusChanged:(NSNotification*)aNote;

- (void) voltageSetChanged:(NSNotification*)aNote;
- (void) voltageMeasureChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) currentMeasureChanged:(NSNotification*)aNote;

- (void) pollingErrorChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) fineAdjustEnabledAction:(id)sender;
- (IBAction) killEnabledAction:(id)sender;
- (IBAction) voltageBoundsAction:(id)sender;
- (IBAction) currentBoundsAction:(id)sender;
- (IBAction) voltageRampSpeedAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) voltageSetAction:(id)sender;
- (IBAction) currentSetAction:(id)sender;
- (IBAction) currentBoundsAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) reportAction:(id)sender;
- (IBAction) loadStartAction:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) stopAction:(id)sender;
- (IBAction) panicAction:(id)sender;
- (IBAction) systemPanicAction:(id)sender;
- (IBAction) doClearAction:(id)sender;
- (IBAction) doClearAction:(id)sender;
- (IBAction) toggleHVOnOffAction:(id)sender;

@end
