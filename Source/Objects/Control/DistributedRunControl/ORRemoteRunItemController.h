//
//  ORRemoteRunItemController.m
//  Orca
//
//  Created by Mark Howe on Apr 22, 2025.
//  Copyright (c) 2025 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Physics Department sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

@class ORRemoteRunItem;
@class ORRemoteRunItemController;
@class StopLightView;

@interface ORRemoteRunItemController : NSObject {
	id					    model;
    id                      owner;
    NSArray*                topLevelObjects;
    IBOutlet NSView*		view;
    IBOutlet NSButton*		plusButton;
    IBOutlet NSButton*		minusButton;
    IBOutlet NSButton*      connectButton;
    IBOutlet NSTextField*   ipNumberField;
    IBOutlet NSTextField*   remotePortField;
    IBOutlet StopLightView* lightBoardView;
    IBOutlet NSTextField*   connectedField;
    IBOutlet NSTextField*   systemNameField;
    IBOutlet NSTextField*   runStatusField;
    IBOutlet NSTextField*   runNumberField;
    IBOutlet NSButton*      ignoreCB;
}

#pragma mark ***Initialization
- (id)   initWithNib:(NSString*)aNibName;
- (void) awakeFromNib;
- (void) registerNotificationObservers;

#pragma mark ***Interface Management
- (void)    updateWindow;
- (NSView*) view;
- (void)    setOwner:(ORRemoteRunItemController*)anOwner;
- (void)    setModel:(id)aModel;
- (id)      model;
- (void)    endEditing;
- (void)    updateButtons;

- (void) isConnectionChanged:(NSNotification*)aNote;
- (void) remotePortChanged:  (NSNotification*)aNote;
- (void) systemNameChanged:  (NSNotification*)aNote;
- (void) ignoreChanged:      (NSNotification*)aNote;
- (void) runNumberChanged:   (NSNotification*)aNote;


#pragma mark ***Actions
- (IBAction) connectAction:      (id)sender;
- (IBAction) ipNumberAction:     (id)sender;
- (IBAction) remotePortAction:   (id)sender;
- (IBAction) ignoreAction:       (id)sender;
- (IBAction) insertRemoteRunItem:(id)sender;
- (IBAction) removeRemoteRunItem:(id)sender;
@end
