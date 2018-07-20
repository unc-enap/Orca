//
//  ORTristanFLTController.m
//  Orca
//
//  Created by Mark Howe on 1/23/18.
//  Copyright 2018, University of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORTristanFLTController.h"
#import "ORTristanFLTModel.h"
#import "ORPlotView.h"
#import "ORValueBarGroupView.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"
#import "ORTimeLinePlot.h"

@implementation ORTristanFLTController

#pragma mark ***Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"TristanFLT"];
    return self;
}

#pragma mark ***Initialization
- (void) dealloc
{
	[rateFormatter release];
	[blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
    settingSize			= NSMakeSize(515,435);
    rateSize			= NSMakeSize(505,450);
	
	rateFormatter = [[NSNumberFormatter alloc] init];
	[rateFormatter setFormat:@"##0.00"];
	[totalHitRateField setFormatter:rateFormatter];
	[rateTextFields setFormatter:rateFormatter];
    blankView = [[NSView alloc] init];
    
    NSString* key = [NSString stringWithFormat: @"orca.ORTristanFLT%d.selectedtab",(int)[model stationNumber]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
    [[timeRatePlot yAxis] setRngLimitsLow:0 withHigh:24*1000000 withMinRng:5];

	[aPlot release];

	[rate0 setNumber:8 height:10 spacing:6];
    [[rate0 xAxis] setRngLimitsLow:0 withHigh:5000000 withMinRng:5];
    
    [[totalRate xAxis] setRngLimitsLow:0 withHigh:24*1000000 withMinRng:5];
	int i;
	for(i=0;i<kNumTristanFLTChannels;i++){
        [[thresholdMatrix cellWithTag:i] setTag:i ];
	}
	[self updateWindow];
}

#pragma mark ***Accessors

#pragma mark ***Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORTristanFLTSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORIpeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdChanged:)
						 name : ORTristanFLTModelThresholdsChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(enabledChanged:)
						 name : ORTristanFLTModelEnabledChanged
					   object : model];
			
    [notifyCenter addObserver : self
                     selector : @selector(gapLengthChanged:)
                         name : ORTristanFLTModelGapLengthChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(shapingLengthChanged:)
                         name : ORTristanFLTModelShapingLengthChanged
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
					 selector : @selector(totalRateChanged:)
						 name : ORRateAverageChangedNotification
					   object : [model totalRate]];
	
    [notifyCenter addObserver : self
                     selector : @selector(postTriggerTimeChanged:)
                         name : ORTristanFLTModelPostTriggerTimeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(udpFrameSizeChanged:)
                         name :     ORTristanFLTModelUdpFrameSizeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(hostNameChanged:)
                         name : ORTristanFLTModelHostNameChanged
                       object : model ] ;
    
    [notifyCenter addObserver : self
                     selector : @selector(portChanged:)
                         name : ORTristanFLTModelPortChanged
                       object : model ] ;

    [notifyCenter addObserver : self
                     selector : @selector(udpConnectedChanged:)
                         name : ORTristanFLTModelUdpConnectedChanged
                       object : model ] ;

}

#pragma mark ***Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self thresholdChanged:nil];
    [self enabledChanged:nil];
    [self totalRateChanged:nil];
    [self scaleAction:nil];
    [self miscAttributesChanged:nil];
    [self postTriggerTimeChanged:nil];
    [self settingsLockChanged:nil];
    [self gapLengthChanged:nil];
    [self shapingLengthChanged:nil];
    [self udpFrameSizeChanged:nil];
    [self hostNameChanged:nil];
    [self portChanged:nil];
    [self udpConnectedChanged:nil];
}

- (void) udpConnectedChanged:(NSNotification*)aNote
{
    if([model udpConnected]){
        [udpConnectedField setStringValue:@"Connected"];
        [connectButton setTitle:@"Disconnect"];
    }
    else {
        [udpConnectedField setStringValue:@"Not Connected"];
        [connectButton setTitle:@"Connect"];
    }
}

- (void) hostNameChanged:(NSNotification*)aNote
{
    [hostNameField setStringValue:[model hostName]];
}

- (void) portChanged:(NSNotification*)aNote
{
    [portField setIntegerValue:[(ORTristanFLTModel*)model  port]];
}

- (void) shapingLengthChanged:(NSNotification*)aNote
{
	[shapingLengthField setIntValue:[model shapingLength]];
}

- (void) gapLengthChanged:(NSNotification*)aNote
{
	[gapLengthField setIntValue: [model gapLength]];
}

- (void) enabledChanged:(NSNotification*)aNotification
{
    int i;
    for(i=0;i<kNumTristanFLTChannels;i++){
        [[enabledMatrix cellWithTag:i] setState: [model enabled:i]];
    }
}

- (void) thresholdChanged:(NSNotification*)aNotification
{
    int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
    [[thresholdMatrix cellWithTag:chan] setIntegerValue: [model threshold:chan]];
}

- (void) postTriggerTimeChanged:(NSNotification*)aNotification
{
    [postTriggerTimeField setIntValue: [model postTriggerTime]];
}

- (void) udpFrameSizeChanged:(NSNotification*)aNotification
{
    [udpFrameSizeField setIntValue: [model udpFrameSize]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    // for FLTv4 'slot' goes from 0-9, 11-20 (SLTv4 has slot 10)
    [[self window] setTitle:[NSString stringWithFormat:@"TristanFLT Card (Slot %d, TristanFLT# %d)",[model slot]+1,(uint32_t)[model stationNumber]]];
    [slotNumField setStringValue: [NSString stringWithFormat:@"# %d",(uint32_t)[model stationNumber]]];
}

- (void) totalRateChanged:(NSNotification*)aNote
{
    if(aNote==nil || [aNote object] == [model totalRate]){
        [timeRatePlot setNeedsDisplay:YES];
    }
}



- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORTristanFLTSettingsLock to:secure];
    [settingLockButton setEnabled:secure];	
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORTristanFLTSettingsLock];
    BOOL locked           = [gSecurity isLocked:ORTristanFLTSettingsLock];

	[gapLengthField              setEnabled: !lockedOrRunningMaintenance];
	[shapingLengthField          setEnabled: !lockedOrRunningMaintenance];
    [settingLockButton           setState: locked];
	[initBoardButton             setEnabled: !lockedOrRunningMaintenance];
    [thresholdMatrix             setEnabled: !lockedOrRunningMaintenance];
    [enabledMatrix               setEnabled: !lockedOrRunningMaintenance];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [rate0 xAxis]){
		[model setMiscAttributes:[[rate0 xAxis]attributes] forKey:@"RateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [totalRate xAxis]){
		[model setMiscAttributes:[[totalRate xAxis]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot xAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot xAxis]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot yAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot yAxis]attributes] forKey:@"TimeRateYAttributes"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"RateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"RateXAttributes"];
		if(attrib){
			[[rate0 xAxis] setAttributes:attrib];
			[rate0 setNeedsDisplay:YES];
			[[rate0 xAxis] setNeedsDisplay:YES];
			[rateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TotalRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
		if(attrib){
			[[totalRate xAxis] setAttributes:attrib];
			[totalRate setNeedsDisplay:YES];
			[[totalRate xAxis] setNeedsDisplay:YES];
			[totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot xAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot yAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot yAxis] setNeedsDisplay:YES];
			[timeRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
}


- (void) tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:settingSize];		break;
		default: [self resizeWindowToSize:rateSize];	    break;
    }
    [[self window] setContentView:totalView];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORTristanFLT%d.selectedtab",(int)[model stationNumber]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

#pragma mark ***Actions
- (IBAction) shapingLengthAction:(id)sender
{
    [self endEditing];
	[model setShapingLength:[sender intValue]];
}

- (IBAction) gapLengthAction:(id)sender
{
    [self endEditing];
	[model setGapLength:[sender intValue]];
}

- (IBAction) postTriggerTimeAction:(id)sender
{
    [self endEditing];
    [model setPostTriggerTime:[sender intValue]];
}


- (IBAction) setDefaultsAction: (id) sender
{
    [model setToDefaults];
}

- (IBAction) writeThresholds:(id)sender
{
	[self endEditing];
    [model loadThresholds];
}

- (IBAction) thresholdAction:(id)sender
{
    [self endEditing];
    [model setThreshold:[[sender selectedCell] tag] withValue: [sender intValue]];
}


- (IBAction) enableAction:(id)sender
{
	[model setEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) initBoardAction:(id)sender
{
	[self endEditing];
    [model initBoard];
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORTristanFLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) resetAction: (id) sender
{
    [model reset];
}

- (IBAction) loadThresholdsAction: (id) sender
{
    [self endEditing];
    [model loadThresholds];
}

- (IBAction) udpFrameSizeAction:(id)sender
{
    [self endEditing];
    [model setUdpFrameSize:[sender intValue]];
}

- (IBAction) hostNameAction:(id)sender
{
    [model setHostName:[sender stringValue]];
}

- (IBAction) portAction:(id)sender
{
    [(ORTristanFLTModel*)model setPort:[sender intValue]];
}
- (IBAction) connectAction:(id)sender
{
   [model startClient];
}

#pragma mark ***Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter
{
	return (int)[[model  totalRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	NSUInteger count = [[model totalRate]count];
	NSUInteger index = count-i-1;
	*yValue =  [[model totalRate] valueAtIndex:index];
	*xValue =  [[model totalRate] timeSampledAtIndex:index];
}




@end



