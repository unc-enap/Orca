//
//  ORDataExplorerModel.m
//  Orca
//
//  Created by Mark Howe on Sun Dec 05 2004.
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


#pragma mark ¥¥¥Imported Files
#import "ORDataExplorerModel.h"
#import "ORHeaderItem.h"
#import "ORDataSet.h"
#import "ORRecordIndexer.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORDataExplorerModelHeaderOnlyChanged		= @"ORDataExplorerModelHeaderOnlyChanged";
NSString* ORDataExplorerModelHistoErrorFlagChanged	= @"ORDataExplorerModelHistoErrorFlagChanged";
NSString* ORDataExplorerModelMultiCatalogChanged	= @"ORDataExplorerModelMultiCatalogChanged";
NSString* ORDataExplorerFileChangedNotification     = @"ORDataExplorerFileChangedNotification";
NSString* ORDataExplorerParseStartedNotification    = @"ORDataExplorerParseStartedNotification";
NSString* ORDataExplorerParseEndedNotification      = @"ORDataExplorerParseEndedNotification";
NSString* ORDataExplorerDataChanged                 = @"ORDataExplorerDataChanged";

@implementation ORDataExplorerModel

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
    [fileToExplore release];
    [header release];
    [dataRecords release];
    [dataSet release];
    
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"DataExplorer"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORDataExplorerController"];
}

- (NSString*) helpURL
{
	return @"Data_Format_Viewing/Data_Explorer.html";
}

#pragma mark ¥¥¥Accessors

- (BOOL) headerOnly
{
    return headerOnly;
}

- (void) setHeaderOnly:(BOOL)aHeaderOnly
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHeaderOnly:headerOnly];
    
    headerOnly = aHeaderOnly;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataExplorerModelHeaderOnlyChanged object:self];
}

- (BOOL) histoErrorFlag
{
    return histoErrorFlag;
}

- (void) setHistoErrorFlag:(BOOL)aHistoErrorFlag
{
    histoErrorFlag = aHistoErrorFlag;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataExplorerModelHistoErrorFlagChanged object:self];
}

- (BOOL) multiCatalog
{
    return multiCatalog;
}

- (void) setMultiCatalog:(BOOL)aMultiCatalog
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiCatalog:multiCatalog];
    
    multiCatalog = aMultiCatalog;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataExplorerModelMultiCatalogChanged object:self];
}
- (ORDataSet*) dataSet
{
    return dataSet;
}

- (void) setDataSet:(ORDataSet*)aDataSet
{
    [aDataSet retain];
    [dataSet release];
    dataSet = aDataSet;
    [dataSet registerForWatchers];
}

- (NSArray *) dataRecords
{
    return dataRecords; 
}

- (void) setDataRecords: (NSArray *) aDataRecords
{
    [aDataRecords retain];
    [dataRecords release];
    dataRecords = aDataRecords;
}

- (id) dataRecordAtIndex:(int)index
{
    return [dataRecords objectAtIndex:index];
}

- (NSString*) fileToExplore
{
    if(fileToExplore)return fileToExplore;
    else return @"";
}

- (void) setFileToExplore:(NSString*)newFileToExplore
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFileToExplore:fileToExplore];
    
    [fileToExplore autorelease];
    fileToExplore=[newFileToExplore retain];
    
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORDataExplorerFileChangedNotification
                              object: self];
    
}

- (ORHeaderItem*)header
{
    return header; 
}

- (void) setHeader:(ORHeaderItem*)aHeader
{
    [aHeader retain];
    [header release];
    header = aHeader;
}


- (id)   name
{
    return @"System";
}

- (id)   childAtIndex:(NSUInteger)index
{
    NSEnumerator* e = [dataSet objectEnumerator];
    id obj;
    id child = nil;
    short i = 0;
    while(obj = [e nextObject]){
        if(i++ == index){
            child = obj;
            break;
        }
    }
    return child;
}
- (NSUInteger)  count
{
    return [dataSet count];
}

- (NSUInteger)  numberOfChildren
{
    int count =  [dataSet count];
    return count;
}

- (void) removeDataSet:(ORDataSet*)item
{
    if([[item name] isEqualToString: [self name]]) {
        [self setDataSet:nil];
    }
    else [dataSet removeObject:item];
}

- (void) createDataSet
{
    [self setDataSet:[[[ORDataSet alloc]initWithKey:@"System" guardian:nil] autorelease]];
}

- (void) setTotalLength:(NSUInteger)aLength
{
	totalLength = aLength;
}

- (void) setLengthDecoded:(NSUInteger)aLength
{
	lengthDecoded = aLength;
}


- (NSUInteger) totalLength
{
    return totalLength;
}

- (NSUInteger) lengthDecoded
{
    return lengthDecoded;
}

- (void) clearCounts
{
    [dataSet clear];
    NSEnumerator* e = [dataRecords objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj setObject:[NSNumber numberWithBool:NO] forKey:@"DecodedOnce"];
    }
    
}
- (void) flushMemory
{
    [self setDataRecords:nil];
    [self setHeader:nil];
    [self setDataSet:nil];    
}

#pragma mark ¥¥¥File Actions

- (BOOL) parseInProgress
{
    return [[queue operations] count]!=0;
}

- (void) stopParse
{
}

- (void) parseFile
{
	[self setHistoErrorFlag:NO];
	    
    totalLength   = 0;
    lengthDecoded = 0;
    [self setDataRecords:nil];
    [self setHeader:nil];
    [self setDataSet:nil];
    
	if(!queue){
		queue = [[NSOperationQueue alloc] init];
	}
	if(headerOnly){
		NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:fileToExplore];
		NSData* data =  [fh readDataOfLength:8];
		unsigned long* ptr = (unsigned long*)[data bytes];
		unsigned long headerLenInBytes = ptr[1];
		NSData* headerAsData = [fh readDataOfLength:headerLenInBytes];
		NSString* theHeaderAsString = [[NSString alloc] initWithBytes:[headerAsData bytes] length:headerLenInBytes encoding:NSASCIIStringEncoding];
		NSDictionary* theHeader = [theHeaderAsString propertyList];
		[theHeaderAsString release];
		if(theHeader){
			ORHeaderItem* d = [ORHeaderItem headerFromObject:theHeader named:@"Root"];
			if(d)[self setHeader:d ];
			[[NSNotificationCenter defaultCenter] postNotificationName:ORDataExplorerParseEndedNotification object:self];
		}
        [fh closeFile];
	}
	else {
		[[NSNotificationCenter defaultCenter] postNotificationName:ORDataExplorerParseStartedNotification object: self];
		[queue setMaxConcurrentOperationCount:1]; //can only do one at a time
		if(recordIndexer)[recordIndexer release];
		recordIndexer = [[ORRecordIndexer alloc] initWithPath:fileToExplore delegate:self];
		[queue addOperation:recordIndexer];
	}

}

- (void) parseEnded
{
	[self performSelector:@selector(delayedSendParseEnded) withObject:nil afterDelay:.1];
}

- (void) delayedSendParseEnded
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORDataExplorerParseEndedNotification object: self];
}

- (void) byteSwapOneRecordAtOffset:(unsigned long)anOffset forKey:(id)aKey
{
    [recordIndexer byteSwapOneRecordAtOffset:anOffset forKey:aKey];
}

- (void) decodeOneRecordAtOffset:(unsigned long)anOffset forKey:(id)aKey
{
    [recordIndexer decodeOneRecordAtOffset:anOffset intoDataSet:dataSet forKey:aKey];
}

- (NSString*) dataRecordDescription:(unsigned long)anOffset forKey:(NSNumber*)aKey
{
	return [recordIndexer dataRecordDescription:anOffset forKey:aKey];
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
    [self setHeaderOnly:	[decoder decodeBoolForKey:@"headerOnly"]];
    [self setMultiCatalog:	[decoder decodeBoolForKey:		@"ORDataExplorerModelMultiCatalog"]];
	[self setFileToExplore:	[decoder decodeObjectForKey:	@"ORDataExplorerFileName"]];
    [self setDataSet:		[decoder decodeObjectForKey:	@"ORDataExplorerDataSet"]];
    
    if(!dataSet)[self setDataSet:[[[ORDataSet alloc]initWithKey:@"System" guardian:nil] autorelease]];
    [[self undoManager] enableUndoRegistration];

    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:headerOnly		forKey:@"headerOnly"];
    [encoder encodeBool:multiCatalog	forKey: @"ORDataExplorerModelMultiCatalog"];
    [encoder encodeObject:fileToExplore forKey: @"ORDataExplorerFileName"];
    [encoder encodeObject:dataSet		forKey: @"ORDataExplorerDataSet"];
    
}

@end
