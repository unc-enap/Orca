//  Orca
//  ORFlashCamReadoutController.h
//
//  Created by Tom Caldwell on Monday Dec 26,2019
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORCardContainerView.h"

@class ORCompositeTimeLineView;

@interface ORFlashCamReadoutController : OrcaObjectController
{
    IBOutlet NSTextField* ipAddressTextField;
    IBOutlet NSTextField* usernameTextField;
    IBOutlet NSTableView* ethInterfaceView;
    IBOutlet NSButton* addEthInterfaceButton;
    IBOutlet NSButton* removeEthInterfaeButton;
    IBOutlet NSButton* sendPingButton;
    IBOutlet NSTableView* listenerView;    
    IBOutlet NSTableView* listenerGPSView;
    IBOutlet NSTableView* listenerDAQView;
    IBOutlet NSTableView* listenerWFView;
    IBOutlet NSTableView* listenerTrigView;
    IBOutlet NSTableView* listenerBaseView;
    IBOutlet NSTableView* listenerReadoutView;
    IBOutlet NSTableView* listenerExtraFlagsView;
    IBOutlet NSTableView* listenerExtraFilesView;
    IBOutlet NSButton* updateIPButton;
    IBOutlet NSButton* listInterfaceButton;
    IBOutlet NSTableView* monitorView;
    IBOutlet ORCardContainerView* listenerContainer;
    IBOutlet NSButton* addIfaceToListenerButton;
    IBOutlet NSPanel* addIfaceToListenerPanel;
    IBOutlet NSPopUpButton* addIfaceToListenerIfacePUButton;
    IBOutlet NSPopUpButton* addIfaceToListenerListenerPUButton;
    IBOutlet NSButton* addIfaceToListenerAddButton;
    IBOutlet NSButton* addIfaceToListenerCloseButton;
    IBOutlet NSButton* rmIfaceFromListenerButton;
    IBOutlet NSPanel* rmIfaceFromListenerPanel;
    IBOutlet NSPopUpButton* rmIfaceFromListenerIfacePUButton;
    IBOutlet NSPopUpButton* rmIfaceFromListenerListenerPUButton;
    IBOutlet NSButton* rmIfaceFromListenerRmButton;
    IBOutlet NSButton* rmIfaceFromListenerCloseButton;
    IBOutlet NSButton* fcSourcePathButton;
    IBOutlet NSTextField* fcSourcePathTextField;
    IBOutlet NSButton* printListenerFlagsButton;
    IBOutlet NSPopUpButton* printListenerFlagsPUButton;
    IBOutlet ORCompositeTimeLineView* dataRateView;
    IBOutlet ORCompositeTimeLineView* eventRateView;
    IBOutlet ORCompositeTimeLineView* deadTimeView;
    IBOutlet NSButton* settingsLockButton;
    BOOL     scheduledToUpdatePlot;
    BOOL     isLocked;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) ipAddressChanged:(NSNotification*)note;
- (void) usernameChanged:(NSNotification*)note;
- (void) ethInterfaceChanged:(NSNotification*)note;
- (void) ethInterfaceAdded:(NSNotification*)note;
- (void) ethInterfaceRemoved:(NSNotification*)note;
- (void) ethTypeChanged:(NSNotification*)note;
- (void) configParamChanged:(NSNotification*)note;
- (void) reloadListenerData;
- (void) pingStart:(NSNotification*)note;
- (void) pingEnd:(NSNotification*)note;
- (void) remotePathStart:(NSNotification*)note;
- (void) remotePathEnd:(NSNotification*)note;
- (void) runInProgress:(NSNotification*)note;
- (void) runEnded:(NSNotification*)note;
- (void) listenerChanged:(NSNotification*)note;
- (void) listenerAdded:(NSNotification*)note;
- (void) listenerRemoved:(NSNotification*)note;
- (void) monitoringUpdated:(NSNotification*)note;
- (void) groupObjectAdded:(NSNotification*)note;
- (void) groupObjectRemoved:(NSNotification*)note;
- (void) groupObjectMoved:(NSNotification*)note;
- (void) groupChanged:(NSNotification*)note;
- (void) scaleAction:(NSNotification*)note;
- (void) miscAttributesChanged:(NSNotification*)note;
- (void) setPlot:(id)aPlotter xAttributes:(id)attrib;
- (void) setPlot:(id)aPlotter yAttributes:(id)attrib;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) deferredPlotUpdate;
- (void) updateAddIfaceToListenerIfacePUButton;
- (void) updateAddIfaceToListenerListenerPUButton;
- (void) updateRmIfaceFromListenerIfacePUButton;
- (void) updateRmIfaceFromListenerListenerPUButton;
- (void) fcSourcePathChanged:(NSNotification*)note;
- (void) checkGlobalSecurity;
- (void) settingsLock:(bool)lock;

#pragma mark •••Actions
- (IBAction) ipAddressAction:(id)sender;
- (IBAction) usernameAction:(id)sender;
- (IBAction) addEthInterfaceAction:(id)sender;
- (IBAction) removeEthInterfaceAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) sendPingAction:(id)sender;
- (IBAction) updateIPAction:(id)sender;
- (IBAction) listInterfaceAction:(id)sender;
- (IBAction) addIfaceToListenerAction:(id)sender;
- (IBAction) addIfaceToListenerIfaceAction:(id)sender;
- (IBAction) addIfaceToListenerListenerAction:(id)sender;
- (IBAction) addIfaceToListenerAddAction:(id)sender;
- (IBAction) addIfaceToListenerCloseAction:(id)sender;
- (IBAction) rmIfaceFromListenerAction:(id)sender;
- (IBAction) rmIfaceFromListenerIfaceAction:(id)sender;
- (IBAction) rmIfaceFromListenerListenerAction:(id)sender;
- (IBAction) rmIfaceFromListenerRmAction:(id)sender;
- (IBAction) rmIfaceFromListenerCloseAction:(id)sender;
- (IBAction) fcSourcePathAction:(id)sender;
- (IBAction) printListenerFlagsAction:(id)sender;
- (IBAction) settingsLockAction:(id)sender;

#pragma mark •••Delegate Methods
- (void) tableViewSelectionDidChange:(NSNotification*)note;

#pragma mark •••Data Source
- (id) tableView:(NSTableView*)view objectValueForTableColumn:(NSTableColumn*)column row:(NSInteger)row;
- (void) tableView:(NSTableView*)view setObjectValue:(id)object forTableColumn:(NSTableColumn*)column row:(NSInteger)row;
- (NSInteger) numberOfRowsInTableView:(NSTableView*)view;

- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
