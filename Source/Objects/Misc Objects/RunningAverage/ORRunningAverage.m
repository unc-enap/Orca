//
//  ORRunningAverage.m
//  Orca
//
//  Created by Wenqin on 3/23/16.
//
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

#import "ORRunningAverage.h"
#import "ORRunningAverageGroup.h"

@implementation ORRunningAverage

- (id) initWithTag: (short)aTag
         andLength: (short) wl
{
    self = [super init];
    [self setTag: aTag];
    [self setWindowLength:wl];
    dataCount = 0;
    return self;
}

- (int) tag
{
    return tag;
}

- (void) setTag:(int)newTag
{
    tag=newTag;
}

- (int) groupTag
{
    return groupTag;
} 

- (void) setGroupTag:(int)newGroupTag
{
    groupTag=newGroupTag;
}

- (void) setWindowLength:(int) wl
{
    windowLength = wl;
    [self reset];
}

- (void) resetCounter:(float) rate
{
    [self reset];
    runningAverage = rate;
}

- (void) reset
{
    dataCount       = 0;
    runningAverage  = 0.;
}

- (float) runningAverage
{
    return runningAverage;
}

- (float)   spikeValue
{
    return spikeValue;
}

- (void) calculateAverage:(float)dataPoint
               minSamples:(int)minSamples
             triggerValue:(float)triggerValue
                spikeType:(BOOL)triggerType
                    group:(ORRunningAverageGroup*)aGroup
{
    
    dataCount= dataCount+1;
    if(dataCount>windowLength)dataCount = windowLength;
    
    if(dataCount<=3){
        spikeState     = NO;
        lastSpikeState = NO;
        runningAverage = dataPoint;
        runningAverage = ((dataCount-1)*runningAverage + dataPoint)/(float)dataCount;
        return;
    }
    
    runningAverage = ((dataCount-1)*runningAverage + dataPoint)/(float)dataCount;

    spikeValue = 0;
    switch(triggerType){
        case kRASpikeOnRatio: //trigger on the ratio of the rate over the average
            if(runningAverage != 0) {
                float ratio = fabsf(dataPoint/runningAverage);
                if(ratio >= triggerValue){
                    if(!spikeState){
                        averageAtTimeOfSpike = runningAverage;
                        spikeValue           = dataPoint;
                    }
                    spikeState           = YES;
                }
                else {
                    //reset state if the new value is lower than the ave that triggered spike
                    if(ratio < averageAtTimeOfSpike){
                        if(spikeState)dataCount=0;
                        spikeState = NO;
                    }
                }
            }            
        break;
            
        case kRASpikeOnThreshold:
            {
                float diff =fabsf(dataPoint-runningAverage);
                if( diff > triggerValue){
                    if(!spikeState){
                        spikeValue = dataPoint;
                    }
                    spikeState = YES;
                }
                else {
                    if(diff < triggerValue){
                        if(spikeState)dataCount=0;
                        spikeState = NO;
                    }
                }
            }
        break;
            
        default:
        break;
    }
    
    if(lastSpikeState != spikeState){
        lastSpikeState = spikeState;
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[self spikedInfo:spikeState]forKey:@"SpikeObject"];
        [[NSNotificationCenter defaultCenter] postNotificationName: ORSpikeStateChangedNotification
                                                                object: aGroup
                                                              userInfo: userInfo];
    }
}

- (BOOL) spiked
{
    return spikeState;
}

- (float) averageAtTimeOfSpike
{
    return averageAtTimeOfSpike;
}

- (ORRunningAveSpike*) spikedInfo:(BOOL)spiked
{
    ORRunningAveSpike* aSpikeObj = [[ORRunningAveSpike alloc] init];
    aSpikeObj.spiked        = spiked;
    aSpikeObj.tag           = tag;
    aSpikeObj.ave           = runningAverage;
    aSpikeObj.spikeValue    = spikeValue;
    
    return [aSpikeObj autorelease];
}
@end

@implementation ORRunningAveSpike
@synthesize tag,spiked,ave,spikeValue;

- (NSString*) description
{
    NSString* s = [NSString stringWithFormat:@"\nspiked:%@\ntag:%d\nave:%.3f\nspikeValue:%.3f",
                   self.spiked?@"YES":@"NO",
                   self.tag,
                   self.ave,
                   self.spikeValue];
    return s;
}
@end

