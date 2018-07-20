//
//  ORHPMJDDewarScaleController.m
//  Orca
//
//  Created by Mark Howe on Mon Jan 11 2016
//  Copyright (c) 2016 CENPA, University of Washington. All rights reserved.
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


#import "ORMJDDewarScaleController.h"
#import "ORMJDDewarScaleModel.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"

@implementation ORMJDDewarScaleController
- (id) init
{
    self = [ super initWithWindowNibName: @"MJDDewarScale" ];
    return self;
}
- (void) awakeFromNib
{
 	[super awakeFromNib];
    int i;
    
    NSColor* theColors[2] =
    {
        [NSColor redColor],
        [NSColor blueColor],
     };
    int tag = 0;
    for(i=0;i<kNumMJDDewarScaleChannels;i++){
        ORTimeLinePlot* aPlot= [[ORTimeLinePlot alloc] initWithTag:tag andDataSource:self];
        [aPlot setLineColor:theColors[i]];
        [aPlot setName:[NSString stringWithFormat:@"Dewar %d",i]];
        [plotter0 addPlot: aPlot];
        [aPlot release];
        tag++;
    }
    
	[(ORTimeAxis*)[plotter0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
    [plotter0 setPlotTitle:@"Level (%)"];
    [plotter0 setShowLegend:YES];

    [[plotter0 yAxis] setRngLow:0.0 withHigh:100];
	[[plotter0 yAxis] setRngLimitsLow:0.0 withHigh:100 withMinRng:4];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORMJDDewarScaleIpAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORMJDDewarScaleLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(pollingTimesChanged:)
                         name : ORMJDDewarScalePollingTimesChanged
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
						 name : ORMJDDewarScaleDataValidChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(refreshProcessTable:)
						 name : ORMJDDewarScaleLowLimitChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(refreshProcessTable:)
                         name : ORMJDDewarScaleHiLimitChanged
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(valuesChanged:)
                         name : ORMJDDewarScaleValueChanged
                       object : model];
    
    
    
}


- (void) updateWindow
{
    [ super updateWindow ];
    
    [self settingsLockChanged:nil];
	[self ipAddressChanged:nil];
	[self pollingTimesChanged:nil];
	[self dataValidChanged:nil];
	[self updateTimePlot:nil];
    [self refreshProcessTable:nil];
    [self valuesChanged:nil];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMJDDewarScaleLock to:secure];
    [dialogLock setEnabled:secure];
}

#pragma mark •••Notifications
- (void) updateTimePlot:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumMJDDewarScaleChannels;i++){
        if(!aNote || [aNote object] == [model timeRate:i]){
            [plotter0 setNeedsDisplay:YES];
            break;
        }
    }
}

- (void) refreshProcessTable:(NSNotification*)aNote
{
    [processTableView reloadData];
}
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

- (void) valuesChanged:(NSNotification*)aNote
{
    [self updateValueMatrix:valueMatrix        getter:@selector(value:)];
    [self updateValueMatrix:weightMatrix        getter:@selector(weight:)];
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
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressField setStringValue: [model ipAddress]];
}

- (void) pollingTimesChanged:(NSNotification*)aNote
{
    [lastPolledField setObjectValue:[model lastTimePolled]];
    [nextPollField setObjectValue:[model nextPollScheduled]];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL locked			= [gSecurity isLocked:ORMJDDewarScaleLock];

	[ipAddressField setEnabled:!locked];
    [dialogLock setState: locked];
}

#pragma mark •••Actions

- (IBAction) ipAddressAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) dialogLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORMJDDewarScaleLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) pollNowAction:(id)sender
{
    [self endEditing];
    [model pollHardware];
}

#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
 if(aTableView == processTableView){
        if([[aTableColumn identifier] isEqualToString:@"Name"]) return [NSString stringWithFormat:@"Dewar %d",(int)rowIndex];
        else if([[aTableColumn identifier] isEqualToString:@"Channel"]) return [NSNumber numberWithInteger:rowIndex];
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
if(aTableView == processTableView){
        return kNumMJDDewarScaleChannels;
    }
    else return 0;
}

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
    NSUInteger aTag = [aPlotter tag];
	return (int)[[model timeRate:(int)aTag] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    NSUInteger aTag = [aPlotter tag];
	int count = (int)[[model timeRate:(int)aTag] count];
	int index = count-i-1;
	*xValue = [[model timeRate:(int)aTag] timeSampledAtIndex:(int)index];
	*yValue = [[model timeRate:(int)aTag] valueAtIndex:index];
}

@end
