//
//  ORIpeCardDecoder.h
//  Orca
//
//  Created by Mark Howe on 10/18/05.
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
#import "ORIpeCardDecoder.h"

@class ORDataSet;

@interface ORIpeV4FLTDecoderForWaveForm : ORIpeCardDecoder {
	@private 
		BOOL getRatesFromDecodeStage;
		NSMutableDictionary* actualFlts;
}
// Documentation in m-file
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end

@interface ORIpeV4FLTDecoderForEnergy : ORIpeCardDecoder {
	@private 
		BOOL getRatesFromDecodeStage;
		NSMutableDictionary* actualFlts;
}
// Documentation in m-file
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr;
@end

@interface ORIpeV4FLTDecoderForHitRate : ORIpeCardDecoder {
}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)ptr;
@end

@interface ORIpeV4FLTDecoderForHistogram : ORIpeCardDecoder {
}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)ptr;
@end

