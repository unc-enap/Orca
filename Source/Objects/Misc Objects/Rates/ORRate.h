//
//  ORRate.h
//  Orca
//
//  Created by Mark Howe on Tue Aug 05 2003.
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

@interface ORRate : NSObject {
	int tag;
	int groupTag;
	NSDate* lastTime;
	unsigned long lastCount;
	float rate;
	ORTimeRate* timeRate;
}

#pragma mark •••Inialization
- (id) initWithTag:(int)aTag;
- (void) 	dealloc;


#pragma mark •••Accessors
- (NSString*) rateNotification;
- (NSDate*) lastTime;
- (void) setLastTime:(NSDate*)newLastTime;
- (int) tag;
- (void) setTag:(int)newTag;
- (float) rate:(int)paramIgnored;
- (float) rate;
- (void) setRate:(float)newRate;
- (int) groupTag;
- (void) setGroupTag:(int)newGroupTag;

- (ORTimeRate*) timeRate;
- (void) setTimeRate:(ORTimeRate*)newTimeRate;

#pragma mark •••Calculations
- (void) reset;
- (void) calcRate:(id)obj;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end


extern NSString* ORRateChangedNotification;
extern NSString* ORRateTag;
extern NSString* ORRateValue;


@interface NSObject (ORRate_Catagory)
- (unsigned long) getCounter:(int)tag forGroup:(int)aGroupTag;
@end
