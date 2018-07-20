//
//  ORFileReader.m
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

#import "ORFileReader.h"
#import "ORDataTypeAssigner.h"
#import "ORDataProcessing.h"
#import "ORReplayDataModel.h"

#define kAmountToRead 5*1024*1024

@implementation ORFileReader
- (id)initWithPath:(NSString*)aPath delegate:(id)aDelegate
{
	self = [super initWithPath:aPath delegate:aDelegate];
    return self;
}

- (void) dealloc
{
	
	if([delegate respondsToSelector:@selector(checkStatus)]){
		[delegate performSelectorOnMainThread:@selector(checkStatus)
								   withObject:nil
								waitUntilDone:YES];
	}
		
	[dataArray release];
	[dataToProcess release];
	[runInfo release];
		
	[super dealloc];
}


- (void) main 
{
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];

	if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
		NSLog(@"<%@> does not exist.\n",filePath);
        [thePool release];
		return;
	}
    @try {
        NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:filePath];
        if([currentDecoder legalDataFile:fh]){
            dataToProcess = [[NSMutableData dataWithCapacity:kAmountToRead] retain];
            [dataToProcess appendData:[fh readDataOfLength:kAmountToRead]];
            if([delegate respondsToSelector:@selector(setFileToReplay:)]){
                [delegate setFileToReplay:filePath];
            }
            dataArray = [[NSMutableArray arrayWithCapacity:1024*1024] retain];

            NSDictionary *fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            int64_t totalSize = [[fattrs objectForKey:NSFileSize] longLongValue];
            int64_t totalProcessed = 0;
            while([dataToProcess length]!=0) {
                NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
                if([delegate respondsToSelector:@selector(cancelAndStop)]){
                    if([delegate cancelAndStop]) {
                        [pool release];
                        break;
                    }
                }
                if([dataToProcess length]!=0){
                    [self processData];
                    NSData* newData = [fh readDataOfLength:kAmountToRead];
                    if([newData length] == 0){
                        [pool release];
                        break;
                    }
                    totalProcessed += [newData length];
                    [dataToProcess appendData:newData];
                    if([delegate respondsToSelector:@selector(updateProgress:)]){
                        [delegate performSelectorOnMainThread:@selector(updateProgress:)
                                                   withObject:[NSNumber numberWithFloat:100.*((double)totalProcessed/(double)totalSize)]
                                                waitUntilDone:NO];
                    }
                }
                else {
                    [pool release];
                    break;
                }
                [pool release];
            }
            if([dataArray count]){
                [delegate sendDataArray:dataArray decoder:currentDecoder];
                [dataArray removeAllObjects];
            }
            if([delegate respondsToSelector:@selector(updateProgress:)]){
                [delegate performSelectorOnMainThread:@selector(updateProgress:)
                                           withObject:[NSNumber numberWithFloat:100.]
                                        waitUntilDone:YES];
            }
        }
        [fh closeFile];
    }
    @catch (NSException* e){
        NSLog(@"Replay halted abnormally\n");
        NSLog(@"%@\n",e);
    }
    @finally {
        [thePool release];
    }
}

- (void) processData
{
	uint32_t* p			= (uint32_t*)[dataToProcess bytes];
	uint32_t* endPtr		= p + [dataToProcess length]/sizeof(int32_t);
	uint32_t bytesProcessed	= 0;
	while(p<endPtr){
		uint32_t firstWord		= *p;
		if(needToSwap)firstWord		= (uint32_t)CFSwapInt32((uint32_t)*p);
		uint32_t dataId		= ExtractDataId(firstWord);
		uint32_t recordLength	= ExtractLength(firstWord);
		if(p+recordLength <= endPtr){
			if(needToSwap){
				[currentDecoder byteSwapData:p forKey:[NSNumber numberWithLong:dataId]];
			}
			if(dataId == 0x0){
				runEnded = NO;
				[currentDecoder loadHeader:p];
				runDataID = (uint32_t)[[currentDecoder headerObject:@"dataDescription",@"ORRunModel",@"Run",@"dataId",nil] longValue];
			}
			else if(dataId == runDataID){
				[self processRunRecord:p];
			}
			NSData* theDataRecord = [[NSData alloc] initWithBytes:p length:recordLength*sizeof(int32_t)];
			[dataArray addObject:theDataRecord];
			[theDataRecord release];
			if(runEnded || [dataArray count] > 10){
				[delegate sendDataArray:dataArray decoder:currentDecoder];
				[dataArray removeAllObjects];
				if(runEnded){
					[delegate sendCloseOutRun:runInfo];
				}
			}
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
	uint32_t theDataWord = *(p+1);

	if((theDataWord & 0x8)){
		//heart beat
	}
	else {
		if(theDataWord & 0x1){
			[self loadRunInfo:p];
			[delegate sendRunStart:runInfo];
		}
		else if(theDataWord & 0x10){
		}
		else if(theDataWord & 0x20){
			[delegate sendRunSubRunStart:runInfo];
		}
		else {
			[delegate sendRunEnd:runInfo];
			runEnded = YES;
		}
	}
}

- (void) loadRunInfo:(uint32_t*)p
{
	//pack up some info about the run.
	[runInfo release];
    runInfo = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
				[self currentHeader], kHeader,
				[NSNumber numberWithLong:p[2]],kRunNumber,
				[NSNumber numberWithLong:p[1]>>16],kSubRunNumber,
				[NSNumber numberWithLong:kNormalRun],  kRunMode,
				nil] retain];
	
}

- (void) shipCurrentHeader
{
	NSData* headerRecord = [currentDecoder headerAsData];
	if(headerRecord){
		[dataArray addObject:headerRecord];
	}
}


@end
