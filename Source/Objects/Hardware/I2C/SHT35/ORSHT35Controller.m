//
//  ORHPSHT35Controller.m
//  Orca
//
//  Created by Mark Howe on 08/1/2024.
//  Copyright 2024 University of North Carolina. All rights reserved.
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

#import "ORSHT35Controller.h"
#import "ORSHT35Model.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"

@implementation ORSHT35Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"SHT35" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];

    [notifyCenter addObserver : self
                     selector : @selector(i2cAddressChanged:)
                         name : ORSHT35ModelI2CAddressChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(updateIntervalChanged:)
                         name : ORSHT35ModelUpdateIntervalChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(temperatureChanged:)
                         name : ORSHT35ModelTemperatureChanged
                        object: nil];
 
    [notifyCenter addObserver : self
                     selector : @selector(humidityChanged:)
                         name : ORSHT35ModelHumidityChanged
                        object: nil];

	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORSHT35ModelRunningChanged
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORSHT35ModelLock
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORSHT35ModelRunningChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(updatePlots:)
                         name : ORRateAverageChangedNotification
                       object : nil];
}
- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [self setWindowTitle];
}

- (void) setWindowTitle
{
    [[self window] setTitle:[model title]];
}

- (void) awakeFromNib
{
    [[temperaturePlot yAxis] setRngLow:0.0 withHigh:300.];
    [[temperaturePlot yAxis] setRngLimitsLow:-300.0 withHigh:500 withMinRng:4];

    [[temperaturePlot xAxis] setRngLow:0.0 withHigh:10000];
    [[temperaturePlot xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];

    [[humidityPlot yAxis] setRngLow:0.0 withHigh:100];
    [[humidityPlot yAxis] setRngLimitsLow:0.0 withHigh:100 withMinRng:4];

    [[humidityPlot xAxis] setRngLow:0.0 withHigh:10000];
    [[humidityPlot xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];

    
    ORTimeLinePlot* aPlot;
    aPlot= [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
    [temperaturePlot addPlot: aPlot];
    [(ORTimeAxis*)[temperaturePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
    [aPlot release];

    aPlot= [[ORTimeLinePlot alloc] initWithTag:1 andDataSource:self];
    [humidityPlot addPlot: aPlot];
    [(ORTimeAxis*)[humidityPlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
    [aPlot release];

    
    [super awakeFromNib];
}

- (void) updateWindow
{
    [ super updateWindow ];
    [self i2cAddressChanged:nil];
    [self temperatureChanged:nil];
    [self humidityChanged:nil];
    [self updateIntervalChanged:nil];
    [self runningChanged:nil];
    [self updatePlots:nil];
    [self setWindowTitle];
    [self lockChanged:nil];
}
- (void) updatePlots:(NSNotification*)aNote
{
    if(!aNote || ([aNote object] == [model temperatureRate])){
        [temperaturePlot setNeedsDisplay:YES];
    }
    else if(!aNote || ([aNote object] == [model humidityRate])){
        [humidityPlot setNeedsDisplay:YES];
    }
}
- (void) scaleAction:(NSNotification*)aNote
{
    if(aNote == nil || [aNote object] == [temperaturePlot xAxis]){
        [model setMiscAttributes:[(ORAxis*)[temperaturePlot xAxis]attributes] forKey:@"XAttributes0"];
    }
    
    if(aNote == nil || [aNote object] == [temperaturePlot yAxis]){
        [model setMiscAttributes:[(ORAxis*)[temperaturePlot yAxis]attributes] forKey:@"YAttributes0"];
    }
    if(aNote == nil || [aNote object] == [humidityPlot xAxis]){
        [model setMiscAttributes:[(ORAxis*)[humidityPlot xAxis]attributes] forKey:@"XAttributes1"];
    }
    
    if(aNote == nil || [aNote object] == [humidityPlot yAxis]){
        [model setMiscAttributes:[(ORAxis*)[humidityPlot yAxis]attributes] forKey:@"YAttributes1"];
    }
}
- (void) miscAttributesChanged:(NSNotification*)aNote
{

    NSString*                key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
    NSMutableDictionary* attrib = [model miscAttributesForKey:key];
    
    if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
        if(attrib){
            [(ORAxis*)[temperaturePlot xAxis] setAttributes:attrib];
            [temperaturePlot setNeedsDisplay:YES];
            [[temperaturePlot xAxis] setNeedsDisplay:YES];
        }
    }
    if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
        if(attrib){
            [(ORAxis*)[temperaturePlot yAxis] setAttributes:attrib];
            [temperaturePlot setNeedsDisplay:YES];
            [[temperaturePlot yAxis] setNeedsDisplay:YES];
        }
    }
    
    if(aNote == nil || [key isEqualToString:@"XAttributes1"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes1"];
        if(attrib){
            [(ORAxis*)[humidityPlot xAxis] setAttributes:attrib];
            [humidityPlot setNeedsDisplay:YES];
            [[humidityPlot xAxis] setNeedsDisplay:YES];
        }
    }
    if(aNote == nil || [key isEqualToString:@"YAttributes1"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes1"];
        if(attrib){
            [(ORAxis*)[humidityPlot yAxis] setAttributes:attrib];
            [humidityPlot setNeedsDisplay:YES];
            [[humidityPlot yAxis] setNeedsDisplay:YES];
        }
    }
}

- (void) updateTemperaturePlot:(NSNotification*)aNote
{
    if(!aNote || ([aNote object] == [model temperatureRate])){
        [temperaturePlot setNeedsDisplay:YES];
    }
}

- (void) updateHumidityPlot:(NSNotification*)aNote
{
    if(!aNote || ([aNote object] == [model humidityRate])){
        [humidityPlot setNeedsDisplay:YES];
    }
}
- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSHT35ModelLock to:secure];
    [lockButton setEnabled:secure];
}

#pragma mark •••Notifications
- (void) lockChanged:(NSNotification*)aNote
{
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSHT35ModelLock];
    BOOL locked = [gSecurity isLocked:ORSHT35ModelLock];
    [lockButton setState: locked];
    [startStopButton setState: locked];
	[i2cAddressField setEnabled:!lockedOrRunningMaintenance];
}

- (void) runningChanged:(NSNotification*)aNote
{
    if([model running])[startStopButton setTitle:@"Stop"];
    else               [startStopButton setTitle:@"Start"];
}

- (void) i2cAddressChanged:(NSNotification*)aNote
{
    [i2cAddressField setIntValue:[model i2cAddress]];
    [self setWindowTitle];
}

- (void) temperatureChanged:(NSNotification*)aNote
{
    [temperatureField setIntValue:[model temperature]];
}

- (void) humidityChanged:(NSNotification*)aNote
{
    [humidityField setIntValue:[model humidity]];
}

- (void) updateIntervalChanged:(NSNotification*)aNote
{
    [updateIntervalPU selectItemWithTag:[model updateInterval]];
}
#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
    if([aPlotter tag]==0)      return (int)[[model temperatureRate] count];
    else if([aPlotter tag]==1) return (int)[[model humidityRate] count];
    else return 0;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    if([aPlotter tag]==0){
        int count = (int)[[model temperatureRate] count];
        int index = count-i-1;
        *xValue = [[model temperatureRate] timeSampledAtIndex:index];
        *yValue = [[model temperatureRate] valueAtIndex:index];
    }
    else if([aPlotter tag]==1){
        int count = (int)[[model humidityRate] count];
        int index = count-i-1;
        *xValue = [[model humidityRate] timeSampledAtIndex:index];
        *yValue = [[model humidityRate] valueAtIndex:index];
    }
}

#pragma mark •••Actions

- (IBAction) lockAction:(id)sender;
{
    [gSecurity tryToSetLock:ORSHT35ModelLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) addressAction:(id)sender
{
    [model setI2CAddress:[sender intValue ]];
}

- (IBAction) startStopAction:(id)sender
{
    [model startStopPolling];
}

- (IBAction) pollNowAction:(id)sender
{
    [model pollNow];
}

- (IBAction) updateIntervalPUAction:(id)sender
{
    //---------------------------
    //tags are the millisecond delays
    //0 -> fastest possible -- no delay
    //100 -> 10Hz
    //1000 -> 1Hz
    //10000 -> .1Hz
    //store as tag.. use as delay in the polling...
    //---------------------------
    [model setUpdateInterval:(int)[sender selectedTag]];
}

@end
