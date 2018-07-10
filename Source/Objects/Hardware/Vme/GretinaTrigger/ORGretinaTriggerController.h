//-------------------------------------------------------------------------
//  ORGretinaTriggerController.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORGretinaTriggerModel.h"

@interface ORGretinaTriggerController : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
	IBOutlet NSTextField*   numTimesToRetryField;
	IBOutlet NSButton*      doNotLockCB;
	IBOutlet NSButton*      verboseCB;
	IBOutlet NSMatrix*      inputLinkMaskMatrix;
	IBOutlet NSMatrix*      serDesTPowerMasMatrix;
	IBOutlet NSMatrix*      serDesRPowerMasMatrix;
	IBOutlet NSMatrix*      lvdsPreemphasisCtlMatrix;
	IBOutlet NSMatrix*      miscCtl1Matrix;
	IBOutlet NSMatrix*      linkLruCrlMatrix;
	IBOutlet NSMatrix*      linkLockedMatrix;
	IBOutlet NSTableView*   miscStatTable;
    IBOutlet NSTextField*   clockUsingLLinkField;
    IBOutlet NSTextField*   initStateField;
    IBOutlet NSTextField*   lockedField;
    IBOutlet NSTextField*   digitizersLockedField;
    IBOutlet NSButton*      shipRecordButton;
    IBOutlet NSBox*         optionsBox;
    IBOutlet NSTextField*   timeStampField;
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;

    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      registerLockButton;
    IBOutlet NSButton*      probeButton;
    IBOutlet NSButton*      dumpFPGARegsButton;
    IBOutlet NSButton*      dumpRegsButton;
    IBOutlet NSButton*      testSandBoxButton;
    IBOutlet NSPopUpButton* masterRouterPU;

	
    //register page
	IBOutlet NSPopUpButton*	registerIndexPU;
	IBOutlet NSTextField*	registerWriteValueField;
	IBOutlet NSButton*		writeRegisterButton;
	IBOutlet NSButton*		readRegisterButton;
	IBOutlet NSTextField*	registerStatusField;

    //state view page
    IBOutlet NSTableView*   stateStatusTable;

    //FPGA download
	IBOutlet NSTextField*			fpgaFilePathField;
	IBOutlet NSButton*				loadMainFPGAButton;
	IBOutlet NSButton*				stopFPGALoadButton;
    IBOutlet NSProgressIndicator*	loadFPGAProgress;
	IBOutlet NSTextField*			mainFPGADownLoadStateField;
	IBOutlet NSTextField*           firmwareStatusStringField;

    NSView *blankView;
    NSSize settingTabSize;
    NSSize stateTabSize;
    NSSize registerTabSize;
    NSSize firmwareTabSize;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) numTimesToRetryChanged:(NSNotification*)aNote;
- (void) doNotLockChanged:(NSNotification*)aNote;
- (void) verboseChanged:(NSNotification*)aNote;
- (void) registerIndexChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) setRegisterDisplay:(unsigned int)index;
- (void) isMasterChanged:(NSNotification*)aNote;
- (void) registerLockChanged:(NSNotification*)aNote;
- (void) registerWriteValueChanged:(NSNotification*)aNote;
- (void) fpgaDownInProgressChanged:(NSNotification*)aNote;
- (void) fpgaDownProgressChanged:(NSNotification*)aNote;
- (void) mainFPGADownLoadStateChanged:(NSNotification*)aNote;
- (void) fpgaFilePathChanged:(NSNotification*)aNote;
- (void) firmwareStatusStringChanged:(NSNotification*)aNote;
- (void) inputLinkMaskChanged:(NSNotification*)aNote;
- (void) serDesTPowerMaskChanged:(NSNotification*)aNote;
- (void) serDesRPowerMaskChanged:(NSNotification*)aNote;
- (void) lvdsPreemphasisCtlChanged:(NSNotification*)aNote;
- (void) miscCtl1RegChanged:(NSNotification*)aNote;
- (void) miscStatRegChanged:(NSNotification*)aNote;
- (void) clockUsingLLinkChanged:(NSNotification*)aNote;
- (void) initStateChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) timeStampChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) numTimesToRetryAction:(id)sender;
- (IBAction) doNotLockAction:(id)sender;
- (IBAction) verboseAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) probeBoard:(id)sender;
- (IBAction) shipRecordAction:(id)sender;

- (IBAction) isMasterAction:(id)sender;
- (IBAction) registerIndexPUAction:(id)sender;
- (IBAction) readRegisterAction:(id)sender;
- (IBAction) writeRegisterAction:(id)sender;
- (IBAction) registerLockAction:(id) sender;
- (IBAction) registerWriteValueAction:(id)sender;
- (IBAction) dumpFPGARegsAction:(id)sender;
- (IBAction) dumpRegsAction:(id)sender;
- (IBAction) testSandBoxAction:(id)sender;
- (IBAction) downloadMainFPGAAction:(id)sender;
- (IBAction) stopLoadingMainFPGAAction:(id)sender;

#pragma mark •••Data Source
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

@end
