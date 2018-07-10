//
//  ORMemoryMap.m
//  Orca
//
//  Created by Mark Howe on 3/30/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
//

#import "ORMemoryMap.h"
#import "ORMemoryArea.h"

@implementation ORMemoryMap

- (id) init
{
	self = [super init];
	lowValue  = 0xffffffff;
	highValue = 0x0;
	return self;
}

- (void) dealloc
{
	[memoryAreas release];
	[super dealloc];
}

- (unsigned) lowValue
{
	return lowValue;
}

- (unsigned) highValue
{
	return highValue;
}

- (unsigned) count
{
	return [memoryAreas count];
}

- (ORMemoryArea*) memoryArea:(int)index
{
	return [memoryAreas objectAtIndex:index];
}

- (void) addMemoryArea:(ORMemoryArea*)anArea
{
	if(!memoryAreas)memoryAreas = [[NSMutableArray array] retain];

	[memoryAreas addObject:anArea];
	
	if([anArea lowValue] < lowValue)  lowValue  =  [anArea lowValue];
	if([anArea highValue] > highValue)highValue =  [anArea highValue];
}

@end
