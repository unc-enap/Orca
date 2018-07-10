//
//  ORAdcModel.h
//  Orca
//
//  Created by Mark Howe on 11/25/05.
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
#import "ORProcessNub.h"

@class ORAdcLowLimitNub;
@class ORAdcHighLimitNub;

@interface ORAdcModel : ORProcessHWAccessor {
	double hwValue;
	double maxValue;
	double minValue;
	double lowLimit;
	double highLimit;
	BOOL valueTooLow;
	BOOL valueTooHigh;
	ORAdcLowLimitNub*  lowLimitNub;
	ORAdcHighLimitNub* highLimitNub;
    float minChange;
	NSGradient* normalGradient;
	NSGradient* alarmGradient;
    NSString* lowText;
    NSString* inRangeText;
    NSString* highText;
	
	NSDate* resetDate;
	NSDate* highDate;
	NSDate* lowDate;
	double  highestValue;
	double	lowestValue;
    BOOL	trackMaxMin;
    NSString* lastValue;
}
@property (retain) NSString* lastValue;

#pragma mark ***Accessors
- (BOOL) trackMaxMin;
- (void) setTrackMaxMin:(BOOL)aTrackMaxMin;
- (NSString*) highText;
- (void) setHighText:(NSString*)aHighText;
- (NSString*) inRangeText;
- (void) setInRangeText:(NSString*)aInRangeText;
- (NSString*) lowText;
- (void) setLowText:(NSString*)aLowText;
- (void) dealloc;
- (NSString*) report;

- (float) minChange;
- (void) setMinChange:(float)aMinChange;

- (BOOL) valueTooLow;
- (BOOL) valueTooHigh;
- (double) lowLimit;
- (double) highLimit;
- (double) hwValue;
- (double) maxValue;
- (void) viewSource;

- (void) checkMaxMinValues;
- (void) resetReportValues;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


extern NSString* ORAdcModelTrackMaxMinChanged;
extern NSString* ORAdcModelHighTextChanged;
extern NSString* ORAdcModelInRangeTextChanged;
extern NSString* ORAdcModelLowTextChanged;
extern NSString* ORAdcModelMinChangeChanged;
extern NSString* ORAdcModelOutOfRangeLow;
extern NSString* ORAdcModelOutOfRangeHi;

@interface ORAdcLowLimitNub : ORProcessNub
- (id) eval;
- (int) evaluatedState;
@end

@interface ORAdcHighLimitNub : ORProcessNub
- (id) eval;
- (int) evaluatedState;
@end

@interface NSObject (ORAdcModel)
-(BOOL) dataForChannelValid:(int)aChannel;
@end
