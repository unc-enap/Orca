
//
//  ORMJDVacuumController.m
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright © 2012 CENPA, University of North Carolina. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORMJDVacuumController.h"
#import "ORMJDVacuumModel.h"
#import "ORMJDVacuumView.h"
#import "ORVacuumParts.h"

@implementation ORMJDVacuumController
- (id) init
{
    self = [super initWithWindowNibName:@"MJDVacuum"];
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	[subComponentsView setGroup:model];
	[super awakeFromNib];
}

#pragma mark •••Accessors
- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"MJD Vacuum (Cryostat %lu)",[model uniqueIdNumber]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
	[notifyCenter addObserver : self
                     selector : @selector(showGridChanged:)
                         name : ORMJDVacuumModelShowGridChanged
                       object : nil];
		
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORVacuumPartChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORVacuumConstraintChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORMJDVacuumModelVetoMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(vetoMaskChanged:)
                         name : ORMJDVacuumModelVetoMaskChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORMJCVacuumLock
                        object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(detectorsBiasedChanged:)
                         name : ORMJDVacuumModelDetectorsBiasedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(localConstraintsChanged:)
                         name : ORMJDVacuumModelConstraintsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(hvUpdateTimeChanged:)
                         name : ORMJDVacuumModelHvUpdateTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lastHvUpdateTimeChanged:)
                         name : ORMJDVacuumModelLastHvUpdateTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(nextHvUpdateTimeChanged:)
                         name : ORMJDVacuumModelNextHvUpdateTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(detectorsBiasedChanged:)
                         name : ORMJDVacuumModelNoHvInfoChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(constraintsDisabledChanged:)
                         name : ORMJDVacuumModelConstraintsDisabledChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(coolerModeChanged:)
                         name : ORMJDVacuumModelCoolerModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(spikeValueChanged:)
                         name : ORMJDVacuumModelSpikeTriggerValueChanged
                        object: model];

}

- (void) updateWindow
{
    [super updateWindow];
	[self showGridChanged:nil];
	[self stateChanged:nil];
	[self vetoMaskChanged:nil];
	[self lockChanged:nil];
	[self detectorsBiasedChanged:nil];
	[self localConstraintsChanged:nil];
	[self hvUpdateTimeChanged:nil];
	[self lastHvUpdateTimeChanged:nil];
	[self nextHvUpdateTimeChanged:nil];
	[self coolerModeChanged:nil];
    [self spikeValueChanged:nil];
}

#pragma mark •••Interface Management
- (void) spikeValueChanged:(NSNotification*)aNote
{
    [spikeValueField setFloatValue:[model spikeTriggerValue]];
}
- (void) coolerModeChanged:(NSNotification*)aNote
{
	[coolerModePU selectItemAtIndex: [model coolerMode]];
}
- (void) constraintsDisabledChanged:(NSNotification*)aNote
{
    if([model disableConstraints])[overRideButton setTitle:@"Re-enable Constraints"];
    else                          [overRideButton setTitle:@"Disable Constraints..."];
    [constraintOverrideField setStringValue:[model disableConstraints]?@"Constraints DISABLED":@""];
	[vacuumView setNeedsDisplay:YES];
    
}

- (void) nextHvUpdateTimeChanged:(NSNotification*)aNote
{
    NSDate* nextTime = [model nextHvUpdateTime];
    if(nextTime){
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd hh:mm a"];
        NSString* dateString  = [dateFormatter stringFromDate:nextTime];
        [dateFormatter release];
        if([dateString length]==0)dateString = @"?";
        [nextHvUpdateTimeField setStringValue: [NSString stringWithFormat:@"%@",dateString]];
    }
    else {
        [nextHvUpdateTimeField setStringValue: @"?"];
    }
}

- (void) lastHvUpdateTimeChanged:(NSNotification*)aNote
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd hh:mm a"];
    NSString* dateString  = [dateFormatter stringFromDate:[model lastHvUpdateTime]];
    [dateFormatter release];
	if([dateString length]==0)dateString = @"?";
	[lastHvUpdateTimeField setStringValue: dateString];
}

- (void) hvUpdateTimeChanged:(NSNotification*)aNote
{
	[hvUpdateTimeField setIntValue: [model hvUpdateTime]];
}
- (void) localConstraintsChanged:(NSNotification*)aNote
{
	if([model detectorsBiased]){
		if([model shouldUnbiasDetector]) [constraintStatusField setStringValue:@"Should unbias"];
		else							 [constraintStatusField setStringValue:@"Normal Ops"];
	}
	else {
		if([model okToBiasDetector]) [constraintStatusField setStringValue:@"OK to bias"];
		else						 [constraintStatusField setStringValue:@"Do NOT bias"];
	}
}

- (void) detectorsBiasedChanged:(NSNotification*)aNote
{
	[vacuumView setNeedsDisplay:YES];
    if([model lastHvUpdateTime]){
        if([model noHvInfo]) [detectorStatusField setStringValue: @"NO Bias Info"];
        else				 [detectorStatusField setStringValue: [model detectorsBiased]?@"Biased":@"Unbiased"];
    }
    else {
        [detectorStatusField setStringValue: @"UnKnown!"];
    }
 }

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[subComponentsView setNeedsDisplay:YES];
	}
}

- (void) vetoMaskChanged:(NSNotification*)aNote
{
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORMJCVacuumLock];
    [lockButton setState: locked];
	
	[vacuumView updateButtons];
}

- (void) stateChanged:(NSNotification*)aNote
{
	if(!updateScheduled){
		updateScheduled = YES;
		[self performSelector:@selector(delayedRefresh) withObject:nil afterDelay:.5];
	}
}
- (void) delayedRefresh
{
	updateScheduled = NO;
	[vacuumView setNeedsDisplay:YES];
	[valueTableView reloadData];
	[statusTableView reloadData];
	[gvTableView reloadData];
}

- (void) showGridChanged:(NSNotification*)aNote
{
	[setShowGridCB setIntValue:[model showGrid]];
	[vacuumView setNeedsDisplay:YES];
}

- (void) toggleGrid
{
	[model toggleGrid];
}

- (BOOL) showGrid
{
	return [model showGrid];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMJCVacuumLock to:secure];
    [lockButton setEnabled:secure];
}

#pragma mark •••Actions

- (void) coolerModeAction:(id)sender
{
	[model setCoolerMode:[sender indexOfSelectedItem]];
}
- (IBAction) showGridAction:(id)sender
{
	[model setShowGrid:[sender intValue]];
}

- (IBAction) openGVControlPanel:(id)sender
{
	[self endEditing];
	
	int gateValveTag	  = [sender tag];
	ORVacuumGateValve* gv = [model gateValve:gateValveTag];
	int currentValveState = [gv state];
	
	BOOL constraintsInPlace = [[gv constraints] count]>0;
	if(constraintsInPlace && ![model disableConstraints]){
		NSArray* allKeys = [[gv constraints] allKeys];
		int n = [allKeys count];
		[constraintTitleField setStringValue:[NSString stringWithFormat:@"%@ can not be opened because it has %d constraint%@ in effect. See below for more info.",
											  [gv label],
											  n,
											  n==1?@"":@"s"]];
		NSMutableString* s = [NSMutableString string];
		for(id aKey in allKeys){
			[s appendFormat:@"%@ --> %@\n\n",aKey,[[gv constraints] objectForKey:aKey]];
		}
		[gvConstraintView setString:s];
		[NSApp beginSheet:gvConstraintPanel modalForWindow:[self window]
			modalDelegate:self didEndSelector:NULL contextInfo:nil];
	}
	else {
		unsigned long changesVetoed = ([model vetoMask] & (0x1>>gateValveTag)) != 0;
		if(gv){
			NSString* statusString = [NSString stringWithFormat:@"%@  current state: %@",[gv label],currentValveState==kGVOpen?@"OPEN":(currentValveState==kGVClosed?@"CLOSED":@"UnKnown")];
			[gvControlValveState setStringValue:statusString];
			
			int region1		= [gv connectingRegion1];
			int region2		= [gv connectingRegion2];
			
			NSColor* c1		= [model colorOfRegion:region1];
			NSColor* c2		= [model colorOfRegion:region2];
			
			[gvControlPressureSide1 setStringValue:[model valueLabel:region1]];
			[gvControlPressureSide2 setStringValue:[model valueLabel:region2]];
			NSString* s = @"";
			
			if([gv controlObj]){
				[gvHwObjectName setStringValue:[NSString stringWithFormat:@"%@,%d",[gv controlObj],[gv controlChannel]]]; 

				switch(currentValveState){
					case kGVOpen:
						[gvOpenToText1 setStringValue:[model namesOfRegionsWithColor:c1]];
						[gvOpenToText2 setStringValue:@"Valve is open. Closing it may isolate some regions."];
						if(!changesVetoed){
							s = @"Are you sure you want to CLOSE it and potentially isolate some regions?";
							[gvControlButton setTitle:@"YES - CLOSE it"];
							[gvControlButton setEnabled:YES];
						}
						else {
							s = @"Changes to this valve have been vetoed. Probably by the process controller.";
							[gvControlButton setTitle:@"---"];
							[gvControlButton setEnabled:NO];
						}
					break;
						
					case kGVClosed:
						if(!changesVetoed){
							if([c1 isEqual:c2]){
								[gvOpenToText1 setStringValue:[model namesOfRegionsWithColor:c1]];
								[gvOpenToText2 setStringValue:@"Each Side Appears Connected now so opening the valve may be OK."];
								s = @"Are you sure you want to OPEN it?";
							}
							else {
								[gvOpenToText1 setStringValue:[model namesOfRegionsWithColor:c1]];
								[gvOpenToText2 setStringValue:[model namesOfRegionsWithColor:c2]];
								s = @"Are you sure you want to OPEN it and join isolated regions?";
							}
						
							[gvControlButton setTitle:@"YES - OPEN it"];
							[gvControlButton setEnabled:YES];
						}
						else {
							s = @"Changes to this valve have been vetoed by the process controller.";
							[gvControlButton setTitle:@"---"];
							[gvControlButton setEnabled:NO];
						}
						break;
						
					default:
						s = @"The valve is currently in an unknown state.";
						[gvOpenToText1 setStringValue:[model namesOfRegionsWithColor:c1]];
						[gvOpenToText2 setStringValue:[model namesOfRegionsWithColor:c2]];
						[gvControlButton setTitle:@"---"];
						[gvControlButton setEnabled:NO];
					break;
				}
				
				[gvControlButton setTag:gateValveTag];
			}
			else {
				s = @"Not mapped to HW! Valve can NOT be controlled!";
				[gvHwObjectName setStringValue:@"--"];
				[gvControlButton setTitle:@"---"];
				[gvControlButton setEnabled:NO];
				[gvOpenToText1 setStringValue:@"--"];
				[gvOpenToText2 setStringValue:@"--"];
			}
			[gvControlField setStringValue:s];
			[NSApp beginSheet:gvControlPanel modalForWindow:[self window]
				modalDelegate:self didEndSelector:NULL contextInfo:nil];
		}
	}
}

- (IBAction) closeGVConstraintPanel:(id)sender
{
    [gvConstraintPanel orderOut:nil];
    [NSApp endSheet:gvConstraintPanel];
}

- (IBAction) closeGVChangePanel:(id)sender
{
    [gvControlPanel orderOut:nil];
    [NSApp endSheet:gvControlPanel];
}

- (IBAction) changeGVAction:(id)sender
{
    [gvControlPanel orderOut:nil];
    [NSApp endSheet:gvControlPanel];
	int gateValveTag = [gvControlButton tag];
	int currentValveState = [model stateOfGateValve:gateValveTag];
	
	if(currentValveState == kGVOpen)       [model closeGateValve:gateValveTag];
	else if(currentValveState == kGVClosed)[model openGateValve:gateValveTag];
	else NSLog(@"GateValve %d in unknown state. Command ignored.\n",gateValveTag);
}


- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMJCVacuumLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) spikeValueAction:(id)sender
{
    [model setSpikeTriggerValue:[sender floatValue]];
}

- (IBAction) overRideAction:(id)sender
{
    if(![model disableConstraints]){
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:@"REALLY disable constraints?"];
        [alert setInformativeText:@"This is a dangerous operation. If you are NOT an expert -- CANCEL this operation.\n\nIf you continue, constraints will be disabled for 60 seconds."];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Yes/Disable Constraints!"];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
            if (result == NSAlertSecondButtonReturn){
                [model disableConstraintsFor60Seconds];
            }
        }];
#else
        NSBeginCriticalAlertSheet(@"REALLY disable constraints?",
                          @"Cancel",
                          @"Yes/Disable Constraints!",
                          nil,[self window],
                          self,
                          @selector(toggleSheetDidEnd:returnCode:contextInfo:),
                          nil,
                          nil,@"This is a dangerous operation. If you are NOT an expert -- CANCEL this operation.\n\nIf you continue, constraints will be disabled for 60 seconds.");
#endif
    }
    else {
        [model enableConstraints];
    }
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) toggleSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
        [model disableConstraintsFor60Seconds];
    }
}
#endif

- (IBAction) reportConstraints:(id)sender
{
    [model reportConstraints];
}

#pragma mark •••Data Source For Tables
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == valueTableView){
		return [[model valueLabels] count];
	}
	else if(aTableView == statusTableView){
		return [[model valueLabels] count];
	}
	else if(aTableView == gvTableView){
		return [[model gateValves] count];
	}
	else return 0;
}
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if((aTableView == valueTableView) || (aTableView == statusTableView)){
		NSArray* theLabels;
		if(aTableView == valueTableView) theLabels = [model valueLabels];
		else							 theLabels = [model statusLabels];
		if(rowIndex < [theLabels count]){
			ORVacuumDynamicLabel* theLabel = [theLabels objectAtIndex:rowIndex];
			if([[aTableColumn identifier] isEqualToString:@"partTag"]){
				return [NSNumber numberWithInt:rowIndex];
			}
			else if([[aTableColumn identifier] isEqualToString:@"label"]){
				return [theLabel label];
			}

			else  if([[aTableColumn identifier] isEqualToString:@"value"]){
				return [theLabel displayString];
			}
			else return @"--";
		}
		else return @"";
	}
	else if(aTableView == gvTableView ){
		NSArray* theGateValves = [model gateValves];
		if(rowIndex < [theGateValves count]){
			ORVacuumGateValve* gv = [theGateValves objectAtIndex:rowIndex];
			if([[aTableColumn identifier] isEqualToString:@"partTag"]){
				return [NSNumber numberWithInt:rowIndex];
			}
			else if([[aTableColumn identifier] isEqualToString:@"label"]){
				return [gv label];
			}
			else if([[aTableColumn identifier] isEqualToString:@"vetoed"]){
				if([gv controlType] == k2BitReadBack || [gv controlType] == k1BitReadBack) return [gv vetoed]?@"Vetoed":@" ";
				else return @" ";
			}
			else if([[aTableColumn identifier] isEqualToString:@"constraints"]){
				return [NSNumber numberWithInt:[gv constraintCount]];
			}
			else if([[aTableColumn identifier] isEqualToString:@"controlChannel"]){
				if([gv controlObj])return [NSNumber numberWithInt:[gv controlChannel]];
				else return @" ";
			}
			else  if([[aTableColumn identifier] isEqualToString:@"state"]){
				if([gv controlType]      == kManualOnlyShowClosed) return @"Manual-Closed??";
				else if([gv controlType] == kManualOnlyShowChanging) return @"Manual-Open??";
				else if([gv controlType] == kSpareValve) return @"--";
				else {
					int currentValveState = [gv state];
					if([gv controlType] == k1BitReadBack){
						return currentValveState==kGVOpen?@"OPEN":@"CLOSED";
					}
					else {
						return currentValveState==kGVOpen?@"OPEN":(currentValveState==kGVClosed?@"CLOSED":@"CHANGING");
					}
				}
			}
			else return @"--";
		}
		else return @"";
	}
	return @"";
}



@end
