//  ORCalibration.h
//  Orca
//
//  Created by Mark Howe on 3/21/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
//
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

@class ORCalibration;

@interface ORCalibrationPane : NSWindowController 
{
	IBOutlet NSButton*		customButton;
	IBOutlet NSButton*		catalogButton;
	IBOutlet NSButton*		storeButton;
	IBOutlet NSButton*		deleteButton;
	IBOutlet NSPopUpButton*	selectionPU;
	IBOutlet NSButton*		ignoreButton;
	IBOutlet NSButton*		calibrateButton;
	IBOutlet NSTableView*   calibrationTableView;
	IBOutlet NSTextField*	unitsField;
	IBOutlet NSTextField*	labelField;
	IBOutlet NSTextField*	nameField;
	IBOutlet NSButton*		cancelButton;
    IBOutlet NSButton*		applyButton;
    IBOutlet NSButton*		removeButton;
	IBOutlet NSButton*		addPtButton;
	IBOutlet NSButton*		removePtButton;
	id                      model;
    ORCalibration*          calibration;
}

+ (id) calibrateForWindow:(NSWindow *)aWindow modalDelegate:(id)aDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo;

- (id) initWithModel:(id)aModel;
- (void) beginSheetFor:(NSWindow *)aWindow delegate:(id)aDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo;
- (void) calibrate;
- (void) enableControls;
- (void) populateSelectionPU;
- (void) loadUI;

- (IBAction) storeAction:(id)sender;
- (IBAction) typeAction:(id)sender;
- (IBAction) selectionAction:(id)sender;
- (IBAction) deleteAction:(id)sender;
- (IBAction) apply:(id)sender;
- (IBAction) remove:(id)sender;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) addPtAction:(id)sender;
- (IBAction) removePtAction:(id)sender;
- (IBAction) ignore:(id)sender;

@property (retain) ORCalibration* calibration;

@end

@interface ORCalibration : NSObject 
{
	NSMutableArray*	calibrationArray;
	double			slope;
	double			intercept;
	NSString*		units;
	NSString*		label;
	BOOL			calibrationValid;
	BOOL			ignoreCalibration;
	int				type;
	NSString*		calibrationName;
}

- (BOOL) isValidCalibration;
- (NSMutableArray*)calibrationArray;
- (double) slope;
- (double) intercept;
- (void) calibrate;
- (BOOL) ignoreCalibration;
- (void) setIgnoreCalibration:(BOOL)aState;
- (BOOL) useCalibration;
- (NSString*) units;
- (void) setUnits:(NSString*)unitString;
- (NSString*) label;
- (void) setLabel:(NSString*)aString;
- (void) setCalibrationName:(NSString*)nameString;
- (NSString*) calibrationName;
- (void) setType:(int)aType;
- (int) type;
- (double) convertedValueForChannel:(int)aChannel;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

@interface NSObject (ORCalibration)
- (id) calibration;
- (void) setCalibration:(id)aCalibration;
- (void) postUpdate;
@end
