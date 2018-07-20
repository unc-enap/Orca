//
//  ORAmptekDP5Decoder.m
//  Orca
//
//  Created by Mark Howe on 9/30/07.
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


#import "ORAmptekDP5Decoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
//#import "ORAmptekDP5Defs.h"














@implementation ORAmptekDP5DecoderForSpectrum

//-------------------------------------------------------------
/** Data format for waveform
 *
 <pre>  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx location = unique ID number (if multiple AmpTek DP5 boards present)  ---> deviceID in ROOT file
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
 ------------------- ^^^^ ^^^^ ^^^^ ^^^^-spectrum length (=MCAC) in 3-byte-words (max. 8192)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx info flags (bit0=hasStatus)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx acquisition time (refer to  page 14,58 of the "DP5 Programmer Guide" Rev A6)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx realtime (dito)

 followed by original UDP packet data (max. ~  25000 bytes, ~6150 32-bit- words)
 UDP packet is: 8 byte header/checksum + 3 * x * 256 byte + 64 byte status => multiple of 4 => can be saved as uint_32
 <pre>  
 */ 
//-------------------------------------------------------------
- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}


- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length	= ExtractLength(ptr[0]);
	unsigned char location	= ptr[1];
    uint32_t specLen        = ptr[4]; // ShiftAndExtract(ptr[1],0,0xffffffff);
	//uint32_t startIndex= ShiftAndExtract(ptr[7],8,0x7ff);



	//channel by channel histograms
	//uint32_t energy = ptr[6];
    //uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array


    NSString* device    = [NSString stringWithFormat:@"Amptek-%d\n", location];


    
    

	
	
//TODO: no offset -tb-
//startIndex=traceStart16;
//startIndex=0;

//TODO: what is the best value for the 'mask'? 0xFFFF is appropriate for shorts ... -tb-


	// Set up the waveform
	NSMutableData* spectrumData = [NSMutableData dataWithCapacity: specLen*sizeof(int32_t)];
	//NSData* waveFormdata = [NSData dataWithBytes:someData length:specLen*sizeof(int32_t)];
    
    int i;
    unsigned char *cSpecData = (unsigned char *) (someData + 4*8+6);//set to start of spectrum data 
    unsigned char cZero = 0;
    for(i=0; i<specLen; i++){
        [spectrumData appendBytes: (cSpecData+3*i) length: 3];
        [spectrumData appendBytes: &cZero length: 1];
    }

	[aDataSet loadWaveform: spectrumData					//pass in the whole data set
					offset: 0					// Offset in bytes (past header words)
				  unitSize: sizeof(int32_t)					// unit size in bytes
				startIndex:	0					// first Point Index (past the header offset!!!)
					  mask:	0xFFFFFFFF							// when displayed all values will be masked with this value
					sender: self 
				  withKeys: @"AmptekDP5", @"Spectrum",device, @"Spectrum", nil];

#if 0
	// Set up the waveform
	//NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(int32_t)];
	

if((eventFlags4bit == 0x1) || (eventFlags4bit == 0x3)){//raw UDP packet
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0xFFFF							// when displayed all values will be masked with this value
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"UDP-Raw",crateKey,stationKey,fiberKey,channelKey,nil];
}else if((eventFlags4bit == 0x2)){//FLT event
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0xFFFF							// when displayed all values will be masked with this value
			   specialBits:0x0000	
				  bitNames: [NSArray arrayWithObjects:nil]
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"FLT-Event-old",crateKey,stationKey,trigChannelKey/*totalChannelKey*/,nil];
				 // withKeys: @"IPE-SLT", @"ADCChannels",crateKey,stationKey,fiberKey,channelKey,nil];
}else{
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0xFFFF							// when displayed all values will be masked with this value
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"UDP-ADC-Channels",crateKey,stationKey,totalChannelKey,nil];
				 // withKeys: @"IPE-SLT", @"ADCChannels",crateKey,stationKey,fiberKey,channelKey,nil];
}



    if(eventFlags4bit == 0x2){//FLT event
        uint32_t energy         = ptr[6] & 0x00ffffff;
        uint32_t shapingLength  = ptr[8] & 0x000000ff;
        printf("energy:0x%08x sL:%i flt:%i chan:%i\n",energy,shapingLength,card,trigChan);
        if(energy & 0x00800000){//energy is negative
            energy = ~(energy | 0xff000000);
	        //channel by channel histograms
            if(shapingLength>0) energy=energy/shapingLength;
	        [aDataSet histogram:energy 
				        numBins:kPageLength sender:self  
			           withKeys:@"IPE-SLT-EW-Energy", @"FLT-Energy (neg)" , crateKey,stationKey,trigChannelKey,nil];
        }else{//energy is positive
	        //channel by channel histograms
            if(shapingLength>0) energy=energy/shapingLength;
	        [aDataSet histogram:energy 
				        numBins:kPageLength sender:self  
			           withKeys:@"IPE-SLT-EW-Energy", @"FLT-Energy (pos)" , crateKey,stationKey,trigChannelKey,nil];
        }
    }

#endif

	
    

										
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{

	uint32_t length	= ExtractLength(ptr[0]);
	//unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	//unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	//unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
    uint32_t location       = ptr[1];
    uint32_t sec            = ptr[2];
    uint32_t subsec         = ptr[3]; // ShiftAndExtract(ptr[1],0,0xffffffff);
    uint32_t specLen        = ptr[4]; // ShiftAndExtract(ptr[1],0,0xffffffff);
    //uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array

    
    NSString* title= @"AmpTekDP5 Spectrum Record\n\n";

	++ptr;		//skip the first word (dataID and length)
    
    NSString* device    = [NSString stringWithFormat:@"DeviceId   = %u\n", location];
    NSString* secStr    = 0;//[NSString stringWithFormat:@"Sec        = %d\n", sec];
    NSString* subsecStr = 0;//[NSString stringWithFormat:@"SubSec     = %d\n", subsec];
        secStr    = [NSString stringWithFormat:@"UTC-sec = 0x%08x\n", sec];
        subsecStr = [NSString stringWithFormat:@"subsec = 0x%08x\n", subsec];
    NSString* specLengthStr = [NSString stringWithFormat:@"Spectrum len = %u\n", specLen];
    
    NSString* lengthStr = [NSString stringWithFormat:@"Length tot    = %u\n", length];
    

    return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,device,  
                secStr, subsecStr, specLengthStr, lengthStr]; 
}

@end





















@implementation ORAmptekDP5DecoderForEvent

//-------------------------------------------------------------
/** Data format for event:
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
					^^^^ ^^^^-----------spare
					          ^^^^------counter type
					               ^^^^-record type (sub type)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventCounter (when record type != 0 see below)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx timeStamp Hi
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx timeStamp Lo
when record type != 0 the eventCounter is 0 (has no meaning) and for
record type = 1 = kStartRunType:	the timestamp is a run start timestamp
record type = 2 = kStopRunType:		the timestamp is a run stop timestamp
record type = 3 = kStartSubRunType: the timestamp is a subrun start timestamp
record type = 4 = kStopSubRunType:	the timestamp is a subrun stop timestamp

counter type = kSecondsCounterType, kVetoCounterType, kDeadCounterType, kRunCounterType
1:
**/
//-------------------------------------------------------------

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length	= ExtractLength(*ptr);	 //get length from first word
	[aDataSet loadGenericData:@" " sender:self withKeys:@"v4SLT",@"Test Record",nil];
    return length; //nothing to display at this time.. just return the length
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{

	NSString* title= @"Ipe SLTv4 Event Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %u\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %u\n",(*ptr>>16) & 0x1f];
	int recordType = (*ptr) & 0xf;
	//int counterType = ((*ptr)>>4) & 0xf;
	
	++ptr;		//point to event counter
	
	if (recordType == 0) {
		NSString* eventCounter    = [NSString stringWithFormat:@"Event     = %u\n",*ptr++];
		NSString* timeStampHi     = [NSString stringWithFormat:@"Time Hi   = %u\n",*ptr++];
		NSString* timeStampLo     = [NSString stringWithFormat:@"Time Lo   = %u\n",*ptr];		

		return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,crate,card,
							eventCounter,timeStampHi,timeStampLo];               
	}
	
	++ptr;		//skip event counter
	//timestamp events
	NSString* counterString;
    counterString    = [NSString stringWithFormat:@"Unknown Counter\n"];
    
    #if 0 //TODO: to omit amptekdp5defs.h
	switch (counterType) {
		case kSecondsCounterType:	counterString    = [NSString stringWithFormat:@"Seconds Counter\n"]; break;
		case kVetoCounterType:		counterString    = [NSString stringWithFormat:@"Veto Counter\n"]; break;
		case kDeadCounterType:		counterString    = [NSString stringWithFormat:@"Deadtime Counter\n"]; break;
		case kRunCounterType:		counterString    = [NSString stringWithFormat:@"Run  Counter\n"]; break;
		default:					counterString    = [NSString stringWithFormat:@"Unknown Counter\n"]; break;
	}
    #endif
	NSString* typeString;
    typeString    = [NSString stringWithFormat:@"Unknown Timestamp Type\n"];
    
    #if 0 //TODO: to omit amptekdp5defs.h
	switch (recordType) {
		case kStartRunType:		typeString    = [NSString stringWithFormat:@"Start Run Timestamp\n"]; break;
		case kStopRunType:		typeString    = [NSString stringWithFormat:@"Stop Run Timestamp\n"]; break;
		case kStartSubRunType:	typeString    = [NSString stringWithFormat:@"Start SubRun Timestamp\n"]; break;
		case kStopSubRunType:	typeString    = [NSString stringWithFormat:@"Stop SubRun Timestamp\n"]; break;
		default:				typeString    = [NSString stringWithFormat:@"Unknown Timestamp Type\n"]; break;
	}
    #endif
    
    
    
    
    
    
	NSString* timeStampHi     = [NSString stringWithFormat:@"Time Hi   = %u\n",*ptr++];
	NSString* timeStampLo     = [NSString stringWithFormat:@"Time Lo   = %u\n",*ptr];		

	return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,
						counterString,typeString,timeStampHi,timeStampLo];               
}
@end


@implementation ORAmptekDP5DecoderForMultiplicity

//-------------------------------------------------------------
/** Data format for multiplicity
  *
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
			        ^^^^ ^^^^ ^^^^ ^^^^-spare
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventCount
followed by multiplicity data (20 longwords -- 1 pixel mask per card)
  *
  */
//-------------------------------------------------------------


- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length	= ExtractLength(*ptr);	 //get length from first word

	++ptr;											//crate, card,channel from second word
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
		
	++ptr;		//point to event count
	//NSString* eventCount = [NSString stringWithFormat:@"%d",*ptr];
	//[aDataSet loadGenericData:eventCount sender:self withKeys:@"EventCount",@"Ipe SLT", crateKey,stationKey,nil];
					
				
	// Display data, ak 12.2.08
	++ptr;		//point to trigger data
	uint32_t *pMult = ptr;
	int i, j, k;
	//NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
    uint32_t xyProj[20];
	uint32_t tyProj[100];
	uint32_t pageSize = length/20;
	
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	
	for (k=0;k<20*pageSize;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<20*pageSize;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	int nTriggered = 0;
	for (i=0;i<20;i++){
		for(j=0;j<22;j++){
			if (((xyProj[i]>>j) & 0x1 ) == 0x1) nTriggered++;
		}
	}
	
	
	// Clear dataset
    [aDataSet clear];	
	
	for(j=0;j<22;j++){
		//NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
		//matrix of triggered pixel
		for(i=0;i<20;i++){
			//if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
			//else							   [s appendFormat:@"."];
			
			if (((xyProj[i]>>j) & 0x1) == 0x1) {
	          [aDataSet histogram2DX: i 
                    y: j
					size: 130                          
					sender: self 
					withKeys: @"SLTv4", @"TriggerData",crateKey,stationKey,nil];
			}
		}
		//[s appendFormat:@"   "];
		
		// trigger timing
		for (k=0;k<pageSize;k++){
			//if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
			//else							   [s appendFormat:@"."];
			
			if (((tyProj[k]>>j) & 0x1) == 0x1 ){
	          [aDataSet histogram2DX: k+30 
                    y: j
					size: 130                          
					sender: self 
					withKeys: @"SLTv4", @"TriggerData",crateKey,stationKey,nil];
			}			
		}
		//NSLogFont(aFont, @"%@\n", s);
		
	}
	
	//NSLogFont(aFont,@"\n");	
	
					
    return length; //must return number of longs processed.
}


- (NSString*) dataRecordDescription:(uint32_t*)ptr
{

    NSString* title= @"Auger FLT Waveform Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %u\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %u\n",(*ptr>>16) & 0x1f];
	++ptr;		//point to next structure
	
	NSString* eventCount		= [NSString stringWithFormat:@"Event Count = %u\n",*ptr];

    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,eventCount]; 
}

@end












@implementation ORAmptekDP5DecoderForWaveForm

//-------------------------------------------------------------
/** Data format for waveform
 *
 <pre>  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
 ------- ^ ^^^---------------------------crate
 -------------^ ^^^^---------------------card
 --------------------^^^^ ---------------fiber
 ------------------------ ^^^^-----------channel
 --------------------^^^^ ^^^^-----------OR FLT trigger channel (0...29, including fast channels; or 0...41 including filter debug output)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
 ------------------- ^^^^ ^^^^ ^^^^ ^^^^ total channel number (or index) (16bit)  ; channel map (for FLT event record)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventID: ...??? TBD
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx numfifo ;  or energy resp. evFIFO3  (for FLT event record)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventFlags
                 ^^^ ^^^^ ^^^^-----------traceStart16 (first trace value in short array, 11 bit, 0..2047)
                                 ^-------append flag is in this record (append to previous record)
                                  ^------append next waveform record
                                    ^^^^-number which defines the content of the record (kind of version number)
                                         bit0=0: ADC trace; (bit1=0:SLT trace from ipe4reader, bit1=1: FLT event data packet)
                                         bit0=1: UDP packet (bit1=0:status packet, bit1=1: data packet)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx not yet defined ... //spare to remain byte compatible with the KATRIN records
 
 followed by waveform data (up to 2048 16-bit words)
 <pre>  
 */ 
//-------------------------------------------------------------
- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualFlts release];
    [super dealloc];
}


- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length	= ExtractLength(ptr[0]);
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	unsigned char fiber		= ShiftAndExtract(ptr[1],12,0xf);
	unsigned int totalChan		= ShiftAndExtract(ptr[4],0,0xffff);
	unsigned char chan		= ShiftAndExtract(ptr[1],8,0xf);
	unsigned int trigChan	= ShiftAndExtract(ptr[1],8,0xff);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* fiberKey	    = [NSString stringWithFormat:@"Fiber %2d",fiber];	
	NSString* channelKey	= [self getChannelKey: chan];	
	NSString* trigChannelKey	= [self getChannelKey: trigChan];	
	NSString* totalChannelKey	= [self getChannelKey: totalChan];	
	uint32_t startIndex= ShiftAndExtract(ptr[7],8,0x7ff);

	//channel by channel histograms
	//uint32_t energy = ptr[6];
    uint32_t eventFlags     = ptr[7];
    //uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array
    
#define kPageLength (64*1024)
    
#if 0



	int page = energy/kPageLength;
	int startPage = page*kPageLength;
	int endPage = (page+1)*kPageLength;
	
	//channel by channel histograms
	[aDataSet histogram:energy - page*kPageLength 
				numBins:kPageLength sender:self  
			   withKeys:@"FLTv4", [NSString stringWithFormat:@"Energy (%d - %d)",startPage,endPage], crateKey,stationKey,channelKey,nil];
	
	//accumulated card level histograms
	[aDataSet histogram:energy - page*kPageLength 
				numBins:kPageLength sender:self  
			   withKeys:@"FLTv4", [NSString stringWithFormat:@"Total Card Energy (%d - %d)",startPage,endPage], crateKey,stationKey,nil];
	
	//accumulated crate level histograms
	[aDataSet histogram:energy - page*kPageLength 
				numBins:kPageLength sender:self  
			   withKeys:@"FLTv4", [NSString stringWithFormat:@"Total Crate Energy (%d - %d)",startPage,endPage], crateKey,nil];
#endif

	
	
	// Set up the waveform
	NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(int32_t)];
	
	#if 0
	//-----------------------------------------------
	//temp.. to lock the waveform to the highest value
	int n = [waveFormdata length]/sizeof(short) - 20;
	uint32_t maxValue = 0;
	startIndex = 0;
	uint32_t i;
	unsigned short* p = (unsigned short*)[waveFormdata bytes];
	for(i=20;i<n;i++){
		unsigned short theValue = p[i] & 0xfff;
		if(theValue>maxValue){
			maxValue = theValue;
			startIndex = i;
		}	
	}
	startIndex = (startIndex+2000)%n;
	//-----------------------------------------------
	#endif
//TODO: no offset -tb-
//startIndex=traceStart16;
startIndex=0;

//TODO: what is the best value for the 'mask'? 0xFFFF is appropriate for shorts ... -tb-

    uint32_t eventFlags4bit     = eventFlags & 0xf;

if((eventFlags4bit == 0x1) || (eventFlags4bit == 0x3)){//raw UDP packet
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0xFFFF							// when displayed all values will be masked with this value
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"UDP-Raw",crateKey,stationKey,fiberKey,channelKey,nil];
}else if((eventFlags4bit == 0x2)){//FLT event
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0xFFFF							// when displayed all values will be masked with this value
			   specialBits:0x0000	
				  bitNames: [NSArray array]
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"FLT-Event-old",crateKey,stationKey,trigChannelKey/*totalChannelKey*/,nil];
				 // withKeys: @"IPE-SLT", @"ADCChannels",crateKey,stationKey,fiberKey,channelKey,nil];
}else{
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0xFFFF							// when displayed all values will be masked with this value
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"UDP-ADC-Channels",crateKey,stationKey,totalChannelKey,nil];
				 // withKeys: @"IPE-SLT", @"ADCChannels",crateKey,stationKey,fiberKey,channelKey,nil];
}



    if(eventFlags4bit == 0x2){//FLT event
        uint32_t energy         = ptr[6] & 0x00ffffff;
        uint32_t shapingLength  = ptr[8] & 0x000000ff;
        printf("energy:0x%08x sL:%i flt:%i chan:%i\n",energy,shapingLength,card,trigChan);
        if(energy & 0x00800000){//energy is negative
            energy = ~(energy | 0xff000000);
	        //channel by channel histograms
            if(shapingLength>0) energy=energy/shapingLength;
	        [aDataSet histogram:energy 
				        numBins:kPageLength sender:self  
			           withKeys:@"IPE-SLT-EW-Energy", @"FLT-Energy (neg)" , crateKey,stationKey,trigChannelKey,nil];
        }else{//energy is positive
	        //channel by channel histograms
            if(shapingLength>0) energy=energy/shapingLength;
	        [aDataSet histogram:energy 
				        numBins:kPageLength sender:self  
			           withKeys:@"IPE-SLT-EW-Energy", @"FLT-Energy (pos)" , crateKey,stationKey,trigChannelKey,nil];
        }
    }



    #if 0 //this was the KATRIN setting -tb-
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0x0FFF							// when displayed all values will be masked with this value
			   specialBits:0xF000	
				  bitNames: [NSArray arrayWithObjects:@"trig",@"over",@"under", @"extern",nil]
					sender: self 
				  withKeys: @"FLTv4", @"Waveform",crateKey,stationKey,channelKey,nil];
    #endif
	
	
    
#if 0
	//get the actual object
	if(getRatesFromDecodeStage){
		NSString* fltKey = [crateKey stringByAppendingString:stationKey];
		if(!actualFlts)actualFlts = [[NSMutableDictionary alloc] init];
		OREdelweissFLTModel* obj = [actualFlts objectForKey:fltKey];
		if(!obj){
			NSArray* listOfFlts = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"OREdelweissFLTModel")];
			for(OREdelweissFLTModel* aFlt in listOfFlts){
				if(/*[aFlt crateNumber] == crate &&*/ [aFlt stationNumber] == card){
					[actualFlts setObject:aFlt forKey:fltKey];
					obj = aFlt;
					break;
				}
			}
		}
		getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:chan];
	}
#endif
	
										
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{

	uint32_t length	= ExtractLength(ptr[0]);
	//unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	//unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	//unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
    uint32_t sec            = ptr[2];
    uint32_t subsec         = ptr[3]; // ShiftAndExtract(ptr[1],0,0xffffffff);
    uint32_t chmap          = ptr[4];
    uint32_t eventID        = ptr[5];
    uint32_t numfifo        = ptr[6];
    uint32_t energy         = ptr[6] & 0x00ffffff;
    uint32_t eventFlags     = ptr[7];
    uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array

    uint32_t eventFlags4bit     = eventFlags & 0xf;
    
    NSString* title= @"EDELWEISS SLT Waveform Record\n\n";

	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate     = [NSString stringWithFormat:@"Crate      = %u\n",(*ptr>>21) & 0xf];
    NSString* card      = [NSString stringWithFormat:@"Station    = %u\n",(*ptr>>16) & 0x1f];
    NSString* fiber     = [NSString stringWithFormat:@"Fiber      = %u\n",(*ptr>>12) & 0xf];
    NSString* chan      = [NSString stringWithFormat:@"Channel    = %u\n",(*ptr>>8) & 0xf];
    NSString* secStr    = 0;//[NSString stringWithFormat:@"Sec        = %d\n", sec];
    NSString* subsecStr = 0;//[NSString stringWithFormat:@"SubSec     = %d\n", subsec];
    NSString* energyStr = 0;//[NSString stringWithFormat:@"NumFIFO     = %d\n", numfifo];
    if((eventFlags4bit == 0x2)){//FLT event
        secStr    = [NSString stringWithFormat:@"Time 0..31 = 0x%08x\n", sec];
        subsecStr = [NSString stringWithFormat:@"Time32..47 = 0x%08x\n", subsec];
        energyStr = [NSString stringWithFormat:@"Energy     = 0x%08x\n", energy];
    }else{
        secStr    = [NSString stringWithFormat:@"Sec        = %d\n", sec];
        subsecStr = [NSString stringWithFormat:@"SubSec     = %d\n", subsec];
        energyStr = [NSString stringWithFormat:@"NumFIFO     = %d\n", numfifo];
    }
    NSString* chmapStr  = [NSString stringWithFormat:@"ChannelMap = 0x%x\n", chmap];
    NSString* eventIDStr= [NSString stringWithFormat:@"ReadPtr,Pg#= %d,%d\n", ShiftAndExtract(eventID,0,0x3ff),ShiftAndExtract(eventID,10,0x3f)];
    NSString* offsetStr = [NSString stringWithFormat:@"Offset16   = %d\n", traceStart16];
    NSString* versionStr= [NSString stringWithFormat:@"RecVersion = %d\n", ShiftAndExtract(eventFlags,0,0xf)];
    NSString* eventFlagsStr
                        = [NSString stringWithFormat:@"Flag(a,ap) = %d,%d\n", ShiftAndExtract(eventFlags,4,0x1),ShiftAndExtract(eventFlags,5,0x1)];
    NSString* lengthStr = [NSString stringWithFormat:@"Length     = %u\n", length];
    
    
    NSString* evFlagsStr= [NSString stringWithFormat:@"EventFlags = 0x%x\n", eventFlags ];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,fiber,chan,  
                secStr, subsecStr, energyStr, chmapStr, eventIDStr, offsetStr, versionStr, eventFlagsStr, lengthStr,   evFlagsStr]; 
}

@end














@implementation ORAmptekDP5DecoderForFLTEvent

//-------------------------------------------------------------
/** Data format for waveform
 *
 <pre>  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
 ------- ^ ^^^---------------------------crate
 -------------^ ^^^^---------------------card
                             !!!!!!!!!             --------------------^^^^ ---------------fiber   //TODO: ensure map is in header -tb- !!!!!!!
 --------------------^^^^ ^^^^-----------channel
 --------------------^^^^ ^^^^-----------OR FLT trigger channel (0...29, including fast channels; or 0...41 including filter debug output)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo0: timestamp lo (bit [31:0])    
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo1: FLT# (8bit) , 8 bit reserved, timestamp hi 16 bit (bit [47:32]) and FLT#
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo2: (TR(3 bit)+)    channel map (for FLT event record) (18 bit)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo3: (U (6 bit)+)    energy (24 bit)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx EventFifo4: pageN (4 bit) +  triggerAddress (12 bit)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventFlags
                 ^^^ ^^^^ ^^^^-----------traceStart16 (first trace value in short array, 11 bit, 0..2047)
                                 ^-------append flag is in this record (append to previous record)
                                  ^------append next waveform record
                                    ^^^^-number which defines the content of the record (kind of version number)
                                         bit0=0: ADC trace; (bit1=0:SLT trace from ipe4reader, bit1=1: FLT event data packet)
                                         bit0=1: UDP packet (bit1=0:status packet, bit1=1: data packet)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx not yet defined ... //spare to remain byte compatible with the KATRIN records
 
 followed by waveform data (up to 2048 16-bit words)
 <pre>  
 */ 
//-------------------------------------------------------------
- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualFlts release];
    [super dealloc];
}


- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length	= ExtractLength(ptr[0]);
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	//unsigned char fiber		= ShiftAndExtract(ptr[1],12,0xf);
	//unsigned int totalChan		= ShiftAndExtract(ptr[4],0,0xffff);//channel map
	//unsigned char chan		= ShiftAndExtract(ptr[1],8,0xf);
	unsigned int trigChan	= ShiftAndExtract(ptr[1],8,0xff);      //channel 0..41
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	//NSString* fiberKey	    = [NSString stringWithFormat:@"Fiber %2d",fiber];
	//NSString* channelKey	= [self getChannelKey: chan];
	NSString* trigChannelKey	= [self getChannelKey: trigChan];	
	//NSString* totalChannelKey	= [self getChannelKey: totalChan];
	//uint32_t startIndex= ShiftAndExtract(ptr[7],8,0x7ff);
	uint32_t startIndex  = 0;
	uint32_t triggerAddr = ShiftAndExtract(ptr[6],0,0xfff);
   // uint32_t eventFifo4       = ptr[6]; //f4

	//channel by channel histograms
	//uint32_t energy = ptr[6];
    uint32_t eventFlags     = ptr[7];
    //uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array
    
#define kPageLength (64*1024)
    
#if 0



	int page = energy/kPageLength;
	int startPage = page*kPageLength;
	int endPage = (page+1)*kPageLength;
	
	//channel by channel histograms
	[aDataSet histogram:energy - page*kPageLength 
				numBins:kPageLength sender:self  
			   withKeys:@"FLTv4", [NSString stringWithFormat:@"Energy (%d - %d)",startPage,endPage], crateKey,stationKey,channelKey,nil];
	
	//accumulated card level histograms
	[aDataSet histogram:energy - page*kPageLength 
				numBins:kPageLength sender:self  
			   withKeys:@"FLTv4", [NSString stringWithFormat:@"Total Card Energy (%d - %d)",startPage,endPage], crateKey,stationKey,nil];
	
	//accumulated crate level histograms
	[aDataSet histogram:energy - page*kPageLength 
				numBins:kPageLength sender:self  
			   withKeys:@"FLTv4", [NSString stringWithFormat:@"Total Crate Energy (%d - %d)",startPage,endPage], crateKey,nil];
#endif

	
	
	// Set up the waveform
	NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(int32_t)];
	
	#if 0
	//-----------------------------------------------
	//temp.. to lock the waveform to the highest value
	int n = [waveFormdata length]/sizeof(short) - 20;
	uint32_t maxValue = 0;
	startIndex = 0;
	uint32_t i;
	unsigned short* p = (unsigned short*)[waveFormdata bytes];
	for(i=20;i<n;i++){
		unsigned short theValue = p[i] & 0xfff;
		if(theValue>maxValue){
			maxValue = theValue;
			startIndex = i;
		}	
	}
	startIndex = (startIndex+2000)%n;
	//-----------------------------------------------
	#endif
//TODO: no offset -tb-
//startIndex=traceStart16;
//2013-12-16: from now on I save the shifted trace -tb- startIndex+=1023;


    uint32_t eventFlags4bit     = eventFlags & 0xf;
    
    

    // waveforms
    //----------------------------------------
    if(trigChan<18 || trigChan>29){//slow channel or filter output
        startIndex=0;
	    [aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0  // 0xFFFF // when displayed all values will be masked with this value //only necessary if some bits need to be masked out -tb-
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"FLT-Event",crateKey,stationKey,trigChannelKey/*totalChannelKey*/,nil];
				 // withKeys: @"IPE-SLT", @"ADCChannels",crateKey,stationKey,fiberKey,channelKey,nil];
    }else{//fast channel
        if(eventFlags4bit==0x2){
            startIndex= (-triggerAddr-1023)%2048;//revert offset from SLTv4Readout -tb-
        }else{
            startIndex= 0;//for e.g. version 0x4
        }

		[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0  // 0xFFFF // when displayed all values will be masked with this value //only necessary if some bits need to be masked out -tb-
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"FLT-Event",crateKey,stationKey,trigChannelKey/*totalChannelKey*/,nil];
    }
    //DEBUG 	   NSLog(@"%@::%@ plot FIC channel %i, flags: %i, triggerAddr:%i, startIndex:%i, eventFifo4:0x%08x\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),trigChan, eventFlags4bit,triggerAddr,startIndex,eventFifo4);//TODO: DEBUG testing ...-tb-

    
    #if 0 //old call  -  the specialBits waveform seems to be buggy (in plots, "Unsigned" check has no effect ...) -tb-
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0xFFFF							// when displayed all values will be masked with this value
			   specialBits:0x0000	
				  bitNames: [NSArray arrayWithObjects:nil]
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"FLT-Event",crateKey,stationKey,trigChannelKey/*totalChannelKey*/,nil];
				 // withKeys: @"IPE-SLT", @"ADCChannels",crateKey,stationKey,fiberKey,channelKey,nil];
    #endif


#if 0 //TODO: remove it -tb-
//TODO: what is the best value for the 'mask'? 0xFFFF is appropriate for shorts ... -tb-
eventFlags4bit=0x2;//TODO: fake FLT event -tb- remove it ...
if((eventFlags4bit == 0x1) || (eventFlags4bit == 0x3)){//raw UDP packet
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0xFFFF							// when displayed all values will be masked with this value
			   specialBits:0x0000	
				  bitNames: [NSArray arrayWithObjects:nil]
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"UDP-Raw",crateKey,stationKey,fiberKey,channelKey,nil];
}else if((eventFlags4bit == 0x2)){//FLT event
    if(1 || trigChan<30){
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0  // 0xFFFF // when displayed all values will be masked with this value //only necessary if some bits need to be masked out -tb-
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"FLT-Eventxxxxx",crateKey,stationKey,trigChannelKey/*totalChannelKey*/,nil];
				 // withKeys: @"IPE-SLT", @"ADCChannels",crateKey,stationKey,fiberKey,channelKey,nil];
    }else{
    }
    #if 0 //old call  -  the specialBits waveform seems to be buggy (in plots, "Unsigned" check has no effect ...) -tb-
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0xFFFF							// when displayed all values will be masked with this value
			   specialBits:0x0000	
				  bitNames: [NSArray arrayWithObjects:nil]
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"FLT-Event",crateKey,stationKey,trigChannelKey/*totalChannelKey*/,nil];
				 // withKeys: @"IPE-SLT", @"ADCChannels",crateKey,stationKey,fiberKey,channelKey,nil];
    #endif

}else{
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0xFFFF							// when displayed all values will be masked with this value
			   specialBits:0x0000	
				  bitNames: [NSArray arrayWithObjects:nil]
					sender: self 
				  withKeys: @"IPE-SLT-EW", @"UDP-ADC-Channels",crateKey,stationKey,totalChannelKey,nil];
				 // withKeys: @"IPE-SLT", @"ADCChannels",crateKey,stationKey,fiberKey,channelKey,nil];
}
#endif



    // energy histogram(s)
    //----------------------------------------
    if(eventFlags4bit == 0x2){//FLT event
        uint32_t energy         = ptr[6] & 0x00ffffff;
        uint32_t shapingLength  = ptr[8] & 0x000000ff;
        printf("energy:0x%08x sL:%i flt:%i chan:%i\n",energy,shapingLength,card,trigChan);
        if(energy & 0x00800000){//energy is negative
            energy = ~(energy | 0xff000000);
	        //channel by channel histograms
            if(shapingLength>0) energy=energy/shapingLength;
	        [aDataSet histogram:energy 
				        numBins:kPageLength sender:self  
			           withKeys:@"IPE-SLT-EW-Energy", @"FLT-Energy (neg)" , crateKey,stationKey,trigChannelKey,nil];
        }else{//energy is positive
	        //channel by channel histograms
            if(shapingLength>0) energy=energy/shapingLength;
	        [aDataSet histogram:energy 
				        numBins:kPageLength sender:self  
			           withKeys:@"IPE-SLT-EW-Energy", @"FLT-Energy (pos)" , crateKey,stationKey,trigChannelKey,nil];
        }
    }



    #if 0 //this was the KATRIN setting -tb-
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(int32_t)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0x0FFF							// when displayed all values will be masked with this value
			   specialBits:0xF000	
				  bitNames: [NSArray arrayWithObjects:@"trig",@"over",@"under", @"extern",nil]
					sender: self 
				  withKeys: @"FLTv4", @"Waveform",crateKey,stationKey,channelKey,nil];
    #endif
	
	
    
#if 0
	//get the actual object
	if(getRatesFromDecodeStage){
		NSString* fltKey = [crateKey stringByAppendingString:stationKey];
		if(!actualFlts)actualFlts = [[NSMutableDictionary alloc] init];
		OREdelweissFLTModel* obj = [actualFlts objectForKey:fltKey];
		if(!obj){
			NSArray* listOfFlts = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"OREdelweissFLTModel")];
			for(OREdelweissFLTModel* aFlt in listOfFlts){
				if(/*[aFlt crateNumber] == crate &&*/ [aFlt stationNumber] == card){
					[actualFlts setObject:aFlt forKey:fltKey];
					obj = aFlt;
					break;
				}
			}
		}
		getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:chan];
	}
#endif
	
										
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{

	uint32_t length	= ExtractLength(ptr[0]);
	//unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	//unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	//unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
	unsigned int trigChan	= ShiftAndExtract(ptr[1],8,0xff);
    uint32_t sec            = ptr[2]; //f0   
    uint32_t subsec         = ptr[3]; //f1   // ShiftAndExtract(ptr[1],0,0xffffffff);
    uint32_t timelo         = ptr[2]; 
    uint64_t timehi         = ptr[3]; // ShiftAndExtract(ptr[1],0,0xffffffff);
    uint64_t timestamp=timelo | ((timehi & 0xffff)<<32);
    uint32_t chmap          = ptr[4]; //f2
    uint32_t energy         = ptr[5] & 0x00ffffff;  //f3
  //  uint32_t eventID        = ptr[6];
    uint32_t eventFifo4       = ptr[6]; //f4
//    uint32_t numfifo        = ptr[6];
    uint32_t eventFlags     = ptr[7];
    uint32_t spareWord      = ptr[8];
    //uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array
    uint32_t traceStart16 = ShiftAndExtract(ptr[6],0,0xfff);//start of trace in short array

    uint32_t eventFlags4bit     = eventFlags & 0xf;
    
    NSString* title= @"EDELWEISS FLT Trigger Event\n\n";

	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate     = [NSString stringWithFormat:@"Crate      = %u\n",(*ptr>>21) & 0xf];
    NSString* card      = [NSString stringWithFormat:@"Station    = %u\n",(*ptr>>16) & 0x1f];
    //NSString* fiber     = [NSString stringWithFormat:@"Fiber      = %u\n",(*ptr>>12) & 0xf];
    //NSString* chan      = [NSString stringWithFormat:@"Channel    = %u\n",(*ptr>>8) & 0xf];
    NSString* chan      = [NSString stringWithFormat:@"Channel    = %u\n",trigChan];
    NSString* timeStr    = 0; 
    NSString* secStr    = 0;//[NSString stringWithFormat:@"Sec        = %d\n", sec];
    NSString* subsecStr = 0;//[NSString stringWithFormat:@"SubSec     = %d\n", subsec];
    NSString* energyStr = 0;//[NSString stringWithFormat:@"NumFIFO     = %d\n", numfifo];
    if((eventFlags4bit == 0x2)){//FLT event
    }
        secStr    = [NSString stringWithFormat:@"Time 0..31 = 0x%08x\n", sec];
        subsecStr = [NSString stringWithFormat:@"Time32..47 = 0x%08x\n", subsec];
        timeStr   = [NSString stringWithFormat:@"Timestamp  = %lli\n", timestamp];
        energyStr = [NSString stringWithFormat:@"Energy     = 0x%08x\n", energy];
    NSString* chmapStr  = [NSString stringWithFormat:@"ChannelMap = 0x%x\n", chmap];
    NSString* eventIDStr= [NSString stringWithFormat:@"Pg#,offset= %d,%d\n", ShiftAndExtract(eventFifo4,12,0xf),ShiftAndExtract(eventFifo4,0,0xfff)];
    NSString* offsetStr = [NSString stringWithFormat:@"Offset16   = %d\n", traceStart16];
    NSString* versionStr= [NSString stringWithFormat:@"RecVersion = %d\n", ShiftAndExtract(eventFlags,0,0xf)];
    NSString* eventFlagsStr
                        = [NSString stringWithFormat:@"Flag(a,ap) = %d,%d\n", ShiftAndExtract(eventFlags,4,0x1),ShiftAndExtract(eventFlags,5,0x1)];
    NSString* lengthStr = [NSString stringWithFormat:@"Length     = %u\n", length];
    
    
    NSString* evFlagsStr= [NSString stringWithFormat:@"EventFlags = 0x%x\n", eventFlags ];
    NSString* spareStr= [NSString stringWithFormat:@"spare      = 0x%x\n", spareWord ];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,  
                secStr, subsecStr, timeStr, energyStr, chmapStr, eventIDStr, offsetStr, versionStr, eventFlagsStr, lengthStr,   evFlagsStr, spareStr]; 
}

@end

