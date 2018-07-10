/*
 *  ORBiRa3251OModel.h
 *  Orca
 *
 *  Created by Mark Howe on Fri Aug 4, 2006.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORCamacIOCard.h"
#import "ORBitProcessing.h"

@interface ORBiRa3251OModel : ORCamacIOCard <ORBitProcessing> {	
	@private
		unsigned short outputRegister;
		
		//bit processing variables
		unsigned long processOutputValue; //outputs to be written at end of process cycle
		unsigned long processOutputMask;  //controlls which bits are written
}

        
#pragma mark ¥¥¥Accessors
- (unsigned short) outputRegister;
- (void) setOutputRegister:(unsigned short)aEnabledMask;
- (BOOL) outputBit:(int)bit;
- (void) setOutputBit:(int)bit withValue:(BOOL)aValue;

#pragma mark ¥¥¥Hardware functions
- (void) initBoard;

#pragma mark ¥¥¥Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ¥¥¥Bit Processing Protocol
- (void)processIsStarting;
- (void)processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;

@end

extern NSString* ORBiRa3251OModelOutputRegisterChanged;
