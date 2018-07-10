//
//  ORMotorSweeper.m
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
#import "ORMotorSweeper.h"
#import "ORMotorModel.h"

//===============================================================
// Sweep States (private)
//===============================================================
@interface MotorStartSweepState (private)
- (void) startWork;
- (void) stopWork;
- (void) doWork;
@end
@interface MotorMovingToStartSweepState (private)
- (void) startWork;
- (void) stopWork;
- (void) doWork;
@end
@interface MotorAdvancingSweepState (private)
- (void) startWork;
- (void) stopWork;
- (void) doWork;
@end
@interface MotorDwellSweepState (private)
- (void) startWork;
- (void) stopWork;
- (void) doWork;
@end
@interface MotorStepDoneState (private)
- (void) startWork;
- (void) stopWork;
- (void) doWork;
@end
@interface MotorEndSweepState (private)
- (void) startWork;
- (void) stopWork;
- (void) doWork;
@end

@interface ORMotorSweeper (private)
- (void)setSweepState:(id)aSweepState;
@end

//===============================================================
// ORMotorSweeper
//===============================================================
@implementation ORMotorSweeper

#pragma mark ¥¥¥Initialization
+ (id) motorSweeper:(id)aMotor start:(int)aStart end:(int)anEnd delta:(int)aDelta dwell:(float)aDwellTime
{
    return [[[ORMotorSweeper alloc]initWithMotor:aMotor start:aStart end:anEnd delta:aDelta dwell:aDwellTime] autorelease];
}

+ (id) motorSweeper:(id)aMotor positions:(NSArray*)aPositionArray dwells:(NSArray*)aDwellArray
{
    return [[[ORMotorSweeper alloc]initWithMotor:aMotor positions:aPositionArray dwells:aDwellArray] autorelease];
}

- (id) init 
{
    self = [super init];
    
    atStartSweepState        = [[MotorStartSweepState alloc] initWithWorker:self];
    atEndSweepState          = [[MotorEndSweepState alloc] initWithWorker:self];
    dwellSweepState          = [[MotorDwellSweepState alloc] initWithWorker:self];
    stepDoneState            = [[MotorStepDoneState alloc] initWithWorker:self];
    motorAdvancingSweepState = [[MotorAdvancingSweepState alloc] initWithWorker:self];
    movingToStartSweepState  = [[MotorMovingToStartSweepState alloc] initWithWorker:self];
    
    sweepState = atStartSweepState;
    
    return self;
}
- (id) initWithMotor:(id)aMotor positions:(NSArray*)aPositionArray dwells:(NSArray*)aDwellArray
{
    self = [self init];
    
    [self setMotor:aMotor];
    [self setPositionArray:aPositionArray];
    [self setDwellArray:aDwellArray];
    
    return self;
}

- (id) initWithMotor:(id)aMotor start:(int)aStart end:(int)anEnd delta:(int)aDelta dwell:(float)aDwellTime
{
    self = [self init];
    
    [self setMotor:aMotor];
    
    start = aStart;
    end   = anEnd;
    delta = aDelta;
    if(delta==0)delta = 1;
    numSteps = abs((end-start)/delta);
    dwell = aDwellTime;  
    
    return self;
}

- (void) dealloc
{
    [positionArray release];
    [dwellArray release];
    [loopTimer invalidate];
    [loopTimer release];
    
    motor = nil;
    
    [atStartSweepState release];
    [atEndSweepState release]; 
    [motorAdvancingSweepState release]; 
    [dwellSweepState release]; 
    [stepDoneState release]; 
    [movingToStartSweepState release];
    [super dealloc];
}

#pragma mark ¥¥¥Accessors
- (BOOL) inhibited
{
    return inhibited;
}

- (void) setInhibited:(BOOL)aFlag
{
    inhibited = aFlag;
}

- (void) finishedStep
{
   [motor finishedStep];
}

- (float) dwell
{
    if(dwellArray){
        if(stepIndex > [dwellArray count])return [[dwellArray lastObject]floatValue];
        else return [[dwellArray objectAtIndex:stepIndex] floatValue];
    }
    else return dwell;
}

- (int) numSteps
{
    if(positionArray){
        return [positionArray count];
    }
    else  return numSteps;
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


//=========================================================== 
//  sweepState 
//=========================================================== 
- (id)sweepState
{
    return sweepState; 
}
- (void)setSweepState:(id)aSweepState
{
    sweepState = aSweepState;
}

//=========================================================== 
//  atstartWorkSweepState 
//=========================================================== 
- (id)atStartSweepState
{
    return atStartSweepState; 
}
- (void)setAtStartSweepState:(id)aSweepState
{
    [aSweepState retain];
    [atStartSweepState release];
    atStartSweepState = aSweepState;
}

//=========================================================== 
//  atEndSweepState 
//=========================================================== 
- (id)atEndSweepState
{
    return atEndSweepState; 
}
- (void)setAtEndSweepState:(id)aSweepState
{
    [aSweepState retain];
    [atEndSweepState release];
    atEndSweepState = aSweepState;
}

//=========================================================== 
//  motorAdvancingSweepState
//=========================================================== 
- (id)motorAdvancingSweepState
{
    return motorAdvancingSweepState; 
}
- (void)setMotorAdvancingSweepState:(id)aState
{
    [aState retain];
    [motorAdvancingSweepState release];
    motorAdvancingSweepState = aState;
}
//=========================================================== 
//  dwellSweepState 
//=========================================================== 
- (id)dwellSweepState
{
    return dwellSweepState; 
}
- (void)setDwellSweepState:(id)aState
{
    [aState retain];
    [dwellSweepState release];
    dwellSweepState = aState;
}

//=========================================================== 
//  stepDoneState 
//=========================================================== 
- (id)stepDoneState
{
    return stepDoneState; 
}
- (void)setStepDoneState:(id)aState
{
    [aState retain];
    [stepDoneState release];
    stepDoneState = aState;
}

//=========================================================== 
//  movingToStartSweepState 
//=========================================================== 
- (id)movingToStartSweepState
{
    return movingToStartSweepState; 
}
- (void)setMovingToStartSweepState:(id)aState
{
    [aState retain];
    [movingToStartSweepState release];
    movingToStartSweepState = aState;
}
//=========================================================== 
//  positionArray 
//=========================================================== 
- (NSArray *)positionArray
{
    return positionArray; 
}
- (void)setPositionArray:(NSArray *)aPositionArray
{
    [aPositionArray retain];
    [positionArray release];
    positionArray = aPositionArray;
}

//=========================================================== 
//  deltaArray 
//=========================================================== 
- (NSArray *)dwellArray
{
    return dwellArray; 
}
- (void)setDwellArray:(NSArray *)aDwellArray
{
    [aDwellArray retain];
    [dwellArray release];
    dwellArray = aDwellArray;
}

#pragma mark ¥¥¥hardware access
- (BOOL) motorAtStartPosition
{
    return start == [self motorPosition];
}
- (BOOL) motorAtEndPosition
{
    return end == [self motorPosition];
}

- (long) motorPosition
{
    return [motor readMotor];
}

- (void) moveDeltaSteps
{
    long aValue;
    if(positionArray){
        stepIndex++;
        if(stepIndex<[positionArray count]){
            aValue = [[positionArray objectAtIndex:stepIndex] longValue];
            [motor moveMotor:motor to:aValue];
        }
    }
    else {
        aValue = delta;
        [motor moveMotor:motor amount:aValue];
    }
}

- (void) moveToStart
{
    long startValue;
    if(positionArray){
        startValue = [[positionArray objectAtIndex:stepIndex] floatValue];
        stepIndex = 0;
    }
    else startValue = start;
    
    [motor moveMotor:motor to:startValue];
}

- (BOOL) motorRunning
{
    return [motor motorRunning];
}

#pragma mark ¥¥¥SweepState Actions
- (void) startWork	
{
    stepIndex = 0;
    [sweepState startWork];
    [loopTimer invalidate];
    [loopTimer release];
    loopTimer = [[NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(doWork) userInfo:nil repeats:YES] retain];
}

- (void) stopWork
{
    [loopTimer invalidate];
    [loopTimer release];
    loopTimer = nil;
    [sweepState stopWork];
}

- (void) pauseWork
{
    [loopTimer invalidate];
    [loopTimer release];
    loopTimer = nil;
}

- (void) continueWork
{
    [loopTimer invalidate];
    [loopTimer release];
    loopTimer = [[NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(doWork) userInfo:nil repeats:YES] retain];
}

- (void) doWork	
{
    [sweepState doWork];
}

- (void) finishedWork
{
    stepIndex = 0;
    [loopTimer invalidate];
    [loopTimer release];
    loopTimer = nil;
    [motor finishedWork];
}

- (void) shipMotorState
{
    [motor shipMotorState:self];
}

- (int) stateId
{
    return [sweepState stateId];
}

@end

@implementation MotorSweepState
- (id) initWithWorker:(id) aWorker
{
    self = [super init];
    worker = aWorker;
    return self;
}

- (void) dealloc
{
    worker = nil;
    [super dealloc];
}

- (NSString*) name
{
    return @"?";
}

- (void) shipSweepState
{
    [worker shipMotorState];
}


#pragma mark ¥¥¥SweepState Actions
- (void) startWork { NSLog(@"Program Error---subclass must override startWork\n"); }
- (void) stopWork  { NSLog(@"Program Error---subclass must override stopWork\n"); }
- (void) doWork    { NSLog(@"Program Error---subclass must override doWork\n"); }
- (int) stateId    {return 0;}
@end

//=========================================================
// MotorStartSweepState
//=========================================================
@implementation MotorStartSweepState
- (id) initWithWorker:(id) aWorker
{
    self = [super initWithWorker:aWorker];
    return self;
}

- (NSString*) name {return @"Starting";}
- (int) stateId { return 0; }

- (void) startWork 
{
    if([worker motorAtStartPosition]){
        [self shipSweepState];
        [worker moveDeltaSteps];
        [worker setSweepState:[worker motorAdvancingSweepState]];
    }
    else {
        [worker moveToStart];
        [worker setSweepState:[worker movingToStartSweepState]];
    }
}

- (void) stopWork  
{
    [worker moveToStart];
    [worker setSweepState:[worker atEndSweepState]];
}

- (void) doWork  {;}
@end

//=========================================================
// MotorMovingToStartSweepState
//=========================================================
@implementation MotorMovingToStartSweepState
- (id) initWithWorker:(id) aWorker
{
    self = [super initWithWorker:aWorker];
    return self;
}
- (NSString*) name { return @"Starting"; }
- (int) stateId    { return 1; }

- (void) startWork { [worker moveToStart]; }

- (void) stopWork  
{
    //[worker moveToStart];
    [worker setSweepState:[worker atEndSweepState]];
}

- (void) doWork  
{ 
    if(![worker motorRunning]){
        if([worker motorAtStartPosition]){
            [self shipSweepState];
            [worker moveDeltaSteps];
            [worker setSweepState:[worker motorAdvancingSweepState]];
        }
        else {
            //this would be an error
        }
        
    }
}
@end

//=========================================================
// MotorAdvancingSweepState
//=========================================================
@implementation MotorAdvancingSweepState
- (id) initWithWorker:(id) aWorker
{
    self = [super initWithWorker:aWorker];
    return self;
}
- (NSString*) name { return @"Moving"; }
- (int) stateId    { return 2; }

- (void) startWork 
{
    count = 0;
    [worker moveToStart];
    [worker setSweepState:[worker movingToStartSweepState]];
}

- (void) stopWork  
{

    [worker moveToStart];
    [worker setSweepState:[worker atEndSweepState]];
}

- (void) doWork  
{ 
    if(![worker motorRunning]){
        ++count;
        if(count >= [worker numSteps]){
            count = 0;
            [worker setSweepState:[worker atEndSweepState]];
        }
        else {
            if([worker dwell] > 0){
                [worker setSweepState:[worker dwellSweepState]];
            }
            else {
                [worker moveDeltaSteps];
            }
        }
    }
}
@end

//=========================================================
// MotorDwellSweepState
//=========================================================
@implementation MotorDwellSweepState
- (id) initWithWorker:(id) aWorker
{
    self = [super initWithWorker:aWorker];
    return self;
}
- (void) dealloc
{
    [dwellTimer stop];
    [dwellTimer release];
    dwellTimer = nil;
    [super dealloc];
}

- (NSString*) name { return @"Dwelling"; }
- (int) stateId    { return 3; }

- (void) startWork 
{
    [worker moveToStart];
    [worker setSweepState:[worker movingToStartSweepState]];
}

- (void) stopWork  
{
    [worker moveToStart];
    [worker setSweepState:[worker atEndSweepState]];
}

- (void) doWork  
{ 
    if(![worker motorRunning]){
        if(!dwellTimer){
            dwellTimer = [[[ORTimer alloc] init] retain];
            [dwellTimer start];
            [self shipSweepState];
        }
        if([dwellTimer seconds]>=[worker dwell]){
            [self shipSweepState];
            [dwellTimer stop];
            [dwellTimer release];
            dwellTimer = nil;
            [worker finishedStep];
            [worker setSweepState:[worker stepDoneState]];
        }
        
    }
    else {
        //shouldn't happen handle error
    }
}
@end

//=========================================================
// MotorStepDoneState
//=========================================================
@implementation MotorStepDoneState
- (id) initWithWorker:(id) aWorker
{
    self = [super initWithWorker:aWorker];
    return self;
}

- (NSString*) name { return @"StepDone"; }
- (int) stateId    { return 5; }

- (void) startWork 
{
    [worker moveToStart];
    [worker setSweepState:[worker movingToStartSweepState]];
}

- (void) stopWork  
{
    [worker moveToStart];
    [worker setSweepState:[worker atEndSweepState]];
}

- (void) doWork  
{ 
    if(![worker inhibited]){
        [self shipSweepState];
        [worker moveDeltaSteps];
        [worker setSweepState:[worker motorAdvancingSweepState]];
    }
}
@end


//=========================================================
// MotorEndSweepState
//=========================================================
@implementation MotorEndSweepState
- (id) initWithWorker:(id) aWorker
{
    self = [super initWithWorker:aWorker];
    return self;
}
- (NSString*) name { return @"Finished"; }
- (int) stateId    { return 4; }

- (void) startWork 
{
    [worker moveToStart];
    [worker setSweepState:[worker movingToStartSweepState]];
}

- (void) stopWork  
{
    [worker moveToStart];
}

- (void) doWork  
{ 
    if(![worker motorRunning]){
        [self shipSweepState];
        [worker finishedWork];
    }
}
@end
