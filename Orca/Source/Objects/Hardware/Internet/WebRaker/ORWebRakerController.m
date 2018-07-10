//
//  ORWebRakerController.m
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


#import "ORWebRakerController.h"
#import "ORWebRakerModel.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"

@implementation ORWebRakerController
- (id) init
{
    self = [ super initWithWindowNibName: @"WebRaker" ];
    return self;
}
- (void) awakeFromNib
{
 	[super awakeFromNib];

    ORTimeLinePlot* aPlot= [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
    [aPlot setLineColor:[NSColor redColor]];
    [aPlot setName:@"?"];
    [plotter0 addPlot: aPlot];
    [aPlot release];

    
	[(ORTimeAxis*)[plotter0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
    [plotter0 setPlotTitle:@"Values"];
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
                         name : ORWebRakerIpAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORWebRakerLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(pollingTimesChanged:)
                         name : ORWebRakerPollingTimesChanged
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
						 name : ORWebRakerDataValidChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(refreshProcessTable:)
						 name : ORWebRakerLowLimitChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(refreshProcessTable:)
                         name : ORWebRakerMinValueChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(refreshProcessTable:)
                         name : ORWebRakerMaxValueChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(refreshProcessTable:)
                         name : ORWebRakerLowLimitChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(valuesChanged:)
                         name : ORWebRakerValueChanged
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                        object: nil];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"Web Raker %lu",[model uniqueIdNumber]]];
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

- (void) tableViewSelectionDidChange:(NSNotification*)aNote
{
    if([aNote object] == dataTableView || !aNote){
        int index = [dataTableView selectedRow];
        if(index<0 || index>[model numDataItems]){
            [detailsView setString:@""];
        }
        else {
            NSDictionary* dict = [model dataAtIndex:index];
            NSString* s = [NSString stringWithFormat:@"%@",dict];
            s = [s stringByReplacingOccurrencesOfString:@"{" withString:@""];
            s = [s stringByReplacingOccurrencesOfString:@"}" withString:@""];
            [detailsView setString:s];
        }
    }
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORWebRakerLock to:secure];
    [dialogLock setEnabled:secure];
}

#pragma mark •••Notifications
- (void) updateTimePlot:(NSNotification*)aNote
{
    int i;
    for(i=0;i<[model numDataItems];i++){
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
    [dataTableView reloadData];
    [self tableViewSelectionDidChange:nil];
}

- (void) dataValidChanged:(NSNotification*)aNote
{
    if([model dataValid]){
        
        //do the plot set up here since we didn't know the number of plots until now
        
        int plotCountDiff = [model numDataItems] - [plotter0 numberOfPlots];
        if(plotCountDiff != 0){
        [plotter0 removeAllPlots];
            NSColor* theColors[10] =
            {
                [NSColor redColor],
                [NSColor blueColor],
                [NSColor blackColor],
                [NSColor darkGrayColor],
                [NSColor greenColor],
                [NSColor yellowColor],
                [NSColor cyanColor],
                [NSColor magentaColor],
                [NSColor purpleColor],
                [NSColor brownColor],
            };
            int tag = 0;
            int i;
            for(i=0;i<[model numDataItems];i++){
                ORTimeLinePlot* aPlot= [[ORTimeLinePlot alloc] initWithTag:tag andDataSource:self];
                [aPlot setLineColor:theColors[i%10]];
                [aPlot setName:@"?"];
                [plotter0 addPlot: aPlot];
                [aPlot release];
                tag++;
            }
        }
    
        [dataValidField setTextColor:[NSColor blackColor]];
        [dataValidField setStringValue: @"Data was returned"];
        int i;
        for(i=0;i<[model numDataItems];i++){
            NSString* description = [[model dataAtIndex:i] objectForKey:@"description"];
            NSString* type        = [[model dataAtIndex:i] objectForKey:@"type"];
            [(ORTimeLinePlot*)[plotter0 plot:i] setName:[NSString stringWithFormat:@"%@ %@",description,type]];
        }
        [plotter0 setShowLegend:NO];
        [plotter0 adjustPositionsAndSizes];
        [plotter0 setShowLegend:YES];

    }
    else {
        [dataValidField setTextColor:[NSColor redColor]];
        [dataValidField setStringValue: @"Waiting"];
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
    BOOL locked			= [gSecurity isLocked:ORWebRakerLock];

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
    [gSecurity tryToSetLock:ORWebRakerLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) pollNowAction:(id)sender
{
    [self endEditing];
    [model pollHardware];
}

#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    if(aTableView == processTableView){
        if([[aTableColumn identifier] isEqualToString:@"description"]){
            NSString* description = [[model dataAtIndex:rowIndex] objectForKey:@"description"];
            NSString* type        = [[model dataAtIndex:rowIndex] objectForKey:@"type"];
            return [NSString stringWithFormat:@"%@/%@",description,type];
        }
        else if([[aTableColumn identifier] isEqualToString:@"Channel"]) return [NSNumber numberWithInt:rowIndex];
        else if([[aTableColumn identifier] isEqualToString:@"LowLimit"]) return [NSNumber numberWithFloat:[model lowLimit:rowIndex]];
        else if([[aTableColumn identifier] isEqualToString:@"HiLimit"]) return [NSNumber numberWithFloat:[model hiLimit:rowIndex]];
        else if([[aTableColumn identifier] isEqualToString:@"MinValue"]) return [NSNumber numberWithFloat:[model minValue:rowIndex]];
        else if([[aTableColumn identifier] isEqualToString:@"MaxValue"]) return [NSNumber numberWithFloat:[model maxValue:rowIndex]];
    }
    else if(aTableView == dataTableView){
        if([[aTableColumn identifier] isEqualToString:@"time"]){
            unsigned long t = [[[model dataAtIndex:rowIndex] objectForKey:[aTableColumn identifier]] intValue];
            return [[NSDate dateWithTimeIntervalSince1970:t] stdDescription];
        }
        else return [[model dataAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
    }

    return nil;
}

- (void) tableView:(NSTableView *) aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(aTableView == processTableView){
        if([[aTableColumn identifier]      isEqualToString:@"LowLimit"]) [model setLowLimit:rowIndex value:[object floatValue]];
        else if([[aTableColumn identifier] isEqualToString:@"HiLimit"])  [model setHiLimit:rowIndex value:[object floatValue]];
        else if([[aTableColumn identifier] isEqualToString:@"MinValue"])  [model setMinValue:rowIndex value:[object floatValue]];
        else if([[aTableColumn identifier] isEqualToString:@"MaxValue"])  [model setMaxValue:rowIndex value:[object floatValue]];
    }
}

//
// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [model numDataItems];
}

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
    int aTag = [aPlotter tag];
	return [[model timeRate:aTag] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    int aTag = [aPlotter tag];
	int count = [[model timeRate:aTag] count];
	int index = count-i-1;
	*xValue = [[model timeRate:aTag] timeSampledAtIndex:index];
	*yValue = [[model timeRate:aTag] valueAtIndex:index];
}

@end
