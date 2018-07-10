//
//  ORDGF4cDecoderForWaveform.m
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


#import "ORDGF4cDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDGF4cModel.h"

@implementation ORDGF4cDecoderForWaveform

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr   = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);

	ptr++;
	unsigned char crate   = (*ptr>>21) & 0x01e;
	unsigned char card   = (*ptr>>16)  & 0x001f;
	unsigned char channel = (*ptr>>12) & 0x0000f;
	
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getStationKey: card];
	NSString* channelKey = [self getChannelKey: channel];
	ptr++;	
    NSData* tmpData = [ NSData dataWithBytes: (char*)ptr length: length*sizeof(long) ];
    [aDataSet loadWaveform:tmpData 
					offset:0 //bytes!
				  unitSize:4 //unit size in bytes!
					sender:self  
				  withKeys:@"ORDGF4c", @"MCA Waveforms",crateKey,cardKey,channelKey,nil];
	
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    
    NSString* title= @"DGF4c Waveform\n\n";
	ptr++;
	unsigned char crate   = (*ptr>>21) & 0x01e;
	unsigned char card   = (*ptr>>16)  & 0x001f;
	unsigned char channel = (*ptr>>12) & 0x0000f;
	
    NSString* crateString = [NSString stringWithFormat:@"Crate = %d\n",crate];
    NSString* cardString  = [NSString stringWithFormat:@"Card  = %d\n",card];
    NSString* chanString  = [NSString stringWithFormat:@"Chan  = %d\n",channel];
    
    return [NSString stringWithFormat:@"%@%@%@%@",title,crateString,cardString,chanString];              
}

@end

@implementation ORDGF4cDecoderForEvent

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long*	recordPtr = (unsigned long*)someData;
	
	//--------------------------------------
	//ORCA header part (all longs)
	// 0: dataID and length
	// 1: location
	//--------------------------------------
	
	unsigned long length = ExtractLength(recordPtr[0]);
	
	unsigned char crate  = (recordPtr[1]>>21) & 0x01e;
	unsigned char card   = (recordPtr[1]>>16) & 0x001f;
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getStationKey: card];
	//note, the channel info will come from the hit pattern in the event header.
	
	//--------
	unsigned short* dataPtr = (unsigned short*)&recordPtr[2];	//recast to short
	unsigned short* endDataPtr;
	
	unsigned long totalWords = length*2 - 4;					//don't count the ORCA header
	unsigned short* bufferHeader = dataPtr;						//set up the bufferHeader block
	unsigned short bufNData		 = bufferHeader[0];				//number of words in the buffer
	endDataPtr = dataPtr + bufNData;
	
	//make sure that there's an event and check the length, if problem flush the rest
	if((long)(totalWords-bufNData)<0 || bufNData<=kBufferHeaderLength)return length; 
	
	unsigned short task	 = bufferHeader[2]; //run task that generated this buffer, needed to determine chanheader length
	task	 &= 0x0fff;						//take off the top bit to get the true 
	
	/* use the run task to determine the channel header length */
	unsigned short chl;
	unsigned short energyIndex = 1;
	switch(task){
		case kListMode:
		case kListModeCompression1:
		case kFastListMode:
		case kFastListModeCompression1:
			chl = 9;
			energyIndex = 2;
			break;
		case kListModeCompression2:
		case kFastListModeCompression2:
			chl = 4;
			break;
		case kListModeCompression3:
		case kFastListModeCompression3:
			chl = 2;
			break;
		default:
			return length; //somethings wrong, just return
			break;
	}
	
	dataPtr += kBufferHeaderLength;
	
	do {
		unsigned short* eventHeader = dataPtr;;
		unsigned short evtPattern = eventHeader[0];	//get the event hit pattern
		dataPtr += kEventHeaderLength;				//the data Ptr ahead to the first channel header
		
		if( evtPattern != 0 ){
			int chan;
			for( chan = 0; chan < 4; chan++){
				if(evtPattern & (0x1<<chan)){
					
					unsigned short* chanHeader	= dataPtr;			//set up for the channel header decode
					unsigned short chanNData	= chanHeader[0];	//number of words in the channel header (may include waveforms)
					long energy					= chanHeader[energyIndex];
					
					[aDataSet histogram:energy numBins:65535 sender:self  withKeys:@"ORDGF4c", @"Events",crateKey,cardKey,[self getChannelKey:chan],nil];
					
					dataPtr += chl;												//move the dataPtr ahead
					
					if( chl == 9 && chanNData > 9){
						
						//there must be a waveform data because the length is greater than the header length.
						unsigned int dataLength = (chanNData-9);
						if(dataPtr + dataLength - 1 < endDataPtr){
							NSData* tmpData = [ NSData dataWithBytes: dataPtr length: dataLength*sizeof(short) ];
						
							//load it into the data monitor.
							[ aDataSet loadWaveform: tmpData		//pass in the whole data set
										 offset: 0				//offset to the start of actual data (bytes!)
									   unitSize: 2				//unit size in bytes
										 sender: self 
									   withKeys: @"ORDGF4c", @"ADC Waveforms",crateKey,cardKey,[self getChannelKey:chan],
								nil];
							dataPtr += chanNData-9;				//move the dataPtr ahead. Note it was moved to the start of waveform already
						}
						else {
							NSLogError(@"Bad Data Record Length",@"DGF4",nil);
							break;
						}
					}
				}
			}
		}
	}while( dataPtr < endDataPtr );
	
	return length;
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    
    NSString* title= @"DGF4c Event\n\n";

    unsigned long*	recordPtr = (unsigned long*)ptr;
	
	//--------------------------------------
	//ORCA header part (all longs)
	// 0: dataID and length
	// 1: location
	//--------------------------------------

	unsigned long length = ExtractLength(recordPtr[0]);

	unsigned char crate  = (recordPtr[1]>>21) & 0x01e;
	unsigned char card   = (recordPtr[1]>>16) & 0x001f;
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getStationKey: card];
	//note, the channel info will come from the hit pattern in the event header.
    NSString* resultString = [NSString stringWithFormat:@"%@\n%@\n%@\n",title,crateKey,cardKey];               

	//--------
	if(recordPtr != NULL) {
		unsigned short* dataPtr = (unsigned short*)&recordPtr[2];	//recast to short
		unsigned short* endDataPtr;
		
		unsigned long totalWords = length*2 - 4;					//don't count the ORCA header
		unsigned short* bufferHeader = dataPtr;						//set up the bufferHeader block
		unsigned short bufNData		 = bufferHeader[0];				//number of words in the buffer
		endDataPtr = dataPtr + bufNData;
		
		//make sure that there's an event and check the length, if problem flush the rest
		if((long)(totalWords-bufNData)<0 || bufNData<=kBufferHeaderLength)return [resultString stringByAppendingString:@"bad record length\n"]; 
		
		unsigned short task	 = bufferHeader[2]; //run task that generated this buffer, needed to determine chanheader length
		task	 &= 0x0fff;						//take off the top bit to get the true 
		
		/* use the run task to determine the channel header length */
		unsigned short chl;
		switch(task){
			case kListMode:
			case kListModeCompression1:
			case kFastListMode:
			case kFastListModeCompression1:
				chl = 9;
			break;
			case kListModeCompression2:
			case kFastListModeCompression2:
				chl = 4;
			break;
			case kListModeCompression3:
			case kFastListModeCompression3:
				chl = 2;
			break;
			default:
				return [resultString stringByAppendingString:@"bad run type\n"]; 
			break;
		}
		
		dataPtr += kBufferHeaderLength;

		do {
			unsigned short* eventHeader = dataPtr;;
			unsigned short evtPattern = eventHeader[0];	//get the event hit pattern
			dataPtr += kEventHeaderLength;				//the data Ptr ahead to the first channel header

			if( evtPattern != 0 ){
				int chan;
				for( chan = 0; chan < 4; chan++){
					if(evtPattern & (0x1<<chan)){
						unsigned short* chanHeader = dataPtr;
						unsigned short energy;
						if( chl == 9 ){
							unsigned short chanNData = chanHeader[0];		//number of words in the channel header (may include waveforms)
							energy = chanHeader[2];
							dataPtr += chanNData;									//move the dataPtr ahead
						}
						else {
							//non waveform chan headers
							energy = chanHeader[1];
							dataPtr += chl;				//move the dataPtr ahead
						}
						resultString = [resultString stringByAppendingString:[NSString stringWithFormat:@"%@ energy: %d\n",[self getChannelKey: chan],energy]];
					}

				}
			}
		}while( dataPtr < endDataPtr );
	}

    return [NSString stringWithFormat:@"%@\n",resultString];               
}
@end

@implementation ORDGF4cDecoderForLiveTime

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

    unsigned long*	recordPtr = (unsigned long*)someData;
	
	//version 0 -- wrong: truncated the livetimes
	//--------------------------------------
	//ORCA header part (all longs)
	// 0: dataID and length  //length == 13
	// 1: spare (for now)
	// 2: location
	// 3: realTime (double packed as long)
	// 4: runTime (double packed as long)
	// 5: chan 0 liveTime (double packed as long)
	// 6: chan 0 numEvents 
	// 7: chan 1 liveTime (double packed as long)
	// 8: chan 1 numEvents 
	// 9: chan 2 liveTime (double packed as long)
	// 10: chan 2 numEvents 
	// 11: chan 3 liveTime (double packed as long)
	// 12: chan 4 numEvents 
	//--------------------------------------

	//version 1
	//--------------------------------------
	//ORCA header part (all longs) //length == 19
	//  0: dataID and length
	//  1: spare
	//  2: location
	//  3: realTime a 
	//  4: realTime b<<16 | c
	//  5: runTime a
	//  6: runTime b<<16 | c
	//  7: chan 0 liveTime a
	//  8: chan 0 liveTime b<<16 | c
	//  9: chan 0 numEvents 
	// 10: chan 1 liveTime a
	// 11: chan 1 liveTime b<<16 | c
	// 12: chan 1 numEvents 
	// 13: chan 2 liveTime a
	// 14: chan 2 liveTime b<<16 | c
	// 15: chan 2 numEvents 
	// 16: chan 3 liveTime a
	// 17: chan 3 liveTime b<<16 | c
	// 18: chan 4 numEvents 
	//--------------------------------------


	unsigned long length = ExtractLength(recordPtr[0]);
	
	//recordPtr[1] reserved for future gtid

	unsigned char crate  = (recordPtr[2]>>21) & 0x01e;
	unsigned char card   = (recordPtr[2]>>16) & 0x001f;
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getStationKey: card];

	int index = 3;
	if(length == 13){
		//unpack the RealTime
		packedDGF4LiveTime.asLong = recordPtr[index++];
		double dValue = packedDGF4LiveTime.asDouble;
		NSString* valueString = [NSString stringWithFormat:@"%.4f",dValue];
		[aDataSet loadGenericData:valueString sender:self withKeys:@"ORDGF4c",@"RealTime",crateKey,cardKey,nil];
		
		//unpack the RunTime
		packedDGF4LiveTime.asLong = recordPtr[index++];
		dValue = packedDGF4LiveTime.asDouble;
		valueString = [NSString stringWithFormat:@"%.4f",dValue];
		[aDataSet loadGenericData:valueString sender:self withKeys:@"ORDGF4c",@"RunTime",crateKey,cardKey,nil];

		int chan;
		for(chan=0;chan<4;chan++){
			//unpack the LiveTime and format a string to display holding the livetime and the number of events
			packedDGF4LiveTime.asLong = recordPtr[index++];
			NSString* result = [NSString stringWithFormat:@"%.4f #Events: %lu",packedDGF4LiveTime.asDouble,recordPtr[index++]];
			[aDataSet loadGenericData:result sender:self withKeys:@"ORDGF4c",@"Livetime",crateKey,cardKey, [self getChannelKey: chan],nil];
			
		}
	}
	else {
		//unpack the RealTime
		unsigned long rta = recordPtr[index++];
		unsigned long bc  = recordPtr[index++];
		unsigned long rtb = bc>>16;
		unsigned long rtc = bc&0x0000ffff;
		double dValue = (rta*pow(65536.0,2.0)+rtb*65536.0+rtc)*1.0e-6/40.;
		NSString* valueString = [NSString stringWithFormat:@"%.4f",dValue];
		[aDataSet loadGenericData:valueString sender:self withKeys:@"ORDGF4c",@"RealTime",crateKey,cardKey,nil];
		
		//unpack the RunTime
		rta = recordPtr[index++];
		bc  = recordPtr[index++];
		rtb = bc>>16;
		rtc = bc&0x0000ffff;
		dValue = (rta*pow(65536.0,2.0)+rtb*65536.0+rtc)*1.0e-6/40.;
		valueString = [NSString stringWithFormat:@"%.4f",dValue];
		[aDataSet loadGenericData:valueString sender:self withKeys:@"ORDGF4c",@"RunTime",crateKey,cardKey,nil];

		int chan;
		for(chan=0;chan<4;chan++){
			//unpack the LiveTime and format a string to display holding the livetime and the number of events
			rta = recordPtr[index++];
			bc  = recordPtr[index++];
			rtb = bc>>16;
			rtc = bc&0x0000ffff;
			double dValue = (rta*pow(65536.0,2.0)+rtb*65536.0+rtc)*1.0e-6/40.;
			NSString* result = [NSString stringWithFormat:@"%.4f #Events: %lu",dValue,recordPtr[index++]];
			[aDataSet loadGenericData:result sender:self withKeys:@"ORDGF4c",@"Livetime",crateKey,cardKey, [self getChannelKey: chan],nil];
			
		}


	}

	return length;
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSString* title= @"DGF4c Event\n\n";

    unsigned long*	recordPtr = (unsigned long*)dataPtr;
	unsigned long length = ExtractLength(recordPtr[0]);

	//version 0 -- wrong: truncated the livetimes
	//--------------------------------------
	//ORCA header part (all longs)
	// 0: dataID and length  //length == 13
	// 1: spare (for now)
	// 2: location
	// 3: realTime (double packed as long)
	// 4: runTime (double packed as long)
	// 5: chan 0 liveTime (double packed as long)
	// 6: chan 0 numEvents 
	// 7: chan 1 liveTime (double packed as long)
	// 8: chan 1 numEvents 
	// 9: chan 2 liveTime (double packed as long)
	// 10: chan 2 numEvents 
	// 11: chan 3 liveTime (double packed as long)
	// 12: chan 4 numEvents 
	//--------------------------------------

	//version 1
	//--------------------------------------
	//ORCA header part (all longs) //length == 19
	//  0: dataID and length
	//  1: spare
	//  2: location
	//  3: realTime a 
	//  4: realTime b<<16 | c
	//  5: runTime a
	//  6: runTime b<<16 | c
	//  7: chan 0 liveTime a
	//  8: chan 0 liveTime b<<16 | c
	//  9: chan 0 numEvents 
	// 10: chan 1 liveTime a
	// 11: chan 1 liveTime b<<16 | c
	// 12: chan 1 numEvents 
	// 13: chan 2 liveTime a
	// 14: chan 2 liveTime b<<16 | c
	// 15: chan 2 numEvents 
	// 16: chan 3 liveTime a
	// 17: chan 3 liveTime b<<16 | c
	// 18: chan 4 numEvents 
	//--------------------------------------

	
	//recordPtr[1] reserved for future gtid

	unsigned char crate  = (recordPtr[2]>>21) & 0x01e;
	unsigned char card   = (recordPtr[2]>>16) & 0x001f;
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getStationKey: card];
    NSString* resultString = [NSString stringWithFormat:@"%@\n%@\n%@\n",title,crateKey,cardKey];               

	
	int index = 3;

	if(length == 13){
		//unpack the realTime
		packedDGF4LiveTime.asLong = recordPtr[index++];
		resultString = [resultString stringByAppendingString:[NSString stringWithFormat:@"RealTime: %.4f\n",packedDGF4LiveTime.asDouble]];

		//unpack the runTime
		packedDGF4LiveTime.asLong = recordPtr[index++];
		resultString = [resultString stringByAppendingString:[NSString stringWithFormat:@"RunTime: %.4f\n",packedDGF4LiveTime.asDouble]];
		
		int chan;
		for(chan=0;chan<4;chan++){
		
			//unpack the liveTime for this channel
			packedDGF4LiveTime.asLong = recordPtr[index++];
			resultString = [resultString stringByAppendingString:[NSString stringWithFormat:@"%@ LiveTime : %.4f\n",[self getChannelKey: chan],packedDGF4LiveTime.asDouble]];
			
			//unpack the numEvents for this channel
			unsigned long numEvents = recordPtr[index++];
			resultString = [resultString stringByAppendingString:[NSString stringWithFormat:@"%@ numEvents: %lu\n",[self getChannelKey: chan],numEvents]];
		}
	}
	else {
		//unpack the realTime
		unsigned long rta = recordPtr[index++];
		unsigned long bc  = recordPtr[index++];
		unsigned long rtb = bc>>16;
		unsigned long rtc = bc&0x0000ffff;
		resultString = [resultString stringByAppendingString:[NSString stringWithFormat:@"RealTime: %.4f\n",(rta*pow(65536.0,2.0)+rtb*65536.0+rtc)*1.0e-6/40.]];

		//unpack the runTime
		rta = recordPtr[index++];
		bc  = recordPtr[index++];
		rtb = bc>>16;
		rtc = bc&0x0000ffff;
		resultString = [resultString stringByAppendingString:[NSString stringWithFormat:@"RunTime: %.4f\n",(rta*pow(65536.0,2.0)+rtb*65536.0+rtc)*1.0e-6/40.]];
		
		int chan;
		for(chan=0;chan<4;chan++){
		
			//unpack the liveTime for this channel
			rta = recordPtr[index++];
			bc  = recordPtr[index++];
			rtb = bc>>16;
			rtc = bc&0x0000ffff;
			resultString = [resultString stringByAppendingString:[NSString stringWithFormat:@"%@ LiveTime : %.4f\n",[self getChannelKey: chan],(rta*pow(65536.0,2.0)+rtb*65536.0+rtc)*1.0e-6/40.]];
			
			//unpack the numEvents for this channel
			unsigned long numEvents = recordPtr[index++];
			resultString = [resultString stringByAppendingString:[NSString stringWithFormat:@"%@ numEvents: %lu\n",[self getChannelKey: chan],numEvents]];
		}
	}
	return resultString;
}

@end

