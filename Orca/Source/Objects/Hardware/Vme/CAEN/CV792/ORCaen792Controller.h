//--------------------------------------------------------------------------------
// ORCaen792Controller.h
// Mark A. Howe
// 01/22/2104
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------
#pragma mark ¥¥¥Imported Files

#import "ORCaenCardController.h"

// Definition of class.
@interface ORCaen792Controller : ORCaenCardController {
	IBOutlet NSPopUpButton* modelTypePU;
	IBOutlet NSTextField*   totalCycleZTimeField;
	IBOutlet NSTextField*   percentZeroOffField;
    IBOutlet NSButton*      useHWResetCB;
	IBOutlet NSButton*      cycleZeroSuppressionCB;
	IBOutlet NSButton*      defaultsButton;
	IBOutlet NSTextField*   slideConstantField;
	IBOutlet NSMatrix*      slidingScaleEnableMatrix;
	IBOutlet NSMatrix*      eventCounterIncMatrix;
	IBOutlet NSMatrix*      zeroSuppressThresResMatrix;
	IBOutlet NSMatrix*      zeroSuppressEnableMatrix;
	IBOutlet NSMatrix*      overflowSuppressEnableMatrix;
	IBOutlet NSTextField*   iPedField;
    IBOutlet NSMatrix*      onlineMaskMatrixA;
    IBOutlet NSMatrix*      onlineMaskMatrixB;
    IBOutlet NSButton*      shipTimeStampCB;
}

#pragma mark ***Initialization
- (id)		init;
 	
#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ***Interface Management
- (void) shipTimeStampChanged:(NSNotification*)aNote;
- (void) useHWResetChanged:(NSNotification*)aNote;
- (void) totalCycleZTimeChanged:(NSNotification*)aNote;
- (void) percentZeroOffChanged:(NSNotification*)aNote;
- (void) cycleZeroSuppressionChanged:(NSNotification*)aNote;
- (void) setUpButtons;
- (void) slideConstantChanged:(NSNotification*)aNote;
- (void) slidingScaleEnableChanged:(NSNotification*)aNote;
- (void) eventCounterIncChanged:(NSNotification*)aNote;
- (void) zeroSuppressThresResChanged:(NSNotification*)aNote;
- (void) zeroSuppressEnableChanged:(NSNotification*)aNote;
- (void) overflowSuppressEnableChanged:(NSNotification*)aNote;
- (void) iPedChanged:(NSNotification*)aNote;
- (NSSize) thresholdDialogSize;
- (void) updateWindow;
- (void) modelTypeChanged:(NSNotification*)aNote;
- (void) onlineMaskChanged:(NSNotification*)aNote;


#pragma mark ***Actions
- (IBAction) shipTimeStampAction:(id)sender;
- (IBAction) useHWResetAction:(id)sender;
- (IBAction) totalCycleZTimeAction:(id)sender;
- (IBAction) percentZeroOffAction:(id)sender;
- (IBAction) cycleZeroSuppressionAction:(id)sender;
- (IBAction) slideConstantAction:(id)sender;
- (IBAction) slidingScaleEnableAction:(id)sender;
- (IBAction) eventCounterIncAction:(id)sender;
- (IBAction) zeroSuppressThresResAction:(id)sender;
- (IBAction) zeroSuppressEnableAction:(id)sender;
- (IBAction) overflowSuppressEnableAction:(id)sender;
- (IBAction) iPedAction:   (id)sender;
- (IBAction) modelTypePUAction:(id)sender;
- (IBAction) onlineAction: (id) sender;
- (IBAction) initBoard:    (id) sender;
- (IBAction) report:       (id) sender;
- (IBAction) setToDefaults:(id) sender;

@end
