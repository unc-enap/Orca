//
//  ORCommandList.m
//  Orca
//
//  Created by Mark Howe on 12/11/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
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

#import "ORCommandList.h"

@implementation ORCommandList 
+ (id) commandList
{
	return [[[ORCommandList alloc] init] autorelease];
}

- (void) dealloc
{
	[commands release];
	[super dealloc];
}
- (NSEnumerator*) objectEnumerator
{
	return [commands objectEnumerator];
}
- (NSMutableArray*) commands
{
	return commands;
}

- (int) addCommand:(id)aCommand
{
	if(aCommand){
		if(!commands)commands = [[NSMutableArray array] retain];
		[commands addObject:aCommand];
		return [commands count] - 1;
	}
	else return -1;
}
- (int) addCommands:(ORCommandList*)anOtherList
{
	if(anOtherList){
		if(!commands)commands = [[NSMutableArray array] retain];
		[commands addObjectsFromArray:[anOtherList commands]];
		return [commands count] - 1;
	}
	else return -1;
}

- (id) command:(int)index
{
	if(index>=0 && index<[commands count]){
		return [commands objectAtIndex:index];
	}
	else return nil;
}

- (void) SBCPacket:(SBC_Packet*)blockPacket
{
	//make the main header
	blockPacket->cmdHeader.destination			= kSBC_Process;
	blockPacket->cmdHeader.cmdID				= kSBC_CmdBlock;
	blockPacket->cmdHeader.numberBytesinPayload	= 0; //fill in as we go
	char* blockPayloadPtr				= (char*)blockPacket->payload;
    
    // We use an NSData object so we can put the packet on the heap and if any exceptions are thrown, we can cleanup.
    NSData* tmpData = [[NSMutableData dataWithLength:sizeof(SBC_Packet)]retain];
    if(tmpData){
        @try {
            SBC_Packet* cmdPacket = (SBC_Packet*)[tmpData bytes];
            
            for(id aCmd in commands){
                [aCmd SBCPacket:cmdPacket];
                if (blockPacket->cmdHeader.numberBytesinPayload + cmdPacket->numBytes > kSBC_MaxPayloadSizeBytes) {
                    [NSException raise: @"SBC/VME access Error" format:@"Memory overflow on SBC_Packet"];
                }
                memcpy(blockPayloadPtr,cmdPacket,cmdPacket->numBytes);

                blockPacket->cmdHeader.numberBytesinPayload += cmdPacket->numBytes;
                blockPayloadPtr += cmdPacket->numBytes;
            }
        }
        @catch (NSException * e) {
            [e raise];
        }
        @finally {
            [tmpData release];
        }
    }
    else {
        [NSException raise: @"SBC/VME allocation Error" format:@"Could not allocate memory for the SBC_Packet"];
    }
}

- (void) extractData:(SBC_Packet*) aPacket
{
	unsigned long totalBytesToProcess = aPacket->cmdHeader.numberBytesinPayload;
	char* dataToProcess = (char*) aPacket->payload;
	for(id aCmd in commands){
		SBC_Packet* packetToProcess = (SBC_Packet*)dataToProcess;
		[aCmd extractData:packetToProcess];
		dataToProcess += packetToProcess->numBytes;
		totalBytesToProcess -= packetToProcess->numBytes;
		if(totalBytesToProcess<=0)break; //we should drop out after all cmds processed, but just in case
	}
}
- (long) longValueForCmd:(int)anIndex
{
	if(anIndex<[commands count]){
		return [[commands objectAtIndex:anIndex] longValue];
	}
	else return 0;
}

- (short) shortValueForCmd:(int)anIndex
{
	if(anIndex<[commands count]){
		return [[commands objectAtIndex:anIndex] shortValue];
	}
	else return 0;
}
- (NSData*) dataForCmd:(int)anIndex
{
	if(anIndex<[commands count]){
		return [commands objectAtIndex:anIndex];
	}
	else return 0;
}

@end

