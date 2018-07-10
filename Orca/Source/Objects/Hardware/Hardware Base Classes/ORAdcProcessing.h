//
//  ORAdcProcessing.h
//  Orca
//
//  Created by Mark Howe on Wed Nov 30 2005.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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


//------------------------------------------------------------
// a formal protocol for objects that participate in Process
// control cycles. They must provide the adc value as
// it exists at the start of a cycle. There must be no hardware
// accesses at any other time.
//------------------------------------------------------------
@protocol ORAdcProcessing
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value; //not usually used, but needed for easy compatibility with the bit protocol
- (NSString*) processingTitle;
- (double) convertedValue:(int)channel;
- (double) maxValueForChan:(int)channel;
- (double) minValueForChan:(int)channel;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel;

@optional
- (int) numberOfChannels;

@end

@protocol ORAdcProcessor
- (void) startProcessCycle;
- (void) endProcessCycle;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (double) setProcessAdc:(int)channel value:(double)value isLow:(BOOL*)isLow isHigh:(BOOL*)isHigh;
- (NSString*) processingTitle;
@end