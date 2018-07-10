//
//  ORIP408Model.h
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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

#pragma mark ¥¥¥Imported Files
#import "ORVmeIPCard.h"
#import "ORBitProcessing.h"

#pragma mark ¥¥¥Forward Declarations
@class ORConnector;

@interface ORIP408Model :  ORVmeIPCard <ORBitProcessing>
{
	@private
		unsigned long writeMask;
		unsigned long readMask;
		unsigned long writeValue;
		unsigned long readValue;
        NSLock* hwLock;
		id	cachedController; //for a little more speed

		//bit processing variables
		unsigned long processInputValue;  //snapshot of the inputs at start of process cycle
		unsigned long processOutputValue; //outputs to be written at end of process cycle
		unsigned long processOutputMask;  //controlls which bits are written
}

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;
- (void) runStarting:(NSNotification*)aNote;
- (void) runStopping:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (unsigned long) writeMask;
- (void) setWriteMask:(unsigned long)aMask;
- (unsigned long) writeValue;
- (void) setWriteValue:(unsigned long)aValue;
- (unsigned long) readMask;
- (void) setReadMask:(unsigned long)aMask;
- (unsigned long) readValue;
- (void) setReadValue:(unsigned long)aValue;

#pragma mark ¥¥¥Hardware Access
- (unsigned long) getInputWithMask:(unsigned long) aChannelMask;
- (void) setOutputWithMask:(unsigned long) aChannelMask value:(unsigned long) aMaskValue;

#pragma mark ¥¥¥Bit Processing Protocol
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;

@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORIP408WriteMaskChangedNotification;
extern NSString* ORIP408WriteValueChangedNotification;
extern NSString* ORIP408ReadMaskChangedNotification;
extern NSString* ORIP408ReadValueChangedNotification;

