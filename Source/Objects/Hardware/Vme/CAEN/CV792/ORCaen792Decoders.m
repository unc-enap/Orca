//
//  ORCaenDataDecoders.m
//  Orca
//
//  Created by Mark Howe on Tues June 1 2010.
//  Copyright © 2010 University of North Carolina. All rights reserved.
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

#import "ORCaen792Decoders.h"
#import "ORDataSet.h"
#import "ORCaen792Model.h"

//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs 
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                                      ^-this bit set if timestamp option selected
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-seconds since Jan 1,1970       (OPTIONAL...only included if timestamp option selected)
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-microseconds since last second (OPTIONAL...only included if timestamp option selected)
//data from the data buffer follows as per the manual


@implementation ORCAEN792DecoderForQdc
- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}
- (void) dealloc
{
	[actualCards release];
    [super dealloc];
}
- (uint32_t) decodeData:(void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*) aDataSet
{
    short i;
    int32_t* ptr   = (int32_t*) aSomeData;
	int32_t length = ExtractLength(ptr[0]);
    int crate   = ShiftAndExtract(ptr[1],21,0xf);
    int card    = ShiftAndExtract(ptr[1],16,0x1f);
    BOOL timeStampsIncluded = ShiftAndExtract(ptr[1],0,0x1);
    
	NSString* crateKey = [self getCrateKey:crate];
	NSString* cardKey  = [self getCardKey: card];
    NSString* dataKey  = [self dataKey];
    
    int dataStartIndex;
    if(timeStampsIncluded)  dataStartIndex = 4;
    else                    dataStartIndex = 2;
    
    for( i = dataStartIndex; i < length; i++ ){
		int dataType = ShiftAndExtract(ptr[i],24,0x7);
		if(dataType == 0x0){
			int qdcValue = ShiftAndExtract(ptr[i],0,0xfff);
			int chan     = [self channel:ptr[i]];
			NSString* channelKey  = [self getChannelKey: chan];
			[aDataSet histogram:qdcValue numBins:0xfff sender:self withKeys:dataKey,crateKey,cardKey,channelKey,nil];

            //get the actual object
            NSString* aKey = [crateKey stringByAppendingString:cardKey];
            
            if(!actualCards)actualCards = [[NSMutableDictionary alloc] init];
            ORCaen792Model* obj = [actualCards objectForKey:aKey];
            if(!obj){
                NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORCaen792Model")];
                NSEnumerator* e = [listOfCards objectEnumerator];
                ORCaen792Model* aCard;
                while(aCard = [e nextObject]){
                    if([aCard slot] == card){
                        [actualCards setObject:aCard forKey:aKey];
                        obj = aCard;
                        break;
                    }
                }
            }

            [obj bumpRateFromDecodeStage:chan];

        }
    }
    return length;
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	int32_t length = ExtractLength(ptr[0]);
    NSString* title= @"CAEN792 QDC Record\n\n";
	
    NSString* len	=[NSString stringWithFormat: @"# QDC = %u\n",length-2];
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(ptr[1] >> 21)&0x0000000f];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(ptr[1] >> 16)&0x0000001f];    
    BOOL timeStampsIncluded = ptr[1]&0x1;
    
    int dataStartIndex;
    if(timeStampsIncluded){
        dataStartIndex  = 4;
    }
    else dataStartIndex = 2;
	
    NSString* restOfString = [NSString string];
    int i;
    for( i = dataStartIndex; i < length; i++ ){
		int dataType = ShiftAndExtract(ptr[i],24,0x7);
		if(dataType == 0x0){
			int qdcValue = ShiftAndExtract(ptr[i],0,0xfff);
			int channel  = [self channel:ptr[i]];
			restOfString = [restOfString stringByAppendingFormat:@"Chan  = %d  Value = %d\n",channel,qdcValue];
        }
    }
    if(timeStampsIncluded){
        NSString* seconds         = [NSString stringWithFormat:@"Seconds      = %u\n",ptr[2]];
        NSString* microseconds    = [NSString stringWithFormat:@"Microseconds = %u\n",ptr[3]];
        return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,len,crate,card,seconds,microseconds,restOfString];
    }
    else return [NSString stringWithFormat:@"%@%@%@%@%@",title,len,crate,card,restOfString];
}

- (unsigned short) channel: (uint32_t) pDataValue
{
    return	ShiftAndExtract(pDataValue,16,0x1F);
}
- (NSString*) identifier
{
    return @"CAEN 792 QDC";
}
- (NSString*) dataKey
{
    return @"CAEN792 QDC";
}
@end

@implementation ORCAEN792NDecoderForQdc

- (unsigned short) channel: (uint32_t) pDataValue
{
    return	ShiftAndExtract(pDataValue,17,0xF);
}
- (NSString*) identifier
{
    return @"CAEN 792N QDC";
}
- (NSString*) dataKey
{
    return @"CAEN792N QDC";
}

@end

