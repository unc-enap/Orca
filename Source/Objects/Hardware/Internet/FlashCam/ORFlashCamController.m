#import "ORFlashCamController.h"
#import "ORFlashCamModel.h"

@implementation ORFlashCamController
- (id) init
{
    self = [super initWithWindowNibName:@"FlashCam"];
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
                         name : ORFlashCamModelIPAddressChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(usernameChanged:)
                         name : ORFlashCamModelUsernameChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(ethInterfaceChanged:)
                         name : ORFlashCamModelEthInterfaceChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(ethTypeChanged:)
                         name : ORFlashCamModelEthTypeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(boardAddressChanged:)
                         name : ORFlashCamModelBoardAddressChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(traceTypeChanged:)
                         name : ORFlashCamModelTraceTypeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(signalDepthChanged:)
                         name : ORFlashCamModelSignalDepthChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(postTriggerChanged:)
                         name : ORFlashCamModelPostTriggerChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(baselineOffsetChanged:)
                         name : ORFlashCamModelBaselineOffsetChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(baselineBiasChanged:)
                         name : ORFlashCamModelBaselineBiasChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(remoteDataPathChanged:)
                         name : ORFlashCamModelRemoteDataPathChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(remoteFilenameChanged:)
                         name : ORFlashCamModelRemoteFilenameChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runNumberChanged:)
                         name : ORFlashCamModelRunNumberChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runCountChanged:)
                         name : ORFlashCamModelRunCountChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runLengthChanged:)
                         name : ORFlashCamModelRunLengthChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runUpdateChanged:)
                         name : ORFlashCamModelRunUpdateChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(chanEnabledChanged:)
                         name : ORFlashCamModelChanEnabledChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORFlashCamModelThresholdChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(poleZeroChanged:)
                         name : ORFlashCamModelPoleZeroChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(shapeTimeChanged:)
                         name : ORFlashCamModelShapeTimeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(pingStart:)
                         name : ORFlashCamModelPingStart
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(pingEnd:)
                         name : ORFlashCamModelPingEnd
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runInProgress:)
                         name : ORFlashCamModelRunInProgress
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(runEnded:)
                          name : ORFlashCamModelRunEnded
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
    [self ethInterfaceChanged:nil];
    [self ethTypeChanged:nil];
    [self boardAddressChanged:nil];
    [self traceTypeChanged:nil];
    [self signalDepthChanged:nil];
    [self postTriggerChanged:nil];
    [self baselineOffsetChanged:nil];
    [self baselineBiasChanged:nil];
    [self remoteDataPathChanged:nil];
    [self remoteFilenameChanged:nil];
    [self runNumberChanged:nil];
    [self runCountChanged:nil];
    [self runLengthChanged:nil];
    [self runUpdateChanged:nil];
    [self chanEnabledChanged:nil];
    [self thresholdChanged:nil];
    [self poleZeroChanged:nil];
    [self shapeTimeChanged:nil];
}

#pragma mark ***Interface Management
- (void) ipAddressChanged:(NSNotification*)note
{
    [ipAddressTextField setStringValue:[model ipAddress]];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam (%@)", [model ipAddress]]];
}

- (void) usernameChanged:(NSNotification*)note
{
    [usernameTextField setStringValue:[model username]];
}

- (void) ethInterfaceChanged:(NSNotification *)note
{
    [ethInterfaceTextField setStringValue:[model ethInterface]];
}

- (void) ethTypeChanged:(NSNotification *)note
{
    [ethTypeTextField setStringValue:[model ethType]];
}

- (void) boardAddressChanged:(NSNotification *)note
{
    [boardAddressTextField setIntValue:[model boardAddress]];
}

- (void) traceTypeChanged:(NSNotification *)note
{
    [traceTypeButton selectItemWithTag:[model traceType]];
}

- (void) signalDepthChanged:(NSNotification *)note
{
    [signalDepthTextField setIntValue:[model signalDepth]];
}

- (void) postTriggerChanged:(NSNotification *)note
{
    [postTriggerTextField setIntValue:[model postTrigger]];
}

- (void) baselineOffsetChanged:(NSNotification *)note
{
    [baselineOffsetTextField setIntValue:[model baselineOffset]];
}

- (void) baselineBiasChanged:(NSNotification *)note
{
    [baselineBiasTextField setIntValue:[model baselineBias]];
}

- (void) remoteDataPathChanged:(NSNotification *)note
{
    [remoteDataPathTextField setStringValue:[model remoteDataPath]];
}

- (void) remoteFilenameChanged:(NSNotification*) note
{
    [remoteFilenameTextField setStringValue:[model remoteFilename]];
}

- (void) runNumberChanged:(NSNotification *)note
{
    [runNumberTextField setIntValue:[model runNumber]];
}

- (void) runCountChanged:(NSNotification*)note
{
    [runCountTextField setIntValue:[model runCount]];
}

- (void) runLengthChanged:(NSNotification *)note
{
    [runLengthTextField setIntValue:[model runLength]];
}

- (void) runUpdateChanged:(NSNotification *)note
{
    [runUpdateButton setIntValue:[model runUpdate]];
}

- (void) chanEnabledChanged:(NSNotification *)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamChannels; i++)
            [[chanEnabledMatrix cellWithTag:i] setState:[model chanEnabled:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[chanEnabledMatrix cellWithTag:chan] setState:[model chanEnabled:chan]];
    }
}

- (void) thresholdChanged:(NSNotification *)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamChannels; i++)
            [[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[thresholdMatrix cellWithTag:chan] setIntValue:[model threshold:chan]];
    }
}

- (void) poleZeroChanged:(NSNotification *)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamChannels; i++)
            [[poleZeroMatrix cellWithTag:i] setIntValue:[model poleZero:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[poleZeroMatrix cellWithTag:chan] setIntValue:[model poleZero:chan]];
    }
}

- (void) shapeTimeChanged:(NSNotification *)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamChannels; i++)
            [[shapeTimeMatrix cellWithTag:i] setIntValue:[model shapeTime:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[shapeTimeMatrix cellWithTag:chan] setIntValue:[model shapeTime:chan]];
    }
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
    [ipAddressTextField setEnabled:!lock];
    [usernameTextField setEnabled:!lock];
    [ethInterfaceTextField setEnabled:!lock];
    [ethTypeTextField setEnabled:!lock];
    [boardAddressTextField setEnabled:!lock];
    [traceTypeButton setEnabled:!lock];
    [signalDepthTextField setEnabled:!lock];
    [postTriggerTextField setEnabled:!lock];
    [baselineOffsetTextField setEnabled:!lock];
    [baselineBiasTextField setEnabled:!lock];
    [remoteDataPathTextField setEnabled:!lock];
    [remoteFilenameTextField setEnabled:!lock];
    [runNumberTextField setEnabled:!lock];
    [runCountTextField setEnabled:!lock];
    [runLengthTextField setEnabled:!lock];
    [runUpdateButton setEnabled:!lock];
    [chanEnabledMatrix setEnabled:!lock];
    [thresholdMatrix setEnabled:!lock];
    [poleZeroMatrix setEnabled:!lock];
    [shapeTimeMatrix setEnabled:!lock];
    [sendPingButton setEnabled:!lock];
    [startRunButton setEnabled:!lock];
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

- (IBAction) ethInterfaceAction:(id)sender
{
    [model setEthInterface:[sender stringValue]];
}

- (IBAction) ethTypeAction:(id)sender
{
    [model setEthType:[sender stringValue]];
}

- (IBAction) boardAddressAction:(id)sender
{
    [model setBoardAddress:[sender intValue]];
}

- (IBAction) traceTypeAction:(id)sender
{
    [model setTraceType:(unsigned int)[sender indexOfSelectedItem]];
}

- (IBAction) signalDepthAction:(id)sender
{
    [model setSignalDepth:[sender intValue]];
}

- (IBAction) postTriggerAction:(id)sender
{
    [model setPostTrigger:[sender intValue]];
}

- (IBAction) baselineOffsetAction:(id)sender
{
    [model setBaselineOffset:[sender intValue]];
}

- (IBAction) baselineBiasAction:(id)sender
{
    [model setBaselineBias:[sender intValue]];
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

- (IBAction) chanEnabledAction:(id)sender
{
    if([sender intValue] != [model chanEnabled:(unsigned int)[[sender selectedCell] tag]])
        [model setChanEnabled:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) thresholdAction:(id)sender
{
    if([sender intValue] != [model threshold:(unsigned int)[[sender selectedCell] tag]])
        [model setThreshold:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) poleZeroAction:(id)sender
{
    if([sender intValue] != [model poleZero:(unsigned int)[[sender selectedCell] tag]])
        [model setPoleZero:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) shapeTimeAction:(id)sender
{
    if([sender intValue] != [model shapeTime:(unsigned int)[[sender selectedCell] tag]])
        [model setShapeTime:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

@end
