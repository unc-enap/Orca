//
//  ORCaen419Model.m
//  Orca
//
//  Created by Mark Howe on 2/20/09
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nug Physics and 
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
#import "ORCaen419Model.h"
#import "ORVmeCrateModel.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#include "VME_HW_Definitions.h"
#import "ORRateGroup.h"

#define k419DefaultBaseAddress 		0xFFE000
#define k419DefaultAuxAddress 		0xFFC000
#define k419DefaultAddressModifier	0x39

NSString* ORCaen419ModelEnabledMaskChanged		= @"ORCaen419ModelEnabledMaskChanged";
NSString* ORCaen419ModelResetMaskChanged		= @"ORCaen419ModelResetMaskChanged";
NSString* ORCaen419ModelRiseTimeProtectionChanged = @"ORCaen419ModelRiseTimeProtectionChanged";
NSString* ORCaen419ModelLinearGateModeChanged	  = @"ORCaen419ModelLinearGateModeChanged";
NSString* ORCaen419ModelAuxAddressChanged		= @"ORCaen419ModelAuxAddressChanged";
NSString* ORCaen419LowThresholdChanged			= @"ORCaen419LowThresholdChanged";
NSString* ORCaen419HighThresholdChanged			= @"ORCaen419HighThresholdChanged";
NSString* ORCaen419BasicLock					= @"ORCaen419BasicLock";
NSString* ORCaen419RateGroupChangedNotification = @"ORShaperRateGroupChangedNotification";

static Caen419Registers reg[kNumRegisters] = {
	{@"Channel 0 Data",		0x00},
	{@"Channel 1 Data",		0x04},
	{@"Channel 2 Data",		0x08},
	{@"Channel 3 Data",		0x0C},
	{@"Channel 0 Status",	0x02},
	{@"Channel 1 Status",	0x06},
	{@"Channel 2 Status",	0x0A},
	{@"Channel 3 Status",	0x0E},
	{@"Chan 0 Low Thres",	0x10},
	{@"Chan 0 Hi  Thres",	0x12},
	{@"Chan 1 Low Thres",	0x14},
	{@"Chan 1 Hi  Thres",	0x16},
	{@"Chan 2 Low Thres",	0x18},
	{@"Chan 2 Hi  Thres",	0x1A},
	{@"Chan 3 Low Thres",	0x1C},
	{@"Chan 3 Hi  Thres",	0x1E},
};

@implementation ORCaen419Model
#pragma mark •••Initialization
- (id) init
{
    self = [super init];
	[[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:		k419DefaultBaseAddress];
    [self setAuxAddress:		k419DefaultAuxAddress];
    [self setAddressModifier:	k419DefaultAddressModifier];
	[self setAdcRateGroup:[[[ORRateGroup alloc] initGroup:kCV419NumberChannels groupTag:0] autorelease]];
	[adcRateGroup setIntegrationTime:5];
	
	[[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [adcRateGroup quit];
    [adcRateGroup release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Caen419"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCaen419Controller"];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x1E);
}

- (NSString*) helpURL
{
	return @"VME/V419.html";
}

- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (NSString*) getRegisterName: (short) anIndex
{
	return reg[anIndex].regName;
}

- (uint32_t) getAddressOffset: (short) anIndex
{
    return( reg[anIndex].addressOffset );
}


- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 419 (Slot %d) ",[self slot]];
}
#pragma mark ***Accessors

- (short) enabledMask
{
    return enabledMask;
}

- (void) setEnabledMask:(short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
    enabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen419ModelEnabledMaskChanged object:self];
}

- (void) setReset:(short)aChan withValue:(BOOL)aValue
{	
	short aMask = [self resetMask];
	if(aValue) aMask |= (1<<aChan);
	else aMask &= ~(1<<aChan);
	[self setResetMask:aMask];
}
- (BOOL) reset:(short)aChan
{
	return [self resetMask] & (1<<aChan);
}

- (void) setEnabled:(short)aChan withValue:(BOOL)aValue
{	
	short aMask = [self enabledMask];
	if(aValue) aMask |= (1<<aChan);
	else aMask &= ~(1<<aChan);
	[self setEnabledMask:aMask];
}
- (BOOL) enabled:(short)aChan
{
	return [self resetMask] & (1<<aChan);
}


- (short) resetMask
{
    return resetMask;
}

- (void) setResetMask:(short)aResetMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setResetMask:resetMask];
    resetMask = aResetMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen419ModelResetMaskChanged object:self];
}

- (short) riseTimeProtection:(short)aChan
{
    return riseTimeProtection[aChan];
}

- (void) setRiseTimeProtection:(short)aChan withValue:(short)aRiseTimeProtection
{
	if(aRiseTimeProtection<0)		aRiseTimeProtection=0;
	else if(aRiseTimeProtection>16)	aRiseTimeProtection=16;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setRiseTimeProtection:aChan withValue:riseTimeProtection[aChan]];
    riseTimeProtection[aChan] = aRiseTimeProtection;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:aChan] forKey:@"channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen419ModelRiseTimeProtectionChanged object:self  userInfo:userInfo];
}

- (uint32_t) lowThreshold:(unsigned short) aChnl
{
    return lowThresholds[aChnl];
}

- (void) setLowThreshold:(unsigned short) aChnl withValue:(uint32_t) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowThreshold:aChnl withValue:[self lowThreshold:aChnl]];
    lowThresholds[aChnl] = aValue;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:@"channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen419LowThresholdChanged object:self userInfo:userInfo];
}

- (uint32_t) highThreshold:(unsigned short) aChnl
{
    return highThresholds[aChnl];
}

- (void) setHighThreshold:(unsigned short) aChnl withValue:(uint32_t) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHighThreshold:aChnl withValue:[self highThreshold:aChnl]];
    highThresholds[aChnl] = aValue;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:@"channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen419HighThresholdChanged object:self userInfo:userInfo];
}


- (short) linearGateMode:(short)aChan
{
    return linearGateMode[aChan];
}

- (void) setLinearGateMode:(short)aChan withValue:(short)aLinearGateMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLinearGateMode:aChan withValue:linearGateMode[aChan]];
    linearGateMode[aChan] = aLinearGateMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen419ModelLinearGateModeChanged object:self];
}

- (uint32_t) auxAddress
{
    return auxAddress;
}

- (void) setAuxAddress:(uint32_t)aAuxAddress
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAuxAddress:auxAddress];
    auxAddress = aAuxAddress;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen419ModelAuxAddressChanged object:self];
}

- (void) writeThresholds
{
    short i;
    for (i = 0; i < kCV419NumberChannels; i++){
        [self writeLowThreshold:i];
        [self writeHighThreshold:i];
    }
}

- (void) readThresholds
{
    short i;
    for (i = 0; i < kCV419NumberChannels; i++){
        [self readLowThreshold:i];
        [self readHighThreshold:i];
    }
}

- (void) writeLowThreshold:(unsigned short) pChan
{    
	unsigned short lowThreshold = lowThresholds[pChan];
    [[self adapter] writeWordBlock:&lowThreshold
                         atAddress:[self baseAddress] + [self lowThresholdOffset:pChan]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) writeHighThreshold:(unsigned short) pChan
{    
	unsigned short highThreshold = highThresholds[pChan];
    [[self adapter] writeWordBlock:&highThreshold
                         atAddress:[self baseAddress] + [self highThresholdOffset:pChan]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (unsigned short) readLowThreshold:(unsigned short) pChan
{    
	int lowOffset = [self lowThresholdOffset:pChan];
	unsigned short lowThreshold;
    [[self adapter] readWordBlock:&lowThreshold
                         atAddress:[self baseAddress] + lowOffset
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
	return lowThreshold;
}

- (unsigned short) readHighThreshold:(unsigned short) pChan
{    

	unsigned short highThreshold;
    [[self adapter] readWordBlock:&highThreshold
						atAddress:[self baseAddress] + [self highThresholdOffset:pChan]
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return highThreshold;
}



- (int) lowThresholdOffset:(unsigned short)aChan
{
	return (int)(reg[kCh0LowThreshold].addressOffset + (aChan * 4));
}

- (int) highThresholdOffset:(unsigned short)aChan
{
	return (int)(reg[kCh0HighThreshold].addressOffset + (aChan * 4));
}

- (void) writeControlStatusRegisters
{
    short i;
    for (i = 0; i < kCV419NumberChannels; i++){
        [self writeControlStatusRegister:i];
    }
}

- (void) writeControlStatusRegister:(int)aChan
{
	unsigned short theValue = 0;
	theValue |= riseTimeProtection[aChan]&0xf;
	theValue |= (linearGateMode[aChan]&0x3)<<4;
	if(!(resetMask & (1<<aChan)))   theValue |= 0x1<<6;
	if(enabledMask & (1<<aChan)) theValue |= 0x1<<7;
	
    [[self adapter] writeWordBlock:&theValue
						atAddress:[self baseAddress] + reg[kCh0ControlStatus+aChan].addressOffset
                        numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
}

- (void) fire
{
	/* Initiate a software trigger */
	unsigned short dummy = 0;
	[[self adapter] writeWordBlock:&dummy
						 atAddress:[self auxAddress] + 2
                        numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
} 

- (void) reset
{
	/* zero out all the channels. */
	unsigned short dummy = 0;
	[[self adapter] writeWordBlock:&dummy
						 atAddress:[self auxAddress]
                        numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}


- (void) initBoard
{
	[self writeControlStatusRegisters];
	[self writeThresholds];
}

#pragma mark ***Rates
- (id) rateObject:(int)channel
{
	return [adcRateGroup rateObject:channel];
}

- (ORRateGroup*) adcRateGroup
{
	return adcRateGroup;
}
- (void) setAdcRateGroup:(ORRateGroup*)newAdcRateGroup
{
	[newAdcRateGroup retain];
	[adcRateGroup release];
	adcRateGroup = newAdcRateGroup;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORCaen419RateGroupChangedNotification
	 object:self];    
}

- (void) setIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setIntegrationTime:[adcRateGroup integrationTime]];
	[adcRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark ***DataTaker

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORCaen419DecoderForAdc",						 @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:NO],                   @"variable",
								 [NSNumber numberWithLong:IsShortForm(dataId)?1:2],@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Adc"];
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"Adc",								@"name",
				   [NSNumber numberWithLong:dataId],	@"dataId",
				   [NSNumber numberWithLong:4],			@"maxChannels",
				   nil];
	
	[anEventDictionary setObject:aDictionary forKey:@"CV419"];
}

- (void) runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:NSStringFromClass([self class])]; 

    [self clearExceptionCount];
    
    controller = [self adapter]; //cache for speed
    slotMask   =  (([self crateNumber]&0x01e)<<21) | ([self slot]& 0x0000001f)<<16;
	
    [self initBoard];
	isRunning = NO;
	
    [self startRates];

}

- (void) takeData: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
	isRunning = YES;
	
    NSString* errorLocation = @"";
    @try {
		int channel;
		for(channel=0;channel<kCV419NumberChannels;channel++){
			errorLocation = @"Reading Status Mask";
			unsigned short theStatusWord;
			[controller readWordBlock:&theStatusWord
							atAddress:baseAddress+reg[kCh0ControlStatus+channel].addressOffset
							numToRead:1
						   withAddMod:addressModifier
						usingAddSpace:0x01];
		
		
			if(theStatusWord & 0x8000){
				unsigned short theValue;
					[controller readWordBlock:&theValue
									atAddress:baseAddress+reg[kCh0DataRegister+channel].addressOffset
									numToRead:1
								   withAddMod:addressModifier
								usingAddSpace:0x01];
				
				if(IsShortForm(dataId)){
					uint32_t data = dataId | slotMask | ((channel & 0x0000000f) << 12) | (theValue & 0x0fff);
					[aDataPacket addLongsToFrameBuffer:&data length:1];
				}
				else {
					uint32_t data[2];
					data[0] = dataId | 2;
					data[1] =  slotMask | ((channel & 0x0000000f) << 12) | (theValue & 0x0fff);
					[aDataPacket addLongsToFrameBuffer:data length:2];
				}
				++adcCount[channel]; 
			}
		}
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"CV419 Card Error",errorLocation,nil);
		[self incExceptionCount];
		[localException raise];
	}
	
}

- (void) runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
    [adcRateGroup stop];
    controller = nil;
	isRunning = NO;
}


- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id = kCaen419; //should be unique
	configStruct->card_info[index].hw_mask[0] 	 = dataId; //better be unique
	configStruct->card_info[index].slot 	 = [self slot];
	configStruct->card_info[index].crate 	 = [self crateNumber];
	configStruct->card_info[index].add_mod 	 = [self addressModifier];
	configStruct->card_info[index].base_add  = [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0] = enabledMask;
	configStruct->card_info[index].deviceSpecificData[1] = reg[kCh0ControlStatus].addressOffset;
	configStruct->card_info[index].deviceSpecificData[2] = reg[kCh0DataRegister].addressOffset;
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
	if(isRunning)return NO;
    ++adcCount[channel];
    return YES;
}

- (uint32_t) adcCount:(int)aChannel
{
    return adcCount[aChannel];
}

-(void) startRates
{
	[self clearAdcCounts];
    [adcRateGroup start:self];
}

- (void) clearAdcCounts
{
    int i;
    for(i=0;i<kCV419NumberChannels;i++){
		adcCount[i]=0;
    }
}

- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kCV419NumberChannels){
			return adcCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

#pragma mark •••HW Wizard

- (int) numberOfChannels
{
    return kCV419NumberChannels;
}

-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Low Threshold"];
    [p setFormat:@"##0.00" upperLimit:0xffffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setLowThreshold:withValue:) getMethod:@selector(lowThreshold:)];
	//[p setCanBeRamped:YES];
	//[p setInitMethodSelector:@selector(writeLowThresholds)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"High Threshold"];
    [p setFormat:@"##0.00" upperLimit:0xffffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHighThreshold:withValue:) getMethod:@selector(highThreshold:)];
	//[p setCanBeRamped:YES];
	//[p setInitMethodSelector:@selector(writeLHighThresholds)];
    [a addObject:p];
	
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Rise Time Protection"];
    [p setFormat:@"#0" upperLimit:0xf lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setRiseTimeProtection:withValue:) getMethod:@selector(riseTimeProtection:)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gate Mode"];
    [p setFormat:@"#0" upperLimit:0x3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setLinearGateMode:withValue:) getMethod:@selector(linearGateMode:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Reset"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setReset:withValue:) getMethod:@selector(reset:)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEnabled:withValue:) getMethod:@selector(enabled:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
	[p setUseValue:NO];
	[p setName:@"Init"];
	[p setSetMethodSelector:@selector(writeThresholds)];
	[a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:NSStringFromClass([self class])]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:NSStringFromClass([self class])]];
    return a;
    
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Low Threshold"])return [[cardDictionary objectForKey:@"lowThresholds"] objectAtIndex:aChannel];
    if([param isEqualToString:@"High Threshold"])return [[cardDictionary objectForKey:@"highThresholds"] objectAtIndex:aChannel];
    if([param isEqualToString:@"Rise Time Protection"])return [[cardDictionary objectForKey:@"riseTimeProtection"] objectAtIndex:aChannel];
    if([param isEqualToString:@"Gate Mode"])return [[cardDictionary objectForKey:@"linearGateMode"] objectAtIndex:aChannel];
    if([param isEqualToString:@"Reset"])return [[cardDictionary objectForKey:@"reset"] objectAtIndex:aChannel];
    else return nil;
}

- (void) logThresholds
{
    short	i;
    NSLog(@"%@ Thresholds\n",[self identifier]);
    for (i = 0; i < kCV419NumberChannels; i++){
        NSLog(@"chan:%d low:0x%04x high:0x%04x\n",i,[self lowThreshold:i],[self highThreshold:i]);
    }
    
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    int i;
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:kCV419NumberChannels];
    for(i=0;i<kCV419NumberChannels;i++)[array addObject:[NSNumber numberWithShort:lowThresholds[i]]];
    [objDictionary setObject:array forKey:@"lowThresholds"];
	
	array = [NSMutableArray arrayWithCapacity:kCV419NumberChannels];
    for(i=0;i<kCV419NumberChannels;i++)[array addObject:[NSNumber numberWithShort:highThresholds[i]]];
    [objDictionary setObject:array forKey:@"highThresholds"];
	
	array = [NSMutableArray arrayWithCapacity:kCV419NumberChannels];
    for(i=0;i<kCV419NumberChannels;i++)[array addObject:[NSNumber numberWithShort:riseTimeProtection[i]]];
    [objDictionary setObject:array forKey:@"riseTimeProtection"];
	
	array = [NSMutableArray arrayWithCapacity:kCV419NumberChannels];
    for(i=0;i<kCV419NumberChannels;i++)[array addObject:[NSNumber numberWithShort:linearGateMode[i]]];
    [objDictionary setObject:array forKey:@"linearGateMode"];

	array = [NSMutableArray arrayWithCapacity:kCV419NumberChannels];
    for(i=0;i<kCV419NumberChannels;i++)[array addObject:[NSNumber numberWithBool:[self reset:i]]];
    [objDictionary setObject:array forKey:@"reset"];
	
	array = [NSMutableArray arrayWithCapacity:kCV419NumberChannels];
    for(i=0;i<kCV419NumberChannels;i++)[array addObject:[NSNumber numberWithBool:[self enabled:i]]];
    [objDictionary setObject:array forKey:@"enabled"];
	
    return objDictionary;
}

#pragma mark •••Archival

- (id) initWithCoder: (NSCoder*) aDecoder
{
	
    self = [super initWithCoder:aDecoder];
    
	[[self undoManager] disableUndoRegistration];
    [self setEnabledMask:[aDecoder decodeIntegerForKey:@"enabledMask"]];
    [self setResetMask:[aDecoder decodeBoolForKey:@"resetMask"]];
    [self setAuxAddress:[aDecoder decodeIntForKey:@"auxAddress"]];
	int i;
    for (i = 0; i < kCV419NumberChannels; i++){
        [self setLowThreshold:i withValue:[aDecoder decodeIntForKey: [NSString stringWithFormat:@"CAENLowThresholdChnl%d", i]]];
        [self setHighThreshold:i withValue:[aDecoder decodeIntForKey: [NSString stringWithFormat:@"CAENHighThresholdChnl%d", i]]];
		[self setLinearGateMode:i withValue:[aDecoder decodeIntegerForKey:[NSString stringWithFormat:@"CAENLinearGateModeChnl%d", i]]];
		[self setRiseTimeProtection:i withValue:[aDecoder decodeIntegerForKey:[NSString stringWithFormat:@"CAENRiseTimeProtectionChnl%d", i]]];
    }    
    [self setAdcRateGroup:[aDecoder decodeObjectForKey:@"adcRateGroup"]];
 
	if(!adcRateGroup){
	    [self setAdcRateGroup:[[[ORRateGroup alloc] initGroup:kCV419NumberChannels groupTag:0] autorelease]];
	    [adcRateGroup setIntegrationTime:5];
    }
    [self startRates];
    [adcRateGroup resetRates];
    [adcRateGroup calcRates];
	
	[[self undoManager] enableUndoRegistration];
    
    return self;
	
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
	[anEncoder encodeInteger:enabledMask forKey:@"enabledMask"];
	[anEncoder encodeBool:resetMask forKey:@"resetMask"];
	[anEncoder encodeInt:auxAddress forKey:@"auxAddress"];
	int i;
    for (i = 0; i < kCV419NumberChannels; i++){
        [anEncoder encodeInt:lowThresholds[i] forKey:[NSString stringWithFormat:@"CAENLowThresholdChnl%d", i]];
        [anEncoder encodeInt:highThresholds[i] forKey:[NSString stringWithFormat:@"CAENHighThresholdChnl%d", i]];
		[anEncoder encodeInteger:linearGateMode[i] forKey:[NSString stringWithFormat:@"CAENLinearGateModeChnl%d", i]];
		[anEncoder encodeInteger:riseTimeProtection[i] forKey:[NSString stringWithFormat:@"CAENRiseTimeProtectionChnl%d", i]];
    }
    [anEncoder encodeObject:adcRateGroup forKey:@"adcRateGroup"];
}

@end

