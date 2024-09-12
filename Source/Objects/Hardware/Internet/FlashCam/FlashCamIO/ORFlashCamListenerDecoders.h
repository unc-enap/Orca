//  Orca
//  ORFlashCamListenerDecoders.h
//
//  Created by Tom Caldwell on November 28, 2021
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
#import "ORDataSet.h"

#import "fcio.h"
#import "fsp.h"

#define kMaxFCIOStreams 16
// streams are identifier by the uniqueID of the sending object (FlashCamListenerModel)
// which are counted sequentially starting from 1. If there is ever a use case to have more than
// 15 simulatenous listeners, this needs to be increased accordingly.

@interface ORFlashCamListenerConfigDecoder : ORBaseDecoder {
    @private
}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end

@interface ORFlashCamListenerStatusDecoder : ORBaseDecoder {
    @private
}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end

@interface ORFCIODecoder : ORBaseDecoder {
    @private
    // lookups per uniqueID of the sending Listener
    FCIOData* fcioStreams[kMaxFCIOStreams];
    FSPState* fspStates[kMaxFCIOStreams];
    StreamProcessor* processors[kMaxFCIOStreams];
    NSMutableDictionary* fcCards;
}
- (void) addToObjectList:(NSMutableDictionary*)dict;
- (bool) allocOrUpdate:(void*)someData withSize:(size_t)size andListener: (uint32_t)listener_id;
- (void) dealloc;
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end
