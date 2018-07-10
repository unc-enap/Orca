//-------------------------------------------------------------------------
//  OREHS8260pController.h
//
//  Created by Mark Howe on Tues Feb 1,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORiSegHVCardController.h"

@interface OREHS8260pController : ORiSegHVCardController 
{
	IBOutlet   NSPopUpButton*	outputFailureBehaviorPU;
	IBOutlet   NSPopUpButton*	currentTripBehaviorPU;
	IBOutlet   NSTextField*		tripTimeTextField;
	IBOutlet   NSTextField*		rampTypeField;
	IBOutlet   NSTableView*		ramperTableView;
	IBOutlet   NSDrawer*		ramperDrawer;
	IBOutlet   NSTextField*		hwKillStatusField;
}

- (id)   init;

#pragma mark •••Interface Management
- (void) outputFailureBehaviorChanged:(NSNotification*)aNote;
- (void) currentTripBehaviorChanged:(NSNotification*)aNote;
- (void) tripTimeChanged:(NSNotification*)aNote;
- (void) ramperEnabledChanged:(NSNotification*)aNote;
- (void) ramperParameterChanged:(NSNotification*)aNote;
- (void) ramperStateChanged:(NSNotification*)aNote;
- (void) setRampTypeField;

#pragma mark •••Actions
- (IBAction) outputFailureBehaviorAction:(id)sender;
- (IBAction) currentTripBehaviorAction:(id)sender;
- (IBAction) tripTimeAction:(id)sender;

#pragma mark •••Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex;
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

@end
