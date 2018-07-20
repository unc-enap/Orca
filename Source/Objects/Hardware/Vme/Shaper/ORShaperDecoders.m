//
//  ORShaperDecoders.m
//  Orca
//
//  Created by Mark Howe on 9/21/04.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORShaperDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORShaperModel.h"
#import "ORDataTypeAssigner.h"
//short form:
//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^--------------------------------data id
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                    ^^^^----------------channel
//                         ^^^^ ^^^^ ^^^^-adc value

//int32_t form:
//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs (2 if no timestamp,4 with timestamp
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                    ^^^^----------------channel
//                         ^^^^ ^^^^ ^^^^-adc value
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-seconds since Jan 1,1970 (only included if timestamp option selected)
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-microseconds since last second (only included if timestamp option selected)


@implementation ORShaperDecoderForShaper

- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualShapers release];
    [super dealloc];
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t length;
    uint32_t* ptr = (uint32_t*)someData;
    if(IsShortForm(*ptr))	length = 1;
    else					length= ExtractLength(ptr[0]);
    
	int dataOffset = 0;
	if(length>1) dataOffset = 1;

	int crate			 = ShiftAndExtract(ptr[dataOffset],21,0xf);
	int card			 = ShiftAndExtract(ptr[dataOffset],16,0x1f);
	int channel			 = ShiftAndExtract(ptr[dataOffset],12,0xf);
	
	NSString* crateKey   = [self getCrateKey:	crate];
	NSString* cardKey    = [self getCardKey:	card];
	NSString* channelKey = [self getChannelKey: channel];
	
	
    [aDataSet histogram:ptr[dataOffset]&0x00000fff numBins:4096 sender:self  withKeys:@"Shaper", crateKey,cardKey,channelKey,nil];
	
	//get the actual object
	if(getRatesFromDecodeStage && !skipRateCounts){
		NSString* shaperKey = [crateKey stringByAppendingString:cardKey];
		if(!actualShapers)actualShapers = [[NSMutableDictionary alloc] init];
		ORShaperModel* obj = [actualShapers objectForKey:shaperKey];
		if(!obj){
			NSArray* listOfShapers = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")];
			for(ORShaperModel* aShaper in listOfShapers){
				if([aShaper crateNumber] == crate && [aShaper slot] == card){
					[actualShapers setObject:aShaper forKey:shaperKey];
					obj = aShaper;
					break;
				}
			}
		}
		getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
	}
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)someData
{
    uint32_t length;
    uint32_t* ptr = (uint32_t*)someData;
    if(IsShortForm(*ptr))	length = 1;
    else					length= ExtractLength(ptr[0]);
	
    NSString* title= @"Shaper ADC Record\n\n";

	int dataOffset = 0;
	if(length>1) dataOffset = 1;
	int crate			 = ShiftAndExtract(ptr[dataOffset],21,0xf);
	int card			 = ShiftAndExtract(ptr[dataOffset],16,0x1f);
	int channel			 = ShiftAndExtract(ptr[dataOffset],12,0xf);
	
    NSString* crateName = [NSString stringWithFormat:@"Crate = %d\n",crate];
    NSString* cardName  = [NSString stringWithFormat:@"Card  = %d\n",card];
    NSString* channame  = [NSString stringWithFormat:@"Chan  = %d\n",channel];
    NSString* adc       = [NSString stringWithFormat:@"ADC   = 0x%x\n",ptr[dataOffset]&0x00000fff];
    
	NSString* timeString = @"No Time Stamp\n";
	if(length==4){
        NSDate* timeStamp = [NSDate dateWithTimeIntervalSince1970:ptr[2]];
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"d MMM yyyy HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        NSString *dateString = [dateFormatter stringFromDate:timeStamp];
		timeString = [NSString stringWithFormat:@"%@ GMT\n sub-secs: %u\n",dateString,ptr[3]];
	}
	
    return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,crateName,cardName,channame,adc,timeString];               
}


@end

@implementation ORShaperDecoderForScalers
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr   = (uint32_t*)someData;
    uint32_t length;
    length = ExtractLength(ptr[0]);
    
    NSString* gtidString = [NSString stringWithFormat:@"%u",ptr[1]];
    
    short crate = (ptr[2] & 0x1e000000)>>25;
    short card  = (ptr[2] & 0x01f00000)>>20;
    NSString* globalScaler = [NSString stringWithFormat:@"%u",ptr[3]];
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
    [aDataSet loadGenericData:gtidString sender:self withKeys:@"Scalers",@"Shaper",  crateKey,cardKey,@"GTID",nil];
    [aDataSet loadGenericData:globalScaler sender:self withKeys:@"Scalers",@"Shaper", crateKey,cardKey,@"Global",nil];

    short index = 4;
    do {
        short crate     = (ptr[index] & 0x1e000000)>>25;
        short card      = (ptr[index] & 0x01f00000)>>20;
        short channel   = (ptr[index] & 0x000f0000)>>16;

        NSString* crateKey = [self getCrateKey: crate];
        NSString* cardKey = [self getCardKey: card];
        NSString* channelKey = [self getChannelKey: channel];
        
        NSString* scaler = [NSString stringWithFormat:@"%u",ptr[index]&0x0000ffff];
        [aDataSet loadGenericData:scaler sender:self withKeys:@"Scalers",@"Shaper", crateKey,cardKey,channelKey,nil];
        index++;

    }while(index < length);

    return length;
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t length = (ptr[0] & 0x003ffff);

    NSString* title= @"Shaper Scaler Record\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:@"GTID  = %u\n",ptr[1]];
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(ptr[2] & 0x1e000000)>>25];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(ptr[2] & 0x01f00000)>>20];
    NSString* global= [NSString stringWithFormat:@"Total = %u\n",ptr[3]];
    NSString* subTitle =@"\nScalers by Card,Chan\n\n";
   
    short index = 4;
    NSString* restOfString = @"";
    do {
        restOfString = [restOfString stringByAppendingFormat:@"%2u,%2u  = %u\n",(ptr[index] & 0x01f00000)>>20,(ptr[index] & 0x000f0000)>>16,ptr[index]&0x0000ffff];
        index++;
    }while(index < length);

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,gtid,global,subTitle,restOfString];               
}

@end




//ARGGGGGG -- because of a cut/paste error some data around jan '07 gat taken with a bugus decoder name
//temp insert this decoder so the data can be replayed.
@implementation ORShaperDecoderFORAxisrs
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr   = (uint32_t*)someData;
    uint32_t length;
    length = ExtractLength(ptr[0]);
    
    NSString* gtidString = [NSString stringWithFormat:@"%u",ptr[1]];
    
    short crate = (ptr[2] & 0x1e000000)>>25;
    short card  = (ptr[2] & 0x01f00000)>>20;
    NSString* globalScaler = [NSString stringWithFormat:@"%u",ptr[3]];
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
    [aDataSet loadGenericData:gtidString sender:self withKeys:@"Scalers",@"Shaper",  crateKey,cardKey,@"GTID",nil];
    [aDataSet loadGenericData:globalScaler sender:self withKeys:@"Scalers",@"Shaper", crateKey,cardKey,@"Global",nil];

    short index = 4;
    do {
        short crate     = (ptr[index] & 0x1e000000)>>25;
        short card      = (ptr[index] & 0x01f00000)>>20;
        short channel   = (ptr[index] & 0x000f0000)>>16;

        NSString* crateKey = [self getCrateKey: crate];
        NSString* cardKey = [self getCardKey: card];
        NSString* channelKey = [self getChannelKey: channel];
        
        NSString* scaler = [NSString stringWithFormat:@"%u",ptr[index]&0x0000ffff];
        [aDataSet loadGenericData:scaler sender:self withKeys:@"Scalers",@"Shaper", crateKey,cardKey,channelKey,nil];
        index++;

    }while(index < length);

    return length;
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t length = (ptr[0] & 0x003ffff);

    NSString* title= @"Shaper Scaler Record\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:@"GTID  = %u\n",ptr[1]];
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(ptr[2] & 0x1e000000)>>25];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(ptr[2] & 0x01f00000)>>20];
    NSString* global= [NSString stringWithFormat:@"Total = %u\n",ptr[3]];
    NSString* subTitle =@"\nScalers by Card,Chan\n\n";
   
    short index = 4;
    NSString* restOfString = @"";
    do {
        restOfString = [restOfString stringByAppendingFormat:@"%2u,%2u  = %u\n",(ptr[index] & 0x01f00000)>>20,(ptr[index] & 0x000f0000)>>16,ptr[index]&0x0000ffff];
        index++;
    }while(index < length);

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,gtid,global,subTitle,restOfString];               
}

@end

