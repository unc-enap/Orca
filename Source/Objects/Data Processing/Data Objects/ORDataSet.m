//
//  ORDataSet.m
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
#import "ORDataSet.h"
#import "OR1DHisto.h"
#import "OR2DHisto.h"
#import "ORPlotFFT.h"
#import "ORWaveform.h"
#import "ORMaskedWaveform.h"
#import "ORGenericData.h"
#import "ORScalerSum.h"
#import "ORDataPacket.h"
#import "ORCARootServiceDefs.h"
#import "ORPlotTimeSeries.h"

NSString* ORDataSetRemoved= @"ORDataSetRemoved";
NSString* ORDataSetCleared= @"ORDataSetCleared";
NSString* ORDataSetAdded  = @"ORDataSetAdded";
NSString* ORForceLimitsMinXChanged = @"ORForceLimitsMinXChanged";
NSString* ORForceLimitsMaxXChanged = @"ORForceLimitsMaxXChanged";
NSString* ORForceLimitsMinYChanged = @"ORForceLimitsMinYChanged";
NSString* ORForceLimitsMaxYChanged = @"ORForceLimitsMaxYChanged";

@implementation ORDataSet

#pragma mark •••Initialization
- (id) initWithKey: (NSString*) aKey guardian:(ORDataSet*)aGuardian
{
    self = [super init];
    if (self != nil) {
        globalWatchers = nil;
        realDictionary = [[NSMutableDictionary alloc] initWithCapacity: 32];
        [self setKey:aKey];
        [self setGuardian:aGuardian]; //we don't retain the guardian, so just set it here.
        data = nil;
//		dataSetLock = [[NSLock alloc] init];
		RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h 
	}
    return self;
}

- (void) dealloc
{
	@synchronized(self){  
		
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self];
		[nc postNotificationName:ORDataSetRemoved object:self userInfo: nil];
		
        if(data!=nil){
            NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
            [userInfo setObject:[NSArray arrayWithObject:data] forKey: ORGroupObjectList];
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:ORGroupObjectsRemoved
                                                                object:self
                                                              userInfo: userInfo];
  
        }
        
		[realDictionary release];
		realDictionary = nil;
		
		[key release];
		[data release];
		
		[sortedArray release];
		sortedArray = nil;
        [watchingDictionary release];
        [globalWatchers release];
        [decodedOnceDictionary release];
	}
    [super dealloc];
}

- (void) registerForWatchers
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];//just in case
    [nc addObserver:self selector:@selector(someoneLooking:)      name:@"DecoderWatching"    object:nil];
    [nc addObserver:self selector:@selector(someoneNotLooking:)   name:@"DecoderNotWatching" object:nil];
    [nc addObserver:self selector:@selector(removeGlobalWatcher:) name:@"DoneWithFullDecode" object:nil];
    [nc addObserver:self selector:@selector(addGlobalWatcher:)    name:@"NeedFullDecode"     object:nil];
}

//individual decoders can use the watchers to limit the amount of decoding of big data records, i.e. waveforms
- (void) someoneLooking:(NSNotification*) aNote
{
    if(!watchingDictionary)watchingDictionary = [[NSMutableDictionary dictionary]retain];
    if([aNote object]){
        id watcherKey   = [[aNote userInfo] objectForKey:@"DataSetKey"];
        if(watcherKey!=nil){
            int watcherRetainCount = [[watchingDictionary objectForKey:watcherKey]intValue];
            watcherRetainCount++;
            [watchingDictionary setObject:[NSNumber numberWithInt:watcherRetainCount] forKey:watcherKey];
        }
    }
}

- (void) someoneNotLooking:(NSNotification*) aNote
{
    id watcherKey   = [[aNote userInfo] objectForKey:@"DataSetKey"];
    if(watcherKey!=nil){
        int watcherRetainCount = [[watchingDictionary objectForKey:watcherKey]intValue];
        watcherRetainCount--;
        if(watcherRetainCount<=0)[watchingDictionary removeObjectForKey:watcherKey];
        else [watchingDictionary setObject:[NSNumber numberWithInt:watcherRetainCount] forKey:watcherKey];
    }
}
- (void) addGlobalWatcher:(NSNotification*) aNote
{
    if(!globalWatchers)globalWatchers = [[NSMutableDictionary dictionary]retain];
    if([aNote object]){
        id watcherKey   = [NSNumber numberWithLong:(uint32_t)[aNote object]];
        if(watcherKey!=nil){
            [globalWatchers setObject:watcherKey forKey:watcherKey]; //just care if an entry exists
        }
    }
}
- (void) removeGlobalWatcher:(NSNotification*) aNote
{
    if([aNote object]){
        id watcherKey   = [NSNumber numberWithLong:(uint32_t)[aNote object]];
        [globalWatchers removeObjectForKey:watcherKey]; //just care if an entry exists
    }
    if([globalWatchers count]==0){
        [globalWatchers release];
        globalWatchers = nil;
    }
}
- (BOOL) isSomeoneLooking:(NSString*)aDataSetKey
{
    if(!decodedOnceDictionary){
        decodedOnceDictionary = [[NSMutableDictionary dictionary]retain];
    }
    BOOL decodedAtLeastOnce = YES;
    if(![decodedOnceDictionary objectForKey:aDataSetKey]){
        [decodedOnceDictionary setObject:[NSNull null] forKey:aDataSetKey];
        decodedAtLeastOnce = NO;
    }
    return !decodedAtLeastOnce || [globalWatchers count] || [watchingDictionary objectForKey:aDataSetKey]!=nil;
}

- (id) findObjectWithFullID:(NSString*)aFullID;
{
    if([self leafNode]){
		return [data findObjectWithFullID:aFullID];
	}
    else {
        NSArray* theKeys = [realDictionary allKeys];
        for(id akey in theKeys){
			id anObj = [realDictionary objectForKey:akey];
			id theResult = [anObj findObjectWithFullID:aFullID];
			if(theResult) return theResult;
        }
        return nil;
    }
}

- (void) removeAllObjects
{
    [realDictionary removeAllObjects];
}

- (void) makeMainController
{
    [self linkToController:@"ORDataSetController"];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if([self leafNode]){
        [[self data] appendDataDescription:aDataPacket userInfo:userInfo];
    }
    else {
        NSEnumerator* e = [realDictionary  objectEnumerator];
        ORDataSet* d;
        while(d = [e nextObject]){
            [d appendDataDescription:aDataPacket userInfo:userInfo];
        }
    }
}

- (ORDataSet*) dataSetWithName:(NSString*)aName
{
    ORDataSet* result = nil;
    if([self leafNode]){
        if([[[self data] shortName] isEqualToString:aName])result = [self data];
    }
    else {
        NSEnumerator* e = [realDictionary  objectEnumerator];
        ORDataSet* d;
        while(d = [e nextObject]){
            result = [d dataSetWithName:aName];
            if(result)return result;
        }
    }
    return result;
}

- (uint32_t) runNumber
{
	return runNumber;
}

- (void) setRunNumber:(uint32_t)aRunNumber
{
	runNumber = aRunNumber;
}

- (void) runTaskBoundary
{
    NSEnumerator* e = [realDictionary  objectEnumerator];
    ORDataSet* d;
    while(d = [e nextObject]){
        [d runTaskBoundary];
    }
    [data runTaskBoundary];
}


- (void) runTaskStopped
{
    //totalCounts = 0;
    NSEnumerator* e = [realDictionary  objectEnumerator];
    ORDataSet* d;
    while(d = [e nextObject]){
        [d runTaskStopped];
    }
    [data runTaskStopped];
}

- (void) clearWithUpdate:(BOOL)update
{
    totalCounts = 0;
    NSEnumerator* e = [realDictionary  objectEnumerator];
    ORDataSet* d;
    while(d = [e nextObject]){
        [d clear];
    }
    
    [data clear];
	if(update){
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:ORDataSetCleared
		 object:self
		 userInfo: nil];
	}
}

- (void) clear
{
    totalCounts = 0;
    NSEnumerator* e = [realDictionary  objectEnumerator];
    ORDataSet* d;
    while(d = [e nextObject]){
        [d clear];
    }
    
    [data clear];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDataSetCleared
	 object:self
	 userInfo: nil];
    
    
}

- (uint32_t) recountTotal
{
    if(data != nil)return totalCounts;
    else totalCounts = 0;
    NSEnumerator* e = [realDictionary  objectEnumerator];
    ORDataSet* d;
    while(d = [e nextObject]){
        totalCounts += [d recountTotal];
    }
    return totalCounts;
}

- (uint32_t) totalCounts
{
    return totalCounts;
}

- (void) setTotalCounts:(uint32_t) newCount
{
    totalCounts = newCount;
}

- (void) incrementTotalCounts
{
	++totalCounts;
}

- (void) incrementTotalCountsBy:(uint32_t) aValue
{
	totalCounts += aValue;
}


- (id) objectForKeyArray:(NSMutableArray*)anArray
{
	if([anArray count] == 0)return data;
	else {
		id aKey = [anArray objectAtIndex:0];
		[anArray removeObjectAtIndex:0];
		return [[realDictionary objectForKey:aKey] objectForKeyArray:anArray];;
    }
}

- (float) minX { return minX;}
- (float) maxX { return maxX;}
- (float) minY { return minY;}
- (float) maxY { return maxY;}
- (void) setMinX:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMinX:minX];
    minX = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceLimitsMinXChanged object:self];
}

- (void) setMaxX:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxX:maxX];
    maxX = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceLimitsMaxXChanged object:self];
}

- (void) setMinY:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMinY:minY];
    minY = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceLimitsMinYChanged object:self];
}

- (void) setMaxY:(float)aValue{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxY:maxY];
    maxY = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceLimitsMaxYChanged object:self];
}


#pragma mark •••Writing Data
- (void) writeDataToFile:(FILE*)aFile
{
    if(data){
        if([data respondsToSelector:@selector(writeDataToFile:)]){
            [data writeDataToFile:aFile];
        }
    }
    else {
        NSEnumerator* e = [realDictionary objectEnumerator];
        id obj;
        while(obj = [e nextObject]){
            [obj writeDataToFile:aFile];
        }
    }
}

- (NSArray*) collectObjectsOfClass:(Class)aClass
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
    
    NSEnumerator* e  = [realDictionary keyEnumerator];
    id aKey;
    id objectData;
    while(aKey = [e nextObject]){
        objectData = [(ORDataSet*)[realDictionary objectForKey:aKey] data];
        if(objectData)[collection addObjectsFromArray:[objectData collectObjectsOfClass:aClass]];
        else [collection addObjectsFromArray:[[realDictionary objectForKey:aKey] collectObjectsOfClass:aClass]];
    }	
    return collection;
}

- (NSArray*) collectionOfDataSets
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
	[collection addObject:self];
	if(data) [collection addObject:data]; //leaf node
	else {
		NSEnumerator* e  = [realDictionary keyEnumerator];
		id aKey;
		while(aKey = [e nextObject]){
			[collection addObjectsFromArray:[[realDictionary objectForKey:aKey] collectionOfDataSets]];
		}	
	}
	return collection;
}


#pragma mark •••Primative NSDictionary Methods

- (NSUInteger) count
{
    return [realDictionary count];
}

- (NSEnumerator *) keyEnumerator
{
    return [realDictionary keyEnumerator];
}

- (id) objectForKey: (id) aKey
{
    return  [realDictionary objectForKey: aKey];
}

- (void) removeObject:(id)anObj
{
	@synchronized(self){  
		NSEnumerator* e = [realDictionary keyEnumerator];
		id aKey;
		NSMutableArray* keysToRemoveFromSelf = [NSMutableArray array];
		while(aKey = [e nextObject]){
			ORDataSet* aDataSet = [realDictionary objectForKey:aKey];
			if(aDataSet == anObj){
				[keysToRemoveFromSelf addObject:aKey];
			}
			else {
				[[realDictionary objectForKey:aKey] removeObject:anObj];
			}
		}
		[realDictionary removeObjectsForKeys: keysToRemoveFromSelf];
		[sortedArray release];
		sortedArray = [[realDictionary keysSortedByValueUsingSelector:@selector(compare:)] retain];
	}
	
}

- (void) removeObjectForKey: (id) aKey;
{
	@synchronized(self){  
		
		[realDictionary removeObjectForKey: aKey];
		[sortedArray release];
		sortedArray = [[realDictionary keysSortedByValueUsingSelector:@selector(compare:)] retain];
	}
}

- (void) setObject: (id) anObject forKey: (id) aKey;
{
	@synchronized(self){  
		
		//   BOOL newObj = NO;
		//    if(![realDictionary objectForKey:aKey])newObj = YES;
		
		[realDictionary setObject: anObject  forKey: aKey];
		[sortedArray release];
		sortedArray = [[realDictionary keysSortedByValueUsingSelector:@selector(compare:)] retain];
	}
	
}

- (NSComparisonResult) compare:(NSString *)aString
{
    return [aString compare:[self name]];
}

#pragma mark •••Accessors
- (NSString*) shortName
{
    if([self leafNode])return [data shortName];
    else return key;
}

- (NSString*) key
{
    if([self leafNode])return [data key];
    else return key;
}

- (NSString*) name
{
    if([self leafNode])return [data name];
    else return [NSString stringWithFormat:@"%@   count: %u",key,totalCounts];
}

- (void) setKey:(NSString*)aKey
{
    [key autorelease];
    key = [aKey copy];
}

- (id) data
{
	id d = nil;
	@synchronized(self){  
		d = [[data retain] autorelease];
	}
    return d;
}


- (void) setData:(id)someData
{	
	@synchronized(self){  
		
		[someData retain];
		[data release];
		data = someData;
	}
	
}



- (NSString*) prependFullName:(NSString*)aName
{
    if(guardian == nil)return aName;
    return [guardian prependFullName:[key stringByAppendingFormat:@",%@",aName]];
}


- (NSEnumerator*) objectEnumerator
{
    return [realDictionary objectEnumerator];
}

#pragma mark •••Level Info
- (BOOL) leafNode
{
    return data != nil;
}


- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    NSEnumerator* e = [realDictionary keyEnumerator];
    NSString* aKey;
    while(aKey = [e nextObject]){
        ORDataSet* ds = [realDictionary objectForKey:aKey];
        [ds packageData:aDataPacket userInfo:userInfo keys:[NSMutableArray arrayWithObject:aKey]];
    }
}

- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo keys:(NSMutableArray*)aKeyArray
{
    if([self leafNode]){
        [[self data] packageData:aDataPacket userInfo:userInfo keys:aKeyArray];
    }
    else {
        NSEnumerator* e = [realDictionary keyEnumerator];
        NSString* aKey;
        while(aKey = [e nextObject]){
            ORDataSet* ds = [realDictionary objectForKey:aKey];
            [aKeyArray addObject:aKey];
            [ds packageData:aDataPacket userInfo:userInfo keys:aKeyArray];
            [aKeyArray removeObject:aKey];
        }
    }
}

- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
	
    if([self leafNode]){
        [collection addObjectsFromArray:[[self data] collectObjectsRespondingTo:aSelector]];
    }
    else {
        NSEnumerator* e = [realDictionary keyEnumerator];
        NSString* aKey;
        while(aKey = [e nextObject]){
            ORDataSet* ds = [realDictionary objectForKey:aKey];
            [collection addObjectsFromArray:[ds collectObjectsRespondingTo:aSelector]];
        }
    }
    return collection;
    
}

#pragma mark •••Data Insertion
- (void)loadHistogram:(uint32_t*)ptr numBins:(uint32_t)numBins withKeyArray:(NSArray*)keyArray
{
	@synchronized(self){  
		NSUInteger n = [keyArray count];
		int i;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		for(i=0;i<n;i++){
			NSString* s = [keyArray objectAtIndex:i];
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
		}
		
		OR1DHisto* histo = [nextLevel data];
		if(!histo){
			histo = [[OR1DHisto alloc] init];
			[histo setKey:[nextLevel key]];
			[histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[histo setNumberBins:numBins];
			[nextLevel setData:histo];
			[histo setDataSet:self];
			[histo mergeHistogram:ptr numValues:numBins];
			[histo release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		else [histo mergeHistogram:ptr numValues:numBins];
	}
}



- (void) histogram:(uint32_t)aValue numBins:(uint32_t)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		
		OR1DHisto* histo = [nextLevel data];
		if(!histo){
			histo = [[OR1DHisto alloc] init];
			[histo setKey:[nextLevel key]];
			[histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[histo setNumberBins:numBins];
			[histo setDataSet:self];
			[nextLevel setData:histo];
			[histo histogram:aValue];
			[histo release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		else if([histo numberBins] != numBins) {
			[histo setNumberBins:numBins];
			[histo histogram:aValue];
		}
		else [histo histogram:aValue];
		
		va_end(myArgs);
    }
}

// ak 6.8.07 
- (void) histogramWW:(uint32_t)aValue weight:(uint32_t)aWeight numBins:(uint32_t)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		
		OR1DHisto* histo = [nextLevel data];
		if(!histo){
			histo = [[OR1DHisto alloc] init];
			[histo setKey:[nextLevel key]];
			[histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[histo setNumberBins:numBins];
			[histo setDataSet:self];
			[nextLevel setData:histo];
			[histo histogramWW:aValue weight:aWeight];
			[histo release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		else [histo histogramWW:aValue weight:aWeight];
		
		va_end(myArgs);
	}   
}

//! merger for hw histograms -tb- 2008-03-23
- (void) mergeHistogram:(uint32_t*)ptr numBins:(uint32_t)numBins withKeyArray:(NSArray*)keyArray
{
	@synchronized(self){  
		
		NSUInteger n = [keyArray count];
		int i;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		for(i=0;i<n;i++){
			NSString* s = [keyArray objectAtIndex:i];
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
		}
		
		OR1DHisto* histo = [nextLevel data];
		if(!histo){
			histo = [[OR1DHisto alloc] init];
			[histo setKey:[nextLevel key]];
			[histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[histo setNumberBins:numBins];
			[nextLevel setData:histo];
			[histo setDataSet:self];
			[histo mergeHistogram:ptr numValues:numBins];
			[histo release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		else [histo mergeHistogram:ptr numValues:numBins];
	}
}



/** Merger for hw histograms with offset, stepsize and sum -tb- 2008-08-05.
 *
 * Fills the histogram beginning from firstBin, every 'stepSize'-th entry will be 
 * filled (firstBin, firstBin+stepSize,firstBin+2*stepSize, ...).
 */
- (void) mergeEnergyHistogram:(uint32_t*)ptr numBins:(uint32_t)numBins   maxBins:(uint32_t)maxBins  firstBin:(uint32_t)firstBin  stepSize:(uint32_t)stepSize   counts:(uint32_t)counts withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCountsBy: counts];
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCountsBy: counts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		OR1DHisto* histo = [nextLevel data];
		if(!histo){
			histo = [[OR1DHisto alloc] init];
			[histo setKey:[nextLevel key]];
			[histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[histo setNumberBins:maxBins];
			[nextLevel setData:histo];
			[histo setDataSet:self];
			//--> [histo mergeHistogram:ptr numValues:numBins];
			[histo mergeEnergyHistogram:ptr numBins:numBins    maxBins:maxBins
							   firstBin:firstBin  stepSize:stepSize 
								 counts:counts];
			
			[histo release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		else //[histo mergeHistogram:ptr numValues:numBins];
			[histo mergeEnergyHistogram:ptr numBins:numBins maxBins:maxBins
							   firstBin:firstBin   stepSize:stepSize 
								 counts:counts];
	}
}



- (void) histogram2DX:(uint32_t)xValue y:(uint32_t)yValue size:(unsigned short)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		
		OR2DHisto* histo = [nextLevel data];
		if(!histo){
			histo = [[OR2DHisto alloc] init];
			[histo setKey:[nextLevel key]];
			[histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[histo setNumberBinsPerSide:numBins];
			[nextLevel setData:histo];
			[histo setDataSet:self];
			[histo histogramX:xValue y:yValue];  
			[histo release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		
		else [histo histogramX:xValue y:yValue];
		
		va_end(myArgs);
    }
}


- (void)loadHistogram2D:(uint32_t*)ptr numBins:(uint32_t)numBins withKeyArray:(NSArray*)keyArray
{
	@synchronized(self){  
		
		NSUInteger n = [keyArray count];
		int i;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		for(i=0;i<n;i++){
			NSString* s = [keyArray objectAtIndex:i];
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
		}
		
		OR2DHisto* histo = [nextLevel data];
		if(!histo){
			histo = [[OR2DHisto alloc] init];
			[histo setKey:[nextLevel key]];
			[histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[histo setNumberBinsPerSide:(unsigned int)pow((float)numBins,.5)];
			[nextLevel setData:histo];
			[histo setDataSet:self];
			[histo mergeHistogram:ptr numValues:numBins];
			[histo release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		else [histo mergeHistogram:ptr numValues:numBins];
	}
}

- (void) loadData2DX:(uint32_t)xValue y:(uint32_t)yValue z:(uint32_t)zValue size:(unsigned short)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		
		OR2DHisto* histo = [nextLevel data];
		if(!histo){
			histo = [[OR2DHisto alloc] init];
			[histo setKey:[nextLevel key]];
			[histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[histo setNumberBinsPerSide:numBins];
			[nextLevel setData:histo];
			[histo setDataSet:self];
			[histo loadX:xValue y:yValue z:zValue];  
			[histo release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		
		else {
			[histo loadX:xValue y:yValue z:zValue];
		}
		va_end(myArgs);
	}
}



- (void) sumData2DX:(uint32_t)xValue y:(uint32_t)yValue z:(uint32_t)zValue size:(unsigned short)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		
		OR2DHisto* histo = [nextLevel data];
		if(!histo){
			histo = [[OR2DHisto alloc] init];
			[histo setKey:[nextLevel key]];
			[histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[histo setNumberBinsPerSide:numBins];
			[nextLevel setData:histo];
			[histo setDataSet:self];
			[histo sumX:xValue y:yValue z:zValue];  
			[histo release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		
		else {
			[histo sumX:xValue y:yValue z:zValue];
		}
		va_end(myArgs);
    }
}

- (void) clearDataUpdate:(BOOL)update withKeys:(NSString*)firstArg,...
{
 	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		[nextLevel clearWithUpdate:update];
		
		va_end(myArgs);
    }
}

- (void) loadWaveform:(NSData*)aWaveForm offset:(uint32_t)anOffset unitSize:(int)aUnitSize sender:(id)obj  withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
        ORWaveform* waveform = [nextLevel data];
        if(aWaveForm){
            if(!waveform){
                waveform = [[ORWaveform alloc] init];
                [waveform setDataSet:self];
                [waveform setDataOffset:anOffset];
                [waveform setKey:[nextLevel key]];
                [waveform setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
                [waveform setUnitSize:aUnitSize];
                [nextLevel setData:waveform];
                [waveform setWaveform:aWaveForm]; //increments the count
                [waveform release];
                [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
            }
            
            else {
                [waveform setDataOffset:anOffset];
                [waveform setUnitSize:aUnitSize];            
                [waveform setWaveform:aWaveForm];
            }
        }
        else {
            [waveform incrementTotalCounts]; //count only
        }
		va_end(myArgs);
	}   
}

- (void) loadSpectrum:(NSData*)aSpectrum  sender:(id)obj  withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		[[aSpectrum retain] autorelease];
		OR1DHisto* histo = [nextLevel data];
		if(!histo){
			histo = [[OR1DHisto alloc] init];
			[histo setKey:[nextLevel key]];
			[histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[histo setDataSet:self];
			[histo setNumberBins:(uint32_t)[aSpectrum length]/4];
			[nextLevel setData:histo];
			[histo loadData:aSpectrum];
			[histo release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		else [histo loadData:aSpectrum];
		
		va_end(myArgs);
	}	
}


- (void) incrementCount:(NSString*)firstArg,...
{
    //an optimization.... some times a decoder may choose increment the count but not do a full decode. 
    va_list myArgs;
    va_start(myArgs,firstArg);
    
    NSString* s             = firstArg;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    [currentLevel incrementTotalCounts];
    
    do {
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        [currentLevel incrementTotalCounts];
        
    } while((s = va_arg(myArgs, NSString *)));
    
    va_end(myArgs);
    
}


- (void) loadWaveform:(NSData*)aWaveForm offset:(uint32_t)anOffset unitSize:(int)aUnitSize mask:(uint32_t)aMask sender:(id)obj  withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		ORMaskedWaveform* waveform = [nextLevel data];
		if(!waveform){
			waveform = [[ORMaskedWaveform alloc] init];
			[waveform setDataSet:self];
			[waveform setMask:aMask];
			[waveform setDataOffset:anOffset];
			[waveform setKey:[nextLevel key]];
			[waveform setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[waveform setUnitSize:aUnitSize];
			[nextLevel setData:waveform];
			[waveform setWaveform:aWaveForm];       
			[waveform release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		else {
			[waveform setWaveform:aWaveForm];
		}
		va_end(myArgs);
    }
}



- (void) loadWaveform:(NSData*)aWaveForm offset:(uint32_t)anOffset unitSize:(int)aUnitSize startIndex:(uint32_t)aStartIndex mask:(uint32_t)aMask sender:(id)obj  withKeys:(NSString*)firstArg,...
{
    //if aWaveForm == nil then only increment the counts without displaying the waveform
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		ORMaskedIndexedWaveform* waveform = [nextLevel data];
		if(!waveform){
			waveform = [[ORMaskedIndexedWaveform alloc] init];
			[waveform setDataSet:self];
			[waveform setMask:aMask];
			[waveform setStartIndex:aStartIndex];
			[waveform setDataOffset:anOffset];
			[waveform setKey:[nextLevel key]];
			[waveform setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[waveform setUnitSize:aUnitSize];
			[nextLevel setData:waveform];
			[waveform setWaveform:aWaveForm];       
			[waveform release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		
		else {
			[waveform setMask:aMask];
			[waveform setStartIndex:aStartIndex];
			[waveform setWaveform:aWaveForm];
		}
		va_end(myArgs);
	}
}
- (void) loadWaveform:(NSData*)aWaveForm
               offset:(uint32_t)anOffset
             unitSize:(int)aUnitSize
           startIndex:(uint32_t)aStartIndex
                 mask:(uint32_t)aMask
          specialBits:(uint32_t)aSpecialMask
             bitNames:(NSArray*)bitNames
               sender:(id)obj
             withKeys:(NSString*)firstArg,...
{
    @synchronized(self){
        va_list myArgs;
        va_start(myArgs,firstArg);
        
        NSString* s             = firstArg;
        ORDataSet* currentLevel = self;
        ORDataSet* nextLevel    = nil;
        [currentLevel incrementTotalCounts];
        
        
        do {
            nextLevel = [currentLevel objectForKey:s];
            if(nextLevel){
                if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
                currentLevel = nextLevel;
            }
            else {
                nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
                [currentLevel setObject:nextLevel forKey:s];
                currentLevel = nextLevel;
                [nextLevel release];
            }
            [currentLevel incrementTotalCounts];
            
        } while((s = va_arg(myArgs, NSString *)));
        
        ORMaskedIndexedWaveformWithSpecialBits* waveform = [nextLevel data];
        if(!waveform){
            waveform = [[ORMaskedIndexedWaveformWithSpecialBits alloc] init];
            [waveform setDataSet:self];
            [waveform setMask:aMask];
            [waveform setScaleOffset:0];
            [waveform setSpecialBitMask:aSpecialMask];
            [waveform setBitNames:bitNames];
            [waveform setStartIndex:aStartIndex];
            [waveform setDataOffset:anOffset];
            [waveform setKey:[nextLevel key]];
            [waveform setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
            [waveform setUnitSize:aUnitSize];
            [nextLevel setData:waveform];
            [waveform setWaveform:aWaveForm];
            [waveform release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
        }
        
        else {
            [waveform setMask:aMask];
            [waveform setSpecialBitMask:aSpecialMask];
            [waveform setBitNames:bitNames];
            [waveform setStartIndex:aStartIndex];
            [waveform setWaveform:aWaveForm];
        }
        va_end(myArgs);
    }
}

- (void) loadWaveform:(NSData*)aWaveForm 
			   offset:(uint32_t)anOffset 
			 unitSize:(int)aUnitSize 
		   startIndex:(uint32_t)aStartIndex
          scaleOffset:(int32_t)aScaleOffset
				 mask:(uint32_t)aMask 
		  specialBits:(uint32_t)aSpecialMask
			 bitNames:(NSArray*)bitNames
			   sender:(id)obj  
			 withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		ORMaskedIndexedWaveformWithSpecialBits* waveform = [nextLevel data];
        if(aWaveForm){
            if(!waveform){
                waveform = [[ORMaskedIndexedWaveformWithSpecialBits alloc] init];
                [waveform setDataSet:self];
                [waveform setMask:aMask];
                [waveform setScaleOffset:aScaleOffset];
                [waveform setSpecialBitMask:aSpecialMask];
                [waveform setBitNames:bitNames];
                [waveform setStartIndex:aStartIndex];
                [waveform setDataOffset:anOffset];
                [waveform setKey:[nextLevel key]];
                [waveform setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
                [waveform setUnitSize:aUnitSize];
                [nextLevel setData:waveform];
                [waveform setWaveform:aWaveForm];       
                [waveform release];
                [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
            }
            
            else {
                [waveform setMask:aMask];
                [waveform setSpecialBitMask:aSpecialMask];
                [waveform setBitNames:bitNames];
                [waveform setStartIndex:aStartIndex];
                [waveform setWaveform:aWaveForm];
            }
        }
        else {
            [waveform incrementTotalCounts]; //count only
        }

		va_end(myArgs);
	}
}



- (void) loadGenericData:(NSString*)aString sender:(id)obj withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		
		[currentLevel incrementTotalCounts];
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		ORGenericData* genericData = [nextLevel data];
		if(!genericData){
			genericData = [[ORGenericData alloc] init];
			[genericData setKey:[nextLevel key]];
			[nextLevel setData:genericData];
			[genericData setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];

			[genericData release];

            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		
		[genericData setGenericData:aString];
		
		
		va_end(myArgs);
	}
}




//exists only as a alternate calling method. i.e. used by NSLogError.
- (void) loadGenericData:(NSString*)aString sender:(id)obj usingKeyArray:(NSArray*)myArgs
{
	@synchronized(self){  
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel = nil;
		[currentLevel incrementTotalCounts];
		NSEnumerator* e = [myArgs objectEnumerator];
		if(myArgs){
			id s;
			while(s = [e nextObject]) {
				nextLevel = [currentLevel objectForKey:s];
				if(nextLevel == nil){
					nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
					[currentLevel setObject:nextLevel forKey:s];
					currentLevel = nextLevel;
					[nextLevel release];
				}
				else {
					if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
					currentLevel = nextLevel;
				}
				[currentLevel incrementTotalCounts];
				
			}
		}
		else nextLevel = self;
		ORGenericData* genericData = [nextLevel data];
		if(!genericData){
			genericData = [[ORGenericData alloc] init];
			[genericData setKey:[nextLevel key]];
			[nextLevel setData:genericData];
			[genericData setGenericData:aString];
			[genericData release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		
		else [genericData setGenericData:aString];
	}
}

- (void) loadScalerSum:(uint32_t)aValue sender:(id)obj withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			
		} while((s = va_arg(myArgs, NSString *)));
		
		ORScalerSum* scalerSumData = [nextLevel data];
		if(!scalerSumData){
			scalerSumData = [[ORScalerSum alloc] init];
			[scalerSumData setKey:[nextLevel key]];
			[nextLevel setData:scalerSumData];
			[scalerSumData release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		
		[scalerSumData loadScalerValue:aValue];
		
		va_end(myArgs);
	}
}

- (void) loadTimeSeries:(float)aValue atTime:(uint32_t)aTime sender:(id)obj withKeys:(NSString*)firstArg,...
{
	@synchronized(self){  
		va_list myArgs;
		va_start(myArgs,firstArg);
		
		NSString* s             = firstArg;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts]; // was missing -tb- 2008-02-07
		
		do {
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
			
		} while((s = va_arg(myArgs, NSString *)));
		
		ORPlotTimeSeries* timeSeries = [nextLevel data];
		if(!timeSeries){
			timeSeries = [[ORPlotTimeSeries alloc] init];
			[timeSeries setKey:[nextLevel key]];
			[timeSeries setDataSet:self]; // was missing -tb- 2008-02-07
			[nextLevel setData:timeSeries];
			[timeSeries setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[timeSeries release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		
		[timeSeries addValue:aValue atTime:aTime];
		
		va_end(myArgs);
	}
}


- (void)loadFFTReal:(NSArray*)realArray imaginary:(NSArray*)imaginaryArray withKeyArray:(NSArray*)keyArray
{
 	@synchronized(self){     
		NSUInteger n = [keyArray count];
		int i;
		ORDataSet* currentLevel = self;
		ORDataSet* nextLevel    = nil;
		[currentLevel incrementTotalCounts];
		
		for(i=0;i<n;i++){
			NSString* s = [keyArray objectAtIndex:i];
			nextLevel = [currentLevel objectForKey:s];
			if(nextLevel){
				if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
				currentLevel = nextLevel;
			}
			else {
				nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
				[currentLevel setObject:nextLevel forKey:s];
				currentLevel = nextLevel;
				[nextLevel release];
			}
			[currentLevel incrementTotalCounts];
		}
		
		ORPlotFFT* fftPlot = [nextLevel data];
		if(!fftPlot){
			fftPlot = [[ORPlotFFT alloc] init];
			[fftPlot setKey:[nextLevel key]];
			[fftPlot setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
			[fftPlot setRealArray:realArray imaginaryArray:imaginaryArray];
			[nextLevel setData:fftPlot];
			[fftPlot release];
            [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORDataSetAdded object:self];
		}
		else {
			[fftPlot setRealArray:realArray imaginaryArray:imaginaryArray];
		}
		[[currentLevel data] askForUniqueIDNumber];
		[[currentLevel data] makeMainController];
	}
}


- (void) processResponse:(NSDictionary*)aResponse
{
	NSString* title = [aResponse objectForKey:ORCARootServiceTitleKey];
	NSMutableArray* keyArray = [NSMutableArray arrayWithArray:[title componentsSeparatedByString:@","]];
	[keyArray insertObject:@"FFT" atIndex:0];
	NSArray* complex = [aResponse nestedObjectForKey:@"Request Outputs",@"FFTComplex",nil];
	NSArray* real    = [aResponse nestedObjectForKey:@"Request Outputs",@"FFTReal",nil];
	[self loadFFTReal:real imaginary:complex withKeyArray:keyArray];
}

#pragma mark •••Data Source Methods
- (NSUInteger)  numberOfChildren
{
    return [self count];
}

- (NSString*)   childAtIndex:(NSUInteger)index
{
	id theData = nil;
	@synchronized(self){  
		
		if([self leafNode])theData = [[data retain] autorelease];
		else {
			if(index < [sortedArray count]){
				id obj = [realDictionary objectForKey:[sortedArray objectAtIndex:index]];
				if(obj)theData =  [[obj retain] autorelease];
			}
		}
	}
	return theData;
}

- (void) doDoubleClick:(id)sender
{
    if([self leafNode]){
		[data askForUniqueIDNumber];
		[data makeMainController];
	}
    else {
        NSEnumerator* e = [realDictionary objectEnumerator];
        id obj;
        while(obj=[e nextObject]){
            if([obj data] == nil){
                return;
            }
        }
		[self askForUniqueIDNumber];
        [self makeMainController];
        
    }
}

- (NSString*) summarizeIntoString:(NSMutableString*)summary
{
    return [self summarizeIntoString:summary level:0];
}

- (NSString*) summarizeIntoString:(NSMutableString*)summary level:(int)level
{
    NSMutableString* padding = [NSMutableString stringWithCapacity:level];
    int i;
    for(i=0;i<level;i++)[padding appendString:@" "];
    if([padding length] == 0)[padding appendString:@""];
    
    [summary appendFormat:@"%@%@\n",padding,[self name]];
    
    NSEnumerator* e = [sortedArray objectEnumerator];
    id akey;
    ++level;
    while(akey = [e nextObject]){
        id obj = [realDictionary objectForKey:akey];
        NSMutableString* aString = [NSMutableString stringWithCapacity:256];
        NSString* s = [obj summarizeIntoString:aString level:level];
        if(s)[summary appendString:s];
    }
    
    return summary;
}



#pragma mark •••Archival
static NSString *ORDataSetRealDictionary 	= @"OR Data Dictionary";
static NSString *ORDataData 			= @"OR Data Data";
static NSString *ORDataKey 			= @"OR Data Key";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
//    dataSetLock = [[NSLock alloc] init];
    
    [[self undoManager] disableUndoRegistration];
   
    realDictionary = [[decoder decodeObjectForKey:ORDataSetRealDictionary] retain];
    if(data == nil){
        [sortedArray release];
        sortedArray = [[realDictionary keysSortedByValueUsingSelector:@selector(compare:)] retain];
    }
    [self setData:[decoder decodeObjectForKey:ORDataData]];
    [self setKey:[decoder decodeObjectForKey:ORDataKey]];
    [self setMinX:[decoder decodeFloatForKey:@"minX"]];
    [self setMinY:[decoder decodeFloatForKey:@"minY"]];
    [self setMaxX:[decoder decodeFloatForKey:@"maxX"]];
    [self setMaxY:[decoder decodeFloatForKey:@"maxY"]];
    [[self undoManager] enableUndoRegistration];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeObject:realDictionary forKey:ORDataSetRealDictionary];
    [encoder encodeObject:data forKey:ORDataData];
    [encoder encodeObject:key forKey:ORDataKey];
    [encoder encodeFloat:minX forKey:@"minX"];
    [encoder encodeFloat:maxX forKey:@"maxX"];
    [encoder encodeFloat:minY forKey:@"minY"];
    [encoder encodeFloat:maxY forKey:@"maxY"];
}
@end
