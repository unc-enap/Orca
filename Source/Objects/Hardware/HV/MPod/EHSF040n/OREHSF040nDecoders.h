//
//  OREHSF040nDecoders.h
//  Orca
//
//  Created by Mark Howe on Thursday June 2,2022

#import "ORBaseDecoder.h"

@class ORDataSet;

@interface OREHSF040nDecoderForHV : ORBaseDecoder {
}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end