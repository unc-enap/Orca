//
//  ORVmeCarrierCard.m
//  Orca
//
//  Created by Mark Howe on 3/2/05.
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


#import "ORVmeCarrierCard.h"
#import "ORVmeDaughterCard.h"

@implementation ORVmeCarrierCard

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(sortCards:)
                         name : ORVmeCardSlotChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(sortCards:)
                         name : ORGroupObjectsAdded
                       object : self];
    
    [notifyCenter addObserver : self
                     selector : @selector(sortCards:)
                         name : ORGroupObjectsRemoved
                       object : self];
    
}

- (id) cardInSlot:(int)aSlot
{
    NSEnumerator* e = [[self orcaObjects] objectEnumerator];
    ORCard* anObj;
    while(anObj = [e nextObject]){
		if(NSIntersectionRange(NSMakeRange([anObj slot],[anObj numberSlotsUsed]),NSMakeRange(aSlot,1)).length) return anObj;
	}
	return nil;
}

- (void) sortCards:(NSNotification*)aNotification
{
    [[self orcaObjects] sortUsingSelector:@selector(slotCompare:)];
}

- (void) setSlot:(int) aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    //must move all of the connectors that this object is indirectly responsible for as a guardian.
    NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
    ORVmeDaughterCard* anObject;
    while(anObject = [e nextObject]){
        [anObject guardian:self positionConnectorsForCard:anObject];
    }
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:self forKey: ORMovedObject];
    
    [[NSNotificationCenter defaultCenter]
         postNotificationName:ORVmeCardSlotChangedNotification
                       object:self
                     userInfo: userInfo];
    
}

-(void)moveTo:(NSPoint)aPoint
{
    [super moveTo:aPoint];
    NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
    ORVmeDaughterCard* anObject;
    while(anObject = [e nextObject]){
        [anObject guardian:self positionConnectorsForCard:anObject];
    }
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORVmeCardSlotChangedNotification
                          object: self];
    
}

/*- (void) positionConnector:(ORConnector*)aConnector forSlot:(int)ip
{
    //subclass responsiblity
}
*/
- (void) connector:(ORConnector*)aConnector tweakPositionByX:(float)x byY:(float)y
{
    NSRect aFrame = [aConnector localFrame];
    aFrame.origin.x += x;
    aFrame.origin.y += y;
    [aConnector setLocalFrame:aFrame];
    
}


- (NSString*) uniqueConnectorName
{
    return [guardian uniqueConnectorName];
}


- (void) assumeDisplayOf:(ORConnector*)aConnector
{
    [guardian assumeDisplayOf:aConnector];
}

- (void) removeDisplayOf:(ORConnector*)aConnector
{
    [guardian removeDisplayOf:aConnector];
}


- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    
    NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
    ORVmeDaughterCard* anObject;
    while(anObject = [e nextObject]){
        if(aGuardian == nil){
            [anObject guardianRemovingDisplayOfConnectors:oldGuardian ];
        }
        [anObject guardianAssumingDisplayOfConnectors:aGuardian];
        if(aGuardian != nil){
            [anObject guardian:self positionConnectorsForCard:anObject];
        }
    }
}

- (void) setBaseAddress:(unsigned long)anAddress
{
	[super setBaseAddress:anAddress];
	[[self orcaObjects] makeObjectsPerformSelector:@selector(calcBaseAddress)];
}

- (void) addObjectInfoToArray:(NSMutableArray*)anArray
{
	NSMutableDictionary* stateDictionary = [NSMutableDictionary dictionary];
	[self addParametersToDictionary:stateDictionary];

	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	NSEnumerator* e = [stateDictionary keyEnumerator];
	id aKey;
	while(aKey = [e nextObject]){
		NSDictionary* d = [stateDictionary objectForKey:aKey];
		[dictionary addEntriesFromDictionary:d];
	}							

	NSArray* daughterCards = [self collectObjectsOfClass:NSClassFromString(@"ORVmeDaughterCard")];
	if([daughterCards count]){
		NSMutableArray* cardArray = [NSMutableArray array];
		[daughterCards makeObjectsPerformSelector:@selector(addObjectInfoToArray:) withObject:cardArray];
		[dictionary setObject:cardArray forKey:@"DaughterCards"];
	}

	[anArray addObject:dictionary];
	
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [self registerNotificationObservers];
    
    return self;
}


- (void) connected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(connected)];
}

- (void) disconnected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(disconnected)];
}

#pragma mark •••CardHolding Protocol
- (int) maxNumberOfObjects	{ return 4; }	//default
- (int) objWidth			{ return 58; }	//default
- (int) groupSeparation		{ return 50; }	//default
- (NSString*) nameForSlot:(int)aSlot	{ return [NSString stringWithFormat:@"position %d",aSlot]; }
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj { return NO;}
- (int) slotForObj:(id)anObj
{
	return [anObj slot];
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	return NSMakeRange(0,[self maxNumberOfObjects]);
}

- (int)slotAtPoint:(NSPoint)aPoint 
{
	//what really screws us up is the space in the middle
	float x = aPoint.x;
	int objWidth = [self objWidth];
	float w = objWidth * [self maxNumberOfObjects] + [self groupSeparation];
	
	if(x>=0 && x<objWidth)						return 0;
	else if(x>objWidth && x<objWidth*2)		return 1;
	else if(x>=w-objWidth*2 && x<w-objWidth)	return 2;
	else if(x>=w-objWidth && x<w)				return 3;
	else										return -1;
}

- (NSPoint) pointForSlot:(int)aSlot 
{
	int objWidth = [self objWidth];
	float w = objWidth * [self maxNumberOfObjects] + [self groupSeparation];
	if(aSlot == 0)		return NSMakePoint(0,0);
	else if(aSlot == 1)	return NSMakePoint(objWidth+1,0);
	else if(aSlot == 2) return NSMakePoint(w-2*objWidth+1,0);
	else return NSMakePoint(w-objWidth+1,0);
}

- (void) place:(id)aCard intoSlot:(int)aSlot
{
	[aCard setSlot: aSlot];
	[aCard moveTo:[self pointForSlot:aSlot]];
}
- (int) numberSlotsNeededFor:(id)anObj
{
	return [anObj numberSlotsUsed];
}

@end
