//-------------------------------------------------------------------------
//  ORXYCom200Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/18/2008.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORXYCom200Model.h"

@class ORPISlashTChipController;

@interface ORXYCom200Controller : OrcaObjectController 
{	
	IBOutlet NSPopUpButton* selectedPLTPU;
	IBOutlet NSView*		chip1View;
	IBOutlet NSView*		chip2View;

    // Register Box
	IBOutlet NSTextField*   slotField;
	IBOutlet NSTextField*   addressText;
    IBOutlet NSStepper* 	addressStepper;
    IBOutlet NSTextField* 	addressTextField;
    IBOutlet NSStepper* 	writeValueStepper;
    IBOutlet NSTextField* 	writeValueTextField;
    IBOutlet NSPopUpButton*	registerAddressPopUp;
    IBOutlet NSButton*		basicWriteButton;
    IBOutlet NSButton*		basicReadButton;
	IBOutlet NSTextField*	registerOffsetField;
	IBOutlet NSTextField*   regNameField;

    IBOutlet NSButton*      basicOpsLockButton;
    IBOutlet NSButton*      settingLockButton;

	IBOutlet NSButton*		initBoardButton;
	IBOutlet NSButton*		reportButton;
	
	NSMutableArray*			subControllers;
	BOOL					viewsSetup;

	//Easy Setup Timer
	IBOutlet   NSTextField* preloadLowField;
	IBOutlet   NSTextField* preloadMiddleField;
	IBOutlet   NSTextField* preloadHighField;
	IBOutlet   NSTextField* timerControlField;
	IBOutlet   NSTextField* periodField;

}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) populatePopup;
- (NSMutableArray*) subControllers;
- (void) setSubControllers:(NSMutableArray*)newSubControllers;
- (void) removeSubPlotViews;
- (void) setUpViews;

#pragma mark •••Interface Management
- (void) modelChanged:(NSNotification*)aNote;
- (void) selectedPLTChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) writeValueChanged: (NSNotification*) aNotification;
- (void) selectedRegIndexChanged: (NSNotification*) aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) updateRegisterDescription:(short) aRegisterIndex;
- (void) initSquareWave:(int)chipIndex;

#pragma mark •••Actions
- (IBAction) selectedPLTPUAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) writeValueAction: (id) aSender;
- (IBAction) selectRegisterAction: (id) aSender;

- (IBAction) read: (id) pSender;
- (IBAction) write: (id) pSender;
- (IBAction) initBoard:(id)sender;
- (IBAction) report:(id)sender;
@end

//the controller for the PI/T Chip model
@interface ORPISlashTChipController : NSObject 
{	
    IBOutlet NSView*		theView;
	
	//Gen Reg
	IBOutlet NSPopUpButton* modePU;
	IBOutlet NSPopUpButton* H1SensePU;
	IBOutlet NSPopUpButton* H2SensePU;
	IBOutlet NSPopUpButton* H3SensePU;
	IBOutlet NSPopUpButton* H4SensePU;
	IBOutlet NSPopUpButton* H12EnablePU;
	IBOutlet NSPopUpButton* H34EnablePU;
	
	//Port A
	IBOutlet NSPopUpButton* portASubModePU;
	IBOutlet NSPopUpButton* portAH1ControlPU;
	IBOutlet NSPopUpButton* portAH2InterruptPU;
	IBOutlet NSPopUpButton* portAH2ControlPU;
	IBOutlet NSMatrix*		portADirectionMatrix;
	IBOutlet NSTextField*   portADataField;
	IBOutlet NSPopUpButton* portATransceiverDirPU;
	IBOutlet NSButton*		emitModeButton;
	
	//Port B
	IBOutlet NSPopUpButton* portBSubModePU;
	IBOutlet NSPopUpButton* portBH1ControlPU;
	IBOutlet NSPopUpButton* portBH2InterruptPU;
	IBOutlet NSPopUpButton* portBH2ControlPU;	
	IBOutlet NSMatrix*		portBDirectionMatrix;
	IBOutlet NSTextField*   portBDataField;
	IBOutlet NSPopUpButton* portBTransceiverDirPU;

	//Port C
	IBOutlet NSMatrix*		portCDirectionMatrix;
	IBOutlet NSMatrix*		portCDataMatrix;
	
	//Timer
	IBOutlet   NSTextField* preloadLowField;
	IBOutlet   NSTextField* preloadMiddleField;
	IBOutlet   NSTextField* preloadHighField;
	IBOutlet   NSTextField* timerControlField;
	IBOutlet   NSTextField* periodField;
	
	IBOutlet   NSButton* easyTimerStartButton;
	
	//local state
	id						model;
	ORXYCom200Controller*	owner;
	int						chipIndex;
    NSArray*                topLevelObjects;
}

-(id) initWithOwner:(ORXYCom200Controller*)anOwner chipIndex:(int)anIndex;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (NSView*) getView;
- (void) awakeFromNib;
- (void) setModel:(id)aModel;
- (void) setButtonStates;
- (void) populatePopup;

#pragma mark •••Interface Management
- (void) lockChanged:(NSNotification*)aNote;

//Gen Reg
- (void) modeChanged:(NSNotification*)aNote;
- (void) H1SenseChanged:(NSNotification*)aNote;
- (void) H2SenseChanged:(NSNotification*)aNote;
- (void) H3SenseChanged:(NSNotification*)aNote;
- (void) H4SenseChanged:(NSNotification*)aNote;
- (void) H12EnableChanged:(NSNotification*)aNote;
- (void) H34EnableChanged:(NSNotification*)aNote;

//Port A
- (void) portASubModeChanged:(NSNotification*)aNote;
- (void) portAH1ControlChanged:(NSNotification*)aNote;
- (void) portAH2InterruptChanged:(NSNotification*)aNote;
- (void) portAH2ControlChanged:(NSNotification*)aNote;
- (void) portADirectionChanged:(NSNotification*)aNote;
- (void) portATransceiverDirChanged:(NSNotification*)aNote;
- (void) portADataChanged:(NSNotification*)aNote;

//Port B
- (void) portBSubModeChanged:(NSNotification*)aNote;
- (void) portBH1ControlChanged:(NSNotification*)aNote;
- (void) portBH2InterruptChanged:(NSNotification*)aNote;
- (void) portBH2ControlChanged:(NSNotification*)aNote;
- (void) portBDirectionChanged:(NSNotification*)aNote;
- (void) portBTransceiverDirChanged:(NSNotification*)aNote;
- (void) portBDataChanged:(NSNotification*)aNote;

//Port C
- (void) portCDirectionChanged:(NSNotification*)aNote;
- (void) portCDataChanged:(NSNotification*)aNote;

//timer
- (void) preloadLowChanged:(NSNotification*)aNote;
- (void) preloadMiddleChanged:(NSNotification*)aNote;
- (void) preloadHighChanged:(NSNotification*)aNote;
- (void) timerControlChanged:(NSNotification*)aNote;
- (void) periodChanged:(NSNotification*)aNote;


#pragma mark •••Actions
//Gen Reg
- (IBAction) modePUAction:(id)sender;
- (IBAction) H1SensePUAction:(id)sender;
- (IBAction) H2SensePUAction:(id)sender;
- (IBAction) H3SensePUAction:(id)sender;
- (IBAction) H4SensePUAction:(id)sender;
- (IBAction) H12EnablePUAction:(id)sender;
- (IBAction) H34EnablePUAction:(id)sender;

//Port A
- (IBAction) portASubModePUAction:(id)sender;
- (IBAction) portAH1ControlPUAction:(id)sender;
- (IBAction) portAH2InterruptPUAction:(id)sender;
- (IBAction) portAH2ControlPUAction:(id)sender;
- (IBAction) portATransceiverDirPUAction:(id)sender;
- (IBAction) portADirectionMatrixAction:(id)sender;
- (IBAction) portADataAction:(id)sender;
- (IBAction) emitModeAction:(id)sender;

//Port B
- (IBAction) portBSubModePUAction:(id)sender;
- (IBAction) portBH1ControlPUAction:(id)sender;
- (IBAction) portBH2InterruptPUAction:(id)sender;
- (IBAction) portBH2ControlPUAction:(id)sender;
- (IBAction) portBDataAction:(id)sender;
- (IBAction) portBTransceiverDirPUAction:(id)sender;
- (IBAction) portBDirectionMatrixAction:(id)sender;

//Port C
- (IBAction) portCDirectionMatrixAction:(id)sender;
- (IBAction) portCDataAction:(id)sender;

//Timer
- (IBAction) preloadLowAction:(id)sender;
- (IBAction) preloadMiddleAction:(id)sender;
- (IBAction) preloadHighAction:(id)sender;
- (IBAction) timerControlAction:(id)sender;
- (IBAction) periodAction:(id)sender;
- (IBAction) easyTimerStartAction:(id)sender;


@end

