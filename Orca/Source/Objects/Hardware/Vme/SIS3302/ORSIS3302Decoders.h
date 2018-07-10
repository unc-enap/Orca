//
//  ORSIS3302Decoder.h
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



#import "ORVmeCardDecoder.h"

@class ORDataPacket;
@class ORDataSet;

@interface ORSIS3302DecoderForEnergy : ORVmeCardDecoder {
@private 
	BOOL getRatesFromDecodeStage;
	NSMutableDictionary* actualSIS3302Cards;
	//BOOL dumpedOneNormal;
	//BOOL dumpedOneBad[8];
	//int recordCount[8];
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
- (void) filterLengthChanged:(NSNotification*)aNote;
//- (void) dumpRecord:(void*)someData;
@end

@interface ORSIS3302GenericDecoderForWaveform : ORVmeCardDecoder {
    NSMutableDictionary* currentWaveformCache;
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

@interface ORSIS3302DecoderForMca : ORVmeCardDecoder {
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

//**********old...leave in for backward compatiblity
@interface ORSIS3302Decoder : ORVmeCardDecoder {
    @private 
        BOOL getRatesFromDecodeStage;
        NSMutableDictionary* actualSIS3302Cards;
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end


@interface ORSIS3302McaDecoder : ORVmeCardDecoder {
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

@interface ORSIS3302DecoderForLostData : ORVmeCardDecoder {
	unsigned long totalLost[8];
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

