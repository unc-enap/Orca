//
//  ORMotorPattern.h
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


enum {
    kSweepReturn,
    kFastReturn
};

@interface ORMotorPattern : NSObject {
    id motor;
    id sweeper;

    int start;
    int end;
    int delta;
    float dwell;
    
    int raster;
    int sweepsToDo;
    int count;
    BOOL workCanceled;
	BOOL arrayMode;
}

#pragma mark ¥¥¥Initialization
+ (id) motorPattern:(id)motor 
              start:(int)aStart 
                end:(int)anEnd 
              delta:(int)aDelta 
              dwell:(float)aDwellTime
         sweepsToDo:(int)numSweeps                    
			 raster:(int)doRaster;

+ (id) motorPattern:(id)motor 
		  positions:(NSArray*)aPositionArray
			 dwells:(NSArray*)aDwellArray
         sweepsToDo:(int)numSweeps;


- (id) initWithMotor:(id)motor 
                         start:(int)aStart 
                           end:(int)anEnd 
                         delta:(int)aDelta 
                         dwell:(float)aDwellTime
                    sweepsToDo:(int)numSweeps  
                        raster:(int)raster;

- (id) initWithMotor:(id)motor 
					 positions:(NSArray*)aPositionArray
						dwells:(NSArray*)aDwellArray
					sweepsToDo:(int)numSweeps;


#pragma mark ¥¥¥Accessors
- (id)   motor;
- (void) setMotor:(id)aMotor;
- (id)   sweeper;
- (void) setSweeper:(id)aSweeper;
- (void) setInhibited:(BOOL)aFlag;
- (void) finishedStep;

#pragma mark ¥¥¥hardware access
- (long) readMotor;
- (BOOL) motorRunning;
- (void) moveMotor:(id)aMotor amount:(long)amount;
- (void) moveMotor:(id)aMotor to:(long)amount;

#pragma mark ¥¥¥State Actions
- (void) shipMotorState:(id)aWorker;
- (void) startWork;
- (void) stopWork;
- (void) finishedWork;

@end

