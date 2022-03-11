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
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(fwTypeChanged:)
                         name : ORFlashCamADCModelFWTypeChanged
                       object : nil];
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
    [self fwTypeChanged:nil];
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
    [self majorityLevelChanged:nil];
    [self majorityWidthChanged:nil];
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
    [super cardAddressChanged:note];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam ADC (0x%x, Crate %d, Slot %d)", [model cardAddress], [model crateNumber], [model slot]]];
}

- (void) cardSlotChanged:(NSNotification*)note
{
    [super cardSlotChanged:note];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam ADC (0x%x, Crate %d, Slot %d)", [model cardAddress], [model crateNumber], [model slot]]];
}

- (void) fwTypeChanged:(NSNotification*)note
{
    [fwTypePUButton selectItemAtIndex:[model fwType]];
    if([model fwType] == 0){
        [shapingLabel setStringValue:@"Fast Shape (ns)"];
        [flatTopLabel setStringValue:@"Slow Shape (ns)"];
        for(unsigned int i=0; i<kMaxFlashCamADCChannels; i++){
            id cell = [filterTypeMatrix cellWithTag:i];
            for(unsigned int j=0; j<3; j++) [[cell itemAtIndex:j] setTitle:@"N/A"];
        }
        [filterTypeMatrix setEnabled:NO];
    }
    else if([model fwType] == 1){
        [shapingLabel setStringValue:@"Shaping Time (ns)"];
        [flatTopLabel setStringValue:@"Flat Top (ns)"];
        for(unsigned int i=0; i<kMaxFlashCamADCChannels; i++){
            id cell = [filterTypeMatrix cellWithTag:i];
            [[cell itemAtIndex:0] setTitle:@"Gauss"];
            [[cell itemAtIndex:1] setTitle:@"Trap"];
            [[cell itemAtIndex:2] setTitle:@"Cusp"];
        }
        [filterTypeMatrix setEnabled:YES];
    }
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

- (void) trigOutEnabledChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
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
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
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
        for(int i=0; i<kMaxFlashCamADCChannels; i++){
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
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
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
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
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
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
        [[postTriggerMatrix cellWithTag:i] setFloatValue:[model postTrigger:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[postTriggerMatrix cellWithTag:chan] setFloatValue:[model postTrigger:chan]];
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
    [majorityWidthTextField setIntValue:[model majorityLevel]];
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
    lock |= [gOrcaGlobals runInProgress] || [gSecurity isLocked:ORFlashCamCardSettingsLock];
    [super settingsLock:lock];
    [fwTypePUButton         setEnabled:!lock];
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
    [baseBiasTextField      setEnabled:!lock];
    [majorityLevelPUButton  setEnabled:!lock];
    [majorityWidthTextField setEnabled:!lock];
    [trigOutEnableButton    setEnabled:!lock];
}


#pragma mark •••Actions

- (IBAction) fwTypeAction:(id)sender
{
    if((unsigned int)[sender indexOfSelectedItem] != [model fwType])
        [model setFWtype:(unsigned int)[sender indexOfSelectedItem]];
}

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


#pragma mark •••Data Source

- (double) getBarValue:(int)tag
{
    return [[[[model wfRates] rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter
{
    if([aPlotter plotView] == [timeRateView plotView]) return (int) [[[model wfRates] timeRate] count];
    else return [super numberPointsInPlot:aPlotter];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
    if([aPlotter plotView] == [timeRateView plotView]){
        int count = (int)[[[model wfRates] timeRate] count];
        int index = count-i-1;
        *yValue = [[[model wfRates] timeRate] valueAtIndex:index];
        *xValue = [[[model wfRates] timeRate] timeSampledAtIndex:index];
    }
    else [super plotter:aPlotter index:i x:xValue y:yValue];
}

@end
