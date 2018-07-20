//
//  OReCPU147Controller.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 16 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
@class ORQueueView;

@interface OReCPU147Controller : OrcaObjectController {
    IBOutlet NSTextField*   fileNameField;
	IBOutlet NSButton*		setFileButton;
	IBOutlet NSButton*		dumpCodeButton;
	IBOutlet NSButton*		verifyCodeButton;
	IBOutlet NSButton*		diagButton;
	IBOutlet NSButton*		outputButton;
	IBOutlet NSButton*		errorButton;
	IBOutlet NSButton*		messageButton;
	IBOutlet ORQueueView* 	queueView;
	IBOutlet NSTextView*	hexView;
	IBOutlet NSDrawer*		diagDrawer;
	IBOutlet NSDrawer*		outputDrawer;
	IBOutlet NSDrawer*		messageDrawer;
	IBOutlet NSDrawer*		errorDrawer;

	IBOutlet NSPopUpButton* updateButton;

	IBOutlet NSTextView* 	outputView;
	IBOutlet NSTextView* 	errorView;
	IBOutlet NSTextView*  	messageView;
    IBOutlet NSTextField*   debugLevelField;
}

- (void) registerNotificationObservers;

#pragma mark ¥¥¥Accessors
- (NSTextField*) fileNameField;
- (NSButton*) 	setFileButton;
- (NSButton*) 	dumpCodeButton;
- (NSButton*) 	verifyCodeButton;
- (NSButton*) 	diagButton;
- (NSButton*) 	outputButton;
- (NSButton*) 	errorButton;
- (NSButton*) 	messageButton;
- (NSTextView*) hexView;
- (NSDrawer*) 	diagDrawer;
- (NSDrawer*) 	outputDrawer;
- (NSDrawer*) 	messageDrawer;
- (NSDrawer*) 	errorDrawer;

#pragma mark ¥¥¥Interface Management
- (void) fileNameChanged:(NSNotification*)aNotification;
- (void) updateIntervalChanged:(NSNotification*)aNotification;
- (void) stuctureUpdated:(NSNotification*)aNotification;
- (void) queChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) selectFile:(id)sender;
- (IBAction) download:(id)sender;
- (IBAction) start:(id)sender;
- (IBAction) stop:(id)sender;
- (IBAction) dump:(id)sender;
- (IBAction) setUpdateIntervalAction:(id)sender;
- (IBAction) updateNowAction:(id)sender;
- (IBAction) verifyCodeAction:(id)sender;
- (IBAction) incDebugLevelAction:(id)sender;

- (void) getQueMinValue:(uint32_t*)aMinValue maxValue:(uint32_t*)aMaxValue head:(uint32_t*)aHeadValue tail:(uint32_t*)aTailValue;


@end
