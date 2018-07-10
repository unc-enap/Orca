//
//  ORIpeSimulationDecoder.h
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

#import "ORBaseDecoder.h"


@interface ORIpeSimulationDecoderForChannelData : ORBaseDecoder {
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end


