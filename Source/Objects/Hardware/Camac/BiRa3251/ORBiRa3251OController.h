
/*
 *  ORBiRa3251OModelController.h
 *  Orca
 *
 *  Created by Mark Howe on Fri Aug 4, 2006.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
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
#import "ORBiRa3251OModel.h"

@interface ORBiRa3251OController : OrcaObjectController {
	@private
		IBOutlet NSMatrix*		outputRegisterMatrix;
 };

-(id)init;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) updateWindow;
- (void) outputRegisterChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (void) outputRegisterMatrixAction:(id)sender;
- (IBAction) initAction:(id)sender;
- (void) showError:(NSException*)anException name:(NSString*)name;
@end