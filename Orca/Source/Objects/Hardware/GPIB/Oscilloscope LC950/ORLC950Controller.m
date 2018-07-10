//
//  ORLC950Controller.m
//  Orca
//
//  Created by Jan Wouters on Fri Feb 14 2003.
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


#import "ORLC950Controller.h"
#import "ORLC950Model.h"


@implementation ORLC950Controller

#pragma mark ¥¥¥Initialization
//--------------------------------------------------------------------------------
/*!\method  init
 * \brief	Top level initialization routine.  Calls inherited class initWith-
 *			WindowNibName that makes sure that correct nib is used for controller.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) init
{
    self = [ super initWithWindowNibName: @"ORLC950" ];
    return self;
}



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
//    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
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
    [ super updateWindow ];
}

//--------------------------------------------------------------------------------
/*!\method  settingsLockName
 * \brief	Returns the lock name for this controller.
 * \note	
 */
//--------------------------------------------------------------------------------
- (NSString*) settingsLockName
{
    return ORLC950Lock;
}

//--------------------------------------------------------------------------------
/*!\method  gpibLockName
 * \brief	Returns the GPIB lock name for this controller.
 * \note	
 */
//--------------------------------------------------------------------------------
- (NSString*) gpibLockName
{
    return ORLC950GpibLock;
}

@end
