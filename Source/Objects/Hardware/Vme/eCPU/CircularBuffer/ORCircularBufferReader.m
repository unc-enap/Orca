//
//  ORCircularBufferReader.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 01 2003.
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


#import "ORCircularBufferReader.h"
#import "ORDataPacket.h"
#import "OReCPU147Config.h"

#import "ORVmeIOCard.h"

@interface ORCircularBufferReader (private)
-(BOOL) getDataFromCB:(ORDataPacket*)aDataPacket  userInfo:(NSDictionary*)userInfo;
@end

@implementation ORCircularBufferReader

- (void) clear
{
	SCBHeader theControlBlockHeader;
	memset(&theControlBlockHeader,0,sizeof(SCBHeader));		
	@try {
		[adapter writeLongBlock:(unsigned long*)&theControlBlockHeader
					  atAddress:baseAddress
					 numToWrite:sizeof(SCBHeader)/sizeof(unsigned long)
					 withAddMod:addressModifier
				  usingAddSpace:addressSpace];
		
		
		queueSize = theControlBlockHeader.cbNumWords;
		headValue = (tCBWord)theControlBlockHeader.qHead;
		tailValue = (tCBWord)theControlBlockHeader.qTail;
		
	}
	@catch(NSException* localException) {
	}
}

- (void) writeControlBlockHeader:(SCBHeader*)theControlBlockHeader
{
	[self writeLong: [self baseAddress]+0x1C value:theControlBlockHeader->blocksRead];
	[self writeLong: [self baseAddress]+0x20 value:theControlBlockHeader->bytesRead];
	[self writeLong: [self baseAddress]+0x18 value:(tCBWord)theControlBlockHeader->qTail];
}


- (tCBWord) readBlockUsing:(SCBHeader*)theControlBlockHeader into:(tCBWord*)aBlockOfMemory size:(tCBWord) blockSize
{
	tCBWord maxAddress		= [self baseAddress] + DATA_CIRC_BUF_SIZE_BYTE;
	tCBWord readPtr			= (tCBWord)theControlBlockHeader->qTail;
	
	blockSize--;				//take account of the first word (the size)
	readPtr += sizeof(tCBWord);	//point past the size.
	if(readPtr>=maxAddress){
		readPtr = [self baseAddress] + sizeof( SCBHeader ) - sizeof( tCBWord );
	}
	
	if( (readPtr+(blockSize*sizeof(tCBWord))) <= maxAddress  ) {
		// One big copy
		[self readLongBlock:readPtr blocks:blockSize atPtr:aBlockOfMemory];
		readPtr += blockSize*sizeof(tCBWord);
		if(readPtr>=maxAddress){
			readPtr = [self baseAddress] + sizeof( SCBHeader ) - sizeof( tCBWord );
		}
	}
	else {
		// Two smaller copies. first read to the end
		tCBWord numLongsToEnd = (maxAddress - readPtr)/sizeof(tCBWord);
		[self readLongBlock:readPtr blocks:numLongsToEnd atPtr:aBlockOfMemory];
		
		//reset the tail
		readPtr = [self baseAddress] + sizeof( SCBHeader ) - sizeof( tCBWord);
		
		//read the reset
		[self readLongBlock:readPtr blocks:blockSize - numLongsToEnd
					  atPtr:aBlockOfMemory+numLongsToEnd];
		
		readPtr += (blockSize - numLongsToEnd)*sizeof(tCBWord);
	}
	// Calculate tail and blocks/bytes read
	theControlBlockHeader->blocksRead++;
	theControlBlockHeader->bytesRead += blockSize*sizeof(tCBWord);
	if( theControlBlockHeader->bytesRead > theControlBlockHeader->cbNumWords*sizeof(tCBWord) )
		theControlBlockHeader->bytesRead -= theControlBlockHeader->cbNumWords*sizeof(tCBWord);
	theControlBlockHeader->qTail = (tCBWord *)readPtr;
	
	[self writeControlBlockHeader:theControlBlockHeader];
	
	return blockSize;
}


-(BOOL) takeData:(ORDataPacket*)aDataPacket  userInfo:(NSDictionary*)userInfo
{
	return [self getDataFromCB:aDataPacket userInfo:userInfo];
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	SCBHeader theControlBlockHeader = [self readControlBlockHeader];
	long numBlocks = theControlBlockHeader.blocksWritten - theControlBlockHeader.blocksRead;
	if(numBlocks){
		NSLog(@"Flushing %d block%@from CB\n",numBlocks,numBlocks>1?@"s ":@" ");
		[self getDataFromCB:aDataPacket userInfo:userInfo];
	}
}
@end

@implementation ORCircularBufferReader (private)

-(BOOL) getDataFromCB:(ORDataPacket*)aDataPacket  userInfo:(NSDictionary*)userInfo
{
	SCBHeader theControlBlockHeader = [self readControlBlockHeader];
	tCBWord numBlocks = theControlBlockHeader.blocksWritten - theControlBlockHeader.blocksRead;
	BOOL wasData = numBlocks>0;
	for(;numBlocks--;){
		tCBWord readPtr = (tCBWord)theControlBlockHeader.qTail;
		tCBWord s1;
		[self readLong:readPtr atPtr:&s1];
		if(s1 && s1 < (DATA_CIRC_BUF_SIZE_BYTE - sizeof( SCBHeader ) + sizeof( tCBWord))){
			unsigned long* ptr = [aDataPacket getBlockForAddingLongs:s1-1];	//first block is the CB header, it	
			[self readBlockUsing:&theControlBlockHeader into:ptr size:s1];   //will be skipped.
		}
		else {
			//retry
			[self readLong:readPtr atPtr:&s1];
			if(s1 && s1 < (DATA_CIRC_BUF_SIZE_BYTE - sizeof( SCBHeader ) + sizeof( tCBWord))){
				unsigned long* ptr = [aDataPacket getBlockForAddingLongs:s1-1];	//first block is the CB header, it	
				[self readBlockUsing:&theControlBlockHeader into:ptr size:s1];   //will be skipped.
			}
			else {
				//whoaa... big problems. just flush it all
				NSLogColor([NSColor redColor],@"resync'ed CB\n");
				theControlBlockHeader.qTail = theControlBlockHeader.qHead;
				theControlBlockHeader.blocksRead = theControlBlockHeader.blocksWritten;
				theControlBlockHeader.bytesRead = theControlBlockHeader.bytesWritten;
				[self writeControlBlockHeader:&theControlBlockHeader];
				wasData = NO;
				break;
			}
		}
	}
	return wasData;
	
}
@end



