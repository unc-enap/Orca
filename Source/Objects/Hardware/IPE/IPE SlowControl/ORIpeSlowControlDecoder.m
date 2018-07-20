//
//  ORIpeSlowControlDecoder.h
//  Orca
//
//  Created by Till Bergmann on 01/16/2009.
//  Copyright 2009 xxxx, University of xxxx. All rights reserved.
//-----------------------------------------------------------
//
//
//
//
//  TODO: Copyright etc. probably new since 2009? -tb-
//
//
//
//
//-------------------------------------------------------------




#import "ORIpeSlowControlDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

#pragma mark •••Static Definitions

static NSString* kIpeAdeiObjectKey[32] = {
	//pre-make some keys for speed.
	@"IPE-ADEI  0", @"IPE-ADEI  1", @"IPE-ADEI  2", @"IPE-ADEI  3",
	@"IPE-ADEI  4", @"IPE-ADEI  5", @"IPE-ADEI  6", @"IPE-ADEI  7",
	@"IPE-ADEI  8", @"IPE-ADEI  9", @"IPE-ADEI 10", @"IPE-ADEI 11",
	@"IPE-ADEI 12", @"IPE-ADEI 13", @"IPE-ADEI 14", @"IPE-ADEI 15",
	@"IPE-ADEI 16", @"IPE-ADEI 17", @"IPE-ADEI 18", @"IPE-ADEI 19",
	@"IPE-ADEI 20", @"IPE-ADEI 21", @"IPE-ADEI 22", @"IPE-ADEI 23",
	@"IPE-ADEI 24", @"IPE-ADEI 25", @"IPE-ADEI 26", @"IPE-ADEI 27",
	@"IPE-ADEI 28", @"IPE-ADEI 29", @"IPE-ADEI 30", @"IPE-ADEI 31"
};

@implementation ORIpeSlowControlDecoderForChannelData  

//-------------------------------------------------------------
/** Data format for ADEI channel data (first two words as cloase as possible at Orca standard):
  *
<pre>
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------adei object id
             ^ ^^^^---------------------spare
			        ^^^^ ^^^^ ----------channel
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx value encoded as float
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx timestampSec (From 1970)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx timestampSubSec
</pre>
    Orca identifies the type of binary data record by the header bytes.
    By this it finds this class (its selector is connected with its ID in
     - (NSDictionary*) dataRecordDescription
  */ //-tb- 2008-02-6
//-------------------------------------------------------------

- (NSString*) getIpeSlowControlObjectKey:(unsigned short)aValue
{
	if(aValue<32) return kIpeAdeiObjectKey[aValue];
	else return [NSString stringWithFormat:@"IPE-ADEI %2d",aValue];		
	
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length	= ExtractLength(*ptr);	 //get length from first word
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	
    NSString* title= @"Slow Controls\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	theString = [theString stringByAppendingFormat:@"ADEI-%u\n",(ptr[1]>>21) & 0xf];
	theString = [theString stringByAppendingFormat:@"Polling Channel: %u\n",ptr[1] & 0xff];
	theData.asLong = ptr[2];
	theString = [theString stringByAppendingFormat:@"Value: %.4E\n",theData.asFloat];
	// -tb- theString = [theString stringByAppendingFormat:@"Value: %.4E\n",theData.asFloat];
	NSTimeInterval seconds = ptr[3] + ptr[4]/1000.;
	NSDate* theDate = [NSDate dateWithTimeIntervalSince1970:seconds];
	theString = [theString stringByAppendingFormat:@"Date: %@\n",[theDate stdDescription]];
	return theString;
}
@end


