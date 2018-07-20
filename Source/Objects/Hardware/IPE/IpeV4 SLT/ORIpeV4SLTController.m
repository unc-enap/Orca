//
//  ORIpeV4SLTController.m
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
#import "ORIpeV4SLTController.h"
#import "ORIpeV4SLTModel.h"
#import "TimedWorker.h"
#import "SBC_Link.h"

#define kFltNumberTriggerSources 5

NSString* fltV4TriggerSourceNames[2][kFltNumberTriggerSources] = {
{
	@"Software",
	@"Right",
	@"Left",
	@"Mirror",
	@"External",
},
{
	@"Software",
	@"N/A",
	@"N/A",
	@"Multiplicity",
	@"External",
}
};

@interface ORIpeV4SLTController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) calibrationSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
- (void) do:(SEL)aSelector name:(NSString*)aName;
@end

@implementation ORIpeV4SLTController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"IpeV4SLT"];
    
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
	controlSize			= NSMakeSize(555,640);
    statusSize			= NSMakeSize(555,480);
    lowLevelSize		= NSMakeSize(555,430);
    cpuManagementSize	= NSMakeSize(475,450);
    cpuTestsSize		= NSMakeSize(555,335);
	
	[[self window] setTitle:@"IPE-DAQ-V4 SLT"];	
	
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
                         name : ORIpeV4SLTModelHwVersionChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusRegChanged:)
                         name : ORIpeV4SLTModelStatusRegChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(controlRegChanged:)
                         name : ORIpeV4SLTModelControlRegChanged
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORIpeV4SLTSelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORIpeV4SLTWriteValueChanged
					   object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(pulserAmpChanged:)
                         name : ORIpeV4SLTPulserAmpChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pulserDelayChanged:)
                         name : ORIpeV4SLTPulserDelayChanged
                       object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : ORIpeV4SLTModelPageSizeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : ORIpeV4SLTModelDisplayEventLoopChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : ORIpeV4SLTModelDisplayTriggerChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interruptMaskChanged:)
                         name : ORIpeV4SLTModelInterruptMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(nextPageDelayChanged:)
                         name : ORIpeV4SLTModelNextPageDelayChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollRateChanged:)
                         name : TimedWorkerTimeIntervalChangedNotification
                       object : [model poller]];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollRunningChanged:)
                         name : TimedWorkerIsRunningChangedNotification
                       object : [model poller]];
	
    [notifyCenter addObserver : self
                     selector : @selector(patternFilePathChanged:)
                         name : ORIpeV4SLTModelPatternFilePathChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(secondsSetChanged:)
                         name : ORIpeV4SLTModelSecondsSetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(deadTimeChanged:)
                         name : ORIpeV4SLTModelDeadTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(vetoTimeChanged:)
                         name : ORIpeV4SLTModelVetoTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runTimeChanged:)
                         name : ORIpeV4SLTModelRunTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(clockTimeChanged:)
                         name : ORIpeV4SLTModelClockTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(countersEnabledChanged:)
                         name : ORIpeV4SLTModelCountersEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sltScriptArgumentsChanged:)
                         name : ORIpeV4SLTModelSltScriptArgumentsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(secondsSetInitWithHostChanged:)
                         name : ORIpeV4SLTModelSecondsSetInitWithHostChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(secondsSetSendToFLTsChanged:)
                         name : ORIpeV4SLTModelSecondsSetSendToFLTsChanged
						object: model];

}

#pragma mark •••Interface Management

- (void) secondsSetSendToFLTsChanged:(NSNotification*)aNote
{
    //NSLog(@"Called %@::%@\n  secondsSetSendToFLTs is %i",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model secondsSetSendToFLTs]);//DEBUG -tb-
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
	[[countersMatrix cellWithTag:3] setIntegerValue:[model clockTime]];
}

- (void) runTimeChanged:(NSNotification*)aNote
{
	//[[countersMatrix cellWithTag:2] setStringValue: [NSString stringWithFormat:@"%llu",(uint64_t)[model runTime]]];
	uint64_t t=[model runTime];
	[[countersMatrix cellWithTag:2] setStringValue: [NSString stringWithFormat:@"%llu",t]];
	//[[countersMatrix cellWithTag:2] setStringValue: [NSString stringWithFormat:@"%llu.%llu", (t>>32) & 0xffffffff, t & 0xffffffff]];
	//[[countersMatrix cellWithTag:2] setIntValue:  [model runTime]];
}

- (void) vetoTimeChanged:(NSNotification*)aNote
{
	uint64_t t=[model vetoTime];
	[[countersMatrix cellWithTag:1] setStringValue: [NSString stringWithFormat:@"%llu",t]];
	//[[countersMatrix cellWithTag:1] setStringValue: [NSString stringWithFormat:@"%llu.%llu", (t>>32) & 0xffffffff, t & 0xffffffff]];
	//[[countersMatrix cellWithTag:1] setIntValue:[model vetoTime]];
}

- (void) deadTimeChanged:(NSNotification*)aNote
{
	uint64_t t=[model deadTime];
	[[countersMatrix cellWithTag:0] setStringValue: [NSString stringWithFormat:@"%llu",t]];
	//[[countersMatrix cellWithTag:0] setStringValue: [NSString stringWithFormat:@"%llu.%llu", (t>>32) & 0xffffffff, t & 0xffffffff]];
	//[[countersMatrix cellWithTag:0] setIntValue:[model deadTime]];
}

- (void) secondsSetChanged:(NSNotification*)aNote
{
	[secondsSetField setIntegerValue: [model secondsSet]];
}

- (void) statusRegChanged:(NSNotification*)aNote
{
	uint32_t statusReg = [model statusReg];
	[[statusMatrix cellWithTag:0] setStringValue: IsBitSet(statusReg,kStatusFltRq)?@"ERR":@"OK"];
	[[statusMatrix cellWithTag:1] setStringValue: IsBitSet(statusReg,kStatusWDog)?@"ERR":@"OK"];
	[[statusMatrix cellWithTag:2] setStringValue: IsBitSet(statusReg,kStatusPixErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:3] setStringValue: IsBitSet(statusReg,kStatusPpsErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:4] setStringValue: [NSString stringWithFormat:@"0x%02x",ExtractValue(statusReg,kStatusClkErr,4)]];
	[[statusMatrix cellWithTag:5] setStringValue: IsBitSet(statusReg,kStatusGpsErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:6] setStringValue: IsBitSet(statusReg,kStatusVttErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:7] setStringValue: IsBitSet(statusReg,kStatusFanErr)?@"ERR":@"OK"]; 

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
    if(aNotification== nil || [aNotification object] == [model poller]){
        [pollRatePopup selectItemAtIndex:[pollRatePopup indexOfItemWithTag:[[model poller] timeInterval]]];
    }
}

- (void) pollRunningChanged:(NSNotification*)aNotification
{
    if(aNotification== nil || [aNotification object] == [model poller]){
        if([[model poller] isRunning])[pollRunningIndicator startAnimation:self];
        else [pollRunningIndicator stopAnimation:self];
    }
}

- (void) nextPageDelayChanged:(NSNotification*)aNote
{
	[nextPageDelaySlider setIntegerValue:100-[model nextPageDelay]];
	[nextPageDelayField  setFloatValue:[model nextPageDelay]*102.3/100.];
}

- (void) interruptMaskChanged:(NSNotification*)aNote
{
	uint32_t aMaskValue = [model interruptMask];
	int i;
	for(i=0;i<16;i++){
		if(aMaskValue & (1L<<i))[[interruptMaskMatrix cellWithTag:i] setIntValue:1];
		else [[interruptMaskMatrix cellWithTag:i] setIntValue:0];
	}
}

- (void) pageSizeChanged:(NSNotification*)aNote
{
	[pageSizeField setIntegerValue: [model pageSize]];
	[pageSizeStepper setIntegerValue: [model pageSize]];
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
	[self pageSizeChanged:nil];	
	[self displayEventLoopChanged:nil];	
	[self displayTriggerChanged:nil];	
	[self interruptMaskChanged:nil];
	[self nextPageDelayChanged:nil];
    [self pollRateChanged:nil];
    [self pollRunningChanged:nil];
	[self patternFilePathChanged:nil];
	[self statusRegChanged:nil];
	[self secondsSetChanged:nil];
	[self deadTimeChanged:nil];
	[self vetoTimeChanged:nil];
	[self runTimeChanged:nil];
	[self clockTimeChanged:nil];
	[self countersEnabledChanged:nil];
	[self sltScriptArgumentsChanged:nil];
	[self secondsSetInitWithHostChanged:nil];
	[self secondsSetSendToFLTsChanged:nil];
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
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORIpeV4SLTSettingsLock];
    BOOL locked = [gSecurity isLocked:ORIpeV4SLTSettingsLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
	
	
	[triggerEnableMatrix setEnabled:!lockedOrRunningMaintenance]; 
    [inhibitEnableMatrix setEnabled:!lockedOrRunningMaintenance];
	[hwVersionButton setEnabled:!isRunning];
	[enableDisableCountersMatrix setEnabled:!isRunning];

	[loadPatternFileButton setEnabled:!lockedOrRunningMaintenance];
	[definePatternFileButton setEnabled:!lockedOrRunningMaintenance];
	[setSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[relSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[resetPageManagerButton setEnabled:!lockedOrRunningMaintenance];
	[forceTriggerButton setEnabled:!lockedOrRunningMaintenance];
	[initBoardButton setEnabled:!lockedOrRunningMaintenance];
	[initBoard1Button setEnabled:!lockedOrRunningMaintenance];
	[readBoardButton setEnabled:!lockedOrRunningMaintenance];
	[secStrobeSrcPU setEnabled:!lockedOrRunningMaintenance]; 
	
	[setSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[relSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[forceTrigger1Button setEnabled:!lockedOrRunningMaintenance];
    
	[clearAllStatusErrorBitsButton setEnabled:!lockedOrRunningMaintenance];

	[resetHWButton setEnabled:!isRunning];
	
	[pulserAmpField setEnabled:!locked];
		
	[pageSizeField setEnabled:!lockedOrRunningMaintenance];
	[pageSizeStepper setEnabled:!lockedOrRunningMaintenance];
	
	
	[nextPageDelaySlider setEnabled:!lockedOrRunningMaintenance];
	
	[self enableRegControls];
}

- (void) enableRegControls
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORIpeV4SLTSettingsLock];
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
	NSString* s = [NSString stringWithFormat:@"%u 0x%x,0x%x",[model projectVersion],[model documentVersion],[model implementation]];
	[hwVersionField setStringValue:s];
}

- (void) writeValueChanged:(NSNotification*) aNote
{
	[self updateStepper:regWriteValueStepper setting:[model writeValue]];
	[regWriteValueTextField setIntegerValue:[model writeValue]];
}

- (void) displayEventLoopChanged:(NSNotification*) aNote
{
	[displayEventLoopButton setState:[model displayEventLoop]];
}

- (void) displayTriggerChanged:(NSNotification*) aNote
{
	[displayTriggerButton setState:[model displayTrigger]];
}


- (void) selectedRegIndexChanged:(NSNotification*) aNote
{
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerPopUp	 setting:index];
	
	[self enableRegControls];
}


- (void) controlRegChanged:(NSNotification*)aNote
{
	uint32_t value = [model controlReg];
	uint32_t aMask = (value & kCtrlTrgEnMask)>>kCtrlTrgEnShift;
	int i;
	for(i=0;i<6;i++)[[triggerEnableMatrix cellWithTag:i] setIntValue:aMask & (0x1<<i)];
	
	aMask = (value & kCtrlInhEnMask)>>kCtrlInhEnShift;
	for(i=0;i<4;i++)[[inhibitEnableMatrix cellWithTag:i] setIntValue:aMask & (0x1<<i)];
	
	aMask = (value & kCtrlTpEnMask)>>kCtrlTpEnEnShift;
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
	
	// Clear all the popup items.
    [registerPopUp removeAllItems];
    
	// Populate the register popup
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

- (IBAction) triggerEnableAction:(id)sender
{
	uint32_t aMask = 0;
	int i;
	for(i=0;i<6;i++){
		if([[triggerEnableMatrix cellWithTag:i] intValue]) aMask |= (1L<<i);
		else aMask &= ~(1L<<i);
	}
	uint32_t theRegValue = [model controlReg] & ~kCtrlTrgEnMask; 
	theRegValue |= (aMask<< kCtrlTrgEnShift);
	[model setControlReg:theRegValue];
}

- (IBAction) inhibitEnableAction:(id)sender;
{
	uint32_t aMask = 0;
	int i;
	for(i=0;i<4;i++){
		if([[inhibitEnableMatrix cellWithTag:i] intValue]) aMask |= (1L<<i);
		else aMask &= ~(1L<<i);
	}
	uint32_t theRegValue = [model controlReg] & ~kCtrlInhEnMask; 
	theRegValue |= (aMask<<kCtrlInhEnShift);
	[model setControlReg:theRegValue];
}

- (IBAction) testPatternEnableAction:(id)sender;
{
	uint32_t aMask       = (uint32_t)[[testPatternEnableMatrix selectedCell] tag];
	uint32_t theRegValue = [model controlReg] & ~kCtrlTpEnMask; 
	theRegValue |= (aMask<<kCtrlTpEnEnShift);
	[model setControlReg:theRegValue];
}

- (IBAction) miscCntrlBitsAction:(id)sender;
{
	uint32_t theRegValue = [model controlReg] & ~(kCtrlPPSMask | kCtrlShapeMask | kCtrlRunMask | kCtrlTstSltMask | kCtrlIntEnMask | kCtrlLedOffmask); 
	if([[miscCntrlBitsMatrix cellWithTag:0] intValue])	theRegValue |= kCtrlPPSMask;
	if([[miscCntrlBitsMatrix cellWithTag:1] intValue])	theRegValue |= kCtrlShapeMask;
	if([[miscCntrlBitsMatrix cellWithTag:2] intValue])	theRegValue |= kCtrlRunMask;
	if([[miscCntrlBitsMatrix cellWithTag:3] intValue])	theRegValue |= kCtrlTstSltMask;
	if([[miscCntrlBitsMatrix cellWithTag:4] intValue])	theRegValue |= kCtrlIntEnMask;
	if([[miscCntrlBitsMatrix cellWithTag:5] intValue])	theRegValue |= kCtrlLedOffmask;

	[model setControlReg:theRegValue];
}

//----------------------------------



- (IBAction) dumpPageStatus:(id)sender
{
	if([[NSApp currentEvent] clickCount] >=2){
		//int pageIndex = [sender selectedRow]*32 + [sender selectedColumn];
		@try {
			//[model dumpTriggerRAM:pageIndex];
		}
		@catch(NSException* localException) {
			NSLog(@"Exception doing SLT dump trigger RAM page\n");
			ORRunAlertPanel([localException name], @"%@\nSLT%d dump trigger RAM failed", @"OK", nil, nil,
							localException,[model stationNumber]);
		}
	}
}

- (IBAction) pollNowAction:(id)sender
{
	[model readAllStatus];
}

- (IBAction) pollRateAction:(id)sender
{
    [model setPollingInterval:[[pollRatePopup selectedItem] tag]];
}

- (IBAction) interruptMaskAction:(id)sender
{
	uint32_t aMaskValue = 0;
	int i;
	for(i=0;i<16;i++){
		if([[interruptMaskMatrix cellWithTag:i] intValue]) aMaskValue |= (1L<<i);
		else aMaskValue &= ~(1L<<i);
	}
	[model setInterruptMask:aMaskValue];	
}

- (IBAction) nextPageDelayAction:(id)sender
{
	[model setNextPageDelay:100-[sender intValue]];	
}

- (IBAction) pageSizeAction:(id)sender
{
	[model setPageSize:[sender intValue]];	
}

- (IBAction) displayTriggerAction:(id)sender
{
	[model setDisplayTrigger:[sender intValue]];	
}


- (IBAction) displayEventLoopAction:(id)sender
{
	[model setDisplayEventLoop:[sender intValue]];	
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
		NSLogFont(aFont,@"Dead Time  : %lld\n",[model readDeadTime]);
		NSLogFont(aFont,@"Veto Time  : %lld\n",[model readVetoTime]);
		NSLogFont(aFont,@"Run Time   : %lld\n",[model readRunTime]);
		NSLogFont(aFont,@"Seconds    : %d\n",  [model getSeconds]);
		[model printInterruptMask];
		[model printInterruptRequests];
	    int32_t fdhwlibVersion = [model getFdhwlibVersion];  //TODO: write a method [model printFdhwlibVersion];
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
    [gSecurity tryToSetLock:ORIpeV4SLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) selectRegisterAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[model undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
		[self settingsLockChanged:nil];
    }
}

- (IBAction) writeValueAction:(id) aSender
{
	[self endEditing];
    // Make sure that value has changed.
    if ([aSender intValue] != [model writeValue]){
		[[model undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) readRegAction: (id) sender
{
	int index = (int)[registerPopUp indexOfSelectedItem];
	@try {
		uint32_t value = [model readReg:index];
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
	int index = (int)[registerPopUp indexOfSelectedItem];
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
		//NSLog(@"%@ Project:%d Doc:%d Implementation:%d\n",[model fullID], [model projectVersion], [model documentVersion], [model implementation]);
		NSLog(@"%@ Project:%d Doc:0x%x Implementation:0x%x\n",[model fullID], [model projectVersion], [model documentVersion], [model implementation]);
		int32_t fdhwlibVersion = [model getFdhwlibVersion];
		int ver=(fdhwlibVersion>>16) & 0xff,maj =(fdhwlibVersion>>8) & 0xff,min = fdhwlibVersion & 0xff;
	    NSLog(@"%@: SBC PrPMC running with fdhwlib version: %i.%i.%i (0x%08x)\n",[model fullID],ver,maj,min, fdhwlibVersion);
		int32_t SltPciDriverVersion = [model getSltPciDriverVersion];
		//NSLog(@"%@: SLT PCI driver version: %i\n",[model fullID],SltPciDriverVersion);
	    if(SltPciDriverVersion<0) NSLog(@"%@: unknown SLT PCI driver version: %i\n",[model fullID],SltPciDriverVersion);
        else if(SltPciDriverVersion==0) NSLog(@"%@: SBC running with SLT PCI driver version: %i (fzk_ipe_slt)\n",[model fullID],SltPciDriverVersion);
        else if(SltPciDriverVersion==1) NSLog(@"%@: SBC running with SLT PCI driver version: %i (fzk_ipe_slt_dma)\n",[model fullID],SltPciDriverVersion);
        else NSLog(@"%@: SBC running with SLT PCI driver version: %i (fzk_ipe_slt%i)\n",[model fullID],SltPciDriverVersion,SltPciDriverVersion);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT HW Model Version\n");
        ORRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

//most of these are not currently connected to anything.. used during testing..
- (IBAction) enableCountersAction:(id)sender	{ [self do:@selector(writeEnCnt) name:@"Enable Counters"]; }
- (IBAction) disableCountersAction:(id)sender	{ [self do:@selector(writeDisCnt) name:@"Disable Counters"]; }
- (IBAction) clearCountersAction:(id)sender		{ [self do:@selector(writeClrCnt) name:@"Clear Counters"]; }
- (IBAction) activateSWRequestAction:(id)sender	{ [self do:@selector(writeSwRq) name:@"Active SW Request Interrupt"]; }
- (IBAction) configureFPGAsAction:(id)sender	{ [self do:@selector(writeFwCfg) name:@"Config FPGAs"]; }
- (IBAction) tpStartAction:(id)sender			{ [self do:@selector(writeTpStart) name:@"Test Pattern Start"]; }
- (IBAction) resetFLTAction:(id)sender			{ [self do:@selector(writeFltReset) name:@"FLT Reset"]; }
- (IBAction) resetSLTAction:(id)sender			{ [self do:@selector(writeSltReset) name:@"SLT Reset"]; }
- (IBAction) writeClrInhibitAction:(id)sender	{ [self do:@selector(writeClrInhibit) name:@"Clr Inhibit"]; }
- (IBAction) writeSetInhibitAction:(id)sender	{ [self do:@selector(writeSetInhibit) name:@"Set Inhibit"]; }
- (IBAction) resetPageManagerAction:(id)sender	{ [self do:@selector(writePageManagerReset) name:@"Reset Page Manager"]; }
- (IBAction) releaseAllPagesAction:(id)sender	{ [self do:@selector(writeReleasePage) name:@"Release Pages"]; }

- (IBAction) clearAllStatusErrorBitsAction:(id)sender		{ [self do:@selector(clearAllStatusErrorBits) name:@"Clear All Status Error+Flag Bits"]; }

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
    [alert setMessageText:@"This will KILL the crate process before compiling and starting simulation mode. "];
    [alert setInformativeText:@"Is this really what you want?"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Yes, Kill Crate"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertSecondButtonReturn){
            [[model sbcLink] killCrate]; //XCode says "No '-killCrate' method found!" but it is found during runtime!! -tb- How to get rid of this warning?
            BOOL rememberState = [[model sbcLink] forceReload];
            if(rememberState) [[model sbcLink] setForceReload: NO];
            [model sendSimulationConfigScriptON];
            //[self connectionAction: nil];
            //[self toggleCrateAction: nil];
            //[[model sbcLink] startCrate]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
            //   [[model sbcLink] startCrateProcess]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
            //[[model sbcLink] startCrate];
            if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];       }
    }];
#else
    NSBeginAlertSheet(@"This will KILL the crate process before compiling and starting simulation mode. "
						"There may be other ORCAs connected to the crate. You need to do a 'Force reload' before.",
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
		//[self connectionAction: nil];
		//[self toggleCrateAction: nil];
		//[[model sbcLink] startCrate]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
		//   [[model sbcLink] startCrateProcess]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
		//[[model sbcLink] startCrate];
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
	//[self killCrateAction: nil];//TODO: this seems not to be modal ??? -tb- 2010-04-27
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"This will KILL the crate process before compiling and starting using DMA mode. "
     "There may be other ORCAs connected to the crate. You need to do a 'Force reload' before."];
    [alert setInformativeText:@"Is this really what you want?"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Yes, Kill Crate"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertSecondButtonReturn){
            [[model sbcLink] killCrate];
            BOOL rememberState = [[model sbcLink] forceReload];
            if(rememberState) [[model sbcLink] setForceReload: NO];
            [model sendLinkWithDmaLibConfigScriptON];  //this is not blocking but the script will run for several seconds so all subsequent commands shouldn't rely on the script! -tb-
            //[self connectionAction: nil];
            //[self toggleCrateAction: nil];
            //[[model sbcLink] startCrate]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
            //   [[model sbcLink] startCrateProcess]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
            //[[model sbcLink] startCrate];
            if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];
       }
    }];
#else
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

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _SLTv4killCrateAndStartLinkWithDMADidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
//NSLog(@"This is my _killCrateDidEnd: -tb-\n");
	//called
	if(returnCode == NSAlertAlternateReturn){		
		[[model sbcLink] killCrate]; //XCode says "No '-killCrate' method found!" but it is found during runtime!! -tb- How to get rid of this warning?
		BOOL rememberState = [[model sbcLink] forceReload];
		if(rememberState) [[model sbcLink] setForceReload: NO];
		//if(rememberState) [[model sbcLink] reloadClient];
		//sleep(2);
		[model sendLinkWithDmaLibConfigScriptON];  //this is not blocking but the script will run for several seconds so all subsequent commands shouldn't rely on the script! -tb-
		//[self connectionAction: nil];
		//[self toggleCrateAction: nil];
		//[[model sbcLink] startCrate]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
		//   [[model sbcLink] startCrateProcess]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
		//[[model sbcLink] startCrate];
		if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];
	}
}
#endif

- (IBAction) sendLinkWithDmaLibConfigScriptOFF:(id)sender
{
#if 0
  //TODO: in fact I would like to run the script and recompile the code without reload; but I did not mane it up to now -tb-
	[model sendLinkWithDmaLibConfigScriptOFF];  
	NSLog(@"Sending link-with-dma-lib script is still under development. If it fails just stop and force-reload-start the crate.\n");
#else
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"This will KILL the crate process before compiling and starting without DMA mode. \nThere may be other ORCAs connected to the crate. You need to do a 'Force reload' before."];
    [alert setInformativeText:@"Is this really what you want?"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Yes, Kill Crate"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
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
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _SLTv4killCrateAndStartLinkWithoutDMADidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
//NSLog(@"This is my _killCrateDidEnd: -tb-\n");
	//called
	if(returnCode == NSAlertAlternateReturn){		
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
}

#endif



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
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Threshold Calibration"];
    [alert setInformativeText:@"Really run threshold calibration for ALL FLTs?\n This will change ALL thresholds on ALL cards."];
    [alert addButtonWithTitle:@"Yes/Do Calibrate"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
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

@implementation ORIpeV4SLTController (private)
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


