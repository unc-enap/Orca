//
//  ORAutoTestUnit.m
//  Orca
//
//  Created by Mark Howe on 8/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ORAutoTestUnit.h"

@implementation ORAutoTestUnit
- (id) initWithName:(NSString*)aName
{
	self = [super init];
	name = [aName copy];
	return self;
}

- (void) dealloc
{
	[failureLog release];
	[name release];
	[super dealloc];
}

- (NSArray*) failureLog
{
	return failureLog;
}

- (NSString*)name
{
	return name;
}

- (void) runTest:(id)anObj
{
	
}

- (void) addFailureLog:(NSString*)aEntry
{
	if(!failureLog)failureLog = [[NSMutableArray array] retain];
	[failureLog addObject:aEntry];
}
@end
