//
//  ORCameraController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
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
#import <QTKit/QTKit.h>

@interface ORCameraController : OrcaObjectController
{
    IBOutlet NSButton*		cameraLockButton;
	IBOutlet NSPopUpButton* deviceIndexPU;
    IBOutlet NSButton*		startStopButton;
	IBOutlet NSPopUpButton*	updateIntervalPU;
	IBOutlet NSImageView*	mCaptureView;
	IBOutlet QTMovieView*	mMovieView;
	IBOutlet NSTextField*   runStateField;
	
	IBOutlet NSButton*		viewPastHistoryButton;
	IBOutlet NSButton*		viewCurrentButton;
	IBOutlet NSButton*		setHistoryFolderButton;
	IBOutlet NSButton*		addFrameNowButton;
	IBOutlet NSTextField*   historyFolderField;
	IBOutlet NSTextField*   movieSizeField;
	IBOutlet NSPopUpButton* keepFileIntervalPU;
	IBOutlet NSPopUpButton* saveFileIntervalPU;
}

#pragma mark •••Initialization
- (id) init;

#pragma mark •••Interface Management
- (void) deviceIndexChanged:(NSNotification*)aNote;
- (void) keepFileIntervalChanged:(NSNotification*)aNote;
- (void) saveFileIntervalChanged:(NSNotification*)aNote;
- (void) historyFolderChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) cameraLockChanged:(NSNotification *)aNote;
- (void) checkGlobalSecurity;
- (void) updateIntervalChanged:(NSNotification*)aNote;
- (void) cameraImageChanged:(NSNotification*)aNote;
- (void) cameraRunningChanged:(NSNotification*)aNote;
- (void) movieChanged:(NSNotification*)aNote;
- (void) updateMovieFileSize;
- (void) setButtonStates;

#pragma mark •••Actions
- (IBAction) deviceIndexAction:(id)sender;
- (IBAction) keepFileIntervalAction:(id)sender;
- (IBAction) saveFileIntervalAction:(id)sender;
- (IBAction) cameraLockAction:(id)sender;
- (IBAction) updateIntervalAction:(id)sender;
- (IBAction) startSession:(id)sender;
- (IBAction) addFrameNowAction:(id)sender;

- (IBAction) viewPastHistoryAction:(id)sender;
- (IBAction) viewCurrentAction:(id)sender;
- (IBAction) setHistoryFolderAction:(id)sender;

@end
