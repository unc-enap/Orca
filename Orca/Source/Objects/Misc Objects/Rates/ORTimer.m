//
//  ORTimer.m
//  Orca
//
//  Created by Mark Howe on Mon Apr 26 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


@interface ORTimer (ORTimerPrivate)
- (double) _currentTime;
@end

@implementation ORTimer

+ (void) delayNanoseconds:(double)nanoSeconds
{
    static double  delayConstant;
    if(!nanoSeconds)return;
    if(!delayConstant){
        double calibrationTime = nanoSeconds*1000.;
        if(calibrationTime > 100000)calibrationTime = 100000;
        ORTimer* timer = [[ORTimer alloc] init];
        [timer start];
        delayConstant=0;
        do {
            ++delayConstant;
        }while([timer microseconds]<calibrationTime);
        [timer release];
        delayConstant/=1000;
    }
    else {
        int i;
        for(i=0;i<delayConstant;i++){;}
    }
}

+ (void) delay:(NSTimeInterval)seconds
{
    [NSThread sleepForTimeInterval:seconds];
	//NSTimeInterval t0 = [NSDate timeIntervalSinceReferenceDate];
	//while([NSDate timeIntervalSinceReferenceDate]-t0 < seconds);
}

// reset
- (void)reset
{
    started = [self _currentTime];
}


// starting and stoping
- (void)start
{
    if (isRunning) return;

    started = [self _currentTime];
    isRunning = YES;
}

- (void)stop
{
    if (! isRunning) return;

    time = [self _currentTime] - started;
    isRunning = NO;
}

// reporting time
- (double )microseconds
{
    if (isRunning){
        // report the current total, like -stop, without stoping
        return [self _currentTime] - started;       
    } else {
        // report the time recorded
        return time;
    }
}

- (double)seconds
{
    return [self microseconds] / 1000000.0;
}

// reporting elapsed time - from last start
- (double )microsecondsSinceStart
{
    if (isRunning){
        // report the time from the last start
        return [self _currentTime] - started;
    } else {
        // report the time recorded
        return time;
    }
}

- (double)secondsSinceStart
{
    return [self microsecondsSinceStart] / 1000000.0;
}

@end

@implementation ORTimer (ORTimerPrivate)

- (double) _currentTime
{
    struct timeval tp;
    gettimeofday(&tp, NULL);
    return (tp.tv_sec * 1000000. + tp.tv_usec);
}

@end
