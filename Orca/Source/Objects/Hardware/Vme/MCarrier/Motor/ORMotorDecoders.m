//
//  ORMotorDecoders.m
//  Orca
//
//  Created by Mark Howe on 03/12/05.
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


#import "ORMotorDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

@implementation ORMotorDecoderForMotor

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    return ExtractLength(*((unsigned long*)someData));
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSString* title= @"Motor Motor Record\n\n";

	NSString* crate   = [NSString stringWithFormat:@"Crate  = %lu\n",(dataPtr[2]>>28) & 0x0000000f];
	NSString* card    = [NSString stringWithFormat:@"Card   = %lu\n",(dataPtr[2]>>23) & 0x0000001f];
	NSString* module  = [NSString stringWithFormat:@"Module = %lu\n",(dataPtr[2]>>20) & 0x00000007];
	NSString* motor   = [NSString stringWithFormat:@"Motor  = %lu\n", (dataPtr[2]>>16)&0x00000003];
	NSString* state   = [NSString stringWithFormat:@"State  = %lu\n",(dataPtr[2]>>12) & 0x0000000f];

    return [NSString stringWithFormat:@"%@%s%@%@%@%@%@Steps  = %lu",title,ctime((const time_t *)(&dataPtr[1])),crate,card,module,motor,state,dataPtr[3]];               
}
@end


