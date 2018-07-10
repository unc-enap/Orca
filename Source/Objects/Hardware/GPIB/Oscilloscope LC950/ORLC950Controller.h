//--------------------------------------------------------------------------------
/*!\class	ORLC950Controller
 * \brief	This class is the top level class handling interaction between the
 *			LeCroy 950 GUI and its hardware.
 * \methods
 *			\li \b 	init						- Constructor - Opens correct nib
 *			\li \b 	dealloc						- Unregister messages, cleanup.
 *			\li \b	connect						- Connect device to GPIB.
 *			\li \b	primaryAddressChanged		- Respond when person changes address.
 *			\li \b	secondaryAddressChanged		- Respond when person changes address.
 * \private
 *			\li \b	populatePullDowns			- Populate pulldowns in GUI.
 * \note	1) The hardware access methods use the internally stored state
 *			   to actually set the hardware.  Thus one first has to use the
 *			   accessor methods prior to setting the oscilloscope hardware.
 *			
 * \author	Jan M. Wouters
 * \history	2004-04-21 (jmw) - Original.
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
#pragma mark ¥¥¥Imported Files

#import "OROscBaseController.h"

@interface ORLC950Controller : OROscBaseController {    
}

// Register notifications that this class will listen for.
- (void) registerNotificationObservers;

#pragma mark ***Initialization
- (id) 			init;

#pragma mark ***Interface Management
- (void)		updateWindow;

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions
/*- (IBAction) ok: (id) aSender; 
*/
@end
