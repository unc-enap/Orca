//
//  ORDataGenDecoders.m
//  Orca
//
//  Created by Mark Howe on 9/22/04.
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


#import "ORDataGenDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"

#pragma mark •••Definitions

static NSString* kChanKey[8] = {
    //pre-make some keys for speed.
    @"Channel 0",  @"Channel 1",  @"Channel 2",  @"Channel 3",
    @"Channel 4",  @"Channel 5",  @"Channel 6",  @"Channel 7",
};

static NSString* kCardKey[8] = {
    //pre-make some keys for speed.
    @"Card 0",  @"Card 1",  @"Card 2",  @"Card 3",
    @"Card 4",  @"Card 5",  @"Card 6",  @"Card 7"

};


@implementation ORDataGenDecoderForTestData1D

- (NSString*) getChannelKey:(unsigned short)aChan
{
    if(aChan<32) return kChanKey[aChan];
    else return [NSString stringWithFormat:@"Channel %d",aChan];	
}

- (NSString*) getCardKey:(unsigned short)aCard
{
    if(aCard<16) return kCardKey[aCard];
    else return [NSString stringWithFormat:@"Card %d",aCard];			
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned short card  = ShiftAndExtract(ptr[1],16,0xf);
	unsigned short chan  = ShiftAndExtract(ptr[1],12,0xf);
	unsigned short value = ShiftAndExtract(ptr[1],0,0xfff);
	
    [aDataSet histogram:value numBins:4096  sender:self  withKeys:@"DataGen",
		kCardKey[card],
		kChanKey[chan],
        nil];
    
    return ExtractLength(ptr[0]); //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Data Gen Record\n\n";
    
    NSString* value  = [NSString stringWithFormat:@"Value = %lu\n",ShiftAndExtract(ptr[1],0,0xfff)];
    NSString* card  = [NSString stringWithFormat: @"Card  = %lu\n",ShiftAndExtract(ptr[1],16,0xf)];
    NSString* chan  = [NSString stringWithFormat: @"Chan  = %lu\n",ShiftAndExtract(ptr[1],12,0xf)];    

    return [NSString stringWithFormat:@"%@%@%@%@",title,value,card,chan];               
}


@end

@implementation ORDataGenDecoderForTestData2D

- (NSString*) getChannelKey:(unsigned short)aChan
{
    if(aChan<32) return kChanKey[aChan];
    else return [NSString stringWithFormat:@"Channel %d",aChan];	
}

- (NSString*) getCardKey:(unsigned short)aCard
{
    if(aCard<16) return kCardKey[aCard];
    else return [NSString stringWithFormat:@"Card %d",aCard];			
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = 3;

	[aDataSet histogram2DX:ShiftAndExtract(ptr[1],0,0xfff) y:ShiftAndExtract(ptr[2],0,0xfff) size:256  sender:self  withKeys:@"DataGen2D",
	 kCardKey[ShiftAndExtract(ptr[1],16,0xf)],
	 kChanKey[ShiftAndExtract(ptr[1],12,0xf)],
	 nil];
	
    [aDataSet loadData2DX:ShiftAndExtract(ptr[1],0,0xfff) y:ShiftAndExtract(ptr[2],0,0xfff) z:1 size:256  sender:self  withKeys:@"DataGen2D_Set",
		kCardKey[ShiftAndExtract(ptr[1],16,0xf)],
		kChanKey[ShiftAndExtract(ptr[1],12,0xf)],
        nil];


	NSDate* now = [NSDate date];
	if(lastTime == 0){
		lastTime = [now retain];
	}
	if([now timeIntervalSinceDate:lastTime] > 1){
		[aDataSet clearDataUpdate:NO withKeys:@"DataGen2D_Set",
			kCardKey[ShiftAndExtract(ptr[1],16,0xf)],
			kChanKey[ShiftAndExtract(ptr[1],11,0xf)],
			nil];
		[lastTime release];
		lastTime = [now retain];
	}

    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Data Gen Record (2D)\n\n";
 
	NSString* valueX  = [NSString stringWithFormat:@"ValueX = %lu\n",ShiftAndExtract(ptr[1],0,0xfff)];
    NSString* valueY  = [NSString stringWithFormat:@"ValueY = %lu\n",ShiftAndExtract(ptr[2],0,0xfff)];
    NSString* card    = [NSString stringWithFormat: @"Card  = %lu\n",ShiftAndExtract(ptr[1],16,0xf)];
    NSString* chan    = [NSString stringWithFormat: @"Chan  = %lu\n",ShiftAndExtract(ptr[1],12,0xf)];    

    return [NSString stringWithFormat:@"%@%@%@%@%@",title,valueX,valueY,card,chan];               
}


@end


@implementation ORDataGenDecoderForTestDataWaveform

- (NSString*) getChannelKey:(unsigned short)aChan
{
    if(aChan<32) return kChanKey[aChan];
    else return [NSString stringWithFormat:@"Channel %d",aChan];	
}

- (NSString*) getCardKey:(unsigned short)aCard
{
    if(aCard<16) return kCardKey[aCard];
    else return [NSString stringWithFormat:@"Card %d",aCard];			
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = ExtractLength(*ptr);
	NSData* data = [NSData dataWithBytes:&ptr[2] length:(length-2)*sizeof(long)];
    [aDataSet loadWaveform:data 
					offset:0 
				  unitSize:sizeof(long) 
				startIndex:0 
					  mask:0x0fffffff 
			   specialBits:0xf0000000
				  bitNames:[NSArray arrayWithObjects:@"bit1",@"bit2",@"bit3",@"bit4",nil]
					sender:self
				  withKeys:@"DataGen_Waveform",
							kCardKey[ShiftAndExtract(ptr[1],16,0xf)],
							kChanKey[ShiftAndExtract(ptr[1],12,0xf)],
							nil];

	return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Data Gen Record (Waveform)\n\n";
    
    NSString* card  = [NSString stringWithFormat: @"Card  = %lu\n",ShiftAndExtract(ptr[1],16,0xf)];
    NSString* chan  = [NSString stringWithFormat: @"Chan  = %lu\n",ShiftAndExtract(ptr[1],12,0xf)];    

    return [NSString stringWithFormat:@"%@%@%@",title,card,chan];               
}

@end

@implementation ORDataGenDecoderForTimeSeries
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long *dataPtr = (unsigned long*)someData;
	union {
		float asFloat;
		unsigned long asLong;
	}theTemp;
	theTemp.asLong = dataPtr[2];									//encoded as float, use union to convert
	[aDataSet loadTimeSeries:theTemp.asFloat										
					  atTime:dataPtr[3]
					  sender:self 
					withKeys:@"DataGenTimeSeries",@"Unit 1",
					nil];
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSString* title= @"DataGen\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	union {
		float asFloat;
		unsigned long asLong;
	}theData;
	
	theData.asLong = dataPtr[2];
	
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[3]];
	
	theString = [theString stringByAppendingFormat:@"%.2E %@\n",theData.asFloat,date];
	
	return theString;
}
@end

@implementation ORDataGenDecoderForBurstData
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long *dataPtr = (unsigned long*)someData;
	union {
		float asFloat;
		unsigned long asLong;
	}theTemp;
	theTemp.asLong = dataPtr[2];									//encoded as float, use union to convert
    unsigned long* ptr = (unsigned long*)someData;
	unsigned short card  = ShiftAndExtract(ptr[1],16,0xf);
	unsigned short chan  = ShiftAndExtract(ptr[1],12,0xf);
	unsigned short value = ShiftAndExtract(ptr[1],0,0xfff);
	
    [aDataSet histogram:value numBins:4096  sender:self  withKeys:@"DataGenBurst",
	 kCardKey[card],
	 kChanKey[chan],
	 nil];	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSString* title		= @"DataGenBurst\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               

	unsigned short card  = ShiftAndExtract(dataPtr[1],16,0xf);
	unsigned short chan  = ShiftAndExtract(dataPtr[1],12,0xf);
	unsigned short value = ShiftAndExtract(dataPtr[1],0,0xfff);
	
	union {
		float asFloat;
		unsigned long asLong;
	}theData;
	
	theData.asLong = dataPtr[2];
	
	theString = [theString stringByAppendingFormat:@"card: %d channel: %d value: %d\n",card,chan,value];
	theString = [theString stringByAppendingFormat:@"%.6f\n",theData.asFloat];
	
	return theString;
}
@end

