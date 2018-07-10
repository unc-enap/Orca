/*
 *  ORVHQ224LModel.cpp
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORVHQ224LModel.h"
#import "ORDataTypeAssigner.h"
#import "ORVmeCrateModel.h"
#import "ORDataPacket.h"

#pragma mark •••Definitions
#define kDefaultAddressModifier			0x29
#define kDefaultBaseAddress				0xDD00

#pragma mark •••Static Declarations
//offsets from the base address (kDefaultBaseAddress)
static unsigned long register_offsets[kNumberOfVHQ224LSRegisters] = {
	0x00,	//kStatusRegister1		[0] 	
	0x04,	//kSetVoltageA			[1] 	
	0x08,	//kSetVoltageB			[2] 	
	0x0C,	//kRampSpeedA			[3] 	
	0x10,	//kRampSpeedAB			[4]     
	0x14,	//kActVoltageA			[5] 	
	0x18,	//kActVoltageB			[6] 	
	0x1C,	//kActCurrentA			[7] 	
	0x20,	//kActCurrentB			[8] 	
	0x24,	//kLimitsA				[9] 	
	0x28,	//kLimitsB				[10] 	
	0x30,	//kStatusRegister2		[11] 	
	0x34,	//kStartVoltA			[12] 	
	0x38,	//kStartVoltB			[13] 	
	0x3C,	//kModID				[14] 	
	0x44,	//kSetCurrTripA			[15] 	
	0x48,	//kSetCurrTripB			[16] 	
};



#pragma mark •••Notification Strings
NSString* ORVHQ224LModelPollingErrorChanged = @"ORVHQ224LModelPollingErrorChanged";
NSString* ORVHQ224LModelStatusReg1Changed	= @"ORVHQ224LModelStatusReg2Changed";
NSString* ORVHQ224LModelStatusReg2Changed	= @"ORVHQ224LModelStatusReg2Changed";
NSString* ORVHQ224LSettingsLock				= @"ORVHQ224LSettingsLock";
NSString* ORVHQ224LSetVoltageChanged		= @"ORVHQ224LSetVoltageChanged";
NSString* ORVHQ224LActVoltageChanged		= @"ORVHQ224LActVoltageChanged";
NSString* ORVHQ224LRampRateChanged			= @"ORVHQ224LRampRateChanged";
NSString* ORVHQ224LPollTimeChanged			= @"ORVHQ224LPollTimeChanged";
NSString* ORVHQ224LModelTimeOutErrorChanged	= @"ORVHQ224LModelTimeOutErrorChanged";
NSString* ORVHQ224LActCurrentChanged		= @"ORVHQ224LActCurrentChanged";
NSString* ORVHQ224LMaxCurrentChanged		= @"ORVHQ224LMaxCurrentChanged";

@implementation ORVHQ224LModel

- (id) init //designated initializer
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
    [self setBaseAddress:kDefaultBaseAddress];
    [self setAddressModifier:kDefaultAddressModifier];
		
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super sleep];
}

- (void) wakeUp
{
	[super wakeUp];
	if(pollTime){
		[self pollHardware];
	}
}
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"VHQ224L"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORVHQ224LController"];
}

- (NSString*) helpURL
{
	return @"VME/VHQ224L.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x52);
}

- (short) numberSlotsUsed
{
    return 2; //default. override if needed.
}

#pragma mark •••Accessors

- (BOOL) pollingError
{
    return pollingError;
}

- (void) setPollingError:(BOOL)aPollingError
{
	if(pollingError!= aPollingError){
		pollingError = aPollingError;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHQ224LModelPollingErrorChanged object:self];
	}
}

- (unsigned short) statusReg1Chan:(unsigned short)aChan
{
	if(aChan>=kNumVHQ224LChannels)return 0;
    return statusReg1Chan[aChan];
}

- (void) setStatusReg1Chan:(unsigned short)aChan withValue:(unsigned short)aStatusWord
{
	if(aChan>=kNumVHQ224LChannels)return;
	if(statusReg1Chan[aChan] != aStatusWord || useStatusReg1Anyway[aChan]){
		statusChanged = YES;
		statusReg1Chan[aChan] = aStatusWord;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHQ224LModelStatusReg1Changed object:self userInfo:userInfo];
		useStatusReg1Anyway[aChan] = NO;
	}
}

- (unsigned short) statusReg2Chan:(unsigned short)aChan
{
	if(aChan>=kNumVHQ224LChannels)return 0;
    return statusReg2Chan[aChan];
}

- (void) setStatusReg2Chan:(unsigned short)aChan withValue:(unsigned short)aStatusWord
{
	if(aChan>=kNumVHQ224LChannels)return;
	if(statusReg2Chan[aChan] != aStatusWord){
		statusChanged = YES;
		statusReg2Chan[aChan] = aStatusWord;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHQ224LModelStatusReg2Changed object:self userInfo:userInfo];
	}
}

- (void) setTimeErrorState:(BOOL)aState
{
	if(timeOutError != aState){
		timeOutError = aState;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHQ224LModelTimeOutErrorChanged object:self];
	}
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
	[self pollHardware];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHQ224LPollTimeChanged object:self];
}

- (float) voltage:(unsigned short) aChan
{
	if(aChan>=kNumVHQ224LChannels)return 0;
    return voltage[aChan];
}

- (void) setVoltage:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumVHQ224LChannels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltage:aChan withValue:voltage[aChan]];
	voltage[aChan] = aVoltage;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHQ224LSetVoltageChanged object:self userInfo: nil];
}

- (float) actVoltage:(unsigned short) aChan
{
	if(aChan>=kNumVHQ224LChannels)return 0;
    return actVoltage[aChan];
}

- (void) setActVoltage:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumVHQ224LChannels)return;
	if(actVoltage[aChan] != aVoltage){
		if(fabs(actVoltage[aChan]-aVoltage)>1){
			statusChanged = YES;
		}
		actVoltage[aChan] = aVoltage;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHQ224LActVoltageChanged object:self userInfo: userInfo];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHQ224LModelStatusReg1Changed object:self userInfo: userInfo]; //also send this to force some updates
	}
}

- (float) actCurrent:(unsigned short) aChan
{
	if(aChan>=kNumVHQ224LChannels)return 0;
    return actCurrent[aChan];
}

- (void) setActCurrent:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumVHQ224LChannels)return;
	if(actCurrent[aChan] != aCurrent){
		statusChanged = YES;
		actCurrent[aChan] = aCurrent;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHQ224LActCurrentChanged object:self userInfo: userInfo];
	}
}

- (float) maxCurrent:(unsigned short) aChan
{
	if(aChan>=kNumVHQ224LChannels)return 0;
    return maxCurrent[aChan];
}

- (void) setMaxCurrent:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumVHQ224LChannels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxCurrent:aChan withValue:maxCurrent[aChan]];
	maxCurrent[aChan] = aCurrent;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHQ224LMaxCurrentChanged object:self userInfo: nil];
}

- (unsigned short) rampRate:(unsigned short) aChan
{
	if(aChan>=kNumVHQ224LChannels)return 2;
	return rampRate[aChan];
}

- (void) setRampRate:(unsigned short) aChan withValue:(unsigned short) aRampRate
{
	if(aChan>=kNumVHQ224LChannels)return;
	
	if(aRampRate<2)aRampRate = 2;
	else if(aRampRate>255)aRampRate = 255;
	
	[[[self undoManager] prepareWithInvocationTarget:self] setRampRate:aChan withValue:[self rampRate:aChan]];
	rampRate[aChan] = aRampRate;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORVHQ224LRampRateChanged object:self userInfo: nil];
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

#pragma mark •••Hardware Access
- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 )return;
    [[self undoManager] disableUndoRegistration];
	@try {
		[self readStatus1Word];
		[self readStatus2Word];
		[self readActVoltage:0];
		[self readActVoltage:1];
		[self readActCurrent:0];
		[self readActCurrent:1];
		if(statusChanged)[self shipVoltageRecords];
		[self setPollingError:NO];
	}
	@catch(NSException* e){
		[self setPollingError:YES];
		NSLogError(@"",@"VHQ224L",@"Polling Error",nil);
	}
	
    [[self undoManager] enableUndoRegistration];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (void) initBoard
{
}

- (void) loadValues:(unsigned short)aChannel
{
	useStatusReg1Anyway[aChannel] = YES; //force an update
	
	if(aChannel>=kNumVHQ224LChannels)return;
	unsigned short aValue;
	//set the ramp rate
	[[self adapter] writeWordBlock:&rampRate[aChannel]
						atAddress:[self baseAddress]+register_offsets[aChannel?kRampSpeedB:kRampSpeedA]
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	aValue = (unsigned short)voltage[aChannel];
	[[self adapter] writeWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[aChannel?kStartVoltB:kStartVoltA]
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	aValue = (unsigned short)maxCurrent[aChannel];
	[[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress]+register_offsets[aChannel?kSetCurrTripB:kSetCurrTripA]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) stopRamp:(unsigned short)aChannel
{
	if(aChannel>=kNumVHQ224LChannels)return;
	[self readActCurrent:aChannel];
	unsigned short aValue = (unsigned short)actVoltage[aChannel];
	[[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress]+register_offsets[aChannel?kStartVoltB:kStartVoltA]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
}

- (void) panicToZero:(unsigned short)aChannel
{
	if(aChannel>=kNumVHQ224LChannels)return;
	unsigned short aValue;
	//set the ramp rate
	unsigned short panicRate = 255;
	[[self adapter] writeWordBlock:&panicRate
						 atAddress:[self baseAddress]+register_offsets[aChannel?kRampSpeedB:kRampSpeedA]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	aValue = 0;
	[[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress]+register_offsets[aChannel?kStartVoltB:kStartVoltA]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	
}


- (unsigned short) readStatus1Word
{
	unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kStatusRegister1]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	[self setStatusReg1Chan:0 withValue:aValue&0x00ff];
	[self setStatusReg1Chan:1 withValue:(aValue&0xff00)>>8];
	
	return aValue;
}

- (unsigned short) readStatus2Word
{
	unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kStatusRegister2]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
		
	[self setStatusReg2Chan:0 withValue:(aValue&0x00ff)>>1];
	[self setStatusReg2Chan:1 withValue:(aValue&0xff00)>>9];
	[self setTimeErrorState:aValue&0x0001];
	
	return aValue;
}

- (float) readActVoltage:(unsigned short)aChan
{
	if(aChan>kNumVHQ224LChannels)return 0;
	unsigned short aValue = 0;
	int theOffset = (aChan == 0?kActVoltageA:kActVoltageB);
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[theOffset]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	[self setActVoltage:aChan withValue:aValue];
	return (float)aValue;
}

- (float) readActCurrent:(unsigned short)aChan
{
	if(aChan>kNumVHQ224LChannels)return 0;
	unsigned short aValue = 0;
	int theOffset = (aChan == 0?kActCurrentA:kActCurrentB);
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[theOffset]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	[self setActCurrent:aChan withValue:aValue];
	return (float)aValue;
}


- (void) readModuleID
{
	unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kModID]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	unsigned short serialNumber =	(aValue>>12)*1000 + 
									((aValue&0x0f00)>>8)*100 + 
									((aValue&0x00f0)>>4) *10 + 
									(aValue &0x000f);
	NSLog(@"VHQ224L (Slot %d) Serial Number = %d\n", [self slot], serialNumber);
}

#pragma mark •••Helpers
- (NSString*) rampStateString:(unsigned short)aChannel
{
	if(aChannel>=kNumVHQ224LChannels)return @"";
	if(!(statusReg1Chan[aChannel] & kHVSwitch)){
		if(statusReg1Chan[aChannel] & kStatV) {
			if(statusReg1Chan[aChannel] & kTrendV)	return @"Rising  ";
			else									return @"Falling ";
		}
		else {
			if(!(statusReg1Chan[aChannel] & kVZOut)) return @"Stable  ";
			else return @"HV OFF  ";
		}
	}
	else return kHVOff;
}

- (eVHQ224LRampingState) rampingState:(unsigned short)aChannel
{
	if(aChannel>=kNumVHQ224LChannels)return kHVOff;
	if(!(statusReg1Chan[aChannel] & kHVSwitch)){
		if(statusReg1Chan[aChannel] & kStatV) {
			if(statusReg1Chan[aChannel] & kTrendV)	return kHVRampingUp;
			else									return kHVRampingDn;
		}
		else {
			if(!(statusReg1Chan[aChannel] & kVZOut))return kHVStableHigh;
			else {
				if(actVoltage[aChannel]>2)return kHVStableLow;
				else return kHVOff;
			}
		}
	}
	else return kHVOff;
}

- (BOOL) polarity:(unsigned short)aChannel
{
	if(aChannel>=kNumVHQ224LChannels)return 0;
	return statusReg1Chan[aChannel] & kHVPolarity;
}

- (BOOL) hvPower:(unsigned short)aChannel
{
	if(aChannel>=kNumVHQ224LChannels)return 0;
	return !(statusReg1Chan[aChannel] & kHVSwitch); //reversed so YES is power on
}

- (BOOL) killSwitch:(unsigned short)aChannel
{
	if(aChannel>=kNumVHQ224LChannels)return 0;
	return (statusReg1Chan[aChannel] & kKillSwitch); 
}

- (BOOL) currentTripped:(unsigned short)aChannel
{
	if(aChannel>=kNumVHQ224LChannels)return 0;
	return (statusReg2Chan[aChannel] & kCurrentExceeded); 
}

- (BOOL) controlState:(unsigned short)aChannel
{
	if(aChannel>=kNumVHQ224LChannels)return NO;
	return !(statusReg1Chan[aChannel] & kHVControl);
}

- (BOOL) extInhibitActive:(unsigned short)aChannel
{
	if(aChannel>=kNumVHQ224LChannels)return NO;
	return (statusReg2Chan[aChannel] & kInibitActive);
}


#pragma mark •••Header Stuff
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"VHQ224LModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORVHQ224LDecoderForHVStatus",                 @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:NO],                   @"variable",
								 [NSNumber numberWithLong:11],					 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"HVStatus"];
    return dataDictionary;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	int i;	
	for(i=0;i<kNumVHQ224LChannels;i++){
		[self setVoltage:i withValue:   [decoder decodeFloatForKey:[NSString stringWithFormat:@"voltage%d",i]]];
		[self setMaxCurrent:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"maxCurrent%d",i]]];
		[self setRampRate:i withValue:  [decoder decodeIntForKey:  [NSString stringWithFormat:@"rampRate%d",i]]];
	}
	[self setPollTime:[decoder decodeIntForKey:@"pollTime"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	int i;	
	for(i=0;i<kNumVHQ224LChannels;i++){
		[encoder encodeFloat:voltage[i]    forKey:[NSString stringWithFormat:@"voltage%d",i]];
		[encoder encodeFloat:maxCurrent[i] forKey:[NSString stringWithFormat:@"maxCurrent%d",i]];
		[encoder encodeInt:rampRate[i]     forKey:[NSString stringWithFormat:@"rampRate%d",i]];
	}
	[encoder encodeInt:pollTime forKey:@"pollTime"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	NSArray* status1 = [NSArray arrayWithObjects:[NSNumber numberWithInt:statusReg1Chan[0]],[NSNumber numberWithInt:statusReg1Chan[1]],nil];
    [objDictionary setObject:status1 forKey:@"StatusReg1"];	

	NSArray* status2 = [NSArray arrayWithObjects:[NSNumber numberWithInt:statusReg2Chan[0]],[NSNumber numberWithInt:statusReg2Chan[1]],nil];
    [objDictionary setObject:status2 forKey:@"StatusReg2"];
	
	NSArray* theActVoltages = [NSArray arrayWithObjects:[NSNumber numberWithFloat:actVoltage[0]],[NSNumber numberWithFloat:actVoltage[1]],nil];
    [objDictionary setObject:theActVoltages forKey:@"Voltages"];
	
	NSArray* theActCurrents = [NSArray arrayWithObjects:[NSNumber numberWithFloat:actCurrent[0]],[NSNumber numberWithFloat:actCurrent[1]],nil];
    [objDictionary setObject:theActCurrents forKey:@"Currents"];
     	
	return objDictionary;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherVHQ224L
{
    [self setDataId:[anotherVHQ224L dataId]];
}

#pragma mark •••RecordShipper
- (void) shipVoltageRecords
{
	if([[ORGlobal sharedGlobal] runInProgress]){
		//get the time(UT!)
		time_t	ut_Time;
		time(&ut_Time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		
		unsigned long data[11];
		data[0] = dataId | 11;
		data[1] = [self uniqueIdNumber]&0xfff;
		data[2] = ut_Time;
		
		union {
			float asFloat;
			unsigned long asLong;
		}theData;
		int index = 3;
		int i;
		for(i=0;i<2;i++){
			data[index++] = statusReg1Chan[i];
			data[index++] = statusReg2Chan[i];

			theData.asFloat = actVoltage[i];
			data[index++] = theData.asLong;

			theData.asFloat = actCurrent[i];
			data[index++] = theData.asLong;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(long)*11]];
	}	
	statusChanged = NO;
}

@end
