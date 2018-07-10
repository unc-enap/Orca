//
//  ORRamperModel.h
//  ORRamperModel
//
//  Created by Mark Howe on 3/29/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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


#import <Cocoa/Cocoa.h>

@class ORWayPoint;
@class ORReadOutList;
@class ORRampItem;

@interface ORRamperModel : OrcaObject {
	NSMutableArray* rampItems;
	ORRampItem* selectedRampItem;
	NSMutableArray* rampingItems;
	NSMutableSet* loadableObjects;
	NSMutableSet* loadSet;
	NSTimer*      incTimer;
}

#pragma mark •••Initialization
- (void) ensureMinimumNumberOfRampItems;

#pragma mark •••Accessors
- (NSString*) lockName;
- (NSMutableArray*) wayPoints;
- (float) rampTarget;
- (NSMutableArray*) rampItems;
- (void) setRampItems:(NSMutableArray*)anItem;
- (void) addRampItem:(ORRampItem*)anItem afterItem:(ORRampItem*)anotherItem;
- (void) removeRampItem:(ORRampItem*)anItem;
- (ORRampItem*) selectedRampItem;
- (void) setSelectedRampItem:(ORRampItem*)anItem;
- (void) addRampItem;

#pragma mark •••Ramping
- (int) enabledCount;
- (int) runningCount;
- (void) startRamping:(ORRampItem*)anItem;
- (void) incTime;
- (void) stopRamping:(ORRampItem*)anItem turnOff:(BOOL)turnOFF;
- (void) startGlobalRamp;
- (void) stopGlobalRamp;
- (void) startGlobalPanic;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORRamperObjectListLock;
extern NSString* ORRamperItemAdded;
extern NSString* ORRamperItemRemoved;
extern NSString* ORRamperSelectionChanged;
extern NSString* ORRamperNeedsUpdate;


