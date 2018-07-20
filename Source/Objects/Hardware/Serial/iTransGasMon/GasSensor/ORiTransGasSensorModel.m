//
//  ORiiTransSensorModel.m
//  
//
//  Created by Mark Howe on Tue May 18 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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

#import "ORiTransGasSensorModel.h"
#import "ORModBusModel.h"
#import "ORAlarm.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"

NSString* ORiTransGasSensorModelChannelChanged		= @"ORiTransGasSensorModelChannelChanged";
NSString* ORiTransGasSensorModelNameChanged			= @"ORiTransGasSensorModelNameChanged";
NSString* ORiTransGasSensorBaseAddressChanged		= @"ORiTransGasSensorBaseAddressChanged";
NSString* ORiTransGasSensorGasSensorTypeChanged		= @"ORiTransGasSensorGasSensorTypeChanged";
NSString* ORiTransGasSensorGasReadingChanged		= @"ORiTransGasSensorGasReadingChanged";
NSString* ORiTransGasSensorGasTypeChanged			= @"ORiTransGasSensorGasTypeChanged";
NSString* ORiTransGasSensorStatusBitsChanged		= @"ORiTransGasSensorStatusBitsChanged";
NSString* ORiTransGasSensorLastAlarmDateChanged		= @"ORiTransGasSensorLastAlarmDateChanged";
NSString* ORiTransGasSensorLastAlarmYearChanged		= @"ORiTransGasSensorLastAlarmYearChanged";
NSString* ORiTransGasSensorRtcDateChanged			= @"ORiTransGasSensorRtcDateChanged";
NSString* ORiTransGasSensorRtcYearChanged			= @"ORiTransGasSensorRtcYearChanged";
NSString* ORiTransGasSensorLowAlarmSettingChanged	= @"ORiTransGasSensorLowAlarmSettingChanged";
NSString* ORiTransGasSensorHighAlarmSettingChanged	= @"ORiTransGasSensorHighAlarmSettingChanged";
NSString* ORiTransGasSensorCalGasValueChanged		= @"ORiTransGasSensorCalGasValueChanged";
NSString* ORiTransGasSensorLoopHighScalingChanged	= @"ORiTransGasSensorLoopHighScalingChanged";
NSString* ORiTransRemoveGasSensor					= @"ORiTransRemoveGasSensor";
NSString* ORiTransGasDecimalPlacesChanged			= @"ORiTransGasDecimalPlacesChanged";

#define kSensorTypeReg			40101
#define kGasReadingReg			40102
#define kGasReadingReg2			40102
#define kGasTypeReg				40103
#define kStatusReg				40106
#define kLastAlarmMMDDReg		40115
#define kLastAlarm00YYReg		40116
#define kRTCMMDDReg				40117
#define kRTC00YYReg				40118
#define kRTC00HHMMReg			40119
#define kLowAlarmSettingReg		40124
#define kHighAlarmSettingReg	40125

#define kChannelOffset			100

@implementation ORiTransGasSensorModel

+ (id) sensor
{
	return [[[ORiTransGasSensorModel alloc] init] autorelease];
}

-(id)	init
{
    if( self = [super init] ){
		fullRead = YES;
    }
    return self;
}

- (void) dealloc
{
    [sensorName release];
	[gasAlarm clearAlarm];
	[gasAlarm release];
    [super dealloc];
}

- (NSUndoManager *)undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

#pragma mark ***Accessors

- (int) channel
{
    return channel;
}

- (void) setChannel:(int)aChannel
{
	if(aChannel>=0 && aChannel<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:channel];
		channel = aChannel;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorModelChannelChanged object:self];
	}
}

- (NSString*) sensorName
{
	if(!sensorName)return @"";
    else return sensorName;
}

- (void) setSensorName:(NSString*)aName
{
	if(!aName)aName = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setSensorName:sensorName];
    
    [sensorName autorelease];
    sensorName = [aName copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorModelNameChanged object:self];
}

- (void) setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

- (int)  baseAddress
{
	return baseAddress;
}

- (void) setBaseAddress:(int)aValue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setBaseAddress:baseAddress];
    baseAddress = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorBaseAddressChanged object:self];
}

- (int)  sensorType
{
	return sensorType;
}

- (void) setSetSensorType:(int)aValue
{
    sensorType = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorGasSensorTypeChanged object:self];
}

- (int)  gasReading
{
	return gasReading;
}

- (void) setGasReading:(int)aValue
{
	time_t	ut_Time;
	time(&ut_Time);
	timeMeasured = (uint32_t)ut_Time;
	
    gasReading = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorGasReadingChanged object:self];
}

- (int)  gasType
{
	return gasType;
}

- (void) setGasType:(int)aValue
{
    gasType = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorGasTypeChanged object:self];
}

- (int)  statusBits;
{
	return statusBits;
}

- (void) setStatusBits:(int)aValue 
{
    statusBits = aValue;
	if(statusBits & 0x3){
		if(!gasAlarm){
			NSString* name;
			if([sensorName length])name = sensorName;
			else name = [NSString stringWithFormat:@"iTrans Gas Sensor: %d,%d",baseAddress,channel];
			gasAlarm = [[ORAlarm alloc] initWithName:name severity:kRangeAlarm];
			[gasAlarm setSticky:YES];
			[gasAlarm postAlarm];	
		}
	}
	else {
		[gasAlarm clearAlarm];
		[gasAlarm release];
		gasAlarm = nil;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorStatusBitsChanged object:self];
}

- (int)  lastAlarmDate 
{
	return lastAlarmDate;
}

- (void) setLastAlarmDate:(int)aValue 
{
    lastAlarmDate = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorLastAlarmDateChanged object:self];
}

- (int)  lastAlarmYear 
{
	return lastAlarmYear;
}

- (void) setLastAlarmYear:(int)aValue 
{
    lastAlarmYear = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorLastAlarmYearChanged object:self];
}

- (int)  rtcDate 
{
	return rtcDate;
}

- (void) setRtcDate:(int)aValue 
{
    rtcDate = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorRtcDateChanged object:self];
}

- (int)  rtcYear 
{
	return rtcYear;
}

- (void) setRtcYear:(int)aValue 
{
    rtcYear = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorRtcYearChanged object:self];
}

- (int)  lowAlarmSetting 
{
	return lowAlarmSetting;
}

- (void) setLowAlarmSetting:(int)aValue 
{
    lowAlarmSetting = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorLowAlarmSettingChanged object:self];
}

- (int)  highAlarmSetting 
{
	return highAlarmSetting;
}

- (void) setHighAlarmSetting:(int)aValue 
{
     highAlarmSetting = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorHighAlarmSettingChanged object:self];
}

- (int)  calGasValue 
{
	return calGasValue;
}

- (void) setCalGasValue:(int)aValue 
{
    calGasValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorCalGasValueChanged object:self];
}

- (int)  loopHighScaling 
{
	return loopHighScaling;
}

- (void) setLoopHighScaling:(int)aValue 
{
    loopHighScaling = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasSensorLoopHighScalingChanged object:self];
}

- (int)  decimalPlaces
{
	return decimalPlaces;
}

- (void) setDecimalPlaces:(int)aValue 
{
    decimalPlaces = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiTransGasDecimalPlacesChanged object:self];
}

#pragma mark •••Helpers
- (NSString*) formattedGasReading
{
	NSString* theFormat = [NSString stringWithFormat:@"%%.%df",[self decimalPlaces]];
	float theValue = (float)[self gasReading];
	theValue = theValue/powf(10.0,(float)[self decimalPlaces]);
	return [NSString stringWithFormat:theFormat,theValue];
}

- (NSString*) gasType:(int)aType fullName:(BOOL)full
{
	switch(aType){
		case 0x01: return full ? @"Carbon Monoxide"	 : @"CO";
		case 0x02: return full ? @"Hydrogen Sulfide" : @"H2S";
		case 0x03: return full ? @"Sulfur Dioxide"	 : @"SO2";
		case 0x04: return full ? @"Nitrogen Dioxide" : @"NO2";
		case 0x05: return full ? @"Chlorine"		 : @"Cl2";
		case 0x06: return full ? @"Cholorine Dioxide": @"ClO2";
		case 0x07: return full ? @"Hydrogen Cyanide" : @"HCN";
		case 0x08: return full ? @"Phosphine"		 : @"PH3";
		case 0x09: return full ? @"Hydrogen"		 : @"H2";
		case 0x0C: return full ? @"Nitric Oxide"	 : @"NO";
		case 0x0D: return full ? @"Ammonia"			 : @"NH3";
		case 0x0E: return full ? @"Hydrogen Chloride": @"HCl";
		case 0x14: return full ? @"Oxygen"			 : @"O2";
		case 0x15: return full ? @"Methane"			 : @"CH4";
		case 0x16: return full ? @"Explosive Limit"	 : @"LEL";
		default:   return full ? @"Unknown"			 :@"??";
	}
}

- (NSString*) sensorType:(int)aType fullName:(BOOL)full
{
	switch(aType){
		case 0x03: return full ? @"Broad Band Infrared"	 : @"BBIR";
		case 0x04: return full ? @"Toxic"				 : @"TOX";
		case 0x05: return full ? @"Oxygen"				 : @"OXY";
		case 0x06: return full ? @"Toxic"				 : @"CAT";
		default:   return full ? @"Unknown"				 :@"??";
	}
}

- (float) gasReadingConversion:(unsigned short)aValue
{
	if((aValue>>16) == 1) return -1 * (float)(~aValue + 1);
	else				  return (float)aValue;
}

- (void) setFullRead:(BOOL)aState
{
	fullRead = aState;
}

- (int) offsetReg:(int)aReg
{
	return aReg + channel*kChannelOffset;
}

- (int) extractChanFrom:(int)aCommand
{
	//401xx == channel 0
	//402xx == channel 1
	return aCommand/100 - 401;
}

- (void) readValues:(ORModBusModel*)modBus
{
	if(baseAddress!=0){
		if(fullRead){
			[modBus readHoldingReg:[self offsetReg:kSensorTypeReg] deviceAddress:baseAddress];
			[modBus readHoldingReg:[self offsetReg:kGasTypeReg] deviceAddress:baseAddress];
			fullRead = NO;
		}
		[modBus readHoldingReg:[self offsetReg:kGasReadingReg] deviceAddress:baseAddress];
		[modBus readHoldingReg:[self offsetReg:kStatusReg] deviceAddress:baseAddress];
	}
}

- (void) processRegister:(int)aReg value:(int)aValue
{
	int aChan = [self extractChanFrom:aReg];
	if(aChan == channel){
		if(aReg == [self offsetReg:kGasTypeReg]){
			[self setGasType:aValue&0xff];
			[self setDecimalPlaces:aValue>>8];
		}
		else if(aReg == [self offsetReg:kGasReadingReg]){
			[self setGasReading:aValue];
		}
		else if(aReg == [self offsetReg:kSensorTypeReg]){
			[self setSetSensorType:aValue>>8];
		}
		else if(aReg == [self offsetReg:kStatusReg]){
			[self setStatusBits:aValue];
		}
	}
}

#pragma mark •••Data Records
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObject
{
    [self setDataId:[anotherObject dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"iTransGasSensorModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORiTrasGasSensorDecoderForValue", @"decoder",
								 [NSNumber numberWithLong:dataId],   @"dataId",
								 [NSNumber numberWithBool:NO],       @"variable",
								 [NSNumber numberWithLong:8],        @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"GasValue"];
    
    return dataDictionary;
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
	fullRead = YES;
    [[self undoManager] disableUndoRegistration];
    [self setChannel:	 [decoder decodeIntForKey:@"channel"]];
    [self setSensorName: [decoder decodeObjectForKey:@"sensorName"]];
    [self setBaseAddress:[decoder decodeIntForKey:@"baseAddress"]];
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInteger:channel		 forKey:@"channel"];
    [encoder encodeObject:sensorName forKey:@"sensorName"];
    [encoder encodeInteger:baseAddress	 forKey:@"baseAddress"];
}

- (void) shipDataRecords
{
    if([[ORGlobal sharedGlobal] runInProgress] && (dataId != 0)){
		
		union {
			float asFloat;
			uint32_t asLong;
		}theData;
		
		uint32_t data[8];
		data[0] = dataId | 8;
		data[1] = (channel<<16) | ([delegate uniqueIdNumber]&0xfff);
		
		data[2] = timeMeasured;
		
		theData.asFloat = [[self formattedGasReading] floatValue];
		data[3] = theData.asLong;
		
		data[4] = statusBits;
		data[5] = gasType;
		data[6] = gasType;
		data[7] = gasType;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(int32_t)*8]];
	}
}

@end


