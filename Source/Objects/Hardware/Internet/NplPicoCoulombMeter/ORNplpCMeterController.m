//
//  ORHPNplpCMeterController.m
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORNplpCMeterController.h"
#import "ORNplpCMeterModel.h"

@implementation ORNplpCMeterController
- (id) init
{
    self = [ super initWithWindowNibName: @"NplpCMeter" ];
    return self;
}
- (void) dealloc
{
    [blankView release];
    [super dealloc];
}
- (void) awakeFromNib
{
	NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
	[formatter setFormat:@"#0.000"];
	int i;
	for(i=0;i<kNplpCNumChannels;i++){
		[[minValueMatrix cellAtRow:i column:0]	setTag:i];
		[[maxValueMatrix cellAtRow:i column:0]	setTag:i];
		[[lowLimitMatrix cellAtRow:i column:0]	setTag:i];
		[[hiLimitMatrix cellAtRow:i column:0]	setTag:i];
		
		[[minValueMatrix cellAtRow:i column:0] setFormatter:formatter];
		[[maxValueMatrix cellAtRow:i column:0] setFormatter:formatter];
		[[lowLimitMatrix cellAtRow:i column:0] setFormatter:formatter];
		[[hiLimitMatrix cellAtRow:i column:0] setFormatter:formatter];
	}
    
    blankView           = [[NSView alloc] init];
    ipConnectionSize	= NSMakeSize(315,255);
    statusSize          = NSMakeSize(270,240);
    processSize         = NSMakeSize(315,240);
	
	NSString* key = [NSString stringWithFormat: @"orca.ORNplpCMeter%u.selectedtab",[model uniqueIdNumber]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
	if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
	[tabView selectTabViewItemAtIndex: index];
	
 	[super awakeFromNib];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORNplpCMeterIpAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isConnectedChanged:)
                         name : ORNplpCMeterIsConnectedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(frameErrorChanged:)
                         name : ORNplpCMeterFrameError
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(averageChanged:)
                         name : ORNplpCMeterAverageChanged
						object: model];
						
    [notifyCenter addObserver : self
                     selector : @selector(receiveCountChanged:)
                         name : ORNplpCMeterReceiveCountChanged
						object: model];


    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORNplpCMeterLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(minValueChanged:)
                         name : ORNplpCMeterMinValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(maxValueChanged:)
                         name : ORNplpCMeterMaxValueChanged
						object: model];
    
	[notifyCenter addObserver : self
                     selector : @selector(lowLimitChanged:)
                         name : ORNplpCMeterLowLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(hiLimitChanged:)
                         name : ORNplpCMeterHiLimitChanged
						object: model];

}


- (void) updateWindow
{
    [ super updateWindow ];
    
    [self settingsLockChanged:nil];
	[self ipAddressChanged:nil];
	[self isConnectedChanged:nil];
	[self frameErrorChanged:nil];
	[self averageChanged:nil];
	[self receiveCountChanged:nil];
	[self lowLimitChanged:nil];
	[self hiLimitChanged:nil];
	[self minValueChanged:nil];
	[self maxValueChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORNplpCMeterLock to:secure];
    [dialogLock setEnabled:secure];
}

#pragma mark •••Notifications
- (void) receiveCountChanged:(NSNotification*)aNote
{
	[receiveCountField setIntValue: [model receiveCount]];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
	NSUInteger style = [[self window] styleMask];
	switch([tabView indexOfTabViewItem:tabViewItem]){
		case  0:
			[self resizeWindowToSize:ipConnectionSize];
			[[self window] setStyleMask: style & ~NSWindowStyleMaskResizable];
			break;
		case  1:
			[self resizeWindowToSize:statusSize];
			[[self window] setStyleMask: style & ~NSWindowStyleMaskResizable];
			break;
		default:
			[self resizeWindowToSize:processSize];
			[[self window] setStyleMask: style | NSWindowStyleMaskResizable];
			break;
	}
    [[self window] setContentView:totalView];
	
	NSString* key = [NSString stringWithFormat: @"orca.ORNplpCMeter%u.selectedtab",[model uniqueIdNumber]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
}

- (void) isConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model isConnected]?@"Connected":@"Not Connected"];
	[ipConnected2TextField setStringValue: [model isConnected]?@"Connected":@"Not Connected"];
	[ipConnectButton setTitle:[model isConnected]?@"Disconnect":@"Connect"];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

- (void) frameErrorChanged:(NSNotification*)aNote
{
	[frameErrorField setIntValue: [model frameError]];
}

- (void) averageChanged:(NSNotification*)aNote
{
	if(!aNote){
		int chan;
		for(chan=0;chan<kNplpCNumChannels;chan++){
			[[averageValueMatrix cellWithTag:chan] setFloatValue:0];
		}
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[averageValueMatrix cellWithTag:chan] setFloatValue:12*[model meterAverage:chan]/1048576.0]; //12 pC/20bits full scale
	}
}
- (void) lowLimitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNplpCNumChannels;i++){
			[[lowLimitMatrix cellWithTag:i] setFloatValue:[model lowLimit:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kNplpCNumChannels){
			[[lowLimitMatrix cellWithTag:chan] setFloatValue:[model lowLimit:chan]];
		}
	}
}

- (void) hiLimitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNplpCNumChannels;i++){
			[[hiLimitMatrix cellWithTag:i] setFloatValue:[model hiLimit:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kNplpCNumChannels){
			[[hiLimitMatrix cellWithTag:chan] setFloatValue:[model hiLimit:chan]];
		}
	}
}

- (void) minValueChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNplpCNumChannels;i++){
			[[minValueMatrix cellWithTag:i] setFloatValue:[model minValue:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kNplpCNumChannels){
			[[minValueMatrix cellWithTag:chan] setFloatValue:[model minValue:chan]];
		}
	}
}

- (void) maxValueChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<kNplpCNumChannels;i++){
			[[maxValueMatrix cellWithTag:i] setFloatValue:[model maxValue:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<kNplpCNumChannels){
			[[maxValueMatrix cellWithTag:chan] setFloatValue:[model maxValue:chan]];
		}
	}
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL locked			= [gSecurity isLocked:ORNplpCMeterLock];

	//[ipConnectButton setEnabled:!locked]; //as per Florian's request 3/19/2013
	[ipAddressTextField setEnabled:!locked];
    [lowLimitMatrix setEnabled:!locked];
    [hiLimitMatrix setEnabled:!locked];
    [minValueMatrix setEnabled:!locked];
    [maxValueMatrix setEnabled:!locked];
    [dialogLock setState: locked];

 }

#pragma mark •••Actions
- (IBAction) ipAddressTextFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) connectAction:(id)sender
{
	[self endEditing];
	[model setFrameError:0];
	[model connect];
}

- (IBAction) dialogLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORNplpCMeterLock to:[sender intValue] forWindow:[self window]];
}
- (IBAction) lowLimitAction:(id)sender
{
	[model setLowLimit:(int)[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];
}

- (IBAction) hiLimitAction:(id)sender
{
	[model setHiLimit:(int)[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];
}

- (IBAction) minValueAction:(id)sender
{
	[model setMinValue:(int)[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];
}

- (IBAction) maxValueAction:(id)sender
{
	[model setMaxValue:(int)[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];
}

@end
