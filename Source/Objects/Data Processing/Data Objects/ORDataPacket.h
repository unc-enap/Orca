//
//  ORDataPacket.h
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files

#pragma mark •••Forward Declarations
@class ORDataSet;

#define kMaxReservedPoolSize 2045
#define kFastLoopupCacheSize 16384

@interface ORDataPacket : NSObject {
    @private
		uint32_t        runNumber;				//current run number for this data
		uint32_t        subRunNumber;           //current subrun number for this data
		NSString*            filePrefix;             //name for file prefix (i.e. Run, R_Run, etc..)
		NSMutableArray*  	 dataArray;             //data records
		NSMutableArray*  	 cacheArray;			//data records that are to be cached for later inclusion into data
		BOOL				 dataInCache;
		NSMutableDictionary* fileHeader;
		ORDecoder*			 currentDecoder;
		NSMutableData*		 frameBuffer;			//accumulator for data
		uint32_t		 frameIndex;
		NSRecursiveLock*     theDataLock;
		uint32_t		 reserveIndex;
        uint32_t        reservePool[kMaxReservedPoolSize];
        uint32_t        lastFrameBufferSize;
		BOOL				 dataAvailable;

		int             version;
        BOOL            addedData;
		int32_t			frameCounter;
		int32_t			oldFrameCounter;
}

#pragma mark •••Accessors
- (int)  version;
- (void)  setVersion:(int)aVersion;
- (void) setRunNumber:(uint32_t)aRunNumber;
- (uint32_t)runNumber;
- (void) setSubRunNumber:(uint32_t)aSubRunNumber;
- (uint32_t)subRunNumber;
- (NSMutableDictionary *) fileHeader;
- (void) setFileHeader: (NSMutableDictionary *) aFileHeader;
- (void) makeFileHeader;
- (void) updateHeader;
- (BOOL) addedData;
- (void) setAddedData:(BOOL)flag;
- (uint32_t) frameIndex;
- (NSMutableArray*)  dataArray;
- (void) setDataArray:(NSMutableArray*)someData;
- (NSMutableArray*) cacheArray;
- (void) setCacheArray:(NSMutableArray*)newCacheArray;
- (NSString*)filePrefix;
- (void)setFilePrefix:(NSString*)aFilePrefix;
- (NSMutableData*)  frameBuffer;
- (void) setFrameBuffer:(NSMutableData*)someData;

- (void) startFrameTimer;
- (void) stopFrameTimer;
- (void) forceFrameLoad;
- (void) addCachedData;
- (void) addDataToCach:(NSData*)someData;
- (void) addArrayToCache:(NSArray*)aDataArray;

- (void) addFrameBuffer:(BOOL)forceAdd;
- (void) addData:(NSData*)someData;
- (void) addDataFromArray:(NSArray*)aDataArray;

- (uint32_t*) getBlockForAddingLongs:(uint32_t)length;
- (uint32_t) addLongsToFrameBuffer:(uint32_t*)someData length:(uint32_t)length;
- (void) replaceReservedDataInFrameBufferAtIndex:(uint32_t)index withLongs:(uint32_t*)data length:(uint32_t)length;
- (uint32_t)reserveSpaceInFrameBuffer:(uint32_t)length;
- (void) removeReservedLongsFromFrameBuffer:(NSRange)aRange;
- (void) clearData;
- (uint32_t) dataCount;

- (void) addEventDescriptionItem:(NSDictionary*) eventDictionary;
- (void) addDataDescriptionItem:(NSDictionary*) dataDictionary forKey:(NSString*)aKey;
- (void) addReadoutDescription:(id) readoutDescription;

@end

