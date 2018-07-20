//
//  ORTrigger32Decoders.h
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



#import "ORVmeCardDecoder.h"

@class ORDataPacket;
@class ORDataSet;


@interface ORTrigger32DecoderFor100MHzClockRecord : ORVmeCardDecoder 
{}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)ptr;
@end

@interface ORTrigger32DecoderFor10MHzClockRecord : ORTrigger32DecoderFor100MHzClockRecord 
{}
@end

@interface ORTrigger32DecoderForGTIDRecord : ORVmeCardDecoder 
{}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)ptr;
@end

@interface ORTrigger32DecoderForGTID1Record : ORTrigger32DecoderForGTIDRecord 
{}
@end
@interface ORTrigger32DecoderForGTID2Record : ORTrigger32DecoderForGTIDRecord 
{}
@end

@interface ORTrigger32DecoderForLiveTime : ORVmeCardDecoder
{
    int64_t   total_live;
    int64_t   trig1_live;
    int64_t   trig2_live;
    int64_t   scope_live;

    int64_t   last_total_live;
    int64_t   last_trig1_live;
    int64_t   last_trig2_live;
    int64_t   last_scope_live;
}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)ptr;
@end
