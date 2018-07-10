//
//  ORMotorPattern.m
//  Orca
//
//  Created by Mark Howe on 3/10/05.
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


#pragma mark ¥¥¥Imported Files
#import "ORMotorPattern.h"
#import "ORMotorSweeper.h"

//===============================================================
// ORMotorPattern
//===============================================================
@implementation ORMotorPattern

#pragma mark ¥¥¥Initialization
+ (id) motorPattern:(id)aMotor 
              start:(int)aStart 
                end:(int)anEnd 
              delta:(int)aDelta 
              dwell:(float)aDwellTime
         sweepsToDo:(int)numSweeps
             raster:(int)doRaster

{
    return [[[ORMotorPattern alloc]initWithMotor:aMotor 
                                           start:aStart 
                                             end:anEnd 
                                           delta:aDelta 
                                           dwell:aDwellTime
                                      sweepsToDo:numSweeps
                                          raster:doRaster] autorelease];
}

+ (id) motorPattern:(id)aMotor 
          positions:(NSArray*)aPositionArray
             dwells:(NSArray*)aDwellArray
         sweepsToDo:(int)numSweeps
{
    return [[[ORMotorPattern alloc]initWithMotor:aMotor 
                                       positions:aPositionArray 
                                          dwells:aDwellArray 
                                      sweepsToDo:numSweeps] autorelease];
}



- (id) initWithMotor:(id)aMotor 
               start:(int)aStart 
                 end:(int)anEnd 
               delta:(int)aDelta 
               dwell:(float)aDwellTime
          sweepsToDo:(int)numSweeps
              raster:(int)doRaster
{
    self = [super init];
    start = aStart;
    end = anEnd;
    dwell = aDwellTime;
    delta = aDelta;
    
    [self setMotor:aMotor];
    
    sweepsToDo = numSweeps;
    arrayMode = NO;
    raster = doRaster;
    
    [self setSweeper:[ORMotorSweeper motorSweeper:[self motor] 
                                            start:aStart 
                                              end:anEnd 
                                            delta:aDelta 
                                            dwell:aDwellTime]];  
    return self;
}

- (id) initWithMotor:(id)aMotor 
           positions:(NSArray*)aPositionArray
              dwells:(NSArray*)aDwellArray
          sweepsToDo:(int)numSweeps
{
    
    self = [super init];
    sweepsToDo = numSweeps;
    arrayMode = YES;
    
    [self setMotor:aMotor];
    [self setSweeper:[ORMotorSweeper motorSweeper:[self motor] 
                                        positions:aPositionArray 
                                           dwells:aDwellArray]];
    
    return self;
}


- (void) dealloc
{
    [sweeper release];
    [super dealloc];
}

#pragma mark ¥¥¥Accessors

- (id) sweeper
{
    return sweeper;
}

- (void) setSweeper:(id)aSweeper
{
    [aSweeper retain];
    [sweeper release];
    sweeper = aSweeper;
}

- (id) motor
{
    return motor;
}

- (void) setMotor:(id)aMotor
{
    //don't retain the Motor
    motor = aMotor;
}

- (void) shipMotorState:(id)aWorker
{
    [motor shipMotorState:aWorker];
}

#pragma mark ¥¥¥Hardware Access
- (long) readMotor;
{
    return [motor readMotor];
}

- (BOOL) motorRunning
{
    return [motor motorRunning];
}

- (void) moveMotor:(id)aMotor amount:(long)amount;
{
    [motor moveMotor:motor amount:amount];
}

- (void) moveMotor:(id)aMotor to:(long)aPosition;
{
    [motor moveMotor:motor to:aPosition];
}

- (void) setInhibited:(BOOL)aFlag
{
    [sweeper setInhibited:aFlag];
}

#pragma mark ¥¥¥State Actions
- (void) startWork
{
    workCanceled = NO;
    [sweeper startWork];
}

- (void) stopWork
{
    workCanceled = YES;
    [sweeper stopWork];
    
}

- (void) finishedStep
{
    [motor finishedStep];
}

- (void) finishedWork
{
    ++count;
    if(!workCanceled && count < sweepsToDo) {
        if(!raster && !arrayMode){
            int temp = start;
            start = end;
            end = temp;
            delta *= -1;
            [self setSweeper:[ORMotorSweeper motorSweeper:[self motor] 
                                                    start:start 
                                                      end:end 
                                                    delta:delta 
                                                    dwell:dwell]];
            
        }
        [self startWork]; //begin again
    }
    else {
        [motor finishedWork];
    }
}
@end