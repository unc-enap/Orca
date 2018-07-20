//
//  ORMemoryArea.m
//  Orca
//
//  Created by Mark Howe on 3/30/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
//

#import "ORMemoryArea.h"


@implementation ORMemoryArea
- (id) init
{
	self = [super init];
	lowValue = 0xffffffff;
	highValue = 0x0;
	return self;
}

- (void) dealloc
{
	[elements release];
	[super dealloc];
}

- (NSString*) name
{
	return name;
}

- (void) setName:(NSString*)aName
{
    [name autorelease];
    name = [aName copy];
}

- (unsigned) lowValue
{
	return lowValue;
}


- (unsigned) highValue
{
	return highValue;
}

- (void) addMemorySection:(NSString*)aName 
			  baseAddress:(uint32_t)anAddress 
		   startingOffset:(int)anOffset 
			  sizeInBytes:(uint32_t)aSize
{
	if(!elements)elements = [[NSMutableArray array] retain];
	[elements addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		aName,@"name",
		[NSNumber numberWithLong:anAddress],@"baseAddress",
		[NSNumber numberWithInt:anOffset],    @"offset",
		[NSNumber numberWithLong:aSize],      @"size",
		nil]
		];
	
	if((anAddress+anOffset)<lowValue)lowValue = anAddress+anOffset;
	if((anAddress+anOffset+aSize)>highValue)highValue = anAddress+anOffset+aSize;
}

- (unsigned) count
{
	return [elements count];
}

- (NSString*) name:(unsigned)index
{
	return [[elements objectAtIndex:index] objectForKey:@"name"];
}

- (uint32_t)  baseAddress:(int)index
{
	return [[[elements objectAtIndex:index] objectForKey:@"baseAddress"] longValue];
}

- (int)  offset:(int)index
{
	return [[[elements objectAtIndex:index] objectForKey:@"offset"] intValue];
}

- (uint32_t)  sizeInBytes:(int)index
{
	return [[[elements objectAtIndex:index] objectForKey:@"size"] longValue];
}

@end
