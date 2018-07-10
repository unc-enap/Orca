//
//  NcdDecoders.h
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


#import "ORBaseDecoder.h"

@class ORDataPacket;
@class ORDataSet;

@interface NcdDecoderForPulserSettings : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

@interface NcdDecoderForLogAmpTask : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

@interface NcdDecoderForLinearityTask : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

@interface NcdDecoderForThresholdTask : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

@interface NcdDecoderForCableCheckTask : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

@interface NcdDecoderForStepPDSTask : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

@interface NcdDecoderForPulseChannelsTask : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end
