//
//  ORExperimentController.h
//  Orca
//
//  Created by Mark Howe on 12/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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

@class ORDetectorView;
@class ORCompositeTimeLineView;
@class ORCompositePlotView;
@class ORColorScale;
@class BiStateView;
@class ORRunModel;

@interface ORExperimentController : OrcaObjectController {
    IBOutlet NSTabView*		tabView;
	IBOutlet NSButton*		ignoreHWChecksCB;
	IBOutlet NSButton*		showNamesCB;

	//detector View tab view
	IBOutlet NSPopUpButton*	displayTypePU;
	IBOutlet NSTextView*	selectionStringTextView;
    IBOutlet ORDetectorView* detectorView;
    IBOutlet ORColorScale*	primaryColorScale;
    IBOutlet NSButton*		primaryColorAxisLogCB;
    IBOutlet ORCompositeTimeLineView*	ratePlot;
    IBOutlet NSButton*		rateLogCB;
    IBOutlet NSButton*		detectorLockButton;
    IBOutlet BiStateView*	hardwareCheckView;
    IBOutlet BiStateView*	cardCheckView;
    IBOutlet NSButton*		captureStateButton;
    IBOutlet NSButton*		reportStateButton;
    IBOutlet NSTextField*	captureDateField;
    IBOutlet NSTextField*	primaryRateField;
	IBOutlet NSPopUpButton* runTypeScriptPU;
    IBOutlet NSButton*		startRunButton;
    IBOutlet NSButton*		stopRunButton;
    IBOutlet NSTextField*	runNumberField;
    IBOutlet NSTextField*	runStatusField;
    IBOutlet NSTextField*   timeStartedField;
    IBOutlet NSTextField*	elapsedTimeField;
    IBOutlet NSButton*      timedRunCB;
    IBOutlet NSButton*      repeatRunCB;
    IBOutlet NSTextField*   timeLimitField;
    IBOutlet NSMatrix*      runModeMatrix;
    IBOutlet NSProgressIndicator* 	runBar;
	IBOutlet NSButton*		clearButton;
    IBOutlet NSMatrix*      colorScaleMatrix;
    IBOutlet NSColorWell*   custumColorWell1;
    IBOutlet NSColorWell*   custumColorWell2;

	//items in the  details tab view
	IBOutlet NSPopUpButton*	displayTypePU1;
    IBOutlet ORCompositePlotView*	valueHistogramsPlot;
	IBOutlet NSTextField*	histogramTitle;
    IBOutlet NSTableView*	primaryValuesView;
    IBOutlet NSButton*		initButton;
    IBOutlet NSButton*		detailsLockButton;

	//items in the  Map tab view
    IBOutlet NSTableView*	primaryTableView;
	IBOutlet NSTextField*	primaryMapFileTextField;
    IBOutlet NSButton*		readPrimaryMapFileButton;
    IBOutlet NSButton*		savePrimaryMapFileButton;
    IBOutlet NSButton*		mapLockButton;
	IBOutlet NSPopUpButton* primaryAdcClassNamePopup;
   
	ORRunModel*     runControl;
}

#pragma mark •••Initialization
- (void) registerNotificationObservers;

#pragma mark •••Subclass responsibility
- (NSString*) defaultPrimaryMapFilePath;
- (void) setDetectorTitle;
- (NSView*) viewToDisplay;

#pragma mark •••Actions
- (IBAction) ignoreHWChecksAction:(id)sender;
- (IBAction) showNamesAction:(id)sender;
- (IBAction) displayTypeAction:(id)sender;
- (IBAction) primaryAdcClassNameAction:(id)sender;
- (IBAction) mapLockAction:(id)sender;
- (IBAction) detectorLockAction:(id)sender;
- (IBAction) captureStateAction:(id)sender;
- (IBAction) reportConfigAction:(id)sender;
- (IBAction) readPrimaryMapFileAction:(id)sender;
- (IBAction) savePrimaryMapFileAction:(id)sender;
- (IBAction) startRunAction:(id)sender;
- (IBAction) stopRunAction:(id)sender;
- (IBAction) timeLimitTextAction:(id)sender;
- (IBAction) timedRunCBAction:(id)sender;
- (IBAction) repeatRunCBAction:(id)sender;
- (IBAction) runModeAction:(id)sender;
- (IBAction) autoscaleMainColorScale:(id)sender;
- (IBAction) selectedRunTypeScriptPUAction:(id)sender;
- (IBAction) colorScaleTypeAction:(id)sender;
- (IBAction) customColor1Action:(id)sender;
- (IBAction) customColor2Action:(id)sender;


#pragma mark •••Toolbar
- (IBAction) openHelp:(NSToolbarItem*)item;
- (IBAction) statusLog:(NSToolbarItem*)item; 
- (IBAction) alarmMaster:(NSToolbarItem*)item; 
- (IBAction) openPreferences:(NSToolbarItem*)item; 
- (IBAction) openHWWizard:(NSToolbarItem*)item; 
- (IBAction) openCommandCenter:(NSToolbarItem*)item; 
- (IBAction) openTaskMaster:(NSToolbarItem*)item; 

#pragma mark •••Details Actions
- (IBAction) detailsLockAction:(id)sender;
- (IBAction) initAction:(id)sender;
- (IBAction) clearAction:(id)sender;

#pragma mark •••Interface Management
- (void) segmentGroupChanged:(NSNotification*)aNote;
- (void) customColor1Changed:(NSNotification*)aNote;
- (void) customColor2Changed:(NSNotification*)aNote;
- (void) refreshSegmentTables:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) ignoreHWChecksChanged:(NSNotification*)aNote;
- (void) showNamesChanged:(NSNotification*)aNote;
- (void) updateRunInfo:(NSNotification*)aNote;
- (void) findRunControl:(NSNotification*)aNote;
- (void) selectionChanged:(NSNotification*)aNote;
- (void) populateClassNamePopup:(NSPopUpButton*)aPopup;
- (void) specialUpdate:(NSNotification*)aNote;
- (void) displayTypeChanged:(NSNotification*)aNote;
- (void) primaryMapFileChanged:(NSNotification*)aNote;
- (void) selectionStringChanged:(NSNotification*)aNote;
- (void) primaryAdcClassNameChanged:(NSNotification*)aNote;
- (void) replayStarted:(NSNotification*)aNotification;
- (void) replayStopped:(NSNotification*)aNotification;
- (void) objectsChanged:(NSNotification*)aNote;
- (void) mapFileRead:(NSNotification*)aNote;
- (void) mapLockChanged:(NSNotification*)aNotification;
- (void) detectorLockChanged:(NSNotification*)aNotification;
- (void) checkGlobalSecurity;
- (void) hardwareCheckChanged:(NSNotification*)aNotification;
- (void) cardCheckChanged:(NSNotification*)aNotification;
- (void) captureDateChanged:(NSNotification*)aNotification;
- (void) updateForReplayMode;
- (void) newTotalRateAvailable:(NSNotification*)aNotification;
- (void) miscAttributesChanged:(NSNotification*)aNotification;
- (void) timedRunChanged:(NSNotification*)aNote;
- (void) runModeChanged:(NSNotification*)aNote;
- (void) runTimeLimitChanged:(NSNotification*)aNote;
- (void) repeatRunChanged:(NSNotification*)aNote;
- (void) elapsedTimeChanged:(NSNotification*)aNote;
- (void) selectedRunTypeScriptChanged:(NSNotification*)aNote;
- (void) colorScaleTypeChanged:(NSNotification*)aNote;

#pragma mark •••Details Interface Management
- (void) histogramsUpdated:(NSNotification*)aNote;
- (void) setValueHistogramTitle;
- (void) detailsLockChanged:(NSNotification*)aNotification;

#pragma mark •••Data Source For Plots
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

#pragma mark •••Data Source For Tables
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn 
                                row:(NSInteger) rowIndex;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject 
            forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
 
@end
