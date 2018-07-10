//
//  ORHV4032Contoller.m
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORHV4032Controller.h"
#import "ORHV4032Model.h"
#import "ORHV2132Model.h"
#import "ORHV4032Supply.h"
#import "ORTimedTextField.h"

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
@interface ORHV4032Controller (private)
- (void) _openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) _startRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _systemPanicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _syncActionSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
@end
#endif

@implementation ORHV4032Controller
- (id) init
{
    self = [super initWithWindowNibName:@"HV4032"];
    return self;
}

- (void) awakeFromNib
{
    [model pollHardware];
    [self performSelector:@selector(updateButtons) withObject:nil afterDelay:2];
	
	int i;
	for(i=0;i<kHV4032NumberSupplies;i++){
		[[controlMatrix cellAtRow:i column:0] setTag:i];
		[[timeMatrix cellAtRow:i column:0] setTag:i];
		[[targetMatrix cellAtRow:i column:0] setTag:i];
		[[dacMatrix cellAtRow:i column:0] setTag:i];
		[[adcMatrix cellAtRow:i column:0] setTag:i];
		[[stateMatrix cellAtRow:i column:0] setTag:i];
		[[voltageAdcOffsetMatrix cellAtRow:i column:0] setTag:i];
		[[voltageAdcSlopeMatrix cellAtRow:i column:0] setTag:i];
	}
#	ifndef HV2132ReadWorking
	[warningField setStringValue:@"WARNING: code in progress. Readback is faked using HV File"];
#	else
	[warningField setStringValue:@""];
#	endif
	
    [super awakeFromNib];
}


- (void) dealloc
{
    [super dealloc];
}

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingStateChanged:)
                         name : HV4032PollingStateChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rampStartedOrStopped:)
                         name : HV4032StartedNotification
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(rampStartedOrStopped:)
                         name : HV4032StoppedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(controllChanged:)
                         name : ORHV4032SupplyControlChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rampTimeChanged:)
                         name : ORHV4032SupplyRampTimeChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(targetChanged:)
                         name : ORHV4032SupplyTargetChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dacChanged:)
                         name : ORHV4032SupplyDacChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(adcChanged:)
                         name : ORHV4032SupplyAdcChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORHV4032SupplyRampStateChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(hvStateChanged:)
                         name : ORHV4032ModelHvStateChanged
						object: model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(voltageAdcOffsetChanged:)
                         name : ORHV4032SupplyVoltageAdcOffsetChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(voltageAdcSlopeChanged:)
                         name : ORHV4032SupplyVoltageAdcSlopeChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(calibrationLockChanged:)
                         name : HV4032CalibrationLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(runStatusChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(hvLockChanged:)
                         name : HV4032Lock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(supplyPresentChanged:)
                         name : ORHV4032SupplyIsPresentChanged
						object: nil];
	
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    
    [gSecurity setLock:HV4032CalibrationLock to:secure];
    [calibrationLockButton setEnabled:secure];
	
    [gSecurity setLock:HV4032Lock to:secure];
    [hvLockButton setEnabled:secure];
    [self updateButtons];
	
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self pollingStateChanged:nil];
	
    [self controllChanged:nil];
    [self rampTimeChanged:nil];
    [self targetChanged:nil];
    [self dacChanged:nil];
    [self adcChanged:nil];
    [self stateChanged:nil];
    [self voltageAdcOffsetChanged:nil];
    [self voltageAdcSlopeChanged:nil];
    [self runStatusChanged:nil];
    [self hvLockChanged:nil];
    [self calibrationLockChanged:nil];
	[self supplyPresentChanged:nil];
}

- (void) uniqueIDChanged:(NSNotification*)aNotification
{
	unsigned long i = [model mainFrameID];
	if(i!=0xffffffff)[[self window] setTitle:[NSString stringWithFormat:@"HV4032-%lu",[model mainFrameID]]];
	else [[self window] setTitle:[NSString stringWithFormat:@"HV4032-NOT CONNECTED"]];
}

- (void) setModel:(id)aModel
{    
    [super setModel:aModel];
	[self uniqueIDChanged:nil];
    [self updateWindow];
}

- (void) pollingStateChanged:(NSNotification*)aNotification
{
	// if([pollingButton indexOfSelectedItem]!=[model pollingState]){
	[pollingButton selectItemAtIndex:[pollingButton indexOfItemWithTag:[model pollingState]]];
	// }
	if([model pollingState] == 0){
		[pollingAlertField setStringValue:@"Polling is OFF"];
	}
	else {
		[pollingAlertField setStringValue:@" "];
	}
	
}
- (void) rampStartedOrStopped:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) controllChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHV4032Supply* aSupply = [[aNotification userInfo] objectForKey:ORHV4032SupplyId];
		[[controlMatrix cellWithTag:[aSupply supply]] setState:[aSupply controlled]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHV4032Supply* s;
		while(s = [e nextObject]){
            BOOL value      = [s controlled];
            NSCell* control = [controlMatrix cellWithTag:[s supply]];
            if (value != [control state]) {
                [control setState:(value ? NSOnState : NSOffState)];
           }
		}
	}
	[self updateButtons];   
}

- (void) rampTimeChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHV4032Supply* aSupply = [[aNotification userInfo] objectForKey:ORHV4032SupplyId];
		[[timeMatrix cellWithTag:[aSupply supply]] setIntValue: [aSupply rampTime]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHV4032Supply* s;
		while(s = [e nextObject]){
			[[timeMatrix cellWithTag:[s supply]] setIntValue: [s rampTime]];
		}
	}
}

- (void) targetChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHV4032Supply* aSupply = [[aNotification userInfo] objectForKey:ORHV4032SupplyId];
		[[targetMatrix cellWithTag:[aSupply supply]] setIntValue: [aSupply targetVoltage]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHV4032Supply* s;
		while(s = [e nextObject]){
			[[targetMatrix cellWithTag:[s supply]] setIntValue: [s targetVoltage]];
		}
	}
}

- (void) dacChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHV4032Supply* aSupply = [[aNotification userInfo] objectForKey:ORHV4032SupplyId];
		[[dacMatrix cellWithTag:[aSupply supply]] setIntValue: [aSupply dacValue]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHV4032Supply* s;
		while(s = [e nextObject]){
			[[dacMatrix cellWithTag:[s supply]] setIntValue: [s dacValue]];
		}
	}
}


- (void) adcChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHV4032Supply* aSupply = [[aNotification userInfo] objectForKey:ORHV4032SupplyId];
		[[ adcMatrix cellWithTag:[aSupply supply]] setIntValue: [aSupply adcVoltage]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHV4032Supply* s;
		while(s = [e nextObject]){
			[[ adcMatrix cellWithTag:[s supply]] setIntValue: [s adcVoltage]];
		}
	}
	
	[self updateButtons];   
}

- (void) hvStateChanged:(NSNotification*)aNotification
{
	[self stateChanged:nil];
}

- (void) stateChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHV4032Supply* aSupply = [[aNotification userInfo] objectForKey:ORHV4032SupplyId];
		if(aSupply){
			NSTextFieldCell* cell = [stateMatrix cellWithTag:[aSupply supply]];
			[cell setStringValue: [aSupply state]];
			[self setTextColor: cell supply:aSupply];
		}
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHV4032Supply* s;
		while(s = [e nextObject]){
			NSTextFieldCell* cell = [stateMatrix cellWithTag:[s supply]];
			[cell setStringValue: [s state]];
			[self setTextColor: cell supply:s];
		}
	}
	[self updateButtons];   
}

- (void) voltageAdcOffsetChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHV4032Supply* aSupply = [[aNotification userInfo] objectForKey:ORHV4032SupplyId];
		[[voltageAdcOffsetMatrix cellWithTag:[aSupply supply]] setFloatValue: [aSupply voltageAdcOffset]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHV4032Supply* s;
		while(s = [e nextObject]){
			[[voltageAdcOffsetMatrix cellWithTag:[s supply]] setFloatValue: [s voltageAdcOffset]];
		}
	}
}

- (void) voltageAdcSlopeChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHV4032Supply* aSupply = [[aNotification userInfo] objectForKey:ORHV4032SupplyId];
		[[voltageAdcSlopeMatrix cellWithTag:[aSupply supply]] setFloatValue: [aSupply voltageAdcSlope]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHV4032Supply* s;
		while(s = [e nextObject]){
			[[voltageAdcSlopeMatrix cellWithTag:[s supply]] setFloatValue: [s voltageAdcSlope]];
		}
	}
}

- (void) hvLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:HV4032Lock];
    [hvLockButton setState: locked];
    [self updateButtons];
}


- (void) runStatusChanged:(NSNotification*)aNotification
{
    [self updateButtons];
}

- (void) calibrationLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:HV4032CalibrationLock];
    [calibrationLockButton setState: locked];
    
    [voltageAdcOffsetMatrix setEnabled:!locked];
    [voltageAdcSlopeMatrix setEnabled:!locked];   
}


- (void) supplyPresentChanged:(NSNotification*)aNotification
{
	if(aNotification){
		id theSupply = [[aNotification userInfo] objectForKey:ORHV4032SupplyId];
		if([theSupply owner] == model){
			int supplyIndex = [theSupply supply];
			BOOL isPresent = [theSupply isPresent];
			[[controlMatrix cellWithTag:supplyIndex] setEnabled:isPresent];
			[[timeMatrix cellWithTag:supplyIndex] setEnabled:isPresent];
			[[targetMatrix cellWithTag:supplyIndex] setEnabled:isPresent];
			[[dacMatrix cellWithTag:supplyIndex] setEnabled:isPresent];
			[[adcMatrix cellWithTag:supplyIndex] setEnabled:isPresent];
			[[stateMatrix cellWithTag:supplyIndex] setEnabled:isPresent];
		}
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHV4032Supply* s;
		while(s = [e nextObject]){
			int supplyIndex = [s supply];
			[[controlMatrix cellWithTag:supplyIndex] setEnabled:NO];
			[[timeMatrix cellWithTag:supplyIndex] setEnabled:NO];
			[[targetMatrix cellWithTag:supplyIndex] setEnabled:NO];
			[[dacMatrix cellWithTag:supplyIndex] setEnabled:NO];
			[[adcMatrix cellWithTag:supplyIndex] setEnabled:NO];
			[[stateMatrix cellWithTag:supplyIndex] setEnabled:NO];
		}
	}
}


- (void) setTextColor:(NSTextFieldCell*)aCell supply:(ORHV4032Supply*)aSupply
{
    switch([aSupply rampState]){
        case kHV4032Up:
        case kHV4032Down:
        case kHV4032Zero:
        case kHV4032Panic:
            [aCell setTextColor:[NSColor orangeColor]];
			break;
        default: 
			[aCell setTextColor:[NSColor blackColor]];	 
			break;
			
    }
}

#pragma mark ¥¥¥Actions
- (IBAction) turnHVOnAction:(id)sender
{
    [self endEditing];
    [model turnHVOn:YES];
    [model saveHVParams];
    [self stateChanged:nil];
}

- (IBAction) turnHVOffAction:(id)sender
{
    [self endEditing];
    [model turnHVOn:NO];
    [model saveHVParams];
    [self stateChanged:nil];
}

- (IBAction) startRampAction:(id)sender
{
    [self endEditing];
    [model pollHardware];
	
    if(![model checkActualVsSetValues]){
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:@"High Voltage Set Value != Actual Value"];
        [alert setInformativeText:@"You can not Ramp HV until this problem is resolved.\nWhat would like to do?"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Set DACs = ADC's"];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
            if (result == NSAlertSecondButtonReturn){
                [model resolveActualVsSetValueProblem];
                [model initializeStates];
                [model startRamping];
                [self updateButtons];
            }
        }];
#else
        NSBeginAlertSheet(@"High Voltage Set Value != Actual Value",
						  @"Cancel",
						  @"Set DACs = ADC's",
						  nil,[self window],
						  self,
						  @selector(_startRampSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  nil,
						  @"You can not Ramp HV until this problem is resolved.\nWhat would like to do?");
#endif
    }
    else {
		[model initializeStates];
		[model startRamping];
		[self updateButtons];
    }
}


#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void)_startRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){
		[model resolveActualVsSetValueProblem];
		[model initializeStates];
		[model startRamping];
		[self updateButtons];
    }
	
}
#endif

- (IBAction) stopRampAction:(id)sender
{
    [model stopRamping];
    [self updateButtons];
}

- (IBAction) rampToZeroAction:(id)sender
{
    [self endEditing];
    [model setStates:kHV4032Zero onlyControlled:YES];
    [model startRamping];
    [self updateButtons];
}

- (IBAction) panicAction:(id)sender
{
    [self endEditing];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"HV Panic"];
    [alert setInformativeText:@"Really Panic Selected High Voltage OFF?"];
    [alert addButtonWithTitle:@"Yes, Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model setStates:kHV4032Panic onlyControlled:YES];
            [model startRamping];
            [self updateButtons];
        }
    }];
#else
    NSBeginAlertSheet(@"HV Panic",
					  @"YES/Do it NOW",
					  @"Canel",
					  nil,[self window],
					  self,
					  @selector(_panicRampSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Really Panic Selected High Voltage OFF?");
	
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertDefaultReturn){
        [model setStates:kHV4032Panic onlyControlled:YES];
		[model startRamping];
		[self updateButtons];
    }
}
#endif
- (IBAction) panicSystemAction:(id)sender
{
    [self endEditing];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"HV Panic"];
    [alert setInformativeText:@"Really Panic ALL High Voltage OFF?"];
    [alert addButtonWithTitle:@"Yes, Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model setStates:kHV4032Panic onlyControlled:NO];
            [model startRamping];
            [self updateButtons];
        }
    }];
#else
    NSBeginAlertSheet(@"HV Panic",
					  @"YES/Do it NOW",
					  @"Canel",
					  nil,[self window],
					  self,
					  @selector(_systemPanicRampSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Really Panic ALL High Voltage OFF?");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _systemPanicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertDefaultReturn){
        [model setStates:kHV4032Panic onlyControlled:NO];
		[model startRamping];
		[self updateButtons];
    }
}
#endif
- (IBAction) syncAction:(id)sender;
{
    [self endEditing];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Sync DACs to ADCs"];
    [alert setInformativeText:@"Really move ADC values into DAC fields?"];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model forceDacToAdc];
            [self updateButtons];
        }
    }];
#else
    NSBeginAlertSheet(@"Sync DACs to ADCs",
					  @"YES",
					  @"Canel",
					  nil,[self window],
					  self,
					  @selector(_syncActionSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Really move ADC values into DAC fields?");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _syncActionSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertDefaultReturn){
		[model forceDacToAdc];
		[self updateButtons];
    }
}
#endif

- (IBAction) setPollingAction:(id)sender
{
    [model setPollingState:(NSTimeInterval)[[sender selectedItem] tag]];
}

- (IBAction) pollNowAction:(id)sender
{
    [model pollHardware];
}



- (IBAction) controllAction:(id)sender
{
    [self endEditing];
    int i = [[sender selectedCell] tag];
    if([sender intValue] != [[[model supplies] objectAtIndex:i] controlled]){
		[[self undoManager] setActionName: @"Set HV Controlled"];
		[[[model supplies] objectAtIndex:i] setControlled: [sender intValue]];
		[self updateButtons];
    }
}

- (IBAction) rampTimeAction:(id)sender
{
    [self endEditing];
    int i = [[sender selectedCell] tag];
    if([sender intValue] != [[[model supplies] objectAtIndex:i] rampTime]){
		[[self undoManager] setActionName: @"Set HV Ramp Time"];
		[[[model supplies] objectAtIndex:i] setRampTime: [sender intValue]];
    }
}

- (IBAction) targetAction:(id)sender
{
    int i = [[sender selectedCell] tag];
    if([sender intValue] != [[[model supplies] objectAtIndex:i] targetVoltage]){
		[[self undoManager] setActionName: @"Set HV Ramp Time"];
		[[[model supplies] objectAtIndex:i] setTargetVoltage: [sender intValue]];
    }
}

- (IBAction) adcOffsetAction:(id)sender
{
    int i = [[sender selectedCell] tag];
    if([sender floatValue] != [[[model supplies] objectAtIndex:i] voltageAdcOffset]){
		[[self undoManager] setActionName: @"Set HV Adc Offset"];
		[[[model supplies] objectAtIndex:i] setVoltageAdcOffset: [sender floatValue]];
    }
	
}

- (IBAction) adcSlopeAction:(id)sender
{
	int i = [[sender selectedCell] tag];
    if([sender floatValue] != [[[model supplies] objectAtIndex:i] voltageAdcSlope]){
		[[self undoManager] setActionName: @"Set HV ADC Slope"];
		[[[model supplies] objectAtIndex:i] setVoltageAdcSlope: [sender floatValue]];
    }
}

- (IBAction) calibrationLockAction:(id)sender
{
    [gSecurity tryToSetLock:HV4032CalibrationLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) hvLockAction:(id)sender
{
    [gSecurity tryToSetLock:HV4032Lock to:[sender intValue] forWindow:[self window]];
}

- (void) updateButtons
{	
	
    BOOL ramping = [model rampTimer] != nil;
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:HV4032Lock];
    BOOL locked = [gSecurity isLocked:HV4032Lock];
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    
    //default state
    [onButton setEnabled:NO];
    [offButton setEnabled:NO];
    [startRampButton setEnabled:NO];
    [stopRampButton setEnabled:NO];
    [rampToZeroButton setEnabled:NO];
    [panicButton setEnabled:NO];
    [syncButton setEnabled:!locked];
	
    BOOL anyControlled		= [model anyControlledSupplies];
	//BOOL anyVoltagePresent	= [model significantVoltagePresent];
    BOOL hvIsOn				= [model hvOn];
	
    if(hvIsOn){
        [statusButton setTitle:@"Panic ALL HV..."];
        [statusButton setEnabled:YES];
        [statusImage setImage:[NSImage imageNamed:@"HV4032On"]];
    }
    else {
        [statusButton setTitle:@"HV IS OFF"];
        [statusButton setEnabled:NO];
        [statusImage setImage:[NSImage imageNamed:@"HV4032Off"]];
    }
	
    if(anyControlled && !lockedOrRunningMaintenance){
		
        BOOL significantVoltagePresent = [model significantVoltagePresent];
        BOOL hasBeenPolled	 = [model hasBeenPolled];
        
        if([model rampTimer] != nil || significantVoltagePresent || !hasBeenPolled) {
            //we are ramping or there is voltage on, disable the appropriate buttons
            [onButton setEnabled:NO];
            [offButton setEnabled:NO];
        }
        else {
            if(hvIsOn){
                [onButton setEnabled:NO];
                [offButton setEnabled:YES];  
            }
            else {
                [onButton setEnabled:YES];
                [offButton setEnabled:NO];  
            }
            
        } 
        
        //the ramping buttons
        if([model rampTimer] != nil){
            //ramp in progress
            [startRampButton setEnabled:NO];
            [stopRampButton setEnabled:YES];
            [panicButton setEnabled:YES];
            [rampToZeroButton setEnabled:NO];
        }
        else {
            //not ramping
            if(hvIsOn){
                [startRampButton setEnabled:YES];
                [stopRampButton setEnabled:NO];
                [rampToZeroButton setEnabled:YES];
                [panicButton setEnabled:YES];
            }
		}
    }
	
	
    [syncButton setEnabled:!(ramping || lockedOrRunningMaintenance)];
    
    [controlMatrix setEnabled:!(ramping || lockedOrRunningMaintenance)];
    [timeMatrix setEnabled:!(ramping || lockedOrRunningMaintenance)];
    [targetMatrix setEnabled:!(ramping || lockedOrRunningMaintenance)];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:HV4032Lock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
}



@end
