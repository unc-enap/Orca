//
//  SNOSlowcontrol.h
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

#define  kNumSlowControlParameters	190
#define  kMaxNumCards 4
#define  kMaxNumChannels 20

@interface SNOSlowControl : NSObject
{
	NSString* Name;
	NSString* Status;
	float Value;
	NSString* Units;
	float LoThresh;
	float HiThresh;
	float LoLoThresh;
	float HiHiThresh;
	float Gain;
	NSString* Card;
	int Channel;
	int Number;
	int iosPort;
	BOOL isSlowControlParameterChanged;
	BOOL isSelected;
	BOOL isEnabled;
	BOOL isConnected;
	NSString* ioServerIPAddress;
	NSString* iosName;
	NSString* ioChannelDocId;
}

#pragma mark •••Initialization
- (void) dealloc;

#pragma mark •••Accessors
- (void) setParameterNumber:(int)aNumber;
- (void) setParameterName:(NSString *)aString;
- (void) setUnits:(NSString *)aString;
- (void) setCardName:(NSString *)aString;
- (void) setIosName:(NSString *)aString;
- (void) setChannelNumber:(int)aChannelNumber;
- (void) setLoThresh:(float)aValue;
- (void) setHiThresh:(float)aValue;
- (void) setLoLoThresh:(float)aValue;
- (void) setHiHiThresh:(float)aValue;
- (void) setChannelGain:(float)aValue;
- (void) setSlowControlParameterChanged:(BOOL)aBool;
- (void) setIPAddress:(NSString *)aString;
- (void) setPort:(int)aPort;
- (void) setParameterValue:(float)aValue;
- (void) setStatus:(NSString *)aString;
- (void) setSelected:(BOOL)aState;
- (void) setParameterEnabled:(BOOL)aState;
- (void) setParameterConnected:(BOOL)aState;
- (void) setIoChannelDocId:(NSString *)aString;
- (BOOL) isSlowControlParameterChanged;
- (int) parameterNumber;
- (NSString *) parameterName;
- (NSString *) parameterStatus;
- (float) parameterValue;
- (NSString *) parameterUnits;
- (float) parameterLoThreshold;
- (float) parameterHiThreshold;
- (float) parameterLoLoThreshold;
- (float) parameterHiHiThreshold;
- (float) parameterGain;
- (NSString *) parameterCard;
- (NSString *) parameterIOS;
- (int) parameterChannel;
- (BOOL) parameterSelected;
- (BOOL) parameterEnabled;
- (BOOL) parameterConnected;
- (NSString *) IPAddress;
- (NSString *) parameterIoChannelDocId;
- (int) Port;

@end