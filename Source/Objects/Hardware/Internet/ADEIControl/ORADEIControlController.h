//--------------------------------------------------------
// ORADEIControlController
// Created by A. Kopmann on Feb 8, 2019
// Copyright (c) 2017, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
@class ORValueBarGroupView;

@class StopLightView;

@interface ORADEIControlController : OrcaObjectController
{
    IBOutlet NSTextField*   groupNumTextField;
    IBOutlet NSTextField*   sensorGroupNameField;

	IBOutlet NSTextField*	ipConnectedTextField;
	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSButton*		ipConnectButton;

	IBOutlet NSTextField*   setPointFileField;
    IBOutlet NSTextField*   deviceConfigFileField;
	IBOutlet NSTextField*	cmdQueCountField;
    IBOutlet NSButton*      lockButton;

    IBOutlet NSButton*      writeAllSetPointsButton;
		
	IBOutlet NSButton*		readSetPointFileButton;
	IBOutlet NSButton*		writeSetPointFileButton;
    IBOutlet NSButton*      readDeviceConfigFileButton;
    IBOutlet NSButton*      readPostRegulationButton;

	IBOutlet NSTableView*	setPointTableView;
    IBOutlet NSTableColumn* readBackColumn;
    IBOutlet NSTableView*   measuredValueTableView;
    IBOutlet NSTableView*   postRegulationTableView;
    IBOutlet NSButton*      addPostRegulationPointButton;
    IBOutlet NSButton*      removePostRegulationPointButton;
    IBOutlet NSTextField*   postRegulationFileField;
    
    IBOutlet StopLightView* lightBoardView;
    IBOutlet NSTextField* expertPCControlOnlyField;
    IBOutlet NSTextField* zeusHasControlField;
    IBOutlet NSTextField* orcaHasControlField;
    IBOutlet NSTextField* setPointNoteField;
    IBOutlet NSPopUpButton* pollTimePU;
    IBOutlet NSProgressIndicator* progressWheel;

    IBOutlet ORValueBarGroupView*  queueValueBar;
    IBOutlet NSButton*    verboseCB;
    IBOutlet NSButton*    warningsCB;
    IBOutlet NSButton*    showFormattedDatesCB;
    
    //Drawers
    IBOutlet NSDrawer*    scriptParameterDrawer;
    IBOutlet NSButton*    parameterViewButton;

}

#pragma mark ***Initialization
- (id) init;
- (void) awakeFromNib;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) sensorGroupChanged:(NSNotification*)aNote;
- (void) setPointChanged:(NSNotification*)aNote;
- (void) setPointsReadBackChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) queCountChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) isConnectedChanged:(NSNotification*)aNote;
- (void) measuredValuesChanged:(NSNotification*)aNote;
- (void) verboseChanged:(NSNotification*)aNote;
- (void) warningsChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) setButtonStates;
- (void) postRegulationPointAdded:(NSNotification*)aNote;
- (void) postRegulationPointRemoved:(NSNotification*)aNote;
- (void) updatePostRegulationTable;
- (void) drawDidOpen:(NSNotification*)aNote;
- (void) drawDidClose:(NSNotification*)aNote;

#pragma mark ***Actions

//ADEIControl#
- (IBAction) writeSetpointsAction:(id)sender;
- (IBAction) readBackSetpointsAction:(id)sender;
- (IBAction) pushReadBacksToSetPointsAction:(id)sender;
- (IBAction) readMeasuredValuesAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) readSetPointFile:(id)sender;
- (IBAction) saveSetPointFile:(id)sender;
- (IBAction) readDeviceConfigFile:(id)sender;
- (IBAction) ipAddressFieldAction:(id)sender;
- (IBAction) connectAction: (id) aSender;
- (IBAction) flushQueueAction: (id) aSender;
- (IBAction) verboseAction: (id) aSender;
- (IBAction) warningsAction: (id) aSender;
- (IBAction) addPostRegulationPoint: (id) aSender;
- (IBAction) removePostRegulationPoint: (id) aSender;
- (IBAction) readPostRegulationScaleFactors: (id) aSender;
- (IBAction) savePostRegulationScaleFactors: (id) aSender;
- (IBAction) pollTimeAction: (id) aSender;
- (IBAction) toggleScriptParameterDrawer:(id)sender;
- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
@end


