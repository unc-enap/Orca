//
//  ORReadOutList.m
//  Orca
//
//  Created by Mark Howe on Wed Jun 25 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORReadOutList.h"
#import "ORDataPacket.h"
#import "ORDataTaker.h"

#import "ORFileIOHelpers.h"

NSString* NSReadOutListChangedNotification = @"NSReadOutListChangedNotification";

@implementation ORReadOutObject

+ (id) readOutObjectWithFile:(NSFileHandle*)aFile owner:(ORReadOutList*)anOwner
{
    NSString* aString = getNextString(aFile);
    //get the object represented by the string
    id obj = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:aString];
    if(obj) {
        ORReadOutObject* anItem = [[ORReadOutObject alloc] initWithObject:obj];
        [anItem setOwner:anOwner];
        [anItem loadUsingFile:aFile];
        return [anItem autorelease];
    }
    else return nil;
}

- (id) initWithObject:(id)anObject
{
    self = [super init];
    owner 	= nil;
    object 	= anObject;
    return self;
}


- (void) setOwner:(id)aOwner
{
    if(owner && owner!=aOwner) [owner removeObject:self];
    owner = aOwner;
}
- (id) owner {return owner;}
- (id) object {return object;}

- (NSMutableArray*) children
{
	return [NSMutableArray arrayWithObject:object];
}

- (void) removeFromOwner
{
    [owner removeObject:self];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    owner = [decoder decodeObjectForKey:@"ReadOut_Owner"];
    object = [decoder decodeObjectForKey:@"ReadOut_Object"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeConditionalObject:owner forKey:@"ReadOut_Owner"];
    [encoder encodeConditionalObject:object forKey:@"ReadOut_Object"];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"Object: %@\n",object];
}

#pragma mark ¥¥¥Forwarding

- (void) showMainInterface
{
    [object showMainInterface];
}

- (void) saveUsingFile:(NSFileHandle*)aFile
{
    [aFile writeData:[[object fullID] dataUsingEncoding:NSASCIIStringEncoding]];
    [aFile writeData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding]];
    [aFile writeData:[@"" dataUsingEncoding:NSASCIIStringEncoding]];
    if([[object children]count])[object saveReadOutList:aFile];
}

- (void) loadUsingFile:(NSFileHandle*)aFile
{
    if([object respondsToSelector:@selector(loadReadOutList:)]){
        [object loadReadOutList:aFile];
    }
}


#pragma mark ¥¥¥ID Helpers
//----++++----++++----++++----++++----++++----++++----++++----++++
//  These methods are used when objects are displayed in tables
//----++++----++++----++++----++++----++++----++++----++++----++++
- (NSString*) objectName
{
    return [object objectName];
}
- (NSString*) isDataTaker
{
    return [object isDataTaker];
}

- (NSString*) identifier
{
    return [object identifier];
}

//----++++----++++----++++----++++----++++----++++----++++----++++


@end

@implementation ORReadOutList

#pragma mark ¥¥¥Initialization
- (id) initWithIdentifier:(NSString*)anIdentifier
{
    self = [super init];
    [self setIdentifier:anIdentifier];
    [self setChildren:[NSMutableArray array]];
    [self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [children release];
    [identifier release];
	[acceptedClasses release];
	[acceptedProtocol release];
    [super dealloc];
}

#pragma mark ¥¥¥Accessors

- (void) wakeUp
{
	[self registerNotificationObservers];
}

- (void) sleep
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableArray*) children
{
	return children;
}
- (void) setChildren:(NSMutableArray*)newChildren
{
	[children autorelease];
	children=[newChildren retain];
}

- (NSString*) objectName
{
	return identifier;
}

- (NSString*) isDataTaker
{
	return @"";
}

- (void) setIdentifier:(NSString*)newIdentifier
{
	[identifier autorelease];
	identifier = [newIdentifier copy];
	[[NSNotificationCenter defaultCenter]
				postNotificationName:NSReadOutListChangedNotification
							  object:self];
}

- (NSString*) identifier
{
	return @"";
}

- (NSUndoManager *)undoManager
{
    return [[(ORAppDelegate*)[NSApp delegate]document] undoManager];
}

- (BOOL) containsObject:(id) anObj
{
    return [children containsObject:anObj];
}

- (NSUInteger) indexOfObject:(id) anObj
{
    return [children indexOfObject:anObj];
}

- (NSString*) acceptedProtocol
{
	return acceptedProtocol;
}

- (void) setAcceptedProtocol:(NSString*)aString
{
	[acceptedProtocol autorelease];
	acceptedProtocol = [aString copy];
}

- (void) addAcceptedObjectName:(NSString*)objectName
{
	if(!acceptedClasses)acceptedClasses = [[NSMutableArray array] retain];
	[acceptedClasses addObject:objectName];
}

- (BOOL) acceptsObject:(id) anObject
{
	BOOL accepted = NO;
	if(!acceptedProtocol){
		accepted =  [anObject conformsToProtocol:@protocol(ORDataTaker)];
	}
	else {
		accepted = [anObject conformsToProtocol:NSProtocolFromString(acceptedProtocol)];
		if(accepted){
			if(acceptedClasses){
				accepted = [acceptedClasses containsObject:[anObject className]];
			}
		}
	}
	return accepted;
}

- (NSArray*) allObjects
{
	//return all objects from within our readoutobjects (NOT the readoutobjects themselves)
	NSMutableArray* all = [NSMutableArray array];
	NSEnumerator* e = [children objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
        if([obj object]){
            [all addObject:[obj object]];
        }
    }
	return all;
}

- (void) removeObject:(id)obj
{	
	if([children containsObject:obj]){
        
		[[[self undoManager] prepareWithInvocationTarget:self] insertObject:obj atIndex:[children indexOfObject:obj]];
        
		[children removeObject:obj];
        
		[[NSNotificationCenter defaultCenter]
					postNotificationName:NSReadOutListChangedNotification
                                  object:self];
        
	}	
}

//--------------------------------------------------------------
//special object... don't use unless you know what you're doing.
- (void) removeOrcaObject:(id)anObject
{
    for(id aChild in children){
        if([aChild isKindOfClass:NSClassFromString(@"ORReadOutObject")]){
            if([aChild object]==anObject){
                [self removeObject:aChild];
                break;
            }
        }
    }
}
//--------------------------------------------------------------

- (NSUInteger) count
{
	return [children count];
}


- (void) addObject:(id)obj
{
	[[[self undoManager] prepareWithInvocationTarget:self] removeObject:obj];
	[children addObject:obj];
    [[NSNotificationCenter defaultCenter]
					postNotificationName:NSReadOutListChangedNotification
                                  object:self];
    
}

- (void) moveObject:(id)anObj toIndex:(NSUInteger)index
{
	[[[self undoManager] prepareWithInvocationTarget:self] moveObject:anObj toIndex:[children indexOfObject:anObj]];
    if(index > [children count]-1){
        index = [children count]-1;
    }
	[children moveObject:anObj toIndex:index];
    [[NSNotificationCenter defaultCenter]
					postNotificationName:NSReadOutListChangedNotification
                                  object:self];
    
}

- (void) removeObjectAtIndex:(NSUInteger)index;
{
	if([children count]){
		[[[self undoManager] prepareWithInvocationTarget:self] insertObject:[children objectAtIndex:index] atIndex:index];
		[children removeObjectAtIndex:index];
		[[NSNotificationCenter defaultCenter]
					postNotificationName:NSReadOutListChangedNotification
                                  object:self];
	}
}

- (void) insertObject:(id)anObj atIndex:(NSUInteger)index
{
        [[[self undoManager] prepareWithInvocationTarget:self] removeObject:anObj];
        [children insertObject:anObj atIndex:index];
        [[NSNotificationCenter defaultCenter]
                        postNotificationName:NSReadOutListChangedNotification
                                      object:self];
}

- (void) addObjectsFromArray:(NSArray*)anArray
{
	[[[self undoManager] prepareWithInvocationTarget:self] removeObjectsInArray:anArray];
    
	[children addObjectsFromArray:anArray];
    
	   [[NSNotificationCenter defaultCenter]
				postNotificationName:NSReadOutListChangedNotification
                              object:self];
       
}

- (void) removeObjectsInArray:(NSArray*)anArray
{
	[[[self undoManager] prepareWithInvocationTarget:self] addObjectsFromArray:anArray];
	[children removeObjectsInArray:anArray];
    [[NSNotificationCenter defaultCenter]
				postNotificationName:NSReadOutListChangedNotification
                              object:self];
    
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSEnumerator* e = [children objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
        if([obj object]){
            [[obj object] appendEventDictionary:anEventDictionary topLevel:topLevel];
        }
    }	
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsRemoved:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
}


- (void) objectsRemoved:(NSNotification*)aNote
{
	[self removeObjects:[[aNote userInfo] objectForKey:ORGroupObjectList]];
}

- (void) removeObjects:(NSArray*)objects
{
	NSEnumerator* e = [objects objectEnumerator];
    
	id removedObject;
	while(removedObject = [e nextObject]){
		if([removedObject isKindOfClass:[ORGroup class]]){
			[self removeObjects:[removedObject orcaObjects]];
		}
		id item;
		while((item = [self itemHolding:removedObject])){
			[self removeObject:item];
		}
	}
}


- (id) itemHolding:(id)anObject
{
	NSEnumerator* e = [children objectEnumerator];
	id item;
	while(item = [e nextObject]){
		if([item object] == anObject)return item;
	}
	return nil;
}

#pragma mark ¥¥¥  Archival
static NSString *ORReadOutList_List 		= @"ORReadOutList_List";
static NSString *ORReadOutList_Identifier 	= @"ORReadOutList_Identifier";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];	
    [self setIdentifier:[decoder decodeObjectForKey:ORReadOutList_Identifier]];
    [self setChildren:[decoder decodeObjectForKey:ORReadOutList_List]];
    [self setAcceptedProtocol:[decoder decodeObjectForKey:@"acceptedProtocol"]];
	acceptedClasses = [[decoder decodeObjectForKey:@"acceptedClasses"] retain];
    [[self undoManager] enableUndoRegistration];
	
    [self registerNotificationObservers];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:identifier forKey:ORReadOutList_Identifier];
    [encoder encodeObject:acceptedProtocol forKey:@"acceptedProtocol"];
    [encoder encodeObject:children forKey:ORReadOutList_List];
	[encoder encodeObject:acceptedClasses forKey:@"acceptedClasses"];
}

- (void) saveUsingFile:(NSFileHandle*)aFile
{
    [aFile writeData:[[NSString stringWithFormat:@"%d <%@> items\n",(int)[children count],identifier] dataUsingEncoding:NSASCIIStringEncoding]];
    [aFile writeData:[@"" dataUsingEncoding:NSASCIIStringEncoding]];
    
    NSEnumerator* e = [children objectEnumerator];
    ORReadOutObject* item;
    while(item = [e nextObject]){
        [item saveUsingFile:aFile];
    }
}

- (void) loadUsingFile:(NSFileHandle*)aFile
{
    //get number of items
    NSString* string = getNextString(aFile);
    NSString* aName;
    NSScanner* 	scanner  = [NSScanner scannerWithString:string];
    [scanner scanUpToString:@"<" intoString:nil];
    [scanner scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:nil];
    [scanner scanUpToString:@">" intoString:&aName];
    if(aName)[self setIdentifier:aName];
    
    int num = [string intValue];
    int i;
    for(i=0;i<num;i++){    
        id obj = [ORReadOutObject readOutObjectWithFile:aFile owner:self];
        if(obj){
            [children addObject:obj];
        }
        else break; //couldn't reconstruct the list....error
    }
}


- (NSString*) description
{
    return [NSString stringWithFormat:@"%@ %@\n",identifier,children];
}


@end
