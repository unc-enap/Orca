//--------------------------------------------------------------------------------
/*!\class	ORCaen785Controller
 * \brief	Handles high level commands to CAEN 785.
 * \methods
 *			\li \b 			- Constructor
 *			\li \b 
 * \note
 * \author	Jan M. Wouters
 * \history	2003-06-25 (mah) - Original
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

#import "ORCaenCardController.h"

// Definition of class.
@interface ORCaen785Controller : ORCaenCardController {
	IBOutlet NSPopUpButton* modelTypePU;
    IBOutlet NSMatrix*	onlineMaskMatrixA;
    IBOutlet NSMatrix*	onlineMaskMatrixB;
    IBOutlet NSButton*	resetButton;
}

#pragma mark ***Initialization
- (id)		init;
 	
#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) modelTypeChanged:(NSNotification*)aNote;
- (void) onlineMaskChanged:(NSNotification*)aNote;

#pragma mark ***Interface Management
- (void) updateWindow;

#pragma mark ***Actions
- (IBAction) modelTypePUAction:(id)sender;
- (IBAction) onlineAction:(id)sender;
- (IBAction) resetAction:(id)sender;

@end
