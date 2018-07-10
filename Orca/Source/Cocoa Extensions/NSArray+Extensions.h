//
//  NSArray+Extensions.h
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
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


@interface NSArray (OrcaExtensions)
- (BOOL)containsObjectIdenticalTo: (id)object;
- (NSArray *)tabJoinedComponents;
- (NSString *)joinAsLinesOfEndingType:(LineEndingType)type;
- (NSData *)dataWithLineEndingType:(LineEndingType)lineEndingType;
- (id) objectForKeyArray:(NSMutableArray*)anArray;
- (void) prettyPrint:(NSString*)aTitle;
+ (NSArray*) arrayFromLongCArray   : (long*)          cArray size:(int)num;
+ (NSArray*) arrayFromULongCArray  : (unsigned long*) cArray size:(int)num;
+ (NSArray*) arrayFromShortCArray  : (short*)         cArray size:(int)num;
+ (NSArray*) arrayFromUShortCArray : (unsigned short*)cArray size:(int)num;
+ (NSArray*) arrayFromCharCArray   : (char*)          cArray size:(int)num;
+ (NSArray*) arrayFromUCharCArray  : (unsigned char*) cArray size:(int)num;
+ (NSArray*) arrayFromBoolCArray   : (BOOL*)          cArray size:(int)num;

- (void) loadLongCArray   : (long*)          cArray size:(int)num;
- (void) loadULongCArray  : (unsigned long*) cArray size:(int)num;
- (void) loadShortCArray  : (short*)         cArray size:(int)num;
- (void) loadUShortCArray : (unsigned short*)cArray size:(int)num;
- (void) loadCharCArray   : (char*)          cArray size:(int)num;
- (void) loadUCharCArray  : (unsigned char*) cArray size:(int)num;
- (void) loadBoolCArray   : (BOOL*)          cArray size:(int)num;
@end

@interface NSMutableArray (OrcaExtensions)
- (void) insertObjectsFromArray:(NSArray *)array atIndex:(int)index;
- (NSMutableArray*) children;
- (NSUInteger) numberOfChildren;
- (void) moveObject:(id)anObj toIndex:(NSUInteger)newIndex;
- (void)shuffle;

//implements stack behavior
- (id)   pop;
- (id)   popTop;
- (void) push:(id)object;
- (id)   peek;
@end
