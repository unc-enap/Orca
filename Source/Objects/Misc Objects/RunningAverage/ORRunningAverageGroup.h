//
//  ORRunningAverageGroup
//  Orca
//
//  Created by Wenqin on 5/16/16.
//
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
#import "ORRunningAverage.h"

@class ORRunningAverage;

@interface ORRunningAverageGroup : NSObject {
    id              objectKeepingRate;
    int             pollTime;
    BOOL            verbose;
    NSMutableArray* runningAverages;
    int             windowLength;
    int             tag;
    int             groupSize;
    float           triggerValue;
    int             triggerType;
}
#pragma mark •••Initialization
- (id)   initGroup:(int)numberInGroup groupTag:(int)aGroupTag withLength:(int)wl;
- (void) start:(id)obj pollTime:(int)aTime;
- (void) stop;

#pragma mark •••Accessors
- (id)          runningAverageObject:(short)index;
- (NSArray*)    runningAverages;
- (NSArray*)    getRunningAverageValues; //float array
- (void)        setRunningAverages:(NSMutableArray*)newRAs;
- (void)        updateWindowLength:(int)newWindowLength;
- (void)        setWindowLength:(int)newWindowLength;
- (int)         windowLength;
- (void)        resetCounters:(float)rate;
- (void)        reset;
- (void)        addValuesUsingTimer;
- (void)        addNewValue:(float)aValue toIndex:(int)i;
- (int)         tag;
- (void)        setTag:(int)newTag;
- (int)         groupSize;
- (void)        setGroupSize:(int)a;
- (void)        setVerbose:(BOOL)b;
- (float)       getRunningAverageValue:(short)idx;
- (void)        setTriggerType: (int)aType;
- (int)         triggerType;
- (void)        setTriggerValue:(float)a;
- (float)       triggerValue;
- (int)         pollTime;
- (void)        setPollTime:(int)aValue;
@end

extern NSString* ORRunningAverageChangedNotification;
extern NSString* ORSpikeStateChangedNotification;

@interface NSObject (ORRunningAverageGroup_Catagory)
- (float) getRate:(int)aChannel;
@end




