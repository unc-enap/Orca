//-------------------------------------------------------------------------
//  ORiSegHVCardController.h
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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
#import "ORiSegHVCardController.h"
#import "ORiSegHVCard.h"
#import "ORCompositePlotView.h"
#import "ORAxis.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"
#import "ORTimeLinePlot.h"
#import "ORTimedTextField.h"
#import "ORMPodCrate.h"

@interface ORiSegHVCardController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info;
- (void) _panicAllRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info;
- (void) _allOnSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info;
- (void) _allOffSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info;
- (void) _syncSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info;
- (void) _allRampToZeroSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info;
#endif
@end


@implementation ORiSegHVCardController
- (void) dealloc
{
    [hvTableView setDataSource:nil];
    [hvTableView setDelegate:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{	
	[super awakeFromNib];
	
	[[currentPlotter yAxis] setRngLimitsLow:-5000000000 withHigh:5000000000 withMinRng:10];
	[[voltagePlotter yAxis] setRngLimitsLow:0 withHigh:10000 withMinRng:10];
	[[currentPlotter yAxis] setLabel:@"Current (pA)"];
	[[voltagePlotter yAxis] setLabel:@"Voltage (V)"];
	ORTimeLinePlot* aPlot;
	
	NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
	[formatter setFormat:@"#0"];
	[maxCurrentField setFormatter:formatter];
	
	NSTableColumn* maxCurrentColumn = [hvTableView tableColumnWithIdentifier:@"maxCurrent"];
	[[maxCurrentColumn dataCell] setFormatter:formatter];
	
	int i;
	NSColor* aColor = [NSColor redColor];
	for(i=0;i<[model numberOfChannels];i++){
		switch(i){
			case 0: aColor  = [NSColor redColor];       break;
			case 1: aColor  = [NSColor greenColor];     break;
			case 2: aColor  = [NSColor blueColor];      break;
			case 3: aColor  = [NSColor cyanColor];      break;
			case 4: aColor  = [NSColor brownColor];     break;
			case 5: aColor  = [NSColor magentaColor];   break;
			case 6: aColor  = [NSColor orangeColor];    break;
			case 7: aColor  = [NSColor purpleColor];    break;
			case 8: aColor  = [NSColor redColor];       break;
			case 9: aColor  = [NSColor greenColor];     break;
			case 10: aColor = [NSColor blueColor];      break;
			case 11: aColor = [NSColor cyanColor];      break;
			case 12: aColor = [NSColor brownColor];    break;
			case 13: aColor = [NSColor magentaColor];   break;
			case 14: aColor = [NSColor orangeColor];    break;
			case 15: aColor = [NSColor purpleColor];    break;
		}
		aPlot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[aPlot setUseConstantColor:YES];
		[aPlot setLineColor: aColor];
        [aPlot setName:[NSString stringWithFormat:@"Chan %d",i]];
		[currentPlotter addPlot: aPlot];
		[aPlot release];
		
		aPlot = [[ORTimeLinePlot alloc] initWithTag:i+[model numberOfChannels] andDataSource:self];
		[aPlot setUseConstantColor:YES];
		[aPlot setLineColor: aColor];
        [aPlot setName:[NSString stringWithFormat:@"Chan %d",i]];
		[voltagePlotter addPlot: aPlot];
		[aPlot release];
	}
    [currentPlotter setShowLegend:YES];
    [voltagePlotter setShowLegend:YES];

	
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORMPodCardSlotChangedNotification
					   object : model];
	    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
	[notifyCenter addObserver : self
                     selector : @selector(targetChanged:)
                         name : ORiSegHVCardTargetChanged
                       object : model];	
	
    [notifyCenter addObserver : self
					 selector : @selector(riseRateChanged:)
						 name : ORiSegHVCardRiseRateChanged
					   object : model];
		
	[notifyCenter addObserver : self
					 selector : @selector(channelReadParamsChanged:)
						 name : ORiSegHVCardChannelReadParamsChanged
					   object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"MPodPowerFailedNotification"
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"MPodPowerRestoredNotification"
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(selectedChannelChanged:)
                         name : ORiSegHVCardSelectedChannelChanged
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(updateHistoryPlots:)
						 name : ORRateAverageChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(maxCurrentChanged:)
                         name : ORiSegHVCardMaxCurrentChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(shipRecordsChanged:)
                         name : ORiSegHVCardShipRecordsChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(timeoutHappened:)
                         name : @"Timeout"
						object: nil];
    
	[notifyCenter addObserver : self
                     selector : @selector(constraintsChanged:)
                         name : ORMPodCrateConstraintsChanged
						object: [model guardian]];

    [notifyCenter addObserver : self
                     selector : @selector(constraintsChanged:)
                         name : ORiSegHVCardConstraintsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(maxVoltageChanged:)
                         name : ORiSegHVCardMaxVoltageChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(customInfoChanged:)
                         name : ORiSegHVCardCustomInfoChanged
                        object: model];

    
    [notifyCenter addObserver : self
                     selector : @selector(chanNameChanged:)
                         name : ORiSegHVCardChanNameChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(doNotPostSafetyLoopAlarmChanged:)
                         name : ORiSegHVCardDoNotPostSafetyAlarmChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORInProductionModeChanged
                       object : nil];

    
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self targetChanged:nil];
    [self riseRateChanged:nil];
    [self channelReadParamsChanged:nil];
	[self updateHistoryPlots:nil];
	
	[self selectedChannelChanged:nil];
	[self maxCurrentChanged:nil];
	[self shipRecordsChanged:nil];
	[self constraintsChanged:nil];
    [self maxVoltageChanged:nil];
    [self customInfoChanged:nil];
    [self chanNameChanged:nil];
    [self doNotPostSafetyLoopAlarmChanged:nil];
}

#pragma mark •••Interface Management
- (void) doNotPostSafetyLoopAlarmChanged:(NSNotification*)aNote
{
    [doNotPostSafetyLoopAlarmCB setIntValue:[model doNotPostSafetyLoopAlarm]];
}

- (void) maxVoltageChanged:(NSNotification*)aNote
{
    [maxVoltageField setStringValue:[NSString stringWithFormat:@"Max: %d",[model maxVoltage:[model selectedChannel]]]];
}

- (void) customInfoChanged:(NSNotification*)aNote
{
    [customInfoField setStringValue:[model customInfo:[model selectedChannel]]];
}

- (void) chanNameChanged:(NSNotification*)aNote
{
    [chanNameField setStringValue:[model chanName:[model selectedChannel]]];
}

- (void) constraintsChanged:(NSNotification*)aNote
{
	NSImage* smallLockImage = [NSImage imageNamed:@"smallLock"];
    ORMPodCrate* theCrate = (ORMPodCrate*)[model guardian];
	if([[theCrate hvConstraints] count] || [[model hvConstraints] count]){
        [hvConstraintImage setEnabled:YES];
		[hvConstraintImage setImage:smallLockImage];
	}
	else {
        [hvConstraintImage setEnabled:NO];
        [hvConstraintImage setImage:nil];
    }
}

- (void) timeoutHappened:(NSNotification*)aNote
{
	if([aNote object] ==model || [aNote object]==[model adapter])[timeoutField setStringValue:@"Timeout -- Cmds Flushed!"];
}

- (void) shipRecordsChanged:(NSNotification*)aNote
{
	[shipRecordsButton setIntValue: [model shipRecords]];
}

- (void) maxCurrentChanged:(NSNotification*)aNote
{
	int chan = [model selectedChannel];
	[maxCurrentField setFloatValue: [model maxCurrent:chan]];
}
- (void) updateHistoryPlots:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model currentHistory:0])){
		[currentPlotter setNeedsDisplay:YES];
	}

	if(!aNote || ([aNote object] == [model voltageHistory:0])){
		[voltagePlotter setNeedsDisplay:YES];
	}
}

- (void) selectedChannelChanged:(NSNotification*)aNote
{
	[selectedChannelField setIntValue: [model selectedChannel]];
	[hvTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[model selectedChannel]] byExtendingSelection:NO];
	[self targetChanged:nil];
	[self maxCurrentChanged:nil];
    [self channelReadParamsChanged:nil];
}

- (void) tableViewSelectionDidChange:(NSNotification*)aNote
{
	if([aNote object] == hvTableView || !aNote){
		int index = (int)[hvTableView selectedRow];
        if(index<0 || index>[model numberOfChannels])index=0;
		[model setSelectedChannel:index];
		[self maxVoltageChanged:nil];
	}
}

- (void) powerFailed:(NSNotification*)aNotification
{
    if([aNotification object] == [model adapter]){
		[powerField setStringValue:@"Crate Power OFF"];
		//[self updateButtons];
	}
}

- (void) powerRestored:(NSNotification*)aNotification
{
    if([aNotification object] == [model adapter]){
		[powerField setStringValue:@""];
		//[self updateButtons];
	}
}

- (void) channelReadParamsChanged:(NSNotification*)aNote
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[hvTableView reloadData];
	[self updateButtons];
	int selectedChannel = [model selectedChannel];
	float voltage	= [model channel:selectedChannel readParamAsFloat:@"outputMeasurementSenseVoltage"];
	[voltageField setStringValue:[NSString stringWithFormat:@"%.2f V",voltage]];
	int numberOnChannels = [model numberChannelsOn];
	[channelCountField setIntValue:numberOnChannels];
	[self outputStatusChanged:aNote];
	uint32_t events = [model failureEvents:selectedChannel];
    uint32_t moduleEvents = [model moduleFailureEvents];
	int state  = [model channel:selectedChannel readParamAsInt:@"outputSwitch"];
	[temperatureField setIntValue:[model channel:0 readParamAsInt:@"outputMeasurementTemperature"]];

	NSString* eventString = @"";
	
	if(!events && (state != kiSegHVCardOutputSetEmergencyOff) && !moduleEvents)eventString = @"No Events";
	else {
		if(state == kiSegHVCardOutputSetEmergencyOff)	eventString = [eventString stringByAppendingString:@"Panicked\n"];
		if(events & outputFailureMinSenseVoltageMask)	eventString = [eventString stringByAppendingString:@"Min Voltage\n"];
		if(events & outputFailureMaxSenseVoltageMask)	eventString = [eventString stringByAppendingString:@"Max Voltage\n"];
		if(events & outputFailureMaxTerminalVoltageMask)eventString = [eventString stringByAppendingString:@"Term. Voltage\n"];
		if(events & outputFailureMaxCurrentMask)		eventString = [eventString stringByAppendingString:@"Max Current\n"];
		if(events & outputFailureMaxTemperatureMask)	eventString = [eventString stringByAppendingString:@"Max Temp\n"];
		if(events & outputFailureMaxPowerMask)			eventString = [eventString stringByAppendingString:@"Max Power\n"];
		if(events & outputFailureTimeoutMask)			eventString = [eventString stringByAppendingString:@"Timeout\n"];
		if(events & outputCurrentLimitedMask)			eventString = [eventString stringByAppendingString:@"Current Limit\n"];
		if(events & outputEmergencyOffMask)				eventString = [eventString stringByAppendingString:@"Emergency Off\n"];
        if(moduleEvents & moduleEventPowerFail)         eventString = [eventString stringByAppendingString:@"Module Power Failure\n"];
        if(moduleEvents & moduleEventLiveInsertion)     eventString = [eventString stringByAppendingString:@"Module Live Insertion\n"];
        if(moduleEvents & moduleEventService)           eventString = [eventString stringByAppendingString:@"Module Requires Service\n"];
        if(moduleEvents &
           moduleHardwareLimitVoltageNotGood)           eventString = [eventString stringByAppendingString:@"Module Hard Limit Voltage Not Good\n"];
        if(moduleEvents & moduleEventInputError)        eventString = [eventString stringByAppendingString:@"Module Input Error\n"];
        if(moduleEvents & moduleEventSafetyLoopNotGood) eventString = [eventString stringByAppendingString:@"Module Safety Loop Not Good\n"];
        if(moduleEvents & moduleEventSupplyNotGood)     eventString = [eventString stringByAppendingString:@"Module Power Supply Not Good\n"];
        if(moduleEvents & moduleEventTemperatureNotGood)eventString = [eventString stringByAppendingString:@"Module Temperature Not Good\n"];
	}
	[eventField setStringValue:eventString];
}


- (void) riseRateChanged:(NSNotification*)aNote
{
	[riseRateField setFloatValue:[model riseRate]];
}

- (void) targetChanged:(NSNotification*)aNote
{
	int selectedChannel = [model selectedChannel];
	[targetField setIntValue:[model target:selectedChannel]];
	[hvTableView reloadData];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:[model settingsLock] to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL inProductionMode   = [gOrcaGlobals inProductionMode];
    //BOOL runInProgress    = [gOrcaGlobals runInProgress];
    //BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORiSegHVCardSettingsLock];
    BOOL locked = [gSecurity isLocked:[model settingsLock]];
    	
    [settingLockButton setState: locked];
    
    [doNotPostSafetyLoopAlarmCB setEnabled: !locked && !inProductionMode];
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model settingsLock]];
	int selectedChannel = [model selectedChannel];
	int state		= [model channel:selectedChannel readParamAsInt:@"outputSwitch"];
	float voltage	= [model channel:selectedChannel readParamAsFloat:@"outputMeasurementSenseVoltage"];
	//float hwGoal	= [model hwGoal:selectedChannel];
	//float voltDiff  = fabs(voltage - hwGoal);
    BOOL constrainstsInPlace = [model constraintsInPlace];
	BOOL cratePower = YES;
	if([[model adapter] respondsToSelector:@selector(power)])cratePower = [[model adapter] power];
	if(cratePower){ 
		//the details buttons
		if(state == kiSegHVCardOutputOff){
			//channel is off
			[powerOnButton setEnabled:YES];
			[powerOffButton setEnabled:NO];
			[panicButton setEnabled:NO];
			[rampToZeroButton setEnabled:NO];
			[loadButton setEnabled:NO];
			[stopRampButton setEnabled:NO];
			[stateField setStringValue:@"OFF"];
			[panicButton setEnabled:NO];
			[targetField setEnabled:!lockedOrRunningMaintenance];
			[riseRateField setEnabled:!lockedOrRunningMaintenance];
			[maxCurrentField setEnabled:!lockedOrRunningMaintenance];

		}
		else if([model failureEvents:selectedChannel] || (state == kiSegHVCardOutputSetEmergencyOff) || [model moduleFailureEvents]){
			//channel is off
			[powerOnButton setEnabled:NO];
			[powerOffButton setEnabled:NO];
			[panicButton setEnabled:YES];
			[loadButton setEnabled:NO];
			[stopRampButton setEnabled:NO];
			[rampToZeroButton setEnabled:NO];
			[stateField setStringValue:@"PANICKED"];
			[panicButton setEnabled:NO];
			[targetField setEnabled:NO];
			[riseRateField setEnabled:NO];
			[maxCurrentField setEnabled:NO];
		}
		else {
			//channel is on
			[powerOnButton setEnabled:NO];
			if(fabs([model voltage:selectedChannel])<10 && ![model channelIsRamping:selectedChannel]) [powerOffButton setEnabled:YES];
			else [powerOffButton setEnabled:NO];
			[panicButton setEnabled:YES];
			[loadButton setEnabled:!constrainstsInPlace];
			[stopRampButton setEnabled:[model channelIsRamping:selectedChannel]];
			[rampToZeroButton setEnabled:fabs(voltage) > 0];
			[stateField setStringValue:@"ON"];
			[panicButton setEnabled:fabs(voltage) > 0];
			[targetField setEnabled:!lockedOrRunningMaintenance];
			[riseRateField setEnabled:!lockedOrRunningMaintenance];
			[maxCurrentField setEnabled:!lockedOrRunningMaintenance];
		}
		
		if([model failureEvents:selectedChannel] || (state == kiSegHVCardOutputSetEmergencyOff) || [model moduleFailureEvents]){
			[clearPanicButton setEnabled:YES];
		}
		else {
            //set up the clear events button
			[clearPanicButton setEnabled:NO];
		}
		
		int numberOnChannels			= [model numberChannelsOn];
		uint32_t channelStateMask	= [model channelStateMask];
		int numChannelsRamping			= [model numberChannelsRamping];
		int numChannelsAboveZero		= [model numberChannelsWithNonZeroVoltage];
		int numChannelsNonZeroHwGoal	= [model numberChannelsWithNonZeroHwGoal];
		
		//the ALL buttons
		if(channelStateMask & (1L << kiSegHVCardOutputSetEmergencyOff)){
			//channel is off
			[powerAllOnButton setEnabled:NO];
			[powerAllOffButton setEnabled:NO];
			[panicAllButton setEnabled:YES];
			[loadAllButton setEnabled:NO];
			[stopAllRampButton setEnabled:NO];
			[rampAllToZeroButton setEnabled:NO];
			[panicAllButton setEnabled:NO];
			[panicAllButton setTitle:@"All HV OFF"];
		}
		else if(numberOnChannels == 0){
			//none on
			[powerAllOnButton setEnabled:YES];
			[powerAllOffButton setEnabled:NO];
			[panicAllButton setEnabled:NO];
			[rampAllToZeroButton setEnabled:NO];
			[loadAllButton setEnabled:NO];
			[stopAllRampButton setEnabled:NO];
			[panicAllButton setEnabled:NO];
			[panicAllButton setTitle:@"All HV OFF"];
		}
		else {
			if(numberOnChannels == [model numberOfChannels]){
				//all on 
				[powerAllOnButton setEnabled:NO];
				[powerAllOffButton setEnabled:YES];
			}
			else {
				[powerAllOnButton setEnabled:YES];
				[powerAllOffButton setEnabled:YES];
			}
			[panicAllButton setEnabled:YES];
			[loadAllButton setEnabled:YES];
			[stopAllRampButton setEnabled:numChannelsRamping>0];
			[rampAllToZeroButton setEnabled:numChannelsAboveZero>0 && numChannelsNonZeroHwGoal>0];
			[panicAllButton setEnabled:numChannelsAboveZero>0];
			[panicAllButton setTitle:@"PANIC ALL..."];
		}
		
		if([model failureEvents] || (channelStateMask == kiSegHVCardOutputSetEmergencyOff)){
			[clearAllPanicButton setEnabled:YES];
		}
		else {
			[clearAllPanicButton setEnabled:NO];
		}
	}
	else {
		//no crate power so disable everything
		[powerOnButton setEnabled:NO];
		[powerOffButton setEnabled:NO];
		[panicButton setEnabled:NO];
		[rampToZeroButton setEnabled:NO];
		[loadButton setEnabled:NO];
		[stopRampButton setEnabled:NO];
		[stateField setStringValue:@"OFF"];
		[panicButton setEnabled:NO];
		[clearPanicButton setEnabled:NO];
		[targetField setEnabled:NO];
		[riseRateField setEnabled:NO];
		[maxCurrentField setEnabled:NO];
	
		[powerAllOnButton setEnabled:NO];
		[powerAllOffButton setEnabled:NO];
		[panicAllButton setEnabled:NO];
		[rampAllToZeroButton setEnabled:NO];
		[loadAllButton setEnabled:NO];
		[stopAllRampButton setEnabled:NO];
		[panicAllButton setEnabled:NO];
		[panicAllButton setTitle:@"All HV OFF"];
		[clearAllPanicButton setEnabled:NO];
	}

}

- (void) outputStatusChanged:(NSNotification*)aNote
{
	int selectedChannel = [model selectedChannel];
	float voltage		= [model channel:selectedChannel readParamAsFloat:@"outputMeasurementSenseVoltage"];
	
	int state = [model channel:selectedChannel readParamAsInt:@"outputStatus"];
	if(state & outputOnMask){
		
		int selectedChannel = [model selectedChannel];
		[hwGoalField setStringValue:[model hwGoalString:selectedChannel]];

		if(state & outputRampUpMask)		[hvStatusImage setImage:[NSImage imageNamed:@"upRamp"]];
		else if(state & outputRampDownMask)	[hvStatusImage setImage:[NSImage imageNamed:@"downRamp"]];
		else {
			if(fabs(voltage) < 100){
				if(fabs(voltage) > 5)[hvStatusImage setImage:[NSImage imageNamed:@"lowVoltage"]];
				else			[hvStatusImage setImage:nil];
			}
			else [hvStatusImage setImage:[NSImage imageNamed:@"highVoltage"]];
		}
	}
	else {
		[hvStatusImage setImage:nil];	
		[hwGoalField setStringValue:@""];

	}
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"%@ Card (Slot %d)",[model name],[model slot]]];
	[slotField setIntValue:[model slot]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [[self window] setTitle:[NSString stringWithFormat:@"%@ Card (Slot %d)",[model name],[model slot]]];
	[slotField setIntValue:[model slot]];
}

#pragma mark •••Actions

- (void) shipRecordsAction:(id)sender
{
	[model setShipRecords:[sender intValue]];	
}

- (void) maxCurrentAction:(id)sender
{
	int selectedChannel = [model selectedChannel];
	[model setMaxCurrent:selectedChannel withValue:[sender floatValue]];	
}

- (IBAction) riseRateAction:(id)sender
{
	if([sender intValue] != [model riseRate]){
		[model setRiseRate:[sender floatValue]];
	}
}


- (IBAction) targetAction:(id)sender
{
	int selectedChannel = [model selectedChannel];
	if([sender intValue] != [model target:selectedChannel]){
		[model setTarget:selectedChannel withValue:[sender intValue]];
	}
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:[model settingsLock] to:[sender intValue] forWindow:[self window]];
}

- (IBAction) incChannelAction:(id)sender
{	
	int selectedChannel = [model selectedChannel] + 1;
	if(selectedChannel>[model numberOfChannels]-1)selectedChannel = 0;
	[model setSelectedChannel:selectedChannel];
}

- (IBAction) decChannelAction:(id)sender
{
	int selectedChannel = [model selectedChannel] - 1;
	if(selectedChannel<0)selectedChannel = [model numberOfChannels]-1;
	[model setSelectedChannel:selectedChannel];
}


- (IBAction) loadAction:(id)sender
{
	[self endEditing];
	int selectedChannel = [model selectedChannel];
	[model loadValues:selectedChannel];

}

#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
	if(aTableView == hvTableView){
		NSParameterAssert(rowIndex >= 0 && rowIndex < [model numberOfChannels]);
		if([[aTableColumn identifier] isEqualToString:@"channel"])return [NSNumber numberWithInteger:rowIndex];
		else {
			if([[aTableColumn identifier] isEqualToString:@"outputSwitch"]){
				return [model channelState:rowIndex];
			}
			else if([[aTableColumn identifier] isEqualToString:@"target"]){
				return [NSNumber numberWithInt:[model target:rowIndex]];
			}
			else if([[aTableColumn identifier] isEqualToString:@"maxCurrent"]){
				return [NSNumber numberWithFloat:[model maxCurrent:rowIndex]];
			}
			else if([[aTableColumn identifier] isEqualToString:@"outputMeasurementSenseVoltage"]){
				float theVoltage = [model channel:rowIndex readParamAsFloat:[aTableColumn identifier]];
				return [NSNumber numberWithFloat:theVoltage];
			}
			else if([[aTableColumn identifier] isEqualToString:@"outputMeasurementCurrent"]){
				float theCurrent = [model channel:rowIndex readParamAsFloat:[aTableColumn identifier]] *1000000.;
				return [NSNumber numberWithFloat:theCurrent];
			}
			else {
				//for now return value as object
				NSDictionary* theEntry = [model channel:rowIndex readParamAsObject:[aTableColumn identifier]];
				NSString* theValue = [theEntry objectForKey:@"Value"];
				if(theValue)return theValue;
				else return @"0";
			}
		}
		return @"--";
	}
	else return @"";
}

- (void) tableView: (NSTableView*) aTableView setObjectValue: (id) anObject forTableColumn: (NSTableColumn*) aTableColumn row: (NSInteger) aRowIndex
{
	if(aTableView == hvTableView){
		NSParameterAssert(aRowIndex >= 0 && aRowIndex < [model numberOfChannels]);
		NSString* colIdentifier = [aTableColumn identifier];
		if([colIdentifier isEqualToString:@"target"]){
			[model setTarget:aRowIndex withValue:[anObject floatValue]];
		}
		else 	if([colIdentifier isEqualToString:@"maxCurrent"]){
			[model setMaxCurrent:aRowIndex withValue:[anObject floatValue]];
		}
	}
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == hvTableView)return [model numberOfChannels];
	else return 0;
}

- (IBAction) powerOnAction:(id)sender
{
	[model turnChannelOn:[model selectedChannel]];
	[[model adapter] pollHardware];
}

- (IBAction) powerOffAction:(id)sender
{
	[model turnChannelOff:[model selectedChannel]];
	[[model adapter] pollHardware];
}

- (IBAction) stopRampAction:(id)sender
{
	[model stopRamping:[model selectedChannel]];
}

- (IBAction) rampToZeroAction:(id)sender
{	
	[model rampToZero:[model selectedChannel]];
}

- (IBAction) panicAction:(id)sender
{
	[self endEditing];
	int chan = [model selectedChannel];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:[NSString stringWithFormat:@"HV Panic Channel %d",chan]];
    [alert setInformativeText:[NSString stringWithFormat:@"Really Panic Channel %d High Voltage OFF?",chan]];
    [alert addButtonWithTitle:@"Yes/Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model panic:chan];
            NSLog(@"Panicked MPod (%u), Card %d Channel %d\n",[[model guardian]uniqueIdNumber],[model slot], chan);
        }
    }];
#else
    NSBeginAlertSheet([NSString stringWithFormat:@"HV Panic Channel %d",chan],
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,
					  [self window],
					  self,
					  @selector(_panicRampSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"%@",[NSString stringWithFormat:@"Really Panic Channel %d High Voltage OFF?",chan]);
#endif
}

- (IBAction) clearPanicAction:(id)sender
{
	[model clearPanicChannel:[model selectedChannel]];
	[model clearEventsChannel:[model selectedChannel]];
    [model clearModule];
}

- (IBAction) doNotPostSafetyLoopAlarmAction:(id)sender
{
    [model setDoNotPostSafetyLoopAlarm:[sender intValue]];
}

#pragma mark •••Actions for All
- (IBAction) powerAllOnAction:(id)sender
{
	int numberOffChannels = [model numberOfChannels]-[model numberChannelsOn];
	[self endEditing];
	NSString* s1;
	NSString* s2; 
	if(numberOffChannels == [model numberOfChannels]){
		s1 = @"Turn ON ALL Channels";
		s2 = @"Really Turn ON ALL Channels?";
	}
	else {
		s1 = [NSString stringWithFormat:@"Turn ON %d Channel%@",numberOffChannels,numberOffChannels>1?@"s":@""];
		s2 = [NSString stringWithFormat:@"Really Turn ON %d Channel%@ (%d Channel%@ already ON)",
			  numberOffChannels,
			  numberOffChannels>1?@"s":@"",
			  [model numberOfChannels]-numberOffChannels,
			  [model numberOfChannels]-numberOffChannels>1?@"s are":@" is"];
	}
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s1];
    [alert setInformativeText:s2];
    [alert addButtonWithTitle:@"Yes/Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model turnAllChannelsOn];
       }
    }];
#else
    NSBeginAlertSheet(s1,
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,
					  [self window],
					  self,
					  @selector(_allOnSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"%@",s2);
#endif
}

- (IBAction) powerAllOffAction:(id)sender
{
	[self endEditing];
	int numberOnChannels = [model numberChannelsOn];
	NSString* s1;
	NSString* s2; 
	if(numberOnChannels == [model numberOfChannels]){
		s1 = @"Turn OFF ALL Channels";
		s2 = @"Really Turn OFF ALL Channels?";
	}
	else {
		s1 = [NSString stringWithFormat:@"Turn OFF %d Channel%@",numberOnChannels,numberOnChannels>1?@"s":@""];
		s2 = [NSString stringWithFormat:@"Really Turn OFF %d Channel%@ (%d Channel%@ already OFF)",
			  numberOnChannels,
			  numberOnChannels>1?@"s":@"",
			  [model numberOfChannels]-numberOnChannels,
			  [model numberOfChannels]-numberOnChannels>1?@"s are":@" is"];
	}
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s1];
    [alert setInformativeText:s2];
    [alert addButtonWithTitle:@"Yes/Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model turnAllChannelsOff];
        }
    }];
#else
    NSBeginAlertSheet(s1,
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,
					  [self window],
					  self,
					  @selector(_allOffSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"%@",s2);
#endif

}

- (IBAction) stopAllRampAction:(id)sender
{
	[model stopAllRamping];
}

- (IBAction) rampAllToZeroAction:(id)sender
{	
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Ramp All Channels to Zero"];
    [alert setInformativeText:@"Really Ramp ALL Channels to Zero?"];
    [alert addButtonWithTitle:@"Yes/Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model rampAllToZero];
       }
    }];
#else
    NSBeginAlertSheet(@"Ramp All Channels to Zero",
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,
					  [self window],
					  self,
					  @selector(_allRampToZeroSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Really Ramp ALL Channels to Zero?");
#endif
	
}
- (IBAction) loadAllAction:(id)sender
{
	[self endEditing];
	[model loadAllValues];
}

- (IBAction) cleadModuleAction:(id)sender
{
    [model clearModule];
}

- (IBAction) panicAllAction:(id)sender
{
	[self endEditing];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"HV Panic ALL Channels"];
    [alert setInformativeText:@"Really Panic ALL Channels High Voltage OFF?"];
    [alert addButtonWithTitle:@"Yes/Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model panicAll];
            NSLog(@"Panicked All Channels MPod (%u), Card %d\n",[[model guardian]uniqueIdNumber],[model slot]);
       }
    }];
#else
    NSBeginAlertSheet(@"HV Panic ALL Channels",
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,
					  [self window],
					  self,
					  @selector(_panicAllRampSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Really Panic ALL Channels High Voltage OFF?");
#endif
}

- (IBAction) clearAllPanicAction:(id)sender
{
	[model clearAllPanicChannels];
	[model clearAllEventsChannels];
}

- (IBAction) syncAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Sync targets to Readback Voltages"];
    [alert setInformativeText:@"This will set the target voltages to the actual hw voltages. The actual hw voltages will not change until you 'load' the values.\n\nReally sync these values?\n\n"];
    [alert addButtonWithTitle:@"Yes/Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model syncDialog];
        }
    }];
#else
    NSBeginAlertSheet(@"Sync targets to Readback Voltages",
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,
					  [self window],
					  self,
					  @selector(_syncSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"This will set the target voltages to the actual hw voltages. The actual hw voltages will not change until you 'load' the values.\n\nReally sync these values?\n\n");
#endif
}

- (IBAction) listConstraintsAction:(id)sender
{
	if([model constraintsInPlace]){
        ORRunAlertPanel(@"The following constraints are in place", @"%@", @"OK", nil, nil,
                        [model constraintReport]);
        
    }
}


#pragma mark •••Plot Data Source
- (int)	numberPointsInPlot:(id)aPlotter
{
	int set = (int)[aPlotter tag];
	if(set < [model numberOfChannels]) return (int)[[model currentHistory:set] count];
	else		return (int)[[model voltageHistory:set-[model numberOfChannels]] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int set = (int)[aPlotter tag];
	if(set < [model numberOfChannels]){
		int count = (int)[[model currentHistory:set] count];
		int index = count-i-1;
		*xValue = [[model currentHistory:set] timeSampledAtIndex:index];
		*yValue = [[model currentHistory:set] valueAtIndex:index] * 1000000.;
	}
	else {
		int count = (int)[[model voltageHistory:set-[model numberOfChannels]] count];
		int index = count-i-1;
		*xValue = [[model voltageHistory:set-[model numberOfChannels]] timeSampledAtIndex:index];
		*yValue = [[model voltageHistory:set-[model numberOfChannels]] valueAtIndex:index];
	}
}

@end

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
@implementation ORiSegHVCardController (private)

- (void) _allRampToZeroSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info
{
	if(returnCode == NSAlertFirstButtonReturn){
		[model rampAllToZero];
	}
}

- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info
{
	if(returnCode == NSAlertFirstButtonReturn){
        int aChannel = [model selectedChannel];
		[model panic:aChannel];
        NSLog(@"Panicked MPod (%u), Card %d Channel %d\n",[[model guardian]uniqueIdNumber],[model slot], aChannel);
	}
}

- (void) _panicAllRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info
{
	if(returnCode == NSAlertFirstButtonReturn){
		[model panicAll];
        NSLog(@"Panicked All Channels MPod (%u), Card %d\n",[[model guardian]uniqueIdNumber],[model slot]);

	}
}
- (void) _syncSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info
{
	if(returnCode == NSAlertFirstButtonReturn){
		[model syncDialog];
	}
}
- (void) _allOnSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info
{
	if(returnCode == NSAlertFirstButtonReturn){
		[model turnAllChannelsOn];
	}
}

- (void) _allOffSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info
{
	if(returnCode == NSAlertFirstButtonReturn){
		[model turnAllChannelsOff];
	}
}

@end
#endif
