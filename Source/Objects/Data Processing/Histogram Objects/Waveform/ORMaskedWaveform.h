//
//  ORMaskedWaveform.h
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


#pragma mark ¥¥¥Imported Files
#import "ORWaveform.h"

@interface ORMaskedWaveform : ORWaveform  {
    uint32_t   mask;
}

#pragma mark ¥¥¥Accessors 
- (void) setMask:(uint32_t)aMask;
- (uint32_t) mask;
-(int32_t) unMaskedValue:(unsigned short)aChan;
@end

@interface ORMaskedIndexedWaveform : ORMaskedWaveform  {
    uint32_t   startIndex;
}

#pragma mark ¥¥¥Accessors 
- (void) setStartIndex:(uint32_t)anIndex;
- (uint32_t) startIndex;
@end

@interface ORMaskedIndexedWaveformWithSpecialBits : ORMaskedIndexedWaveform  {
    uint32_t   specialBitMask;
	int numBits;
	uint32_t firstBitMask;
	NSArray* bitNames;
    int32_t scaleOffset;
}

#pragma mark ¥¥¥Accessors 
- (void) setBitNames:(NSArray*)someNames;
- (NSArray*) bitNames;
- (void) setSpecialBitMask:(uint32_t)aMask;
- (uint32_t) specialBitMask;
- (void) setScaleOffset:(int32_t)aValue;
- (int32_t) scaleOffset;
- (int) numBits;
- (uint32_t) firstBitMask;
@end




