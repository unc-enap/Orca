//
//  ORGroup.h
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


#pragma mark ¥¥¥Imported Files

@interface ORGroup:OrcaObject <NSCoding> {
    @private
	NSMutableArray* orcaObjects;
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) awakeAfterDocumentLoaded;

#pragma mark ¥¥¥Assessors
- (void) setOrcaObjects:(NSMutableArray*)anArray;
- (NSMutableArray*) orcaObjects;
- (NSUInteger) count;
- ( NSMutableArray*)children;
- (NSMutableArray*) familyList;
- (NSEnumerator*) objectEnumerator;
- (id) objectAtIndex:(NSUInteger) index;

#pragma mark ¥¥¥Undoable Actions
- (void) addObject:(id)anObject;
- (void) removeObject:(id)anObject;
- (void) addObjects:(NSArray*)someObjects;
- (void) removeObjects:(NSArray*)someObjects;
- (void) objectCountChanged;
- (void) bringSelectedObjectsToFront;
- (void) sendSelectedObjectsToBack;

#pragma mark ¥¥¥Group Methods
- (BOOL)   useAltView;
- (BOOL)    changesAllowed;
- (void)    removeSelectedObjects;
- (void)    drawContents:(NSRect)aRect;
- (void)	drawIcons:(NSRect)aRect;
- (NSArray*) selectedObjects;
- (NSArray*)allSelectedObjects;
- (void)    clearSelections:(BOOL)shiftKeyDown;
- (void)    checkSelectionRect:(NSRect)aRect inView:(NSView*)aView;
- (void)    checkRedrawRect:(NSRect)aRect inView:(NSView*)aView;
- (NSRect)  rectEnclosingObjects:(NSArray*)someObjects;
- (NSImage*) imageOfObjects:(NSArray*)someObjects withTransparency:(float)aTransparency;
- (NSPoint) originOfObjects:(NSArray*)someObjects;
- (void)    unHighlightAll;
- (void)    highlightAll;
- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector;
- (NSArray*) collectObjectsConformingTo:(Protocol*)aProtocol;
- (NSArray*) collectObjectsOfClass:(Class)aClass;
- (void) resetAlreadyVisitedInChainSearch;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) changeSelectedObjectsLevel:(BOOL)up;

- (id) findObjectWithFullID:(NSString*)aFullID;

@end

#pragma mark ¥¥¥Extern Definitions
extern NSString* ORGroupObjectList;
extern NSString* ORGroupObjectsAdded;
extern NSString* ORGroupObjectsRemoved;
extern NSString* ORGroupSelectionChanged;

extern NSString* ORGroupPasteBoardItem;
extern NSString* ORGroupDragBoardItem;

