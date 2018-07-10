//
//  ORObjectProxy.m
//  Orca
//
//  Created by Mark Howe on 11/27/07.
//  Copyright 2007 University of North Carolina. All rights reserved.
//

#import "ORObjectProxy.h"
#import "ORGroup.h"

NSString* ORObjectProxyChanged			= @"ORObjectProxyChanged";
NSString* ORObjectProxyNumberChanged	= @"ORObjectProxyNumberChanged";

@implementation ORObjectProxy
- (id) initWithProxyName:(NSString*)aProxyName  slotNotification:(NSString*) aSlotNotification
{
	self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self setProxyName:aProxyName];
	[self setSlotNotification:aSlotNotification];
	[self registerNotificationObservers];
	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[hwName release];
	[proxyName release];
	[hwObject release];
	[slotNotification release];
	[super dealloc];
}

- (void) registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];
    
    [ notifyCenter addObserver: self
                      selector: @selector(objectsRemoved:)
                          name: ORGroupObjectsRemoved
                        object: nil];
    
    [ notifyCenter addObserver: self
                      selector: @selector(objectsAdded:)
                          name: ORGroupObjectsAdded
                        object: nil];
    
    [notifyCenter addObserver: self
                      selector: @selector(slotChanged:)
                          name: slotNotification
                        object: nil];

    [notifyCenter addObserver: self
                      selector: @selector(objectsAdded:)
                          name: ORDocumentLoadedNotification
                        object: nil];

}

- (NSArray*) validObjects
{
    return [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString([self proxyName])];
}

- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

- (BOOL) classInList:(NSArray*)anArray
{
	NSEnumerator* e = [anArray objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		if([[obj className] isEqualToString:proxyName]){
			return YES;
		}
	}
	return NO;
}

- (void) objectsRemoved:(NSNotification*) aNote
{
	BOOL doWeCare = [self classInList:[[aNote userInfo] objectForKey:ORGroupObjectList]];

	if(hwObject && hwName && doWeCare){
		//we have a hwObject. make sure that our hwObj still exists
		NSArray* validObjs = [self validObjects];  
		BOOL stillExists = NO; //assume the worst
		id obj;
		NSEnumerator* e = [validObjs objectEnumerator];
		while(obj = [e nextObject]){
			if(hwObject == obj){
				stillExists = YES;
				break;
			}
		}
		if(!stillExists){
			[self setHwObject:nil];
		}
	}
	if(doWeCare)[[NSNotificationCenter defaultCenter] postNotificationName:ORObjectProxyNumberChanged object:self];
}

- (void) objectsAdded:(NSNotification*) aNote
{
 	BOOL doWeCare = [self classInList:[[aNote userInfo] objectForKey:ORGroupObjectList]] ||
					[[aNote name] isEqualToString:ORDocumentLoadedNotification];
					
	if(!hwObject && hwName && doWeCare){
        //we have a hwName but no valid object. try to match up with on of the new objects
        id obj;
        NSEnumerator* e = [[self validObjects] objectEnumerator];
        while(obj = [e nextObject]){
            if([hwName isEqualToString:[obj processingTitle]]){
                [self setHwObject:obj];
                break;
            }
        }
    }
	if(doWeCare) [[NSNotificationCenter defaultCenter] postNotificationName:ORObjectProxyNumberChanged object:self];
	
}

- (void) slotChanged:(NSNotification*) aNote
{
    //we have a hwName. our obj may have switched slots
    if(hwName){
        id obj;
        NSEnumerator* e = [[self validObjects] objectEnumerator];
        while(obj = [e nextObject]){
            if(obj == hwObject && ![hwName isEqualToString:[obj processingTitle]]){
                [self useProxyObjectWithName:[obj processingTitle]];
                break;
            }
        }
    }
}


- (void) useProxyObjectWithName:(NSString*)aName
{
    id objectToUse      = nil;
    NSString* nameOfObj = nil;
    NSArray* validObjs = [self validObjects];   
    if([validObjs count]){
        id obj;
        NSEnumerator* e = [validObjs objectEnumerator];
        while(obj = [e nextObject]){
            if([aName isEqualToString:[obj processingTitle]]){
                objectToUse = obj;
                nameOfObj = aName;
                break;
            }
        }
        [self setHwName:nameOfObj];
    }
    [self setHwObject:objectToUse];
}


- (void) setSlotNotification: (NSString *) newValue 
{
   [slotNotification autorelease];
    slotNotification = [newValue copy];
}

- (id) hwObject 
{
	return hwObject;
}

- (void) setHwObject: (id) newValue 
{
	[[[self undoManager] prepareWithInvocationTarget:self] setHwObject:hwObject];
	[newValue retain];
	[hwObject release];
	hwObject = newValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORObjectProxyChanged object:self];
}


- (NSString *) hwName 
{
	return hwName;
}

- (void) setHwName: (NSString *) aName 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHwName:hwName];
	
    [hwName autorelease];
    hwName = [aName copy];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORObjectProxyChanged object:self];
}

- (NSString *) proxyName 
{
	return proxyName;
}

- (void) setProxyName: (NSString *) aName 
{
    [proxyName autorelease];
    proxyName = [aName copy];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setHwName:[decoder decodeObjectForKey:@"hwName"]];
    [self setProxyName:[decoder decodeObjectForKey:@"proxyName"]];
    [self setSlotNotification:[decoder decodeObjectForKey:@"slotNotification"]];
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:hwName forKey:@"hwName"];
    [encoder encodeObject:proxyName forKey:@"proxyName"];
    [encoder encodeObject:slotNotification forKey:@"slotNotification"];
}

#pragma mark •••GUI Helpers
- (void) populatePU:(NSPopUpButton*) pu
{
	[pu removeAllItems];
    [pu addItemWithTitle:@"---"];
    id obj;
    NSEnumerator* e = [[self validObjects] objectEnumerator];
    while(obj = [e nextObject]){
        [pu addItemWithTitle:[obj processingTitle]];
    }
}

- (void) selectItemForPU:(NSPopUpButton*) pu
{
	BOOL ok = NO;
	id obj;
	NSEnumerator* e = [[self validObjects] objectEnumerator];
	while(obj = [e nextObject]){
		if([hwName isEqualToString:[obj processingTitle]]){
			[pu selectItemWithTitle:hwName];
			ok = YES;
			break;
		}
	}
	if(!ok)[pu selectItemAtIndex:0];
}

#pragma mark •••Method Forwarding
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if(hwObject && ![self respondsToSelector:aSelector]){
        return [hwObject methodSignatureForSelector:aSelector];
    }
    else {
        return [super methodSignatureForSelector:aSelector];
    }
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
    if(hwObject)[invocation invokeWithTarget:hwObject];
}

@end
