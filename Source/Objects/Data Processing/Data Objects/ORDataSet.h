//
//  ORDataSet.h
//  Orca
//
//  Created by Mark Howe on Tue Mar 18 2003.
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
@class ORDataPacket;

@interface ORDataSet : OrcaObject {
    NSMutableDictionary*    globalWatchers;
    NSMutableDictionary*    decodedOnceDictionary;
    NSMutableDictionary*    watchingDictionary;
    NSMutableDictionary*    realDictionary;
    NSArray*                sortedArray;
    NSString*               key;		//crate x, card y, etc...
    id                      data;		//data will be nil unless this is a leaf node.	
    uint32_t			totalCounts;
	//NSLock*					dataSetLock;
	uint32_t					runNumber;
    float                   minX,maxX,minY,maxY;
}

#pragma mark •••Initialization
- (id) initWithKey: (NSString*) aKey guardian:(ORDataSet*)aGuardian;
- (void) dealloc;

#pragma mark •••Accessors
- (float) minX;
- (float) maxX;
- (float) minY;
- (float) maxY;
- (void) setMinX:(float)aValue;
- (void) setMaxX:(float)aValue;
- (void) setMinY:(float)aValue;
- (void) setMaxY:(float)aValue;
- (void) registerForWatchers;
- (void) someoneLooking:(NSNotification*) aNote;
- (void) someoneNotLooking:(NSNotification*) aNote;
- (BOOL) isSomeoneLooking:(NSString*)aDataSetKey;
- (void) addGlobalWatcher:(NSNotification*) aNote;
- (void) removeGlobalWatcher:(NSNotification*) aNote;

- (id) findObjectWithFullID:(NSString*)aFullID;
- (NSArray*) collectObjectsOfClass:(Class)aClass;
- (uint32_t) runNumber;
- (void) setRunNumber:(uint32_t)aRunNumber;
- (id) objectForKeyArray:(NSMutableArray*)anArray;
- (ORDataSet*) dataSetWithName:(NSString*)aName;
- (void) setKey:(NSString*)aKey;
- (NSString*) key;
- (NSString*)name; 
- (NSString*) shortName;
- (NSUInteger) count;
- (NSEnumerator*) objectEnumerator;
- (uint32_t) totalCounts;
- (void) setTotalCounts:(uint32_t) newCount;
- (void) incrementTotalCounts;
- (void) incrementTotalCountsBy:(uint32_t) aValue;
- (uint32_t) recountTotal;
- (id) 	 data;
- (void) setData:(id)someData;
- (void) clear;
- (void) clearWithUpdate:(BOOL)update;
- (void) runTaskStopped;
- (void) runTaskBoundary;
- (void) doDoubleClick:(id)sender;
- (NSString*) prependFullName:(NSString*)name;
- (NSArray*) collectObjectsOfClass:(Class)aClass;
- (NSComparisonResult) compare:(NSString *)aString;
- (void) removeAllObjects;
- (void) removeObject:(id)anObj;
- (void) removeObjectForKey: (id) aKey;
- (void) processResponse:(NSDictionary*)aResponse;
- (NSArray*) collectionOfDataSets;
- (id) objectForKey: (id) aKey;

#pragma mark •••Level Info
- (BOOL) leafNode;

#pragma mark •••Data Insertion
- (void) incrementCount:(NSString*)firstArg,...;
- (void) loadHistogram:(uint32_t*)ptr numBins:(uint32_t)numBins withKeyArray:(NSArray*)keyArray;
- (void) loadHistogram2D:(uint32_t*)ptr numBins:(uint32_t)numBins withKeyArray:(NSArray*)keyArray;
- (void) histogram:(uint32_t)aValue numBins:(uint32_t)numBins sender:(id)obj  withKeys:(NSString*)key,...;
- (void) histogramWW:(uint32_t)aValue weight:(uint32_t)aWeight numBins:(uint32_t)numBins sender:(id)obj  withKeys:(NSString*)key,...;
- (void) mergeHistogram:(uint32_t*)ptr numBins:(uint32_t)numBins withKeyArray:(NSArray*)keyArray;
- (void) mergeEnergyHistogram:(uint32_t*)ptr numBins:(uint32_t)numBins   maxBins:(uint32_t)maxBins  firstBin:(uint32_t)firstBin  stepSize:(uint32_t)stepSize   counts:(uint32_t)counts withKeys:(NSString*)firstArg,...;
- (void) histogram2DX:(uint32_t)xValue y:(uint32_t)yValue size:(unsigned short)numBins  sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) loadData2DX:(uint32_t)xValue y:(uint32_t)yValue z:(uint32_t)zValue size:(unsigned short)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) sumData2DX:(uint32_t)xValue y:(uint32_t)yValue z:(uint32_t)zValue size:(unsigned short)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) clearDataUpdate:(BOOL)update withKeys:(NSString*)firstArg,...;
- (void) loadWaveform:(NSData*)aWaveForm offset:(uint32_t)anOffset unitSize:(int)unitSize sender:(id)obj  withKeys:(NSString*)keyArg,...;
- (void) loadWaveform:(NSData*)aWaveForm offset:(uint32_t)anOffset unitSize:(int)aUnitSize mask:(uint32_t)aMask sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) loadWaveform:(NSData*)aWaveForm offset:(uint32_t)anOffset unitSize:(int)aUnitSize startIndex:(uint32_t)aStartIndex scaleOffset:(int32_t)aDataOffset mask:(uint32_t)aMask specialBits:(uint32_t)aSpecialMask bitNames:(NSArray*)bitNames sender:(id)obj withKeys:(NSString*)firstArg,...;
- (void) loadWaveform:(NSData*)aWaveForm offset:(uint32_t)anOffset unitSize:(int)aUnitSize startIndex:(uint32_t)aStartIndex mask:(uint32_t)aMask sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) loadWaveform:(NSData*)aWaveForm offset:(uint32_t)anOffset unitSize:(int)aUnitSize startIndex:(uint32_t)aStartIndex mask:(uint32_t)aMask specialBits:(uint32_t)aSpecialMask bitNames:(NSArray*)someNames sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) loadFFTReal:(NSArray*)realArray imaginary:(NSArray*)imaginaryArray withKeyArray:(NSArray*)keyArray;
- (void) loadGenericData:(NSString*)aString sender:(id)obj withKeys:(NSString*)topLevel,...;
- (void) loadGenericData:(NSString*)aString sender:(id)obj usingKeyArray:(NSArray*)myArgs;
- (void) loadScalerSum:(uint32_t)aValue sender:(id)obj withKeys:(NSString*)firstArg,...;
- (void) loadFFTReal:(NSArray*)realArray imaginary:(NSArray*)imaginaryArray withKeyArray:(NSArray*)keyArray;
- (void) loadTimeSeries:(float)aValue atTime:(uint32_t)aTime sender:(id)obj withKeys:(NSString*)firstArg,...;
- (void) loadSpectrum:(NSData*)aSpectrum  sender:(id)obj  withKeys:(NSString*)firstArg,...;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector;

#pragma mark •••Writing Data
- (void) writeDataToFile:(FILE*)aFile;
- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo keys:(NSMutableArray*)aKeyArray;
- (NSString*) summarizeIntoString:(NSMutableString*)summary;
- (NSString*) summarizeIntoString:(NSMutableString*)summary level:(int)level;

#pragma mark •••Data Source Methods
- (NSUInteger)  numberOfChildren;
- (id)   childAtIndex:(NSUInteger)index;

@end

extern NSString* ORDataSetRemoved;
extern NSString* ORDataSetCleared;
extern NSString* ORDataSetAdded;
extern NSString* ORForceLimitsMinXChanged;
extern NSString* ORForceLimitsMaxXChanged;
extern NSString* ORForceLimitsMaxYChanged;
extern NSString* ORForceLimitsMinYChanged;

