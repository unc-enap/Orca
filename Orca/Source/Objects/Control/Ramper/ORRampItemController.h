//
//  ORRampItemController.h
//  Orca
//
//  Created by Mark Howe on 5/23/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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


#import <Cocoa/Cocoa.h>

@class ORRampItem;
@class ORRamperController;

@interface ORRampItemController : NSObject {
	id							model;
	ORRamperController*			owner;
    IBOutlet NSView*			view;
    IBOutlet NSButton*			plusButton;
    IBOutlet NSButton*			minusButton;
    IBOutlet NSButton*			listLockButton;
    IBOutlet NSButton*			startStopButton;
    IBOutlet NSTextField*		crateNumberField;
    IBOutlet NSTextField*		cardNumberField;
    IBOutlet NSTextField*		channelNumberField;
    IBOutlet NSTextField*		rampTargetField;
    IBOutlet NSTextField*		currentValueField;
    IBOutlet NSPopUpButton*		targetNamePU;
    IBOutlet NSPopUpButton*		selectorPU;
    IBOutlet NSProgressIndicator* progressIndicator;
    IBOutlet NSButton*			visibleButton;
    IBOutlet NSButton*			globalEnableButton;
    NSArray*                    topLevelObjects;
}

#pragma mark ***Interface Management
- (id) initWithNib:(NSString*)aNibName;
- (void) awakeFromNib;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (NSView*) view;
- (void) setOwner:(ORRamperController*)anOwner;
- (void) setModel:(id)aModel;
- (id) model;
- (void) globalEnabledChanged:(NSNotification*)aNote;
- (void) currentValueChanged:(NSNotification*)aNote;
- (void) parameterNameChanged:(NSNotification*)aNote;
- (void) targetNameChanged:(NSNotification*)aNote;
- (void) parametersChanged:(NSNotification*)aNote;
- (void) crateNumberChanged:(NSNotification*)aNote;
- (void) cardNumberChanged:(NSNotification*)aNote;
- (void) channelNumberChanged:(NSNotification*)aNote;
- (void) visibleChanged:(NSNotification*)aNote;
- (void) rampTargetChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (NSMutableDictionary*) miscAttributesForKey:(NSString*)aKey;
- (void) populatePopups;
- (void) reloadObjects:(NSNotification*)aNote;
- (void) ramperRunningChanged:(NSNotification*)aNote;

#pragma mark ***Actions
- (IBAction) rampTargetAction:(id)sender;
- (IBAction) globalEnabledAction:(id)sender;
- (IBAction) targetSelectionAction:(id)sender;
- (IBAction) paramSelectionAction:(id)sender;
- (IBAction) crateNumberAction:(id)sender;
- (IBAction) cardNumberAction:(id)sender;
- (IBAction) channelNumberAction:(id)sender;
- (IBAction) insertRampItem:(id)sender;
- (IBAction) removeRampItem:(id)sender;
- (IBAction) selectItem:(id)sender;
- (IBAction) startStop:(id)sender;
- (IBAction) panic:(id)sender;
- (void)     endEditing;
@end
