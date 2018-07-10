//
//  ORReadOutList.h
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




@class ORDataPacket;
@class ORReadOutList;

@interface ORReadOutObject : NSObject {
    id owner;       //another readoutlist
    id object;      //object this readout points to
}

+ (id) readOutObjectWithFile:(NSFileHandle*)aFile owner:(ORReadOutList*)anOwner;

- (id) initWithObject:(id)anObject;
- (void) setOwner:(id)anOwner;
- (NSMutableArray*) children;
- (id) owner;
- (id) object;
- (NSString*) objectName;
- (NSString*) isDataTaker;
- (NSString*) identifier;
- (void) saveUsingFile:(NSFileHandle*)aFile;
- (void) loadUsingFile:(NSFileHandle*)aFile;

@end


@interface ORReadOutList : NSObject {
    NSString*       identifier;
    NSMutableArray* children;
	NSString* acceptedProtocol;
	NSMutableArray*  acceptedClasses;
}

#pragma mark ¥¥¥Initialization
- (id) initWithIdentifier:(NSString*)anIdentifier;
- (void) dealloc;

#pragma mark ¥¥¥Accessors
- (NSUInteger) count;
- (NSMutableArray*) children;
- (void)	    setChildren:(NSMutableArray*)newChildren;
- (NSString*) acceptedProtocol;
- (void) setAcceptedProtocol:(NSString*)aString;
- (void) addAcceptedObjectName:(NSString*)objectName;

- (BOOL) containsObject:(id) anObj;
- (NSUInteger) indexOfObject:(id) anObj;

- (BOOL) acceptsObject:(id) anObject;
- (void) moveObject:(id)anObj toIndex:(NSUInteger)index;
- (void) removeObject:(id)obj;
- (void) addObject:(id)obj;
- (void) insertObject:(id)anObj atIndex:(NSUInteger)index;
- (void) removeObjectAtIndex:(NSUInteger)index;
- (void) addObjectsFromArray:(NSArray*)anArray;
- (void) removeObjectsInArray:(NSArray*)anArray;
- (NSUndoManager *)	undoManager;
- (void) removeOrcaObject:(id)anObject;

- (NSArray*) allObjects;
- (id) itemHolding:(id)anObject;
- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel;

#pragma mark ¥¥¥ID Helpers
- (NSString*) objectName;
- (NSString*) isDataTaker;
- (void)      setIdentifier:(NSString*)newIdentifier;
- (NSString*) identifier;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) objectsRemoved:(NSNotification*)aNote;
- (void) removeObjects:(NSArray*)objects;

#pragma mark ¥¥¥Archival
- (id)	 initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (void) saveUsingFile:(NSFileHandle*)aFile;
- (void) loadUsingFile:(NSFileHandle*)aFile;

@end

extern NSString* NSReadOutListChangedNotification;

@interface NSObject (ORReadOutList)
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;
@end
