//
//  ORTest.m
//  Orca
//
//  Created by snodaq on 9/22/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORTest.h"

@implementation ORTest
+ testSelector:(SEL)aSelector tag:(int)aTag
{
	ORTest* test = [[ORTest alloc] initTestSelector:aSelector tag:aTag];
	return [test autorelease];
}

- (id) initTestSelector:(SEL)aSelector tag:(int)aTag
{
	self = [super init];
	tag = aTag;
	testSelector = aSelector;
	return self;
}

- (void) runForObject:(id)anObject
{
	if([anObject testsRunning]){
		[anObject runningTest:tag status:@"Running"];
		[anObject performSelector:testSelector withObject:nil afterDelay:0];
	}
}
	
@end

@implementation ORTestSuit
- (void) dealloc
{
	[tests release];
	[super dealloc];
}

- (void) addTest:(ORTest*)aTest
{
	if(!tests)tests = [[NSMutableArray array] retain];
	[tests addObject:aTest];
}

- (void) runForObject:(id)anObject
{
	if([tests count]){
		[[tests objectAtIndex:0] runForObject:anObject];
		[tests removeObjectAtIndex:0];
	}
	else {
		[tests release];
		tests = nil;
		[anObject setTestsRunning:NO];
	}
}

- (void) stopForObject:(id)anObject
{
	[anObject setTestsRunning:NO];
	[tests removeAllObjects];
	[tests release];
	tests = nil;
}

@end

@implementation NSObject (ORTest)
- (BOOL) testsRunning
{
	return NO;
}
- (void) runningTest:(int)testTag status:(NSString*)theStatus
{
}
- (void) setTestsRunning:(BOOL)aState
{
}

@end