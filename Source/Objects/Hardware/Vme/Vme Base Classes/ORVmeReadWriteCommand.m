//
//  ORVmeReadWriteCommand.m
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
#import "ORVmeReadWriteCommand.h"

@implementation ORVmeReadWriteCommand
+ (id) delayCmd:(unsigned long)aMilliSeconds
{
	return [[[ORVmeReadWriteCommand alloc] initWithMilliSecondDelay: kDelayOp] autorelease];
}

+ (id) writeLongBlock:(unsigned long *) writeAddress
			 atAddress:(unsigned long) vmeAddress
			numToWrite:(unsigned int) numberLongs
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace
{
	return [[[ORVmeReadWriteCommand alloc] initWithOp: kWriteOp
										   dataAdress: writeAddress
										   vmeAddress: vmeAddress
										  numberItems: numberLongs
											 itemSize: sizeof(long)
										   withAddMod: anAddressModifier
										usingAddSpace: anAddressSpace] autorelease];
	
}

+ (id) readLongBlockAtAddress:(unsigned long) vmeAddress
		   numToRead:(unsigned int) numberLongs
		   withAddMod:(unsigned short) anAddressModifier
		usingAddSpace:(unsigned short) anAddressSpace
{
	return [[[ORVmeReadWriteCommand alloc] initWithOp: kReadOp
										   dataAdress: 0		
										   vmeAddress: vmeAddress
										  numberItems: numberLongs
											 itemSize: sizeof(long)
										   withAddMod: anAddressModifier
										usingAddSpace: anAddressSpace] autorelease];
	
}

+ (id) writeShortBlock:(unsigned long *) writeAddress
			atAddress:(unsigned long) vmeAddress
		   numToWrite:(unsigned int) numberShorts
		   withAddMod:(unsigned short) anAddressModifier
		usingAddSpace:(unsigned short) anAddressSpace
{
	return [[[ORVmeReadWriteCommand alloc] initWithOp: kWriteOp
										   dataAdress: writeAddress
										   vmeAddress: vmeAddress
										  numberItems: numberShorts
											 itemSize: sizeof(short)
										   withAddMod: anAddressModifier
										usingAddSpace: anAddressSpace] autorelease];
	
}

+ (id) readShortBlockAtAddress:(unsigned long) vmeAddress
					numToRead:(unsigned int) numberShorts
				   withAddMod:(unsigned short) anAddressModifier
				usingAddSpace:(unsigned short) anAddressSpace
{
	return [[[ORVmeReadWriteCommand alloc] initWithOp: kReadOp
										   dataAdress: 0		
										   vmeAddress: vmeAddress
										  numberItems: numberShorts
											 itemSize: sizeof(short)
										   withAddMod: anAddressModifier
										usingAddSpace: anAddressSpace] autorelease];
	
}


- (id) initWithMilliSecondDelay:(unsigned long) aMilliSecondDelay
{
	self			= [super init];
	opType			= kDelayOp;
	milliSecondDelay= aMilliSecondDelay;
	return self;
}

- (id) initWithOp: (int) anOpType
	   dataAdress: (unsigned long*) dataAddress
	   vmeAddress: (unsigned long) aVmeAddress
	  numberItems: (unsigned int) aNumberItems
		 itemSize: (unsigned int) anItemSize
	   withAddMod: (unsigned short) anAddressModifier
	usingAddSpace: (unsigned short) anAddressSpace
{
	self			= [super init];
	opType			= anOpType;
	vmeAddress		= aVmeAddress;
	numberItems		= aNumberItems;
	itemSize		= anItemSize;
	addressSpace	= anAddressSpace;
	addressModifier = anAddressModifier;
	unsigned long numBytes		= itemSize*numberItems;
	if(dataAddress)	data = [[NSMutableData dataWithBytes:dataAddress length:numBytes] retain];
	else			data = [[NSMutableData dataWithLength:numBytes] retain];
	
	return self;
}

- (void) dealloc
{
	[data release];
	[super dealloc];
}

- (unsigned long) milliSecondDelay { return milliSecondDelay;}
- (int)	opType				 { return opType; }
- (int) numberItems			 { return numberItems; }
- (int) itemSize			 { return itemSize; }
- (int)	addressModifier		 { return addressModifier; }
- (int)	addressSpace		 { return addressSpace; }
- (unsigned long) vmeAddress { return vmeAddress; }
- (int) returnCode			 { return returnCode; }
- (void) setReturnCode:(int)aCode {  returnCode = aCode; }
- (NSMutableData*) data		 { return data; }
- (unsigned char*) bytes	 { return (unsigned char*)[data bytes];}

- (void) SBCPacket:(SBC_Packet*)aPacket
{
	BOOL validOp = YES;
	aPacket->cmdHeader.destination		= kSBC_Process;
	if(opType == kWriteOp){
		aPacket->cmdHeader.cmdID			= kSBC_WriteBlock;
		aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_VmeWriteBlockStruct) + numberItems*itemSize;
        if (aPacket->cmdHeader.numberBytesinPayload > kSBC_MaxPayloadSizeBytes) [self throwError:ENOMEM];
		SBC_VmeWriteBlockStruct* writeBlockPtr = (SBC_VmeWriteBlockStruct*)aPacket->payload;
		writeBlockPtr->address			= vmeAddress;
		writeBlockPtr->addressModifier	= addressModifier;
		writeBlockPtr->addressSpace		= addressSpace;
		writeBlockPtr->unitSize			= itemSize;
		writeBlockPtr->numItems			= numberItems;
		writeBlockPtr++;				//point to the payload
		char* p = (char*)[data bytes];
		memcpy(writeBlockPtr,p,numberItems*itemSize);		
	}
	else if(opType == kReadOp){
		aPacket->cmdHeader.cmdID			= kSBC_ReadBlock;
		aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_VmeReadBlockStruct) + numberItems*itemSize;
        if (aPacket->cmdHeader.numberBytesinPayload > kSBC_MaxPayloadSizeBytes) [self throwError:ENOMEM];        
		SBC_VmeReadBlockStruct* readBlockPtr = (SBC_VmeReadBlockStruct*)aPacket->payload;
		readBlockPtr->address			= vmeAddress;
		readBlockPtr->addressModifier	= addressModifier;
		readBlockPtr->addressSpace		= addressSpace;
		readBlockPtr->unitSize			= itemSize;
		readBlockPtr->numItems			= numberItems;
		//payload is empty, will have data on return, fill with zeros for now
		readBlockPtr++;				//point to the payload
		memset(readBlockPtr,0,numberItems*itemSize);
	}
	else if(opType == kDelayOp){
		aPacket->cmdHeader.cmdID			= kSBC_TimeDelay;
		aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_TimeDelay);
		SBC_TimeDelay* delayStructPtr = (SBC_TimeDelay*)aPacket->payload;
		delayStructPtr->milliSecondDelay			= milliSecondDelay;
	}
	else validOp = NO;
	if(validOp) aPacket->numBytes = sizeof(unsigned long) + sizeof(SBC_CommandHeader) + kSBC_MaxMessageSizeBytes + aPacket->cmdHeader.numberBytesinPayload;
}

- (void) extractData:(SBC_Packet*) aPacket
{
	if(aPacket->cmdHeader.cmdID == kSBC_WriteBlock){
		//nothing to do except to look at the error code
		SBC_VmeWriteBlockStruct* rp = (SBC_VmeWriteBlockStruct*)aPacket->payload;
		if(rp->errorCode){
			[self throwError:rp->errorCode];
		}
	}
	else if(aPacket->cmdHeader.cmdID == kSBC_ReadBlock){
		SBC_VmeReadBlockStruct* rp = (SBC_VmeReadBlockStruct*)aPacket->payload;
		if(!rp->errorCode){		
			int num = numberItems;
			int size = itemSize;
			char* dp = (char*)(rp+1); //point to the data
			[data replaceBytesInRange:NSMakeRange(0,num*size) withBytes:dp];
		}
		else {
			[self throwError:rp->errorCode];
		}
	}
}

- (void) throwError:(int)anError
{
	NSString* baseString = [NSString stringWithFormat:@"Vme Address Exception. "];
	NSString* details;
	if(anError == EPERM)		details = @"Operation not permitted";
	else if(anError == ENODEV)	details = @"No such device";
	else if(anError == ENXIO)	details = @"No such device or address";
	else if(anError == EINVAL)	details = @"Invalid argument";
	else if(anError == EFAULT)	details = @"Bad address";
	else if(anError == EBUSY)	details = @"Device Busy";
	else if(anError == ENOMEM)	details = @"Out of Memory";
	else details = [NSString stringWithFormat:@"%d",anError];
	[NSException raise: @"SBC/VME access Error" format:@"%@:%@",baseString,details];
}

- (long) longValue
{
	long* p = (long*)[data bytes];
	return p[0];
}

- (short) shortValue
{
	short* p = (short*)[data bytes];
	return p[0];
}

@end

