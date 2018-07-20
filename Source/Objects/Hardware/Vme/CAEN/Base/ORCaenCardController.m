//--------------------------------------------------------------------------------
// CLASS:		ORCaenController
// Purpose:		Handles the interaction between the user and the base CAEN module.
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
#import "ORCaenCardController.h"
#import "ORCaenDataDecoder.h"
#import "ORCaenCardModel.h"

@implementation ORCaenCardController
#pragma mark ***Initialization
//--------------------------------------------------------------------------------
/*!\method  initWithWindowNibName
 * \brief	Initialize the window using the nib file.
 * \param	aNibName			- The name of the nib object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) initWithWindowNibName:(NSString*) aNibName
{
    self = [super initWithWindowNibName:aNibName];
    return self;
}

//--------------------------------------------------------------------------------
/*!\method  dealloc
 * \brief	Just calls super dealloc.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

//--------------------------------------------------------------------------------
/*!\method  awakeFromNib
 * \brief	Initializes object after everything is loaded.  Populates the
 *			pulldown menus registers for message notification.
 */
//--------------------------------------------------------------------------------
- (void) awakeFromNib
{
	
    settingSize     = NSMakeSize(280,400);
    thresholdSize   = [self thresholdDialogSize];
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	
    [registerAddressPopUp setAlignment:NSTextAlignmentCenter];
    [channelPopUp setAlignment:NSTextAlignmentCenter];
	
    [self populatePullDown];
    
    [super awakeFromNib];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORCaenCard%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
}

- (NSSize) thresholdDialogSize
{
	return NSMakeSize(290,570);
}

#pragma mark ¥¥¥Notfications
//--------------------------------------------------------------------------------
/*!\method  registerNotificationObservers
 * \brief	Register notices that we want to receive.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
	
    // Register any changes to first base tab
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
	
    // Register any changes to thresholds
    [notifyCenter addObserver:self
					 selector:@selector(thresholdChanged:)
						 name:caenChnlThresholdChanged
					   object:model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(thresholdLockChanged:)
                         name : [self thresholdLockName]
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : [self basicLockName]
						object: nil];
	
	
	[notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
	
	[notifyCenter addObserver : self
					 selector : @selector(thresholdLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
	
}

- (NSString*) thresholdLockName {return @"OverRide This";}
- (NSString*) basicLockName     {return @"OverRide This";}

#pragma mark ***Interface Management
//--------------------------------------------------------------------------------
/*!\method  updateWindow
 * \brief	Sets all GUI values to current model values.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) updateWindow
{
    short 	i;
    
    [super updateWindow];
    
    // Call change routines.
    [self baseAddressChanged:nil];
    [self writeValueChanged:nil];
    [self selectedRegIndexChanged:nil];
    [self selectedRegIndexChanged:nil];
    [self thresholdLockChanged:nil];
    [self basicLockChanged:nil];
    
    // Loop though all threshold scale parameters and reset them.
    for (i = 0; i < [model numberOfChannels]; i++){
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:caenChnl];
		
        [[NSNotificationCenter defaultCenter]
		 postNotificationName:caenChnlThresholdChanged
		 object:model
		 userInfo:userInfo];
    }
    
    [self slotChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:[self thresholdLockName] to:secure];
    [gSecurity setLock:[self basicLockName] to:secure];
    [thresholdLockButton setEnabled:secure];
    [basicLockButton setEnabled:secure];
}

#pragma mark ***Interface Management - Base tab

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

- (void) basicLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self basicLockName]];
    BOOL locked = [gSecurity isLocked:[self basicLockName]];
    [basicLockButton setState: locked];
    
    [addressStepper setEnabled:!locked && !runInProgress];
    [addressTextField setEnabled:!locked && !runInProgress];
	
    [writeValueStepper setEnabled:!lockedOrRunningMaintenance];
    [writeValueTextField setEnabled:!lockedOrRunningMaintenance];
    [registerAddressPopUp setEnabled:!lockedOrRunningMaintenance];
    [channelPopUp setEnabled:!lockedOrRunningMaintenance];
	
	
    [basicWriteButton setEnabled:!lockedOrRunningMaintenance];
    [basicReadButton setEnabled:!lockedOrRunningMaintenance]; 
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:[self basicLockName]])s = @"Not in Maintenance Run.";
    }
    [basicLockDocField setStringValue:s];
}

- (void) thresholdLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self thresholdLockName]];
    BOOL locked = [gSecurity isLocked:[self thresholdLockName]];
    [thresholdLockButton setState: locked];
    
    [thresholdA setEnabled:!lockedOrRunningMaintenance];
    [stepperA setEnabled:!lockedOrRunningMaintenance];
    [thresholdB setEnabled:!lockedOrRunningMaintenance];
    [stepperB setEnabled:!lockedOrRunningMaintenance];
	
    [thresholdWriteButton setEnabled:!lockedOrRunningMaintenance];
    [thresholdReadButton setEnabled:!lockedOrRunningMaintenance]; 
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:[self thresholdLockName]])s = @"Not in Maintenance Run.";
    }
    [thresholdLockDocField setStringValue:s];
}


//--------------------------------------------------------------------------------
/*!\method  baseAddressChanged
 * \brief	Notification that base address has changed.  Update the interface.
 * \param	aNotification			- The notification object.	
 */
//--------------------------------------------------------------------------------
- (void) baseAddressChanged:(NSNotification*) aNotification
{
	[addressStepper setDoubleValue:[model baseAddress]];
	[addressTextField setDoubleValue:[model baseAddress]];
}

//--------------------------------------------------------------------------------
/*!\method  writeValueChanged
 * \brief	Notification that value to write has changed.  Update the interface.
 * \param	aNotification			- The notification object.	
 */
//--------------------------------------------------------------------------------
- (void) writeValueChanged:(NSNotification*) aNotification
{
	//  Set value of both text and stepper
	[self updateStepper:writeValueStepper setting:[model writeValue]];
	[writeValueTextField setIntegerValue:[model writeValue]];
}

//--------------------------------------------------------------------------------
/*!\method  selectedRegIndexChanged
 * \brief	Notification that selected register has changed.  Update the interface.
 * \param	aNotification			- The notification object.	
 */
//--------------------------------------------------------------------------------
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

//--------------------------------------------------------------------------------
/*!\method  selectedRegIndexChanged
 * \brief	Notification that selected register has changed.  Update the interface.
 * \param	aNotification			- The notification object.	
 */
//--------------------------------------------------------------------------------
- (void) selectedRegChannelChanged:(NSNotification*) aNotification
{
	[self updatePopUpButton:channelPopUp setting:[model selectedChannel]];
}

#pragma mark ***Interface Management - Threshold
//--------------------------------------------------------------------------------
/*!\method  thresholdChanged
 * \brief	Notification that threshold has changed.  Update the interface.
 * \param	aNotification			- The notification object.	
 */
//--------------------------------------------------------------------------------
- (void) thresholdChanged:(NSNotification*) aNotification
{
	// Get the channel that changed and then set the GUI value using the model value.
	int chnl = [[[aNotification userInfo] objectForKey:caenChnl] intValue];
	if (chnl < 16){
		[[thresholdA cellWithTag:chnl] setIntValue:[model threshold:chnl]];
		[[stepperA cellWithTag:chnl] setIntValue:[model threshold:chnl]];
	}
	else {
		[[thresholdB cellWithTag:chnl] setIntValue:[model threshold:chnl]];
		[[stepperB cellWithTag:chnl] setIntValue:[model threshold:chnl]];
	}
	
}

#pragma mark ¥¥¥Actions

//--------------------------------------------------------------------------------
/*!\method  baseAddressAction
 * \brief	Set base address of module.
 * \param	aSender			- GUI object sending the message.
 */
//--------------------------------------------------------------------------------
- (IBAction) baseAddressAction:(id) aSender
{
	[[[model document] undoManager] setActionName:@"Set Base Address"]; // Set undo name.
	[model setBaseAddress:[aSender doubleValue]]; // set new value.
} 

//--------------------------------------------------------------------------------
/*!\method  writeValueAction
 * \brief	Write value to register.
 * \param	aSender			- GUI object sending the message.
 */
//--------------------------------------------------------------------------------
- (IBAction) writeValueAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender intValue] != [model writeValue]){
		[[[model document] undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

//--------------------------------------------------------------------------------
/*!\method  selectRegisterAction
 * \brief	Select the register to use.
 * \param	aSender			- GUI object sending the message.
 */
//--------------------------------------------------------------------------------
- (IBAction) selectRegisterAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[[model document] undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
    }
}

//--------------------------------------------------------------------------------
/*!\method  selectChannelAction
 * \brief	Select the channel to use.
 * \param	aSender			- GUI object sending the message.
 */
//--------------------------------------------------------------------------------
- (IBAction) selectChannelAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedChannel]){
		[[[model document] undoManager] setActionName:@"Select Channel"]; // Set undo name
		[model setSelectedChannel:[aSender indexOfSelectedItem]]; // Set new value
    }
}

//--------------------------------------------------------------------------------
/*!\method  thresholdChangedAction
 * \brief	A threshold value has been changed in the UI.
 * \param	aSender			- GUI object sending the message.
 */
//--------------------------------------------------------------------------------
- (IBAction) thresholdChangedAction:(id) aSender
{
    // NSMatrix which is aSender knows the intValue of the selected cell in the NSMatrix.
    if ([aSender intValue] != [model threshold:[[aSender selectedCell] tag]]){
        [[[model document] undoManager] setActionName:@"Set thresholds"]; // Set name of undo.z
        [model setThreshold:[[aSender selectedCell] tag] threshold:[aSender intValue]]; // Set new value
    }
}

//--------------------------------------------------------------------------------
/*!
 * \method  read
 * \brief	Read from VME module.
 * \note	
 */
//--------------------------------------------------------------------------------
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

//--------------------------------------------------------------------------------
/*!
 * \method  write
 * \brief	Write data to VME module.
 * \param	pSender			- GUI element sending message.
 * \note	
 */
//--------------------------------------------------------------------------------
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

//--------------------------------------------------------------------------------
/*!
 * \method  readThresholds
 * \brief	Send command to model to read thresholds from VME module.
 * \param	pSender			- GUI element sending message.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) readThresholds:(id) pSender
{
	@try {
		[self endEditing];
		[model readThresholds];
		[model logThresholds];
    }
	@catch(NSException* localException) {
        NSLog(@"Read of %@ thresholds FAILED.\n",[model identifier]);
        ORRunAlertPanel([localException name], @"%@\nFailed Reading Thresholds", @"OK", nil, nil,
                        localException);
    }
	
}

//--------------------------------------------------------------------------------
/*!
 * \method  writeThresholds
 * \brief	Send command to model to write model thresholds to VME module.
 * \param	pSender			- GUI element sending message.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) writeThresholds:(id) pSender
{
	@try {
		[self endEditing];
		[model writeThresholds];
    }
	@catch(NSException* localException) {
        NSLog(@"Write of %@ thresholds FAILED.\n",[model identifier]);
        ORRunAlertPanel([localException name], @"%@\nFailed Writing Thresholds", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) thresholdLockAction:(id)sender
{
    [gSecurity tryToSetLock:[self thresholdLockName] to:[sender intValue] forWindow:[self window]];
}

- (IBAction) basicLockAction:(id)sender
{
    [gSecurity tryToSetLock:[self basicLockName] to:[sender intValue] forWindow:[self window]];
}

#pragma mark ***Misc Helpers
//--------------------------------------------------------------------------------
/*!
 * \method  populatePullDown
 * \brief	Populate the pull down items in the dialog.  These include the register
 *			and channel.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) populatePullDown
{
    short	i;
	
	// Clear all the popup items.
    [registerAddressPopUp removeAllItems];
    [channelPopUp removeAllItems];
    
	// Populate the register popup
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[NSString stringWithFormat:@"%d %@",i,[model
												   getRegisterName:i]]
										  atIndex:i];
    }
    
	// Populate the channel popup
    for (i = 0; i < [model numberOfChannels]; i++) {
        [channelPopUp insertItemWithTitle:[NSString stringWithFormat:@"%d", i] 
								  atIndex:i];
    }
	
    [channelPopUp insertItemWithTitle:@"All" atIndex:[model numberOfChannels]];
	
    [self selectedRegIndexChanged:nil];
	
}

//--------------------------------------------------------------------------------
/*!
 * \method  updateRegisterDescription
 * \brief	Update description of register on dialog.
 * \param	aRegisterIndex			- The index to update.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) updateRegisterDescription:(short) aRegisterIndex
{
    NSString* types[] = {
		@"[ReadOnly]",
		@"[WriteOnly]",
		@"[ReadWrite]"
    };
	
    [registerOffsetTextField setStringValue:
	 [NSString stringWithFormat:@"0x%04lx",
	  (unsigned long)[model getAddressOffset:aRegisterIndex]]];
	
    [registerReadWriteTextField setStringValue:types[[model getAccessType:aRegisterIndex]]];
    [regNameField setStringValue:[model getRegisterName:aRegisterIndex]];
	
    [drTextField setStringValue:[model dataReset:aRegisterIndex] ? @"Y" :@"N"];
    [srTextField setStringValue:[model swReset:aRegisterIndex]   ? @"Y" :@"N"];
    [hrTextField setStringValue:[model hwReset:aRegisterIndex]   ? @"Y" :@"N"];    
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:thresholdSize];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORCaenCard%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}


@end
