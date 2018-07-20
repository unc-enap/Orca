//-------------------------------------------------------------------------
//  ORXYCom200Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/18/2008.
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

#pragma mark ***Imported Files
#import "ORXYCom200Controller.h"

@implementation ORXYCom200Controller

-(id)init
{
    self = [super initWithWindowNibName:@"XYCom200"];
	
    return self;
}

- (void) dealloc
{
	[subControllers release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
    [registerAddressPopUp setAlignment:NSTextAlignmentCenter];
	
    [self populatePopup];
	
	[self modelChanged:nil];
	[self setUpViews];
	
}

- (NSMutableArray*) subControllers
{
    return subControllers;
}

- (void) setSubControllers:(NSMutableArray*)newSubControllers
{
    [newSubControllers retain];
    [subControllers release];
    subControllers=newSubControllers;
}


- (void) removeSubPlotViews
{
    [subControllers removeAllObjects];
	viewsSetup = NO;
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
                         name : ORXYCom200Lock
                        object: nil];
	
	[notifyCenter addObserver:self
					 selector:@selector(selectedRegIndexChanged:)
						 name:ORXYCom200SelectedRegIndexChanged
					   object:model];
	
    [notifyCenter addObserver:self
					 selector:@selector(writeValueChanged:)
						 name:ORXYCom200WriteValueChanged
					   object:model]; 
	
    [notifyCenter addObserver : self
                     selector : @selector(selectedPLTChanged:)
                         name : ORXYCom200SelectedPLTChanged
						object: model];
}


- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self lockChanged:nil];
	
    [self writeValueChanged:nil];
    [self selectedRegIndexChanged:nil];
	[self selectedPLTChanged:nil];
}

- (void) setUpViews
{
	if(!viewsSetup){
		if(!subControllers)[self setSubControllers:[NSMutableArray array]];
		[self removeSubPlotViews];
		int i;
		for(i=0;i<2;i++){ 
			ORPISlashTChipController* subPlotController = [[ORPISlashTChipController alloc] initWithOwner:self chipIndex:i];
			[subControllers addObject:subPlotController];
			if(i == 0) [chip1View addSubview:[subPlotController getView]];
			else       [chip2View addSubview:[subPlotController getView]];
			[subPlotController release];
		}
		viewsSetup= YES;
	}
}

#pragma mark •••Interface Management

- (void) modelChanged:(NSNotification*)aNotification
{    
	NSEnumerator* e = [subControllers objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		[[obj getView] setNeedsDisplay:YES];
    }
}

- (void) selectedPLTChanged:(NSNotification*)aNote
{
	[selectedPLTPU selectItemAtIndex: [model selectedPLT]];
    short index = [model selectedRegIndex];
    [self updateRegisterDescription:index];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORXYCom200Lock to:secure];
    [settingLockButton setEnabled:secure];
    [basicOpsLockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
	// BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORXYCom200Lock];
    BOOL locked = [gSecurity isLocked:ORXYCom200Lock];
	
    [settingLockButton setState: locked];
    [basicOpsLockButton setState: locked];
    [addressText setEnabled:!locked && !runInProgress];
	[initBoardButton setEnabled:!locked && !runInProgress];
}

- (void) setModel:(id)aModel
{	
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"XYCom200 Card (Slot %d)",[model slot]]];
	[self setUpViews];
	id subController;
	NSEnumerator* e = [subControllers objectEnumerator];
	while(subController = [e nextObject]){
		[subController setModel: [model chip:(int)[subControllers indexOfObject:subController]]];
	}
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"XYCom200 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntegerValue: [model baseAddress]];
}

- (void) selectedRegIndexChanged:(NSNotification*) aNotification
{
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerAddressPopUp setting:index];
	[self updateRegisterDescription:index];
}

- (void) writeValueChanged:(NSNotification*) aNotification
{
	[self updateStepper:writeValueStepper setting:[model writeValue]];
	[writeValueTextField setIntegerValue:[model writeValue]];
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

- (void) selectedPLTPUAction:(id)sender
{
	[model setSelectedPLT:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
}

-(IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORXYCom200Lock to:[sender intValue] forWindow:[self window]];
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

- (void) initSquareWave:(int)chipIndex
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model initSqWave:chipIndex];	
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"Init Square Wave failed: %@", @"OK", nil, nil,
                        localException);
    }	
}
#pragma mark ***Misc Helpers
- (void) populatePopup
{
    [registerAddressPopUp removeAllItems];
    
    short	i;
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[model 
												   getRegisterName:i] 
										  atIndex:i];
    }
    
    [self selectedRegIndexChanged:nil];
}

- (void) updateRegisterDescription:(short) aRegisterIndex
{
    [registerOffsetField setStringValue:
	 [NSString stringWithFormat:@"0x%04x",[model getAddressOffset:aRegisterIndex] + (0x40 * [model selectedPLT])]];
	
    [regNameField setStringValue:[model getRegisterName:aRegisterIndex]];
	
}
@end

@implementation ORPISlashTChipController

-(id) initWithOwner:(ORXYCom200Controller*)anOwner chipIndex:(int)anIndex 
{
    self=[super init];
    owner = anOwner;
    chipIndex = anIndex;
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"PISlashTChip" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"PISlashTChip" owner:self topLevelObjects:&topLevelObjects];
#endif
    
    [topLevelObjects retain];

    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self]; 
    [theView removeFromSuperview];
    [topLevelObjects release];
	[super dealloc];
}

- (void) awakeFromNib
{
    //[self populatePopup];
}

- (void) setModel:(id)aModel
{
	model = aModel;
    [self registerNotificationObservers];
	[self updateWindow];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver:self];
	if(!model)return;
	
	//Gen Reg
	[notifyCenter addObserver : self selector : @selector(modeChanged:)
                         name : ORPISlashTChipModeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(H1SenseChanged:)
                         name : ORPISlashTChipH1SenseChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(H2SenseChanged:)
                         name : ORPISlashTChipH2SenseChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(H3SenseChanged:)
                         name : ORPISlashTChipH3SenseChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(H4SenseChanged:)
                         name : ORPISlashTChipH4SenseChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(H12EnableChanged:)
                         name : ORPISlashTChipH12EnableChanged
						object: model];
	[notifyCenter addObserver : self
                     selector : @selector(H34EnableChanged:)
                         name : ORPISlashTChipH34EnableChanged
						object: model];
	
	
	//Port A
	[notifyCenter addObserver : self
                     selector : @selector(portASubModeChanged:)
                         name : ORPISlashTChipPortASubModeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(portAH1ControlChanged:)
                         name : ORPISlashTChipPortAH1ControlChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(portAH2ControlChanged:)
                         name : ORPISlashTChipPortAH2ControlChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(portAH2InterruptChanged:)
                         name : ORPISlashTChipPortAH2InterruptChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(portADataChanged:)
                         name : ORPISlashTChipPortADataChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(portADirectionChanged:)
                         name : ORPISlashTChipPortADirectionChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(portATransceiverDirChanged:)
                         name : ORPISlashTChipPortATransceiverDirChanged
						object: model];
	
	
	//Port B
	[notifyCenter addObserver : self
                     selector : @selector(portBSubModeChanged:)
                         name : ORPISlashTChipPortBSubModeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(portBH1ControlChanged:)
                         name : ORPISlashTChipPortBH1ControlChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(portBH2ControlChanged:)
                         name : ORPISlashTChipPortBH2ControlChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(portBH2InterruptChanged:)
                         name : ORPISlashTChipPortBH2InterruptChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(portBDirectionChanged:)
                         name : ORPISlashTChipPortBDirectionChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(portBDataChanged:)
                         name : ORPISlashTChipPortBDataChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(portBTransceiverDirChanged:)
                         name : ORPISlashTChipPortBTransceiverDirChanged
						object: model];
	
	//Port C
    [notifyCenter addObserver : self
                     selector : @selector(portCDirectionChanged:)
                         name : ORPISlashTChipPortCDirectionChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(portCDataChanged:)
                         name : ORPISlashTChipPortCDataChanged
						object: model];
	
	//timer
	[notifyCenter addObserver : self
                     selector : @selector(timerControlChanged:)
                         name : ORPISlashTChipTimerControlChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(preloadHighChanged:)
                         name : ORPISlashTChipPreloadHighChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(preloadMiddleChanged:)
                         name : ORPISlashTChipPreloadMiddleChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(preloadLowChanged:)
                         name : ORPISlashTChipPreloadLowChanged
						object: model];
	
	//Other
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORXYCom200Lock
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(periodChanged:)
                         name : ORPISlashTChipPeriodChanged
						object: model];
}


- (void) updateWindow
{
	//Gen Reg
	[self modeChanged:nil];
	[self H34EnableChanged:nil];
	[self H12EnableChanged:nil];
	[self H4SenseChanged:nil];
	[self H3SenseChanged:nil];
	[self H2SenseChanged:nil];
	[self H1SenseChanged:nil];
	
	//Port A
	[self portASubModeChanged:nil];
	[self portAH1ControlChanged:nil];
	[self portAH2ControlChanged:nil];
	[self portAH2InterruptChanged:nil];
	[self portADirectionChanged:nil];
	[self portATransceiverDirChanged:nil];
	[self portADataChanged:nil];
	
	//Port B
	[self portBSubModeChanged:nil];
	[self portBH1ControlChanged:nil];
	[self portBH2ControlChanged:nil];
	[self portBH2InterruptChanged:nil];
	[self portBDirectionChanged:nil];
	[self portBTransceiverDirChanged:nil];
	[self portBDataChanged:nil];
	
	//Port C
	[self portCDirectionChanged:nil];
	[self portCDataChanged:nil];
	
	//Timer
	[self timerControlChanged:nil];
	[self preloadHighChanged:nil];
	[self preloadMiddleChanged:nil];
	[self preloadLowChanged:nil];
	[self periodChanged:nil];
	
	[self lockChanged:nil];
}

#pragma mark •••Interface Management
-(NSView *)getView 
{
    return theView;
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self setButtonStates];
}

- (void) setButtonStates
{
    //BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORXYCom200Lock];
    //BOOL locked						= [gSecurity isLocked:ORXYCom200Lock];
	
	//Gen Reg
	[modePU setEnabled: !lockedOrRunningMaintenance];
    [H1SensePU setEnabled: !lockedOrRunningMaintenance];
    [H2SensePU setEnabled: !lockedOrRunningMaintenance];
    [H3SensePU setEnabled: !lockedOrRunningMaintenance];
    [H4SensePU setEnabled: !lockedOrRunningMaintenance];
    [H12EnablePU setEnabled: !lockedOrRunningMaintenance];
    [H34EnablePU setEnabled: !lockedOrRunningMaintenance];
	
	//Port A
	[portASubModePU setEnabled: !lockedOrRunningMaintenance];
    [portAH1ControlPU setEnabled: !lockedOrRunningMaintenance];
    [portAH2InterruptPU setEnabled: !lockedOrRunningMaintenance];
    [portAH2ControlPU setEnabled: !lockedOrRunningMaintenance];
    [portATransceiverDirPU setEnabled: !lockedOrRunningMaintenance];
	[portADataField  setEnabled: !lockedOrRunningMaintenance];
    [portADirectionMatrix setEnabled: !lockedOrRunningMaintenance];
    [emitModeButton setEnabled: !lockedOrRunningMaintenance];
	
	//Port B
 	[portBSubModePU setEnabled: !lockedOrRunningMaintenance];
    [portBH1ControlPU setEnabled: !lockedOrRunningMaintenance];
    [portBH2InterruptPU setEnabled: !lockedOrRunningMaintenance];
    [portBH2ControlPU setEnabled: !lockedOrRunningMaintenance];
	[portBTransceiverDirPU setEnabled: !lockedOrRunningMaintenance];
	[portBDataField  setEnabled: !lockedOrRunningMaintenance];
    [portBDirectionMatrix setEnabled: !lockedOrRunningMaintenance];
	
	//Port C
    [portCDirectionMatrix setEnabled: !lockedOrRunningMaintenance];
	[portCDataMatrix  setEnabled: !lockedOrRunningMaintenance ];
	
	//Timer
	[timerControlField  setEnabled: !lockedOrRunningMaintenance ];
	[preloadHighField  setEnabled: !lockedOrRunningMaintenance ];
	[preloadMiddleField  setEnabled: !lockedOrRunningMaintenance ];
	[preloadLowField  setEnabled: !lockedOrRunningMaintenance ];
	[periodField  setEnabled: !lockedOrRunningMaintenance ];
	[easyTimerStartButton  setEnabled: !lockedOrRunningMaintenance ];
	
}

//Gen Reg
- (void) modeChanged:(NSNotification*)aNote
{
	[modePU selectItemAtIndex: [model opMode]];
    [self populatePopup];
}

- (void) H1SenseChanged:(NSNotification*)aNote
{
	[H1SensePU selectItemAtIndex: [model H1Sense]];
}

- (void) H2SenseChanged:(NSNotification*)aNote
{
	[H2SensePU selectItemAtIndex: [model H2Sense]];
}

- (void) H3SenseChanged:(NSNotification*)aNote
{
	[H3SensePU selectItemAtIndex: [model H3Sense]];
}

- (void) H4SenseChanged:(NSNotification*)aNote
{
	[H4SensePU selectItemAtIndex: [model H4Sense]];
}

- (void) H12EnableChanged:(NSNotification*)aNote
{
	[H12EnablePU selectItemAtIndex: [model H12Enable]];
}

- (void) H34EnableChanged:(NSNotification*)aNote
{
	[H34EnablePU selectItemAtIndex: [model H34Enable]];
}

//Port A
- (void) portASubModeChanged:(NSNotification*)aNote
{
	NSInteger count = [portASubModePU numberOfItems];
	NSInteger indexToSelect = [model portASubMode];
	if(indexToSelect >= count-1) indexToSelect = count-1;
	[portASubModePU selectItemAtIndex: indexToSelect];
}

- (void) portAH1ControlChanged:(NSNotification*)aNote
{
	[portAH1ControlPU selectItemAtIndex: [model portAH1Control]];
}

- (void) portAH2InterruptChanged:(NSNotification*)aNote
{
	[portAH2InterruptPU selectItemAtIndex: [model portAH2Interrupt]];
}

- (void) portAH2ControlChanged:(NSNotification*)aNote
{
	[portAH2ControlPU selectItemAtIndex: [model portAH2Control]];
}

- (void) portADirectionChanged:(NSNotification*)aNote
{
	int mask = [model portADirection];
	int i;
	for(i=0;i<8;i++)[[portADirectionMatrix cellWithTag:i] setState:mask & (1<<i)];
}

- (void) portATransceiverDirChanged:(NSNotification*)aNote
{
	[portATransceiverDirPU selectItemAtIndex: [model portATransceiverDir]];
}

- (void) portADataChanged:(NSNotification*)aNote
{
	[portADataField setIntValue: [model portAData]];
}

//Port B
- (void) portBSubModeChanged:(NSNotification*)aNote
{
	NSInteger count = [portBSubModePU numberOfItems];
	NSInteger indexToSelect = [model portBSubMode];
	if(indexToSelect >= count-1) indexToSelect = count-1;
	[portBSubModePU selectItemAtIndex: indexToSelect];
}

- (void) portBH1ControlChanged:(NSNotification*)aNote
{
	[portBH1ControlPU selectItemAtIndex: [model portBH1Control]];
}

- (void) portBH2InterruptChanged:(NSNotification*)aNote
{
	[portBH2InterruptPU selectItemAtIndex: [model portBH2Interrupt]];
}

- (void) portBH2ControlChanged:(NSNotification*)aNote
{
	[portBH2ControlPU selectItemAtIndex: [model portBH2Control]];
}

- (void) portBDirectionChanged:(NSNotification*)aNote
{
	int mask = [model portBDirection];
	int i;
	for(i=0;i<8;i++)[[portBDirectionMatrix cellWithTag:i] setState:mask & (1<<i)];
}

- (void) portBTransceiverDirChanged:(NSNotification*)aNote
{
	[portBTransceiverDirPU selectItemAtIndex: [model portBTransceiverDir]];
}

- (void) portBDataChanged:(NSNotification*)aNote
{
	[portBDataField setIntValue: [model portBData]];
}

//Port C
- (void) portCDirectionChanged:(NSNotification*)aNote
{
	int mask = [model portCDirection];
	int i;
	for(i=0;i<8;i++)[[portCDirectionMatrix cellWithTag:i] setState:mask & (1<<i)];
}

- (void) portCDataChanged:(NSNotification*)aNote
{	
	int mask = [model portCData];
	int i;
	for(i=0;i<8;i++)[[portCDataMatrix cellWithTag:i] setState:mask & (1<<i)];
}

//Timer 
- (void) preloadLowChanged:(NSNotification*)aNote
{
	[preloadLowField setIntValue: [model preloadLow]];
}

- (void) preloadMiddleChanged:(NSNotification*)aNote
{
	[preloadMiddleField setIntValue: [model preloadMiddle]];
}

- (void) preloadHighChanged:(NSNotification*)aNote
{
	[preloadHighField setIntValue: [model preloadHigh]];
}

- (void) timerControlChanged:(NSNotification*)aNote
{
	[timerControlField setIntValue: [model timerControl]];
}

- (void) periodChanged:(NSNotification*)aNote
{
	[periodField setIntValue: [model period]];
}

#pragma mark •••Actions
//Gen Reg
- (IBAction) modePUAction:(id)sender
{
	[model setMode:[sender indexOfSelectedItem]];	
}
- (IBAction) H1SensePUAction:(id)sender
{
	[model setH1Sense:[sender indexOfSelectedItem]];	
}

- (IBAction) H2SensePUAction:(id)sender
{
	[model setH2Sense:[sender indexOfSelectedItem]];	
}

- (void) H3SensePUAction:(id)sender
{
	[model setH3Sense:[sender indexOfSelectedItem]];	
}

- (IBAction) H4SensePUAction:(id)sender
{
	[model setH4Sense:[sender indexOfSelectedItem]];	
}

- (IBAction) H12EnablePUAction:(id)sender
{
	[model setH12Enable:[sender indexOfSelectedItem]];	
}

- (IBAction) H34EnablePUAction:(id)sender
{
	[model setH34Enable:[sender indexOfSelectedItem]];	
}

//Port A
- (IBAction) portASubModePUAction:(id)sender
{
	[model setPortASubMode:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
}

- (IBAction) portAH1ControlPUAction:(id)sender
{
	[model setPortAH1Control:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
}

- (IBAction) portAH2InterruptPUAction:(id)sender
{
	[model setPortAH2Interrupt:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
}

- (IBAction) portAH2ControlPUAction:(id)sender
{
	[model setPortAH2Control:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
}

- (IBAction) portADirectionMatrixAction:(id)sender
{
	int mask = 0;
	int i;
	for(i=0;i<8;i++){
		if([[sender cellWithTag:i] intValue]) mask |= (1<<i);
	}
	[model setPortADirection:mask];	
}

- (IBAction) portATransceiverDirPUAction:(id)sender
{
	[model setPortATransceiverDir:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
	unsigned char portCData = [model portCData];
	portCData &= ~0x1;
	if([sender indexOfSelectedItem])portCData |= 0x1;	
	[model setPortCData:portCData];
}

- (IBAction) portADataAction:(id)sender
{
	[model setPortAData:[sender intValue]];	
}

//Port B
- (IBAction) portBSubModePUAction:(id)sender
{
	[model setPortBSubMode:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
}

- (IBAction) portBH1ControlPUAction:(id)sender
{
	[model setPortBH1Control:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
}

- (IBAction) portBH2InterruptPUAction:(id)sender
{
	[model setPortBH2Interrupt:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
}

- (IBAction) portBH2ControlPUAction:(id)sender
{
	[model setPortBH2Control:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
}

- (IBAction) portBDataAction:(id)sender
{
	[model setPortBData:[(NSPopUpButton*)sender intValue]];
}

- (IBAction) portBTransceiverDirPUAction:(id)sender
{
	[model setPortBTransceiverDir:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
	unsigned char portCData = [model portCData];
	portCData &= ~0x2;
	if([sender indexOfSelectedItem]) portCData |= 0x2;	
	[model setPortCData:portCData];
}

- (IBAction) portBDirectionMatrixAction:(id)sender
{
	int mask = 0;
	int i;
	for(i=0;i<8;i++){
		if([[sender cellWithTag:i] intValue]) mask |= (1<<i);
	}
	[model setPortBDirection:mask];	
}

//Port C
- (IBAction) portCDirectionMatrixAction:(id)sender
{
	int mask = 0;
	int i;
	for(i=0;i<8;i++){
		if([[sender cellWithTag:i] intValue]) mask |= (1<<i);
	}
	[model setPortCDirection:mask];	
}

- (IBAction) portCDataAction:(id)sender
{
	int mask = 0;
	int i;
	for(i=0;i<8;i++){
		if([[sender cellWithTag:i] intValue]) mask |= (1<<i);
	}
	[model setPortCData:mask];	
	[model setPortATransceiverDir:(mask & 0x1)!=0];
	[model setPortBTransceiverDir:(mask & 0x2)!=0];	
}

//Timer
- (IBAction) preloadLowAction:(id)sender
{
	[model setPreloadLow:[sender intValue]];	
}

- (IBAction) preloadMiddleAction:(id)sender
{
	[model setPreloadMiddle:[sender intValue]];	
}

- (IBAction) preloadHighAction:(id)sender
{
	[model setPreloadHigh:[sender intValue]];	
}

- (IBAction) timerControlAction:(id)sender
{
	[model setTimerControl:[sender intValue]];	
}

- (IBAction) periodAction:(id)sender
{
	[model setPeriod:[sender intValue]];	
}

- (IBAction) emitModeAction:(id)sender
{
	[owner  initSquareWave:0];	
}

- (IBAction) easyTimerStartAction:(id)sender
{
	[owner  initSquareWave:chipIndex];	
}

- (void) populatePopup
{
    [portASubModePU removeAllItems];
    [portBSubModePU removeAllItems];
    
    short	i;
    for (i = 0; i < 3; i++) {
        [portASubModePU insertItemWithTitle:[model subModeName:i] atIndex:[portASubModePU numberOfItems]];
        [portBSubModePU insertItemWithTitle:[model subModeName:i] atIndex:[portBSubModePU numberOfItems]];
    }
    
    [self portASubModeChanged:nil];
    [self portBSubModeChanged:nil];
}

@end
