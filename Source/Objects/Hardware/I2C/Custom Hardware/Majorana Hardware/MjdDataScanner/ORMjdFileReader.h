//
//  ORMjdFileReader.h
//
//  Created by Mark Howe on 08/4/2015.
//  Copyright 2015 University of North Carolina. All rights reserved.
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------
#import "ORDecoderOperation.h"

@interface ORMjdFileReader : ORDecoderOperation {
	NSMutableData* dataToProcess;
    uint32_t runDataID;
    uint32_t gretina4ID;
    uint32_t gretina4MID;
    uint32_t gretina4AID;
    uint32_t v830ID;
    uint32_t v792ID;
    
	NSMutableDictionary* runInfo;
	BOOL runEnded;
    
    uint32_t gretinaOutOfOrderCount;
    uint32_t gretinaEventsCount;
    uint32_t badGretinaHeaderCount;
    uint32_t badScalerCount;
    uint32_t totalScalerCount;
    uint32_t totalQdcCount;
    uint64_t lastTimeStamp[20][10];
}

- (id)   initWithPath:(NSString*)aPath delegate:(id)aDelegate;
- (void) dealloc;
- (void) processData;
- (void) processRunRecord:(uint32_t*)p;
- (void) processGretina4Record:(uint32_t*)p;
- (void) processGretina4MRecord:(uint32_t*)p;
- (void) processGretina4ARecord:(uint32_t*)p;
- (void) processQDCRecord:(uint32_t*)p;
- (void) processScalerRecord:(uint32_t*)p;
- (void) loadRunInfo:(uint32_t*)p;

@end

@interface NSObject (ORMjdFileReader)
- (void) updateProgress:(NSNumber*)amountDone;
- (BOOL) cancelAndStop;
- (void) setFileToReplay:(NSString*)newFileToReplay;
- (void) sendRunStart:(NSDictionary*)userInfo;
- (void) sendCloseOutRun:(NSDictionary*)userInfo;
- (void) sendRunEnd:(NSDictionary*)userInfo;
- (void) sendRunSubRunStart:(NSDictionary*)userInfo;
@end
