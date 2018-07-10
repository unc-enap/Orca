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

#import "ORQueue.h"
#import "ORLinkedList.h"

@implementation ORQueue

-(id)init
{
    self = [super init];
    list = [[ORLinkedList alloc] init];
    return self;
}

-(void)dealloc
{
    [list release];
    [super dealloc];
}
- (unsigned int)count
{
    return [list count];
}

//if you try to enqueue nil, it will return false
-(BOOL) enqueue:(id)pushedObj
{
    if (!pushedObj)return NO;
    [list addLast:pushedObj];
    return YES;
}

//returns nil if the queue is empty.
-(id) dequeue
{
    id retval = [[list first] retain];
    [list removeFirst];
    return [retval autorelease];
}

-(id) dequeueFromBottom
{
    id retval = [[list last] retain];
    [list removeLast];
    return [retval autorelease];
}

//simple BOOL for whether the queue is empty or not.
-(BOOL) isEmpty
{
    return ([list first] == nil);
}

-(void) removeAllObjects
{
    [list removeAllObjects];
}

-(NSEnumerator *)objectEnumerator
{
    return [list objectEnumerator];
}

+ (id) queueWithArray:(NSArray *)array
                  ofOrder:(BOOL)direction
{
    ORQueue* q = [[ORQueue alloc] init];
    int s = [array count];
    int i = 0;
    
    if (!array || !s){ /*do nothing*/}
    else if (direction) {//so the order to dequeue will be from 0...n
        while (i < s) [q enqueue: [array objectAtIndex: i++]];
    }
    else { //order to dequeue will be n...0
        while (s > i) [q enqueue: [array objectAtIndex: --s]];
    }

    return [q autorelease];
}

@end
