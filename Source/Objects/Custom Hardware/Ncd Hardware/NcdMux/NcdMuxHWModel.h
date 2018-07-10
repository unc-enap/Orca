//
//  NcdMuxHWModel.h
//  Orca
//
//  Created by Mark Howe on Fri Feb 21 2003.
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


#pragma mark •••Imported Files

#pragma mark •••Definitions
#define kTestValue           0x7b
#define	kDataByteMask        0x000000FF
#define	kChanHitRegisterMask 0x00000FFF

//completion codes and errors
#define	kControllerReset 	0x00
#define	kCarWritten 		0x01
#define	kDacWriteComplete 	0x02
#define	kAdcToDr 		 	0x03
#define	kIdStatusToDr		0x04
#define	kEventHeaderToDr	0x05
#define	kSingleDataToDr		0x06
#define	kErrorCode		 	0x07
#define	kBusStrobeLow		0x08
#define kNotInitited		0xFE
#define	kTimeOut		 	0xFF

#define	kNoScopeTrigger		0x0
#define	kTriggerScopeA		0x1
#define	kTriggerScopeB		0x2
#define	kTriggerToggle		0x3

#define	kWriteChannelCmd 	0x01
#define	kWriteDacCmd 		0x02
#define	kReadAdcCmd 		0x03
#define	kStatusQueryCmd 	0x04
#define	kArmRearmCmd 		0x05
#define	kReadEventCmd 		0x06
#define	kReadSelMuxCmd 		0x07
#define	kResetCmd 			0x08

#define	kMuxSelBitsMask    	0xE0000000
#define	kOutDataMask   		0xFF000000
#define	kChannelMask   		0x1F000000
#define	kBusStrobeBitMask  	0x00800000
#define	kCmdMask  			0x00780000
#define	kReturnCodeMask   	0x00070000
#define	kCmdCompleteBitMask 0x00000001
#define	kControlPad			0x0007FFFF
#define	kDataRegisterMask 	0x00007FFF
#define	kStatusQueryMask    0x000000FF
#define	kAdcMask    	 	0x000001FE
#define kRelayMask    		0x000001FE
#define kHVPwrMask    		0x00000200

#define	kScopeTrigMask		0x00000c00
#define	kScopeATrigMask		0x00000800
#define	kScopeBTrigMask		0x00000400
#define	kControlOutputMask  kMuxSelBitsMask | kChannelMask | kBusStrobeBitMask | kCmdMask
#define	kCmdShift			19
#define	kChannelShift		25
#define	kOutDataShift  	 	24
#define	kOutReadDRShift		 1
#define	kMuxSelBitsShift	29
#define	kReturnCodeShift	16

//------------------------------------------------------
//HV specific definitions
#define kHVFullScale 		2274.
#define kReadDelayTime		3
#define kHVOffset    		3.
enum {
	kHVCoarseWriteAddress= 0, 	//the DAC setting readback
	kHVFineWriteAddress	 = 1, 	//the DAC setting readback
	kHVReadAddress 		 = 4, 	//the actual HV readback
	kHVCurrentReadAddress= 5,	//the current readback 
	kLow 			 = 0x00,
	kHigh 			 = 0x01,
};

//HV codes
#define kHVRelaysToDr		0x04
#define kNullCmdSent		0x05
#define kHVRelaysSet		0x06
#define kReadHVRelaysCmd 	0x05
#define kSetHVRelaysCmd 	0x07



//------------------------------------------------------

#pragma mark •••Forward Declarations
@class ORConnector;

typedef char mux_result;

@interface NcdMuxHWModel :  NSObject
{
    ORConnector* connectorTo408;
    int scopeSelection;

    //hv variables
    double 	adcDelayTimeStart;
    BOOL 	delayAdcRead;
    BOOL	doNotWaitForCSBLow;
	BOOL	lowPowerOn;
	NSLock* sendLock;
}

#pragma mark •••Accessors
- (ORConnector*) connectorTo408;
- (void) setConnectorTo408:(ORConnector*)aConnector;
- (int) scopeSelection;
- (void) setScopeSelection:(int)newScopeSelection;
- (void) setDoNotWaitForCSBLow:(BOOL)aState;
- (BOOL) doNotWaitForCSBLow;
- (void) connectionChanged;

#pragma mark •••Hardware Access
- (mux_result) writeChannel:(unsigned char) aChannel mux:(unsigned short) muxBox;
- (mux_result) writeDACValue:(unsigned short) aValue mux:(unsigned char) muxBox channel:(unsigned short) aChannel;
- (mux_result) getADCValue:(unsigned short*)theDrValue mux:(unsigned char) muxBox channel:(unsigned short) aChannel;
- (mux_result) getStatusQuery:(unsigned short*)theDrValue mux:(unsigned char) muxBox;
- (mux_result) armScopeSelection;
- (mux_result) disableScopes;
- (mux_result) getEventRegister:(unsigned short*)theDrValue;
- (mux_result) getSelectedMux:(unsigned short*)theDrValue mux:(unsigned char) muxBox;
- (mux_result) reset;

#pragma mark •••HV Hardware Access
- (void) turnOnSupplies:(NSArray*)someSupplies state:(BOOL)aState;
- (void) writeDac:(int)aValue supply:(id)aSupply;
- (BOOL) readAdc:(id) aSupply;
- (BOOL) readDac:(id) aSupply;
- (BOOL) readCurrent:(id) aSupply;
- (unsigned long) readRelayMask;
- (mux_result) getHVADCValue:(unsigned short*)theDrValue mux:(unsigned char) muxBox channel:(unsigned short) aChannel;
- (BOOL) lowPowerOn;

#pragma mark •••HV Helpers
- (void) resetAdcs;

@end
