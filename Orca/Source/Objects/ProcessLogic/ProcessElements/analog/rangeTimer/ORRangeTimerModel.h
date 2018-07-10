//
//  ORRangeTimerModel.h
//  Orca
//
//  Created by Mark Howe on Fri Sept 8, 2006.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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



#import "ORProcessHWAccessor.h"

@interface ORRangeTimerModel : ORProcessHWAccessor {
	@private
		double hwValue;
		int deadband;
		float limit;
		int direction;
		BOOL lastOutOfBounds;
		BOOL timing;
		BOOL firstTime;
		BOOL sentMessage;
		NSDate* deadTimeStart;
		NSDate* startTime;
		BOOL enableMail;
		NSMutableArray* eMailList;
}
- (void) dealloc;
- (void) viewSource;

#pragma mark ¥¥¥Accessors
- (NSMutableArray*) eMailList;
- (void) addAddress;
- (void) removeAddressAtIndex:(int) anIndex;
- (void) setEMailList:(NSMutableArray*)aEMailList;
- (id)   addressEntry:(NSUInteger)index;
- (BOOL) enableMail;
- (void) setEnableMail:(BOOL)aEnableMail;
- (int)	  direction;
- (void)  setDirection:(int)aDirection;
- (float) limit;
- (void)  setLimit:(float)aLimit;
- (int)   deadband;
- (void)  setDeadband:(int)aDeadband;
- (void) setDeadTimeStart:(NSDate*)aDate;
- (BOOL) isTrueEndNode;
- (NSUInteger) addressCount;

#pragma mark ¥¥¥Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORRangeTimerModelAddressesChanged;
extern NSString* ORRangeTimerModelEnableMailChanged;
extern NSString* ORRangeTimerModelDirectionChanged;
extern NSString* ORRangeTimerModelLimitChanged;
extern NSString* ORRangeTimerModelDeadbandChanged;

