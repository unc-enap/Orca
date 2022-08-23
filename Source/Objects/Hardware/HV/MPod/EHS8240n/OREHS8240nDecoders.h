//-------------------------------------------------------------------------
//  OREHS8240nDecoder.h
//
//  Created by James Browning on Tuesday Aug 23,2022
//-----------------------------------------------------------
//-------------------------------------------------------------

#import "ORBaseDecoder.h"

@class ORDataSet;

@interface OREHS8240nDecoderForHV : ORBaseDecoder {
}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end
