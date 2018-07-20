//
//  ORHeaderCollector.m
//  OrcaIntel
//
//  Created by Mark Howe on 11/14/2009.
//  Copyright 2009 CENPA, University of North Carolina. All rights reserved.
//
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

#import "ORHeaderExplorerModel.h"
#import "ORHeaderCollector.h"
#import "ORDataTypeAssigner.h"

#define kAmountToRead 10*1024*1024

@implementation ORHeaderCollector

- (id)initWithPath:(NSString*)aPath delegate:(id)aDelegate
{
	self = [super initWithPath:aPath delegate:aDelegate];
	
	NSDictionary *fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath:aPath error:nil];
	fileSize = [[fattrs objectForKey:NSFileSize] longLongValue];

    return self;
}

- (void) dealloc
{
	
	if([delegate respondsToSelector:@selector(checkStatus)]){
		[delegate performSelectorOnMainThread:@selector(checkStatus)
								   withObject:nil
								waitUntilDone:YES];
	}
	
	[dataToProcess release];
		
	[super dealloc];
}

- (void) main 
{
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];

	NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:filePath];
	if([currentDecoder legalDataFile:fh]){
		dataToProcess = [[NSMutableData dataWithCapacity:kAmountToRead] retain];
		[dataToProcess appendData:[fh readDataOfLength:kAmountToRead]];
		if([delegate respondsToSelector:@selector(setFileToProcess:)]){
			[delegate setFileToProcess:filePath];
		}

		while([dataToProcess length]!=0) {
			if([delegate respondsToSelector:@selector(cancelAndStop)]){
				if([delegate cancelAndStop]) break;
			}
			if([dataToProcess length]!=0){
				if([delegate respondsToSelector:@selector(updateProgress:)]){
					[delegate performSelectorOnMainThread:@selector(updateProgress:)
								   withObject:[NSNumber numberWithDouble:[dataToProcess length]]
								waitUntilDone:NO];
				}
				[self processData];
				NSData* newData = [fh readDataOfLength:kAmountToRead];
				if([newData length] == 0) break;
				[dataToProcess appendData:newData];
			}
			else break;
		}		
	}
	else NSLog(@"%@ doesn't appear to be a legal ORCA file\n");
    [fh closeFile];
    [thePool release];
}

- (void) processData
{
	uint32_t* p		= (uint32_t*)[dataToProcess bytes];
	uint32_t* endPtr		= p + [dataToProcess length]/sizeof(int32_t);
	uint32_t bytesProcessed	= 0;
	while(p<endPtr){
		uint32_t firstWord		= *p;
		if(needToSwap)firstWord		= (uint32_t)CFSwapInt32((uint32_t)*p);
		uint32_t dataId		= ExtractDataId(firstWord);
		uint32_t recordLength	= ExtractLength(firstWord);
		if(p+recordLength <= endPtr){
			if(dataId == 0x0){
				//[currentDecoder loadHeader:p];
				runDataID = (uint32_t)[[currentDecoder headerObject:@"dataDescription",@"ORRunModel",@"Run",@"dataId",nil] longValue];
			}
			else if(dataId == runDataID){
				[self processRunRecord:p];
			}
			/*
			if(needToSwap){
				[currentDecoder byteSwapData:p forKey:[NSNumber numberWithLong:dataId]];
			}
			*/
			p += recordLength;
			bytesProcessed += recordLength*sizeof(int32_t);
			if(p>=endPtr)break;
		}
		else break;
	}
	[dataToProcess replaceBytesInRange:NSMakeRange( 0, bytesProcessed ) withBytes:NULL length:0];
}

- (void) processRunRecord:(uint32_t*)p
{
	if(needToSwap){
		//NSNumber* aKey = [NSNumber numberWithInt:ExtractLength(CFSwapInt32(p[0]))];
		NSNumber* aKey = [NSNumber numberWithUnsignedLong:runDataID];
		[currentDecoder byteSwapOneRecord:p forKey:aKey];
	}
	if((p[1] & 0x8)){
	}
	else {
		if(p[1] & 0x1){
			currentRunStart = p[3];
		}
		else if(p[1] & 0x10){
			//prepare sub run (end of subrun)
			currentRunEnd = p[3];
			unsigned short subRunNumber = (p[1]&0xFFFF000)>>16;
			[self logHeader:[currentDecoder fileHeader] 
						   runStart:currentRunStart 
							 runEnd:currentRunEnd 
						  runNumber:p[2]
						  useSubRun:subRunNumber!=0
					   subRunNumber:subRunNumber
						   fileSize:(uint32_t)fileSize
						   fileName:filePath];
		}
		else if(p[1] & 0x20){
			//sub run start
			currentRunStart = p[3];
		}
		else {
			//run end
			currentRunEnd = p[3];
			unsigned short subRunNumber = (p[1]&0xFFFF000)>>16;
			[self logHeader:[currentDecoder fileHeader] 
				   runStart:currentRunStart 
					 runEnd:currentRunEnd 
				  runNumber:p[2]
				  useSubRun:subRunNumber!=0
			   subRunNumber:subRunNumber
				   fileSize:(uint32_t)fileSize
				   fileName:filePath];	
		}
	}
}

- (void)logHeader:(NSDictionary*)aHeader
		 runStart:(uint32_t)aRunStart 
		   runEnd:(uint32_t)aRunEnd 
		runNumber:(uint32_t)aRunNumber 
		useSubRun:(uint32_t)aUseSubRun
	 subRunNumber:(uint32_t)aSubRunNumber
		 fileSize:(uint32_t)aFileSize
		 fileName:(NSString*)aFilePath
{
	if([delegate respondsToSelector:@selector(logHeader:runStart:runEnd:runNumber:useSubRun:subRunNumber:fileSize:fileName:)]){
		[delegate logHeader:aHeader 
				   runStart:aRunStart 
					 runEnd:aRunEnd 
				  runNumber:aRunNumber 
				  useSubRun:aUseSubRun
			   subRunNumber:aSubRunNumber
				   fileSize:aFileSize
				   fileName:aFilePath];
		 
	}
}

@end
