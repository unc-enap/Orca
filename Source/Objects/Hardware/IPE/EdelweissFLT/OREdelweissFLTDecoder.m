//
//  OREdelweissFLTDecoder.m
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

#import "OREdelweissFLTDecoder.h"
#import "OREdelweissFLTModel.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "OREdelweissFLTDefs.h"
#import "SLTv4_HW_Definitions.h"

#import "ipe4structure.h"


@implementation OREdelweissFLTDecoderForEnergy

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
           ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (24bit, 1 bit set denoting the channel number)  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
                  ^^-------------------- time precision(2 bit)
                     ^^^^ ^^------------ number of page in hardware buffer (0..63, 6 bit)
                            ^^ ^^^^ ^^^^ eventID (0..511, 10 bit!)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx energy
 </pre>
 *
 */
//-------------------------------------------------------------

#define kPageLength (64*1024)

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

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(ptr[0]);								 
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	

	unsigned long energy = ptr[6];
	
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

	//get the actual object
	if(getRatesFromDecodeStage && !skipRateCounts){
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
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Katrin FLT Energy Record\n\n";    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",ShiftAndExtract(ptr[1],21,0xf)];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",ShiftAndExtract(ptr[1],16,0x1f)];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %lu\n",ShiftAndExtract(ptr[1],8,0xff)];
		
	
	NSDate* theDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ptr[2]];
	NSString* eventDate     = [NSString stringWithFormat:@"Date       = %@\n", [theDate descriptionFromTemplate:@"MM/dd/yy"]];
	NSString* eventTime     = [NSString stringWithFormat:@"Time       = %@\n", [theDate descriptionFromTemplate:@"HH:mm:ss"]];
	
	NSString* seconds		= [NSString stringWithFormat:@"Seconds    = %lu\n",     ptr[2]];
	NSString* subSec        = [NSString stringWithFormat:@"SubSeconds = %lu\n",     ptr[3]];
	NSString* chMap	    	= [NSString stringWithFormat:@"Channelmap = 0x%06lx\n", ptr[4]];
    NSString* nPages		= [NSString stringWithFormat:@"Stored Pg  = %lu\n",     ptr[5]];
	
	NSString* energy        = [NSString stringWithFormat:@"Energy     = %lu\n",     ptr[6]];

	
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
			energy,eventDate,eventTime,seconds,subSec,nPages,chMap];               
    	
}

@end

@implementation OREdelweissFLTDecoderForWaveForm

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
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
 ----------^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (24bit, 1 bit set denoting the channel number)  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventID:
 -----------------^^---------------------precision
 --------------------^^^^ ^^-------------number of page in hardware buffer
 ---------------------------^^ ^^^^ ^^^^-readPtr (0..1024)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx energy
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventFlags
                 ^^^ ^^^^ ^^^^-----------traceStart16 (first trace value in short array, 11 bit, 0..2047)
                                 ^-------append flag is in this record (append to previous record)
                                  ^------append next waveform record
                                    ^^^^-number which defines the content of the record (kind of version number)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx not yet defined ... named eventInfo (started to store there postTriggTime -tb-)
 
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


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(ptr[0]);
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	unsigned char fiber		= ShiftAndExtract(ptr[1],12,0xf);
	unsigned char chan		= ShiftAndExtract(ptr[1],8,0xf);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* fiberKey	    = [NSString stringWithFormat:@"Fiber %2d",fiber];	
	NSString* channelKey	= [self getChannelKey: chan];	
	unsigned long startIndex= ShiftAndExtract(ptr[7],8,0x7ff);

	//channel by channel histograms
	unsigned long energy = ptr[6];
    //uint32_t eventFlags     = ptr[7];
    //uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array

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
	
	
	// Set up the waveform
	NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(long)];
	
	#if 0
	//-----------------------------------------------
	//temp.. to lock the waveform to the highest value
	int n = [waveFormdata length]/sizeof(short) - 20;
	unsigned long maxValue = 0;
	startIndex = 0;
	unsigned long i;
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
//for FLT event readout we would need a startIndex ...

//TODO: what is the best value for the 'mask'? 0xFFFF is appropriate for shorts ... -tb-


	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(long)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0xFFFF							// when displayed all values will be masked with this value
			   specialBits:0x0000	
				  bitNames: [NSArray array]
					sender: self 
				  withKeys: @"FLTv4", @"Waveform",crateKey,stationKey,fiberKey,channelKey,nil];

    #if 0 //this was the KATRIN setting -tb-
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(long)					// Offset in bytes (past header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	startIndex					// first Point Index (past the header offset!!!)
					  mask:	0x0FFF							// when displayed all values will be masked with this value
			   specialBits:0xF000	
				  bitNames: [NSArray arrayWithObjects:@"trig",@"over",@"under", @"extern",nil]
					sender: self 
				  withKeys: @"FLTv4", @"Waveform",crateKey,stationKey,channelKey,nil];
    #endif
	
	
	//get the actual object
	if(getRatesFromDecodeStage && !skipRateCounts){
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
	
										
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

	unsigned long length	= ExtractLength(ptr[0]);
	//unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	//unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	//unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
    uint32_t sec            = ptr[2];
    uint32_t subsec         = ptr[3]; // ShiftAndExtract(ptr[1],0,0xffffffff);
    uint32_t chmap          = ptr[4];
    uint32_t eventID        = ptr[5];
    uint32_t energy         = ptr[6];
    uint32_t eventFlags     = ptr[7];
    uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array
    
    NSString* title= @"EDELWEISS FLT Waveform Record\n\n";

	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate     = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card      = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    NSString* fiber     = [NSString stringWithFormat:@"Fiber      = %lu\n",(*ptr>>12) & 0xf];
    NSString* chan      = [NSString stringWithFormat:@"Channel    = %lu\n",(*ptr>>8) & 0xf];
    NSString* secStr    = [NSString stringWithFormat:@"Sec        = %d\n", sec];
    NSString* subsecStr = [NSString stringWithFormat:@"SubSec     = %d\n", subsec];
    NSString* energyStr = [NSString stringWithFormat:@"Energy     = %d\n", energy];
    NSString* chmapStr  = [NSString stringWithFormat:@"ChannelMap = 0x%x\n", chmap];
    NSString* eventIDStr= [NSString stringWithFormat:@"ReadPtr,Pg#= %d,%d\n", ShiftAndExtract(eventID,0,0x3ff),ShiftAndExtract(eventID,10,0x3f)];
    NSString* offsetStr = [NSString stringWithFormat:@"Offset16   = %d\n", traceStart16];
    NSString* versionStr= [NSString stringWithFormat:@"RecVersion = %d\n", ShiftAndExtract(eventFlags,0,0xf)];
    NSString* eventFlagsStr
                        = [NSString stringWithFormat:@"Flag(a,ap) = %d,%d\n", ShiftAndExtract(eventFlags,4,0x1),ShiftAndExtract(eventFlags,5,0x1)];
    NSString* lengthStr = [NSString stringWithFormat:@"Length     = %lu\n", length];
    
    
    NSString* evFlagsStr= [NSString stringWithFormat:@"EventFlags = 0x%x\n", eventFlags ];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,fiber,chan,  
                secStr, subsecStr, energyStr, chmapStr, eventIDStr, offsetStr, versionStr, eventFlagsStr, lengthStr,   evFlagsStr]; 
}

@end

@implementation OREdelweissFLTDecoderForHitRate

//-------------------------------------------------------------
/** Data format for hit rate mode:
 *
 <pre>
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
                  ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
         ^ ^^^---------------------------crate
              ^ ^^^^---------------------card
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx hitRate length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx total hitRate
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
      ^^^^ ^^^^-------------------------- channel (0..23)
			       ^--------------------- overflow  
				     ^^^^ ^^^^ ^^^^ ^^^^- hitrate
 ...more 
 </pre>
 *
 */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(ptr[0]);
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	unsigned long seconds	= ptr[2];
	unsigned long hitRateTotal = ptr[4];
	int i;
	int n = length - 5;
	for(i=0;i<n;i++){
		int chan = ShiftAndExtract(ptr[5+i],20,0xff);
		NSString* channelKey	= [self getChannelKey:chan];
		unsigned long hitRate = ShiftAndExtract(ptr[5+i],0,0xffff);
		if(hitRate){
			[aDataSet histogram:hitRate
							   numBins:65536 
								sender:self  
							  withKeys: @"FLTv4",@"HitrateHistogram",crateKey,stationKey,channelKey,nil];
			
			[aDataSet loadData2DX:card y:chan z:hitRate size:25  sender:self  withKeys:@"FLTv4",@"HitRate_2D",crateKey, nil];
			[aDataSet sumData2DX:card y:chan z:hitRate size:25  sender:self  withKeys:@"FLTv4",@"HitRateSum_2D",crateKey, nil];
		}
	}
	
	[aDataSet loadTimeSeries: hitRateTotal
                      atTime:seconds
					  sender:self  
					withKeys: @"FLTv4",@"HitrateTimeSeries",crateKey,stationKey,nil];
	
	
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Katrin FLT Hit Rate Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",ShiftAndExtract(ptr[1],21,0xf)];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",ShiftAndExtract(ptr[1],16,0x1f)];
	
	unsigned long length		= ExtractLength(ptr[0]);
    uint32_t ut_time			= ptr[2];
    uint32_t hitRateLengthSec	= ptr[3]; // ShiftAndExtract(ptr[1],0,0xffffffff);
    uint32_t newTotal			= ptr[4];

	NSDate* date = [NSDate dateWithTimeIntervalSince1970:ut_time];
	
	NSMutableString *hrString = [NSMutableString stringWithFormat:@"UTTime     = %d\nHitrateLen = %d\nTotal HR   = %d\n",
						  ut_time,hitRateLengthSec,newTotal];
	int i;
	for(i=0; i<length-5; i++){
		uint32_t chan	= ShiftAndExtract(ptr[5+i],20,0xff);
		uint32_t over	= ShiftAndExtract(ptr[5+i],16,0x1);
		uint32_t hitrate= ShiftAndExtract(ptr[5+i], 0,0xffff);
		if(over)
			[hrString appendString: [NSString stringWithFormat:@"Chan %2d    = OVERFLOW\n", chan] ];
		else
			[hrString appendString: [NSString stringWithFormat:@"Chan %2d    = %d\n", chan,hitrate] ];
	}
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,[date descriptionFromTemplate:@"m/d/y H:M:S z\n"],hrString];
}
@end




@implementation OREdelweissFLTDecoderForHistogram

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
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx histogramID
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx histogramInfo (some flags; some spare for future extensions)
                                      ^-pageAB flag
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
	
	
	katrinV4HistogramDataStruct* ePtr = (katrinV4HistogramDataStruct*) ptr;
    #if 0 //debug output -tb-
	NSLog(@"Keys:%@ %@ %@ %@ %@ \n", @"FLTv4",@"HitrateTimeSerie",crateKey,stationKey,channelKey);
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

    ptr = ptr + (sizeof(katrinV4HistogramDataStruct)/sizeof(long));// points now to the histogram data -tb-
    
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
                            numBins:2048 
                             sender:self  
                           withKeys: @"FLTv4",
                 @"Histogram (all counts)", // use better name -tb-
                 crateKey,stationKey,channelKey,nil];
            }
            #endif
        }
    }
    #endif
    

    #if 1
    // this counts one histogram as one event in data monitor -tb-
    //if(ePtr->histogramLength){
    {// I want to see empty histograms
        int numBins = 2048; //TODO: this has changed for V4 to 2048!!!! -tb-512;
		if(ePtr->maxHistogramLength>numBins) numBins=ePtr->maxHistogramLength;
        unsigned long data[numBins];// v3: histogram length is 512 -tb-
        int i;
        for(i=0; i< numBins;i++) data[i]=0;
        for(i=0; i< ePtr->histogramLength;i++){
            data[i+(ePtr->firstBin)]=*(ptr+i);
            //NSLog(@"Decoder: HistoEntry %i: bin %i val %i\n",i,i+(ePtr->firstBin),data[i+(ePtr->firstBin)]);
        }
        NSMutableArray*  keyArray = [NSMutableArray arrayWithCapacity:5];
        [keyArray insertObject:@"FLTv4" atIndex:0];
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
        [keyArray insertObject:@"FLTv4" atIndex:0];
        [keyArray insertObject:@"Histogram (loadHistogram test)" atIndex:1];
        [keyArray insertObject:crateKey atIndex:2];
        [keyArray insertObject:stationKey atIndex:3];
        [keyArray insertObject:channelKey atIndex:4];
        
        [aDataSet loadHistogram:  ptr 
                        numBins:        ePtr->histogramLength 
                   withKeyArray:   keyArray];
    }
    #endif
    
    
    
    

    
    
    #if 0
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
                         withKeys: @"FLTv4",
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

	katrinV4HistogramDataStruct* ePtr = (katrinV4HistogramDataStruct*)ptr;			//recast to event structure

    #if 0
    //debug output
	NSLog(@" readoutSec = %d \n", ePtr->readoutSec);
	//NSLog(@" recordingTimeSec = %d \n", ePtr->recordingTimeSec);
	NSLog(@" refreshTimeSec = %d \n", ePtr->refreshTimeSec);
	NSLog(@" firstBin = %d \n", ePtr->firstBin);
	NSLog(@" lastBin = %d \n", ePtr->lastBin);
	NSLog(@" histogramLength = %d \n", ePtr->histogramLength);
    #endif
	
	NSString* readoutSec	= [NSString stringWithFormat:@"ReadoutSec = %d\n",ePtr->readoutSec];
	//NSString* recordingTimeSec	= [NSString stringWithFormat:@"recordingTimeSec = %d\n",ePtr->recordingTimeSec];
	NSString* refreshTimeSec	= [NSString stringWithFormat:@"refreshTimeSec = %d\n",ePtr->refreshTimeSec];
	NSString* firstBin	= [NSString stringWithFormat:@"firstBin = %d\n",ePtr->firstBin];
	NSString* lastBin	= [NSString stringWithFormat:@"lastBin  = %d\n",ePtr->lastBin];
	NSString* histogramLength		= [NSString stringWithFormat:@"histogramLength    = %d\n",ePtr->histogramLength];
	NSString* maxHistogramLength	= [NSString stringWithFormat:@"maxHistogramLength = %d\n",ePtr->maxHistogramLength];
	NSString* binSize		= [NSString stringWithFormat:@"binSize    = %d\n",ePtr->binSize];
	NSString* offsetEMin	= [NSString stringWithFormat:@"offsetEMin = %d\n",ePtr->offsetEMin];
	NSString* histIDInfo	= [NSString stringWithFormat:@"ID         = %d.%c\n",ePtr->histogramID,(ePtr->histogramInfo&0x1)?'B':'A'];


    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
	                       readoutSec,refreshTimeSec,firstBin,lastBin,histogramLength,
                           maxHistogramLength,binSize,offsetEMin,histIDInfo]; 
}



@end


