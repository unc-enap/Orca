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

#import "ORLinkedList.h"

//nice for malloc
#define NODESIZE sizeof(struct LLNode)

//private class for the enumerator
@interface ORLinkedListEnumerator : NSEnumerator
{
    struct LLNode *header;
    struct LLNode *tail;
    struct LLNode *current;
    
    BOOL direction;//YES == forward
}
@end

@implementation ORLinkedListEnumerator

//forward means YES == same order as linked list, NO == reverse.
-(id)initWithHead:(struct LLNode *)beginMarker
        withTail:(struct LLNode *)endMarker
        forward:(BOOL)dir
{
    self=[super init];
    
    header = beginMarker;
    tail = endMarker;
    
    direction = dir;
    
    if (direction)  current = header;
    else	    current = tail;
    
    if (!header || !tail) {
        [NSException raise:@"LLEnumeratorFoobar" format:@"Your linked list is invalid for this enumerator."];
    }
    return self;
}
        
-(id)nextObject
{
    struct LLNode *old = current;
    
    if (direction) {
        if ( !(old->next) || old->next == tail) return nil;
        else    return (current = old->next)->data;//return and advance the list
    }
    else {
        if (!(old->prev) || old->prev == header) return nil;
        else return (current = old->prev)->data;
    }
}

-(NSArray *)allObjects
{
    struct LLNode *old = current;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    if (direction) {
        while ( (current = old->next) != tail){
            if (current) [array addObject: current->data];
	}
    }
    else {
        while ( (current = old->prev) != header) {
            if (current) [array addObject: current->data];
	}
    }
    
    return [array autorelease];
}

@end


//And now our class implementation.
@implementation ORLinkedList
/****** 
from the header:
instance vars of ORLinkedList:
{
    int theSize;

    LLNode *beginMarker;
    LLNode *endMarker;
}
***/

+ (id) listFromArray:(NSArray *)array 
                        ofOrder:(BOOL)dir
{
    
    ORLinkedList* list = [[ORLinkedList alloc] init];
    NSUInteger s = [array count];
    int i = 0;
    
    if (!array || s < 1){ /*do nothing*/}
    else if (dir) {//so the order will be 0...n
        while (i < s) [list addLast: [array objectAtIndex: i++]];
    }
    else {//order to dequeue will be n...0
        while (s > i) [list addFirst: [array objectAtIndex: --s]];
    }
    
    return [list autorelease];
}


-(id)init
{
    self=[super init];
    
    ///set up the markers pointing to each other    
    beginMarker = malloc(NODESIZE);
    endMarker = malloc(NODESIZE);
    
    beginMarker->next = endMarker;
    beginMarker->prev = nil;
    beginMarker->data = nil;
    
    endMarker->prev = beginMarker;
    endMarker->next = nil;
    endMarker->data = nil;
    
    return self;
}

-(unsigned int) count
{
    return theSize;
}

-(struct LLNode *) _findPos:(id)obj
                    identical:(BOOL)ident
{
    struct LLNode *p;
    
    if (!obj) return nil;
    
    //simply iterate through
    for (p = beginMarker->next; p != endMarker; p = p->next) {
        if (!ident) {
            if ( [obj isEqual:p->data] ) return p;
	}
        else if ( obj == p->data ) return p;           
    }
    
    //not found
    return nil;
}

-(struct LLNode *) _nodeAtIndex:(unsigned int)index
{
    int i;
    struct LLNode *p; //a runner, also our return val
    
    //need to handle special case -- they can "insert it" at the
    //index of the size of the list (in other words, at the end)
    //but not beyond.
    if (index > theSize) return nil;
    else if (index == 0) return beginMarker->next;
    
    if (index < theSize / 2) {
	p = beginMarker->next;
	for (i = 0; i < index; ++i) {
	    p = p->next;
	}
    }
    else {
        //note that we start at the tail itself, because we may just be displacing it
        //with a new object at the end.
	p = endMarker;
	for (i = theSize; i > index; --i){
	    p = p->prev;
	}
    }
    
    return p;
}

-(BOOL) containsObject:(id)obj
{
    //if that returns nil, we'll return NO automagically
    return ([self _findPos:obj identical:NO] != nil);
}

-(BOOL) containsObjectIdenticalTo:(id)obj
{
    return ([self _findPos:obj identical:YES] != nil);
}

-(BOOL) insertObject:(id)obj atIndex:(unsigned int)index
{
    struct LLNode *p, *newNode;

    if (obj == nil){ //won't insert nil
	return NO;
    }
    
    //our node to attach to is found
    //nodeAtIndex:int does range checking, etc., by returning nil on error
    p = [self _nodeAtIndex:index];
    if (p == nil) return NO;
    
    //is malloc okay in context of obj c??
    newNode = malloc(NODESIZE);
    if(!newNode)return NO;
    
    //now we do the linking -- a little harder to see when using a struct.
    newNode->data = [obj retain];
    //our prev pointer is set to point to the prev pointer of the node it displaces
    newNode->prev = p->prev;
    //our next pointer is set to point to the node it displaces
    newNode->next = p;
    //the "next" pointer of our prev pointer is set to point to us
    newNode->prev->next = newNode;
    //and finally the prev link of the node we're displacing is going to point to us
    p->prev = newNode;
    
    ++theSize;
    
    return YES;
}

-(BOOL) addFirst:(id)obj
{
    return [self insertObject:obj atIndex:0];
}

-(BOOL) addLast:(id)obj
{
    return [self insertObject:obj atIndex:theSize];
}

-(id) first
{
    struct LLNode *thenode = [self _nodeAtIndex:0];
    return thenode->data;
}

-(id) last
{
    struct LLNode *thenode = [self _nodeAtIndex:(theSize - 1)];
    return thenode->data;
}

-(BOOL) isEmpty
{
    return (beginMarker->next == endMarker) ? YES : NO;
}

-(id) objectAtIndex:(unsigned int)index
{
    struct LLNode *thenode = [self _nodeAtIndex:index];
    
    if (!thenode) return nil;
    
    return thenode->data;
}

-(BOOL) _removeNode:(struct LLNode *)node
{
    if (!node || node == beginMarker || node == endMarker) return NO;

    //break the links.
    node->next->prev = node->prev;
    node->prev->next = node->next;
    
    [node->data release];
    
    //remember we're using C...we malloced it in the first place!
    free(node);
    
    --theSize;
    
    return YES;
}

-(BOOL)removeFirst
{
    return [self _removeNode: (beginMarker->next)  ];
}

-(BOOL)removeLast
{
    return [self _removeNode: (endMarker->prev)  ];
}

-(BOOL)removeObjectAtIndex:(unsigned int)index
{
    return [ self _removeNode:[self _nodeAtIndex:index] ];
}

-(BOOL)removeObject:(id)obj
{
    struct LLNode *pos;
    pos = [self _findPos:obj identical:NO];
    
    //removeNode: will check for nils, etc.
    return [self _removeNode:pos];
}

-(BOOL)removeObjectIdenticalTo:(id)obj
{
    struct LLNode *pos;
    pos = [self _findPos:obj identical:YES];
    
    //removeNode: will check for nils, etc.
    return [self _removeNode:pos];
}

-(void)dealloc
{
    [self removeAllObjects];
    
    if (beginMarker != nil) {
        [beginMarker->data release];
        free(beginMarker);
    }
    if (endMarker != nil) {
        [endMarker->data release];
        free(endMarker);
    }
    
    [super dealloc];
}

-(void) removeAllObjects
{
    struct LLNode *runner, *old;
    
    runner = beginMarker->next;
	
    while ( runner != endMarker ) {
        old = runner;  runner = runner->next;
        [old->data release];
        free(old);
    }

    theSize = 0;
    
    beginMarker->next = endMarker;
    endMarker->prev = beginMarker;
    
}

-(NSEnumerator *)objectEnumerator
{
    return [
            [[ORLinkedListEnumerator alloc] 
                    initWithHead:beginMarker
                    withTail:endMarker
                    forward:YES
            ]
          autorelease];
}

-(NSEnumerator *)reverseObjectEnumerator
{
    return [
            [[ORLinkedListEnumerator alloc] 
                    initWithHead:beginMarker
                    withTail:endMarker
                    forward:NO
            ]
          autorelease];   
}


@end
