//
//  ORHeaderExplorerModel.m
//  Orca
//
//  Created by Mark Howe on Tue Feb 26.
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
#import "ORHeaderExplorerModel.h"
#import "ORDataPacket.h"
#import "ORDataTaker.h"
#import "ORDataPacket.h"
#import "ORHeaderItem.h"
#import "ORHeaderCollector.h"

#pragma mark •••Notification Strings
NSString* ORHeaderExplorerUseFilterChanged		= @"ORHeaderExplorerUseFilterChanged";
NSString* ORHeaderExplorerAutoProcessChanged	= @"ORHeaderExplorerAutoProcessChanged";
NSString* ORHeaderExplorerListChanged			= @"ORHeaderExplorerListChanged";

NSString* ORHeaderExplorerProcessing			= @"ORHeaderExplorerProcessing";
NSString* ORHeaderExplorerProcessingFinished	= @"ORHeaderExplorerProcessingFinished";
NSString* ORHeaderExplorerProcessingFile		= @"ORHeaderExplorerProcessingFile";
NSString* ORHeaderExplorerOneFileDone			= @"ORHeaderExplorerOneFileDone";

NSString* ORHeaderExplorerSelectionDate			= @"ORHeaderExplorerSelectionDate";
NSString* ORHeaderExplorerRunSelectionChanged	= @"ORHeaderExplorerRunSelectionChanged";
NSString* ORHeaderExplorerFileSelectionChanged	= @"ORHeaderExplorerFileSelectionChanged";
NSString* ORHeaderExplorerHeaderChanged			= @"ORHeaderExplorerHeaderChanged";
NSString* ORHeaderExplorerSearchKeysChanged		= @"ORHeaderExplorerSearchKeysChanged";
NSString* ORHeaderExplorerProgressChanged		= @"ORHeaderExplorerProgressChanged";


#pragma mark •••Definitions

@interface ORHeaderExplorerModel (private)
- (void) processFinished;
@end

@implementation ORHeaderExplorerModel

#pragma mark •••Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}


- (void) dealloc
{
    [searchKeys release];
    [lastListPath release];
	[lastFilePath release];
	
    [filesToProcess release];
    [fileAsDataPacket release];
	[fileToProcess release];
	[runArray release];
	
	[queue cancelAllOperations];
	[queue release];

    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"HeaderExplorer"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORHeaderExplorerController"];
}

- (NSString*) helpURL
{
	return @"Data_Format_Viewing/Header_Explorer.html";
}

#pragma mark •••Accessors

- (BOOL) useFilter
{
    return useFilter;
}

- (void) setUseFilter:(BOOL)aUseFilter
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseFilter:useFilter];
    
    useFilter = aUseFilter;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHeaderExplorerUseFilterChanged object:self];
}

- (NSMutableArray*) searchKeys
{
    return searchKeys;
}

- (void) setSearchKeys:(NSMutableArray*)anArray
{
	[anArray retain];
	[searchKeys release];
	searchKeys = anArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHeaderExplorerSearchKeysChanged object:self];
	
}

- (void) replace:(NSInteger)index withSearchKey:(NSString*)aKey
{
    if(!searchKeys)searchKeys = [[NSMutableArray array] retain];
	[searchKeys replaceObjectAtIndex:index withObject:aKey];
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerSearchKeysChanged
                              object: self];      
}

- (void) insert:(NSInteger)index withSearchKey:(NSString*)aKey
{
    if(!searchKeys)searchKeys = [[NSMutableArray array] retain];
	if(index>[searchKeys count])[searchKeys addObject:aKey];
	else [searchKeys insertObject:aKey atIndex:index];
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerSearchKeysChanged
                              object: self];      
}


- (void) addSearchKeys:(NSMutableArray*)newKeys
{
	if(!newKeys)return;
    if(!searchKeys)searchKeys = [[NSMutableArray array] retain];
    
    [[[self undoManager] prepareWithInvocationTarget:self] removeSearchKeys:newKeys];
    
    [searchKeys addObjectsFromArray:newKeys];
    
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerSearchKeysChanged
                              object: self];      
}

- (void) removeSearchKeys:(NSMutableArray*)anArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] addSearchKeys:anArray];
    [searchKeys removeObjectsInArray:anArray];

    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerSearchKeysChanged
                              object: self];
}

- (void) removeSearchKeysWithIndexes:(NSIndexSet*)indexSet
{
    NSMutableArray* keysToRemove = [NSMutableArray array];
	NSUInteger current_index = [indexSet firstIndex];
    while (current_index != NSNotFound){
		[keysToRemove addObject:[searchKeys objectAtIndex:current_index]];
        current_index = [indexSet indexGreaterThanIndex: current_index];
    }
	if([keysToRemove count]){
		[self removeSearchKeys:keysToRemove];    
	}
}


- (BOOL) autoProcess
{
    return autoProcess;
}

- (void) setAutoProcess:(BOOL)aAutoProcess
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoProcess:autoProcess];
    
    autoProcess = aAutoProcess;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHeaderExplorerAutoProcessChanged object:self];
}

- (int) selectedFileIndex
{
	return selectedFileIndex;
}
- (void) setSelectedFileIndex:(int)anIndex
{
	if(anIndex>=(int)[filesToProcess count])	selectedFileIndex = (int)[filesToProcess count]-1;
	else								        selectedFileIndex = anIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHeaderExplorerFileSelectionChanged object:self];
}

- (int) selectedRunIndex
{
	return selectedRunIndex;
}

- (void) setSelectedRunIndex:(int)anIndex
{
	selectedRunIndex = anIndex;
	[self loadHeader];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORHeaderExplorerRunSelectionChanged object: self];
}


- (int32_t) selectionDate
{
	return selectionDate;
}

- (void) setSelectionDate:(int32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectionDate:selectionDate];

    selectionDate = aValue;
		
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerSelectionDate
                              object: self];
}

- (uint32_t)   total
{
	return (uint32_t)[filesToProcess count];
}

- (NSDictionary*) runDictionaryForIndex:(int)index
{
	if(index>=0 && index<[runArray count]){
		return [runArray objectAtIndex:index];
	}
	else return nil;
}

- (ORDataPacket*) fileAsDataPacket
{
    return fileAsDataPacket;
}

- (NSString*) fileToProcess
{
    if(fileToProcess)return fileToProcess;
    else return @"";
}

- (void) setFileToProcess:(NSString*)newFileToProcess
{    
    [fileToProcess autorelease];
    fileToProcess=[newFileToProcess retain];
	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORHeaderExplorerProcessingFile
								object: self];
}

- (NSArray*) filesToProcess
{
    return filesToProcess;
}


- (ORHeaderItem *)header
{
    return header; 
}

- (void) setHeader:(ORHeaderItem *)aHeader
{
    [aHeader retain];
    [header release];
    header = aHeader;

	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORHeaderExplorerHeaderChanged
								object: self];
}

- (NSMutableDictionary*) filteredHeader:(id)aHeader
{
	int index;
	NSUInteger n = [searchKeys count];
	id headerData;
	NSMutableDictionary* filteredStuff = [NSMutableDictionary dictionary];
	if(n){
		for(index = 0;index<n;index++){
			id searchKey = [searchKeys objectAtIndex:index];
			NSString* s = searchKey;
			if([searchKey hasSuffix:@"/"])s = [searchKey substringToIndex:[searchKey length]-1];
			NSMutableArray* keyArray = [NSMutableArray arrayWithArray:[s componentsSeparatedByString:@"/"]]; //must be mutable
			headerData = [aHeader objectForKeyArray:keyArray];
			if(headerData){
				[filteredStuff setObject:headerData forKey:[NSString stringWithFormat:@"Key %d",index]];
			}
		}
		if([filteredStuff count]){
			return filteredStuff;
		}
		else return aHeader;

	}
	else return aHeader;
}

- (void) loadHeader
{
	if(selectedRunIndex>=0 && selectedRunIndex<[runArray count]){
		id aHeader = [[runArray objectAtIndex:selectedRunIndex] objectForKey:@"FileHeader"];
		if(useFilter){
			NSMutableDictionary* filteredStuff = [self filteredHeader:aHeader];
			[self setHeader:[ORHeaderItem headerFromObject:filteredStuff named:@"Root"]];
		}
		else {
			[self setHeader:[ORHeaderItem headerFromObject:aHeader named:@"Root"]];
		}
	}
	else [self setHeader:nil];
}

- (BOOL) fileHasBeenProcessed:(uint32_t)anIndex
{
    if(anIndex<[filesToProcess count]){
        NSString* aFileName = [filesToProcess objectAtIndex:anIndex];
        for(id anItem in runArray){
            if([[anItem objectForKey:@"FilePath"] isEqualToString:aFileName])return YES;
        }
        return NO;
    }
    else return NO;
}

- (BOOL)isProcessing
{
    return [[queue operations] count]!=0;
}

- (void) checkStatus
{
	if(![self isProcessing]){
		[self processFinished];
	}
}


- (NSString *) lastListPath
{
    return lastListPath; 
}

- (void) setLastListPath: (NSString *) aLastListPath
{
    [lastListPath release];
    lastListPath = [aLastListPath copy];
}

- (NSString *) lastFilePath
{
    return lastFilePath;
}
- (void) setLastFilePath: (NSString *) aSetLastListPath
{
    [lastFilePath release];
    lastFilePath = [aSetLastListPath copy];
}

- (void) selectFirstRunForFileIndex:(int)anIndex
{
	if(anIndex<0){
		[self setSelectedRunIndex: -1];
	}
	else {
		uint32_t minTime = 0xFFFFFFFF;
		NSString* selectedRunFilePath = nil;
		if(anIndex<[filesToProcess count]) selectedRunFilePath = [filesToProcess objectAtIndex:anIndex];
		NSUInteger foundIndex = 0;
		for(id runDictionary in runArray){
			NSString* runFilePath = [runDictionary objectForKey:@"FilePath"];
			if([selectedRunFilePath isEqual:runFilePath]){
				uint32_t startTime = (uint32_t)[[runDictionary objectForKey:@"RunStart"] unsignedLongValue];
				if(startTime < minTime){
					minTime = startTime;
					foundIndex = [runArray indexOfObject:runDictionary];
				}
			}
		}
		[self setSelectedRunIndex: (int)foundIndex];
	}
}

- (void) findSelectedRunByDate
{
	BOOL valid = NO;
	uint32_t actualDate	= minRunStartTime + ((maxRunEndTime - minRunStartTime) * (selectionDate/1000.));

	NSUInteger n = [runArray count];
	int index;
	for(index=0;index<n;index++){
		NSDictionary* runDictionary = [runArray objectAtIndex:index];
		uint32_t start = (uint32_t)[[runDictionary objectForKey:@"RunStart"] unsignedLongValue];
		uint32_t end   = (uint32_t)[[runDictionary objectForKey:@"RunEnd"] unsignedLongValue];
		if(actualDate >= start && actualDate < end){
			NSString* fileName  = [runDictionary objectForKey:@"FilePath"];
			[self setSelectedFileIndex:[self indexOfFile:fileName]];
			[self setSelectedRunIndex: index];
			valid = YES;
			break;
		}
	}
	
	if(!valid){
		if(actualDate>=maxRunEndTime){
			[self setSelectedRunIndex: (int)[runArray count]-1];
		}
		else {
			[self setHeader:nil];
		}
	}
}

- (int) indexOfFile:(NSString*)aFilePath
{
	return (int)[filesToProcess indexOfObject:aFilePath];
}

- (void) assembleDataForPlotting
{
	if(useFilter){
		NSUInteger n = [searchKeys count];
		int i;
		for(i=0;i<n;i++){
			[self assembleDataForPlotting:i];
		}
	}
}

- (void) assembleDataForPlotting:(int)keyNumber
{
	NSLog(@"Key %d : %@ (by Run Number)\n",keyNumber,[searchKeys objectAtIndex:keyNumber]);
	NSUInteger n = [runArray count];
	int i;
	for(i=0;i<n;i++){
		NSNumber* runNumber = [[runArray objectAtIndex:i] objectForKey:@"RunNumber"];
		BOOL	  useSubRun = [[[runArray objectAtIndex:i] objectForKey:@"UseSubRun"] boolValue];
		NSNumber* subRunNumber = [[runArray objectAtIndex:i] objectForKey:@"SubRunNumber"];
		id aHeader = [[runArray objectAtIndex:i] objectForKey:@"FileHeader"];
		NSMutableDictionary* filteredStuff = [self filteredHeader:aHeader];
		if(filteredStuff){
			ORHeaderItem* headerItem = [ORHeaderItem headerFromObject:filteredStuff named:@"Root"];
			//there are only certain things we can plot, namely arrays and values
			//A valid plot set will be at Root/Key n/array or Root/Key n/value
			if([[headerItem name] isEqualToString:@"Root"]){
				ORHeaderItem* keyItem = [[headerItem items] objectAtIndex:keyNumber];
				if([[keyItem name] hasPrefix:@"Key"]){
					if([keyItem object]){
						NSLog(@"%@%@%@ %@\n",
							  runNumber, 
							  useSubRun?@".":@"",
							  useSubRun?[NSString stringWithFormat:@"%@",subRunNumber]:@"",
							  [keyItem object]);
					}
					else {
						NSArray* array = [keyItem items];
						NSUInteger n = [array count];
						int i;
						for(i=0;i<n;i++){
							ORHeaderItem* lowestItem = [array objectAtIndex:i];
							if([lowestItem object]){
								NSLog(@"%@%@%@ %@\n",
									  runNumber, 
									  useSubRun?@".":@"",
									  useSubRun?[NSString stringWithFormat:@"%@",subRunNumber]:@"",
									  [lowestItem object]);
							}
						}						
					}
				}
				else {
					NSLog(@"Not valid\n");
				}
			}
		}
	}
}

- (uint32_t) minRunStartTime {return minRunStartTime;}
- (uint32_t) maxRunEndTime	  {return maxRunEndTime;}
- (int32_t) numberRuns {return (uint32_t)[runArray count];}
- (id) run:(int)index objectForKey:(id)aKey
{
	if(index<[runArray count]){
		return [[runArray objectAtIndex:index] objectForKey:aKey];
	}
	else return 0;
}

#pragma mark •••File Actions

- (void) removeAll
{
    [self removeFiles:filesToProcess];
}

- (void) addFilesToProcess:(NSMutableArray*)newFilesToProcess
{
	if(!newFilesToProcess)return;
    if(!filesToProcess){
        filesToProcess = [[NSMutableArray array] retain];
    }
    
    [[[self undoManager] prepareWithInvocationTarget:self] removeFiles:newFilesToProcess];
    
    
    //remove dups
    for(id newFileName in newFilesToProcess){
        for(id oldFileName in filesToProcess){
            if([oldFileName isEqualToString:newFileName]){
                [filesToProcess removeObject:oldFileName];
                break;
            }
        }
    }
    
    [filesToProcess addObjectsFromArray:newFilesToProcess];
    [filesToProcess sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerListChanged
                              object: self];

	if(autoProcess)[self readHeaders];
      
}

- (void) removeFiles:(NSMutableArray*)arrayOfFilesToRemove
{
    [[[self undoManager] prepareWithInvocationTarget:self] addFilesToProcess:arrayOfFilesToRemove];
    [filesToProcess removeObjectsInArray:arrayOfFilesToRemove];

    NSMutableArray* processedFilesToRemove = [NSMutableArray array];
    for(id aFileName in arrayOfFilesToRemove){
        for(id anItem in runArray){
            if([[anItem objectForKey:@"FilePath"] isEqualToString:aFileName]){
                [processedFilesToRemove addObject:anItem];
            }
        }
    }
    [runArray removeObjectsInArray:processedFilesToRemove];
    
    
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerListChanged
                              object: self];
}

- (void) removeFilesWithIndexes:(NSIndexSet*)indexSet;
{
    NSMutableArray* filesToRemove = [NSMutableArray array];
	NSUInteger current_index = [indexSet firstIndex];
    while (current_index != NSNotFound){
		[filesToRemove addObject:[filesToProcess objectAtIndex:current_index]];
        current_index = [indexSet indexGreaterThanIndex: current_index];
    }
	if([filesToRemove count]){
		[self removeFiles:filesToRemove];    
	}
}

- (void) stopProcessing
{
	[queue cancelAllOperations];
	reading = NO;
	stop = YES;
    NSLog(@"Header Explorer stopped manually\n");
}

#pragma mark •••File Actions
- (BOOL) readHeaders
{
	[runArray release];
	runArray = [[NSMutableArray array] retain];
	
	[self setHeader:nil];
	minRunStartTime  = 0xffffffff;
	maxRunEndTime	 = 0;
    currentFileIndex = 0;
	
	if ([filesToProcess count]){
		
		amountDoneSoFar = 0;
		totalToBeProcessed = 0;
        NSMutableArray* nonExistantFiles = [NSMutableArray array];
		for(id aPath in filesToProcess){
			if([[NSFileManager defaultManager] fileExistsAtPath:aPath]){
				NSDictionary *fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath:aPath error:nil];
				totalToBeProcessed += [[fattrs objectForKey:NSFileSize] longLongValue];
			}
            else [nonExistantFiles addObject:aPath];
		}
		[self removeFiles:nonExistantFiles];
    }
	if ([filesToProcess count]){
        [[NSNotificationCenter defaultCenter] postNotificationName:ORHeaderExplorerProcessing object: self];

		if(!queue){
			queue = [[NSOperationQueue alloc] init];
		}
		
		[queue setMaxConcurrentOperationCount:1];
		for(id aPath in filesToProcess){
			if([[NSFileManager defaultManager] fileExistsAtPath:aPath]){
				ORHeaderCollector* headerCollector = [[ORHeaderCollector alloc] initWithPath:aPath delegate:self];
				[queue addOperation:headerCollector];
				[headerCollector release];
				reading = YES;
				stop = NO;
			}
		}
		
        return [filesToProcess count]?YES:NO;
	}
    return NO;
}

- (void)logHeader:(NSDictionary*)aHeader
		 runStart:(uint32_t)aRunStart 
		   runEnd:(uint32_t)aRunEnd 
		runNumber:(uint32_t)aRunNumber 
		useSubRun:(uint32_t)aUseSubRun
	 subRunNumber:(uint32_t)aSubRunNumber
		 fileSize:(uint32_t)aFileSize
		 fileName:(NSString*)aFilePath
{
	if(aRunStart!=0 && aRunEnd!=0){
	
		if(aRunStart < minRunStartTime) minRunStartTime = aRunStart;
		if(aRunEnd > maxRunEndTime)     maxRunEndTime   = aRunEnd;
		
		NSMutableDictionary* runDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedLong:aRunStart],			@"RunStart",
				[NSNumber numberWithUnsignedLong:aRunEnd],				@"RunEnd",
				[NSNumber numberWithUnsignedLong:aRunEnd-aRunStart],	@"RunLength",
				[NSNumber numberWithUnsignedLong:aRunNumber],			@"RunNumber",
				[NSNumber numberWithBool:aUseSubRun],					@"UseSubRun",
				[NSNumber numberWithUnsignedLong:aSubRunNumber],		@"SubRunNumber",
				[NSNumber numberWithUnsignedLong:aFileSize],			@"FileSize",
				aHeader,												@"FileHeader",
				aFilePath,												@"FilePath",
				nil];
				
		[runArray addObject:runDictionary];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORHeaderExplorerOneFileDone object: self];
	}
}

- (void) updateProgress:(NSNumber*)amountDone
{
	amountDoneSoFar += [amountDone doubleValue];
	percentComplete = 100. * amountDoneSoFar/totalToBeProcessed;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORHeaderExplorerProgressChanged object: self];		
}

- (double) percentComplete
{
	return percentComplete;
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
    [self setUseFilter:		[decoder decodeBoolForKey:	@"useFilter"]];
    [self setSearchKeys:	[decoder decodeObjectForKey:@"searchKeys"]];
    [self setAutoProcess:	[decoder decodeBoolForKey:	@"autoProcess"]];
	[self addFilesToProcess:[decoder decodeObjectForKey:@"filesToProcess"]];
	[self setLastListPath:	[decoder decodeObjectForKey:@"lastListPath"]];
	[self setLastFilePath:	[decoder decodeObjectForKey:@"lastFilePath"]];
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:useFilter		forKey: @"useFilter"];
    [encoder encodeObject:searchKeys	forKey: @"searchKeys"];
    [encoder encodeBool:autoProcess		forKey: @"autoProcess"];
    [encoder encodeObject:filesToProcess forKey:@"filesToProcess"];
    [encoder encodeObject:lastListPath	forKey: @"lastListPath"];
    [encoder encodeObject:lastFilePath	forKey: @"lastFilePath"];
    
}

@end

@implementation ORHeaderExplorerModel (private)
- (void) processFinished
{    
	reading = NO;
	stop = NO;

	[fileAsDataPacket clearData];
    [fileAsDataPacket release];
    fileAsDataPacket = nil;
		      
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORHeaderExplorerProcessingFinished
                              object: self];

	[self loadHeader];
}

@end

