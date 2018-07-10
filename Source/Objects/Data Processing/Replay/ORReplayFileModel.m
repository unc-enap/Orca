//
//  ORReplayFileModel.m
//  Orca
//
//  Created by Rielage on Thu Oct 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#pragma mark •••Imported Files
#import "ORReplayFileModel.h"
#import "ORConnector.h"
#import "StatusLog.h"
#import "ORDataPacket.h"
#import <unistd.h>
#import "ORStatusController.h"
#import "ORDocument.h"

#pragma mark •••Notification Strings
NSString* ORReplayDirChangedNotification				= @"The ReplayFile Dir Changed";
NSString* ORReplayFileChangedNotification				= @"The ReplayFile File Has Changed";
NSString* ORReplayFileStatusChangedNotification 		= @"The DataFile Status Has Changed";
NSString* ORReplayFileSizeChangedNotification 		= @"The ReplayFile Size Has Changed";
NSString* ORReplayFileCopyEnabledChangedNotification 	= @"ORReplayFileCopyEnabledChangedNotification";
NSString* ORReplayFileDeleteWhenCopiedChangedNotification=@"ORReplayFileDeleteWhenCopiedChangedNotification";
NSString* ORReplayFileCopyStatusEnabledChangedNotification 	= @"ORReplayFileCopyStatusEnabledChangedNotification";
NSString* ORReplayFileDeleteStatusWhenCopiedChangedNotification=@"ORReplayFileDeleteStatusWhenCopiedChangedNotification";
NSString* ORReplayFileRemotePathChangedNotification	=@"ORReplayFileRemotePathChangedNotification";
NSString* ORReplayFileRemoteHostChangedNotification	=@"ORReplayFileRemoteHostChangedNotification";
NSString* ORReplayFilePassWordChangedNotification		=@"ORReplayFilePassWordChangedNotification";
NSString* ORReplayFileUserNameChangedNotification		=@"ORReplayFileUserNameChangedNotification";
NSString* ORReplayFileTransferTypeChangedNotification =@"ORReplayFileTransferTypeChangedNotification";
NSString* ORReplayFileVerboseChangedNotification 		=@"ORReplayFileVerboseChangedNotification";

#pragma mark •••Definitions
static NSString *ORReplayFileConnection 		= @"Replay File Input Connector";

@implementation ORReplayFileModel

#pragma mark •••Initialization
- (id) init //designated initializer
{
    self = [super init];

	[[self undoManager] disableUndoRegistration];
	[self setDirectoryName:@"~"];
	[self setFilePointer:NULL];
	[self setStatusFilePointer:NULL];
	[self setRemoteHost:@""];
	[self setRemoteUserName:@""];
	[self setPassWord:@""];
	[[self undoManager] enableUndoRegistration];

    return self;
}


- (void) dealloc
{
	if(filePointer){
		fclose(filePointer);
		filePointer = nil;
	}
	if(statusFilePointer){
		fclose(statusFilePointer);
		statusFilePointer = nil;
	}
	[self setFileSizeTimer:nil];
	[_statusFileName release];
	[fileName release];
	[directoryName release];
	[remoteHost release];
	[remoteUserName release];
	[passWord release];
	[runningTasks release];
	
    [super dealloc];
}

- (void) makeConnectors
{
	ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self x],[self y]+15) withParent:self withObjectLink:self];
	[[self connectors] setObject:aConnector forKey:ORReplayFileConnection];
	[aConnector release];
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"DataFile"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORReplayFileController"];
}

#pragma mark •••Accessors
- (void) setDirectoryName:(NSString*)aDirName
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDirectoryName:[self directoryName]];


	[directoryName autorelease];
    directoryName = [aDirName copy];
	
	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayDirChangedNotification
				object:self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
	
}

- (NSString*)directoryName
{
	return directoryName;
}

- (void) setFileName:(NSString*)aFileName
{

	[fileName autorelease];
    fileName = [aFileName copy];

	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFileChangedNotification
				object:self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
}

- (NSString*)fileName
{
	return fileName;
}


- (void) setFilePointer:(FILE*)aFilePointer
{
	filePointer = aFilePointer; 
}

- (FILE*)filePointer
{
	return filePointer;
}

- (FILE*) statusFilePointer
{
	return statusFilePointer;
}
- (void) setStatusFilePointer:(FILE*)newStatusFilePointer
{
	statusFilePointer = newStatusFilePointer;
}


- (NSTimer*) fileSizeTimer
{
	return fileSizeTimer;
}

- (void) setFileSizeTimer:(NSTimer*)aTimer
{
	[fileSizeTimer invalidate];
	[aTimer retain];
	[fileSizeTimer release];
	fileSizeTimer = aTimer;
}

- (BOOL) copyEnabled
{
	return copyEnabled;
}
- (void) setCopyEnabled:(BOOL)newCopyEnabled
{
	[[[self undoManager] prepareWithInvocationTarget:self] setCopyEnabled:copyEnabled];

	copyEnabled=newCopyEnabled;

	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFileCopyEnabledChangedNotification
				object: self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
}

- (BOOL) deleteWhenCopied
{
	return deleteWhenCopied;
}
- (void) setDeleteWhenCopied:(BOOL)newDeleteWhenCopied
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDeleteWhenCopied:deleteWhenCopied];

	deleteWhenCopied=newDeleteWhenCopied;
	
	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFileDeleteWhenCopiedChangedNotification
				object: self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
}

- (BOOL) copyStatusEnabled
{
	return copyStatusEnabled;
}
- (void) setCopyStatusEnabled:(BOOL)newCopyStatusEnabled
{
	[[[self undoManager] prepareWithInvocationTarget:self] setCopyStatusEnabled:copyStatusEnabled];

	copyStatusEnabled=newCopyStatusEnabled;

	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFileCopyStatusEnabledChangedNotification
				object: self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
}

- (BOOL) deleteStatusWhenCopied
{
	return deleteStatusWhenCopied;
}
- (void) setDeleteStatusWhenCopied:(BOOL)newDeleteStatusWhenCopied
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDeleteStatusWhenCopied:deleteWhenCopied];

	deleteStatusWhenCopied=newDeleteStatusWhenCopied;
	
	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFileDeleteStatusWhenCopiedChangedNotification
				object: self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
}


- (NSString*) remotePath
{
	return remotePath;
}
- (void) setRemotePath:(NSString*)newRemotePath
{
	[[[self undoManager] prepareWithInvocationTarget:self] setRemotePath:remotePath];
	[remotePath autorelease];
	remotePath=[newRemotePath retain];
	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFileRemotePathChangedNotification
				object: self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];

}



- (NSString*) remoteHost
{
	return remoteHost;
}
- (void) setRemoteHost:(NSString*)newRemoteHost
{
	[[[self undoManager] prepareWithInvocationTarget:self] setRemoteHost:remoteHost];

	[remoteHost autorelease];
	remoteHost=[newRemoteHost retain];

	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFileRemoteHostChangedNotification
				object: self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
}

- (NSString*) remoteUserName
{
	return remoteUserName;
}
- (void) setRemoteUserName:(NSString*)newRemoteUserName
{
	[[[self undoManager] prepareWithInvocationTarget:self] setRemoteUserName:remoteUserName];

	[remoteUserName autorelease];
	remoteUserName=[newRemoteUserName retain];

	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFileUserNameChangedNotification
				object: self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
}

- (NSString*) passWord
{
	return passWord;
}
- (void) setPassWord:(NSString*)newPassWord
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPassWord:passWord];

	[passWord autorelease];
	passWord=[newPassWord retain];

	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFilePassWordChangedNotification
				object: self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
}

- (eFileTransferType) transferType
{
	return transferType;
}

- (void) setTransferType:(eFileTransferType)newTransferType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setTransferType:transferType];

	transferType=newTransferType;

	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFileTransferTypeChangedNotification
				object: self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
}

- (BOOL) verbose
{
	return verbose;
}
- (void) setVerbose:(BOOL)newVerbose
{
	[[[self undoManager] prepareWithInvocationTarget:self] setVerbose:verbose];

	verbose=newVerbose;
	
	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFileVerboseChangedNotification
				object: self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
}




#pragma mark •••Data Handling
- (void) fileMoverIsDone: (NSNotification*)aNote
{
	[runningTasks removeObject:[aNote object]];
}

- (void) processData:(ORDataPacket*)aDataPacket
{
	if(filePointer && [[self document] runMode] == kNormalRun){
		[aDataPacket writeData:filePointer];
	}
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket
{
	if([[self document] runMode] == kNormalRun){
		//open file and write headers
		[self setFileName:[NSString stringWithFormat:@"Run%d",[aDataPacket runNumber]]];

		if(copyStatusEnabled){
			statusStart = [[ORStatusController sharedStatusController] statusTextlength];
		}


		if(fileName){
			NSString* fullFileName = [[[self directoryName]stringByExpandingTildeInPath] stringByAppendingPathComponent:[self fileName]];
			NSLog(@"Opening dataFile: %@\n",fullFileName);
			filePointer = fopen([fullFileName cString],"w+");
			if(filePointer){
				[aDataPacket writeHeader: filePointer];
			}
		}

		[[NSNotificationCenter defaultCenter]
					postNotificationName:ORReplayFileStatusChangedNotification
								  object: self
								userInfo: [NSDictionary dictionaryWithObject: self
															 forKey:ORNotificationSender]];


		[self getDataFileSize:nil];
		[self setFileSizeTimer:[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(getDataFileSize:) userInfo:nil repeats:YES]];
		
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket
{
	if(filePointer && [[self document] runMode] == kNormalRun){
		
		[self getDataFileSize:nil];
		[self setFileSizeTimer:nil];

		//write out the last of the data if any
		[aDataPacket writeData:filePointer];
		
		fclose(filePointer);
		filePointer = nil;
		
		NSString* fullFileName = [[[self directoryName]stringByExpandingTildeInPath] stringByAppendingPathComponent:[self fileName]];
		NSLog(@"Closing dataFile: %@\n",fullFileName);
		

		if(copyEnabled){		
			//start a copy of the Data File
			[self sendFile:fullFileName];
		}
		

		if(copyStatusEnabled){	
			//start a copy of the Status File
					
			int statusEnd = [[ORStatusController sharedStatusController] statusTextlength];

			_statusFileName = [[NSString stringWithFormat:@"Status_%d",[aDataPacket runNumber]] retain];
			
			NSString* fullStatusFileName = [[[self directoryName]stringByExpandingTildeInPath] stringByAppendingPathComponent:_statusFileName];
			statusFilePointer = fopen([fullStatusFileName cString],"w+");
			NSString* text = [[[ORStatusController sharedStatusController] text] substringWithRange:NSMakeRange(statusStart, statusEnd - statusStart)];
			fprintf(statusFilePointer,"%s",[text cString]);
			fclose(statusFilePointer);
	
			[self sendFile:fullStatusFileName];

		}

		
	}
	
	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayFileStatusChangedNotification
				object: self
				userInfo: [NSDictionary dictionaryWithObject: self
				forKey:ORNotificationSender]];
}

- (void) sendFile:(NSString*)fullPath
{
	ORFileMover* mover = [[ORFileMover alloc] init];
	if(!runningTasks)runningTasks = [[NSMutableArray array] retain];
	[runningTasks addObject:mover];
	[mover setTransferType:[self transferType]];
	[mover setVerbose:[self verbose]];
	[mover setDelegate:self];
	
	NSString* remoteFilePath = [remotePath stringByAppendingPathComponent:[fullPath lastPathComponent]];
	
	[mover move:fullPath to:remoteFilePath remoteHost:remoteHost userName:remoteUserName passWord:passWord];
	
	[mover release]; //still retained by the array, will be release fully when copy is done.
}

- (BOOL) shouldRemoveFile:(NSString*)aFile
{
	if([fileName isEqualToString:[aFile lastPathComponent]]){
		if(deleteWhenCopied)return YES;
		else return NO;
	}
	else if([_statusFileName isEqualToString:[aFile lastPathComponent]]){
		if(deleteStatusWhenCopied)return YES;
		else return NO;
	}
	else return NO;
}

- (void) sendAll
{

	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSArray* files = [fileManager directoryContentsAtPath:[[self directoryName]stringByExpandingTildeInPath]];
	NSEnumerator* e = [files objectEnumerator];
	NSString* aFile;
	while(aFile = [e nextObject]){
		NSString* fullName = [[[self directoryName] stringByAppendingPathComponent:aFile] stringByExpandingTildeInPath];
		BOOL isDir;
		if ([fileManager fileExistsAtPath:fullName isDirectory:&isDir] && !isDir){
			NSRange range = [fullName rangeOfString:@".DS_Store"];
			if(range.location == NSNotFound){
				[self sendFile:fullName];
			}
		}
	}
}

- (void) deleteAll
{
	ORFileMover* mover = [[ORFileMover alloc] init];
	if(!runningTasks)runningTasks = [[NSMutableArray array] retain];
	[runningTasks addObject:mover];
	[mover cleanSentFolder:[[self directoryName]stringByExpandingTildeInPath]];
	[mover release];
}


- (unsigned long)dataFileSize
{
	return dataFileSize;
}

- (void) setDataFileSize:(unsigned long)aNumber
{
	dataFileSize = aNumber;
	
	[[NSNotificationCenter defaultCenter]
			postNotificationName:ORReplayFileSizeChangedNotification
			object: self
			userInfo: [NSDictionary dictionaryWithObject: self
			forKey:ORNotificationSender]];
	
}

- (void) getDataFileSize:(NSTimer*)timer
{
	NSNumber* fsize;
	NSFileManager* manager = [NSFileManager defaultManager];
	NSString* fullFileName = [[[self directoryName]stringByExpandingTildeInPath] stringByAppendingPathComponent:[self fileName]];
	NSDictionary *fattrs = [manager fileAttributesAtPath:fullFileName traverseLink:YES];
	if (fsize = [fattrs objectForKey:NSFileSize]){
		[self setDataFileSize:[fsize intValue]];
	}
}

#pragma mark •••Archival
static NSString* ORReplayDirName 			= @"Replay file dir name";
static NSString* ORReplayCopyEnabled		= @"ORReplay CopyEnabled";
static NSString* ORReplayDeleteWhenCopied	= @"ORReplay DeleteWhenCopied";
static NSString* ORReplayCopyStatusEnabled		= @"ORReplay CopyStatusEnabled";
static NSString* ORReplayDeleteStatusWhenCopied	= @"ORReplay DeleteStatusWhenCopied";
static NSString* ORReplayRemotePath		= @"ORReplay Remote Path";
static NSString* ORReplayRemoteHost		= @"ORReplay Remote Host";
static NSString* ORReplayRemoteUserName	= @"ORReplay Remote UserName";
static NSString* ORReplayPassWord			= @"ORReplay PassWord";
static NSString* ORReplayTransferType		= @"ORReplay Transfer Type";
static NSString* ORReplayVerbose			= @"ORReplay Verbose";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];

	[[self undoManager] disableUndoRegistration];
	[self setDirectoryName:[decoder decodeObjectForKey:ORReplayDirName]];
	[self setCopyEnabled:[decoder decodeBoolForKey:ORReplayCopyEnabled]];
	[self setDeleteWhenCopied:[decoder decodeBoolForKey:ORReplayDeleteWhenCopied]];
	[self setCopyStatusEnabled:[decoder decodeBoolForKey:ORReplayCopyStatusEnabled]];
	[self setDeleteStatusWhenCopied:[decoder decodeBoolForKey:ORReplayDeleteStatusWhenCopied]];
	[self setRemotePath:[decoder decodeObjectForKey:ORReplayRemotePath]];
	[self setRemoteHost:[decoder decodeObjectForKey:ORReplayRemoteHost]];
	[self setPassWord:[decoder decodeObjectForKey:ORReplayPassWord]];
	[self setRemoteUserName:[decoder decodeObjectForKey:ORReplayRemoteUserName]];
	[self setTransferType:[decoder decodeIntForKey:ORReplayTransferType]];
	[self setVerbose:[decoder decodeBoolForKey:ORReplayVerbose]];
	[[self undoManager] enableUndoRegistration];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject:[self directoryName] forKey:ORReplayDirName];
	[encoder encodeBool:[self copyEnabled] forKey:ORReplayCopyEnabled];
	[encoder encodeBool:[self deleteWhenCopied] forKey:ORReplayDeleteWhenCopied];
	[encoder encodeBool:[self copyStatusEnabled] forKey:ORReplayCopyStatusEnabled];
	[encoder encodeBool:[self deleteStatusWhenCopied] forKey:ORReplayDeleteStatusWhenCopied];
	[encoder encodeObject:[self remotePath] forKey:ORReplayRemotePath];
	[encoder encodeObject:[self remoteHost] forKey:ORReplayRemoteHost];
	[encoder encodeObject:[self remoteUserName] forKey:ORReplayRemoteUserName];
	[encoder encodeObject:[self passWord] forKey:ORReplayPassWord];
	[encoder encodeInt:[self transferType] forKey:ORReplayTransferType];
	[encoder encodeBool:[self verbose] forKey:ORReplayVerbose];
}

@end


