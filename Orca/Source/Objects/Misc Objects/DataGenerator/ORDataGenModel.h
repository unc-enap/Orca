//
//  ORDataGenModel.h
//  Orca
//
//  Created by Mark Howe on Thu Oct 02 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORDataTaker.h"
#import "ORAdcProcessing.h"

@interface ORDataGenModel :  OrcaObject <ORDataTaker,ORAdcProcessing>
{
    unsigned long burstDataId;
    unsigned long dataId1D;
    unsigned long dataId2D;
    unsigned long dataIdWaveform;
	unsigned long timeSeriesId;
	BOOL first;
	float adcValue;
	int theta;
	NSDate* lastTime;
	float   timeIndex;
	ORTimer* burstTimer;
	unsigned long nextBurst;
}
- (unsigned long) timeSeriesId;
- (unsigned long) burstDataId;
- (unsigned long) dataId1D;
- (unsigned long) dataId2D;
- (unsigned long) dataIdWaveform;
- (void) setTimeSeriesId: (unsigned long) aDataId;
- (void) setBurstDataId: (unsigned long) aDataId;
- (void) setDataId1D: (unsigned long) aDataId;
- (void) setDataId2D: (unsigned long) aDataId;
- (void) setDataIdWaveform: (unsigned long) aDataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;

#pragma mark ¥¥¥Adc Processing Protocol
- (void)processIsStarting;
- (void)processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel;
- (double) convertedValue:(int)channel;
- (double) maxValueForChan:(int)channel;

#pragma mark ¥¥¥Data Taking
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) reset;

@end


