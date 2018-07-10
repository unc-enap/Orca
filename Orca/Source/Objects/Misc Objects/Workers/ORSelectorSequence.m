//
//  ORSelectorSequence.m
//  Orca
//
//  Created by Mark Howe on 10/3/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
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

#import "ORSelectorSequence.h"

NSString* ORSequenceRunning  = @"ORSequenceRunning";
NSString* ORSequenceProgress = @"ORSequenceProgress";
NSString* ORSequenceStopped  = @"ORSequenceStopped";

@interface ORSelectorSequence (private)
- (void) doOneItem;
@end

@implementation ORSelectorSequence
+ (id) selectorSequenceWithDelegate:(id)aDelegate
{
	return [[[ORSelectorSequence alloc] initWithDelegate:aDelegate] autorelease];
}

- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
	return self;
}

- (void) dealloc
{
	[selectors release];
	[nextSelector release];
	[super dealloc];
}

//--------------------------------------------------------------
//Here's the meat of this object. Call it like:
// [[seq forTarget:aTarget] setX:x y:y];
//
// Since this object doesn't implement it the selector will fall 
// thru to the forwardInvocation method, 
// turned into an NSInvocation, and added to the list to sequence
// thru when the sequence is started.
//----------------------------------------------------------------
- (id) forTarget:(id)aTarget
{
	if(nextSelector)[nextSelector release];
	nextSelector = [[NSMutableDictionary dictionary] retain];
	[nextSelector setObject:aTarget forKey:@"target"];
	return self;
}

- (void) setTag:(int)aTag
{
	tag = aTag;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	id target = [nextSelector objectForKey:@"target"];
	
	if(target && ![self respondsToSelector:aSelector]){
		return [target methodSignatureForSelector:aSelector];
	}
	else {
		return [super methodSignatureForSelector:aSelector];
	}	
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
	if(nextSelector){
		[nextSelector setObject:invocation forKey:@"invocation"];
		if(!selectors)selectors = [[NSMutableArray array] retain];
		[selectors addObject: nextSelector];
		[nextSelector release];
		nextSelector = nil;
	}
}

- (void) startSequence
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSequenceRunning 
														object:delegate
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tag],@"tag",nil]];
	startCount = [selectors count];
	[self retain];
	[self performSelector:@selector(doOneItem) withObject:nil afterDelay:0];
}

- (void) stopSequence
{
	if([delegate respondsToSelector:@selector(sequenceCompleted:)]) [delegate sequenceCompleted:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSequenceStopped 
														object:delegate
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tag],@"tag",nil]];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[selectors release];
	selectors = nil;
	[self autorelease];
}

@end

@implementation ORSelectorSequence (private)
- (void) doOneItem
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	@try {
		if([selectors count]){
			NSMutableDictionary* theTask = [selectors objectAtIndex:0];
			
			id target					 = [theTask objectForKey:@"target"];
			NSInvocation* theInvocation  = [theTask objectForKey:@"invocation"];
			
			[theInvocation invokeWithTarget:target];
			[selectors removeObject:theTask];
			float progress = 100. - 100.*[selectors count]/(float)startCount;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORSequenceProgress 
																object:delegate
															  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:progress],@"progress",[NSNumber numberWithInt:tag],@"tag",nil]];
			
			[self performSelector:@selector(doOneItem) withObject:nil afterDelay:0];
			
		}
		else {
			[self stopSequence];
		}
		
	}
	@catch(NSException* localException) {
		NSLog(@"Task sequence aborted because of exception: %@\n",localException);
		[self stopSequence];
	}
}
@end
