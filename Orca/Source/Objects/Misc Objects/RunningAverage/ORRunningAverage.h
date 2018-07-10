//
//  ORRunningAverage.h
//  Orca
//
//  Created by Wenqin on 3/23/16.
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
#define kRASpikeOnThreshold  0
#define kRASpikeOnRatio      1

#define kRASpikeNoChange     0
#define kRASpiked            1
#define kRARecovered         2

@class ORRunningAveSpike;
@class ORRunningAverageGroup;

@interface ORRunningAverage : NSObject
{
    float           runningAverage;
    int             dataCount;
    float           spikeValue;
    float           averageAtTimeOfSpike;
    int             windowLength;
    int             tag;
    int             groupTag;
    BOOL            spikeState;
    BOOL            lastSpikeState;
}
- (id)      initWithTag:(short)aTag andLength:(short)wl;
- (void)    setWindowLength:(int) wl;
- (void)    resetCounter:(float) rate;
- (void)    reset;
- (float)   runningAverage;
- (float)   spikeValue;
- (int)     tag;
- (void)    setTag:(int)newTag;
- (int)     groupTag;
- (void)    setGroupTag:(int)newGroupTag;
- (void) calculateAverage:(float)dataPoint minSamples:(int)minSamples triggerValue:(float)triggerValue spikeType:(BOOL)triggerType group:(ORRunningAverageGroup*)aGroup;
- (BOOL) spiked;
- (float) averageAtTimeOfSpike;

- (ORRunningAveSpike*) spikedInfo:(BOOL)spiked;
@end




@interface NSObject (ORRunningAverage_Catagory)
- (unsigned long) getRate:(int)tag forGroup:(int)aGroupTag;
@end

@interface ORRunningAveSpike : NSObject
{
    BOOL    spiked;
    int     tag;
    float   ave;
    float   spikeValue;
}
@property (assign) BOOL     spiked;
@property (assign) int      tag;
@property (assign) float    ave;
@property (assign) float    spikeValue;

@end



