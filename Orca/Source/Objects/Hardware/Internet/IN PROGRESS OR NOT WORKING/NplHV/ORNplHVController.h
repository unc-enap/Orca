//
//  ORHPNplHVController.h
//  Orca
//
//  Created by Mark Howe on Thurs Dec 6 2007
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

#import "ORRamperController.h"

@interface ORNplHVController : ORRamperController 
{
	IBOutlet NSButton*		lockButton;
	IBOutlet NSButton*		sendButton;
	//lots of other Outlets inherited from the RamperController
	IBOutlet NSView*		totalView;
	IBOutlet NSTabView*		tabView;	
	NSSize					basicOpsSize;
	NSSize					rampOpsSize;
	NSView*					blankView;
}

#pragma mark •••Notifications

#pragma mark ***Interface Management
- (void) lockChanged:(NSNotification*)aNote;
- (void) setButtonStates;

#pragma mark •••Actions
- (IBAction) version:(id)sender;
- (IBAction) sendCmdAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) initBoard:(id) sender;

@end

