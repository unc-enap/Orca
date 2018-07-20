    //
//  ORSIS3305Decoders.m
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

#import "ORSIS3305Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORSIS3305Model.h"


@implementation ORSIS3305DecoderForWaveform
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

const unsigned short kchannelModeAndEventID[16][16] = {
    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 0: 4x1.25 w/ FIFO
    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 1: 4x1.25 w/ FIFO
    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 2: 4x1.25 w/ FIFO
    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 3: 4x1.25 w/ FIFO
    
    {0xF,0xF,0xF,0xF,0,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 4: 2x2.5 w/ FIFO
    {0xF,0xF,0xF,0xF,1,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 5: 2x2.5 w/ FIFO
    {0xF,0xF,0xF,0xF,0,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 6: 2x2.5 w/ FIFO
    {0xF,0xF,0xF,0xF,1,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 7: 2x2.5 w/ FIFO
    
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,0,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 8
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,1,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 9
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode A
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode B
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,0,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode C
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,1,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode D
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode E
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF}  // channel mode F
};


- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualSIS3305Cards release];
    [super dealloc];
}


- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    
    uint32_t* ptr	= (uint32_t*)someData;

    // extract things from the Orca header
	uint32_t length = ExtractLength(ptr[0]);        // the length in longs of the full *read* record (may contain multiple waveforms), with Orca header
	unsigned int crate	 = ShiftAndExtract(ptr[1],28,0xf);
	unsigned int card	 = ShiftAndExtract(ptr[1],20,0x1f);

    unsigned short  channelMode = ShiftAndExtract(ptr[1],16, 0xF);
    unsigned int    group       = ShiftAndExtract(ptr[1],12, 0x1);
    unsigned short  rate        = ShiftAndExtract(ptr[1], 8, 0xF);
    unsigned short  savingMode  = ShiftAndExtract(ptr[1], 4, 0xF);
    BOOL            wrapMode    = ShiftAndExtract(ptr[1], 0, 0x1);
    
    uint32_t dataLengthSingle = ptr[2];      // SIS header + data length of single record, in longs
    
	int32_t sisHeaderLength;
	if(wrapMode)sisHeaderLength = 16;
	else		sisHeaderLength = 4;
    uint32_t orcaHeaderLength = 4;
    
    unsigned short numEvents = (length-orcaHeaderLength)/dataLengthSingle;
    uint32_t numEventsFromHeader = ptr[3]&0xFFFF;
    
    if (numEvents != numEventsFromHeader)
    {
        NSLogColor([NSColor redColor], @"SIS3305: Number of events incorrectly determined in at least one location!\n");
        NSLogColor([NSColor redColor], @"SIS3305: Header gives 0x%x, calculation gives 0x%x\n",numEventsFromHeader,numEvents);
    }
    
//    NSLog(@"Record is 0x%x longs in total length, which should be %d events.\n",length,numEvents);

    //uint32_t waveformLengthSet = dataLengthSingle-sisHeaderLength;
    // this is the length of (waveform + sisheader) in longs. Each int32_t word is 3 10 bit adc samples
    // "waveformLengthSet" is the value Orca thinks should be the length based on the sample length settings that have been used.
    // It should always be right, but if something went wrong, a safer place to look is in the SIS header, at the block length of samples.
    // I will compare the value from the header to this each time to be safe.
    uint32_t dataLengthSIS;
    uint32_t waveformLengthSIS;
    
    uint32_t* dataPtr       = ptr + orcaHeaderLength;   // hold on to this here
    
    unsigned short n;
    for(n=0;n<numEvents;n++)
    {
        uint32_t* nextRecordPtr = 0; // take you to the start of the next SIS header
        
        // Should check  that the dataPtr points to realistic data
        
        // extract things from the SIS header
//        uint32_t       timestampLow = dataPtr[1];
//        uint32_t       timestampHigh = dataPtr[0]&0xFFFF;
//        uint64_t  timestamp = timestampLow | (timestampHigh << 31);

        // Biggest pre-computed value  is 31 - if you see this in the data, there IS an error somewhere (only 8 channels...)
        // each of the possible decoding options should handle assigning the channel independently.
        unsigned short channel = 31;
        NSString* channelKey; //= [self getChannelKey: channel];;
        
        NSString* crateKey		= [self getCrateKey: crate];
        NSString* cardKey		= [self getCardKey: card];
        NSMutableData*  recordAsData; // = [NSMutableData dataWithCapacity:(waveformLengthSIS*3*8)];

//        if(waveformLengthSIS /*&& (waveformLength == (length - 3))*/)
//        { // this is a sanity check that we have data and it is the size we expect
            if(wrapMode)
            {
                return (uint32_t)(-1);
              /*
                channel = (kchannelModeAndEventID[channelMode][eventID] + (group*4));
                channelKey    = [self getChannelKey: channel];

                uint32_t nof_wrap_samples = dataPtr[6] ;
                if(nof_wrap_samples <= waveformLength*3)
                {
                    uint32_t wrap_start_index = dataPtr[7] ;
                    unsigned short* dataPtr			  = (unsigned short*)[recordAsData bytes];
                    unsigned short* ushort_buffer_ptr = (unsigned short*) &dataPtr[8];
                    int i;
                    uint32_t j	=	wrap_start_index;
                    for (i=0;i<nof_wrap_samples;i++)
                    {
                        if(j >= nof_wrap_samples ) j=0;
                        dataPtr[i] = ushort_buffer_ptr[j++];
                    }
                }
               */
            }
            else if((savingMode == 4) && (channelMode < 4))  // 1.25 Gsps Event fifo mode with all four channels potentially enabled
            {
                if (dataPtr[0] == 0xFFFFFFFF) {
                    NSLog(@"Data was packed with 0xFFFF at end, returning...\n");
                    return length;
                }
                
                unsigned short      eventID = ShiftAndExtract(dataPtr[0], 28, 0xF);
                channel = eventID + (group*4);
                channelKey    = [self getChannelKey: channel];
                
                waveformLengthSIS   = (dataPtr[3]&0xFFFF)*4;      // data length (no headers), in longs
                dataLengthSIS       = sisHeaderLength + waveformLengthSIS;
                if(dataLengthSingle != dataLengthSIS){
                    NSLogColor([NSColor redColor], @"SIS3305: Header-written data lengths disagree (0x%x vs 0x%x) in group %d after (%d / %d) records processed. This is serious!\n",dataLengthSingle,dataLengthSIS, group,n,numEvents);
                    break;
                }
                recordAsData = [NSMutableData dataWithCapacity:(waveformLengthSIS*3*8)];
                
                [recordAsData setLength:(waveformLengthSIS*3*2)];  // length in bytes! there are 3 samples in each Long of the waveform, each takes 2 bytes
                uint32_t* lptr = (uint32_t*)&dataPtr[sisHeaderLength]; // skip ORCA header + SIS header
                
                int i=0;
                unsigned short* waveData = (unsigned short*)[recordAsData mutableBytes];
                int waveformIndex = 0;
                // here `i` increments through each int32_t word in the data
                for(i=0;i<waveformLengthSIS;i++){
                    waveData[waveformIndex++] = (lptr[i]>>20)   &0x3ff; // sample (3*i + waveformIndex)
                    waveData[waveformIndex++] = (lptr[i]>>10)   &0x3ff;
                    waveData[waveformIndex++] = (lptr[i])       &0x3ff;
                }
            
            }
            else if(savingMode == 0){  // 1 x 5 Gsps Event fifo mode
                //            uint32_t numBlocks = (ptr[6]&0xFFFF);
                channel = group*4;  //  FIX: use the real channel number - this is unique, but not right
                channelKey    = [self getChannelKey: channel];
                
                waveformLengthSIS = 16*(dataPtr[3]&0xFFFF); // # longs SIS header claims are in waveform
                dataLengthSIS       = sisHeaderLength + waveformLengthSIS;
                if(dataLengthSingle != dataLengthSIS){
                    NSLogColor([NSColor redColor], @"SIS3305: Header-written data lengths disagree (0x%x vs 0x%x) in group %d. This is serious!\n",dataLengthSingle,dataLengthSIS, group);                    break;
                }
                recordAsData = [NSMutableData dataWithCapacity:(waveformLengthSIS*3*8)];
                [recordAsData setLength:waveformLengthSIS*3*2];    // length is in bytes (hence 2), 3 samples per Lword
                
                if (rate == 2) { // 5gsps
                    // if we're reading out at 5 gsps, we have to unpack and de-interlace all four of the 4-word blocks at once...
                    
                    uint32_t* lptr = (uint32_t*)&dataPtr[sisHeaderLength]; // skip ORCA header + SIS header
                    int i;
                    unsigned short* waveData = (unsigned short*)[recordAsData bytes];
                    int waveformIndex = 0;
                    
                    // sisDataLength*3 = number samples in waveform
                    for(i=0;i<(dataLengthSIS*3);i+=16) // i steps through the entire waveform
                    {
                        unsigned short k;
                        for (k = 0; k<4; k++) { // k steps through the 4-word block that each ADC produces
                            waveData[waveformIndex++] = (lptr[0+i+k]>>20)   &0x3ff;   // sample 1 + 12*k
                            waveData[waveformIndex++] = (lptr[8+i+k]>>20)   &0x3ff;   // sample 2 + 12*k
                            waveData[waveformIndex++] = (lptr[4+i+k]>>20)   &0x3ff;   // sample 3 + 12*k
                            waveData[waveformIndex++] = (lptr[12+i+k]>>20)  &0x3ff;   // sample 4 + 12*k
                            
                            waveData[waveformIndex++] = (lptr[0+i+k]>>10)   &0x3ff;   // sample 5 + 12*k
                            waveData[waveformIndex++] = (lptr[8+i+k]>>10)   &0x3ff;   // sample 6 + 12*k
                            waveData[waveformIndex++] = (lptr[4+i+k]>>10)   &0x3ff;   // sample 7 + 12*k
                            waveData[waveformIndex++] = (lptr[12+i+k]>>10)  &0x3ff;   // sample 8 + 12*k
                            
                            waveData[waveformIndex++] = (lptr[0+i+k])       &0x3ff;   // sample 9 + 12*k
                            waveData[waveformIndex++] = (lptr[8+i+k])         &0x3ff;   // sample 10 + 12*k
                            waveData[waveformIndex++] = (lptr[4+i+k])         &0x3ff;   // sample 11 + 12*k
                            waveData[waveformIndex++] = (lptr[12+i+k])        &0x3ff;   // sample 12 + 12*k
                            
                        }
                    }
                }
                
                
                if (rate == 1) {
                    // FIX: THIS COMPLETELY WON'T WORK -- just a placeholder!!!!!!
                    
                    uint32_t* lptr = (uint32_t*)&dataPtr[sisHeaderLength]; // skip ORCA header + SIS header
                    int i;
                    unsigned short* waveData = (unsigned short*)[recordAsData bytes];
                    int waveformIndex = 0;
                    // here `i` increments through each word in the data
                    //
                    for(i=0;i<waveformLengthSIS;i++){
                        waveData[waveformIndex++] = (lptr[i]>>20)   &0x3ff; // sample (3*i + waveformIndex)
                        waveData[waveformIndex++] = (lptr[i]>>10)   &0x3ff;
                        waveData[waveformIndex++] = (lptr[i])       &0x3ff;
                    }
                    
                }
            }
            else if(savingMode == 1){   // 2.5 Gsps Event FIFO mode
                channel = ((dataPtr[0]>>28)&0xF)+ (group*4);

                channelKey    = [self getChannelKey: channel];
                
                waveformLengthSIS = 8*(dataPtr[3]&0xFFFF); // # longs SIS header claims are in waveform
                dataLengthSIS       = sisHeaderLength + waveformLengthSIS;
                if(dataLengthSingle != dataLengthSIS){
                    NSLogColor([NSColor redColor], @"SIS3305: Header-written data lengths disagree (0x%x vs 0x%x) in group %d. This is serious!\n",dataLengthSingle,dataLengthSIS, group);
                    break;
                }
                
//                if(waveformLengthSIS > 0x300)
//                {
//                    NSLogColor([NSColor redColor], @"SIS3305: waveform length 0x%x is too int32_t. \n",waveformLengthSIS*12 );
//                    return length;
//                }
                recordAsData = [NSMutableData dataWithCapacity:(waveformLengthSIS*3*8)];

                
//                uint32_t sisDataLength = 8*(dataPtr[3]&0xFFFF); // # longs SIS header claims are in waveform

                [recordAsData setLength:3*2*waveformLengthSIS];
                uint32_t* lptr = (uint32_t*)&dataPtr[sisHeaderLength]; //ORCA header + SIS header
                int i = 0;
                unsigned short* waveData = (unsigned short*)[recordAsData bytes];
                int waveformIndex = 0;
                unsigned short k = 0;
                //            for(i=0;i<2*waveformLength/3;i++){
                for(i=0;i<(dataLengthSIS*3);i+=8) { // sisDataLength*3 = number samples in waveform
                    // lptr[i] is at the first word of the 8x32-bit data block
                    for (k=0; k<4; k++ )
                    {
                        waveData[waveformIndex++] = (lptr[0+i+k]>>20)   &0x3ff;   // sample 1
                        waveData[waveformIndex++] = (lptr[4+i+k]>>20)   &0x3ff;   // sample 2
                        waveData[waveformIndex++] = (lptr[0+i+k]>>10)   &0x3ff;   // sample 3
                        waveData[waveformIndex++] = (lptr[4+i+k]>>10)   &0x3ff;   // sample 4
                        waveData[waveformIndex++] = (lptr[0+i+k])       &0x3ff;   // sample 5
                        waveData[waveformIndex++] = (lptr[4+i+k])       &0x3ff;   // sample 6
                    }
                }
                
            }   // end if( savingMode == 1)
            else
            {
                NSLogColor([NSColor redColor], @"SIS3305: Apparently there was no decoder for this data!\n");
                // take a guess at the data length... will probably fail, but we should never get here.
                return length;
            }
            //        unsigned short* waveData = (unsigned short*)[recordAsData bytes];
            //        NSLog(@"         waveData[0,10,20,100] = (%d,%d,%d,%d)\n",waveData[0],waveData[10],waveData[20],waveData[100]);
            
//        } // if(waveformLength)
            if(recordAsData)[aDataSet loadWaveform:recordAsData
                                            offset: 0 //bytes!
                                          unitSize: sizeof( unsigned short ) //unit size in bytes! 10 bits needs 2 bytes
                                            sender: self
                                          withKeys: @"SIS3305", @"Waveform",crateKey,cardKey,channelKey,nil];

        nextRecordPtr = dataPtr + dataLengthSingle; // take you to the start of the next SIS header
        dataPtr = nextRecordPtr;
//        NSLog(@"    Decoded %d/%d events so far\n",n+1,numEvents);
        
        //get the actual object
        if(getRatesFromDecodeStage && !skipRateCounts){
            NSString* aKey = [crateKey stringByAppendingString:cardKey];
            if(!actualSIS3305Cards)actualSIS3305Cards = [[NSMutableDictionary alloc] init];
            ORSIS3305Model* obj = [actualSIS3305Cards objectForKey:aKey];
            if(!obj){
                NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSIS3305Model")];
                NSEnumerator* e = [listOfCards objectEnumerator];
                ORSIS3305Model* aCard;
                while(aCard = [e nextObject]){
                    if([aCard slot] == card){
                        [actualSIS3305Cards setObject:aCard forKey:aKey];
                        obj = aCard;
                        break;
                    }
                }
            }
            getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
        }

    }// end of loop over numEvents
    
//    NSLog(@"Processed %d events\n",n);
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	
 //   uint32_t length= ExtractLength(ptr[0]);
    unsigned int crateNum	= ShiftAndExtract(ptr[1],28,0xf);
    unsigned int cardNum	= ShiftAndExtract(ptr[1],20,0x1f);
    unsigned short channelModeNum = ShiftAndExtract(ptr[1], 16, 0xF);
    unsigned int groupNum	= ShiftAndExtract(ptr[1],12,0xf);
    unsigned short rateNum = ShiftAndExtract(ptr[1], 8, 0xF);
    unsigned short savingModeNum = ShiftAndExtract(ptr[1], 4, 0xF);
 //   BOOL wrapMode		= ShiftAndExtract(ptr[1],0,0x1);
    
    
//	 ptr++;
    NSString* title= @"SIS3305 Waveform Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",crateNum];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",cardNum];
    NSString* group  = [NSString stringWithFormat:@"Group  = %d\n",groupNum];
    NSString* rate  = [NSString stringWithFormat:@"Rate  = %d\n",rateNum];
    NSString* savingMode  = [NSString stringWithFormat:@"SavingMode  = %d\n",savingModeNum];
    NSString* channelMode  = [NSString stringWithFormat:@"Channel Mode  = %d\n",channelModeNum];

	 
    uint32_t timestampLow = ptr[4];
    uint32_t timestampHigh = ptr[3]&0xFFFF;
    uint64_t timestamp = timestampLow | (timestampHigh << 31);
    NSString* timeStamp = [NSString stringWithFormat:@"Timestamp:\n  0x%llx\n",timestamp];
    
    
    NSString* rawHeader = @"Raw header:\n";
    unsigned int i;
    for(i=0;i<4;i++){
        NSString* tmp = [NSString stringWithFormat:@"%03d: 0x%08x \n",i,(*ptr++)];
        rawHeader = [rawHeader stringByAppendingString:tmp];
    }
    rawHeader = [rawHeader stringByAppendingString:@"\n"];

    
    
    NSString* raw = @"Raw data:\n";
    for(i=0;i<100;i++){
        NSString* tmp1 = [NSString stringWithFormat:@"%03d: 0x%04x, ",i,(((*ptr++)>>20)&0x3ff)];
        NSString* tmp2 = [NSString stringWithFormat:@"0x%04x, ",(((*ptr++)>>10)&0x3ff)];
        NSString* tmp3 = [NSString stringWithFormat:@"0x%04x \n",(((*ptr++)>>00)&0x3ff)];
        raw = [raw stringByAppendingString:[tmp1 stringByAppendingString:[tmp2 stringByAppendingString:tmp3]]];
    }

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@",title,crate,card,group,rate,savingMode,channelMode,timeStamp,rawHeader,raw];
    
}
@end


