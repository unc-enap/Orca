//
//  ORHPLabJackUE9Controller.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 11,2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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

#import "ORLabJackUE9Controller.h"
#import "ORLabJackUE9Model.h"
#import "ORCardContainerView.h"

@implementation ORLabJackUE9Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"LabJackUE9" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
	[groupView setGroup:model];

	NSNumberFormatter *numberFormatter2 = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter2 setFormat:@"#0.00"];
	
	NSNumberFormatter *numberFormatter3 = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter3 setFormat:@"#0.000"];
	
	NSNumberFormatter *numberFormatter4 = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter4 setFormat:@"#0.0000"];

	//arggggg-- why oh why can't NSPopupButtons live in NSMatrixes
	gainPU[0] = gainPU0;
	gainPU[1] = gainPU1;
	gainPU[2] = gainPU2;
	gainPU[3] = gainPU3;
	gainPU[4] = gainPU4;
	gainPU[5] = gainPU5;
	gainPU[6] = gainPU6;
	gainPU[7] = gainPU7;
	gainPU[8] = gainPU8;
	gainPU[9] = gainPU9;
	gainPU[10] = gainPU10;
	gainPU[11] = gainPU11;
	gainPU[12] = gainPU12;
	gainPU[13] = gainPU13;
	
	bipolarPU[0] = bipolarPU0;
	bipolarPU[1] = bipolarPU1;
	bipolarPU[2] = bipolarPU2;
	bipolarPU[3] = bipolarPU3;
	bipolarPU[4] = bipolarPU4;
	bipolarPU[5] = bipolarPU5;
	bipolarPU[6] = bipolarPU6;
	bipolarPU[7] = bipolarPU7;
	bipolarPU[8] = bipolarPU8;
	bipolarPU[9] = bipolarPU9;
	bipolarPU[10] = bipolarPU10;
	bipolarPU[11] = bipolarPU11;
	bipolarPU[12] = bipolarPU12;
	bipolarPU[13] = bipolarPU13;	
	
	timerOptionPU[0] = timerOptionPU0;
	timerOptionPU[1] = timerOptionPU1;
	timerOptionPU[2] = timerOptionPU2;
	timerOptionPU[3] = timerOptionPU3;
	timerOptionPU[4] = timerOptionPU4;
	timerOptionPU[5] = timerOptionPU5;
	
	short i;
	for(i=0;i<14;i++){	
		[gainPU[i] setTag:i];
		[bipolarPU[i] setTag:i];
		[[unitMatrix cellAtRow:i column:0] setEditable:YES];
		[[nameMatrix cellAtRow:i column:0] setEditable:YES];
		
		[[nameMatrix cellAtRow:i column:0]		setTag:i];
		[[unitMatrix cellAtRow:i column:0]		setTag:i];
		[[adcMatrix cellAtRow:i column:0]		setTag:i];
		[[minValueMatrix cellAtRow:i column:0]	setTag:i];
		[[maxValueMatrix cellAtRow:i column:0]	setTag:i];
		[[slopeMatrix cellAtRow:i column:0]		setTag:i];
		[[interceptMatrix cellAtRow:i column:0] setTag:i];
		[[lowLimitMatrix cellAtRow:i column:0]	setTag:i];
		[[hiLimitMatrix cellAtRow:i column:0]	setTag:i];
		[[adcEnabledMatrix cellAtRow:i column:0] setTag:i];

		[[slopeMatrix cellAtRow:i column:0] setFormatter:numberFormatter4];
		[[interceptMatrix cellAtRow:i column:0] setFormatter:numberFormatter4];
		[[minValueMatrix cellAtRow:i column:0] setFormatter:numberFormatter2];
		[[maxValueMatrix cellAtRow:i column:0] setFormatter:numberFormatter2];
		[[lowLimitMatrix cellAtRow:i column:0] setFormatter:numberFormatter3];
		[[hiLimitMatrix cellAtRow:i column:0] setFormatter:numberFormatter3];
		[[adcMatrix cellAtRow:i column:0] setFormatter:numberFormatter4];
		[[name1Matrix cellAtRow:i column:0]		setStringValue:[NSString stringWithFormat:@"%d",i]];

		[gainPU[i] setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
		[bipolarPU[i] setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];

	}
	
	for(i=0;i<kUE9NumIO;i++){	
		[[doNameMatrix cellAtRow:i column:0] setTag:i];
		[[doDirectionMatrix cellAtRow:i column:0] setTag:i];
		[[doValueOutMatrix cellAtRow:i column:0] setTag:i];
		[[doValueInMatrix cellAtRow:i column:0] setTag:i];
	}
	
	for(i=0;i<kUE9NumTimers;i++){	
		[[timerInputLineMatrix cellAtRow:i column:0] setTag:i];
		[[timerEnableMaskMatrix cellAtRow:i column:0] setTag:i];
		[timerOptionPU[i] setTag:i];
		[[timerMatrix cellAtRow:i column:0] setTag:i];
		[[timerResultMatrix cellAtRow:i column:0] setTag:i];
	}
	
	for(i=0;i<2;i++){	
		[[counterEnableMatrix cellAtRow:i column:0] setTag:i];
		[[counterInputLineMatrix cellAtRow:i column:0] setTag:i];
	}
	
	
    blankView = [[NSView alloc] init];
    ioSize			= NSMakeSize(400,800);
    setupSize		= NSMakeSize(620,650);
    timersSize		= NSMakeSize(570,580);
    mux80Size		= NSMakeSize(400,440);
	
    NSString* key = [NSString stringWithFormat: @"orca.ORLabJackUE9%lu.selectedtab",[model uniqueIdNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	[super awakeFromNib];
}


- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
			
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORLabJackUE9Lock
						object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(channelNameChanged:)
                         name : ORLabJackUE9ChannelNameChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(channelUnitChanged:)
                         name : ORLabJackUE9ChannelUnitChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(adcChanged:)
                         name : ORLabJackUE9AdcChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(gainChanged:)
                         name : ORLabJackUE9GainChanged
						object: model];		

	[notifyCenter addObserver : self
                     selector : @selector(bipolarChanged:)
                         name : ORLabJackUE9BipolarChanged
						object: model];		
	
	[notifyCenter addObserver : self
                     selector : @selector(doNameChanged:)
                         name : ORLabJackUE9DoNameChanged
						object: model];
			
	[notifyCenter addObserver : self
                     selector : @selector(doDirectionChanged:)
                         name : ORLabJackUE9DoDirectionChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(doValueOutChanged:)
                         name : ORLabJackUE9DoValueOutChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(doValueInChanged:)
                         name : ORLabJackUE9DoValueInChanged
                       object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(counterChanged:)
                         name : ORLabJackUE9CounterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(digitalOutputEnabledChanged:)
                         name : ORLabJackUE9DigitalOutputEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORLabJackUE9PollTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(shipDataChanged:)
                         name : ORLabJackUE9ShipDataChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lowLimitChanged:)
                         name : ORLabJackUE9LowLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(hiLimitChanged:)
                         name : ORLabJackUE9HiLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(aOut0Changed:)
                         name : ORLabJackUE9ModelAOut0Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(aOut1Changed:)
                         name : ORLabJackUE9ModelAOut1Changed
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(slopeChanged:)
                         name : ORLabJackUE9SlopeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interceptChanged:)
                         name : ORLabJackUE9InterceptChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(involvedInProcessChanged:)
                         name : ORLabJackUE9ModelInvolvedInProcessChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(minValueChanged:)
                         name : ORLabJackUE9MinValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(maxValueChanged:)
                         name : ORLabJackUE9MaxValueChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORLabJackUE9IpAddressChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(isConnectedChanged:)
                         name : ORLabJackUE9IsConnectedChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(timerOptionChanged:)
                         name : ORLabJackUE9ModelTimerOptionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(timerEnableMaskChanged:)
                         name : ORLabJackUE9ModelTimerEnableMaskChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(clockSelectionChanged:)
                         name : ORLabJackUE9ModelClockSelectionChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(counterEnableMaskChanged:)
                         name : ORLabJackUE9ModelCounterEnableMaskChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(timerChanged:)
                         name : ORLabJackUE9TimerChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(timerResultChanged:)
                         name : ORLabJackUE9ModelTimerResultChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(clockDivisorChanged:)
                         name : ORLabJackUE9ModelClockDivisorChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(adcEnabledChanged:)
                         name : ORLabJackUE9ModelAdcEnableMaskChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(localIDChanged:)
                         name : ORLabJackUE9ModelLocalIDChanged
						object: model];

}


- (void) updateWindow
{
    [ super updateWindow ];
	[self ipAddressChanged:nil];
	[self isConnectedChanged:nil];
	[self channelNameChanged:nil];
	[self channelUnitChanged:nil];
	[self doNameChanged:nil];
	[self doDirectionChanged:nil];
	[self doValueOutChanged:nil];
	[self doValueInChanged:nil];
	[self adcChanged:nil];
	[self gainChanged:nil];
	[self bipolarChanged:nil];
    [self lockChanged:nil];
	[self counterChanged:nil];
	[self digitalOutputEnabledChanged:nil];
	[self pollTimeChanged:nil];
	[self shipDataChanged:nil];
	[self lowLimitChanged:nil];
	[self hiLimitChanged:nil];
	[self minValueChanged:nil];
	[self maxValueChanged:nil];
	[self aOut0Changed:nil];
	[self aOut1Changed:nil];
	[self slopeChanged:nil];
	[self interceptChanged:nil];
	[self involvedInProcessChanged:nil];
	[self timerOptionChanged:nil];
	[self timerEnableMaskChanged:nil];
	[self counterEnableMaskChanged:nil];
	[self clockSelectionChanged:nil];
	[self timerChanged:nil];
	[self timerResultChanged:nil];
	[self clockDivisorChanged:nil];
	[self adcEnabledChanged:nil];
    [groupView setNeedsDisplay:YES];
	[self localIDChanged:nil];
}

- (void) localIDChanged:(NSNotification*)aNote
{
	[localIDField setIntValue: [model localID]];
}

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[model setUpImage];
		[self updateWindow];
	}
}

- (ORCardContainerView *)groupView
{
    return [self groupView];
}

- (void) setModel:(OrcaObject*)aModel
{
    [super setModel:aModel];
    [groupView setGroup:(ORGroup*)model];
}

- (void) clockDivisorChanged:(NSNotification*)aNote
{
	[clockDivisorField setIntValue: [model clockDivisor]];
}

- (void) adcEnabledChanged:(NSNotification*)aNote
{
	unsigned long aMask = [model adcEnabledMask:0];
	int i;
	for(i=0;i<14;i++){
		[[adcEnabledMatrix cellWithTag:i] setIntValue:aMask& (1<<i)];
	}	
}


- (void) timerChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kUE9NumTimers;i++){
		[[timerMatrix cellWithTag:i] setIntValue:[model timer:i]];
	}
}

- (void) timerResultChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kUE9NumTimers;i++){
		[[timerResultMatrix cellWithTag:i] setStringValue:[NSString stringWithFormat:@"%lu",[model timerResult:i]]];
	}
}

- (void) clockSelectionChanged:(NSNotification*)aNote
{
	[clockSelectionMatrix selectCellWithTag:[model clockSelection]];
}

- (void) counterEnableMaskChanged:(NSNotification*)aNote
{
	unsigned long aMask = [model counterEnableMask];
	[[counterEnableMatrix cellWithTag:0] setIntValue: (aMask & (1L<<0))!=0];
	[[counterEnableMatrix cellWithTag:1] setIntValue: (aMask & (1L<<1))!=0];
	[self updateButtons];
}


- (void) timerEnableMaskChanged:(NSNotification*)aNote
{
	unsigned long aMask = [model timerEnableMask];
	int i;
	for(i=0;i<kUE9NumTimers;i++){
		[[timerEnableMaskMatrix cellWithTag:i] setIntValue: (aMask & (1L<<i))!=0];
	}
	[self updateButtons];
}

- (void) timerOptionChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kUE9NumTimers;i++){
		[timerOptionPU[i] selectItemAtIndex:[model timerOption:i]];
	}
}

- (void) isConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model isConnected]?@"Connected":@"Not Connected"];
	[ipConnectButton setTitle:[model isConnected]?@"Disconnect":@"Connect"];
    [self updateButtons];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
	switch([tabView indexOfTabViewItem:tabViewItem]){
		case  0: [self resizeWindowToSize:ioSize];     break;
		case  1: [self resizeWindowToSize:timersSize];     break;
		default: [self resizeWindowToSize:setupSize];	    break;
	}
    [[self window] setContentView:totalView];

    NSString* key = [NSString stringWithFormat: @"orca.ORLabJackUE9%lu.selectedtab",[model uniqueIdNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

- (void) involvedInProcessChanged:(NSNotification*)aNote
{
	[self lockChanged:nil];
}

- (void) aOut1Changed:(NSNotification*)aNote
{
	[aOut1Field setFloatValue: [model aOut1] * 4.86/4096];
	[aOut1Slider setFloatValue:[model aOut1] * 4.86/4096];
}

- (void) aOut0Changed:(NSNotification*)aNote
{
	[aOut0Field setFloatValue: [model aOut0] * 4.86/4096];
	[aOut0Slider setFloatValue:[model aOut0] * 4.86/4096];
}


- (void) lowLimitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			[[lowLimitMatrix cellWithTag:i] setFloatValue:[model lowLimit:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kUE9NumAdcs){
			[[lowLimitMatrix cellWithTag:chan] setFloatValue:[model lowLimit:chan]];
		}
	}
}

- (void) hiLimitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			[[hiLimitMatrix cellWithTag:i] setFloatValue:[model hiLimit:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kUE9NumAdcs){
			[[hiLimitMatrix cellWithTag:chan] setFloatValue:[model hiLimit:chan]];
		}
	}
}

- (void) minValueChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			[[minValueMatrix cellWithTag:i] setFloatValue:[model minValue:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kUE9NumAdcs){
			[[minValueMatrix cellWithTag:chan] setFloatValue:[model minValue:chan]];
		}
	}
}

- (void) maxValueChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			[[maxValueMatrix cellWithTag:i] setFloatValue:[model maxValue:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kUE9NumAdcs){
			[[maxValueMatrix cellWithTag:chan] setFloatValue:[model maxValue:chan]];
		}
	}
}

- (void) slopeChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			[[slopeMatrix cellWithTag:i] setFloatValue:[model slope:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kUE9NumAdcs){
			[[slopeMatrix cellWithTag:chan] setFloatValue:[model slope:chan]];
		}
	}
}

- (void) interceptChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			[[interceptMatrix cellWithTag:i] setFloatValue:[model intercept:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kUE9NumAdcs){
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
	[counter0Field setIntValue: [model counter:0]];
	[counter1Field setIntValue: [model counter:1]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORLabJackUE9Lock to:secure];
    [lockButton setEnabled:secure];
}

- (void) setDoEnabledState
{
	unsigned long aMask = [model doDirection];
	int i;
	for(i=0;i<kUE9NumIO;i++){
		[[doValueOutMatrix cellWithTag:i] setTransparent: (aMask & (1L<<i))!=0];
	}
	[doValueOutMatrix setNeedsDisplay:YES];
}

- (void) channelNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			[[nameMatrix cellWithTag:i] setStringValue:[model channelName:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<kUE9NumAdcs){
			[[nameMatrix cellWithTag:chan] setStringValue:[model channelName:chan]];
		}
	}
}

- (void) channelUnitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			[[unitMatrix cellWithTag:i] setStringValue:[model channelUnit:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<kUE9NumAdcs){
			[[unitMatrix cellWithTag:chan] setStringValue:[model channelUnit:chan]];
		}
	}
}

- (void) doDirectionChanged:(NSNotification*)aNotification
{
	int value = [model doDirection];
	short i;
	for(i=0;i<kUE9NumIO;i++){
		[[doDirectionMatrix cellWithTag:i] setState:(value & (1L<<i))>0];
	}
	[self setDoEnabledState];
	[self doValueInChanged:nil];
}

- (void) doValueOutChanged:(NSNotification*)aNotification
{
	int value = [model doValueOut];
	short i;
	for(i=0;i<kUE9NumIO;i++){
		[[doValueOutMatrix cellWithTag:i] setState:(value & (1L<<i))>0];
	}
}

- (void) doValueInChanged:(NSNotification*)aNotification
{
	short i;
	for(i=0;i<kUE9NumIO;i++){
		[[doValueInMatrix cellWithTag:i] setTextColor:[model doInColor:i]];
		[[doValueInMatrix cellWithTag:i] setStringValue:[model doInString:i]];
	}
}

- (void) adcChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			[[adcMatrix cellWithTag:i] setFloatValue:[model convertedValue:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<kUE9NumAdcs){
			[[adcMatrix cellWithTag:chan] setFloatValue:[model convertedValue:chan]];
		}
	}
}

- (void) gainChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			[gainPU[i] selectItemAtIndex:[model gain:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<kUE9NumAdcs){
			[gainPU[chan] selectItemAtIndex:[model gain:chan]];
		}
	}
}
- (void) bipolarChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			[bipolarPU[i] selectItemAtIndex:[model bipolar:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<kUE9NumAdcs){
			[bipolarPU[chan] selectItemAtIndex:[model bipolar:chan]];
		}
	}
	[self updateButtons];
}


- (void) doNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kUE9NumIO;i++){
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
    BOOL locked = [gSecurity isLocked:ORLabJackUE9Lock];
    [lockButton setState: locked];
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL locked    = [gSecurity isLocked:ORLabJackUE9Lock];
	BOOL inProcess = [model involvedInProcess];
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORLabJackUE9Lock];
	
	[nameMatrix			setEnabled:!locked];
	[unitMatrix			setEnabled:!locked];
	[doNameMatrix		setEnabled:!locked];
	[doDirectionMatrix	setEnabled:!locked && !inProcess];
	[doValueOutMatrix	setEnabled:!locked && !inProcess];
	[digitalOutputEnabledButton		setEnabled:!locked && !inProcess];
	
	[resetCounterButton setEnabled:!locked];
	
	[pollTimePopup		setEnabled:!lockedOrRunningMaintenance  && !inProcess];
	
	[aOut0Slider		setEnabled:!lockedOrRunningMaintenance];
	[aOut1Slider		setEnabled:!lockedOrRunningMaintenance];

	[aOut0Field			setEnabled:!lockedOrRunningMaintenance];
	[aOut1Field			setEnabled:!lockedOrRunningMaintenance];
	[initTimersButton	setEnabled:!lockedOrRunningMaintenance];
	[clockDivisorField	setEnabled:!lockedOrRunningMaintenance];
	[changeIPNumberButton setEnabled:!locked && [model isConnected]];
	[changeIDNumberButton setEnabled:!locked && [model isConnected]];
    
	int i;
	for(i=0;i<kUE9NumAdcs;i++){
		[bipolarPU[i] setEnabled:!locked];
		[gainPU[i] setEnabled:![model bipolar:i] && !locked];
	}
	int inputLine=0;
	for(i=0;i<kUE9NumTimers;i++){
		[timerOptionPU[i] setEnabled:([model timerEnableMask]&(0x1<<i)) && !locked];
		if([model timerEnableMask]&(0x1<<i)){
			[[timerInputLineMatrix cellWithTag:i] setStringValue:[NSString stringWithFormat:@"FIO%d",inputLine++]];
		}
		else [[timerInputLineMatrix cellWithTag:i] setStringValue:@"--"];
	}
	for(i=0;i<2;i++){
		if([model counterEnableMask]&(0x1<<i)){
			[[counterInputLineMatrix cellWithTag:i] setStringValue:[NSString stringWithFormat:@"FIO%d",inputLine++]];
		}
		else [[counterInputLineMatrix cellWithTag:i] setStringValue:@"--"];
	}

}

#pragma mark •••Actions

- (IBAction) changeLocalIDAction:(id)sender
{
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}
	[model changeLocalID:[newLocalIDField intValue]];
	[idChangePanel orderOut:nil];
	[NSApp endSheet:idChangePanel];	
}
- (IBAction) openIDChangePanel:(id)sender
{
	[self endEditing];
    [NSApp beginSheet:idChangePanel modalForWindow:[self window]
		modalDelegate:self didEndSelector:NULL contextInfo:nil];
	[newLocalIDField setIntValue:[model localID]];
}
- (IBAction) closeIDChangePanel:(id)sender
{
    [idChangePanel orderOut:nil];
    [NSApp endSheet:idChangePanel];
}
- (void) clockDivisorAction:(id)sender
{
	[model setClockDivisor:[sender intValue]];	
}

- (void) clockSelectionAction:(id)sender
{
	[model setClockSelection:[[sender selectedCell]tag]];	
}

- (void) timerEnableMaskAction:(id)sender
{
	int theIndex = [[sender selectedCell] tag];
	[model setTimerEnableBit:theIndex value:[sender intValue]];
	[self updateButtons];
}

- (void) counterEnableMaskAction:(id)sender
{
	int theIndex = [[sender selectedCell] tag];
	[model setCounterEnableBit:theIndex value:[sender intValue]];
	[self updateButtons];
}

- (void) timerOptionAction:(id)sender
{
	int timerIndex = [sender tag];
	[model setTimer:timerIndex option:[sender indexOfSelectedItem]];
}

- (IBAction) ipAddressAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) connectAction:(id)sender
{
	[self endEditing];
	[model connect];
}

- (IBAction) aOut1Action:(id)sender
{
	[model setAOut1:[sender floatValue] * 4095/4.86];	
	[model pollHardware:YES];
}

- (IBAction) aOut0Action:(id)sender
{
	[model setAOut0:[sender floatValue]* 4095/4.86];	
	[model pollHardware:YES];
}

- (IBAction) shipDataAction:(id)sender
{
	[model setShipData:[sender intValue]];	
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];	
}

- (void) digitalOutputEnabledAction:(id)sender
{
	[model setDigitalOutputEnabled:[sender state]];	
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORLabJackUE9Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) channelNameAction:(id)sender
{
	[model setChannel:[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}

- (IBAction) channelUnitAction:(id)sender
{
	[model setChannel:[[sender selectedCell] tag] unit:[[sender selectedCell] stringValue]];
}

- (IBAction) doNameAction:(id)sender
{
	[model setDo:[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}

- (IBAction) updateAllAction:(id)sender
{
	[model queryAll];
}

- (IBAction) doDirectionBitAction:(id)sender
{
	int theIndex = [[sender selectedCell] tag];
	[model setDoDirectionBit:theIndex value:[sender intValue]];
}

- (IBAction) doValueOutBitAction:(id)sender
{
	int theIndex = [[sender selectedCell] tag];
	[model setDoValueOutBit:theIndex value:[sender intValue]];
	[model readAllValues];
}

- (IBAction) resetCounter:(id)sender
{
	[model resetCounter];
}

- (IBAction) lowLimitAction:(id)sender
{
	[model setLowLimit:[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];	
}

- (IBAction) hiLimitAction:(id)sender
{
	[model setHiLimit:[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];	
}

- (IBAction) minValueAction:(id)sender
{
	[model setMinValue:[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];	
}

- (IBAction) maxValueAction:(id)sender
{
	[model setMaxValue:[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];	
}

- (IBAction) gainAction:(id)sender
{
	[model setGain:[sender tag] value:[sender indexOfSelectedItem]];
}

- (IBAction) bipolarAction:(id)sender
{
	[model setBipolar:[sender tag] value:[sender indexOfSelectedItem]];
}

- (IBAction) slopeAction:(id)sender
{
	[model setSlope:[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];	
}

- (IBAction) interceptAction:(id)sender
{
	[model setIntercept:[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];	
}

- (IBAction) testAction:(id)sender
{
	[model readAllValues];
}

- (IBAction) initTimersAction:(id)sender
{
	[model sendTimerCounter:kUE9UpdateCounters];
}

- (IBAction) timerAction:(id)sender
{
	[self endEditing];
	[model setTimer:[[sender selectedCell] tag] value:[sender intValue]];
}

- (IBAction) changeIPNumber:(id)sender
{
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}
	[model changeIPAddress:[newIpAddressField stringValue]];
    [ipChangePanel orderOut:nil];
    [NSApp endSheet:ipChangePanel];
}

- (IBAction) openIPChangePanel:(id)sender
{
	[self endEditing];
    [NSApp beginSheet:ipChangePanel modalForWindow:[self window]
		modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (IBAction) closeIPChangePanel:(id)sender
{
    [ipChangePanel orderOut:nil];
    [NSApp endSheet:ipChangePanel];
}

- (IBAction) adcEnabledAction:(id)sender
{
	int theBit = [[sender selectedCell] tag];
	[model setAdcEnabled:theBit value:[sender intValue]];

}
- (IBAction) printChannelLocations:(id)sender
{
    [model printChannelLocations];
}


@end
