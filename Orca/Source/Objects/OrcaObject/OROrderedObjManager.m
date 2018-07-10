//
//  ORSlotManager.m
//  Orca
//
//  Created by Mark Howe on 11/19/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//
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
#import "OROrderedObjManager.h"

@implementation OROrderedObjManager

+ (id) for:(id)aContainerObj
{
	return [[[OROrderedObjManager alloc] initForContainer:aContainerObj] autorelease];
}

- (id) initForContainer:(id)aContainerObj
{
	self = [super init];
	containerObj = aContainerObj;
	return self;
}

- (void) drawSlotLabels
{
    if([(NSObject*)containerObj respondsToSelector:@selector(drawSlotLabels)]){
        [(NSObject*)containerObj drawSlotLabels];
    }
}

- (void) drawSlotBoundaries
{
    if([(NSObject*)containerObj respondsToSelector:@selector(drawSlotBoundaries)]){
        [(NSObject*)containerObj drawSlotBoundaries];
    }
}

- (NSPoint) suggestLocationFor:(id)anObj
{	
    int slot;
	NSRange legalRange = [containerObj legalSlotsForObj:anObj];
    for(slot=0;slot<=[containerObj maxNumberOfObjects];slot++){
		if([containerObj slot:slot excludedFor:anObj])continue;
		NSRange testRange = NSMakeRange(slot,[containerObj numberSlotsNeededFor:anObj]);
        if([self slotRangeEmpty:testRange] && NSUnionRange(testRange, legalRange).length <= legalRange.length){
            return [containerObj pointForSlot:slot];
        }
    }
    return NSMakePoint(-1,-1);
}

- (BOOL) dropPositionOK:(NSPoint)aPoint
{
	int slot =  [containerObj slotAtPoint:aPoint];
	return [self slotRangeEmpty:NSMakeRange(slot,1)];
}

- (void) moveObject:(id)obj to:(NSPoint)aPoint
{
	int aSlot = [containerObj slotAtPoint:aPoint];
	if(aSlot >=0 && aSlot < [containerObj maxNumberOfObjects]){
		[containerObj place:obj intoSlot:aSlot];
	}
}

- (id) objectInSlot:(int)aSlot
{
    NSEnumerator* e = [containerObj  objectEnumerator];
    id anObj;
    while(anObj = [e nextObject]){
		if(NSIntersectionRange(NSMakeRange([containerObj slotForObj:anObj],[containerObj numberSlotsNeededFor:anObj]),NSMakeRange(aSlot,1)).length) return anObj;
	}
	return nil;
}

- (BOOL) slotRangeEmpty:(NSRange)slotRange
{
	if(slotRange.location > [containerObj maxNumberOfObjects])return NO;
	if(slotRange.location+slotRange.length > [containerObj maxNumberOfObjects])return NO;
    NSEnumerator* e = [containerObj objectEnumerator];
    id anObj;
    while(anObj = [e nextObject]){
		if(NSIntersectionRange(slotRange,NSMakeRange([containerObj slotForObj:anObj],[containerObj numberSlotsNeededFor:anObj])).length != 0){
			return NO;
		}
    }
    return YES;
}

- (BOOL) canAddObject:(id)obj atPoint:(NSPoint)aPoint
{
	int aSlot = [containerObj slotAtPoint:aPoint];	
	if(aSlot > [containerObj maxNumberOfObjects]-1 || aSlot<0){
		NSBeep();
		NSLog(@"Rejected attempt to place card out of bounds\n");
		return NO;
	}
	else {
		if([containerObj slot:aSlot excludedFor:obj]){
			NSLog(@"%@ is illegal for that object\n",[containerObj nameForSlot:aSlot]);
			return NO;
		}
		NSRange testRange = NSMakeRange(aSlot,[obj numberSlotsUsed]);
		NSRange legalRange = [containerObj legalSlotsForObj:obj];
		if(NSIntersectionRange(legalRange,testRange).length!=[obj numberSlotsUsed]){
			NSLog(@"%@ is illegal for that object\n",[containerObj nameForSlot:aSlot]);
			return NO;
		}
		
		if([self objectInSlot:aSlot] != obj && [self objectInSlot:aSlot]!=nil) {
			NSLog(@"Rejected attempt to place multiple objects in %@\n",[containerObj nameForSlot:aSlot]);
			return NO;
		}
	}
	return YES;
}

- (void) moveSelectedObjects:(NSPoint)delta
{
	int direction = ((delta.x > 0) || (delta.y >0))  ? 1 : -1;
    
    if([(NSObject*)containerObj respondsToSelector:@selector(reverseDirection)]){
        if([(NSObject*)containerObj reverseDirection]) direction *= -1;
    }
    
	NSArray* sortedSelection = [[containerObj selectedObjects] sortedArrayUsingSelector:@selector(sortCompare:)];
	id anObj;
	NSEnumerator* e;
	if(direction<0) e = [sortedSelection objectEnumerator];
	else			e = [sortedSelection reverseObjectEnumerator];
	
	//First, can they -all- be moved?
	BOOL moveOK = YES;
	while(anObj = [e nextObject]){
		
		int objSlot	       = [containerObj slotForObj:anObj];
		int numSlotsNeeded = [containerObj numberSlotsNeededFor:anObj];
		int testSlot;
		if(direction == -1) testSlot = objSlot-1;
		else			    testSlot = objSlot+numSlotsNeeded;
		NSRange testRange  = NSMakeRange(objSlot+direction,numSlotsNeeded);
		NSRange legalRange = [containerObj legalSlotsForObj:anObj];
		
		if(NSIntersectionRange(legalRange,testRange).length!=numSlotsNeeded){
			moveOK = NO;
			break;
		}
		
		if([containerObj slot:testSlot excludedFor:anObj]){
			moveOK = NO;
			break;
		}
		if(!([self slotRangeEmpty:NSMakeRange(testSlot,1)] || [[self objectInSlot:testSlot] highlighted])){
			moveOK = NO;
			break;
		}
	}
	
	if(moveOK){		
		e = [sortedSelection objectEnumerator];
		while(anObj = [e nextObject]){
			[containerObj place:anObj intoSlot:[containerObj slotForObj:anObj]+direction];
		}		
	}
}

@end
