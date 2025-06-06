//
//  ORFec32Controller.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORFec32Model.h"
#import "ORMultiStateBox.h"

#pragma mark •••Forward Declarations
@class ORFecPmtsView;
@class ORGroupView;

#define kPMTStateSeqColumn      0
#define kPMTState20nsColumn     1
#define kPMTState100nsColumn    2
#define kPMTStateCMOSColumn     3

@interface ORFec32Controller : OrcaObjectController  {
    IBOutlet NSTabView* tabView;
    IBOutlet ORGroupView*	groupView;
	IBOutlet NSButton*		showVoltsCB;
	IBOutlet NSTextField*	commentsTextField;
    IBOutlet ORFecPmtsView* pmtView;
    IBOutlet NSTextField*	vResField;
    IBOutlet NSTextField*	hvRefField;
    IBOutlet NSMatrix*		cmosMatrix;
    IBOutlet NSButton*		lockButton;
	IBOutlet NSTextField*	crateNumberField;
	IBOutlet NSTextField*   fecNumberField;
	IBOutlet NSMatrix*		pmtImages0;
	IBOutlet NSMatrix*		onlineSwitches0;
	IBOutlet NSMatrix*		onlineSwitches1;
	IBOutlet NSMatrix*		onlineSwitches2;
	IBOutlet NSMatrix*		onlineSwitches3;
	IBOutlet NSMatrix*		pmtImages1;
	IBOutlet NSMatrix*		pmtImages2;
	IBOutlet NSMatrix*		pmtImages3;
    ;
    IBOutlet NSMatrix*      pmtStateLabelMatrix0_15;
    IBOutlet NSMatrix*      pmtStateMatrix0_15;
    IBOutlet NSMatrix*      pmtStateLabelMatrix16_31;
    IBOutlet NSMatrix*      pmtStateMatrix16_31;
    IBOutlet NSButton *loadPMTStateButton;
	IBOutlet NSTextField*	boardIdField;
    IBOutlet NSButton*		initButton;
	IBOutlet NSButton*		autoInitButton;
    IBOutlet NSButton*		readVoltagesButton;
    IBOutlet NSButton*		readCMOSRatesButton;
	
	//labels
	IBOutlet NSMatrix*		dc0Labels;
	IBOutlet NSMatrix*		dc1Labels;
	IBOutlet NSMatrix*		dc2Labels;
	IBOutlet NSMatrix*		dc3Labels;

    
	IBOutlet NSTabView*		variablesTabView;
	IBOutlet NSPopUpButton*	variablesSelectionPU;
	
	//voltage adcs
	IBOutlet NSMatrix*		adcLabelsMatrix;
	IBOutlet NSMatrix*		adcMatrix;
	IBOutlet NSMatrix*		adcUnitsMatrix;

	//thresholds
	IBOutlet NSMatrix*		thresholds0LabelsMatrix;
	IBOutlet NSMatrix*		thresholds0Matrix;
	IBOutlet NSMatrix*		thresholds1LabelsMatrix;
	IBOutlet NSMatrix*		thresholds1Matrix;
	
	//vBals
	IBOutlet NSMatrix*		vb0LabelsMatrix;
	IBOutlet NSMatrix*		vb0HMatrix;
	IBOutlet NSMatrix*		vb0LMatrix;
	IBOutlet NSMatrix*		vb1LabelsMatrix;
	IBOutlet NSMatrix*		vb1HMatrix;
	IBOutlet NSMatrix*		vb1LMatrix;
	
	//cmos
	IBOutlet NSMatrix*		cmosRates0LabelsMatrix;
	IBOutlet NSMatrix*		cmosRates0Matrix;
	IBOutlet NSMatrix*		cmosRates1LabelsMatrix;
	IBOutlet NSMatrix*		cmosRates1Matrix;
	
	NSNumberFormatter*		cmosFormatter;

    //DB
    IBOutlet NSMatrix*      problemMatrix;

	//cache some stuff to make things easier
	NSMatrix* onlineSwitches[4];
	NSMatrix* pmtImages[4];
    
    ORMultiStateBox *msbox;
}

#pragma mark •••Accessors
- (ORGroupView *)groupView;

#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) everythingChanged:(NSNotification*)aNote;
- (void) updatePMTInfo:(NSNotification*)aNote;
- (void) dcVBsChanged:(NSNotification*)aNote;
- (void) dcThresholdsChanged:(NSNotification*)aNote;
- (void) variableDisplayChanged:(NSNotification*)aNote;
- (void) adcStatusChanged:(NSNotification*)aNote;
- (void) loadAdcStatus:(int)i;
- (void) enablePmtGroup:(short)enabled groupNumber:(short)group;
- (void) onlineMaskChanged:(NSNotification*)aNote;
- (void) showVoltsChanged:(NSNotification*)aNote;
- (void) commentsChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (void) lockChanged:(NSNotification*)note;
- (void) groupChanged:(NSNotification*)note;
- (void) runStatusChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) vResChanged:(NSNotification*)aNote;
- (void) hvRefChanged:(NSNotification*)aNote;
- (void) cmosChanged:(NSNotification*)aNote;
- (void) boardIdChanged:(NSNotification*)aNote;
- (void) cmosRatesChanged:(NSNotification*)aNote;
- (void) updateSequencerInfo:(NSNotification*)aNote;
- (void) update20nTriggerInfo:(NSNotification*)aNote;
- (void) update100nTriggerInfo:(NSNotification*)aNote;
- (void) updateCmosReadInfo:(NSNotification*)aNote;
- (void) keyDown:(NSEvent *)event;

#pragma mark •••Actions
- (IBAction) readCmosRatesAction:(id)sender;
- (IBAction) variableDisplayPUAction:(id)sender;
- (IBAction) initAction:(id)sender;
- (IBAction) probeAction:(id)sender;
- (IBAction) onlineMaskAction:(id)sender;
- (IBAction) incCardAction:(id)sender;
- (IBAction) decCardAction:(id)sender;
- (IBAction) showVoltsAction:(id)sender;
- (IBAction) commentsTextFieldAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) vResAction:(id)sender;
- (IBAction) hvRefAction:(id)sender;
- (IBAction) cmosAction:(id)sender;
- (IBAction) autoInitAction:(id)sender;
- (IBAction) readVoltagesAction:(id)sender;
- (IBAction) pmtStateClickAction:(id)sender;
- (IBAction) loadHardware:(id)sender;
@end
