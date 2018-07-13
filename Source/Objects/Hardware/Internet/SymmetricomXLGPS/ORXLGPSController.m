//
//  ORXLGPSController.m
//  ORCA
//
//  Created by Jarek Kaspar on November 2, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORXLGPSController.h"
#import "ORXLGPSModel.h"

static NSDictionary* gpsOps;

@implementation ORXLGPSController

#pragma mark •••Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"XLGPS"];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	[ipNumberComboBox reloadData];
	[self populateOps];
	[super awakeFromNib];
}	

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];

	[notifyCenter addObserver : self
			 selector : @selector(lockChanged:)
			     name : ORRunStatusChangedNotification
			   object : nil];
	
	[notifyCenter addObserver : self
			 selector : @selector(lockChanged:)
			     name : ORXLGPSModelLock
			    object: nil];
	
	[notifyCenter addObserver : self
			 selector : @selector(ipNumberChanged:)
			     name : ORXLGPSIPNumberChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(userChanged:)
			     name : ORXLGPSModelUserNameChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(passwordChanged:)
			     name : ORXLGPSModelPasswordChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(timeOutChanged:)
			     name : ORXLGPSModelTimeOutChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(opsRunningChanged:)
			     name : ORXLGPSModelOpsRunningChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(commandChanged:)
			     name : ORXLGPSModelCommandChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(ppoCommandChanged:)
			     name : ORXLGPSModelPpoCommandChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(ppoTimeChanged:)
			     name : ORXLGPSModelPpoTimeChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(ppoTimeOffsetChanged:)
			     name : ORXLGPSModelPpoTimeOffsetChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(ppoPulseWidthChanged:)
			     name : ORXLGPSModelPpoPulseWidthChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(ppoPulsePeriodChanged:)
			     name : ORXLGPSModelPpoPulsePeriodChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(ppoRepeatsChanged:)
			     name : ORXLGPSModelPpoRepeatsChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(ppsCommandChanged:)
			     name : ORXLGPSModelPpsCommandChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(isPpoChanged:)
			     name : ORXLGPSModelIsPpoChanged
			   object : model];
}

- (void) populateOps
{
	gpsOps = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSDictionary dictionaryWithObjectsAndKeys:	telnetTestButton, @"button",
									telnetTestPI, @"spinner",
									NSStringFromSelector(@selector(test)), @"selector",
			 nil], @"telnetTest",
			[NSDictionary dictionaryWithObjectsAndKeys:	telnetPingButton, @"button",
									telnetPingPI, @"spinner",
									NSStringFromSelector(@selector(ping)), @"selector",
			 nil], @"telnetPing",
			[NSDictionary dictionaryWithObjectsAndKeys:	basicSendButton, @"button",
									basicSendPI, @"spinner",
									NSStringFromSelector(@selector(send)), @"selector",
			 nil], @"basicSend",
			[NSDictionary dictionaryWithObjectsAndKeys:	basicTimeButton, @"button",
									basicTimePI, @"spinner",
									NSStringFromSelector(@selector(time)), @"selector",
			 nil], @"basicTime",
			[NSDictionary dictionaryWithObjectsAndKeys:	basicLockedButton, @"button",
									basicLockedPI, @"spinner",
									NSStringFromSelector(@selector(isLocked)), @"selector",
			 nil], @"basicLocked",
			[NSDictionary dictionaryWithObjectsAndKeys:	basicReportButton, @"button",
									basicReportPI, @"spinner",
									NSStringFromSelector(@selector(report)), @"selector",
			 nil], @"basicReport",
			[NSDictionary dictionaryWithObjectsAndKeys:	basicSatellitesButton, @"button",
									basicSatellitesPI, @"spinner",
									NSStringFromSelector(@selector(satellites)), @"selector",
			 nil], @"basicSatellites",
			[NSDictionary dictionaryWithObjectsAndKeys:	basicSelfTestButton, @"button",
									basicSelfTestPI, @"spinner",
									NSStringFromSelector(@selector(selfTest)), @"selector",
			 nil], @"basicSelfTest",
			[NSDictionary dictionaryWithObjectsAndKeys:	ppoGetButton, @"button",
									ppoGetPI, @"spinner",
									NSStringFromSelector(@selector(getPpo)), @"selector",
			 nil], @"ppoGet",
			[NSDictionary dictionaryWithObjectsAndKeys:	ppoSetButton, @"button",
									ppoSetPI, @"spinner",
									NSStringFromSelector(@selector(setPpo)), @"selector",
			 nil], @"ppoSet",
			[NSDictionary dictionaryWithObjectsAndKeys:	ppoTurnOffButton, @"button",
									ppoTurnOffPI, @"spinner",
									NSStringFromSelector(@selector(turnOffPpo)), @"selector",
			 nil], @"ppoTurnOff",
		   nil];
}

#pragma mark •••Interface Management
- (void) updateWindow
{
	[super updateWindow];
	
	[self lockChanged:nil];
	[self ipNumberChanged:nil];
	[self userChanged:nil];
	[self passwordChanged:nil];
	[self timeOutChanged:nil];
	[self commandChanged:nil];
	[self ppoCommandChanged:nil];
	[self ppoTimeChanged:nil];
	[self ppoTimeOffsetChanged:nil];
	[self ppoPulseWidthChanged:nil];
	[self ppoPulsePeriodChanged:nil];
	[self ppoRepeatsChanged:nil];
	[self ppsCommandChanged:nil];
	[self isPpoChanged:nil];
}

- (void) checkGlobalSecurity
{
	BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
	[gSecurity setLock:ORXLGPSModelLock to:secure];
	[lockButton setEnabled:secure];
	[self updateButtons];
}

- (void) lockChanged:(NSNotification*)aNote
{   
	BOOL locked = [gSecurity isLocked:ORXLGPSModelLock];
	[lockButton setState: locked];
	[self updateButtons];
}

- (void) updateButtons
{
	BOOL locked	= [gSecurity isLocked:ORXLGPSModelLock];
	//BOOL busy	= NO; //[model isBusy];

	[ipNumberComboBox setEnabled: !locked];
	[clrHistoryButton setEnabled: !locked];
	[userField setEnabled: !locked];
	[passwordField setEnabled: !locked];
	[timeOutPU setEnabled: !locked];
	[commandField setEnabled: !locked];
	[ppoCommandField setEnabled: !locked];
	[ppoPulseWidthField setEnabled: !locked];
	[ppoDayField setEnabled: !locked];
	[ppoHourField setEnabled: !locked];
	[ppoMinuteField setEnabled: !locked];
	[ppoSecondField setEnabled: !locked];
	[ppoTimeOffsetField setEnabled: !locked];
	[ppoPulsePeriodPU setEnabled: !locked];
	[ppoRepeatsButton setEnabled: !locked];
	[ppsCommandPU setEnabled: !locked];
	[isPpoMatrix setEnabled: !locked];

	//[sendButton setEnabled: !locked && !busy];
}

- (void) ipNumberChanged:(NSNotification*)aNote
{
	[ipNumberComboBox setStringValue:[model IPNumber]];
}

- (void) userChanged:(NSNotification*)aNote
{
	[userField setStringValue:[model userName]];
}

- (void) passwordChanged:(NSNotification*)aNote
{
	[passwordField setStringValue:[model password]];
}

- (void) timeOutChanged:(NSNotification*)aNote
{
	[timeOutPU selectItemWithTag:[model timeOut]];
}

- (void) commandChanged:(NSNotification*)aNote
{
	[commandField setStringValue:[model command]];
}

- (void) ppoCommandChanged:(NSNotification*)aNote
{
	[ppoCommandField setStringValue:[model ppoCommand]];
}

- (void) ppsCommandChanged:(NSNotification*)aNote
{
	[ppsCommandPU selectItemWithTitle:[model ppsCommand]];
}

- (void) ppoTimeChanged:(NSNotification*)aNote
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific            
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
	NSDateComponents *componentsPpo = [gregorian components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)
						       fromDate:[model ppoTime]];
#else
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *componentsPpo = [gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit)
                                                   fromDate:[model ppoTime]];
#endif
	NSDateFormatter* frmt = [[[NSDateFormatter alloc] init] autorelease];
	[frmt setDateFormat:@"D"];
	int day = [[frmt stringFromDate:[model ppoTime]] intValue];

	[ppoDayField setIntValue:day];
	[ppoHourField setIntegerValue:[componentsPpo hour]];
	[ppoMinuteField setIntegerValue:[componentsPpo minute]];
	[ppoSecondField setIntegerValue:[componentsPpo second]];
}

- (void) ppoTimeOffsetChanged:(NSNotification*)aNote
{
	[ppoTimeOffsetField setIntegerValue:[model ppoTimeOffset]];
}

- (void) ppoPulseWidthChanged:(NSNotification*)aNote
{
	[ppoPulseWidthField setIntegerValue:[model ppoPulseWidth]];
}

- (void) ppoPulsePeriodChanged:(NSNotification*)aNote
{
	[ppoPulsePeriodPU selectItemWithTag:[model ppoPulsePeriod]];
}

- (void) ppoRepeatsChanged:(NSNotification *)aNote
{
	[ppoRepeatsButton setIntValue:[model ppoRepeats]];
}

- (void) isPpoChanged:(NSNotification*)aNote
{
	[[isPpoMatrix cellWithTag:0] setIntValue:[model isPpo]];
	[[isPpoMatrix cellWithTag:1] setIntValue:![model isPpo]];
}

- (void) opsRunningChanged:(NSNotification*)aNote
{
	for (id key in gpsOps) {
		if ([model gpsOpsRunningForKey:key])
			[[[gpsOps objectForKey:key] objectForKey:@"spinner"] startAnimation:model];
		else
			[[[gpsOps objectForKey:key] objectForKey:@"spinner"] stopAnimation:model];			
	}
}

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender
{
	[gSecurity tryToSetLock:ORXLGPSModelLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) opsAction:(id) sender
{
	[self endEditing];
	NSString* theKey = @"";
	for (id key in gpsOps) {
		if ((id) [[gpsOps objectForKey:key] objectForKey:@"button"] == sender) {
			theKey = [NSString stringWithString: key];
			break;
		}
	}
	[model performSelector:NSSelectorFromString([[gpsOps objectForKey:theKey] objectForKey:@"selector"])];
}

- (IBAction) ipNumberAction:(id)sender
{
	[model setIPNumber:[sender stringValue]];
}

- (IBAction) clearHistoryAction:(id)sender
{
	[model clearConnectionHistory];
}

- (IBAction) userFieldAction:(id)sender
{
	[model setUserName:[sender stringValue]];	
}

- (IBAction) passwordFieldAction:(id)sender
{
	[model setPassword:[sender stringValue]];	
}

- (IBAction) timeOutAction:(id)sender
{
	[model setTimeOut:[[sender selectedItem] tag]];
}

- (IBAction) commandAction:(id)sender
{
	[model setCommand:[sender stringValue]];
}

- (IBAction) ppoCommandAction:(id)sender
{
	[model setPpoCommand:[sender stringValue]];
}

- (IBAction) ppoTimeAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific            
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
	NSDateComponents *componentsNow = [gregorian components:(NSCalendarUnitYear) fromDate:[NSDate date]];
#else
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *componentsNow = [gregorian components:(NSYearCalendarUnit) fromDate:[NSDate date]];
#endif
	[componentsNow setDay:[ppoDayField intValue]];
	[componentsNow setHour:[ppoHourField intValue]];
	[componentsNow setMinute:[ppoMinuteField intValue]];
	[componentsNow setSecond:[ppoSecondField intValue]];
	
	[model setPpoTime:[gregorian dateFromComponents:componentsNow]];
}

- (IBAction) ppoTimeOffsetAction:(id)sender
{
	[model setPpoTimeOffset:[sender intValue]];
}

- (IBAction) ppoPulseWidthAction:(id)sender
{
	[model setPpoPulseWidth:[sender intValue]];
}

- (IBAction) ppoPulsePeriodAction:(id)sender
{
	[model setPpoPulsePeriod:[[sender selectedItem] tag]];
}

- (IBAction) ppoRepeatsAction:(id)sender
{
	[model setPpoRepeats:[sender intValue]];
}

- (IBAction) ppoTodayAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific

	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
	NSDateComponents *componentsNow = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
						       fromDate:[NSDate date]];
	NSDateComponents *componentsPpo = [gregorian components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)
						       fromDate:[model ppoTime]];
#else
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *componentsNow = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                                   fromDate:[NSDate date]];
	NSDateComponents *componentsPpo = [gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit)
                                                   fromDate:[model ppoTime]];
#endif
    
	[componentsPpo setYear:[componentsNow year]];
	[componentsPpo setMonth:[componentsNow month]];
	[componentsPpo setDay:[componentsNow day]];

	[model setPpoTime:[gregorian dateFromComponents:componentsPpo]];
}

- (IBAction) ppoNowAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
	NSDateComponents *componentsPpo = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
						       fromDate:[model ppoTime]];
	NSDateComponents *componentsNow = [gregorian components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)
				       fromDate:[NSDate date]];
#else
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *componentsPpo = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                                   fromDate:[model ppoTime]];
	NSDateComponents *componentsNow = [gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit)
                                                   fromDate:[NSDate date]];
#endif
	[componentsPpo setHour:[componentsNow hour]];
	[componentsPpo setMinute:[componentsNow minute]];
	[componentsPpo setSecond:[componentsNow second]];
	
	[model setPpoTime:[gregorian dateFromComponents:componentsPpo]];
}

- (IBAction) ppsCommandAction:(id)sender
{
	[model setPpsCommand:[sender titleOfSelectedItem]];
}

- (IBAction) isPpoAction:(id)sender
{
	[model setIsPpo:[[sender cellWithTag:0] intValue]];
}


#pragma mark •••Data Source
- (NSInteger ) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	return  [model connectionHistoryCount];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	return [model connectionHistoryItem:index];
}

@end
