//
//  SNOSlowControl.m
//  Orca
//
//  Created by H S  Wan Chan Tseung on 11/18/11.
//  Copyright (c) 2011 CENPA, University of Washington. All rights reserved.
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
#import "SNOSlowControl.h"

@implementation SNOSlowControl

#pragma mark •••Initialization

-(id)init
{
	Name = @"N/A";
	Status = @"N/A";
	Value = 0.0;
	Units = @"N/A";
	LoThresh = 0.0;
	HiThresh = 0.0;
	LoLoThresh = 0.0;
	HiHiThresh = 0.0;
	Gain = 0.0;
	Card = @"N/A";
	Channel = 0;
	Number = 0;
	iosPort = 0;
	iosName = @"N/A";
	ioServerIPAddress = @"";
	ioChannelDocId = @"";
	isSlowControlParameterChanged = NO;
	isSelected = NO;
	isEnabled = YES;
	isConnected = YES;
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark •••Accessors
- (void) setParameterNumber:(int)aNumber
{
	Number = aNumber;
}

- (void) setParameterName:(NSString *)aString
{	
	[aString retain];
	[Name release];
	Name = aString;
}

- (void) setUnits:(NSString *)aString
{	
	[aString retain];
	[Units release];
	Units = aString;
}

- (void) setCardName:(NSString *)aString
{
	[aString retain];
	[Card release];
	Card = aString;
}

- (void) setIosName:(NSString *)aString
{
	[aString retain];
	[iosName release];
	iosName = aString;	
}

- (void) setChannelNumber:(int)aChannelNumber
{
	Channel = aChannelNumber;
}

- (void) setLoThresh:(float)aValue
{	
	LoThresh = aValue;
}

- (void) setHiThresh:(float)aValue
{
	HiThresh = aValue;
}

- (void) setLoLoThresh:(float)aValue
{	
	LoLoThresh = aValue;
}

- (void) setHiHiThresh:(float)aValue
{
	HiHiThresh = aValue;
}

- (void) setChannelGain:(float)aValue
{
	Gain = aValue;
}

- (void) setSlowControlParameterChanged:(BOOL)aBool
{
	isSlowControlParameterChanged = aBool;
}

- (void) setIPAddress:(NSString *)aString
{	
	[aString retain];
	[ioServerIPAddress release];	
	ioServerIPAddress = aString;
}

- (void) setPort:(int)aPort
{
	iosPort=aPort;
}

- (void) setParameterValue:(float)aValue
{
	Value = aValue;
}

- (void) setStatus:(NSString *)aString
{	
	[aString retain];
	[Status release];	
	Status = aString;
}

- (void) setSelected:(BOOL)aState
{
	isSelected = aState;
}

- (void) setParameterEnabled:(BOOL)aState
{
	isEnabled = aState;
}

- (void) setParameterConnected:(BOOL)aState
{
	isConnected = aState;
}

- (void) setIoChannelDocId:(NSString *)aString
{
	[aString retain];
	[ioChannelDocId release];	
	ioChannelDocId = aString;
}

- (BOOL) isSlowControlParameterChanged
{
	return isSlowControlParameterChanged;
}

- (int) parameterNumber
{
	return Number;
}

- (NSString *) parameterName
{
	return Name;
}

- (NSString *) parameterStatus
{	
	return Status;
}

- (float) parameterValue
{
	return Value;
}

- (NSString *) parameterUnits
{
	return Units;
}

- (float) parameterLoThreshold
{
	return LoThresh;
}

- (float) parameterHiThreshold
{
	return HiThresh;
}

- (float) parameterLoLoThreshold
{
	return LoLoThresh;
}

- (float) parameterHiHiThreshold
{
	return HiHiThresh;
}

- (float) parameterGain
{
	return Gain;
}

- (NSString *) parameterCard
{
	return Card;
}

- (NSString *) parameterIOS
{ 
	return iosName;
}

- (int) parameterChannel
{
	return Channel;
}

- (BOOL) parameterSelected
{
	return isSelected;
}

- (BOOL) parameterEnabled
{
	return isEnabled;
}

- (BOOL) parameterConnected
{
	return isConnected;
}

- (NSString *) IPAddress
{
	return ioServerIPAddress;
}

- (NSString *) parameterIoChannelDocId
{ 
	return ioChannelDocId;
}

- (int) Port
{
	return iosPort;
}

@end
