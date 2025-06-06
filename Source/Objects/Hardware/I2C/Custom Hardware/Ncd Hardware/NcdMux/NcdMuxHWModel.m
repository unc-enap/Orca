//
//  NcdMuxHWModel.m
//  Orca
//
//  Created by Mark Howe on Fri Feb 21 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "NcdMuxHWModel.h"
#import "NcdMuxController.h"
#import "ORIP408Model.h"
#import "ORHVSupply.h"

@interface NcdMuxHWModel (private)
- (BOOL) waitForCSBLow;
- (BOOL) waitForCSBLow;
- (mux_result) sendCmd:(uint32_t) anOutputWord;
- (uint32_t) invertValue: (uint32_t) anOutputWord;
- (uint32_t) insertMuxAddress:(uint32_t)aMuxAddress into:(uint32_t) anOutputWord;
- (uint32_t) insertCommand: (uint32_t)aCommand into:(uint32_t) anOutputWord;
- (uint32_t) insertBusStrobe:(BOOL)aState into:(uint32_t) anOutputWord;
- (uint32_t) insertScopeTrigger:(char)aScopeTriggerSelection into:(uint32_t)anOutputWord;
- (uint32_t) insertChannel:(unsigned short)theChannel into:(uint32_t) anOutputWord;
- (uint32_t) insertData:(unsigned short) theData into:(uint32_t) anOutputWord;
- (uint32_t) insertControlPadInto:(uint32_t) anOutputWord;
- (void) resetBusStrobeInWord:(uint32_t) anOutputWord;
- (mux_result) readReturnCode;
- (BOOL) delayRead;
- (void) initAdcReadDelay;
@end

@implementation NcdMuxHWModel

- (id) init 
{
	self = [super init];
	sendLock = [[NSLock alloc] init];
	return self;
}

- (void) dealloc
{
	[sendLock release];
	[super dealloc];
}

- (void) connectionChanged
{
}

#pragma mark •••Accessors
- (ORConnector*) connectorTo408
{
    return connectorTo408;
}

- (void) setConnectorTo408:(ORConnector*)aConnector
{
    connectorTo408 = aConnector;
}

- (int) scopeSelection
{
    return scopeSelection;
}

- (void) setScopeSelection:(int)newScopeSelection
{
    
    scopeSelection = newScopeSelection;
}

- (void) setDoNotWaitForCSBLow:(BOOL)aState
{
    doNotWaitForCSBLow = aState;
}
- (BOOL) doNotWaitForCSBLow
{
    return doNotWaitForCSBLow;
}

#pragma mark •••Hardware Access
-(mux_result) writeChannel:(unsigned char) aChannel mux:(unsigned short) muxBox
{
	mux_result theResult;
    @synchronized(self){
		//Build the command word
		uint32_t anOutputWord = [self insertMuxAddress:muxBox into:0L];
		anOutputWord = [self insertCommand:kWriteChannelCmd into:anOutputWord];
		anOutputWord = [self insertChannel:aChannel into:anOutputWord];
		
		theResult = [self sendCmd:anOutputWord];
		
		[self resetBusStrobeInWord:anOutputWord];
	}
    
    return theResult;
}

-(mux_result) writeDACValue:(unsigned short) aValue mux:(unsigned char) muxBox channel:(unsigned short) aChannel
{
	mux_result theResult;    
    @synchronized(self){
		theResult = [self writeChannel:aChannel mux:muxBox];
		if(theResult==kCarWritten){
			uint32_t anOutputWord = 0L;
			anOutputWord = [self insertCommand:kWriteDacCmd into:anOutputWord];
			anOutputWord = [self insertData:aValue into:anOutputWord];
			
			theResult = [self sendCmd:anOutputWord];
			
			[self resetBusStrobeInWord:anOutputWord];
		}
		else {
			NSLogError(@" ",@"Mux",@"Writing DAC",nil);
		}
	}
    
    return theResult;
}

-(mux_result) getADCValue:(unsigned short*)theDrValue mux:(unsigned char) muxBox channel:(unsigned short) aChannel
{
	// First write the MUX and channel from which the ADC value will be read
	mux_result theResult;
	
	@synchronized(self){
		theResult = [self writeChannel:aChannel mux:muxBox];
		if(theResult==kCarWritten){
			uint32_t anOutputWord = [self insertCommand:kReadAdcCmd into:0L];
			
			theResult = [self sendCmd:anOutputWord];
			
			if(theResult == kAdcToDr){
				ORIP408Model* the408 = [connectorTo408 connectedObject];
				uint32_t value = [the408 getInputWithMask:kControlPad];
				*theDrValue = (unsigned short)((kDataRegisterMask & value) >> kOutReadDRShift);
			}
			[self resetBusStrobeInWord:anOutputWord];
		}
		else {
			NSLogError(@" ",@"Mux",@"Reading ACD",nil);
		}
    }
    return theResult;
}

-(mux_result) getHVADCValue:(unsigned short*)theDrValue mux:(unsigned char) muxBox channel:(unsigned short) aChannel
{
	mux_result 	theResult;
    
    @synchronized(self){
		// First write the MUX and channel from which the ADC value will be read
		theResult = [self writeChannel:aChannel mux:muxBox];
		
		if(theResult==kCarWritten){
			uint32_t anOutputWord = [self insertCommand:kReadAdcCmd into:0L];
			
			theResult = [self sendCmd:anOutputWord];
			
			if(theResult == kAdcToDr){
				ORIP408Model* the408 = [connectorTo408 connectedObject];
				uint32_t value = [the408 getInputWithMask:kControlPad];
				*theDrValue = (kAdcMask & value) >> kOutReadDRShift;
			}
			[self resetBusStrobeInWord:anOutputWord];
		}
		else {
			NSLogError(@" ",@"HV",@"Reading ADC Value",nil);
		}
    }
    return theResult;
}



-(mux_result) getStatusQuery:(unsigned short*)theDrValue mux:(unsigned char) muxBox
{
    
	mux_result theResult;
    @synchronized(self){
		uint32_t anOutputWord = [self insertMuxAddress:muxBox into:0L];
		anOutputWord = [self insertCommand:kStatusQueryCmd into:anOutputWord];
		
		theResult = [self sendCmd:anOutputWord];
		
		if (theResult == kIdStatusToDr){
			ORIP408Model* the408 = [connectorTo408 connectedObject];
			*theDrValue = kStatusQueryMask & ([the408 getInputWithMask:kControlPad] >> kOutReadDRShift);
		}
		else {
			*theDrValue = 0xff;
			NSLogError(@" ",@"Mux",@"Status Query",nil);
		}
		[self resetBusStrobeInWord:anOutputWord];
	}
    
    return theResult;
}

- (mux_result) disableScopes
{
	mux_result theResult;
	@synchronized(self){
		
		uint32_t anOutputWord = 0L;
		anOutputWord = [self insertCommand:kArmRearmCmd into:anOutputWord];
		anOutputWord = [self insertScopeTrigger:0 into:anOutputWord];
		
		theResult = [self sendCmd:anOutputWord];
		
		[self resetBusStrobeInWord:anOutputWord];
		
	}
    return theResult;
}

- (mux_result) armScopeSelection
{
	mux_result theResult;
	@synchronized(self){
		
		uint32_t anOutputWord = 0L;
		anOutputWord = [self insertCommand:kArmRearmCmd into:anOutputWord];
		anOutputWord = [self insertScopeTrigger:[self scopeSelection] into:anOutputWord];
		
		theResult = [self sendCmd:anOutputWord];
		
		[self resetBusStrobeInWord:anOutputWord];
		
	}
    return theResult;
}

-(mux_result) getEventRegister:(unsigned short*)theDrValue
{
	mux_result theResult;
 	@synchronized(self){
		
		// Build the command word
		uint32_t anOutputWord = 0L;
		anOutputWord = [self insertCommand:kReadEventCmd into:anOutputWord];
		
		theResult = [self sendCmd:anOutputWord];
		
		if (theResult == kEventHeaderToDr) {
			ORIP408Model* the408 = [connectorTo408 connectedObject];
			*theDrValue = kDataRegisterMask & ([the408 getInputWithMask:kControlPad] >> kOutReadDRShift);
		}
		else {
			NSLogError(@" ",@"Mux",@"Reading Event Reg",nil);
		}
		[self resetBusStrobeInWord:anOutputWord];
    }
    
    return theResult;
}

- (mux_result) getSelectedMux:(unsigned short*)theDrValue mux:(unsigned char) muxBox
{
	mux_result theResult;
	@synchronized(self){
		
		uint32_t anOutputWord = 0L;
		anOutputWord = [self insertMuxAddress:muxBox into:anOutputWord];
		anOutputWord = [self insertCommand:kReadSelMuxCmd into:anOutputWord];
		
		theResult = [self sendCmd:anOutputWord];
		
		if (theResult == kSingleDataToDr) {
			ORIP408Model* the408 = [connectorTo408 connectedObject];
			*theDrValue = kDataRegisterMask & ([the408 getInputWithMask:kControlPad] >> kOutReadDRShift);
		}
		else {
			NSLogError(@" ",@"Mux",@"Get Selected Mux",nil);
		}
		[self resetBusStrobeInWord:anOutputWord];
    }
    
    return theResult;
}

- (mux_result) reset
{
    
	mux_result theResult;
	@synchronized(self){
		uint32_t anOutputWord = 0L;
		anOutputWord = [self insertCommand:kResetCmd into:anOutputWord];
		
		theResult = [self sendCmd:anOutputWord];
		
		[self resetBusStrobeInWord:anOutputWord];
	}	
    
    return theResult;
}

//-----------------------------------------------------------------------------
//	Method: 	resetAdcs
//	Description:	read back all adc in order to reset them.
//-----------------------------------------------------------------------------
-(void) resetAdcs
{
    
    
    unsigned short theValue;
    short anAdc;
    short aChan;
    for(anAdc=0;anAdc<9;anAdc++){
        for(aChan=0;aChan<11;aChan++){
            [self getHVADCValue:&theValue mux:anAdc channel:aChan];
        }
    }
    
    
}


#pragma mark •••HV Hardware Access
//-------------------------------------------------------------------------
//these methods are REQUIRED for interfacing to an HVRampModel
//
- (void) turnOnSupplies:(NSArray*)someSupplies state:(BOOL)aState;
{
    
    //when the relays change state, there can be a spurious jump in
    //the readback adc voltage. So here we init the delay counters.
    //any call to the adc readback routines will do nothing until the
    //delay has timed out.
    [self initAdcReadDelay];
    
    if(aState==YES){
        //about to turn a replay on, make sure that the dac is set to zero.
        NSEnumerator* e = [someSupplies objectEnumerator];
        id aSupply;
        while(aSupply = [e nextObject]){
            [self writeDac:0 supply:aSupply];
        }
    }
    
    // Build the command word
    uint32_t anOutputWord = 0L;
    
    uint32_t aMask = [self readRelayMask];
    NSEnumerator* e = [someSupplies objectEnumerator];
    id aSupply;
    while(aSupply = [e nextObject]){
        int s = [aSupply supply];
        if(aState){
            aMask |= (1L<<s);
        }
        else {
            aMask &= ~(1L<<s);
        }
    }
    
    anOutputWord = [self insertData:aMask into:anOutputWord];
    anOutputWord = [self insertCommand:kSetHVRelaysCmd into:anOutputWord];
    
    mux_result theResult = [self sendCmd:anOutputWord];
    [self resetBusStrobeInWord:anOutputWord];
    
    if(theResult == kHVRelaysSet){
        aMask = [self readRelayMask];	//get the state
        e = [someSupplies objectEnumerator];
        while(aSupply = [e nextObject]){
            int s = [aSupply supply];
            [aSupply setRelay:((aMask & (1L << s))!=0)];
        }
    }
    else {
		NSLogError(@" ",@"HV",@"Setting Relays",nil);
    }
	
    
    
    
}

- (void) writeDac:(int)aValue supply:(id)aSupply
{
    
    BOOL result = YES;
    //let's be conversative and double check the value
    if(aValue > kHVFullScale)aValue = kHVFullScale;
    
    //break up the value into whole and fractional parts.
    double wholePart;
    double fractionalPart = modf(255*aValue/kHVFullScale,&wholePart);
    
    //send out the coarse part
    mux_result err = [self writeDACValue:(short)wholePart mux:kHVCoarseWriteAddress channel:[aSupply supply]];
    if(err != kDacWriteComplete)result = NO;
    else {
        //send out the fine part
        //err = writeDACValue(kHVFineWriteAddress,aSupply,(short)(fractionalPart*255));
        err = [self writeDACValue:(short)(fractionalPart*255) mux:kHVFineWriteAddress channel:[aSupply supply]];
        if(err != kDacWriteComplete)result = NO;
        else [self readDac:aSupply];
    }
    
    if(result){
        [aSupply setDacValue:aValue];
    }
    
    
}

- (BOOL) readDac:(id) aSupply
{
    
    unsigned short coarseValue=0;
    unsigned short fineValue=0;
    BOOL result = YES;
    //grab out the coarse part
    mux_result err = [self getHVADCValue:&coarseValue mux:kHVCoarseWriteAddress channel:[aSupply supply]];
    if(err == kReadAdcCmd){
        //grab out the fine part
        mux_result err = [self getHVADCValue:&fineValue mux:kHVFineWriteAddress channel:[aSupply supply]];
        
        if(err == kReadAdcCmd){
            int value = ((coarseValue + fineValue/255.)*2000/168.)+.5;
            [aSupply setDacValue:value];
        }
        else {
			NSLogError(@" ",@"HV",@"Reading DAC",nil);
			result = NO;
		}
    }
    
    return result;
}


- (BOOL) readAdc:(id) aSupply
{
    
    BOOL result = YES;
    if( ![self delayRead]){
        unsigned short val=0;
        mux_result err = [self getHVADCValue:&val mux:kHVReadAddress channel:[aSupply supply]];
        if(err == kReadAdcCmd){
            [aSupply setAdcVoltage:([aSupply voltageAdcOffset]+([aSupply voltageAdcSlope]* val/255.))];
        }
        else {
			NSLogError(@" ",@"HV",@"Reading ADC",nil);
			result = NO;
        }
    }
    
    return result;
}

- (BOOL) readCurrent:(id) aSupply
{
    
    unsigned short val=0;
    BOOL result = YES;
    mux_result err = [self getHVADCValue:&val mux:kHVCurrentReadAddress channel:[aSupply supply]];
    if(err == kReadAdcCmd){
        [aSupply setCurrent:(val*3./255.)*1000.0/4.]; //uncomment when more sensitive board ready
        //[aSupply setCurrent:(val*3./255.)*66.66666/4.]; //uncomment when more sensitive board ready
		//[aSupply setCurrent:(val*3./255.)*1000.];      //remove this line when above line uncommented
    }
    else {
		NSLogError(@" ",@"HV",@"Reading Current",nil);
		result = NO;
    }
    
    return result;
}

- (uint32_t) readRelayMask
{
    // Build the command word
    
    uint32_t mask = 0L;
    uint32_t anOutputWord = 0L;
    anOutputWord = [self insertCommand:kReadHVRelaysCmd into:anOutputWord];
    
    mux_result theResult = [self sendCmd:anOutputWord];
    
    if(theResult == kHVRelaysToDr){
        uint32_t theData;
        
        
        ORIP408Model* the408 = [connectorTo408 connectedObject];
        theData = [the408 getInputWithMask:kControlPad];
        
        mask = (kRelayMask & theData)>>kOutReadDRShift;
        lowPowerOn = (theData & kHVPwrMask)!=0;
        [self resetBusStrobeInWord:anOutputWord];
        
    }
    else {
		NSLogError(@" ",@"HV",@"Reading Relay Mask",nil);
        [self resetBusStrobeInWord:anOutputWord];
    }
    
    return mask;
}

//End of REQUIRED methods
//-------------------------------------------------------------------------

#pragma mark •••HV Helpers
//these methods are not required


- (BOOL) lowPowerOn
{
    return lowPowerOn;
}


#pragma mark •••Archival
static NSString *NcdMuxHW408Connector 		= @"NcdMuxHW 408 Connector";
static NSString *NcdMuxHWDoNotWaitForCSLow 	= @"NcdMuxHW DoNoTWaitForCSLow";
static NSString *NcdMuxScopeSelection 		= @"NcdMuxHW ScopeSelection";
static NSString *NcdMuxDelayTimeStart 		= @"NcdMuxDelayTimeStart";
static NSString *NcdMuxdelayAdcRead 		= @"NcdMuxdelayAdcRead";


- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [self setConnectorTo408:[decoder decodeObjectForKey:NcdMuxHW408Connector]];
    [self setDoNotWaitForCSBLow:[decoder decodeIntegerForKey:NcdMuxHWDoNotWaitForCSLow]];
    [self setScopeSelection:[decoder decodeIntForKey:NcdMuxScopeSelection]];
    adcDelayTimeStart = [decoder decodeBoolForKey:NcdMuxDelayTimeStart];
    delayAdcRead = [decoder decodeBoolForKey:NcdMuxdelayAdcRead];
	
	sendLock = [[NSLock alloc] init];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:[self connectorTo408] forKey:NcdMuxHW408Connector];
    [encoder encodeInteger:[self doNotWaitForCSBLow] forKey:NcdMuxHWDoNotWaitForCSLow];
    [encoder encodeInteger:[self scopeSelection] forKey:NcdMuxScopeSelection];
    [encoder encodeBool:adcDelayTimeStart forKey:NcdMuxDelayTimeStart];
    [encoder encodeBool:delayAdcRead forKey:NcdMuxdelayAdcRead];
}

@end

@implementation NcdMuxHWModel (private)
- (BOOL) waitForCSBHigh
{
    ORIP408Model* the408 = [connectorTo408 connectedObject];
    if([the408 getInputWithMask:kCmdCompleteBitMask] & kCmdCompleteBitMask)return YES;
    else {
        double t0 = [NSDate timeIntervalSinceReferenceDate];
        while(true){
            if([the408 getInputWithMask:kCmdCompleteBitMask] & kCmdCompleteBitMask)return YES;
            else if([NSDate timeIntervalSinceReferenceDate]-t0 > .001)return NO;
        }
    }
    return YES;
}

- (BOOL) waitForCSBLow
{
    if([self doNotWaitForCSBLow]){
        double t0 = [NSDate timeIntervalSinceReferenceDate];
        while([NSDate timeIntervalSinceReferenceDate]-t0 < .0001);
        return YES;
    }
    
    ORIP408Model* the408 = [connectorTo408 connectedObject];
    if(!([the408 getInputWithMask:kCmdCompleteBitMask] & kCmdCompleteBitMask))return YES;
    else {
        double t0 = [NSDate timeIntervalSinceReferenceDate];
        while(true){
            if(!([the408 getInputWithMask:kCmdCompleteBitMask] & kCmdCompleteBitMask))return YES;
            else if([NSDate timeIntervalSinceReferenceDate]-t0 > .001)return NO;
        }
        return YES;
    }
}

- (mux_result) sendCmd:(uint32_t) anOutputWord
{
	mux_result theResult = 0;
	[sendLock lock];
	
	@try {
		if(![self waitForCSBLow]){
			[self resetBusStrobeInWord:anOutputWord];
			theResult =  kTimeOut;
		}
		else {
			ORIP408Model* the408 = [connectorTo408 connectedObject];
			anOutputWord = [self insertControlPadInto:anOutputWord];
			[the408 setOutputWithMask:kControlOutputMask value:[self invertValue:anOutputWord]];
			
			anOutputWord = [self insertBusStrobe:1 into:anOutputWord];				//raise the strobe
			[the408 setOutputWithMask:kControlOutputMask value:[self invertValue:anOutputWord]];
			
			if(![self waitForCSBHigh]){
				[self resetBusStrobeInWord:anOutputWord];
				theResult =  kTimeOut;
			}
			else {
				mux_result muxResult = [self readReturnCode];
				anOutputWord = [self insertBusStrobe:0 into:anOutputWord];			//lower the strobe
				[the408 setOutputWithMask:kControlOutputMask value:[self invertValue:anOutputWord]];
				theResult =  muxResult;
			}
		}
		[sendLock unlock];
	}
	@catch(NSException* localException) {
		[sendLock unlock];
		[localException raise];
	}
	
	return theResult;
}

- (void) resetBusStrobeInWord:(uint32_t) anOutputWord
{
    ORIP408Model* the408 = [connectorTo408 connectedObject];
    anOutputWord = [self insertBusStrobe:0 into:anOutputWord];			//lower the strobe
    [the408 setOutputWithMask:kControlOutputMask value:[self invertValue:anOutputWord]];
}

#pragma mark •••Low Level Access
- (uint32_t) invertValue: (uint32_t) anOutputWord
{
    return ~anOutputWord;
}

- (uint32_t) insertMuxAddress:(uint32_t)aMuxAddress into:(uint32_t) anOutputWord
{
    anOutputWord |= ((uint32_t)aMuxAddress << kMuxSelBitsShift) & kMuxSelBitsMask;
    return anOutputWord;
}

- (uint32_t) insertCommand: (uint32_t)aCommand into:(uint32_t) anOutputWord
{
    anOutputWord |= ((uint32_t)aCommand << kCmdShift) & kCmdMask;
    return anOutputWord;
}

- (uint32_t) insertBusStrobe:(BOOL)aState into:(uint32_t) anOutputWord
{
    if(aState)anOutputWord |= kBusStrobeBitMask;
    else anOutputWord &= ~kBusStrobeBitMask;
    return anOutputWord;
}

- (uint32_t) insertScopeTrigger:(char)aScopeTriggerSelection into:(uint32_t)anOutputWord
{
    return [self insertData:aScopeTriggerSelection into:anOutputWord];
}

- (uint32_t) insertChannel:(unsigned short)theChannel into:(uint32_t) anOutputWord
{
    anOutputWord |= ((uint32_t)theChannel << kChannelShift) & kChannelMask;
    return anOutputWord;
}

- (uint32_t) insertData:(unsigned short) theData into:(uint32_t) anOutputWord
{
    anOutputWord |= ((uint32_t)theData << kOutDataShift) & kOutDataMask;
    return anOutputWord;
    
}

- (uint32_t) insertControlPadInto:(uint32_t) anOutputWord
{
    anOutputWord |=  kControlPad;
    return anOutputWord;
}

- (BOOL) delayRead
{
    if(delayAdcRead){
        if([NSDate timeIntervalSinceReferenceDate] - adcDelayTimeStart > kReadDelayTime){
            delayAdcRead = false;
        }
    }
    return delayAdcRead;
}

- (void) initAdcReadDelay
{
    delayAdcRead = YES;
    adcDelayTimeStart = [NSDate timeIntervalSinceReferenceDate];
}

- (mux_result) readReturnCode
{
	mux_result val;
	@synchronized(self){
		ORIP408Model* the408 = [connectorTo408 connectedObject];
		val =  ([the408 getInputWithMask:kReturnCodeMask] & kReturnCodeMask) >> kReturnCodeShift;
	}
    return val;
}

@end
