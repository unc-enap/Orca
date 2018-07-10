//
//  ORKatrinFLTDecoder.m
//  Orca
//
//  Created by Mark Howe on 10/18/05.
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


#import "ORKatrinFLTDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORKatrinFLTDefs.h"

@implementation ORKatrinFLTDecoderForEnergy

//-------------------------------------------------------------
/** Data format for energy mode:
  *
<pre>
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
			        ^^^^ ^^^^ ----------channel
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
^^^^ ^^^^------------------------------ channel (0..22)
            ^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (22bit, 1 bit set denoting the channel number)  
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
        ^ ^^^^ ^^^^-------------------- number of page in hardware buffer
		                   ^^ ^^^^ ^^^^ eventID (0..1024)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx energy
</pre>
  *
  */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	katrinEventDataStruct* ePtr;

    unsigned long* ptr = (unsigned long*)someData;
	
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word
	++ptr;										 
	
	//crate and card from second word
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	unsigned char chan		= (*ptr>>8) & 0xff;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	
	++ptr;	
	
	// Get the global data from the first event
    // ptr to event data
	ePtr = (katrinEventDataStruct*) ptr;			//recast to event structure

    //NSLog(@"Channel %08x - %8d %8d\n", ePtr->channelMap, ePtr->sec, ePtr->subSec);
	//channel by channel histograms
	[aDataSet histogram:ePtr->energy 
					  numBins:32768 
					  sender:self  
					  withKeys: @"FLT",@"Energy",crateKey,stationKey,channelKey,nil];
	
	//accumulated card level histograms
	[aDataSet histogram:ePtr->energy 
				numBins:32768 
				 sender:self  
			   withKeys: @"FLT",@"Total Card Energy",crateKey,stationKey,nil];
	
	//accumulated crate level histograms
	[aDataSet histogram:ePtr->energy 
				numBins:32768 
				 sender:self  
			   withKeys: @"FLT",@"Total Crate Energy",crateKey,nil];
	
	

    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Katrin FLT Energy Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %lu\n",(*ptr>>8)  & 0xff];

	++ptr;		//point to event struct
	katrinEventDataStruct* ePtr = (katrinEventDataStruct*)ptr;			//recast to event structure
	
	NSString* energy        = [NSString stringWithFormat:@"Energy     = %lu\n",ePtr->energy];

	NSDate* theDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ePtr->sec];
	NSString* eventDate     = [NSString stringWithFormat:@"Date       = %@\n", [theDate descriptionFromTemplate:@"MM/dd/yy"]];
	NSString* eventTime     = [NSString stringWithFormat:@"Time       = %@\n", [theDate descriptionFromTemplate:@"HH:mm:ss"]];

	NSString* seconds		= [NSString stringWithFormat:@"Seconds    = %lu\n", ePtr->sec];
	NSString* subSec        = [NSString stringWithFormat:@"SubSeconds = %lu\n", ePtr->subSec];
	NSString* eventID		= [NSString stringWithFormat:@"Event ID   = %lu\n", ePtr->eventID & 0xffff];
    NSString* nPages		= [NSString stringWithFormat:@"Stored Pg  = %lu\n", ePtr->eventID >> 16];
	NSString* chMap	    	= [NSString stringWithFormat:@"Channelmap = 0x%06lx\n", ePtr->channelMap & 0x3fffff];	
		

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
	                    energy,eventDate,eventTime,seconds,subSec,eventID,nPages,chMap];               

}
@end


@implementation ORKatrinFLTDecoderForWaveForm

//-------------------------------------------------------------
/** Data format for waveform
  *
<pre>  
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
			        ^^^^ ^^^^-----------channel
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
^^^^ ^^^^------------------------------ channel (0..22)
            ^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (22bit, 1 bit set denoting the channel number)  
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
^ ------------------------------------- flag to indicate that the ADC have been swapped
        ^ ^^^^ ^^^^-------------------- number of page in hardware buffer
		                   ^^ ^^^^ ^^^^ eventID (0..1024)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx energy
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec of restart/reset
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subsec of restart/reset
followed by waveform data (n x 1024 16-bit words)
</pre>
  *
  * All data is stored in the orignal format except for the short data type arrays of the waveform data. 
  * The litle endian machines will store the orignal data that comes from the electronics. 
  * The electronics uses also little endian byte order. The organisation is as follows
<pre>  
1H 1L 2H 2L 3H 3L 4H 4L ...
</pre>
  *
  * The big endian machines will swap the bytes (under the assumption of a long array)
  *
<pre>
2L 2H 2L 1H 4L 4H 3L 3H ...
</pre>
  * This is the byte format stored by the big endian machines.
  * In order to display the waveforms in the correct order a second correction is necessary
  * Before display 1 -2, 3 -4 , .. have to be changed.
  * The little endian machines will apply the normal endian swap to the stored data 
  * and can display the data correctly without any further operation.
  *
  */ 
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word

	++ptr;											//crate, card,channel from second word
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	unsigned char chan		= (*ptr>>8) & 0xff;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];
		
	++ptr;		//point to event struct
	
	
	katrinEventDataStruct* ePtr = (katrinEventDataStruct*) ptr;
	bool isSwapped          = ePtr->eventID >> 31; 
	
	[aDataSet histogram:ePtr->energy 
			  numBins:65536 //-tb- 32768 
			  sender:self  
			  withKeys: @"FLT",@"Energy",crateKey,stationKey,channelKey,nil];

	
	// Change order of shorts in the ADC trace for PowerPC CPUs	
	// Note: This the endian swap itself is handled by the firewire drivers.
	//       The swap of the shorts has been moved from the model code
	//       Every data set should be only swapped once (!)
	// ak, 29.2.08
    #ifdef __ORCA_DEVELOPMENT__CONFIGURATION__
    //NSLog(@"ORKatrinFLTDecoder::decodeData: flag isSwapped is  %d (0x%x), (ntohl(1) == 1) is  (%d) \n", isSwapped,ePtr->eventID, (ntohl(1) == 1));
    //if( (ntohl(1) == 1) ) NSLog(@"    ORKatrinFLTDecoder::decodeData:   is big endian host!\n" );
    #endif
	if ((ntohl(1) == 1) && (!isSwapped) ){ // big endian host
        #ifdef __ORCA_DEVELOPMENT__CONFIGURATION__
        //NSLog(@"    ORKatrinFLTDecoder::decodeData:   will swap unsigned long  NOW!\n" );
        #endif
		// Point to ADC data
		ptr += (sizeof(katrinEventDataStruct)+sizeof(katrinDebugDataStruct))/sizeof(unsigned long);
		
		// The order of the shorts has to be switched (endianess)
		int i;
		int traceLen = (length / 512) * 512;
		
		for (i=0;i< traceLen;i++)
		    ptr[i] = (ptr[i] >> 16)  |  (ptr[i] << 16);
			
		ePtr->eventID = ePtr->eventID | (0x1 << 31); // set isSpapped flag	
	    isSwapped          = ePtr->eventID >> 31; 
    }
	
	// Set up the waveform
	NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(long)];


	[aDataSet loadWaveform: waveFormdata							//pass in the whole data set
					offset: (2*sizeof(long)+sizeof(katrinEventDataStruct)+sizeof(katrinDebugDataStruct))/2	// Offset in bytes (2 header words + katrinEventDataStruct)
				    unitSize: sizeof(short)							// unit size in bytes
					sender: self 
					withKeys: @"FLT", @"Waveform",crateKey,stationKey,channelKey,nil];

    //'swap back' = undo the swap made above -tb-
    //this is due to the bug reported by Michelle in July 2008 -tb-
    //(the problem was: if in a fan out on slot 1 there was the DataMonitor and on a higher slot the
    //  DataFile, the flag was set to 1 by DataMonitor and saved by DataFile -tb-)
    //  1. recalculate the ptr position: 
    ptr = (unsigned long*)someData;
    ++ptr;
    ++ptr;
    //  2. swap back:
	if ((ntohl(1) == 1) && (isSwapped) ){ // big endian host
        #ifdef __ORCA_DEVELOPMENT__CONFIGURATION__
		//this was swamping the statuslog comment out mah 04/20/09
        //NSLog(@"    ORKatrinFLTDecoder::decodeData:   will swap back unsigned long  NOW!\n" );
        #endif
		// Point to ADC data
		ptr += (sizeof(katrinEventDataStruct)+sizeof(katrinDebugDataStruct))/sizeof(unsigned long);
		
		// The order of the shorts has to be switched (endianess)
		int i;
		int traceLen = (length / 512) * 512;
		
		for (i=0;i< traceLen;i++)
		    ptr[i] = (ptr[i] >> 16)  |  (ptr[i] << 16);
			
		ePtr->eventID = ePtr->eventID & ~(0x1 << 31); // unset isSpapped flag	
	    isSwapped          = ePtr->eventID >> 31; 
        if(isSwapped) NSLog(@"ERROR: swap-flag wrong in ORKatrinFLTDecoder!\n");
    }
					

    #if 0
    ptr = (unsigned long*)someData; ++ptr; ++ptr:
    ptr = ptr + (sizeof(katrinEventDataStruct) + sizeof(katrinDebugDataStruct)) / sizeof(long);
	NSLog(@" len = %d (%d), %x %x %x\n", length, ptr - (unsigned long *) someData , ptr[0], ptr[1], ptr[2]);
    #endif
					
    return length; //must return number of longs processed.
}


- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title= @"Katrin FLT Waveform Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %lu\n",(*ptr>>8) & 0xff];
	++ptr;		//point to next structure
	
	katrinEventDataStruct* ePtr = (katrinEventDataStruct*)ptr;			//recast to event structure
	
	NSString* energy		= [NSString stringWithFormat:@"Energy     = %lu\n",ePtr->energy];

	NSDate* theDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ePtr->sec];
	NSString* eventDate     = [NSString stringWithFormat:@"Date       = %@\n", [theDate descriptionFromTemplate:@"MM/dd/yy"]];
	NSString* eventTime     = [NSString stringWithFormat:@"Time       = %@\n", [theDate descriptionFromTemplate:@"HH:mm:ss"]];

	NSString* seconds		= [NSString stringWithFormat:@"Seconds    = %lu\n", ePtr->sec];
	NSString* subSec    	= [NSString stringWithFormat:@"Subseconds = %lu\n", ePtr->subSec];
	NSString* eventID		= [NSString stringWithFormat:@"Event ID   = %lu\n", ePtr->eventID & 0xffff];
	NSString* chMap   		= [NSString stringWithFormat:@"Channelmap = 0x%06lx\n", ePtr->channelMap & 0x3fffff];	


    // Decode extra debug information
	ptr = ptr + sizeof(katrinEventDataStruct) / sizeof(unsigned long);
	katrinDebugDataStruct* dPtr = (katrinDebugDataStruct*) ptr;

	NSString* resetSec		= [NSString stringWithFormat:@"ResetSec   = %lu\n", dPtr->resetSec];
	NSString* resetSubSec  	= [NSString stringWithFormat:@"ResetSubSec= %lu\n", dPtr->resetSubSec];


    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
	                       energy,eventDate,eventTime,seconds,subSec,eventID,chMap,
	                       resetSec,resetSubSec]; 
}



@end






@implementation ORKatrinFLTDecoderForHitRate   //TODO: work in progress ... -tb-

//-------------------------------------------------------------
/** Data format for hitrate mode:
  *
<pre>
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
			        ^^^^ ^^^^ ----------channel
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx hitrate
</pre>
    Orca identifies the type of binary data record by the header bytes.
    By this it finds this class (its selector is connected with its ID in
     - (NSDictionary*) dataRecordDescription
  */ //-tb- 2008-02-6
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	katrinHitRateDataStruct* ePtr;

    unsigned long* ptr = (unsigned long*)someData;
	
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word
	++ptr;										 
	
	//crate and card from second word
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	unsigned char chan		= (*ptr>>8) & 0xff;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	
	++ptr;	
	
	// Get the global data from the first event
    // ptr to event data
	ePtr = (katrinHitRateDataStruct*) ptr;			//recast to event structure

    //NSLog(@"Channel %08x - %8d %8d\n", ePtr->channelMap, ePtr->sec, ePtr->subSec);
    float fHitrate = ePtr->hitrate;
   NSLog(@"Receiving hitrate data for chan %d: (%d, %d, %f)\n",chan, ePtr->sec, ePtr->hitrate, fHitrate);

 
    #if 1
	[aDataSet histogram:ePtr->hitrate 
					  numBins:65536 //-tb- 32768 
					  sender:self  
					  withKeys: @"FLT",@"HitrateHistogram",crateKey,stationKey,channelKey,nil];
    #endif

    #if 1
    // data formats are in ORDataSet.h/.m (histogram:,loadTimeSeries:,loadWaveform: etc) -tb- 2008-02-04
	[aDataSet loadTimeSeries: ePtr->hitrate
                      atTime:ePtr->sec
					  sender:self  
					  withKeys: @"FLT",@"HitrateTimeSerie",crateKey,stationKey,channelKey,nil];
    #endif

    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Katrin FLT Hitrate Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %lu\n",(*ptr>>8)  & 0xff];

	++ptr;		//point to event struct
	katrinHitRateDataStruct* ePtr = (katrinHitRateDataStruct*)ptr;			//recast to event structure
	
	NSString* hitrate        = [NSString stringWithFormat:@"Hitrate     = %lu\n",ePtr->hitrate];

	NSDate* theDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ePtr->sec];
	NSString* sampleDate     = [NSString stringWithFormat:@"Date       = %@\n", [theDate descriptionFromTemplate:@"MM/dd/yy"]];
	NSString* sampleTime     = [NSString stringWithFormat:@"Time       = %@\n", [theDate descriptionFromTemplate:@"HH:mm:ss"]];

	NSString* seconds		= [NSString stringWithFormat:@"Seconds    = %lu\n", ePtr->sec];
		

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",title,crate,card,chan,
	                    hitrate,sampleDate,sampleTime,seconds];               

}
@end











@implementation ORKatrinFLTDecoderForThresholdScan   //renamed from ORKatrinFLTDecoderForHitRate to ORKatrinFLTDecoderForThresholdScan -tb- 2008-02

//-------------------------------------------------------------
/** Data format for frequency plot
  *
  * - Threshold 16bit 0..65000
  * - Frequency 23bit + 1 bit overflow  
  *
  *
<pre>  
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
			        ^^^^ ^^^^ ----------channel
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
^^^^ ^^^^------------------------------ channel (0..22)
            ^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (22bit, 1 bit set denoting the channel number) 
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx Threshold
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx Hitrate
</pre>
  *
  */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    int i;
	//int j;
	//int mult;
	//int width;
	int energy;

    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word
	++ptr;										 //crate and card from second word
	
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	unsigned char chan		= (*ptr>>8) & 0xff;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];
	++ptr;		//point to event struct
	
	
	katrinThresholdScanDataStruct* ePtr = (katrinThresholdScanDataStruct*) ptr;
	
/*
    // Calculate the multiplicity of the bin 
	// TODO: Check the relation between threshold and energy
	energy = ePtr->threshold << 1; 
	width = energy - lastEnergy[chan];
	mult =  lastHitrate[chan] - ePtr->hitrate;  // / width ?!
    mult =  ((float) mult) / width;


	//NSLog(@"Data arrived in ch %d: width = %d, mult = %d rate = %d / %d, energy=%d %d\n", 
	//        chan, width, mult, ePtr->hitrate, lastHitrate[chan], 
	//		energy, lastEnergy[chan]);

    // Fill in the number 
	if (lastEnergy[chan] > 0){
	  for (i=lastEnergy[chan]; i< energy;i++){
	    for (j=0;j<mult;j++){
		  [aDataSet histogram:i
					  numBins:32768 
					  sender:self  
					  withKeys: @"FLT",@"Hitrate",crateKey,stationKey,channelKey,nil];
		}			  
	  }
	}  
*/	


    // Display the hitrates
	// TODO: Howto plot a list of points?!
	// Plot: (ePtr->threshold, ePtr->hitrate)
	//
	energy = ePtr->threshold; 
	//width = energy - lastEnergy[chan];
	
	//NSLog(@"Hitrate: (%d .. %d) - %d\n", lastEnergy[chan], energy, width);
	 
	if (lastEnergy[chan] > 0){
	  for (i=lastEnergy[chan]+1;i<=energy;i++){
	    [aDataSet histogramWW:i
		              weight:ePtr->hitrate
					  numBins:65536 //-tb- 32768 
					  sender:self  
					  withKeys: @"FLT",@"Hitrate",crateKey,stationKey,channelKey,nil];
	  }
	}  	
	
	lastEnergy[chan] = energy;
	lastHitrate[chan] = ePtr->hitrate;

    return length; //must return number of longs processed.

}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title= @"Katrin FLT ThresholdScan Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate     = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card      = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    NSString* chan      = [NSString stringWithFormat:@"Channel    = %lu\n",(*ptr>>8) & 0xff];
	++ptr;		//point to next structure
	
	katrinThresholdScanDataStruct* ePtr = (katrinThresholdScanDataStruct*)ptr;			//recast to event structure
	
	NSString* threshold	= [NSString stringWithFormat:@"Threshold  = %lu\n",ePtr->threshold];
	NSString* hitrate	= [NSString stringWithFormat:@"Hitrate    = %lu\n",ePtr->hitrate];
	NSString* chMap   	= [NSString stringWithFormat:@"Channelmap = 0x%06lx\n", ePtr->channelMap & 0x3fffff];	

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,chan,
	                       threshold,hitrate,chMap];
}

@end




@implementation ORKatrinFLTDecoderForHistogram

//-------------------------------------------------------------
/** Data format for hardware histogram
  *
<pre>  
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
			        ^^^^ ^^^^-----------channel
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx readoutSec
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx refreshTime  (was recordingTimeSec)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx firstBin
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx lastBin
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx histogramLength
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx maxHistogramLength
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx binSize
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx offsetEMin
</pre>

  * For more infos: see
  * readOutHistogramDataV3:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo (in model)
  *
  */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    //debug output -tb-
    //NSLog(@"  ORKatrinFLTDecoderForHistogram::decodeData:\n");
    
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word

	++ptr;											//crate, card,channel from second word
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	unsigned char chan		= (*ptr>>8) & 0xff;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];
		
	++ptr;		//point to event struct
	
	
	katrinHistogramDataStruct* ePtr = (katrinHistogramDataStruct*) ptr;
    #if 0 //debug output -tb-
	NSLog(@"Keys:%@ %@ %@ %@ %@ \n", @"FLT",@"HitrateTimeSerie",crateKey,stationKey,channelKey);
	NSLog(@"  readoutSec = %d \n", ePtr->readoutSec);
	//NSLog(@"  recordingTimeSec = %d \n", ePtr->recordingTimeSec);
	NSLog(@"  refreshTimeSec = %d \n", ePtr->recordingTimeSec);
	NSLog(@"  firstBin = %d \n", ePtr->firstBin);
	NSLog(@"  lastBin = %d \n", ePtr->lastBin);
	NSLog(@"  histogramLength = %d \n", ePtr->histogramLength);
	NSLog(@"  maxHistogramLength = %d \n", ePtr->maxHistogramLength);
	NSLog(@"  binSize = %d \n", ePtr->binSize);
	NSLog(@"  offsetEMin = %d \n", ePtr->offsetEMin);
    #endif

    ptr = ptr + (sizeof(katrinHistogramDataStruct)/sizeof(long));// points now to the histogram data -tb-
    
    #if 0
    {
        // this is really brute force, but probably we want the second version (see below) ... -tb-
        // this counts every single event in the histogram as one event in data monitor -tb-
        int i;
        unsigned long aValue;
        unsigned long aBin;
        for(i=0; i< ePtr->histogramLength;i++){
            aValue=*(ptr+i);
            aBin = i+ (ePtr->firstBin);
            //if(aValue) NSLog(@"  Bin %i = %d \n", aBin,aValue);
            #if 1
            int j;
            for(j=0;j<aValue;j++){
                //NSLog(@"  Fill Bin %i = %d times \n", aBin,aValue);
                [aDataSet histogram:aBin 
                            numBins:1024 
                             sender:self  
                           withKeys: @"FLT",
                 @"Histogram (all counts)", // use better name -tb-
                 crateKey,stationKey,channelKey,nil];
            }
            #endif
        }
    }
    #endif
    

    #if 1
    // this counts one histogram as one event in data monitor -tb-
    if(ePtr->histogramLength){
        int numBins = 512;
        unsigned long data[numBins];// v3: histogram length is 512 -tb-
        int i;
        for(i=0; i< numBins;i++) data[i]=0;
        for(i=0; i< ePtr->histogramLength;i++){
            data[i+(ePtr->firstBin)]=*(ptr+i);
            //NSLog(@"Decoder: HistoEntry %i: bin %i val %i\n",i,i+(ePtr->firstBin),data[i+(ePtr->firstBin)]);
        }
        NSMutableArray*  keyArray = [NSMutableArray arrayWithCapacity:5];
        [keyArray insertObject:@"FLT" atIndex:0];
        [keyArray insertObject:@"Energy Histogram (HW)" atIndex:1]; //TODO: 1. use better name 2. keep memory clean -tb-
        [keyArray insertObject:crateKey atIndex:2];
        [keyArray insertObject:stationKey atIndex:3];
        [keyArray insertObject:channelKey atIndex:4];
        
        [aDataSet mergeHistogram:  data  
                         numBins:  numBins  // is fixed in the current FPGA version -tb- 2008-03-13 
                    withKeyArray:  keyArray];
    }
    #endif
    
    
    
    #if 0
    // test - ok  -tb-
    {        
        NSMutableArray*  keyArray = [NSMutableArray arrayWithCapacity:5];
        [keyArray insertObject:@"FLT" atIndex:0];
        [keyArray insertObject:@"Histogram (loadHistogram test)" atIndex:1];
        [keyArray insertObject:crateKey atIndex:2];
        [keyArray insertObject:stationKey atIndex:3];
        [keyArray insertObject:channelKey atIndex:4];
        
        [aDataSet loadHistogram:  ptr 
                        numBins:        ePtr->histogramLength 
                   withKeyArray:   keyArray];
    }
    #endif
    
    
    
    
    //this slows down the system at very high rates - an improved version is below -tb-
    #if 0
    {
        // this is very similar to the first version ('brute force'),
        // but probably it is usefull as it is in 'energy mode' units ... -tb-
        int i;
        unsigned long aValue;
        unsigned long aBin;
        unsigned long energy;
        for(i=0; i< ePtr->histogramLength;i++){
            aValue=*(ptr+i);
            aBin = i+ (ePtr->firstBin);
            energy= ( ((aBin) << (ePtr->binSize))/2 )   + ePtr->offsetEMin;
            //TODO: fill all bins from this one to the next energy -tb- 2008-05-30
            //if(aValue) NSLog(@"  Bin %i = %d \n", aBin,aValue);
            #if 1
            int j;
            for(j=0;j<aValue;j++){
                //NSLog(@"  Fill Bin %i = %d times \n", aBin,aValue);
                [aDataSet histogram:energy 
                            numBins:65536 //-tb- 32768  
                             sender:self  
                           withKeys: @"FLT",
                 @"Histogram - TEST+DEBUG - (energy mode units)", // use better name -tb-
                 crateKey,stationKey,channelKey,nil];
            }
            #endif
        }
    }
    #endif
    
    
    #if 1
    {
        // this is very similar to the first version (with speed up improvement 2008-08-05),
        // but probably it is usefull as it is in 'energy mode' units ... -tb-
        int i;
        //first compute the sum of events:
        unsigned int sumEvents=0;
        for(i=0; i< ePtr->histogramLength;i++){
            sumEvents += *(ptr+i);
        }
        unsigned long energy;
        //energy= ( ((ePtr->firstBin) << (ePtr->binSize))/2 )   + ePtr->offsetEMin;
        //energy= ( ((ePtr->firstBin) << (ePtr->binSize))/4 )   + ePtr->offsetEMin;// since 2009 May: /4 instead of /2, see getHistoEnergyOfBin of ORKatrinFLTDecoder.m
        energy= ( ((ePtr->firstBin) << (ePtr->binSize-2)) )   + ePtr->offsetEMin;// since 2009 May: /4 instead of /2, see getHistoEnergyOfBin of ORKatrinFLTDecoder.m
                       // maybe I should use getHistoEnergyOfBin here (then need to include header) ... -tb-
        int stepSize;
        stepSize = 1 << (ePtr->binSize -2);// again: see  getHistoEnergyOfBin of ORKatrinFLTDecoder.m

        [aDataSet mergeEnergyHistogram: ptr
                          numBins: ePtr->histogramLength  
                          maxBins: 65536  //32768
                         firstBin: energy   
                         stepSize: stepSize
                           counts: sumEvents
                         withKeys: @"FLT",
                                   @"Energy Histogram (HW, energy mode units)", // use better name -tb-
                                   crateKey,stationKey,channelKey,nil];
        
    }
    #endif
    

    return length; //must return number of longs processed.
}



- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title= @"Katrin FLT Histogram Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %lu\n",(*ptr>>8) & 0xff];
	++ptr;		//point to next structure

	katrinHistogramDataStruct* ePtr = (katrinHistogramDataStruct*)ptr;			//recast to event structure

	NSLog(@" readoutSec = %d \n", ePtr->readoutSec);
	//NSLog(@" recordingTimeSec = %d \n", ePtr->recordingTimeSec);
	NSLog(@" refreshTimeSec = %d \n", ePtr->recordingTimeSec);
	NSLog(@" firstBin = %d \n", ePtr->firstBin);
	NSLog(@" lastBin = %d \n", ePtr->lastBin);
	NSLog(@" histogramLength = %d \n", ePtr->histogramLength);
	
	NSString* readoutSec	= [NSString stringWithFormat:@"ReadoutSec = %ld\n",ePtr->readoutSec];
	//NSString* recordingTimeSec	= [NSString stringWithFormat:@"recordingTimeSec = %d\n",ePtr->recordingTimeSec];
	NSString* refreshTimeSec	= [NSString stringWithFormat:@"refreshTimeSec = %ld\n",ePtr->recordingTimeSec];
	NSString* firstBin	= [NSString stringWithFormat:@"firstBin = %ld\n",ePtr->firstBin];
	NSString* lastBin	= [NSString stringWithFormat:@"lastBin = %ld\n",ePtr->lastBin];
	NSString* histogramLength	= [NSString stringWithFormat:@"histogramLength = %ld\n",ePtr->histogramLength];
	NSString* maxHistogramLength	= [NSString stringWithFormat:@"maxHistogramLength = %ld\n",ePtr->maxHistogramLength];
	NSString* binSize	= [NSString stringWithFormat:@"binSize = %ld\n",ePtr->binSize];
	NSString* offsetEMin	= [NSString stringWithFormat:@"offsetEMin = %ld\n",ePtr->offsetEMin];


    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
	                       readoutSec,refreshTimeSec,firstBin,lastBin,histogramLength,
                           maxHistogramLength,binSize,offsetEMin]; 
}



@end





