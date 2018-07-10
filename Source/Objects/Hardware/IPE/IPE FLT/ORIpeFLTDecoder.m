//
//  ORIpeFLTDecoder.m
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


#import "ORIpeFLTDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORIpeFLTDefs.h"

@implementation ORIpeFLTDecoderForWaveForm

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
followed by waveform data (n x 1024 16-bit words)
</pre>
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
			
	// Set up the waveform
	NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(long)];

	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 2*sizeof(long)					// Offset in bytes (2 header words)
				  unitSize: sizeof(short)					// unit size in bytes
				startIndex:	0							// first Point Index (past the header offset!!!)
					  mask:	0x0FFF							// when displayed all values will be masked with this value
			   specialBits: 0xF000						
				  bitNames: [NSArray arrayWithObjects:@"trig",@"over",@"under", @"extern",nil]
					sender: self 
				  withKeys: @"FLT", @"Waveform",crateKey,stationKey,channelKey,nil];

	
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title= @"Ipe FLT Waveform Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %lu\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %lu\n",(*ptr>>8) & 0xff];

    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,chan]; 
}



@end


