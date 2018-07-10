//--------------------------------------------------------------------------------
/*!\class	OROscBaseController
 * \brief	Abstract class that handles general GUI operations related to GPIB
 *			oscilloscopes.
 * \methods
 *			\li \b 	initWithWindowNibName		- Constructor
 *			\li \b 								- dealloc
 * \note	
 *			
 * \author	Jan M. Wouters
 * \history	2003-04-16 (jmw) - Original.
 * \history 2003-12-01 (jmw) - Changed all methods that read doubles from model to
 *								read floats.
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
#pragma mark •••Imported Files

#import "ORGpibDeviceController.h"


@interface OROscBaseController : ORGpibDeviceController {
// Buttons
        IBOutlet NSButton*	    mSetOscFromDialog;
        IBOutlet NSButton*	    mSetDialogFromOsc;
        IBOutlet NSButton*	    mAutoReset;
        
// Vertical scale parameters.
        IBOutlet NSMatrix*	    mChnlAcquire;
        IBOutlet NSPopUpButton*     mChnlCoupling0;
        IBOutlet NSPopUpButton*     mChnlCoupling1;
        IBOutlet NSPopUpButton*     mChnlCoupling2;
        IBOutlet NSPopUpButton*     mChnlCoupling3;
        IBOutlet NSMatrix*	    mChnlPos;
        IBOutlet NSMatrix*	    mChnlPosSteppers;
        IBOutlet NSMatrix*	    mChnlScale;   
        IBOutlet NSMatrix*	    mChnlScaleSteppers;
        
// Horizontal scale parameters
        IBOutlet NSMatrix*	    mHorizUnits;
        IBOutlet NSTextField*       mHorizScale;
        IBOutlet NSTextField*       mHorizPos;
        IBOutlet NSStepper*	    mHorizPosStepper;
        IBOutlet NSPopUpButton*     mRecordLength;
        
// Trigger parameters
        IBOutlet NSPopUpButton*     mTriggerCoupling;
        IBOutlet NSTextField*       mTriggerLevel;
        IBOutlet NSPopUpButton*     mTriggerMode;
        IBOutlet NSMatrix*	    mTriggerPolarity;
        IBOutlet NSTextField*       mTriggerPos;
        IBOutlet NSStepper*	    mTriggerPosStepper;
        IBOutlet NSPopUpButton*     mTriggerSource;
        
        IBOutlet NSTextField*       mModelReflectsHardware;

        IBOutlet NSTextField*       settingsLockDocField;
	IBOutlet NSButton*	    settingsLockButton;
	IBOutlet NSButton*	    gpibLockButton;
}


#pragma mark ***Initialization
- (id) 		initWithWindowNibName: (NSString*) aNibName;
- (void) 	dealloc;

#pragma mark ***Accessors
//- (NSMatrix*)	chnlAcquire;

#pragma mark ***Notifications
- (void) 		registerNotificationObservers;

#pragma mark ***Interface Management
- (void)		updateWindow;
- (void) 		setTitle;
- (NSString*)		settingsLockName;
- (NSString*)		gpibLockName;

#pragma mark ***Interface Management - Channels
- (void) 		oscChnlAcquireChanged: (NSNotification*) aNotification;
- (void) 		oscChnlCouplingChanged: (NSNotification*) aNotification;
- (void) 		oscChnlPosChanged: (NSNotification*) aNotification;
- (void) 		oscChnlScaleChanged: (NSNotification*) aNotification;

#pragma mark ***Interface Management - Horizontal parameters
- (void)		oscHorizPosChanged: (NSNotification*) aNotification;
- (void)		oscHorizRecordLengthChanged: (NSNotification*) aNotification;
- (void) 		oscHorizScaleChanged: (NSNotification*) aNotification;

#pragma mark ***Interface Management - Trigger parameters
- (void)		oscTriggerCouplingChanged: (NSNotification*) aNotification;
- (void)		oscTriggerLevelChanged: (NSNotification*) aNotification;
- (void)		oscTriggerModeChanged: (NSNotification*) aNotification;
- (void)		oscTriggerPolarityChanged: (NSNotification*) aNotification;
- (void)		oscTriggerPosChanged: (NSNotification*) aNotification;
- (void)		oscTriggerSourceChanged: (NSNotification*) aNotification;

#pragma mark ***Interface Management - Misc
- (void) oscModelReflectsHardwareChanged: (NSNotification*) aNotification;
- (void) gpibLockChanged: (NSNotification*) aNotification;
- (void) settingsLockChanged: (NSNotification*) aNotification;
- (void) checkGlobalSecurity;

#pragma mark ***Actions - Channels
- (IBAction)	chnlAcquireAction: (id) aSender;
- (IBAction)	chnlCouplingAction0: (id) aSender;
- (IBAction)	chnlCouplingAction1: (id) aSender;
- (IBAction)	chnlCouplingAction2: (id) aSender;
- (IBAction)	chnlCouplingAction3: (id) aSender;
- (IBAction)	chnlPosAction: (id) aSender;
- (IBAction)	chnlScaleAction: (id) aSender;

#pragma mark ***Actions - Horizontal
- (IBAction)	horizPosAction: (id) aSender;
- (IBAction)	horizRecordLengthAction: (id) aSender;
- (IBAction)	horizScaleAction: (id) aSender; 
- (IBAction)	horizUnitsAction: (id) aSender;

#pragma mark ***Actions - Trigger
- (IBAction)	triggerCouplingAction: (id) aSender;
- (IBAction)	triggerLevelAction: (id) aSender;
- (IBAction)	triggerModeAction: (id) aSender;
- (IBAction)	triggerPolarityAction: (id) aSender;
- (IBAction)	triggerPosAction: (id) aSender;
- (IBAction)	triggerSourceAction: (id) aSender;

#pragma mark ***Commands
- (IBAction)	autoReset: (id) aSender;
- (IBAction)	setOscFromDialog: (id) aSender;
- (IBAction)	setDialogFromOsc: (id) aSender;
- (IBAction)    settingsLockAction:(id)sender;
- (IBAction)    gpibLockAction:(id)sender;

#pragma mark ***Support
- (void)	populatePullDownsOscBase;
@end
