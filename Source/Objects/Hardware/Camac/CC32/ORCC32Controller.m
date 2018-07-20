/*
 
 File:		ORCC32Controller.m
 
 Usage:		Test PCI Basic I/O Kit Kernel Extension (KEXT) Functions
 for the Camac CC32 VME Bus Controller
 
 Author:		FM
 
 Copyright:		Copyright 2001-2002 F. McGirt.  All rights reserved.
 
 Change History:	1/22/02, 2/2/02, 2/12/02
 2/13/02 MAH CENPA. converted to Objective-C
 
 
 -----------------------------------------------------------
 This program was prepared for the Regents of the University of 
 Washington at the Center for Experimental Nuclear Physics and 
 Astrophysics (CENPA) sponsored in part by the United States 
 Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
 The University has certain rights in the program pursuant to 
 the contract and the program should not be copied or distributed 
 outside your organization.  The DOE and the University of 
 Washington reserve all rights in the program. Neither the authors,
 University of Washington, or U.S. Government make any warranty, 
 express or implied, or assume any liability or responsibility 
 for the use of this software.
 -------------------------------------------------------------
 
 
 */


#pragma mark ¥¥¥Imported Files
#import "ORCC32Controller.h"
#import "ORCC32Model.h"

#define kWriteValueEnabledMask 0x01
#define kSubAddressEnabledMask 0x02


@implementation ORCC32Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"CC32"];
    
    return self;
}

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
    [self setHelpStrings: nil];
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	NSString*   path = [[NSBundle mainBundle] pathForResource: @"CamacCmdHelp" ofType: @"plist"];
    [self setHelpStrings:[NSArray arrayWithContentsOfFile:path]];
    int i;
    [cmdSelectPopUp removeAllItems];
    for(i=0;i<[helpStrings count];i++){
        NSDictionary* dict = [helpStrings objectAtIndex:i];
        NSString* name = [NSString stringWithFormat:@"%d-%@",i,[dict objectForKey:@"Name"]];
        [cmdSelectPopUp insertItemWithTitle:name atIndex:i];
        [[cmdSelectPopUp itemAtIndex:i] setTag:i];
    };
    
    [self updateWindow];
}



#pragma mark ¥¥¥Accessors
- (NSArray *) helpStrings
{
    return helpStrings; 
}

- (void) setHelpStrings: (NSArray *) aHelpStrings
{
    [aHelpStrings retain];
    [helpStrings release];
    helpStrings = aHelpStrings;
}

- (NSString*) helpString:(int)index
{
    if(helpStrings){
        if(index>=0 && index<[helpStrings count]){
            NSString* aString =  [[helpStrings objectAtIndex:[model cmdSelection]] objectForKey:@"Help"];
            //remove the \n's and extra spaces
            aString = [[aString componentsSeparatedByString:@"\n"] componentsJoinedByString:@" "];
            while([aString rangeOfString:@"  "].location!=NSNotFound){
                aString = [[aString componentsSeparatedByString:@"  "] componentsJoinedByString:@" "];
            }
            return [NSString stringWithFormat:@"Command Function %d: %@",index,aString];
        }
    }
    return @"";
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(cmdSelectedChanged:)
                         name : ORCamacControllerCmdSelectedChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(cmdStationChanged:)
                         name : ORCamacControllerCmdStationChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(cmdSubAddressChanged:)
                         name : ORCamacControllerCmdSubAddressChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(cmdWriteValueChanged:)
                         name : ORCamacControllerCmdWriteAddressChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(moduleWriteValueChanged:)
                         name : ORCamacControllerModuleWriteValueChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(reponseValuesChanged:)
                         name : ORCamacControllerCmdValuesChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : [model settingsLock]
                        object: nil];
    
}

#pragma mark ¥¥¥Interface Management

- (void) updateWindow
{
    [super updateWindow];
    [self cmdSelectedChanged:nil];
    [self cmdStationChanged:nil];
    [self cmdSubAddressChanged:nil];
    [self cmdWriteValueChanged:nil];
    [self moduleWriteValueChanged:nil];
    [self reponseValuesChanged:nil];
    [self settingsLockChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:[model settingsLock] to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	[self setButtonStates];
}

- (void) setButtonStates
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    //BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model settingsLock]];
    BOOL locked = [gSecurity isLocked:[model settingsLock]];
    
    [settingLockButton setState: locked];
    
    [executeButton setEnabled:!locked && !runInProgress];
    [subaddressStepper setEnabled:!locked && !runInProgress];
    [cmdSelectPopUp setEnabled:!locked && !runInProgress];
    [stationField setEnabled:!locked && !runInProgress];
    [stationStepper setEnabled:!locked && !runInProgress];
    [subaddressField setEnabled:!locked && !runInProgress];
    [subaddressStepper setEnabled:!locked && !runInProgress];
    [writeValueField setEnabled:!locked && !runInProgress];
    [writeValueStepper setEnabled:!locked && !runInProgress];
    [helpField setEnabled:!locked && !runInProgress];
    [moduleWriteValueField setEnabled:!locked && !runInProgress];
    
    [responseField setEnabled:!locked && !runInProgress];
    [cmdAcceptedField setEnabled:!locked && !runInProgress];
    [inhibitField setEnabled:!locked && !runInProgress];
    [lookAtMeField setEnabled:!locked && !runInProgress];
    [valueField setEnabled:!locked && !runInProgress];
    
    [initButton setEnabled:!locked && !runInProgress];
    [testButton setEnabled:!locked && !runInProgress];
    [resetButton setEnabled:!locked && !runInProgress];
    [inhibitOnButton setEnabled:!locked && !runInProgress];
    [inhibitOffButton setEnabled:!locked && !runInProgress];
    [setLamMaskButton setEnabled:!locked && !runInProgress];
    [zCycleButton setEnabled:!locked && !runInProgress];
    [cCycleButton setEnabled:!locked && !runInProgress];
    [cICycleButton setEnabled:!locked && !runInProgress];
    [zICycleButton setEnabled:!locked && !runInProgress];
    [resetLamFFButton setEnabled:!locked && !runInProgress];
    
    [readIhibitButton setEnabled:!locked && !runInProgress];
    [readLamMaskButton setEnabled:!locked && !runInProgress];
    [readLamStationsButton setEnabled:!locked && !runInProgress];
    [readLedsButton setEnabled:!locked && !runInProgress];
    [readLamFFButton setEnabled:!locked && !runInProgress];
    
    
    // NSString* s = @"";
    //if(lockedOrRunningMaintenance){
	//if(runInProgress && ![gSecurity isLocked:[model settingsLock]])s = @"Not in Maintenance Run.";
    //}
    //[settingLockDocField setStringValue:s];
	
}



- (void) cmdSelectedChanged:(NSNotification*)aNotification
{
	if(helpStrings){
		[cmdSelectPopUp selectItemAtIndex:[model cmdSelection]];
		[helpField setStringValue:[self helpString:[model cmdSelection]]];
	}
}

- (void) cmdStationChanged:(NSNotification*)aNotification
{
	[stationField setIntValue:[model cmdStation]];
	[stationStepper setIntValue:[model cmdStation]];
}

- (void) cmdSubAddressChanged:(NSNotification*)aNotification
{
	[subaddressField setIntValue:[model cmdSubAddress]];
	[subaddressStepper setIntValue:[model cmdSubAddress]];
}

- (void) cmdWriteValueChanged:(NSNotification*)aNotification
{
	[writeValueField setIntValue:[model cmdWriteValue]];
	[writeValueStepper setIntValue:[model cmdWriteValue]];
}

- (void) moduleWriteValueChanged:(NSNotification*)aNotification
{
	[moduleWriteValueField setIntValue:[model moduleWriteValue]];
}


- (void) reponseValuesChanged:(NSNotification*)aNotification
{
	[responseField setIntValue:[model cmdResponse]];
	[cmdAcceptedField setIntValue:[model cmdAccepted]];
	[inhibitField setIntValue:[model inhibit]];
	[lookAtMeField setIntValue:[model lookAtMe]];
}


- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    int theTag = (int)[menuItem tag];
    if([helpStrings count]) return [[[helpStrings objectAtIndex:theTag] objectForKey:@"Active"] boolValue];
    else return NO;
}

#pragma mark ¥¥¥Actions

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:[model settingsLock] to:[sender intValue] forWindow:[self window]];
}

- (IBAction) init:(id)sender
{
    unsigned short statusCC32 = 0;
    @try {
        [model checkCratePower];
        statusCC32 = [model initializeContrl];
        NSLog(@"Initialize CC32 - LCR CNTRL Status: 0x%04x\n",statusCC32);
	}
	@catch(NSException* localException) {
        NSLog(@"CC32 Initialization FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"CC32 Initialization"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed Initialization of CC32", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
    }
}

- (IBAction) test:(id)sender
{
    unsigned short statusCC32 = 0;
    @try {
        [model checkCratePower];
        [model test];
        statusCC32 = [model initializeContrl];
    }
	@catch(NSException* localException) {
        NSLog(@"CC32 Test FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"CC32 Test"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\n%@", @"OK", nil, nil,
                            [localException name],statusCC32,@"Failed Test of CC32");
        }
	}
}

- (IBAction) execute:(id)sender
{
    [self endEditing];
    unsigned short statusCC32 = 0;
    @try {
        [model checkCratePower];
        statusCC32 = [model execute];
	}
	@catch(NSException* localException) {
        int i = (int)[cmdSelectPopUp indexOfSelectedItem];
        NSDictionary* dict = [helpStrings objectAtIndex:i];
        NSString* name = [dict objectForKey:@"Name"];
        
        NSLog(@"Failed Cmd: %@ (F%d)\n",name,i);
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:[NSString stringWithFormat:@"%@ (F%d)",name,i]];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\n%@ (F%d)", @"OK", nil, nil,
                            [localException name],statusCC32,name,i);
        }
	}
}


- (IBAction) resetController:(id)sender
{   
    unsigned short statusCC32 = 0;
    @try {
        [model checkCratePower];
        statusCC32 = [model resetContrl];
        NSLog(@"Reset CC32\n");
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"Reset Failed\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Reset"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 Reset", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}

- (IBAction) inhibitOnAction:(id)sender
{
    unsigned short statusCC32 = 0;
    @try {
        [model checkCratePower];
        statusCC32 = [model setCrateInhibit:YES];
        NSLog(@"SET CC32 inhibit\n");
	}
	@catch(NSException* localException) {
        NSLog(@"SET CC32 inhibit FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Inhibit On"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 Inhibit On", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}

- (IBAction) inhibitOffAction:(id)sender
{
    unsigned short statusCC32 = 0;
    @try {
        [model checkCratePower];
        statusCC32 = [model setCrateInhibit:NO];
        NSLog(@"CLEAR CC32 inhibit\n");
	}
	@catch(NSException* localException) {
        NSLog(@"CLEAR CC32 inhibit FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Inhibit Off"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 Inhibit Off", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}


- (IBAction) readInhibitAction:(id)sender
{
    unsigned short statusCC32 = 0;
    unsigned short inhibitState;
    @try {
        [model checkCratePower];
        statusCC32 = [model readCrateInhibit:&inhibitState];
        NSLog(@"CC32 inhibit state = %@\n",inhibitState?@"SET":@"CLEAR");
	}
	@catch(NSException* localException) {
        NSLog(@"Read CC32 inhibit FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Read Inhibit"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 Read Inhibit", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}

- (IBAction) setLamMaskAction:(id)sender
{
    [self endEditing];
    unsigned short statusCC32 = 0;
    unsigned short maskValue = [model moduleWriteValue];
    @try {
        [model checkCratePower];
        statusCC32 = [model setLAMMask:maskValue];
        NSLog(@"CC32 LAM Mask set to 0x%0x\n",maskValue);
	}
	@catch(NSException* localException) {
        NSLog(@"Set CC32 LAM Mask FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Set LAM Mask"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 Set LAM Mask", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}


- (IBAction) readLamMaskAction:(id)sender
{
    unsigned short statusCC32 = 0;
    uint32_t maskValue;
    @try {
        [model checkCratePower];
        statusCC32 = [model readLAMMask:&maskValue];
        NSLog(@"CC32 LAM Mask: 0x%0x\n",maskValue);
	}
	@catch(NSException* localException) {
        NSLog(@"Read CC32 LAM Mask FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Read LAM Mask"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 Read LAM Mask", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}

- (IBAction) readLamStationsAction:(id)sender
{
    unsigned short statusCC32 = 0;
    uint32_t value;
    @try {
        [model checkCratePower];
        statusCC32 = [model readLAMStations:&value];
        NSLog(@"CC32 LAM Stations: 0x%0x\n",value);
	}
	@catch(NSException* localException) {
        NSLog(@"Read CC32 LAM Stations FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Read LAM Stations"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 Read LAM Stations", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}

- (IBAction) readLedsAction:(id)sender
{
    @try {
        [model checkCratePower];
		NSLog(@"LEDs: 0x%08x\n",[model readLEDs]);
	}
	@catch(NSException* localException) {
        NSLog(@"Read CC32 LEDs FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Read LEDs"];
        else {
            ORRunAlertPanel([localException name], @"%@\nFailed CC32 Read LEDs", @"OK", nil, nil,
                            [localException name]);
        }
	}
}

- (IBAction) zCycleAction:(id)sender
{
    unsigned short statusCC32 = 0;
    @try {
        [model checkCratePower];
        statusCC32 = [model executeZCycle];
        NSLog(@"CC32 Z-Cycle\n");
	}
	@catch(NSException* localException) {
        NSLog(@"Execute Z-Cycle FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Z-Cycle"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 Z-Cycle", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}

- (IBAction) cCycleAction:(id)sender
{
    unsigned short statusCC32 = 0;
    @try {
        [model checkCratePower];
        statusCC32 = [model executeCCycle];
        NSLog(@"CC32 C-Cycle\n");
	}
	@catch(NSException* localException) {
        NSLog(@"Execute C-Cycle FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"C-Cycle"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 C-Cycle", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}

- (IBAction) cCycleIAction:(id)sender
{
    unsigned short statusCC32 = 0;
    @try {
        [model checkCratePower];
        statusCC32 = [model executeCCycleIOff];
        NSLog(@"CC32 C-Cycle, Inhibit Off\n");
	}
	@catch(NSException* localException) {
        NSLog(@"Execute C-Cycle, Inhibit Off FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"C-Cycle, Inhibit Off"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 C-Cycle, Inhibit Off", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}

- (IBAction) zCycleIAction:(id)sender
{
    unsigned short statusCC32 = 0;
    @try {
        [model checkCratePower];
        statusCC32 = [model executeZCycleIOn];
        NSLog(@"CC32 Z-Cycle, Inhibit On\n");
	}
	@catch(NSException* localException) {
        NSLog(@"Execute Z-Cycle, Inhibit On FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Z-Cycle, Inhibit On"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 Z-Cycle, Inhibit On", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}

- (IBAction) resetLamFFAction:(id)sender
{
    unsigned short statusCC32 = 0;
    @try {
        [model checkCratePower];
        statusCC32 = [model resetLAMFF];
        NSLog(@"Reset CC32 LAM_FF\n");
	}
	@catch(NSException* localException) {
        NSLog(@"Read CC32 LAM_FF Failed\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Reset LAM-FF"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 Reset LAM_FF", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}

- (IBAction) readLamFFAction:(id)sender
{
    unsigned short statusCC32 = 0;
    unsigned short value;
    @try {
        [model checkCratePower];
        statusCC32 = [model readLAMFFStatus:&value];
        NSLog(@"CC32 LAM_FF: 0x%0x\n",value);
	}
	@catch(NSException* localException) {
        NSLog(@"Read CC32 LAM_FF FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"Read LAM_FF"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\nFailed CC32 Read LAM_FF", @"OK", nil, nil,
                            [localException name],statusCC32);
        }
	}
}

- (IBAction) cmdSelectAction:(id)sender
{
	if([sender indexOfSelectedItem] != [model cmdSelection]){
		[[self undoManager] setActionName: @"Set Camac Command Number"];
        [model setCmdSelection:(int)[sender indexOfSelectedItem]];
	}
}

- (IBAction) cmdStationAction:(id)sender
{
	if([sender intValue] != [model cmdStation]){
		[[self undoManager] setActionName: @"Set Camac Station Number"];
        [model setCmdStation:[sender intValue]];
	}
}
- (IBAction) cmdSubAddressAction:(id)sender
{
	if([sender intValue] != [model cmdSubAddress]){
		[[self undoManager] setActionName: @"Set Camac Subaddress Number"];
        [model setCmdSubAddress:[sender intValue]];
	}
}
- (IBAction) cmdWriteValueAction:(id)sender
{
	if([sender intValue] != [model cmdWriteValue]){
		[[self undoManager] setActionName: @"Set Camac Write Value"];
        [model setCmdWriteValue:[sender intValue]];
	}
}

- (IBAction) moduleWriteValueAction:(id)sender
{
	if([sender intValue] != [model moduleWriteValue]){
		[[self undoManager] setActionName: @"Set Camac Write Value"];
        [model setModuleWriteValue:[sender intValue]];
	}
}



@end



