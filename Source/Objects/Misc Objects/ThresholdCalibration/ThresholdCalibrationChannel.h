//
//  ThresholdCalibrationChannel.h
//  Orca
//
//  Created by Mark Howe on Tue Mar 23 2004.
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




@class ORRateGroup;
@class ThresholdCalibrationTask;

typedef  enum  thresholdCalibrationStates {
	kIdle,
	kStarting,
	kBottomSearch,
	kIteratingDown,
	kIntegrating,
	kIteratingUp,
	kTweakDown,
	kIntegrating1,
	kTweakUp,
	kFinishing,
	kDone,
	kFailed,
	kNumStates //must be last
}thresholdCalibrationStates;



@interface ThresholdCalibrationChannel : NSObject {
	@private
		id delegate;
		int channel;
		int originalThreshold;
		int noiseBottom;
		int baseThreshold;
		int lastThreshold;
		int threshold;
		ThresholdCalibrationTask* owner;
		int state;
		int lastIteratingState;
		BOOL isDone;
		NSString* reason;
		int stateCount;
		int bottomSearchCount;
}
- (int)channel;
- (void)setChannel:(int)aChannel;
- (void) setOwner:(ThresholdCalibrationTask*)anOwner;
- (int)threshold; 
- (void)setThreshold:(int)aThreshold;
- (BOOL) isDone;
- (void) stepCalibration;
- (void) printReport;
- (NSString*) reason;
- (void) setReason:(NSString*)aReason;

@end

@interface NSObject (ThresholdCalibrationChannel)
- (void) setThresholdCalibration:(int)channel state:(NSString*)aString;
- (float) rate:(int)aChannel;
@end;