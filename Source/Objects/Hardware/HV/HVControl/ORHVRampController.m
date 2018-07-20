//
//  ORHVRampContoller.m
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
#import "ORHVRampController.h"
#import "ORHVRampModel.h"
#import "ORHVSupply.h"
#import "ORCompositePlotView.h"
#import "ORTimeLinePlot.h"
#import "ORAxis.h"


#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
@interface ORHVRampController (private)
- (void) _startRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _systemPanicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _syncActionSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
@end
#endif

@implementation ORHVRampController
- (id) init
{
    self = [super initWithWindowNibName:@"HVRamp"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [model pollHardware:model];
    [self performSelector:@selector(updateButtons) withObject:nil afterDelay:2];
	[[currentPlotter yAxis] setRngLimitsLow:0 withHigh:100 withMinRng:10];
	
	ORTimeLinePlot* aPlot;
	
	int i;
	NSColor* aColor = [NSColor redColor];
	for(i=0;i<8;i++){
		switch(i){
			case 0: aColor =[NSColor redColor]; break;
			case 1: aColor = [NSColor greenColor]; break;
			case 2: aColor = [NSColor blueColor]; break;
			case 3: aColor = [NSColor cyanColor]; break;
			case 4: aColor = [NSColor yellowColor]; break;
			case 5: aColor = [NSColor magentaColor]; break;
			case 6: aColor = [NSColor orangeColor]; break;
			case 7: aColor = [NSColor purpleColor]; break;
		}
		aPlot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[aPlot setUseConstantColor:YES];
		[aPlot setLineColor: aColor];
		[currentPlotter addPlot: aPlot];
		[aPlot release];
	}
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"HV Ramper (%u)",[model uniqueIdNumber]]];
}

- (void) dealloc
{
    [super dealloc];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingStateChanged:)
                         name : HVPollingStateChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rampStartedOrStopped:)
                         name : HVRampStartedNotification
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(rampStartedOrStopped:)
                         name : HVRampStoppedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(controllChanged:)
                         name : ORHVSupplyControlChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rampTimeChanged:)
                         name : ORHVSupplyRampTimeChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(targetChanged:)
                         name : ORHVSupplyTargetChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dacChanged:)
                         name : ORHVSupplyDacChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(adcChanged:)
                         name : ORHVSupplyAdcChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(currentChanged:)
                         name : ORHVSupplyCurrentChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORHVSupplyRampStateChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dirChanged:)
                         name : HVStateFileDirChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORHVSupplyActualRelayChangedNotification
						object: model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(voltageAdcOffsetChanged:)
                         name : ORHVSupplyVoltageAdcOffsetChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(voltageAdcSlopeChanged:)
                         name : ORHVSupplyVoltageAdcSlopeChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(calibrationLockChanged:)
                         name : HVRampCalibrationLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(runStatusChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(hvLockChanged:)
                         name : HVRampLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(saveCurrentToFileChanged:)
                         name : ORHVRampModelSaveCurrentToFileChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(currentFileChanged:)
                         name : ORHVRampModelCurrentFileChanged
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(updateTrends:)
                         name : ORHVRampModelUpdatedTrends
						object: nil];
	
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    
    [gSecurity setLock:HVRampCalibrationLock to:secure];
    [calibrationLockButton setEnabled:secure];
	
    [gSecurity setLock:HVRampLock to:secure];
    [hvLockButton setEnabled:secure];
    [self updateButtons];
	
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self pollingStateChanged:nil];
    [self dirChanged:nil];
	
    [self controllChanged:nil];
    [self rampTimeChanged:nil];
    [self targetChanged:nil];
    [self dacChanged:nil];
    [self adcChanged:nil];
    [self currentChanged:nil];
    [self stateChanged:nil];
    [self voltageAdcOffsetChanged:nil];
    [self voltageAdcSlopeChanged:nil];
    [self runStatusChanged:nil];
    [self hvLockChanged:nil];
    [self calibrationLockChanged:nil];
	[self saveCurrentToFileChanged:nil];
	[self currentFileChanged:nil];
	[self updateTrends:nil];

}

- (void) updateTrends:(NSNotification*)aNote
{
	[currentPlotter setNeedsDisplay:YES];
}

- (void) dirChanged:(NSNotification*)aNotification
{
	if([model dirName]!=nil)[hvStateDirField setStringValue: [model dirName]];
}


- (void) pollingStateChanged:(NSNotification*)aNotification
{
	// if([pollingButton indexOfSelectedItem]!=[model pollingState]){
	[pollingButton selectItemAtIndex:[pollingButton indexOfItemWithTag:[model pollingState]]];
	// }
	if([model pollingState] == 0){
		[pollingAlertField setStringValue:@"Current NOT being checked"];
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
		ORHVSupply* aSupply = [[aNotification userInfo] objectForKey:ORHVSupplyId];
		[[controlMatrix cellWithTag:[aSupply supply]] setState:[aSupply controlled]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHVSupply* s;
		while(s = [e nextObject]){
			[[controlMatrix cellWithTag:[s supply]] setState:[s controlled]];
		}
	}
	[self updateButtons];   
}

- (void) rampTimeChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHVSupply* aSupply = [[aNotification userInfo] objectForKey:ORHVSupplyId];
		[[timeMatrix cellWithTag:[aSupply supply]] setIntValue: [aSupply rampTime]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHVSupply* s;
		while(s = [e nextObject]){
			[[timeMatrix cellWithTag:[s supply]] setIntValue: [s rampTime]];
		}
	}
}

- (void) targetChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHVSupply* aSupply = [[aNotification userInfo] objectForKey:ORHVSupplyId];
		[[targetMatrix cellWithTag:[aSupply supply]] setIntValue: [aSupply targetVoltage]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHVSupply* s;
		while(s = [e nextObject]){
			[[targetMatrix cellWithTag:[s supply]] setIntValue: [s targetVoltage]];
		}
	}
}

- (void) dacChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHVSupply* aSupply = [[aNotification userInfo] objectForKey:ORHVSupplyId];
		[[dacMatrix cellWithTag:[aSupply supply]] setIntValue: [aSupply dacValue]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHVSupply* s;
		while(s = [e nextObject]){
			[[dacMatrix cellWithTag:[s supply]] setIntValue: [s dacValue]];
		}
	}
}


- (void) adcChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHVSupply* aSupply = [[aNotification userInfo] objectForKey:ORHVSupplyId];
		[[ adcMatrix cellWithTag:[aSupply supply]] setIntValue: [aSupply adcVoltage]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHVSupply* s;
		while(s = [e nextObject]){
			[[ adcMatrix cellWithTag:[s supply]] setIntValue: [s adcVoltage]];
		}
	}
	
	[self updateButtons];   
}

- (void) currentChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHVSupply* aSupply = [[aNotification userInfo] objectForKey:ORHVSupplyId];
		[[ currentMatrix cellWithTag:[aSupply supply]] setIntValue: [aSupply current]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHVSupply* s;
		while(s = [e nextObject]){
			[[ currentMatrix cellWithTag:[s supply]] setIntValue: [s current]];
		}
	}
}

- (void) stateChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHVSupply* aSupply = [[aNotification userInfo] objectForKey:ORHVSupplyId];
		if(aSupply){
			NSTextFieldCell* cell = [stateMatrix cellWithTag:[aSupply supply]];
			[cell setStringValue: [aSupply state]];
			[self setTextColor: cell supply:aSupply];
		}
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHVSupply* s;
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
		ORHVSupply* aSupply = [[aNotification userInfo] objectForKey:ORHVSupplyId];
		[[voltageAdcOffsetMatrix cellWithTag:[aSupply supply]] setFloatValue: [aSupply voltageAdcOffset]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHVSupply* s;
		while(s = [e nextObject]){
			[[voltageAdcOffsetMatrix cellWithTag:[s supply]] setFloatValue: [s voltageAdcOffset]];
		}
	}
}

- (void) voltageAdcSlopeChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORHVSupply* aSupply = [[aNotification userInfo] objectForKey:ORHVSupplyId];
		[[voltageAdcSlopeMatrix cellWithTag:[aSupply supply]] setFloatValue: [aSupply voltageAdcSlope]];
	}
	else {
		NSEnumerator* e = [[model supplies] objectEnumerator];
		ORHVSupply* s;
		while(s = [e nextObject]){
			[[voltageAdcSlopeMatrix cellWithTag:[s supply]] setFloatValue: [s voltageAdcSlope]];
		}
	}
}

- (void) hvLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:HVRampLock];
    [hvLockButton setState: locked];
    [self updateButtons];
}


- (void) runStatusChanged:(NSNotification*)aNotification
{
    [self updateButtons];
}

- (void) saveCurrentToFileChanged:(NSNotification*)aNotification
{
	[saveCurrentToFileButton setState:[model saveCurrentToFile]];
}

- (void) currentFileChanged:(NSNotification*)aNotification
{
	[currentFileField setStringValue:[[model currentFile] stringByAbbreviatingWithTildeInPath]];
}

- (void) calibrationLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:HVRampCalibrationLock];
    [calibrationLockButton setState: locked];
    
    [voltageAdcOffsetMatrix setEnabled:!locked];
    [voltageAdcSlopeMatrix setEnabled:!locked];   
}




- (void) setTextColor:(NSTextFieldCell*)aCell supply:(ORHVSupply*)aSupply
{
    switch([aSupply rampState]){
        case kHVRampUp:
        case kHVRampDown:
        case kHVRampZero:
        case kHVRampPanic:
            [aCell setTextColor:[NSColor orangeColor]];
			break;
        default: 
			if([aSupply actualRelay]!=[aSupply relay])[aCell setTextColor:[NSColor orangeColor]];
            else if([aSupply actualRelay])[aCell setTextColor:[NSColor redColor]]; 	
            else [aCell setTextColor:[NSColor blackColor]];	 
			break;
			
    }
}

#pragma mark ¥¥¥Actions
- (IBAction) supplyOnAction:(id)sender
{
    [self endEditing];
    [model turnOnSupplies:YES];
    [model saveHVParams];
    [self stateChanged:nil];
}

- (IBAction) supplyOffAction:(id)sender
{
    [self endEditing];
    [model turnOnSupplies:NO];
    [model saveHVParams];
    [self stateChanged:nil];
}

- (IBAction) startRampAction:(id)sender
{
    [self endEditing];
    [model pollHardware:model];
	
    if(![model checkActualVsSetValues]){
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:@"High Voltage Set Value != Actual Value"];
        [alert setInformativeText:@"You can not Ramp HV until this problem is resolved.\nWhat would like to do?"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle: @"Set DACs = ADC's"];
        [alert setAlertStyle:NSAlertStyleWarning];
        
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
            if (result == NSAlertSecondButtonReturn){
                [model resolveActualVsSetValueProblem];
                [model initializeStates];
                [model resetAdcs];
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
		[model resetAdcs];
		[model startRamping];
		[self updateButtons];
    }
}


- (IBAction) stopRampAction:(id)sender
{
    [model stopRamping];
    [self updateButtons];
}

- (IBAction) rampToZeroAction:(id)sender
{
    [self endEditing];
    [model setStates:kHVRampZero onlyControlled:YES];
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
    [alert addButtonWithTitle:@"Yes/Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        [model setStates:kHVRampPanic onlyControlled:YES];
        [model startRamping];
        [self updateButtons];
        if (result == NSAlertFirstButtonReturn){
            [model setStates:kHVRampPanic onlyControlled:YES];
            [model startRamping];
            [self updateButtons];
        }
    }];
#else
    NSBeginAlertSheet(@"HV Panic",
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,[self window],
					  self,
					  @selector(_panicRampSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Really Panic Selected High Voltage OFF?");
#endif
}

- (IBAction) panicSystemAction:(id)sender
{
    [self endEditing];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"HV Panic"];
    [alert setInformativeText:@"Really Panic ALL High Voltage OFF?"];
    [alert addButtonWithTitle:@"Yes/Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model setStates:kHVRampPanic onlyControlled:NO];
            [model startRamping];
            [self updateButtons];
        }
    }];
#else
    NSBeginAlertSheet(@"HV Panic",
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,[self window],
					  self,
					  @selector(_systemPanicRampSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Really Panic ALL High Voltage OFF?");
#endif
}

- (IBAction) syncAction:(id)sender;
{
    [self endEditing];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Sync DACs to ADCs"];
    [alert setInformativeText:@"Really move ADC values into DAC fields?"];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model forceDacToAdc];
            [self updateButtons];
        }
    }];
#else
    NSBeginAlertSheet(@"Sync DACs to ADCs",
					  @"YES",
					  @"Cancel",
					  nil,[self window],
					  self,
					  @selector(_syncActionSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Really move ADC values into DAC fields?");
#endif
}


- (IBAction) setPollingAction:(id)sender
{
    [model setPollingState:(NSTimeInterval)[[sender selectedItem] tag]];
}

- (IBAction) pollNowAction:(id)sender
{
    [model pollHardware:model];
}

- (IBAction) chooseDir:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Choose"];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* dirName = [[[openPanel URL] path] stringByAbbreviatingWithTildeInPath];
            [model setDirName:dirName];
        }
    }];
}



- (IBAction) controllAction:(id)sender
{
    [self endEditing];
    int i = (int)[[sender selectedCell] tag];
    if([sender intValue] != [[[model supplies] objectAtIndex:i] controlled]){
		[[self undoManager] setActionName: @"Set HV Controlled"];
		[[[model supplies] objectAtIndex:i] setControlled: [sender intValue]];
		[self updateButtons];
    }
}

- (IBAction) rampTimeAction:(id)sender
{
    [self endEditing];
    int i = (int)[[sender selectedCell] tag];
    if([sender intValue] != [[[model supplies] objectAtIndex:i] rampTime]){
		[[self undoManager] setActionName: @"Set HV Ramp Time"];
		[[[model supplies] objectAtIndex:i] setRampTime: [sender intValue]];
    }
}

- (IBAction) targetAction:(id)sender
{
    int i = (int)[[sender selectedCell] tag];
    if([sender intValue] != [[[model supplies] objectAtIndex:i] targetVoltage]){
		[[self undoManager] setActionName: @"Set HV Ramp Time"];
		[[[model supplies] objectAtIndex:i] setTargetVoltage: [sender intValue]];
    }
}

- (IBAction) adcOffsetAction:(id)sender
{
    int i = (int)[[sender selectedCell] tag];
    if([sender floatValue] != [[[model supplies] objectAtIndex:i] voltageAdcOffset]){
		[[self undoManager] setActionName: @"Set HV Adc Offset"];
		[[[model supplies] objectAtIndex:i] setVoltageAdcOffset: [sender floatValue]];
    }
	
}

- (IBAction) adcSlopeAction:(id)sender
{
	int i = (int)[[sender selectedCell] tag];
    if([sender floatValue] != [[[model supplies] objectAtIndex:i] voltageAdcSlope]){
		[[self undoManager] setActionName: @"Set HV ADC Slope"];
		[[[model supplies] objectAtIndex:i] setVoltageAdcSlope: [sender floatValue]];
    }
}

- (IBAction) calibrationLockAction:(id)sender
{
    [gSecurity tryToSetLock:HVRampCalibrationLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) hvLockAction:(id)sender
{
    [gSecurity tryToSetLock:HVRampLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) saveCurrentToFileAction:(id)sender
{
    [model setSaveCurrentToFile:[sender intValue]];
}

- (IBAction) setCurrentFileAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Choose Folder"];
	
    NSString* startingDir;
    if([model currentFile])	startingDir = [[model currentFile] stringByDeletingLastPathComponent];
    else					startingDir = NSHomeDirectory();
	
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* theFolder = [[[openPanel URL] path] stringByAbbreviatingWithTildeInPath];
            [model setCurrentFile:[theFolder stringByAppendingPathComponent:@"HVCurrents.txt"]];
        }
    }];
}

- (void) updateButtons
{	
	
    BOOL ramping = [model rampTimer] != nil;
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:HVRampLock];
    BOOL locked = [gSecurity isLocked:HVRampLock];
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    
    //default state
    [onButton setEnabled:NO];
    [offButton setEnabled:NO];
    [startRampButton setEnabled:NO];
    [stopRampButton setEnabled:NO];
    [rampToZeroButton setEnabled:NO];
    [panicButton setEnabled:NO];
    [syncButton setEnabled:!locked];
	
    BOOL anyRelaysOn 	= [model anyRelaysSetOn];
    BOOL anyRelaysOnControlled 	= [model anyRelaysSetOnControlledSupplies];
    BOOL anyControlled 	= [model anyControlledSupplies];
    BOOL anyVoltageOn 	= [model anyVoltageOn];
	
    if(anyRelaysOn || anyVoltageOn){
        [statusButton setTitle:@"Panic ALL HV..."];
        [statusButton setEnabled:YES];
        [model setImage:[NSImage imageNamed:@"HVRampOn"]];
        [statusImage setImage:[NSImage imageNamed:@"HVRampOn"]];
    }
    else {
        [statusButton setTitle:@"HV IS OFF"];
        [statusButton setEnabled:NO];
        [model setImage:[NSImage imageNamed:@"HVRamp"]];
        [statusImage setImage:[NSImage imageNamed:@"HVRamp"]];
    }
	
    BOOL powerCycled	 = [model powerCycled];
	
    if(anyControlled && !lockedOrRunningMaintenance){
		
        BOOL allRelaysAreOn 	 = [model allRelaysSetOnControlledSupplies];
        BOOL allRelaysAreOff	 = [model allRelaysOffOnControlledSupplies];
        BOOL voltageOnControlled = [model anyVoltageOnControlledSupplies];
        BOOL hasBeenPolled	 = [model hasBeenPolled];
        
        if([model rampTimer] != nil || voltageOnControlled || !hasBeenPolled) {
            //we are ramping or there is voltage on, disable the appropriate buttons
            [onButton setEnabled:NO];
            [offButton setEnabled:NO];
        }
        else {
            if(allRelaysAreOn){
                [onButton setEnabled:NO];
                [offButton setEnabled:YES];  
            }
            else if(allRelaysAreOff){
                [onButton setEnabled:YES];
                [offButton setEnabled:NO];  
            }
            else {
                [onButton setEnabled:YES];
                [offButton setEnabled:YES];  
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
            if(anyRelaysOnControlled || voltageOnControlled){
                [startRampButton setEnabled:YES];
                [stopRampButton setEnabled:NO];
                [rampToZeroButton setEnabled:YES];
                [panicButton setEnabled:YES];
            }
            if(powerCycled){
                [startRampButton setEnabled:NO];
                [stopRampButton setEnabled:NO];
                [rampToZeroButton setEnabled:YES];
                [panicButton setEnabled:YES];
            }
		}
    }
	
	
    [dirSelectionButton setEnabled:!locked];
    [syncButton setEnabled:!(ramping || lockedOrRunningMaintenance) && !powerCycled];
    
    [controlMatrix setEnabled:!(ramping || lockedOrRunningMaintenance)];
    [timeMatrix setEnabled:!(ramping || lockedOrRunningMaintenance)];
    [targetMatrix setEnabled:!(ramping || lockedOrRunningMaintenance)];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:HVRampLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
}

#pragma mark ¥¥¥Plot Data Source

- (int)	numberPointsInPlot:(id)aPlotter
{
	int set = (int)[aPlotter tag];
	return [model currentTrendCount:set];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	double aValue = 0;
	int set = (int)[aPlotter tag];
	int count = (int)[model currentTrendCount:set];
	aValue =  [model currentValue:count-i-1 supply:set];
	*xValue = (double)i;
	*yValue = aValue;
}
@end


#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
@implementation ORHVRampController (private)
- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertFirstButtonReturn){
        [model setStates:kHVRampPanic onlyControlled:YES];
		[model startRamping];
		[self updateButtons];
    }
	
}
- (void)_startRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){
		[model resolveActualVsSetValueProblem];
		[model initializeStates];
		[model resetAdcs];
		[model startRamping];
		[self updateButtons];
    }
	
}

- (void) _systemPanicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertFirstButtonReturn){
        [model setStates:kHVRampPanic onlyControlled:NO];
		[model startRamping];
		[self updateButtons];
    }
}
- (void) _syncActionSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertFirstButtonReturn){
		[model forceDacToAdc];
		[self updateButtons];
    }
}
@end
#endif
