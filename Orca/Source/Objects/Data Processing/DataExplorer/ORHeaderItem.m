//
//  ORHeaderItem.m
//  Orca
//
//  Created by Mark Howe on 12/6/04.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORHeaderItem.h"

@implementation ORHeaderItem

+ (ORHeaderItem*) headerFromObject:(id)anObject named:(NSString*)aName
{
    ORHeaderItem* item = [[ORHeaderItem alloc] init];
    [item setName:aName];
    [item setClassType:NSStringFromClass([anObject class])];
    [item setItems:[NSMutableArray array]];
    //might be a dictionary
    if([anObject isKindOfClass:NSClassFromString(@"NSDictionary")]){
        NSArray* array = [anObject allKeys];
        NSArray* sortedArray = [array sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        int i;
        for(i=0;i<[sortedArray count];i++){
            NSString* aKey = [sortedArray objectAtIndex:i];
			ORHeaderItem* h = [ORHeaderItem headerFromObject:[anObject objectForKey:aKey] named:aKey];
			[h setGuardian:item];
            [item addObject:h];
        }
    }
    //might be an Array
    else if([anObject isKindOfClass:NSClassFromString(@"NSArray")]){
        int i;
        for(i=0;i<[anObject count];i++){
            NSString* aKey = [NSString stringWithFormat:@"%d",i];
			ORHeaderItem* h = [ORHeaderItem headerFromObject:[anObject objectAtIndex:i] named:aKey];
  			[h setGuardian:item];
			[item addObject:h];
        }
    }
    else {
        //else its just an NSNumber or something.
        [item setObject:anObject];
        
    }
    return [item autorelease];
}


- (void) dealloc
{
    [self setName: nil];
    [self setClassType: nil];
    [self setItems: nil];
    [self setObject: nil];

    [super dealloc];
}

- (NSString*) path
{
	NSArray* parts = [[self reversedPath] componentsSeparatedByString:@"/"];
	NSMutableArray* reversedParts = [NSMutableArray array];
	if([parts count]){
		NSEnumerator* e = [parts reverseObjectEnumerator];
		NSString* part;
		while(part = [e nextObject]){
			[reversedParts addObject:part];
		}
		return [reversedParts componentsJoinedByString:@"/"];
	}
	else return @"";
}

- (NSString*) reversedPath
{
	if([self guardian]){
		return [[name stringByAppendingString:@"/"] stringByAppendingString:[[self guardian] reversedPath]];
	}
	return name;
}

- (void) setGuardian:(ORHeaderItem*)anObject
{
	guardian = anObject; //don't retain
}

- (ORHeaderItem*) guardian
{
	return guardian;
}


- (NSString *) name
{
    return name; 
}

- (void) setName: (NSString *) aName
{
    [aName retain];
    [name release];
    name = aName;
}


- (NSString *) classType
{
    return classType; 
}

- (void) setClassType: (NSString *) aType
{
    if([aType hasPrefix:@"NSCF"])aType = [aType substringFromIndex:4];
    [aType retain];
    [classType release];
    classType = aType ;
}

- (id) object
{
    return object; 
}

- (void) setObject: (id) anObject
{
    [anObject retain];
    [object release];
    object = anObject;
}

- (NSMutableArray *) items
{
    return items; 
}

- (void) setItems: (NSMutableArray *) anItems
{
    [anItems retain];
    [items release];
    items = anItems;
}
- (void) addObject:(id)anObject
{
    [items addObject:anObject];
}

- (NSUInteger) count
{
    if([self isLeafNode]){
		return 1;
	}
	else return [items count];
}
- (BOOL) isLeafNode
{
    return object!=nil;
}
- (id) childAtIndex:(NSUInteger)index
{
	if([self isLeafNode])return object;
    else return [items objectAtIndex:index];
}

@end
