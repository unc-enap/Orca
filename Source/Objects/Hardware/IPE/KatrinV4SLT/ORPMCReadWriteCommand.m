//
//  ORPMCReadWriteCommand.m
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
#import "ORPMCReadWriteCommand.h"

@implementation ORPMCReadWriteCommand
+ (id) delayCmd:(uint32_t)aMilliSeconds
{
	return [[[ORPMCReadWriteCommand alloc] initWithMilliSecondDelay: kDelayOp] autorelease];
}

+ (id) writeLongBlock:(uint32_t *) writeAddress
			 atAddress:(uint32_t) pmcAddress
			numToWrite:(uint32_t) numberLongs
{
	return [[[ORPMCReadWriteCommand alloc] initWithOp: kSBC_WriteBlock
										   dataAdress: writeAddress
										   pmcAddress: pmcAddress
										  numberItems: numberLongs]autorelease];
	
}

+ (id) readLongBlockAtAddress:(uint32_t) pmcAddress
		   numToRead:(uint32_t) numberLongs
{
	return [[[ORPMCReadWriteCommand alloc] initWithOp: kSBC_ReadBlock
										   dataAdress: 0		
										   pmcAddress: pmcAddress
										  numberItems: numberLongs]autorelease];
	
}

- (id) initWithMilliSecondDelay:(uint32_t) aMilliSecondDelay
{
	self			= [super init];
	opType			= kDelayOp;
	milliSecondDelay= aMilliSecondDelay;
	return self;
}

- (id) initWithOp: (int) anOpType
	   dataAdress: (uint32_t*) dataAddress
	   pmcAddress: (unsigned int) apmcAddress
	  numberItems: (unsigned int) aNumberItems
{
	self			= [super init];
	opType			= anOpType;
	pmcAddress		= apmcAddress;
	numberItems		= aNumberItems;
	uint32_t numBytes		= sizeof(int32_t)*numberItems;
	if(dataAddress)	data = [[NSMutableData dataWithBytes:dataAddress length:numBytes] retain];
	else			data = [[NSMutableData dataWithLength:numBytes] retain];
	
	return self;
}

- (void) dealloc
{
	[data release];
	[super dealloc];
}

- (uint32_t) milliSecondDelay { return milliSecondDelay;}
- (int)	opType				 { return opType; }
- (int) numberItems			 { return numberItems; }
- (unsigned int) pmcAddress  { return pmcAddress; }
- (int) returnCode			 { return returnCode; }
- (void) setReturnCode:(int)aCode {  returnCode = aCode; }
- (NSMutableData*) data		 { return data; }
- (unsigned char*) bytes	 { return (unsigned char*)[data bytes];}

- (void) SBCPacket:(SBC_Packet*)aPacket
{
	BOOL validOp = YES;
	aPacket->cmdHeader.destination		= kSBC_Process;
	if(opType == kSBC_WriteBlock){
		aPacket->cmdHeader.cmdID			= kSBC_WriteBlock;
		aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_IPEv4WriteBlockStruct) + numberItems*sizeof(int32_t);
        if (aPacket->cmdHeader.numberBytesinPayload > kSBC_MaxPayloadSizeBytes) [self throwError:ENOMEM];
		SBC_IPEv4WriteBlockStruct* writeBlockPtr = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
		writeBlockPtr->address			= pmcAddress;
		writeBlockPtr->numItems			= numberItems;
		writeBlockPtr++;				//point to the payload
		char* p = (char*)[data bytes];
		memcpy(writeBlockPtr,p,numberItems*sizeof(int32_t));		
	}
	else if(opType == kSBC_ReadBlock){
		aPacket->cmdHeader.cmdID			= kSBC_ReadBlock;
		aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_IPEv4ReadBlockStruct) + numberItems*sizeof(int32_t);
        if (aPacket->cmdHeader.numberBytesinPayload > kSBC_MaxPayloadSizeBytes) [self throwError:ENOMEM];        
		SBC_IPEv4ReadBlockStruct* readBlockPtr = (SBC_IPEv4ReadBlockStruct*)aPacket->payload;
		readBlockPtr->address			= pmcAddress;
		readBlockPtr->numItems			= numberItems;
		//payload is empty, will have data on return, fill with zeros for now
		readBlockPtr++;				//point to the payload
		memset(readBlockPtr,0,numberItems*sizeof(int32_t));
	}
	else if(opType == kDelayOp){
		aPacket->cmdHeader.destination	= kSBC_Process;
		aPacket->cmdHeader.cmdID			= kSBC_TimeDelay;
		aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_TimeDelay);
		SBC_TimeDelay* delayStructPtr = (SBC_TimeDelay*)aPacket->payload;
		delayStructPtr->milliSecondDelay			= milliSecondDelay;
	}
	else validOp = NO;
	
	if(validOp) aPacket->numBytes = sizeof(uint32_t) + sizeof(SBC_CommandHeader) + kSBC_MaxMessageSizeBytes + aPacket->cmdHeader.numberBytesinPayload;
}

- (void) extractData:(SBC_Packet*) aPacket
{
	if(aPacket->cmdHeader.cmdID == kSBC_WriteBlock){
		//nothing to do except to look at the error code
		SBC_IPEv4WriteBlockStruct* rp = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
		if(rp->errorCode){
			[self throwError:rp->errorCode];
		}
	}
	else if(aPacket->cmdHeader.cmdID == kSBC_ReadBlock){
		SBC_IPEv4ReadBlockStruct* rp = (SBC_IPEv4ReadBlockStruct*)aPacket->payload;
		if(!rp->errorCode){		
			int num = numberItems;
			char* dp = (char*)(rp+1); //point to the data
			[data replaceBytesInRange:NSMakeRange(0,num*sizeof(int32_t)) withBytes:dp];
		}
		else {
			[self throwError:rp->errorCode];
		}
	}
}

- (void) throwError:(int)anError
{
	NSString* baseString = [NSString stringWithFormat:@"PMC Address Exception. "];
	NSString* details;
	if(anError == EPERM)		details = @"Operation not permitted";
	else if(anError == ENODEV)	details = @"No such device";
	else if(anError == ENXIO)	details = @"No such device or address";
	else if(anError == EINVAL)	details = @"Invalid argument";
	else if(anError == EFAULT)	details = @"Bad address";
	else if(anError == EBUSY)	details = @"Device Busy";
	else if(anError == ENOMEM)	details = @"Out of Memory";
	else details = [NSString stringWithFormat:@"%d",anError];
	[NSException raise: @"SBC/PMC access Error" format:@"%@:%@",baseString,details];
}
- (int32_t) longValue
{
	int32_t* p = (int32_t*)[data bytes];
	return p[0];
}

@end

