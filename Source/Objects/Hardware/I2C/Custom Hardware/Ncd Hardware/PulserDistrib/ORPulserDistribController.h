//
//  ORPulserDistribController.h
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#import "ORPulserDistribModel.h"

@interface ORPulserDistribController : OrcaObjectController  {
	@private
		IBOutlet NSMatrix* patternMatrix0;
		IBOutlet NSButton* noisyEnvBroadcastEnabledButton;
		IBOutlet NSMatrix* patternMatrix1;
		IBOutlet NSMatrix* patternMatrix2;
		IBOutlet NSMatrix* patternMatrix3;

		IBOutlet NSButton* disableForPulserCB;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) noisyEnvBroadcastEnabledChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) patternChanged:(NSNotification*)aNotification;
- (void) disableForPulserChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) noisyEnvBroadcastEnabledButtonAction:(id)sender;
- (IBAction) loadAction:(id)sender;
- (IBAction) patternAction:(id)sender;
- (IBAction) allColAction:(id)sender;
- (IBAction) noneColAction:(id)sender;
- (IBAction) disableForPulserAction:(id)sender;

@end
