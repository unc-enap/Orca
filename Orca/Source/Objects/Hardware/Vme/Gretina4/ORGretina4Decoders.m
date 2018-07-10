//
//  ORGretina4Decoders.m
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


#import "ORGretina4Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORGretina4Model.h"

#define kIntegrationTimeKey @"Integration Time"
#define kHistEMultiplierKey @"Hist E Multiplier"

@implementation ORGretina4WaveformDecoder
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
	[nc addObserver:self selector:@selector(integrationTimeChanged:) name:ORGretina4CardInited object:nil];
	[nc addObserver:self selector:@selector(histEMultiplierChanged:) name:ORGretina4ModelHistEMultiplierChanged object:nil];
}

- (void) integrationTimeChanged:(NSNotification*)aNote
{
	ORGretina4Model* theCard	= [aNote object];
	NSString* crateKey			= [self getCrateKey: [theCard crateNumber]];
	NSString* cardKey			= [self getCardKey: [theCard slot]];
	[self setObject:[NSNumber numberWithInt:[theCard integrationTimeAsInt]] forNestedKey:crateKey,cardKey,kIntegrationTimeKey,nil];
}

- (void) histEMultiplierChanged:(NSNotification*)aNote
{
	ORGretina4Model* theCard	= [aNote object];
	NSString* crateKey			= [self getCrateKey: [theCard crateNumber]];
	NSString* cardKey			= [self getCardKey: [theCard slot]];
	[self setObject:[NSNumber numberWithInt:[theCard histEMultiplier]] forNestedKey:crateKey,cardKey,kHistEMultiplierKey,nil];
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

	if(![self cacheSetUp]){
		[self cacheCardLevelObject:kIntegrationTimeKey fromHeader:[aDecoder fileHeader]];
		[self cacheCardLevelObject:kHistEMultiplierKey fromHeader:[aDecoder fileHeader]];
	}
	
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	ptr++; //point to location info
    int crate = (*ptr&0x01e00000)>>21;
    int card  = (*ptr&0x001f0000)>>16;

	ptr++; //first word of the actual card packet
	int channel		 = *ptr&0xF;
	int packetLength = ((*ptr & kGretina4NumberWordsMask) >>16) - kGretina4HeaderLengthLongs;
	ptr += 2; //point to Energy low word
	unsigned long energy = *ptr >> 16;
	ptr++;	  //point to Energy second word
	energy += (*ptr & 0x000001ff) << 16;
	
	// energy is in 2's complement, taking abs value if necessary
	if (energy & 0x1000000) energy = (~energy & 0x1ffffff) + 1;

	NSString* crateKey	 = [self getCrateKey: crate];
	NSString* cardKey	 = [self getCardKey: card];
	NSString* channelKey = [self getChannelKey: channel];

	int histEMultiplier = [[self objectForNestedKey:crateKey,cardKey,kHistEMultiplierKey,nil] intValue];
        if(histEMultiplier) energy *= histEMultiplier;
	int integrationTime = [[self objectForNestedKey:crateKey,cardKey,kIntegrationTimeKey,nil] intValue];
	if(integrationTime) energy /= integrationTime; 
	
    [aDataSet histogram:energy numBins:0x1fff*histEMultiplier sender:self  withKeys:@"Gretina4 Energy",crateKey,cardKey,channelKey,nil];
	
	
	if (packetLength > 0) {
		/* Decode the waveforms if the exist. */
		ptr += 4; //point to the data

		NSMutableData* tmpData = [NSMutableData dataWithCapacity:512*2];
		
		//note:  there is something wrong here. The package length should be in longs but the
		//packet is always half empty.   
		[tmpData setLength:packetLength*sizeof(long)];
		unsigned short* dPtr = (unsigned short*)[tmpData bytes];
		int i;
		int wordCount = 0;
		//data is actually 2's complement. detwiler 08/26/08
		for(i=0;i<packetLength;i++){
			dPtr[wordCount++] =    (0x0000ffff & *ptr);
			dPtr[wordCount++] =    (0xffff0000 & *ptr) >> 16;
			ptr++;
		}
		[aDataSet loadWaveform:tmpData 
						offset:0 //bytes!
					  unitSize:2 //unit size in bytes!
						sender:self  
					  withKeys:@"Gretina4 Waveforms",crateKey,cardKey,channelKey,nil];
	}
	if(getRatesFromDecodeStage && !skipRateCounts){
		//get the actual object
		NSString* aKey = [crateKey stringByAppendingString:cardKey];
		if(!actualGretinaCards)actualGretinaCards = [[NSMutableDictionary alloc] init];
		ORGretina4Model* obj = [actualGretinaCards objectForKey:aKey];
		if(!obj){
			NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORGretina4Model")];
			NSEnumerator* e = [listOfCards objectEnumerator];
			ORGretina4Model* aCard;
			while(aCard = [e nextObject]){
				if([aCard slot] == card){
					[actualGretinaCards setObject:aCard forKey:aKey];
					obj = aCard;
					break;
				}
			}
		}
		getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
	}
	 
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Gretina4 Waveform Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate = %lu\n",(ptr[1]&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %lu\n",(ptr[1]&0x001f0000)>>16];
    NSString* chan  = [NSString stringWithFormat:@"Chan  = %lu\n",ptr[2]&0x7];
    
    unsigned long long timeStamp = ((unsigned long long)(ptr[4]&0xffff) << 32) + ptr[3];
    NSString* timeStampString = [NSString stringWithFormat:@"Time: %lld\n",timeStamp];

	unsigned long energy = ptr[4] >> 16;
	energy += (ptr[5] & 0x0000001ff) << 16;
	
	// energy is in 2's complement, taking abs value if necessary
	if (energy & 0x1000000) energy = (~energy & 0x1ffffff) + 1;
	NSString* energyStr  = [NSString stringWithFormat:@"Energy  = %lu\n",energy/50]; //mah 10/21 added the /50 to be consistent with histogramed value
    return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,crate,card,chan,timeStampString,energyStr];
}

@end
