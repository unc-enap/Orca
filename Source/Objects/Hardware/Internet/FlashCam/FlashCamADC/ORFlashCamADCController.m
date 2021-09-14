//  Orca
//  ORFlashCamADCController.h
//
//  Created by Tom Caldwell on Monday Dec 17,2019
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
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

#import "ORFlashCamADCController.h"
#import "ORFlashCamADCModel.h"
#import "ORFlashCamReadoutModel.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORTimeRate.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"

@implementation ORFlashCamADCController

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamADC"];
    [promSlotPUButton removeAllItems];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"FlasCam ADC (0x%x Slot %d)", [model cardAddress], [model slot]]];
    [promSlotPUButton removeAllItems];
    for(int i=0; i<3; i++) [promSlotPUButton addItemWithTitle:[NSString stringWithFormat:@"Slot %d", i]];
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
                     selector : @selector(chanEnabledChanged:)
                         name : ORFlashCamADCModelChanEnabledChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(baselineChanged:)
                         name : ORFlashCamADCModelBaselineChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(baseCalibChanged:)
                         name : ORFlashCamADCModelBaseCalibChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORFlashCamADCModelThresholdChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(adcGainChanged:)
                         name : ORFlashCamADCModelADCGainChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(trigGainChanged:)
                         name : ORFlashCamADCModelTrigGainChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(shapeTimeChanged:)
                         name : ORFlashCamADCModelShapeTimeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(filterTypeChanged:)
                         name : ORFlashCamADCModelFilterTypeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(poleZeroTimeChanged:)
                         name : ORFlashCamADCModelPoleZeroTimeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORFlashCamADCModelRateGroupChanged
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(totalRateChanged:)
                         name : ORRateGroupTotalRateChangedNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(updateTimePlot:)
                         name : ORRateAverageChangedNotification
                       object : [[model wfRates] timeRate]];
    [notifyCenter addObserver : self
                     selector : @selector(rateIntegrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(miscAttributesChanged:)
                         name : ORMiscAttributesChanged
                       object : model];
    [self registerRates];
}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
    NSEnumerator* e = [[[model wfRates] rates] objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [notifyCenter removeObserver:self name:ORRateChangedNotification object:obj];
        [notifyCenter addObserver : self
                         selector : @selector(waveformRateChanged:)
                             name : ORRateChangedNotification
                           object : obj];
    }
}

- (void) awakeFromNib
{
    ORTimeLinePlot* plot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
    [timeRateView addPlot:plot];
    [(ORTimeAxis*) [timeRateView xAxis] setStartTime:[[NSDate date] timeIntervalSince1970]];
    [plot release];
    
    [rateView setNumber:6 height:10 spacing:5];
    
    [super awakeFromNib];
}

- (void) updateWindow
{
    [super updateWindow];
    [self cardAddressChanged:nil];
    [self promSlotChanged:nil];
    [self firmwareVerChanged:nil];
    [self chanEnabledChanged:nil];
    [self cardSlotChanged:nil];
    [self baselineChanged:nil];
    [self baseCalibChanged:nil];
    [self thresholdChanged:nil];
    [self adcGainChanged:nil];
    [self trigGainChanged:nil];
    [self shapeTimeChanged:nil];
    [self filterTypeChanged:nil];
    [self poleZeroTimeChanged:nil];
    [self rateGroupChanged:nil];
    [self updateTimePlot:nil];
    [self waveformRateChanged:nil];
    [self totalRateChanged:nil];
    [self rateIntegrationChanged:nil];
    [self miscAttributesChanged:nil];
}

#pragma mark •••Interface Management

- (void) cardAddressChanged:(NSNotification*)note
{
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam ADC (0x%x, Slot %d)", [model cardAddress], [model slot]]];
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
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam ADC (0x%x, Slot %d)", [model cardAddress], [model slot]]];
}

- (void) chanEnabledChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamADCChannels; i++){
            [[chanEnabledMatrix cellWithTag:i] setState:[model chanEnabled:i]];
            [[chanEnabledRateMatrix cellWithTag:i] setState:[model chanEnabled:i]];
        }
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[chanEnabledMatrix cellWithTag:chan] setState:[model chanEnabled:chan]];
        [[chanEnabledRateMatrix cellWithTag:chan] setState:[model chanEnabled:chan]];
    }
}

- (void) baselineChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
            [[baselineMatrix cellWithTag:i] setIntValue:[model baseline:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[baselineMatrix cellWithTag:chan] setIntValue:[model baseline:chan]];
    }
}

- (void) baseCalibChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
            [[baseCalibMatrix cellWithTag:i] setIntValue:[model baseCalib:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[baseCalibMatrix cellWithTag:chan] setIntValue:[model baseCalib:chan]];
    }
}

- (void) thresholdChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
            [[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[thresholdMatrix cellWithTag:chan] setIntValue:[model threshold:chan]];
    }
}

- (void) adcGainChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
            [[adcGainMatrix cellWithTag:i] setIntValue:[model adcGain:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[adcGainMatrix cellWithTag:chan] setIntValue:[model adcGain:chan]];
    }
}

- (void) trigGainChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
            [[trigGainMatrix cellWithTag:i] setFloatValue:[model trigGain:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[trigGainMatrix cellWithTag:chan] setFloatValue:[model trigGain:chan]];
    }
}

- (void) shapeTimeChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
            [[shapeTimeMatrix cellWithTag:i] setIntValue:[model shapeTime:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[shapeTimeMatrix cellWithTag:chan] setIntValue:[model shapeTime:chan]];
    }
}

- (void) filterTypeChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
            [[filterTypeMatrix cellWithTag:i] setFloatValue:[model filterType:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[filterTypeMatrix cellWithTag:chan] setFloatValue:[model filterType:chan]];
    }
}

- (void) poleZeroTimeChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
            [[poleZeroTimeMatrix cellWithTag:i] setFloatValue:[model poleZeroTime:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[poleZeroTimeMatrix cellWithTag:chan] setFloatValue:[model poleZeroTime:chan]];
    }
}

- (void) waveformRateChanged:(NSNotification*)note
{
    ORRate* rateObj = [note object];
    [[rateTextFields cellWithTag:[rateObj tag]] setFloatValue:[rateObj rate]];
    [rateView setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)note
{
    ORRateGroup* rateObj = [note object];
    if(note == nil || [model wfRates] == rateObj){
        [totalRateTextField setFloatValue:[rateObj totalRate]];
        [totalRateView setNeedsDisplay:YES];
    }
}

- (void) rateGroupChanged:(NSNotification*)note
{
    [self registerRates];
}

- (void) rateIntegrationChanged:(NSNotification*)note
{
    ORRateGroup* rateObj = [note object];
    if(note == nil || [model wfRates] == rateObj || [note object] == model){
        double value = [[model wfRates] integrationTime];
        [integrationStepper setDoubleValue:value];
        [integrationTextField setDoubleValue:value];
    }
}

- (void) updateTimePlot:(NSNotification*)note
{
    if(!note || [note object] == [[model wfRates] timeRate]) [timeRateView setNeedsDisplay:YES];
}

- (void) scaleAction:(NSNotification*)note
{
    if(note == nil || [note object] == [rateView xAxis])
        [model setMiscAttributes:[[rateView xAxis] attributes] forKey:@"RateXAttributes"];
    if(note == nil || [note object] == [totalRateView xAxis])
        [model setMiscAttributes:[[totalRateView xAxis] attributes] forKey:@"TotalRateXAttributes"];
    if(note == nil || [note object] == [timeRateView xAxis])
        [model setMiscAttributes:[(ORAxis*)[timeRateView xAxis]attributes] forKey:@"TimeRateXAttributes"];
    if(note == nil || [note object] == [timeRateView yAxis])
        [model setMiscAttributes:[(ORAxis*)[timeRateView yAxis]attributes] forKey:@"TimeRateYAttributes"];
}

- (void) miscAttributesChanged:(NSNotification*)note
{
    NSString* key = [[note userInfo] objectForKey:ORMiscAttributeKey];
    NSMutableDictionary* attrib = [model miscAttributesForKey:key];
    if(note == nil || [key isEqualToString:@"RateXAttributes"]){
        if(note == nil) attrib = [model miscAttributesForKey:@"RateXAttributes"];
        if(attrib){
            [[rateView xAxis] setAttributes:attrib];
            [rateView setNeedsDisplay:YES];
            [[rateView xAxis] setNeedsDisplay:YES];
            [rateLogButton setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
        }
    }
    if(note == nil || [key isEqualToString:@"TotalRateXAttributes"]){
        if(note == nil) attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
        if(attrib){
            [[totalRateView xAxis] setAttributes:attrib];
            [totalRateView setNeedsDisplay:YES];
            [[totalRateView xAxis] setNeedsDisplay:YES];
            [totalRateLogButton setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
        }
    }
    if(note == nil || [key isEqualToString:@"TimeRateXAttributes"]){
        if(note == nil) attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
        if(attrib){
            [(ORAxis*)[timeRateView xAxis] setAttributes:attrib];
            [timeRateView setNeedsDisplay:YES];
            [[timeRateView xAxis] setNeedsDisplay:YES];
        }
    }
    if(note == nil || [key isEqualToString:@"TimeRateYAttributes"]){
        if(note == nil) attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
        if(attrib){
            [(ORAxis*)[timeRateView yAxis] setAttributes:attrib];
            [timeRateView setNeedsDisplay:YES];
            [[timeRateView yAxis] setNeedsDisplay:YES];
            [timeRateLogButton setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
        }
    }
}

- (void) settingsLock:(bool)lock
{
    [cardAddressTextField setEnabled:!lock];
    [promSlotPUButton     setEnabled:!lock];
    [rebootCardButton     setEnabled:!lock];
    [getFirmwareVerButton setEnabled:!lock];
    [chanEnabledMatrix    setEnabled:!lock];
    [baselineMatrix       setEnabled:!lock];
    [baseCalibMatrix      setEnabled:!lock];
    [thresholdMatrix      setEnabled:!lock];
    [adcGainMatrix        setEnabled:!lock];
    [trigGainMatrix       setEnabled:!lock];
    [shapeTimeMatrix      setEnabled:!lock];
    [filterTypeMatrix     setEnabled:!lock];
    [poleZeroTimeMatrix   setEnabled:!lock];
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

- (IBAction) chanEnabledAction:(id)sender
{
    if([sender intValue] != [model chanEnabled:(unsigned int)[[sender selectedCell] tag]])
        [model setChanEnabled:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) baselineAction:(id)sender
{
    if([sender intValue] != [model baseline:(unsigned int)[[sender selectedCell] tag]])
        [model setBaseline:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) baseCalibAction:(id)sender
{
    if([sender floatValue] != [model baseCalib:(unsigned int)[[sender selectedCell] tag]])
        [model setBaseCalib:(unsigned int)[[sender selectedCell] tag] withValue:[sender floatValue]];
}

- (IBAction) thresholdAction:(id)sender
{
    if([sender intValue] != [model threshold:(unsigned int)[[sender selectedCell] tag]])
        [model setThreshold:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) adcGainAction:(id)sender
{
    if([sender intValue] != [model adcGain:(unsigned int)[[sender selectedCell] tag]])
        [model setADCGain:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) trigGainAction:(id)sender
{
    if([sender floatValue] != [model trigGain:(unsigned int)[[sender selectedCell] tag]])
        [model setTrigGain:(unsigned int)[[sender selectedCell] tag] withValue:[sender floatValue]];
}

- (IBAction) shapeTimeAction:(id)sender
{
    if([sender intValue] != [model shapeTime:(int)[[sender selectedCell] tag]])
        [model setShapeTime:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) filterTypeAction:(id)sender
{
    if([sender floatValue] != [model filterType:(unsigned int)[[sender selectedCell] tag]])
        [model setFilterType:(unsigned int)[[sender selectedCell] tag] withValue:[sender floatValue]];
}

- (IBAction) poleZeroTimeAction:(id)sender
{
    if([sender floatValue] != [model poleZeroTime:(unsigned int)[[sender selectedCell] tag]])
        [model setPoleZeroTime:(unsigned int)[[sender selectedCell] tag] withValue:[sender floatValue]];
}

- (IBAction) printFlagsAction:(id)sender
{
    [model printRunFlagsForChannelOffset:0];
}

- (IBAction) rateIntegrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model wfRates] integrationTime])
        [model setRateIntTime:[sender doubleValue]];
}

#pragma mark •••Data Source
- (double) getBarValue:(int)tag
{
    return [[[[model wfRates] rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter
{
    return (int) [[[model wfRates]timeRate] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
    int count = (int)[[[model wfRates] timeRate] count];
    int index = count-i-1;
    *yValue = [[[model wfRates] timeRate] valueAtIndex:index];
    *xValue = [[[model wfRates] timeRate] timeSampledAtIndex:index];
}

@end
