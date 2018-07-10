//
//  ORPlotLinkController.h
//  Orca
//
//  Created by Mark Howe on Wed 23 23 2009.
//  Copyright © 2009 University of North Carolina. All rights reserved.
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


@interface ORPlotLinkController : OrcaObjectController
{
	IBOutlet NSTextField*	plotNameField;
	IBOutlet NSMatrix*		iconTypeMatrix;
    IBOutlet NSPopUpButton* dataCatalogPU;
    IBOutlet NSButton*		plotLinkLockButton;
}

#pragma mark •••Initialization
- (id) init;

#pragma mark •••Interface Management
- (void) iconTypeChanged:(NSNotification*)aNote;
- (void) plotNameChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) plotLinkLockChanged:(NSNotification *)aNote;
- (void) checkGlobalSecurity;
- (void) plotLinkLockChanged:(NSNotification*)aNote;
- (void) dataCatalogNameChanged:(NSNotification*)aNote;

- (void) populatePopup:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) iconTypeAction:(id)sender;
- (IBAction) openAltDialogAction:(id)sender;
- (IBAction) applyAction:(id)sender;
- (IBAction) plotNameAction:(id)sender;
- (IBAction) plotLinkLockAction:(id)sender;
- (IBAction) dataCatalogNameAction:(id)sender;

@end
