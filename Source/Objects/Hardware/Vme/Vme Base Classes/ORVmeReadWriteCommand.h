//
//  ORVmeReadWriteCommand.h
//  Orca
//
//  Created by Mark Howe on 12/9/08.
//  Copyright 2008 Univerisity of North Carolina. All rights reserved.
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

@interface ORVmeReadWriteCommand : NSObject {
	int32_t			milliSecondDelay;
	int				opType;				//read/write
	int				addressModifier;	//vme address modifier
	int				addressSpace;		//vme address space
	int				itemSize;
	int				numberItems;
	uint32_t	vmeAddress;			//hw Address
	int				returnCode;			//should be 1 for success, 0 for failure
	NSMutableData*	data;			//if read theData == returned data, if write theData = writeData
}
+ (id) delayCmd:(uint32_t) milliSeconds;
	
+ (id) writeLongBlock:(uint32_t*) writeAddress
			atAddress:(uint32_t) vmeAddress
		   numToWrite:(unsigned int) numberLongs
		   withAddMod:(unsigned short) anAddressModifier
		usingAddSpace:(unsigned short) anAddressSpace;

+ (id) readLongBlockAtAddress:(uint32_t) vmeAddress
				   numToRead:(unsigned int) numberLongs
				   withAddMod:(unsigned short) anAddressModifier
				usingAddSpace:(unsigned short) anAddressSpace;

+ (id) writeShortBlock:(uint32_t*) writeAddress
			atAddress:(uint32_t)  vmeAddress
		   numToWrite:(unsigned int)   numberShorts
		   withAddMod:(unsigned short) anAddressModifier
		usingAddSpace:(unsigned short) anAddressSpace;

+ (id) readShortBlockAtAddress:(uint32_t) vmeAddress
					 numToRead:(unsigned int) numberShorts
					withAddMod:(unsigned short) anAddressModifier
				 usingAddSpace:(unsigned short) anAddressSpace;

- (id) initWithMilliSecondDelay:(uint32_t) aMilliSecondDelay;
	
- (id) initWithOp: (int) aOpType
	   dataAdress: (uint32_t*) dataAddress
	   vmeAddress: (uint32_t) vmeAddress
	  numberItems: (unsigned int) aNumberItems
		 itemSize: (unsigned int) anItemSize
	   withAddMod: (unsigned short) anAddressModifier
	usingAddSpace: (unsigned short) anAddressSpace;

- (uint32_t) milliSecondDelay;
- (int)	opType;
- (int)	addressModifier;
- (int)	addressSpace;
- (int) numberItems;
- (int) itemSize;
- (int)	returnCode;
- (void) setReturnCode:(int)aCode;
- (uint32_t)	vmeAddress;
- (unsigned char*) bytes;
- (NSMutableData*)	data;

- (void) SBCPacket:(SBC_Packet*)aPacket;
- (void) extractData:(SBC_Packet*) aPacket;
- (void) throwError:(int)anError;
- (int32_t) longValue;
- (short) shortValue;

@end

