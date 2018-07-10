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
    unsigned long   mask;
}

#pragma mark ¥¥¥Accessors 
- (void) setMask:(unsigned long)aMask;
- (unsigned long) mask;
-(long) unMaskedValue:(unsigned short)aChan;
@end

@interface ORMaskedIndexedWaveform : ORMaskedWaveform  {
    unsigned long   startIndex;
}

#pragma mark ¥¥¥Accessors 
- (void) setStartIndex:(unsigned long)anIndex;
- (unsigned long) startIndex;
@end

@interface ORMaskedIndexedWaveformWithSpecialBits : ORMaskedIndexedWaveform  {
    unsigned long   specialBitMask;
	int numBits;
	unsigned long firstBitMask;
	NSArray* bitNames;
    long scaleOffset;
}

#pragma mark ¥¥¥Accessors 
- (void) setBitNames:(NSArray*)someNames;
- (NSArray*) bitNames;
- (void) setSpecialBitMask:(unsigned long)aMask;
- (unsigned long) specialBitMask;
- (void) setScaleOffset:(long)aValue;
- (long) scaleOffset;
- (int) numBits;
- (unsigned long) firstBitMask;
@end




