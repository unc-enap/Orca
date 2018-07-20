/*
 *  ORAD413AModel.cpp
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

#pragma mark ¥¥¥Imported Files
#import "ORAD413AModel.h"

#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"

NSString* ORAD413AOnlineMaskChangedNotification		= @"ORAD413AOnlineMaskChangedNotification";
NSString* ORAD413ASettingsLock						= @"ORAD413ASettingsLock";
NSString* ORAD413ADiscriminatorChangedNotification      = @"ORAD413ADiscriminatorChangedNotification";
NSString* ORAD413AControlReg1ChangedNotification     = @"ORAD413AControlReg1ChangedNotification";
NSString* ORAD413AControlReg2ChangedNotification     = @"ORAD413AControlReg2ChangedNotification";

@interface ORAD413AModel (private)
- (void) readChannels:(ORDataPacket*)aDataPacket;
- (void) readZeroSuppressedChannels:(ORDataPacket*)aDataPacket;
- (void) ship:(ORDataPacket*)aDataPacket adc:(unsigned short)adcValue forChan:(int)i;
@end

@implementation ORAD413AModel

#pragma mark ¥¥¥Initialization
- (id) init
{		
    self = [super init];
	[self setCAMACMode:YES];
	[self setCheckLAM:YES];
    return self;
}

- (void) dealloc
{
    [discriminators release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"AD413ACard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORAD413AController"];
}

- (NSString*) helpURL
{
	return @"CAMAC/AD413.html";
}

- (short) numberSlotsUsed
{
    return 2;
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"AD413";
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (unsigned char)onlineMask {
	
    return onlineMask;
}

- (void)setOnlineMask:(unsigned char)anOnlineMask {
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:[self onlineMask]];
	
    onlineMask = anOnlineMask;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAD413AOnlineMaskChangedNotification
	 object:self];
	
}

- (BOOL)onlineMaskBit:(int)bit
{
	return onlineMask&(1<<bit);
}

- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned char aMask = onlineMask;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setOnlineMask:aMask];
}

- (NSMutableArray *) discriminators
{
    return discriminators; 
}

- (void) setDiscriminators: (NSMutableArray *) anArray
{
    [anArray retain];
    [discriminators release];    
    discriminators = anArray;
}

- (unsigned short) discriminatorForChan:(int)aChan
{
    if(discriminators) return [[discriminators objectAtIndex:aChan] intValue];
    else return 0.0;
}

- (void) setDiscriminator:(unsigned short)aValue forChan:(int)aChan
{
    if(!discriminators){
        [self setDiscriminators:[NSMutableArray arrayWithObjects:
								 [NSNumber numberWithChar:0],
								 [NSNumber numberWithChar:0],
								 [NSNumber numberWithChar:0],
								 [NSNumber numberWithChar:0],
								 nil]];
        
    }
    [[[self undoManager] prepareWithInvocationTarget:self] setDiscriminator:[self discriminatorForChan:aChan] forChan:aChan];
    
    [discriminators replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAD413ADiscriminatorChangedNotification
	 object:self
	 userInfo: [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"]];
}

- (BOOL) gateEnable:(int)index
{
	return gateEnable[index];
}

- (void) setGateEnable:(int)index withValue:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setGateEnable:index withValue:gateEnable[index]];
    gateEnable[index] = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD413AControlReg2ChangedNotification object:self];

}

- (BOOL) singles
{
    return singles;
}

- (void) setSingles: (BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSingles:singles];
    singles = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD413AControlReg1ChangedNotification object:self];
}

- (BOOL) randomAccessMode
{
    return randomAccessMode;
}

- (void) setRandomAccessMode: (BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRandomAccessMode:randomAccessMode];
    randomAccessMode = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD413AControlReg1ChangedNotification object:self];
}

- (BOOL) zeroSuppressionMode
{
    return zeroSuppressionMode;
}

- (void) setZeroSuppressionMode: (BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setZeroSuppressionMode:zeroSuppressionMode];
    zeroSuppressionMode = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD413AControlReg1ChangedNotification object:self];
}

- (BOOL) ofSuppressionMode
{
    return ofSuppressionMode;
}

- (void) setOfSuppressionMode: (BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOfSuppressionMode:ofSuppressionMode];
    ofSuppressionMode = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD413AControlReg1ChangedNotification object:self];
}

- (BOOL) lamEnable
{
    return lamEnable;
}

- (void) setLamEnable: (BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLamEnable:lamEnable];
    lamEnable = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD413AControlReg1ChangedNotification object:self];
}

- (BOOL) CAMACMode
{
    return CAMACMode;
}

- (void) setCAMACMode: (BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCAMACMode:CAMACMode];
    CAMACMode = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD413AControlReg1ChangedNotification object:self];
}

- (void) setCheckLAM:(BOOL)aState
{
    checkLAM = aState;
}


#pragma mark ¥¥¥Hardware functions

//note that this card is a special case -- the power comes from the right-hand slot, so the station number
//must be incremented by one in all cases
- (void) readControlReg1
{
    unsigned short aValue;
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:0 data:&aValue];
	zeroSuppressionMode |= !((aValue>>kZeroSuppressionBit)&0x1);
	singles				|= (aValue>>kSinglesBit)&0x1;				//in manual -- coincidence bit
	randomAccessMode	|= (aValue>>kRandomAccessBit)&0x1;
	ofSuppressionMode	|= !((aValue>>kOFSuppressionBit)&0x1);
	CAMACMode			|= (aValue>>kECLPortEnableBit)&0x1;
	lamEnable			|= (aValue>>kLAMEnableBit)&0x1;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD413AControlReg1ChangedNotification object:self];
}

- (void) readControlReg2
{
    unsigned short aValue;
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:1 f:0 data:&aValue];
	int bit;
	for(bit=0;bit<5;bit++){
		gateEnable[bit] = !((aValue>>bit) & 0x1); //zero is enabled
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAD413AControlReg2ChangedNotification object:self];
	
}

- (void) writeControlReg1
{
	unsigned short controlReg1 = 0;
	controlReg1 |= vsn;
	controlReg1 |= (!zeroSuppressionMode)<<kZeroSuppressionBit;
	controlReg1 |= singles<<kSinglesBit;							//in manual -- coincidence bit
	controlReg1 |= randomAccessMode<<kRandomAccessBit;
	controlReg1 |= (!ofSuppressionMode)<<kOFSuppressionBit;
	controlReg1 |= CAMACMode<<kECLPortEnableBit;
	controlReg1 |= lamEnable<<kLAMEnableBit;	
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:16 data:&controlReg1];

}

- (void) writeControlReg2
{
	unsigned short controlReg2 = 0;
	int bit;
	for(bit=0;bit<5;bit++){
		if(!gateEnable[bit])controlReg2 |= (1<<bit); //zero is enabled
	}
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:1 f:16 data:&controlReg2];

}

- (void) clearModule
{
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:9];

}

- (void) clearLAM
{
    [controller camacShortNAF:[self stationNumber]+1 a:0 f:10 data:nil];
}

- (void) readDiscriminators
{
    unsigned short aValue;
    int i;
    for(i=0;i<4;i++){
        [[self adapter] camacShortNAF:[self stationNumber]+1 a:i f:1 data:&aValue];
        [self setDiscriminator:0x00ff&aValue forChan:i];
    }
}

- (int) vsn
{
	return vsn;
}

- (void) writeDiscriminators
{
    unsigned short aValue;
    int i;
    for(i=0;i<4;i++){
        aValue = [self discriminatorForChan:i];
        [[self adapter] camacShortNAF:[self stationNumber]+1 a:i f:17 data:&aValue];
    }
}


#pragma mark ¥¥¥DataTaker

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kShortForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (void) reset
{
	//[self initBoard];    
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORAD413ADecoderForAdc",                       @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:NO],                   @"variable",
								 [NSNumber numberWithLong:IsShortForm(dataId)?1:2],@"length",
								 [NSNumber numberWithBool:YES],                  @"canBeGated",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"ADC"];
    return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	
    if(![self adapter]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI-CAMAC Controller (i.e. a CC32)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORAD413AModel"];    
    
    //----------------------------------------------------------------------------------------
    controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
    unChangingDataPart   = (uint32_t)((([self crateNumber]&0xf)<<21) | ((([self stationNumber]+1)& 0x0000001f)<<16)); //doesn't change so do it here.
	cachedStation = [self stationNumber]+1;
	
    [self clearExceptionCount];
    
    int i;
	onlineChannelCount = 0;
    for(i=0;i<4;i++){
        if(onlineMask & (0x1<<i)){
            onlineList[onlineChannelCount] = i;
            onlineChannelCount++;
        }
    }
	
    [self clearModule];
    [self writeControlReg2];
    [self writeControlReg1];  //LAM enable is rolled into this load
	[self writeDiscriminators];
    [self clearLAM];
	
	
	if(zeroSuppressionMode && randomAccessMode){
		NSLogColor([NSColor redColor],@"OR413 (%d,%d) Parameter conflict -- both zero suppression and random access modes selected.\n");
		NSLogColor([NSColor redColor],@"The random access mode has precedence. Zero Suppresion not used.\n");
	}
	
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    @try {
		BOOL lamIsSet = NO;
		if(checkLAM) lamIsSet = isQbitSet([controller camacShortNAF:cachedStation a:0 f:8]); //test the lam
		else lamIsSet = YES;
		if((lamEnable && lamIsSet) || !lamEnable){
			if(randomAccessMode)		[self readChannels:aDataPacket];
			else {
				if(zeroSuppressionMode)	[self readZeroSuppressedChannels:aDataPacket];
				else					[self readChannels:aDataPacket];
			}
			if(checkLAM && lamIsSet && lamEnable)[controller camacShortNAF:cachedStation a:0 f:10]; //clear lam
			[controller camacShortNAF:cachedStation a:0 f:9]; //clear module
		}
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	[self setCheckLAM:YES];
	[self setFeraEnable:NO];
}


#pragma mark ¥¥¥FERA
- (void) setVSN:(int)aVSN
{
	vsn = aVSN;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD413AControlReg1ChangedNotification object:self];
}

- (void) setFeraEnable:(BOOL)aState
{
	[self setCAMACMode:!aState];
	if(aState){
		oldZeroSuppressionMode = zeroSuppressionMode;
		[self setZeroSuppressionMode:YES];
	}
	else {
		[self setZeroSuppressionMode:oldZeroSuppressionMode];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD413AControlReg1ChangedNotification object:self];
}

- (int) maxNumChannels
{
	return 4;
}

- (void) shipFeraData:(ORDataPacket*)aDataPacket data:(uint32_t)data 
{
	int chan = (data>>13)&0x3;
	[self ship:aDataPacket adc:data&0x1fff forChan:chan];
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    
    [self setOnlineMask:			[decoder decodeIntegerForKey:   @"ORAD413AOnlineMask"]];
    [self setDiscriminators:		[decoder decodeObjectForKey:@"OR413Discriminators"]];
    [self setSingles:				[decoder decodeBoolForKey:	@"singles"]];
    [self setRandomAccessMode:		[decoder decodeBoolForKey:	@"randomAccessMode"]];
    [self setZeroSuppressionMode:	[decoder decodeBoolForKey:	@"zeroSuppressionMode"]];
    [self setOfSuppressionMode:		[decoder decodeBoolForKey:	@"ofSuppressionMode"]];
    [self setLamEnable:				[decoder decodeBoolForKey:	@"lamEnable"]];
	int bit;
	for(bit=0;bit<5;bit++){
		[self setGateEnable:bit withValue: [decoder decodeBoolForKey:[NSString stringWithFormat:@"enableGate%d",bit]]];
	}
	[self setCAMACMode:YES];
	[self setCheckLAM:YES];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:onlineMask			forKey:@"ORAD413AOnlineMask"];
    [encoder encodeObject:discriminators	forKey:@"OR413Discriminators"];
	
    [encoder encodeBool:singles				forKey:@"singles"];
    [encoder encodeBool:randomAccessMode	forKey:@"randomAccessMode"];
    [encoder encodeBool:zeroSuppressionMode forKey:@"zeroSuppressionMode"];
    [encoder encodeBool:ofSuppressionMode	forKey:@"ofSuppressionMode"];
    [encoder encodeBool:lamEnable			forKey:@"lamEnable"];
	
	int bit;
	for(bit=0;bit<5;bit++){
		[encoder encodeBool:gateEnable[bit] forKey:[NSString stringWithFormat:@"enableGate%d",bit]];
	}
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithInt:onlineMask] forKey:@"onlineMask"];
		
    [objDictionary setObject:[NSNumber numberWithBool:singles]				forKey:@"singles"];
    [objDictionary setObject:[NSNumber numberWithBool:randomAccessMode]		forKey:@"randomAccessMode"];
    [objDictionary setObject:[NSNumber numberWithBool:zeroSuppressionMode]	forKey:@"zeroSuppressionMode"];
    [objDictionary setObject:[NSNumber numberWithBool:ofSuppressionMode]	forKey:@"ofSuppressionMode"];
    [objDictionary setObject:[NSNumber numberWithBool:CAMACMode]			forKey:@"CAMACMode"];
    [objDictionary setObject:[NSNumber numberWithBool:lamEnable]			forKey:@"lamEnable"];
	int bit;
	for(bit=0;bit<5;bit++){
		[objDictionary setObject:[NSNumber numberWithBool:gateEnable[bit]]	forKey:[NSString stringWithFormat:@"enableGate%d",bit]];
	}
	
    return objDictionary;
}
@end

@implementation ORAD413AModel (private)

- (void) readChannels:(ORDataPacket*)aDataPacket
{
	int numToRead;
	if(randomAccessMode) numToRead = onlineChannelCount;
	else				 numToRead = 4;
	
	int i;
	for(i=0;i<numToRead;i++){
		unsigned short adcValue;
		[controller camacShortNAF:cachedStation a:onlineList[i] f:2 data:&adcValue];
		int chan;
		if(randomAccessMode)chan = onlineList[i];
		else chan = i;
		if(onlineMask & (0x1<<chan)){
			[self ship:aDataPacket adc:adcValue&0x1fff forChan:chan];
		}
	}

}

- (void) readZeroSuppressedChannels:(ORDataPacket*)aDataPacket
{
	unsigned short data;
	unsigned short  status = [controller camacShortNAF:cachedStation a:0 f:2 data:&data];
	if(isQbitSet(status)){
		int numValues = (data>>11) & 0x3;
		if(numValues==0)numValues=4;
		int i;
		for(i=0;i<numValues;i++){
			[controller camacShortNAF:cachedStation a:i f:2 data:&data];
			int chan = (data>>13)&0x3;
			if(onlineMask & (0x1<<chan)){
				[self ship:aDataPacket adc:data&0x1fff forChan:chan];
			}
		}
	}
}

- (void) ship:(ORDataPacket*)aDataPacket adc:(unsigned short)adcValue forChan:(int)i
{
    if(IsShortForm(dataId)){
        uint32_t data = dataId | unChangingDataPart | (i&0x3)<<13 | (adcValue & 0x1FFF);
        [aDataPacket addLongsToFrameBuffer:&data length:1];
    }
    else {
        uint32_t data[2];
        data[0] =  dataId | 2;
        data[1] =  unChangingDataPart | (i&0x3)<<13 | (adcValue & 0x1FFF);
        [aDataPacket addLongsToFrameBuffer:data length:2];
    }
}
@end
