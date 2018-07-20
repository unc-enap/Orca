//-------------------------------------------------------------------------
//  ORSIS3320Controller.h
//
//  Created by Mark A. Howe on Thursday 8/6/09
//  Copyright (c) 2009 Universiy of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORSIS3320Controller.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORTimeRate.h"
#import "ORRate.h"
#import "OHexFormatter.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORValueBarGroupView.h"

@implementation ORSIS3320Controller

-(id)init
{
    self = [super initWithWindowNibName:@"SIS3320"];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	settingSize     = NSMakeSize(930,645);
    rateSize		= NSMakeSize(470,480);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	NSString* key = [NSString stringWithFormat: @"orca.SIS3320%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
		
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
	int i;
	for(i=0;i<8;i++){
		[[gtMatrix              cellAtRow:i column:0] setTag:i];
		[[triggerOutMatrix      cellAtRow:i column:0] setTag:i];
		[[extendedTriggerMatrix cellAtRow:i column:0] setTag:i];
		[[thresholdMatrix       cellAtRow:i column:0] setTag:i];
		[[sumGMatrix            cellAtRow:i column:0] setTag:i];
		[[peakingTimeMatrix     cellAtRow:i column:0] setTag:i];
		[[dacValueMatrix        cellAtRow:i column:0] setTag:i];
		[[trigPulseLenMatrix    cellAtRow:i column:0] setTag:i];
	}
	
	for(i=0;i<4;i++){
        [[endAddressThresholdMatrix     cellAtRow:i column:0] setTag:i];
        [[bufferStartMatrix             cellAtRow:i column:0] setTag:i];
        [[bufferLengthMatrix            cellAtRow:i column:0] setTag:i];
        
        [[accGate1LengthMatrix          cellAtRow:i column:0] setTag:i];
        [[accGate1StartIndexMatrix      cellAtRow:i column:0] setTag:i];
        [[accGate2LengthMatrix          cellAtRow:i column:0] setTag:i];
        [[accGate2StartIndexMatrix      cellAtRow:i column:0] setTag:i];
        [[accGate3LengthMatrix          cellAtRow:i column:0] setTag:i];
        [[accGate3StartIndexMatrix      cellAtRow:i column:0] setTag:i];
        [[accGate4LengthMatrix          cellAtRow:i column:0] setTag:i];
        [[accGate4StartIndexMatrix      cellAtRow:i column:0] setTag:i];
        [[accGate5LengthMatrix          cellAtRow:i column:0] setTag:i];
        [[accGate5StartIndexMatrix      cellAtRow:i column:0] setTag:i];
        [[accGate6LengthMatrix          cellAtRow:i column:0] setTag:i];
        [[accGate6StartIndexMatrix      cellAtRow:i column:0] setTag:i];
        [[accGate7LengthMatrix          cellAtRow:i column:0] setTag:i];
        [[accGate7StartIndexMatrix      cellAtRow:i column:0] setTag:i];
        [[accGate8LengthMatrix          cellAtRow:i column:0] setTag:i];
        [[accGate8StartIndexMatrix      cellAtRow:i column:0] setTag:i];

    }
    for(i=0;i<2;i++){
        [[invertInputMatrix             cellAtRow:i column:0] setTag:i];
        [[enableErrorCorrectionMatrix   cellAtRow:i column:0] setTag:i];
        [[saveAlwaysMatrix              cellAtRow:i column:0] setTag:i];
        [[saveIfPileUpMatrix            cellAtRow:i column:0] setTag:i];
        [[saveFIRTriggerMatrix          cellAtRow:i column:0] setTag:i];
        [[saveFirstEventMatrix          cellAtRow:i column:0] setTag:i];
        [[triggerModeMatrix             cellAtRow:i column:0] setTag:i];
    }

    [rate0 setNumber:8 height:10 spacing:5];

	[super awakeFromNib];
	
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(baseAddressChanged:)
                         name : ORVmeIOCardBaseAddressChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORSIS3320SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORSIS3320RateGroupChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
    
    [notifyCenter addObserver : self
                     selector : @selector(updateTimePlot:)
                         name : ORRateAverageChangedNotification
                       object : [[model waveFormRateGroup]timeRate]];
    
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(moduleIDChanged:)
                         name : ORSIS3320ModelIDChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORSIS3320ModelClockSourceChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(internalTriggerEnabledChanged:)
                         name : ORSIS3320ModelInternalTriggerEnabledChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoTriggerEnabledChanged:)
                         name : ORSIS3320ModelLemoTriggerEnabledChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoTimeStampClrEnabledChanged:)
                         name : ORSIS3320ModelLemoTimeStampClrEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dacValueChanged:)
                         name : ORSIS3320ModelDacValueChanged
                       object : model];

 	[notifyCenter addObserver : self
                     selector : @selector(triggerModeChanged:)
                         name : ORSIS3320ModelTriggerModeChanged
						object: model];
  
    [notifyCenter addObserver : self
                     selector : @selector(preTriggerDelayChanged:)
                         name : ORSIS3320ModelPreTriggerDelayChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(triggerGateLengthChanged:)
                         name : ORSIS3320ModelTriggerGateLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORSIS3320ModelThresholdChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(endAddressThresholdChanged:)
                         name : ORSIS3320ModelEndAddressThresholdChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(trigPulseLenChanged:)
                         name : ORSIS3320ModelTrigPulseLenChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(sumGChanged:)
                         name : ORSIS3320ModelSumGChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(peakingTimeChanged:)
                         name : ORSIS3320ModelPeakingTimeChanged
						object: model];
			
	[notifyCenter addObserver : self
                     selector : @selector(gtMaskChanged:)
                         name : ORSIS3320ModelGtMaskChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(triggerOutMaskChanged:)
                         name : ORSIS3320ModelTriggerOutMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(extendedTriggerMaskChanged:)
                         name : ORSIS3320ModelExtendedTriggerMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(saveFirstEventChanged:)
                         name : ORSIS3320ModelSaveFirstEventChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(saveFIRTriggerChanged:)
                         name : ORSIS3320ModelSaveFIRTriggerChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(saveIfPileUpChanged:)
                         name : ORSIS3320ModelSaveIfPileUpChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(saveAlwaysChanged:)
                         name : ORSIS3320ModelSaveAlwaysChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enableErrorCorrectionChanged:)
                         name : ORSIS3320ModelEnableErrorCorrectionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(invertInputChanged:)
                         name : ORSIS3320ModelInvertInputChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(bufferLengthChanged:)
                         name : ORSIS3320ModelBufferLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(bufferStartChanged:)
                         name : ORSIS3320ModelBufferStartChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(accGate1StartIndexChanged:)
                         name : ORSIS3320ModelAccGate1StartIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(accGate1LengthChanged:)
                         name : ORSIS3320ModelAccGate1LengthChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate2StartIndexChanged:)
                         name : ORSIS3320ModelAccGate2StartIndexChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate2LengthChanged:)
                         name : ORSIS3320ModelAccGate2LengthChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate3StartIndexChanged:)
                         name : ORSIS3320ModelAccGate3StartIndexChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate3LengthChanged:)
                         name : ORSIS3320ModelAccGate3LengthChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate4StartIndexChanged:)
                         name : ORSIS3320ModelAccGate4StartIndexChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate4LengthChanged:)
                         name : ORSIS3320ModelAccGate4LengthChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate5StartIndexChanged:)
                         name : ORSIS3320ModelAccGate5StartIndexChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate5LengthChanged:)
                         name : ORSIS3320ModelAccGate5LengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(accGate6StartIndexChanged:)
                         name : ORSIS3320ModelAccGate6StartIndexChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate6LengthChanged:)
                         name : ORSIS3320ModelAccGate6LengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(accGate7StartIndexChanged:)
                         name : ORSIS3320ModelAccGate7StartIndexChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate7LengthChanged:)
                         name : ORSIS3320ModelAccGate7LengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(accGate8StartIndexChanged:)
                         name : ORSIS3320ModelAccGate8StartIndexChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate8LengthChanged:)
                         name : ORSIS3320ModelAccGate8LengthChanged
						object: model];

	
    //a fake action for the scale objects
    [notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
    
    [notifyCenter addObserver : self
					 selector : @selector(onlineMaskChanged:)
						 name : ORSIS3320ModelOnlineChanged
					   object : model];

    [self registerRates];
}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
    
    NSArray* theRates = [[model waveFormRateGroup] rates];
    for(id obj in theRates){
		
        [notifyCenter removeObserver:self name:ORRateChangedNotification object:obj];
		
        [notifyCenter addObserver : self
                         selector : @selector(waveFormRateChanged:)
                             name : ORRateChangedNotification
                           object : obj];
    }
}


- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
    
	[self moduleIDChanged:nil];
    [self internalTriggerEnabledChanged:nil];
	[self lemoTriggerEnabledChanged:nil];
	[self lemoTimeStampClrEnabledChanged:nil];
	[self clockSourceChanged:nil];
	[self dacValueChanged:nil];
	[self triggerModeChanged:nil];
	[self preTriggerDelayChanged:nil];
	[self triggerGateLengthChanged:nil];
	[self saveFirstEventChanged:nil];
	[self saveFIRTriggerChanged:nil];
	[self saveIfPileUpChanged:nil];
	[self saveAlwaysChanged:nil];
	[self enableErrorCorrectionChanged:nil];
	[self invertInputChanged:nil];
    
	[self gtMaskChanged:nil];
	[self triggerOutMaskChanged:nil];
	[self extendedTriggerMaskChanged:nil];
	
	[self thresholdChanged:nil];
	[self endAddressThresholdChanged:nil];
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
	[self trigPulseLenChanged:nil];
	[self sumGChanged:nil];
	[self peakingTimeChanged:nil];
	[self bufferLengthChanged:nil];
	[self bufferStartChanged:nil];
	[self accGate1StartIndexChanged:nil];
	[self accGate1LengthChanged:nil];
	[self accGate2StartIndexChanged:nil];
	[self accGate2LengthChanged:nil];
	[self accGate3StartIndexChanged:nil];
	[self accGate3LengthChanged:nil];
	[self accGate4StartIndexChanged:nil];
	[self accGate4LengthChanged:nil];
	[self accGate5StartIndexChanged:nil];
	[self accGate5LengthChanged:nil];
	[self accGate6StartIndexChanged:nil];
	[self accGate6LengthChanged:nil];
	[self accGate7StartIndexChanged:nil];
	[self accGate7LengthChanged:nil];
	[self accGate8StartIndexChanged:nil];
	[self accGate8LengthChanged:nil];
    [self onlineMaskChanged:nil];
}

#pragma mark •••Interface Management
- (void) onlineMaskChanged:(NSNotification*)aNotification
{
	short i;
	unsigned char theMask = [model onlineMask];
	for(i=0;i<kNumSIS3320Channels;i++){
		BOOL bitSet = (theMask&(1<<i))>0;
		if(bitSet != [[onlineMaskMatrix cellWithTag:i] intValue]){
			[[onlineMaskMatrix cellWithTag:i] setState:bitSet];
		}
	}
    [self settingsLockChanged:aNotification];
}

- (void) accGate1StartIndexChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++)[[accGate1StartIndexMatrix cellWithTag:i] setIntegerValue: [model accGate1StartIndex:i]];
}
- (void) accGate1LengthChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++){
        [[accGate1LengthMatrix cellWithTag:i] setIntegerValue: [model accGate1Length:i]];
    }
}

- (void) accGate2StartIndexChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++)[[accGate2StartIndexMatrix cellWithTag:i] setIntegerValue: [model accGate2StartIndex:i]];
}
- (void) accGate2LengthChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++){
        [[accGate2LengthMatrix cellWithTag:i] setIntegerValue: [model accGate2Length:i]];
    }
}

- (void) accGate3StartIndexChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++)[[accGate3StartIndexMatrix cellWithTag:i] setIntegerValue: [model accGate3StartIndex:i]];
}
- (void) accGate3LengthChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++){
        [[accGate3LengthMatrix cellWithTag:i] setIntegerValue: [model accGate3Length:i]];
    }
}

- (void) accGate4StartIndexChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++)[[accGate4StartIndexMatrix cellWithTag:i] setIntegerValue: [model accGate4StartIndex:i]];
}
- (void) accGate4LengthChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++){
        [[accGate4LengthMatrix cellWithTag:i] setIntegerValue: [model accGate4Length:i]];
    }
}

- (void) accGate5StartIndexChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++)[[accGate5StartIndexMatrix cellWithTag:i] setIntegerValue: [model accGate5StartIndex:i]];
}
- (void) accGate5LengthChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++){
        [[accGate5LengthMatrix cellWithTag:i] setIntegerValue: [model accGate5Length:i]];
    }
}

- (void) accGate6StartIndexChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++)[[accGate6StartIndexMatrix cellWithTag:i] setIntegerValue: [model accGate6StartIndex:i]];
}
- (void) accGate6LengthChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++){
        [[accGate6LengthMatrix cellWithTag:i] setIntegerValue: [model accGate6Length:i]];
    }
}

- (void) accGate7StartIndexChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++)[[accGate7StartIndexMatrix cellWithTag:i] setIntegerValue: [model accGate7StartIndex:i]];
}
- (void) accGate7LengthChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++){
        [[accGate7LengthMatrix cellWithTag:i] setIntegerValue: [model accGate7Length:i]];
    }
}

- (void) accGate8StartIndexChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++)[[accGate8StartIndexMatrix cellWithTag:i] setIntegerValue: [model accGate8StartIndex:i]];
}
- (void) accGate8LengthChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++){
        [[accGate8LengthMatrix cellWithTag:i] setIntegerValue: [model accGate8Length:i]];
    }
}


- (void) bufferStartChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++){
        [[bufferStartMatrix cellWithTag:i] setIntegerValue: [model bufferStart:i]];
    }
}

- (void) bufferLengthChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++){
        [[bufferLengthMatrix cellWithTag:i] setIntegerValue: [model bufferLength:i]];
    }
}

- (void) moduleIDChanged:(NSNotification*)aNote
{
   [firmwareVersionField setStringValue:[model firmwareVersion]];
}

- (void) lemoTimeStampClrEnabledChanged:(NSNotification*)aNote
{
	[lemoTimeStampClrEnabledCB setIntValue: [model lemoTimeStampClrEnabled]];
}

- (void) lemoTriggerEnabledChanged:(NSNotification*)aNote
{
	[lemoTriggerEnabledCB setIntValue: [model lemoTriggerEnabled]];
}

- (void) internalTriggerEnabledChanged:(NSNotification*)aNote
{
	[internalTriggerEnabledCB setIntValue: [model internalTriggerEnabled]];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
}

- (void) dacValueChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3320Channels;i++)[[dacValueMatrix cellWithTag:i] setIntegerValue:[model dacValue:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[dacValueMatrix cellWithTag:i] setIntegerValue:[model dacValue:i]];
	}
}

- (void) invertInputChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumSIS3320Groups;i++){
        [[invertInputMatrix cellWithTag:i] setIntValue: [model invertInput:i]];
    }
}

- (void) enableErrorCorrectionChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumSIS3320Groups;i++){
        [[enableErrorCorrectionMatrix cellWithTag:i] setIntValue: [model enableErrorCorrection:i]];
    }
}
- (void) triggerModeChanged:(NSNotification*)aNotification
{
    int i;
    for(i=0;i<kNumSIS3320Groups;i++){
        [[triggerModeMatrix cellAtRow:i column:0] selectItemAtIndex:[model triggerMode:i]];
    }
}

- (void) saveAlwaysChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumSIS3320Groups;i++){
        [[saveAlwaysMatrix cellWithTag:i] setIntValue: [model saveAlways:i]];
    }
}

- (void) saveIfPileUpChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumSIS3320Groups;i++){
        [[saveIfPileUpMatrix cellWithTag:i] setIntValue: [model saveIfPileUp:i]];
    }
}

- (void) saveFIRTriggerChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumSIS3320Groups;i++){
        [[saveFIRTriggerMatrix cellWithTag:i] setIntValue: [model saveFIRTrigger:i]];
    }
}

- (void) saveFirstEventChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumSIS3320Groups;i++){
        [[saveFirstEventMatrix cellWithTag:i] setIntValue: [model saveFirstEvent:i]];
    }
}

- (void) triggerGateLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3320Groups;i++){
		[[triggerGateLengthMatrix cellWithTag:i] setIntValue:[model triggerGateLength:i]];
	}
}

- (void) preTriggerDelayChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3320Groups;i++){
		[[preTriggerDelayMatrix cellWithTag:i] setIntValue:[model preTriggerDelay:i]];
	}
}

- (void) thresholdChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3320Channels;i++)[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
	}
}

- (void) endAddressThresholdChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3320Groups;i++)[[endAddressThresholdMatrix cellWithTag:i] setIntegerValue:[model endAddressThreshold:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[endAddressThresholdMatrix cellWithTag:i] setIntegerValue:[model endAddressThreshold:i]];
	}
}

- (void) trigPulseLenChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3320Groups;i++)[[trigPulseLenMatrix cellWithTag:i] setIntValue:[model trigPulseLen:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[trigPulseLenMatrix cellWithTag:i] setIntValue:[model trigPulseLen:i]];
	}
}

- (void) sumGChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3320Channels;i++)[[sumGMatrix cellWithTag:i] setIntValue:[model sumG:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[sumGMatrix cellWithTag:i] setIntValue:[model sumG:i]];
	}
}

- (void) peakingTimeChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3320Channels;i++)[[peakingTimeMatrix cellWithTag:i] setIntValue:[model peakingTime:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[peakingTimeMatrix cellWithTag:i] setIntValue:[model peakingTime:i]];
	}
}

- (void) gtMaskChanged:(NSNotification*)aNotification
{
	short i;
	uint32_t theMask = [model gtMask];
	for(i=0;i<8;i++){
		[[gtMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
}

- (void) triggerOutMaskChanged:(NSNotification*)aNotification
{
	short i;
	uint32_t theMask = [model triggerOutMask];
	for(i=0;i<8;i++){
		[[triggerOutMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
}

- (void) extendedTriggerMaskChanged:(NSNotification*)aNotification
{
	short i;
	uint32_t theMask = [model extendedTriggerMask];
	for(i=0;i<8;i++){
		[[extendedTriggerMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
}


- (void) waveFormRateChanged:(NSNotification*)aNote
{
    ORRate* theRateObj = [aNote object];		
    [[rateTextFields cellWithTag:[theRateObj tag]] setFloatValue: [theRateObj rate]];
    [rate0 setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateObj = [aNotification object];
	if(aNotification == nil || [model waveFormRateGroup] == theRateObj){
		
		[totalRateText setFloatValue: [theRateObj totalRate]];
		[totalRate setNeedsDisplay:YES];
	}
}

- (void) rateGroupChanged:(NSNotification*)aNote
{
    [self registerRates];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSIS3320SettingsLock to:secure];
    [settingLockButton setEnabled:secure];

}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress              = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3320SettingsLock];
    BOOL locked                     = [gSecurity isLocked:ORSIS3320SettingsLock];
    
    [settingLockButton			setState: locked];
    [onlineMaskMatrix           setEnabled:!lockedOrRunningMaintenance];
    [addressText				setEnabled:!locked && !runInProgress];
	[clockSourcePU				setEnabled:!lockedOrRunningMaintenance];
    [initButton					setEnabled:!lockedOrRunningMaintenance];
    [resetButton				setEnabled:!lockedOrRunningMaintenance];
    [triggerButton				setEnabled:!lockedOrRunningMaintenance];
    [clearTimeStampButton		setEnabled:!lockedOrRunningMaintenance];
	[regDumpButton				setEnabled:!lockedOrRunningMaintenance];
	[gtMatrix				    setEnabled:!lockedOrRunningMaintenance];
    
    int i;
	for(i=0;i<8;i++){
        BOOL chanEnabled = [model onlineMaskBit:i];
		[[thresholdMatrix           cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & chanEnabled];
		[[gtMatrix                  cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & chanEnabled];
		[[triggerOutMatrix          cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & chanEnabled];
		[[extendedTriggerMatrix     cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & chanEnabled];
		[[sumGMatrix                cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & chanEnabled];
		[[peakingTimeMatrix         cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & chanEnabled];
		[[dacValueMatrix            cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & chanEnabled];
		[[trigPulseLenMatrix        cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & chanEnabled];
	}
    for(i=0;i<4;i++){
        BOOL groupEnabled = [model onlineMaskBit:i*2] || [model onlineMaskBit:i*2+1];
        [[preTriggerDelayMatrix         cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[triggerGateLengthMatrix       cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[endAddressThresholdMatrix     cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[bufferStartMatrix             cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[bufferLengthMatrix            cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        
        [[accGate1LengthMatrix          cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate1StartIndexMatrix      cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate2LengthMatrix          cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate2StartIndexMatrix      cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate3LengthMatrix          cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate3StartIndexMatrix      cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate4LengthMatrix          cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate4StartIndexMatrix      cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate5LengthMatrix          cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate5StartIndexMatrix      cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate6LengthMatrix          cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate6StartIndexMatrix      cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate7LengthMatrix          cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate7StartIndexMatrix      cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate8LengthMatrix          cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[accGate8StartIndexMatrix      cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
    }
    
    for(i=0;i<2;i++){
        
        BOOL groupEnabled = [model onlineMaskBit:i] || [model onlineMaskBit:i+2] || [model onlineMaskBit:i+4] || [model onlineMaskBit:i*6];

        [[invertInputMatrix             cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[enableErrorCorrectionMatrix   cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[saveAlwaysMatrix              cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[saveIfPileUpMatrix            cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[saveFIRTriggerMatrix          cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[saveFirstEventMatrix          cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
        [[triggerModeMatrix             cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance & groupEnabled];
    }

}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3320 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3320 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntegerValue: [model baseAddress]];
}

- (void) integrationChanged:(NSNotification*)aNotification
{
    ORRateGroup* theRateGroup = [aNotification object];
    if(aNotification == nil || [model waveFormRateGroup] == theRateGroup || [aNotification object] == model){
        double dValue = [[model waveFormRateGroup] integrationTime];
        [integrationStepper setDoubleValue:dValue];
        [integrationText setDoubleValue: dValue];
    }
}


- (IBAction) scaleAction:(NSNotification*)aNote
{
	if(aNote == nil || [aNote object] == [rate0 xAxis]){
		[model setMiscAttributes:[[rate0 xAxis]attributes] forKey:@"RateXAttributes"];
	};
	
	if(aNote == nil || [aNote object] == [totalRate xAxis]){
		[model setMiscAttributes:[[totalRate xAxis]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNote == nil || [aNote object] == [timeRatePlot xAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot xAxis]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNote == nil || [aNote object] == [timeRatePlot yAxis]){
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


- (void) updateTimePlot:(NSNotification*)aNote
{
    if(!aNote || ([aNote object] == [[model waveFormRateGroup]timeRate])){
        [timeRatePlot setNeedsDisplay:YES];
    }
}

#pragma mark •••Actions

- (IBAction) onlineAction:(id)sender
{
	if([sender intValue] != [model onlineMaskBit:(int)[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Online Mask"];
		[model setOnlineMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) accGate1LengthAction:(id)sender      { [model setAccGate1Length:   (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate1StartIndexAction:(id)sender    { [model setAccGate1StartIndex: (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate2LengthAction:(id)sender      { [model setAccGate2Length:   (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate2StartIndexAction:(id)sender    { [model setAccGate2StartIndex: (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate3LengthAction:(id)sender      { [model setAccGate3Length:   (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate3StartIndexAction:(id)sender    { [model setAccGate3StartIndex: (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate4LengthAction:(id)sender      { [model setAccGate4Length:   (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate4StartIndexAction:(id)sender    { [model setAccGate4StartIndex: (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate5LengthAction:(id)sender      { [model setAccGate5Length:   (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate5StartIndexAction:(id)sender    { [model setAccGate5StartIndex: (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate6LengthAction:(id)sender      { [model setAccGate6Length:   (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate6StartIndexAction:(id)sender    { [model setAccGate6StartIndex: (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate7LengthAction:(id)sender      { [model setAccGate7Length:   (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate7StartIndexAction:(id)sender    { [model setAccGate7StartIndex: (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate8LengthAction:(id)sender      { [model setAccGate8Length:   (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }
- (IBAction) accGate8StartIndexAction:(id)sender    { [model setAccGate8StartIndex: (int)[[sender selectedCell] tag] withValue:[sender intValue]]; }

- (IBAction) bufferStartAction:(id)sender
{
    [model setBufferStart:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) bufferLengthAction:(id)sender
{
    [model setBufferLength:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) invertInputAction:(id)sender
{
    [model setInvertInput:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) enableErrorCorrectionAction:(id)sender
{
    [model setEnableErrorCorrection:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) saveAlwaysAction:(id)sender
{
    [model setSaveAlways:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) saveIfPileUpAction:(id)sender
{
    [model setSaveIfPileUp:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) saveFIRTriggerAction:(id)sender
{
    [model setSaveFIRTrigger:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) saveFirstEventAction:(id)sender
{
    [model setSaveFirstEvent:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) lemoTimeStampClrEnabledAction:(id)sender
{
	[model setLemoTimeStampClrEnabled:[sender intValue]];
}

- (IBAction) lemoTriggerEnabledAction:(id)sender
{
	[model setLemoTriggerEnabled:[sender intValue]];
}

- (IBAction) internalTriggerEnabledAction:(id)sender
{
	[model setInternalTriggerEnabled:[sender intValue]];
}

- (IBAction) clockSourceAction:(id)sender
{
	[model setClockSource:(int)[sender indexOfSelectedItem]];
}

- (IBAction) dacValueAction:(id)sender
{
    if([sender intValue] != [model dacValue:(int)[[sender selectedCell] tag]]){
		[model setDacValue:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) triggerModeAction:(id)sender
{
    [model setTriggerMode:(int)[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) triggerGateLengthAction:(id)sender
{
    if([sender intValue] != [model triggerGateLength:[[sender selectedCell] tag]]){
		[model setTriggerGateLength:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) preTriggerDelayAction:(id)sender
{
    if([sender intValue] != [model preTriggerDelay:[[sender selectedCell] tag]]){
		[model setPreTriggerDelay:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) thresholdAction:(id)sender
{
    if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) endAddressThresholdAction:(id)sender
{
    if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[model setEndAddressThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}


- (IBAction) trigPulseLenAction:(id)sender
{
    if([sender intValue] != [model trigPulseLen:[[sender selectedCell] tag]]){
		[model setTrigPulseLen:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) sumGAction:(id)sender
{
    if([sender intValue] != [model sumG:[[sender selectedCell] tag]]){
		[model setSumG:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) peakingTimeAction:(id)sender
{
    if([sender intValue] != [model peakingTime:[[sender selectedCell] tag]]){
		[model setPeakingTime:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) gtAction:(id)sender
{
	[model setGtMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) triggerOutAction:(id)sender
{
	[model setTriggerOutMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) extendedTriggerAction:(id)sender
{
	[model setExtendedTriggerMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}


-(IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORSIS3320SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];		
    }
}

#pragma mark ***hardware actions
- (IBAction) reset:(id)sender
{
    @try {
        [self endEditing];
        [model reset];		
        NSLog(@"Reset SIS3320 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of SIS3320 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3320 Reset", @"OK", nil, nil,
                        localException);
    }  
}

- (IBAction) triggerAction:(id)sender
{
    @try {
        [self endEditing];
        [model trigger];
        NSLog(@"Force trigger on SIS3320 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Trigger of SIS3320 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3320 Trigger", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) clearTimeStampButtonAction:(id)sender
{
    @try {
        [self endEditing];
        [model clearTimeStamp];
        NSLog(@"Clear Timestamp on SIS3320 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Clear Timestamp of SIS3320 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3320 Clear Timestamp", @"OK", nil, nil,
                        localException);
    }
}


- (IBAction) initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3320 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Init of SIS3320 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3320 Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) probeBoardAction:(id)sender;
{
	@try {
		[model readModuleID:YES];
	}
	@catch (NSException* localException) {
		NSLog(@"Probe of SIS3320 board ID failed\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3320 Probe FAILED", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) report:(id)sender;
{
	@try {
		[model printReport];
	}
	@catch (NSException* localException) {
		NSLog(@"Read for Report of SIS3320 board ID failed\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3320 Report FAILED", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) regDump:(id)sender
{
	BOOL ok = NO;
    @try {
		[self endEditing];
		[model initBoard];
		ok = YES;
	}
	@catch(NSException* localException) {
        NSLog(@"SIS3320 Reg Dump FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3320 Reg Dump FAILED", @"OK", nil, nil,
                        localException);
    }
	if(ok)[model regDump];
}

#pragma mark •••Data Source and Delegate Actions
- (double) getBarValue:(int)tag
{
	return [[[[model waveFormRateGroup]rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter;
{
	return (int)[[[model waveFormRateGroup]timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int count = (int)[[[model waveFormRateGroup]timeRate] count];
	int index = count-i-1;
	*yValue =  [[[model waveFormRateGroup]timeRate]valueAtIndex:index];
	*xValue =  [[[model waveFormRateGroup]timeRate]timeSampledAtIndex:index];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:rateSize];
		[[self window] setContentView:tabView];
    }
    
    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3320%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
}

@end
