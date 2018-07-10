//
//  ORStandardEnumerator.m
//  Mandy
//
//  Created by Andreas on Mon Aug 04 2003.
//  Copyright (c) 2003 Andreas Mayer. All rights reserved.
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


#import "ORStandardEnumerator.h"


@implementation ORStandardEnumerator


- (id)initWithCollection:(id)theCollection countSelector:(SEL)theCountSelector objectAtIndexSelector:(SEL)theObjectSelector
{
	if (self = [super init]) {
		collection = [theCollection retain];
		countSelector = theCountSelector;
		count = (CountMethod)[collection methodForSelector:countSelector];
		nextObjectSelector = theObjectSelector;
		nextObject = (NextObjectMethod)[collection methodForSelector:nextObjectSelector];
		position = 0;
	}
	return self;
}

- (void)dealloc
{
	[collection release];
	[super dealloc];
}

- (id)nextObject
{
	if (position >= count(collection, countSelector))
		return nil;

	return (nextObject(collection, nextObjectSelector, position++));
}

- (NSArray *)allObjects
{
	NSArray *result = [[[NSMutableArray alloc] init] autorelease];
	id object;
	while (object = [self nextObject]) [(NSMutableArray *)result addObject:object];
	return result;
}

@end
