//
//  ORTimeSeries.h
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




#define kTimeSeriesBufferSize 4096

@interface ORTimeSeries : NSObject {
	unsigned long   time[kTimeSeriesBufferSize]; //seconds since 1/1/1970 (gmt)
	float			value[kTimeSeriesBufferSize];
	int writeIndex;
	int readIndex;
	int lastWriteIndex;
}

- (unsigned long) startTime;
- (NSUInteger) count;
- (void) addValue:(float)aValue atTime:(unsigned long)aTime;
- (void) index:(NSUInteger)index time:(unsigned long*)theTime value:(double*)y;
- (unsigned long) timeAtIndex:(NSUInteger)index;
- (float) valueAtIndex:(NSUInteger)index;
@end

extern NSString* ORTimeSeriesChangedNotification;


