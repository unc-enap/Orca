/*
 *  ORL2301Model.m
 *  Orca
 *
 *  Created by Sam Meijer, Jason Detwiler, and David Miller, July 2012.
 *  Adapted from AD811 code by Mark Howe, written Sat Nov 16 2002.
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
#import "ORL2301Model.h"

#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"

NSString* ORL2301ModelIncludeTimingChanged			= @"ORL2301ModelIncludeTimingChanged";
NSString* ORL2301SettingsLock						= @"ORL2301SettingsLock";
NSString* ORL2301SuppressZerosChangedNotification   = @"ORL2301SuppressZerosChangedNotification";
NSString* ORL2301AllowOverflowChangedNotification   = @"ORL2301AllowOverflowChangedNotification";

@implementation ORL2301Model

#pragma mark ¥¥¥Initialization
- (id) init
{		
    self = [super init];
    return self;
}

- (void) dealloc
{
    [lastDataTS release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"L2301Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORL2301Controller"];
}

- (NSString*) helpURL
{
	return @"CAMAC/L2301.html";
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"L2301";
}

- (BOOL) includeTiming
{
    return includeTiming;
}

- (void) setIncludeTiming:(BOOL)aIncludeTiming
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIncludeTiming:includeTiming];
    
    includeTiming = aIncludeTiming;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL2301ModelIncludeTimingChanged object:self];
}

- (uint32_t) dataId 
{ 
    return dataId; 
}

- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
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
	 postNotificationName:ORL2301SuppressZerosChangedNotification
	 object:self];
    
}

- (BOOL) allowOverflow
{   
    return allowOverflow;
}

- (void) setAllowOverflow:(BOOL)aFlag
{   
    [[[self undoManager] prepareWithInvocationTarget:self] setAllowOverflow:allowOverflow];
	
    allowOverflow = aFlag;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORL2301AllowOverflowChangedNotification
	 object:self];
}


- (NSDate *) lastDataTS
{
    return lastDataTS; 
}

- (void) setLastDataTS: (NSDate *) aLastTime
{
    [aLastTime retain];
    [lastDataTS release];
    lastDataTS = aLastTime;
}

#pragma mark ¥¥¥DataTaker

- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (void) reset
{
    [self stopQVT];
    [self clearQVT];
    [self setReadWriteBin: 0];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORL2301DecoderForHist",         @"decoder",
								 [NSNumber numberWithLong:dataId], @"dataId",
								 [NSNumber numberWithBool:YES],    @"variable",
								 [NSNumber numberWithLong:-1],     @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"histogramData"];
    return dataDictionary;
	
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(![self adapter]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI-CAMAC Controller (i.e. a CC32)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORL2301Model"];    
    
    //----------------------------------------------------------------------------------------
    // Cache the following items for a little more speed.
    controller         = [[self adapter] controller];
    cachedStation      = [self stationNumber];
    unChangingDataPart = (([self crateNumber]&0xf)<<21) | ((cachedStation & 0x0000001f)<<16);
	
    [self clearExceptionCount];
    [self reset];
    [self startQVT];
    [self setLastDataTS:[NSDate date]];
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if([lastDataTS timeIntervalSinceNow] < -5.) {
        [self shipHistogram:aDataPacket];
        [self startQVT];
        [self setLastDataTS:[NSDate date]];
    }
}

- (void) shipHistogram:(ORDataPacket*)aDataPacket
{   
    [self readHistIntoDataBuffer];
	
    // ship the packet if there is any data to be shipped
    unsigned int len = dataBuffer[0] & 0x3ffff;
    if(len > 0) {
        [aDataPacket addLongsToFrameBuffer:dataBuffer length:len];
    }
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [self stopQVT];
    [self shipHistogram:aDataPacket];
}

#pragma mark ¥¥¥Hardware Test functions
- (unsigned short) readQVT
{   
    unsigned short qvtValue;
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:2 data:&qvtValue];
	return qvtValue;
}

- (unsigned short) readQVTAt:(unsigned short)bin
{
	[self setReadWriteBin: bin];
	return [self readQVT];
}

- (void) readHistIntoDataBuffer 
{   
    NSString* errorLocation = @"";
	
    union {
        NSTimeInterval asTimeInterval;
        uint32_t asLongs[2];
    } theTimeRef;
	
    @try {
        [self setReadWriteBin: 0];
        [self setReadWriteBin: 0]; // this command is sometimes flaky

        unsigned int len = 0;
        int iBin;
        for(iBin = 0; iBin < kNBins; iBin++) {
            // read the counts for this bin
            // note: the internal read/write bin is set to iBin+1 after this call
            unsigned short counts = [self readQVT];
			
            // Error checking: counts should never decrease. This shouldn't
            // happen, but emit a warning message and just continue
            if(counts < cachedCounts[iBin]) {
                NSLog(@"L2301 Card Warning: bin %d counts decreased (or cycled) from %d to %d",
                      iBin, cachedCounts[iBin], counts);
            }
			
            // calculate the count increase in this bin
            unsigned short newCounts = counts - cachedCounts[iBin];
			
            // add newCounts to the data record if necessary
            if(!suppressZeros || newCounts > 0) {
                // initialize the data record; dataBuffer[0] is set at the end
                if(len == 0) {
                    int32_t includeTimingMask = 0;
                    len = 2;
                    if(includeTiming){
                        theTimeRef.asTimeInterval = [NSDate timeIntervalSinceReferenceDate];
                        includeTimingMask = 0x1<<25;
                        dataBuffer[2] = theTimeRef.asLongs[1]; //low part
                        dataBuffer[3] = theTimeRef.asLongs[0]; //high part
                        len = 4;
                    }
                    dataBuffer[1] = includeTimingMask | unChangingDataPart;
                }
                dataBuffer[len] = iBin << 16 | newCounts;
                len++;
				
                // cache the counts
                cachedCounts[iBin] = counts;
            }
			
            // zero the bin (and cachedCounts) to avoid overflow if requested by the user
            if(allowOverflow && counts > kHalfMaxCounts) {
                // Emit a warning if any bin has maxed out its counts since
                // the last read: it means the data rate is too high.
                if(counts >= kMaxCounts-1) {
                    static BOOL firstTime = true;
                    if(firstTime) {
                        NSLog(@"L2301 Card Warning: reached max counts on bin %d -- data rate is too high.", iBin);
                        firstTime = false       ;
                    }
                }
                // note: the internal read/write bin is set to iBin+1 after
                // this call (same as for the earlier readQVT, so this is safe)
                [self writeQVT:0 atBin:iBin];
                cachedCounts[iBin] = 0;
            }
        }
		
        dataBuffer[0] = dataId | len;
		
    }
    @catch(NSException* localException) {
        NSLogError(@"",@"L2301 Card Error",errorLocation,nil);
        [self incExceptionCount];
        [localException raise];
    }
}

- (void) clearQVT
{   
    //[[self adapter] camacShortNAF:[self stationNumber] a:0 f:9];
    uint32_t iBin;
    for(iBin = 0; iBin < kNBins; iBin++) [self writeQVT:0 atBin:iBin];
    memset(cachedCounts, 0, kNBins*sizeof(unsigned short));
}

- (void) writeQVT:(unsigned short)counts;
{   
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:16 data:&counts];
}

- (void) writeQVT:(unsigned short)counts atBin:(unsigned short)bin
{
    [self setReadWriteBin: bin];
    [self  writeQVT: counts];
}

- (void) setReadWriteBin:(unsigned short)bin
{
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:17 data:&bin];
}

- (void) stopQVT
{
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:24];
}

- (void) incrementQVT
{
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:25];
}

- (void) incrementQVTAt:(unsigned short)bin
{
    [self setReadWriteBin: bin];
    [self incrementQVT];
}

- (void) startQVT
{
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:26];
}

- (unsigned short) readStatusRegister
{
    uint32_t theRawValue;
    [[self adapter] camacLongNAF:[self stationNumber] a:0 f:1 data:&theRawValue];
    return theRawValue;
}


#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setIncludeTiming:[decoder decodeBoolForKey:@"ORL2301ModelIncludeTiming"]];
    [self setSuppressZeros:[decoder decodeIntegerForKey:@"ORL2301SuppressZeros"]];
    [self setAllowOverflow:[decoder decodeIntegerForKey:@"ORL2301AllowOverflow"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:includeTiming forKey:@"ORL2301ModelIncludeTiming"];
    [encoder encodeInteger:suppressZeros forKey:@"ORL2301SuppressZeros"];
    [encoder encodeInteger:allowOverflow forKey:@"ORL2301AllowOverflow"];
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithBool:suppressZeros] forKey:@"suppressZeros"];
    [objDictionary setObject:[NSNumber numberWithBool:allowOverflow] forKey:@"allowOverflow"];
    return objDictionary;
}

@end
