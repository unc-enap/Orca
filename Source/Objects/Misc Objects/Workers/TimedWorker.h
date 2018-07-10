//
//  TimedWorker.h
//  Orca
//
//  Created by Mark Howe on 1/13/05.
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





@interface TimedWorker : NSObject {
    BOOL            isRunning;
    float           timeInterval;
    id              target;
    SEL             _selector;
}
+ (id) TimeWorkerWithInterval:(NSTimeInterval)anInterval;
- (id) initWithInterval:(NSTimeInterval)anInterval;
- (void) dealloc;

- (void) runWithTarget:(id)aTarget selector:(SEL)aSelector;
- (void) stop;
- (BOOL) isRunning;
- (void) setIsRunning: (BOOL) flag;
- (float) timeInterval;
- (void) setTimeInterval: (NSTimeInterval) aTimeInterval;

- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* TimedWorkerTimeIntervalChangedNotification;
extern NSString* TimedWorkerIsRunningChangedNotification;
