//
//  ORHWizSelectionController.h
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

ORHWizSelectionController

Overview:

The ORHWizSelectionController is the controller class for the custom views used 
in the table that represents the available rule components.
It provides the view, and answers to actions methods from the view or the 
table view controller.

*****************************************************************************/

@interface ORHWizSelectionController : NSObject
{
    @private

    IBOutlet NSView *subview;
    IBOutlet NSPopUpButton* logicalPopUpButton;
    IBOutlet NSPopUpButton* objPopUpButton;
    IBOutlet NSPopUpButton* selectionPopUpButton;
    IBOutlet NSTextField*   selectionTextField;
    IBOutlet NSStepper*     selectionStepper;

    int logicalTag;
    int objTag;
    int selectionTag;
    int selectionValue;
    NSArray* selectionArray;
    NSArray* topLevelObjects;
}

// Convenience factory method
+ (id) controller;

// The view displayed in the table view
#pragma mark ***Accessors
- (NSArray *)selectionArray;
- (void)setSelectionArray:(NSArray *)aSelectionArray;
- (int) logicalTag;
- (void) setLogicalTag:(int)aNewLogicalTag;
- (int) objTag;
- (void) setObjTag:(int)aNewObjTag;
- (int) selectionTag;
- (void) setSelectionTag:(int)aNewSelectionTag;
- (int) selectionValue;
- (void) setSelectionValue:(int)aNewSelectionValue;
- (NSView *) view;
- (NSUndoManager *)undoManager;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) selectionChanged:(NSNotification*)note;
- (void) selectionValueChanged:(NSNotification*)note;
- (void) configChanged:(NSNotification*)aNote;
- (void) setupSelection;

- (void) installSelectionArray:(NSArray*)anArray;
- (void) enableForRow:(int)row;

#pragma mark ***Actions
- (IBAction) logicalPopUpButtonAction:(id)sender;
- (IBAction) objPopUpButtonAction:(id)sender;
- (IBAction) selectionPopUpButtonAction:(id)sender;
- (IBAction) selectionTextFieldAction:(id)sender;


//- (RuleCriteriaType) selectedRuleCriteriaType;
//- (void) setSelectedRuleCriteriaType:(RuleCriteriaType) criteriaType;

// Add action methods from the view components here

@end
extern NSString* ORSelectionControllerSelectionChangedNotification;
extern NSString* ORSelectionControllerSelectionValueChangedNotification;

