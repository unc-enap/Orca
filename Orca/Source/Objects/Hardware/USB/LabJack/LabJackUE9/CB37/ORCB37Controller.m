//
//  ORHPCB37Controller.m
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

#import "ORCB37Controller.h"
#import "ORCB37Model.h"
#import "ORLabJackUE9Model.h"

@implementation ORCB37Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"CB37" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
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
	gainPU[14] = gainPU14;
	gainPU[15] = gainPU15;
	gainPU[16] = gainPU16;
	gainPU[17] = gainPU17;
	gainPU[18] = gainPU18;
	gainPU[19] = gainPU19;
	gainPU[20] = gainPU20;
	gainPU[21] = gainPU21;
	gainPU[22] = gainPU22;
	gainPU[23] = gainPU23;
	
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
	bipolarPU[14] = bipolarPU14;
	bipolarPU[15] = bipolarPU15;
	bipolarPU[16] = bipolarPU16;
	bipolarPU[17] = bipolarPU17;
	bipolarPU[18] = bipolarPU18;
	bipolarPU[19] = bipolarPU19;
	bipolarPU[20] = bipolarPU20;
	bipolarPU[21] = bipolarPU21;
	bipolarPU[22] = bipolarPU22;
	bipolarPU[23] = bipolarPU23;
	
	short i;
	for(i=0;i<kCB37NumAdcs;i++){	
		[gainPU[i] setTag:i];
		[bipolarPU[i] setTag:i];
		[[unitMatrix cellAtRow:i column:0] setEditable:YES];
		[[nameMatrix cellAtRow:i column:0] setEditable:YES];
		
		[[adcEnabledMatrix cellAtRow:i column:0]setTag:i];
		[[nameMatrix cellAtRow:i column:0]		setTag:i];
		[[unitMatrix cellAtRow:i column:0]		setTag:i];
		[[adcMatrix cellAtRow:i column:0]		setTag:i];
		[[minValueMatrix cellAtRow:i column:0]	setTag:i];
		[[maxValueMatrix cellAtRow:i column:0]	setTag:i];
		[[slopeMatrix cellAtRow:i column:0]		setTag:i];
		[[interceptMatrix cellAtRow:i column:0] setTag:i];
		[[lowLimitMatrix cellAtRow:i column:0]	setTag:i];
		[[hiLimitMatrix cellAtRow:i column:0]	setTag:i];

		[[slopeMatrix cellAtRow:i column:0]		setFormatter:numberFormatter4];
		[[interceptMatrix cellAtRow:i column:0] setFormatter:numberFormatter4];
		[[minValueMatrix cellAtRow:i column:0]	setFormatter:numberFormatter2];
		[[maxValueMatrix cellAtRow:i column:0]	setFormatter:numberFormatter2];
		[[lowLimitMatrix cellAtRow:i column:0]	setFormatter:numberFormatter3];
		[[hiLimitMatrix cellAtRow:i column:0]	setFormatter:numberFormatter3];
		[[adcMatrix cellAtRow:i column:0]		setFormatter:numberFormatter4];
		int adcChan = [self tagToAdcIndex:i];
		[[name1Matrix cellAtRow:i column:0]		setStringValue:[NSString stringWithFormat:@"%d",adcChan]];

		[gainPU[i] setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
		[bipolarPU[i] setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
		[[adcMatrix cellAtRow:i column:0]		setTag:i];

	}
		
	
	
    blankView = [[NSView alloc] init];
    ioSize			= NSMakeSize(300,500);
    setupSize		= NSMakeSize(700,700);
	
    NSString* key = [NSString stringWithFormat: @"orca.ORCB37%lu.selectedtab",[model uniqueIdNumber]];
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
                     selector : @selector(channelNameChanged:)
                         name : ORLabJackUE9ChannelNameChanged
						object: [model guardian]];	
	
	[notifyCenter addObserver : self
                     selector : @selector(channelUnitChanged:)
                         name : ORLabJackUE9ChannelUnitChanged
						object: [model guardian]];	
	
	[notifyCenter addObserver : self
                     selector : @selector(adcChanged:)
                         name : ORLabJackUE9AdcChanged
						object: [model guardian]];	
	
	[notifyCenter addObserver : self
                     selector : @selector(lowLimitChanged:)
                         name : ORLabJackUE9LowLimitChanged
						object: [model guardian]];
	
    [notifyCenter addObserver : self
                     selector : @selector(hiLimitChanged:)
                         name : ORLabJackUE9HiLimitChanged
						object: [model guardian]];
	
	[notifyCenter addObserver : self
                     selector : @selector(slopeChanged:)
                         name : ORLabJackUE9SlopeChanged
						object: [model guardian]];
	
    [notifyCenter addObserver : self
                     selector : @selector(interceptChanged:)
                         name : ORLabJackUE9InterceptChanged
						object: [model guardian]];
	
    [notifyCenter addObserver : self
                     selector : @selector(minValueChanged:)
                         name : ORLabJackUE9MinValueChanged
						object: [model guardian]];
	
    [notifyCenter addObserver : self
                     selector : @selector(maxValueChanged:)
                         name : ORLabJackUE9MaxValueChanged
						object: [model guardian]];

	[notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORCB37SlotChangedNotification
                        object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(gainChanged:)
                         name : ORLabJackUE9GainChanged
						object: [model guardian]];		
	
	[notifyCenter addObserver : self
                     selector : @selector(bipolarChanged:)
                         name : ORLabJackUE9BipolarChanged
						object: [model guardian]];		
	
	[notifyCenter addObserver : self
                     selector : @selector(adcEnabledChanged:)
                         name : ORLabJackUE9ModelAdcEnableMaskChanged
                       object : [model guardian]];
}


- (void) updateWindow
{
	[ super updateWindow ];
	[self channelNameChanged:nil];
	[self channelUnitChanged:nil];
	[self adcChanged:nil];
    [self lockChanged:nil];
	[self lowLimitChanged:nil];
	[self hiLimitChanged:nil];
	[self minValueChanged:nil];
	[self maxValueChanged:nil];
	[self slopeChanged:nil];
	[self interceptChanged:nil];
	[self gainChanged:nil];
	[self bipolarChanged:nil];
	[self adcEnabledChanged:nil];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"CB37 (Slot X%d)",[model slot]+2]];
    [slotField setStringValue: [NSString stringWithFormat:@"X%d",[model slot]+2]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setStringValue: [NSString stringWithFormat:@"X%d",[model slot]+2]];
    [[self window] setTitle:[NSString stringWithFormat:@"CB37 (Slot X%d)",[model slot]+2]];
	[self updateWindow];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
	NSSize newSize;
	switch([tabView indexOfTabViewItem:tabViewItem]){
		case  0: newSize = ioSize;      break;
		default: newSize = setupSize;	break;
	}	
	[self resizeWindowToSize:newSize];
    [[self window] setContentView:totalView];
    NSString* key = [NSString stringWithFormat: @"orca.ORCB37%lu.selectedtab",[[model guardian] uniqueIdNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

- (void) adcEnabledChanged:(NSNotification*)aNote
{
	int startChan = [self startChannel];
	int i;
	for(i=0;i<kCB37NumAdcs;i++){
		int adcChan = i + startChan;
		[[adcEnabledMatrix cellWithTag:i] setIntValue:[[model guardian] adcEnabled:adcChan]];
	}	
}

- (void) gainChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int startChan = [self startChannel];
		int i;
		for(i=0;i<kCB37NumAdcs;i++){
			int adcChan = i + startChan;
			[gainPU[i] selectItemAtIndex:[[model guardian] gain:adcChan]];
		}
	}
	else {
		int adcChan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		int displayChan = [self displayChanFromAdcChan:adcChan];
		if(displayChan>=0 && displayChan < kCB37NumAdcs){
			[gainPU[displayChan] selectItemAtIndex:[[model guardian] gain:adcChan]];
		}
	}
}
- (void) bipolarChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int startChan = [self startChannel];
		int i;
		for(i=0;i<kCB37NumAdcs;i++){
			int adcChan = i + startChan;
			[bipolarPU[i] selectItemAtIndex:[[model guardian] bipolar:adcChan]];
		}
	}
	else {
		int adcChan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		int displayChan = [self displayChanFromAdcChan:adcChan];
		if(displayChan>=0 && displayChan < kCB37NumAdcs){
			[bipolarPU[displayChan] selectItemAtIndex:[[model guardian] bipolar:adcChan]];
		}
	}
	[self updateButtons];
}

- (void) involvedInProcessChanged:(NSNotification*)aNote
{
	[self lockChanged:nil];
}

- (void) lowLimitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		int startChan = [self startChannel];
		for(i=0;i<kCB37NumAdcs;i++){
			int adcChan = i + startChan;
			[[lowLimitMatrix cellWithTag:i] setFloatValue:[[model guardian] lowLimit:adcChan]];
		}
	}
	else {
		int adcChan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		int displayChan = [self displayChanFromAdcChan:adcChan];
		if(displayChan>=0 && displayChan < kCB37NumAdcs){
			[[lowLimitMatrix cellWithTag:displayChan] setFloatValue:[[model guardian] lowLimit:adcChan]];
		}
	}
}

- (void) hiLimitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		int startChan = [self startChannel];
		for(i=0;i<kCB37NumAdcs;i++){
			int adcChan = i + startChan;
			[[hiLimitMatrix cellWithTag:i] setFloatValue:[[model guardian] hiLimit:adcChan]];
		}
	}
	else {
		int adcChan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		int displayChan = [self displayChanFromAdcChan:adcChan];
		if(displayChan>=0 && displayChan < kCB37NumAdcs){
			[[hiLimitMatrix cellWithTag:displayChan] setFloatValue:[[model guardian] hiLimit:adcChan]];
		}
	}
}

- (void) minValueChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		int startChan = [self startChannel];
		for(i=0;i<kCB37NumAdcs;i++){
			int adcChan = i + startChan;
			[[minValueMatrix cellWithTag:i] setFloatValue:[[model guardian] minValue:adcChan]];
		}
	}
	else {
		int adcChan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		int displayChan = [self displayChanFromAdcChan:adcChan];
		if(displayChan>=0 && displayChan < kCB37NumAdcs){
			[[minValueMatrix cellWithTag:displayChan] setFloatValue:[[model guardian] minValue:adcChan]];
		}
	}
}

- (void) maxValueChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		int startChan = [self startChannel];
		for(i=0;i<kCB37NumAdcs;i++){
			int adcChan = i + startChan;
			[[maxValueMatrix cellWithTag:i] setFloatValue:[[model guardian] maxValue:adcChan]];
		}
	}
	else {
		int adcChan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		int displayChan = [self displayChanFromAdcChan:adcChan];
		if(displayChan>=0 && displayChan < kCB37NumAdcs){
			[[maxValueMatrix cellWithTag:displayChan] setFloatValue:[[model guardian] maxValue:adcChan]];
		}
	}
}

- (void) slopeChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		int startChan = [self startChannel];
		for(i=0;i<kCB37NumAdcs;i++){
			int adcChan = i + startChan;
			[[slopeMatrix cellWithTag:i] setFloatValue:[[model guardian] slope:adcChan]];
		}
	}
	else {
		int adcChan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		int displayChan = [self displayChanFromAdcChan:adcChan];
		if(displayChan>=0 && displayChan < kCB37NumAdcs){
			[[slopeMatrix cellWithTag:displayChan] setFloatValue:[[model guardian] slope:adcChan]];
		}
	}
}

- (void) interceptChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		int startChan = [self startChannel];
		for(i=0;i<kCB37NumAdcs;i++){
			int adcChan = i + startChan;
			[[interceptMatrix cellWithTag:i] setFloatValue:[[model guardian] intercept:adcChan]];
		}
	}
	else {
		int adcChan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		int displayChan = [self displayChanFromAdcChan:adcChan];
		if(displayChan>=0 && displayChan < kCB37NumAdcs){
			[[interceptMatrix cellWithTag:displayChan] setFloatValue:[[model guardian] intercept:adcChan]];
		}
	}
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORCB37Lock to:secure];
    [lockButton setEnabled:secure];
}

- (void) channelNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		int startChan = [self startChannel];
		for(i=0;i<kCB37NumAdcs;i++){
			int adcChan = i + startChan;
			[[nameMatrix cellWithTag:i] setStringValue:[[model guardian] channelName:adcChan]];
		}
	}
	else {
		int adcChan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		int displayChan = [self displayChanFromAdcChan:adcChan];
		if(displayChan>=0 && displayChan < kCB37NumAdcs){
			[[nameMatrix cellWithTag:displayChan] setStringValue:[[model guardian] channelName:adcChan]];
		}
	}
}

- (void) channelUnitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		int startChan = [self startChannel];
		for(i=0;i<kCB37NumAdcs;i++){
			int adcChan = i + startChan;
			[[unitMatrix cellWithTag:i] setStringValue:[[model guardian] channelUnit:adcChan]];
		}
	}
	else {
		int adcChan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		int displayChan = [self displayChanFromAdcChan:adcChan];
		if(displayChan>=0 && displayChan < kCB37NumAdcs){
			[[unitMatrix cellWithTag:displayChan] setStringValue:[[model guardian] channelUnit:adcChan]];
		}
	}
}

- (void) adcChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		int startChan = [self startChannel];
		for(i=0;i<kCB37NumAdcs;i++){
			int adcChan = i + startChan;
			[[adcMatrix cellWithTag:i] setFloatValue:[[model guardian] convertedValue:adcChan]];
		}
	}
	else {
		int adcChan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		int displayChan = [self displayChanFromAdcChan:adcChan];
		if(displayChan>=0 && displayChan < kCB37NumAdcs){
			[[adcMatrix cellWithTag:displayChan] setFloatValue:[[model guardian] convertedValue:adcChan]];
		}
	}
}
- (int) startChannel
{
	int slot = [model slot];
	switch(slot){
		case 0: return 0;
		case 1: return 12;
		case 2: return 36;
		case 3: return 60;
		default: return 0;
	}
}

- (int)  displayChanFromAdcChan:(int)adcChan
{
	if([self legalAdcRange:adcChan]){
		int slot = [model slot];
		switch(slot){
			case 0: return adcChan;
			case 1: return adcChan - 12;
			case 2: return adcChan - 36;
			case 3: return adcChan - 60;
			default: return 0;
		}
	}
	else return -1;
}

- (BOOL) legalAdcRange:(int)adcChan
{
	int slot = [model slot];
	switch(slot){
		case 0:  return (adcChan>=0 && adcChan<=24);
		case 1:  return (adcChan>=12 && adcChan<=35);
		case 2:  return (adcChan>=36 && adcChan<=59);
		case 3:  return (adcChan>=60 && adcChan<=83);
		default: return NO;
	}
}

#pragma mark •••Notifications
- (void) lockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORCB37Lock];
    [lockButton setState: locked];
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL locked = [gSecurity isLocked:ORCB37Lock];
	[nameMatrix	setEnabled:!locked];
	[unitMatrix	setEnabled:!locked];
	int i;
	for(i=0;i<kCB37NumAdcs;i++){
		int adcChan = [self tagToAdcIndex:i];	
		[bipolarPU[i] setEnabled:!locked];
		[gainPU[i] setEnabled:![[model guardian] bipolar:adcChan] && !locked];
	}
}

#pragma mark •••Actions
- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORCB37Lock to:[sender intValue] forWindow:[self window]];
}

- (int) tagToAdcIndex:(int)aTag
{
	switch([model slot]){
		case 0: return aTag;
		default: return aTag + [self startChannel];
	}
}

- (IBAction) channelNameAction:(id)sender
{
	int adcChan = [self tagToAdcIndex:[[sender selectedCell] tag]];	
	[[model guardian] setChannel:adcChan name:[[sender selectedCell] stringValue]];
}

- (IBAction) channelUnitAction:(id)sender
{
	int adcChan = [self tagToAdcIndex:[[sender selectedCell] tag]];
	[[model guardian] setChannel:adcChan unit:[[sender selectedCell] stringValue]];
}

- (IBAction) lowLimitAction:(id)sender
{
	int adcChan = [self tagToAdcIndex:[[sender selectedCell] tag]];
	[[model guardian] setLowLimit:adcChan value:[[sender selectedCell] floatValue]];	
}

- (IBAction) hiLimitAction:(id)sender
{
	int adcChan = [self tagToAdcIndex:[[sender selectedCell] tag]];
	[[model guardian] setHiLimit:adcChan value:[[sender selectedCell] floatValue]];	
}

- (IBAction) minValueAction:(id)sender
{
	int adcChan = [self tagToAdcIndex:[[sender selectedCell] tag]];
	[[model guardian] setMinValue:adcChan value:[[sender selectedCell] floatValue]];	
}

- (IBAction) maxValueAction:(id)sender
{
	int adcChan = [self tagToAdcIndex:[[sender selectedCell] tag]];
	[[model guardian] setMaxValue:adcChan value:[[sender selectedCell] floatValue]];	
}

- (IBAction) slopeAction:(id)sender
{
	int adcChan = [self tagToAdcIndex:[[sender selectedCell] tag]];
	[[model guardian] setSlope:adcChan value:[[sender selectedCell] floatValue]];	
}

- (IBAction) interceptAction:(id)sender
{
	int adcChan = [self tagToAdcIndex:[[sender selectedCell] tag]];
	[[model guardian] setIntercept:adcChan value:[[sender selectedCell] floatValue]];	
}

- (IBAction) showLabJackUE9:(id)sender
{
	[[model guardian] makeMainController];
}

- (IBAction) gainAction:(id)sender
{
	int adcChan = [self tagToAdcIndex:[sender tag]];
	[[model guardian] setGain:adcChan value:[sender indexOfSelectedItem]];
}

- (IBAction) bipolarAction:(id)sender
{
	int adcChan = [self tagToAdcIndex:[sender tag]];
	[[model guardian] setBipolar:adcChan value:[sender indexOfSelectedItem]];
}

- (IBAction) adcEnabledAction:(id)sender
{
	int adcChan = [self tagToAdcIndex:[[sender selectedCell] tag]];
	[[model guardian] setAdcEnabled:adcChan value:[sender intValue]];
	
}

- (IBAction) printChannelLocations:(id)sender
{
    [model printChannelLocations];
}
@end
