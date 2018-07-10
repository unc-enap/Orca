
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


@class ORLinkedList;

@interface ORQueue : NSObject
{
    ORLinkedList *list;
}
-(BOOL) enqueue:(id)pushedObj;

//returns nil if the queue is empty.
//autoreleases your object
-(id) dequeue;
-(id) dequeueFromBottom;

//simple BOOL for whether the queue is empty or not.
//count == 0 usually, or for linked lists it's a nil test. 
-(BOOL) isEmpty;

//releases the queue and starts a new one.
-(void) removeAllObjects;
- (unsigned int)count;

/**
 * Returns an autoreleased queue with the contents of your 
 * array in the specified order.
 * YES means that objects will dequeue in the order indexed (0...n)
 * whereas NO means that objects will dequeue (n...0).
 * Your array will not be changed, released, etc.  The queue will retain,
 * not copy, your references.  If you retain this queue, your array will
 * be safe to release.
 */
+ (id) queueWithArray:(NSArray *)array
                        ofOrder:(BOOL)direction;
			
-(NSEnumerator *)objectEnumerator;
@end
