//
//  ORHWizActionController.h
//  SubviewTableViewRuleEditor
//
//  Created by Mark Howe on Tue Dec 02 2003.
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


/*****************************************************************************

ORHWizActionController

Overview:

The ORHWizActionController is the controller class for the custom views used 
in the table that represents the available rule components.
It provides the view, and answers to actions methods from the view or the 
table view controller.

*****************************************************************************/

@interface ORHWizActionController : NSObject
{
    @private
	IBOutlet NSView *subview;
	IBOutlet NSPopUpButton* actionPopupButton;
	IBOutlet NSPopUpButton* parameterPopupButton;
	IBOutlet NSTextField* parameterValueTextField;
	IBOutlet NSStepper* parameterValueStepper;
	IBOutlet NSTextField* valueChangeField;
	IBOutlet NSTextField* unitsField;

	int actionTag;
	int parameterTag;
	NSNumber* parameterValue;
	NSArray* paramArray;
    NSArray* topLevelObjects;
}

// Convenience factory method
+ (id) controller;

#pragma mark ***Initialization
-(id)   init;
-(void) dealloc;
-(void) awakeFromNib;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) actionChanged:(NSNotification*)note;
- (void) parameterValueChanged:(NSNotification*)note;

#pragma mark ***Accessors
- (NSArray*)paramArray;
- (void) setParamArray:(NSArray*)aParamArray;
- (NSView*) view;
- (int) actionTag;
- (void) setActionTag:(int)aNewActionTag;
- (int) parameterTag;
- (void) setParameterTag:(int)aNewParameterTag;
- (NSNumber*) parameterValue;
- (void) setParameterValue:(NSNumber*)aNewParameterValue;
- (NSUndoManager*)undoManager;
- (BOOL)validateMenuItem:(NSMenuItem*)anItem;

#pragma mark ***Actions
- (IBAction) actionPopupButtonAction:(id)sender;
- (IBAction) parameterPopupButtonAction:(id)sender;
- (IBAction) parameterValueTextFieldAction:(id)sender;
- (void) installParamArray:(NSArray*)anArray;

@end

extern NSString* ORActionControllerActionChanged;
extern NSString* ORActionControllerParameterValueChanged;

