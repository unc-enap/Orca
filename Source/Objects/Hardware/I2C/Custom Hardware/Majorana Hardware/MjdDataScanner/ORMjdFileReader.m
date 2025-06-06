//
//  ORMjdFileReader.m
//
//  Created by Mark Howe on 08/4/2015.
//  Copyright 2015 University of North Carolina. All rights reserved.
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORMjdFileReader.h"
#import "ORDataTypeAssigner.h"
#import "ORDataProcessing.h"
#import "ORMjdDataScannerModel.h"

#define kAmountToRead 5*1024*1024

@implementation ORMjdFileReader
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
		uint32_t dataId		= ExtractDataId(firstWord);
		uint32_t recordLength	= ExtractLength(firstWord);
		if(p+recordLength <= endPtr){
			if(dataId == 0x0){
                //this is the header
				runEnded = NO;
				[currentDecoder loadHeader:p];
                runDataID   = (uint32_t)[[currentDecoder headerObject:@"dataDescription",@"ORRunModel",    @"Run",        @"dataId",nil] longValue];
                gretina4ID  = (uint32_t)[[currentDecoder headerObject:@"dataDescription",@"ORGretina4M",   @"Gretina4",   @"dataId",nil] longValue];
                gretina4MID = (uint32_t)[[currentDecoder headerObject:@"dataDescription",@"ORGretina4M",   @"Gretina4M",  @"dataId",nil] longValue];
                gretina4AID = (uint32_t)[[currentDecoder headerObject:@"dataDescription",@"ORGretina4A",   @"Gretina4A",  @"dataId",nil] longValue];
                v830ID      = (uint32_t)[[currentDecoder headerObject:@"dataDescription",@"ORCV830Model",  @"Event",      @"dataId",nil] longValue];
                v792ID      = (uint32_t)[[currentDecoder headerObject:@"dataDescription",@"ORCaen792Model",@"QdcN",       @"dataId",nil] longValue];

                
			}
            else if(dataId == runDataID){
                [self processRunRecord:p];
            }
            else if(dataId == gretina4ID){
                [self processGretina4Record:p];
            }
            else if(dataId == gretina4MID){
                [self processGretina4MRecord:p];
            }
            else if(dataId == gretina4AID){
                [self processGretina4ARecord:p];
            }
            else if(dataId == v830ID){
                [self processScalerRecord:p];
            }
            else if(dataId == v792ID){
                [self processQDCRecord:p];
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
	}
	else {
		if(theDataWord & 0x1){
			[self loadRunInfo:p];
            
            NSNumber* runNumber    = [runInfo objectForKey:kRunNumber];
            NSNumber* subRunNumber = [runInfo objectForKey:kSubRunNumber];
            NSString* run;
            if([subRunNumber longValue]!=0)run = [NSString stringWithFormat:@"%@.%@",runNumber,subRunNumber];
            else run = [NSString stringWithFormat:@"%@",runNumber];
            NSLog(@"---------------------------\n");
            NSLog(@"Run #: %@\n",run);
            totalScalerCount    = 0;
            badScalerCount      = 0;
            gretinaEventsCount  = 0;
            gretinaOutOfOrderCount = 0;
            badGretinaHeaderCount  = 0;
            totalQdcCount       = 0;
        }
		else if(theDataWord & 0x10){
            //between subruns
		}
		else if(theDataWord & 0x20){
            //subrun start
		}
		else {
			runEnded = YES;
            if(totalScalerCount!=0){
                NSLog(@"Total Scaler events: %d. (%d were bad reads)\n",totalScalerCount,badScalerCount);
                NSLog(@"Percent of Bad Scaler reads: %.2f%%\n",100.* badScalerCount/(float)totalScalerCount);
            }
            else NSLog(@"No scaler events\n");
            
            if(gretinaEventsCount!=0){
                NSLog(@"Total Gretina events: %d. (%d timestamps out of order)\n",gretinaEventsCount,gretinaOutOfOrderCount);
                NSLog(@"Percent of timestamps out of order: %.2f%%\n",100.* gretinaOutOfOrderCount/(float)gretinaEventsCount);
                NSLog(@"Total Gretina events with obviously bad headers: %d.\n",badGretinaHeaderCount);
                NSLog(@"Percent with bad headers: %.2f%%\n",100.* badGretinaHeaderCount/(float)gretinaEventsCount);
            }
            else NSLog(@"No gretina events\n");
            if(totalQdcCount){
                NSLog(@"Total QDC events: %d\n",totalQdcCount);
                if(totalQdcCount/2 == totalScalerCount){
                    NSLog(@"Total QDC events is exactly double the scaler events as expected\n");
                }
                else NSLog(@"QDC events did NOT match scaler events\n");

            }
            else NSLog(@"No QDC events\n");
            NSLog(@"---------------------------\n");
		}
	}
}

#define ExtractLength(x) (IsShortForm(x) ? 1 : ((x) & ~kLongFormDataIdMask))

- (void) processGretina4Record:(uint32_t*)dataRecord
{
 }

- (void) processGretina4MRecord:(uint32_t*)dataRecord
{
    //first word is the dataID and Record Length
    uint32_t recordLength = ExtractLength(dataRecord[0]);
    uint32_t numEvents = (recordLength-2)/1024;  //records can have more than one event
    
    //next is the location
    int crate     = (dataRecord[1]>>21) & 0xf;
    int card      = (dataRecord[1]>>16) & 0x1f;
    
    uint32_t* ptr = &dataRecord[2];
    
    int i;
    uint32_t* dataPtr = ptr;
    for(i=0;i<numEvents;i++){
        uint32_t* header = dataPtr;
        
        if(header[0] == 0xAAAAAAAA){
            int channel	= header[1] & 0xF; //extract the channel
            if(channel>=10)badGretinaHeaderCount++;
            else {
                //extract the energy.
                //energy is in 2's complement. if top bit is set, we have to convert
                //uint32_t energy = ((header[4] & 0x000001ff) << 16) | (header[3] >> 16);
                //if (energy & 0x1000000) energy = (~energy & 0x1ffffff) + 1;
                
                uint64_t ledTimeStamp = ((uint64_t)(header[3]&0xFFFF)<<32) | header[2];
               // uint64_t cfdTimeStamp = ((uint64_t)(header[4]&0xFFFF)>>16) | ((uint64_t)header[2]<<32);
                
                if(card<20 && channel<10){
                    if(ledTimeStamp>lastTimeStamp[card][channel]){
                        lastTimeStamp[card][channel] = ledTimeStamp;
                    }
                    else {
                        NSLog(@"gretina4M timestamp out of order on %d,%d,%d at event %d\n",crate,card,channel,gretinaEventsCount);
                        gretinaOutOfOrderCount++;
                   }
                }
                
                //NSLog(@"%d,%d,%d ledTS: %d\n",crate,card,channel,ledTimeStamp);
                //NSLog(@"%d,%d,%d cfdTS: %d\n",crate,card,channel,cfdTimeStamp);
            }
            
            dataPtr += 1024; //point to next record. fixed size records for this card
            gretinaEventsCount++;
        }
        else {
            //NO Packet separator -- can't trust this record
            break;
        }
    }
}

- (void) processGretina4ARecord:(uint32_t*)p
{
}
- (void) processQDCRecord:(uint32_t*)dataRecord
{
    totalQdcCount++;
}
- (void) processScalerRecord:(uint32_t*)dataRecord
{
    /* Event Record
     xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
     ^^^^ ^^^^ ^^^^ ^^----------------------- V830 ID (from header)
     -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length (variable)
     xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
     --------^-^^^--------------------------- Crate number
     -------------^-^^^^--------------------- Card number
     xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx- Chan0 Roll over
     xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx- Enabled Mask
     xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  header
     xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter 0
     ..
     ..
     xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter 31 //note that only enabled channels are included so list may be shorter
     */
    
    //int crate     = (dataRecord[1]>>21) & 0xf;
    //int card      = (dataRecord[1]>>16) & 0x1f;
    
    //for MJD, only one  event is readout at a time. And the only one we care about is chan 0. Check that it is enabled.
    if(dataRecord[3] & 0x1){
        //get the Chan 0 roll over and combine with chan 0 to get the time stamp
        uint64_t timeStamp = ((uint64_t)dataRecord[2]<<32) | dataRecord[5];
        //NSLog(@"scaler timestamp: 0x%016llx\n",timeStamp);
        if(timeStamp == 0xffffffffffffffff)badScalerCount++;
        totalScalerCount++;
    }
}


- (void) loadRunInfo:(uint32_t*)dataRecord
{
	//pack up some info about the run.
	[runInfo release];
    runInfo = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
				[self currentHeader],                        kHeader,
				[NSNumber numberWithLong:dataRecord[2]],     kRunNumber,
				[NSNumber numberWithLong:dataRecord[1]>>16], kSubRunNumber,
				[NSNumber numberWithLong:kNormalRun],        kRunMode,
				nil] retain];
	
}

@end
