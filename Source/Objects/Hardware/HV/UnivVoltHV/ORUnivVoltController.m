//
//  ORUnivVoltController.m
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
#import "ORUnivVoltController.h"
#import "ORUnivVoltModel.h"
#import "ORUnivVoltHVCrateModel.h"
#import "ORCircularBufferUV.h"
#import "ORCompositePlotView.h"
#import "ORTimeLinePlot.h"
#import "ORTimeAxis.h"

const int MAXcCHNLS_PER_PLOT = 6;

@implementation ORUnivVoltController
- (id) init
{
    self = [ super initWithWindowNibName: @"UnivVolt" ];
	if ( self ) 
	{
	
	}
    return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
  
	  [super registerNotificationObservers];

    
	[notifyCenter addObserver : self
                     selector : @selector( channelChanged: )
                         name : UVChnlChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector( channelEnabledChanged:)
                         name : UVChnlEnabledChanged
						object: model];

   [notifyCenter addObserver : self
                     selector : @selector( measuredCurrentChanged:)
                         name : UVChnlMeasuredCurrentChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector( measuredHVChanged:)
                         name : UVChnlMeasuredHVChanged
						object: model];
						    
	[notifyCenter addObserver : self
                     selector : @selector( demandHVChanged:)
                         name : UVChnlDemandHVChanged
						object: model];
						
//	[notifyCenter  addObserver: self
//	                  selector: @selector( writeErrorMsg: )
//					     name : HVSocketNotConnectedNotification
//					   object : nil];

	[notifyCenter addObserver : self
                     selector : @selector( rampUpRateChanged:)
                         name : UVChnlRampUpRateChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector( rampDownRateChanged:)
                         name : UVChnlRampDownRateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector( tripCurrentChanged:)
                         name : UVChnlTripCurrentChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector( statusChanged:)
                         name : UVChnlStatusChanged
						object: model];
						
	[notifyCenter addObserver : self
                     selector : @selector( MVDZChanged:)
                         name : UVChnlMVDZChanged
						object: model];
						
    [notifyCenter addObserver : self
                     selector : @selector( MCDZChanged:)
                         name : UVChnlMCDZChanged
						object: model];
						
    [notifyCenter addObserver : self
                     selector : @selector( hvLimitChanged:)
                         name : UVChnlHVLimitChanged
						object: model];						

	[notifyCenter  addObserver: self
	                  selector: @selector( setValues: )
					     name : UVChnlHVValuesChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector( pollingTimeChanged: )
                         name : UVPollTimeMinsChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector( pollingStatusChanged: )
                         name : UVStatusPollTaskChanged
					   object : model];
						
	[notifyCenter addObserver : self
	                 selector : @selector( lastPollTimeChanged: )
					     name : UVLastPollTimeChanged
					   object : model];
						
	[notifyCenter addObserver : self
	                 selector : @selector( plotterDataChanged: )
					     name : UVPlotterDataChanged
					   object : model]; 

	[notifyCenter addObserver : self
	                 selector : @selector( alarmChanged: )
					     name : UVAlarmChanged
					   object : model]; 

	[notifyCenter  addObserver: self
	                  selector: @selector( writeErrorMsg: )
					     name : HVShortErrorNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector( scaleAction: )
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector( miscAttributesChanged: )
						 name : ORMiscAttributesChanged
					   object : model];
	
}


- (void) awakeFromNib
{
	[super awakeFromNib];
	
	int i;
	mCurrentChnl = 0;
	mOrigChnl = 0;
	NSLog( @"UnivVoltController - AwakeFromNIB.  Current chnl: ", mCurrentChnl );
	[mChannelStepperField setIntValue: mCurrentChnl];
	[mChannelNumberField setIntValue: mCurrentChnl];
	[mCmdStatus setStringValue: @"Undefined"];
	
	// Set all measured values to undefined
	for ( i = 0; i < UVkNumChannels; i++ ) {
		if ( [model updateFirst: i] ) {
		}
		else {
			[model setStatus: i status: @"Undefined"];
		}
	}
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[mPlottingObj1 addPlot: aPlot];
		[(ORTimeAxis*)[mPlottingObj1 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i+4 andDataSource:self];
		[mPlottingObj2 addPlot: aPlot];
		[(ORTimeAxis*)[mPlottingObj2 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	
	[mChnlTable reloadData];

}

- (void) setValues: (NSNotification *) aNote
{
	NSDictionary* curChnlDict = [aNote userInfo];
	mCurrentChnl = [[curChnlDict objectForKey: HVkCurChnl] intValue];
	[self setChnlValues: mCurrentChnl];

	[mChnlTable reloadData];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"Univ Volt Card (Slot %d)",[model stationNumber]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Univ Volt Card (Slot %d)",[model stationNumber]]];
}

- (void) updateWindow
{
    [super updateWindow];
    
	[self channelEnabledChanged: nil];
	[self demandHVChanged: nil];
	[self measuredHVChanged: nil];
	[self tripCurrentChanged: nil];
	[self rampUpRateChanged: nil];
	[self rampDownRateChanged: nil];
	[self MVDZChanged: nil];
	[self MCDZChanged: nil];
	[self hvLimitChanged: nil];
	[self pollingTimeChanged: nil];
	[self pollingStatusChanged: nil];
	[self miscAttributesChanged: nil];
	
	
	[mChnlTable reloadData];	
}

#pragma mark •••Notification - Responses•••
- (void) channelChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  

}

- (void) channelEnabledChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ]; 
	int value =  [model chnlEnabled: mCurrentChnl];
//	NSLog( @"ORController - EnabledChanged( %d ): %d\n", mCurrentChnl, value );
	[mChnlEnabled setIntValue: value];
	[mChnlTable reloadData];	
}

- (void) measuredCurrentChanged: (NSNotification*) aNote
{
//	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mMeasuredCurrent setFloatValue: [model measuredCurrent: mCurrentChnl]];
	NSLog( @"UnivVoltController - Measured current: %g, for chnl: %d", [model measuredCurrent: mCurrentChnl], mCurrentChnl );
	[mChnlTable reloadData];	
}

- (void) demandHVChanged: (NSNotification*) aNote
{
	float value;
	[self setCurrentChnl: (NSNotification*) aNote ];  
	value = [model demandHV: mCurrentChnl];
	NSLog( @"UnivVoltController - Setting demand HV to: %f  for channel %d\n", value, mCurrentChnl);
	[mDemandHV setFloatValue: value];
}

- (void) measuredHVChanged: (NSNotification*) aNote
{
//	[self setCurrentChnl: (NSNotification *) aNote ];  
	float hvValue = [model measuredHV: mCurrentChnl];
	[mMeasuredHV setFloatValue: hvValue];	
//	ORCircularBufferUV* cbObj = [mCircularBuffers objectAtIndex: mCurrentChnl];
	
/*	if (cbObj ) {
		NSDate* dateObj = [NSDate date];
//	NSNumber* hvValueObj = [NSNumber numberWithFloat: hvValue];
		[cbObj insertHVEntry: dateObj hvValue: hvValue];
	}
	*/
	[mChnlTable reloadData];	
}

- (void) tripCurrentChanged: (NSNotification*) aNote
{
	float value;
	[self setCurrentChnl: (NSNotification*) aNote ];  
	value = [model tripCurrent: mCurrentChnl];
	NSLog( @"UnivVoltController - tripCurrentChanged for chnl %d: %f\n", mCurrentChnl, value );
	[mTripCurrent setFloatValue: value];
}

- (void) rampUpRateChanged: (NSNotification*) aNote
{
	float value;
	[self setCurrentChnl: (NSNotification*) aNote ]; 
	value = [model rampUpRate: mCurrentChnl];
	NSLog( @"UnivVoltController - RampUpRate %f for channel %d changed.\n", value, mCurrentChnl);
	[mRampUpRate setFloatValue: [model rampUpRate: mCurrentChnl]];
}

- (void) rampDownRateChanged: (NSNotification*) aNote
{
	float value;
	[self setCurrentChnl: (NSNotification*) aNote ]; 
	value = [model rampDownRate: mCurrentChnl];
	NSLog( @"UnivVoltController - RampDownRate %f for channel %d changed.\n", value, mCurrentChnl);
	[mRampDownRate setFloatValue: [model rampDownRate: mCurrentChnl]];
}

-(void) statusChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification*) aNote ];  
	[mStatus setStringValue: [model status: mCurrentChnl]];
	[mChnlTable reloadData];	
}

- (void) MVDZChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mMVDZ setFloatValue: [model MVDZ: mCurrentChnl]];
}

- (void) MCDZChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification*) aNote ];  
	[mMCDZ setFloatValue: [model MCDZ: mCurrentChnl]];
}

- (void) hvLimitChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mHVLimit setFloatValue: [model HVLimit: mCurrentChnl]];
}

- (void) pollingTimeChanged: (NSNotification *) aNote
{
	float pollTimeMinsValue = [model pollTimeMins];
	[mPollingTimeMinsField setFloatValue: pollTimeMinsValue];
	NSLog( @"UnivVoltController - notified of polling time change: %f\n", [mPollingTimeMinsField floatValue]);
}

- (void) pollingStatusChanged: (NSNotification*) aNote
{
	bool ifPoll = [model isPollingTaskRunning];
	[mStartStopPolling setTitle: ( ifPoll ? @"Stop" : @"Start" ) ];
}

- (void) lastPollTimeChanged: (NSNotification*) aNote
{
	NSDictionary* pollObj = [aNote userInfo];
	NSString* lastPollTime = [pollObj objectForKey: HVkLastPollTimeMins];
	NSLog( @"UnivVoltController - Last polltime %@\n", lastPollTime );
	[mLastPoll setObjectValue: lastPollTime];
}


- (void) plotterDataChanged: (NSNotification*) aNote
{
	[mPlottingObj1 setNeedsDisplay: YES];
	[mPlottingObj2 setNeedsDisplay: YES];
}

- (void) alarmChanged: (NSNotification*) aNote
{
	[mAlarmEnabledTextField setStringValue: [model areAlarmsEnabled] ? @"Enabled" : @"Disabled"];
	[mAlarmButton setTitle: [model areAlarmsEnabled] ? @"Disable" : @"Enable"];
//	[model isConnected] ? [model disconnect] : [model connect];
}


- (void) writeErrorMsg: (NSNotification*) aNote
{
	NSDictionary* errorDict = [aNote userInfo];
	NSLog( @"UnivVoltController - error: %@", [errorDict objectForKey: HVkErrorMsg] );
	[mCmdStatus setStringValue: [errorDict objectForKey: HVkErrorMsg]];
}

/*- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORUnivVoltLock to:secure];
    [dialogLock setEnabled:secure];
}
*/
/*
- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL locked			= [gSecurity isLocked:ORUnivVoltLock];

	[ipConnectButton setEnabled:!locked];
	[ipAddressTextField setEnabled:!locked];

    [dialogLock setState: locked];

}
*/
#pragma mark •••Actions
- (IBAction) enableAllChannels: (id) aSender
{
	int i;
	for (i = 0; i < UVkNumChannels; i++ )
	{
		[model setChannelEnabled: 1 chnl: i];
	}
}

- (IBAction) disableAllChannels: (id) aSender
{
	int i;
	for (i = 0; i < UVkNumChannels; i++ )
	{
		[model setChannelEnabled: 0 chnl: i];
	}
}

- (IBAction) setAlarm: (id) aSender
{
	[model areAlarmsEnabled] ? [model enableAlarms: NO] : [model enableAlarms: YES];
}

- (IBAction) setChannelNumberField: (id) aSender
{
	 mCurrentChnl = [mChannelNumberField intValue];
	[mChannelStepperField setIntValue: mCurrentChnl];
	[self setChnlValues: mCurrentChnl];
//	[self updateWindow]; Not needed.
}

- (IBAction) setChannelNumberStepper: (id) aSender
{
	mCurrentChnl = [mChannelStepperField intValue];
	[mChannelNumberField setIntValue: mCurrentChnl];
	[self setChnlValues: mCurrentChnl];
	// setChannelNumberField - updates display
}

- (IBAction) setChnlEnabled: (id) aSender
{
	int enabled = [mChnlEnabled intValue];
	NSLog( @"UnivVoltController -  - SetEnabled( %d ): %d\n", mCurrentChnl, enabled );
	[model setChannelEnabled: enabled chnl: mCurrentChnl];
}

- (IBAction) setDemandHV: (id) aSender
{	
	[model setDemandHV: [mDemandHV floatValue] chnl: mCurrentChnl];
}

- (IBAction) setTripCurrent: (id) aSender
{
	float value = [mTripCurrent floatValue];
	NSLog( @"UnivVoltController - Set trip current for channel %d to %f\n", mCurrentChnl, value );
	[model setTripCurrent: value chnl: mCurrentChnl];	
}

- (IBAction) setRampUpRate: (id) aSender
{
	[model setRampUpRate: [mRampUpRate floatValue] chnl: mCurrentChnl];
}

- (IBAction) setRampDownRate: (id) aSender
{
	[model setRampDownRate: [mRampDownRate floatValue] chnl: mCurrentChnl];
}

- (IBAction) setMVDZ: (id) aSender
{
	[model setMVDZ: [mMVDZ floatValue] chnl: mCurrentChnl];
}

- (IBAction) setMCDZ: (id) aSender
{
	[model setMCDZ: [mMCDZ floatValue] chnl: mCurrentChnl];
}

- (IBAction) updateTable: (id) aSender
{
	[mChnlTable reloadData];	
}

- (IBAction) hardwareValuesOneChannel: (id) aSender
{
	[model getValues: mCurrentChnl];
}

- (IBAction) hardwareValues: (id) aSender
{
	NSLog( @"UnivVoltController - Get hardware values\n" );
	[model getValues: -1];
}

- (IBAction) setHardwareValesOneChannel: (id ) aSender;
{
	NSLog( @"UnivVoltController - Download params for chnl %d\n", mCurrentChnl );
	[model loadValues: mCurrentChnl];
}

- (IBAction) setHardwareValues: (id) aSender
{
	NSLog( @"UnivVoltController - Download hardware values\n" );
	[model loadValues: -1];
}

- (IBAction) pollTimeAction: (id) aSender
{
	[model setPollTimeMins: [mPollingTimeMinsField floatValue]];
}

- (IBAction) startStopPolling: (id) aSender
{
	if ( [model isPollingTaskRunning] ) {
		[model stopPolling];
	} else {
		float pollingTimeMins = [mPollingTimeMinsField floatValue];
		[model setPollTimeMins: pollingTimeMins] ;
		[model startPolling];
	}
}

#pragma mark •••Code for plotter
- (int)	numberPointsInPlot: (id) aPlotter
{
	int aChnl = [aPlotter tag];
	return( [model numPointsInCB: aChnl] );
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int aChnl = [aPlotter tag];
	double aValue = 0;
	if ( aChnl >= 0 ) {
		ORCircularBufferUV* cbObj = [model circularBuffer: aChnl];
/* Used for debugging
		if ( anX == 1 ) {
			NSDictionary* storedData = [cbObj HVEntry: anX];
			float value = [[storedData objectForKey: @"Value"] floatValue];//MAH -- key was wrong
			NSLog( @"plotter: %f\n", value );
		}
*/
	
		if ( i < [cbObj count] ) {			
			NSDictionary* retDataObj = [cbObj HVEntry: i];
			NSNumber* hvValueObj = [retDataObj objectForKey: @"Value"]; //MAH -- key was wrong
			aValue = [hvValueObj floatValue];
		}
	}
	*xValue = (double)i;
	*yValue = aValue;
}

//a fake action from the scale object
- (void) scaleAction: (NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [mPlottingObj1 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[mPlottingObj1 yAxis]attributes] forKey: @"HVPlot1YAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [mPlottingObj2 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[mPlottingObj2 yAxis]attributes] forKey: @"HVPlot2YAttributes"];
	};	
}


- (void) miscAttributesChanged: (NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString: @"HVPlot1YAttributes"]){
		if( aNote == nil ) attrib = [model miscAttributesForKey: @"HVPlot1YAttributes"];
		if( attrib ){
			[(ORAxis*)[mPlottingObj1 yAxis] setAttributes: attrib];
			[mPlottingObj1 setNeedsDisplay: YES]; // Probably not needed.
			[[mPlottingObj1 yAxis] setNeedsDisplay: YES];
//			[rateLogCB setState: [[attrib objectForKey: ORAxisUseLog] boolValue]];
		}
	}
	if( aNote == nil || [key isEqualToString: @"HVPlot2YAttributes"]){
		if( aNote == nil ) attrib = [model miscAttributesForKey: @"HVPlot2YAttributes"];
		if( attrib ){
			[(ORAxis*)[mPlottingObj2 yAxis] setAttributes: attrib];
			[mPlottingObj2 setNeedsDisplay: YES];
			[[mPlottingObj2 yAxis] setNeedsDisplay: YES];
//			[totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
}

#pragma mark •••Delegate
- (void) tabView: (NSTabView*) aTabView didSelectTabViewItem: (NSTabViewItem*) aTabViewItem
{
//	int index = [aTabView indexOfTabViewItem: aTabViewItem];
	NSString* labelTab = [aTabViewItem label];
	//( @"tab index: %d, tab label %@\n", index, labelTab );
	if ( [labelTab isEqualToString: @"Channel"] )
	{
		mCurrentChnl = mOrigChnl;
		[mChannelStepperField setIntValue: mCurrentChnl];
		[mChannelNumberField setIntValue: mCurrentChnl];
		[self setChnlValues: mCurrentChnl];
	}
	else
	{
		mOrigChnl = mCurrentChnl;
	}
}

#pragma mark •••Table handling routines
- (int) numberOfRowsInTableView: (NSTableView*) aTableView
{	return( UVkNumChannels );
}

- (void) tableView: (NSTableView*) aTableView
       setObjectValue: (id) anObject
	   forTableColumn: (NSTableColumn*) aTableColumn
	   row: (int) aRowIndex
{
//	NSMutableDictionary* tmpChnl = [[model dictionary] objectAtIndex: aRowIndex];
	NSString* colIdentifier = [aTableColumn identifier];
	NSMutableDictionary* tmpChnl = [model channelDictionary: aRowIndex];
	[tmpChnl setObject: anObject forKey: colIdentifier];
}

- (id) tableView: (NSTableView*) aTableView
	   objectValueForTableColumn: (NSTableColumn*) aTableColumn
	   row: (int) aRowIndex
{
	NSMutableDictionary* tmpChnl = [model channelDictionary: aRowIndex];
	NSString* colIdentifier = [aTableColumn identifier];
//	if ( [colIdentifier isEqualToString: @"chnlEnabled"]) NSLog( @"ORUnivVoltCont - Row: %d, column: %@", aRowIndex, colIdentifier );
	return( [tmpChnl objectForKey: colIdentifier] );
}

#pragma mark •••Utilities
- (void) setCurrentChnl: (NSNotification *) aNote
{
	if ( aNote == 0 ) {
//	    NSLog( @"aNote is nil" );
		mCurrentChnl = 0;
	} else {
		NSDictionary* chnlDict = [aNote userInfo];
		mCurrentChnl = [[chnlDict objectForKey: HVkChannel] intValue];
	}
//[chnlDict objectForKey: HVkCurChnl];

}

// Set values for single channel display.
- (void) setChnlValues: (int) aCurrentChannel
{
	float			value;
	NSDictionary*	tmpChnl = [model channelDictionary: aCurrentChannel];
//	bool			state = [mChnlEnabled state];
	NSString*		valueStr;
	int				valueInt;
//	int				status;

//	[model printDictionary: mCurrentChnl];
//	NSLog( @"\n\nChnl: %d\n", aCurrentChannel );
	
//	[mChnlEnabled setState: state];
//	NSLog( @"State: %d\n", state );
	valueInt = [[tmpChnl objectForKey: HVkChannelEnabled] intValue];
	[mChnlEnabled setIntValue: valueInt];
//	valueStr = [mChnlEnabled: intValue: valueInt];
	
	value = [[tmpChnl objectForKey: HVkMeasuredCurrent] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	
	[mMeasuredCurrent setStringValue: valueStr];
//	NSLog( @"Measured current: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkMeasuredHV] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mMeasuredHV setStringValue: valueStr];
//	NSLog( @"Measured HV: %f\n", value );

	value = [[tmpChnl objectForKey: HVkDemandHV] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mDemandHV setStringValue: valueStr];
//	NSLog( @"Demand HV: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkRampUpRate] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mRampUpRate setStringValue: valueStr];
//	NSLog( @"mRampUpRate: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkRampDownRate] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mRampDownRate setStringValue: valueStr];
//	NSLog( @"mRampDownRate: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkTripCurrent] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mTripCurrent setStringValue: valueStr];
//	NSLog( @"mTripCurrent: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkMVDZ] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mMVDZ setStringValue: valueStr];
//	NSLog( @"mMVDZ: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkMCDZ] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mMCDZ setStringValue: valueStr];
//	NSLog( @"mMCDZ: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkHVLimit] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mHVLimit setStringValue: valueStr];
//	NSLog( @"mHVLimit: %f\n", value );
	
	// status case statement
	[mStatus setStringValue: [tmpChnl objectForKey: HVkStatus]];

}


@end
