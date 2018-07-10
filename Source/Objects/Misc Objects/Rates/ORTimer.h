//
//  ORTimer.h
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

@interface ORTimer : NSObject 
{
    double time;
    double started;
    BOOL isRunning;
}
+ (void) delayNanoseconds:(double)nanoSeconds;
+ (void) delay:(NSTimeInterval)seconds;

// reset
- (void)reset;

// starting and stoping
- (void)start;
- (void)stop;

// reporting total time
- (double)microseconds;
- (double)seconds;

// reporting elapsed time - from last start
- (double)microsecondsSinceStart;
- (double)secondsSinceStart;
@end
