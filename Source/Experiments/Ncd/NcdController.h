//
//  NcdController.h
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
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


@class NcdDetector;
@class ORColorScale;
@class BiStateView;
@class ORPlotView;

@interface NcdController : OrcaObjectController {
    IBOutlet NSView* 	  detectorView;
    IBOutlet NSTextView*  tubeInfoView;
    IBOutlet ORColorScale*  detectorColorBar;
    IBOutlet NSButton*	  colorBarLogCB;
    IBOutlet ORPlotView*  ratePlot;
    IBOutlet NSButton*	  rateLogCB;
    IBOutlet NSMatrix*	  displayOptionMatrix;
    IBOutlet NSTableView* hwTableView;
    
    IBOutlet NSButton*	  readMapFileButton;
    IBOutlet NSButton*	  saveMapFileButton;
    IBOutlet NSTextField* mapFileField;
    IBOutlet NSButton*	  deleteTubeButton;
    IBOutlet NSButton*	  addTubeButton;
    IBOutlet NSTabView*   tabView;

    IBOutlet NSButton*    specialLockButton;
    IBOutlet NSButton*    tubeMapLockButton;
    IBOutlet NSButton*    detectorLockButton;
    IBOutlet NSButton*    nominalSettingsLockButton;
    IBOutlet NSButton*    standAloneButton;
    
    IBOutlet BiStateView* hardwareCheckView;
    IBOutlet BiStateView* triggerCheckView;
    IBOutlet BiStateView* muxCheckView;
    IBOutlet BiStateView* shaperCheckView;
    IBOutlet NSButton*    captureStateButton;
    IBOutlet NSButton*    reportStateButton;
    IBOutlet NSTextField* captureDateField;
    IBOutlet NSButton*    allDisabledButton;
    IBOutlet NSArrayController *altMuxThresholdsController;
    IBOutlet NSTableView* muxThresholdView;
    IBOutlet NSPopUpButton* muxThresholdPopup;
    IBOutlet NSButton*     muxEnableButton;
    IBOutlet NSButton*     muxSelectButton;
    IBOutlet NSButton*     muxAddButton;
    
	IBOutlet NSButton*     allToNominalButton;
	IBOutlet NSButton*     muxToNominalButton;
	IBOutlet NSButton*     shaperAllToNominalButton;
	IBOutlet NSButton*     shaperGainsToNominalButton;
	IBOutlet NSButton*     shaperThresholdsToNominalButton;
	IBOutlet NSButton*     captureNominalFileButton;
	IBOutlet NSButton*     selectNominalFileButton;
	IBOutlet NSButton*     setMuxEfficiencyButton;
	IBOutlet NSPopUpButton* muxEfficiencyPopup;
    IBOutlet NSTextField*  muxEfficiencyField;
	IBOutlet NSButton*     restoreEfficiencyButton;
    IBOutlet NSTextField*  nominalFileField;
    IBOutlet NSTextField*  reducedEfficiencyDateField;

	
    NSImage* descendingSortingImage;
    NSImage* ascendingSortingImage;

}

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Accessors
- (NSArray *)sourceMasks;
- (NSView*) detectorView;
- (ORPlotView*) ratePlot;

- (NSMutableArray *)altMuxThresholds;
- (void)setAltMuxThresholds:(NSMutableArray *)anArray;
- (unsigned int)countOfAltMuxThresholds;
- (void) replaceObjectInAltMuxThresholdsAtIndex:(unsigned int)index withObject:(id)anObject;
- (id) objectInAltMuxThresholdsAtIndex:(unsigned int)index;
- (void)insertObject:(id)anObject inAltMuxThresholdsAtIndex:(unsigned int)index; 
- (void)removeObjectFromAltMuxThresholdsAtIndex:(unsigned int)index;

#pragma mark ¥¥¥Actions
- (IBAction) allDisabledAction:(id)sender;
- (IBAction) showCrate:(id)sender;
- (IBAction) showMac:(id)sender;
- (IBAction) showPulser:(id)sender;
- (IBAction) showEnetGpib:(id)sender;
- (IBAction) showHVMaster:(id)sender;
- (IBAction) showScopeA:(id)sender;
- (IBAction) showScopeB:(id)sender;
- (IBAction) showMux:(id)sender;
- (IBAction) colorBarUsesLogAction:(id)sender;
- (IBAction) setDisplayOptionAction:(id)sender;
- (IBAction) saveMapFileAction:(id)sender;
- (IBAction) readMapFileAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) addTubeAction:(id)sender;
- (IBAction) specialLockAction:(id)sender;
- (IBAction) tubeMapLockAction:(id)sender;
- (IBAction) detectorLockAction:(id)sender;
- (IBAction) nominalSettingsLockAction:(id)sender;
- (IBAction) standAloneAction:(id)sender;
- (IBAction) captureStateAction:(id)sender;
- (IBAction) reportConfigAction:(id)sender;
- (IBAction) selectFile:(id)sender;
- (IBAction) muxEfficiencyAction:(id)sender;
- (IBAction) setMuxEfficiencyAction:(id)sender;
- (IBAction) restoreEfficiencyAction:(id)sender;
- (IBAction) captureNominalSettingsAction:(id)sender;
- (IBAction) selectDifferentNominalSettingsFileAction:(id)sender;
- (IBAction) restoreAllToNominal:(id)sender;
- (IBAction) restoreMuxesToNominal:(id)sender;
- (IBAction) restoreShapersToNominal:(id)sender;
- (IBAction) restoreShaperGainsToNominal:(id)sender;
- (IBAction) restoreShaperThresoldsToNominal:(id)sender;


#pragma mark ¥¥¥Interface Management
- (void) tubeSelectionChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNotification;
- (void) objectsChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) colorAttributesChanged:(NSNotification*)aNote;
- (void) tubeRateChanged:(NSNotification*)aNote;
- (void) displayOptionsChanged:(NSNotification*)aNote;
- (void) mapFileNameChanged:(NSNotification*)aNote;
- (void) mapFileRead:(NSNotification*)aNote;
- (void) tubeParamChanged:(NSNotification*)aNote;
- (void) selectionChanged:(NSNotification*)aNote;
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem;
- (void) tubeMapLockChanged:(NSNotification*)aNotification;
- (void) detectorLockChanged:(NSNotification*)aNotification;
- (void) nominalSettingsLockChanged:(NSNotification*)aNotification;
- (void) specialLockChanged:(NSNotification*)aNotification;
- (void) checkGlobalSecurity;
- (void) hardwareCheckChanged:(NSNotification*)aNotification;
- (void) shaperCheckChanged:(NSNotification*)aNotification;
- (void) muxCheckChanged:(NSNotification*)aNotification;
- (void) triggerCheckChanged:(NSNotification*)aNotification;
- (void) captureDateChanged:(NSNotification*)aNotification;
- (void) allDisabledChanged:(NSNotification*)aNotification;
- (void) muxEfficiencyChanged:(NSNotification*)aNotification;
- (void) runningAtReducedMuxEfficiencyChanged:(NSNotification*)aNotification;
- (void) nominalSettingsFileChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Data Source

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn 
                                row:(NSInteger) rowIndex;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject 
            forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
- (void) tableView:(NSTableView*)tv didClickTableColumn:(NSTableColumn *)tableColumn;
- (void) updateTableHeaderToMatchCurrentSort;
 

@end
