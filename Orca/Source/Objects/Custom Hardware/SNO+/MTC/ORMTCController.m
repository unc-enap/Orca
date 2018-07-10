//
//  ORMTCController.m
//  Orca
//
//Created by Mark Howe on Fri, May 2, 2008
//Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#import "ORMTCController.h"
#import "ORMTCModel.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORValueBar.h"
#import "ORAxis.h"
#import "ORTimeRate.h"
#import "ORMTC_Constants.h"
#import "ORSelectorSequence.h"
#import "ORPQModel.h"


#define VIEW_RAW_UNITS_TAG 0
#define VIEW_mV_UNITS_TAG 1
#define VIEW_NHIT_UNITS_TAG 2

#define FIRST_NHIT_TAG 1
#define VIEW_N100H_TAG 1
#define VIEW_N100M_TAG 2
#define VIEW_N100L_TAG 3
#define VIEW_N20_TAG 4
#define VIEW_N20LB_TAG 5
#define VIEW_OWLN_TAG 6
#define LAST_NHIT_TAG 6

#define FIRST_ESUM_TAG 7
#define VIEW_ESUML_TAG 7
#define VIEW_ESUMH_TAG 8
#define VIEW_OWLEL_TAG 9
#define VIEW_OWLEH_TAG 10
#define LAST_ESUM_TAG 10


#pragma mark •••PrivateInterface
@interface ORMTCController (private)

- (void) setupNHitFormats;
- (void) setupESumFormats;
- (void) storeUserNHitValue:(float)value index:(int) thresholdIndex;
- (void) calcNHitValueForRow:(int) aRow;
- (void) storeUserESumValue:(float)userValue index:(int) thresholdIndex;
- (void) calcESumValueForRow:(int) aRow;

@end

@implementation ORMTCController

-(id)init
{
    self = [super initWithWindowNibName:@"MTC"];
    return self;
}

- (void) awakeFromNib
{
    standardOpsSizeSmall = NSMakeSize(590,300);
    standardOpsSizeLarge = NSMakeSize(590,620);
    settingsSizeSmall	 = NSMakeSize(580,400);
    settingsSizeLarge	 = NSMakeSize(580,520);
    triggerSize          = NSMakeSize(800,655);
    blankView = [[NSView alloc] init];
    [tabView setFocusRingType:NSFocusRingTypeNone];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	[initProgressField setHidden:YES];
    [settingsAdvancedOptionsBox setHidden:YES];
    [opAdvancedOptionsBox setHidden:YES];

    [super awakeFromNib];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORMTC%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;

    [tabView selectTabViewItemAtIndex: index];
    [self populatePullDown];
    [self updateWindow];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];

	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORMTCBasicLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(selectedRegisterChanged:)
                         name : ORMTCModelSelectedRegisterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(memoryOffsetChanged:)
                         name : ORMTCModelMemoryOffsetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(writeValueChanged:)
                         name : ORMTCModelWriteValueChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatCountChanged:)
                         name : ORMTCModelRepeatCountChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatDelayChanged:)
                         name : ORMTCModelRepeatDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useMemoryChanged:)
                         name : ORMTCModelUseMemoryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(autoIncrementChanged:)
                         name : ORMTCModelAutoIncrementChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(basicOpsRunningChanged:)
                         name : ORMTCModelBasicOpsRunningChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mtcPulserRateChanged:)
                         name : ORMTCPulserRateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mtcGTMaskChanged:)
                         name : ORMTCGTMaskChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isPulserFixedRateChanged:)
                         name : ORMTCModelIsPulserFixedRateChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fixedPulserRateCountChanged:)
                         name : ORMTCModelFixedPulserRateCountChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fixedPulserRateDelayChanged:)
                         name : ORMTCModelFixedPulserRateDelayChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sequenceRunning:)
                         name : ORSequenceRunning
						object: model];
						
    [notifyCenter addObserver : self
                     selector : @selector(sequenceStopped:)
                         name : ORSequenceStopped
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sequenceProgress:)
                         name : ORSequenceProgress
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(triggerMTCAMaskChanged:)
                         name : ORMTCModelMTCAMaskChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(updateThresholdsDisplay:)
                         name : ORMTCAThresholdChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateThresholdsDisplay:)
                         name : ORMTCABaselineChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(updateThresholdsDisplay:)
                         name : ORMTCAConversionChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerMTCAMaskChanged:)
                         name : ORMTCAThresholdChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(isPedestalEnabledInCSRChanged:)
                         name : ORMTCModelIsPedestalEnabledInCSR
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(mtcSettingsChanged:)
                         name : ORMTCSettingsChanged
                       object : model];
}

- (void) updateWindow
{
    [super updateWindow];
    [self regBaseAddressChanged:nil];
    [self memBaseAddressChanged:nil];
    [self slotChanged:nil];
    [self basicLockChanged:nil];
	[self selectedRegisterChanged:nil];
	[self memoryOffsetChanged:nil];
	[self writeValueChanged:nil];
	[self repeatCountChanged:nil];
	[self repeatDelayChanged:nil];
	[self useMemoryChanged:nil];
	[self autoIncrementChanged:nil];
	[self basicOpsRunningChanged:nil];
    [self mtcGTMaskChanged:nil];
    [self updateThresholdsDisplay:nil];
    [self mtcPulserRateChanged:nil];
	[self isPulserFixedRateChanged:nil];
	[self fixedPulserRateCountChanged:nil];
	[self fixedPulserRateDelayChanged:nil];
    [self triggerMTCAMaskChanged:nil];
    [self isPedestalEnabledInCSRChanged:nil];
    [self mtcSettingsChanged:nil];
    [lockOutWidthField setIntValue:[model lockoutWidth]];
    [pedestalWidthField setIntValue:[model pedestalWidth]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMTCBasicLock to:secure];
    [basicOpsLockButton setEnabled:secure];
}

#pragma mark •••Interface Management
- (void) sequenceRunning:(NSNotification*)aNote
{
	sequenceRunning = YES;
	[initProgressBar startAnimation:self];
	[initProgressBar setDoubleValue:0];
	[initProgressField setHidden:NO];
	[initProgressField setDoubleValue:0];
    [self basicLockChanged:nil];
    //hack to unlock UI if the sequence couldn't finish and didn't raise an exception (MTCD feature)
    [self performSelector:@selector(sequenceStopped:) withObject:nil afterDelay:5];
}

- (void) sequenceStopped:(NSNotification*)aNote
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[initProgressField setHidden:YES];
	[initProgressBar setDoubleValue:0];
	[initProgressBar stopAnimation:self];
	sequenceRunning = NO;
    [self basicLockChanged:nil];
}

- (void) sequenceProgress:(NSNotification*)aNote
{
	double progress = [[[aNote userInfo] objectForKey:@"progress"] floatValue];
	[initProgressBar setDoubleValue:progress];
	[initProgressField setFloatValue:progress/100.];
}

- (void) mtcPulserRateChanged:(NSNotification *)aNote
{
    int rate = [model pgtRate];
    [pulserPeriodField setIntValue:rate];
}

- (void) mtcGTMaskChanged:(NSNotification *) aNote
{
    int maskValue = [model gtMask];
    for(int i=0;i<26;i++){
        [[globalTriggerMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
    }
}

- (void) updateThresholdsDisplay:(NSNotification *)aNote
{
    int nhit_units,esum_units;
    int nhit_view_unit_index = [[nHitViewTypeMatrix selectedCell] tag];
    int esum_view_unit_index = [[eSumViewTypeMatrix selectedCell] tag];
    @try {
        nhit_units = [self convert_view_unit_index_to_model_index: nhit_view_unit_index];
        esum_units = [self convert_view_unit_index_to_model_index: esum_view_unit_index];
    } @catch (NSException *exception) {
        NSLogColor([NSColor redColor], @"Error displaying updated threshold information. Reason: %@\n",[exception reason]);
        return;
    }
    [self changeNhitThresholdsDisplay:nhit_units];
    [self changeESUMThresholdDisplay:esum_units];
}

- (void) cancelOperation:(id)sender {
    [self endEditing];
    [[self window] makeFirstResponder:nil];
}

- (void) displayMasks
{
	int i;
	int maskValue = [model gtMask];
	for(i=0;i<26;i++){
		[[globalTriggerMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
	}
	maskValue = [model GTCrateMask];
	for(i=0;i<25;i++){
		[[globalTriggerCrateMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
	}
	maskValue = [model pedCrateMask];
	for(i=0;i<25;i++){
		[[pedCrateMaskMatrix cellWithTag:i]  setIntValue: maskValue & (1<<i)];
	}
}

- (void) basicOpsRunningChanged:(NSNotification*)aNote
{
	if([model basicOpsRunning])[basicOpsRunningIndicator startAnimation:model];
	else [basicOpsRunningIndicator stopAnimation:model];
}

- (void) autoIncrementChanged:(NSNotification*)aNote
{
	[autoIncrementCB setIntValue: [model autoIncrement]];
}

- (void) useMemoryChanged:(NSNotification*)aNote
{
	[useMemoryMatrix selectCellWithTag: [model useMemory]];
}

- (void) repeatDelayChanged:(NSNotification*)aNote
{
	[repeatDelayField setIntValue: [model repeatDelay]];
	[repeatDelayStepper setIntValue:   [model repeatDelay]];
}

- (void) repeatCountChanged:(NSNotification*)aNote
{
	[repeatCountField setIntValue:	 [model repeatOpCount]];
	[repeatCountStepper setIntValue: [model repeatOpCount]];
}

- (void) writeValueChanged:(NSNotification*)aNote
{
	[writeValueField setIntValue: [model writeValue]];
}

- (void) memoryOffsetChanged:(NSNotification*)aNote
{
	[memoryOffsetField setIntValue: [model memoryOffset]];
}

- (void) selectedRegisterChanged:(NSNotification*)aNote
{
	[selectedRegisterPU selectItemAtIndex: [model selectedRegister]];
}

- (void) isPulserFixedRateChanged:(NSNotification*)aNote
{
	[[isPulserFixedRateMatrix cellWithTag:1] setIntValue:[model isPulserFixedRate]];
	[[isPulserFixedRateMatrix cellWithTag:0] setIntValue:![model isPulserFixedRate]];
    [self basicLockChanged:nil];
}

- (void) fixedPulserRateCountChanged:(NSNotification*)aNote
{
	[fixedTimePedestalsCountField setIntValue:[model fixedPulserRateCount]];
}

- (void) fixedPulserRateDelayChanged:(NSNotification*)aNote
{
	[fixedTimePedestalsDelayField setFloatValue:[model fixedPulserRateDelay]];
}

- (void) basicLockChanged:(NSNotification*)aNotification
{
    BOOL locked                        = [gSecurity isLocked:ORMTCBasicLock];
    BOOL lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORMTCBasicLock];

    //Basic ops
    [basicOpsLockButton setState: locked];
    [autoIncrementCB setEnabled: !lockedOrNotRunningMaintenance];
    [useMemoryMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [repeatDelayField setEnabled: !lockedOrNotRunningMaintenance];
    [repeatDelayStepper setEnabled: !lockedOrNotRunningMaintenance];
    [repeatCountField setEnabled: !lockedOrNotRunningMaintenance];
    [repeatCountStepper setEnabled: !lockedOrNotRunningMaintenance];
    [writeValueField setEnabled: !lockedOrNotRunningMaintenance];
    [writeValueStepper setEnabled: !lockedOrNotRunningMaintenance];
    [memoryOffsetField setEnabled: !lockedOrNotRunningMaintenance];
    [memoryOffsetStepper setEnabled: !lockedOrNotRunningMaintenance];
    [selectedRegisterPU setEnabled: !lockedOrNotRunningMaintenance];
    [memBaseAddressStepper setEnabled: !lockedOrNotRunningMaintenance];
    [readButton setEnabled: !lockedOrNotRunningMaintenance];
    [writteButton setEnabled: !lockedOrNotRunningMaintenance];
    [stopButton setEnabled: !lockedOrNotRunningMaintenance];
    
    //Standards ops
    lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORMTCBasicLock] | sequenceRunning;
    
    [includePedestalsCheckBox   setEnabled: !locked];
    [initMtcButton				setEnabled: !lockedOrNotRunningMaintenance];
    [firePedestalsButton		setEnabled: !lockedOrNotRunningMaintenance && [model isPulserFixedRate]];
    [stopPedestalsButton		setEnabled: !lockedOrNotRunningMaintenance && [model isPulserFixedRate]];
    [continuePedestalsButton	setEnabled: !lockedOrNotRunningMaintenance && [model isPulserFixedRate]];
    [fireFixedTimePedestalsButton	setEnabled: !lockedOrNotRunningMaintenance  && ![model isPulserFixedRate]];
    [stopFixedTimePedestalsButton	setEnabled: !lockedOrNotRunningMaintenance && ![model isPulserFixedRate]];
    [fixedTimePedestalsCountField	setEnabled: !lockedOrNotRunningMaintenance && ![model isPulserFixedRate]];
    [fixedTimePedestalsDelayField	setEnabled: !lockedOrNotRunningMaintenance && ![model isPulserFixedRate]];
    
    //Settings
    [nhitMatrix                     setEnabled: !locked];
    [esumMatrix                     setEnabled: !locked];
    [lockOutWidthField              setEnabled: !locked];
    [pedestalWidthField             setEnabled: !locked];
    [nhit100LoPrescaleField         setEnabled: !locked];
    [pulserPeriodField              setEnabled: !locked];
    [coarseDelayField               setEnabled: !locked];
    [setAdvancedOptionsButton       setEnabled: !lockedOrNotRunningMaintenance];
    [loadMTCADacsButton				setEnabled: !lockedOrNotRunningMaintenance];

    //Triggers
    [globalTriggerCrateMaskMatrix setEnabled: !locked];
    [globalTriggerMaskMatrix setEnabled: !locked];
    [pedCrateMaskMatrix setEnabled: !locked];
    [mtcaEHIMatrix setEnabled: !locked];
    [mtcaELOMatrix setEnabled: !locked];
    [mtcaN100Matrix setEnabled: !locked];
    [mtcaN20Matrix setEnabled: !locked];
    [mtcaOEHIMatrix setEnabled: !locked];
    [mtcaOELOMatrix setEnabled: !locked];
    [mtcaOWLNMatrix setEnabled: !locked];
    [loadGTCrateMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadMTCACrateMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadPEDCrateMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadTriggerMaskButton setEnabled: !lockedOrNotRunningMaintenance];
}

- (void) isPedestalEnabledInCSRChanged:(NSNotification*)aNotification
{
    [includePedestalsCheckBox setState:[model isPedestalEnabledInCSR]];
}

- (void) mtcSettingsChanged:(NSNotification*)aNotification
{
    [coarseDelayField setFloatValue:[model coarseDelay]];
    [fineDelayField setFloatValue:[model fineDelay]/1000.0];
    [lockOutWidthField setIntValue:[model lockoutWidth]];
    [pedestalWidthField setIntValue:[model pedestalWidth]];
    [nhit100LoPrescaleField setIntValue:[model prescaleValue]];
    [self displayMasks];
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    if ([tabView indexOfTabViewItem:item] == 0) {
        NSSize* newSize =nil;
        if ([opAdvancedOptionsBox isHidden]) {
            newSize = &standardOpsSizeSmall;
        } else {
            newSize = &standardOpsSizeLarge;
        }
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:*newSize];
		[[self window] setContentView:mtcView];
    } else if ([tabView indexOfTabViewItem:item] == 1) {
        NSSize* newSize = nil;
        if ([settingsAdvancedOptionsBox isHidden]) {
            newSize = &settingsSizeSmall;
        } else {
            newSize = &settingsSizeLarge;
        }
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:*newSize];
		[[self window] setContentView:mtcView];
    } else if ([tabView indexOfTabViewItem:item] == 2) {
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:triggerSize];
		[[self window] setContentView:mtcView];
    }

    NSString* key = [NSString stringWithFormat: @"orca.ORMTC%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"MTC Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"MTC Card (Slot %d)",[model slot]]];
}

- (void) regBaseAddressChanged:(NSNotification*)aNotification
{
	[regBaseAddressText setIntValue: [model baseAddress]];
}

- (void) memBaseAddressChanged:(NSNotification*)aNotification
{
	[memBaseAddressText setIntValue: [model memBaseAddress]];
}

- (void) triggerMTCAMaskChanged:(NSNotification*)aNotification
{
    NSArray* matrices = @[mtcaN100Matrix, mtcaN20Matrix, mtcaEHIMatrix, mtcaELOMatrix,
                          mtcaOWLNMatrix,mtcaOEHIMatrix,mtcaOELOMatrix];
    uint32_t masks[7] = {[model mtcaN100Mask],[model mtcaN20Mask],[model mtcaEHIMask],
                            [model mtcaELOMask],[model mtcaOWLNMask],[model mtcaOEHIMask],
                            [model mtcaOELOMask]};
    for (int matrix_index = 0; matrix_index < [matrices count]; matrix_index++) {
        uint32_t maskValue = masks[matrix_index];
        NSMatrix* thisMatrix = matrices[matrix_index];
        for (int i = 0; i < [thisMatrix numberOfRows]; i++) {
            NSCell* thisCell = [thisMatrix cellAtRow:i column:0];
            int bitPos = [thisCell tag];
            [thisCell setIntValue:(maskValue & (1<<bitPos))];
        }
    }
}

#pragma mark •••Actions

- (IBAction) basicAutoIncrementAction:(id)sender
{
	[model setAutoIncrement:[sender intValue]];	
}

//basic ops
- (IBAction) basicUseMemoryAction:(id)sender
{
	[model setUseMemory:[[sender selectedCell] tag]];	
}

- (IBAction) basicRepeatDelayAction:(id)sender
{
	[model setRepeatDelay:[sender intValue]];	
}

- (IBAction) basicRepeatCountAction:(id)sender
{
	[model setRepeatOpCount:[sender intValue]];	
}

- (IBAction) basicWriteValueAction:(id)sender
{
	[model setWriteValue:[sender intValue]];	
}

- (IBAction) basicMemoryOffsetAction:(id)sender
{
	[model setMemoryOffset:[sender intValue]];	
}

- (void) basicSelectedRegisterAction:(id)sender
{
	[model setSelectedRegister:[sender indexOfSelectedItem]];	
}

- (IBAction) basicLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORMTCBasicLock to:[sender intValue] forWindow:[self window]];
}

- (void) populatePullDown
{
    short i;
        
    [selectedRegisterPU removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [selectedRegisterPU insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
     
    [self selectedRegisterChanged:nil];
}

//basic ops Actions
- (IBAction) basicReadAction:(id) sender
{
	[model readBasicOps];
}

- (IBAction) basicWriteAction:(id) sender
{
	[model writeBasicOps];
}

- (IBAction) basicStopAction:(id) sender
{
	[model stopBasicOps];
}

//MTC Init Ops buttons.
- (IBAction) standardInitMTC:(id) sender 
{
    [model initializeMtc];
}

- (IBAction) standardLoadMTCADacs:(id) sender 
{
    @try {
	    [model loadTheMTCADacs];
    } @catch(NSException *excep) {
        NSLogColor([NSColor redColor], @"Error loading the MTCA DACs. Reason: %@\n.",[excep reason]);
    }
}

- (IBAction) setAdvancedOptions:(id)sender
{
    @try {
        [model loadCoarseDelayToHardware];
        [model loadFineDelayToHardware];
        [model loadPrescaleValueToHardware];
        [model loadLockOutWidthToHardware];
        [model loadPedWidthToHardware];
    } @catch (NSException *excep) {
        // Do nothing
        // The above will all catch and warn about any error already
    }
}

- (IBAction) standardIsPulserFixedRate:(id) sender
{
	[self endEditing];
	[model setIsPulserFixedRate:[[sender selectedCell] tag]];
}

- (IBAction) standardFirePedestals:(id) sender 
{
	[model fireMTCPedestalsFixedRate];
}

- (IBAction) standardStopPedestals:(id) sender 
{
	[model stopMTCPedestalsFixedRate];
}

- (IBAction) standardContinuePedestals:(id) sender 
{
	[model continueMTCPedestalsFixedRate];
}

- (IBAction) standardFirePedestalsFixedTime:(id) sender
{
	[model fireMTCPedestalsFixedTime];
}

- (IBAction) standardStopPedestalsFixedTime:(id) sender
{
    @try {
        [model stopMTCPedestalsFixedTime];
    } @catch (NSException* excep) {
        NSLog(@"Failed to stop pulser: %@\n",[excep reason]);
    }
}

- (IBAction) standardSetPedestalsCount:(id) sender
{
	unsigned long aValue = [sender intValue];
	if (aValue < 1) aValue = 1;
	if (aValue > 10000) aValue = 10000;
	[model setFixedPulserRateCount:aValue];
}

- (IBAction) standardSetPedestalsDelay:(id) sender
{
	float aValue = [sender floatValue];
	if (aValue < 0.1) aValue = 0.1;
	if (aValue > 2000000) aValue = 2000000;
	[model setFixedPulserRateDelay:aValue];
}

- (IBAction) standardPulserFeeds:(id)sender
{
    [model setIsPedestalEnabledInCSR:[includePedestalsCheckBox state]];
    [self endEditing];
}

//Settings buttons.
- (IBAction) eSumViewTypeAction:(id)sender
{
    int unit_index;
    int view_index = [[sender selectedCell] tag];
    @try {
        unit_index = [self convert_view_unit_index_to_model_index:view_index];
    } @catch (NSException *exception) {
        NSLogColor([NSColor redColor], @"Could not change views. Reason:%@\n",[exception reason]);
        return;
    }
    [self changeESUMThresholdDisplay:unit_index];
}

- (IBAction) nHitViewTypeAction:(id)sender
{
    int unit_index;
    int view_index = [[sender selectedCell] tag];
    @try {
        unit_index = [self convert_view_unit_index_to_model_index:view_index];
        [self changeNhitThresholdsDisplay: unit_index];
    } @catch (NSException *exception) {
        NSLogColor([NSColor redColor], @"Could not change views. Reason:%@\n",[exception reason]);
    }
}

- (IBAction)opsAdvancedOptionsTriangeChanged:(id)sender
{
    [self showHideOptions:sender Box:opAdvancedOptionsBox resizeSmall:standardOpsSizeSmall resizeLarge:standardOpsSizeLarge];
}

- (IBAction)settingsAdvancedOptionsTriangeChanged:(id)sender
{
    [self showHideOptions:sender Box:settingsAdvancedOptionsBox resizeSmall:settingsSizeSmall resizeLarge:settingsSizeLarge];
}

- (void) showHideOptions:(id) sender Box:(id)box resizeSmall:(NSSize) smallSize resizeLarge:(NSSize) largeSize
{
    if ([sender state] == NSOffState) {
        [box setHidden:YES];
        [self resizeWindowToSize:smallSize];
    } else {
        [box setHidden:NO];
        // Don't resize if the window is already large enough
        if(self.window.frame.size.height <  largeSize.height || self.window.frame.size.width < largeSize.width) {
            [self resizeWindowToSize:largeSize];
        }
    }
}

- (IBAction) settingsLockoutWidthFieldChanged:(id)sender
{
    int lockout_width = [lockOutWidthField intValue];
    [model setLockoutWidth:lockout_width];
}

- (IBAction) settingsPedWidthFieldChanged:(id)sender
{
    int ped_width = [pedestalWidthField intValue];
    [model setPedestalWidth:ped_width];
}

- (IBAction) settingsPrescaleFieldChanged:(id)sender
{
    int prescale_value = [nhit100LoPrescaleField intValue];
    [model setPrescaleValue:prescale_value];
}

- (IBAction) settingsPedDelayFieldChanged:(id)sender
{
    int coarse_delay = [coarseDelayField intValue];
    float fine_delay = [fineDelayField floatValue];
    int fine_delay_ps = fine_delay*1000.0;

    [model setCoarseDelay:coarse_delay];
    [model setFineDelay:fine_delay_ps];
}

- (IBAction) standardPulserRateFieldChanged:(id)sender
{
    float pulser_rate = [pulserPeriodField floatValue];
    [model setPgtRate:pulser_rate];
}

- (void) changeNhitThresholdsDisplay: (int) units
{
    int threshold_index;
    float value;
    for(int i=FIRST_NHIT_TAG;i<=LAST_NHIT_TAG;i++) {
        @try {
            threshold_index = [self convert_view_threshold_index_to_model_index:i];
            if(![model ConversionIsValidForThreshold:threshold_index] && units!=MTC_RAW_UNITS) {
                [[nhitMatrix cellWithTag:i] setEnabled:NO];
                [[nhitMatrix cellWithTag:i] setStringValue:@"--"];
                continue;
            }
            [[nhitMatrix cellWithTag:i] setEnabled:YES];
            value = [model getThresholdOfType: threshold_index inUnits:units];
        } @catch (NSException *exception) {
            NSLogColor([NSColor redColor], @"Failed to interpret field with tag %i, Reason: %@\n. Aborting after %i changes already made\n", i,[exception reason],i-FIRST_NHIT_TAG);
            [self basicLockChanged:nil];
            return;
        }
        [[nhitMatrix cellWithTag:i] setFloatValue: value];
    }
    [self basicLockChanged:nil];
}

- (void) changeESUMThresholdDisplay: (int) units
{
    int threshold_index;
    float value;
    for (int i = FIRST_ESUM_TAG; i <= LAST_ESUM_TAG; i++) {
        @try {
            threshold_index = [self convert_view_threshold_index_to_model_index:i];
            if (![model ConversionIsValidForThreshold:threshold_index] && units!=MTC_RAW_UNITS) {
                [[esumMatrix cellWithTag:i] setEnabled:NO];
                [[esumMatrix cellWithTag:i] setStringValue:@"--"];
                continue;
            }
            [[esumMatrix cellWithTag:i] setEnabled:YES];
            value = [model getThresholdOfType: threshold_index inUnits:units];
        } @catch (NSException *exception) {
            NSLogColor([NSColor redColor], @"Failed to interpret field with tag %i, Reason: %@\n. Aborting after %i changes already made\n", i,[exception reason],i-FIRST_ESUM_TAG);
            [self basicLockChanged:nil];
            return;
        }
        [[esumMatrix cellWithTag:i] setFloatValue: value];
    }
    [self basicLockChanged:nil];
}

- (int) convert_view_threshold_index_to_model_index: (int) view_index
{
    switch (view_index) {
        case VIEW_N100H_TAG:
            return MTC_N100_HI_THRESHOLD_INDEX;
            break;
        case VIEW_N100M_TAG:
            return MTC_N100_MED_THRESHOLD_INDEX;
            break;
        case VIEW_N100L_TAG:
            return MTC_N100_LO_THRESHOLD_INDEX;
            break;
        case VIEW_N20_TAG:
            return MTC_N20_THRESHOLD_INDEX;
            break;
        case VIEW_N20LB_TAG:
            return MTC_N20LB_THRESHOLD_INDEX;
            break;
        case VIEW_ESUMH_TAG:
            return MTC_ESUMH_THRESHOLD_INDEX;
            break;
        case VIEW_ESUML_TAG:
            return MTC_ESUML_THRESHOLD_INDEX;
            break;
        case VIEW_OWLEH_TAG:
            return MTC_OWLEHI_THRESHOLD_INDEX;
            break;
        case VIEW_OWLEL_TAG:
            return MTC_OWLELO_THRESHOLD_INDEX;
            break;
        case VIEW_OWLN_TAG:
            return MTC_OWLN_THRESHOLD_INDEX;
            break;
        default:
            [NSException raise:@"MTCController" format:@"Cannot convert threshold index %i to model index",view_index];
            break;
    }
    return -1; // Will never reach here
}

- (int) convert_model_threshold_index_to_view_index: (int) model_index
{
    switch (model_index) {
        case MTC_N100_HI_THRESHOLD_INDEX:
            return VIEW_N100H_TAG;
            break;
        case MTC_N100_MED_THRESHOLD_INDEX:
            return VIEW_N100M_TAG;
            break;
        case MTC_N100_LO_THRESHOLD_INDEX:
            return VIEW_N100L_TAG;
            break;
        case MTC_N20_THRESHOLD_INDEX:
            return VIEW_N20_TAG;
            break;
        case MTC_N20LB_THRESHOLD_INDEX:
            return VIEW_N20LB_TAG;
            break;
        case MTC_ESUMH_THRESHOLD_INDEX:
            return VIEW_ESUMH_TAG;
            break;
        case MTC_ESUML_THRESHOLD_INDEX:
            return VIEW_ESUML_TAG;
            break;
        case MTC_OWLEHI_THRESHOLD_INDEX:
            return VIEW_OWLEH_TAG;
            break;
        case MTC_OWLELO_THRESHOLD_INDEX:
            return VIEW_OWLEL_TAG;
            break;
        case MTC_OWLN_THRESHOLD_INDEX:
            return VIEW_OWLN_TAG;
            break;
        default:
            [NSException raise:@"MTCController" format:@"Cannot convert threshold  index %i to view index",model_index];
        break;
    }
    return -1;
}

- (int) convert_view_unit_index_to_model_index: (int) view_index
{
    switch (view_index) {
        case VIEW_RAW_UNITS_TAG:
            return MTC_RAW_UNITS;
            break;
        case VIEW_mV_UNITS_TAG:
            return MTC_mV_UNITS;
            break;
        case VIEW_NHIT_UNITS_TAG:
            return MTC_NHIT_UNITS;
            break;
        default:
            [NSException raise:@"MTCController" format:@"Cannot convert units index %i to model index",view_index];
            break;
    }
    return -1;
}

- (int) convert_model_unit_index_to_view_index: (int) model_index
{
    switch (model_index) {
        case MTC_RAW_UNITS:
            return VIEW_RAW_UNITS_TAG;
            break;
        case MTC_mV_UNITS:
            return VIEW_NHIT_UNITS_TAG;
            break;
        case MTC_NHIT_UNITS:
            return VIEW_NHIT_UNITS_TAG;
            break;
        default:
            [NSException raise:@"MTCController" format:@"Cannot convert units index %i to view index",model_index];
            break;
    }
    return -1;
}

- (IBAction) settingsNHitAction:(id) sender 
{
    int threshold_index, unit_index;
    @try {
        threshold_index = [self convert_view_threshold_index_to_model_index:[[sender selectedCell] tag]];
        unit_index = [self convert_view_unit_index_to_model_index:[[nHitViewTypeMatrix selectedCell] tag]];
        float threshold = [[sender selectedCell] floatValue];
        [model setThresholdOfType:threshold_index fromUnits:unit_index toValue:threshold];
    } @catch (NSException *exception) {
        NSLogColor([NSColor redColor], @"Error when setting threshold. Reason: %@\n Aborting\n",[exception reason]);
    }
}

- (IBAction) settingsESumAction:(id) sender 
{
    int threshold_index, unit_index;
    @try {
        threshold_index = [self convert_view_threshold_index_to_model_index:[[sender selectedCell]tag]];
        unit_index = [self convert_view_unit_index_to_model_index:[[eSumViewTypeMatrix selectedCell] tag]];
        float threshold = [[sender selectedCell] floatValue];
        [model setThresholdOfType:threshold_index fromUnits:unit_index toValue:threshold];
    } @catch (NSException *excep) {
        NSLogColor([NSColor redColor], @"Error when setting threshold. Reason: %@\n Aborting\n",[excep reason]);
    }
}

- (IBAction) updateConversionSettingsAction:(id)sender
{
    [model getLatestTriggerScans];
}

- (IBAction) grab_current_thresholds:(id)sender
{
    [model updateTriggerThresholds];
}

- (uint32_t) gatherMaskFromCheckBoxes:(NSMatrix *) boxes
{
    uint32_t mask = 0;
    for (int i = 0; i < [boxes numberOfRows]; i++){
        if([[boxes cellAtRow:i column:0] intValue]) {
            int position = [[boxes cellAtRow:i column:0] tag];
            mask |= (1L << position);
        }
    }
    return mask;
}

- (IBAction) settingsGTMaskAction:(id) sender
{
    uint32_t mask = 0;
    [self CheckBoxMatrixCellClicked:sender newState:![[sender selectedCell] nextState]];
    mask = [self gatherMaskFromCheckBoxes:sender];
	[model setGtMask:mask];
}

- (IBAction) settingsGTCrateMaskAction:(id) sender 
{
    uint32_t mask;
    [self CheckBoxMatrixCellClicked:sender newState:![[sender selectedCell] nextState]];
    mask = [self gatherMaskFromCheckBoxes:sender];
	[model setGTCrateMask:mask];
}

- (IBAction) settingsPEDCrateMaskAction:(id) sender
{
    uint32_t mask;
    [self CheckBoxMatrixCellClicked:sender newState:![[sender selectedCell] nextState]];
    mask = [self gatherMaskFromCheckBoxes:sender];
    [model setPedCrateMask:mask];
}


- (IBAction) triggerMTCAN100:(id) sender
{
    uint32_t mask;
    [self CheckBoxMatrixCellClicked:sender newState:![[sender selectedCell] nextState]];
    mask = [self gatherMaskFromCheckBoxes:sender];
    [model setMtcaN100Mask:mask];
}

- (IBAction) triggerMTCAN20:(id) sender
{
    uint32_t mask;
    [self CheckBoxMatrixCellClicked:sender newState:![[sender selectedCell] nextState]];
    mask = [self gatherMaskFromCheckBoxes:sender];
    [model setMtcaN20Mask:mask];
}

- (IBAction) triggerMTCAEHI:(id) sender
{
    uint32_t mask;
    [self CheckBoxMatrixCellClicked:sender newState:![[sender selectedCell] nextState]];
    mask = [self gatherMaskFromCheckBoxes:sender];
    [model setMtcaEHIMask:mask];
}

- (IBAction) triggerMTCAELO:(id) sender
{
    uint32_t mask;
    [self CheckBoxMatrixCellClicked:sender newState:![[sender selectedCell] nextState]];
    mask = [self gatherMaskFromCheckBoxes:sender];

    [model setMtcaELOMask:mask];
}

- (IBAction) triggerMTCAOELO:(id) sender
{
    uint32_t mask = 0;
    [self CheckBoxMatrixCellClicked:sender newState:![[sender selectedCell] nextState]];
    mask = [self gatherMaskFromCheckBoxes:sender];
    [model setMtcaOELOMask:mask];
}

- (IBAction) triggerMTCAOEHI:(id) sender
{
    uint32_t mask;
    [self CheckBoxMatrixCellClicked:sender newState:![[sender selectedCell] nextState]];
    mask = [self gatherMaskFromCheckBoxes:sender];
    [model setMtcaOEHIMask:mask];
}

- (IBAction) triggerMTCAOWLN:(id) sender
{
    uint32_t mask;
    [self CheckBoxMatrixCellClicked:sender newState:![[sender selectedCell] nextState]];
    mask = [self gatherMaskFromCheckBoxes:sender];
    [model setMtcaOWLNMask:mask];
}

- (IBAction) triggersLoadTriggerMask:(id) sender
{
    @try {
        [model setGlobalTriggerWordMask];
    } @catch (NSException* excep) {
        //pass, the model already warns
    }
}

- (IBAction) triggersLoadGTCrateMask:(id) sender
{
    @try {
        [model loadGTCrateMaskToHardware];
    } @catch (NSException* excep) {
        // pass, the model already warns
    }
}

- (IBAction) triggersLoadPEDCrateMask:(id) sender
{
    @try {
        [model loadPedestalCrateMaskToHardware];
    } @catch (NSException* excep) {
        // pass, the model already warns
    }
}

- (IBAction) triggersLoadMTCACrateMask:(id) sender
{
    @try {
        [model mtcatLoadCrateMasks];
    } @catch (NSException* excep) {
        //pass, the model already warns
    }
}

- (IBAction) helpButtonClicked:(id)sender
{
    [helpText setHidden:![helpText isHidden]];
}

- (void)CheckBoxMatrixCellClicked:(NSMatrix*) checkBoxes newState:(int)state
{
    BOOL cmdKeyDown = ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) != 0;
    if (cmdKeyDown) {
        for (int i = 0; i < [checkBoxes numberOfRows]; i++) {
            [[checkBoxes cellAtRow:i column:0] setState: state];
        }
    }
}
@end
