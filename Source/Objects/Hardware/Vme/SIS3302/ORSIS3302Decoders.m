//
//  ORSIS3302Decoders.m
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#import "ORSIS3302Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORSIS3302Model.h"


@implementation ORSIS3302DecoderForEnergy
//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^--------------------------------most  sig bits of num records lost
//------------------------------^^^^-^^^--least sig bits of num records lost
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                    ^^^^ ^^^^-----------channel
//                                      ^--buffer wrap mode
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-length of waveform (longs)
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-length of energy   (longs)
// ---- followed by the data record as read 
//from hardware. see the manual. Be careful-- the new 15xx firmware data structure 
//is slightly diff (two extra words -- if the buffer wrap bit is set)
// ---- should end in 0xdeadbeef
//------------------------------------------------------------------
#define kPageLength (65*1024)
#define kFilterLengthKey @"energyPeakingTimes"

- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
	/*dumpedOneNormal = NO;
	int i;
	for(i=0;i<8;i++){
		recordCount[i]=0;
		dumpedOneBad[i]=NO;
	}
	 */
    return self;
}

- (void) dealloc
{
	[actualSIS3302Cards release];
    [super dealloc];
}

- (void) registerNotifications
{
	[super registerNotifications];
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(filterLengthChanged:) name:ORSIS3302CardInited object:nil];
}

- (void) filterLengthChanged:(NSNotification*)aNote
{
    @synchronized (self){
        ORSIS3302Model* theCard		= [aNote object];
        NSString* crateKey			= [self getCrateKey: [theCard crateNumber]];
        NSString* cardKey			= [self getCardKey: [theCard slot]];
        NSMutableArray*  theValues  = [NSMutableArray arrayWithCapacity:8];
        int group;
        for(group=0;group<[theCard numberOfChannels]/2;group++){
            [theValues addObject:[NSNumber numberWithInt:[theCard energyPeakingTime:group]]];
        }
        [self setObject:theValues forNestedKey:crateKey,cardKey,kFilterLengthKey,nil];
    }
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr	= (uint32_t*)someData;
	uint32_t length= ExtractLength(ptr[0]);
	int crate			= ShiftAndExtract(ptr[1],21,0xf);
	int card			= ShiftAndExtract(ptr[1],16,0x1f);
	int channel			= ShiftAndExtract(ptr[1],8,0xff);
	BOOL wrapMode		= ShiftAndExtract(ptr[1],0,0x1);
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];
	
	//int waveformLength1	 = ptr[2];
	//int energyLength1	 = ptr[3];
	//int waveformLength2	 = ptr[6];

	int32_t sisHeaderLength;
	if(wrapMode)sisHeaderLength = 4;
	else		sisHeaderLength = 2;
	if(![self cacheSetUp]){
		[self cacheCardLevelObject:kFilterLengthKey fromHeader:[aDecoder fileHeader]];
	}	
	uint32_t lastWord = ptr[length-1];
	//if(channel == 0 && !dumpedOneNormal)[self dumpRecord:ptr];

	if(lastWord == 0xdeadbeef){
		//if(!dumpedOneNormal){
		//	[self dumpRecord:someData];
		//}
		uint32_t energy = ptr[length - 4]; 

        NSArray* theFilterLengths = nil;
        @synchronized (self){
            theFilterLengths = [self objectForNestedKey:crateKey,cardKey,kFilterLengthKey,nil];
        }
        if([theFilterLengths count]>channel/2){
            int filterLength = [[theFilterLengths objectAtIndex:channel/2] intValue];
            if(filterLength)energy = energy/filterLength;
        }
        
		[aDataSet histogram:energy numBins:65536 sender:self  withKeys:@"SIS3302", @"Energy", crateKey,cardKey,channelKey,nil];
		
		uint32_t waveformLength = ptr[2]; //each int32_t word is two 16 bit adc samples
		uint32_t energyLength   = ptr[3];  
	
		if(waveformLength && (waveformLength == (length - 4 - sisHeaderLength - energyLength - 4))){
			NSData* recordAsData = nil;
			if(wrapMode){
				uint32_t nof_wrap_samples = ptr[6] ;
				if(nof_wrap_samples <= waveformLength*2){
					uint32_t wrap_start_index = ptr[7] ;
					recordAsData = [NSMutableData dataWithLength:waveformLength*sizeof(int32_t)];
					unsigned short* dataPtr			  = (unsigned short*)[recordAsData bytes];
					unsigned short* ushort_buffer_ptr = (unsigned short*) &ptr[8];
					int i;
					uint32_t j	=	wrap_start_index; 
					for (i=0;i<nof_wrap_samples;i++) { 
						if(j >= nof_wrap_samples ) j=0;
						dataPtr[i] = ushort_buffer_ptr[j++];
					}
				}
			}
			else {
				unsigned char* bPtr = (unsigned char*)&ptr[4 + sisHeaderLength]; //ORCA header + SIS header
				recordAsData = [NSData dataWithBytes:bPtr length:waveformLength*sizeof(int32_t)];
			}
			if(recordAsData)[aDataSet loadWaveform:recordAsData 
							offset: 0 //bytes!
						  unitSize: 2 //unit size in bytes!
							sender: self  
						  withKeys: @"SIS3302", @"ADC Trace",crateKey,cardKey,channelKey,nil];
		}
		
		if(energyLength && (energyLength == (length - 4 - sisHeaderLength - waveformLength - 4))){
			unsigned char* bPtr = (unsigned char*)&ptr[4 + sisHeaderLength + waveformLength];//ORCA header + SIS header + possible waveform
			NSData* recordAsData = [NSData dataWithBytes:bPtr length:energyLength*sizeof(int32_t)];
			[aDataSet loadWaveform:recordAsData 
							offset: 0
						  unitSize: 4 //unit size in bytes!
							sender: self 						 
						  withKeys: @"SIS3302", @"Energy Waveform",crateKey,cardKey,channelKey,nil];	
		}
		
		//get the actual object
        if(getRatesFromDecodeStage && !skipRateCounts){
			NSString* aKey = [crateKey stringByAppendingString:cardKey];
			if(!actualSIS3302Cards)actualSIS3302Cards = [[NSMutableDictionary alloc] init];
			ORSIS3302Model* obj = [actualSIS3302Cards objectForKey:aKey];
			if(!obj){
				NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSIS3302Model")];
				NSEnumerator* e = [listOfCards objectEnumerator];
				ORSIS3302Model* aCard;
				while(aCard = [e nextObject]){
					if([aCard slot] == card){
						[actualSIS3302Cards setObject:aCard forKey:aKey];
						obj = aCard;
						break;
					}
				}
			}
			getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
		}
	}
	else {
		/*
		recordCount[channel]++;
		if(!dumpedOneBad[channel]){
			NSLog(@"-----------------------------------\n");
			int i;
			for(i=0;i<length+100;i++){
				if(ptr[i] == 0xdeadbeef){
					NSLog(@"length: %d deadbeef at: %d\n",length,i);
					break;
				}
			}
			dumpedOneBad[channel] = YES;
			NSLog(@"Bad Record for channel: %d  total: %d\n",channel,recordCount[channel]);
			NSLog(@"Orca waveformLength: %d energyLength: %d\n",waveformLength1,energyLength1);
			NSLog(@"sis waveformLength: %d\n",waveformLength2);
			[self dumpRecord:ptr];
			NSLog(@"-----------------------------------\n");
		}
		*/
	}
	
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	
	//TODO ---- 
	/*
	 ptr++;
	 NSString* title= @"SIS3302 Waveform Record\n\n";
	 NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
	 NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	 NSString* moduleID = (*ptr&0x1)?@"SIS3301":@"SIS3302";
	 ptr++;
	 NSString* triggerWord = [NSString stringWithFormat:@"TriggerWord  = 0x08%x\n",*ptr];
	 ptr++;
	 NSString* Event = [NSString stringWithFormat:@"Event  = 0x%08x\n",(*ptr>>24)&0xff];
	 NSString* Time = [NSString stringWithFormat:@"Time Since Last Trigger  = 0x%08x\n",*ptr&0xffffff];
	 
	 return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,moduleID,triggerWord,Event,Time];       
	 */
	return @"Description not implemented yet";
}
/*
- (void) dumpRecord:(void*)someData 
{
	dumpedOneNormal = YES;
	
    uint32_t* ptr	= (uint32_t*)someData;
	uint32_t length= ExtractLength(ptr[0]);
	int crate			= ShiftAndExtract(ptr[1],21,0xf);
	int card			= ShiftAndExtract(ptr[1],16,0x1f);
	int channel			= ShiftAndExtract(ptr[1],8,0xff);
	BOOL wrapMode		= ShiftAndExtract(ptr[1],0,0x1);
	
	
	int32_t waveformLength = ptr[2]; //each int32_t word is two 16 bit adc samples
	int32_t energyLength   = ptr[3];  
	
	int32_t sisHeaderLength;
	if(wrapMode)sisHeaderLength = 4;
	else		sisHeaderLength = 2;
	NSFont* afont = [NSFont fontWithName:@"Monaco" size:12];
	NSLogFont(afont,@"-----------------------------------\n");
	NSLogFont(afont,@"Length: %d longs\n",length);
	NSLogFont(afont,@"Crate: %d Card: %d Channel: %d\n",crate,card,channel);
	NSLogFont(afont,@"Wrap Mode: %@\n",wrapMode?@"YES":@"NO");
	NSLogFont(afont,@"WaveForm Length: %d longs\n",waveformLength);
	NSLogFont(afont,@"EnergyLength Length: %d longs\n",energyLength);
	NSLogFont(afont,@"ORCA Header:: 0x%08x 0x%08x 0x%08x 0x%08x\n",ptr[0],ptr[1],ptr[2],ptr[3]);
	
	int i;
	int index = 4;
	for(i=0;i<sisHeaderLength;i++){
		NSLogFont(afont,@"SIS Header %3d: 0x%08x\n",i,ptr[index]);
		index++;
	}
	NSLogFont(afont,@"\n");
	NSLogFont(afont,@"Waveform (unpacked)\n");
	NSLogFont(afont,@"\n");
	BOOL once = NO;
	for(i=0;i<waveformLength;i+=10){
		if(i<20 || i>waveformLength-30){
			if(i<waveformLength){
				NSLogFont(afont,@"%3d: 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x 0x%04x\n",i,
						ptr[index]  & 0xFFFF, (ptr[index]>>16)     & 0xFFFF,
						ptr[index+1]& 0xFFFF, (ptr[index+1]>>16) & 0xFFFF,
						ptr[index+2]& 0xFFFF, (ptr[index+2]>>16) & 0xFFFF,
						ptr[index+3]& 0xFFFF, (ptr[index+3]>>16) & 0xFFFF,
						ptr[index+4]& 0xFFFF, (ptr[index+4]>>16) & 0xFFFF,
						ptr[index+5]& 0xFFFF, (ptr[index+5]>>16) & 0xFFFF,
						ptr[index+6]& 0xFFFF, (ptr[index+6]>>16) & 0xFFFF,
						ptr[index+8]& 0xFFFF, (ptr[index+8]>>16) & 0xFFFF,
						ptr[index+8]& 0xFFFF, (ptr[index+8]>>16) & 0xFFFF,
						ptr[index+9]& 0xFFFF, (ptr[index+9]>>16) & 0xFFFF);
			}
			else break;
		}
		else {
			if(!once){
				NSLogFont(afont,@"....\n");
				NSLogFont(afont,@"....\n");
				once = YES;
			}
		}
		index += 10;
	}
	NSLogFont(afont,@"\n");
	if(energyLength)	{
		NSLogFont(afont,@"Energy Waveform\n");
		NSLogFont(afont,@"\n");
	}

	//in case the waveform wasn't a multiple of ten
	index = 4 + sisHeaderLength + waveformLength;
	for(i=0;i<energyLength;i+=10){
		NSLogFont(afont,@"%3d: 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x\n",i,
				  ptr[index],ptr[index+1],ptr[index+2],ptr[index+3],ptr[index+4],ptr[index+5],ptr[index+6],ptr[index+7],ptr[index+8],ptr[index+9]);
		index += 10;
	}
	NSLogFont(afont,@"\n");
	NSLog(@"Trailer\n");
	NSLogFont(afont,@"%3d: 0x%08x 0x%08x 0x%08x 0x%08x\n",index,ptr[index],ptr[index+1],ptr[index+2],ptr[index+3]);

	NSLogFont(afont,@"-----------------------------------\n");
}
 */
@end

@implementation ORSIS3302DecoderForMca

//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^--------------------------------spare
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                    ^^^^ ^^^^-----------channel
//								^^^^ ^^^--spare
// ---- followed by the mcadata record as read 
//------------------------------------------------------------------

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(ptr[0]);
	int crate	= ShiftAndExtract(ptr[1],21,0xf);
	int card	= ShiftAndExtract(ptr[1],16,0x1f);
	int channel = ShiftAndExtract(ptr[1],8,0xff);
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];
	
	
	[aDataSet loadSpectrum:[NSMutableData dataWithBytes:&ptr[2] length:(length-2)*sizeof(int32_t)] 
					sender:self  
				  withKeys:@"SIS3302",@"MCA",crateKey,cardKey,channelKey,nil];
	
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	
	//TODO ---- 
	/*
	 ptr++;
	 NSString* title= @"SIS3302 Waveform Record\n\n";
	 NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
	 NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	 NSString* moduleID = (*ptr&0x1)?@"SIS3301":@"SIS3302";
	 ptr++;
	 NSString* triggerWord = [NSString stringWithFormat:@"TriggerWord  = 0x08%x\n",*ptr];
	 ptr++;
	 NSString* Event = [NSString stringWithFormat:@"Event  = 0x%08x\n",(*ptr>>24)&0xff];
	 NSString* Time = [NSString stringWithFormat:@"Time Since Last Trigger  = 0x%08x\n",*ptr&0xffffff];
	 
	 return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,moduleID,triggerWord,Event,Time];       
	 */
	return @"Description not implemented yet";
}

@end


@implementation ORSIS3302GenericDecoderForWaveform

//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                    ^^^^ ^^^^-----------channel

//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-waveform piece tag
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-length of total waveform

// ---- followed by the waveform data
//------------------------------------------------------------------

- (void) dealloc
{
	[currentWaveformCache release];
    [super dealloc];
}


- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(ptr[0]);
	int crate	= ShiftAndExtract(ptr[1],21,0xf);
	int card	= ShiftAndExtract(ptr[1],16,0x1f);
	int channel = ShiftAndExtract(ptr[1],8,0xff);
    //uint32_t wfTag = ptr[2];
    uint32_t totalWFLength = ptr[3];
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];
    
    
    if(length > 4){
        unsigned char* bPtr = (unsigned char*)&ptr[4];
        NSMutableData* recordAsData = [NSMutableData dataWithBytes:bPtr length:(length-4)*sizeof(int32_t)];
        if ( length - 4 == totalWFLength ) {
            [aDataSet loadWaveform:recordAsData 
                            offset: 0
                          unitSize: 2 //unit size in bytes!
                            sender: self 						 
                          withKeys: @"SIS3302Generic", @"Energy Waveform",crateKey,cardKey,channelKey,nil];	
        } else {
            NSString* astr = [NSString stringWithFormat:@"%@%@%@",crateKey,cardKey,channelKey];
            if (currentWaveformCache == nil) currentWaveformCache = [[NSMutableDictionary alloc] init];
            NSMutableData* oldData = [currentWaveformCache objectForKey:astr];
            if (oldData == nil) {
                [currentWaveformCache setObject:recordAsData forKey:astr];
            } else {
                [oldData appendData:recordAsData];
                if ([oldData length]/4 == totalWFLength) {
                    [aDataSet loadWaveform: oldData
                                    offset: 0
                                  unitSize: 2 //unit size in bytes!
                                    sender: self 						 
                                  withKeys: @"SIS3302Generic", @"Energy Waveform",crateKey,cardKey,channelKey,nil];	
                    [currentWaveformCache removeObjectForKey:astr];
                }
                
            }
        }
    }
    
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	
	//TODO ---- 
	/*
	 ptr++;
	 NSString* title= @"SIS3302 Waveform Record\n\n";
	 NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
	 NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	 NSString* moduleID = (*ptr&0x1)?@"SIS3301":@"SIS3302";
	 ptr++;
	 NSString* triggerWord = [NSString stringWithFormat:@"TriggerWord  = 0x08%x\n",*ptr];
	 ptr++;
	 NSString* Event = [NSString stringWithFormat:@"Event  = 0x%08x\n",(*ptr>>24)&0xff];
	 NSString* Time = [NSString stringWithFormat:@"Time Since Last Trigger  = 0x%08x\n",*ptr&0xffffff];
	 
	 return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,moduleID,triggerWord,Event,Time];       
	 */
	return @"Description not implemented yet";
}

@end

//************old...leave in for backward compatiblity
@implementation ORSIS3302Decoder

//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^--------------------------------spare
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                    ^^^^ ^^^^-----------channel
//								^^^^ ^^^--spare
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-length of waveform (longs)
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-length of energy   (longs)
// ---- followed by the data record as read 
//from hardware. see the manual.
// ---- should end in 0xdeadbeef
//------------------------------------------------------------------
//#define kPageLength (65*1024)

- (id) init

{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualSIS3302Cards release];
    [super dealloc];
}

- (void) registerNotifications
{
	[super registerNotifications];
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(filterLengthChanged:) name:ORSIS3302CardInited object:nil];
}

- (void) filterLengthChanged:(NSNotification*)aNote
{
	ORSIS3302Model* theCard		= [aNote object];
	NSString* crateKey			= [self getCrateKey: [theCard crateNumber]];
	NSString* cardKey			= [self getCardKey: [theCard slot]];
    NSMutableArray*  theValues  = [NSMutableArray arrayWithCapacity:8];
	int group;
	for(group=0;group<[theCard numberOfChannels]/2;group++){
        [theValues addObject:[NSNumber numberWithInt:[theCard energyPeakingTime:group]]];
	}
    [self setObject:theValues forNestedKey:crateKey,cardKey,kFilterLengthKey,nil];
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(ptr[0]);
	int crate	= ShiftAndExtract(ptr[1],21,0xf);
	int card	= ShiftAndExtract(ptr[1],16,0x1f);
	int channel = ShiftAndExtract(ptr[1],8,0xff);
	
	if(![self cacheSetUp]){
		[self cacheCardLevelObject:kFilterLengthKey fromHeader:[aDecoder fileHeader]];
	}	
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];

	uint32_t lastWord = ptr[length-1];
	if(lastWord == 0xdeadbeef){
		//histogram the energy.... prescale by dividing by 4 so we can have a histogram of reseanable length.... have to do something better at some point
		uint32_t energy = ptr[length - 4]; 
		//int page = energy/kPageLength;
		//int startPage = page*kPageLength;
		//int endPage = (page+1)*kPageLength;
		//[aDataSet histogram:energy - page*kPageLength numBins:kPageLength sender:self  withKeys:@"SIS3302", [NSString stringWithFormat:@"Energy (%d - %d)",startPage,endPage], crateKey,cardKey,channelKey,nil];

		NSArray* theFilterLengths = [self objectForNestedKey:crateKey,cardKey,kFilterLengthKey,nil];
		if([theFilterLengths count]>channel/2){
			int filterLength = [[theFilterLengths objectAtIndex:channel] intValue];
			if(filterLength)energy = energy/filterLength;
			[aDataSet histogram:energy numBins:65536 sender:self  withKeys:@"SIS3302", @"Energy", crateKey,cardKey,channelKey,nil];
		}
		
		int32_t waveformLength = ptr[2]; //each int32_t word is two 16 bit adc samples
		int32_t energyLength   = ptr[3]; //each energy value is a sum of two 
		
		if(waveformLength){
			unsigned char* bPtr = (unsigned char*)&ptr[4 + 2]; //ORCA header + SIS header
			NSData* recordAsData = [NSData dataWithBytes:bPtr length:waveformLength*sizeof(int32_t)];
			[aDataSet loadWaveform:recordAsData 
							offset: 0 //bytes!
						  unitSize: 2 //unit size in bytes!
							sender: self  
						  withKeys: @"SIS3302", @"ADC Trace",crateKey,cardKey,channelKey,nil];
		}

		if(energyLength){
			unsigned char* bPtr = (unsigned char*)&ptr[4 + 2 + waveformLength];//ORCA header + SIS header + possible waveform
			NSData* recordAsData = [NSData dataWithBytes:bPtr length:energyLength*sizeof(int32_t)];
			[aDataSet loadWaveform:recordAsData 
							offset: 0
						  unitSize: 4 //unit size in bytes!
							sender: self 						 
						  withKeys: @"SIS3302", @"Energy Waveform",crateKey,cardKey,channelKey,nil];	
		}

		//get the actual object
        if(getRatesFromDecodeStage && !skipRateCounts){
			NSString* aKey = [crateKey stringByAppendingString:cardKey];
			if(!actualSIS3302Cards)actualSIS3302Cards = [[NSMutableDictionary alloc] init];
			ORSIS3302Model* obj = [actualSIS3302Cards objectForKey:aKey];
			if(!obj){
				NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSIS3302Model")];
				NSEnumerator* e = [listOfCards objectEnumerator];
				ORSIS3302Model* aCard;
				while(aCard = [e nextObject]){
					if([aCard slot] == card){
						[actualSIS3302Cards setObject:aCard forKey:aKey];
						obj = aCard;
						break;
					}
				}
			}
			getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
		}
	}
 
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	
	//TODO ---- 
	/*
	ptr++;
    NSString* title= @"SIS3302 Waveform Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	NSString* moduleID = (*ptr&0x1)?@"SIS3301":@"SIS3302";
	ptr++;
	NSString* triggerWord = [NSString stringWithFormat:@"TriggerWord  = 0x08%x\n",*ptr];
	ptr++;
	NSString* Event = [NSString stringWithFormat:@"Event  = 0x%08x\n",(*ptr>>24)&0xff];
	NSString* Time = [NSString stringWithFormat:@"Time Since Last Trigger  = 0x%08x\n",*ptr&0xffffff];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,moduleID,triggerWord,Event,Time];       
	 */
	return @"Description not implemented yet";
}
@end



@implementation ORSIS3302McaDecoder

//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^--------------------------------spare
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                    ^^^^ ^^^^-----------channel
//								^^^^ ^^^--spare
// ---- followed by the mcadata record as read 
//------------------------------------------------------------------
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(ptr[0]);
	int crate	= ShiftAndExtract(ptr[1],21,0xf);
	int card	= ShiftAndExtract(ptr[1],16,0x1f);
	int channel = ShiftAndExtract(ptr[1],8,0xff);
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];

	
	[aDataSet loadSpectrum:[NSMutableData dataWithBytes:&ptr[2] length:(length-2)*sizeof(int32_t)] 
				   sender:self  
				 withKeys:@"SIS3302",@"MCA",crateKey,cardKey,channelKey,nil];
	
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	
	//TODO ---- 
	/*
	 ptr++;
	 NSString* title= @"SIS3302 Waveform Record\n\n";
	 NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
	 NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	 NSString* moduleID = (*ptr&0x1)?@"SIS3301":@"SIS3302";
	 ptr++;
	 NSString* triggerWord = [NSString stringWithFormat:@"TriggerWord  = 0x08%x\n",*ptr];
	 ptr++;
	 NSString* Event = [NSString stringWithFormat:@"Event  = 0x%08x\n",(*ptr>>24)&0xff];
	 NSString* Time = [NSString stringWithFormat:@"Time Since Last Trigger  = 0x%08x\n",*ptr&0xffffff];
	 
	 return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,moduleID,triggerWord,Event,Time];       
	 */
	return @"Description not implemented yet";
}

@end


@implementation ORSIS3302DecoderForLostData

//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^--------------------------------spare
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                    ^^^^ ^^^^-----------channel
//								^^^^ ^^^^-data type
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-data
//data type:
//0 -> number of lost events
//1 -> reset due to timeout on one or more channels
//------------------------------------------------------------------

- (id) init
{
    self = [super init];
	int i;
	for(i=0;i<8;i++){
		totalLost[i]=0;
	}
    return self;
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(ptr[0]);
	int crate	 = ShiftAndExtract(ptr[1],21,0xf);
	int card	 = ShiftAndExtract(ptr[1],16,0x1f);
	int channel  = ShiftAndExtract(ptr[1],8,0xff);
	int dataType = ShiftAndExtract(ptr[1],0,0xff);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];
	if(dataType == 0){
		if(channel>=0 && channel<8){
			totalLost[channel] += ptr[2];
			NSString* numLostRecords = [NSString stringWithFormat:@"%u",totalLost[channel]];
			[aDataSet loadGenericData:numLostRecords sender:self withKeys:@"SIS3302", @"Lost Records", crateKey,cardKey,channelKey,nil];
		}
	}
	else if(dataType == 1){
		[aDataSet loadGenericData:[NSString stringWithFormat:@"0x%02x",ptr[2]>>16] sender:self withKeys:@"SIS3302", @"Reset Event", crateKey,cardKey,nil];
	}
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	int crate	 = ShiftAndExtract(ptr[1],21,0xf);
	int card	 = ShiftAndExtract(ptr[1],16,0x1f);
	int channel  = ShiftAndExtract(ptr[1],8,0xff);
	int dataType = ShiftAndExtract(ptr[1],0,0xff);
		
	NSString* title= @"SIS3302 Lost Records\n\n";
    
	NSString* data = @"";
	NSString* crateString   = [NSString stringWithFormat:@"Crate = %d\n",crate];
    NSString* cardString    = [NSString stringWithFormat:@"Card  = %d\n",card];    
    NSString* channelString = [NSString stringWithFormat:@"Card  = %d\n",channel];  
	if(dataType == 0){
		data = [NSString stringWithFormat:@"Num Records Lost = %u\n",ptr[2]];
	}
	else if(dataType == 1){
		data = [NSString stringWithFormat:@"Reset Event Mask = 0x%02x\n",ptr[2]];
	}

    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crateString,cardString,channelString,data];               
}

@end

