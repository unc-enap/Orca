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

#import "ORSafeQueue.h"
#import "ORLinkedList.h"

@implementation ORSafeQueue

-(id)init
{
    self=[super init];
    queueLock = [[NSRecursiveLock alloc] init];
    return self;
}

-(void)dealloc
{
    [queueLock release];
    [super dealloc];
}

-(BOOL) enqueue:(id)pushedObj
{
    [queueLock lock];
    BOOL result = [super enqueue:pushedObj];
    [queueLock unlock];
	return result;
}

-(void) enqueueArray:(NSArray*)arrayOfObjects
{
    [queueLock lock];
    int i;
    int n = [arrayOfObjects count];
    for(i=0;i<n;i++)[super enqueue:[arrayOfObjects objectAtIndex:i]];
    [queueLock unlock];
}

- (unsigned int) count
{
	//we try to get the count. but if we can not get the lock, just return 0
	//we want the data taking thread to block as little as possible even our expense.
	unsigned int theCount = 0;
    if([queueLock tryLock]){
		theCount = [super count];
        [queueLock unlock];
    }
	return theCount;
}

-(BOOL) tryEnqueue:(id)pushedObj
{
    if([queueLock tryLock]){
        [super enqueue:pushedObj];
        [queueLock unlock];
        return YES;
    }
    else return NO;
}

-(BOOL) tryEnqueueArray:(NSArray*)arrayOfObjects
{
    if([queueLock tryLock]){
        int i;
        int n = [arrayOfObjects count];
        for(i=0;i<n;i++)[super enqueue:[arrayOfObjects objectAtIndex:i]];
        [queueLock unlock];
        return YES;
    }
    else return NO;
}

-(id) dequeue
{
    [queueLock lock];
    id retval = [[[super dequeue]retain] autorelease];
    [queueLock unlock];
    return retval;
}

- (NSArray*) dequeueArray
{
    NSMutableArray* theDataArray = nil;
	[queueLock lock];
    if([super count]){
        theDataArray = [NSMutableArray array];
        while([super count]){
            [theDataArray addObject:[super dequeue]];
        }
    }
	[queueLock unlock];
    return theDataArray;
}


//simple BOOL for whether the queue is empty or not.
-(BOOL) isEmpty
{
    [queueLock lock];
    BOOL result =  [super isEmpty];
    [queueLock unlock];
    return result;
}

-(void) removeAllObjects
{
    [queueLock lock];
    [super removeAllObjects];
    [queueLock unlock];
}


@end
