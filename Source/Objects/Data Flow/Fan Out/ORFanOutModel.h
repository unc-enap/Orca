//
//  ORFanOutModel.h
//  Orca
//
//  Created by Mark Howe on Wed Jan 1 2003.
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
@class ORDecoder;

@interface ORFanOutModel :  OrcaObject 
{
    short numberOfOutputs;
    int			 lineType;
    NSColor*	 lineColor;
	NSMutableArray* cachedProcessors;
	NSUInteger cachedProcessorsCount;
}

#pragma mark ¥¥¥Initialization
- (void) loadDefaults;
- (void) makeConnectors;
- (void) adjustNumberOfOutputs:(short)aValue;
- (BOOL) okToAdjustNumberOfOutputs:(short)newValue;

#pragma mark ¥¥¥Accessors
- (short) 		numberOfOutputs;
- (void) 		setNumberOfOutputs:(short)aValue;
- (NSColor*) 	lineColor;
- (void) 		setLineColor: (NSColor*)aColor;
- (int) 		lineType;
- (void) 		setLineType: (int)aType;

//used with caching to speed up the data processing.
- (void) runTaskStarted:(NSDictionary*)userInfo;
- (void) runTaskStopped:(NSDictionary*)userInfo;
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
- (void) preCloseOut:(NSDictionary*)userInfo;
- (void) closeOutRun:(NSDictionary*)userInfo;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) lineColorChanged:(NSNotification*)aNotification;
- (void) lineTypeChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Forwarding
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
- (void) forwardInvocation:(NSInvocation *)invocation;
- (void) messageDump;
@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORFanOutChangedNotification;


