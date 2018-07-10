//
//  ORXL3Decoders.h
//  Orca
//
//Created by Jarek Kaspar on Sun, September 12, 2010
//Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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

@interface ORXL3DecoderForXL3MegaBundle : ORVmeCardDecoder {
    @private
	BOOL indexerSwaps;
}

- (NSString*) decodePMTBundle:(unsigned long*)aBundle;
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

@interface ORXL3DecoderForCmosRate : ORVmeCardDecoder {
@private
	BOOL indexerSwaps;
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

@interface ORXL3DecoderForFifo : ORVmeCardDecoder {
    @private
	BOOL indexerSwaps;
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

@interface ORXL3DecoderForPmtBaseCurrent : ORVmeCardDecoder {
@private
	BOOL indexerSwaps;
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

@interface ORXL3DecoderForHv : ORVmeCardDecoder {
@private
	BOOL indexerSwaps;
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

@interface ORXL3DecoderForVlt : ORVmeCardDecoder {
@private
	BOOL indexerSwaps;
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

@interface ORXL3DecoderForFecVlt : ORVmeCardDecoder {
@private
	BOOL indexerSwaps;
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end
