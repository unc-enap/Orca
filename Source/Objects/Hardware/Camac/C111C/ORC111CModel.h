/*
 *  ORCC32Model.cpp
 *  Orca
 *
 *  Created by Mark Howe on Mon Dec 10, 2007.
 *  Copyright (c) 2007 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORCC32Model.h"
#import "crate_lib.h"

@class ORCmdHistory;

#define kMaxNumberC111CTransactionsPerSecond 1024

// class definition
@interface ORC111CModel : ORCC32Model
{
    NSString*		ipAddress;
    BOOL			isConnected;
    NSDate*         timeConnected;
	int				crate_id;
	CRATE_INFO		cr_info;
    short			stationToTest;
    uint32_t	transactionsPerSecondHistogram[kMaxNumberC111CTransactionsPerSecond];
    BOOL			trackTransactions;
	ORTimer*		transactionTimer;
	ORCmdHistory*   cmdHistory;
	unsigned int   lamMask;
	NSLock* socketLock;
	NSLock* irqLock;  

}

#pragma mark •••Initialization
- (NSString*) settingsLock;

#pragma mark •••Accessors
- (BOOL) trackTransactions;
- (void) setTrackTransactions:(BOOL)aTrackTranactions;
- (char) stationToTest;
- (void) setStationToTest:(char)aStationToTest;
- (NSDate*) timeConnected;
- (void) setTimeConnected:(NSDate*)newTimeConnected;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aFlag;
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;
- (float) transactionsPerSecondHistogram:(int)index;
- (void) clearTransactions;
- (ORCmdHistory*) cmdHistory;

#pragma mark ***Utilities
- (void) connect;
- (unsigned short) testLAMForStation:(char)aStation value:(char*)result;

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
							 data:(unsigned short*) data;

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f;
								
- (unsigned short)  camacLongNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(uint32_t*) data;


- (unsigned short)  camacShortNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned short*) data
                                length:(uint32_t) numWords;

- (unsigned short)  camacLongNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(uint32_t*) data
                                length:(uint32_t) numWords;

- (void) sendCmd:(NSString*)aCmd verbose:(BOOL)verbose;
- (void) handleIRQ:(short)irq_type data:(unsigned int)irq_data;
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


extern NSString* ORC111CModelTrackTransactionsChanged;
extern NSString* ORC111CModelStationToTestChanged;
extern NSString* ORC111CSettingsLock;
extern NSString* ORC111CTimeConnectedChanged;
extern NSString* ORC111CConnectionChanged;	
extern NSString* ORC111CIpAddressChanged;
