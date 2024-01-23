//  Orca
//  ORFlashCamCardController.m
//
//  Created by Tom Caldwell on Wednesday, Sep 15,2021
//  Copyright (c) 2021 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORFlashCamCardController.h"
#import "ORFlashCamCard.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"

@implementation ORFlashCamCardController

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamADC"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(cardAddressChanged:)
                         name : ORFlashCamCardAddressChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(promSlotChanged:)
                         name : ORFlashCamCardPROMSlotChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(firmwareVerRequest:)
                         name : ORFlashCamCardFirmwareVerRequest
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(firmwareVerChanged:)
                         name : ORFlashCamCardFirmwareVerChanged
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(cardSlotChanged:)
                         name : ORFlashCamCardSlotChangedNotification
                       object : self];
    [notifyCenter addObserver : self
                     selector : @selector(statusChanged:)
                         name : ORFlashCamCardStatusChanged
                       object : model];
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
                     selector : @selector(settingsLock:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(settingsLock:)
                         name : ORFlashCamCardSettingsLock
                        object: nil];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    NSColor* colors[kFlashCamCardNTemps] = { [NSColor blueColor],
        [NSColor redColor],   [NSColor greenColor],  [NSColor blackColor],
        [NSColor brownColor], [NSColor purpleColor], [NSColor orangeColor] };
    
    [tempView setPlotTitle:@"Temperature (C)"];
    [[tempView xAxis] setRngLow:0.0 withHigh:10000.0];
    [[tempView xAxis] setRngLimitsLow:0.0 withHigh:200000.0 withMinRng:200.0];
    [[tempView yAxis] setRngLow:20.0 withHigh:80.0];
    [[tempView yAxis] setRngLimitsLow:0.0 withHigh:250.0 withMinRng:1.0];
    for(int i=0; i<kFlashCamCardNTemps; i++){
        ORTimeLinePlot* plot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
        [tempView addPlot:plot];
        [plot setLineColor:colors[i]];
        [plot setName:[NSString stringWithFormat:@"Temp %d", i]];
        [plot release];
    }
    [(ORTimeAxis*) [tempView xAxis] setStartTime:[[NSDate date] timeIntervalSince1970]];
    [tempView setShowLegend:YES];
    
    [voltageView setPlotTitle:@"Voltage (V)"];
    [[voltageView xAxis] setRngLow:0.0 withHigh:10000.0];
    [[voltageView xAxis] setRngLimitsLow:0.0 withHigh:200000.0 withMinRng:200.0];
    [[voltageView yAxis] setRngLow:0.0 withHigh:30.0];
    [[voltageView yAxis] setRngLimitsLow:0.0 withHigh:100.0 withMinRng:0.1];
    for(int i=0; i<kFlashCamCardNVoltages; i++){
        ORTimeLinePlot* plot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
        [voltageView addPlot:plot];
        [plot setLineColor:colors[i]];
        [plot setName:[NSString stringWithFormat:@"Voltage %d", i]];
        [plot release];
    }
    [(ORTimeAxis*) [voltageView xAxis] setStartTime:[[NSDate date] timeIntervalSince1970]];
    [voltageView setShowLegend:YES];
    
    [currentView setPlotTitle:@"Mains Current (A)"];
    [[currentView xAxis] setRngLow:0.0 withHigh:10000.0];
    [[currentView xAxis] setRngLimitsLow:0.0 withHigh:200000.0 withMinRng:200.0];
    [[currentView yAxis] setRngLow:0.1 withHigh:1.0];
    [[currentView yAxis] setRngLimitsLow:0.0 withHigh:5.0 withMinRng:0.01];
    ORTimeLinePlot* cplot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
    [currentView addPlot:cplot];
    [cplot setLineColor:colors[0]];
    [(ORTimeAxis*) [currentView xAxis] setStartTime:[[NSDate date] timeIntervalSince1970]];
    [cplot release];
    
    [humidityView setPlotTitle:@"Humidity"];
    [[humidityView xAxis] setRngLow:0.0 withHigh:10000.0];
    [[humidityView xAxis] setRngLimitsLow:0.0 withHigh:200000.0 withMinRng:200.0];
    [[humidityView yAxis] setRngLow:50.0 withHigh:150.0];
    [[humidityView yAxis] setRngLimitsLow:0.0 withHigh:1000.0 withMinRng:1.0];
    ORTimeLinePlot* hplot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
    [humidityView addPlot:hplot];
    [hplot setLineColor:colors[0]];
    [(ORTimeAxis*) [humidityView xAxis] setStartTime:[[NSDate date] timeIntervalSince1970]];
    [hplot release];
    
    [self populatePromSlotPopup];
}


- (void) populatePromSlotPopup
{
    [promSlotPUButton removeAllItems];
    for(int i=0; i<3; i++) [promSlotPUButton addItemWithTitle:[NSString stringWithFormat:@"Slot %d", i]];
}


- (void) updateWindow
{
    [super updateWindow];
    [self cardAddressChanged:nil];
    [self promSlotChanged:nil];
    [self firmwareVerChanged:nil];
    [self statusChanged:nil];
    [self updateTimePlot:nil];
    [self settingsLock:nil];
}


#pragma mark •••Interface Management

- (void) cardAddressChanged:(NSNotification*)note
{
    [cardAddressTextField setIntValue:[model cardAddress]];
    [model taskFinished:nil];
}

- (void) promSlotChanged:(NSNotification*)note
{
    [promSlotPUButton selectItemAtIndex:[model promSlot]];
}

- (void) firmwareVerRequest:(NSNotification*)note
{
    [getFirmwareVerButton setEnabled:NO];
}

- (void) firmwareVerChanged:(NSNotification*)note
{
    if([model firmwareVer])
        [firmwareVerTextField setStringValue:[[model firmwareVer] componentsJoinedByString:@" / "]];
    else [firmwareVerTextField setStringValue:@""];
    [getFirmwareVerButton setEnabled:YES];
}

- (void) cardSlotChanged:(NSNotification*)note
{
}

- (void) statusChanged:(NSNotification*)note
{
    if(note) if([note object] != model) return;
    [fcioIDTextField      setIntValue:(int) [model fcioID]];
    [statusEventTextField setIntValue:(int) [model statusEvent]];
    [statusPPSTextField   setIntValue:(int) [model statusPPS]];
    [statusTicksTextField setIntValue:(int) [model statusTicks]];
    [totalErrorsTextField setIntValue:(int) [model totalErrors]];
    [envErrorsTextField   setIntValue:(int) [model envErrors]];
    [ctiErrorsTextField   setIntValue:(int) [model ctiErrors]];
    [linkErrorsTextField  setIntValue:(int) [model linkErrors]];
}

- (void) scaleAction:(NSNotification*)note
{
    if(note == nil || [note object] == [tempView xAxis])
        [model setMiscAttributes:[(ORAxis*) [tempView xAxis]     attributes] forKey:@"XAttrib0"];
    if(note == nil || [note object] == [tempView yAxis])
        [model setMiscAttributes:[(ORAxis*) [tempView yAxis]     attributes] forKey:@"YAttrib0"];
    if(note == nil || [note object] == [voltageView xAxis])
        [model setMiscAttributes:[(ORAxis*) [voltageView xAxis]  attributes] forKey:@"XAttrib1"];
    if(note == nil || [note object] == [voltageView yAxis])
        [model setMiscAttributes:[(ORAxis*) [voltageView yAxis]  attributes] forKey:@"YAttrib1"];
    if(note == nil || [note object] == [currentView xAxis])
        [model setMiscAttributes:[(ORAxis*) [currentView xAxis]  attributes] forKey:@"XAttrib2"];
    if(note == nil || [note object] == [currentView yAxis])
        [model setMiscAttributes:[(ORAxis*) [currentView yAxis]  attributes] forKey:@"YAttrib2"];
    if(note == nil || [note object] == [humidityView xAxis])
        [model setMiscAttributes:[(ORAxis*) [humidityView xAxis] attributes] forKey:@"XAttrib3"];
    if(note == nil || [note object] == [humidityView yAxis])
        [model setMiscAttributes:[(ORAxis*) [humidityView yAxis] attributes] forKey:@"YAttrib3"];
}

- (void) miscAttributesChanged:(NSNotification*)note
{
    NSString* key = [[note userInfo] objectForKey:ORMiscAttributeKey];
    NSMutableDictionary* attrib = [model miscAttributesForKey:key];
    if(note == nil || [key isEqualToString:@"XAttrib0"]) [self setPlot:tempView     xAttributes:attrib];
    if(note == nil || [key isEqualToString:@"YAttrib0"]) [self setPlot:tempView     yAttributes:attrib];
    if(note == nil || [key isEqualToString:@"XAttrib1"]) [self setPlot:voltageView  xAttributes:attrib];
    if(note == nil || [key isEqualToString:@"YAttrib1"]) [self setPlot:voltageView  yAttributes:attrib];
    if(note == nil || [key isEqualToString:@"XAttrib2"]) [self setPlot:currentView  xAttributes:attrib];
    if(note == nil || [key isEqualToString:@"YAttrib2"]) [self setPlot:currentView  yAttributes:attrib];
    if(note == nil || [key isEqualToString:@"XAttrib3"]) [self setPlot:humidityView xAttributes:attrib];
    if(note == nil || [key isEqualToString:@"YAttrib3"]) [self setPlot:humidityView yAttributes:attrib];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORFlashCamCardSettingsLock to:secure];
    [settingsLockButton setEnabled:secure];
}

- (void) settingsLock:(bool)lock
{
    BOOL locked = [gSecurity isLocked:ORFlashCamCardSettingsLock];
    [settingsLockButton   setState:locked];
    lock |= locked || [gOrcaGlobals runInProgress];
    [cardAddressTextField setEnabled:!lock];
    [promSlotPUButton     setEnabled:!lock];
    [rebootCardButton     setEnabled:!lock];
    [getFirmwareVerButton setEnabled:!lock];
}

- (void) setPlot:(id)plotter xAttributes:(id)attrib
{
    if(attrib){
        [(ORAxis*)[plotter xAxis] setAttributes:attrib];
        [plotter setNeedsDisplay:YES];
        [[plotter yAxis] setNeedsDisplay:YES];
    }
}
- (void) setPlot:(id)plotter yAttributes:(id)attrib
{
    if(attrib){
        [(ORAxis*)[plotter yAxis] setAttributes:attrib];
        [plotter setNeedsDisplay:YES];
        [[plotter yAxis] setNeedsDisplay:YES];
    }
}

- (void) updateTimePlot:(NSNotification*)aNote
{
    if(!scheduledToUpdatePlot){
        scheduledToUpdatePlot=YES;
        [self performSelector:@selector(deferredPlotUpdate) withObject:nil afterDelay:2];
    }
}

- (void) deferredPlotUpdate
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(deferredPlotUpdate) object:nil];
    scheduledToUpdatePlot = NO;
    [tempView     setNeedsDisplay:YES];
    [voltageView  setNeedsDisplay:YES];
    [currentView  setNeedsDisplay:YES];
    [humidityView setNeedsDisplay:YES];
}

#pragma mark •••Actions

- (IBAction) cardAddressAction:(id)sender
{
    [model setCardAddress:[sender intValue]];
}

- (IBAction) promSlotAction:(id)sender
{
    [model setPROMSlot:(unsigned int)[sender indexOfSelectedItem]];
}

- (IBAction) rebootCardAction:(id)sender
{
    [model requestReboot];
}

- (IBAction) firmwareVerAction:(id)sender
{
    [model requestFirmwareVersion];
}

- (IBAction) printFlagsAction:(id)sender
{
}

- (IBAction) settingsLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORFlashCamCardSettingsLock to:[sender intValue] forWindow:[self window]];
}


#pragma mark •••Data Source

- (int) numberPointsInPlot:(id)aPlotter
{
    unsigned int tag = (unsigned int) [aPlotter tag];
    if([aPlotter plotView]      == [tempView     plotView]) return (int) [[model     tempHistory:tag] count];
    else if([aPlotter plotView] == [voltageView  plotView]) return (int) [[model  voltageHistory:tag] count];
    else if([aPlotter plotView] == [currentView  plotView]) return (int) [[model  currentHistory]     count];
    else if([aPlotter plotView] == [humidityView plotView]) return (int) [[model humidityHistory]     count];
    return 0;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    unsigned int tag = (unsigned int) [aPlotter tag];
    if([aPlotter plotView] == [tempView plotView]){
        int index = (int) [[model tempHistory:tag] count] - i - 1;
        if(index >= 0){
            *xValue = [[model tempHistory:tag] timeSampledAtIndex:index];
            *yValue = [[model tempHistory:tag] valueAtIndex:index] / 1000.0;
        }
    }
    else if([aPlotter plotView] == [voltageView plotView]){
        int index = (int) [[model voltageHistory:tag] count] - i - 1;
        if(index >= 0){
            *xValue = [[model voltageHistory:tag] timeSampledAtIndex:index];
            *yValue = [[model voltageHistory:tag] valueAtIndex:index] / 1000.0;
        }
    }
    else if([aPlotter plotView] == [currentView plotView]){
        int index = (int) [[model currentHistory] count] - i - 1;
        if(index >= 0){
            *xValue = [[model currentHistory] timeSampledAtIndex:index];
            *yValue = [[model currentHistory] valueAtIndex:index] / 1000.0;
        }
    }
    else if([aPlotter plotView] == [humidityView plotView]){
        int index = (int) [[model humidityHistory] count] - i - 1;
        if(index >= 0){
            *xValue = [[model humidityHistory] timeSampledAtIndex:index];
            *yValue = [[model humidityHistory] valueAtIndex:index];
        }
    }
}

@end
