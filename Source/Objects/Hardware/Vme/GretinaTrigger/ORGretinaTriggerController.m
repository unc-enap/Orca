//-------------------------------------------------------------------------
//  ORGretinaTriggerController.m
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORGretinaTriggerController.h"

@implementation ORGretinaTriggerController

-(id)init
{
    self = [super initWithWindowNibName:@"GretinaTrigger"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    settingTabSize  = NSMakeSize(830,510);
    stateTabSize	= NSMakeSize(520,540);
    registerTabSize	= NSMakeSize(400,180);
    firmwareTabSize	= NSMakeSize(400,180);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	// Setup register popup buttons
	[registerIndexPU removeAllItems];
	[registerIndexPU setAutoenablesItems:NO];
	int i;
	for (i=0;i<kNumberOfGretinaTriggerRegisters;i++) {
        NSString* itemName = [NSString stringWithFormat:@"(0x%04x) %@",[model registerOffsetAt:i],[model registerNameAt:i]];
		[registerIndexPU insertItemWithTitle:itemName	atIndex:i];
	}
    
    int n = 11;
	for(i=0;i<n;i++){
        [[inputLinkMaskMatrix   cellAtRow:0 column:n-i-1]   setTag:i];
        [[serDesTPowerMasMatrix cellAtRow:0 column:n-i-1] setTag:i];
        [[serDesRPowerMasMatrix cellAtRow:0 column:n-i-1] setTag:i];
        [[linkLockedMatrix      cellAtRow:0 column:n-i-1] setTag:i];
    }
    
    n = 9;
	for(i=0;i<n;i++){
        [[lvdsPreemphasisCtlMatrix cellAtRow:0 column:n-i-1]   setTag:i];
    }
    
    n = 16;
	for(i=0;i<n;i++){
        [[miscCtl1Matrix cellAtRow:0 column:n-i-1]   setTag:i];
    }
    
    n = 12;
	for(i=0;i<n;i++){
        [[linkLruCrlMatrix cellAtRow:0 column:n-i-1]   setTag:i];
    }
   
    
    
    NSString* key = [NSString stringWithFormat: @"orca.ORGretinaTrigger%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

	[super awakeFromNib];
	
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
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORGretinaTriggerSettingsLock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretinaTriggerSettingsLock
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerWriteValueChanged:)
                         name : ORGretinaTriggerRegisterWriteValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerIndexChanged:)
                         name : ORGretinaTriggerRegisterIndexChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(isMasterChanged:)
                         name : ORGretinaTriggerModelIsMasterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fpgaFilePathChanged:)
                         name : ORGretinaTriggerFpgaFilePathChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(mainFPGADownLoadStateChanged:)
                         name : ORGretinaTriggerMainFPGADownLoadStateChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownProgressChanged:)
                         name : ORGretinaTriggerFpgaDownProgressChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownInProgressChanged:)
                         name : ORGretinaTriggerMainFPGADownLoadInProgressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(firmwareStatusStringChanged:)
                         name : ORGretinaTriggerFirmwareStatusStringChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(inputLinkMaskChanged:)
                         name : ORGretinaTriggerModelInputLinkMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(serDesTPowerMaskChanged:)
                         name : ORGretinaTriggerSerdesTPowerMaskChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(serDesRPowerMaskChanged:)
                         name : ORGretinaTriggerSerdesRPowerMaskChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lvdsPreemphasisCtlChanged:)
                         name : ORGretinaTriggerLvdsPreemphasisCtlMask
						object: model];

    
    [notifyCenter addObserver : self
                     selector : @selector(miscCtl1RegChanged:)
                         name : ORGretinaTriggerMiscCtl1RegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(miscStatRegChanged:)
                         name : ORGretinaTriggerMiscStatRegChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(linkLruCrlRegChanged:)
                         name : ORGretinaTriggerLinkLruCrlRegChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(linkLockedRegChanged:)
                         name : ORGretinaTriggerLinkLockedRegChanged
						object: model];

    
    [notifyCenter addObserver : self
                     selector : @selector(clockUsingLLinkChanged:)
                         name : ORGretinaTriggerClockUsingLLinkChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(initStateChanged:)
                         name : ORGretinaTriggerModelInitStateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(verboseChanged:)
                         name : ORGretinaTriggerModelVerboseChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORGretinaTriggerLockChanged
						object: model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(doNotLockChanged:)
                         name : ORGretinaTriggerModelDoNotLockChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(numTimesToRetryChanged:)
                         name : ORGretinaTriggerModelNumTimesToRetryChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(timeStampChanged:)
                         name : ORGretinaTriggerTimeStampChanged
						object: model];
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
    [self registerLockChanged:nil];
	[self registerIndexChanged:nil];
	[self registerWriteValueChanged:nil];
	[self isMasterChanged:nil];
    [self fpgaFilePathChanged:nil];
    [self mainFPGADownLoadStateChanged:nil];
    [self fpgaDownProgressChanged:nil];
    [self fpgaDownInProgressChanged:nil];
    [self firmwareStatusStringChanged:nil];
	[self inputLinkMaskChanged:nil];
	[self serDesTPowerMaskChanged:nil];
	[self serDesRPowerMaskChanged:nil];
	[self lvdsPreemphasisCtlChanged:nil];
	[self miscCtl1RegChanged:nil];
	[self miscStatRegChanged:nil];
	[self linkLruCrlRegChanged:nil];
	[self linkLockedRegChanged:nil];
	[self clockUsingLLinkChanged:nil];
	[self initStateChanged:nil];
	[self verboseChanged:nil];
	[self lockChanged:nil];
	[self doNotLockChanged:nil];
	[self numTimesToRetryChanged:nil];
    [self timeStampChanged:nil];
}

#pragma mark •••Interface Management
- (void) timeStampChanged:(NSNotification*)aNote
{
    [timeStampField setDoubleValue:(double)[model timeStamp]];
}

- (void) numTimesToRetryChanged:(NSNotification*)aNote
{
	[numTimesToRetryField setIntValue: [model numTimesToRetry]];
}

- (void) doNotLockChanged:(NSNotification*)aNote
{
	[doNotLockCB setIntValue: [model doNotLock]];
    [self settingsLockChanged:nil];
}

- (void) lockChanged:(NSNotification*)aNote
{
    [lockedField setStringValue:[model locked]?@"Yes":@"No"];
    
    [digitizersLockedField setStringValue:[NSString stringWithFormat:@"%d/%d",[model digitizerLockCount],[model digitizerCount]]];    
}

- (void) verboseChanged:(NSNotification*)aNote
{
	[verboseCB setIntValue: [model verbose]];
}

- (void) firmwareStatusStringChanged:(NSNotification*)aNote
{
	[firmwareStatusStringField setStringValue: [model firmwareStatusString]];
}

- (void) fpgaDownInProgressChanged:(NSNotification*)aNote
{
	if([model downLoadMainFPGAInProgress])[loadFPGAProgress startAnimation:self];
	else [loadFPGAProgress stopAnimation:self];
}

- (void) fpgaDownProgressChanged:(NSNotification*)aNote
{
	[loadFPGAProgress setDoubleValue:(double)[model fpgaDownProgress]];
}

- (void) mainFPGADownLoadStateChanged:(NSNotification*)aNote
{
	[mainFPGADownLoadStateField setStringValue: [model mainFPGADownLoadState]];
}

- (void) fpgaFilePathChanged:(NSNotification*)aNote
{
	[fpgaFilePathField setStringValue: [[model fpgaFilePath] stringByAbbreviatingWithTildeInPath]];
}

- (void) initStateChanged:(NSNotification*)aNote
{
    [initStateField setStringValue:[model initialStateName]];
    [stateStatusTable reloadData];
}

- (void) clockUsingLLinkChanged:(NSNotification*)aNote
{
    if([model isMaster])[clockUsingLLinkField setStringValue:@"N/A (This is Master)"];
    else [clockUsingLLinkField setStringValue:[model clockUsingLLink]?@"YES":@"NO"];
}

- (void) linkLockedRegChanged:(NSNotification*)aNote
{
    int value = ~[model linkLockedReg];
	short i;
	for(i=0;i<[linkLockedMatrix numberOfColumns];i++){
		[[linkLockedMatrix cellWithTag:i] setIntValue:(value & 1L<<i)];
	}
}

- (void) linkLruCrlRegChanged:(NSNotification*)aNote
{
    int value = [model linkLruCrlReg];
	short i;
	for(i=0;i<[linkLruCrlMatrix numberOfColumns];i++){
		[[linkLruCrlMatrix cellWithTag:i] setIntValue:(value & 1L<<i)];
	}
}

- (void) miscCtl1RegChanged:(NSNotification*)aNote
{
    int value = [model miscCtl1Reg];
	short i;
	for(i=0;i<[miscCtl1Matrix numberOfColumns];i++){
		[[miscCtl1Matrix cellWithTag:i] setIntValue:(value & 1L<<i)];
	}
}

- (void) miscStatRegChanged:(NSNotification*)aNote
{
    [miscStatTable reloadData];    
}

- (void) inputLinkMaskChanged:(NSNotification*)aNote
{
    int value = ~[model inputLinkMask];
	short i;
	for(i=0;i<[inputLinkMaskMatrix numberOfColumns];i++){
		[[inputLinkMaskMatrix cellWithTag:i] setIntValue:(value & 1L<<i)];
	}
}

- (void) serDesTPowerMaskChanged:(NSNotification*)aNote
{
    int value = [model serdesTPowerMask];
	short i;
	for(i=0;i<[serDesTPowerMasMatrix numberOfColumns];i++){
		[[serDesTPowerMasMatrix cellWithTag:i] setIntValue:(value & 1L<<i)];
	}
}

- (void) lvdsPreemphasisCtlChanged:(NSNotification*)aNote
{
    int value = [model lvdsPreemphasisCtlMask];
	short i;
	for(i=0;i<[lvdsPreemphasisCtlMatrix numberOfColumns];i++){
		[[lvdsPreemphasisCtlMatrix cellWithTag:i] setIntValue:(value & 1L<<i)];
	}
}

- (void) serDesRPowerMaskChanged:(NSNotification*)aNote
{
    int value = [model serdesRPowerMask];
	short i;
	for(i=0;i<[serDesRPowerMasMatrix numberOfColumns];i++){
		[[serDesRPowerMasMatrix cellWithTag:i] setIntValue:(value & 1L<<i)];
	}
}

- (void) registerWriteValueChanged:(NSNotification*)aNote
{
	[registerWriteValueField setIntValue: [model regWriteValue]];
}

- (void) registerIndexChanged:(NSNotification*)aNote
{
	[registerIndexPU selectItemAtIndex: [model registerIndex]];
	[self setRegisterDisplay:[model registerIndex]];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORGretinaTriggerSettingsLock to:secure];
    [gSecurity setLock:ORGretinaTriggerRegisterLock to:secure];
    [settingLockButton setEnabled:secure];
    [registerLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    //BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretinaTriggerSettingsLock];
    BOOL locked = [gSecurity isLocked:ORGretinaTriggerSettingsLock];
		
    [settingLockButton  setState: locked];
	[probeButton        setEnabled:!locked && !runInProgress];
 
    if(![model isMaster]){
        [shipRecordButton setHidden:YES];
        [optionsBox setHidden:YES];
    }
    else {
        [shipRecordButton setHidden:NO];
        [shipRecordButton   setEnabled:!locked && [model isMaster]];
        [optionsBox setHidden:NO];
        [numTimesToRetryField setEnabled:![model doNotLock]];
    }
}

- (void) registerLockChanged:(NSNotification*)aNotification
{
    
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretinaTriggerRegisterLock];
    BOOL locked = [gSecurity isLocked:ORGretinaTriggerRegisterLock];
		
    [registerLockButton setState: locked];
    [registerWriteValueField setEnabled:!lockedOrRunningMaintenance];
    [registerIndexPU setEnabled:!lockedOrRunningMaintenance];
    [readRegisterButton setEnabled:!lockedOrRunningMaintenance];
    [writeRegisterButton setEnabled:!lockedOrRunningMaintenance];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"GretinaTrigger Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"GretinaTrigger Card (Slot %d)",[model slot]]];
}

- (void) setRegisterDisplay:(unsigned int)index
{
	if (index < kNumberOfGretinaTriggerRegisters) {
        [writeRegisterButton setEnabled:[model canWriteRegister:index]];
        [registerWriteValueField setEnabled:[model canWriteRegister:index]];
        [readRegisterButton setEnabled:[model canReadRegister:index]];
        [registerStatusField setStringValue:@""];
	}
}

- (void) isMasterChanged:(NSNotification*)aNote
{
    [masterRouterPU selectItemAtIndex:[model isMaster]];
    [self settingsLockChanged:nil];
}

#pragma mark •••Actions
- (IBAction) numTimesToRetryAction:(id)sender
{
	[model setNumTimesToRetry:[sender intValue]];
}

- (IBAction) doNotLockAction:(id)sender
{
	[model setDoNotLock:[sender intValue]];
}

- (IBAction) verboseAction:(id)sender
{
	[model setVerbose:[sender intValue]];
}

- (IBAction) isMasterAction:(id)sender
{
    [model setIsMaster:[sender indexOfSelectedItem]];
}

- (IBAction) readRegisterAction:(id)sender
{
	[self endEditing];
	uint32_t aValue = 0;
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretinaTriggerRegisters) {
		aValue = [model readRegister:index];
		NSLog(@"GretinaTrigger(%d,%d) %@: %u (0x%0x)\n",[model crateNumber],[model slot], [model registerNameAt:index],aValue,aValue);
	}
}

- (IBAction) writeRegisterAction:(id)sender
{
	[self endEditing];
	unsigned short aValue = [model regWriteValue];
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretinaTriggerRegisters) {
		[model writeRegister:index withValue:aValue];
	} 
}

- (IBAction) registerWriteValueAction:(id)sender
{
	[model setRegWriteValue:[sender intValue]];
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretinaTriggerSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) registerLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretinaTriggerRegisterLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) registerIndexPUAction:(id)sender
{
	int index = (int)[sender indexOfSelectedItem];
	[model setRegisterIndex:index];
	[self setRegisterDisplay:index];
}

-(IBAction)probeBoard:(id)sender
{
    [self endEditing];
    @try {
        uint32_t rev = [model readCodeRevision];
        NSLog(@"Gretina Trigger Code Revision (slot %d): 0x%x\n",[model slot],rev);
        uint32_t date = [model readCodeDate];
        NSLog(@"Gretina Trigger Code Date (slot %d): 0x%x\n",[model slot],date);
        [model readDisplayRegs];
    }
	@catch(NSException* localException) {
        NSLog(@"Probe GretinaTrigger Board FAILED Probe.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
                        localException);
    }
}
- (IBAction) shipRecordAction:(id)sender
{
    [model shipDataRecord];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingTabSize];
		[[self window] setContentView:tabView];
    }
 	else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:stateTabSize];
		[[self window] setContentView:tabView];
    }	
 	else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:registerTabSize];
		[[self window] setContentView:tabView];
    }
 	else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:firmwareTabSize];
		[[self window] setContentView:tabView];
    }

    NSString* key = [NSString stringWithFormat: @"orca.ORGretinaTrigger%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}
- (IBAction) dumpFPGARegsAction:(id)sender
{
    [model dumpFpgaRegisters];
}

- (IBAction) dumpRegsAction:(id)sender
{
    [model dumpRegisters];
}

- (IBAction) testSandBoxAction:(id)sender
{
    [model testSandBoxRegisters];

}
- (IBAction) downloadMainFPGAAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Select FPGA Binary File"];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setFpgaFilePath:[[openPanel URL]path]];
            [model startDownLoadingMainFPGA];
        }
    }];
}
- (IBAction) stopLoadingMainFPGAAction:(id)sender
{
  	[model stopDownLoadingMainFPGA];  
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(aTableView == miscStatTable){
		if([[aTableColumn identifier] isEqualToString:@"name"]){
            if([model isMaster]){
                switch(rowIndex){
                    case 0: return @"Lock Error";
                    case 1: return @"All Locked";
                    case 2: return @"Trigger Veto";
                    case 3: return @"Link Init State";
                    case 4: return @"Fast Strobe";
                    case 5: return @"TimeStamp RollOver";
                    case 6: return @"NIM In 1";
                    case 7: return @"NIM In 2";
                    default: return @"";
                }
            }
            else {
                switch(rowIndex){
                    case 0: return @"Lock Error";
                    case 1: return @"All Locked";
                    case 2: return @"Link Init State";
                    case 3: return @"CPLD Multiplicity";
                    case 4: return @"Fast Strobe";
                    case 5: return @"Router Lock";
                    case 6: return @"NIM In 1";
                    case 7: return @"NIM In 2";
                    default: return @"";
                }
            }
        }

		else {
            unsigned short miscStat         = [model miscStatReg];
            unsigned short linkInitState    = ((miscStat >> 8) & 0xF);
            unsigned short cpldMultiplicity = ((miscStat >> 4) & 0xF);
            if([model isMaster]){
                switch(rowIndex){
                    case 0:
                        if(miscStat & (0x1<<15))return @"YES";
                        else                    return @"NO";
                        
                    case 1:
                        if(miscStat & (0x1<<14))return @"YES";
                        else                    return @"NO";
                        
                    case 2:
                        if(miscStat & (0x1<<12))return @"Active";
                        else                    return @"NOT Active";
                        
                    case 3:
                        switch(linkInitState){
                            case 0:  return @"Machine In reset";
                            case 3:  return @"Waiting for SerDes Lock";
                            case 4:  return @"All SerDes Locked";
                            case 5:  return @"Locked. Sync Removed.";
                            case 6:  return @"1 or more Locks Lost";
                            default: return @"?";
                       }
                        
                    case 4:
                        if(miscStat & (0x1<<3))return @"Set";
                        else return @"Clr";
                        
                    case 5:
                        if(miscStat & (0x1<<2))return @"Rolled Over";
                        else return @"Not Rolled Over";
                        
                    case 6:
                        if(miscStat & (0x1<<1))return @"1";
                        else                   return @"0";
                        
                    case 7:
                        if(miscStat & (0x1<<0)) return @"1";
                        else                    return @"0";
                }
            }
            else {
                switch(rowIndex){
                    case 0:
                        if(miscStat & (0x1<<15))return @"YES";
                        else                    return @"NO";
                        
                    case 1:
                        if(miscStat & (0x1<<14))return @"YES";
                        else                    return @"NO";
                        
                    case 2:
                        switch(linkInitState){
                            case 0:  return @"Machine In reset";
                            case 3:  return @"Waiting for SerDes Lock";
                            case 4:  return @"All SerDes Locked";
                            case 5:  return @"Locked. Sync Removed.";
                            case 6:  return @"1 or more Locks Lost";
                            default: return @"?";
                        }
                        
                    case 3:
                        return [NSString stringWithFormat:@"%d",cpldMultiplicity];
                        
                    case 4:
                        if(miscStat & (0x1<<3)) return @"Set";
                        else                    return @"Clr";

                    case 5:
                        if(miscStat & (0x1<<2)) return @"Locked";
                        else                    return @"NOT Locked";
                        
                    case 6:
                        if(miscStat & (0x1<<1)) return @"1";
                        else                    return @"0";
                        
                    case 7:
                        if(miscStat & (0x1<<0)) return @"1";
                        else                    return @"0";
                }

            }
		}
	}
    else if(aTableView == stateStatusTable){
        if([[aTableColumn identifier] isEqualToString:@"name"]){
            return [model stateName:rowIndex];
        }
        else {
            return [model stateStatus:rowIndex];
        }
    }
	return @"";
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == miscStatTable)return 8;
    else if(aTableView == stateStatusTable){
        if([model isMaster])return kNumMasterTriggerStates;
        else                return kNumRouterTriggerStates;
    }
	else return 0;
}
@end
