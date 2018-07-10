//--------------------------------------------------------------------------------
/*!\class	ORCaenController
 * \brief	Handles interface between CAEN GUI and CAEN base model class.
 * \methods
 *			\li \b 			- Constructor
 *			\li \b 
 * \note
 * \author	Jan M. Wouters
 * \history	2003-06-26 (jmw) - Original
 */
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

// Definition of class.
@interface ORCaenCardController : OrcaObjectController {

    IBOutlet NSTabView* 	tabView;
    IBOutlet NSTextField*       slotField;

    // Register Box
    IBOutlet NSStepper* 	addressStepper;
    IBOutlet NSTextField* 	addressTextField;
    IBOutlet NSStepper* 	writeValueStepper;
    IBOutlet NSTextField* 	writeValueTextField;
    IBOutlet NSPopUpButton*	registerAddressPopUp;
    IBOutlet NSPopUpButton*	channelPopUp;
    IBOutlet NSTextField*       basicLockDocField;
    IBOutlet NSButton*		basicWriteButton;
    IBOutlet NSButton*		basicReadButton;

    // Results box
    IBOutlet NSTextField*	regNameField;
    IBOutlet NSTextField*	drTextField;
    IBOutlet NSTextField*	srTextField;
    IBOutlet NSTextField*	hrTextField;
    IBOutlet NSTextField*	registerOffsetTextField;
    IBOutlet NSTextField*	registerReadWriteTextField;
    
    // Threshold tab
    IBOutlet NSMatrix*		thresholdA;
    IBOutlet NSMatrix*		stepperA;
    IBOutlet NSMatrix*		thresholdB;
    IBOutlet NSMatrix*		stepperB;
    IBOutlet NSButton*		thresholdWriteButton;
    IBOutlet NSButton*		thresholdReadButton;

    IBOutlet NSButton*		thresholdLockButton;
    IBOutlet NSButton*		basicLockButton;
    IBOutlet NSTextField*       thresholdLockDocField;


    NSView *blankView;
    NSSize settingSize;
    NSSize thresholdSize;

}

#pragma mark ***Initialization
- (id)		initWithWindowNibName: (NSString*) aNibName;
- (void)	dealloc;
- (NSSize)	thresholdDialogSize;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ***Interface Management
- (void) updateWindow;

#pragma mark ***Interface Management - Base tab
- (void) baseAddressChanged: (NSNotification*) aNotification;
- (void) writeValueChanged: (NSNotification*) aNotification;
- (void) selectedRegIndexChanged: (NSNotification*) aNotification;
- (void) slotChanged:(NSNotification*)aNotification;

#pragma mark ***Interface Management - Threshold
- (void) thresholdChanged: (NSNotification*) aNotification;
- (void) thresholdLockChanged:(NSNotification*)aNotification;
- (void) basicLockChanged:(NSNotification*)aNotification;
- (void) checkGlobalSecurity;
- (void) selectedRegChannelChanged:(NSNotification*) aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) baseAddressAction: (id) aSender;
- (IBAction) writeValueAction: (id) aSender;
- (IBAction) selectRegisterAction: (id) aSender;
- (IBAction) selectChannelAction: (id) aSender;
- (IBAction) thresholdChangedAction: (id) aSender;

- (IBAction) read: (id) pSender;
- (IBAction) write: (id) pSender;

- (IBAction) readThresholds: (id) pSender;
- (IBAction) writeThresholds: (id) pSender;

- (IBAction) thresholdLockAction:(id)sender;
- (IBAction) basicLockAction:(id)sender;


#pragma mark ¥¥¥Misc Helpers
- (void)    populatePullDown;
- (void)    updateRegisterDescription: (short) aRegisterIndex;
- (void)    tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (NSString*) thresholdLockName;
- (NSString*) basicLockName;

// The outlets
	

@end
