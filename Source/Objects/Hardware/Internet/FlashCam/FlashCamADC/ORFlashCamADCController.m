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
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam ADC (0x%x, Crate %d, Slot %d)", [model cardAddress], [model crateNumber], [model slot]]];
    [shapingLabel setStringValue:@"Shaping Time (ns)"];
    [flatTopLabel setStringValue:@"Flat Top (ns)"];
    for(unsigned int i=0; i<[model numberOfChannels]; i++){
        id cell = [filterTypeMatrix cellWithTag:i];
        [[cell itemAtIndex:0] setTitle:@"Gauss"];
        [[cell itemAtIndex:1] setTitle:@"Trap"];
        [[cell itemAtIndex:2] setTitle:@"Cusp"];
    }
    [filterTypeMatrix setEnabled:YES];
    NSArray* m = [NSArray arrayWithObjects:baselineMatrix, thresholdMatrix, adcGainMatrix, trigGainMatrix,
                  shapeTimeMatrix, flatTopTimeMatrix, poleZeroTimeMatrix, postTriggerMatrix, baselineSlewMatrix,
                  swTrigIncludeMatrix, rateTextFields,
                  trigRateTextFields, nil];
    for(NSMatrix* matrix in m){
        for(NSUInteger i=0; i<[matrix numberOfRows]; i++)
            [[matrix cellAtRow:i column:0] setFormatter:[[[NSNumberFormatter alloc] init] autorelease]];
    }
    m = [NSArray arrayWithObjects:rateTextFields, trigRateTextFields, nil];
    for(NSMatrix* matrix in m){
        for(NSUInteger i=0; i<[matrix numberOfRows]; i++){
            NSNumberFormatter* nf = [[matrix cellAtRow:i column:0] formatter];
            nf.usesSignificantDigits = YES;
            nf.minimumSignificantDigits = 3;
            nf.maximumSignificantDigits = 6;
        }
    }
    m = [NSArray arrayWithObjects:totalRateTextField, totalTrigRateTextField, nil];
    for(NSTextField* tf in m){
        NSNumberFormatter* nf = [[[NSNumberFormatter alloc] init] autorelease];
        nf.usesSignificantDigits = YES;
        nf.minimumSignificantDigits = 3;
        nf.maximumSignificantDigits = 6;
        [tf setFormatter:nf];
    }
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(chanEnabledChanged:)
                         name : ORFlashCamADCModelChanEnabledChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(trigOutEnabledChanged:)
                         name : ORFlashCamADCModelTrigOutEnabledChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(baselineChanged:)
                         name : ORFlashCamADCModelBaselineChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(baseBiasChanged:)
                         name : ORFlashCamADCModelBaseBiasChanged
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
                     selector : @selector(flatTopTimeChanged:)
                         name : ORFlashCamADCModelFlatTopTimeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(poleZeroTimeChanged:)
                         name : ORFlashCamADCModelPoleZeroTimeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(postTriggerChanged:)
                         name : ORFlashCamADCModelPostTriggerChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(baselineSlewChanged:)
                         name : ORFlashCamADCModelBaselineSlewChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(swTrigIncludeChanged:)
                         name : ORFlashCamADCModelSWTrigIncludeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(majorityLevelChanged:)
                         name : ORFlashCamADCModelMajorityLevelChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(majorityWidthChanged:)
                         name : ORFlashCamADCModelMajorityWidthChanged
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
                     selector : @selector(updateTimePlot:)
                         name : ORRateAverageChangedNotification
                       object : [[model trigRates] timeRate]];
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
    [notifyCenter addObserver : self
                     selector : @selector(enableBaselineHistoryChanged:)
                         name : ORFlashCamADCModelEnableBaselineHistoryChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(baselineSampleTimeChanged:)
                         name : ORFlashCamADCModelBaselineSampleTimeChanged
                       object : nil];
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
    e = [[[model trigRates] rates] objectEnumerator];
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
    [plot setLineColor:[NSColor systemGreenColor]];
    [plot setName:@"Trig"];
    [timeRateView addPlot:plot];
    [plot release];
    plot = [[ORTimeLinePlot alloc] initWithTag:1 andDataSource:self];
    [plot setLineColor:[NSColor systemBlueColor]];
    [plot setName:@"Total"];
    [timeRateView addPlot:plot];
    [plot release];
    [(ORTimeAxis*) [timeRateView xAxis] setStartTime:[[NSDate date] timeIntervalSince1970]];
    
    [rateView setNumber:[model numberOfChannels] height:10 spacing:5];
    
    ORCompositeTimeLineView* baseViews[4] = {baselineView0, baselineView1, baselineView2, baselineView3};
    NSColor* colors[6] = {[NSColor blueColor], [NSColor redColor], [NSColor greenColor],
                          [NSColor blackColor], [NSColor brownColor], [NSColor purpleColor]};
    for(int i=0; i<4; i++){
        if(i*6 >= [model numberOfChannels]) continue;
        [baseViews[i] setPlotTitle:@"Baseline (ADC)"];
        [[baseViews[i] xAxis] setRngLow:0 withHigh:10000];
        [[baseViews[i] xAxis] setRngLimitsLow:0 withHigh:200000 withMinRng:200];
        [[baseViews[i] yAxis] setRngLow:-1 withHigh:1+(1<<16)];
        [[baseViews[i] yAxis] setRngLimitsLow:-1 withHigh:1+(1<<16) withMinRng:10];
        for(int j=0; j<6; j++){
            int k = i*6 + j;
            ORTimeLinePlot* plot = [[ORTimeLinePlot alloc] initWithTag:k andDataSource:self];
            [baseViews[i] addPlot:plot];
            [plot setLineColor:colors[j]];
            [plot setName:[NSString stringWithFormat:@"Ch %d", k]];
            [plot release];
        }
        [(ORTimeAxis*)[baseViews[i] xAxis] setStartTime:[[NSDate date] timeIntervalSince1970]];
        [baseViews[i] setShowLegend:YES];
    }
    
    [super awakeFromNib];
}

- (void) updateWindow
{
    [super updateWindow];
    [self cardAddressChanged:nil];
    [self cardSlotChanged:nil];
    [self chanEnabledChanged:nil];
    [self trigOutEnabledChanged:nil];
    [self baselineChanged:nil];
    [self baseBiasChanged:nil];
    [self thresholdChanged:nil];
    [self adcGainChanged:nil];
    [self trigGainChanged:nil];
    [self shapeTimeChanged:nil];
    [self filterTypeChanged:nil];
    [self flatTopTimeChanged:nil];
    [self poleZeroTimeChanged:nil];
    [self postTriggerChanged:nil];
    [self baselineSlewChanged:nil];
    [self swTrigIncludeChanged:nil];
    [self majorityLevelChanged:nil];
    [self majorityWidthChanged:nil];
    [self rateGroupChanged:nil];
    [self updateTimePlot:nil];
    [self waveformRateChanged:nil];
    [self totalRateChanged:nil];
    [self rateIntegrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self enableBaselineHistoryChanged:nil];
    [self baselineSampleTimeChanged:nil];
}

#pragma mark •••Interface Management

- (void) cardAddressChanged:(NSNotification*)note
{
    [super cardAddressChanged:note];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam ADC (0x%x, Crate %d, Slot %d)", [model cardAddress], [model crateNumber], [model slot]]];
}

- (void) cardSlotChanged:(NSNotification*)note
{
    [super cardSlotChanged:note];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam ADC (0x%x, Crate %d, Slot %d)", [model cardAddress], [model crateNumber], [model slot]]];
}

- (void) chanEnabledChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<[model numberOfChannels]; i++){
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

- (void) trigOutEnabledChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<[model numberOfChannels]; i++)
            [[trigOutEnabledMatrix cellWithTag:i] setState:[model trigOutEnabled:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[trigOutEnabledMatrix cellWithTag:chan] setState:[model trigOutEnabled:chan]];
    }
    [trigOutEnableButton setIntValue:[model trigOutEnable]];
    if([model trigOutEnable]) [trigOutEnabledMatrix setEnabled:YES];
    else [trigOutEnabledMatrix setEnabled:NO];
}

- (void) baselineChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<[model numberOfChannels]; i++)
            [[baselineMatrix cellWithTag:i] setIntValue:[model baseline:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[baselineMatrix cellWithTag:chan] setIntValue:[model baseline:chan]];
    }
}

- (void) thresholdChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<[model numberOfChannels]; i++)
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
        for(int i=0; i<[model numberOfChannels]; i++)
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
        for(int i=0; i<[model numberOfChannels]; i++)
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
        for(int i=0; i<[model numberOfChannels]; i++)
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
        for(int i=0; i<[model numberOfChannels]; i++){
            [[filterTypeMatrix cellWithTag:i] setIntValue:[model filterType:i]];
            if([model filterType:i] == 0) [[flatTopTimeMatrix cellWithTag:i] setEnabled:NO];
            else [[flatTopTimeMatrix cellWithTag:i] setEnabled:YES];
        }
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[filterTypeMatrix cellWithTag:chan] setIntValue:[model filterType:chan]];
        if([model filterType:chan] == 0) [[flatTopTimeMatrix cellWithTag:chan] setEnabled:NO];
        else [[flatTopTimeMatrix cellWithTag:chan] setEnabled:YES];
    }
}

- (void) flatTopTimeChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<[model numberOfChannels]; i++)
            [[flatTopTimeMatrix cellWithTag:i] setFloatValue:[model flatTopTime:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[flatTopTimeMatrix cellWithTag:chan] setFloatValue:[model flatTopTime:chan]];
    }
}

- (void) poleZeroTimeChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<[model numberOfChannels]; i++)
            [[poleZeroTimeMatrix cellWithTag:i] setFloatValue:[model poleZeroTime:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[poleZeroTimeMatrix cellWithTag:chan] setFloatValue:[model poleZeroTime:chan]];
    }
}

- (void) postTriggerChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<[model numberOfChannels]; i++)
            [[postTriggerMatrix cellWithTag:i] setFloatValue:[model postTrigger:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[postTriggerMatrix cellWithTag:chan] setFloatValue:[model postTrigger:chan]];
    }
}

- (void) baselineSlewChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<[model numberOfChannels]; i++)
            [[baselineSlewMatrix cellWithTag:i] setIntValue:[model baselineSlew:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[baselineSlewMatrix cellWithTag:chan] setIntValue:[model baselineSlew:chan]];
    }
}

- (void) swTrigIncludeChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<[model numberOfChannels]; i++)
            [[swTrigIncludeMatrix cellWithTag:i] setIntValue:[model swTrigInclude:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[swTrigIncludeMatrix cellWithTag:chan] setIntValue:[model swTrigInclude:chan]];
    }
}

- (void) baseBiasChanged:(NSNotification*)note
{
    [baseBiasTextField setIntValue:[model baseBias]];
}

- (void) majorityLevelChanged:(NSNotification*)note
{
    [majorityLevelPUButton selectItemAtIndex:[model majorityLevel]-1];
}

- (void) majorityWidthChanged:(NSNotification*)note
{
    [majorityWidthTextField setIntValue:[model majorityWidth]];
}

- (void) waveformRateChanged:(NSNotification*)note
{
    ORRate* rateObj = [note object];
    for(NSUInteger i=0; i<[[[model wfRates] rates] count]; i++){
        ORRate* rate = [[[model wfRates] rates] objectAtIndex:i];
        if(rateObj != rate) continue;
        [[rateTextFields cellWithTag:[rateObj tag]] setFloatValue:[rateObj rate]];
        [rateView setNeedsDisplay:YES];
        return;
    }
    for(NSUInteger i=0; i<[[[model trigRates] rates] count]; i++){
        ORRate* rate = [[[model trigRates] rates] objectAtIndex:i];
        if(rateObj != rate) continue;
        [[trigRateTextFields cellWithTag:[rateObj tag]] setFloatValue:[rateObj rate]];
        [rateView setNeedsDisplay:YES];
    }
}

- (void) totalRateChanged:(NSNotification*)note
{
    ORRateGroup* rateObj = [note object];
    if(note == nil || [model wfRates] == rateObj){
        [totalRateTextField setFloatValue:[rateObj totalRate]];
        [totalRateView setNeedsDisplay:YES];
    }
    if(note == nil || [model trigRates] == rateObj){
        [totalTrigRateTextField setFloatValue:[rateObj totalRate]];
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
    if(note == nil || [note object] == model ||
       [model wfRates] == rateObj || [model trigRates] == rateObj){
        double value = [[model wfRates] integrationTime];
        [integrationStepper setDoubleValue:value];
        [integrationTextField setDoubleValue:value];
    }
}

- (void) updateTimePlot:(NSNotification*)note
{
    if([note object] == [[model wfRates] timeRate]   ||
       [note object] == [[model trigRates] timeRate] || note == nil) [timeRateView setNeedsDisplay:YES];
    [super updateTimePlot:note];
}

- (void) deferredPlotUpdate
{
    [super deferredPlotUpdate];
    [baselineView0 setNeedsDisplay:YES];
    if([model numberOfChannels] > kFlashCamADCChannels){
        [baselineView1 setNeedsDisplay:YES];
        [baselineView2 setNeedsDisplay:YES];
        [baselineView3 setNeedsDisplay:YES];
    }
}

- (void) scaleAction:(NSNotification*)note
{
    if(note == nil || [note object] == [rateView xAxis])
        [model setMiscAttributes:[[rateView xAxis] attributes] forKey:@"RateXAttributes"];
    if(note == nil || [note object] == [totalRateView xAxis])
        [model setMiscAttributes:[[totalRateView xAxis] attributes] forKey:@"TotalRateXAttributes"];
    if(note == nil || [note object] == [timeRateView xAxis])
        [model setMiscAttributes:[(ORAxis*)[timeRateView xAxis] attributes] forKey:@"TimeRateXAttributes"];
    if(note == nil || [note object] == [timeRateView yAxis])
        [model setMiscAttributes:[(ORAxis*)[timeRateView yAxis] attributes] forKey:@"TimeRateYAttributes"];
    if(note == nil || [note object] == [baselineView0 xAxis])
        [model setMiscAttributes:[(ORAxis*)[baselineView0 xAxis] attributes] forKey:@"BaseView0XAttributes"];
    if(note == nil || [note object] == [baselineView0 yAxis])
        [model setMiscAttributes:[(ORAxis*)[baselineView0 yAxis] attributes] forKey:@"BaseView0YAttributes"];
    if(note == nil || [note object] == [baselineView1 xAxis])
        [model setMiscAttributes:[(ORAxis*)[baselineView1 xAxis] attributes] forKey:@"BaseView1XAttributes"];
    if(note == nil || [note object] == [baselineView1 yAxis])
        [model setMiscAttributes:[(ORAxis*)[baselineView1 yAxis] attributes] forKey:@"BaseView1YAttributes"];
    if(note == nil || [note object] == [baselineView2 xAxis])
        [model setMiscAttributes:[(ORAxis*)[baselineView2 xAxis] attributes] forKey:@"BaseView2XAttributes"];
    if(note == nil || [note object] == [baselineView2 yAxis])
        [model setMiscAttributes:[(ORAxis*)[baselineView2 yAxis] attributes] forKey:@"BaseView2YAttributes"];
    if(note == nil || [note object] == [baselineView3 xAxis])
        [model setMiscAttributes:[(ORAxis*)[baselineView3 xAxis] attributes] forKey:@"BaseView3XAttributes"];
    if(note == nil || [note object] == [baselineView3 yAxis])
        [model setMiscAttributes:[(ORAxis*)[baselineView3 yAxis] attributes] forKey:@"BaseView3YAttributes"];
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
    if(note == nil || [key isEqualToString:@"BaseView0XAttributes"]){
        if(note == nil) attrib = [model miscAttributesForKey:@"BaseView0XAttributes"];
        if(attrib) [self setPlot:baselineView0 xAttributes:attrib];
    }
    if(note == nil || [key isEqualToString:@"BaseView0YAttributes"]){
        if(note == nil) attrib = [model miscAttributesForKey:@"BaseView0YAttributes"];
        if(attrib) [self setPlot:baselineView0 yAttributes:attrib];
    }
    if(note == nil || [key isEqualToString:@"BaseView1XAttributes"]){
        if(note == nil) attrib = [model miscAttributesForKey:@"BaseView1XAttributes"];
        if(attrib) [self setPlot:baselineView1 xAttributes:attrib];
    }
    if(note == nil || [key isEqualToString:@"BaseView1YAttributes"]){
        if(note == nil) attrib = [model miscAttributesForKey:@"BaseView1YAttributes"];
        if(attrib) [self setPlot:baselineView1 yAttributes:attrib];
    }
    if(note == nil || [key isEqualToString:@"BaseView2XAttributes"]){
        if(note == nil) attrib = [model miscAttributesForKey:@"BaseView2XAttributes"];
        if(attrib) [self setPlot:baselineView2 xAttributes:attrib];
    }
    if(note == nil || [key isEqualToString:@"BaseView3YAttributes"]){
        if(note == nil) attrib = [model miscAttributesForKey:@"BaseView3YAttributes"];
        if(attrib) [self setPlot:baselineView3 yAttributes:attrib];
    }
}

- (void) enableBaselineHistoryChanged:(NSNotification*)note
{
    [enableBaselineHistoryButton setIntValue:(int)[model enableBaselineHistory]];
}

- (void) baselineSampleTimeChanged:(NSNotification*)note
{
    [baselineSampleTimeTextField setDoubleValue:[model baselineSampleTime]];
}

- (void) settingsLock:(bool)lock
{
    lock |= [gOrcaGlobals runInProgress] || [gSecurity isLocked:ORFlashCamCardSettingsLock];
    [super settingsLock:lock];
    [chanEnabledMatrix      setEnabled:!lock];
    [trigOutEnabledMatrix   setEnabled:!lock];
    [baselineMatrix         setEnabled:!lock];
    [thresholdMatrix        setEnabled:!lock];
    [adcGainMatrix          setEnabled:!lock];
    [trigGainMatrix         setEnabled:!lock];
    [shapeTimeMatrix        setEnabled:!lock];
    [filterTypeMatrix       setEnabled:!lock];
    [flatTopTimeMatrix      setEnabled:!lock];
    [poleZeroTimeMatrix     setEnabled:!lock];
    [postTriggerMatrix      setEnabled:!lock];
    [baselineSlewMatrix     setEnabled:!lock];
    [swTrigIncludeMatrix    setEnabled:!lock];
    [baseBiasTextField      setEnabled:!lock];
    [majorityLevelPUButton  setEnabled:!lock];
    [majorityWidthTextField setEnabled:!lock];
    [trigOutEnableButton    setEnabled:!lock];
}


#pragma mark •••Actions

- (IBAction) chanEnabledAction:(id)sender
{
    if((bool) [sender intValue] != [model chanEnabled:(unsigned int)[[sender selectedCell] tag]])
        [model setChanEnabled:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) trigOutEnabledAction:(id)sender
{
    if((bool) [sender intValue] != [model trigOutEnabled:(unsigned int)[[sender selectedCell] tag]])
        [model setTrigOutEnabled:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) baselineAction:(id)sender
{
    if([sender intValue] != [model baseline:(unsigned int)[[sender selectedCell] tag]])
        [model setBaseline:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
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
    if([sender intValue] != [model shapeTime:(unsigned int)[[sender selectedCell] tag]])
        [model setShapeTime:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) filterTypeAction:(id)sender
{
    if([sender intValue] != [model filterType:(unsigned int)[[sender selectedCell] tag]])
        [model setFilterType:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) flatTopTimeAction:(id)sender
{
    if([sender floatValue] != [model flatTopTime:(unsigned int)[[sender selectedCell] tag]])
        [model setFlatTopTime:(unsigned int)[[sender selectedCell] tag] withValue:[sender floatValue]];
}

- (IBAction) poleZeroTimeAction:(id)sender
{
    if([sender floatValue] != [model poleZeroTime:(unsigned int)[[sender selectedCell] tag]])
        [model setPoleZeroTime:(unsigned int)[[sender selectedCell] tag] withValue:[sender floatValue]];
}

- (IBAction) postTriggerAction:(id)sender
{
    if([sender floatValue] != [model postTrigger:(unsigned int)[[sender selectedCell] tag]])
        [model setPostTrigger:(unsigned int)[[sender selectedCell] tag] withValue:[sender floatValue]];
}

- (IBAction) baselineSlewAction:(id)sender
{
    if([sender intValue] != [model baselineSlew:(unsigned int)[[sender selectedCell] tag]])
        [model setBaselineSlew:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) swTrigIncludeAction:(id)sender
{
    if([sender intValue] != [model swTrigInclude:(unsigned int)[[sender selectedCell] tag]])
        [model setSWTrigInclude:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) baseBiasAction:(id)sender
{
    [model setBaseBias:[sender intValue]];
}

- (IBAction) majorityLevelAction:(id)sender
{
    [model setMajorityLevel:(int)[sender indexOfSelectedItem]+1];
}

- (IBAction) majorityWidthAction:(id)sender
{
    [model setMajorityWidth:[sender intValue]];
}

- (IBAction) trigOutEnableAction:(id)sender
{
    [model setTrigOutEnable:(bool)[sender intValue]];
}

- (IBAction) printFlagsAction:(id)sender
{
    [super printFlagsAction:sender];
    [model printRunFlagsForChannelOffset:0];
}

- (IBAction) rateIntegrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model wfRates] integrationTime])
        [model setRateIntTime:[sender doubleValue]];
}

- (IBAction) enableBaselineHistoryAction:(id)sender
{
    [model setEnableBaselineHistory:(bool)[sender intValue]];
}

- (IBAction) baselineSampleTimeAction:(id)sender
{
    [model setBaselineSampleTime:[sender doubleValue]];
}


#pragma mark •••Data Source

- (double) getBarValue:(int)tag
{
    return [[[[model trigRates] rates] objectAtIndex:tag] rate];
}

- (double) getSecondaryBarValue:(int)tag
{
    return [[[[model wfRates] rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter
{
    unsigned int tag = (unsigned int) [aPlotter tag];
    if([aPlotter plotView] == [timeRateView plotView]) return (int) [[[model wfRates] timeRate] count];
    else if([aPlotter plotView] == [baselineView0 plotView]) return (int) [[model baselineHistory:tag] count];
    else if([aPlotter plotView] == [baselineView1 plotView]) return (int) [[model baselineHistory:tag] count];
    else if([aPlotter plotView] == [baselineView2 plotView]) return (int) [[model baselineHistory:tag] count];
    else if([aPlotter plotView] == [baselineView3 plotView]) return (int) [[model baselineHistory:tag] count];
    else return [super numberPointsInPlot:aPlotter];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
    unsigned int tag = (unsigned int) [aPlotter tag];
    if([aPlotter plotView] == [timeRateView plotView]){
        if(tag == 0){
            int count = (int) [[[model trigRates] timeRate] count];
            int index = count-i-1;
            *yValue = [[[model trigRates] timeRate] valueAtIndex:index];
            *xValue = [[[model trigRates] timeRate] timeSampledAtIndex:index];
        }
        else if(tag == 1){
            int count = (int) [[[model wfRates] timeRate] count];
            int index = count-i-1;
            *yValue = [[[model wfRates] timeRate] valueAtIndex:index];
            *xValue = [[[model wfRates] timeRate] timeSampledAtIndex:index];
        }
    }
    else if([aPlotter plotView] == [baselineView0 plotView] || [aPlotter plotView] == [baselineView0 plotView] ||
            [aPlotter plotView] == [baselineView2 plotView] || [aPlotter plotView] == [baselineView3 plotView]){
        int index = (int) [[model baselineHistory:tag] count] - i - 1;
        if(index >= 0){
            *xValue = [[model baselineHistory:tag] timeSampledAtIndex:index];
            *yValue = [[model baselineHistory:tag] valueAtIndex:index];
        }
    }
    else [super plotter:aPlotter index:i x:xValue y:yValue];
}

@end


@implementation ORFlashCamADCStdController

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamADCStd"];
    return self;
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [shapingLabel setStringValue:@"Fast Shape (ns)"];
    [flatTopLabel setStringValue:@"Slow Shape (ns)"];
    for(unsigned int i=0; i<[model numberOfChannels]; i++){
        id cell = [filterTypeMatrix cellWithTag:i];
        for(unsigned int j=0; j<3; j++) [[cell itemAtIndex:j] setTitle:@"N/A"];
    }
    [filterTypeMatrix setEnabled:NO];
}

@end
