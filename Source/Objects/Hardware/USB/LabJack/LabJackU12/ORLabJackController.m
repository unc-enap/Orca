//
//  ORHPLabJackController.m
//  Orca
//
//  Created by Mark Howe on Wed Feb 18, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

#import "ORLabJackController.h"
#import "ORLabJackModel.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"

@implementation ORLabJackController
- (id) init
{
    self = [ super initWithWindowNibName: @"LabJack" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
    [super dealloc];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceAdded
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceRemoved
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORLabJackSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORLabJackUSBInterfaceChanged
						object: nil];
		
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORLabJackLock
						object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(channelNameChanged:)
                         name : ORLabJackChannelNameChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(channelUnitChanged:)
                         name : ORLabJackChannelUnitChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(adcChanged:)
                         name : ORLabJackAdcChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(gainChanged:)
                         name : ORLabJackGainChanged
						object: model];		
	
	[notifyCenter addObserver : self
                     selector : @selector(doNameChanged:)
                         name : ORLabJackDoNameChanged
						object: model];
		
	[notifyCenter addObserver : self
                     selector : @selector(ioNameChanged:)
                         name : ORLabJackIoNameChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(doDirectionChanged:)
                         name : ORLabJackDoDirectionChanged
                       object : model];

	[notifyCenter addObserver : self
                     selector : @selector(ioDirectionChanged:)
                         name : ORLabJackIoDirectionChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(doValueOutChanged:)
                         name : ORLabJackDoValueOutChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(ioValueOutChanged:)
                         name : ORLabJackIoValueOutChanged
                       object : model];

	[notifyCenter addObserver : self
                     selector : @selector(doValueInChanged:)
                         name : ORLabJackDoValueInChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(ioValueInChanged:)
                         name : ORLabJackIoValueInChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(counterChanged:)
                         name : ORLabJackCounterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(digitalOutputEnabledChanged:)
                         name : ORLabJackDigitalOutputEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORLabJackPollTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(shipDataChanged:)
                         name : ORLabJackShipDataChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lowLimitChanged:)
                         name : ORLabJackLowLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(hiLimitChanged:)
                         name : ORLabJackHiLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(adcDiffChanged:)
                         name : ORLabJackAdcDiffChanged
						object: model];	
    [notifyCenter addObserver : self
                     selector : @selector(aOut0Changed:)
                         name : ORLabJackModelAOut0Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(aOut1Changed:)
                         name : ORLabJackModelAOut1Changed
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(slopeChanged:)
                         name : ORLabJackSlopeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interceptChanged:)
                         name : ORLabJackInterceptChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(involvedInProcessChanged:)
                         name : ORLabJackModelInvolvedInProcessChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(minValueChanged:)
                         name : ORLabJackMinValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(maxValueChanged:)
                         name : ORLabJackMaxValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(deviceSerialNumberChanged:)
                         name : ORLabJackModelDeviceSerialNumberChanged
						object: model];

}

- (void) awakeFromNib
{
	[self populateInterfacePopup:[model getUSBController]];
	short i;
	for(i=0;i<8;i++){	
		[[nameMatrix cellAtRow:i column:0] setEditable:YES];
		[[nameMatrix cellAtRow:i column:0] setTag:i];
		[[unitMatrix cellAtRow:i column:0] setEditable:YES];
		[[unitMatrix cellAtRow:i column:0] setTag:i];
		[[adcMatrix cellAtRow:i column:0] setTag:i];
		[[minValueMatrix cellAtRow:i column:0] setTag:i];
		[[maxValueMatrix cellAtRow:i column:0] setTag:i];
		[[slopeMatrix cellAtRow:i column:0] setTag:i];
		[[interceptMatrix cellAtRow:i column:0] setTag:i];
	}
	
	for(i=0;i<16;i++){	
		[[doNameMatrix cellAtRow:i column:0] setTag:i];
		[[doDirectionMatrix cellAtRow:i column:0] setTag:i];
		[[doValueOutMatrix cellAtRow:i column:0] setTag:i];
		[[doValueInMatrix cellAtRow:i column:0] setTag:i];
	}
	for(i=0;i<4;i++){	
		[[ioNameMatrix cellAtRow:i column:0] setTag:i];
		[[ioDirectionMatrix cellAtRow:i column:0] setTag:i];
		[[ioValueOutMatrix cellAtRow:i column:0] setTag:i];
		[[ioValueInMatrix cellAtRow:i column:0] setTag:i];
	}
	[super awakeFromNib];

    blankView = [[NSView alloc] init];
    ioSize			= NSMakeSize(421,665);
    setupSize		= NSMakeSize(521,551);
	
    NSString* key = [NSString stringWithFormat: @"orca.ORLabJac%ld.selectedtab",[model uniqueIdNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
}

- (void) updateWindow
{
    [ super updateWindow ];
	[self serialNumberChanged:nil];
	[self channelNameChanged:nil];
	[self channelUnitChanged:nil];
	[self ioNameChanged:nil];
	[self doNameChanged:nil];
	[self doDirectionChanged:nil];
	[self ioDirectionChanged:nil];
	[self doValueOutChanged:nil];
	[self ioValueOutChanged:nil];
	[self doValueInChanged:nil];
	[self ioValueInChanged:nil];
	[self adcChanged:nil];
	[self gainChanged:nil];
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

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:ioSize];     break;
		default: [self resizeWindowToSize:setupSize];	    break;
    }
    [[self window] setContentView:totalView];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORLabJac%ld.selectedtab",[model uniqueIdNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

- (void) involvedInProcessChanged:(NSNotification*)aNote
{
	[self lockChanged:nil];
}

- (void) aOut1Changed:(NSNotification*)aNote
{
	[aOut1Field setFloatValue: [model aOut1] * 5.1/255.];
	[aOut1Slider setFloatValue:[model aOut1] * 5.1/255.];
}

- (void) aOut0Changed:(NSNotification*)aNote
{
	[aOut0Field setFloatValue: [model aOut0] * 5.1/255.];
	[aOut0Slider setFloatValue:[model aOut0] * 5.1/255.];
}

- (void) adcDiffChanged:(NSNotification*)aNotification
{
	int value = [model adcDiff];
	short i;
	for(i=0;i<4;i++){
		[[adcDiffMatrix cellWithTag:i] setState:(value & (1L<<i))>0];
	}
	[self lockChanged:nil];
	[self adcChanged:nil];
}

- (void) lowLimitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<8;i++){
			[[lowLimitMatrix cellWithTag:i] setFloatValue:[model lowLimit:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<8){
			[[lowLimitMatrix cellWithTag:chan] setFloatValue:[model lowLimit:chan]];
		}
	}
}

- (void) hiLimitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<8;i++){
			[[hiLimitMatrix cellWithTag:i] setFloatValue:[model hiLimit:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<8){
			[[hiLimitMatrix cellWithTag:chan] setFloatValue:[model hiLimit:chan]];
		}
	}
}

- (void) minValueChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<8;i++){
			[[minValueMatrix cellWithTag:i] setFloatValue:[model minValue:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<8){
			[[minValueMatrix cellWithTag:chan] setFloatValue:[model minValue:chan]];
		}
	}
}

- (void) maxValueChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<8;i++){
			[[maxValueMatrix cellWithTag:i] setFloatValue:[model maxValue:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<8){
			[[maxValueMatrix cellWithTag:chan] setFloatValue:[model maxValue:chan]];
		}
	}
}

- (void) slopeChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<8;i++){
			[[slopeMatrix cellWithTag:i] setFloatValue:[model slope:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<8){
			[[slopeMatrix cellWithTag:chan] setFloatValue:[model slope:chan]];
		}
	}
}

- (void) interceptChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<8;i++){
			[[interceptMatrix cellWithTag:i] setFloatValue:[model intercept:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] floatValue];
		if(chan<8){
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
	[counterField setIntValue: [model counter]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORLabJackLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) setDoEnabledState
{
	unsigned short aMask = [model doDirection];
	int i;
	for(i=0;i<16;i++){
		[[doValueOutMatrix cellWithTag:i] setTransparent: (aMask & (1L<<i))!=0];
	}
	[doValueOutMatrix setNeedsDisplay:YES];
}

- (void) setIoEnabledState
{
	unsigned short aMask = [model ioDirection];
	int i;
	for(i=0;i<4;i++){
		[[ioValueOutMatrix cellWithTag:i] setTransparent: (aMask & (1L<<i))!=0];
	}
	[ioValueOutMatrix setNeedsDisplay:YES];
}

- (void) channelNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<8;i++){
			[[nameMatrix cellWithTag:i] setStringValue:[model channelName:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<8){
			[[nameMatrix cellWithTag:chan] setStringValue:[model channelName:chan]];
		}
	}
}

- (void) channelUnitChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<8;i++){
			[[unitMatrix cellWithTag:i] setStringValue:[model channelUnit:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<8){
			[[unitMatrix cellWithTag:chan] setStringValue:[model channelUnit:chan]];
		}
	}
}

- (void) doDirectionChanged:(NSNotification*)aNotification
{
	int value = [model doDirection];
	short i;
	for(i=0;i<16;i++){
		[[doDirectionMatrix cellWithTag:i] setState:(value & (1L<<i))>0];
	}
	[self setDoEnabledState];
	[self doValueInChanged:nil];
}

- (void) ioDirectionChanged:(NSNotification*)aNotification
{
	int value = [model ioDirection];
	short i;
	for(i=0;i<4;i++){
		[[ioDirectionMatrix cellWithTag:i] setState:(value & (1L<<i))>0];
	}
	[self setIoEnabledState];
	[self ioValueInChanged:nil];
}

- (void) doValueOutChanged:(NSNotification*)aNotification
{
	int value = [model doValueOut];
	short i;
	for(i=0;i<16;i++){
		[[doValueOutMatrix cellWithTag:i] setState:(value & (1L<<i))>0];
	}
}

- (void) ioValueOutChanged:(NSNotification*)aNotification
{
	int value = [model ioValueOut];
	short i;
	for(i=0;i<4;i++){
		[[ioValueOutMatrix cellWithTag:i] setState:(value & (1L<<i))>0];
	}
}

- (void) doValueInChanged:(NSNotification*)aNotification
{
	short i;
	for(i=0;i<16;i++){
		[[doValueInMatrix cellWithTag:i] setTextColor:[model doInColor:i]];
		[[doValueInMatrix cellWithTag:i] setStringValue:[model doInString:i]];
	}
}

- (void) ioValueInChanged:(NSNotification*)aNotification
{
	short i;
	for(i=0;i<4;i++){
		[[ioValueInMatrix cellWithTag:i] setTextColor:[model ioInColor:i]];
		[[ioValueInMatrix cellWithTag:i] setStringValue:[model ioInString:i]];
	}
}

- (void) adcChanged:(NSNotification*)aNotification
{
	unsigned short diffMask = [model adcDiff];
	if(!aNotification){
		int i;
		for(i=0;i<8;i++){
			if((diffMask & (1<<i/2)) && ((i%2)!=0))[[adcMatrix cellWithTag:i] setStringValue:@"----"];
			else [[adcMatrix cellWithTag:i] setFloatValue:[model convertedValue:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<8){
			if((diffMask & (1<<chan/2)) && ((chan%2)!=0))[[adcMatrix cellWithTag:chan] setStringValue:@"----"];
			else [[adcMatrix cellWithTag:chan] setFloatValue:[model convertedValue:chan]];
		}
	}
}

- (void) gainChanged:(NSNotification*)aNotification
{
	[gainPU0 selectItemAtIndex:[model gain:0]];
	[gainPU1 selectItemAtIndex:[model gain:1]];
	[gainPU2 selectItemAtIndex:[model gain:2]];
	[gainPU3 selectItemAtIndex:[model gain:3]];
}

- (void) ioNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<4;i++){
			[[ioNameMatrix cellWithTag:i] setStringValue:[model ioName:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<4) [[ioNameMatrix cellWithTag:chan] setStringValue:[model ioName:chan]];
	}
}

- (void) doNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<16;i++){
			[[doNameMatrix cellWithTag:i] setStringValue:[model doName:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		[[doNameMatrix cellWithTag:chan]   setStringValue:[model doName:chan]];
	}
}



#pragma mark •••Notifications
- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup:[aNote object]];
}

- (void) lockChanged:(NSNotification*)aNote
{
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORLabJackLock];
    BOOL locked = [gSecurity isLocked:ORLabJackLock];
	BOOL inProcess = [model involvedInProcess];
    [lockButton setState: locked];
	[serialNumberPopup	setEnabled:!locked];
	[nameMatrix			setEnabled:!locked];
	[unitMatrix			setEnabled:!locked];
	[doNameMatrix		setEnabled:!locked];
	[ioNameMatrix		setEnabled:!locked];
	[doDirectionMatrix	setEnabled:!locked && !inProcess];
	[ioDirectionMatrix	setEnabled:!locked && !inProcess];
	[doValueOutMatrix	setEnabled:!locked && !inProcess];
	[ioValueOutMatrix	setEnabled:!locked && !inProcess];
	[adcDiffMatrix		setEnabled:!locked && !inProcess];
	[digitalOutputEnabledButton		setEnabled:!locked && !inProcess];
	
	[resetCounterButton setEnabled:!locked];
	
	int adcDiff = [model adcDiff];
	[gainPU0			setEnabled:!lockedOrRunningMaintenance && (adcDiff&0x01)] ;
	[gainPU1			setEnabled:!lockedOrRunningMaintenance && (adcDiff&0x02)];
	[gainPU2			setEnabled:!lockedOrRunningMaintenance && (adcDiff&0x04)];
	[gainPU3			setEnabled:!lockedOrRunningMaintenance && (adcDiff&0x08)];
	[pollTimePopup		setEnabled:!lockedOrRunningMaintenance && !inProcess];
	
	[aOut0Slider		setEnabled:!lockedOrRunningMaintenance];
	[aOut1Slider		setEnabled:!lockedOrRunningMaintenance];

	[aOut0Field		setEnabled:!lockedOrRunningMaintenance];
	[aOut1Field		setEnabled:!lockedOrRunningMaintenance];
}

- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	[[self window] setTitle:[model title]];
}

#pragma mark •••Actions
- (IBAction) probeAction:(id)sender
{
	[model readSerialNumber];
}

- (IBAction) aOut1Action:(id)sender
{
	[model setAOut1:[sender floatValue] * 255./5.1];	
}

- (IBAction) aOut0Action:(id)sender
{
	[model setAOut0:[sender floatValue]* 255./5.1];	
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
    [gSecurity tryToSetLock:ORLabJackLock to:[sender intValue] forWindow:[self window]];
}

- (void) populateInterfacePopup:(ORUSB*)usb
{
	NSArray* interfaces = [usb interfacesForVender:[model vendorID] product:[model productID]];
	[serialNumberPopup removeAllItems];
	[serialNumberPopup addItemWithTitle:@"N/A"];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([serialNumber length]){
			[serialNumberPopup addItemWithTitle:serialNumber];
		}
	}
	[self validateInterfacePopup];
	if([model serialNumber])[serialNumberPopup selectItemWithTitle:[model serialNumber]];
	else [serialNumberPopup selectItemAtIndex:0];
}

- (void) validateInterfacePopup
{
	NSArray* interfaces = [[model getUSBController] interfacesForVender:[model vendorID] product:[model productID]];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([anInterface registeredObject] == nil || [serialNumber isEqualToString:[model serialNumber]]){
			[[serialNumberPopup itemWithTitle:serialNumber] setEnabled:YES];
		}
		else [[serialNumberPopup itemWithTitle:serialNumber] setEnabled:NO];
	}
}

- (IBAction) serialNumberAction:(id)sender
{
	if([serialNumberPopup indexOfSelectedItem] == 0){
		[model setSerialNumber:nil];
	}
	else {
		[model setSerialNumber:[serialNumberPopup titleOfSelectedItem]];
	}
}

- (IBAction) channelNameAction:(id)sender
{
	[model setChannel:[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}

- (IBAction) channelUnitAction:(id)sender
{
	[model setChannel:[[sender selectedCell] tag] unit:[[sender selectedCell] stringValue]];
}

- (IBAction) ioNameAction:(id)sender
{
	[model setIo:[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}

- (IBAction) doNameAction:(id)sender
{
	[model setDo:[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}

- (IBAction) updateAllAction:(id)sender
{
	[model queryAll];
}

- (IBAction) adcDiffBitAction:(id)sender
{
	[model setAdcDiffBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) ioDirectionBitAction:(id)sender
{
	[model setIoDirectionBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) doDirectionBitAction:(id)sender
{
	int theIndex = [[sender selectedCell] tag];
	[model setDoDirectionBit:theIndex withValue:[sender intValue]];
}


- (IBAction) ioValueOutBitAction:(id)sender
{
	[model setIoValueOutBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) doValueOutBitAction:(id)sender
{
	int theIndex = [[sender selectedCell] tag];
	[model setDoValueOutBit:theIndex withValue:[sender intValue]];
}

- (IBAction) resetCounter:(id)sender
{
	[model resetCounter];
}

- (IBAction) lowLimitAction:(id)sender
{
	[model setLowLimit:[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];	
}

- (IBAction) hiLimitAction:(id)sender
{
	[model setHiLimit:[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];	
}

- (IBAction) minValueAction:(id)sender
{
	[model setMinValue:[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];	
}

- (IBAction) maxValueAction:(id)sender
{
	[model setMaxValue:[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];	
}

- (IBAction) gainAction:(id)sender
{
	[model setGain:[sender tag] withValue:[sender indexOfSelectedItem]];
}

- (IBAction) slopeAction:(id)sender
{
	[model setSlope:[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];	
}

- (IBAction) interceptAction:(id)sender
{
	[model setIntercept:[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];	
}

@end
