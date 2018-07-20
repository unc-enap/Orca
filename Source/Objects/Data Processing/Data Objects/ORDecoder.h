//
//  ORDecoder.h
//  
//
//  Created by Mark Howe on Sun Nov 15,2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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

@class ORDataSet;

#define kFastLoopupCacheSize 16384

@interface ORDecoder : NSObject {
	NSMutableDictionary* objectLookup;			//table of objects that are taking data.
	id					 fastLookupCache[kFastLoopupCacheSize];
	NSMutableDictionary* fileHeader;
	BOOL                 needToSwap;
    BOOL                 skipRateCounts;
}
+ (NSMutableDictionary*)readHeader:(NSFileHandle*)fp;
+ (id) decoderWithFile:(NSFileHandle*)fp;
+ (NSData*) convertHeaderToData:(NSMutableDictionary*)aHeader;
- (id) initWithHeader:(NSMutableDictionary*)aHeader;
- (void) dealloc;
- (void) setSkipRateCounts:(BOOL)aState;
- (BOOL) skipRateCounts;
- (NSMutableDictionary*) readHeader:(NSFileHandle*)fh;
- (void) setFileHeader:(NSMutableDictionary*) aHeader;
- (NSMutableDictionary*)fileHeader;
- (NSMutableDictionary*) objectLookup;
- (void) setObjectLookup:(NSMutableDictionary*)aDictionary;
- (void) generateObjectLookup;
- (id) objectForKey:(id)key;
- (void) decode:(NSData*)someData intoDataSet:(ORDataSet*)aDataSet;
- (void) decode:(uint32_t*)dPtr length:(int32_t)length intoDataSet:(ORDataSet*)aDataSet;
- (void) byteSwapData:(uint32_t*)dPtr forKey:(NSNumber*)aKey;
- (uint32_t)decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (void) byteSwapOneRecord:(uint32_t*)dPtr forKey:(NSNumber*)aKey;
- (BOOL) legalDataFile: (NSFileHandle*)fp;
- (BOOL) legalData:(NSData*)someData;
- (NSData*) headerAsData;
- (void) loadHeader:(uint32_t*)p;
- (id) headerObject:(NSString*) firstKey,...;
- (BOOL) needToSwap;
- (void) setNeedToSwap:(BOOL)aNeedToSwap;

@end
