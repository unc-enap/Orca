//--------------------------------------------------------------------------------
//ORCV977Controller.m
//Mark A. Howe 20013-09-26
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
#import "ORCV977Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCV977Model.h"
#import "ORGlobal.h"

@implementation ORCV977Controller
#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"CV977" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    lowLevelOpsSize   = NSMakeSize(280,400);
    basicOpsSize      = NSMakeSize(565,370);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
    
    [registerAddressPopUp setAlignment:NSTextAlignmentCenter];
	
    [self populatePullDown];

    
	int i;
	for(i=0;i<16;i++){
		[[inputSetMatrix cellAtRow:0 column:i] setTag:15-i];
		[[inputMaskMatrix cellAtRow:0 column:i] setTag:15-i];
		[[outputSetMatrix cellAtRow:0 column:i] setTag:15-i];
		[[outputMaskMatrix cellAtRow:0 column:i] setTag:15-i];
		[[interruptMaskMatrix cellAtRow:0 column:i] setTag:15-i];
	}
	[super awakeFromNib];
    
    NSString* key = [NSString stringWithFormat: @"orca.ORCaen977%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [ super registerNotificationObservers ];
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

	[notifyCenter addObserver : self
					 selector : @selector(inputSetChanged:)
						 name : ORCV977ModelInputSetChanged
					   object : model];
 
    [notifyCenter addObserver : self
					 selector : @selector(inputMaskChanged:)
						 name : ORCV977ModelInputMaskChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(outputSetChanged:)
						 name : ORCV977ModelOutputSetChanged
					   object : model];
    
    [notifyCenter addObserver : self
					 selector : @selector(outputMaskChanged:)
						 name : ORCV977ModelOutputMaskChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(interruptMaskChanged:)
						 name : ORCV977ModelInterruptMaskChanged
					   object : model];
    
    [notifyCenter addObserver:self
					 selector:@selector(baseAddressChanged:)
						 name:ORVmeIOCardBaseAddressChangedNotification
					   object:model];
	
    [notifyCenter addObserver:self
					 selector:@selector(selectedRegIndexChanged:)
						 name:caenSelectedRegIndexChanged
					   object:model];
	
    [notifyCenter addObserver:self
					 selector:@selector(selectedRegChannelChanged:)
						 name:caenSelectedChannelChanged
					   object:model];
	
    [notifyCenter addObserver:self
					 selector:@selector(writeValueChanged:)
						 name:caenWriteValueChanged
					   object:model];
	
    [notifyCenter addObserver : self
                     selector : @selector(basicOpsLockChanged:)
                         name : ORCV977BasicOpsLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lowLevelLockChanged:)
                         name : ORCV977LowLevelOpsLock
						object: nil];

	[notifyCenter addObserver : self
					 selector : @selector(lowLevelLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(basicOpsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
    [notifyCenter addObserver : self
                     selector : @selector(patternBitChanged:)
                         name : ORCV977ModelPatternBitChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(gateMaskBitChanged:)
                         name : ORCV977ModelGateMaskBitChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(orMaskBitChanged:)
                         name : ORCV977ModelOrMaskBitChanged
						object: model];

}

#pragma mark ***Interface Management

- (void) orMaskBitChanged:(NSNotification*)aNote
{
	[orMaskBitPU selectItemAtIndex: [model orMaskBit]];
}

- (void) gateMaskBitChanged:(NSNotification*)aNote
{
	[gateMaskBitPU selectItemAtIndex: [model gateMaskBit]];
}

- (void) patternBitChanged:(NSNotification*)aNote
{
	[patternBitPU selectItemAtIndex: [model patternBit]];
}

- (void) updateWindow
{
    [super updateWindow ];
	[self inputSetChanged:nil];
	[self inputMaskChanged:nil];
	[self outputSetChanged:nil];
	[self outputMaskChanged:nil];
	[self interruptMaskChanged:nil];
    [self baseAddressChanged:nil];
    [self writeValueChanged:nil];
    [self selectedRegIndexChanged:nil];
    [self basicOpsLockChanged:nil];
    [self lowLevelLockChanged:nil];
    [self slotChanged:nil];
	[self patternBitChanged:nil];
	[self gateMaskBitChanged:nil];
	[self orMaskBitChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORCV977LowLevelOpsLock to:secure];
    [gSecurity setLock:ORCV977BasicOpsLock to:secure];
    
    [basicOpsLockButton setEnabled:secure];
    [lowLevelOpsLockButton setEnabled:secure];
}


#pragma mark ***Interface Management - Module specific
- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) inputSetChanged:(NSNotification*)aNotification
{
	short i;
	uint32_t theMask = [model inputSet];
	for(i=0;i<16;i++){
		[[inputSetMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
    [inputSetField setIntegerValue:theMask];
}

- (void) inputMaskChanged:(NSNotification*)aNotification
{
	short i;
	uint32_t theMask = [model inputMask];
	for(i=0;i<16;i++){
		[[inputMaskMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
    [inputMaskField setIntegerValue:theMask];
}

- (void) outputSetChanged:(NSNotification*)aNotification
{
	short i;
	uint32_t theMask = [model outputSet];
	for(i=0;i<16;i++){
		[[outputSetMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
    [outputSetField setIntegerValue:theMask];
}

- (void) outputMaskChanged:(NSNotification*)aNotification
{
	short i;
	uint32_t theMask = [model outputMask];
	for(i=0;i<16;i++){
		[[outputMaskMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
    [outputMaskField setIntegerValue:theMask];
}

- (void) interruptMaskChanged:(NSNotification*)aNotification
{
	short i;
	uint32_t theMask = [model interruptMask];
	for(i=0;i<16;i++){
		[[interruptMaskMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
    [interruptMaskField setIntegerValue:theMask];
}

- (void) lowLevelLockChanged:(NSNotification*)aNotification
{
    //BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCV977LowLevelOpsLock];
    BOOL locked = [gSecurity isLocked:ORCV977LowLevelOpsLock];
    [lowLevelOpsLockButton setState: locked];
    	
    [writeValueTextField setEnabled:!lockedOrRunningMaintenance];
    [registerAddressPopUp setEnabled:!lockedOrRunningMaintenance];
	[inputSetMatrix setEnabled:!lockedOrRunningMaintenance];
	[inputMaskMatrix setEnabled:!lockedOrRunningMaintenance];
	
    [basicWriteButton setEnabled:!lockedOrRunningMaintenance];
    [basicReadButton setEnabled:!lockedOrRunningMaintenance];
}

- (void) basicOpsLockChanged:(NSNotification*)aNotification
{
    //BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCV977BasicOpsLock];
    BOOL locked = [gSecurity isLocked:ORCV977BasicOpsLock];
    [basicOpsLockButton         setState: locked];
	[clearOutputRegButton       setEnabled:!lockedOrRunningMaintenance];
	[clearSingleHitRegButton    setEnabled:!lockedOrRunningMaintenance];
	[clearMultiHitRegButton     setEnabled:!lockedOrRunningMaintenance];
}

- (void) baseAddressChanged:(NSNotification*) aNotification
{
	[addressTextField setDoubleValue:[model baseAddress]];
}
- (void) writeValueChanged:(NSNotification*) aNotification
{
	[writeValueTextField setIntegerValue:[model writeValue]];
}
- (void) selectedRegIndexChanged:(NSNotification*) aNotification
{
	//  Set value of popup
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerAddressPopUp setting:index];
	[self updateRegisterDescription:index];
	
	
	BOOL readAllowed = [model getAccessType:index] == kReadOnly || [model getAccessType:index] == kReadWrite;
	BOOL writeAllowed = [model getAccessType:index] == kWriteOnly || [model getAccessType:index] == kReadWrite;
	
	[basicWriteButton setEnabled:writeAllowed];
	[basicReadButton setEnabled:readAllowed];
}

#pragma mark •••Actions

- (IBAction) orMaskBitAction:(id)sender
{
	[model setOrMaskBit:[sender indexOfSelectedItem]];
}

- (IBAction) gateMaskBitAction:(id)sender
{
	[model setGateMaskBit:[sender indexOfSelectedItem]];	
}

- (IBAction) patternBitAction:(id)sender
{
	[model setPatternBit:[sender indexOfSelectedItem]];	
}

- (IBAction) baseAddressAction:(id) aSender
{
	[model setBaseAddress:[aSender doubleValue]]; // set new value.
}

- (IBAction) writeValueAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender intValue] != [model writeValue]){
		[[[model document] undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}
- (IBAction) selectRegisterAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[[model document] undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
    }
}
- (IBAction) read:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model read];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nRead of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    }
}
- (IBAction) write:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model write];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nWrite to %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    }
}

- (IBAction) settingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCV977BasicOpsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) lowLevelLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCV977LowLevelOpsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) inputSetAction:(id)sender
{
	[model setInputSetBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) inputMaskAction:(id)sender
{
	[model setInputMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) outputSetAction:(id)sender
{
	[model setOutputSetBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) outputMaskAction:(id)sender
{
	[model setOutputMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) interruptMaskAction:(id)sender
{
	[model setInterruptMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) clearOutputRegisterAction:(id)sender
{
    @try {
		[self endEditing];
		[model clearOutputRegister];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nClear Output Reg of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:kClearOutput]);
    }
}

- (IBAction) clearSingleHitRegisterAction:(id)sender
{
    @try {
		[self endEditing];
		[model clearSingleHitRegister];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nClear Single Hit Reg of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:kSinglehitReadClear]);
    }
  
}
- (IBAction) clearMultiHitRegisterAction:(id)sender
{
    @try {
		[self endEditing];
		[model clearMultiHitRegister];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nClear Multi Hit Reg of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:kMultihitReadClear]);
    }
}
- (IBAction) initBoardAction:(id)sender
{
    @try {
		[self endEditing];
		[model initBoard];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nInit failed", @"OK", nil, nil,
                        localException);
    }
 
}
- (IBAction) resetAction:(id)sender
{
    @try {
		[model reset];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nReset of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:kSoftwareReset]);
    }
 
}


#pragma mark •••Helpers
- (void) populatePullDown
{
    short	i;
	
    [registerAddressPopUp removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
    
    [self selectedRegIndexChanged:nil];
}

- (void) updateRegisterDescription:(short) aRegisterIndex
{
    NSString* types[] = {
		@"[ReadOnly]",
		@"[WriteOnly]",
		@"[ReadWrite]"
    };
	
    [registerOffsetTextField setStringValue:
	 [NSString stringWithFormat:@"0x%04x",
	  [model getAddressOffset:aRegisterIndex]]];
	
    [registerReadWriteTextField setStringValue:types[[model getAccessType:aRegisterIndex]]];
    [regNameField setStringValue:[model getRegisterName:aRegisterIndex]];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:lowLevelOpsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicOpsSize];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORCaen977%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
}
@end
