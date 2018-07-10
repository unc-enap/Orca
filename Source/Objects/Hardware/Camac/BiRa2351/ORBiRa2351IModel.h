/*
 *  ORBiRa2351IModel.h
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

@interface ORBiRa2351IModel : ORCamacIOCard <ORBitProcessing> {	
	@private
		unsigned short inputRegister;
		int pollingState;
		NSString* lastRead;
		
		//bit processing variables
		unsigned long processInputValue;  //snapshot of the inputs at start of process cycle
}

#pragma mark ¥¥¥Initialization
- (void) dealloc;
        
#pragma mark ¥¥¥Accessors
- (int) pollingState;
- (void) setPollingState:(int)aPollingState;
- (unsigned short) inputRegister;
- (void) setInputRegister:(unsigned short)aValue;
- (BOOL) inputBit:(int)bit;
- (void) setInputBit:(int)bit withValue:(BOOL)aValue;
- (NSString*) lastRead;
- (void) setLastRead:(NSString*)aLastRead;

#pragma mark ¥¥¥Hardware functions
- (void) readInputRegister:(BOOL)verbose;

#pragma mark ¥¥¥Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ¥¥¥Bit Processing Protocol
- (void)processIsStarting;
- (void)processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (NSString*) processingTitle;

@end

extern NSString* ORBiRa2351IModelInputRegisterChanged;
extern NSString* ORBiRa2351IModelPollingStateChanged;
extern NSString* ORBiRa2351IModelLastReadChanged;

