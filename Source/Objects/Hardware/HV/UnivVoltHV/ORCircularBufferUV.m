//
//  ORCircularBufferUV.m
//  Orca
//
//  Created by Jan Wouters on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORCircularBufferUV.h"
NSString* CBeTime		= @"Time";
NSString* CBeValue		= @"Value";


@implementation ORCircularBufferUV
- (id) init
{
    mTailIndex = 0;
	mHeadIndex = 0;
	mFWrapped = NO;
		
    return self;
}

- ( void ) dealloc
{
	[mStorageArray release];
	[super dealloc];
}

- ( void ) setSize: (int32_t) aSizeCB
{
	mSize = aSizeCB;
	mStorageArray = [NSMutableArray arrayWithCapacity: mSize];
	[mStorageArray retain];
//	NSLog( @"Size of array: %d\n", [mStorageArray count] );
}

//mah -- changed to count to remove compiler warning with other methods named 'size' in other objects that return diff type than int32_t.
- ( NSUInteger ) count
{
	return (uint32_t)[mStorageArray count];
}

- (void) insertHVEntry: (NSDate *) aDateOfAquistion hvValue: (NSNumber*) anHVEntry
{
	@try
	{
		NSLog( @"Date: %@, HV Value: %@\n", [aDateOfAquistion stdDescription], anHVEntry );
//	NSNumber* numObj = [NSNumber numberWithFloat: anHVEntry];
//	NSLog( @"Number: %@\n", numObj );
		NSArray* tmpTimePoint = [NSArray arrayWithObjects: aDateOfAquistion, anHVEntry, nil];
		NSArray* keyArray = [NSArray arrayWithObjects: CBeTime, CBeValue, nil];
//	NSLog( @"time: %@, value: %@\n", [tmpTimePoint objectAtIndex: 0], [tmpTimePoint objectAtIndex: 1] );
		NSDictionary* dictObj = [NSDictionary dictionaryWithObjects: tmpTimePoint forKeys: keyArray];
	
//		int i;
	 
		if ( mFWrapped ) 
		{
			[mStorageArray replaceObjectAtIndex: mTailIndex  withObject: dictObj];
		}
		else
		{
			[mStorageArray addObject: dictObj];
		}
//	NSLog( @"insert: %f at index: %d, size: %d\n", anHVEntry, mTailIndex, [mStorageArray count] );
//	NSLog( @"Entry after insertion ( %d ): %f\n", mTailIndex, [[mStorageArray objectAtIndex: mTailIndex] floatValue] );
		mTailIndex += 1;
		if ( mTailIndex >= mSize ) {
			mTailIndex = 0;
			mFWrapped = YES;
		}
	
		//int maxCount = (int)([mStorageArray count] > 5 ? 5: [mStorageArray count]);
/*
		for( i = 0; i < [mStorageArray count]; i++ )
		{
			NSDictionary* timeDataPoint = [mStorageArray objectAtIndex: i];
			NSLog( @"Entry ( %d ) - Time %@ value: %f\n", i, [timeDataPoint objectForKey: [mKeys objectAtIndex: 0]], 
					[[timeDataPoint objectForKey: [mKeys objectAtIndex: 1]] floatValue] );
		}
		NSLog( @"-----Count: %d\n\n\n", [mStorageArray count] );
*/
	}
	@catch (NSException* e )
	{
		NSLog( @"Encountered expection %@ in 'ORCircularBuffer:insertHVEntry'\n", [e reason] );
	}
}

- (NSDictionary *) HVEntry: (int32_t) anOffsetFromMostRecent
{
	int32_t index = mTailIndex - 1 + anOffsetFromMostRecent; // -1 present because mTailIndex points to next position where new entry will be placed.
	if ( index < 0 ) index += [mStorageArray count];
	if ( index >= [mStorageArray count] ) index -= [mStorageArray count];
	
	NSDictionary* dictObj = [mStorageArray objectAtIndex: index];
	return( dictObj );
}


- (NSDictionary *) HVEntry
{
	NSDictionary* dictObj = [mStorageArray objectAtIndex: mHeadIndex];
//	NSNumber* numObj = [dictObj objectForKey: [mKeys objectAtIndex: 1]];
//	NSDate* dateObj = [dictObj	objectForKey: [mKeys objectAtIndex: 0]];
//	float tmpFloat = [numObj floatValue];
//	NSLog( @"returned for date: %@, Value: %f, for index %d\n", dateObj, tmpFloat, mHeadIndex );
	
	// Set up index for next call to this routine.
	mHeadIndex += 1;
	if ( mHeadIndex >= mSize ) {
		mHeadIndex = 0;		
	}
	return( dictObj );
}
@end
