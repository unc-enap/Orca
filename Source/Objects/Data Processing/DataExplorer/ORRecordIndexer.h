//
//  ORRecordIndexer.h
//  OrcaIntel
//
//  Created by Mark Howe on 11/14/2009.
//  Copyright 2009 CENPA, University of North Carolina. All rights reserved.
//
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

#import "ORDecoderOperation.h"

@interface ORRecordIndexer : ORDecoderOperation {
	NSMutableData* dataToProcess;
	NSMutableArray* dataArray;
	int64_t fileOffset;
	NSMutableDictionary* nameCatalog;
	NSMutableArray* array;
	NSData* fileAsData;
}

- (id)   initWithPath:(NSString*)aPath delegate:(id)aDelegate;
- (void) dealloc;
- (NSString*) nameForDataID:(int32_t)anID;
- (NSArray*) decodeDataIntoArray;
- (void) decodeOneRecordAtOffset:(uint32_t)anOffset intoDataSet:(ORDataSet*)aDataSet forKey:(NSNumber*)aKey;
- (void) byteSwapOneRecordAtOffset:(uint32_t)anOffset forKey:(NSNumber*)aKey;
- (NSString*) dataRecordDescription:(uint32_t)anOffset forKey:(NSNumber*)aKey;
- (NSString*) dataRecordDescription:(uint32_t*)ptr;
@end

@interface NSObject (ORFileReader)
- (void) parseEnded;
- (void) updateProgress:(NSNumber*)amountDone;
- (BOOL) cancelAndStop;
- (void) setFileToReplay:(NSString*)newFileToReplay;
- (void) setDataRecords: (NSArray *) aDataRecords;
- (void) setTotalLength:(NSUInteger)aLength;
- (void) setLengthDecoded:(NSUInteger)aLength;
- (void) setHeader:(id)aHeader;
- (void) checkStatus;

@end
