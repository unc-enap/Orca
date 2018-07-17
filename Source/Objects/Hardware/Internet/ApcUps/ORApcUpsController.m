//
//  ORHPApcUpsController.m
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
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


#import "ORApcUpsController.h"
#import "ORApcUpsModel.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"

@implementation ORApcUpsController
- (id) init
{
    self = [ super initWithWindowNibName: @"ApcUps" ];
    return self;
}
- (void) awakeFromNib
{
	[subComponentsView setGroup:model];
 	[super awakeFromNib];
    int i;
    
    NSColor* theColors[8] =
	{
		[NSColor redColor],
		[NSColor darkGrayColor],
		[NSColor blueColor],
		[NSColor magentaColor],
		[NSColor blackColor],
		[NSColor orangeColor],
		[NSColor purpleColor],
		[NSColor brownColor]
	};
    int tag = 0;
    for(i=0;i<3;i++){
        ORTimeLinePlot* aPlot= [[ORTimeLinePlot alloc] initWithTag:tag andDataSource:self];
        [aPlot setLineColor:theColors[i]];
        [aPlot setName:[model nameForChannel:tag]];
        [plotter0 addPlot: aPlot];
        [aPlot release];
        tag++;
    }
    
    for(i=0;i<6;i++){
        ORTimeLinePlot* aPlot= [[ORTimeLinePlot alloc] initWithTag:tag andDataSource:self];
        [aPlot setLineColor:theColors[i]];
        [aPlot setName:[model nameForChannel:tag]]; 
        [plotter1 addPlot: aPlot];
        [aPlot release];
        tag++;
    }
    
	[(ORTimeAxis*)[plotter0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
    [plotter0 setPlotTitle:@"Battery Status"];
    [plotter1 setPlotTitle:@"Voltage and Current"];
    [plotter0 setShowLegend:YES];
    [plotter1 setShowLegend:YES];

    [[plotter0 yAxis] setRngLow:0.0 withHigh:250];
	[[plotter0 yAxis] setRngLimitsLow:0.0 withHigh:250 withMinRng:4];
    [[plotter1 yAxis] setRngLow:0.0 withHigh:150.];
	[[plotter1 yAxis] setRngLimitsLow:0.0 withHigh:150 withMinRng:4];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORApcUpsIpAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isConnectedChanged:)
                         name : ORApcUpsIsConnectedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORApcUpsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(refreshTables:)
                         name : ORApcUpsRefreshTables
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(pollingTimesChanged:)
                         name : ORApcUpsPollingTimesChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(timedOut:)
                         name : ORApcUpsTimedOut
                        object: model];
    
    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
    
    [notifyCenter addObserver : self
					 selector : @selector(updateTimePlot:)
						 name : ORRateAverageChangedNotification
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(dataValidChanged:)
						 name : ORApcUpsDataValidChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(passwordChanged:)
						 name : ORApcUpsPasswordChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(usernameChanged:)
						 name : ORApcUpsUsernameChanged
					   object : model];
    
    [notifyCenter addObserver : self
					 selector : @selector(refreshProcessTable:)
						 name : ORApcUpsLowLimitChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(refreshProcessTable:)
						 name : ORApcUpsHiLimitChanged
					   object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(eventLogChanged:)
                         name : ORApcUpsModelEventLogChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(maintenanceModeChanged:)
                         name : ORApcUpsModelMaintenanceModeChanged
						object: model];

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

}


- (void) updateWindow
{
    [ super updateWindow ];
    
    [self settingsLockChanged:nil];
	[self ipAddressChanged:nil];
	[self usernameChanged:nil];
	[self passwordChanged:nil];
	[self isConnectedChanged:nil];
	[self refreshTables:nil];
	[self pollingTimesChanged:nil];
	[self dataValidChanged:nil];
	[self updateTimePlot:nil];
    [self refreshProcessTable:nil];
	[self eventLogChanged:nil];
	[self maintenanceModeChanged:nil];
}

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[subComponentsView setNeedsDisplay:YES];
	}
}

- (void) maintenanceModeChanged:(NSNotification*)aNote
{
    BOOL inMaintenanceMode = [model maintenanceMode];
    [maintenanceModeButton setTitle:inMaintenanceMode?@"End Maintenance":@"Start Maintenance"];
	[maintenanceModeField setStringValue: inMaintenanceMode?@"Maintence Mode":@""];
}

- (void) eventLogChanged:(NSNotification*)aNote
{
    NSArray* events = [model sortedEventLog];
    NSMutableString* eventLog = [NSMutableString stringWithString:@""];
    for (NSString *anEvent in events) {
        [eventLog appendFormat:@"%@\n",anEvent];
    }
    if([eventLog length])[eventLogTextView setString:eventLog];
    else [eventLogTextView setString:@""];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORApcUpsLock to:secure];
    [dialogLock setEnabled:secure];
}

#pragma mark •••Notifications

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter0 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 xAxis]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter0 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 yAxis]attributes] forKey:@"YAttributes0"];
	};
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
    
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 xAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 yAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 yAxis] setNeedsDisplay:YES];
		}
	}
}

- (void) updateTimePlot:(NSNotification*)aNote
{
    int i;
    for(i=0;i<3;i++){
        if(!aNote || [aNote object] == [model timeRate:i]){
            [plotter0 setNeedsDisplay:YES];
            break;
        }
    }
    for(i=0;i<6;i++){
        if(!aNote || [aNote object] == [model timeRate:i]){
            [plotter1 setNeedsDisplay:YES];
            break;
        }
    }
}

- (void) timedOut:(NSNotification*)aNote
{
    [timedOutField setStringValue:@"No Response"];
}
- (void) connectionChanged:(NSNotification*)aNote
{
}
- (void) dataValidChanged:(NSNotification*)aNote
{
    if([model dataValid]){
        [dataValidField setTextColor:[NSColor blackColor]];
        [dataValidField setStringValue: @"Data was returned"];
    }
    else {
        [dataValidField setTextColor:[NSColor redColor]];
        [dataValidField setStringValue: @"Data Invalid"];
    }
    [self refreshTables:nil];
}

- (void) passwordChanged:(NSNotification*)aNote
{
	if([model password]!=nil)[passwordField setStringValue: [model password]];
}

- (void) usernameChanged:(NSNotification*)aNote
{
    if([model username]!=nil) [usernameField setStringValue: [model username]];
}

- (void) isConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedField setStringValue: [model isConnected]?@"Polling":@"Idle"];
}

- (void) refreshTables:(NSNotification*)aNote
{
    NSString* name = [[model valueDictionary] objectForKey:@"NAME"];
    if([name length]!=0)[[self window] setTitle:[NSString stringWithFormat:@"UPS : %@",name]];
    [powerTableView reloadData];
    [loadTableView reloadData];
    [batteryTableView reloadData];
}
- (void) refreshProcessTable:(NSNotification*)aNote
{
    [processTableView reloadData];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressField setStringValue: [model ipAddress]];
}

- (void) pollingTimesChanged:(NSNotification*)aNote
{
    [lastPolledField setObjectValue:[model lastTimePolled]];
    if(![model maintenanceMode]){
        [nextPollField setObjectValue:[model nextPollScheduled]];
    }
    else {
        [nextPollField setStringValue:@"---"];
    }
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL locked			= [gSecurity isLocked:ORApcUpsLock];

	[ipAddressField setEnabled:!locked];
	[usernameField setEnabled:!locked];
	[passwordField setEnabled:!locked];
    [dialogLock setState: locked];
}

#pragma mark •••Actions

- (IBAction) maintenanceModeAction:(id)sender
{
    if(![model maintenanceMode]){
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:@"Really Start Maintenance Mode."];
        [alert setInformativeText:@"This will stop polling the UPS and allow unfetered access via the web interface. It will disable all power out alarms. It will automatically revert to normal operations in 30 minutes."];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Yes, Go to Maintenance"];
        [alert setAlertStyle:NSAlertStyleWarning];
        
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
            if (result == NSAlertSecondButtonReturn){
                [model setMaintenanceMode:YES];
             }
        }];
#else
        NSBeginAlertSheet(@"Really Start Maintenance Mode.",
                          @"Cancel",
                          @"Yes, Go to Maintenance",
                          nil,[self window],
                          self,
                          @selector(maintenanceModeActionDidEnd:returnCode:contextInfo:),
                          nil,
                          nil,@"This will stop polling the UPS and allow unfetered access via the web interface. It will disable all power out alarms. It will automatically revert to normal operations in 30 minutes.");
#endif
    }
    else {
        [model setMaintenanceMode:NO];
    }
}
    
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) maintenanceModeActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){
        [model setMaintenanceMode:YES];
    }
}
#endif
- (IBAction) clearEventLogAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Clear the Event Log."];
    [alert setInformativeText:@"This will clear the persistant history event log kept by ORCA and refresh with only the latest events recorded by the UPS. Is that really what you want to do?"];
    [alert addButtonWithTitle:@"Yes, Event Log"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model clearEventLog];
        }
    }];
#else
    NSBeginAlertSheet(@"Clear the Event Log.",
                      @"Cancel",
                      @"Yes, Clear Event Log",
                      nil,[self window],
                      self,
                      @selector(clearEventActionDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"This will clear the persistant history event log kept by ORCA and refresh with only the latest events recorded by the UPS. Is that really what you want to do?");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) clearEventActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){
		[model clearEventLog];
	}
}
#endif
- (IBAction) ipAddressAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) usernameAction:(id)sender
{
	[model setUsername:[sender stringValue]];
}

- (IBAction) passwordAction:(id)sender
{
	[model setPassword:[sender stringValue]];
}

- (IBAction) connectAction:(id)sender
{
	[self endEditing];
	[model pollHardware];
}

- (IBAction) dialogLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORApcUpsLock to:[sender intValue] forWindow:[self window]];
}

#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    if(aTableView == powerTableView){
        if([[aTableColumn identifier] isEqualToString:@"Name"]){
            return [model nameAtIndexInPowerTable:(int)rowIndex];
        }
        else {
            if([model dataValid]){
                if(rowIndex==4){
                    //special case, just one value in the first column
                    if([[aTableColumn identifier] isEqualToString:@"1"]) return [model valueForKeyInValueDictionary:@"INPUT FREQUENCY"];
                    else return @"";
                }
                else return [model valueForPowerPhase:[[aTableColumn identifier] intValue] powerTableIndex:(int)rowIndex];
            }
            else return @"?";
        }
    }
    else if(aTableView == loadTableView){
        if([[aTableColumn identifier] isEqualToString:@"Name"]) return [model nameForIndexInLoadTable:(int)rowIndex];
        else {
            if([model dataValid]){
                if(rowIndex==2){
                    if([[aTableColumn identifier] isEqualToString:@"1"]) return [model valueForKeyInValueDictionary:@"INTERNAL TEMPERATURE"];
                    else return @"";
                }
                else if(rowIndex==3){
                    if([[aTableColumn identifier] isEqualToString:@"1"]) return [model valueForKeyInValueDictionary:@"OUTPUT FREQUENCY"];
                    else return @"";
                }
                else return [model valueForLoadPhase:[[aTableColumn identifier] intValue] loadTableIndex:(int)rowIndex];
            }
            else return @"?";
        }
    }
    else if(aTableView == batteryTableView){
        if([[aTableColumn identifier] isEqualToString:@"Name"]) return [model nameForIndexInBatteryTable:(int)rowIndex];
        else {
            if([model dataValid]){
                return [model valueForBattery:[[aTableColumn identifier] intValue] batteryTableIndex:(int)rowIndex];
            }
            else return @"?";           
        }
    }
    else if(aTableView == processTableView){
        if([[aTableColumn identifier] isEqualToString:@"Name"]) return [model nameForIndexInProcessTable:(int)rowIndex];
        else if([[aTableColumn identifier] isEqualToString:@"Channel"]) return [NSNumber numberWithInt:(int)rowIndex];
        else if([[aTableColumn identifier] isEqualToString:@"LowLimit"]) return [NSNumber numberWithFloat:[model lowLimit:(int)rowIndex]];
        else if([[aTableColumn identifier] isEqualToString:@"HiLimit"]) return [NSNumber numberWithFloat:[model hiLimit:(int)rowIndex]];
    }

    return nil;
}

- (void) tableView:(NSTableView *) aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(aTableView == processTableView){
        if([[aTableColumn identifier]      isEqualToString:@"LowLimit"])      [model setLowLimit:(int)rowIndex value:[object floatValue]];
        else if([[aTableColumn identifier] isEqualToString:@"HiLimit"])  [model setHiLimit:(int)rowIndex value:[object floatValue]];
    }
}

//
// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == powerTableView){
        return 5;
    }
    else if(aTableView == loadTableView){
        return 4;
    }
    else if(aTableView == batteryTableView){
        return 4;
    }
    else if(aTableView == processTableView){
        return kNumApcUpsAdcChannels;
    }
    else return 0;
}

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
    int aTag = (int)[aPlotter tag];
	return (int)[[model timeRate:aTag] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    int aTag = (int)[aPlotter tag];
	int count = (int)[[model timeRate:aTag] count];
	int index = count-i-1;
	*xValue = [[model timeRate:aTag] timeSampledAtIndex:index];
	*yValue = [[model timeRate:aTag] valueAtIndex:index];
}

@end
