//
//  OR1dFitController.h
//  testplot
//
//  Created by Mark Howe on Tue May 18 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


@interface NSObject (OR1dFitControllerDataSource)
- (id)    plotView;
@end

@interface OR1dFitController : NSObject {
    IBOutlet NSButton*      fitButton;
    IBOutlet NSButton*      deleteButton;
    IBOutlet NSPopUpButton* fitTypePopup;
    IBOutlet NSTextField*   serviceStatusField;
    IBOutlet NSTextField*   polyOrderField;
 	IBOutlet NSTextField*   fitFunctionField;
    IBOutlet NSBox*			fitView;
	
	id model;
    NSArray* topLevelObjects;
}

+ (id) panel;

#pragma mark ***Initialization
- (id) init;
- (NSView*) view;

#pragma mark ***Accessors
- (void)	setModel:(id)aModel;
- (id)		model ;

#pragma mark ***Notifications
- (void) updateWindow;
- (void) registerNotificationObservers;
- (void) fitFunctionChanged:(NSNotification*)aNote;
- (void) fitOrderChanged:(NSNotification*)aNote;
- (void) fitTypeChanged:(NSNotification*)aNote;
- (void) orcaRootServiceFitChanged:(NSNotification*)aNote;
- (void) orcaRootServiceConnectionChanged:(NSNotification*)aNote;

#pragma mark ***Actions
- (void) endEditing;
- (IBAction) doFitAction:(id)sender;
- (IBAction) deleteFitAction:(id)sender;

- (IBAction) fitTypeAction:(id)sender;
- (IBAction) fitOrderAction:(id)sender;
- (IBAction) fitFunctionAction:(id)sender;
@end


