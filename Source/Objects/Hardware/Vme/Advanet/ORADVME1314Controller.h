//
//  ORADVME1314Controller.h
//  Orca
//
//  Created by Michael Marino on Mon 6 Feb 2012 
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


#pragma mark ¥¥¥Imported Files
#import "ORADVME1314Model.h"
#import "ORContainerController.h"

@class ORTriggerLogicView;

@interface ORADVME1314Controller : ORContainerController  {
	@private
    IBOutlet ORTriggerLogicView* logicView;
	IBOutlet NSMatrix*    writeMaskHexField;
	IBOutlet NSMatrix* 	  writeMaskBitMatrix;

	IBOutlet NSMatrix*    writeHexField;
	IBOutlet NSMatrix* 	  writeBitMatrix;
    IBOutlet NSTextField* baseAddress;

}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) writeMaskChanged:(NSNotification*)aNotification;
- (void) writeValueChanged:(NSNotification*)aNotification;
- (void) baseAddressChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Interface Management

#pragma mark ¥¥¥Actions
- (IBAction) write:(id)sender;
- (IBAction) dump:(id)sender;
- (IBAction) sync:(id)sender;
- (IBAction) reset:(id)sender;
- (IBAction) writeMaskHexAction:(id)sender;
- (IBAction) writeMaskBitAction:(id)sender;
- (IBAction) writeValueHexAction:(id)sender;
- (IBAction) writeValueBitAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;

@end
