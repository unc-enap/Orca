//
//  ORMaskedWaveform.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 7 2007.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORMaskedWaveform.h"

@implementation ORMaskedWaveform

#pragma mark ¥¥¥Accessors

- (uint32_t) mask
{
	return mask;
}

- (void) setMask:(uint32_t)aMask
{
	mask=aMask;
}

-(int32_t) value:(uint32_t)aChan
{
	if(!mask)return [super value:aChan];
	return [super value:aChan] & mask;
}

-(int32_t) unMaskedValue:(unsigned short)aChan
{
	return [super value:aChan];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setMask:[decoder decodeIntForKey:@"mask"]];
    [[self undoManager] enableUndoRegistration];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:mask forKey:@"mask"];
}

@end

@implementation ORMaskedIndexedWaveform

#pragma mark ¥¥¥Accessors

- (void) setStartIndex:(uint32_t)anIndex
{
	startIndex = anIndex;
}

- (uint32_t) startIndex
{
	return startIndex;
}

-(int32_t) value:(uint32_t)aChan
{
	aChan = (aChan + startIndex)%[self numberBins];;
	if(!mask)return [super value:aChan];
	return [super value:aChan] & mask;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setStartIndex:[decoder decodeIntForKey:@"startIndex"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:startIndex forKey:@"startIndex"];
}
@end

@implementation ORMaskedIndexedWaveformWithSpecialBits
- (void) dealloc
{
	[bitNames release];
	[super dealloc];
}
- (void) makeMainController
{
    [self linkToController:@"ORWaveformSpecialBitsController"];
}

#pragma mark ¥¥¥Accessors
- (void) setScaleOffset:(int32_t)aValue
{
    scaleOffset = aValue;
}

- (int32_t) scaleOffset
{
    return scaleOffset;
}

- (void) setBitNames:(NSArray*)someNames
{
	[someNames retain];
	[bitNames release];
	bitNames = someNames;
}

- (NSArray*) bitNames
{
	return bitNames;
}

- (void) setSpecialBitMask:(uint32_t)aMask
{
	specialBitMask=aMask;
	numBits = 0;
	firstBitMask = 0;
	int i;
	for(i=0;i<32;i++){
		if(specialBitMask & (1UL<<i)) {
			numBits++;
			if(firstBitMask==0)firstBitMask = (uint32_t)(1L<<i);
		}
	}
}

- (uint32_t) specialBitMask
{
	return specialBitMask;
}

- (int) numBits
{
	return numBits;
}

- (uint32_t) firstBitMask
{
	return firstBitMask;
}

-(int32_t) value:(uint32_t)aChan
{
	aChan = (aChan + startIndex)%[self numberBins];
    return [self unMaskedValue:aChan];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setSpecialBitMask:[decoder decodeIntForKey:@"specialBitMask"]];
    [self setScaleOffset:   [decoder decodeIntForKey:@"scaleOffset"]];
    [self setBitNames:      [decoder decodeObjectForKey:@"bitNames"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:specialBitMask forKey:@"specialBitMask"];
    [encoder encodeInt:scaleOffset    forKey:@"scaleOffset"];
    [encoder encodeObject:bitNames      forKey:@"bitNames"];
}

@end



