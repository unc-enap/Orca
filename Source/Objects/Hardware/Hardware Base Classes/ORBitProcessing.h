//
//  ORBitProcessing.h
//  Orca
//
//  Created by Mark Howe on Wed Nov 30 2005.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
// control cycles. They must provide the input bit pattern as
// it exists at the start of a cycle and write out the output
// bit pattern at the end of the cycle. There must be no hardware
// accesses at any other time.
//------------------------------------------------------------
@protocol ORBitProcessing
- (void) processIsStarting;
- (void) processIsStopping; 
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;
@end

@protocol ORBitProcessor
- (void) startProcessCycle;
- (void) endProcessCycle;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) setProcessBit:(int)channel value:(int)value;
- (NSString*) processingTitle;
@end

@protocol ORCallBackBitProcessor
- (void) startProcessCycle;
- (void) endProcessCycle;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (void) mapChannel:(int)aChannel toHWObject:(NSString*)objIdentifier hwChannel:(int)objChannel;
- (void) unMapChannel:(int)aChannel fromHWObject:(NSString*)objIdentifier hwChannel:(int)aHWChannel;
- (void) vetoChangesOnChannel:(int)aChannel state:(BOOL)aState;
- (NSString*) processingTitle;
@end

@interface NSObject (ORCallBackBitProcessor)
- (void) setOutputBit:(int)bit value:(BOOL) aValue;
- (void) vetoChangesOnChannel:(int)aChannel state:(BOOL)aState;
@end
