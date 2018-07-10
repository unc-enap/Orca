//
//  ThresholdCalibrationTask.h
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
@protocol ThresholdCalibration
- (void) setCalibrationTask:(ThresholdCalibrationTask*)aTask;
- (void) setThresholdCalibration:(int)channel state:(NSString*)aString;
- (void) setThresholdDac:(unsigned short) aChan withValue:(unsigned short) aThreshold;
- (unsigned short) thresholdDac:(unsigned short) aChan;
- (void) loadCalibrationValues;
- (int)  calibrationFinalDelta;
@end



@interface ThresholdCalibrationTask : NSObject {
	NSString* name;
    int tag;
    id delegate;
    double savedIntegrationTime;
    NSMutableArray* channelArray;
    ORRateGroup* rateGroup;
    int numChannels;
	unsigned int maxThreshold;
	float stepTime;
    NSMutableArray* reportArray;
}
- (id) init;
- (void) dealloc;
- (float) stepTime;
- (void) setStepTime:(float)aTime;
- (NSString*) name;
- (void) setName:(NSString*)aName;
- (void) setTag:(int)aTag;
- (int) tag;
- (id) delegate;
- (void) setDelegate:(id)aDelegate;
- (NSMutableArray *)channelArray;
- (void)setChannelArray:(NSMutableArray *)someChannels;
- (void) setRateGroup:(ORRateGroup*)aRateGroup;
- (ORRateGroup*) rateGroup;
- (unsigned int)maxThreshold;
- (void) setMaxThreshold:(unsigned int)aValue;

- (void) start:(int)numChannels enabledMask:(unsigned long)enabledMask 
     rateGroup:(ORRateGroup*)aRateGroup tag:(int)aTag;
- (void) abort;
- (void) stop;
- (void) stepCalibration;

- (void) runStatusChanged:(NSNotification*)aNote;

@end

@interface NSObject (ThreadholdCalibrationTask)
- (void) reArm;
@end
