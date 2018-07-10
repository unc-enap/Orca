//
//  ORContainerController.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
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


#pragma mark ¥¥¥Forward Declarations
@class ORGroupView;

@interface ORContainerController : OrcaObjectController
{
    IBOutlet ORGroupView*   groupView;
    IBOutlet NSTextField*   lockDocField;
    IBOutlet NSButton*      goBackButton;
    IBOutlet NSTextField*   scaleFactorField;
}

- (id) init;
- (void) awakeFromNib;

#pragma mark *Accessors
- (void) groupChanged:(NSNotification*)note;
- (ORGroupView *)groupView;
- (void) documentLockChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) scaleFactorChanged:(NSNotification*)aNote;
- (void) remoteScaleFactorChanged:(NSNotification*)aNote;
-(void) backgroundImageChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) openHelp:(NSToolbarItem*)item;
- (IBAction) statusLog:(NSToolbarItem*)item;
- (IBAction) alarmMaster:(NSToolbarItem*)item;
- (IBAction) openCatalog:(NSToolbarItem*)item;
- (IBAction) openHWWizard:(NSToolbarItem*)item;
- (IBAction) openPreferences:(NSToolbarItem*)item; 
- (IBAction) scaleFactorAction:(id)sender;
- (IBAction) openCommandCenter:(NSToolbarItem*)item;
- (IBAction) openTaskMaster:(NSToolbarItem*)item; 
- (NSRect)windowWillUseStandardFrame:(NSWindow*)sender defaultFrame:(NSRect)defaultFrame;

- (IBAction) goBackAction:(id)sender;

@end
