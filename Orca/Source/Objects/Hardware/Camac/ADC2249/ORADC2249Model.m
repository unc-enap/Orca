/*
 *  ORADC2249Model.cpp
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
#import "ORADC2249Model.h"

#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"

NSString* ORADC2249ModelIncludeTimingChanged		= @"ORADC2249ModelIncludeTimingChanged";
NSString* ORADC2249OnlineMaskChangedNotification	= @"ORADC2249OnlineMaskChangedNotification";
NSString* ORADC2249SettingsLock						= @"ORADC2249SettingsLock";
NSString* ORADC2249SuppressZerosChangedNotification  = @"ORADC2249SuppressZerosChangedNotification";


@implementation ORADC2249Model

#pragma mark ¥¥¥Initialization
- (id) init
{		
    self = [super init];
	[self setCheckLAM:YES];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"ADC2249Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORADC2249Controller"];
}

- (NSString*) helpURL
{
	return @"CAMAC/AD2249.html";
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"2249";
}

- (BOOL) includeTiming
{
    return includeTiming;
}

- (void) setIncludeTiming:(BOOL)aIncludeTiming
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIncludeTiming:includeTiming];
    
    includeTiming = aIncludeTiming;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORADC2249ModelIncludeTimingChanged object:self];
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (unsigned short)onlineMask {
	
    return onlineMask;
}

- (void)setOnlineMask:(unsigned short)anOnlineMask {
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:[self onlineMask]];
	
    onlineMask = anOnlineMask;
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:ORADC2249OnlineMaskChangedNotification
							  object:self];
	
}

- (BOOL)onlineMaskBit:(int)bit
{
	return onlineMask&(1L<<bit);
}

- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = onlineMask;
	if(aValue)aMask |= (1L<<bit);
	else aMask &= ~(1L<<bit);
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
                postNotificationName:ORADC2249SuppressZerosChangedNotification
							  object:self];
    
}

- (void) setCheckLAM: (BOOL) aState
{
    checkLAM = aState;
}

#pragma mark ¥¥¥DataTaker

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:includeTiming?kLongForm:kShortForm];
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
		if(IsLongForm(dataId))len = 2;	//not timing, long form = 2 words total
	}
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORADC2249DecoderForAdc",          @"decoder",
        [NSNumber numberWithLong:dataId],   @"dataId",
        [NSNumber numberWithBool:NO],       @"variable",
        [NSNumber numberWithLong:len],		@"length",
        [NSNumber numberWithBool:YES],      @"canBeGated",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"ADC"];
    return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	
    if(![[self adapter] controller]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI-CAMAC Controller (i.e. a CC32)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORADC2249Model"];    
    
    //----------------------------------------------------------------------------------------
    controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
    unChangingDataPart   =  (([self crateNumber]&0xf)<<21) | (([self stationNumber]& 0x0000001f)<<16); //doesn't change so do it here.
	cachedStation = [self stationNumber];
    [self clearExceptionCount];
    
	//[self initBoard];
    
    int i;
	onlineChannelCount = 0;
    for(i=0;i<kRegisterNumberADC2249;i++){
        if(onlineMask & (0x1L<<i)){
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
    BOOL resetDone;
	
	union {
		NSTimeInterval asTimeInterval;
		unsigned long asLongs[2];
	}theTimeRef;
	
    @try {
        
        //check the LAM
		BOOL isLamSet = NO;
		if(checkLAM)isLamSet = isQbitSet([controller camacShortNAF:cachedStation a:0 f:8 ]); //LAM status comes back in the Q bit
		else isLamSet =YES;
        if(isLamSet) { 
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
							unsigned long data = dataId | unChangingDataPart | (onlineList[i]&0xf)<<12 | (adcValue & 0xfff);
							[aDataPacket addLongsToFrameBuffer:&data length:1];
						}
						else {
							unsigned long data[4];
							int len = 2;			//default to no timing info
							long includeTimingMask = 0;
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
                    if(i == (kRegisterNumberADC2249- 1)) resetDone = YES;
                    
                }
                //read of last channel clears lam , if last channel wasn't read clear lam here
				if(!resetDone) {
					[controller camacShortNAF:cachedStation a:0 f:9]; 
				}
			}
            
            
  		}
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"ADC2249 Card Error",nil);
		[self incExceptionCount];
		[localException raise];
	}
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	[self disableLAMEnableLatch];
}

#pragma mark ¥¥¥Hardware Test functions

- (void) readNoReset
{
    if(onlineMask){
	    //[[self adapter] setCrateInhibit:NO];
		//[self generalReset];
		//[self enableLAMEnableLatch];
		unsigned short dummy;
        unsigned short status = [[[self adapter] controller] camacShortNAF:cachedStation a:0 f:8 data:&dummy];
        if(isQbitSet(status)) { //LAM status comes back in the Q bit
			NSLog(@"ADC2249 Read/No reset for Station %d\n",[self stationNumber]);
			int i;
			for(i=0;i<kRegisterNumberADC2249;i++){
				//read one adc channnel
				if(onlineMask & (0x1L<<i)){
					unsigned short adcValue;
					[[[self adapter] controller] camacShortNAF:[self stationNumber] a:i f:0 data:&adcValue];
					
					NSLog(@"chan: %d  adcValue:0x%x\n",i,adcValue);
				}
			}
		}
		else NSLog(@"ADC2249 Station %d No LAM--No Data\n",[self stationNumber]);
    }
    else NSLog(@"No channels online for ADC2249 Station %d\n",[self stationNumber]);
}

- (void) readReset
{
    if(onlineMask){
	    //[[self adapter] setCrateInhibit:NO];
		//[self generalReset];
		//[self enableLAMEnableLatch];
		unsigned short dummy;
        unsigned short status = [[[self adapter] controller] camacShortNAF:cachedStation a:0 f:8 data:&dummy];
        if(isQbitSet(status)) { //LAM status comes back in the Q bit
			BOOL resetDone = NO;
			NSLog(@"ADC2249 Read/Reset for Station %d\n",[self stationNumber]);
			int i;
			for(i=0;i<kRegisterNumberADC2249;i++){
				//read one adc channnel
				if(onlineMask & (0x1L<<i)){
					unsigned short adcValue;
					[[[self adapter] controller] camacShortNAF:[self stationNumber] a:i f:2 data:&adcValue];
					if(i==(kRegisterNumberADC2249 - 1))resetDone = YES;
					NSLog(@"chan: %d  adcValue:0x%x\n",i,adcValue);
				}
			}
			if(!resetDone){
				unsigned short dummy;
				[[[self adapter] controller] camacShortNAF:[self stationNumber] a:11 f:2 data:&dummy]; //force reset
			}
		}
		else NSLog(@"ADC2249 Station %d No LAM--No Data\n",[self stationNumber]);
    }
    else NSLog(@"No channels online for ADC2249 Station %d\n",[self stationNumber]);
}

- (void) testLAM
{
    unsigned short dummy;
    unsigned short status = [[[self adapter] controller] camacShortNAF:[self stationNumber] a:11 f:8 data:&dummy];
    NSLog(@"Q Response indicates LAM %@ set\n",isQbitSet(status)?@"is":@"is not");
}
- (void) resetLAM
{
    unsigned short dummy;
    [[[self adapter] controller] camacShortNAF:[self stationNumber] a:11 f:10 data:&dummy];
	//[self testAllChannels];
}

- (void) generalReset;
{
    unsigned short dummy;
    [[[self adapter] controller] camacShortNAF:[self stationNumber] a:11 f:9 data:&dummy];
}

- (void) disableLAMEnableLatch
{
    unsigned short dummy;
    [[[self adapter] controller] camacShortNAF:[self stationNumber] a:11 f:24 data:&dummy];
}

- (void) enableLAMEnableLatch
{
    unsigned short dummy;
    [[[self adapter] controller] camacShortNAF:[self stationNumber] a:11 f:26 data:&dummy];
}

- (void) testAllChannels
{
    unsigned short dummy;
    [[[self adapter] controller] camacShortNAF:[self stationNumber] a:11 f:25 data:&dummy];
    [self readReset];
}

//- (void) testBusy
//{
    //The following functions are undefined for this ADC module.
	
	//unsigned short dummy;
    //unsigned short status = [[[self adapter] controller] camacShortNAF:[self stationNumber] a:12 f:27 data:&dummy];
    //NSLog(@"Busy %@ set\n",isQbitSet(status)?@"is":@"is not");
//}


#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setIncludeTiming:[decoder decodeBoolForKey:@"ORADC2249ModelIncludeTiming"]];
    [self setOnlineMask:[decoder decodeIntForKey:@"ORADC2249OnlineMask"]];
    [self setSuppressZeros:[decoder decodeIntForKey:@"ORADC2249SuppressZeros"]];
    [[self undoManager] enableUndoRegistration];
	
	[self setCheckLAM:YES];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:includeTiming forKey:@"ORADC2249ModelIncludeTiming"];
    [encoder encodeInt:onlineMask forKey:@"ORADC2249OnlineMask"];
    [encoder encodeInt:suppressZeros forKey:@"ORADC2249SuppressZeros"];
	
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
 	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"onlineMask"]) return [cardDictionary objectForKey:@"onlineMask"];
    else if([param isEqualToString:@"suppressZeros"]) return [cardDictionary objectForKey:@"suppressZeros"];
    else return nil;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithInt:onlineMask] forKey:@"onlineMask"];
    [objDictionary setObject:[NSNumber numberWithBool:suppressZeros] forKey:@"suppressZeros"];
    return objDictionary;
}


#pragma mark ¥¥¥CamacList
- (BOOL) partOfLAMMask
{
	return onlineMask!=0;
}

- (void) addReadOutCommandsToStack:(NSMutableData*)stack;
{
	unsigned short naf;
	if(onlineMask){
		//unsigned short naf = nafGen([self stationNumber],0,8) | 0x8000;
		//[stack appendBytes:&naf length:sizeof(short)];
		//naf = 0x0080; //wait for lam
		//[stack appendBytes:&naf length:sizeof(short)];
		
		int i;
		for(i=0;i<onlineChannelCount;i++){
			naf = nafGen([self stationNumber],onlineList[i],2);
			[stack appendBytes:&naf length:sizeof(short)];
		}
	}
}

@end
