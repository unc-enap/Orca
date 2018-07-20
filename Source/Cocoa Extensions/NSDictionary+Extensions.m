//
//  NSDictionary+Extensions.m
//  Orca
//
//  Created by Mark Howe on 10/4/04.
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
#import "NSDictionary+Extensions.h"
#import "NSFileManager+Extensions.h"

@implementation NSDictionary (OrcaExtensions)

- (NSArray*) allKeysStartingWith:(NSString*)aString
{
    NSArray* allKeys = [self allKeys];
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[allKeys count]];
    NSEnumerator* e = [allKeys objectEnumerator];
    id s;
    while(s = [e nextObject]){
        if([s rangeOfString:aString].location == 0){
            [result addObject:s];
        }
    }
    return result;
}

- (id) objectForNestedKey:(NSString*)aStringList
{
	return [self objectForKeyArray:[NSMutableArray arrayWithArray:[aStringList componentsSeparatedByString:@","]]];
}

- (id) objectForKeyArray:(NSMutableArray*)anArray
{
	if([anArray count] == 0)return self;
	else {
		id aKey = [anArray objectAtIndex:0];
		[anArray removeObjectAtIndex:0];
		id anObj = [self objectForKey:aKey];
		if([anObj respondsToSelector:@selector(objectForKeyArray:)]){
			return [anObj objectForKeyArray:anArray];
		}
		else {
			if(anObj)return anObj;
			else return self;
		}
    }
}

- (id) nestedObjectForKeyList:(id)firstKey withvaList:(va_list)keyList
{
	NSString* s = firstKey;
	id result = [self objectForKey:s];
	while((s = va_arg(keyList, NSString *))) {
		result = [result objectForKey:s];
    }
	return result;
}

- (id) nestedObjectForKey:(id)firstKey,...
{
    va_list myArgs;
    va_start(myArgs,firstKey);
    
    NSString* s = firstKey;
	id result = [self objectForKey:s];
	while((s = va_arg(myArgs, NSString *))) {
		result = [result objectForKey:s];
    }
    va_end(myArgs);
	
	return result;
}

- (NSData*) asData
{
    //write request to temp file because we want the form you get from a disk file...the string to property list isn't right.
    NSString* thePath =[NSFileManager tempPathInAppSupportFolderUsingTemplate:@"ORCADictionaryXXX"];
    [self writeToFile:thePath atomically:YES];
    NSData* data = [NSData dataWithContentsOfFile:thePath];
	[[NSFileManager defaultManager] removeItemAtPath:thePath error:nil];
	return data;
}

- (uint32_t) uLongForKey:(NSString*)aKey
{
	return (uint32_t)[[self objectForKey:aKey] unsignedLongValue];
}
- (int32_t) longForKey:(NSString*)aKey
{
	return (int32_t)[[self objectForKey:aKey] unsignedLongValue];
}

- (unsigned short) uShortForKey:(NSString*)aKey
{
	return [[self objectForKey:aKey] unsignedShortValue];
}

- (short) shortForKey:(NSString*)aKey
{
	return [[self objectForKey:aKey] shortValue];
}

- (unsigned int) uIntForKey:(NSString*)aKey
{
	return [[self objectForKey:aKey] unsignedIntValue];
}

- (int) intForKey:(NSString*)aKey
{
	return [[self objectForKey:aKey] intValue];
}

- (BOOL) boolForKey:(NSString*)aKey
{
	return [[self objectForKey:aKey] boolValue];
}


+ (id) dictionaryWithPList:(id)plist
{
	//write request to temp file because we want the form you get from a disk file...the string to property list isn't right.
    NSString* thePath =[NSFileManager tempPathInAppSupportFolderUsingTemplate:@"ORCADictionaryXXX"];

    [plist writeToFile:thePath atomically:YES];
	NSDictionary* theResponse = [NSDictionary dictionaryWithContentsOfFile:thePath];
	[[NSFileManager defaultManager] removeItemAtPath:thePath error:nil];
	return theResponse;
}
- (void) prettyPrint:(NSString*)aTitle
{
	NSLog(@"%@\n",aTitle);
	NSArray* allKeys = [self allKeys];
	for(id aKey in allKeys){
		NSLog(@"%@ : %@\n",aKey,[self objectForKey:aKey]);
	}
}
@end

@implementation NSMutableDictionary (OrcaExtensions)

- (void) setObject:(id)anObject forNestedKey:(NSString*)aStringList
{
	NSMutableArray* anArrayOfKeys = [NSMutableArray arrayWithArray:[aStringList componentsSeparatedByString:@","]];
	id firstKey = [anArrayOfKeys objectAtIndex:0];
	if([anArrayOfKeys count] == 1){
		[self setObject:anObject forKey:firstKey];
	}
	else {
		id obj = [self objectForKey:firstKey];
		if(!obj){
			obj = [NSMutableDictionary dictionary];
			[self setObject:obj forKey:firstKey];
		}
		[anArrayOfKeys removeObjectAtIndex:0];
		[obj setObject:anObject forNestedKey:[anArrayOfKeys componentsJoinedByString:@","]];
	}
}

@end

@implementation NSMutableDictionary (ThreadSafety)

- (id) threadSafeObjectForKey: (id) aKey
					usingLock: (NSLock *) aLock;
{
    id    result;
	
	@try {
		[aLock lock];
		result = [self objectForKey: aKey];
		[[result retain] autorelease];
	}
	@finally {
		[aLock unlock];
	}
    return result;
}

- (void) threadSafeRemoveObjectForKey: (id) aKey
							usingLock: (NSLock *) aLock;
{
	@try {
		[aLock lock];
		[self removeObjectForKey: aKey];
	}
	@finally {
		[aLock unlock];
	}
}

- (void) threadSafeSetObject: (id) anObject
					  forKey: (id) aKey
				   usingLock: (NSLock *) aLock;
{
	@try {
		[aLock lock];
		[[anObject retain] autorelease];
		[self setObject: anObject  forKey: aKey];
	}
	@finally {
		[aLock unlock];
	}
}



@end

