
//
//  MJDPreAmpController.m
//  Orca
//
//  Created by Mark Howe on Wed Jan 18 2012.
//  Copyright � 2012 University of North Carolina. All rights reserved.
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

#pragma mark ⅴ쩒mported Files
#import "ORMJDPreAmpController.h"
#import "ORMJDPreAmpModel.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"
#import "ORVmeCard.h"

@implementation ORMJDPreAmpController

- (id) init
{
    self = [super initWithWindowNibName:@"MJDPreAmp"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (NSString*) adcName:(int)adcIndex
{
    if(adcIndex>=0 && adcIndex<kMJDPreAmpAdcChannels){
        NSString* tagString[kMJDPreAmpAdcChannels] = {
            @"Baseline0",
            @"Baseline1",
            @"Baseline2",
            @"Baseline3",
            @"Baseline4",
            @"+12V",
            @"-12V",
            @"Temp 1",           
            @"Baseline8",
            @"Baseline9",
            @"Baseline10",
            @"Baseline11",
            @"Baseline12",
            @"+24V",
            @"-24V",
            @"Temp 2"
        };
        return tagString[adcIndex];
    }
    else return @"?";
}

- (void) awakeFromNib
{
    [super  awakeFromNib];
	short chan;
	NSNumberFormatter* aFormat = [[[NSNumberFormatter alloc] init] autorelease];
	[aFormat setFormat:@"##0.00"];

	for(chan=0;chan<kMJDPreAmpDacChannels;chan++){
		[[dacsMatrix cellAtRow:chan column:0] setTag:chan];
		[[dacsMatrix cellAtRow:chan column:0] setFormatter:aFormat];
		[[amplitudesMatrix cellAtRow:chan column:0] setTag:chan];
		[[pulserMaskMatrix cellAtRow:chan column:0] setTag:chan];
        
		[[baselineVoltageMatrix cellAtRow:chan column:0] setTag:chan];
		[[baselineVoltageMatrix cellAtRow:chan column:0] setFormatter:aFormat];
    }
    for(chan=0;chan<kMJDPreAmpAdcChannels;chan++){
		[[adcMatrix cellAtRow:chan column:0] setTag:chan];
		[[adcMatrix cellAtRow:chan column:0] setFormatter:aFormat];
        [[detectorNameMatrix cellAtRow:chan column:0] setTag:chan];

        
		[[adcEnabledMaskMatrix cellAtRow:chan column:0] setTag:chan];
        
		[[feedBackResistorMatrix cellAtRow:chan column:0] setFormatter:aFormat];
 		[[feedBackResistorMatrix cellAtRow:chan column:0] setTag:chan];
	}
    
    [[baselinePlot0 xAxis] setRngLow:0.0 withHigh:10000];
    [[baselinePlot0 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[baselinePlot0 yAxis] setRngLow:-15.0 withHigh:15.];
    [[baselinePlot0 yAxis] setRngLimitsLow:-15. withHigh:10. withMinRng:4]; // rail of preamp at -12V - niko
    
    [[baselinePlot1 xAxis] setRngLow:0.0 withHigh:10000];
    [[baselinePlot1 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[baselinePlot1 yAxis] setRngLow:-15. withHigh:15.];
    [[baselinePlot1 yAxis] setRngLimitsLow:-15. withHigh:15. withMinRng:4]; // rail of preamp at -12V - niko
    
    [[temperaturePlot xAxis] setRngLow:0.0 withHigh:10000];
    [[temperaturePlot xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[temperaturePlot yAxis] setRngLow:0.0 withHigh:300.];
    [[temperaturePlot yAxis] setRngLimitsLow:0.0 withHigh:60 withMinRng:4]; // up to 60 degrees on chip - niko
    
    [[voltagePlot xAxis] setRngLow:0.0 withHigh:10000];
    [[voltagePlot xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[voltagePlot yAxis] setRngLow:-30. withHigh:30.];
    [[voltagePlot yAxis] setRngLimitsLow:-30. withHigh:30. withMinRng:4]; // up to +/-24V - niko
    
    [[leakageCurrentPlot0 xAxis] setRngLow:0.0 withHigh:10000];
    [[leakageCurrentPlot0 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[leakageCurrentPlot0 yAxis] setRngLow:0.0 withHigh:300.];
    [[leakageCurrentPlot0 yAxis] setRngLimitsLow:-50 withHigh:150 withMinRng:4]; // up to 150 pA leakage current - niko
    
    [[leakageCurrentPlot1 xAxis] setRngLow:0.0 withHigh:10000];
    [[leakageCurrentPlot1 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[leakageCurrentPlot1 yAxis] setRngLow:0.0 withHigh:300.];
    [[leakageCurrentPlot1 yAxis] setRngLimitsLow:-50 withHigh:150 withMinRng:4]; // up to 150 pA leakage current - niko
    
	NSColor* color[5] = {
		[NSColor redColor],
		[NSColor greenColor],
		[NSColor blueColor],
		[NSColor brownColor],
		[NSColor blackColor],
	};
    
    //baselines
	int i;
	for(i=0;i<5;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[baselinePlot0 addPlot: aPlot];
		[aPlot setLineColor:color[i]];
		[aPlot setName:[self adcName:i]];
		[(ORTimeAxis*)[baselinePlot0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
    //baselines
	for(i=8;i<13;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[baselinePlot1 addPlot: aPlot];
		[aPlot setLineColor:color[i-8]];
		[aPlot setName:[self adcName:i]];
		[(ORTimeAxis*)[baselinePlot1 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
    //temps
	for(i=0;i<2;i++){
        int tag[2] = {7,15};
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:tag[i] andDataSource:self];
		[temperaturePlot addPlot: aPlot];
		[aPlot setLineColor:color[i]];
		[aPlot setName:[self adcName:tag[i]]];
		[(ORTimeAxis*)[temperaturePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
    //hw voltages
	for(i=0;i<4;i++){
        int tag[4] = {5,6,13,14};
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:tag[i] andDataSource:self];
		[voltagePlot addPlot: aPlot];
		[aPlot setLineColor:color[i]];
		[aPlot setName:[self adcName:tag[i]]];
		[(ORTimeAxis*)[voltagePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
    
    
    //leakage currents
    for(i=0;i<5;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[leakageCurrentPlot0 addPlot: aPlot];
		[aPlot setLineColor:color[i]];
		[aPlot setName:[NSString stringWithFormat:@"Leakage %d",i]];
		[(ORTimeAxis*)[leakageCurrentPlot0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
    //leakage currents
    for(i=5;i<10;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[leakageCurrentPlot1 addPlot: aPlot];
		[aPlot setLineColor:color[i-5]];
		[aPlot setName:[NSString stringWithFormat:@"Leakage %d",i+3]];
		[(ORTimeAxis*)[leakageCurrentPlot1 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
    
    [baselinePlot0       setPlotTitle:@"Baselines, ADC0-4"];
    [baselinePlot1       setPlotTitle:@"Baselines, ADC8-12"];
    [temperaturePlot     setPlotTitle:@"On-chip Temperatures"];
    [voltagePlot         setPlotTitle:@"Operating Voltages"];
    [leakageCurrentPlot0 setPlotTitle:@"Leakage Currents, ADC0-4"];
    [leakageCurrentPlot1 setPlotTitle:@"Leakage Currents, ADC8-12"];

    [baselinePlot0       setShowLegend:YES];
	[baselinePlot1       setShowLegend:YES];
	[temperaturePlot     setShowLegend:YES];
	[voltagePlot         setShowLegend:YES];
    [leakageCurrentPlot0 setShowLegend:YES];
	[leakageCurrentPlot1 setShowLegend:YES];
    
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [self setWindowTitle];
    [self settingsLockChanged:nil];
}

- (void) setWindowTitle
{
    [[self window] setTitle:[NSString stringWithFormat:@"Preamp %lu (Rev %d) -> %@",[model uniqueIdNumber],[model boardRev]+1,[model connectedObjectName]]];
}

#pragma mark ⅴ쩘otifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
     
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : MJDPreAmpSettingsLock
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(dacArrayChanged:)
                         name : ORMJDPreAmpDacArrayChanged
						object: model];

    [notifyCenter addObserver : self
					 selector : @selector(dacChanged:)
						 name : ORMJDPreAmpDacChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pulseLowTimeChanged:)
                         name : ORMJDPreAmpPulseLowTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pulseHighTimeChanged:)
                         name : ORMJDPreAmpPulseHighTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pulserMaskChanged:)
                         name : ORMJDPreAmpPulserMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(attenuatedChanged:)
                         name : ORMJDPreAmpAttenuatedChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(finalAttenuatedChanged:)
                         name : ORMJDPreAmpFinalAttenuatedChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledChanged:)
                         name : ORMJDPreAmpEnabledChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(amplitudeArrayChanged:)
                         name : ORMJDPreAmpAmplitudeArrayChanged
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(amplitudeChanged:)
						 name : ORMJDPreAmpAmplitudeChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pulseCountChanged:)
                         name : ORMJDPreAmpPulseCountChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(loopForeverChanged:)
                         name : ORMJDPreAmpLoopForeverChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(adcChanged:)
                         name : ORMJDPreAmpAdcChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(feedbackResistorArrayChanged:)
                         name : ORMJDFeedBackResistorArrayChanged
						object: model];
    
	[notifyCenter addObserver : self
                     selector : @selector(feedbackResistorChanged:)
                         name : ORMJDFeedBackResistorChanged
						object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(baselineVoltageArrayChanged:)
                         name : ORMJDBaselineVoltageArrayChanged
						object: model];
    
	[notifyCenter addObserver : self
                     selector : @selector(baselineVoltageChanged:)
                         name : ORMJDBaselineVoltageChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(shipValuesChanged:)
                         name : ORMJDPreAmpModelShipValuesChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORMJDPreAmpModelPollTimeChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(adcEnabledMaskChanged:)
                         name : ORMJDPreAmpModelAdcEnabledMaskChanged
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
					 selector : @selector(detectorNameChanged:)
						 name : ORMJDPreAmpModelDetectorNameChanged
					   object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(boardRevChanged:)
                         name : ORMJDPreAmpModelBoardRevChanged
						object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(setWindowTitle)
                         name : ORMJDPreAmpModelConnectionChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(setWindowTitle)
                         name : ORVmeCardSlotChangedNotification
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(doNotUseHWMapChanged:)
                         name : ORMJDPreAmpModelDoNotUseHWMapChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(firmwareRevChanged:)
                         name : ORMJDPreAmpModelFirmwareRevChanged
                        object: model];


}


- (void) updateWindow
{
    [super updateWindow];
    [self settingsLockChanged:nil];
	[self dacArrayChanged:nil];
	[self dacChanged:nil];
	[self amplitudeArrayChanged:nil];
	[self pulseLowTimeChanged:nil];
	[self pulseHighTimeChanged:nil];
	[self pulserMaskChanged:nil];
	[self attenuatedChanged:nil];
	[self finalAttenuatedChanged:nil];
	[self enabledChanged:nil];
	[self pulseCountChanged:nil];
	[self loopForeverChanged:nil];
	[self shipValuesChanged:nil];
	[self pollTimeChanged:nil];
	[self adcEnabledMaskChanged:nil];
	[self updateTimePlot:nil];
	[self baselineVoltageChanged:nil];
	[self feedbackResistorChanged:nil];
	[self detectorNameChanged:nil];
    [self doNotUseHWMapChanged:nil];
	[self boardRevChanged:nil];
    [self adcChanged:nil];
    [self firmwareRevChanged:nil];
}

#pragma mark ⅴ쩒nterface Management

- (void) firmwareRevChanged:(NSNotification*)aNote
{
    [firmwareRevPU selectItemAtIndex: [model firmwareRev]];
}

- (void) doNotUseHWMapChanged:(NSNotification*)aNote
{
    [doNotUseHWMapPU selectItemAtIndex: [model doNotUseHWMap]];
    
    if([model doNotUseHWMap]){
        [nameSourceHelpField setStringValue:@"The detector ID is IMPORTANT! It is used to label this data in the database!"];

    }
    else {
        [nameSourceHelpField setStringValue:@"Detector IDs will be synced from the MJD HW Map. Make sure the map is up-to-date!"];
    }
    short chan;
    for(chan=0;chan<kMJDPreAmpAdcChannels;chan++){
        if(chan<=4 || chan>=8 && chan<=12){
            [[detectorNameMatrix cellWithTag:chan] setBezeled: [model doNotUseHWMap]];
            /*if([model doNotUseHWMap])*/[[detectorNameMatrix cellWithTag:chan] setDrawsBackground: [model doNotUseHWMap]];
        }
    }
    [self updateButtons];
}

- (void) boardRevChanged:(NSNotification*)aNote
{
	[boardRevPU selectItemAtIndex: [model boardRev]];
    [self setWindowTitle];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [baselinePlot0 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[baselinePlot0 xAxis]attributes] forKey:@"XAttributes0"];
	}
	if(aNotification == nil || [aNotification object] == [baselinePlot0 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[baselinePlot0 yAxis]attributes] forKey:@"YAttributes0"];
	}
    
	if(aNotification == nil || [aNotification object] == [baselinePlot1 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[baselinePlot1 xAxis]attributes] forKey:@"XAttributes1"];
	}
	if(aNotification == nil || [aNotification object] == [baselinePlot1 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[baselinePlot1 yAxis]attributes] forKey:@"YAttributes1"];
	}
    
    if(aNotification == nil || [aNotification object] == [temperaturePlot xAxis]){
		[model setMiscAttributes:[(ORAxis*)[temperaturePlot xAxis]attributes] forKey:@"XAttributes2"];
	}
	if(aNotification == nil || [aNotification object] == [temperaturePlot yAxis]){
		[model setMiscAttributes:[(ORAxis*)[temperaturePlot yAxis]attributes] forKey:@"YAttributes2"];
	}
    
    if(aNotification == nil || [aNotification object] == [voltagePlot xAxis]){
		[model setMiscAttributes:[(ORAxis*)[voltagePlot xAxis]attributes] forKey:@"XAttributes3"];
	}
	if(aNotification == nil || [aNotification object] == [voltagePlot yAxis]){
		[model setMiscAttributes:[(ORAxis*)[voltagePlot yAxis]attributes] forKey:@"YAttributes3"];
	}
    
    if(aNotification == nil || [aNotification object] == [leakageCurrentPlot0 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[leakageCurrentPlot0 xAxis]attributes] forKey:@"XAttributes4"];
	}
	if(aNotification == nil || [aNotification object] == [leakageCurrentPlot0 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[leakageCurrentPlot0 yAxis]attributes] forKey:@"YAttributes4"];
	}
    
    if(aNotification == nil || [aNotification object] == [leakageCurrentPlot1 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[leakageCurrentPlot1 xAxis]attributes] forKey:@"XAttributes5"];
	}
	if(aNotification == nil || [aNotification object] == [leakageCurrentPlot1 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[leakageCurrentPlot1 yAxis]attributes] forKey:@"YAttributes5"];
	}
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
    
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"])[self setPlot:baselinePlot0 xAttributes:attrib];
	if(aNote == nil || [key isEqualToString:@"YAttributes0"])[self setPlot:baselinePlot0 yAttributes:attrib];
    
	if(aNote == nil || [key isEqualToString:@"XAttributes1"])[self setPlot:baselinePlot1 xAttributes:attrib];
	if(aNote == nil || [key isEqualToString:@"YAttributes1"])[self setPlot:baselinePlot1 yAttributes:attrib];
    
    if(aNote == nil || [key isEqualToString:@"XAttributes2"])[self setPlot:temperaturePlot xAttributes:attrib];
	if(aNote == nil || [key isEqualToString:@"YAttributes2"])[self setPlot:temperaturePlot yAttributes:attrib];
    
    if(aNote == nil || [key isEqualToString:@"XAttributes3"])[self setPlot:voltagePlot xAttributes:attrib];
	if(aNote == nil || [key isEqualToString:@"YAttributes3"])[self setPlot:voltagePlot yAttributes:attrib];
    
    if(aNote == nil || [key isEqualToString:@"XAttributes4"])[self setPlot:leakageCurrentPlot0 xAttributes:attrib];
	if(aNote == nil || [key isEqualToString:@"YAttributes4"])[self setPlot:leakageCurrentPlot0 yAttributes:attrib];
    
    if(aNote == nil || [key isEqualToString:@"XAttributes5"])[self setPlot:leakageCurrentPlot1 xAttributes:attrib];
	if(aNote == nil || [key isEqualToString:@"YAttributes5"])[self setPlot:leakageCurrentPlot1 yAttributes:attrib];
}

- (void) setPlot:(id)aPlotter xAttributes:(id)attrib
{
    if(attrib){
        [(ORAxis*)[aPlotter xAxis] setAttributes:attrib];
        [aPlotter setNeedsDisplay:YES];
        [[aPlotter yAxis] setNeedsDisplay:YES];
    }
}
- (void) setPlot:(id)aPlotter yAttributes:(id)attrib
{
    if(attrib){
        [(ORAxis*)[aPlotter yAxis] setAttributes:attrib];
        [aPlotter setNeedsDisplay:YES];
        [[aPlotter yAxis] setNeedsDisplay:YES];
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
    [baselinePlot0 setNeedsDisplay:YES];
    [baselinePlot1 setNeedsDisplay:YES];
    [temperaturePlot setNeedsDisplay:YES];
    [voltagePlot setNeedsDisplay:YES];
    [leakageCurrentPlot0 setNeedsDisplay:YES];
    [leakageCurrentPlot1 setNeedsDisplay:YES];
}

- (void) adcEnabledMaskChanged:(NSNotification*)aNote
{

	unsigned short aMask = [model adcEnabledMask];
	int i;
	for(i=0;i<kMJDPreAmpDacChannels;i++){
		BOOL bitSet = (aMask&(1<<i))>0;
		if(bitSet != [[adcEnabledMaskMatrix cellWithTag:i] intValue]){
			[[adcEnabledMaskMatrix cellWithTag:i] setState:bitSet];
		}
	}
}

- (void) pollTimeChanged:(NSNotification*)aNotification
{
	[pollTimePU selectItemWithTag:[model pollTime]];
}

- (void) shipValuesChanged:(NSNotification*)aNote
{
	[shipValuesCB setIntValue: [model shipValues]];
}

- (void) adcChanged:(NSNotification*)aNote
{
    if(!aNote){
        int chan;
        for(chan=0;chan<kMJDPreAmpDacChannels;chan++){
            [[adcMatrix cellWithTag:chan] setFloatValue: [model adc:chan]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[adcMatrix cellWithTag:chan] setFloatValue: [model adc:chan]];
    }
}

- (void) detectorNameChanged:(NSNotification*)aNote
{
 	short chan;
	for(chan=0;chan<kMJDPreAmpAdcChannels;chan++){
        [[detectorNameMatrix cellWithTag:chan] setStringValue: [model detectorName:chan]];
	}
}

- (void) feedbackResistorArrayChanged:(NSNotification*)aNote
{
 	short chan;
	for(chan=0;chan<kMJDPreAmpAdcChannels;chan++){
        if(chan>=5 && chan<=7)[[feedBackResistorMatrix cellWithTag:chan] setStringValue:@""];
        else if(chan>=13)[[feedBackResistorMatrix cellWithTag:chan] setStringValue:@""];
		else [[feedBackResistorMatrix cellWithTag:chan] setFloatValue: [model feedBackResistor:chan]];
	}
}

- (void) feedbackResistorChanged:(NSNotification*)aNote
{
    int chan;
    if(!aNote){
        for(chan=0;chan<kMJDPreAmpAdcChannels;chan++){
            if(chan>=5 && chan<=7)[[feedBackResistorMatrix cellWithTag:chan] setStringValue:@""];
            else if(chan>=13)[[feedBackResistorMatrix cellWithTag:chan] setStringValue:@""];
            else [[feedBackResistorMatrix cellWithTag:chan] setFloatValue: [model feedBackResistor:chan]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        if(chan>=5 && chan<=7)[[feedBackResistorMatrix cellWithTag:chan] setStringValue:@""];
        else if(chan>=13)[[feedBackResistorMatrix cellWithTag:chan] setStringValue:@""];
        else [[feedBackResistorMatrix cellWithTag:chan] setFloatValue: [model feedBackResistor:chan]];
    }
}

- (void) baselineVoltageArrayChanged:(NSNotification*)aNote
{
 	short chan;
	for(chan=0;chan<kMJDPreAmpAdcChannels;chan++){
        if(chan>=5 && chan<=7)[[baselineVoltageMatrix cellWithTag:chan] setStringValue:@""];
        else if(chan>=13)[[baselineVoltageMatrix cellWithTag:chan] setStringValue:@""];
		else [[baselineVoltageMatrix cellWithTag:chan] setFloatValue: [model baselineVoltage:chan]];
	}   
}

- (void) baselineVoltageChanged:(NSNotification*)aNote
{
    int chan;
    if(!aNote){
        for(chan=0;chan<kMJDPreAmpAdcChannels;chan++){
            if(chan>=5 && chan<=7)[[baselineVoltageMatrix cellWithTag:chan] setStringValue:@""];
            else if(chan>=13)[[baselineVoltageMatrix cellWithTag:chan] setStringValue:@""];
            else [[baselineVoltageMatrix cellWithTag:chan] setFloatValue: [model baselineVoltage:chan]];
        }
    }
    else {
        chan= [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        if(chan>=5 && chan<=7)[[baselineVoltageMatrix cellWithTag:chan] setStringValue:@""];
        else if(chan>=13)[[baselineVoltageMatrix cellWithTag:chan] setStringValue:@""];
        else [[baselineVoltageMatrix cellWithTag:chan] setFloatValue: [model baselineVoltage:chan]];
   }
}

- (void) loopForeverChanged:(NSNotification*)aNote
{
	[loopForeverPU selectItemAtIndex: ![model loopForever]];
	[self updateButtons];
}

- (void) pulseCountChanged:(NSNotification*)aNote
{
	[pulseCountField setIntValue: [model pulseCount]];
}

- (void) enabledChanged:(NSNotification*)aNote
{
	[enabled0PU selectItemAtIndex: [model enabled:0]];
	[enabled1PU selectItemAtIndex: [model enabled:1]];
}

- (void) attenuatedChanged:(NSNotification*)aNote
{
	[attenuated0PU selectItemAtIndex: [model attenuated:0]];
	[attenuated1PU selectItemAtIndex: [model attenuated:1]];
}

- (void) finalAttenuatedChanged:(NSNotification*)aNote
{
	[finalAttenuated0PU selectItemAtIndex: [model finalAttenuated:0]];
	[finalAttenuated1PU selectItemAtIndex: [model finalAttenuated:1]];
}

- (void) pulserMaskChanged:(NSNotification*)aNote
{
	unsigned short aMask = [model pulserMask];
	int i;
	for(i=0;i<16;i++){
		BOOL bitSet = (aMask&(1<<i))>0;
		if(bitSet != [[pulserMaskMatrix cellWithTag:i] intValue]){
			[[pulserMaskMatrix cellWithTag:i] setState:bitSet];
		}
	}
}

- (void) pulseHighTimeChanged:(NSNotification*)aNote
{
	[pulseHighTimeField setFloatValue: ([model pulseHighTime]*2)+2]; //convert to 탎econds
    //[pulseHighTimeField setFloatValue: [model pulseHighTime]*2];
    //[pulseHighTimeField setFloatValue: [model pulseHighTime]*64]; //convert to 탎econds, 32 multiplier in new firmware
	[self displayFrequency];
}

- (void) pulseLowTimeChanged:(NSNotification*)aNote
{
	[pulseLowTimeField setFloatValue: ([model pulseLowTime]*2)+2]; //convert to 탎econds
    //[pulseLowTimeField setFloatValue: [model pulseLowTime]*2];
    //[pulseLowTimeField setFloatValue: [model pulseLowTime]*64]; //convert to 탎econds, 32 multiplier in new firmware
	[self displayFrequency];
}

- (void) displayFrequency
{
	[frequencyField setFloatValue: 1/ ((([model pulseLowTime] + [model pulseHighTime]) * 2.0E-6)+4.0E-6)];
    //[frequencyField setFloatValue: 1/ (([model pulseLowTime] + [model pulseHighTime]) * 2.0E-6)];
    //[frequencyField setFloatValue: 1/ (([model pulseLowTime] + [model pulseHighTime]) * 64.0E-6)];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:MJDPreAmpSettingsLock to:secure];
    [settingsLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification *)notification
{    
    BOOL locked = [gSecurity isLocked:MJDPreAmpSettingsLock];
    [settingsLockButton setState:locked];
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL locked = [gSecurity isLocked:MJDPreAmpSettingsLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:MJDPreAmpSettingsLock];
	[loopForeverPU		setEnabled:!lockedOrRunningMaintenance];
	[pulseCountField	setEnabled:!lockedOrRunningMaintenance && ![model loopForever]];
	[enabled0PU			setEnabled:!lockedOrRunningMaintenance];
	[enabled1PU			setEnabled:!lockedOrRunningMaintenance];
    [attenuated0PU      setEnabled:!lockedOrRunningMaintenance];
    [attenuated1PU      setEnabled:!lockedOrRunningMaintenance];
    [finalAttenuated0PU setEnabled:!lockedOrRunningMaintenance];
    [finalAttenuated1PU setEnabled:!lockedOrRunningMaintenance];
	[pulseHighTimeField setEnabled:!lockedOrRunningMaintenance];
	[pulseLowTimeField	setEnabled:!lockedOrRunningMaintenance];
	[dacsMatrix			setEnabled:!lockedOrRunningMaintenance];
	[amplitudesMatrix	setEnabled:!lockedOrRunningMaintenance];
	[pulserMaskMatrix	setEnabled:!lockedOrRunningMaintenance];	
	[startPulserButton	setEnabled:!lockedOrRunningMaintenance];	
	[stopPulserButton	setEnabled:!lockedOrRunningMaintenance];	
	[pollTimePU			setEnabled:!locked];
    [detectorNameMatrix setEnabled:!locked && [model doNotUseHWMap]];
}

- (void) dacChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
    float referenceVoltage = [model boardRev]==0 ? 4.1 : 3.0;

    [[dacsMatrix cellWithTag:chan] setFloatValue: [model dac:chan]*referenceVoltage/65535.];		//new voltage ref
}

- (void) amplitudeChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
	[[amplitudesMatrix cellWithTag:chan] setIntValue: [model amplitude:chan]];		//convert to volts
}

- (void) dacArrayChanged:(NSNotification*)aNotification
{
    float referenceVoltage = [model boardRev]==0 ? 4.1 : 3.0;
    
	short chan;
	for(chan=0;chan<kMJDPreAmpDacChannels;chan++){
        [[dacsMatrix cellWithTag:chan] setFloatValue: [model dac:chan]*referenceVoltage/65535.];   //new voltage ref
	}
}

- (void) amplitudeArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kMJDPreAmpDacChannels;chan++){
		[[amplitudesMatrix cellWithTag:chan] setIntValue: [model amplitude:chan]]; //convert to volts
	}
}

#pragma mark ⅴ쩇ctions
- (IBAction) firmwareRevAction:(id)sender
{
    [model setFirmwareRev:[sender indexOfSelectedItem]];
}

- (IBAction) doNotUseHWMapAction:(id)sender
{
    [model setDoNotUseHWMap:[sender indexOfSelectedItem]];
}

- (IBAction) boardRevAction:(id)sender
{
	[model setBoardRev:[sender indexOfSelectedItem]];
}

- (IBAction) adcEnabledMaskAction:(id)sender
{
	unsigned short mask = 0;
	int i;
	for(i=0;i<16;i++){
		int theValue = [[adcEnabledMaskMatrix cellWithTag:i] intValue];
		if(theValue) mask |= (0x1<<i);
	}
	[model setAdcEnabledMask:mask];	
}

- (IBAction) shipValuesAction:(id)sender
{
	[model setShipValues:[sender intValue]];	
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];
}

- (IBAction) loopForeverAction:(id)sender
{
	[model setLoopForever:![sender indexOfSelectedItem]];	
}

- (IBAction) pulseCountAction:(id)sender
{
	[model setPulseCount:[sender intValue]];	
}

- (IBAction) clearSupplyErrorsAction:(id)sender
{
    [model clearSupplyErrors];
}

- (IBAction) detectorNameAction:(id)sender
{
   	[model setDetector:[[sender selectedCell] tag] name:[sender stringValue]];
}

- (IBAction) enabledAction:(id)sender
{
	int index = [sender tag];
	[model setEnabled:index value:[sender indexOfSelectedItem]];	
}

- (IBAction) attenuatedAction:(id)sender
{
	int index = [sender tag];
	[model setAttenuated:index value:[sender indexOfSelectedItem]];	
}

- (IBAction) finalAttenuatedAction:(id)sender
{
	int index = [sender tag];
	[model setFinalAttenuated:index value:[sender indexOfSelectedItem]];	
}

- (IBAction) pulserMaskAction:(id)sender
{
	unsigned short mask = 0;
	int i;
	for(i=0;i<16;i++){
		int theValue = [[pulserMaskMatrix cellWithTag:i] intValue];
		if(theValue) mask |= (0x1<<i);
	}
	[model setPulserMask:mask];	
}

- (IBAction) pulseHighTimeAction:(id)sender
{
	[model setPulseHighTime:([sender intValue]-2)/2]; //convert from 탎econds to hw value
    //[model setPulseHighTime:[sender intValue]/64]; //convert from 탎econds to hw value
}

- (IBAction) pulseLowTimeAction:(id)sender
{
	[model setPulseLowTime:([sender intValue]-2)/2];	 //convert from 탎econds to hw value
    //[model setPulseLowTime:[sender intValue]/64];	 //convert from 탎econds to hw value
}

- (IBAction) dacsAction:(id)sender
{
    float referenceVoltage = [model boardRev]==0 ? 4.1 : 3.0;
    
    [model setDac:[[sender selectedCell] tag] withValue:[sender floatValue]*65535./referenceVoltage];
}

- (IBAction) amplitudesAction:(id)sender
{
	[model setAmplitude:[[sender selectedCell] tag] withValue:[sender intValue]]; 
}

- (IBAction) settingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:MJDPreAmpSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) writeFetVdsAction:(id)sender
{
	[model writeFetVdsToHW];
}

- (IBAction) startPulserAction:(id)sender
{
	[model startPulser];
}

- (IBAction) stopPulserAction:(id)sender
{
	[model stopPulser];
}

- (IBAction) readAdcs:(id)sender
{
	[model readAllAdcs:YES];
}

- (IBAction) pollNowAction:(id)sender
{
	[model pollValues];
}

- (IBAction) feedBackResistorAction:(id)sender
{
	[model setFeedBackResistor:[[sender selectedCell] tag]  value:[sender floatValue]];
}

- (IBAction) baselineVoltageAction:(id)sender
{
  	[model setBaselineVoltage:[[sender selectedCell] tag]  value:[sender floatValue]];
  
}

#pragma mark ⅴ쩊ata Source
- (int) numberPointsInPlot:(id)aPlotter
{
    if(aPlotter == leakageCurrentPlot0 || aPlotter == leakageCurrentPlot1){
        return [[model leakageCurrentHistory:[aPlotter tag]] count];
    }
    else {
        return [[model adcHistory:[aPlotter tag]] count];
    }
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    if(aPlotter == leakageCurrentPlot0 || aPlotter == leakageCurrentPlot1){
        int tag = [aPlotter tag];
        int count = [[model leakageCurrentHistory:tag] count];
        int index = count-i-1;        
        *xValue = [[model leakageCurrentHistory:tag] timeSampledAtIndex:index];
        *yValue = [[model leakageCurrentHistory:tag] valueAtIndex:index];
    }
    else {
        int tag = [aPlotter tag];
        int count = [[model adcHistory:tag] count];
        int index = count-i-1;
        *xValue = [[model adcHistory:tag] timeSampledAtIndex:index];
        *yValue = [[model adcHistory:tag] valueAtIndex:index];
    }
}
@end
