//-------------------------------------------------------------------------
//  ORComparatorController.h
//
//  Created by Mark A. Howe on Thursday 05/12/2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark ***Imported Files

#import "ORProcessElementController.h"

@interface ORComparatorController : ORProcessElementController {
	@private
	IBOutlet   NSTextField* rangeForEqualTextField;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ¥¥¥Interface Management
- (void) rangeForEqualChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) rangeForEqualTextFieldAction:(id)sender;

@end
