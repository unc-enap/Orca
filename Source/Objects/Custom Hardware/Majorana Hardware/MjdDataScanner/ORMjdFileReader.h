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
    unsigned long runDataID;
    unsigned long gretina4ID;
    unsigned long gretina4MID;
    unsigned long gretina4AID;
    unsigned long v830ID;
    unsigned long v792ID;
    
	NSMutableDictionary* runInfo;
	BOOL runEnded;
    
    unsigned long gretinaOutOfOrderCount;
    unsigned long gretinaEventsCount;
    unsigned long badGretinaHeaderCount;
    unsigned long badScalerCount;
    unsigned long totalScalerCount;
    unsigned long totalQdcCount;
    unsigned long long lastTimeStamp[20][10];
}

- (id)   initWithPath:(NSString*)aPath delegate:(id)aDelegate;
- (void) dealloc;
- (void) processData;
- (void) processRunRecord:(unsigned long*)p;
- (void) processGretina4Record:(unsigned long*)p;
- (void) processGretina4MRecord:(unsigned long*)p;
- (void) processGretina4ARecord:(unsigned long*)p;
- (void) processQDCRecord:(unsigned long*)p;
- (void) processScalerRecord:(unsigned long*)p;
- (void) loadRunInfo:(unsigned long*)p;

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
