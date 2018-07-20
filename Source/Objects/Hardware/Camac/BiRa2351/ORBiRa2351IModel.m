/*
 *  ORBiRa2351IModel.cpp
 *  Joerger Enterprises, Inc. 12 Channel Input register
 *  Orca
 *
 *  Created by Mark Howe on Fri Aug 4, 2006.
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
#import "ORBiRa2351IModel.h"

#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"

NSString* ORBiRa2351IModelInputRegisterChanged	= @"ORBiRa2351IModelInputRegisterChanged";
NSString* ORBiRa2351IModelPollingStateChanged   = @"ORBiRa2351IModelPollingStateChanged";
NSString* ORBiRa2351IModelLastReadChanged		= @"ORBiRa2351IModelLastReadChanged";

@interface ORBiRa2351IModel (private)
- (void) _setUpPolling;
- (void) _pollInputRegister;
@end

@implementation ORBiRa2351IModel

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [lastRead release];
    [super dealloc];
}
- (void) wakeUp
{
    if(![self aWake]){
        [self _setUpPolling];
    }
    [super wakeUp];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"BiRa2351ICard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORBiRa2351IController"];
}

- (NSString*) helpURL
{
	return @"CAMAC/BiRa2351.html";
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"2351";
}
- (NSString*) lastRead
{
    return lastRead;
}

- (void) setLastRead:(NSString*)aLastRead
{
    [lastRead autorelease];
    lastRead = [aLastRead copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBiRa2351IModelLastReadChanged object:self];
}
- (int) pollingState
{
    return pollingState;
}

- (void) setPollingState:(int)aPollingState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollingState:pollingState];
    
    pollingState = aPollingState;
    [self performSelector:@selector(_setUpPolling) withObject:nil afterDelay:0.5];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBiRa2351IModelPollingStateChanged object:self];
}

- (unsigned short) inputRegister
{
    return inputRegister;
}

- (void) setInputRegister:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInputRegister:inputRegister];
    
    inputRegister = aMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBiRa2351IModelInputRegisterChanged object:self];
}

- (BOOL)inputBit:(int)bit
{
	return inputRegister&(1<<bit);
}

- (void) setInputBit:(int)bit withValue:(BOOL)aValue
{
	unsigned char aMask = inputRegister;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setInputRegister:aMask];
}

- (NSString*) identifier
{
    return @"In";
}

#pragma mark ¥¥¥Hardware functions
- (void) readInputRegister:(BOOL)verbose
{
	@synchronized(self){
		uint32_t theRawValue;
		[[self adapter] camacLongNAF:[self stationNumber] a:0 f:2 data:&theRawValue];
		[self setInputRegister:theRawValue];
		if(verbose)NSLog(@"BiRa 2351 (station %d) Input Reg: 0x%03x\n",[self stationNumber],inputRegister);
	}
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setPollingState:[decoder decodeIntForKey:	   @"pollingState"]];
	[self setLastRead:@"Never"];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];	
    [encoder encodeInteger:pollingState forKey:@"pollingState"];
}

#pragma mark ¥¥¥Bit Processing Protocol
- (void)processIsStarting
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self setLastRead:@"Via Process Manager"];
}

- (void)processIsStopping
{
	[self _setUpPolling];
	[self setLastRead:[[NSDate date] stdDescription]];
}

- (void) startProcessCycle
{
	//grab the bit pattern at the start of the cycle. it
	//will not be changed during the cycle.
	[self readInputRegister:NO];
	processInputValue = inputRegister;
}

- (void) endProcessCycle
{
}

- (BOOL) processValue:(int)channel;
{
	return (processInputValue & (1L<<channel)) > 0;
}
- (void) setProcessOutput:(int)channel value:(int)value
{
	//no output, nothing to do
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"%d,%d,%@",(int)[self crateNumber],(int)[self  stationNumber],[self identifier]];
}

@end

@implementation ORBiRa2351IModel (private)
- (void) _setUpPolling
{
    if(pollingState!=0){        
        NSLog(@"Polling BiRa 2351 Input Register,%d,%d  every %d seconds.\n",[self crateNumber],[self stationNumber],pollingState);
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(_pollInputRegister) withObject:self afterDelay:pollingState];
        [self _pollInputRegister];
    }
    else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        NSLog(@"Not Polling BiRa 2351 Input Register,%d,%d\n",[self crateNumber],[self stationNumber]);
    }
}

- (void) _pollInputRegister
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    @try { 
        [self readInputRegister:NO];    
		[self setLastRead:[[NSDate date] description]];
    }
	@catch(NSException* localException) { 
        //catch this here to prevent it from falling thru, but nothing to do.
	}
	
	if(pollingState!=0){
		[self performSelector:@selector(_pollInputRegister) withObject:nil afterDelay:pollingState];
	}
}

@end
