//
//  ORTask.h
//  Orca
//
//  Created by Mark Howe on Wed Nov 26 2003.
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

#import "ORModBusController.h"

@interface ORiTransGasSensorController : NSObject 
{
	id						model;
    IBOutlet NSView*        view;
	IBOutlet NSPopUpButton* channelPU;
	IBOutlet NSTextField*	nameField;
	IBOutlet NSTextField*	baseAddressField;
	IBOutlet NSTextField*	gasTypeField;
	IBOutlet NSTextField*	sensorTypeField;
	IBOutlet NSTextField*	gasReadingField;
	IBOutlet NSButton*		removeSelfButton;
	IBOutlet NSTextField*	powerField;
	IBOutlet NSTextField*	calibrationField;
	IBOutlet NSTextField*	zeroFaultField;
	IBOutlet NSTextField*	overRangeField;
	IBOutlet NSTextField*	currentLoopField;
	NSColor*				okColor;
	NSColor*				badColor;
	BOOL					alarmed;
	BOOL					failedSensor;
	BOOL					missingSensor;
    NSArray*                topLevelObjects;
 }

+ (id) sensorPanel;
- (id)	init;
- (void) registerNotificationObservers;

#pragma mark •••Accessors
- (NSView*)view;
- (void) setModel:(id)aModel;

#pragma mark ***Interface Management
- (void) channelChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) nameChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) gasTypeChanged:(NSNotification*)aNote;
- (void) sensorTypeChanged:(NSNotification*)aNote;
- (void) gasReadingChanged:(NSNotification*)aNote;
- (void) statusChanged:(NSNotification*)aNote;
- (void) stateChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) channelAction:(id)sender;
- (IBAction) nameAction:(id)sender;
- (void)	 updateButtons;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) removeSelf:(id)sender;
@end



