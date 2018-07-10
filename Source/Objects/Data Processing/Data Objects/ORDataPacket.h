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
		unsigned long        runNumber;				//current run number for this data
		unsigned long        subRunNumber;           //current subrun number for this data
		NSString*            filePrefix;             //name for file prefix (i.e. Run, R_Run, etc..)
		NSMutableArray*  	 dataArray;             //data records
		NSMutableArray*  	 cacheArray;			//data records that are to be cached for later inclusion into data
		BOOL				 dataInCache;
		NSMutableDictionary* fileHeader;
		ORDecoder*			 currentDecoder;
		NSMutableData*		 frameBuffer;			//accumulator for data
		unsigned long		 frameIndex;
		NSRecursiveLock*     theDataLock;
		unsigned long		 reserveIndex;
        unsigned long        reservePool[kMaxReservedPoolSize];
        unsigned long        lastFrameBufferSize;
		BOOL				 dataAvailable;

		int             version;
        BOOL            addedData;
		long			frameCounter;
		long			oldFrameCounter;
}

#pragma mark •••Accessors
- (int)  version;
- (void)  setVersion:(int)aVersion;
- (void) setRunNumber:(unsigned long)aRunNumber;
- (unsigned long)runNumber;
- (void) setSubRunNumber:(unsigned long)aSubRunNumber;
- (unsigned long)subRunNumber;
- (NSMutableDictionary *) fileHeader;
- (void) setFileHeader: (NSMutableDictionary *) aFileHeader;
- (void) makeFileHeader;
- (void) updateHeader;
- (BOOL) addedData;
- (void) setAddedData:(BOOL)flag;
- (unsigned long) frameIndex;
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

- (unsigned long*) getBlockForAddingLongs:(unsigned long)length;
- (unsigned long) addLongsToFrameBuffer:(unsigned long*)someData length:(unsigned long)length;
- (void) replaceReservedDataInFrameBufferAtIndex:(unsigned long)index withLongs:(unsigned long*)data length:(unsigned long)length;
- (unsigned long)reserveSpaceInFrameBuffer:(unsigned long)length;
- (void) removeReservedLongsFromFrameBuffer:(NSRange)aRange;
- (void) clearData;
- (unsigned long) dataCount;

- (void) addEventDescriptionItem:(NSDictionary*) eventDictionary;
- (void) addDataDescriptionItem:(NSDictionary*) dataDictionary forKey:(NSString*)aKey;
- (void) addReadoutDescription:(id) readoutDescription;

@end

