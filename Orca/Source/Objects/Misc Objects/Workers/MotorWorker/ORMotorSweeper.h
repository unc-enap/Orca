//
//  ORMotorSweeper.h
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


@class ORTimer;

@interface ORMotorSweeper : NSObject {
    NSTimer* loopTimer;
    BOOL inhibited;
    id motor;
    id sweepState;
    id atStartSweepState;
    id atEndSweepState;
    id motorAdvancingSweepState;
    id dwellSweepState;
    id stepDoneState;
    id movingToStartSweepState;
    
    int start;
    int end;
    int delta;
    int numSteps;
    float dwell;
	
    int stepIndex;
    NSArray* positionArray;
    NSArray* dwellArray;
}

#pragma mark ¥¥¥Initialization
+ (id) motorSweeper:(id)aPattern
			  start:(int)aStart 
				end:(int)anEnd 
			  delta:(int)aDelta 
			  dwell:(float)aDwellTime;

+ (id) motorSweeper:(id)aPattern
		  positions:(NSArray*)aPositionArray 
			 dwells:(NSArray*)aDwellArray;

- (id) initWithMotor:(id)aPattern
						 start:(int)aStart 
						   end:(int)anEnd 
						 delta:(int)aDelta 
						 dwell:(float)aDwellTime;
						 
- (id) initWithMotor:(id)aPattern
					 positions:(NSArray*)aPositionArray
						dwells:(NSArray*)aDwellArray;

#pragma mark ¥¥¥Accessors
- (void) finishedStep;
- (BOOL) inhibited;
- (void) setInhibited:(BOOL)aFlag;
- (id)   motor;
- (void) setMotor:(id)aMotor;
- (id)   sweepState;
- (id)   atStartSweepState;
- (void) setAtStartSweepState:(id)anAtStartSweepState;
- (id)   atEndSweepState;
- (void) setAtEndSweepState:(id)anAtEndSweepState;
- (id)   motorAdvancingSweepState;
- (void) setMotorAdvancingSweepState:(id)aState;
- (id)   dwellSweepState;
- (void) setDwellSweepState:(id)aState;
- (id)   stepDoneState;
- (void) setStepDoneState:(id)aState;
- (void) setMovingToStartSweepState:(id)aState;
- (id)   movingToStartSweepState;
- (float) dwell;
- (NSArray*) positionArray;
- (void)	 setPositionArray:(NSArray *)aPositionArray;
- (NSArray*) dwellArray;
- (void)	 setDwellArray:(NSArray *)aDeltaArray;

#pragma mark ¥¥¥hardware access
- (long) motorPosition;
- (BOOL) motorRunning;
- (BOOL) motorAtEndPosition;
- (BOOL) motorAtStartPosition;
- (void) moveDeltaSteps;
- (void) moveToStart;

#pragma mark ¥¥¥SweepState Actions
- (void) startWork;
- (void) stopWork;
- (void) pauseWork;
- (void) continueWork;
- (void) doWork;
- (void) finishedWork;
- (void) shipMotorState;
- (int) stateId;

@end

//===============================================================
// Sweep States 
//===============================================================
@interface MotorSweepState : NSObject {
    @protected
        id worker;
}
- (id) initWithWorker:(id) aWorker;
- (void) shipSweepState;
- (int) stateId;
@end

@interface MotorStartSweepState  : MotorSweepState {} @end
@interface MotorDwellSweepState  : MotorSweepState {ORTimer* dwellTimer;} @end
@interface MotorAdvancingSweepState  : MotorSweepState {long count;} @end
@interface MotorStepDoneState  : MotorSweepState {} @end
@interface MotorEndSweepState    : MotorSweepState {} @end
@interface MotorMovingToStartSweepState    : MotorSweepState {} @end
//===============================================================

