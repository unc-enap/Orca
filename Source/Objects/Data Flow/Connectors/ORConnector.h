//
//  ORConnector.h
//  Orca
//
//  Created by Mark Howe on Thu Dec 12 2002.
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


@class ORConnector;

#define kConnectorSize 10

#define kDefaultImage 		0
#define kHorizontalRect 	1
#define kVerticalRect 		2
#define kSmallVerticalRect 	3
#define kSmallDot			4

#define kInOutConnector		0	//Either (default)
#define kInputConnector		1	//only input
#define kOutputConnector	2	//only output

@interface ORConnector : NSObject <NSCoding> {
	id			 guardian;
    BOOL         sameGuardianIsOK;
	id  		 objectLink;
	NSRect		 localFrame;
	ORConnector* connector;
    NSColor*	 lineColor;
	NSImage*  	 onImage;
	NSImage*  	 offImage;

	NSImage*  	 onImage_Highlighted;
	NSImage*  	 offImage_Highlighted;

	int			 lineType;
	int 		 connectorImageType;
	uint32_t     connectorType;
	uint32_t 	 ioType;
	int 		 identifer;
    NSColor*     onColor;
    NSColor*     offColor;
    
	NSMutableArray* restrictedList;
	BOOL		hidden;
}

#pragma mark ¥¥¥Initialization
- (id) initAt:(NSPoint)aPoint withGuardian:(id)aGuardian;
- (id) initAt:(NSPoint)aPoint withGuardian:(id)aGuardian withObjectLink:(id)anObjectLink;
- (void) loadImages;
- (void) loadDefaults;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) lineColorChanged:(NSNotification*)aNotification;
- (void) lineTypeChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Accessors
- (BOOL) isConnected;
- (BOOL) hidden;
- (void) setHidden:(BOOL)state;
- (NSColor *) onColor;
- (void) setOnColor: (NSColor *) anOnColor;
- (NSColor *) offColor;
- (void) setOffColor: (NSColor *) anOffColor;
- (ORConnector*) connector;
- (id)          connectedObject;
- (id) 			guardian;
- (void) 		setGuardian: (id)aGuardian;
- (void) 		setSameGuardianIsOK: (BOOL)aFlag;
- (id) 			objectLink;
- (void) 		setObjectLink: (id)anObject;
- (NSColor*) 	lineColor;
- (void) 		setLineColor: (NSColor*)aColor;
- (int) 		lineType;
- (void) 		setLineType: (int)aType;
- (int)  		identifer;
- (void) 		setIdentifer:(int) anIdentifer;
- (NSRect) 		localFrame;
- (void) 		setLocalFrame: (NSRect)aRect;
- (NSImage*) 	onImage;
- (void) 		setOnImage: (NSImage*)anImage;
- (NSImage*) 	offImage;
- (void) 		setOffImage: (NSImage*)anImage;

- (uint32_t) 		ioType;
- (void) 		setIoType: (uint32_t)aType;

- (NSMutableArray*) restrictedList;
- (void) setRestrictedList:(NSMutableArray*)newRestrictedList;

- (int)			connectorImageType;
- (void) 		setConnectorImageType:(int) type;
- (uint32_t) connectorType;
- (void) 		setConnectorType:(uint32_t) type;
- (void)		addRestrictedConnectionType:(uint32_t)type;
- (NSRect)      lineBounds;
- (BOOL)		acceptsIoType:(uint32_t)aType;
- (BOOL)		acceptsIoType:(uint32_t)aType;

#pragma mark ¥¥¥Undoable Actions
- (void) 		setConnection: (ORConnector*)aConnection;

#pragma mark ¥¥¥drawing
- (NSPoint) 	centerPoint;
- (void) 		drawSelf: (NSRect)aRect;
- (void) 		drawSelf: (NSRect)aRect withTransparency: (float)aTransparency;
- (void) 		drawConnection: (NSRect)aRect;
- (void)		strokeLine:(NSBezierPath*) path;

#pragma mark ¥¥¥Events
- (BOOL) 		pointInRect: (NSPoint)aLocalPoint;
- (void) 		connectTo: (ORConnector*)aConnector;
- (void) 		disconnect;

@end

extern NSString* ORConnectionChanged;
