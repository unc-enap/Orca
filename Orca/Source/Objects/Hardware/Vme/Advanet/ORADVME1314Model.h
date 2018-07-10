//
//  ORADVME1314Model.h
//  Orca
//
//  Created by Michael Marino on Mon 6 Feb 2012 
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
#import "ORVmeIOCard.h"
#import "ORBitProcessing.h"

#pragma mark ¥¥¥Forward Declarations

#define kADVME1314Number32ChannelSets 4

typedef struct { 
    uint32_t channelDat[kADVME1314Number32ChannelSets];
} ADVME1314ChannelDat;

@interface ORADVME1314Model :  ORVmeIOCard <ORBitProcessing>
{
	@private
		ADVME1314ChannelDat writeMask;
        ADVME1314ChannelDat writeValue;
        NSLock* hwLock;
		id	cachedController; //for a little more speed

		//bit processing variables
        ADVME1314ChannelDat processOutputValue; //outputs to be written at end of process cycle
        ADVME1314ChannelDat processOutputMask; //controls which bits are written
}

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;
- (void) runStarting:(NSNotification*)aNote;
- (void) runStopping:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (ADVME1314ChannelDat) writeMask;
- (void) setWriteMask:(ADVME1314ChannelDat)aMask;
- (ADVME1314ChannelDat) writeValue;
- (void) setWriteValue:(ADVME1314ChannelDat)aValue;


#pragma mark ¥¥¥Hardware Access
- (void) setOutputWithMask:(ADVME1314ChannelDat) aChannelMask value:(ADVME1314ChannelDat) aMaskValue;
- (void) syncWithHardware;
- (void) reset;
- (void) dump;
#pragma mark ¥¥¥Bit Processing Protocol
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;

@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORADVME1314WriteMaskChangedNotification;
extern NSString* ORADVME1314WriteValueChangedNotification;

