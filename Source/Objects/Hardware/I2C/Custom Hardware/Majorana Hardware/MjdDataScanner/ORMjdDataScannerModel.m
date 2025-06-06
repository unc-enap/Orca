//
//  ORMjdDataScannerModel.m
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

#pragma mark •••Imported Files
#import "ORMjdDataScannerModel.h"
#import "ORHeaderItem.h"
#import "ORMjdFileReader.h"

#pragma mark •••Notification Strings
NSString* ORMjdDataScannerFileListChanged = @"ORMjdDataScannerFileListChanged";

NSString* ORMjdDataScannerRunningNotification		  = @"ORMjdDataScannerRunningNotification";
NSString* ORMjdDataScannerStoppedNotification		  = @"ORMjdDataScannerStoppedNotification";
NSString* ORMjdDataScannerFileChangedNotification		= @"ORMjdDataScannerFileChangedNotification";
NSString* ORMjdDataScannerProgressChangedNotification	= @"ORMjdDataScannerProgressChangedNotification";

#pragma mark •••Definitions

@interface ORMjdDataScannerModel (private)
- (void) replayFinished;
- (void) fileFinished;
@end


@implementation ORMjdDataScannerModel

#pragma mark •••Initialization
- (void) dealloc
{
    [lastListPath release];
	[lastFilePath release];
	[header release];
    [filesToReplay release];
	[fileToReplay release];
	
    [dataRecords release];
	[queue cancelAllOperations];
	[queue release];
    [super dealloc];
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MjdDataScanner"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORMjdDataScannerController"];
}

#pragma mark •••Accessors

- (NSString*) fileToReplay
{
    if(fileToReplay)return fileToReplay;
    else return @"";
}

- (void) setFileToReplay:(NSString*)newFileToReplay
{    
    [fileToReplay autorelease];
    fileToReplay=[newFileToReplay retain];
    
	NSLog(@"Scanning: %@\n",[newFileToReplay  stringByAbbreviatingWithTildeInPath]);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMjdDataScannerFileChangedNotification object: self];
    
}

- (NSArray*) filesToReplay
{
    return filesToReplay;
}

- (void) addFilesToReplay:(NSMutableArray*)newFilesToReplay
{
    
    if(!filesToReplay)filesToReplay = [[NSMutableArray array] retain];
    
    [[[self undoManager] prepareWithInvocationTarget:self] removeFiles:newFilesToReplay];
    
    //remove dups
    NSEnumerator* newListEnummy = [newFilesToReplay objectEnumerator];
    id newFileName;
    while(newFileName = [newListEnummy nextObject]){
        NSEnumerator* oldListEnummy = [filesToReplay objectEnumerator];
        id oldFileName;
        while(oldFileName = [oldListEnummy nextObject]){
            if([oldFileName isEqualToString:newFileName]){
                [filesToReplay removeObject:oldFileName];
                break;
            }
        }
        
    }
    
    [filesToReplay addObjectsFromArray:newFilesToReplay];
    [filesToReplay sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMjdDataScannerFileListChanged
	 object: self];
    
}

- (ORHeaderItem *)header
{
    return header; 
}

- (void)setHeader:(ORHeaderItem *)aHeader
{
    [aHeader retain];
    [header release];
    header = aHeader;
 
}

- (BOOL) isReplaying
{
    return [[queue operations] count]!=0;
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


#pragma mark •••File Actions
- (void) removeAll
{
    [filesToReplay removeAllObjects];
}

- (void) replayFiles
{
	if(![filesToReplay count])return;
	if([self isReplaying]) return;
	stop = NO;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMjdDataScannerRunningNotification object: self];
	
	sentRunStart = NO;
	if(!queue){
		queue = [[NSOperationQueue alloc] init];
	}
	
	[queue setMaxConcurrentOperationCount:1]; //can only do one at a time
	
	for(id aPath in filesToReplay){
		ORMjdFileReader* fileReader = [[ORMjdFileReader alloc] initWithPath:aPath delegate:self];
		[queue addOperation:fileReader];
		[fileReader release];
	}	
}

- (void) checkStatus
{
	if(![self isReplaying]){
		[self replayFinished];
	}
}

- (void) updateProgress:(NSNumber*)amountDone
{
	percentComplete = [amountDone doubleValue];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMjdDataScannerProgressChangedNotification object: self];		
}

- (double) percentComplete
{
	return percentComplete;
}

- (BOOL) cancelAndStop
{
	return stop;
}

- (void) stopReplay
{
	stop = YES;
	[queue cancelAllOperations];
    NSLog(@"Replay stopped manually\n");
}

- (void) readHeaderForFileIndex:(int)index
{
    if(index>=0 && [filesToReplay count]){
		NSString* aFileName = [filesToReplay objectAtIndex:index];
		ORMjdFileReader* fileReader = [[ORMjdFileReader alloc] initWithPath:aFileName delegate:self];
		if(![[NSFileManager defaultManager] fileExistsAtPath:aFileName]){
			[self setHeader:nil];
			[fileReader release];
			return;
		}
		if([fileReader currentHeader]){
			[self setHeader:[ORHeaderItem headerFromObject:[fileReader currentHeader] named:@"Root"]];
		}
		else {
			NSLogColor([NSColor redColor],@"Problem reading header for <%@>.\n",aFileName);
		}
		[fileReader release];
    }
    else [self setHeader:nil];
}

- (void) removeFiles:(NSMutableArray*)anArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] addFilesToReplay:anArray];
    [filesToReplay removeObjectsInArray:anArray];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMjdDataScannerFileChangedNotification object: self];
}

- (void) removeFilesWithIndexes:(NSIndexSet*)indexSet;
{
    NSMutableArray* filesToRemove = [NSMutableArray array];
	NSUInteger current_index = [indexSet firstIndex];
    while (current_index != NSNotFound){
		[filesToRemove addObject:[filesToReplay objectAtIndex:current_index]];
        current_index = [indexSet indexGreaterThanIndex: current_index];
    }
	if([filesToRemove count]){
		[[[self undoManager] prepareWithInvocationTarget:self] addFilesToReplay:filesToRemove];
		[filesToReplay removeObjectsInArray:filesToRemove];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMjdDataScannerFileChangedNotification object: self];
	}
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];

	[[self undoManager] disableUndoRegistration];
	[self addFilesToReplay:[decoder decodeObjectForKey:@"fileList"]];
	[self setLastListPath: [decoder decodeObjectForKey:@"filePath"]];
	[self setLastFilePath: [decoder decodeObjectForKey:@"lastFilePath"]];
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:filesToReplay forKey:@"fileList"];
    [encoder encodeObject:lastListPath forKey:@"filePath"];
    [encoder encodeObject:lastFilePath forKey:@"lastFilePath"];
}

@end

@implementation ORMjdDataScannerModel (private)
- (void) replayFinished
{
    [self fileFinished];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMjdDataScannerStoppedNotification object: self];
}

- (void) fileFinished
{
}



@end

