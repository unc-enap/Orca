//
//  ORTimeRate.h
//  Orca
//
//  Created by Mark Howe on Tue Sep 09 2003.
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




#define kTimeAverageBufferSize 4096
#define kAverageStackSize 512

@class ORAlarm;


@interface ORTimeRate : NSObject {
	
	double averageStack[kAverageStackSize];
	double timeAverage[kTimeAverageBufferSize];
	NSTimeInterval timeSampled[kTimeAverageBufferSize];
	int timeAverageWrite;
	int timeAverageRead;
	NSUInteger averageStackCount;
	NSDate* lastAverageTime;
	uint32_t sampleTime;
}


- (NSDate*) lastAverageTime;
- (void) setLastAverageTime:(NSDate*)newLastAverageTime;
- (uint32_t) sampleTime;
- (void) setSampleTime:(uint32_t)newSampleTime;
- (NSUInteger) count;
- (double)valueAtIndex:(NSUInteger)index;
- (NSTimeInterval)timeSampledAtIndex:(NSUInteger)index;
- (NSArray*) ratesAsArray;


- (void) addDataToTimeAverage:(float)aValue;

@end

extern NSString* ORRateAverageChangedNotification;


@interface ORHighRateChecker : NSObject {
    NSString*       name;
    NSTimeInterval  timeFrame;
    NSDate*         highRateStartTime;
    float           maxValue;
    float           sum;
    ORAlarm*        highRateAlarm;
    int             count;
}
- (id) init:(NSString*)aName timeFrame:(float)aTimeFrame;
- (void) dealloc;
- (void) checkRate:(float)aValue;
- (void) reset;

@property (copy)   NSString*        name;
@property (retain) NSDate*          highRateStartTime;
@property (assign) NSTimeInterval   timeFrame;
@property (assign) float            sum;
@property (assign) float            maxValue;

@end
