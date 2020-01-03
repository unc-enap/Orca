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
    [[self window] setTitle:[NSString stringWithFormat:@"FlasCam ADC (%x Slot %d)", [model boardAddress], [model slot]]];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(boardAddressChanged:)
                         name : ORFlashCamADCModelBoardAddressChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(cardSlotChanged:)
                         name : ORFlashCamCardSlotChangedNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(chanEnabledChanged:)
                         name : ORFlashCamADCModelChanEnabledChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(baselineChanged:)
                         name : ORFlashCamADCModelBaselineChanged
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
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) updateWindow
{
    [super updateWindow];
    [self boardAddressChanged:nil];
    [self chanEnabledChanged:nil];
    [self baselineChanged:nil];
    [self thresholdChanged:nil];
    [self adcGainChanged:nil];
    [self trigGainChanged:nil];
    [self shapeTimeChanged:nil];
    [self filterTypeChanged:nil];
    [self poleZeroTimeChanged:nil];
}

#pragma mark •••Interface Management

- (void) boardAddressChanged:(NSNotification *)note
{
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam ADC (0x%x, Slot %d)", [model boardAddress], [model slot]]];
    [boardAddressTextField setIntValue:[model boardAddress]];
}

- (void) cardSlotChanged:(NSNotification*)note
{
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam ADC (0x%x, Slot %d)", [model boardAddress], [model slot]]];
}

- (void) chanEnabledChanged:(NSNotification*)note
{
    if(note == nil){
        for(int i=0; i<kMaxFlashCamADCChannels; i++)
            [[chanEnabledMatrix cellWithTag:i] setState:[model chanEnabled:i]];
    }
    else{
        int chan = [[[note userInfo] objectForKey:@"Channel"] intValue];
        [[chanEnabledMatrix cellWithTag:chan] setState:[model chanEnabled:chan]];
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

#pragma mark •••Actions

- (IBAction) boardAddressAction:(id)sender
{
    [model setBoardAddress:[sender intValue]];
}

- (IBAction) chanEnabledAction:(id)sender
{
    if([sender intValue] != [model chanEnabled:(unsigned int)[[sender selectedCell] tag]])
        [model setChanEnabled:(unsigned int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) baselineAction:(id)sender
{
    if([sender intValue] != [model baseline:(int)[[sender selectedCell] tag]])
        [model setBaseline:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) thresholdAction:(id)sender
{
    if([sender intValue] != [model threshold:(int)[[sender selectedCell] tag]])
        [model setThreshold:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) adcGainAction:(id)sender
{
    if([sender intValue] != [model adcGain:(int)[[sender selectedCell] tag]])
        [model setADCGain:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) trigGainAction:(id)sender
{
    if([sender floatValue] != [model trigGain:(float)[[sender selectedCell] tag]])
        [model setTrigGain:(float)[[sender selectedCell] tag] withValue:[sender floatValue]];
}

- (IBAction) shapeTimeAction:(id)sender
{
    if([sender intValue] != [model shapeTime:(int)[[sender selectedCell] tag]])
        [model setShapeTime:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) filterTypeAction:(id)sender
{
    if([sender floatValue] != [model filterType:(float)[[sender selectedCell] tag]])
        [model setFilterType:(float)[[sender selectedCell] tag] withValue:[sender floatValue]];
}

- (IBAction) poleZeroTimeAction:(id)sender
{
    if([sender floatValue] != [model poleZeroTime:(float)[[sender selectedCell] tag]])
        [model setPoleZeroTime:(float)[[sender selectedCell] tag] withValue:[sender floatValue]];
}

- (IBAction) printFlagsAction:(id)sender
{
    [model printRunFlagsForChannelOffset:0];
}

@end
