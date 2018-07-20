//
//  ORHPLabJackU6Controller.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 20,2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Physics and Department sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORLabJackU6Controller.h"
#import "ORLabJackU6Model.h"

@implementation ORLabJackU6Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"LabJackU6" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
    short i;
    for(i=0;i<kNumU6AdcChannels;i++){
        [[nameMatrix cellAtRow:i column:0] setEditable:YES];
        [[nameMatrix cellAtRow:i column:0] setTag:i];
        [[nameMatrix1 cellAtRow:i column:0] setEditable:YES];
        [[nameMatrix1 cellAtRow:i column:0] setTag:i];
        [[unitMatrix cellAtRow:i column:0] setEditable:YES];
        [[unitMatrix cellAtRow:i column:0] setTag:i];
        [[adcMatrix cellAtRow:i column:0] setTag:i];
        [[minValueMatrix cellAtRow:i column:0] setTag:i];
        [[maxValueMatrix cellAtRow:i column:0] setTag:i];
        [[slopeMatrix cellAtRow:i column:0] setTag:i];
        [[interceptMatrix cellAtRow:i column:0] setTag:i];
        [[adcRangeMatrix cellAtRow:i column:0] setTag:i];
        
        [[hiLimitMatrix cellAtRow:i column:0] setTag:i];
        [[lowLimitMatrix cellAtRow:i column:0] setTag:i];
        [[enabledMatrix  cellAtRow:i column:0] setTag:i];
        [[enabledMatrix  cellAtRow:i column:0] setTag:i];

        
        if(i<kNumU6AdcChannels/2){
            [[adcDiffMatrix cellAtRow:i column:0] setTag:i];
        }
    }
    
    for(i=0;i<2;i++){
        [[counterEnabledMatrix  cellAtRow:i column:0] setTag:i];
        [[counterMatrix         cellAtRow:i column:0] setTag:i];
    }
    
    for(i=0;i<kNumU6IOChannels;i++){
        [[doNameMatrix cellAtRow:i column:0] setTag:i];
        [[doDirectionMatrix cellAtRow:i column:0] setTag:i];
        [[doValueOutMatrix cellAtRow:i column:0] setTag:i];
        [[doValueInMatrix cellAtRow:i column:0] setTag:i];
    }
    [super awakeFromNib];
    
    blankView = [[NSView alloc] init];
    ioSize			= NSMakeSize(630,665);
    setupSize		= NSMakeSize(630,665);
    
    NSString* key = [NSString stringWithFormat: @"orca.ORLabJac%d.selectedtab",[model uniqueIdNumber]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
}


- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(deviceHandleChanged:)
                         name : ORLabJackU6ModelDeviceHandleChanged
                        object: model];
    
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORLabJackU6Lock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledChanged:)
                         name : ORLabJackU6EnabledChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(counterEnabledChanged:)
                         name : ORLabJackU6CounterEnabledChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(channelNameChanged:)
                         name : ORLabJackU6ChannelNameChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(channelUnitChanged:)
                         name : ORLabJackU6ChannelUnitChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(adcChanged:)
                         name : ORLabJackU6AdcChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(adcRangeChanged:)
                         name : ORLabJackU6AdcRangeChanged
						object: model];		
	
	[notifyCenter addObserver : self
                     selector : @selector(doNameChanged:)
                         name : ORLabJackU6DoNameChanged
						object: model];
		
	[notifyCenter addObserver : self
                     selector : @selector(doDirectionChanged:)
                         name : ORLabJackU6DoDirectionChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(doValueOutChanged:)
                         name : ORLabJackU6DoValueOutChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(doValueInChanged:)
                         name : ORLabJackU6DoValueInChanged
                       object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(counterChanged:)
                         name : ORLabJackU6CounterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(digitalOutputEnabledChanged:)
                         name : ORLabJackU6DigitalOutputEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORLabJackU6PollTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(shipDataChanged:)
                         name : ORLabJackU6ShipDataChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lowLimitChanged:)
                         name : ORLabJackU6LowLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(hiLimitChanged:)
                         name : ORLabJackU6HiLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(adcDiffChanged:)
                         name : ORLabJackU6AdcDiffChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(aOut0Changed:)
                         name : ORLabJackU6ModelAOut0Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(aOut1Changed:)
                         name : ORLabJackU6ModelAOut1Changed
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(slopeChanged:)
                         name : ORLabJackU6SlopeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interceptChanged:)
                         name : ORLabJackU6InterceptChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(involvedInProcessChanged:)
                         name : ORLabJackU6ModelInvolvedInProcessChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(minValueChanged:)
                         name : ORLabJackU6MinValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(maxValueChanged:)
                         name : ORLabJackU6MaxValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(deviceSerialNumberChanged:)
                         name : ORLabJackU6ModelDeviceSerialNumberChanged
						object: model];
}


- (void) updateWindow
{
    [ super updateWindow ];
    [self enabledChanged:nil];
    [self counterEnabledChanged:nil];
    [self deviceHandleChanged:nil];
	[self channelNameChanged:nil];
	[self channelUnitChanged:nil];
	[self doNameChanged:nil];
	[self doDirectionChanged:nil];
	[self doValueOutChanged:nil];
	[self doValueInChanged:nil];
	[self adcChanged:nil];
	[self adcRangeChanged:nil];
    [self lockChanged:nil];
	[self counterChanged:nil];
	[self digitalOutputEnabledChanged:nil];
	[self pollTimeChanged:nil];
	[self shipDataChanged:nil];
	[self lowLimitChanged:nil];
	[self hiLimitChanged:nil];
	[self minValueChanged:nil];
	[self maxValueChanged:nil];
	[self adcDiffChanged:nil];
	[self aOut0Changed:nil];
	[self aOut1Changed:nil];
	[self slopeChanged:nil];
	[self interceptChanged:nil];
	[self involvedInProcessChanged:nil];
	[self deviceSerialNumberChanged:nil];
}

- (void) deviceSerialNumberChanged:(NSNotification*)aNote
{
	[deviceSerialNumberField setIntValue: [model deviceSerialNumber]];
}

- (void) deviceHandleChanged:(NSNotification*)aNote
{
    if([model deviceOpen]){
        [probeButton setEnabled:NO];
        [openCloseButton setTitle:@"Close"];
    }
    else {
        [probeButton setEnabled:YES];
        [openCloseButton setTitle:@"Open"];
    }
    if([model deviceOpen]){
        [[self window] setTitle:[NSString stringWithFormat:@"LabJack U6 : 0x%x",[model deviceSerialNumber]]];
        [openCloseStatusField setStringValue:@"Open"];
    }
    
    else {
        [[self window] setTitle:@"LabJack U6"];
        [openCloseStatusField setStringValue:@"Closed"];
    }

}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:ioSize];     break;
		default: [self resizeWindowToSize:setupSize];	    break;
    }
    [[self window] setContentView:totalView];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORLabJac%d.selectedtab",[model uniqueIdNumber]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

- (void) involvedInProcessChanged:(NSNotification*)aNote
{
	[self lockChanged:nil];
}
- (void) enabledChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumU6AdcChannels;chan++){
        [[enabledMatrix cellWithTag:chan] setIntValue:[model enabled:chan]];
    }
}
- (void) counterEnabledChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<2;chan++){
        [[counterEnabledMatrix cellWithTag:chan] setIntValue:[model counterEnabled:chan]];
    }
    [self lockChanged:nil];
}
- (void) aOut1Changed:(NSNotification*)aNote
{
	[aOut1Field setFloatValue: [model aOut1] * 5.0/4095.];
	[aOut1Slider setFloatValue:[model aOut1] * 5.0/4095.];
}

- (void) aOut0Changed:(NSNotification*)aNote
{
	[aOut0Field setFloatValue: [model aOut0] * 5.0/4095.];
	[aOut0Slider setFloatValue:[model aOut0] * 5.0/4095.];
}

- (void) adcDiffChanged:(NSNotification*)aNotification
{
	int value = [model adcDiff];
	short i;
	for(i=0;i<kNumU6AdcChannels/2;i++){
		[[adcDiffMatrix cellWithTag:i] setState:(value & (1L<<i))>0];
	}
	[self adcChanged:nil];
    [self lockChanged:nil];
}

- (void) lowLimitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNumU6AdcChannels;i++){
			[[lowLimitMatrix cellWithTag:i] setFloatValue:[model lowLimit:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kNumU6AdcChannels){
			[[lowLimitMatrix cellWithTag:chan] setFloatValue:[model lowLimit:chan]];
		}
	}
}

- (void) hiLimitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNumU6AdcChannels;i++){
			[[hiLimitMatrix cellWithTag:i] setFloatValue:[model hiLimit:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kNumU6AdcChannels){
			[[hiLimitMatrix cellWithTag:chan] setFloatValue:[model hiLimit:chan]];
		}
	}
}

- (void) minValueChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNumU6AdcChannels;i++){
			[[minValueMatrix cellWithTag:i] setFloatValue:[model minValue:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kNumU6AdcChannels){
			[[minValueMatrix cellWithTag:chan] setFloatValue:[model minValue:chan]];
		}
	}
}

- (void) maxValueChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNumU6AdcChannels;i++){
			[[maxValueMatrix cellWithTag:i] setFloatValue:[model maxValue:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kNumU6AdcChannels){
			[[maxValueMatrix cellWithTag:chan] setFloatValue:[model maxValue:chan]];
		}
	}
}

- (void) slopeChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNumU6AdcChannels;i++){
			[[slopeMatrix cellWithTag:i] setFloatValue:[model slope:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kNumU6AdcChannels){
			[[slopeMatrix cellWithTag:chan] setFloatValue:[model slope:chan]];
		}
	}
}

- (void) interceptChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNumU6AdcChannels;i++){
			[[interceptMatrix cellWithTag:i] setFloatValue:[model intercept:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kNumU6AdcChannels){
			[[interceptMatrix cellWithTag:chan] setFloatValue:[model intercept:chan]];
		}
	}
}

- (void) shipDataChanged:(NSNotification*)aNote
{
	[shipDataCB setIntValue: [model shipData]];
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag: [model pollTime]];
}

- (void) digitalOutputEnabledChanged:(NSNotification*)aNote
{
	[digitalOutputEnabledButton setState: [model digitalOutputEnabled]];
}

- (void) counterChanged:(NSNotification*)aNote
{
    [[counterMatrix cellWithTag:0] setDoubleValue:(double)[model counter:0]];
    [[counterMatrix cellWithTag:1] setDoubleValue:(double)[model counter:1]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORLabJackU6Lock to:secure];
    [lockButton setEnabled:secure];
}

- (void) setDoEnabledState
{
	unsigned short aMask = [model doDirection];
	int i;
	for(i=0;i<kNumU6IOChannels;i++){
		[[doValueOutMatrix cellWithTag:i] setTransparent: (aMask & (1L<<i))!=0];
	}
	[doValueOutMatrix setNeedsDisplay:YES];
}

- (void) channelNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNumU6AdcChannels;i++){
            [[nameMatrix cellWithTag:i] setStringValue:[model channelName:i]];
            [[nameMatrix1 cellWithTag:i] setStringValue:[model channelName:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<kNumU6AdcChannels){
            [[nameMatrix cellWithTag:chan] setStringValue:[model channelName:chan]];
            [[nameMatrix1 cellWithTag:chan] setStringValue:[model channelName:chan]];
		}
	}
}

- (void) channelUnitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNumU6AdcChannels;i++){
			[[unitMatrix cellWithTag:i] setStringValue:[model channelUnit:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<kNumU6AdcChannels){
			[[unitMatrix cellWithTag:chan] setStringValue:[model channelUnit:chan]];
		}
	}
}

- (void) doDirectionChanged:(NSNotification*)aNotification
{
    //i/o on the connector
	uint32_t value = [model doDirection];
	short i;
	for(i=0;i<kNumU6IOChannels;i++){
		[[doDirectionMatrix cellWithTag:i] setState:(value & (1L<<i))>0];
	}
	[self setDoEnabledState];
	[self doValueInChanged:nil];
}

- (void) doValueOutChanged:(NSNotification*)aNotification
{
	uint32_t value = [model doValueOut];
	short i;
	for(i=0;i<kNumU6IOChannels;i++){
		[[doValueOutMatrix cellWithTag:i] setState:(value & (1L<<i))>0];
	}
}

- (void) doValueInChanged:(NSNotification*)aNotification
{
	short i;
	for(i=0;i<kNumU6IOChannels;i++){
		[[doValueInMatrix cellWithTag:i] setTextColor:[model doInColor:i]];
		[[doValueInMatrix cellWithTag:i] setStringValue:[model doInString:i]];
	}
}

- (void) adcChanged:(NSNotification*)aNotification
{
	unsigned short diffMask = [model adcDiff];
	if(!aNotification){
		int i;
		for(i=0;i<kNumU6AdcChannels;i++){
            if((i%2!=0) && (diffMask & (0x1<<i/2)))[[adcMatrix cellWithTag:i] setStringValue:@"----"];
            else [[adcMatrix cellWithTag:i] setDoubleValue:[model convertedValue:i]];
		}
	}
	else {
		int i = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(i<kNumU6AdcChannels){
            if((i%2!=0) && (diffMask & (0x1<<i/2)))[[adcMatrix cellWithTag:i] setStringValue:@"----"];
            else [[adcMatrix cellWithTag:i] setDoubleValue:[model convertedValue:i]];
		}
	}
}

- (void) adcRangeChanged:(NSNotification*)aNotification
{
    int chan;
    for(chan=0;chan<kNumU6AdcChannels;chan++){
        [[adcRangeMatrix cellAtRow:chan column:0] selectItemAtIndex:[model adcRange:chan]];
    }
}

- (void) doNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNumU6IOChannels;i++){
			[[doNameMatrix cellWithTag:i] setStringValue:[model doName:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		[[doNameMatrix cellWithTag:chan]   setStringValue:[model doName:chan]];
	}
}



#pragma mark •••Notifications

- (void) lockChanged:(NSNotification*)aNote
{
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORLabJackU6Lock];
    BOOL locked = [gSecurity isLocked:ORLabJackU6Lock];
	BOOL inProcess = [model involvedInProcess];
    [lockButton setState: locked];
	[nameMatrix			setEnabled:!locked];
	[unitMatrix			setEnabled:!locked];
	[doNameMatrix		setEnabled:!locked];
	[doDirectionMatrix	setEnabled:!locked && !inProcess];
	[doValueOutMatrix	setEnabled:!locked && !inProcess];
    [adcDiffMatrix		setEnabled:!locked && !inProcess];
	[digitalOutputEnabledButton		setEnabled:!locked && !inProcess];

    [resetCounter0Button setEnabled:!locked];
    [resetCounter1Button setEnabled:!locked];
	
	//int adcDiff = [model adcDiff];
	[pollTimePopup	setEnabled:!lockedOrRunningMaintenance && !inProcess];
	
	[aOut0Slider	setEnabled:!lockedOrRunningMaintenance];
	[aOut1Slider	setEnabled:!lockedOrRunningMaintenance];

	[aOut0Field		setEnabled:!lockedOrRunningMaintenance];
	[aOut1Field		setEnabled:!lockedOrRunningMaintenance];
    
    int value = [model adcDiff];
    short i;
    short j=0;
    for(i=1;i<kNumU6AdcChannels;i+=2){
        BOOL diff = value&(0x1<<j);
        [[adcRangeMatrix cellAtRow:i column:0] setEnabled:!diff & !lockedOrRunningMaintenance];
        j++;
    }
    for(i=0;i<kNumU6AdcChannels;i+=2){
        [[adcRangeMatrix cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance];
    }
    
    for(i=0;i<kNumU6IOChannels;i++){
        if(i==0 || i==1){
            if([model counterEnabled:i]){
                [[doDirectionMatrix cellAtRow:i column:0] setEnabled:NO];
                [[doValueOutMatrix cellAtRow:i  column:0] setEnabled:NO];
            }
            else {
                [[doDirectionMatrix cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance];
                [[doValueOutMatrix cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance];
            }
        }
        else {
            [[doDirectionMatrix cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance];
            [[doValueOutMatrix cellAtRow:i column:0] setEnabled:!lockedOrRunningMaintenance];
        }
    }

    
}

#pragma mark •••Actions
- (IBAction) probeAction:(id)sender
{
	[model readSerialNumbers];
}

- (IBAction) toggleOpenAction:(id)sender
{
    [self endEditing];
    [model toggleOpen];
}
- (IBAction) enabledAction:(id)sender
{
    [model setEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) counterEnabledAction:(id)sender
{
    [model setCounterEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) aOut1Action:(id)sender
{
	[model setAOut1:[sender floatValue] * 4095./5.];
}

- (IBAction) aOut0Action:(id)sender
{
	[model setAOut0:[sender floatValue]* 4095./5.];
}

- (IBAction) shipDataAction:(id)sender
{
	[model setShipData:[sender intValue]];	
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:(int)[[sender selectedItem] tag]];
}

- (void) digitalOutputEnabledAction:(id)sender
{
	[model setDigitalOutputEnabled:[sender state]];	
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORLabJackU6Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) serialNumberAction:(id)sender
{
    [model setDeviceSerialNumber:[deviceSerialNumberField intValue]];
}

- (IBAction) channelNameAction:(id)sender
{
	[model setChannel:(int)[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}

- (IBAction) channelUnitAction:(id)sender
{
	[model setChannel:(int)[[sender selectedCell] tag] unit:[[sender selectedCell] stringValue]];
}

- (IBAction) doNameAction:(id)sender
{
	[model setDo:(int)[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}

- (IBAction) updateAllAction:(id)sender
{
	[model queryAll];
}

- (IBAction) adcDiffBitAction:(id)sender
{
	[model setAdcDiffBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) doDirectionBitAction:(id)sender
{
	int theIndex = (int)[[sender selectedCell] tag];
	[model setDoDirectionBit:theIndex withValue:[sender intValue]];
}

- (IBAction) doValueOutBitAction:(id)sender
{
	int theIndex = (int)[[sender selectedCell] tag];
	[model setDoValueOutBit:theIndex withValue:[sender intValue]];
}

- (IBAction) resetCounter0:(id)sender
{
    [model resetCounter:0];
}
- (IBAction) resetCounter1:(id)sender
{
    [model resetCounter:1];
}

- (IBAction) lowLimitAction:(id)sender
{
	[model setLowLimit:(int)[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];
}

- (IBAction) hiLimitAction:(id)sender
{
	[model setHiLimit:(int)[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];
}

- (IBAction) minValueAction:(id)sender
{
	[model setMinValue:(int)[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];
}

- (IBAction) maxValueAction:(id)sender
{
	[model setMaxValue:(int)[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];
}

- (IBAction) adcRangeAction:(id)sender
{
    [model setAdcRange:(int)[sender selectedRow] withValue:(int)[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) slopeAction:(id)sender
{
	[model setSlope:(int)[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];
}

- (IBAction) interceptAction:(id)sender
{
	[model setIntercept:(int)[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];	
}

@end
