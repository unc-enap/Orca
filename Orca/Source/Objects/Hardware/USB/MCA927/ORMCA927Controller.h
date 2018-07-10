//
//  ORHPMCA927Controller.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 26 2007.
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


#import "ORHPPulserController.h"

@class ORUSB;
@class ORCompositePlotView;

@interface ORMCA927Controller : OrcaObjectController 
{
	IBOutlet ORTimedTextField* noDataWarningField;
	IBOutlet   NSTextField* commentField;
	IBOutlet ORTimedTextField* checkFPGAField;
	IBOutlet NSPopUpButton* serialNumberPopup;
	IBOutlet NSMatrix*		runOptionsMatrix;
	IBOutlet NSMatrix*		selectedChannelMatrix;
	IBOutlet NSTabView*		tabView;
	IBOutlet ORCompositePlotView*    plotter;
	IBOutlet NSTextField*	liveTimeField;
	IBOutlet NSMatrix*		controlRegMatrix;
	IBOutlet NSMatrix*		presetCtrlRegMatrix;
	IBOutlet NSTextField*	ltPresetField;
	IBOutlet NSTextField*	rtPresetField;
	IBOutlet NSTextField*	roiPresetField;
	IBOutlet NSTextField*	roiPeakPresetField;
	IBOutlet NSTextField*	realTimeField;
	IBOutlet NSPopUpButton* convGainPopup;
	IBOutlet NSTextField*	lowerDiscriminatorField;
	IBOutlet NSTextField*	upperDiscriminatorField;
	IBOutlet NSTextField*	lowerDiscriminatorPercentField;
	IBOutlet NSTextField*	upperDiscriminatorPercentField;
	IBOutlet NSButton*		autoClearCB;
	IBOutlet NSPopUpButton* zdtSpeedPU;
	IBOutlet NSMatrix*		zdtModeMatrix;

	IBOutlet NSButton*		useCustomFileCB;
	IBOutlet NSTextField*	fpgaFilePathField;
	IBOutlet NSButton*		selectFileButton;

	IBOutlet NSMatrix*		statusParamsMatrix;

	IBOutlet NSButton*		startChannelButton;
	IBOutlet NSButton*		stopChannelButton;
	IBOutlet NSButton*		startAllButton;
	IBOutlet NSButton*		stopAllButton;
	IBOutlet NSButton*		clearAllButton;
	IBOutlet NSButton*		loadFpgaButton;
    IBOutlet NSButton*		logCB;
    IBOutlet NSButton*		reportButton;
    IBOutlet NSButton*		syncButton;

	IBOutlet NSButton*		lockButton;

}

#pragma mark •••Initialization
- (id) init;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;
- (void) updateChannelParams;

#pragma mark ***Interface Management
- (void) commentChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) autoClearChanged:(NSNotification*)aNote;
- (void) runOptionsChanged:(NSNotification*)aNote;
- (void) statusParamsChanged:(NSNotification*)aNote;
- (void) liveTimeChanged:(NSNotification*)aNote;
- (void) realTimeChanged:(NSNotification*)aNote;
- (void) ltPresetChanged:(NSNotification*)aNote;
- (void) useCustomFileChanged:(NSNotification*)aNote;
- (void) fpgaFilePathChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) controlRegChanged:(NSNotification*)aNote;
- (void) presetCtrlRegChanged:(NSNotification*)aNote;
- (void) rtPresetChanged:(NSNotification*)aNote;
- (void) roiPresetChanged:(NSNotification*)aNote;
- (void) roiPeakPresetChanged:(NSNotification*)aNote;
- (void) convGainChanged:(NSNotification*)aNote;
- (void) lowerDiscriminatorChanged:(NSNotification*)aNote;
- (void) upperDiscriminatorChanged:(NSNotification*)aNote;
- (void) selectedChannelChanged:(NSNotification*)aNote;
- (void) runningStatusChanged:(NSNotification*)aNote;
- (void) displayFPGAError;
- (void) zdtModeChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) commentAction:(id)sender;
- (IBAction) viewSpectrum0Action:(id)sender;
- (IBAction) viewSpectrum1Action:(id)sender;
- (IBAction) viewZDT0Action:(id)sender;
- (IBAction) viewZDT1Action:(id)sender;
- (IBAction) autoClearAction:(id)sender;
- (IBAction) runOptionsAction:(id)sender;
- (IBAction) selectedChannelAction:(id)sender;
- (IBAction) clearSpectrumAction:(id)sender;
- (IBAction) readSpectrumAction:(id)sender;
- (IBAction) controlRegAction:(id)sender;
- (IBAction) presetCtrlRegAction:(id)sender;
- (IBAction) realTimeAction:(id)sender;
- (IBAction) liveTimeAction:(id)sender;
- (IBAction) rtPresetAction:(id)sender;
- (IBAction) roiPresetAction:(id)sender;
- (IBAction) roiPeakPresetAction:(id)sender;
- (IBAction) convGainAction:(id)sender;
- (IBAction) ltPresetAction:(id)sender;
- (IBAction) useCustomFileAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) selectFPGAFileAction:(id)sender;
- (IBAction) sartFPGAAction:(id)sender;
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) lowerDiscriminatorAction:(id)sender;
- (IBAction) upperDiscriminatorAction:(id)sender;
- (IBAction) zdtModeAction:(id)sender;
- (IBAction) zdtSpeedAction:(id)sender;
- (IBAction) writeSpectrumAction:(id)sender;

- (IBAction) syncAction:(id)sender;
- (IBAction) reportAction:(id)sender;

- (IBAction) startAllAcquistionAction:(id)sender;
- (IBAction) stopAllAcquistionAction:(id)sender;
- (IBAction) startAcquistionAction:(id)sender;
- (IBAction) stopAcquistionAction:(id)sender;

- (void) validateInterfacePopup;

- (NSColor*) colorForDataSet:(int)set;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end


