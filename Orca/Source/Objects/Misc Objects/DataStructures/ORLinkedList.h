
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


//a struct to hold the data.
typedef struct LLNode
{
    struct LLNode *next;
    struct LLNode *prev;
    id data;

} LLNode;

@interface ORLinkedList : NSObject 
{
    int theSize;
    LLNode *beginMarker;
    LLNode *endMarker;
}

+(id)listFromArray:(NSArray *)array 
                        ofOrder:(BOOL)direction;

-(id)init;

-(unsigned int) count;
-(BOOL) containsObject:(id)obj;
-(BOOL) containsObjectIdenticalTo:(id)obj;
-(void) removeAllObjects;

//f you try to insert nil or if your index is out of bounds these will return NO.
-(BOOL) insertObject:(id)obj atIndex:(unsigned int)index;
-(BOOL) addFirst:(id)obj;
-(BOOL) addLast:(id)obj;

-(BOOL) isEmpty;

-(id) first;
-(id) last;
-(id) objectAtIndex:(unsigned int)index;

//These BOOLS are all success / no success
-(BOOL)removeFirst;
-(BOOL)removeLast;
-(BOOL)removeObjectAtIndex:(unsigned int)index;

//See NSMutableArray for the difference between these two methods.
//basically removeObject uses isEqual, removeObjectIdenticalTo uses ==
-(BOOL)removeObject:(id)obj;
-(BOOL)removeObjectIdenticalTo:(id)obj;

-(NSEnumerator *)objectEnumerator;
-(NSEnumerator *)reverseObjectEnumerator;

@end
