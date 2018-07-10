//
//  ORVmeAdapter.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 25 2009.
//  Copyright © 2009 University of North Carolina. All rights reserved.
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

#import "ORVmeTests.h"
#import "ORVmeIOCard.h"
#import "ORVmeCrate.h"

#define kReadWrite 0
#define kReadOnly  1
#define kWriteOnly 2

@implementation ORVmeReadWriteTest
+ (id) test:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize validMask:(unsigned long)aValidMask name:(NSString*)aName
{
	return [[[ORVmeReadWriteTest alloc] initWith:anOffset length:aLength wordSize:aWordSize validMask:aValidMask name:aName] autorelease];
}
+ (id) test:(unsigned long) anOffset wordSize:(short)aWordSize validMask:(unsigned long)aValidMask name:(NSString*)aName
{
	return [[[ORVmeReadWriteTest alloc] initWith:anOffset length:1 wordSize:aWordSize validMask:aValidMask name:aName] autorelease];
}

- (id) initWith:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize validMask:(unsigned long)aValidMask name:(NSString*)aName
{
	self = [super initWithName:aName];
	type = kReadWrite;
	theOffset	= anOffset;
	length		= aLength;
	validMask	= aValidMask;
	wordSize = aWordSize;
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) runTest:(id)anObj
{
#define kNumPatterns 4
	unsigned long patterns[kNumPatterns]={
		0x55555555,
		0xAAAAAAAA,
		0x00000000,
		0xFFFFFFFF,
	};
	int errorCount = 0;
	@try {
		int i;
		unsigned long  theAddress  = [anObj baseAddress] + theOffset;
		unsigned short theModifier = [anObj addressModifier];
		id theController = [anObj adapter];
		
		NSMutableData* readData  = [NSMutableData dataWithLength:length*wordSize];
		NSMutableData* writeData = [NSMutableData dataWithLength:length*wordSize];
		for(i=0;i<kNumPatterns;i++){
			//load up the write values -- we use the same write value for all write addresses
			int index;
			for(index=0;index<length;index++){
				if(wordSize == sizeof(long)){
					unsigned long* longPtr = (unsigned long*)[writeData bytes];
					longPtr[index] = patterns[i] & validMask;
				}
				else if(wordSize == sizeof(short)){
					unsigned short* shortPtr = (unsigned short*)[writeData bytes];
					shortPtr[index] = patterns[i] & validMask;
				}
				else {
					unsigned char* charPtr = (unsigned char*)[writeData bytes];
					charPtr[index] = patterns[i] & validMask;
				}
			}
			
			if([[ORAutoTester sharedAutoTester] stopTests])break;
			if(wordSize == sizeof(long)){
				unsigned long* longWritePtr = (unsigned long*)[writeData bytes];
				unsigned long* longReadPtr  = (unsigned long*)[readData bytes];
				if(type == kReadWrite || type == kWriteOnly) [theController writeLongBlock:longWritePtr atAddress:theAddress numToWrite:length withAddMod:theModifier usingAddSpace:0x01];
				if(type == kReadWrite || type == kReadOnly)  [theController readLongBlock:longReadPtr   atAddress:theAddress numToRead:length  withAddMod:theModifier usingAddSpace:0x01];
			}
			else if(wordSize == sizeof(short)){
				unsigned short* shortWritePtr = (unsigned short*)[writeData bytes];
				unsigned short* shortReadPtr  = (unsigned short*)[readData bytes];
				if(type == kReadWrite || type == kWriteOnly)[theController writeWordBlock:shortWritePtr atAddress:theAddress numToWrite:length withAddMod:theModifier usingAddSpace:0x01];
				if(type == kReadWrite || type == kReadOnly) [theController readWordBlock:shortReadPtr   atAddress:theAddress numToRead:length  withAddMod:theModifier usingAddSpace:0x01];
			}
			else if(wordSize == sizeof(char)){
				unsigned char* charWritePtr = (unsigned char*)[writeData bytes];
				unsigned char* charReadPtr  = (unsigned char*)[readData bytes];
				if(type == kReadWrite || type == kWriteOnly)[theController writeByteBlock:charWritePtr atAddress:theAddress numToWrite:length withAddMod:theModifier usingAddSpace:0x01];
				if(type == kReadWrite || type == kReadOnly) [theController readByteBlock:charReadPtr   atAddress:theAddress numToRead:length  withAddMod:theModifier usingAddSpace:0x01];
			}
		
			if(type == kReadWrite) {
				int i;
				for(i=0;i<length;i++){
					unsigned long theReadValue  = 0;
					unsigned long theWriteValue = 0;
					if(wordSize == sizeof(long)){
						unsigned long* longReadPtr = (unsigned long*)[readData bytes];
						unsigned long* longWritePtr = (unsigned long*)[writeData bytes];
						theReadValue = longReadPtr[i];
						theWriteValue = longWritePtr[i];
					}
					else if(wordSize == sizeof(short)){
						unsigned short* shortReadPtr  = (unsigned short*)[readData bytes];
						unsigned short* shortWritePtr = (unsigned short*)[writeData bytes];
						theReadValue = shortReadPtr[i];
						theWriteValue = shortWritePtr[i];
					}
					else {
						unsigned char* charReadPtr = (unsigned char*)[readData bytes];
						unsigned char* charWritePtr = (unsigned char*)[writeData bytes];
						theReadValue = charReadPtr[i];
						theWriteValue = charWritePtr[i];
					}
					if((theWriteValue&validMask) != (theReadValue&validMask)) {
						errorCount++;
						if(errorCount<4){
							[self addFailureLog:[NSString stringWithFormat:@"R/W Error: 0x%08lx: 0x%0lx != 0x%0lx (Mask = 0x%08lx)",[anObj baseAddress] + theOffset,theWriteValue&validMask,theReadValue&validMask,validMask]];
						}
					}
				}
			}
		}
		
		if(errorCount>4){
			[self addFailureLog:[NSString stringWithFormat:@"Errors Reports skipped. Total Errors: %d",errorCount]];
		}
		
	}
	@catch(NSException* e){
		errorCount++;
		[self addFailureLog:[NSString stringWithFormat:@"Exception: 0x%08lx\n",[anObj baseAddress] + theOffset]];
	}
}
@end

@implementation ORVmeReadOnlyTest
+ (id) test:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize name:(NSString*)aName
{
	return [[[ORVmeReadOnlyTest alloc] initWith:anOffset length:aLength wordSize:aWordSize name:aName] autorelease];
}

+ (id) test:(unsigned long) anOffset wordSize:(short)aWordSize name:(NSString*)aName
{
	return [[[ORVmeReadOnlyTest alloc] initWith:anOffset length:1 wordSize:aWordSize name:aName] autorelease];
}
- (id) initWith:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize name:(NSString*)aName
{
	self = [super initWith:anOffset length:aLength wordSize:aWordSize validMask:0xFFFFFFFF name:aName];
	type = kReadOnly;
	return self;
}

@end

@implementation ORVmeWriteOnlyTest
+ (id) test:(unsigned long) anOffset  wordSize:(short)aWordSize name:(NSString*)aName
{
	return [[[ORVmeWriteOnlyTest alloc] initWith:anOffset length:1 wordSize:aWordSize name:aName] autorelease];
}
- (id) initWith:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize  name:(NSString*)aName
{
	self = [super initWith:anOffset length:aLength wordSize:aWordSize validMask:0xFFFFFFFF name:aName];
	type = kWriteOnly;
	return self;
}
@end
