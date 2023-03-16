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
#import "ORFlashCamListenerModel.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"
#import "Utilities.h"

@implementation ORFlashCamReadoutController

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamReadout"];
    scheduledToUpdatePlot = NO;
    isLocked = NO;
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
    if([model localMode]) [fcSourcePathButton setTitle:@"Set Path to FC Readout Source:"];
    else [fcSourcePathButton setTitle:@"Get Path to FC Readout Source:"];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(settingsLock:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(settingsLock:)
                         name : ORFlashCamReadoutSettingsLock
                       object : nil];
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
                         name : ORFlashCamListenerModelConfigChanged
                       object : nil];
    [notifyCenter addObserver :self
                     selector : @selector(fcSourcePathChanged:)
                         name : ORFlashCamReadoutModelFCSourcePathChanged
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
                     selector : @selector(remotePathStart:)
                         name : ORFlashCamReadoutModelRemotePathStart
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(remotePathEnd:)
                         name : ORFlashCamReadoutModelRemotePathEnd
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
                       object : listenerGPSView];
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : listenerDAQView];
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : listenerWFView];
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : listenerTrigView];
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : listenerBaseView];
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : listenerReadoutView];
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
    [notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(miscAttributesChanged:)
                         name : ORMiscAttributesChanged
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(updateTimePlot:)
                         name : ORRateAverageChangedNotification
                       object : nil];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    NSColor* colors[kFlashCamMaxListeners] = {
        [NSColor blueColor],   [NSColor redColor],   [NSColor greenColor],
        [NSColor blackColor],  [NSColor brownColor], [NSColor purpleColor],
        [NSColor orangeColor], [NSColor yellowColor] };
    
    [dataRateView setPlotTitle:@"Data Rates (MB/s)"];
    [[dataRateView xAxis] setRngLow:0.0 withHigh:10000.0];
    [[dataRateView xAxis] setRngLimitsLow:0.0 withHigh:200000.0 withMinRng:200.0];
    [[dataRateView yAxis] setRngLow:0.0 withHigh:1500.0];
    [[dataRateView yAxis] setRngLimitsLow:0.0 withHigh:10000.0 withMinRng:10.0];
    for(int i=0; i<kFlashCamMaxListeners; i++){
        ORTimeLinePlot* plot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
        [dataRateView addPlot:plot];
        [plot setLineColor:colors[i]];
        [plot setName:[NSString stringWithFormat:@"Listener %d", i]];
        [plot release];
    }
    [(ORTimeAxis*) [dataRateView xAxis] setStartTime:[[NSDate date] timeIntervalSince1970]];
    [dataRateView setShowLegend:YES];

    
    [eventRateView setPlotTitle:@"Event Rates (Hz)"];
    [[eventRateView xAxis] setRngLow:0.0 withHigh:10000.0];
    [[eventRateView xAxis] setRngLimitsLow:0.0 withHigh:200000.0 withMinRng:200.0];
    [[eventRateView yAxis] setRngLow:0.0 withHigh:1500.0];
    [[eventRateView yAxis] setRngLimitsLow:0.0 withHigh:10000.0 withMinRng:10.0];
    for(int i=0; i<kFlashCamMaxListeners; i++){
        ORTimeLinePlot* plot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
        [eventRateView addPlot:plot];
        [plot setLineColor:colors[i]];
        [plot setName:[NSString stringWithFormat:@"Listener %d", i]];
        [plot release];
    }
    [(ORTimeAxis*) [eventRateView xAxis] setStartTime:[[NSDate date] timeIntervalSince1970]];
    [eventRateView setShowLegend:YES];
    
    [deadTimeView setPlotTitle:@"Dead Time (%)"];
    [[deadTimeView xAxis] setRngLow:0.0 withHigh:10000.0];
    [[deadTimeView xAxis] setRngLimitsLow:0.0 withHigh:200000.0 withMinRng:200.0];
    [[deadTimeView yAxis] setRngLow:-1.0 withHigh:100.0];
    [[deadTimeView yAxis] setRngLimitsLow:-1.0 withHigh:100.0 withMinRng:5.0];
    for(int i=0; i<kFlashCamMaxListeners; i++){
        ORTimeLinePlot* plot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
        [deadTimeView addPlot:plot];
        [plot setLineColor:colors[i]];
        [plot setName:[NSString stringWithFormat:@"Listener %d", i]];
        [plot release];
    }
    [(ORTimeAxis*) [deadTimeView xAxis] setStartTime:[[NSDate date] timeIntervalSince1970]];
    [deadTimeView setShowLegend:YES];
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
    [self fcSourcePathChanged:nil];
    [self reloadListenerData];
    [monitorView reloadData];
    [self updateTimePlot:nil];
    [self settingsLock:nil];
}

#pragma mark •••Interface Management

- (void) ipAddressChanged:(NSNotification*)note
{
    [ipAddressTextField setStringValue:[model ipAddress]];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam Readout Configuration %d (%@)",
                             [model uniqueIdNumber], [model ipAddress]]];
    if([model localMode]) [fcSourcePathButton setTitle:@"Set Path to FC Readout Source:"];
    else [fcSourcePathButton setTitle:@"Get Path to FC Readout Source:"];
}

- (void) usernameChanged:(NSNotification*)note
{
    [usernameTextField setStringValue:[model username]];
}

- (void) ethInterfaceChanged:(NSNotification*)note
{
    [ethInterfaceView reloadData];
    [self updateAddIfaceToListenerIfacePUButton];
    [self reloadListenerData];
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
    [self reloadListenerData];
}

- (void) ethTypeChanged:(NSNotification*)note
{
    [ethInterfaceView reloadData];
}

- (void) configParamChanged:(NSNotification*)note
{
    [self reloadListenerData];
}

- (void) reloadListenerData
{
    [listenerView           reloadData];
    [listenerGPSView        reloadData];
    [listenerDAQView        reloadData];
    [listenerWFView         reloadData];
    [listenerTrigView       reloadData];
    [listenerBaseView       reloadData];
    [listenerReadoutView    reloadData];
    [listenerExtraFilesView reloadData];
    [listenerExtraFlagsView reloadData];
}

- (void) pingStart:(NSNotification*)note
{
    [ipAddressTextField setEnabled:NO];
    [sendPingButton setEnabled:NO];
}

- (void) pingEnd:(NSNotification*)note
{
    [ipAddressTextField setEnabled:!isLocked];
    [sendPingButton setEnabled:!isLocked];
}

- (void) remotePathStart:(NSNotification*)note
{
    [usernameTextField setEnabled:NO];
    [ipAddressTextField setEnabled:NO];
    [fcSourcePathButton setEnabled:NO];
}

- (void) remotePathEnd:(NSNotification*)note
{
    [usernameTextField setEnabled:!isLocked];
    [ipAddressTextField setEnabled:!isLocked];
    [fcSourcePathButton setEnabled:!isLocked];
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
    [self reloadListenerData];
    [monitorView  reloadData];
    [self updateAddIfaceToListenerListenerPUButton];
    [self updateRmIfaceFromListenerListenerPUButton];
    int tag   = [[[note userInfo] objectForKey:@"tag"]   intValue];
    [[printListenerFlagsPUButton itemAtIndex:tag] setEnabled:YES];
}

- (void) listenerAdded:(NSNotification*)note
{
    [self reloadListenerData];
    int index = [[[note userInfo] objectForKey:@"index"] intValue];
    int tag   = [[[note userInfo] objectForKey:@"tag"]   intValue];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
    [listenerView        selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerGPSView     selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerDAQView     selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerWFView      selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerTrigView    selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerBaseView    selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerReadoutView selectRowIndexes:indexSet byExtendingSelection:NO];
    [ethInterfaceView reloadData];
    [monitorView reloadData];
    [self updateAddIfaceToListenerListenerPUButton];
    [self updateRmIfaceFromListenerListenerPUButton];
    [[printListenerFlagsPUButton itemAtIndex:tag] setEnabled:YES];
}

- (void) listenerRemoved:(NSNotification*)note
{
    int index = [[[note userInfo] objectForKey:@"index"] intValue];
    int tag   = [[[note userInfo] objectForKey:@"tag"]   intValue];
    index = MAX(0, MIN(index, [model listenerCount]-1));
    [self reloadListenerData];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
    [listenerView selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerGPSView     selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerDAQView     selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerWFView      selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerTrigView    selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerBaseView    selectRowIndexes:indexSet byExtendingSelection:NO];
    [listenerReadoutView selectRowIndexes:indexSet byExtendingSelection:NO];
    [ethInterfaceView reloadData];
    [monitorView reloadData];
    [self updateAddIfaceToListenerListenerPUButton];
    [self updateRmIfaceFromListenerListenerPUButton];
    [[printListenerFlagsPUButton itemAtIndex:tag] setEnabled:NO];
}

- (void) monitoringUpdated:(NSNotification*)note
{
    if([NSThread isMainThread]) [monitorView reloadData];
    else dispatch_async(dispatch_get_main_queue(), ^{[monitorView reloadData];});
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

- (void) scaleAction:(NSNotification*)note;
{
    if(note == nil || [note object] == [dataRateView xAxis])
        [model setMiscAttributes:[(ORAxis*) [dataRateView xAxis] attributes] forKey:@"XAttrib0"];
    if(note == nil || [note object] == [dataRateView yAxis])
        [model setMiscAttributes:[(ORAxis*) [dataRateView yAxis] attributes] forKey:@"YAttrib0"];
    if(note == nil || [note object] == [eventRateView xAxis])
        [model setMiscAttributes:[(ORAxis*) [eventRateView xAxis] attributes] forKey:@"XAttrib1"];
    if(note == nil || [note object] == [eventRateView yAxis])
        [model setMiscAttributes:[(ORAxis*) [eventRateView yAxis] attributes] forKey:@"YAttrib1"];
    if(note == nil || [note object] == [deadTimeView xAxis])
        [model setMiscAttributes:[(ORAxis*) [deadTimeView xAxis] attributes] forKey:@"XAttrib2"];
    if(note == nil || [note object] == [deadTimeView yAxis])
        [model setMiscAttributes:[(ORAxis*) [deadTimeView yAxis] attributes] forKey:@"YAttrib2"];
}

- (void) miscAttributesChanged:(NSNotification*)note
{
    NSString* key = [[note userInfo] objectForKey:ORMiscAttributeKey];
    NSMutableDictionary* attrib = [model miscAttributesForKey:key];
    if(note == nil || [key isEqualToString:@"XAttrib0"]) [self setPlot:dataRateView  xAttributes:attrib];
    if(note == nil || [key isEqualToString:@"YAttrib0"]) [self setPlot:dataRateView  yAttributes:attrib];
    if(note == nil || [key isEqualToString:@"XAttrib1"]) [self setPlot:eventRateView xAttributes:attrib];
    if(note == nil || [key isEqualToString:@"YAttrib1"]) [self setPlot:eventRateView yAttributes:attrib];
    if(note == nil || [key isEqualToString:@"XAttrib2"]) [self setPlot:deadTimeView  xAttributes:attrib];
    if(note == nil || [key isEqualToString:@"YAttrib2"]) [self setPlot:deadTimeView  yAttributes:attrib];
}

- (void) setPlot:(id)plotter xAttributes:(id)attrib
{
    if(attrib){
        [(ORAxis*)[plotter xAxis] setAttributes:attrib];
        [plotter setNeedsDisplay:YES];
        [[plotter yAxis] setNeedsDisplay:YES];
    }
}
- (void) setPlot:(id)plotter yAttributes:(id)attrib
{
    if(attrib){
        [(ORAxis*)[plotter yAxis] setAttributes:attrib];
        [plotter setNeedsDisplay:YES];
        [[plotter yAxis] setNeedsDisplay:YES];
    }
}

- (void) updateTimePlot:(NSNotification*)aNote
{
    if(!scheduledToUpdatePlot){
        scheduledToUpdatePlot=YES;
        [self performSelector:@selector(deferredPlotUpdate) withObject:nil afterDelay:2];
    }
}

- (void) deferredPlotUpdate
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(deferredPlotUpdate) object:nil];
    scheduledToUpdatePlot = NO;
    [dataRateView setNeedsDisplay:YES];
    [eventRateView setNeedsDisplay:YES];
    [deadTimeView setNeedsDisplay:YES];
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

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORFlashCamReadoutSettingsLock to:secure];
    [settingsLockButton setEnabled:secure];
}

- (void) settingsLock:(bool)lock
{
    BOOL locked = [gSecurity isLocked:ORFlashCamReadoutSettingsLock];
    [settingsLockButton        setState:locked];
    lock |= locked || [gOrcaGlobals runInProgress];
    [ipAddressTextField        setEnabled:!lock];
    [usernameTextField         setEnabled:!lock];
    [ethInterfaceView          setEnabled:!lock];
    [addEthInterfaceButton     setEnabled:!lock];
    [removeEthInterfaeButton   setEnabled:!lock];
    [sendPingButton            setEnabled:!lock];
    [listenerView              setEnabled:!lock];
    [listenerGPSView           setEnabled:!lock];
    [listenerDAQView           setEnabled:!lock];
    [listenerWFView            setEnabled:!lock];
    [listenerTrigView          setEnabled:!lock];
    [listenerBaseView          setEnabled:!lock];
    [listenerReadoutView       setEnabled:!lock];
    [listenerExtraFilesView    setEnabled:!lock];
    [listenerExtraFlagsView    setEnabled:!lock];
    [addIfaceToListenerButton  setEnabled:!lock];
    [rmIfaceFromListenerButton setEnabled:!lock];
    [fcSourcePathButton        setEnabled:!lock];
    isLocked = lock;
}

- (void) fcSourcePathChanged:(NSNotification*)note
{
    [fcSourcePathTextField setStringValue:[model fcSourcePath]];
    if([model validFCSourcePath]) [fcSourcePathTextField setTextColor:[NSColor systemGreenColor]];
    else [fcSourcePathTextField setTextColor:[NSColor systemRedColor]];
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
        [addIfaceToListenerAddButton setEnabled:!isLocked];
    else [addIfaceToListenerAddButton setEnabled:NO];
}

- (IBAction) addIfaceToListenerListenerAction:(id)sender
{
    [addIfaceToListenerListenerPUButton setTitle:[addIfaceToListenerListenerPUButton titleOfSelectedItem]];
    int i = (int) [addIfaceToListenerListenerPUButton indexOfSelectedItem] - 1;
    int j = (int) [addIfaceToListenerIfacePUButton indexOfSelectedItem] - 1;
    if(i >= 0 && i < [model listenerCount] && j >= 0 && j < [model ethInterfaceCount])
        [addIfaceToListenerAddButton setEnabled:!isLocked];
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
        [rmIfaceFromListenerRmButton setEnabled:!isLocked];
    else [rmIfaceFromListenerRmButton setEnabled:NO];
}

- (IBAction) rmIfaceFromListenerListenerAction:(id)senmder
{
    [rmIfaceFromListenerListenerPUButton setTitle:[rmIfaceFromListenerListenerPUButton titleOfSelectedItem]];
    [self updateRmIfaceFromListenerIfacePUButton];
    int i = (int) [rmIfaceFromListenerListenerPUButton indexOfSelectedItem] - 1;
    int j = (int) [rmIfaceFromListenerIfacePUButton indexOfSelectedItem] - 1;
    if(i >= 0 && i < [model listenerCount] && j >= 0 && j < [model ethInterfaceCount])
        [rmIfaceFromListenerRmButton setEnabled:!isLocked];
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

- (IBAction) fcSourcePathAction:(id)sender
{
    if([model localMode]){
        NSOpenPanel* panel = [NSOpenPanel openPanel];
        [panel setCanChooseDirectories:YES];
        [panel setCanChooseFiles:NO];
        [panel setAllowsMultipleSelection:NO];
        NSString* startDir;
        NSString* prevPath = [[model fcSourcePath] stringByExpandingTildeInPath];
        if(prevPath) startDir = [prevPath stringByDeletingLastPathComponent];
        else startDir = NSHomeDirectory();
        [panel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
        [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
            if(result == NSFileHandlingPanelOKButton){
                [model setFCSourcePath:[[[panel URL] path] stringByAbbreviatingWithTildeInPath]];
                [model checkFCSourcePath];
            }
        }];
    }
    else [model getRemotePath];
}

- (IBAction) printListenerFlagsAction:(id)sender
{
    int tag = (int) [[printListenerFlagsPUButton selectedItem] tag];
    ORFlashCamListenerModel* l = [model getListenerForTag:tag];
    if(l) [l runFlags:YES];
    else NSLog(@"ORFlashCamReadoutModel: listener tag %d not found\n", tag);
}

- (IBAction) settingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORFlashCamReadoutSettingsLock to:[sender intValue] forWindow:[self window]];
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
        else if(col == 1){
            for(int i=0; i<kFlashCamEthTypeCount; i++){
                if([[model ethTypeAtIndex:(int)row] isEqualToString:kFlashCamEthTypes[i]])
                    return [NSNumber numberWithInt:i];
            }
        }
    }
    else if(view == listenerView        || view == listenerGPSView  || view == listenerDAQView  ||
            view == listenerWFView      || view == listenerTrigView || view == listenerBaseView ||
            view == listenerReadoutView || view == monitorView      || view == listenerExtraFilesView ||
            view == listenerExtraFlagsView){
        ORFlashCamListenerModel* l = [model getListenerAtIndex:(int)row];
        if(!l) return nil;
        if(col == 0){
            NSUInteger i = [l tag];
            return [NSNumber numberWithUnsignedLong:i];
        }
        else if(view == listenerExtraFilesView){
            if(col == 1)      return [l configParam:@"writeFCIOLog"];
            else if(col == 2) return [l configParam:@"extraFiles"];
        }
        else if(view == listenerExtraFlagsView){
            if(col == 1) return [l configParam:@"extraFlags"];
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
        else if(view == listenerGPSView){
            if(col == 1)      return [l configParam:@"gpsMode"];
            else if(col == 2) return [l configParam:@"gpsusClockAlarm"];
        }
        else if(view == listenerDAQView){
            if(col == 1){
                int m = [[l configParam:@"daqMode"] intValue];
                if(m > 2) m -= 7;
                return [NSNumber numberWithInt:m];
            }
            else if(col == 2) return [l configParam:@"nonsparseStart"];
            else if(col == 3) return [l configParam:@"nonsparseEnd"];
            else if(col == 4) return [l configParam:@"sparseOverwrite"];
        }
        else if(view == listenerWFView){
            if(col == 1)      return [l configParam:@"eventSamples"];
            else if(col == 2) return [l configParam:@"signalDepth"];
            else if(col == 3) return [l configParam:@"retriggerLength"];
            else if(col == 4) return [NSNumber numberWithInt:[[l configParam:@"traceType"] intValue]];
            else if(col == 5) return [l configParam:@"incBaseline"];
        }
        else if(view == listenerTrigView){
            if(col == 1)      return [l configParam:@"trigAllEnable"];
            else if(col == 2) return [l configParam:@"trigTimer1Addr"];
            else if(col == 3) return [l configParam:@"trigTimer1Sec"];
            else if(col == 4) return [l configParam:@"trigTimer2Addr"];
            else if(col == 5) return [l configParam:@"trigTimer2Sec"];
        }
        else if(view == listenerBaseView){
            if(col == 1)      return [l configParam:@"baselineCalib"];
            else if(col == 2) return [l configParam:@"baselineSlew"];
            else if(col == 3) return [l configParam:@"integratorLen"];
            else if(col == 4) return [l configParam:@"phaseAdjust"];
            else if(col == 5) return [l configParam:@"pileupRej"];
        }
        else if(view == listenerReadoutView){
            if(col == 1)      return [l configParam:@"logTime"];
            else if(col == 2) return [l configParam:@"maxPayload"];
            else if(col == 3) return [l configParam:@"eventBuffer"];
            else if(col == 4) return [l configParam:@"timeout"];
            else if(col == 5) return [l configParam:@"resetMode"];
            else if(col == 6) return [l configParam:@"evPerRequest"];
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
        if(col == 0)      [model setEthInterface:object atIndex:(int)row];
        else if(col == 1) [model setEthType:kFlashCamEthTypes[[object intValue]] atIndex:(int)row];
    }
    else{
        ORFlashCamListenerModel* l = [model getListenerAtIndex:(int)row];
        if(!l) return;
        if(view == listenerView){
            if(col == 1)      [model setListener:object atPort:[l port] forIndex:(int)row];
            else if(col == 2) [model setListener:[l interface] atPort:(uint16_t)[object intValue] forIndex:(int)row];
            else if(col == 4) [l     setIObuffer:[object intValue]];
            else if(col == 5) [l  setStateBuffer:[object intValue]];
            else if(col == 6) [l      setTimeout:[object intValue]];
        }
        else if(view == listenerExtraFilesView){
            if(col == 1)      [l setConfigParam:@"writeFCIOLog"
                                      withValue:[NSNumber numberWithBool:[object boolValue]]];
            else if(col == 2) [l setConfigParam:@"extraFiles"
                                      withValue:[NSNumber numberWithBool:[object boolValue]]];
        }
        else if(view == listenerExtraFlagsView){
            if(col == 1) [l setConfigParam:@"extraFlags"
                                withString:object];
        }
        else if(view == listenerGPSView){
            if(col == 1)      [l setConfigParam:@"gpsMode"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 2) [l setConfigParam:@"gpsusClockAlarm"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
        }
        
        else if(view == listenerDAQView){
            if(col == 1){
                int i = [object intValue];
                if(i > 2) i = 10 + (i % 3);
                [l setConfigParam:@"daqMode" withValue:[NSNumber numberWithInt:i]];
            }
            else if(col == 2) [l setConfigParam:@"nonsparseStart"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 3) [l setConfigParam:@"nonsparseEnd"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 4) [l setConfigParam:@"sparseOverride"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
        }
        else if(view == listenerWFView){
            if(col == 1)      [l setConfigParam:@"eventSamples"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 2) [l setConfigParam:@"signalDepth"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 3) [l setConfigParam:@"retriggerLength"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 4) [l setConfigParam:@"traceType"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 5) [l setConfigParam:@"incBaseline"
                                      withValue:[NSNumber numberWithBool:[object boolValue]]];
        }
        else if(view == listenerTrigView){
            if(col == 1)      [l setConfigParam:@"trigAllEnable"
                                      withValue:[NSNumber numberWithBool:[object boolValue]]];
            else if(col == 2) [l setConfigParam:@"trigTimer1Addr"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 3) [l setConfigParam:@"trigTimer1Sec"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 4) [l setConfigParam:@"trigTimer2Addr"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 5) [l setConfigParam:@"trigTimer2Sec"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
        }
        else if(view == listenerBaseView){
            if(col == 1)      [l setConfigParam:@"baselineCalib"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 2) [l setConfigParam:@"baselineSlew"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 3) [l setConfigParam:@"integratorLen"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 4) [l setConfigParam:@"phaseAdjust"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 5) [l setConfigParam:@"pileupRej"
                                      withValue:[NSNumber numberWithDouble:[object doubleValue]]];
        }
        else if(view == listenerReadoutView){
            if(col == 1)      [l setConfigParam:@"logTime"
                                      withValue:[NSNumber numberWithDouble:[object doubleValue]]];
            else if(col == 2) [l setConfigParam:@"maxPayload"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 3) [l setConfigParam:@"eventBuffer"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 4) [l setConfigParam:@"timeout"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 5) [l setConfigParam:@"resetMode"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
            else if(col == 6) [l setConfigParam:@"evPerRequest"
                                      withValue:[NSNumber numberWithInt:[object intValue]]];
        }
    }
}

- (NSInteger) numberOfRowsInTableView:(NSTableView*)view
{
    if(view == ethInterfaceView)         return [model ethInterfaceCount];
    else if(view == listenerView)        return [model listenerCount];
    else if(view == listenerGPSView)     return [model listenerCount];
    else if(view == listenerDAQView)     return [model listenerCount];
    else if(view == listenerWFView)      return [model listenerCount];
    else if(view == listenerTrigView)    return [model listenerCount];
    else if(view == listenerBaseView)    return [model listenerCount];
    else if(view == listenerExtraFilesView) return [model listenerCount];
    else if(view == listenerExtraFlagsView) return [model listenerCount];
    else if(view == listenerReadoutView) return [model listenerCount];
    else if(view == monitorView)         return [model listenerCount];
    else return 0;
}

- (int) numberPointsInPlot:(id)aPlotter
{
    ORFlashCamListenerModel* l = [model getListenerAtIndex:(int) [aPlotter tag]];
    if(!l) return 0;
    if([aPlotter plotView]      == [dataRateView plotView])  return (int) [[l dataRateHistory]  count];
    else if([aPlotter plotView] == [eventRateView plotView]) return (int) [[l eventRateHistory] count];
    else if([aPlotter plotView] == [deadTimeView  plotView]) return (int) [[l deadTimeHistory]  count];
    return 0;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    ORFlashCamListenerModel* l = [model getListenerAtIndex:(int) [aPlotter tag]];
    if(!l) return;
    if([aPlotter plotView] == [dataRateView plotView]){
        int index = (int) [[l dataRateHistory] count] - i - 1;
        if(index >= 0){
            *xValue = [[l dataRateHistory] timeSampledAtIndex:index];
            *yValue = [[l dataRateHistory] valueAtIndex:index];
        }
    }
    else if([aPlotter plotView] == [eventRateView plotView]){
        int index = (int) [[l eventRateHistory] count] - i - 1;
        if(index >= 0){
            *xValue = [[l eventRateHistory] timeSampledAtIndex:index];
            *yValue = [[l eventRateHistory] valueAtIndex:index];
        }
    }
    else if([aPlotter plotView] == [deadTimeView plotView]){
        int index = (int) [[l deadTimeHistory] count] - i - 1;
        if(index >= 0){
            *xValue = [[l deadTimeHistory] timeSampledAtIndex:index];
            *yValue = [[l deadTimeHistory] valueAtIndex:index];
        }
    }
}

@end
