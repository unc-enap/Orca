//
//  ORPMCReadWriteCommand.h
//  Orca
//
//  Created by Mark Howe on 12/14/09.
//  Copyright 2009 Univerisity of North Carolina. All rights reserved.
//
/*-----------------------------------------------------------
This program was prepared for the Regents of the University of 
Washington at the Center for Experimental Nuclear Physics and 
Astrophysics (CENPA) sponsored in part by the United States 
Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
The University has certain rights in the program pursuant to 
the contract and the program should not be copied or distributed 
outside your organization.  The DOE and the University of 
Washington reserve all rights in the program. Neither the authors,
University of Washington, or U.S. Government make any warranty, 
express or implied, or assume any liability or responsibility 
for the use of this software.
-------------------------------------------------------------*/
#import "SBC_Cmds.h"

#define kWriteOp 0
#define kReadOp	 1
#define kDelayOp 2

@interface ORPMCReadWriteCommand : NSObject {
	int32_t			milliSecondDelay;
	int				opType;				//read/write
	uint32_t	numberItems;
	uint32_t	pmcAddress;			//hw Address
	int				returnCode;			//should be 1 for success, 0 for failure
	NSMutableData*	data;			//if read theData == returned data, if write theData = writeData
}
+ (id) delayCmd:(uint32_t) milliSeconds;
	
+ (id) writeLongBlock:(uint32_t *) writeAddress
			atAddress:(uint32_t) pmcAddress
		   numToWrite:(uint32_t) numberLongs;

+ (id) readLongBlockAtAddress:(uint32_t) pmcAddress
					numToRead:(uint32_t) numberLongs;

- (id) initWithMilliSecondDelay:(uint32_t) aMilliSecondDelay;
	
- (id) initWithOp: (int) aOpType
	   dataAdress: (uint32_t*) dataAddress
	   pmcAddress: (uint32_t) pmcAddress
	  numberItems: (uint32_t) aNumberItems;

- (uint32_t) milliSecondDelay;
- (int)	opType;
- (uint32_t) numberItems;
- (int)	returnCode;
- (void) setReturnCode:(int)aCode;
- (uint32_t)	pmcAddress;
- (unsigned char*) bytes;
- (NSMutableData*)	data;

- (void) SBCPacket:(SBC_Packet*)aPacket;
- (void) extractData:(SBC_Packet*) aPacket;
- (void) throwError:(int)anError;
- (int32_t) longValue;

@end

