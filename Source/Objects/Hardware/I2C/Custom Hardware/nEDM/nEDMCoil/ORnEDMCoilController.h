//
//  ORnEDMCoilController.h
//  Orca
//
//  Created by Michael Marino 15 Mar 2012 
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

#pragma mark •••Imported Files

#import "OrcaObjectController.h"

//modified so this will compile under 10.5 09/06/12 MAH
@interface ORnEDMCoilController : OrcaObjectController <NSTableViewDataSource>
{
    IBOutlet NSTabView* 	tabView;
    IBOutlet ORGroupView*   groupView;
    IBOutlet NSTextField*   lockDocField;
    IBOutlet NSButton*      startStopButton;
    IBOutlet NSTextField*   runRateField;
    IBOutlet NSTextField*   proportionalTermField;
    IBOutlet NSTextField*   integralTermField;
    IBOutlet NSTextField*   feedbackThresholdField;
    IBOutlet NSTextField*   regularizationParameterField;
    IBOutlet NSTextField*   runCommentField;
    IBOutlet NSPopUpButton* listOfAdcs;
    IBOutlet NSProgressIndicator* processIndicate;
    IBOutlet NSTextField*   realProcessFrequencyField;
    
    IBOutlet NSPopUpButton* commandPopUp;
    IBOutlet NSPopUpButton* outputNumberPopUp;    
    IBOutlet NSTextField*   inputValueText;
    IBOutlet NSButton*      debugModeButton;
    IBOutlet NSButton*      dynamicModeButton;
    
    IBOutlet NSButton*      saveFeedBackMapButton;
    IBOutlet NSButton*      orientationMatrixButton;
    IBOutlet NSButton*      magnetometerMapButton;
    IBOutlet NSButton*      sensitivityMapButton;
    IBOutlet NSButton*      activeChannelMapButton;
    IBOutlet NSButton*      buildNewFeedbackMatrixButton;
    IBOutlet NSButton*      loadSensorInformationButton;
    
    IBOutlet NSTextField*   feedBackNotifier;
    IBOutlet NSButton*      deleteADCButton;
    IBOutlet NSButton*      addADCButton;

    IBOutlet NSTableView*   listOfRegisteredADCs;
    IBOutlet NSTableView*   hardwareMap;
    IBOutlet NSTableView*   orientationMatrix;
    IBOutlet NSTableView*   feedbackMatrix;
    IBOutlet NSTableView*   currentValues;
    IBOutlet NSTableView*   fieldValues;
    IBOutlet NSTableView*   targetFieldValues;
    IBOutlet NSTableView*   startCurrentValues;
    IBOutlet NSTableView*   sensitivityMatrix;
    IBOutlet NSTableView*   activeChannelMap;
    IBOutlet NSTableView*   sensorInfo;
    IBOutlet NSTableView*   sensorDirectInfo;
    
    IBOutlet NSTextField*   coilText;
    IBOutlet NSTextField*   postDatabaseNameText;
    IBOutlet NSTextField*   postDatabaseDesignDocText;
    IBOutlet NSTextField*   postDatabaseDesignUpdateText;
    
    IBOutlet NSTextField*   postDatabasePeriodText;
	IBOutlet NSButton*      refreshIPsButton;
    IBOutlet NSProgressIndicator* refreshIPIndicate;
    
    IBOutlet NSButton*      processVerbose;
    IBOutlet NSButton*      postDataToDBButton;
    
    NSView *blankView;    
    NSSize controlSize;
    NSSize powerSupplySize;
    NSSize adcSize;
    NSSize configSize;
    NSString* startingDirectory;
}

- (id) init;
- (void) awakeFromNib;

#pragma mark •••Accessors
- (ORGroupView *)groupView;
- (void) setModel:(id)aModel;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) groupChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (BOOL) validateMenuItem:(NSMenuItem*)aMenuItem;
- (void) documentLockChanged:(NSNotification*)aNote;
- (void) runStatusChanged:(NSNotification*)aNote;
- (void) proportionalTermChanged:(NSNotification*)aNote;
- (void) integralTermChanged:(NSNotification*)aNote;
- (void) feedbackThresholdChanged:(NSNotification*)aNote;
- (void) runCommentChanged:(NSNotification*)aNote;
- (void) runRateChanged:(NSNotification*)aNote;
- (void) modelADCListChanged:(NSNotification*)aNote;
- (void) channelMapChanged:(NSNotification*)aNote;
- (void) sensitivityMapChanged:(NSNotification*)aNote;
- (void) sensorInfoChanged:(NSNotification*)aNote;
- (void) objectsAdded:(NSNotification*)aNote;
- (void) debugRunningChanged:(NSNotification*)aNote;
- (void) dynamicModeChanged:(NSNotification*)aNote;
- (void) refreshIPAddressesDone:(NSNotification*)aNote;
- (void) processVerboseChanged:(NSNotification*)aNote;
- (void) realProcessFrequencyChanged:(NSNotification*)aNote;
- (void) targetFieldChanged:(NSNotification*)aNote;
- (void) startCurrentChanged:(NSNotification*)aNote;
- (void) postDataToDBChanged:(NSNotification*)aNote;
- (void) postToPathChanged:(NSNotification*)aNote;
- (void) postToDBPeriodChanged:(NSNotification*)aNote;

- (void) populateListADCs;

- (IBAction) runRateAction:(id)sender;
- (IBAction) proportionalTermAction:(id)sender;
- (IBAction) integralTermAction:(id)sender;
- (IBAction) feedbackThresholdAction:(id)sender;
- (IBAction) regularizationParameterAction:(id)sender;
- (IBAction) runAction:(id)sender;
- (IBAction) runCommentAction:(id)sender;
- (IBAction) saveFeedbackMatrixAction:(id)sender;
- (IBAction) readPrimaryMagnetometerMapFileAction:(id)sender;
- (IBAction) readPrimaryOrientationMatrixFileAction:(id)sender;
- (IBAction) addADCAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;
- (IBAction) debugCommandAction:(id)sender;
- (IBAction) dynamicModeCommandAction:(id)sender;
- (IBAction) connectAllAction:(id)sender;
- (IBAction) removeSelectedADCs:(id)sender;
- (IBAction) handleToBeAddedADC:(id)sender;
- (IBAction) refreshIPsAction:(id)sender;
- (IBAction) processVerboseAction:(id)sender;
- (IBAction) refreshCurrentAndFieldValuesAction:(id)sender;
- (IBAction) loadTargetFieldValuesAction:(id)sender;
- (IBAction) saveCurrentFieldAsTargetFieldAction:(id)sender;
- (IBAction) setTargetFieldAction:(id)sender;
- (IBAction) setTargetFieldToZeroAction:(id)sender;
- (IBAction) loadStartCurrentValuesAction:(id)sender;
- (IBAction) saveCurrentStartCurrentAsStartCurrentAction:(id)sender;
- (IBAction) setStartCurrentToZeroAction:(id)sender;
- (IBAction) postDataToDBAction:(id)sender;
- (IBAction) postToPathAction:(id)sender;
- (IBAction) postToDBPeriodAction:(id)sender;
- (IBAction) loadSensitivityMatrixAction:(id)sender;
- (IBAction) loadAcitveChannelMapAction:(id)sender;
- (IBAction) buildNewFeedbackMatrixAction:(id)sender;
- (IBAction) loadSensorInformationAction:(id)sender;

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

//- (IBAction) delete:(id)sender; 
//- (IBAction) cut:(id)sender; 
//- (IBAction) paste:(id)sender ;
//- (IBAction) selectAll:(id)sender;
//-----------------------------------------------------------------

@end
