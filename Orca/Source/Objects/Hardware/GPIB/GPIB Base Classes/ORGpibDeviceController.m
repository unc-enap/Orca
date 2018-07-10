//
//  ORGpibDeviceController.m
//  Orca
//
//  Created by Jan Wouters on Wed Feb 19 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORGpibDeviceController.h"
#import "ORGpibDeviceModel.h"
#import "ORGpibEnetModel.h"



@implementation ORGpibDeviceController
#pragma mark ¥¥¥Initialization
//--------------------------------------------------------------------------------
/*!\method  initWithWindowNibName
 * \brief	Initialize the window using the nib file.
 * \param	aNibName			- The name of the nib object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) initWithWindowNibName: (NSString*) aNibName
{
    self = [ super initWithWindowNibName: aNibName ];
    return self;
}


//--------------------------------------------------------------------------------
/*!\method  awakeFromNib
 * \brief	Initializes object after everything is loaded.  Populates the
 *			pulldown menus, registers to receive notifications and updates
 *			the GUI.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) awakeFromNib
{
	[ self populatePullDownsGpibDevice ];
    [ mConfigured setStringValue: [ NSString stringWithFormat: 
								   @"Not configured: %d", [[ self model ] primaryAddress ]]];
	//    mConnected = false;
	@try {
		[super awakeFromNib];
	}
	@catch(NSException* localException) {
	}
}

#pragma mark ***Accessors
//--------------------------------------------------------------------------------
/*!\method  isConnected
 * \brief	Determines if connection is setup to GPIB.
 * \return	True - GPIB is object is connected to hardware device.
 * \note	
 */
//--------------------------------------------------------------------------------
//- (bool) isConnected
//{
//    return( mConnected );
//}

#pragma mark ***Notifications
//--------------------------------------------------------------------------------
/*!\method  registerNotificationObservers
 * \brief	Registers following messages: 
 *				1) Change primary address.
 *				2) Change secondary address.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];
	
    [super registerNotificationObservers];
    
    [ notifyCenter addObserver: self
                      selector: @selector( primaryAddressChanged: )
                          name: ORGpibPrimaryAddressChangedNotification
                        object: model];
	
    [ notifyCenter addObserver: self
                      selector: @selector( secondaryAddressChanged: )
                          name: ORGpibSecondaryAddressChangedNotification
                        object: model];
	
    [ notifyCenter addObserver: self
                      selector: @selector( connectionChanged: )
                          name: ORGpibDeviceConnectedNotification
                        object: model];
}

#pragma mark ***Interface Management
//--------------------------------------------------------------------------------
/*!\method  updateWindow
 * \brief	Sets all GUI values to current model values.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) updateWindow
{
    [super updateWindow];
    [ self primaryAddressChanged: nil ];
    [ self secondaryAddressChanged: nil ];
}


//--------------------------------------------------------------------------------
/*!\method  connectionChanged
 * \brief	Reacts to connection established message and updates GUI.
 * \param	aNotification		- The message that was sent out.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) connectionChanged: (NSNotification*) aNotification
{
    bool	deviceConnected = false;
    
	// Check to see that device was connected.
	int chnl = [[[ aNotification userInfo ] objectForKey: ORGpibAddress ] intValue ];
	if ( chnl == [[ self model ] primaryAddress ] && [[model getGpibController ]isConnected])
	{
		
		// Device was connected so update GUI appropriately.
		if ( [[[ aNotification userInfo ] objectForKey: ORGpibDeviceConnected ] intValue ] )
		{
			[ mConfigured setStringValue: [ NSString stringWithFormat: 
										   @"Configured: %d", [[ self model ] primaryAddress ]]];
			deviceConnected = true;
		}
	}
    
	// Device was not connected so update GUI appropriately
    if ( !deviceConnected )
    {
        [ mConfigured setStringValue: [ NSString stringWithFormat: 
									   @"Not configured: %d", [[ self model ] primaryAddress ]]];
    }
}


//--------------------------------------------------------------------------------
/*!\method  primaryAddressChanged
 * \brief	Update the primary address.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) primaryAddressChanged: (NSNotification*) aNotification
{
	[ self updatePopUpButton: mPrimaryAddress setting: [[ self model ] primaryAddress ]];
}

//--------------------------------------------------------------------------------
/*!\method  secondaryAddressChanged
 * \brief	Update the secondary address.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) secondaryAddressChanged: (NSNotification*) aNotification
{
	[ mSecondaryAddress setStringValue: [ NSString stringWithFormat: @"%d",
										 [[ self model ] secondaryAddress ]]];
}

#pragma mark ***Actions
//--------------------------------------------------------------------------------
/*!\method  connectAction
 * \brief	Connect to the actual device.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) connectAction: (id) aSender
{
    @try {
		//        primaryAddress = [ mPrimaryAddress indexOfSelectedItem ];
        
        [[ self model ] connect ];
		//        mConnected = true;
		
    }
	@catch(NSException* localException) {
		//        mConnected = false;
        NSLog( [ localException reason ] );
        ORRunAlertPanel( [ localException name ], 	// Name of panel
                        @"%@",                      // Reason for error
                        @"OK", 						// Okay button
                        nil, 						// alternate button
                        nil,                        // other button
                        [ localException reason ]);
        
    }
}

//--------------------------------------------------------------------------------
/*!
 * \method  primaryAddressAction
 * \brief	Set the primary address for the GPIB device.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) primaryAddressAction: (id) aSender
{
    if ( [ aSender indexOfSelectedItem ] != [[ self model ] primaryAddress ] )
    {
        [[self undoManager ] setActionName: @"Set Primary Address" ];
        [[ self model ] setPrimaryAddress: [ aSender indexOfSelectedItem ]];
    }
}

//--------------------------------------------------------------------------------
/*!
 * \method  secondaryAddressAction
 * \brief	Set the primary address for the GPIB device.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) secondaryAddressAction: (id) aSender
{
    if ( [ aSender intValue ] != [[ self model ] secondaryAddress ] )
    {
        [[self undoManager ] setActionName: @"Set Secondary Address" ];
        [[ self model ] setSecondaryAddress: [ aSender intValue ]];
    }
}


#pragma mark ***Support
//--------------------------------------------------------------------------------
/*!
 * \method  populatePullDownsGpibDevice
 * \brief	Populate the GPIB board pulldown and the primary address pulldown
 *			items.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) populatePullDownsGpibDevice
{
    short	i;
    
	// Remove all items from popup menus
    [ mPrimaryAddress removeAllItems ];
    
	// Repopulate Primary GPIB address
    for ( i = 0; i <  kMaxGpibAddresses; i++ ) {
        [ mPrimaryAddress insertItemWithTitle: [ NSString stringWithFormat: @"%d", i ]
                                      atIndex: i ];
    } 
}


@end
