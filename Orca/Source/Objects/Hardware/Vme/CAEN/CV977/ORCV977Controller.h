//--------------------------------------------------------------------------------
//ORCV977Controller.h
//Mark A. Howe 20013-09-26
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
#pragma mark •••Imported Files

#import "ORCaenCardController.h"


// Definition of class.
@interface ORCV977Controller : OrcaObjectController {
    IBOutlet NSTabView* 	tabView;
	IBOutlet NSPopUpButton* orMaskBitPU;
	IBOutlet NSPopUpButton* gateMaskBitPU;
	IBOutlet NSPopUpButton* patternBitPU;
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*	inputSetField;
    IBOutlet NSMatrix*      inputSetMatrix;
    IBOutlet NSTextField*	inputMaskField;
    IBOutlet NSMatrix*      inputMaskMatrix;
    IBOutlet NSTextField*	outputSetField;
    IBOutlet NSMatrix*      outputSetMatrix;
    IBOutlet NSTextField*	outputMaskField;
    IBOutlet NSMatrix*      outputMaskMatrix;
    IBOutlet NSTextField*	interruptMaskField;
    IBOutlet NSMatrix*      interruptMaskMatrix;
    IBOutlet NSButton*		clearOutputRegButton;
    IBOutlet NSButton*		clearSingleHitRegButton;
    IBOutlet NSButton*		clearMultiHitRegButton;

    IBOutlet NSTextField* 	addressTextField;
    IBOutlet NSTextField* 	writeValueTextField;
    IBOutlet NSPopUpButton*	registerAddressPopUp;
    IBOutlet NSButton*		basicWriteButton;
    IBOutlet NSButton*		basicReadButton;
    IBOutlet NSButton*		basicOpsLockButton;
    IBOutlet NSButton*		lowLevelOpsLockButton;
    IBOutlet NSButton*		initBoardButton;
    IBOutlet NSButton*		resetButton;
    
    // Results box
    IBOutlet NSTextField*	regNameField;
    IBOutlet NSTextField*	registerOffsetTextField;
    IBOutlet NSTextField*	registerReadWriteTextField;

    NSView* blankView;
    NSSize lowLevelOpsSize;
    NSSize basicOpsSize;
}

- (id) init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark ***Interface Management
- (void) orMaskBitChanged:(NSNotification*)aNote;
- (void) gateMaskBitChanged:(NSNotification*)aNote;
- (void) patternBitChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) checkGlobalSecurity;

#pragma mark ***Interface Management - Module specific
- (void) slotChanged:(NSNotification*)aNotification;
- (void) setModel:(id)aModel;
- (void) inputSetChanged:(NSNotification*)aNotification;
- (void) inputMaskChanged:(NSNotification*)aNotification;
- (void) outputSetChanged:(NSNotification*)aNotification;
- (void) outputMaskChanged:(NSNotification*)aNotification;
- (void) interruptMaskChanged:(NSNotification*)aNotification;
- (void) lowLevelLockChanged:(NSNotification*)aNotification;
- (void) basicOpsLockChanged:(NSNotification*)aNotification;
- (void) baseAddressChanged:(NSNotification*) aNotification;
- (void) writeValueChanged:(NSNotification*) aNotification;
- (void) selectedRegIndexChanged:(NSNotification*) aNotification;

#pragma mark •••Actions
- (IBAction) orMaskBitAction:(id)sender;
- (IBAction) gateMaskBitAction:(id)sender;
- (IBAction) patternBitAction:(id)sender;
- (IBAction) baseAddressAction:(id) aSender;
- (IBAction) writeValueAction:(id) aSender;
- (IBAction) selectRegisterAction:(id) aSender;
- (IBAction) read:(id) pSender;
- (IBAction) write:(id) pSender;
- (IBAction) settingsLockAction:(id)sender;
- (IBAction) lowLevelLockAction:(id)sender;
- (IBAction) inputSetAction:(id)sender;
- (IBAction) inputMaskAction:(id)sender;
- (IBAction) outputSetAction:(id)sender;
- (IBAction) outputMaskAction:(id)sender;
- (IBAction) interruptMaskAction:(id)sender;
- (IBAction) clearOutputRegisterAction:(id)sender;
- (IBAction) clearSingleHitRegisterAction:(id)sender;
- (IBAction) clearMultiHitRegisterAction:(id)sender;
- (IBAction) initBoardAction:(id)sender;
- (IBAction) resetAction:(id)sender;

#pragma mark •••Helpers
- (void) populatePullDown;
- (void) updateRegisterDescription:(short) aRegisterIndex;
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

@end
