//
//  ORRamperController.h
//  test
//
//  Created by Mark Howe on 3/29/07.
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

@class ORAxis;
@class ORRampItem;
@class ZFlowLayout;
@class ORCompositeRamperView;

@interface ORRamperController : OrcaObjectController {
	IBOutlet ZFlowLayout*		rampItemContentView;
	IBOutlet ORCompositeRamperView*			ramperView;
	IBOutlet NSMatrix*			downRampPathMatrix;
	IBOutlet NSTextField*		downRateTextField;
	IBOutlet NSTextField*		numberRunningField;
	IBOutlet NSTextField*		titleField;
	IBOutlet NSButton*			listLockButton;
	IBOutlet NSButton*			startButton;
	IBOutlet NSButton*			stopButton;
	IBOutlet NSButton*			linearButton;
	IBOutlet NSButton*			logButton;
	IBOutlet NSButton*			scaleToMaxButton;
	IBOutlet NSButton*			scaleToTargetButton;
	NSMutableArray*				rampItemControllers;
    BOOL once;
}
- (NSString*) windowNibName;
- (NSString*) rampItemNibFileName;
- (ORRampItem*) selectedRampItem;
- (void) addRampItem:(ORRampItem*)anItem;
- (void) removeRampItem:(ORRampItem*)anItem;
- (void) setButtonStates;
- (void) numberRunningChanged:(NSNotification*)aNote;
- (void) updateView:(NSNotification*)aNote;
- (void) downRampPathChanged:(NSNotification*)aNote;
- (void) listLockChanged:(NSNotification*)aNote;
- (void) rampItemAdded:(NSNotification*)aNote;
- (void) rampItemRemoved:(NSNotification*)aNote;
- (void) downRateChanged:(NSNotification*)aNote;
- (void) selectionChanged:(NSNotification*)aNote;
- (void) globalEnabledChanged:(NSNotification*)aNote;
- (void) currentValueChanged:(NSNotification*)aNote;
- (ORAxis*) xAxis;
- (ORAxis*) yAxis;
- (ORCompositeRamperView*) ramperView;

#pragma mark ***Actions
- (IBAction) startGlobalAction:(id)sender;
- (IBAction) stopGlobalAction:(id)sender;
- (IBAction) downRampPathAction:(id)sender;
- (IBAction) downRateTextFieldAction:(id)sender;
- (IBAction) rescaleToMax:(id)sender;
- (IBAction) rescaleToTarget:(id)sender;
- (IBAction) listLockAction:(id)sender;
- (IBAction) makeLinear:(id)sender;
- (IBAction) makeLog:(id)sender;
- (IBAction) panic:(id)sender;
@end


