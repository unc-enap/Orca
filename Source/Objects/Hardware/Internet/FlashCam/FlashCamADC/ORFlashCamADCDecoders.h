//  Orca
//  ORFlashCamADCDecoders.h
//
//  Created by Tom Caldwell on Saturday Feb 13,2021
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORBaseDecoder.h"

@class ORDataPacket;
@class ORDataSet;

@interface ORFlashCamADCWaveformDecoder : ORBaseDecoder {
    @private
}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
- (uint32_t) getChannel:(uint32_t)dataWord;
- (uint32_t) getIndex:(uint32_t)dataWord;
@end

@interface ORFlashCamWaveformDecoder : ORFlashCamADCWaveformDecoder {
    @private
}
- (uint32_t) getChannel:(uint32_t)dataWord;
- (uint32_t) getIndex:(uint32_t)dataWord;
@end
