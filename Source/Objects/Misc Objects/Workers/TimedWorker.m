//
//  TimedWorker.m
//  Orca
//
//  Created by Mark Howe on 1/13/05.
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


#import "TimedWorker.h"

@interface TimedWorker (private)
- (void) execute;
- (NSUndoManager*) undoManager;
@end


NSString* TimedWorkerTimeIntervalChangedNotification    = @"TimedWorkerTimeIntervalChangedNotification";
NSString* TimedWorkerIsRunningChangedNotification       = @"TimedWorkerIsRunningChangedNotification";


@implementation TimedWorker
+ (id) TimeWorkerWithInterval:(NSTimeInterval)anInterval
{
    return [[[TimedWorker alloc] initWithInterval:anInterval] autorelease];
}

- (id) initWithInterval:(NSTimeInterval)anInterval
{
    self = [super init];
    [self setTimeInterval:anInterval];
    [self setIsRunning:NO];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) runWithTarget:(id)aTarget selector:(SEL)aSelector
{
    if(timeInterval){
        target = aTarget;
        _selector = aSelector;
        [self setIsRunning:YES];
		[self performSelector:@selector(execute) withObject:self afterDelay:timeInterval];
    }
}

- (void) stop
{
    [self setIsRunning:NO];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (float) timeInterval
{
    return timeInterval;
}

- (void) setTimeInterval: (NSTimeInterval) aTimeInterval
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeInterval:timeInterval];
	
    timeInterval = aTimeInterval;
    if(timeInterval < .001) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self setIsRunning:NO];
    }
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:TimedWorkerTimeIntervalChangedNotification
	 object:self
	 userInfo: [NSDictionary dictionaryWithObject: self
										   forKey:@"OrcaObject Notification Sender"]];
}


- (BOOL) isRunning
{
    return isRunning;
}

- (void) setIsRunning: (BOOL) flag
{
    isRunning = flag;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:TimedWorkerIsRunningChangedNotification
	 object:self
	 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
				self,@"OrcaObject Notification Sender",
				[NSNumber numberWithBool:isRunning],@"State",
				nil]];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
    [self setTimeInterval:[decoder decodeFloatForKey:    @"TimeWorkerTimeInterval"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeFloat:timeInterval   forKey:@"TimeWorkerTimeInterval"];
}
@end

@implementation TimedWorker (private)
- (void) execute 
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(!isRunning)return;
    if(timeInterval < .001) {
        [self setIsRunning:NO];
        return;
    }
    @try {
        [target performSelector:_selector];
    }
	@catch(NSException* localException) {
    }
    
    [self performSelector:@selector(execute) withObject:self afterDelay:timeInterval];
}

- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

@end
