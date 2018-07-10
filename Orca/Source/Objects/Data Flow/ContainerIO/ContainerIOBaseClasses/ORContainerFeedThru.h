//
//  ORContainerFeedThru.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 12, 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
@class ORDataPacket;
@class ORConnector;
@class ORMessagePipe;

@interface ORContainerFeedThru :  OrcaObject 
{
    short numberOfFeedThrus;
    int			 lineType;
    NSColor*	 lineColor;
	NSMutableArray* cachedProcessors;
	unsigned long cachedProcessorsCount;

	//this connectors we make, but do not display.
	//so we keep a separate list.
	NSMutableDictionary* remoteConnectors;
    NSArray* messagePipes;
}

#pragma mark ¥¥¥Initialization
- (void) dealloc;
- (void) setUpImage;
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian;
- (void) setGuardian:(id)aGuardian;
- (void) loadDefaults;
- (void) makeMainController;
- (NSMutableDictionary*) remoteConnectors;
- (void) setRemoteConnectors:(NSMutableDictionary*)aDict;

#pragma mark ¥¥¥Accessors
- (NSArray*) messagePipes;
- (void) setMessagePipes:(NSArray*)aMessagePipes;
- (short) numberOfFeedThrus;
- (void) setNumberOfFeedThrus:(short)newValue;
- (float) connectorXPlane;
- (float) remoteConnectorXPlane;
- (NSColor*) lineColor;
- (void) setLineColor:(NSColor*)aColor;
- (int) lineType;
- (void) setLineType:(int)aType;

#pragma mark ¥¥¥SubClass responsibility
- (NSString*) connectorKey:(int)i;
- (void) setUpMessagePipeLocal:(ORConnector*)localConnector remote:(ORConnector*)remoteConnector  pipe:(ORMessagePipe*)aPipe;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) lineColorChanged:(NSNotification*)aNotification;
- (void) lineTypeChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Drawing
- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency;
- (void) adjustNumberOfFeedThrus:(short)newValue;
- (BOOL) okToAdjustNumberOfFeedThrus:(short)newValue;
- (void) adjustFeedThruPositions;
- (void) adjustRemoteFeedThruPositions;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORContainerFeedThruChangedNotification;
