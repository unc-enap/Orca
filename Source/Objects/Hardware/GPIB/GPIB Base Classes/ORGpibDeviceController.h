//--------------------------------------------------------------------------------
/*!\class	ORGpibDeviceController
 * \brief	This class handles a GPIB devices interaction with the GPIB controller
 *			object.  All GPIB devices need to inherit from this class.
 * \methods
 *			\li \b 	initWithWindowNibName		- Constructor - Opens correct nib
 *			\li \b 	dealloc						- Unregister messages, cleanup.
 *			\li \b	connect						- Connect device to GPIB.
 *			\li \b	primaryAddressChanged		- Respond when person changes address.
 *			\li \b	secondaryAddressChanged		- Respond when person changes address.
 * \private
 *			\li \b	populatePullDowns			- Populate pulldowns in GUI.
 * \note	
 *			
 * \author	Jan M. Wouters
 * \history	2003-04-16 (jmw) - Original.
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

@interface ORGpibDeviceController : OrcaObjectController {
    IBOutlet	NSButton*	    mConnectButton;
    IBOutlet	NSPopUpButton*      mPrimaryAddress;
    IBOutlet	NSTextField*	    mSecondaryAddress;
    IBOutlet	NSTextField*	    mConfigured;
}

// Register notifications that this class will listen for.
- (void) registerNotificationObservers;

#pragma mark ***Initialization
- (id)		initWithWindowNibName: (NSString*) aNibName;

#pragma mark ***Accessors
//- (bool)      isConnected;

#pragma mark ***Interface Management
- (void)	updateWindow;
- (void)	connectionChanged: (NSNotification*) aNotification;
- (void)	primaryAddressChanged: (NSNotification*) aNotification;
- (void)	secondaryAddressChanged: (NSNotification*) aNotification;

#pragma mark ***Actions
- (IBAction) 	connectAction: (id) aSender;
- (IBAction) 	primaryAddressAction: (id) aSender;
- (IBAction) 	secondaryAddressAction: (id) aSender;

#pragma mark ***Support
- (void) 		populatePullDownsGpibDevice;

@end
