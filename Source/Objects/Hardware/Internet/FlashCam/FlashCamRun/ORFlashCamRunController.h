//  Orca
//  ORFlashCamRunController.h
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

#import "OrcaObjectController.h"

@interface ORFlashCamRunController : OrcaObjectController
{
    IBOutlet NSTextField* ipAddressTextField;
    IBOutlet NSTextField* usernameTextField;
    IBOutlet NSTableView* ethInterfaceView;
    IBOutlet NSButton* addEthInterfaceButton;
    IBOutlet NSButton* removeEthInterfaeButton;
    IBOutlet NSTextField* ethTypeTextField;
    IBOutlet NSTextField* maxPayloadTextField;
    IBOutlet NSTextField* eventBufferTextField;
    IBOutlet NSTextField* phaseAdjustTextField;
    IBOutlet NSTextField* baselineSlewTextField;
    IBOutlet NSTextField* integratorLenTextField;
    IBOutlet NSTextField* eventSamplesTextField;
    IBOutlet NSPopUpButton* traceTypePUButton;
    IBOutlet NSTextField* pileupRejectionTextField;
    IBOutlet NSTextField* logTimeTextField;
    IBOutlet NSButton* gpsEnabledButton;
    IBOutlet NSButton* includeBaselineButton;
    IBOutlet NSTextField* additionalFlagsTextField;
    IBOutlet NSTextField* overrideCmdTextField;
    IBOutlet NSButton* runOverrideButton;
    IBOutlet NSTextField* remoteDataPathTextField;
    IBOutlet NSTextField* remoteFilenameTextField;
    IBOutlet NSTextField* runNumberTextField;
    IBOutlet NSTextField* runCountTextField;
    IBOutlet NSTextField* runLengthTextField;
    IBOutlet NSButton* runUpdateButton;
    IBOutlet NSButton* sendPingButton;
    IBOutlet NSButton* startRunButton;
    IBOutlet NSButton* killRunButton;
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
- (void) maxPayloadChanged:(NSNotification*)note;
- (void) eventBufferChanged:(NSNotification*)note;
- (void) phaseAdjustChanged:(NSNotification*)note;
- (void) baselineSlewChanged:(NSNotification*)note;
- (void) integratorLenChanged:(NSNotification*)note;
- (void) eventSamplesChanged:(NSNotification*)note;
- (void) traceTypeChanged:(NSNotification*)note;
- (void) pileupRejectionChanged:(NSNotification*)note;
- (void) logTimeChanged:(NSNotification*)note;
- (void) gpsEnabledChanged:(NSNotification*)note;
- (void) includeBaselineChanged:(NSNotification*)note;
- (void) additionalFlagsChanged:(NSNotification*)note;
- (void) overrideCmdChanged:(NSNotification*)note;
- (void) runOverrideChanged:(NSNotification*)note;
- (void) remoteDataPathChanged:(NSNotification*)note;
- (void) remoteFilenameChanged:(NSNotification*)note;
- (void) runNumberChanged:(NSNotification*)note;
- (void) runCountChanged:(NSNotification*)note;
- (void) runLengthChanged:(NSNotification*)note;
- (void) runUpdateChanged:(NSNotification*)note;
- (void) pingStart:(NSNotification*)note;
- (void) pingEnd:(NSNotification*)note;
- (void) runInProgress:(NSNotification*)note;
- (void) runEnded:(NSNotification*)note;
- (void) settingsLock:(bool)lock;

#pragma mark •••Actions
- (IBAction) ipAddressAction:(id)sender;
- (IBAction) usernameAction:(id)sender;
- (IBAction) addEthInterfaceAction:(id)sender;
- (IBAction) removeEthInterfaceAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) ethTypeAction:(id)sender;
- (IBAction) maxPayloadAction:(id)sender;
- (IBAction) eventBufferAction:(id)sender;
- (IBAction) phaseAdjustAction:(id)sender;
- (IBAction) baselineSlewAction:(id)sender;
- (IBAction) integratorLenAction:(id)sender;
- (IBAction) eventSamplesAction:(id)sender;
- (IBAction) traceTypeAction:(id)sender;
- (IBAction) pileupRejectionAction:(id)sender;
- (IBAction) logTimeAction:(id)sender;
- (IBAction) gpsEnabledAction:(id)sender;
- (IBAction) includeBaselineAction:(id)sender;
- (IBAction) additionalFlagsAction:(id)sender;
- (IBAction) overrideCmdAction:(id)sender;
- (IBAction) runOverrideAction:(id)sender;
- (IBAction) remoteDataPathAction:(id)sender;
- (IBAction) remoteFilenameAction:(id)sender;
- (IBAction) runNumberAction:(id)sender;
- (IBAction) runCountAction:(id)sender;
- (IBAction) runLengthAction:(id)sender;
- (IBAction) runUpdateAction:(id)sender;
- (IBAction) sendPingAction:(id)sender;
- (IBAction) startRunAction:(id)sender;
- (IBAction) killRunAction:(id)sender;

#pragma mark •••Delegate Methods
- (void) tableViewSelectionDidChange:(NSNotification*)note;

#pragma mark •••Data Source
- (id) tableView:(NSTableView*)view objectValueForTableColumn:(NSTableColumn*)column row:(NSInteger)row;
- (void) tableView:(NSTableView*)view setObjectValue:(id)object forTableColumn:(NSTableColumn*)column row:(NSInteger)row;
- (NSInteger) numberOfRowsInTableView:(NSTableView*)view;

@end
