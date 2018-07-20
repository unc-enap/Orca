// ORVHSC040nModel.,
// Orca
//
//  Created by Mark Howe on Mon Sept 13,2010.
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
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
#pragma mark •••Imported Files
#import "ORVHSC040nModel.h"
#import "ORDataTypeAssigner.h"
#import "ORVmeCrateModel.h"
#import "ORDataPacket.h"

#pragma mark •••Definitions
#define kDefaultAddressModifier			0x29
#define kDefaultBaseAddress				0x4000

#pragma mark •••Static Declarations
//offsets from the base address (kDefaultBaseAddress)
static uint32_t vhsc040ModuleRegOffsets[kNumberOfVHSC040nRegisters] = {
	0x00,	//kModuleStatus				[0] 	
	0x02,	//kModuleControl			[1] 	
	0x04,	//kModuleEventStatus		[2] 	
	0x06,	//kModuleEventMask			[3] 	
	0x08,	//kModuleEventChannelStatus	[4] 	
	0x0A,	//kModuleEventChannelMask	[5]     
	0x0C,	//kModuleEventGroupStatus	[6] 	
	0x10,	//kModuleEventGroupMask		[7] 	
	0x14,	//kVoltageRampSpeed			[8] 	
	0x18,	//kCurrentRampSpeed			[9] 	
	0x1C,	//kVoltageMax				[10] 	
	0x20,	//kCurrentMax				[11] 	
	0x24,	//kSupplyP5					[12] 	
	0x28,	//kSupplyP12				[13] 	
	0x2C,	//kSupplyN12				[14] 	
	0x30,	//kTemperature				[15] 	
	0x34,	//kSerialNumber				[16] 	
	0x38,	//kFirmwareRelease			[17] 	
	0x3C,	//kPlacedChannels			[18] 	
	0x3E,	//kDeviceClass				[19] 

	0x60,	//kChannel1StartOffset		[20]
	0x90,	//kChannel2StartOffset		[21]
	0xC0,	//kChannel3StartOffset		[22]
	0xF0,	//kChannel4StartOffset		[23]
	0x120,	//kChannel5StartOffset		[24]
	0x150,	//kChannel6StartOffset		[25]
	0x180,	//kChannel7StartOffset		[26]
	0x1B0,	//kChannel8StartOffset		[27]
	0x1E0,	//kChannel9StartOffset		[28]
	0x210,	//kChannel10StartOffset		[29]
	0x240,	//kChannel11StartOffset		[30]
	0x270,	//kChannel12StartOffset		[31]
};

static uint32_t vhsc040ChannelStartOffsets[kNumberOfVHSC040nChannelRegisters] = {
	0x60,
	0x90,
	0xC0,
	0xF0,
	0x120,	
	0x150,	
	0x180,
	0x1B0,	
	0x1E0,	
	0x210,	
	0x240,	
	0x270
};

static uint32_t vhsc040ChannelRegOffsets[kNumberOfVHSC040nChannelRegisters] = {
	0x00,	//kChannelStatus,
	0x02,	//kChannelControl,
	0x04,	//kChannelEventStatus,
	0x06,	//kChannelEventMask,
	0x08,	//kVoltageSet,
	0x0C,	//kCurrentSetTrip,
	0x10,	//kVoltageMeasure,
	0x14,	//kCurrentMeasure,
	0x18,	//kVoltageBounds,
	0x1C,	//kCurrentBounds,
	0x20,	//kVoltageNominal,
	0x24	//kCurrentNominal,
};



#pragma mark •••Notification Strings
NSString* ORVHSC040nModelFineAdjustEnabledChanged = @"ORVHSC040nModelFineAdjustEnabledChanged";
NSString* ORVHSC040nModelKillEnabledChanged = @"ORVHSC040nModelKillEnabledChanged";
NSString* ORVHSC040nTemperatureChanged				= @"ORVHSC040nTemperatureChanged";
NSString* ORVHSC040nSupplyN12Changed					= @"ORVHSC040nSupplyN12Changed";
NSString* ORVHSC040nSupplyP12Changed					= @"ORVHSC040nSupplyP12Changed";
NSString* ORVHSC040nSupplyP5Changed					= @"ORVHSC040nSupplyP5Changed";
NSString* ORVHSC040nVoltageRampSpeedChanged			= @"ORVHSC040nVoltageRampSpeedChanged";
NSString* ORVHSC040nModuleEventGroupStatusChanged	= @"ORVHSC040nModuleEventGroupStatusChanged";
NSString* ORVHSC040nModuleEventGroupMaskChanged		= @"ORVHSC040nModuleEventGroupMaskChanged";
NSString* ORVHSC040nModuleEventChannelMaskChanged	= @"ORVHSC040nModuleEventChannelMaskChanged";
NSString* ORVHSC040nModuleEventChannelStatusChanged = @"ORVHSC040nModuleEventChannelStatusChanged";
NSString* ORVHSC040nModuleEventMaskChanged			= @"ORVHSC040nModuleEventMaskChanged";
NSString* ORVHSC040nModuleEventStatusChanged			= @"ORVHSC040nModuleEventStatusChanged";
NSString* ORVHSC040nModuleControlChanged				= @"ORVHSC040nModuleControlChanged";
NSString* ORVHSC040nModuleStatusChanged				= @"ORVHSC040nModuleStatusChanged";
NSString* ORVHSC040nCurrentMaxChanged				= @"ORVHSC040nCurrentMaxChanged";
NSString* ORVHSC040nVoltageMaxChanged				= @"ORVHSC040nVoltageMaxChanged";
NSString* ORVHSC040nCurrentSetChanged					= @"ORVHSC040nCurrentSetChanged";

NSString* ORVHSC040nPollingErrorChanged				= @"ORVHSC040nPollingErrorChanged";
NSString* ORVHSC040nChannelStatusChanged				= @"ORVHSC040nChannelStatusChanged";
NSString* ORVHSC040nChannelEventStatusChanged		= @"ORVHSC040nChannelEventStatusChanged";
NSString* ORVHSC040nSettingsLock						= @"ORVHSC040nSettingsLock";

NSString* ORVHSC040nPollTimeChanged					= @"ORVHSC040nPollTimeChanged";
NSString* ORVHSC040nTimeOutErrorChanged				= @"ORVHSC040nTimeOutErrorChanged";
NSString* ORVHSC040nCurrentMeasureChanged			= @"ORVHSC040nCurrentMeasureChanged";
NSString* ORVHSC040nVoltageMeasureChanged			= @"ORVHSC040nVoltageMeasureChanged";
NSString* ORVHSC040nVoltageSetChanged				= @"ORVHSC040nVoltageSetChanged";
NSString* ORVHSC040nCurrentNominalChanged			= @"ORVHSC040nCurrentNominalChanged";
NSString* ORVHSC040nVoltageNominalChanged			= @"ORVHSC040nVoltageNominalChanged";
NSString* ORVHSC040nCurrentBoundsChanged				= @"ORVHSC040nCurrentBoundsChanged";
NSString* ORVHSC040nVoltageBoundsChanged				= @"ORVHSC040nVoltageBoundsChanged";

@interface ORVHSC040nModel (private)
- (float) convertTwoShortsToFloat:(unsigned short*)aValue;
- (void) pollHardware;
- (void) pollChannel:(int)aChannel;
@end


@implementation ORVHSC040nModel

- (id) init //designated initializer
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
    [self setBaseAddress:kDefaultBaseAddress];
    [self setAddressModifier:kDefaultAddressModifier];
	int i;
	for(i=0;i<kNumVHSC040nChannels;i++){
		[self setVoltageBounds:i withValue:3000];
		[self setCurrentBounds:i withValue:.003];
	}
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"VHSC040n"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORVHSC040nController"];
}

- (NSString*) helpURL
{
	return @"VME/VHSC040n.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x270 + 0x30);
}

- (short) numberSlotsUsed
{
    return 2; //default. override if needed.
}

#pragma mark •••Accessors
- (unsigned short)	moduleEventGroupStatus	{ return moduleEventGroupStatus; }
- (unsigned short)	moduleEventGroupMask	{ return moduleEventGroupMask; }
- (unsigned short)	moduleEventChannelMask	{ return moduleEventChannelMask; }
- (unsigned short)	moduleEventChannelStatus{ return moduleEventChannelStatus;}
- (unsigned short)	moduleEventMask			{ return moduleEventMask; }
- (unsigned short)	moduleEventStatus		{ return moduleEventStatus; }
- (unsigned short)	moduleControl			{ return moduleControl; }
- (unsigned short)	moduleStatus			{ return moduleStatus; }
- (float)			temperature				{ return temperature; }
- (float)			supplyN12				{ return supplyN12; }
- (float)			supplyP12				{ return supplyP12; }
- (float)			supplyP5				{ return supplyP5; }
- (float)			voltageRampSpeed		{ return voltageRampSpeed; }
- (BOOL)			pollingError			{ return pollingError; }
- (float)			voltageMax				{ return voltageMax; }
- (float)			currentMax				{ return currentMax; }
- (BOOL)			killEnabled				{ return killEnabled; }
- (BOOL)			fineAdjustEnabled		{ return fineAdjustEnabled; }

- (void) setFineAdjustEnabled:(BOOL)aFineAdjustEnabled
{
	[[[self undoManager] prepareWithInvocationTarget:self] setFineAdjustEnabled:fineAdjustEnabled];
	fineAdjustEnabled = aFineAdjustEnabled;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nModelFineAdjustEnabledChanged object:self];
}

- (void) setKillEnabled:(BOOL)aKillEnabled
{
	[[[self undoManager] prepareWithInvocationTarget:self] setKillEnabled:killEnabled];
	killEnabled = aKillEnabled;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nModelKillEnabledChanged object:self];
}
	
- (void) setTemperature:(float)aTemperature
{
    temperature = aTemperature;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nTemperatureChanged object:self];
}

- (void) setSupplyN12:(float)aSupplyN12
{
    supplyN12 = aSupplyN12;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nSupplyN12Changed object:self];
}

- (void) setSupplyP12:(float)aSupplyP12
{
    supplyP12 = aSupplyP12;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nSupplyP12Changed object:self];
}

- (void) setSupplyP5:(float)aSupplyP5
{
    supplyP5 = aSupplyP5;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nSupplyP5Changed object:self];
}

- (void) setVoltageMax:(float)aValue;
{
	voltageMax = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nVoltageMaxChanged object:self];
}

- (void) setCurrentMax:(float)aValue
{
	currentMax = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nCurrentMaxChanged object:self];
}

- (void) setVoltageRampSpeed:(float)aValue
{
	if(aValue<0)aValue=0;
	else if(aValue>20)aValue = 20;

    [[[self undoManager] prepareWithInvocationTarget:self] setVoltageRampSpeed:voltageRampSpeed];
    voltageRampSpeed = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nVoltageRampSpeedChanged object:self];
}

- (void) setModuleEventGroupStatus:(unsigned short)aValue
{
    moduleEventGroupStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nModuleEventGroupStatusChanged object:self];
}

- (void) setModuleEventGroupMask:(unsigned short)aValue
{
    moduleEventGroupMask = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nModuleEventGroupMaskChanged object:self];
}

- (void) setModuleEventChannelMask:(unsigned short)aValue
{
    moduleEventChannelMask = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nModuleEventChannelMaskChanged object:self];
}

- (void) setModuleEventChannelStatus:(unsigned short)aValue
{
    moduleEventChannelStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nModuleEventChannelStatusChanged object:self];
}

- (void) setModuleEventMask:(unsigned short)aValue
{
    moduleEventMask = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nModuleEventMaskChanged object:self];
}

- (void) setModuleEventStatus:(unsigned short)aValue
{
    moduleEventStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nModuleEventStatusChanged object:self];
}

- (void) setModuleControl:(unsigned short)aValue
{
	moduleControl = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nModuleControlChanged object:self];
}


- (void) setModuleStatus:(unsigned short)aValue
{
	if(moduleStatus != aValue){
		moduleStatus = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nModuleStatusChanged object:self];
	}
}

- (void) setPollingError:(BOOL)aValue
{
	if(pollingError!= aValue){
		pollingError = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nPollingErrorChanged object:self];
	}
}

- (unsigned short) channelStatus:(unsigned short)aChan
{
	if(aChan>=kNumVHSC040nChannels)return 0;
    return channelStatus[aChan];
}

- (void) setChannelStatus:(unsigned short)aChan withValue:(unsigned short)aValue
{
	if(aChan>=kNumVHSC040nChannels)return;
	if(channelStatus[aChan] != aValue ){
		statusChanged = YES;
		channelStatus[aChan] = aValue;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nChannelStatusChanged object:self userInfo:userInfo];
	}
}

- (unsigned short) channelEventStatus:(unsigned short)aChan
{
	if(aChan>=kNumVHSC040nChannels)return 0;
    return channelEventStatus[aChan];
}

- (void) setChannelEventStatus:(unsigned short)aChan withValue:(unsigned short)aValue
{
	if(aChan>=kNumVHSC040nChannels)return;
	if(channelEventStatus[aChan] != aValue){
		statusChanged = YES;
		channelEventStatus[aChan] = aValue;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nChannelEventStatusChanged object:self userInfo:userInfo];
	}
}

- (void) setTimeErrorState:(BOOL)aState
{
	if(timeOutError != aState){
		timeOutError = aState;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nTimeOutErrorChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nPollTimeChanged object:self];
}

- (float) voltageSet:(unsigned short) aChan
{
	if(aChan>=kNumVHSC040nChannels)return 0;
    return voltageSet[aChan];
}

- (void) setVoltageSet:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumVHSC040nChannels)return;
	if(voltageSet[aChan] != aVoltage){
		if(fabs(voltageSet[aChan]-aVoltage)>1){
			statusChanged = YES;
		}
		[[[self undoManager] prepareWithInvocationTarget:self] setVoltageSet:aChan withValue:voltageSet[aChan]];
		voltageSet[aChan] = aVoltage;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nVoltageSetChanged object:self userInfo: userInfo];
	}
}

- (float) voltageMeasure:(unsigned short) aChan
{
	if(aChan>=kNumVHSC040nChannels)return 0;
    return voltageMeasure[aChan];
}

- (void) setVoltageMeasure:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumVHSC040nChannels)return;
	if(voltageMeasure[aChan] != aVoltage){
		if(fabs(voltageMeasure[aChan]-aVoltage)>1){
			statusChanged = YES;
		}
		voltageMeasure[aChan] = aVoltage;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nVoltageMeasureChanged object:self userInfo: userInfo];
	}
}

- (float) currentMeasure:(unsigned short) aChan
{
	if(aChan>=kNumVHSC040nChannels)return 0;
    return currentMeasure[aChan];
}
- (void) setCurrentMeasure:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumVHSC040nChannels)return;
	if(currentMeasure[aChan] != aCurrent){
		statusChanged = YES;
		currentMeasure[aChan] = aCurrent;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nCurrentMeasureChanged object:self userInfo: userInfo];
	}
}
- (float) currentSet:(unsigned short) aChan
{
	if(aChan>=kNumVHSC040nChannels)return 0;
    return currentSet[aChan];
}

- (void) setCurrentSet:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumVHSC040nChannels)return;
	if(aCurrent<0)      aCurrent=0;
	else if(aCurrent>.003) aCurrent=.003;
	if(currentMeasure[aChan] != aCurrent){
		[[[self undoManager] prepareWithInvocationTarget:self] setCurrentSet:aChan withValue:currentSet[aChan]];
		statusChanged = YES;
		currentSet[aChan] = aCurrent;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nCurrentSetChanged object:self userInfo: userInfo];
	}
}

- (float) voltageNominal:(unsigned short) aChan
{
	if(aChan>=kNumVHSC040nChannels)return 0;
    return voltageNominal[aChan];
}

- (void) setVoltageNominal:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumVHSC040nChannels)return;
	if(voltageNominal[aChan] != aVoltage){
		if(fabs(voltageNominal[aChan]-aVoltage)>1){
			statusChanged = YES;
		}
		voltageNominal[aChan] = aVoltage;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nVoltageNominalChanged object:self userInfo: userInfo];
	}
}

- (float) currentNominal:(unsigned short) aChan
{
	if(aChan>=kNumVHSC040nChannels)return 0;
    return currentNominal[aChan];
}

- (void) setCurrentNominal:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumVHSC040nChannels)return;
	if(currentNominal[aChan] != aCurrent){
		statusChanged = YES;
		currentNominal[aChan] = aCurrent;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nCurrentNominalChanged object:self userInfo: userInfo];
	}
}

- (float) currentBounds:(unsigned short) aChan
{
	if(aChan>=kNumVHSC040nChannels)return 0;
    return currentBounds[aChan];
}

- (void) setCurrentBounds:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumVHSC040nChannels)return;
	
	if(aCurrent<0)			aCurrent = 0;
	else if(aCurrent>.003)  aCurrent = 0.003;
	
	[[[self undoManager] prepareWithInvocationTarget:self] setCurrentBounds:aChan withValue:currentBounds[aChan]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	currentBounds[aChan] = aCurrent;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nCurrentBoundsChanged object:self userInfo: userInfo];
}

- (float) voltageBounds:(unsigned short) aChan
{
	if(aChan>=kNumVHSC040nChannels)return 0;
    return voltageBounds[aChan];
}

- (void) setVoltageBounds:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumVHSC040nChannels)return;
	if(aVoltage<0)			aVoltage = 0;
	else if(aVoltage>.003)  aVoltage = 3000;
	[[[self undoManager] prepareWithInvocationTarget:self] setVoltageBounds:aChan withValue:voltageBounds[aChan]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	voltageBounds[aChan] = aVoltage;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORVHSC040nVoltageBoundsChanged object:self userInfo: userInfo];
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

#pragma mark •••Hardware Access
- (void) toggleHVOnOff:(unsigned short)aChannel
{
	if([self hvPower:aChannel]) [self turnOff:aChannel];
	else						{
		[self loadValues:aChannel];
		[self turnOn:aChannel];
	}
	[self readChannelStatus:aChannel];
}

- (void) loadValues:(unsigned short)aChannel
{
	[self loadModuleValues];
	[self writeVoltageBounds:aChannel];
	[self writeCurrentBounds:aChannel];
	[self writeCurrentSet:aChannel];
	[self writeVoltageSet:aChannel];
}

- (void) loadModuleValues
{	
	[self writeModuleControl];
	[self writeVoltageRampSpeed];
}

- (void) stopRamp:(unsigned short)aChannel
{
	
	if(aChannel>=kNumVHSC040nChannels)return;
	[self readVoltageMeasure:aChannel];
	unsigned short aValue = (unsigned short)voltageMeasure[aChannel];
	
	[self writeChannel:aChannel regIndex:kVoltageSet withFloatValue:aValue];	
}

- (void) panicToZero:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return;
	if(aChannel == 0xFFFF){
		int i;
		for(i=0;i<kNumVHSC040nChannels;i++){
			[self writeChannel:i regIndex:kVoltageSet withFloatValue:0];	
			[self writeEmergency:i];
		}
	}
	else {
		[self writeChannel:aChannel regIndex:kVoltageSet withFloatValue:0];	
		[self writeEmergency:aChannel];
	}
}

- (unsigned short) readModuleStatus
{
	unsigned short aValue = 0;
	 [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+vhsc040ModuleRegOffsets[kModuleStatus]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	[self setModuleStatus:aValue];
	return aValue;
}

- (unsigned short) readModuleEventStatus
{
	unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+vhsc040ModuleRegOffsets[kModuleEventStatus]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
		
	[self setModuleEventStatus:aValue];
	return aValue;
}

- (unsigned short) readChannelStatus:(unsigned short)aChan
{
	unsigned short aValue = 0;
	[[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+vhsc040ChannelStartOffsets[aChan] + vhsc040ChannelRegOffsets[kChannelStatus]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	[self setChannelStatus:aChan withValue:aValue];
	return aValue;
}

- (void) readModuleInfo
{
	unsigned short aValue[2];

	NSFont* f = [NSFont fontWithName:@"Monaco" size:12];
	NSLogFont(f,@"VHSC040n (Slot %d)\n", [self slot]);
 
	unsigned short firmware[4];
    [[self adapter] readWordBlock:firmware
						atAddress:[self baseAddress]+vhsc040ModuleRegOffsets[kFirmwareRelease]
						numToRead:4
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	NSLogFont(f,@"Firmware: %d.%d.%d.%d\n", firmware[0]&0xff, firmware[1]&0xff, firmware[2]&0xff, firmware[3]&0xff);
	
    [[self adapter] readWordBlock:aValue
						atAddress:[self baseAddress]+vhsc040ModuleRegOffsets[kSerialNumber]
						numToRead:2
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	NSLogFont(f,@"Serial Number: %u%u\n",aValue[0],aValue[1]);
	NSLogFont(f,@"Voltage Max  : pot set to %.0f%% = %.1f V\n",[self readVoltageMax],3000.*voltageMax/100.);
	NSLogFont(f,@"Current Max  : pot set to %.0f%% = %.2f mA\n",[self readCurrentMax],0.003*currentMax/100. * 1000.);
	NSLogFont(f,@"Ramp Speed   : %.1f%% = %.1f V/s\n",[self readModuleRegIndex:kVoltageRampSpeed],3000*voltageRampSpeed/100.);
	NSLogFont(f,@"P5           : %5.1f V\n",[self readModuleRegIndex:kSupplyP5]);
	NSLogFont(f,@"P12          : %5.1f V\n",[self readModuleRegIndex:kSupplyP12]);
	NSLogFont(f,@"N12          : %5.1f V\n",[self readModuleRegIndex:kSupplyN12]);
	NSLogFont(f,@"Temperature  : %5.1f C\n",[self readModuleRegIndex:kTemperature]);
	unsigned short theModuleStatus = [self readModuleStatus];

	NSLogFont(f,@"Supplies     : %@\n",(theModuleStatus & kPowerSupplyGood)				? @" OK": @"BAD");
	NSLogFont(f,@"Temperature  : %@\n",(theModuleStatus & kTemperatureGood)				? @" OK": @"BAD");
	NSLogFont(f,@"Module State : %@\n",(theModuleStatus & kModuleInStateGood)			? @" OK": @"BAD");
	NSLogFont(f,@"Event Active : %@\n",(theModuleStatus & kAnyEventIsActiveAndMaskSet)	? @"YES": @" NO");
	NSLogFont(f,@"IntLk Closed : %@\n",(theModuleStatus & kSafetyLoopClosed)			? @"YES": @" NO");
	NSLogFont(f,@"All Stable   : %@\n",(theModuleStatus & kAllChannelsStable)			? @"YES": @" NO");
	NSLogFont(f,@"Any Failures : %@\n",(theModuleStatus & kModuleWithoutFailure)		? @" NO": @"YES");
	NSLogFont(f,@"Cmds Complete: %@\n",(theModuleStatus & kIsCmdComplete)				? @"YES": @" NO");
	
	int i;
	NSLogFont(f,@"-----------------------------------------------------------------\n");
	NSLogFont(f,@"          Voltage        Current       Bounds           Nominal\n");
	NSLogFont(f,@"Chan     Set    Act     Set   Act  Voltage  Current  Voltage Current\n");
	for(i = 0; i < kNumVHSC040nChannels ; i++){
		NSLogFont(f,@"%4d: %6.1f %6.1f   %5.2f %5.2f    %5.1f    %5.3f   %6.1f   %5.3f\n",
					i,
					[self readChannel:i regIndex:kVoltageSet],
					[self readChannel:i regIndex:kVoltageMeasure],
					[self readChannel:i regIndex:kCurrentSetTrip],
					[self readChannel:i regIndex:kCurrentMeasure] * 1000,
					[self readChannel:i regIndex:kVoltageBounds],
					[self readChannel:i regIndex:kCurrentBounds] * 1000.,
					[self readChannel:i regIndex:kVoltageNominal],
					[self readChannel:i regIndex:kCurrentNominal]* 1000.);
	}
	NSLogFont(f,@"-----------------------------------------------------------------\n");
}

- (float) readVoltageMax
{
	float theFloatValue = [self readModuleRegIndex:kVoltageMax];
	[self setVoltageMax:theFloatValue];
	return theFloatValue;
}

- (float) readCurrentMax
{
	float theFloatValue = [self readModuleRegIndex:kCurrentMax];
	[self setCurrentMax:theFloatValue];
	return theFloatValue;
}

- (float) readTemperature
{
	float theFloatValue = [self readModuleRegIndex:kTemperature];
	[self setTemperature:theFloatValue];
	return theFloatValue;
}

- (float) readSupplyN12
{
	float theFloatValue = [self readModuleRegIndex:kSupplyN12];
	[self setSupplyN12:theFloatValue];
	return theFloatValue;
}

- (float) readSupplyP12
{
	float theFloatValue = [self readModuleRegIndex:kSupplyP12];
	[self setSupplyP12:theFloatValue];
	return theFloatValue;
}

- (float) readSupplyP5
{
	float theFloatValue = [self readModuleRegIndex:kSupplyP5];
	[self setSupplyP5:theFloatValue];
	return theFloatValue;
}

- (void) writeEmergency:(unsigned short)aChannel 
{
	unsigned short theValues = 0x20;
	[[self adapter] writeWordBlock:&theValues
						 atAddress:[self baseAddress] + vhsc040ChannelStartOffsets[aChannel] + vhsc040ChannelRegOffsets[kChannelControl]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) clearEmergency:(unsigned short)aChannel 
{
	unsigned short theValues = 0x00;
	[[self adapter] writeWordBlock:&theValues
						 atAddress:[self baseAddress] + vhsc040ChannelStartOffsets[aChannel] + vhsc040ChannelRegOffsets[kChannelControl]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}


- (void) turnOn:(unsigned short)aChannel 
{
	unsigned short theValues = 0x08;
	[[self adapter] writeWordBlock:&theValues
						atAddress:[self baseAddress] + vhsc040ChannelStartOffsets[aChannel] + vhsc040ChannelRegOffsets[kChannelControl]
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
}

- (void) turnOff:(unsigned short)aChannel 
{
	unsigned short theValues = 0x00;
	[[self adapter] writeWordBlock:&theValues
						atAddress:[self baseAddress] + vhsc040ChannelStartOffsets[aChannel] + vhsc040ChannelRegOffsets[kChannelControl]
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
}

- (void) writeVoltageSet:(unsigned short)aChannel
{
	[self writeChannel:aChannel regIndex:kVoltageSet withFloatValue:voltageSet[aChannel]];	
}

- (void) writeCurrentSet:(unsigned short)aChannel
{
	[self writeChannel:aChannel regIndex:kCurrentSetTrip withFloatValue:currentSet[aChannel]];	
}

- (void) writeVoltageBounds:(unsigned short)aChannel
{
	[self writeChannel:aChannel regIndex:kVoltageBounds withFloatValue:voltageBounds[aChannel]];	
}

- (void) writeCurrentBounds:(unsigned short)aChannel
{
	[self writeChannel:aChannel regIndex:kCurrentBounds withFloatValue:currentBounds[aChannel]];	
}

- (void) writeVoltageRampSpeed
{
	[self writeModuleRegIndex:kVoltageRampSpeed withFloatValue:voltageRampSpeed];
}

- (float) readVoltageNominal:(unsigned short)aChan
{
	float theFloatValue = [self readChannel:aChan regIndex:kCurrentNominal];
	[self setVoltageNominal:aChan withValue:theFloatValue];
	return theFloatValue;
}

- (float) readCurrentNominal:(unsigned short)aChan
{
	float theFloatValue = [self readChannel:aChan regIndex:kCurrentNominal];
	[self setCurrentNominal:aChan withValue:theFloatValue];
	return theFloatValue;
}

- (float) readVoltageMeasure:(unsigned short)aChan
{
	float theFloatValue = [self readChannel:aChan regIndex:kVoltageMeasure];
	[self setVoltageMeasure:aChan withValue:theFloatValue];
	return theFloatValue;
}

- (float) readCurrentMeasure:(unsigned short)aChan
{
	float theFloatValue = [self readChannel:aChan regIndex:kCurrentMeasure];
	[self setCurrentMeasure:aChan withValue:theFloatValue];
	return theFloatValue;
}

- (void) writeModuleControl
{
	unsigned short aValue = 0;
	if(killEnabled)			aValue |= kSetKillEnable;
	if(fineAdjustEnabled)	aValue |= kSetAdjustment;
	aValue |= kDoClear;
		
	[[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress]+vhsc040ModuleRegOffsets[kModuleControl]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];		
}

- (void) doClear
{
	unsigned short aValue = 0x40;
	[[self adapter] writeWordBlock:&aValue
						atAddress:[self baseAddress]+vhsc040ModuleRegOffsets[kModuleControl]
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];	
	
	int i;
	for(i=0;i<kNumVHSC040nChannels;i++){
		[self clearEmergency:i];
	}
}

#pragma mark •••Helpers

- (float) readModuleRegIndex:(int)anIndex
{
	unsigned short theValues[2];
	[[self adapter] readWordBlock:theValues
						atAddress:[self baseAddress]+vhsc040ModuleRegOffsets[anIndex]
						numToRead:2
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return [self convertTwoShortsToFloat:theValues];
}

- (void) writeModuleRegIndex:(int)anIndex withFloatValue:(float)aFloatValue
{
	unsigned short aValue[2];
	union {
		uint32_t l;
		float f;
	} d;
	d.f = aFloatValue;
	aValue[0] = (d.l & 0xffff0000) >> 16;
	aValue[1] =  d.l & 0xffff;
	[[self adapter] writeWordBlock:aValue
						 atAddress:[self baseAddress]+vhsc040ModuleRegOffsets[anIndex]
						numToWrite:2
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) writeChannel:(int)aChannel regIndex:(int)anIndex withFloatValue:(float)floatValue
{
	if(aChannel>kNumVHSC040nChannels)return;
	unsigned short aValue[2];
	union {
		uint32_t l;
		float f;
	} d;
	
	d.f = floatValue;
	aValue[0] = (d.l & 0xffff0000) >> 16;
	aValue[1] =  d.l & 0xffff;
	
	NSLog(@"floatValue: %f\n",[self convertTwoShortsToFloat:aValue]);
	[[self adapter] writeWordBlock:aValue
						 atAddress:[self baseAddress]+vhsc040ChannelStartOffsets[aChannel] + vhsc040ChannelRegOffsets[anIndex]
						numToWrite:2
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (float) readChannel:(int)aChannel regIndex:(int)anIndex
{
	if(aChannel>kNumVHSC040nChannels)return 0;
	unsigned short theValues[2];
    [[self adapter] readWordBlock:theValues
						atAddress:[self baseAddress]+vhsc040ChannelStartOffsets[aChannel] + vhsc040ChannelRegOffsets[anIndex]
						numToRead:2
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return [self convertTwoShortsToFloat:theValues];
}

- (NSString*) channelStatusString:(unsigned short)aChan
{
	NSString* s = @"";
	if([self isRamping:aChan])						s = @"Ramping";
	else  {
		if([self isInputError:aChan])				s = @"I/O";
		else if([self isEmergency:aChan])			s = @"Panic";
		else if([self isExternInhibit:aChan])		s = @"Ext Inhib";
		else if([self isTripSet:aChan])				s = @"I Trip";
		else if([self isVoltageLimitExceeded:aChan])s = @"V Limit";
		else if([self isCurrentLimitExceeded:aChan])s = @"I Limit";
		else if([self isCurrentOutOfBounds:aChan])	s = @"I Bounds";
		else if([self isVoltageOutOfBounds:aChan])	s = @"V Bounds";
		else if([self isControlledVoltage:aChan] || [self isControlledCurrent:aChan]){
			if([self isControlledVoltage:aChan])	s = @"CV";
			if([self isControlledCurrent:aChan]){
				if([s length]) s = [s stringByAppendingString:@"/CC"];
				else		 s = @"CC";
			}
		}
		else s = @"--";
	}
	return s;
}

- (BOOL) isVoltageOutOfBounds:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsVoltageBoundsExceeded) == kIsVoltageBoundsExceeded ;
}

- (BOOL) isCurrentOutOfBounds:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsCurrentBoundsExceeded) == kIsCurrentBoundsExceeded ;
}

- (BOOL) isVoltageLimitExceeded:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsVoltageLimitExceeded) == kIsVoltageLimitExceeded ;
}

- (BOOL) isCurrentLimitExceeded:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsCurrentLimitExceeded) == kIsCurrentLimitExceeded ;
}

- (BOOL) isControlledVoltage:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsControlledVoltage) == kIsControlledVoltage ;
}

- (BOOL) isControlledCurrent:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsControlledCurrent) == kIsControlledCurrent ;
}

- (BOOL) isEmergency:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsEmergency) == kIsEmergency ;
}

- (BOOL) isInputError:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kInputError) == kInputError ;
}

- (BOOL) isRamping:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsRamping) == kIsRamping ;
}

- (BOOL) hvPower:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsOn) == kIsOn ;
}

- (BOOL) isTripSet:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsTripSet) == kIsTripSet; 
}

- (BOOL) isExternInhibit:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsExtInhibit)==kIsExtInhibit; 
}

- (BOOL) isCurrentTrip:(unsigned short)aChannel
{
	if(aChannel>=kNumVHSC040nChannels)return NO;
	return (channelStatus[aChannel] & kIsTripSet)==kIsTripSet; 
}


#pragma mark •••Header Stuff
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"VHSC040nModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORVHSC040nDecoderForHVStatus",                 @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:NO],                   @"variable",
								 [NSNumber numberWithLong:kVHS403DataRecordLength],	@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"HVStatus"];
    return dataDictionary;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	[self setFineAdjustEnabled:	[decoder decodeBoolForKey: @"fineAdjustEnabled"]];
    [self setKillEnabled:		[decoder decodeBoolForKey: @"killEnabled"]];
	[self setPollTime:			[decoder decodeIntForKey:  @"pollTime"]];
	[self setVoltageRampSpeed:	[decoder decodeFloatForKey:@"voltageRampSpeed"]];
	
	int i;	
	for(i=0;i<kNumVHSC040nChannels;i++){
 		[self setVoltageSet:i withValue:	[decoder decodeFloatForKey:[NSString stringWithFormat:@"voltageSet%d",i]]];
 		[self setCurrentSet:i withValue:	[decoder decodeFloatForKey:[NSString stringWithFormat:@"currentSet%d",i]]];
		[self setVoltageBounds:i withValue: [decoder decodeFloatForKey:[NSString stringWithFormat:@"voltageBounds%d",i]]];
		[self setCurrentBounds:i withValue:	[decoder decodeFloatForKey:[NSString stringWithFormat:@"currentBounds%d",i]]];
	}


	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeBool:fineAdjustEnabled	forKey:@"fineAdjustEnabled"];
	[encoder encodeBool:killEnabled			forKey:@"killEnabled"];
	[encoder encodeInteger:pollTime				forKey:@"pollTime"];
	[encoder encodeFloat:voltageRampSpeed	forKey:@"voltageRampSpeed"];
	int i;	
	for(i=0;i<kNumVHSC040nChannels;i++){
		[encoder encodeFloat:voltageSet[i]    forKey:[NSString stringWithFormat:@"voltageSet%d",i]];
		[encoder encodeFloat:currentSet[i]    forKey:[NSString stringWithFormat:@"currentSet%d",i]];
		[encoder encodeFloat:voltageBounds[i] forKey:[NSString stringWithFormat:@"voltageBounds%d",i]];
		[encoder encodeFloat:currentBounds[i] forKey:[NSString stringWithFormat:@"currentBounds%d",i]];
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	NSArray* status1 = [NSArray arrayWithObjects:
						[NSNumber numberWithInt:channelStatus[0]],
						[NSNumber numberWithInt:channelStatus[1]],
						[NSNumber numberWithInt:channelStatus[2]],
						[NSNumber numberWithInt:channelStatus[3]],
						nil];
    [objDictionary setObject:status1 forKey:@"ChannelStatus"];	

	NSArray* status2 = [NSArray arrayWithObjects:
						[NSNumber numberWithInt:channelEventStatus[0]],
						[NSNumber numberWithInt:channelEventStatus[1]],
						[NSNumber numberWithInt:channelEventStatus[2]],
						[NSNumber numberWithInt:channelEventStatus[3]],
						nil];
    [objDictionary setObject:status2 forKey:@"ChannelEventStatus"];
	
	NSArray* theVoltageMeasures = [NSArray arrayWithObjects:
								   [NSNumber numberWithFloat:voltageMeasure[0]],
								   [NSNumber numberWithFloat:voltageMeasure[1]],
								   [NSNumber numberWithFloat:voltageMeasure[2]],
								   [NSNumber numberWithFloat:voltageMeasure[3]],
								   nil];
    [objDictionary setObject:theVoltageMeasures forKey:@"Voltages"];
	
	NSArray* theCurrentMeasures = [NSArray arrayWithObjects:
								   [NSNumber numberWithFloat:currentMeasure[0]],
								   [NSNumber numberWithFloat:currentMeasure[1]],
								   [NSNumber numberWithFloat:currentMeasure[2]],
								   [NSNumber numberWithFloat:currentMeasure[3]],
								   nil];
    [objDictionary setObject:theCurrentMeasures forKey:@"Currents"];

	return objDictionary;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherVHSC040n
{
    [self setDataId:[anotherVHSC040n dataId]];
}

#pragma mark •••RecordShipper
- (void) shipVoltageRecords
{
	if([[ORGlobal sharedGlobal] runInProgress]){
		//get the time(UT!)
		time_t	ut_Time;
		time(&ut_Time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		
		uint32_t data[kVHS403DataRecordLength];
		data[0] = dataId | kVHS403DataRecordLength;
		data[1] = [self uniqueIdNumber]&0xfff;
		data[2] = (uint32_t)ut_Time;
		
		union {
			float asFloat;
			uint32_t asLong;
		}theData;
		int index = 3;
		int i;
		for(i=0;i<kNumVHSC040nChannels;i++){
			data[index++] = channelStatus[i];
			data[index++] = channelEventStatus[i];

			theData.asFloat = voltageMeasure[i];
			data[index++] = theData.asLong;

			theData.asFloat = currentMeasure[i];
			data[index++] = theData.asLong;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(int32_t)*kVHS403DataRecordLength]];
	}	
	statusChanged = NO;
}
@end

@implementation ORVHSC040nModel (private)
- (float) convertTwoShortsToFloat:(unsigned short*)aValue;
{
	uint32_t theLongValue = (((int32_t)aValue[0]<<16) | aValue[1]);
	union {
		uint32_t l;
		float f;
	} d;
	d.l = theLongValue;
	return d.f;
}

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 )return;
    [[self undoManager] disableUndoRegistration];
	@try {
		[self readSupplyP5];
		[self readSupplyP12];
		[self readSupplyN12];
		[self readTemperature];
		[self readModuleStatus];
		[self readModuleEventStatus];
		[self readVoltageMax];
		[self readCurrentMax];
		int i;
		for(i=0;i<kNumVHSC040nChannels;i++){
			[self pollChannel:i];
		}
		
		if(statusChanged)[self shipVoltageRecords];
		
		[self setPollingError:NO];
	}
	@catch(NSException* e){
		[self setPollingError:YES];
		NSLogError(@"",@"VHSC040n",@"Polling Error",nil);
	}
	
	
    [[self undoManager] enableUndoRegistration];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}


- (void) pollChannel:(int)aChannel
{	
	[self readChannelStatus:aChannel];
	[self readVoltageMeasure:aChannel];
	[self readCurrentMeasure:aChannel];
	if(voltageNominal[aChannel] < 1){
		[self readVoltageNominal:aChannel];
		[self readCurrentNominal:aChannel];
	}
}

@end
