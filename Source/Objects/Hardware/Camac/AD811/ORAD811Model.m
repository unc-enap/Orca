/*
 *  ORAD811Model.cpp
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
#import "ORAD811Model.h"

#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"

NSString* ORAD811ModelIncludeTimingChanged			= @"ORAD811ModelIncludeTimingChanged";
NSString* ORAD811OnlineMaskChangedNotification		= @"ORAD811OnlineMaskChangedNotification";
NSString* ORAD811SettingsLock						= @"ORAD811SettingsLock";
NSString* ORAD811SuppressZerosChangedNotification   = @"ORAD811SuppressZerosChangedNotification";

@implementation ORAD811Model

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
    [self setImage:[NSImage imageNamed:@"AD811Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORAD811Controller"];
}

- (NSString*) helpURL
{
	return @"CAMAC/AD811.html";
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"AD811";
}

- (BOOL) includeTiming
{
    return includeTiming;
}

- (void) setIncludeTiming:(BOOL)aIncludeTiming
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIncludeTiming:includeTiming];
    
    includeTiming = aIncludeTiming;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAD811ModelIncludeTimingChanged object:self];
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
	 postNotificationName:ORAD811OnlineMaskChangedNotification
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

- (BOOL) suppressZeros
{
	return suppressZeros;
}
- (void) setSuppressZeros:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSuppressZeros:suppressZeros];
	
    suppressZeros = aFlag;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAD811SuppressZerosChangedNotification
	 object:self];
    
}

#pragma mark ¥¥¥DataTaker

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:includeTiming?kLongForm:kShortForm]; //short form preferred
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
    int len = 1;						//default to the short form
	if(includeTiming)len = 4;			//including timing adds two timing words
	else {
		if(IsLongForm(dataId))len = 2;	//not timing, int32_t form = 2 words total
	}
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORAD811DecoderForAdc",                        @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:NO],                   @"variable",
								 [NSNumber numberWithLong:len],		@"length",
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
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORAD811Model"];    
    
    //----------------------------------------------------------------------------------------
    controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
    unChangingDataPart   = (uint32_t)((([self crateNumber]&0xf)<<21) | (([self stationNumber]& 0x0000001f)<<16)); //doesn't change so do it here.
	cachedStation = [self stationNumber];
    [self clearExceptionCount];
    
	//[self initBoard];
    
    int i;
	onlineChannelCount = 0;
    for(i=0;i<8;i++){
        if(onlineMask & (0x1<<i)){
            onlineList[onlineChannelCount] = i;
            onlineChannelCount++;
        }
    }
    
	
    if([[userInfo objectForKey:@"doinit"]intValue]){
		[self generalReset];
    }
	[self enableLAMEnableLatch];
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    NSString* errorLocation = @"";
    BOOL resetDone;
	
	union {
		NSTimeInterval asTimeInterval;
		uint32_t asLongs[2];
	}theTimeRef;
	
    @try {
        
        //check the LAM
        unsigned short dummy;
        unsigned short status = [controller camacShortNAF:cachedStation a:12 f:8 data:&dummy];
        if(isQbitSet(status)) { //LAM status comes back in the Q bit
            if(onlineChannelCount){
				resetDone = NO;
				int i;
				if(includeTiming){
					theTimeRef.asTimeInterval = [NSDate timeIntervalSinceReferenceDate];
				}
				
                for(i=0;i<onlineChannelCount;i++){
                    //read one adc channnel
                    unsigned short adcValue;
                    [controller camacShortNAF:cachedStation a:onlineList[i] f:2 data:&adcValue];
					if(!(suppressZeros && adcValue==0)){
						if(IsShortForm(dataId)){
							uint32_t data = dataId | unChangingDataPart | (onlineList[i]&0xf)<<12 | (adcValue & 0xfff);
							[aDataPacket addLongsToFrameBuffer:&data length:1];
						}
						else {
							uint32_t data[4];
							int len = 2;			//default to no timing info
							int32_t includeTimingMask = 0;
							if(includeTiming){
								len = 4;
								includeTimingMask = 1L<<25;
								data[2] = theTimeRef.asLongs[1];	//low part
								data[3] = theTimeRef.asLongs[0];	//high part
							}
							
							
							data[0] =  dataId | len;
							data[1] =  includeTimingMask | unChangingDataPart | (onlineList[i]&0xf)<<12 | (adcValue & 0xfff);
							[aDataPacket addLongsToFrameBuffer:data length:len];
						}
					}
                    if(i == 7) resetDone = YES;
                    
                }
                //read of last channel with this command clears
				if(!resetDone) [controller camacShortNAF:[self stationNumber] a:7 f:2 data:&dummy]; 
            }
            
            
  		}
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"AD811 Card Error",errorLocation,nil);
		[self incExceptionCount];
		[localException raise];
	}
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
}

#pragma mark ¥¥¥Hardware Test functions
- (void) readNoReset
{
    if(onlineMask){
        NSLog(@"AD811 Read/No reset for Station %d\n",[self stationNumber]);
        int i;
        for(i=0;i<8;i++){
            //read one adc channnel
            if(onlineMask & (0x1<<i)){
                unsigned short adcValue;
                [[self adapter] camacShortNAF:[self stationNumber] a:i f:0 data:&adcValue];
                
                NSLog(@"chan: %d  adcValue:%d\n",i,adcValue);
            }
        }
    }
    else NSLog(@"No channels online for AD811 Station %d\n",[self stationNumber]);
}

- (void) readReset
{
    if(onlineMask){
        BOOL resetDone = NO;
        NSLog(@"AD811 Read/Reset for Station %d\n",[self stationNumber]);
        int i;
        for(i=0;i<8;i++){
            //read one adc channnel
            if(onlineMask & (0x1<<i)){
                unsigned short adcValue;
                [[self adapter] camacShortNAF:[self stationNumber] a:i f:2 data:&adcValue];
                if(i==7)resetDone = YES;
                NSLog(@"chan: %d  adcValue:%d\n",i,adcValue);
            }
        }
        if(!resetDone){
            unsigned short dummy;
            [[self adapter] camacShortNAF:[self stationNumber] a:7 f:2 data:&dummy]; //force reset
        }
    }
    else NSLog(@"No channels online for AD811 Station %d\n",[self stationNumber]);
}

- (void) testLAM
{
    unsigned short dummy;
    unsigned short status = [[self adapter] camacShortNAF:[self stationNumber] a:12 f:8 data:&dummy];
    NSLog(@"LAM %@ set\n",isQbitSet(status)?@"is":@"is not");
}
- (void) resetLAM
{
    unsigned short dummy;
    [[self adapter] camacShortNAF:[self stationNumber] a:12 f:10 data:&dummy];
}

- (void) generalReset;
{
    unsigned short dummy;
    [[self adapter] camacShortNAF:[self stationNumber] a:12 f:11 data:&dummy];
}

- (void) disableLAMEnableLatch
{
    unsigned short dummy;
    [[self adapter] camacShortNAF:[self stationNumber] a:12 f:24 data:&dummy];
}

- (void) enableLAMEnableLatch
{
    unsigned short dummy;
    [[self adapter] camacShortNAF:[self stationNumber] a:12 f:26 data:&dummy];
}
- (void) testAllChannels
{
    unsigned short dummy;
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:25 data:&dummy];
    [self readReset];
}
- (void) testBusy
{
    unsigned short dummy;
    unsigned short status = [[self adapter] camacShortNAF:[self stationNumber] a:12 f:27 data:&dummy];
    NSLog(@"Busy %@ set\n",isQbitSet(status)?@"is":@"is not");
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setIncludeTiming:[decoder decodeBoolForKey:@"ORAD811ModelIncludeTiming"]];
	[self setOnlineMask:[decoder decodeIntegerForKey:@"OR811OnlineMask"]];
    [self setSuppressZeros:[decoder decodeIntegerForKey:@"OR811SuppressZeros"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeBool:includeTiming forKey:@"ORAD811ModelIncludeTiming"];
    [encoder encodeInteger:onlineMask forKey:@"OR811OnlineMask"];
    [encoder encodeInteger:suppressZeros forKey:@"OR811SuppressZeros"];
	
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithInt:onlineMask] forKey:@"onlineMask"];
    [objDictionary setObject:[NSNumber numberWithBool:suppressZeros] forKey:@"suppressZeros"];
    return objDictionary;
}

@end
