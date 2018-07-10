//
//  ORMotorController.h
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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


#pragma mark ¥¥¥Imported Files
#import "ORMotorModel.h"

@class ORAxis;
@class ORQueueView;

@interface ORMotorController : OrcaObjectController  {
	@private
		IBOutlet NSMatrix* motorProfileFields;
		IBOutlet NSButton* incButton;
		IBOutlet NSButton* decButton;
		IBOutlet NSButton* homeButton;
		IBOutlet NSButton* setStepCountButton;
		IBOutlet NSMatrix* multiplierMatrix;
		IBOutlet NSButton* goButton;
		IBOutlet NSButton* stopButton;
		IBOutlet NSPopUpButton* absRelStepPopUp;
		IBOutlet NSPopUpButton* risingEdgePopUp;
		IBOutlet NSPopUpButton* stepModePopUp;
		IBOutlet NSPopUpButton* holdCurrentPopUp;
		IBOutlet NSPopUpButton* absRelBrkPtPopUp;
		IBOutlet NSTextField* motorNameField;
		IBOutlet NSTextField* targetField;
		IBOutlet NSTextField* breakPointField;
		IBOutlet NSTextField* stepCountField;
		IBOutlet NSTextField* motorPositionField;
		IBOutlet NSTextField* homeDetectedField;
		IBOutlet NSTextField* seekAmountField;
		IBOutlet NSTextField* stepTargetField;
		IBOutlet NSProgressIndicator* motorRunningProgress;

		IBOutlet NSButton* usePatternFileCB;
		IBOutlet NSButton* startRunningPatternButton;
		IBOutlet NSButton* setPatternFileButton;
		IBOutlet NSMatrix* patternTypeMatrix;
		IBOutlet NSMatrix* motorPatternMatrix;
		IBOutlet NSTextField* patternFileName;

		IBOutlet NSMatrix* optionMatrix;
		IBOutlet NSMatrix* statusMatrix;
        IBOutlet ORAxis*   xAxis;
        IBOutlet ORQueueView*   queueView;
}


#pragma mark ¥¥¥Notifications
- (void) motorWorkerChanged:(NSNotification*)aNote;
- (void) patternChanged:(NSNotification*)aNote;
- (void) usePatternFileNameChanged:(NSNotification*)aNote;
- (void) patternFileNameChanged:(NSNotification*)aNote;
- (void) homeDetectedChanged:(NSNotification*)aNote;
- (void) motorRunningChanged:(NSNotification*)aNote;
- (void) motorPositionChanged:(NSNotification*)aNote;
- (void) holdCurrentChanged:(NSNotification*)aNote;
- (void) stepModeChanged:(NSNotification*)aNote;
- (void) riseFreqChanged:(NSNotification*)aNote;
- (void) driveFreqChanged:(NSNotification*)aNote;
- (void) accelerationChanged:(NSNotification*)aNote;
- (void) positionChanged:(NSNotification*)aNote;
- (void) multiplierChanged:(NSNotification*)aNote;
- (void) absRelChanged:(NSNotification*)aNote;
- (void) risingEdgeChanged:(NSNotification*)aNote;
- (void) breakPointChanged:(NSNotification*)aNote;
- (void) absBreakPointChanged:(NSNotification*)aNote;
- (void) stepCountChanged:(NSNotification*)aNote;
- (void) seekAmountChanged:(NSNotification*)aNote;
- (void) patternTypeChanged:(NSNotification*)aNote;
- (void) optionMaskChanged:(NSNotification*)aNote;
- (void) motorNameChanged:(NSNotification*)aNote;
- (void) updateButtons:(NSNotification*)aNote;
- (void) connectionChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) stepCountAction:(id)sender;
- (IBAction) holdCurrentAction:(id)sender;
- (IBAction) stepModeAction:(id)sender;
- (IBAction) incAction:(id)sender;
- (IBAction) decAction:(id)sender;
- (IBAction) multiplierAction:(id)sender;
- (IBAction) targetAction:(id)sender;
- (IBAction) absRelAction:(id)sender;
- (IBAction) setProfileAction:(id)sender;
- (IBAction) goAction:(id)sender;
- (IBAction) stopAction:(id)sender;
- (IBAction) risingEdgeAction:(id)sender;
- (IBAction) readMotorAction:(id)sender;
- (IBAction) seekHomeAction:(id)sender;
- (IBAction) readHomeAction:(id)sender;
- (IBAction) breakPointAction:(id)sender;
- (IBAction) absBreakPointAction:(id)sender;
- (IBAction) setStepCountAction:(id)sender;
- (IBAction) seekAmountAction:(id)sender;
- (IBAction) patternAction:(id)sender;
- (IBAction) usePatternFileAction:(id)sender;
- (IBAction) patternFileAction:(id)sender;
- (IBAction) selectPatternFileAction:(id)sender;
- (IBAction) startPatternRunAction:(id)sender;
- (IBAction) optionMaskAction:(id)sender;
- (IBAction) patternAction:(id)sender;
- (IBAction) patternTypeAction:(id)sender;
- (IBAction) motorNameAction:(id)sender;

#pragma mark ¥¥¥Data Source
- (void) getQueMinValue:(unsigned long*)aMinValue maxValue:(unsigned long*)aMaxValue head:(unsigned long*)aHeadValue tail:(unsigned long*)aTailValue;

@end
