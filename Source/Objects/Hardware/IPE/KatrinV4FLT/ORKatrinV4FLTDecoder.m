//
//  ORKatrinV4FLTDecoder.m
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


#import "ORKatrinV4FLTDecoder.h"
#import "ORKatrinV4FLTModel.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORKatrinV4FLTDefs.h"
#import "SLTv4_HW_Definitions.h"

@implementation ORKatrinV4FLTDecoderForEnergy

//-------------------------------------------------------------
/** Data format for energy mode:
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
                  ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
		 ^ ^^^---------------------------crate
			  ^ ^^^^---------------------card
                     ^^^^ ^^^^ ----------channel
                                 ^^------boxcarLen  
                                    ^^^^-filterShapingLength  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
           ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (24bit, 1 bit set denoting the channel number)  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 -----^^^^-------------------------------flt run mode
 ----------^^^^--------------------------FIFO Flags: FF, AF, AE, EF
 -----------------^^---------------------time precision(2 bit)
 --------------------^^^^ ^^-------------number of page in hardware buffer (0..63, 6 bit)
 ---------------------------^^ ^^^^ ^^^^-readPtr/eventID (0..511, 10 bit!)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^--------------------------fifoEventID
                ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-energy
 */
//-------------------------------------------------------------

- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    getFifoFlagsFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualFlts release];
    [super dealloc];
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length	= ExtractLength(ptr[0]);								 
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0x0f);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	unsigned char chan		= ShiftAndExtract(ptr[1], 8,0xff);
	int boxcarLen           = ShiftAndExtract(ptr[1], 4,0x03);
	int filterShapingLength = ShiftAndExtract(ptr[1], 0,0x0f);
	uint32_t histoLen  = 4*4096;
	uint32_t filterDiv = (uint32_t)(1L << filterShapingLength);
	if(filterShapingLength==0){
		filterDiv = boxcarLen + 1;
	}
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	

	//note the ptr[6] shares the eventID and the energy
	//the eventID must be masked off
    uint32_t energy = (ptr[6] & 0xfffff)/filterDiv; //keep this
    //uint32_t energy = (ptr[6] & 0xfffff)>>8; //scale to 4096
		
	//channel by channel histograms
	[aDataSet histogram:energy
				numBins:histoLen sender:self  
			   withKeys:@"FLT", @"Energy", crateKey,stationKey,channelKey,nil];
	
	//get the actual object
	if(getRatesFromDecodeStage || getFifoFlagsFromDecodeStage){
		NSString* fltKey          = [crateKey stringByAppendingString:stationKey];
		if(!actualFlts)actualFlts = [[NSMutableDictionary alloc] init];
		ORKatrinV4FLTModel*   obj = [actualFlts objectForKey:fltKey];
		if(!obj){
			NSArray* listOfFlts = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORKatrinV4FLTModel")];
			for(ORKatrinV4FLTModel* aFlt in listOfFlts){
				if(/*[aFlt crateNumber] == crate &&*/ [aFlt stationNumber] == card){
					[actualFlts setObject:aFlt forKey:fltKey];
					obj = aFlt;
					break;
				}
			}
		}
		if(getRatesFromDecodeStage)    getRatesFromDecodeStage     = [obj bumpRateFromDecodeStage:chan];
    }
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"Katrin V4 FLT Energy Record\n\n";    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %u\n",ShiftAndExtract(ptr[1],21,0xf)];
    NSString* card  = [NSString stringWithFormat:@"Station    = %u\n",ShiftAndExtract(ptr[1],16,0x1f)];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %u\n",ShiftAndExtract(ptr[1],8,0xff)];
		
	
	NSDate* theDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ptr[2]];
	NSString* eventDate     = [NSString stringWithFormat:@"Date       = %@\n", [theDate descriptionFromTemplate:@"MM/dd/yy"]];
	NSString* eventTime     = [NSString stringWithFormat:@"Time       = %@\n", [theDate descriptionFromTemplate:@"HH:mm:ss"]];
	
	NSString* seconds		= [NSString stringWithFormat:@"Seconds    = %u\n",     ptr[2]];
	NSString* subSec        = [NSString stringWithFormat:@"SubSeconds = %u\n",     ptr[3]];
	NSString* chMap	    	= [NSString stringWithFormat:@"Channelmap = 0x%06x\n", ptr[4]];
    NSString* nPages		= [NSString stringWithFormat:@"EventFlags = 0x%x\n",     ptr[5]];
	
	NSString* fifoEventId   = [NSString stringWithFormat:@"FifoEventId = %u\n",     ShiftAndExtract(ptr[6],20,0xfff) ];
	NSString* energy        = [NSString stringWithFormat:@"Energy      = %u\n",     ShiftAndExtract(ptr[6],0,0xffff)];

	
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
			fifoEventId,energy,eventDate,eventTime,seconds,subSec,nPages,chMap];               
    	
}

@end

@implementation ORKatrinV4FLTDecoderForWaveForm

//-------------------------------------------------------------
/** Data format for waveform
 *
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
 ------- ^ ^^^---------------------------crate
 -------------^ ^^^^---------------------card
 --------------------^^^^ ^^^^-----------channel
                                 ^^------boxcarLen  
                                    ^^^^-filterShapingLength  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
 ----------^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-channel Map (24bit, 1 bit set denoting the channel number)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 -----^^^^-------------------------------flt run mode
 ----------^^^^--------------------------FIFO Flags: FF, AF, AE, EF
 -----------------^^---------------------time precision(2 bit)
 --------------------^^^^ ^^-------------number of page in hardware buffer (0..63, 6 bit)
 ---------------------------^^ ^^^^ ^^^^-readPtr/eventID (0..511, 10 bit!)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^--------------------------fifoEventID
                ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-energy
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
                 ^^^ ^^^^ ^^^^-----------traceStart16 (first trace value in short array, 11 bit, 0..2047)
                                 ^-------append flag is in this record (append to previous record)
                                  ^------append next waveform record
                                    ^^^^-number which defines the content of the record (kind of version number)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx spare
 
 followed by waveform data (2048 16-bit words)
 */
//-------------------------------------------------------------

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t* ptr      = (uint32_t*)someData;
	uint32_t length	= ExtractLength(ptr[0]);
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	
	int boxcarLen           = ShiftAndExtract(ptr[1],4,0x3);
	int filterShapingLength = ShiftAndExtract(ptr[1],0,0xf);
	uint32_t  histoLen = 4096;//=max. ADC value for 12 bit ADC
	unsigned short filterDiv= 1L << filterShapingLength;
	if(filterShapingLength==0){
		filterDiv = boxcarLen + 1;
	}
	
	uint32_t energy  = (ptr[6] & 0xfffff)/filterDiv;
	
	[aDataSet histogram:energy
				numBins:histoLen sender:self  
			   withKeys:@"FLT", @"Energy", crateKey,stationKey,channelKey,nil];
    
    unsigned short* dataPtr     = (unsigned short*)&ptr[9];
    NSData* waveformData = [NSData dataWithBytes:dataPtr length:4096];
    
	[aDataSet loadWaveform: waveformData
					offset: 0
				  unitSize: sizeof(short)
				startIndex:	0
					  mask:	0x0FFF
			   specialBits: 0xE000
				  bitNames: [NSArray arrayWithObjects:@"appPg",@"inhibit", @"trigger",nil]
					sender: self 
				  withKeys: @"FLT", @"Waveform",crateKey,stationKey,channelKey,nil];

	if(getRatesFromDecodeStage){
		NSString* fltKey = [crateKey stringByAppendingString:stationKey];
		if(!actualFlts)actualFlts = [[NSMutableDictionary alloc] init];
		ORKatrinV4FLTModel* obj = [actualFlts objectForKey:fltKey];
		if(!obj){
			NSArray* listOfFlts = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORKatrinV4FLTModel")];
			for(ORKatrinV4FLTModel* aFlt in listOfFlts){
				if(/*[aFlt crateNumber] == crate &&*/ [aFlt stationNumber] == card){
					[actualFlts setObject:aFlt forKey:fltKey];
					obj = aFlt;
					break;
				}
			}
		}
		if(getRatesFromDecodeStage) getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:chan];
	}
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{

	uint32_t length       = ExtractLength(ptr[0]);
	uint32_t crate        = ShiftAndExtract(ptr[1],21,0x0f);
	uint32_t card         = ShiftAndExtract(ptr[1],16,0x1f);
	uint32_t chan         = ShiftAndExtract(ptr[1], 8,0xff);
    uint32_t sec          = ptr[2];
    uint32_t subsec       = ptr[3];
    uint32_t chmap        = ptr[4];
    uint32_t eventID      = ptr[5];
    uint32_t fifoEventID  = ShiftAndExtract(ptr[6],20,0xfff);
    uint32_t energy       = ShiftAndExtract(ptr[6],0,0xfffff);
    uint32_t eventFlags   = ptr[7];
    uint32_t traceStart16 = ShiftAndExtract(eventFlags,8,0x7ff);//start of trace in short array
    
    NSString* title= @"Katrin V4 FLT Waveform Record\n\n";
    
    NSString* crateStr       = [NSString stringWithFormat:@"Crate       = %u\n",crate];
    NSString* cardStr		 = [NSString stringWithFormat:@"Station     = %u\n",card];
    NSString* chanStr		 = [NSString stringWithFormat:@"Channel     = %u\n",chan];
    NSString* secStr		 = [NSString stringWithFormat:@"Sec         = %u\n", sec];
    NSString* subsecStr		 = [NSString stringWithFormat:@"SubSec      = %u\n", subsec];
    NSString* fifoEventIdStr = [NSString stringWithFormat:@"FifoEventId = %u\n", fifoEventID];
    NSString* energyStr		 = [NSString stringWithFormat:@"Energy      = %u\n", energy];
    NSString* chmapStr		 = [NSString stringWithFormat:@"ChannelMap  = 0x%x\n", chmap];
    NSString* eventIDStr	 = [NSString stringWithFormat:@"ReadPtr,Pg# = %u,%u\n", ShiftAndExtract(eventID,0,0x3ff),ShiftAndExtract(eventID,10,0x3f)];
    NSString* offsetStr		 = [NSString stringWithFormat:@"Offset16    = %u\n", traceStart16];
    NSString* versionStr	 = [NSString stringWithFormat:@"RecVersion  = %u\n", ShiftAndExtract(eventFlags,0,0xf)];
    NSString* eventFlagsStr
							 = [NSString stringWithFormat:@"Flag(a,ap)  = %u,%u\n", ShiftAndExtract(eventFlags,4,0x1),ShiftAndExtract(eventFlags,5,0x1)];
    NSString* lengthStr		 = [NSString stringWithFormat:@"Length      = %u\n", length];
    
    
    NSString* evFlagsStr     = [NSString stringWithFormat:@"EventFlags = 0x%x\n", eventFlags ];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crateStr,cardStr,chanStr,
                secStr, subsecStr, fifoEventIdStr, energyStr, chmapStr, eventIDStr, offsetStr, versionStr, eventFlagsStr, lengthStr,   evFlagsStr]; 
}

@end

@implementation ORKatrinV4FLTDecoderForHitRate

//-------------------------------------------------------------
//2013-04-24 -tb- extended data format to support 32 bit hitrate register (added additional set of words at end of old record format)
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
			         ---^ ^^^^-----------number of channels NOC (=num of contained HR values)                        //2013-04-24 added -tb-
                                       ^-record version (0x0 old (wrong) version; 0x1: appending 32-bit HR registers //2013-04-24 added -tb-
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec (readout second!)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx hitRate length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx total hitRate
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx                             
      ^^^^ ^^^^-------------------------- channel (0..23)
			       ^--------------------- overflow  
				     ^^^^ ^^^^ ^^^^ ^^^^- hitrate ('hitrate')
 ...  (NOC) x times
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  'hitrate32': 32 bit hitrate register (channel number: stored in according 'hitrate' words) //2013-04-24 added -tb-                            
 ...  (NOC) x times
 </pre>
 *
 */
//-------------------------------------------------------------


- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length	= ExtractLength(ptr[0]);
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	uint32_t seconds	= ptr[2];
	uint32_t hitRateTotal = ptr[4];
	int i;
	int n = (int)((length - 5)/2); //so far, only using the 16 bit counters.. the 32 bit counter follow
	for(i=0;i<n;i++){
		int chan = ShiftAndExtract(ptr[5+i],20,0xff);
		NSString* channelKey    = [self getChannelKey:chan];
		uint32_t hitRate   = ptr[5+i] & 0xffff;
		if(hitRate){
			[aDataSet histogram:hitRate
							   numBins:65536 
								sender:self  
							  withKeys: @"FLT",@"HitrateHistogram",crateKey,stationKey,channelKey,nil];
			
			[aDataSet loadData2DX:card y:chan z:hitRate size:25  sender:self  withKeys:@"FLT",@"HitRate_2D",crateKey, nil];
			[aDataSet sumData2DX:card y:chan z:hitRate size:25  sender:self  withKeys:@"FLT",@"HitRateSum_2D",crateKey, nil];
		}
	}
	
	[aDataSet loadTimeSeries: hitRateTotal
                      atTime:seconds
					  sender:self  
					withKeys: @"FLT",@"HitrateTimeSeries",crateKey,stationKey,nil];
	
	
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"Katrin FLT Hit Rate Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate      = %u\n",ShiftAndExtract(ptr[1],21,0xf)];
    NSString* card  = [NSString stringWithFormat:@"Station    = %u\n",ShiftAndExtract(ptr[1],16,0x1f)];
	
	uint32_t length                = ExtractLength(ptr[0]);
    uint32_t ut_time               = ptr[2];
    uint32_t hitRateLengthSec      = ptr[3]; // ShiftAndExtract(ptr[1],0,0xffffffff);
    uint32_t newTotal              = ptr[4];
    uint32_t version               = ShiftAndExtract(ptr[1],0,0x1);    //bit 1 = version
    uint32_t countHREnabledChans   = ShiftAndExtract(ptr[1],8,0x1f);   //NOC in record
    if(version==1) title= @"Katrin FLT Hit Rate Record v1\n\n";
    
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:ut_time];

	int i;
    NSMutableString* hrString;
    if(version==0x1){
	    hrString = [NSMutableString stringWithFormat:@"\nSLTsecond  = %u\nHitrateLen = %u\nTotal HR   = %u\n",
						  ut_time,hitRateLengthSec,newTotal];
        for(i=0; i<countHREnabledChans; i++){
        uint32_t chan	= ShiftAndExtract(ptr[5+i],20,0xff);
        uint32_t over	= ShiftAndExtract(ptr[5+countHREnabledChans+i],23,0x1);
        uint32_t hitrate= ShiftAndExtract(ptr[5+countHREnabledChans+i], 0,0x7fffff);
        uint32_t pileupcount= ShiftAndExtract(ptr[5+countHREnabledChans+i], 24,0xff);
            if(over)
                [hrString appendString: [NSString stringWithFormat:@"Chan %2u    = OVERFLOW\n", chan] ];
            else
                [hrString appendString: [NSString stringWithFormat:@"Chan %2u    = %u\n", chan,hitrate] ];
            //[hrString appendString: [NSString stringWithFormat:@"PilUpCnt %2d    = %d\n", chan,  pileupcount] ];
            [hrString appendString: [NSString stringWithFormat:    @"PilUpCnt   = %u\n",   pileupcount] ];
        }
        
    }
    else{
	    hrString = [NSMutableString stringWithFormat:@"\nUTTime     = %u\nHitrateLen = %u\nTotal HR   = %u\n",
						  ut_time,hitRateLengthSec,newTotal];
        for(i=0; i<length-5; i++){
        uint32_t chan	= ShiftAndExtract(ptr[5+i],20,0xff);
        uint32_t over	= ShiftAndExtract(ptr[5+i],16,0x1);
        uint32_t hitrate= ShiftAndExtract(ptr[5+i], 0,0xffff);
            if(over) [hrString appendString: [NSString stringWithFormat:@"Chan %2u    = OVERFLOW\n", chan] ];
            else     [hrString appendString: [NSString stringWithFormat:@"Chan %2u    = %u\n", chan,hitrate] ];
        }
    }
    
    
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,[date stdDescription],hrString];
}
@end




@implementation ORKatrinV4FLTDecoderForHistogram

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
                                 ^^------boxcarLen  (<-- not necessary; temporarily set to have same header for all except hitrate record -tb-)
                                    ^^^^-filterShapingLength    (<-- not necessary; temporarily set to have same header for all except hitrate record -tb-)
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
									 ^--is set for sum histogram (mask 0x02)
                                    ^---is set for between-subrun sum histogram (mask 0x04)
</pre>

  * For more infos: see
  * readOutHistogramDataV3:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo (in model)
  *
  */
//-------------------------------------------------------------

- (id) init
{
    //NSLog(@"DEBUG: Calling %@ :: %@   <<<<------ wie oft?\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG init is called twice at run start and once at 'start subrun' ...-tb-
    self = [super init];
    getHistoReceivedNoteFromDecodeStage = YES;
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
	uint32_t length	= ExtractLength(*ptr);	 //get length from first word

	unsigned char crate		= (ptr[1]>>21) & 0xf;
	unsigned char card		= (ptr[1]>>16) & 0x1f;
	unsigned char chan		= (ptr[1]>>8) & 0xff;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];
    
    int filterShapingLength = ShiftAndExtract(ptr[1],0,0xf);
	uint32_t filterLen = (uint32_t)(1L << filterShapingLength);
    uint32_t histoEBinSize = (uint32_t)(1L << ptr[8]);
    uint32_t histoEOffset = ptr[9];
    
    
    // Normalize the histogram to the full ADC range from 0 .. 4095
    // Todo: Avoid comb structure when scaling up !!!
    
    uint32_t *ptrData;
    uint32_t normE;
    uint32_t spacing;
    uint32_t digiErr;
    uint32_t low, high, edge;
    
    ptrData = &ptr[12];
    for (int i=0;i<4095;i++) normHisto[i] = 0;
    
    // Spacing 2 should be considered, anything larger does not make sense
    spacing = histoEBinSize / filterLen;
    for (int i=0; i<2048;i++) {
        if (spacing < 2) {
           normE = (histoEOffset + i * histoEBinSize) / filterLen;
           if (normE > 4095) normE = 4095;
        
           normHisto[normE] += ptrData[i];
            
        } else {
            // Calculate missing counts due to the integer division
            // digiErr is the number of counts that need to be added
            // to some of the bins. Consider rising and faling edges.
            digiErr = ptrData[i] % spacing;
            low = MAX(i-1,0);
            high = MIN(i+1,2047);
            edge = ptrData[high] - ptrData[low];
            
            for (int j=0; j<spacing; j++){
                normE = (histoEOffset + i * histoEBinSize) / filterLen + j;
                if (normE > 4095) normE = 4095;
                normHisto[normE] = ptrData[i] / spacing;
                
                // Correct digitization error
                if (edge > 0){
                    if (j >= (spacing - digiErr)) normHisto[normE] += 1;
                } else {
                    if (j < digiErr) normHisto[normE] += 1;
                }
            }
            
        }
    }
    
    
	int isSumHistogram = ptr[11] & 0x2; //the bit1 marks the Sum Histograms
    // this counts one histogram as one event in data monitor -tb-
	if(!isSumHistogram) {
        NSArray*  keyArray = [NSArray arrayWithObjects:@"FLT",@"HW Histogram",crateKey,stationKey,channelKey, nil];
        
        [aDataSet mergeHistogram:  normHisto
                         numBins:  4096
                    withKeyArray:  keyArray];
    }
    else {
        NSArray*  keyArray = [NSArray arrayWithObjects:@"FLT",@"HW Histogram (sum)",crateKey,stationKey,channelKey, nil];
        [aDataSet mergeHistogram:  normHisto
                         numBins:  4096
                    withKeyArray:  keyArray];
    }
    

	//get the actual object
	if(getHistoReceivedNoteFromDecodeStage){
		NSString* fltKey = [crateKey stringByAppendingString:stationKey];
		if(!actualFlts)actualFlts = [[NSMutableDictionary alloc] init];
		ORKatrinV4FLTModel* obj = [actualFlts objectForKey:fltKey];
		if(!obj){
			NSArray* listOfFlts = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORKatrinV4FLTModel")];
			for(ORKatrinV4FLTModel* aFlt in listOfFlts){
				if(/*[aFlt crateNumber] == crate &&*/ [aFlt stationNumber] == card){ //TODO: we might have multiple crates in the future -tb-
					[actualFlts setObject:aFlt forKey:fltKey];
					obj = aFlt;
					break;
				}
			}
		}
		//if(getHistoReceivedNoteFromDecodeStage)    [obj addToSumHistogram: someData];
		if(getHistoReceivedNoteFromDecodeStage)    getHistoReceivedNoteFromDecodeStage  =  [obj setFromDecodeStageReceivedHistoForChan:chan ];
    }
    

    return length; //must return number of longs processed.
}



- (NSString*) dataRecordDescription:(uint32_t*)ptr
{

    NSString* title; //= @"Katrin V4 FLT Histogram Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %u\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %u\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %u\n",(*ptr>>8) & 0xff];
	++ptr;		//point to next structure

	katrinV4HistogramDataStruct* ePtr = (katrinV4HistogramDataStruct*)ptr;			//recast to event structure

	int isSumHistogram = ePtr->histogramInfo & 0x2; //the bit1 marks the Sum Histograms
	if(!isSumHistogram) title= @"Katrin V4 FLT Histogram Record\n\n";
	else                title= @"Katrin V4 FLT Summed Histogram Record\n\n";
	
	NSString* readoutSec         = [NSString stringWithFormat:@"ReadoutSec = %d\n",         ePtr->readoutSec];
	NSString* refreshTimeSec	 = [NSString stringWithFormat:@"recordingTimeSec = %d\n",   ePtr->refreshTimeSec];
	NSString* firstBin           = [NSString stringWithFormat:@"firstBin = %d\n",           ePtr->firstBin];
	NSString* lastBin            = [NSString stringWithFormat:@"lastBin  = %d\n",           ePtr->lastBin];
	NSString* histogramLength	 = [NSString stringWithFormat:@"histogramLength    = %d\n", ePtr->histogramLength];
	NSString* maxHistogramLength = [NSString stringWithFormat:@"maxHistogramLength = %d\n", ePtr->maxHistogramLength];
	NSString* binSize            = [NSString stringWithFormat:@"binSize    = %d\n",         ePtr->binSize];
	NSString* offsetEMin         = [NSString stringWithFormat:@"offsetEMin = %d\n",         ePtr->offsetEMin];
	NSString* histIDInfo         = [NSString stringWithFormat:@"ID         = %d.%c\n",      ePtr->histogramID,(ePtr->histogramInfo&0x1)?'B':'A'];


    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
	                       readoutSec,refreshTimeSec,firstBin,lastBin,histogramLength,
                           maxHistogramLength,binSize,offsetEMin,histIDInfo]; 
}

@end


