//
//  NSDictionary+Extensions.h
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

@interface NSDictionary (OrcaExtensions)
- (NSArray*) allKeysStartingWith:(NSString*)aString;
- (id) objectForNestedKey:(NSString*)aStringList;
- (id) nestedObjectForKeyList:(id) firstKey withvaList:(va_list)keyList;
- (id) nestedObjectForKey:(id)firstKey,...;
- (id) objectForKeyArray:(NSMutableArray*)anArray;
- (NSData*) asData;
+ (id) dictionaryWithPList:(id)plist;
- (unsigned long) uLongForKey:(NSString*)aKey;
- (long) longForKey:(NSString*)aKey;
- (unsigned short) uShortForKey:(NSString*)aKey;
- (short) shortForKey:(NSString*)aKey;
- (unsigned int) uIntForKey:(NSString*)aKey;
- (int) intForKey:(NSString*)aKey;
- (BOOL) boolForKey:(NSString*)aKey;
- (void) prettyPrint:(NSString*)aTitle;
@end

@interface NSMutableDictionary (OrcaExtensions)
- (void) setObject:(id)anObject forNestedKey:(NSString*)aStringList;
@end

@interface NSMutableDictionary (ThreadSafety)

- (id) threadSafeObjectForKey: (id) aKey
					usingLock: (NSLock *) aLock;

- (void) threadSafeRemoveObjectForKey: (id) aKey
							usingLock: (NSLock *) aLock;

- (void) threadSafeSetObject: (id) anObject
					  forKey: (id) aKey
				   usingLock: (NSLock *) aLock;

@end