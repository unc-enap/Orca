//
//  OROpSequence
//  Orca
//
//  Created by Matt Gallagher on 2010/11/01.
//  Found on web and heavily modified by Mark Howe on Fri Nov 28, 2013.
//  Copyright (c) 2013  University of North Carolina. All rights reserved.
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

#import "OROpSequence.h"
#import "OROpSequenceQueue.h"
#import "OROpSeqStep.h"
NSArray *ScriptSteps(void);

NSString* OROpSeqStepsChanged               = @"OROpSeqStepsChanged";
NSString* ORSequenceQueueCountChanged       = @"ORSequenceQueueCountChanged";
NSString* OROpSequenceAllowedToRunChanged   = @"OROpSequenceAllowedToRunChanged";

@implementation OROpSequence

@synthesize idIndex;
@synthesize steps;
@synthesize state;
@synthesize scriptQueue;
@synthesize delegate;
@synthesize allowedToRun;
@synthesize stepStorage;

- (id) initWithDelegate:(id)aDelegate idIndex:(int)anIndex
{
 	self = [super init];
	if (self) {
        idIndex = anIndex;
        delegate = aDelegate;
		scriptQueue = [[OROpSequenceQueue alloc] init];
        state = kOpSeqQueueNeverRun;
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cancel:)
                                                     name:ScriptQueueCancelledNotification
                                                   object:scriptQueue];

        [scriptQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
        [scriptQueue addObserver:self forKeyPath:@"selectionIndex" options:0 context:NULL];
	}
	return self;
}

- (void) dealloc
{
    [self cancel:nil];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ScriptQueueCancelledNotification
                                                  object:scriptQueue];
    
    [scriptQueue removeObserver:self forKeyPath:@"selectionIndex"];
    [scriptQueue removeObserver:self forKeyPath:@"operationCount"];
    
	[scriptQueue cancelAllOperations];
	[scriptQueue release];
	scriptQueue = nil;
        
	[steps release];
	steps = nil;
 
    [stepStorage release];
	stepStorage = nil;
    
	[super dealloc];
}

- (id) step:(OROpSeqStep*)aStep objectForKey:(NSString*)aKey
{
    NSDictionary* variables = [stepStorage objectForKey:[aStep persistantAccessKey]];
    return [variables objectForKey:aKey];
}

- (void) step:(OROpSeqStep*)aStep setObject:(id)aValue forKey:(NSString*)aKey
{
    if(!stepStorage)self.stepStorage = [NSMutableDictionary dictionary];
    NSString* stepKey = [aStep persistantAccessKey];
    if(![stepStorage objectForKey:stepKey]){
        [stepStorage setObject:[NSMutableDictionary dictionary] forKey:stepKey];
    }
    NSMutableDictionary* variables = [stepStorage objectForKey:stepKey];
    [variables setObject:aValue forKey:aKey];
}

- (void) setSteps:(NSArray *)anArray
{
    [anArray retain];
    [steps release];
    steps = anArray;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OROpSeqStepsChanged object:self];
}

- (void) setAllowedToRun:(BOOL)aState
{
    allowedToRun = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:OROpSequenceAllowedToRunChanged object:self];
}

- (void) start
{	
    if([scriptQueue operationCount]>0){
        [self cancel:nil];
    }
    else {
        if([scriptQueue operationCount]==0){
            if([delegate respondsToSelector:@selector(scriptSteps:)]){
                self.steps = [delegate scriptSteps:idIndex];
                for (OROpSeqStep *step in steps){
                    [scriptQueue addOperation:step];
                }
                state = kOpSeqQueueRunning;
            }
        }
    }
}

- (void) cancel:(id)parameter
{
   	if ([[scriptQueue operations] count] > 0) {
		if ([parameter isKindOfClass:[NSNotification class]]) {
			state = kOpSeqQueueFailed;
		}
		else {
			state = kOpSeqQueueCancelled;
		}
        
		[[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:ScriptQueueCancelledNotification
                                                      object:scriptQueue];
		[scriptQueue cancelAllOperations];
		//while ([[scriptQueue operations] count] > 0) {
		//	[[NSRunLoop currentRunLoop]
        //     runMode:NSDefaultRunLoopMode
        //     beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		//}
		[scriptQueue clearState];
	}

	else {
		state = kOpSeqQueueFailed;
	} 
}

- (NSArray*) operations
{
    return [scriptQueue operations];
}
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"operationCount"]) {
        [[NSNotificationCenter defaultCenter]
            postNotificationName:ORSequenceQueueCountChanged
            object:self];
	}
	else [super observeValueForKeyPath:keyPath ofObject:object change:change
                          context:context];
}

@end
