//
//  ORMotionNodeDecoders.m
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


#import "ORMotionNodeDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "OR1DHisto.h"

/*----------------------------------------------
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
                  ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
				  ^^---------------------traceid (0=x,1=y,2=z)
                          ^^^^ ^^^^ ^^^^-device
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx Unix Time
 the  trace follows and fills out the record length (floats encoded as longs)
  ------------------------------------------------*/
static NSString* kMotionNodeTraceType[3] = {
	//pre-make some keys for speed.
	@"X Trace",@"Y Trace",@"Z Trace"
};

@implementation ORMotionNodeDecoderForXYZTrace

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr	 = (uint32_t*)someData;
    uint32_t length = ExtractLength(*ptr);
	ptr++; //location info
    int type   = (*ptr>>16) & 0x3;
	int device = *ptr&0xFFF;
	ptr++; //time
	ptr++; //start of data

	NSMutableData* tmpData = [NSMutableData dataWithLength:(length-3)*sizeof(int32_t)];
	int32_t* lPtr = (int32_t*)[tmpData bytes];
	
	int i;
	for(i=0;i<length-3;i++){
		*lPtr++ = *ptr++;
	}
	
    [aDataSet loadWaveform:tmpData 
					offset:0 //bytes!
				  unitSize:sizeof(int32_t) //unit size in bytes!
					sender:self  
				  withKeys:@"MotionNode",[NSString stringWithFormat:@"Device %2d",device], [self getChannelKey:type],nil];
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{    
    NSString* title= @"MotionNode Accel Record\n\n";
	
    ptr++; //point at location;
    int type  = (*ptr>>16) & 0x3;
    int device = (*ptr) & 0xfff;
	NSString* traceType = kMotionNodeTraceType[type];
	
    ptr++; //point at trace time
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)*ptr];		
    return [NSString stringWithFormat:@"%@\nMotionNode (%d)\ntype: %@\nTime: %@",title,device,traceType,[date stdDescription]];
}


@end

