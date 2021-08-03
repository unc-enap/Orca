//  Orca
//  ORFlashCamReadoutController.m
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

#import "ORFlashCamReadoutController.h"
#import "ORFlashCamReadoutModel.h"
#import "Utilities.h"

@implementation ORFlashCamReadoutController

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamReadout"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [listenerContainer setGroup:model];
    [listenerContainer setDrawSlots:YES];
    [listenerContainer setDrawSlotNumbers:YES];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam Readout Configuration %d (%@)",
                             [model uniqueIdNumber], [model ipAddress]]];
    [self updateAddIfaceToListenerIfacePUButton];
    [self updateAddIfaceToListenerListenerPUButton];
    [self updateRmIfaceFromListenerIfacePUButton];
    [self updateRmIfaceFromListenerListenerPUButton];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORFlashCamReadoutModelIPAddressChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(usernameChanged:)
                         name : ORFlashCamReadoutModelUsernameChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(ethInterfaceChanged:)
                         name : ORFlashCamReadoutModelEthInterfaceChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(ethInterfaceAdded:)
                         name : ORFlashCamReadoutModelEthInterfaceAdded
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(ethInterfaceRemoved:)
                         name : ORFlashCamReadoutModelEthInterfaceRemoved
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : ethInterfaceView];
    [notifyCenter addObserver : self
                     selector : @selector(ethTypeChanged:)
                         name : ORFlashCamReadoutModelEthTypeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(configParamChanged:)
                         name : ORFlashCamReadoutModelConfigParamChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(pingStart:)
                         name : ORFlashCamReadoutModelPingStart
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(pingEnd:)
                         name : ORFlashCamReadoutModelPingEnd
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runInProgress:)
                         name : ORFlashCamReadoutModelRunInProgress
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runEnded:)
                         name : ORFlashCamReadoutModelRunEnded
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(listenerChanged:)
                         name : ORFlashCamReadoutModelListenerChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(listenerAdded:)
                         name : ORFlashCamReadoutModelListenerAdded
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(listenerRemoved:)
                         name : ORFlashCamReadoutModelListenerRemoved
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(monitoringUpdated:)
                         name : ORFlashCamListenerModelStatusChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(listenerChanged:)
                         name : ORFlashCamListenerModelConfigChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : listenerView];
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : monitorView];
    [notifyCenter addObserver : self
                     selector : @selector(groupObjectAdded:)
                         name : ORGroupObjectsAdded
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(groupObjectRemoved:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(groupObjectMoved:)
                         name : OROrcaObjectMoved
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
    [self configParamChanged:nil];
    [listenerView reloadData];
    [monitorView reloadData];
}

#pragma mark •••Interface Management

- (void) ipAddressChanged:(NSNotification*)note
{
    [ipAddressTextField setStringValue:[model ipAddress]];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam Readout Configuration %d (%@)",
                             [model uniqueIdNumber], [model ipAddress]]];
}

- (void) usernameChanged:(NSNotification*)note
{
    [usernameTextField setStringValue:[model username]];
}

- (void) ethInterfaceChanged:(NSNotification*)note
{
    [ethInterfaceView reloadData];
    [self updateAddIfaceToListenerIfacePUButton];
}

- (void) ethInterfaceAdded:(NSNotification*)note
{
    [ethInterfaceView reloadData];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:[model ethInterfaceCount]-1];
    [ethInterfaceView selectRowIndexes:indexSet byExtendingSelection:NO];
    [self updateAddIfaceToListenerIfacePUButton];
}

- (void) ethInterfaceRemoved:(NSNotification*)note
{
    int index = [[[note userInfo] objectForKey:@"index"] intValue];
    index = MAX(0, MIN(index, [model ethInterfaceCount]-1));
    [ethInterfaceView reloadData];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
    [ethInterfaceView selectRowIndexes:indexSet byExtendingSelection:NO];
    [self updateAddIfaceToListenerIfacePUButton];
    [self updateRmIfaceFromListenerIfacePUButton];
}

- (void) ethTypeChanged:(NSNotification*)note
{
    [ethTypePUButton selectItemWithTitle:[model ethType]];
}

- (void) configParamChanged:(NSNotification*)note
{
    [maxPayloadTextField    setIntValue:[[model   configParam:@"maxPayload"]    intValue]];
    [eventBufferTextField   setIntValue:[[model   configParam:@"eventBuffer"]   intValue]];
    [phaseAdjustTextField   setIntValue:[[model   configParam:@"phaseAdjust"]   intValue]];
    [baselineSlewTextField  setIntValue:[[model   configParam:@"baselineSlew"]  intValue]];
    [integratorLenTextField setIntValue:[[model   configParam:@"integratorLen"] intValue]];
    [eventSamplesTextField  setIntValue:[[model   configParam:@"eventSamples"]  intValue]];
    [traceTypePUButton      setIntValue:[[model   configParam:@"traceType"]     intValue]];
    [pileupRejTextField     setFloatValue:[[model configParam:@"pileupRej"]     doubleValue]];
    [logTimeTextField       setFloatValue:[[model configParam:@"logTime"]       doubleValue]];
    [gpsEnabledButton       setIntValue:[[model   configParam:@"gpsEnabled"]    boolValue]];
    [incBaselineButton      setIntValue:[[model   configParam:@"incBaseline"]   boolValue]];
}

- (void) pingStart:(NSNotification*)note
{
    [ipAddressTextField setEnabled:NO];
    [sendPingButton setEnabled:NO];
}

- (void) pingEnd:(NSNotification*)note
{
    [ipAddressTextField setEnabled:YES];
    [sendPingButton setEnabled:YES];
}

- (void) runInProgress:(NSNotification*)note
{
    [self settingsLock:YES];
}

- (void) runEnded:(NSNotification*)note
{
    [self settingsLock:NO];
}

- (void) listenerChanged:(NSNotification*)note
{
    [listenerView reloadData];
    [monitorView  reloadData];
    [self updateAddIfaceToListenerListenerPUButton];
    [self updateRmIfaceFromListenerListenerPUButton];
}

- (void) listenerAdded:(NSNotification*)note
{
    [listenerView reloadData];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:[model listenerCount]-1];
    [listenerView selectRowIndexes:indexSet byExtendingSelection:NO];
    [ethInterfaceView reloadData];
    [monitorView reloadData];
    [self updateAddIfaceToListenerListenerPUButton];
    [self updateRmIfaceFromListenerListenerPUButton];
}

- (void) listenerRemoved:(NSNotification*)note
{
    int index = [[[note userInfo] objectForKey:@"index"] intValue];
    index = MAX(0, MIN(index, [model listenerCount]-1));
    [listenerView reloadData];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
    [listenerView selectRowIndexes:indexSet byExtendingSelection:NO];
    [ethInterfaceView reloadData];
    [monitorView reloadData];
    [self updateAddIfaceToListenerListenerPUButton];
    [self updateRmIfaceFromListenerListenerPUButton];
}

- (void) monitoringUpdated:(NSNotification*)note
{
    [monitorView reloadData];
}

- (void) groupObjectAdded:(NSNotification*)note
{
    if(note == nil || [note object] == model || [[note object] guardian] == model){
        id userInfo = [note userInfo];
        if(userInfo){
            id dict = [userInfo objectForKey:@"ORGroupObjectList"];
            if(dict){
                for(id obj in dict)
                    if([obj isKindOfClass:NSClassFromString(@"ORFlashCamListenerModel")])
                        for(int i=0; i<[obj remoteInterfaceCount]; i++)
                            [obj removeRemoteInterfaceAtIndex:i];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamReadoutModelListenerAdded object:self];
        [listenerContainer setNeedsDisplay:YES];
    }
}

- (void) groupObjectRemoved:(NSNotification*)note
{
    if(note == nil || [note object] == model || [[note object] guardian] == model){
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamReadoutModelListenerRemoved object:self];
        [listenerContainer setNeedsDisplay:YES];
    }
}

- (void) groupObjectMoved:(NSNotification*)note
{
    if(note == nil || [note object] == model || [[note object] guardian] == model){
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamReadoutModelListenerChanged object:self];
        [listenerContainer setNeedsDisplay:YES];
    }
}

- (void) groupChanged:(NSNotification*)note
{
    if(note == nil || [note object] == model || [[note object] guardian] == model){
        [listenerContainer setNeedsDisplay:YES];
    }
}

- (void) settingsLock:(bool)lock
{
    [ipAddressTextField        setEnabled:!lock];
    [usernameTextField         setEnabled:!lock];
    [ethInterfaceView          setEnabled:!lock];
    [ethTypePUButton           setEnabled:!lock];
    [maxPayloadTextField       setEnabled:!lock];
    [eventBufferTextField      setEnabled:!lock];
    [phaseAdjustTextField      setEnabled:!lock];
    [baselineSlewTextField     setEnabled:!lock];
    [integratorLenTextField    setEnabled:!lock];
    [eventSamplesTextField     setEnabled:!lock];
    [traceTypePUButton         setEnabled:!lock];
    [pileupRejTextField        setEnabled:!lock];
    [logTimeTextField          setEnabled:!lock];
    [gpsEnabledButton          setEnabled:!lock];
    [incBaselineButton         setEnabled:!lock];
    [sendPingButton            setEnabled:!lock];
    [listenerView              setEnabled:!lock];
    [addIfaceToListenerButton  setEnabled:!lock];
    [rmIfaceFromListenerButton setEnabled:!lock];
}

- (void) updateAddIfaceToListenerIfacePUButton
{
    [addIfaceToListenerIfacePUButton removeAllItems];
    [addIfaceToListenerIfacePUButton addItemWithTitle:@"Interface"];
    for(int i=0; i<[model ethInterfaceCount]; i++){
        [addIfaceToListenerIfacePUButton addItemWithTitle:[model ethInterfaceAtIndex:i]];
    }
}

- (void) updateAddIfaceToListenerListenerPUButton
{
    [addIfaceToListenerListenerPUButton removeAllItems];
    [addIfaceToListenerListenerPUButton addItemWithTitle:@"Listener"];
    for(int i=0; i<[model listenerCount]; i++){
        NSMutableString* title = [NSMutableString string];
        [title appendString:[NSString stringWithFormat:@"%lu - ", [[model getListenerAtIndex:i] tag]]];
        [title appendString:[NSString stringWithFormat:@"%@:",    [[model getListenerAtIndex:i] ip]]];
        [title appendString:[NSString stringWithFormat:@"%d",     [[model getListenerAtIndex:i] port]]];
        [addIfaceToListenerListenerPUButton addItemWithTitle:title];
    }
}

- (void) updateRmIfaceFromListenerIfacePUButton
{
    [rmIfaceFromListenerIfacePUButton removeAllItems];
    [rmIfaceFromListenerIfacePUButton addItemWithTitle:@"Interface"];
    int index = (int) [rmIfaceFromListenerListenerPUButton indexOfSelectedItem] - 1;
    if(index < 0 || index >= [model listenerCount]) return;
    NSMutableArray* rinterfaces = [[model getListenerAtIndex:index] remoteInterfaces];
    for(id interface in rinterfaces) [rmIfaceFromListenerIfacePUButton addItemWithTitle:interface];
}

- (void) updateRmIfaceFromListenerListenerPUButton
{
    [rmIfaceFromListenerListenerPUButton removeAllItems];
    [rmIfaceFromListenerListenerPUButton addItemWithTitle:@"Listener"];
    for(int i=0; i<[model listenerCount]; i++){
        NSMutableString* title = [NSMutableString string];
        [title appendString:[NSString stringWithFormat:@"%lu - ", [[model getListenerAtIndex:i] tag]]];
        [title appendString:[NSString stringWithFormat:@"%@:",    [[model getListenerAtIndex:i] ip]]];
        [title appendString:[NSString stringWithFormat:@"%d",     [[model getListenerAtIndex:i] port]]];
        [rmIfaceFromListenerListenerPUButton addItemWithTitle:title];
    }
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
    [model setEthType:[sender titleOfSelectedItem]];
}

- (IBAction) maxPayloadAction:(id)sender
{
    [model setConfigParam:@"maxPayload" withValue:[NSNumber numberWithInt:[sender intValue]]];
}

- (IBAction) eventBufferAction:(id)sender
{
    [model setConfigParam:@"eventBuffer" withValue:[NSNumber numberWithInt:[sender intValue]]];
}

- (IBAction) phaseAdjustAction:(id)sender
{
    [model setConfigParam:@"phaseAdjust" withValue:[NSNumber numberWithInt:[sender intValue]]];
}

- (IBAction) baselineSlewAction:(id)sender
{
    [model setConfigParam:@"baselineSlew" withValue:[NSNumber numberWithInt:[sender intValue]]];
}

- (IBAction) integratorLenAction:(id)sender
{
    [model setConfigParam:@"integratorLen" withValue:[NSNumber numberWithInt:[sender intValue]]];
}

- (IBAction) eventSamplesAction:(id)sender
{
    [model setConfigParam:@"eventSamples" withValue:[NSNumber numberWithInt:[sender intValue]]];
}

- (IBAction) traceTypeAction:(id)sender
{
    [model setConfigParam:@"traceType" withValue:[NSNumber numberWithInt:[sender intValue]]];
}

- (IBAction) pileupRejAction:(id)sender
{
    [model setConfigParam:@"pileupRej" withValue:[NSNumber numberWithDouble:[sender doubleValue]]];
}

- (IBAction) logTimeAction:(id)sender
{
    [model setConfigParam:@"logTime" withValue:[NSNumber numberWithDouble:[sender doubleValue]]];
}

- (IBAction) gpsEnabledAction:(id)sender
{
    [model setConfigParam:@"gpsEnabled" withValue:[NSNumber numberWithBool:[sender intValue]]];
}

- (IBAction) incBaselineAction:(id)sender
{
    [model setConfigParam:@"incBaseline" withValue:[NSNumber numberWithBool:[sender intValue]]];
}

- (IBAction) sendPingAction:(id)sender
{
    [model sendPing:YES];
}

- (IBAction) updateIPAction:(id)sender
{
    [model updateIPs];
}

- (IBAction) listInterfaceAction:(id)sender
{
    ipAddressAndListInterfaces(@"", YES);
}

- (IBAction) addIfaceToListenerAction:(id)sender
{
    [self endEditing];
    [addIfaceToListenerAddButton setEnabled:NO];
    [[self window] beginSheet:addIfaceToListenerPanel completionHandler:nil];
}

- (IBAction) addIfaceToListenerIfaceAction:(id)sender
{
    [addIfaceToListenerIfacePUButton setTitle:[addIfaceToListenerIfacePUButton titleOfSelectedItem]];
    int i = (int) [addIfaceToListenerListenerPUButton indexOfSelectedItem] - 1;
    int j = (int) [addIfaceToListenerIfacePUButton indexOfSelectedItem] - 1;
    if(i >= 0 && i < [model listenerCount] && j >= 0 && j < [model ethInterfaceCount])
        [addIfaceToListenerAddButton setEnabled:YES];
    else [addIfaceToListenerAddButton setEnabled:NO];
}

- (IBAction) addIfaceToListenerListenerAction:(id)sender
{
    [addIfaceToListenerListenerPUButton setTitle:[addIfaceToListenerListenerPUButton titleOfSelectedItem]];
    int i = (int) [addIfaceToListenerListenerPUButton indexOfSelectedItem] - 1;
    int j = (int) [addIfaceToListenerIfacePUButton indexOfSelectedItem] - 1;
    if(i >= 0 && i < [model listenerCount] && j >= 0 && j < [model ethInterfaceCount])
        [addIfaceToListenerAddButton setEnabled:YES];
    else [addIfaceToListenerAddButton setEnabled:NO];
}

- (IBAction) addIfaceToListenerAddAction:(id)sender
{
    int i = (int) [addIfaceToListenerListenerPUButton indexOfSelectedItem] - 1;
    int j = (int) [addIfaceToListenerIfacePUButton indexOfSelectedItem] - 1;
    if(i < 0 || i >= [model listenerCount]) return;
    if(j < 0 || j >= [model ethInterfaceCount]) return;
    [[model getListenerAtIndex:i] addRemoteInterface:[model ethInterfaceAtIndex:j]];
    [self updateAddIfaceToListenerIfacePUButton];
    [addIfaceToListenerAddButton setEnabled:NO];
}

- (IBAction) addIfaceToListenerCloseAction:(id)sender
{
    [addIfaceToListenerPanel orderOut:nil];
    [NSApp endSheet:addIfaceToListenerPanel];
}

- (IBAction) rmIfaceFromListenerAction:(id)sender
{
    [self endEditing];
    [rmIfaceFromListenerRmButton setEnabled:NO];
    [[self window] beginSheet:rmIfaceFromListenerPanel completionHandler:nil];
}

- (IBAction) rmIfaceFromListenerIfaceAction:(id)sender
{
    [rmIfaceFromListenerIfacePUButton setTitle:[rmIfaceFromListenerIfacePUButton titleOfSelectedItem]];
    int i = (int) [rmIfaceFromListenerListenerPUButton indexOfSelectedItem] - 1;
    int j = (int) [rmIfaceFromListenerIfacePUButton indexOfSelectedItem] - 1;
    if(i >= 0 && i < [model listenerCount] && j >= 0 && j < [model ethInterfaceCount])
        [rmIfaceFromListenerRmButton setEnabled:YES];
    else [rmIfaceFromListenerRmButton setEnabled:NO];
}

- (IBAction) rmIfaceFromListenerListenerAction:(id)senmder
{
    [rmIfaceFromListenerListenerPUButton setTitle:[rmIfaceFromListenerListenerPUButton titleOfSelectedItem]];
    [self updateRmIfaceFromListenerIfacePUButton];
    int i = (int) [rmIfaceFromListenerListenerPUButton indexOfSelectedItem] - 1;
    int j = (int) [rmIfaceFromListenerIfacePUButton indexOfSelectedItem] - 1;
    if(i >= 0 && i < [model listenerCount] && j >= 0 && j < [model ethInterfaceCount])
        [rmIfaceFromListenerRmButton setEnabled:YES];
    else [rmIfaceFromListenerRmButton setEnabled:NO];
}

- (IBAction) rmIfaceFromListenerRmAction:(id)sender
{
    int i = (int) [rmIfaceFromListenerListenerPUButton indexOfSelectedItem] - 1;
    int j = (int) [rmIfaceFromListenerIfacePUButton indexOfSelectedItem] - 1;
    if(i < 0 || i >= [model listenerCount]) return;
    if(j < 0 || j >= [model ethInterfaceCount]) return;
    [[model getListenerAtIndex:i] removeRemoteInterface:[model ethInterfaceAtIndex:j]];
    [self updateRmIfaceFromListenerIfacePUButton];
    [rmIfaceFromListenerRmButton setEnabled:NO];
}

- (IBAction) rmIfaceFromListenerCloseAction:(id)sender
{
    [rmIfaceFromListenerPanel orderOut:nil];
    [NSApp endSheet:rmIfaceFromListenerPanel];
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
    NSUInteger col = [[view tableColumns] indexOfObject:column];
    if(view == ethInterfaceView){
        if(col == 0)      return [model ethInterfaceAtIndex:(int)row];
    }
    else if(view == listenerView || view == monitorView){
        ORFlashCamListenerModel* l = [model getListenerAtIndex:(int)row];
        if(!l) return nil;
        if(col == 0){
            NSUInteger i = [l tag];//[model getIndexOfListener:[l interface] atPort:[l port]];
            return [NSNumber numberWithUnsignedLong:i];
        }
        else if(view == listenerView){
            if(col == 1)      return [l interface];
            else if(col == 2) return [NSNumber numberWithInt:(int)[l port]];
            else if(col == 3) return [l ip];
            else if(col == 4) return [NSNumber numberWithInt:[l ioBuffer]];
            else if(col == 5) return [NSNumber numberWithInt:[l stateBuffer]];
            else if(col == 6) return [NSNumber numberWithInt:[l timeout]];
            else if(col == 7) return [[l remoteInterfaces] componentsJoinedByString:@","];
        }
        else if(view == monitorView){
            if(col == 1){
                NSString* s = [l status];
                if(!s) s = @"Idle";
                return s;
            }
            else if(col == 2) return [NSNumber numberWithDouble:[l runTime]];
            else if(col == 3) return [NSNumber numberWithInt:(int)[l eventCount]];
            else if(col == 4) return [NSNumber numberWithDouble:[l rateMB]];
            else if(col == 5) return [NSNumber numberWithDouble:[l rateHz]];
            else if(col == 6) return [NSNumber numberWithDouble:[l curDead]];
            else if(col == 7) return [NSNumber numberWithInt:(int)[l bufferedRecords]];
        }
    }
    return nil;
}

- (void) tableView:(NSTableView*)view setObjectValue:(id)object forTableColumn:(NSTableColumn*)column row:(NSInteger)row
{
    NSUInteger col= [[view tableColumns] indexOfObject:column];
    if(view == ethInterfaceView){
        if(col == 0) [model setEthInterface:object atIndex:(int)row];
    }
    else if(view == listenerView){
        ORFlashCamListenerModel* l = [model getListenerAtIndex:(int)row];
        if(!l) return;
        if(col == 1)      [model setListener:object atPort:[l port] forIndex:(int)row];
        else if(col == 2) [model setListener:[l interface] atPort:(uint16_t)[object intValue] forIndex:(int)row];
        else if(col == 4) [l     setIObuffer:[object intValue]];
        else if(col == 5) [l  setStateBuffer:[object intValue]];
        else if(col == 6) [l      setTimeout:[object intValue]];
    }
}

- (NSInteger) numberOfRowsInTableView:(NSTableView*)view
{
    if(view == ethInterfaceView)  return [model ethInterfaceCount];
    else if(view == listenerView) return [model listenerCount];
    else if(view == monitorView)  return [model listenerCount];
    else return 0;
}

@end
