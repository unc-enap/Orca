//--------------------------------------------------------------------------------
/*!\class	ORCaen775Controller
 * \brief	Handles high level commands to CAEN 775.
 * \methods
 *			\li \b 			- Constructor
 *			\li \b 
 * \note
 * \author	Jan M. Wouters
 * \history	2002-02-25 (mah) - Original
 *			2002-11-18 (jmw) - Modified for ORCA.
 * 			2002-12-20 (mah) - added undo/redo, archiving, etc...
 *			2003-07-01 (jmw) - Rewritten to handle new CAEN base class.
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

// Definition of class
@interface ORCaen775Controller : ORCaenCardController {
	IBOutlet NSPopUpButton* modelTypePU;
	IBOutlet   NSTextField* fullScaleRangeTextField;
	IBOutlet NSMatrix* commonStopModeMatrix;
    IBOutlet NSMatrix*	onlineMaskMatrixA;
    IBOutlet NSMatrix*	onlineMaskMatrixB;
    IBOutlet NSButton*	initBoardButton;
}

#pragma mark ***Initialization
- (id)		init;
- (void)	registerNotificationObservers;
	
#pragma mark ***Interface Management
- (void) fullScaleRangeChanged:(NSNotification*)aNote;
- (void) commonStopModeChanged:(NSNotification*)aNote;
- (void) modelTypeChanged:(NSNotification*)aNote;
- (void) onlineMaskChanged:(NSNotification*)aNote;
- (void) updateWindow;

#pragma mark ¥¥¥Actions
- (IBAction) fullScaleRangeTextFieldAction:(id)sender;
- (IBAction) commonStopModeAction:(id)sender;
- (IBAction) modelTypePUAction:(id)sender;
- (IBAction) onlineAction:(id)sender;
- (IBAction) initBoardAction:(id)sender;

@end

