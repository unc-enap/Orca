//
//  OROneShotModel.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORProcessElementModel.h"

@class ORInvertedOutputNub;

@interface OROneShotModel :  ORProcessElementModel 
{
    int resetState;
    int setState;
	BOOL timerRunning;
    NSTimeInterval t0;
    NSTimeInterval oneShotTime;
    ORInvertedOutputNub* invertedOuputNub;
}

#pragma mark ¥¥¥Initialization
- (void) setUpImage;
- (void) makeMainController;
- (void) processIsStarting;
- (id) eval;
- (id) evalInput1;
- (id) evalInput2;

#pragma mark ¥¥¥Accessors
- (NSTimeInterval) oneShotTime;
- (void) setOneShotTime:(NSTimeInterval)aoneShotTime;

@end

extern NSString* OROneShotTimeChangedNotification;
extern NSString* OROneShotLock;
