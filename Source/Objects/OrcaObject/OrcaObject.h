//
//  OrcaObject.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 29 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Extern Definitions
extern NSString* OROrcaObjectMoved;
extern NSString* OROrcaObjectDeleted;
extern NSString* ORObjPtr;
extern NSString* ORObjArrayPtrPBType;

#pragma mark ¥¥¥Forward Definitions
@class OrcaObjectController;
@class ORDataPacket;
@class ORDocument;
@class ORConnector;
@class ORGroup;
@class ORConnection;

@interface OrcaObject:NSObject <NSCoding,NSCopying,NSMenuDelegate>
{
	@protected
        id			guardian;
        NSImage* 	image;
        NSImage* 	highlightedImage;
        NSRect 		frame;
        NSRect 		bounds;
        BOOL 		highlighted;
        BOOL 		insideSelectionRect;
        NSPoint 	offset;
        BOOL		skipConnectionDraw;
        NSMutableDictionary* connectors;
 		BOOL		alreadyVisitedInChainSearch;
        NSMutableDictionary* miscAttributes;
		BOOL        loopChecked;
        BOOL        enableIconControls;
    
    @private
        //internal flags
        BOOL		aWake;
        NSUInteger   tag; //used by subclasses for identification
        uint32_t uniqueIdNumber;
}

#pragma mark ¥¥¥Inialization
- (id) init; //designated initializer
- (id) copyWithZone:(NSZone*)zone;
- (void) setUpImage;

#pragma mark *Subclass Methods
- (void) makeMainController;
- (BOOL) hasDialog;
- (NSString*) helpURL;

#pragma mark ¥¥¥Accessors
- (void)		setLoopChecked:(BOOL)aFlag;
- (void)		clearLoopChecked;
- (BOOL)		loopChecked;
- (int)			x;
- (int) 		y;
- (id) 			guardian;
- (void) 		setGuardian:(id)aGuardian;
- (void) 		setConnectors:(NSMutableDictionary*)anArray;
- (NSMutableDictionary*)  connectors;
- (id)			document;
- (void) 		wakeUp;
- (void)		sleep;
- (NSUndoManager *)	undoManager;
- (NSRect) 		defaultFrame;
- (void) 		setFrame:(NSRect)aValue;
- (NSRect) 		frame;
- (void) 		setBounds:(NSRect)aValue;
- (NSRect)		bounds;
- (void) 		setOffset:(NSPoint)aPoint;
- (NSPoint) 		offset;
- (BOOL) 		highlighted;
- (void) 		setHighlighted:(BOOL)state;
- (BOOL) 		insideSelectionRect;
- (void) 		setInsideSelectionRect:(BOOL)state;
- (void) 		setImage:(NSImage*)anImage;
- (NSImage*)		image;
- (BOOL) 		acceptsGuardian: (OrcaObject*)aGuardian;
- (BOOL) 		skipConnectionDraw;
- (void)		setSkipConnectionDraw:(BOOL)state;
- (NSMutableArray*) 	children;
- (NSMutableArray*) 	familyList;
- (int)         stationNumber;
- (NSUInteger)	tag;
- (void)		setTag:(NSUInteger)aTag;
- (int)         tagBase;
- (BOOL)        solitaryObject;
- (BOOL)		solitaryInViewObject;
- (void)        askForUniqueIDNumber;
- (void)        setUniqueIdNumber:(uint32_t)anIdNumber;
- (uint32_t) uniqueIdNumber;
- (BOOL)        selectionAllowed;
- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey;
- (BOOL) isObjectInConnectionChain:(id)anObject;
- (void) resetAlreadyVisitedInChainSearch;
- (BOOL) changesAllowed;
- (NSMutableDictionary*) miscAttributesForKey:(NSString*)aKey;
- (void) setMiscAttributes:(NSMutableDictionary*)someAttributes forKey:(NSString*)aKey;
- (id) calibration;

#pragma mark ¥¥¥ID Helpers
- (NSString*)		objectName;
- (NSString*) 		isDataTaker;
- (NSString*)		supportsHardwareWizard;
- (NSString*) 		identifier;
- (NSString*)		fullID;

#pragma mark ¥¥¥Mouse Events
- (BOOL) intersectsRect:(NSRect) aRect;
- (BOOL) acceptsClickAtPoint:(NSPoint)aPoint;
- (void) openHelp:(id)sender;
- (void) doDoubleClick:(id)sender;
- (void) doCmdClick:(id)sender atPoint:(NSPoint)aPoint;
- (void) doShiftCmdClick:(id)sender atPoint:(NSPoint)aPoint;
- (void) doCmdDoubleClick:(id)sender atPoint:(NSPoint)aPoint;
- (void) doCntrlClick:(NSView*)aView;
- (ORConnector*) requestsConnection: (NSPoint)aPoint;
- (BOOL) rectIntersectsIcon:(NSRect)aRect;
- (BOOL) validateMenuItem:(NSMenuItem *)anItem;
- (void) flagsChanged:(NSEvent *)theEvent;
- (void) setEnableIconControls:(BOOL) aState;

#pragma mark ¥¥¥Archival
- (id)	initWithCoder:(NSCoder*)aCoder;
- (void)encodeWithCoder:(NSCoder*)aCoder;

#pragma mark ¥¥¥Positioning
- (void) setFrameOrigin:(NSPoint)aPoint;

#pragma mark ¥¥¥Undoable Actions
- (void) moveTo:(NSPoint)aPoint;
- (void) move:(NSPoint)aPoint;
- (void) showMainInterface;

#pragma mark ¥¥¥Drawing
- (void) drawSelf:(NSRect)aRect;
- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency;
- (void) drawIcon:(NSRect)aRect withTransparency:(float)aTransparency;
- (void) drawImageAtOffset:(NSPoint)anOffset withTransparency:(float)aTransparency;
- (void) drawConnections:(NSRect)aRect withTransparency:(float)aTransparency;

#pragma mark ¥¥¥General Helpers
- (void) setHighlightedYES;
- (void) setHighlightedNO;
- (NSArray*) collectObjectsOfClass:(Class)aClass;
- (NSArray*) collectConnectedObjectsOfClass:(Class)aClass;
- (NSArray*) collectObjectsConformingTo:(Protocol*)aProtocol;
- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector;
- (NSArray*) subObjectsThatMayHaveDialogs;
- (id) findObjectWithFullID:(NSString*)aFullID;
- (void) postWarning:(NSString*)warningString;
- (id) findController;
- (NSComparisonResult)sortCompare:(OrcaObject*)anObj;


#pragma mark ¥¥¥Dialog Linking
- (void) linkToController:(NSString*)controllerClassName;

#pragma mark ¥¥¥Connection Management
- (id) objectConnectedTo:(id)aConnectorName;
- (id) connectorOn:(id)aConnectorName;
- (id) connectorAt:(NSPoint)aPt;
- (void) removeConnectorForKey:(NSString*)key;
- (void) disconnect;
- (void) connectionChanged;
- (void) assumeDisplayOf:(ORConnector*)aConnector;
- (void) removeDisplayOf:(ORConnector*)aConnector;
- (id) connectorWithName:(id)aConnectorName;

- (BOOL) aWake;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark ¥¥¥Run Management
- (void) addRunWaitWithReason:(NSString*)aReason;
- (void) releaseRunWait;
- (void) addRunWaitFor:(id)anObject reason:(NSString*)aReason;
- (void) releaseRunWaitFor:(id)anObject;

- (uint32_t) processID;
- (void) setProcessID:(uint32_t)aValue;

@end

#pragma mark ¥¥¥Compiler Warning Fixes
//This following are mostly just to fix compiler warnings in one place by supplying methods that 
//return default values
@interface OrcaObject (cardSupport)
- (short) numberSlotsUsed;
- (BOOL) acceptsObject:(id) anObject;
@end

@interface OrcaObject (scriptingAdditions)
- (long) longValue;
- (NSInteger) second;
- (NSInteger) minute;
- (NSInteger) hour;
- (NSInteger) day;
- (NSInteger) month;
- (NSInteger) year; 
@end

@interface OrcaObject (compilerErrorFix)
- (NSDictionary*) dataRecordDescription;
@end

@interface NSObject (OrcaObject_Catagory)
- (void) makeConnectors;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)aDataPacket forChannel:(int)aChannel;
- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel;
- (void) runTaskBoundary;
@end


extern NSString* OROrcaObjectMoved;
extern NSString* ORMovedObject;
extern NSString* ORForceRedraw;
extern NSString* OROrcaObjectImageChanged;
extern NSString* ORTagChangedNotification;
extern NSString* ORIDChangedNotification;
extern NSString* ORWarningPosted;
extern NSString* ORMiscAttributesChanged;
extern NSString* ORMiscAttributeKey;



