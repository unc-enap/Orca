/*
 *  ORBiRa3251OModel.cpp
 *  Joerger Enterprises, Inc. 12 Channel Output register
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
#import "ORBiRa3251OModel.h"

#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"

NSString* ORBiRa3251OModelOutputRegisterChanged = @"ORBiRa3251OModelOutputRegisterChanged";

@implementation ORBiRa3251OModel

#pragma mark ¥¥¥Initialization
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"BiRa3251OCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORBiRa3251OController"];
}

- (NSString*) helpURL
{
	return @"CAMAC/BiRa3251.html";
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"3251";
}
- (unsigned short) outputRegister
{
    return outputRegister;
}

- (void) setOutputRegister:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputRegister:outputRegister];
    
    outputRegister = aMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORBiRa3251OModelOutputRegisterChanged object:self];
}

- (BOOL)outputBit:(int)bit
{
	return outputRegister&(1<<bit);
}

- (void) setOutputBit:(int)bit withValue:(BOOL)aValue
{
	unsigned char aMask = outputRegister;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setOutputRegister:aMask];
}

- (NSString*) identifier
{
    return @"Out";
}

#pragma mark ¥¥¥Hardware Test functions
- (void) writeOutputRegister:(BOOL)verbose
{
	@synchronized(self){
		if(verbose)NSLog(@"output mask for BiRa 3251 Output (station %d)\n",[self stationNumber]);
		unsigned long theRawValue = outputRegister;
		[[self adapter] camacLongNAF:[self stationNumber] a:0 f:16 data:&theRawValue];
	}
}

- (void) initBoard
{
	[self writeOutputRegister:NO];
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setOutputRegister:[decoder decodeIntForKey:  @"outputRegister"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];	
    [encoder encodeInt:outputRegister forKey:@"outputRegister"];
}

#pragma mark ¥¥¥Bit Processing Protocol
- (void)processIsStarting
{
}

- (void)processIsStopping
{
}

- (void) startProcessCycle
{
	processOutputMask = 0L;
}

- (void) endProcessCycle
{
	//write out the output bit pattern result.
	[self setOutputRegister:processOutputMask];
	[self writeOutputRegister:NO];
}

- (void) setProcessOutput:(int)channel value:(int)value
{
	processOutputMask |= (1L<<channel);
	if(value)	processOutputValue |= (1L<<channel);
	else		processOutputValue &= ~(1L<<channel);
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"%d,%d,%@",[self crateNumber],[self  stationNumber],[self identifier]];
}
- (BOOL) processValue:(int)channel;
{
	return 0;
}
@end

