//
//  ORReplayDataModel.m
//  Orca
//
//  Created by Rielage on Thu Oct 02 2003.
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
#import "ORReplayDataModel.h"
#import "ORHeaderItem.h"
#import "ORFileReader.h"
#import "ORDecoder.h"
#import "ORDataChainObject.h"
#import "ORDataSet.h"
#import "ORDataTaker.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORReplayFileListChangedNotification = @"ORReplayFileListChangedNotification";

NSString* ORReplayRunningNotification		  = @"ORReplayRunningNotification";
NSString* ORReplayStoppedNotification		  = @"ORReplayStoppedNotification";
NSString* ORRelayFileChangedNotification		= @"ORRelayFileChangedNotification";
NSString* ORReplayProgressChangedNotification	= @"ORReplayProgressChangedNotification";

#pragma mark ¥¥¥Definitions
static NSString *ORReplayDataConnection = @"Replay File Input Connector";

@interface ORReplayDataModel (private)
- (void) replayFinished;
- (void) fileFinished;
@end


@implementation ORReplayDataModel

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}


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

- (void) makeConnectors
{
	ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,30) withGuardian:self withObjectLink:self];
	[[self connectors] setObject:aConnector forKey:ORReplayDataConnection];
	[aConnector setIoType:kOutputConnector];
	[aConnector release];
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"ReplayData"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORReplayDataController"];
}

- (NSString*) helpURL
{
	return @"Data_Format_Viewing/Data_Replay.html";
}

#pragma mark ¥¥¥Accessors

- (NSString*) fileToReplay
{
    if(fileToReplay)return fileToReplay;
    else return @"";
}

- (void) setFileToReplay:(NSString*)newFileToReplay
{    
    [fileToReplay autorelease];
    fileToReplay=[newFileToReplay retain];
    
	NSLog(@"Replaying: %@\n",[newFileToReplay  stringByAbbreviatingWithTildeInPath]);
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRelayFileChangedNotification
	 object: self];
    
}

- (NSArray*) filesToReplay
{
    return filesToReplay;
}

- (void) addFilesToReplay:(NSMutableArray*)newFilesToReplay
{
    
    if(!filesToReplay){
        filesToReplay = [[NSMutableArray array] retain];
    }
    
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
	 postNotificationName:ORReplayFileListChangedNotification
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


#pragma mark ¥¥¥File Actions

- (void) removeAll
{
    [filesToReplay removeAllObjects];
}

- (void) replayFiles
{
	if(![filesToReplay count])return;
	if([self isReplaying]) return;
	stop = NO;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORReplayRunningNotification object: self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NeedFullDecode" object:self];

	sentRunStart = NO;
	if(!queue){
		queue = [[NSOperationQueue alloc] init];
	}
	
	[queue setMaxConcurrentOperationCount:1]; //can only do one at a time
	
	for(id aPath in filesToReplay){
		ORFileReader* fileReader = [[ORFileReader alloc] initWithPath:aPath delegate:self];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:ORReplayProgressChangedNotification object: self];		
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

- (void) sendRunStart:(NSDictionary*)userInfo
{
	[userInfo retain];
	nextObject = [self objectConnectedTo:ORReplayDataConnection];
    [nextObject runTaskStarted:userInfo];
	[nextObject setInvolvedInCurrentRun:YES];
	[userInfo release];
}

- (void) sendDataArray:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder
{
	if([dataArray count]){
		nextObject = [self objectConnectedTo:ORReplayDataConnection];
		[nextObject processData:dataArray decoder:aDecoder];
	}
}
- (void) sendRunEnd:(NSDictionary*)userInfo
{
	[userInfo retain];
	nextObject = [self objectConnectedTo:ORReplayDataConnection];
    [nextObject runTaskStopped:userInfo];
	[userInfo release];
}

- (void) sendCloseOutRun:(NSDictionary*)userInfo
{
	[userInfo retain];
	nextObject = [self objectConnectedTo:ORReplayDataConnection];
    [nextObject closeOutRun:userInfo];
	[userInfo release];
}

- (void) sendRunSubRunStart:(NSDictionary*)userInfo
{
	[userInfo retain];
	nextObject = [self objectConnectedTo:ORReplayDataConnection];
    [nextObject subRunTaskStarted:userInfo];
	[userInfo release];
}

- (void) readHeaderForFileIndex:(int)index
{
    if(index>=0 && [filesToReplay count]){
		NSString* aFileName = [filesToReplay objectAtIndex:index];
		ORFileReader* fileReader = [[ORFileReader alloc] initWithPath:aFileName delegate:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORReplayFileListChangedNotification object: self];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORReplayFileListChangedNotification object: self];
	}
}

#pragma mark ¥¥¥Archival
static NSString* ORReplayFileList 			= @"ORReplayFileList";
static NSString* ORLastListPath 			= @"ORLastListPath";
static NSString* ORLastFilePath 			= @"ORLastFilePath";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];

	[[self undoManager] disableUndoRegistration];
	[self addFilesToReplay:[decoder decodeObjectForKey:ORReplayFileList]];
	[self setLastListPath:[decoder decodeObjectForKey:ORLastListPath]];
	[self setLastFilePath:[decoder decodeObjectForKey:ORLastFilePath]];
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:filesToReplay forKey:ORReplayFileList];
    [encoder encodeObject:lastListPath forKey:ORLastListPath];
    [encoder encodeObject:lastFilePath forKey:ORLastFilePath];
}

@end

@implementation ORReplayDataModel (private)
- (void) replayFinished
{
    [self fileFinished];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DoneWithFullDecode" object:self];

    [nextObject runTaskStopped:nil];
    [nextObject closeOutRun:nil];
	[nextObject setInvolvedInCurrentRun:NO];
		
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORReplayStoppedNotification object: self];
	
}

 ///keep!!!
- (void) fileFinished
{
    [nextObject runTaskBoundary];
}



@end

