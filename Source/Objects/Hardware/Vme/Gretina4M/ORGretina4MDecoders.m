//
//  ORGretina4MDecoders.m
//  Orca
//
//  Created by Mark Howe on 02/07/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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


#import "ORGretina4MDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORGretina4MModel.h"
#include <sys/time.h>

#define kIntegrateTimeKey @"Integration Time"
#define kHistEMultiplierKey @"Hist E Multiplier"

@implementation ORGretina4MWaveformDecoder
- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualGretinaCards release];
    [super dealloc];
}
- (void) registerNotifications
{
	[super registerNotifications];
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(integrateTimeChanged:) name:ORGretina4MCardInited object:nil];
	[nc addObserver:self selector:@selector(histEMultiplierChanged:) name:ORGretina4MModelHistEMultiplierChanged object:nil];
}

- (void) integrateTimeChanged:(NSNotification*)aNote
{
	ORGretina4MModel* theCard	= [aNote object];
	NSString* crateKey			= [self getCrateKey: [theCard crateNumber]];
	NSString* cardKey			= [self getCardKey: [theCard slot]];
	[self setObject:[NSNumber numberWithInt:[theCard integrateTime]] forNestedKey:crateKey,cardKey,kIntegrateTimeKey,nil];
}

- (void) histEMultiplierChanged:(NSNotification*)aNote
{
	ORGretina4MModel* theCard	= [aNote object];
	NSString* crateKey			= [self getCrateKey: [theCard crateNumber]];
	NSString* cardKey			= [self getCardKey: [theCard slot]];
	[self setObject:[NSNumber numberWithInt:[theCard histEMultiplier]] forNestedKey:crateKey,cardKey,kHistEMultiplierKey,nil];
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

	if(![self cacheSetUp]){
		[self cacheCardLevelObject:kIntegrateTimeKey fromHeader:[aDecoder fileHeader]];
		[self cacheCardLevelObject:kHistEMultiplierKey fromHeader:[aDecoder fileHeader]];
	}
	
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
    
	ptr++; //point to location info
    int crate = (*ptr&0x01e00000)>>21;
    int card  = (*ptr&0x001f0000)>>16;
    
    int numEvents = (int)(length-2)/1024;

    ptr++; //point to first word of first data record
    int headerSize = 14; //int32_t words
    int i;
    uint32_t* dataPtr = ptr;
    for(i=0;i<numEvents;i++){
        if(*dataPtr == 0xAAAAAAAA){
            uint32_t *nextRecordPtr = dataPtr+1024;
            dataPtr++;
            int channel	= *dataPtr & 0xF; //extract the channel
            dataPtr += 2;                 //point to Energy low word
            uint32_t energy = *dataPtr >> 16;
            
            dataPtr++;	  //point to Energy second word
            energy += (*dataPtr & 0x000001ff) << 16;
            
            //energy is in 2's complement, take abs value if necessary
            if (energy & 0x1000000) energy = (~energy & 0x1ffffff) + 1;

            NSString* crateKey	 = [self getCrateKey: crate];
            NSString* cardKey	 = [self getCardKey: card];
            NSString* channelKey = [self getChannelKey: channel];

            int histEMultiplier = [[self objectForNestedKey:crateKey,cardKey,kHistEMultiplierKey,nil] intValue];
            if(histEMultiplier) energy *= histEMultiplier;

            int integrateTime = [[self objectForNestedKey:crateKey,cardKey,kIntegrateTimeKey,nil] intValue];
            if(integrateTime) energy /= integrateTime; 
            
            [aDataSet histogram:energy numBins:0x1fff sender:self  withKeys:@"Gretina4",@"Energy",crateKey,cardKey,channelKey,nil];
            
            
            BOOL fullDecode = NO;
            
            struct timeval tv;
            gettimeofday(&tv, NULL);
            
            uint64_t now =
                (uint64_t)(tv.tv_sec) * 1000 +
                (uint64_t)(tv.tv_usec) / 1000;
            
            if(!decoderOptions){
                decoderOptions = [[NSMutableDictionary dictionary]retain];
            }
            
            NSString* lastTimeKey = [NSString stringWithFormat:@"%@,%@,%@,LastTime",crateKey,cardKey,channelKey];
            
            uint64_t lastTime = [[decoderOptions objectForKey:lastTimeKey] unsignedLongLongValue];

            if(now - lastTime >= 100){
                fullDecode = YES;
                [decoderOptions setObject:[NSNumber numberWithUnsignedLongLong:now] forKey:lastTimeKey];
            }
            BOOL someoneWatching = NO;
            if([aDataSet isSomeoneLooking:[NSString stringWithFormat:@"Gretina4,Waveforms,%d,%d,%d",crate,card,channel]]){
                someoneWatching = YES;
            }
            
            NSMutableData* tmpData = nil;
            if(lastTime==0 || (fullDecode && someoneWatching)){
            
                dataPtr += 11; //point to the data

                tmpData = [NSMutableData dataWithCapacity:512*2];
                  
                int dataLength = 1024 - headerSize -1;
                [tmpData setLength:dataLength*sizeof(int32_t)];
                short* dPtr = (short*)[tmpData bytes];
                int i;
                int wordCount = 0;
                //data is actually 2's complement. detwiler 08/26/08
                for(i=0;i<dataLength;i++){
                    dPtr[wordCount++] =    (0x0000ffff & *dataPtr);
                    dPtr[wordCount++] =    (0xffff0000 & *dataPtr) >> 16;
                    dataPtr++;
                }
            }
            [aDataSet loadWaveform:tmpData
                            offset:0 //bytes!
                          unitSize:2 //unit size in bytes!
                            sender:self
                          withKeys:@"Gretina4",@"Waveforms",crateKey,cardKey,channelKey,nil];
  
            //get the actual object
            NSString* aKey = [crateKey stringByAppendingString:cardKey];
            if(!actualGretinaCards)actualGretinaCards = [[NSMutableDictionary alloc] init];
            ORGretina4MModel* obj = [actualGretinaCards objectForKey:aKey];
            if(!obj){
                NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORGretina4MModel")];
                NSEnumerator* e = [listOfCards objectEnumerator];
                ORGretina4MModel* aCard;
                while(aCard = [e nextObject]){
                    if([aCard slot] == card && [aCard crateNumber] == crate){
                        [actualGretinaCards setObject:aCard forKey:aKey];
                        obj = aCard;
                        break;
                    }
                }
            }
            if(channel>=0 && channel<kNumGretina4MChannels){
                [obj bumpRateFromDecodeStage:channel];
            }
            
            dataPtr = nextRecordPtr;
        }
        else {
            headerSize = 0;
  
        }
    }
    
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t* headerStartPtr = ptr+2;

    NSString* title= @"Gretina4M Waveform Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(ptr[1]&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(ptr[1]&0x001f0000)>>16];
    NSString* fifoState  = [NSString stringWithFormat:@"FifoState  = 0x%04x\n",(ptr[1]>>30)&0x3];

    NSString* crateKey			= [self getCrateKey: (ptr[1]&0x01e00000)>>21];
	NSString* cardKey			= [self getCardKey: (ptr[1]&0x001f0000)>>16];

    //recast pointer to short and point to the actual data header
    unsigned short* headerPtr = (unsigned short*)(ptr+2);
    NSString* chan  = [NSString stringWithFormat:@"Chan  = %d\n",headerPtr[2]&0xf];
    
	uint32_t energy = headerPtr[7] + (headerPtr[8] << 16);
	
	// energy is in 2's complement, taking abs value if necessary
	if (energy & 0x1000000) energy = (~energy & 0x1ffffff) + 1;
    
    NSString* rawEnergyStr = [NSString stringWithFormat:@"Raw Energy  = 0x%08x\n",energy];

    int histEMultiplier = [[self objectForNestedKey:crateKey,cardKey,kHistEMultiplierKey,nil] intValue];
    if(histEMultiplier) energy *= histEMultiplier;
    
    int integrateTime = [[self objectForNestedKey:crateKey,cardKey,kIntegrateTimeKey,nil] intValue];
    if(integrateTime) energy /= integrateTime;
    
	NSString* energyStr  = [NSString stringWithFormat:@"Energy  = %u\n",energy];
    
    uint64_t timeStamp = ((uint64_t)headerPtr[6] << 32) + ((uint64_t)headerPtr[5] << 16) + (uint64_t)headerPtr[4];
    NSString* timeStampString = [NSString stringWithFormat:@"Time: %lld\n",timeStamp];
    
    NSString* header = @"Header (Raw)\n";
    int i;
    for(i=0;i<15;i++){
        header = [header stringByAppendingFormat:@"%d: 0x%08x\n",i,headerStartPtr[i]];
    }
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@",title,crate,card,chan,fifoState,timeStampString,rawEnergyStr,energyStr,header];
}

@end
