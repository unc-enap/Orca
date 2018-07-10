//
//  ORObjectProxy.h
//  Orca
//
//  Created by Mark Howe on 11/27/07.
//  Copyright 2007 University of North Carolina. All rights reserved.
//

@interface ORObjectProxy : NSObject {
	id hwObject;
	NSString* hwName;
	NSString* proxyName;
	NSString* slotNotification;
}

#pragma mark •••Initialization
- (id) initWithProxyName:(NSString*)aProxyName  slotNotification:(NSString*) aSlotNotification;
- (void) dealloc;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) objectsRemoved:(NSNotification*) aNote;
- (void) objectsAdded:(NSNotification*) aNote;
- (void) useProxyObjectWithName:(NSString*)aName;
- (void) slotChanged:(NSNotification*) aNote;

- (NSArray*) validObjects;
- (NSUndoManager*) undoManager;

#pragma mark •••Accessors
- (id) hwObject; 
- (void) setHwObject: (id) newValue; 
- (NSString *) hwName; 
- (void) setHwName: (NSString *) aName; 
- (NSString *) proxyName;
- (void) setProxyName: (NSString *) aName; 
- (void) setSlotNotification: (NSString *) newValue;
- (BOOL) classInList:(NSArray*)anArray;


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••GUI Helpers
- (void) populatePU:(NSPopUpButton*) pu;
- (void) selectItemForPU:(NSPopUpButton*) pu;

#pragma mark •••Method Forwarding
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
- (void) forwardInvocation:(NSInvocation *)invocation;

@end

@interface NSObject (ORObjectProxy)
- (NSString*) processingTitle;
@end

extern NSString* ORObjectProxyChanged;
extern NSString* ORObjectProxyNumberChanged;
