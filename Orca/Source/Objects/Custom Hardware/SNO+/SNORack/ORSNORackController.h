//
//  ORSNORackController.h
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
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

#pragma mark •••Imported Files

#import "OrcaObjectController.h"

@interface ORSNORackController : OrcaObjectController
{
    IBOutlet ORGroupView*   groupView;
    IBOutlet NSTextField*   lockDocField;
    IBOutlet NSTextField*   rackNumberField;
    IBOutlet NSTextField*   crate0Field;
    IBOutlet NSTextField*   crate1Field;
}

- (id) init;
- (void) awakeFromNib;

#pragma mark •••Accessors
- (ORGroupView *)groupView;
- (void) setModel:(id)aModel;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) groupChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (BOOL) validateMenuItem:(NSMenuItem*)aMenuItem;
- (void) documentLockChanged:(NSNotification*)aNote;
- (void) setCrateLabels;
-(void)keyDown:(NSEvent*)event;


- (IBAction) delete:(id)sender; 
- (IBAction) cut:(id)sender; 
- (IBAction) paste:(id)sender ;
- (IBAction) selectAll:(id)sender;
//-----------------------------------------------------------------

@end
