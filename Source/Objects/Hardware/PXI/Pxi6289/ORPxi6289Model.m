//
//  ORPxi6289Model.m
//  Orca
//
//  Created by Mark Howe on Thurs Aug 26 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORPxi6289Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORPxiCrate.h"
#import "ORRateGroup.h"
#import "ORTimer.h"

NSString* ORPxi6289RateGroupChangedNotification	= @"ORPxi6289RateGroupChangedNotification";
NSString* ORPxi6289SettingsLock					= @"ORPxi6289SettingsLock";
NSString* ORPxi6289ModelEnabledChanged			= @"ORPxi6289ModelEnabledChanged";
NSString* ORPxi6289ModelThresholdChanged		= @"ORPxi6289ModelThresholdChanged";


@implementation ORPxi6289Model

#pragma mark •••Static Declarations
//offsets from the base address
static uint32_t register_offsets[kNumberOfPxi6289Registers] = {
	0x00, //[0] board ID
	0xff, //[1] Threshold <<<==== fix
};

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self setDefaults];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    [waveFormRateGroup release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Pxi6289Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORPxi6289Controller"];
}

#pragma mark ***Accessors
- (void) setDefaults
{
	int i;
	for(i=0;i<kNumPxi6289Channels;i++){
		enabled[i]			= YES;
		threshold[i]		= 0xFFFF;
	}
}

#pragma mark •••Rates
- (ORRateGroup*) waveFormRateGroup
{
    return waveFormRateGroup;
}

- (void) setWaveFormRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [waveFormRateGroup release];
    waveFormRateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPxi6289RateGroupChangedNotification object:self];    
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumPxi6289Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark •••specific accessors
- (int) enabled:(short)chan			{ return enabled[chan]; }
- (void) setEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
	enabled[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPxi6289ModelEnabledChanged object:self];
}

- (int) threshold:(short)chan	{ return threshold[chan]; }
- (void) setThreshold:(short)chan withValue:(int)aValue 
{ 
	if(aValue<0)aValue=0;
	else if(aValue>0xfFFF)aValue = 0xfFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:chan withValue:threshold[chan]];
	threshold[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPxi6289ModelThresholdChanged object:self];
}



#pragma mark •••Hardware Access
- (short) readBoardID
{
    unsigned short theValue = 0;
    [[self adapter] readWordBlock:&theValue
                        atAddress:[self baseAddress] + register_offsets[kBoardID]
                        numToRead:1];
    return theValue & 0xffff;
}

- (void) initBoard
{
	int i;
    for(i=0;i<kNumPxi6289Channels;i++){
        [self writeThreshold:i];
    }
}

- (void) writeThreshold:(int)channel
{    
    [[self adapter] writeWordBlock:(unsigned short*)&threshold[channel]
                         atAddress:[self baseAddress] + register_offsets[kThreshold] + 2*channel
                        numToWrite:1];
}

#pragma mark •••Data Taker
- (uint32_t) dataId { return dataId; }

- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORPxi6289DecoderForWaveform",          @"decoder",
								 [NSNumber numberWithLong:dataId],        @"dataId",
								 [NSNumber numberWithBool:YES],           @"variable",
								 [NSNumber numberWithLong:-1],			  @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
    
    return dataDictionary;
}


#pragma mark •••HW Wizard
- (int) numberOfChannels
{
    return kNumPxi6289Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
      
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEnabled:withValue:) getMethod:@selector(enabled:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0x7fff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}


- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORPxiCrate"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORPxi6289Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORPxi6289Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    
    id obj = [cardDictionary objectForKey:param];
    if(obj)return obj;
    else return [[cardDictionary objectForKey:param] objectAtIndex:aChannel];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORPxi6289Model"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    controller		= [self adapter];
    
    dataBuffer = (uint32_t*)malloc(0xffff * sizeof(uint32_t));
    [self startRates];
    [self initBoard];
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    isRunning = YES; 
	BOOL dataReady = NO;

	//------------
	//just for testing the decoder chain. remove
	if(++delay > 10000){
		dataReady = YES;
		delay = 0;
	}
	//------------
	
    @try {
		if(dataReady){
			dataReady = NO;
			int channel;
			for(channel=0;channel<kNumPxi6289Channels;channel++){
				if(enabled[channel]){
					uint32_t numLongs = 0;
					dataBuffer[numLongs++] = dataId | 0; //we'll fill in the length later
					dataBuffer[numLongs++] = location | (channel << 8);
					dataBuffer[numLongs++] = 512; //number of longs in waveform
					
					//read the waveform and stuff into dataBuffer. This code is just for testing the decoder chain.
					//we pack two shorts into a int32_t. The actual digitizer data will be different.
					int i;
					int j = 0;
					for(i=0;i<1024;i++){
						dataBuffer[numLongs] = (uint32_t)(j*2) & 0xffff;
						dataBuffer[numLongs] |= ((uint32_t)(j*2+1) & 0xffff)<<16;
						numLongs++;
						j+=2;
						if(j>256)j=0;
					
					}
					//this gives us the rate
					++waveFormCount[channel];  //grab the channel and inc the count
						
					dataBuffer[0] |= numLongs; //see, we did fill it in...
					[aDataPacket addLongsToFrameBuffer:dataBuffer length:numLongs];
				}
			}
		}
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"Pxi6289 Card Error",nil);
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
    free(dataBuffer);
}

- (void) reset
{
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    ++waveFormCount[channel];
    return YES;
}

- (uint32_t) waveFormCount:(int)aChannel
{
    return waveFormCount[aChannel];
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumPxi6289Channels;i++){
        waveFormCount[i]=0;
    }
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumPxi6289Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	int i;
	for(i=0;i<kNumPxi6289Channels;i++){
		[self setEnabled:i withValue:[decoder decodeIntegerForKey:[@"enabled" stringByAppendingFormat:@"%d",i]]];
		[self setThreshold:i withValue:[decoder decodeIntForKey:[@"hreshold" stringByAppendingFormat:@"%d",i]]];
	}
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:waveFormRateGroup forKey:@"waveFormRateGroup"];
	int i;
 	for(i=0;i<kNumPxi6289Channels;i++){
		[encoder encodeInteger:enabled[i] forKey:[@"enabled" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:threshold[i] forKey:[@"threshold" stringByAppendingFormat:@"%d",i]];
	}
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	int i;
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
 	for(i=0;i<kNumPxi6289Channels;i++){
		[self addCurrentState:objDictionary cArray:enabled   forKey:[@"enabled" stringByAppendingFormat:@"%d",i]];
		[self addCurrentState:objDictionary cArray:threshold forKey:[@"threshold" stringByAppendingFormat:@"%d",i]];
	}	
	
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(short*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumPxi6289Channels;i++){
		[ar addObject:[NSNumber numberWithShort:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}


@end
