//
//  ORDataSetModel.h
//  Orca
//
//  Created by Mark Howe on Mon Sep 29 2003.
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


@interface ORDataSetModel : OrcaObject {
    NSString*		key;
    NSString*		fullName;
    NSString*		shortName;
    uint32_t   totalCounts;
    
    BOOL			scheduledForUpdate;
	NSLock*			dataSetLock;
	id				dataSet;
	id				calibration;
    int				refreshMode;
    BOOL			paused;
}

#pragma mark ¥¥¥Accessors
- (BOOL) paused;
- (void) setPaused:(BOOL)aPaused;
- (int) refreshMode;
- (void) setRefreshMode:(int)aRefreshMode;
- (void) setDataSet:(id)aDataSet;
- (id) dataSet;
- (id) calibration;
- (void) setCalibration:(id)aCalibration;
- (void) setKey:(NSString*)akey;
- (NSString*)key;
- (void) setFullName:(NSString*)aString;
- (NSString*) fullName;
- (NSString*) shortName;
- (NSString*)name;
- (uint32_t) totalCounts;
- (void) setTotalCounts:(uint32_t)aNewTotalCounts;
- (void) incrementTotalCounts;
- (void) postUpdateOnMainThread;
- (void) scheduleUpdateOnMainThread;
- (void) postUpdate;
- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo keys:(NSMutableArray*)aKeyArray;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (BOOL) canJoinMultiPlot;
- (void) runTaskStopped;
- (void) runTaskBoundary;
- (void) processResponse:(NSDictionary*)aResponse;
- (NSString*) runNumberString;
- (NSString*) fullNameWithRunNumber;
- (float) refreshRate;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ¥¥¥Data Source Methods
- (NSUInteger)  numberOfChildren;
- (id)   childAtIndex:(NSUInteger)index;
- (NSString*)   name;

@end


@interface NSObject (ORDatasSetModel_Cat)
- (void)  clear;
- (void)  runTaskStopped;
- (int32_t)  runNumber;
@end


extern NSString* ORDataSetModelPausedChanged;
extern NSString* ORDataSetModelRefreshModeChanged;
extern NSString* ORDataSetDataChanged;
extern NSString* ORDataSetCalibrationChanged;

