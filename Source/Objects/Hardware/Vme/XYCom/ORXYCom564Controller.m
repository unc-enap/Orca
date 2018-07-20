//-------------------------------------------------------------------------
//  ORXYCom564Controller.h
//
//  Created by Michael G. Marino on 10/21/1011
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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


#define kXVME564ChannelKey	@"Chan"

#pragma mark ***Imported Files
#import "ORXYCom564Controller.h"


@interface ORXYCom564Controller (private)
- (NSString*) stringOfADCValue:(double)aVal withFormat:(EInterpretXy564ADC)interpret;
- (void) _updateButtons;
@end

@implementation ORXYCom564Controller

-(id)init
{
    self = [super initWithWindowNibName:@"XYCom564"];
	
    return self;
}

- (void) dealloc
{
	[blankView release];    
	[super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    settingsSize       = NSMakeSize(400,570);
    gainsSize          = NSMakeSize(480,580);
    channelReadoutSize = NSMakeSize(580,500);
    
    blankView = [[NSView alloc] init];
    
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];    
    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3302%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];   

	
    [registerAddressPopUp setAlignment:NSTextAlignmentCenter];
	
    [self populatePopups];
	
	[self modelChanged:nil];
	
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(baseAddressChanged:)
                         name : ORVmeIOCardBaseAddressChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORXYCom564Lock
                        object: nil];
    
    [notifyCenter addObserver:self
					 selector:@selector(readoutModeChanged:)
						 name:ORXYCom564ReadoutModeChanged
					   object:model]; 
    
    [notifyCenter addObserver:self
					 selector:@selector(operationModeChanged:)
						 name:ORXYCom564OperationModeChanged
					   object:model]; 	
    
    [notifyCenter addObserver:self
					 selector:@selector(autoscanModeChanged:)
						 name:ORXYCom564AutoscanModeChanged
					   object:model]; 
    
    [notifyCenter addObserver:self
					 selector:@selector(channelGainsChanged:)
						 name:ORXYCom564ChannelGainChanged
					   object:model];
    
    [notifyCenter addObserver:self
					 selector:@selector(displayRawChanged:)
						 name:ORXYCom564ADCValuesChanged
					   object:model];     
    
    [notifyCenter addObserver:self
					 selector:@selector(pollingActivityChanged:)
						 name:ORXYCom564PollingActivityChanged
					   object:model];         
    
    [notifyCenter addObserver:self
					 selector:@selector(shipRecordsChanged:)
						 name:ORXYCom564ShipRecordsChanged
					   object:model];  
    
    [notifyCenter addObserver:self
					 selector:@selector(averagingValueChanged:)
						 name:ORXYCom564AverageValueNumberHasChanged
					   object:model];
    
    [notifyCenter addObserver:self
					 selector:@selector(pollingSpeedChanged:)
						 name:ORXYCom564PollingSpeedHasChanged
					   object:model];
    
    [notifyCenter addObserver:self
					 selector:@selector(interpretADCChanged:)
						 name:ORXYCom564InterpretADCHasChanged
					   object:model];
}


- (void) updateWindow
{
    [super updateWindow];
    [self populatePopups];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self lockChanged:nil];
    [self readoutModeChanged:nil];
    [self operationModeChanged:nil];    
    [self channelGainsChanged:nil]; 
    [self displayRawChanged:nil];
    [self pollingActivityChanged:nil];
    [self shipRecordsChanged:nil];    
    [self autoscanModeChanged:nil]; 
    [self averagingValueChanged:nil];
    [self pollingSpeedChanged:nil];
    [self interpretADCChanged:nil];
}
#pragma mark •••Interface Management

- (void) modelChanged:(NSNotification*)aNotification
{    

}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORXYCom564Lock to:secure];
    [settingLockButton setEnabled:secure];
    [basicOpsLockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
	// BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORXYCom564Lock];
    BOOL locked = [gSecurity isLocked:ORXYCom564Lock];
	
    [settingLockButton setState: locked];
    [basicOpsLockButton setState: locked];
    [addressText setEnabled:!locked && !runInProgress];
	[initBoardButton setEnabled:!locked && !runInProgress];
    [self _updateButtons];
}

- (void) setModel:(id)aModel
{	
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"XYCom564 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"XYCom564 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntegerValue:[model baseAddress]];
}

- (void) readoutModeChanged:(NSNotification*) aNotification
{
	short index = [model readoutMode];
	[self updatePopUpButton:addressModifierPopUp setting:index];
}

- (void) operationModeChanged:(NSNotification*) aNotification
{
	short index = [model operationMode];
	[self updatePopUpButton:operationModePopUp setting:index];
    if ([model operationMode] != kAutoscanning) {
        [autoscanModePopUp setEnabled:NO];
    } else {
        [autoscanModePopUp setEnabled:YES];
        [self autoscanModeChanged:nil];
    }    
}

- (void) autoscanModeChanged:(NSNotification*) aNotification
{
	short index = [model autoscanMode];
	[self updatePopUpButton:autoscanModePopUp setting:index];
}

- (void) channelGainsChanged:(NSNotification *)aNotification
{

    NSInteger rows = [channelGainSettings numberOfRows];
	short index;
    for (index=0; index < [model getNumberOfChannels]; index++) {
        NSInteger currentColumn = index / rows;
        NSInteger currentRow = index % rows;    
        [[channelGainSettings cellAtRow:currentRow column:currentColumn] selectItemAtIndex:[model getGain:index]];
    }
	[self updatePopUpButton:autoscanModePopUp setting:index];
}

- (void) pollingActivityChanged:(NSNotification*)aNote
{
    [pollButton setEnabled:YES];
    [self _updateButtons];
    if ([model isPolling]) {
        [pollButton setTitle:@"Stop Polling"];
        [pollingIndicator startAnimation:self];
        [pollingText setHidden:NO];
    } else {
        [pollButton setTitle:@"Start Polling"];
        [pollingIndicator stopAnimation:self];
        [pollingText setHidden:YES];
    }
}

- (void) shipRecordsChanged:(NSNotification*)aNote
{
    [shipRecordsButton setState:[model shipRecords]];
}

- (void) displayRawChanged:(NSNotification*)aNote
{
    [adcCountsAndChannels reloadData];
}

- (void) averagingValueChanged:(NSNotification *)aNote
{
    [averagingValue setIntValue:[model averageValueNumber]];
}

- (void) pollingSpeedChanged:(NSNotification *)aNote
{
    NSTimeInterval atime = [model pollSpeed];
    if (atime == 0.0) {
        [pollingSpeed setStringValue:[NSString stringWithFormat:@"%.1f Hz",0.0]];
    } else {
        [pollingSpeed setStringValue:[NSString stringWithFormat:@"%.1f Hz",1./atime]];
    }
}

- (void) interpretADCChanged:(NSNotification *)aNote
{
    [interpretADCAsPopUp selectItemAtIndex:[model interpretADC]];
    [self displayRawChanged:aNote];
}

#pragma mark •••Actions

- (IBAction) initBoard:(id)sender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model initBoard];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"Init failed: %@", @"OK", nil, nil,
                        localException);
    }	
}

- (IBAction) resetBoard:(id)sender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model resetBoard];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"Reset failed: %@", @"OK", nil, nil,
                        localException);
    }	
}

- (IBAction) report:(id)sender
{
	@try {
		[model report];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"Report failed: %@", @"OK", nil, nil,
                        localException);
    }
}

-(IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORXYCom564Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) writeValueAction:(id) aSender
{
}

- (IBAction) selectReadoutModeAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model readoutMode]){
	    [[[model document] undoManager] setActionName:@"Readout Mode"]; // Set undo name
	    [model setReadoutMode:(int)[aSender indexOfSelectedItem]]; // set new value
    }
}

- (IBAction) selectRegisterAction:(id) aSender
{
    [self updateRegisterDescription:[aSender indexOfSelectedItem]];
}

- (IBAction) selectOperationModeAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model operationMode]){
	    [[[model document] undoManager] setActionName:@"Operation Mode"]; // Set undo name
	    [model setOperationMode:(int)[aSender indexOfSelectedItem]]; // set new value
    }    
}

- (IBAction) selectAutoscanModeAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model autoscanMode]){
	    [[[model document] undoManager] setActionName:@"Autoscan Mode"]; // Set undo name
	    [model setAutoscanMode:(int)[aSender indexOfSelectedItem]]; // set new value
    }    
}

- (IBAction) setOneChannelGain:(id)sender
{
    id cell = [sender selectedCell];
    NSInteger rows = [sender numberOfRows];
    short channel = rows*[sender selectedColumn] + [sender selectedRow];
    if ([cell indexOfSelectedItem] != [model getGain:channel]) {
        [[[model document] undoManager] setActionName:@"Channel Gain"]; // Set undo name
        [model setGain:(int)[cell indexOfSelectedItem] channel:channel];
    }
}

- (IBAction) setAllChannelGains:(id)sender
{
    [model setGain:(int)[setAllChannelGains indexOfSelectedItem]];
}

- (IBAction) read:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		uint8_t val = 0;
        [model read:&val atRegisterIndex:(int)[registerAddressPopUp indexOfSelectedItem]];
        [readbackField setStringValue:[NSString stringWithFormat:@"0x%02x",val]];
        
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nRead of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:(int)[registerAddressPopUp indexOfSelectedItem]]);
    }
}

- (IBAction) write:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		uint8_t val = [writeValueTextField intValue];
        [model write:val atRegisterIndex:(int)[registerAddressPopUp indexOfSelectedItem]];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nWrite to %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:(int)[registerAddressPopUp indexOfSelectedItem]]);
    }
}

- (IBAction) startPollingActivityAction:(id)sender
{
    [sender setEnabled:NO];
    if ([model isPolling]) {
        [model stopPollingActivity];
    } else {
        [model startPollingActivity];        
    }
}

- (IBAction) setShipRecordsAction:(id)sender
{
    [model setShipRecords:[sender state]];
}

- (IBAction) setAverageValueAction:(id)sender
{
    [model setAverageValueNumber:[sender intValue]];
}

- (IBAction) setInterpretADCAction:(id)sender
{
    [model setInterpretADC:(EInterpretXy564ADC)[interpretADCAsPopUp indexOfSelectedItem]];
}

- (IBAction) refreshADCValuesAction:(id)sender
{
    [self displayRawChanged:nil];
}

#pragma mark ***Misc Helpers
- (void) populatePopups
{
    [registerAddressPopUp removeAllItems];
    [operationModePopUp removeAllItems]; 
    [autoscanModePopUp removeAllItems];
    [setAllChannelGains removeAllItems];    
    short	i;
    short	j;    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp addItemWithTitle:[model getRegisterName:i]];
    }
    for (i = 0; i < [model getNumberOperationModes]; i++) {
        [operationModePopUp addItemWithTitle:[model getOperationModeName:i]];
    }    
    for (i = 0; i < [model getNumberAutoscanModes]; i++) {
        [autoscanModePopUp addItemWithTitle:[model getAutoscanModeName:i]];
    }        
    for (j=0;j< [model getNumberGainModes];j++) {
        [setAllChannelGains addItemWithTitle:[model getChannelGainName:j]];
    }    
    NSInteger columns;
    NSInteger rows;
    [channelLabels getNumberOfRows:&rows columns:&columns];
    [channelGainSettings setTabKeyTraversesCells:YES];
    assert(columns*rows >= [model getNumberOfChannels]);

    for (i=0;i < [model getNumberOfChannels];i++) {
        NSInteger currentColumn = i / rows;
        NSInteger currentRow = i % rows;
        id cell = [channelLabels cellAtRow:currentRow column:currentColumn];
        [cell setTag:i];
        [[channelLabels cellAtRow:currentRow column:currentColumn] setStringValue:[NSString stringWithFormat:@"%d:",i]];
        NSPopUpButtonCell* popCell = [channelGainSettings cellAtRow:currentRow column:currentColumn];
        [popCell setTag:i];
        [popCell removeAllItems];
        for (j=0;j< [model getNumberGainModes];j++) {
            [popCell addItemWithTitle:[model getChannelGainName:j]];
        }
    }
}

- (void) updateRegisterDescription:(short) aRegisterIndex
{
    [registerOffsetField setStringValue:[NSString stringWithFormat:@"0x%04x",[model getAddressOffset:aRegisterIndex]]];
	
    [regNameField setStringValue:[model getRegisterName:aRegisterIndex]];
	
    [readbackField setStringValue:@"N/A"];
}

#pragma mark •••Data Source
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    return YES;
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    rowIndex += [aTableView tag];
    NSInteger chan = [[aTableView tableColumns] indexOfObject:aTableColumn]/2;
    chan = rowIndex + chan*[self numberOfRowsInTableView:aTableView];  
	if([[aTableColumn identifier] hasPrefix:kXVME564ChannelKey]){
        return [NSString stringWithFormat:@"%u",(uint32_t)chan];
	} else {
        return [self stringOfADCValue:[model convertedValue:(int)chan] withFormat:[model interpretADC]];
    }
}


// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [model getNumberOfChannels]*2/[aTableView numberOfColumns];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingsSize];
		[[self window] setContentView:winView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:gainsSize];
		[[self window] setContentView:winView];
    }    
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:channelReadoutSize];
		[[self window] setContentView:winView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3302%d.selectedtab",[model slot]];
    NSUInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

@end

@implementation ORXYCom564Controller (private)

- (NSString*) stringOfADCValue:(double)aVal withFormat:(EInterpretXy564ADC)interpret
{

    switch (interpret) {
        case kRawADC:
            return [NSString stringWithFormat:@"%d",(int)aVal];
        case k0to5Volts:
        case k0to10Volts:
        case kPlusMinus5Volts:
        case kPlusMinus10Volts:
            return [NSString stringWithFormat:@"%4.3f",aVal];
        default:
            return @"";
    }
}

- (void) _updateButtons
{
    BOOL isUserLocked = [model userLocked];
    if (isUserLocked) {
        [userLockedText setStringValue:[NSString stringWithFormat:@"Card locked with: %@",[model userLockedString]]];
    } else {
        [userLockedText setStringValue:@""];
    }
    BOOL isPolling = [model isPolling];
    [averagingValue setEnabled:(!isPolling && !isUserLocked)];
    [shipRecordsButton setEnabled:(!isPolling && !isUserLocked)];
    [resetBoardButton setEnabled:(!isPolling && !isUserLocked)];
    [initBoardButton setEnabled:(!isPolling && !isUserLocked)];
    [basicWriteButton setEnabled:(!isPolling && !isUserLocked)];
    [addressModifierPopUp setEnabled:(!isPolling && !isUserLocked)];
    [addressText setEnabled:(!isPolling && !isUserLocked)];
    [operationModePopUp setEnabled:(!isPolling && !isUserLocked)];
    [autoscanModePopUp setEnabled:(!isPolling && !isUserLocked)];
    [pollButton setEnabled:!isUserLocked];
    
}
@end
