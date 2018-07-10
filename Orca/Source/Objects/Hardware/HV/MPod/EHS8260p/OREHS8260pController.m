//-------------------------------------------------------------------------
//  OREHS8260pController.h
//
//  Created by Mark Howe on Tues Feb 1,2011
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
#import "OREHS8260pController.h"
#import "OREHS8260pModel.h"
#import "ORDetectorRamper.h"

@implementation OREHS8260pController

-(id)init
{
    self = [super initWithWindowNibName:@"EHS8260p"];
    return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(tripTimeChanged:)
                         name : OREHS8260pModelTripTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(currentTripBehaviorChanged:)
                         name : OREHS8260pModelCurrentTripBehaviorChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(outputFailureBehaviorChanged:)
                         name : OREHS8260pModelOutputFailureBehaviorChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(outputFailureBehaviorChanged:)
                         name : OREHS8260pModelOutputFailureBehaviorChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(ramperEnabledChanged:)
                         name : ORDetectorRamperEnabledChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(ramperStateChanged:)
                         name : ORDetectorRamperStateChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(ramperParameterChanged:)
                         name : ORDetectorRamperStepWaitChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(ramperParameterChanged:)
                         name : ORDetectorRamperLowVoltageWaitChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(ramperParameterChanged:)
                         name : ORDetectorRamperLowVoltageThresholdChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(ramperParameterChanged:)
                         name : ORDetectorRamperLowVoltageStepChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(ramperParameterChanged:)
                         name : ORDetectorRamperMaxVoltageChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(ramperParameterChanged:)
                         name : ORDetectorRamperMinVoltageChanged
						object: model];
	
}

- (void) updateWindow
{
    [super updateWindow];
 	[self tripTimeChanged:nil];
	[self currentTripBehaviorChanged:nil];
	[self outputFailureBehaviorChanged:nil];
	[self ramperParameterChanged:nil];
}

#pragma mark •••Interface Management
- (void) ramperEnabledChanged:(NSNotification*)aNote
{
	[hvTableView reloadData];
	[self outputStatusChanged:aNote];
	[self setRampTypeField];
}

- (void) ramperStateChanged:(NSNotification*)aNote
{
	[hvTableView reloadData];
	[self outputStatusChanged:aNote];
}

- (void) selectedChannelChanged:(NSNotification*)aNote
{
	[super selectedChannelChanged:aNote];
	[self setRampTypeField];
}

- (void) setRampTypeField
{
	int chan = [model selectedChannel];
	[rampTypeField setStringValue:[[model ramper:chan] enabled]?@"Staged Ramp":@""];
}

- (void) ramperParameterChanged:(NSNotification*)aNote
{
	[ramperTableView reloadData];
}

- (void) outputFailureBehaviorChanged:(NSNotification*)aNote
{
	int chan = [model selectedChannel];
	[outputFailureBehaviorPU selectItemAtIndex: [model outputFailureBehavior:chan]];
	if(([model outputFailureBehavior:chan] & 0x3) == 0){
		[hwKillStatusField setStringValue:@"HW Kill Disabled"];
	}
	else {
		[hwKillStatusField setStringValue:@""];
	}

    [self channelReadParamsChanged:nil]; //force reload of table
}

- (void) currentTripBehaviorChanged:(NSNotification*)aNote
{
	int chan = [model selectedChannel];
	[currentTripBehaviorPU selectItemAtIndex: [model currentTripBehavior:chan]];
    [self channelReadParamsChanged:nil]; //force reload of table
}

- (void) tripTimeChanged:(NSNotification*)aNote
{
	int chan = [model selectedChannel];
	[tripTimeTextField setIntValue: [model tripTime:chan]];
    [self channelReadParamsChanged:nil]; //force reload of table
}

- (void) channelReadParamsChanged:(NSNotification*)aNote
{
	[super channelReadParamsChanged:aNote];
	int chan = [model selectedChannel];
	[tripTimeTextField setIntValue: [model tripTime:chan]];
	[currentTripBehaviorPU selectItemAtIndex: [model currentTripBehavior:chan]];
	[outputFailureBehaviorPU selectItemAtIndex: [model outputFailureBehavior:chan]];
}

#pragma mark •••Actions
- (void) outputFailureBehaviorAction:(id)sender
{
	int chan = [model selectedChannel];
	[model setOutputFailureBehavior:chan withValue:[sender indexOfSelectedItem]];	
	[model writeSupervisorBehaviour:chan];

}

- (void) currentTripBehaviorAction:(id)sender
{
	int chan = [model selectedChannel];
	[model setCurrentTripBehavior:chan withValue:[sender indexOfSelectedItem]];	
	[model writeSupervisorBehaviour:chan];
}

- (IBAction) tripTimeAction:(id)sender
{
	int chan = [model selectedChannel];
	[model setTripTime:chan withValue:[sender intValue]];
}

#pragma mark •••Data Source Methods
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == ramperTableView)	return 8;
	else return [super numberOfRowsInTableView:aTableView];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(aTableView == hvTableView){
		if([[aTableColumn identifier] isEqualToString:@"stagedRamp"]){
			[[model ramper:rowIndex] setEnabled:[anObject intValue]];
		}
	}
	else if(aTableView == ramperTableView){
		if([[aTableColumn identifier] isEqualToString:@"stepWait"]){
			[[model ramper:rowIndex] setStepWait:[anObject intValue]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"lowVoltageWait"]){
			[[model ramper:rowIndex] setLowVoltageWait:[anObject intValue]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"lowVoltageThreshold"]){
			[[model ramper:rowIndex] setLowVoltageThreshold:[anObject floatValue]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"voltageStep"]){
			[[model ramper:rowIndex] setVoltageStep:[anObject floatValue]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"lowVoltageStep"]){
			[[model ramper:rowIndex] setLowVoltageStep:[anObject floatValue]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"maxVoltage"]){
			[[model ramper:rowIndex] setMaxVoltage:[anObject floatValue]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"minVoltage"]){
			[[model ramper:rowIndex] setMinVoltage:[anObject floatValue]];
		}
	}
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(aTableView == hvTableView){
		NSParameterAssert(rowIndex >= 0 && rowIndex < 8);
		if([[aTableColumn identifier] isEqualToString:@"channel"])return [NSNumber numberWithInt:rowIndex];
		else if([[aTableColumn identifier] isEqualToString:@"outputSwitch"]){
			return [model channelState:rowIndex];
		}
		else if([[aTableColumn identifier] isEqualToString:@"stagedRamp"]){
			return [NSNumber numberWithInt:[[model ramper:rowIndex] enabled]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"ramperState"]){
			return [[model ramper:rowIndex] stateString];
		}
		else if([[aTableColumn identifier] isEqualToString:@"target"]){
			return [NSNumber numberWithInt:[model target:rowIndex]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"tripTime"]){
			return [NSNumber numberWithInt:[model tripTime:rowIndex]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"maxCurrent"]){
			return [NSNumber numberWithFloat:[model maxCurrent:rowIndex]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"outputMeasurementSenseVoltage"]){
			float senseVoltage = [model channel:rowIndex readParamAsFloat:[aTableColumn identifier]];
			return [NSNumber numberWithFloat:senseVoltage];
		}
		else if([[aTableColumn identifier] isEqualToString:@"outputMeasurementCurrent"]){
			float theCurrent = [model channel:rowIndex readParamAsFloat:[aTableColumn identifier]] *1000000.;
			return [NSNumber numberWithFloat:theCurrent];
		}
		
		else if([[aTableColumn identifier] isEqualToString:@"outputSupervisionBehavior"]){
			return [model behaviourString:rowIndex];
		}
		else {
				//for now return value as object
			NSDictionary* theEntry = [model channel:rowIndex readParamAsObject:[aTableColumn identifier]];
			NSString* theValue = [theEntry objectForKey:@"Value"];
			if(theValue)return theValue;
			else return @"0";
		}
		
	}
	else if(aTableView == ramperTableView){
		NSParameterAssert(rowIndex >= 0 && rowIndex < 8);
		if([[aTableColumn identifier] isEqualToString:@"channel"])return [NSNumber numberWithInt:rowIndex];
		else if([[aTableColumn identifier] isEqualToString:@"stepWait"]){
			return [NSNumber numberWithInt:[[model ramper:rowIndex] stepWait]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"lowVoltageThreshold"]){
			return [NSNumber numberWithInt:[[model ramper:rowIndex] lowVoltageThreshold]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"voltageStep"]){
			return [NSNumber numberWithInt:[[model ramper:rowIndex] voltageStep]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"lowVoltageWait"]){
			return [NSNumber numberWithInt:[[model ramper:rowIndex] lowVoltageWait]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"lowVoltageStep"]){
			return [NSNumber numberWithInt:[[model ramper:rowIndex] lowVoltageStep]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"maxVoltage"]){
			return [NSNumber numberWithInt:[[model ramper:rowIndex] maxVoltage]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"minVoltage"]){
			return [NSNumber numberWithInt:[[model ramper:rowIndex] minVoltage]];
		}
		else return @"";
	}
	else return @"";
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex 
{    
	if(aTableView == hvTableView){
		if([[aTableColumn identifier] isEqualToString:@"stagedRamp"] && [[model ramper:rowIndex] running]) {   
			[aCell setEnabled:NO];
		}  
		else [aCell setEnabled:YES];
	}
	else [aCell setEnabled:YES];

}	
@end
