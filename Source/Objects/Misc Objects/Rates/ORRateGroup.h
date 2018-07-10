//
//  ORRateGroup.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 06 2003.
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


#pragma mark •••Imported Files

@class ORTimeRate;

@interface ORRateGroup : NSObject <NSCoding> {
	NSMutableArray* rates;
	double integrationTime;
	int tag;
	
	//non-persistant variables
	id objectKeepingCount;
	double   totalRate;
	ORTimeRate* timeRate;
}
#pragma mark •••Initialization
- (id) initGroup:(int)numberInGroup groupTag:(int)aGroupTag;

#pragma mark •••Accessors
- (id) rateObject:(int)index;
- (NSArray*) rates;
- (void) setRates:(NSMutableArray*)newRates;
- (double) integrationTime;
- (void) setIntegrationTime:(double)newIntegrationTime;
- (double) totalRate;
- (void) setTotalRate:(double)newTotalRate;
- (NSUInteger) tag;
- (void) setTag:(int)newTag;
- (ORTimeRate*) timeRate;
- (void) setTimeRate:(ORTimeRate*)newTimeRate;


- (void) start:(id)obj;
- (void) quit;
- (void) stop;
- (void) calcRates;
- (void) resetRates;
- (void) collectTimeRate;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;


@end

extern NSString* ORRateGroupIntegrationChangedNotification;
extern NSString* ORRateGroupTotalRateChangedNotification;

