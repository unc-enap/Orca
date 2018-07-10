//
//  ORDataGenModel.m
//  Orca
//
//  Created by Mark Howe on Thu Oct 02 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORDataGenModel.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"
#import "SBC_Config.h"
#import "VME_HW_Definitions.h"

@implementation ORDataGenModel

#pragma mark ¥¥¥Initialization

- (void) dealloc
{
	[lastTime release];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"DataGen"]];
}

- (BOOL) hasDialog
{
	return NO;
}
- (void) showMainInterface
{
    NSLog(@"The Data Generator has no settable parameters and hence no dialog. Just put it into a readout list to make some test data\n");
}
- (unsigned long) timeSeriesId { return timeSeriesId; }
- (void) setTimeSeriesId: (unsigned long) aDataId
{
    timeSeriesId = aDataId;
}

- (unsigned long) burstDataId { return burstDataId; }
- (void) setBurstDataId: (unsigned long) aDataId
{
    burstDataId = aDataId;
}

- (unsigned long) dataId1D { return dataId1D; }
- (void) setDataId1D: (unsigned long) aDataId
{
    dataId1D = aDataId;
}

- (unsigned long) dataId2D { return dataId2D; }
- (void) setDataId2D: (unsigned long) aDataId
{
    dataId2D = aDataId;
}

- (unsigned long) dataIdWaveform { return dataIdWaveform; }
- (void) setDataIdWaveform: (unsigned long) aDataId
{
    dataIdWaveform = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId1D       = [assigner assignDataIds:kLongForm];
    dataId2D       = [assigner assignDataIds:kLongForm];
    burstDataId    = [assigner assignDataIds:kLongForm];
	dataIdWaveform = [assigner assignDataIds:kLongForm];
	timeSeriesId= [assigner assignDataIds:kLongForm];
}


- (void) syncDataIdsWith:(id)anotherObj
{
    [self setBurstDataId:[anotherObj burstDataId]];
    [self setDataId1D:[anotherObj dataId1D]];
    [self setDataId2D:[anotherObj dataId2D]];
    [self setDataIdWaveform:[anotherObj dataIdWaveform]];
    [self setTimeSeriesId:[anotherObj timeSeriesId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		 @"ORDataGenDecoderForTimeSeries",       @"decoder",
		 [NSNumber numberWithLong:timeSeriesId],		 @"dataId",
		 [NSNumber numberWithBool:NO],           @"variable",
		 [NSNumber numberWithLong:4],            @"length",								 
		 nil];
	[dataDictionary setObject:aDictionary forKey:@"TestSeries"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORDataGenDecoderForTestData1D",       @"decoder",
        [NSNumber numberWithLong:dataId1D],     @"dataId",
        [NSNumber numberWithBool:NO],           @"variable",
        [NSNumber numberWithLong:2],            @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"TestData1D"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORDataGenDecoderForTestData2D",       @"decoder",
        [NSNumber numberWithLong:dataId2D],     @"dataId",
        [NSNumber numberWithBool:NO],           @"variable",
        [NSNumber numberWithLong:3],            @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"TestData2D"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORDataGenDecoderForBurstData",       @"decoder",
				   [NSNumber numberWithLong:burstDataId],     @"dataId",
				   [NSNumber numberWithBool:NO],           @"variable",
				   [NSNumber numberWithLong:3],            @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"BurstTestData"];
	
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORDataGenDecoderForTestDataWaveform",		@"decoder",
        [NSNumber numberWithLong:dataIdWaveform],   @"dataId",
        [NSNumber numberWithBool:NO],				@"variable",
        [NSNumber numberWithLong:2048+2],			@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"TestDataWaveform"];
    return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORDataGenModel"];  
	first = YES; 
	lastTime = [[NSDate date]retain];
	burstTimer = [[ORTimer alloc] init];
	[burstTimer start];
	nextBurst = random_range(1,1000000);
	timeIndex = 0;
}

//----------------------------------------------------------------------------
// Function:	TakeData
// Description: Read data from a card
//----------------------------------------------------------------------------

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	//check for burst first
	if([burstTimer microseconds] >= nextBurst){
		short card = 0;
        short chan = 0;
		int i;
		unsigned long burstCount = random_range(1,10);
		for(i=0;i<burstCount;i++){
			unsigned long aValue = ((random()%500 + random()%500 + random()%500+ random()%500)/4);
			unsigned long data[3];
			data[0] = burstDataId | 3;
			data[1] = (card<<16) | (chan << 12) | (aValue & 0x0fff);
			data[2] = [burstTimer microseconds];			 
			
			[aDataPacket addLongsToFrameBuffer:data length:3];	
		}
		nextBurst = [burstTimer microseconds] + random_range(1000000,10000000);
	}
	
     if(random()%500 > 450 ){
        
		 NSDate* now = [NSDate date];
		 if([now timeIntervalSinceDate:lastTime] >= 1){
			 [now retain];
			 [lastTime release];
			 lastTime = now;
			 float theValue = 10.*sin(timeIndex*3.14159/180.)-5.;
			 timeIndex = (timeIndex+10);
	
			 time_t	ut_Time;
			 time(&ut_Time);
			 unsigned long timeMeasured = ut_Time;
			 
			 unsigned long data[4];
			 data[0] = timeSeriesId | 4;
			 data[1] = [self uniqueIdNumber]&0xfff;
			 
			 union {
				 float asFloat;
				 unsigned long asLong;
			 }theData;
			 theData.asFloat = theValue;
			 data[2] = theData.asLong;			 
			 data[3] = timeMeasured;
			 
			 [aDataPacket addLongsToFrameBuffer:data length:4];
		 }
		 
		 
        short card = random()%2;
        short chan = random()%8;
        unsigned long aValue = (100*chan) + ((random()%500 + random()%500 + random()%500+ random()%500)/4);
        if(card==0 && chan ==0)aValue = 100;
        unsigned long data[3];
        data[0] = dataId1D | 2;
        data[1] = (card<<16) | (chan << 12) | (aValue & 0x0fff);
        [aDataPacket addLongsToFrameBuffer:data length:2];

        data[0] = dataId2D | 3;
        aValue = 64 + ((random()%128 + random()%128 + random()%128)/3);
        data[1] = (aValue & 0x0fff); //card 0, chan 0
        aValue = 64 + ((random()%64 + random()%64 + random()%64)/3);
        data[2] = (aValue & 0x0fff);
        [aDataPacket addLongsToFrameBuffer:data length:3];
    }
	if(random()%500 > 498 ){
		 
		unsigned long data[2050];
        data[0] = dataIdWaveform | (2048+2);
        data[1] = 0; //card 0, chan 0
		int i;
		float radians = 0;
		float delta = 2*3.141592/360.;
		 short a = random()%20;
		 short b = random()%20;
		int count = 0;
		int toggle = 0;
		for(i=2;i<2050;i++){
			count++;
			data[i] = (50+(long)(a*sinf(radians) + b*sinf(2*radians))) & 0x0fffffff;
			if(i<512)data[i]  |= 0x10000000;
			if(i<1024)data[i] |= 0x20000000;
			if(i<1563)data[i] |= 0x40000000;
			if(count>50){
				count=0;
				toggle = !toggle;
			}
			if(toggle)data[i] |= 0x80000000;
			radians += delta;
		}
        [aDataPacket addLongsToFrameBuffer:data length:2050];

        data[0] = dataIdWaveform | 2050;
        data[1] = 0x00001000; //card 0, chan 1
		radians = 0;
		delta = 2*3.141592/360.;
		for(i=2;i<2050;i++){
			data[i] = 50+(long)(a*sinf(4*radians));
			radians += delta;
		}
        [aDataPacket addLongsToFrameBuffer:data length:2050];

	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo  
{
	[burstTimer release];
	burstTimer = nil;
}
	   
- (void)reset  {}


- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id = kDataGen; 
	configStruct->card_info[index].hw_mask[0] = dataId1D; 
	configStruct->card_info[index].hw_mask[1] = dataId2D; 
	configStruct->card_info[index].hw_mask[2] = dataIdWaveform; 
	configStruct->card_info[index].hw_mask[3] = burstDataId; 
	configStruct->card_info[index].num_Trigger_Indexes = 0;	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	return index+1;
}


#pragma mark ¥¥¥Bit Processing Protocol
- (void)processIsStarting
{
	adcValue = 0;
	theta = 0;
}

- (void)processIsStopping
{
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{
	adcValue = 10.0*sinf(0.017453 * theta);
	theta = (theta+1)%360;
}

- (void) endProcessCycle
{
}

- (BOOL) processValue:(int)channel
{
	return adcValue!=0;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    //nothing to do
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"Test Data %lu",[self uniqueIdNumber]];
}

- (NSString*) processingTitle
{
    return @"Data Gen";
}

- (double) convertedValue:(int)channel
{
	return adcValue;
}

- (double) maxValueForChan:(int)channel
{
	return 10.0;
}
- (double) minValueForChan:(int)channel
{
	return -10.0;
}
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		*theLowLimit = -5.0;
		*theHighLimit = +5.0;
	}		
}

@end


