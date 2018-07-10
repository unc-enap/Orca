//
//  ORGroup.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 03 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Notification Strings
NSString* ORGroupObjectsAdded		= @"ORGroupObjectsAdded";
NSString* ORGroupObjectsRemoved		= @"ORGroupObjectsRemoved";
NSString* ORGroupSelectionChanged	= @"ORGroupSelectionChanged";
NSString* ORGroupObjectList			= @"ORGroupObjectList";


#pragma mark ¥¥¥PasteBoard Types
NSString* ORGroupPasteBoardItem = @"ORGroupPasteBoardItem";
NSString* ORGroupDragBoardItem  = @"ORGroupDragBoardItem";

@implementation ORGroup

#pragma mark ¥¥¥Initialization

- (id) init //designated initializer
{
    if(self = [super init]){
        [[self undoManager] disableUndoRegistration]; //disable the undoManager for initialization..
        [self setOrcaObjects:[[[NSMutableArray alloc]init] autorelease]];
        [[self undoManager] enableUndoRegistration];
    }
    return self;
}

- (void) dealloc
{
    [orcaObjects makeObjectsPerformSelector:@selector(disconnect)];	
    [orcaObjects release];
    orcaObjects = nil;
    [super dealloc];
}
- (void) sleep 	
{
    [super sleep];
    [orcaObjects makeObjectsPerformSelector:@selector(sleep)];
}

#pragma mark ¥¥¥Assessors
- (void)setOrcaObjects:(NSMutableArray*)someObjects
{
    [someObjects retain];
    [orcaObjects release];
    orcaObjects = someObjects;
}

- (NSMutableArray*)orcaObjects
{
    return orcaObjects;
}

- (NSUInteger) count
{
    return [orcaObjects count];
}
- (id) objectAtIndex:(NSUInteger) index
{
    if(index<[orcaObjects count]){
        return [orcaObjects objectAtIndex:index];
    }
    return nil;
}

- (NSMutableArray*) children
{
    //methods exists to give common interface across all objects for display in lists
    return orcaObjects;
}

- (NSMutableArray*) familyList
{
    //return array containing self and all children recursively
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
    [collection addObject:self];
    NSEnumerator* e  = [orcaObjects objectEnumerator];
    OrcaObject* anObject;
    while(anObject = [e nextObject]){
        [collection addObjectsFromArray:[anObject familyList]];
    }
    return collection;
}

- (BOOL) useAltView
{
    return NO;
}
#pragma mark ¥¥¥Archival
static NSString *ORGroupObjects 			= @"ORGroupObjects";

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setOrcaObjects:[[[NSMutableArray alloc]init] autorelease]];
	NSMutableArray* someObjects;
	@try {
		someObjects = [decoder decodeObjectForKey:ORGroupObjects];
		if(someObjects)[self addObjects:someObjects];
    }
	@catch (NSException* e) {
		NSLogColor([NSColor redColor],@"%@\n",e);
		[e raise];
	}
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject: orcaObjects forKey:ORGroupObjects];
}


#pragma mark ¥¥¥Undoable Actions
- (void) addObject:(id)anObject
{
	[self addObjects:[NSArray arrayWithObject:anObject]]; 
}

- (void) removeObject:(id)anObject
{
	[self removeObjects:[NSArray arrayWithObject:anObject]]; 
}

- (void) addObjects:(NSArray*)someObjects
{
	//all objects in paste must accept this guardian
	
    NSEnumerator* e  = [someObjects objectEnumerator];
    OrcaObject* anObject;
    while(anObject = [e nextObject]){
		if(![anObject acceptsGuardian:self]){
			return;
		}
    }

    [[[self undoManager] prepareWithInvocationTarget:self] removeObjects:someObjects];
    [someObjects makeObjectsPerformSelector:@selector(setGuardian:) withObject:self];
    [orcaObjects addObjectsFromArray:someObjects];
    [someObjects makeObjectsPerformSelector:@selector(askForUniqueIDNumber) withObject:nil];
	@try {
		//some objects will try to make a hw access on a wakeUp. If that raises an exception it
		//causes a failure of the config load, which is very bad....
		[someObjects makeObjectsPerformSelector:@selector(wakeUp)];
	}
	@catch (NSException* e) {
	}
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:someObjects forKey: ORGroupObjectList];
    
	[self objectCountChanged];

 
	[[NSNotificationCenter defaultCenter]
                        postNotificationName:ORGroupObjectsAdded
                                      object:self
                                    userInfo: userInfo];
    
}

- (void) removeObjects:(NSArray*)someObjects
{
    [[[self undoManager] prepareWithInvocationTarget:self] addObjects:someObjects];
    [someObjects makeObjectsPerformSelector:@selector(setGuardian:) withObject:nil];
    [someObjects makeObjectsPerformSelector:@selector(sleep)];
    [someObjects makeObjectsPerformSelector:@selector(disconnect)];
    [orcaObjects removeObjectsInArray:someObjects];
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:someObjects forKey: ORGroupObjectList];
    
 	[self objectCountChanged];
	
	[[NSNotificationCenter defaultCenter]
                        postNotificationName:ORGroupObjectsRemoved
                                      object:self
                                    userInfo: userInfo];
}

- (void) objectCountChanged
{
	//we don't do anything with this info, but subclasses can override
}

#pragma mark ¥¥¥Group Methods
- (void)wakeUp
{
    [super wakeUp];
	@try {
		//some objects will try to make a hw access on a wakeUp. If that raises an exception it
		//causes a failure of the config load, which is very bad....
		[orcaObjects makeObjectsPerformSelector:@selector(wakeUp)];
	}
	@catch (NSException* e) {
	}
}

- (void) awakeAfterDocumentLoaded
{
    [orcaObjects makeObjectsPerformSelector:@selector(awakeAfterDocumentLoaded)];
}

- (void) unHighlightAll
{
    [orcaObjects makeObjectsPerformSelector:@selector(setHighlightedNO)];
}

- (void) highlightAll
{
    [orcaObjects makeObjectsPerformSelector:@selector(setHighlightedYES)];
}

- (BOOL) changesAllowed
{
    return [[(ORAppDelegate*)[NSApp delegate]document] documentCanBeChanged];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* dictionaryToUse = dictionary;
    if([[self identifier] length]){
        dictionaryToUse = [NSMutableDictionary dictionary];
        [dictionary setObject:dictionaryToUse forKey:[self identifier]];
        [dictionaryToUse setObject:[NSNumber numberWithShort:[self count]] forKey:@"count"]; 
        [dictionaryToUse setObject:NSStringFromClass([self class]) forKey:@"Class Name"]; 
    }
    [orcaObjects makeObjectsPerformSelector:@selector(addParametersToDictionary:) withObject:dictionaryToUse];
    return dictionaryToUse;
}

- (void) resetAlreadyVisitedInChainSearch
{
	[orcaObjects makeObjectsPerformSelector:@selector(resetAlreadyVisitedInChainSearch)];
}

- (NSArray*) collectObjectsOfClass:(Class)aClass
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
    
    [collection addObjectsFromArray:[super collectObjectsOfClass:aClass]];
    
    NSEnumerator* e  = [orcaObjects objectEnumerator];
    OrcaObject* anObject;
    while(anObject = [e nextObject]){
        [collection addObjectsFromArray:[anObject collectObjectsOfClass:aClass]];
    }
    return collection;
}

- (NSArray*) collectObjectsConformingTo:(Protocol*)aProtocol
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
    [collection addObjectsFromArray:[super collectObjectsConformingTo:aProtocol]];
    
    NSEnumerator* e  = [orcaObjects objectEnumerator];
    OrcaObject* anObject;
    while(anObject = [e nextObject]){
        [collection addObjectsFromArray:[anObject collectObjectsConformingTo:aProtocol]];
    }
    
    return collection;
    
}

- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
    [collection addObjectsFromArray:[super collectObjectsRespondingTo:aSelector]];
    
    NSEnumerator* e  = [orcaObjects objectEnumerator];
    OrcaObject* anObject;
    while(anObject = [e nextObject]){
        [collection addObjectsFromArray:[anObject collectObjectsRespondingTo:aSelector]];
    }
    
    return collection;
    
}

- (id) findObjectWithFullID:(NSString*)aFullID
{
    if([aFullID isEqualToString:[self fullID]])return self;
    else {
        NSEnumerator* e  = [orcaObjects objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject]){
            id obj = [anObject findObjectWithFullID:aFullID];
            if(obj)return obj;
        }
        return nil;
    }
}

- (void) bringSelectedObjectsToFront
{
	NSEnumerator* e = [[self selectedObjects] reverseObjectEnumerator];
	OrcaObject* anObject;
	while(anObject = [e nextObject]){
		[orcaObjects moveObject:anObject toIndex:[orcaObjects count]];
	}
}

- (void) sendSelectedObjectsToBack
{
	NSEnumerator* e = [[self selectedObjects] objectEnumerator];
	OrcaObject* anObject;
	while(anObject = [e nextObject]){
		[orcaObjects moveObject:anObject toIndex:0];
	}
	
}

- (void) removeSelectedObjects
{
    [self removeObjects:[self selectedObjects]];
}

- (NSEnumerator*) objectEnumerator
{
	return [orcaObjects objectEnumerator];
}

- (void) drawContents:(NSRect)aRect
{
    int n = [orcaObjects count];
    int i;
    for(i=0;i<n;i++){
        [[orcaObjects objectAtIndex:i] drawSelf:aRect];
    }
}

- (void) drawIcons:(NSRect)aRect
{
    int n = [orcaObjects count];
    int i;
    for(i=0;i<n;i++){
        [[orcaObjects objectAtIndex:i] drawIcon:aRect withTransparency:1];
    }
}


- (NSArray*)selectedObjects
{
    NSMutableArray* theSelectedObjects = [[NSMutableArray alloc] init];
    int n = [orcaObjects count];
    int i;
    for(i=0;i<n;i++){
        OrcaObject* anObject = [orcaObjects objectAtIndex:i];
        if([anObject highlighted] && [anObject changesAllowed]){
            [theSelectedObjects addObject:anObject];
        }
    }
    return [theSelectedObjects autorelease];
}

- (NSArray*)allSelectedObjects
{
    NSMutableArray* theSelectedObjects = [[NSMutableArray alloc] init];
    int n = [orcaObjects count];
    int i;
    for(i=0;i<n;i++){
        OrcaObject* anObject = [orcaObjects objectAtIndex:i];
        if([anObject highlighted]){
            [theSelectedObjects addObject:anObject];
        }
    }
    return [theSelectedObjects autorelease];
}


- (void) clearSelections:(BOOL)shiftKeyDown
{
    NSEnumerator* e  = [orcaObjects objectEnumerator];
    id anObject;
    while (anObject = [e nextObject]) {
        [anObject setInsideSelectionRect:NO];
        if(!shiftKeyDown){
            [anObject setHighlighted:NO];
        }
    }
}

- (void) checkSelectionRect:(NSRect)aRect inView:(NSView*)aView;
{

    int n = [orcaObjects count];
    int i;
    for(i=0;i<n;i++){
        OrcaObject* anObject = [orcaObjects objectAtIndex:i];

		BOOL oldHighlighted = [anObject highlighted];
        if([anObject intersectsRect:aRect]){ //touched by the selection rect
            [aView setNeedsDisplayInRect:[anObject frame]];
            if(![anObject insideSelectionRect]){
                [anObject setInsideSelectionRect:YES];
                [anObject setHighlighted : ![anObject highlighted]];
            }
        }
        else {													//NOT touched by the selection rect
            if([anObject insideSelectionRect]){
                [anObject setInsideSelectionRect:NO];
                [anObject setHighlighted : ![anObject highlighted]];
            }
        }
		if(oldHighlighted != [anObject highlighted]){
            [aView setNeedsDisplayInRect:[anObject frame]];
		}
    }
}

- (void) changeSelectedObjectsLevel:(BOOL)up
{
	id obj;
	NSEnumerator* e = [[self selectedObjects] objectEnumerator];
	while(obj = [e nextObject]){
		[orcaObjects removeObject:obj];
		[orcaObjects insertObject:obj atIndex:up?0:[orcaObjects count]];
	}
}

- (void) checkRedrawRect:(NSRect)aRect inView:(NSView*)aView;
{
    int n = [orcaObjects count];
    int i;
    for(i=0;i<n;i++){
        OrcaObject* anObject = [orcaObjects objectAtIndex:i];
        if([anObject rectIntersectsIcon:aRect]){      //touched by the selection rect
            [aView setNeedsDisplayInRect:[anObject bounds]];
        }
    }
}

-(NSRect)rectEnclosingObjects:(NSArray*)someObjects
{
    NSRect theEnclosingRect = NSZeroRect;
    BOOL first = YES;
    int n = [someObjects count];
    int i;
    for(i=0;i<n;i++){
        OrcaObject* anObject = [someObjects objectAtIndex:i];
        if(first){
            theEnclosingRect = [anObject frame];
            first = NO;
        }
        else theEnclosingRect =  NSUnionRect(theEnclosingRect,[anObject frame]);
    }
    return theEnclosingRect;
}

-(NSImage*) imageOfObjects:(NSArray*)someObjects withTransparency:(float)aTransparency
{
    NSRect imageBounds;
    float minx,miny;
    
    NSEnumerator *enumerator = [someObjects objectEnumerator];
    NSRect theEnclosingRect  = [self rectEnclosingObjects:someObjects];
    NSImage* anUnScaledImage = [[NSImage alloc] initWithSize:theEnclosingRect.size];
    
    id anObject;
    
    minx = NSMinX(theEnclosingRect);
    miny = NSMinY(theEnclosingRect);
    imageBounds.origin = NSMakePoint(0,0);
    imageBounds.size   = theEnclosingRect.size;
    
    [anUnScaledImage lockFocus];
    while ((anObject = [enumerator nextObject])) {
       [anObject drawImageAtOffset:NSMakePoint(-minx, -miny) withTransparency:(float)aTransparency];
    }
    [anUnScaledImage unlockFocus];
    
    
    return [anUnScaledImage autorelease];
}

- (NSPoint) originOfObjects:(NSArray*)someObjects
{
    return [self rectEnclosingObjects:someObjects].origin;
}



@end
