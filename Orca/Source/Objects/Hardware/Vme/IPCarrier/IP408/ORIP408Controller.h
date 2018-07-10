//
//  ORIP408Controller.h
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


#pragma mark ¥¥¥Imported Files
#import "ORIP408Model.h"
#import "ORContainerController.h"


@interface ORIP408Controller : ORContainerController  {
	@private
	IBOutlet NSTextField* writeMaskDecimalField;
	IBOutlet NSTextField* writeMaskHexField;
	IBOutlet NSMatrix* 	  writeMaskBitMatrix;

	IBOutlet NSTextField* writeDecimalField;
	IBOutlet NSTextField* writeHexField;
	IBOutlet NSMatrix* 	  writeBitMatrix;

	IBOutlet NSTextField* readMaskDecimalField;
	IBOutlet NSTextField* readMaskHexField;
	IBOutlet NSMatrix* 	  readMaskBitMatrix;

	IBOutlet NSTextField* readDecimalField;
	IBOutlet NSTextField* readHexField;
	IBOutlet NSMatrix* 	  readBitMatrix;

}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) writeMaskChanged:(NSNotification*)aNotification;
- (void) writeValueChanged:(NSNotification*)aNotification;
- (void) readMaskChanged:(NSNotification*)aNotification;
- (void) readValueChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Interface Management

#pragma mark ¥¥¥Actions
- (IBAction) read:(id)sender;
- (IBAction) write:(id)sender;
- (IBAction) writeMaskDecimalAction:(id)sender;
- (IBAction) writeMaskHexAction:(id)sender;
- (IBAction) writeMaskBitAction:(id)sender;
- (IBAction) writeValueDecimalAction:(id)sender;
- (IBAction) writeValueHexAction:(id)sender;
- (IBAction) writeValueBitAction:(id)sender;
- (IBAction) readMaskDecimalAction:(id)sender;
- (IBAction) readMaskHexAction:(id)sender;
- (IBAction) readMaskBitAction:(id)sender;

@end
