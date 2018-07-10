//
//  ORFFTController.h
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


@interface NSObject (ORFFTControllerDataSource)
- (id)    plotView;
@end

@interface ORFFTController : NSObject {
    IBOutlet NSTextField*   serviceStatusField;
    IBOutlet NSButton*      fftButton;
    IBOutlet NSPopUpButton* fftOptionPopup;
    IBOutlet NSPopUpButton* fftWindowPopup;
    IBOutlet NSBox*			fftView;
	
	id       model;
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
- (void) fftOptionChanged:(NSNotification*)aNote;
- (void) fftWindowChanged:(NSNotification*)aNote;
- (void) orcaRootServiceConnectionChanged:(NSNotification*)aNote;

#pragma mark ***Actions
- (IBAction) doFFTAction:(id)sender;
- (IBAction) fftOptionAction:(id)sender;
- (IBAction) fftWindowAction:(id)sender;
@end


