//
//  ORFilterController.h
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

@class ORTimedTextField;
@class ORScriptView;
@class ORCompositePlotView;

@interface ORFilterController : OrcaObjectController {

	IBOutlet ORScriptView*		scriptView;
	IBOutlet NSMatrix*			usePluginMatrix;
	IBOutlet NSTextField*		typeField;
	IBOutlet NSTextField*		pluginValidField;
	IBOutlet NSTextField*		pluginPathField;
	IBOutlet NSTextField*		pluginNameField;
    IBOutlet NSButton*			lockButton;
	IBOutlet NSTextView*		helpView;
	IBOutlet ORTimedTextField*	statusField;
	IBOutlet NSView*			panelView;
	IBOutlet NSTableView*		inputVariablesTableView;
	IBOutlet NSTableView*		outputVariablesTableView;
	IBOutlet id					loadSaveView;
    IBOutlet NSTextField*		lastFileField;
    IBOutlet NSTextField*		classNameField;
	IBOutlet NSTextField*		runStatusField;
	IBOutlet NSButton*			runButton;
	IBOutlet NSButton*			loadSaveButton;
	IBOutlet NSButton*			timerEnabledCB;
	IBOutlet ORCompositePlotView*		timePlot;
	IBOutlet NSButton*			addInputButton;
	IBOutlet NSButton*			removeInputButton;
	IBOutlet NSButton*			parseButton;
	IBOutlet NSPopUpButton*		codeHelperPU;
	IBOutlet NSButton*			insertCodeButton;
}

#pragma mark •••Initialization
- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) setLabelFields;
- (void) usePluginChanged:(NSNotification*)aNote;
- (void) pluginValidChanged:(NSNotification*)aNote;
- (void) pluginPathChanged:(NSNotification*)aNote;
- (void) scriptChanged:(NSNotification*)aNote;
- (void) textDidChange:(NSNotification*)aNote;
- (void) lastFileChanged:(NSNotification*)aNote;
- (void) timerEnabledChanged:(NSNotification*)aNote;
- (void) updateTiming:(NSNotification*)aNote;
- (void) displayValuesChanged:(NSNotification*)aNote;
- (void) inputValuesChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) insertCode:(id) sender;
- (IBAction) listDecoders:(id)sender;
- (IBAction) usePluginAction:(id)sender;
- (IBAction) enableTimer:(id)sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) listMethodsAction:(id) sender;
- (IBAction) cancelLoadSaveAction:(id)sender;
- (IBAction) parseScript:(id) sender;	
- (IBAction) nameAction:(id) sender;
- (IBAction) loadSaveAction:(id)sender;
- (IBAction) loadFileAction:(id) sender;
- (IBAction) saveAsFileAction:(id) sender;
- (IBAction) saveFileAction:(id) sender;
- (IBAction) addInput:(id)sender;
- (IBAction) removeInput:(id)sender;
- (IBAction) selectPluginPath:(id)sender;

#pragma mark •••Interface Management
- (void) lockChanged:(NSNotification*)aNotification;

#pragma mark •••DataSource
- (int)  numberOfRowsInTableView:(NSTableView *)aTable;
- (id) tableView:(NSTableView *)aTable objectValueForTableColumn:(NSTableColumn *)aCol row:(int)aRow;
- (void) tableView:(NSTableView*)aTable setObjectValue:(id)aData forTableColumn:(NSTableColumn*)aCol row:(int)aRow;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
