//
//  HaloModel.h
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
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
#import "ORExperimentModel.h"

#define kUseTubeView 0
#define kUseCrateView 1
#define kNumTubes	 128
#define kNumTestTubes 4

@class HaloSentry;

@interface HaloModel :  ORExperimentModel
{
	int             viewType;
    HaloSentry*     haloSentry;
    NSMutableArray* emailList;
    int             heartBeatIndex;
	NSDate*         nextHeartbeat;
}

//- (NSMutableArray*) setupMapEntries:(int)index;

#pragma mark ¥¥¥Accessors
- (HaloSentry*) haloSentry;
- (void) setHaloSentry:(HaloSentry*)aHaloSentry;
- (void) setViewType:(int)aViewType;
- (int) viewType;
- (BOOL) sentryIsRunning;
- (void) takeOverRunning;
- (NSMutableArray*) emailList;
- (void) setEmailList:(NSMutableArray*)aEmailList;
- (void) addAddress:(id)anAddress atIndex:(int)anIndex;
- (void) removeAddressAtIndex:(int) anIndex;
- (int) heartBeatIndex;
- (void) setHeartBeatIndex:(int)aHeartBeatIndex;
- (int) heartbeatSeconds;
- (void) sendHeartbeat;
- (void) setNextHeartbeatString;
- (NSDate*) nextHeartbeat;

#pragma mark ¥¥¥EMail
- (void) mailSent:(NSString*)address;
- (void) sendMail:(NSDictionary*)userInfo;
- (NSString*) cleanupAddresses:(NSArray*)aListOfAddresses;

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups;

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock;
- (NSString*) experimentDetectorLock;
- (NSString*) secondaryMapLock;
- (NSString*) experimentDetailsLock;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


extern NSString* HaloModelHaloSentryChanged;
extern NSString* HaloModelViewTypeChanged;
extern NSString* HaloModelSentryLock;
extern NSString* HaloModelEmailListChanged;
extern NSString* HaloModelNextHeartBeatChanged;

