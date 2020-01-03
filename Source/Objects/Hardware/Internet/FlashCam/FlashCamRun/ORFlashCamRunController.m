//  Orca
//  ORFlashCamRunController.m
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

#import "ORFlashCamRunController.h"
#import "ORFlashCamRunModel.h"

@implementation ORFlashCamRunController

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamRun"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"FlasCam (%@)", [model ipAddress]]];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORFlashCamRunModelIPAddressChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(usernameChanged:)
                         name : ORFlashCamRunModelUsernameChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(ethInterfaceChanged:)
                         name : ORFlashCamRunModelEthInterfaceChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(ethInterfaceAdded:)
                         name : ORFlashCamRunModelEthInterfaceAdded
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(ethInterfaceRemoved:)
                         name : ORFlashCamRunModelEthInterfaceRemoved
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : ethInterfaceView];
    [notifyCenter addObserver : self
                     selector : @selector(ethTypeChanged:)
                         name : ORFlashCamRunModelEthTypeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(maxPayloadChanged:)
                         name : ORFlashCamRunModelMaxPayloadChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(eventBufferChanged:)
                         name : ORFlashCamRunModelEventBufferChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(phaseAdjustChanged:)
                         name : ORFlashCamRunModelPhaseAdjustChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(baselineSlewChanged:)
                         name : ORFlashCamRunModelBaselineSlewChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(integratorLenChanged:)
                         name : ORFlashCamRunModelIntegratorLenChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(eventSamplesChanged:)
                         name : ORFlashCamRunModelEventSamplesChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(traceTypeChanged:)
                         name : ORFlashCamRunModelTraceTypeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(pileupRejectionChanged:)
                         name : ORFlashCamRunModelPileupRejectionChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(logTimeChanged:)
                         name : ORFlashCamRunModelLogTimeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(gpsEnabledChanged:)
                         name : ORFlashCamRunModelGPSEnabledChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(includeBaselineChanged:)
                         name : ORFlashCamRunModelIncludeBaselineChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(additionalFlagsChanged:)
                         name : ORFlashCamRunModelAdditionalFlagsChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(overrideCmdChanged:)
                         name : ORFlashCamRunModelOverrideCmdChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runOverrideChanged:)
                         name : ORFlashCamRunModelRunOverrideChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(remoteDataPathChanged:)
                         name : ORFlashCamRunModelRemoteDataPathChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(remoteFilenameChanged:)
                         name : ORFlashCamRunModelRemoteFilenameChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runNumberChanged:)
                         name : ORFlashCamRunModelRunNumberChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runCountChanged:)
                         name : ORFlashCamRunModelRunCountChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runLengthChanged:)
                         name : ORFlashCamRunModelRunLengthChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runUpdateChanged:)
                         name : ORFlashCamRunModelRunUpdateChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(pingStart:)
                         name : ORFlashCamRunModelPingStart
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(pingEnd:)
                         name : ORFlashCamRunModelPingEnd
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runInProgress:)
                         name : ORFlashCamRunModelRunInProgress
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runEnded:)
                          name : ORFlashCamRunModelRunEnded
                        object : nil];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) updateWindow
{
    [super updateWindow];
    [self ipAddressChanged:nil];
    [self usernameChanged:nil];
    [self tableViewSelectionDidChange:nil];
    [ethInterfaceView reloadData];
    [self ethTypeChanged:nil];
    [self maxPayloadChanged:nil];
    [self eventBufferChanged:nil];
    [self phaseAdjustChanged:nil];
    [self baselineSlewChanged:nil];
    [self integratorLenChanged:nil];
    [self eventSamplesChanged:nil];
    [self traceTypeChanged:nil];
    [self pileupRejectionChanged:nil];
    [self logTimeChanged:nil];
    [self gpsEnabledChanged:nil];
    [self includeBaselineChanged:nil];
    [self additionalFlagsChanged:nil];
    [self overrideCmdChanged:nil];
    [self runOverrideChanged:nil];
    [self remoteDataPathChanged:nil];
    [self remoteFilenameChanged:nil];
    [self runNumberChanged:nil];
    [self runCountChanged:nil];
    [self runLengthChanged:nil];
    [self runUpdateChanged:nil];
}

#pragma mark •••Interface Management
- (void) ipAddressChanged:(NSNotification*)note
{
    [ipAddressTextField setStringValue:[model ipAddress]];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam (%@)", [model ipAddress]]];
}

- (void) usernameChanged:(NSNotification*)note
{
    [usernameTextField setStringValue:[model username]];
}

- (void) ethInterfaceChanged:(NSNotification*)note
{
    [ethInterfaceView reloadData];
}

- (void) ethInterfaceAdded:(NSNotification*)note
{
    [ethInterfaceView reloadData];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:[model ethInterfaceCount]-1];
    [ethInterfaceView selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void) ethInterfaceRemoved:(NSNotification*)note
{
    int index = [[[note userInfo] objectForKey:@"index"] intValue];
    index = MAX(0, MIN(index, [model ethInterfaceCount]-1));
    [ethInterfaceView reloadData];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
    [ethInterfaceView selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void) ethTypeChanged:(NSNotification*)note
{
    [ethTypeTextField setStringValue:[model ethType]];
}

- (void) maxPayloadChanged:(NSNotification*)note
{
    [maxPayloadTextField setIntValue:[model maxPayload]];
}

- (void) eventBufferChanged:(NSNotification*)note
{
    [eventBufferTextField setIntValue:[model eventBuffer]];
}

- (void) phaseAdjustChanged:(NSNotification*)note
{
    [phaseAdjustTextField setIntValue:[model phaseAdjust]];
}

- (void) baselineSlewChanged:(NSNotification*)note
{
    [baselineSlewTextField setIntValue:[model baselineSlew]];
}

- (void) integratorLenChanged:(NSNotification*)note
{
    [integratorLenTextField setIntValue:[model integratorLen]];
}

- (void) eventSamplesChanged:(NSNotification*)note
{
    [eventSamplesTextField setIntValue:[model eventSamples]];
}

- (void) traceTypeChanged:(NSNotification*)note
{
    [traceTypePUButton setIntValue:[model traceType]];
}

- (void) pileupRejectionChanged:(NSNotification*)note
{
    [pileupRejectionTextField setFloatValue:[model pileupRejection]];
}

- (void) logTimeChanged:(NSNotification*)note
{
    [logTimeTextField setFloatValue:[model logTime]];
}

- (void) gpsEnabledChanged:(NSNotification*)note
{
    [gpsEnabledButton setIntValue:[model gpsEnabled]];
}

- (void) includeBaselineChanged:(NSNotification*)note
{
    [includeBaselineButton setIntValue:[model includeBaseline]];
}

- (void) additionalFlagsChanged:(NSNotification*)note
{
    [additionalFlagsTextField setStringValue:[model additionalFlags]];
}

- (void) overrideCmdChanged:(NSNotification*)note
{
    [overrideCmdTextField setStringValue:[model overrideCmd]];
}

- (void) runOverrideChanged:(NSNotification*)note
{
    [runOverrideButton setIntValue:[model runOverride]];
}

- (void) remoteDataPathChanged:(NSNotification*)note
{
    [remoteDataPathTextField setStringValue:[model remoteDataPath]];
}

- (void) remoteFilenameChanged:(NSNotification*) note
{
    [remoteFilenameTextField setStringValue:[model remoteFilename]];
}

- (void) runNumberChanged:(NSNotification*)note
{
    [runNumberTextField setIntValue:[model runNumber]];
}

- (void) runCountChanged:(NSNotification*)note
{
    [runCountTextField setIntValue:[model runCount]];
}

- (void) runLengthChanged:(NSNotification*)note
{
    [runLengthTextField setIntValue:[model runLength]];
}

- (void) runUpdateChanged:(NSNotification*)note
{
    [runUpdateButton setIntValue:[model runUpdate]];
}

- (void) pingStart:(NSNotification*)note
{
    [ipAddressTextField setEnabled:NO];
    [sendPingButton setEnabled:NO];
    [startRunButton setEnabled:NO];
    [killRunButton setEnabled:NO];
}

- (void) pingEnd:(NSNotification*)note
{
    [ipAddressTextField setEnabled:YES];
    [sendPingButton setEnabled:YES];
    [startRunButton setEnabled:YES];
    [killRunButton setEnabled:YES];
}

- (void) runInProgress:(NSNotification*)note
{
    [self settingsLock:YES];
}

- (void) runEnded:(NSNotification*)note
{
    [self settingsLock:NO];
}

- (void) settingsLock:(bool)lock
{
    [ipAddressTextField       setEnabled:!lock];
    [usernameTextField        setEnabled:!lock];
    [ethInterfaceView         setEnabled:!lock];
    [ethTypeTextField         setEnabled:!lock];
    [ethTypeTextField         setEnabled:!lock];
    [maxPayloadTextField      setEnabled:!lock];
    [eventBufferTextField     setEnabled:!lock];
    [phaseAdjustTextField     setEnabled:!lock];
    [baselineSlewTextField    setEnabled:!lock];
    [integratorLenTextField   setEnabled:!lock];
    [eventSamplesTextField    setEnabled:!lock];
    [traceTypePUButton        setEnabled:!lock];
    [pileupRejectionTextField setEnabled:!lock];
    [logTimeTextField         setEnabled:!lock];
    [gpsEnabledButton         setEnabled:!lock];
    [includeBaselineButton    setEnabled:!lock];
    [additionalFlagsTextField setEnabled:!lock];
    [overrideCmdTextField     setEnabled:!lock];
    [runOverrideButton        setEnabled:!lock];
    [remoteDataPathTextField  setEnabled:!lock];
    [remoteFilenameTextField  setEnabled:!lock];
    [runNumberTextField       setEnabled:!lock];
    [runCountTextField        setEnabled:!lock];
    [runLengthTextField       setEnabled:!lock];
    [runUpdateButton          setEnabled:!lock];
    [sendPingButton           setEnabled:!lock];
    [startRunButton           setEnabled:!lock];
}

#pragma mark ***Actions

- (IBAction) ipAddressAction:(id)sender
{
    [model setIPAddress:[sender stringValue]];
}

- (IBAction) usernameAction:(id)sender
{
    [model setUsername:[sender stringValue]];
}

- (IBAction) addEthInterfaceAction:(id)sender
{
    [model addEthInterface:@""];
}

- (IBAction) removeEthInterfaceAction:(id)sender
{
    NSUInteger index = [[ethInterfaceView selectedRowIndexes] firstIndex];
    if(index != NSNotFound) [model removeEthInterfaceAtIndex:(int)index];
}

- (IBAction) delete:(id)sender
{
    [self removeEthInterfaceAction:nil];
}

- (IBAction) cut:(id)sender
{
    [self removeEthInterfaceAction:nil];
}

- (IBAction) ethTypeAction:(id)sender
{
    [model setEthType:[sender stringValue]];
}

- (IBAction) maxPayloadAction:(id)sender
{
    [model setMaxPayload:[sender intValue]];
}

- (IBAction) eventBufferAction:(id)sender
{
    [model setEventBuffer:[sender intValue]];
}

- (IBAction) phaseAdjustAction:(id)sender
{
    [model setPhaseAdjust:[sender intValue]];
}

- (IBAction) baselineSlewAction:(id)sender
{
    [model setBaselineSlew:[sender intValue]];
}

- (IBAction) integratorLenAction:(id)sender
{
    [model setIntegratorLen:[sender intValue]];
}

- (IBAction) eventSamplesAction:(id)sender
{
    [model setEventSamples:[sender intValue]];
}

- (IBAction) traceTypeAction:(id)sender
{
    [model setTraceType:(int)[sender indexOfSelectedItem]];
}

- (IBAction) pileupRejectionAction:(id)sender
{
    [model setPileupRejection:[sender floatValue]];
}

- (IBAction) logTimeAction:(id)sender
{
    [model setLogTime:[sender floatValue]];
}

- (IBAction) gpsEnabledAction:(id)sender
{
    [model setGPSEnabled:[sender intValue]];
}

- (IBAction) includeBaselineAction:(id)sender
{
    [model setIncludeBaseline:[sender intValue]];
}

- (IBAction) additionalFlagsAction:(id)sender
{
    [model setAdditionalFlags:[sender stringValue]];
}

- (IBAction) overrideCmdAction:(id)sender
{
    [model setOverrideCmd:[sender stringValue]];
}

- (IBAction) runOverrideAction:(id)sender
{
    [model setRunOverride:[sender intValue]];
}

- (IBAction) remoteDataPathAction:(id)sender
{
    [model setRemoteDataPath:[sender stringValue]];
}

- (IBAction) remoteFilenameAction:(id)sender
{
    [model setRemoteFilename:[sender stringValue]];
}

- (IBAction) runNumberAction:(id)sender
{
    [model setRunNumber:[sender intValue]];
}

- (IBAction) runCountAction:(id)sender
{
    [model setRunCount:[sender intValue]];
}

- (IBAction) runLengthAction:(id)sender
{
    [model setRunLength:[sender intValue]];
}

- (IBAction) runUpdateAction:(id)sender
{
    [model setRunUpdate:[sender intValue]];
}

- (IBAction) sendPingAction:(id)sender
{
    [model sendPing:YES];
}

- (IBAction) startRunAction:(id)sender
{
    [model startRun];
}

- (IBAction) killRunAction:(id)sender
{
    [model killRun];
}

#pragma mark •••Delegate Methods

- (void) tableViewSelectionDidChange:(NSNotification*)note
{
    if([note object] == ethInterfaceView || note == nil){
        NSInteger index = [ethInterfaceView selectedRow];
        [removeEthInterfaeButton setEnabled:index>=0];
    }
}

#pragma mark •••Data Source

- (id) tableView:(NSTableView*)view objectValueForTableColumn:(NSTableColumn*)column row:(NSInteger)row
{
    if(view == ethInterfaceView)
        return [model ethInterfaceAtIndex:(int)row];
    else return nil;
}

- (void) tableView:(NSTableView*)view setObjectValue:(id)object forTableColumn:(NSTableColumn*)column row:(NSInteger)row
{
    if(view == ethInterfaceView)
        [model setEthInterface:object atIndex:(int)row];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView*)view
{
    if(view == ethInterfaceView) return [model ethInterfaceCount];
    else return 0;
}

@end
