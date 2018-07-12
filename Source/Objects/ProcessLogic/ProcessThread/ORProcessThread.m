//
//  ORProcessThread.m
//  Orca
//
//  Created by Mark Howe on 11/23/05.
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


#import "ORProcessThread.h"
#import "ORProcessEndNode.h"
#import "ORProcessModel.h"
#import "SynthesizeSingleton.h"

@implementation ORProcessThread

#pragma mark ¥¥¥Inialization

SYNTHESIZE_SINGLETON_FOR_ORCLASS(ProcessThread);

+ (BOOL) isRunning
{
    return [[ORProcessThread sharedProcessThread] isRunning];
}

+ (void) registerInputObject:(id)anInputObject
{
    [[ORProcessThread sharedProcessThread] registerInputObject:anInputObject];
}

+ (void) registerOutputObject:(id)anOutputObject
{
    [[ORProcessThread sharedProcessThread] registerOutputObject:anOutputObject];
}

+ (void) setCR:(int)aBit value:(id)aValue
{
    [[ORProcessThread sharedProcessThread] setCR:aBit value:aValue];
}

+ (id) getCR:(int)aBit
{
    return [[ORProcessThread sharedProcessThread] getCR:aBit];
}


- (id) init
{
    self = [super init];
    [self registerNotificationObservers];
	int i;
	for(i=0;i<256;i++){
		crBits[i] = nil;;
	}
	
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	int i;
	for(i=0;i<256;i++){
		[crBits[i] release];
	}
    [endNodes release];
    [super dealloc];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];
    
    // Register for the acquisition mode of a channel being changed.
    [ notifyCenter addObserver: self
                      selector: @selector( documentIsClosing: )
                          name: ORDocumentClosedNotification
                        object: [(ORAppDelegate*)[NSApp delegate] document]];
    
    [ notifyCenter addObserver: self
                      selector: @selector( documentIsClosing: )
                          name: @"ORAppTerminating"
                        object: nil];
  
    [ notifyCenter addObserver: self
                      selector: @selector( orcaIsQuitting: )
                          name: OROrcaAboutToQuitNotice
                        object: nil];

    
    
}

- (void) orcaIsQuitting:(NSNotification*)aNote
{
    //a quit kills the thread, so we just flag it as done here
    running = NO;
}


- (void) documentIsClosing:(NSNotification*)aNote
{
    [self stop];
}


#pragma mark ¥¥¥Accessors
- (BOOL) isRunning
{
    return running;
}

- (void) setCR:(int)aBit value:(id)aValue
{
	if(aBit>=0 && aBit<256){	
		[aValue retain];
		[crBits[aBit] release];
		crBits[aBit] = aValue;
	}
}

- (id) getCR:(int)aBit
{
	if(aBit>=0 && aBit<256){
		return crBits[aBit];
	}
	else return nil;
}

- (void) startNodes:(NSArray*) someNodes
{
    if(![someNodes count])return;
    
    //process only the true end nodes... discard the others
    NSMutableArray* trueEndNodes = [NSMutableArray array];
    NSEnumerator* e = [someNodes objectEnumerator];
    id node;
    while(node = [e nextObject]){
        if([node isTrueEndNode]){
            [trueEndNodes addObject:node];
        }
    }
    
    if(![trueEndNodes count]) return;
    
    [endNodes makeObjectsPerformSelector:@selector(processIsStarting)];
	
	@try {
        @synchronized(self){
            if(!endNodes) endNodes = [[NSMutableSet alloc] init];
            [endNodes addObjectsFromArray:trueEndNodes];
            if(!running)[self start];
        }
	}
	@finally {
	}
}

- (void) stopNodes:(NSArray*) someNodes
{    
    
    
    //process only the true end nodes... discard the others
    NSMutableArray* trueEndNodes = [NSMutableArray array];
    NSEnumerator* e = [someNodes objectEnumerator];
    id node;
    while(node = [e nextObject]){
        if([node isTrueEndNode]){
            [trueEndNodes addObject:node];
        }
    }
    if(![trueEndNodes count]) return;
    
    NSSet* objectSet = [NSSet setWithArray:trueEndNodes];
    
    [trueEndNodes makeObjectsPerformSelector:@selector(processIsStopping)];
	
 	@try {
        @synchronized(self){
            [endNodes minusSet:objectSet];
            if(![endNodes count]){
                if(running)[self stop];
                [endNodes release];
                endNodes = nil;
            }
        }
	}
	@finally {
	}
}

- (void) startNode:(ORProcessEndNode*) aNode
{
 	@try {
		if(!aNode)return;
		if(![aNode isTrueEndNode])return;
        @synchronized(self){
            if(!endNodes) endNodes = [[NSMutableSet alloc] init];
            [aNode processIsStarting];
            [endNodes addObject:aNode];
            if(!running)[self start];
        }
	}
	@finally {
	}
}

- (void) stopNode:(ORProcessEndNode*) aNode
{
  	@try {
        @synchronized(self){
            [aNode processIsStopping];
            [endNodes removeObject:aNode];
            if([endNodes count] == 0){
                if(running)[self stop];
                [endNodes release];
                endNodes = nil;
            }
        }
	}
	@finally {
	}
}

- (BOOL) nodesRunning:(NSArray*)someNodes
{
    BOOL result = NO;
  	@try {
        @synchronized(self){
            result = [endNodes intersectsSet:[NSSet setWithArray:someNodes]];
        }
	}
	@finally {
	}
    return result;
}

- (void) registerInputObject:(id)anObject
{
   	@try {
        @synchronized(self){
            if(!inputs)inputs = [[ProcessElementSet alloc] retain];
            [inputs addObject:anObject];
        }
	}
	@finally {
	}
}

- (void) registerOutputObject:(id)anObject
{
   	@try {
        @synchronized(self){
            if(!outputs)outputs = [[ProcessElementSet alloc] retain];
            [outputs addObject:anObject];
        }
	}
	@finally {
	}
}

#pragma mark ¥¥¥Thread
- (void) start
{
    if(!running){
        canceled = NO;
		int i;
		for(i=0;i<8;i++)crBits[i] = 0L;
		
        allProcesses      = [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORProcessModel")] retain];
        allProcessElements = [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORProcessElementModel")] retain];
        allEndNodes        = [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsRespondingTo:@selector(isTrueEndNode)] retain];
        [allProcesses makeObjectsPerformSelector:@selector(processIsStarting)];
        [allEndNodes makeObjectsPerformSelector:@selector(processIsStarting)];
        [NSThread detachNewThreadSelector:@selector(processThread) toTarget:self withObject:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver : self
												 selector : @selector(stop)
													 name : ORDocumentClosedNotification
												   object : [(ORAppDelegate*)[NSApp delegate] document]];
    }
}

- (void) stop
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	float totalTime = 0;
    [self markAsCanceled];
    while([self isRunning]){
		//[self markAsCanceled];
		
		[NSThread sleepUntilDate:[[NSDate date] dateByAddingTimeInterval:.05]];
		totalTime += .05;
		if(totalTime > 20){
			NSLogColor([NSColor redColor], @"Process Failed to stop.....You should stop and restart ORCA!\n");
			break;
		}
	}
	
	[allEndNodes makeObjectsPerformSelector:@selector(processIsStopping)];
    
    [allEndNodes release];
    allEndNodes = nil;
	
    [allProcessElements release];
    allProcessElements = nil;
    
    
    [outputs release];
    outputs = nil;
    
    [inputs release];
    inputs = nil;
}

-(BOOL) cancelled
{
    return canceled;
}

- (void) markAsCanceled
{
    canceled = YES;
}

- (void) processThread
{
	running = YES;
    do {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            
        [allProcessElements makeObjectsPerformSelector:@selector(clearAlreadyEvaluatedFlag)];
        
        //tell all the input hw to store the current state
        @try {
            [allProcesses makeObjectsPerformSelector:@selector(startProcessCycle)];
            [inputs startProcessCycle];
        }
        @catch(NSException* localException) {
        }
        
        @try {
            [endNodes makeObjectsPerformSelector:@selector(eval)];
        }
        @catch(NSException* localException) {
        }
        
        @try {
            //tell all the output hw to write out the current state
            [outputs endProcessCycle];
            [inputs endProcessCycle];
            [allProcesses makeObjectsPerformSelector:@selector(endProcessCycle)];
        }
        @catch(NSException* localException) {
        }
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        
        [pool release];
    }while(![ self cancelled ]);
	running = NO;
}
@end

@implementation ProcessElementSet
- (void) dealloc
{
	[processElements release];
	[super dealloc];
}

- (void) startProcessCycle
{
	[processElements makeObjectsPerformSelector:@selector(startProcessCycle)];
}

- (void) endProcessCycle
{
	[processElements makeObjectsPerformSelector:@selector(endProcessCycle)];
}


- (void) addObject:(id)anObject
{
	if(!processElements) processElements = [[NSMutableArray alloc] init];
	NSEnumerator* e = [processElements objectEnumerator];
	id obj;
	BOOL foundOne = NO;
	while(obj = [e nextObject]){
		if([anObject hwObject] == [obj hwObject]){
			[obj addProcess:[anObject guardian]];
			foundOne = YES;
			break;
		}
	}
	if(!foundOne){
		ProcessElementInfo* info = [[ProcessElementInfo alloc] init];
		[info setHWObject:[anObject hwObject]];
		[info addProcess: [anObject guardian]];
		[processElements addObject:info];
		[info release];
	}
}

@end



@implementation ProcessElementInfo

- (void) dealloc
{
	[hwObject release];
	[processes release];
	[super dealloc];
}

- (void) setHWObject:(id)anObject
{
	[anObject retain];
	[hwObject release];
	hwObject = anObject;
}

- (id) hwObject
{
	return hwObject;
}

- (void) addProcess:(id)aProcess
{
	if(!processes)processes = [[NSMutableArray alloc] init];
    if(aProcess && ![processes containsObject:aProcess]){
		[processes addObject:aProcess];
	}
}

- (void) startProcessCycle
{
	int i;
	int n = (int)[processes count];
	for(i=0;i<n;i++){
		ORProcessModel* aProcess = [processes objectAtIndex:i];
		if([aProcess sampleGateOpen]){
			[hwObject startProcessCycle];
			break;
		}
	}
}

- (void) endProcessCycle
{
	int i;
	int n = (int)[processes count];
	for(i=0;i<n;i++){
		ORProcessModel* aProcess = [processes objectAtIndex:i];
		if([aProcess sampleGateOpen]){
			[hwObject endProcessCycle];
			break;
		}
	}
}

@end
