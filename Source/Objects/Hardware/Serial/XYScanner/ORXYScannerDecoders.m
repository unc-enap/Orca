//
//  ORXYScannerDecoders.m
//  Orca
//
//  Created by Mark Howe on 08/1/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORXYScannerDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

@implementation ORXYScannerDecoderForPosition

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    return ExtractLength(*((uint32_t*)someData));
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"Motor Position Record\n\n";

	NSString* motor   = [NSString stringWithFormat:@"Motor  = %u\n",(dataPtr[2]) & 0x0000ffff];
    unsigned short optionMask = (dataPtr[2]>>16) & 0x0000ffff;
    NSString* optionString;
    if(optionMask == 0)optionString = @"stopped\n";
    else optionString = @"moving\n";
    union {
        int32_t theLong;
        float theFloat;
    }data;
    data.theLong = dataPtr[3];
    NSString* xPosition = [NSString stringWithFormat:@"X = %.4f\n",data.theFloat];
    data.theLong = dataPtr[4];
    NSString* yPosition = [NSString stringWithFormat:@"Y = %.4f\n",data.theFloat];
    return [NSString stringWithFormat:@"%@%s%@%@%@%@",title,ctime((const time_t *)(&dataPtr[1])),motor,optionString,xPosition,yPosition];               
}
@end


