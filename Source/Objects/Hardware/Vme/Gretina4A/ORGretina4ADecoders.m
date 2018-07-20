//
//  ORGretina4ADecoders.m
//  Orca
//
//  Created by Mark A. Howe on Wednesday 11/20/14.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//Washington sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#import "ORGretina4ADecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORGretina4AModel.h"

#define kIntegrateTimeKey @"Integration Time"
#define kHistEMultiplierKey @"Hist E Multiplier"

@implementation ORGretina4AWaveformDecoder
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

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
//#define koffset -8170
#define koffset 0
	if(![self cacheSetUp]){
		[self cacheCardLevelObject:kIntegrateTimeKey fromHeader:[aDecoder fileHeader]];
		[self cacheCardLevelObject:kHistEMultiplierKey fromHeader:[aDecoder fileHeader]];
	}
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(ptr[0]);
    //point to ORCA location info
    int crate           = (ptr[1]>>21)&0xf;
    int card            = (ptr[1]>>16)&0x1f;
    NSString* crateKey	= [self getCrateKey: crate];
    NSString* cardKey	= [self getCardKey: card];
    ptr = &ptr[2]; //move the pointer up to the data header
    if(ptr[0] == 0xAAAAAAAA){
        int             channel         = ptr[1] & 0xF;
        NSString*       channelKey      = [self getChannelKey: channel];
        int             headerLength    = (ptr[3] >> 26) & 0x3f;
//      int             packetLength    = (ptr[1] >> 16) & 0x7ff;
//      int             dataLength      = (packetLength - headerLength)/2;
        uint32_t   sumWord1        = ptr[8];
        uint32_t   sumWord2        = ptr[9];
        uint32_t   scaleFactor     = 0xfff;
        uint32_t   postRiseSum     = ((sumWord2 & 0xFFFF)<< 8) | ((sumWord1 >> 24) & 0xff);
        uint32_t   preRiseSum      = sumWord1 & 0xFFFFFF;
        int32_t            energy          = (postRiseSum - preRiseSum)/scaleFactor;
        if(energy >= 0){
            [aDataSet histogram:energy numBins:0xFFFFFF/scaleFactor  sender:self  withKeys:@"Gretina4",@"Energy",crateKey,cardKey,channelKey,nil];
        }
    
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
        
        BOOL fullDecode = NO;
        if(now - lastTime >= 100){
            fullDecode = YES;
            [decoderOptions setObject:[NSNumber numberWithUnsignedLongLong:now] forKey:lastTimeKey];
        }
        
        BOOL someoneWatching = NO;
        if([aDataSet isSomeoneLooking:[NSString stringWithFormat:@"Gretina4,Waveforms,%d,%d,%d",crate,card,channel]]){
            someoneWatching = YES;
        }
        
        NSMutableData* waveformData = nil;
        if(lastTime==0 || (fullDecode && someoneWatching)){
            waveformData = [NSMutableData dataWithBytes:&ptr[0] length:(length-4)*sizeof(int32_t)];
        }
        
        [aDataSet loadWaveform: waveformData     //pass in the whole data set, if nil it will be counted only
                        offset: headerLength*2   // Offset in bytes (past header words)
                      unitSize: sizeof(short)    // unit size in bytes
                    startIndex:	0                // first Point Index
                   scaleOffset: koffset          // offset the value by this
                          mask:	0x3FFF           // display mask for all values
                   specialBits: 0xC000
                      bitNames: [NSArray arrayWithObjects:@"M",@"O",nil]
                        sender: self 
                      withKeys: @"Gretina4",@"Waveforms",crateKey,cardKey,channelKey,nil];

        //get the actual object
        NSString* aKey = [crateKey stringByAppendingString:cardKey];
        if(!actualGretinaCards)actualGretinaCards = [[NSMutableDictionary alloc] init];
        ORGretina4AModel* obj = [actualGretinaCards objectForKey:aKey];
        if(!obj){
            NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORGretina4AModel")];
            for(ORGretina4AModel* aCard in listOfCards){
                if([aCard slot] == card){
                    [actualGretinaCards setObject:aCard forKey:aKey];
                    obj = aCard;
                    break;
                }
            }
        }
        [obj bumpRateFromDecodeStage:channel];
    }
	 
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t* headerStartPtr = ptr+2;

    NSString* title= @"Gretina4A Waveform Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(ptr[1]&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(ptr[1]&0x001f0000)>>16];

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
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",title,crate,card,chan,timeStampString,rawEnergyStr,energyStr,header];
}

@end
