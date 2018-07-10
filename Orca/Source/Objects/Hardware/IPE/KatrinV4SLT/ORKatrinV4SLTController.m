//
//  ORKatrinV4SLTController.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
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


#pragma mark •••Imported Files
#import "ORKatrinV4SLTController.h"
#import "ORKatrinV4SLTModel.h"
#import "TimedWorker.h"
#import "SBC_Link.h"
#import "StopLightView.h"


@interface ORKatrinV4SLTController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) calibrationSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
- (void) do:(SEL)aSelector name:(NSString*)aName;
@end

@implementation ORKatrinV4SLTController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"KatrinV4SLT"];
    return self;
}

#pragma mark •••Initialization
- (void) dealloc
{
	[xImage release];
	[yImage release];
    [super dealloc];
}

- (void) awakeFromNib
{
	controlSize			= NSMakeSize(555,480);
    statusSize			= NSMakeSize(555,480);
    lowLevelSize		= NSMakeSize(555,490);
    cpuManagementSize	= NSMakeSize(485,450);
    cpuTestsSize		= NSMakeSize(555,355);
	
	[[self window] setTitle:@"IPE-DAQ-V4 SLT"];
    
    [lightBoardView hideCautionLight];
    [lightBoardView1 hideCautionLight];

    [super awakeFromNib];
    [self updateWindow];
	
	[self populatePullDown];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
	
	[notifyCenter addObserver : self
                     selector : @selector(hwVersionChanged:)
                         name : ORKatrinV4SLTModelHwVersionChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusRegChanged:)
                         name : ORKatrinV4SLTModelStatusRegChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(controlRegChanged:)
                         name : ORKatrinV4SLTModelControlRegChanged
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORKatrinV4SLTSelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORKatrinV4SLTWriteValueChanged
					   object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(pulserAmpChanged:)
                         name : ORKatrinV4SLTPulserAmpChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pulserDelayChanged:)
                         name : ORKatrinV4SLTPulserDelayChanged
                       object : model];
			
    [notifyCenter addObserver : self
                     selector : @selector(interruptMaskChanged:)
                         name : ORKatrinV4SLTModelInterruptMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollRateChanged:)
                         name : ORKatrinV4SLTPollTimeChanged
                       object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(patternFilePathChanged:)
                         name : ORKatrinV4SLTModelPatternFilePathChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(secondsSetChanged:)
                         name : ORKatrinV4SLTModelSecondsSetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(deadTimeChanged:)
                         name : ORKatrinV4SLTModelDeadTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(vetoTimeChanged:)
                         name : ORKatrinV4SLTModelVetoTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runTimeChanged:)
                         name : ORKatrinV4SLTModelRunTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(clockTimeChanged:)
                         name : ORKatrinV4SLTModelClockTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(countersEnabledChanged:)
                         name : ORKatrinV4SLTModelCountersEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sltScriptArgumentsChanged:)
                         name : ORKatrinV4SLTModelSltScriptArgumentsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(secondsSetInitWithHostChanged:)
                         name : ORKatrinV4SLTModelSecondsSetInitWithHostChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(secondsSetSendToFLTsChanged:)
                         name : ORKatrinV4SLTModelSecondsSetSendToFLTsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pixelBusEnableRegChanged:)
                         name : ORKatrinV4SLTModelPixelBusEnableRegChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lostEventsChanged:)
                         name : ORKatrinV4SLTModelLostEventsChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lostFltEventsChanged:)
                         name : ORKatrinV4SLTModelLostFltEventsChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lostFltEventsTrChanged:)
                         name : ORKatrinV4SLTModelLostFltEventsTrChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(minimumDecodingChanged:)
                         name : ORKatrinV4SLTModelMinimizeDecodingChanged
                        object: model];
}

#pragma mark •••Interface Management
- (void) minimumDecodingChanged:(NSNotification*)aNote
{
    [minimumDecodingMatrix selectCellWithTag:[model minimizeDecoding]];
}

- (void) pixelBusEnableRegChanged:(NSNotification*)aNote
{
	[pixelBusEnableRegTextField setIntValue: [model pixelBusEnableReg]];
	int i;
	for(i=0;i<20;i++){
		[[pixelBusEnableRegMatrix cellWithTag:i] setIntValue: ([model pixelBusEnableReg] & (0x1 <<i))];
	}    

}

- (void) secondsSetSendToFLTsChanged:(NSNotification*)aNote
{
	[secondsSetSendToFLTsCB setState: [model secondsSetSendToFLTs]];
}

- (void) secondsSetInitWithHostChanged:(NSNotification*)aNote
{
	[secondsSetInitWithHostButton setState: [model secondsSetInitWithHost]];
	[secondsSetField setEnabled:![model secondsSetInitWithHost]];
}

- (void) sltScriptArgumentsChanged:(NSNotification*)aNote
{
	[sltScriptArgumentsTextField setStringValue: [model sltScriptArguments]];
}

- (void) countersEnabledChanged:(NSNotification*)aNote
{
	[enableDisableCountersMatrix selectCellWithTag: [model countersEnabled]];
}

- (void) clockTimeChanged:(NSNotification*)aNote
{
	[[countersMatrix cellWithTag:5] setIntValue:[model clockTime]];
}

- (void) runTimeChanged:(NSNotification*)aNote
{
	unsigned long long t=[model runTime];
	[[countersMatrix cellWithTag:0] setStringValue: [NSString stringWithFormat:@"%.3f",t/1.E7]];
}

- (void) vetoTimeChanged:(NSNotification*)aNote
{
	//unsigned long long t=[model vetoTime];
	//[[countersMatrix cellWithTag:1] setStringValue: [NSString stringWithFormat:@"%.3f",t/1.E7]];
}

- (void) deadTimeChanged:(NSNotification*)aNote
{
	unsigned long long t=[model deadTime];
	[[countersMatrix cellWithTag:1] setStringValue: [NSString stringWithFormat:@"%.3f",t/1.E7]];
}

- (void) lostEventsChanged:(NSNotification*)aNote
{
    unsigned long long t=[model lostEvents];
    [[countersMatrix cellWithTag:2] setStringValue: [NSString stringWithFormat:@"%llu",t]];
}

- (void) lostFltEventsChanged:(NSNotification*)aNote
{
    unsigned long long t=[model lostFltEvents];
    [[countersMatrix cellWithTag:4] setStringValue: [NSString stringWithFormat:@"%llu",t]];
}

- (void) lostFltEventsTrChanged:(NSNotification*)aNote
{
    unsigned long long t=[model lostFltEventsTr];
    [[countersMatrix cellWithTag:3] setStringValue: [NSString stringWithFormat:@"%llu",t]];
}


- (void) secondsSetChanged:(NSNotification*)aNote
{
	[secondsSetField setIntValue: [model secondsSet]];
}

- (void) statusRegChanged:(NSNotification*)aNote
{
    if(![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(statusRegChanged:) withObject:aNote waitUntilDone:NO];
        return;
    }
	unsigned long statusReg = [model statusReg];
	[[statusMatrix cellWithTag:0] setStringValue: IsBitSet(statusReg,kStatusFltRq)?@"ERR":@"OK"];
	[[statusMatrix cellWithTag:1] setStringValue: IsBitSet(statusReg,kStatusWDog)?@"ERR":@"OK"];
	[[statusMatrix cellWithTag:2] setStringValue: IsBitSet(statusReg,kStatusPixErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:3] setStringValue: IsBitSet(statusReg,kStatusPpsErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:4] setStringValue: [NSString stringWithFormat:@"0x%02lx",ExtractValue(statusReg,kStatusClkErr,4)]];
	[[statusMatrix cellWithTag:5] setStringValue: IsBitSet(statusReg,kStatusGpsErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:6] setStringValue: IsBitSet(statusReg,kStatusVttErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:7] setStringValue: IsBitSet(statusReg,kStatusFanErr)?@"ERR":@"OK"]; 

    
    if(statusReg & kStatusInh){
        [lightBoardView setState:kStoppedLight];
        [lightBoardView1 setState:kStoppedLight];
    }
    else {
        [lightBoardView setState:kGoLight];
        [lightBoardView1 setState:kGoLight];
    }
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	[super tabView:aTabView didSelectTabViewItem:tabViewItem];
	
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:controlSize];			break;
		case  1: [self resizeWindowToSize:statusSize];			break;
		case  2: [self resizeWindowToSize:lowLevelSize];	    break;
		case  3: [self resizeWindowToSize:cpuManagementSize];	break;
		case  4: [self resizeWindowToSize:cpuTestsSize];        break;
		default: [self resizeWindowToSize:controlSize];	    break;//default=largest size
    }
}

- (void) patternFilePathChanged:(NSNotification*)aNote
{
	NSString* thePath = [[model patternFilePath] stringByAbbreviatingWithTildeInPath];
	if(!thePath)thePath = @"---";
	[patternFilePathField setStringValue: thePath];
}

- (void) pollRateChanged:(NSNotification*)aNotification
{
    [pollRatePopup selectItemWithTag:[model pollTime]];
    if([model pollTime])[pollRunningIndicator startAnimation:self];
    else                [pollRunningIndicator stopAnimation:self];

}

- (void) interruptMaskChanged:(NSNotification*)aNote
{
	unsigned long aMaskValue = [model interruptMask];
	int i;
	for(i=0;i<16;i++){
		if(aMaskValue & (1L<<i))[[interruptMaskMatrix cellWithTag:i] setIntValue:1];
		else [[interruptMaskMatrix cellWithTag:i] setIntValue:0];
	}
}


- (void) updateWindow
{
    [super updateWindow];
	[self hwVersionChanged:nil];
	[self controlRegChanged:nil];
    [self writeValueChanged:nil];
    [self pulserAmpChanged:nil];
    [self pulserDelayChanged:nil];
    [self selectedRegIndexChanged:nil];
	[self interruptMaskChanged:nil];
    [self pollRateChanged:nil];
	[self patternFilePathChanged:nil];
	[self statusRegChanged:nil];
	[self secondsSetChanged:nil];
    [self deadTimeChanged:nil];
    [self lostEventsChanged:nil];
    [self lostFltEventsChanged:nil];
    [self lostFltEventsTrChanged:nil];
	[self vetoTimeChanged:nil];
	[self runTimeChanged:nil];
	[self clockTimeChanged:nil];
	[self countersEnabledChanged:nil];
	[self sltScriptArgumentsChanged:nil];
	[self secondsSetInitWithHostChanged:nil];
	[self secondsSetSendToFLTsChanged:nil];
	[self pixelBusEnableRegChanged:nil];
}

- (void) checkGlobalSecurity
{
    [super checkGlobalSecurity]; 
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:[model sbcLockName] to:secure];
}


- (void) settingsLockChanged:(NSNotification*)aNotification
{
    [super settingsLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORKatrinV4SLTSettingsLock];
    BOOL locked = [gSecurity isLocked:ORKatrinV4SLTSettingsLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
	
    [initOnConnectButton        setEnabled:!lockedOrRunningMaintenance];
    [setCodeLocationButton      setEnabled:!lockedOrRunningMaintenance];
    [haltSBCButton              setEnabled:!lockedOrRunningMaintenance];
    [inhibitEnableMatrix        setEnabled:!lockedOrRunningMaintenance];
    [pixelBusEnableRegMatrix    setEnabled:!isRunning];
    [hwVersionButton            setEnabled:!isRunning];
    [enableDisableCountersMatrix setEnabled:!isRunning];
    [minimumDecodingMatrix      setEnabled:!isRunning];
    
    [secondsSetInitWithHostButton setEnabled:!lockedOrRunningMaintenance];
    [secondsSetSendToFLTsCB     setEnabled:!lockedOrRunningMaintenance];
    [secondsSetNowButton        setEnabled:!lockedOrRunningMaintenance];
    [secondsSetField            setEnabled:!lockedOrRunningMaintenance];
    [pixelBusReadButton         setEnabled:!lockedOrRunningMaintenance];
    [pixelBusWriteButton        setEnabled:!lockedOrRunningMaintenance];
    [miscCntrlBitsMatrix        setEnabled:!lockedOrRunningMaintenance];
    [testPatternEnableMatrix    setEnabled:!lockedOrRunningMaintenance];
    [pixelBusEnableRegTextField setEnabled:!lockedOrRunningMaintenance];
    [loadPatternFileButton      setEnabled:!lockedOrRunningMaintenance];
	[definePatternFileButton    setEnabled:!lockedOrRunningMaintenance];
	[setSWInhibitButton         setEnabled:!lockedOrRunningMaintenance];
	[relSWInhibitButton         setEnabled:!lockedOrRunningMaintenance];
	[forceTriggerButton         setEnabled:!lockedOrRunningMaintenance];
    [initAllBoardsButton         setEnabled:!lockedOrRunningMaintenance];
    [initAllBoards1Button         setEnabled:!lockedOrRunningMaintenance];
    [initBoardButton            setEnabled:!lockedOrRunningMaintenance];
	[initBoard1Button           setEnabled:!lockedOrRunningMaintenance];
	[readBoardButton            setEnabled:!lockedOrRunningMaintenance];
	[secStrobeSrcPU             setEnabled:!lockedOrRunningMaintenance];
	
    [interruptMaskMatrix        setEnabled:!lockedOrRunningMaintenance];
    [resetFLTButton             setEnabled:!lockedOrRunningMaintenance];
    [resetSLTButton             setEnabled:!lockedOrRunningMaintenance];
    [setSWInhibitButton         setEnabled:!lockedOrRunningMaintenance];
	[relSWInhibitButton         setEnabled:!lockedOrRunningMaintenance];
	[forceTrigger1Button        setEnabled:!lockedOrRunningMaintenance];
    
	[clearAllStatusErrorBitsButton setEnabled:!lockedOrRunningMaintenance];

	[resetHWButton setEnabled:!isRunning];
	
	[pulserAmpField setEnabled:!locked];
    
	[self enableRegControls];
}

- (void) enableRegControls
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORKatrinV4SLTSettingsLock];
	short index = [model selectedRegIndex];
	BOOL readAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegReadable)>0;
	BOOL writeAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegWriteable)>0;
	
	[regWriteButton setEnabled:writeAllowed];
	[regReadButton setEnabled:readAllowed];
	
	[regWriteValueStepper setEnabled:writeAllowed];
	[regWriteValueTextField setEnabled:writeAllowed];
}

- (void) endAllEditing:(NSNotification*)aNotification
{
}

- (void) hwVersionChanged:(NSNotification*) aNote
{
	NSString* s = [NSString stringWithFormat:@"%lu 0x%lx,0x%lx",[model projectVersion],[model documentVersion],[model implementation]];
	[hwVersionField setStringValue:s];
}

- (void) writeValueChanged:(NSNotification*) aNote
{
	[self updateStepper:regWriteValueStepper setting:[model writeValue]];
	[regWriteValueTextField setIntValue:[model writeValue]];
}

- (void) selectedRegIndexChanged:(NSNotification*) aNote
{
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerPopUp	 setting:index];
	
	[self enableRegControls];
}


- (void) controlRegChanged:(NSNotification*)aNote
{
	unsigned long value = [model controlReg];
	unsigned long aMask = (value & kCtrlInhEnMask)>>kCtrlInhEnShift;
    int i;
	for(i=0;i<4;i++)[[inhibitEnableMatrix cellWithTag:i] setIntValue:aMask & (0x1<<i)];
	
	//aMask = (value & kCtrlTpEnMask)>>kCtrlTpEnEnShift;
	[testPatternEnableMatrix selectCellWithTag:aMask];
	
	[[miscCntrlBitsMatrix cellWithTag:0] setIntValue:value & kCtrlPPSMask];
	[[miscCntrlBitsMatrix cellWithTag:1] setIntValue:value & kCtrlShapeMask];
	[[miscCntrlBitsMatrix cellWithTag:2] setIntValue:value & kCtrlRunMask];
	[[miscCntrlBitsMatrix cellWithTag:3] setIntValue:value & kCtrlTstSltMask];
	[[miscCntrlBitsMatrix cellWithTag:4] setIntValue:value & kCtrlIntEnMask];
	[[miscCntrlBitsMatrix cellWithTag:5] setIntValue:value & kCtrlLedOffmask];	
}

- (void) populatePullDown
{
    short	i;
    [registerPopUp removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerPopUp insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
}

- (void) pulserAmpChanged:(NSNotification*) aNote
{
	[pulserAmpField setFloatValue:[model pulserAmp]];
}

- (void) pulserDelayChanged:(NSNotification*) aNote
{
	[pulserDelayField setFloatValue:[model pulserDelay]];
}

#pragma mark ***Actions
- (IBAction) minimumDecodingAction:(id)sender
{
    [model setMinimizeDecoding:[[sender selectedCell]tag]];
}

- (IBAction) readSLTEventFifoButtonAction:(id)sender
{
	[model readSLTEventFifoSingleEvent];	
}

- (void) pixelBusEnableRegTextFieldAction:(id)sender
{
	[model setPixelBusEnableReg:[sender intValue]];	
}


- (void) pixelBusEnableRegMatrixAction:(id)sender
{
	int i, val=0;
	for(i=0;i<20;i++){
		if([[sender cellWithTag:i] intValue]) val |= (0x1<<i);
	}
	[model setPixelBusEnableReg:val];

}

- (IBAction) writePixelBusEnableRegButtonAction:(id)sender
{
	[model writePixelBusEnableReg];	
}

- (IBAction) readPixelBusEnableRegButtonAction:(id)sender
{
	[model readPixelBusEnableReg];	
}

- (IBAction) secondsSetSetNowButtonAction:(id)sender
{
    [model loadSecondsReg];
}

- (void) secondsSetSendToFLTsCBAction:(id)sender
{
	[model setSecondsSetSendToFLTs:[secondsSetSendToFLTsCB intValue]];	
}

- (void) secondsSetInitWithHostButtonAction:(id)sender
{
	[model setSecondsSetInitWithHost:[secondsSetInitWithHostButton intValue]];	
}

- (void) sltScriptArgumentsTextFieldAction:(id)sender
{
	[model setSltScriptArguments:[sender stringValue]];	
}

- (void) enableDisableCounterAction:(id)sender
{
	[model setCountersEnabled:[[sender selectedCell]tag]];	
}

- (IBAction) secondsSetAction:(id)sender
{
	[model setSecondsSet:[sender intValue]];	
}

- (IBAction) inhibitEnableAction:(id)sender;
{
	unsigned long aMask = 0;
	int i;
	for(i=0;i<4;i++){
		if([[inhibitEnableMatrix cellWithTag:i] intValue]) aMask |= (1L<<i);
		else aMask &= ~(1L<<i);
	}
	unsigned long theRegValue = [model controlReg] & ~kCtrlInhEnMask; 
	theRegValue |= (aMask<<kCtrlInhEnShift);
	[model setControlReg:theRegValue];
}

- (IBAction) testPatternEnableAction:(id)sender;
{
	unsigned long aMask       = [[testPatternEnableMatrix selectedCell] tag];
	unsigned long theRegValue = [model controlReg] & ~kCtrlTpEnMask; 
	theRegValue |= (aMask<<kCtrlTpEnEnShift);
	[model setControlReg:theRegValue];
}

- (IBAction) miscCntrlBitsAction:(id)sender;
{
	unsigned long theRegValue = [model controlReg] & ~(kCtrlPPSMask | kCtrlShapeMask | kCtrlRunMask | kCtrlTstSltMask | kCtrlIntEnMask | kCtrlLedOffmask); 
	if([[miscCntrlBitsMatrix cellWithTag:0] intValue])	theRegValue |= kCtrlPPSMask;
	if([[miscCntrlBitsMatrix cellWithTag:1] intValue])	theRegValue |= kCtrlShapeMask;
	if([[miscCntrlBitsMatrix cellWithTag:2] intValue])	theRegValue |= kCtrlRunMask;
	if([[miscCntrlBitsMatrix cellWithTag:3] intValue])	theRegValue |= kCtrlTstSltMask;
	if([[miscCntrlBitsMatrix cellWithTag:4] intValue])	theRegValue |= kCtrlIntEnMask;
	if([[miscCntrlBitsMatrix cellWithTag:5] intValue])	theRegValue |= kCtrlLedOffmask;

	[model setControlReg:theRegValue];
}

//----------------------------------
- (IBAction) pollNowAction:(id)sender
{
	[model readAllStatus];
}

- (IBAction) pollRateAction:(id)sender
{
    [model setPollTime:[[pollRatePopup selectedItem] tag]];
}

- (IBAction) interruptMaskAction:(id)sender
{
	unsigned long aMaskValue = 0;
	int i;
	for(i=0;i<16;i++){
		if([[interruptMaskMatrix cellWithTag:i] intValue]) aMaskValue |= (1L<<i);
		else aMaskValue &= ~(1L<<i);
	}
	[model setInterruptMask:aMaskValue];	
}

- (IBAction) initBoardAction:(id)sender
{
	@try {
		[self endEditing];
		[model initBoard];
		NSLog(@"SLT%d initialized\n",[model stationNumber]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception SLT init\n");
        ORRunAlertPanel([localException name], @"%@\nSLT%d InitBoard failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}
- (IBAction) initAllBoardsAction:(id)sender
{
    @try {
        [self endEditing];
        [model initAllBoards];
        NSLog(@"SLT%d and All FLTs initialized\n",[model stationNumber]);
    }
    @catch(NSException* localException) {
        NSLog(@"Exception SLT init\n");
        ORRunAlertPanel([localException name], @"%@\nSLT%d InitAllBoards failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
    }
}
- (IBAction) readStatus:(id)sender
{
	[model readStatusReg];
}

- (IBAction) reportAllAction:(id)sender
{
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont, @"SLT station# %d Report:\n",[model stationNumber]);

	@try {
		NSLogFont(aFont, @"Board ID: %lld\n",[model readBoardID]);
		[model printStatusReg];
		[model printControlReg];
		NSLogFont(aFont,@"--------------------------------------\n");
		NSLogFont(aFont,@"Dead Time  : %.3f\n",[model readDeadTime]/1.0E7);
		NSLogFont(aFont,@"Veto Time  : %.3f\n",[model readVetoTime]/1.0E7);
		NSLogFont(aFont,@"Run Time   : %.3f\n",[model readRunTime]/1.0E7);
		NSLogFont(aFont,@"Seconds    : %d\n",  [model getSeconds]);
		[model printInterruptMask];
		[model printInterruptRequests];
	    long fdhwlibVersion = [model getFdhwlibVersion];  //TODO: write a method [model printFdhwlibVersion];
	    int ver=(fdhwlibVersion>>16) & 0xff,maj =(fdhwlibVersion>>8) & 0xff,min = fdhwlibVersion & 0xff;
	    NSLogFont(aFont,@"%@: SBC PrPMC running with fdhwlib version: %i.%i.%i (0x%08x)\n",[model fullID],ver,maj,min, fdhwlibVersion);
	    NSLogFont(aFont,@"SBC PrPMC readout code version: %i \n", [model getSBCCodeVersion]);
	    NSLogFont(aFont,@"SBC PrPMC is using DMA lib (0=no/1=yes): %i \n", [model getSltkGetIsLinkedWithPCIDMALib]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT status\n");
        ORRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
	
	[self hwVersionAction: self]; //display SLT firmware version, fdhwlib ver, SLT PCI driver ver
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORKatrinV4SLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) selectRegisterAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[model undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
		[self settingsLockChanged:nil];
    }
}

- (IBAction) writeValueAction:(id) aSender
{
	[self endEditing];
    if ([aSender intValue] != [model writeValue]){
		[[model undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) readRegAction: (id) sender
{
	int index = [registerPopUp indexOfSelectedItem];
	@try {
		unsigned long value = [model readReg:index];
		NSLog(@"SLT reg: %@ value: 0x%x (%u)\n",[model getRegisterName:index],value,value);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT reg: %@\n",[model getRegisterName:index]);
        ORRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}
- (IBAction) writeRegAction: (id) sender
{
	[self endEditing];
	int index = [registerPopUp indexOfSelectedItem];
	@try {
		[model writeReg:index value:[model writeValue]];
		NSLog(@"wrote 0x%x to SLT reg: %@ \n",[model writeValue],[model getRegisterName:index]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception writing SLT reg: %@\n",[model getRegisterName:index]);
        ORRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) hwVersionAction: (id) sender
{
	@try {
		[model readHwVersion];
		NSLog(@"%@ Project:%d Doc:0x%x Implementation:0x%x\n",[model fullID], [model projectVersion], [model documentVersion], [model implementation]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT HW Model Version\n");
        ORRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

//most of these are not currently connected to anything.. used during testing..
- (IBAction) enableCountersAction:(id)sender          { [self do:@selector(writeEnCnt)              name:@"Enable Counters"];                   }
- (IBAction) disableCountersAction:(id)sender         { [self do:@selector(writeDisCnt)             name:@"Disable Counters"];                  }
- (IBAction) clearCountersAction:(id)sender           { [self do:@selector(writeClrCnt)             name:@"Clear Counters"];                    }
- (IBAction) activateSWRequestAction:(id)sender       { [self do:@selector(writeSwRq)               name:@"Active SW Request Interrupt"];       }
- (IBAction) configureFPGAsAction:(id)sender          { [self do:@selector(writeFwCfg)              name:@"Config FPGAs"];                      }
- (IBAction) tpStartAction:(id)sender                 { [self do:@selector(writeTpStart)            name:@"Test Pattern Start"];                }
- (IBAction) resetFLTAction:(id)sender                { [self do:@selector(writeFltReset)           name:@"FLT Reset"];                         }
- (IBAction) resetSLTAction:(id)sender                { [self do:@selector(writeSltReset)           name:@"SLT Reset"];                         }
- (IBAction) writeClrInhibitAction:(id)sender         { [self do:@selector(writeClrInhibit)         name:@"Clr Inhibit"];                       }
- (IBAction) writeSetInhibitAction:(id)sender         { [self do:@selector(writeSetInhibit)         name:@"Set Inhibit"];                       }
- (IBAction) clearAllStatusErrorBitsAction:(id)sender { [self do:@selector(clearAllStatusErrorBits) name:@"Clear All Status Error+Flag Bits"];  }

- (IBAction) sendCommandScript:(id)sender
{
	[self endEditing];
	NSString *fullCommand = [NSString stringWithFormat: @"shellcommand %@",[model sltScriptArguments]];
	[model sendPMCCommandScript: fullCommand];  
}

- (IBAction) sendSimulationConfigScriptON:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"This will KILL the crate process before compiling and starting simulation mode. \nThere may be other ORCAs connected to the crate. You need to do a 'Force reload' before."];
    [alert setInformativeText:@"Is this really what you want?"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Yes, Kill Crate"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertSecondButtonReturn){
            [[model sbcLink] killCrate]; //XCode says "No '-killCrate' method found!" but it is found during runtime!! -tb- How to get rid of this warning?
            BOOL rememberState = [[model sbcLink] forceReload];
            if(rememberState) [[model sbcLink] setForceReload: NO];
            [model sendSimulationConfigScriptON];
            if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];
        }
    }];
#else
    NSBeginAlertSheet(@"This will KILL the crate process before compiling and starting simulation mode. \nThere may be other ORCAs connected to the crate. You need to do a 'Force reload' before.",
                      @"Cancel",
                      @"Yes, Kill Crate",
                      nil,[self window],
                      self,
                      @selector(_SLTv4killCrateAndStartSimDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Is this really what you want?");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _SLTv4killCrateAndStartSimDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){
		[[model sbcLink] killCrate]; //XCode says "No '-killCrate' method found!" but it is found during runtime!! -tb- How to get rid of this warning?
		BOOL rememberState = [[model sbcLink] forceReload];
		if(rememberState) [[model sbcLink] setForceReload: NO];
		[model sendSimulationConfigScriptON];  
		if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];
	}
}
#endif

- (IBAction) sendSimulationConfigScriptOFF:(id)sender
{
	[model sendSimulationConfigScriptOFF];  
	NSLog(@"Sending simulation-mode-off script is still under development. If it fails just stop and force-reload-start the crate.\n");
}

- (IBAction) sendLinkWithDmaLibConfigScriptON:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"This will KILL the crate process before compiling and starting using DMA mode. \nThere may be other ORCAs connected to the crate. You need to do a 'Force reload' before."];
    [alert setInformativeText:@"Is this really what you want?"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Yes, Kill Crate"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertSecondButtonReturn){
            [[model sbcLink] killCrate]; //XCode says "No '-killCrate' method found!" but it is found during runtime!! -tb- How to get rid of this warning?
            BOOL rememberState = [[model sbcLink] forceReload];
            if(rememberState) [[model sbcLink] setForceReload: NO];
            [model sendLinkWithDmaLibConfigScriptON];  //this is not blocking but the script will run for several seconds so all subsequent commands shouldn't rely on the script! -tb-
             if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];
        }
    }];
#else
    //[self killCrateAction: nil];//TODO: this seems not to be modal ??? -tb- 2010-04-27
    NSBeginAlertSheet(@"This will KILL the crate process before compiling and starting using DMA mode. "
						"There may be other ORCAs connected to the crate. You need to do a 'Force reload' before.",
                      @"Cancel",
                      @"Yes, Kill Crate",
                      nil,[self window],
                      self,
                      @selector(_SLTv4killCrateAndStartLinkWithDMADidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Is this really what you want?");
#endif
}

- (void) _SLTv4killCrateAndStartLinkWithDMADidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
//NSLog(@"This is my _killCrateDidEnd: -tb-\n");
	//called
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    if(returnCode == NSAlertFirstButtonReturn){
#else
    if(returnCode == NSAlertAlternateReturn){
#endif
		[[model sbcLink] killCrate]; //XCode says "No '-killCrate' method found!" but it is found during runtime!! -tb- How to get rid of this warning?
		BOOL rememberState = [[model sbcLink] forceReload];
		if(rememberState) [[model sbcLink] setForceReload: NO];
		[model sendLinkWithDmaLibConfigScriptON];  //this is not blocking but the script will run for several seconds so all subsequent commands shouldn't rely on the script! -tb-
		if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];
	}
}


- (IBAction) sendLinkWithDmaLibConfigScriptOFF:(id)sender
{

#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"This will KILL the crate process before compiling and starting using DMA mode. \nThere may be other ORCAs connected to the crate. You need to do a 'Force reload' before."];
    [alert setInformativeText:@"Is this really what you want?"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Yes, Kill Crate"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertSecondButtonReturn){
            [[model sbcLink] killCrate]; //XCode says "No '-killCrate' method found!" but it is found during runtime!! -tb- How to get rid of this warning?
            BOOL rememberState = [[model sbcLink] forceReload];
            if(rememberState) [[model sbcLink] setForceReload: NO];
            [model sendLinkWithDmaLibConfigScriptOFF];
            //[self connectionAction: nil];
            //[self toggleCrateAction: nil];
            //[[model sbcLink] startCrate]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
            //   [[model sbcLink] startCrateProcess]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
            //[[model sbcLink] startCrate];
            if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];
        }
    }];
#else
    //[self killCrateAction: nil];//TODO: this seems not to be modal ??? -tb- 2010-04-27
    NSBeginAlertSheet(@"This will KILL the crate process before compiling and starting without DMA mode. "
						"There may be other ORCAs connected to the crate. You need to do a 'Force reload' before.",
                      @"Cancel",
                      @"Yes, Kill Crate",
                      nil,[self window],
                      self,
                      @selector(_SLTv4killCrateAndStartLinkWithoutDMADidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Is this really what you want?");
#endif
}

- (void) _SLTv4killCrateAndStartLinkWithoutDMADidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
	if(returnCode == NSAlertFirstButtonReturn){
#else
    if(returnCode == NSAlertAlternateReturn){
#endif
        [[model sbcLink] killCrate]; //XCode says "No '-killCrate' method found!" but it is found during runtime!! -tb- How to get rid of this warning?
		BOOL rememberState = [[model sbcLink] forceReload];
		if(rememberState) [[model sbcLink] setForceReload: NO];
	    [model sendLinkWithDmaLibConfigScriptOFF];  
		if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];
	}
}

- (IBAction) pulserAmpAction: (id) sender
{
	[model setPulserAmp:[sender floatValue]];
}

- (IBAction) pulserDelayAction: (id) sender
{
	[model setPulserDelay:[sender floatValue]];
}

- (IBAction) loadPulserAction: (id) sender
{
	@try {
		//[model loadPulserValues];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception loading SLT pulser values\n");
        ORRunAlertPanel([localException name], @"%@\nSLT%d load pulser failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) definePatternFileAction:(id)sender
{
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model patternFilePath]){
        startDir = [[model patternFilePath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Load Pattern File"];
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* fileName = [[openPanel URL] path];
            [model setPatternFilePath:fileName];
        }
    }];
}

- (IBAction) loadPatternFile:(id)sender
{
	//[model loadPatternFile];
}

- (IBAction) calibrateAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:      @"Threshold Calibration"];
    [alert setInformativeText:  @"Really run threshold calibration for ALL FLTs?\n This will change ALL thresholds on ALL cards."];
    [alert addButtonWithTitle:  @"Yes/Do Calibrate"];
    [alert addButtonWithTitle:  @"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model autoCalibrate];
        }
    }];
#else    
    NSBeginAlertSheet(@"Threshold Calibration",
                      @"Cancel",
                      @"Yes/Do Calibrate",
                      nil,[self window],
                      self,
                      @selector(calibrationSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really run threshold calibration for ALL FLTs?\n This will change ALL thresholds on ALL cards.");
#endif
}


@end

@implementation ORKatrinV4SLTController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) calibrationSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
		@try {
			[model autoCalibrate];
		}
		@catch(NSException* localException) {
		}
    }    
}
#endif
    
- (void) do:(SEL)aSelector name:(NSString*)aName
{
	@try { 
		[model performSelector:aSelector]; 
		NSLog(@"SLT: Manual %@\n",aName);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception doing SLT %@\n",aName);
        ORRunAlertPanel([localException name], @"%@\nSLT%d %@ failed", @"OK", nil, nil,
                        localException,[model stationNumber],aName);
	}
}

@end


