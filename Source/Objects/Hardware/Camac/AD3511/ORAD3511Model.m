/*
 *  ORAD3511Model.cpp
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

//**********************************************************************************
//------this is really for the 3512. The real 3511 is a single wide card without a buffer. 
//If we ever get a real 3511 this object will be renamed to be a 3512 and a 3511 object will be added.
//**********************************************************************************


#pragma mark ¥¥¥Imported Files
#import "ORAD3511Model.h"

#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"

NSString* ORAD3511ModelIncludeTimingChanged			= @"ORAD3511ModelIncludeTimingChanged";
NSString* ORAD3511EnabledChanged					= @"ORAD3511EnabledChanged";
NSString* ORAD3511StorageOffsetChanged				= @"ORAD3511StorageOffsetChanged";
NSString* ORAD3511GainChanged						= @"ORAD3511GainChanged";
NSString* ORAD3511SettingsLock						= @"ORAD3511SettingsLock";
NSString* ORAD3511WarningPosted						= @"ORAD3511WarningPosted";

@implementation ORAD3511Model

#pragma mark ¥¥¥Initialization
- (id) init
{		
    self = [super init];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"AD3511Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORAD3511Controller"];
}

- (NSString*) helpURL
{
	return @"CAMAC/3512A.html";
}


- (short) numberSlotsUsed
{
    return 2;
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"AD3511";
}
- (BOOL) includeTiming
{
    return includeTiming;
}

- (void) setIncludeTiming:(BOOL)aIncludeTiming
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIncludeTiming:includeTiming];
    
    includeTiming = aIncludeTiming;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD3511ModelIncludeTimingChanged object:self];
}

- (BOOL) enabled
{
    return enabled;
}

- (void) setEnabled:(BOOL)aEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:enabled];
    
    enabled = aEnabled;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD3511EnabledChanged object:self];
}

- (unsigned short) storageOffset
{
    return storageOffset;
}

- (void) setStorageOffset:(unsigned short)aStorageOffset
{
    if(aStorageOffset > 0 && aStorageOffset <= gain) {
		[self setGain:aStorageOffset-1];
		[self postWarning:@"Offset must be zero or exceed Gain!"];
	}
	
    [[[self undoManager] prepareWithInvocationTarget:self] setStorageOffset:storageOffset];
    
    storageOffset = aStorageOffset;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD3511StorageOffsetChanged object:self];
}

- (void) postWarning:(NSString*)aMessage
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAD3511WarningPosted 
														object:self 
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aMessage,@"WarningMessage",nil]];
}


- (unsigned short) gain
{
    return gain;
}

- (void) setGain:(unsigned short)aGain
{
	if(aGain>5)aGain=5;
	if(storageOffset > 0 && storageOffset <= aGain) {
		[self setStorageOffset:aGain+1];
		[self postWarning:@"Offset must be zero or exceed Gain!"];
	}
	
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:gain];
	
    
    gain = aGain;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD3511GainChanged object:self];
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

#pragma mark ¥¥¥DataTaker

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
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
								 @"ORAD3511DecoderForAdc",                       @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:YES],                  @"variable",
								 [NSNumber numberWithLong:-1],					@"length",
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
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORAD3511Model"];    
    
    //----------------------------------------------------------------------------------------
    controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
    crateAndStationId   = (uint32_t)((([self crateNumber]&0xf)<<21) | (([self stationNumber]& 0x0000001f)<<16)); //doesn't change so do it here.
	if(includeTiming)crateAndStationId |= 0x02000000;
	cachedStation = [self stationNumber];
    [self clearExceptionCount];
    
	firstTime = YES;
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    @try {
        
		if(!firstTime){
			//test the LAM
			union {
				NSTimeInterval asTimeInterval;
				uint32_t asLongs[2];
			}theTimeRef;
			
			unsigned short dummy;
			unsigned short status = [controller camacShortNAF:cachedStation a:0 f:8 data:&dummy];
			if(isQbitSet(status)) { //LAM status comes back in the Q bit
				[controller camacShortNAF:cachedStation a:0 f:24 data:&dummy]; //disable LAM
				unsigned short adcValue;
				short eventCount = 0;
				short dataOffset;
				if(includeTiming){
					dataOffset = 4;
					//grab the event time as reference from Jan 1, 2004.
					theTimeRef.asTimeInterval = [NSDate timeIntervalSinceReferenceDate];
				}
				else {
					dataOffset = 2;
				}
				
				uint32_t dataBuffer[512+dataOffset];
				do {
					//read a word from the buffer
					[controller camacShortNAF:cachedStation a:0 f:2 data:&adcValue];
					dataBuffer[eventCount+dataOffset] = adcValue;
					//we get out after the full buffer has been read EVEN if 
					//there is now more data in it. This prevents us from hogging
					//all the processing time.
					eventCount++;
					if(eventCount >= 512)break;
					status = [controller camacShortNAF:cachedStation a:0 f:8 data:&dummy];
				}while(isQbitSet(status));
				
				if(eventCount){
					dataBuffer[0] =  dataId | eventCount+dataOffset;
					dataBuffer[1] =  crateAndStationId;
					if(includeTiming){
						dataBuffer[2] = theTimeRef.asLongs[1];
						dataBuffer[3] = theTimeRef.asLongs[0];
					}
					[aDataPacket addLongsToFrameBuffer:dataBuffer length:eventCount+dataOffset];
				}
				[controller camacShortNAF:cachedStation a:0 f:26 data:&dummy]; //enable LAM
			}
		}
		else {
			firstTime = NO;
			[self setEnabled:YES];
			[self initBoard];
			[self resetLAMandClearBuffer];
			[self setEnabled:NO];
			[self initBoard];
		}
  		
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"AD3512 Card Error",nil);
		[self incExceptionCount];
		[localException raise];
	}
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	[self disableLAM];
}


#pragma mark ¥¥¥Hardware Test functions

- (void) read
{
	NSLog(@"AD3512 Read for Station %d\n",[self stationNumber]);
	unsigned short status = [[self adapter] camacShortNAF:[self stationNumber] a:0 f:8];
	if(isQbitSet(status)){
		unsigned short adcValue;
		[[self adapter] camacShortNAF:[self stationNumber] a:0 f:2 data:&adcValue];
		NSLog(@"adcValue:%d\n",adcValue);
	}
	else NSLog(@"No data\n");
}

- (void) testLAM
{
    unsigned short status = [[self adapter] camacShortNAF:[self stationNumber] a:0 f:8];
    NSLog(@"LAM %@ set\n",isQbitSet(status)?@"is":@"is not");
}
- (void) resetLAMandClearBuffer
{
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:10];
}

- (void) disableLAM
{
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:24];
}

- (void) enableLAM
{
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:26];
}

- (void) initBoard
{
    unsigned short controlValue = 0;
	if(storageOffset) controlValue |= (0x1L<<(storageOffset-1)) & 0xff;
	controlValue |= ((6-gain) & 0x7) << 8;
	controlValue |= (enabled & 0x1) << 15;
	controlValue |= 0x1 << 13;
	
	NSLog(@"AD3512 (Station %d) control reg: 0x%0x\n",[self stationNumber], controlValue); 
	
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:16 data:&controlValue];
	[self enableLAM];
}


#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setIncludeTiming:[decoder decodeBoolForKey:@"ORAD3511ModelIncludeTiming"]];
    [self setEnabled:[decoder decodeBoolForKey:@"ORAD3511ModelEnabled"]];
    [self setStorageOffset:[decoder decodeIntegerForKey:@"ORAD3511ModelStorageOffset"]];
    [self setGain:[decoder decodeIntegerForKey:@"ORAD3511ModelGain"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:includeTiming forKey:@"ORAD3511ModelIncludeTiming"];
    [encoder encodeBool:enabled forKey:@"ORAD3511ModelEnabled"];
    [encoder encodeInteger:storageOffset forKey:@"ORAD3511ModelStorageOffset"];
    [encoder encodeInteger:gain forKey:@"ORAD3511ModelGain"];
	
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithInt:gain] forKey:@"gain"];
    [objDictionary setObject:[NSNumber numberWithInt:storageOffset] forKey:@"storageOffset"];
    return objDictionary;
}

@end
