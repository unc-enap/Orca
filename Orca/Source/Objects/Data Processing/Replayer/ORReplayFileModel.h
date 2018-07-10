//
//  ORReplayFileModel.h
//  Orca
//
//  Created by Rielage on Thu Oct 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#pragma mark •••Imported Files
#import "OrcaObject.h"
#import "ORFileMover.h"

#pragma mark •••Forward Declarations
@class ORDataPacket;

@interface ORReplayFileModel :  OrcaObject
{
	@private
	FILE* 				filePointer;
	FILE* 				statusFilePointer;
	NSTimer*			fileSizeTimer;
	unsigned long		dataFileSize;
	NSString* 			directoryName;
	NSString* 			fileName;
	
	BOOL				copyEnabled;
	BOOL				deleteWhenCopied;
	BOOL				copyStatusEnabled;
	BOOL				deleteStatusWhenCopied;

	NSString*			remotePath;
	NSString*			remoteHost;
	NSString*			remoteUserName;
	NSString*			passWord;
	NSMutableArray* 	runningTasks;

	eFileTransferType 	transferType;
	BOOL        		verbose;
	int 				statusStart;
	
	
	//------------------internal use only
	NSString* 			_statusFileName;

}

#pragma mark •••Accessors
- (void) setDirectoryName:(NSString*)aFileName;
- (NSString*)directoryName;
- (void) setFileName:(NSString*)aFileName;
- (NSString*)fileName;
- (FILE*)filePointer;
- (void) setFilePointer:(FILE*)aFilePointer;
- (FILE*) statusFilePointer;
- (void) setStatusFilePointer:(FILE*)newStatusFilePointer;

- (unsigned long)dataFileSize;
- (void) setDataFileSize:(unsigned long)aSize;
- (NSTimer*) fileSizeTimer;
- (void) setFileSizeTimer:(NSTimer*)aTimer;
- (void) getDataFileSize:(NSTimer*)aTimer;

- (BOOL) copyEnabled;
- (void) setCopyEnabled:(BOOL)newCopyEnabled;
- (BOOL) deleteWhenCopied;
- (void) setDeleteWhenCopied:(BOOL)newDeleteWhenCopied;
- (BOOL) copyStatusEnabled;
- (void) setCopyStatusEnabled:(BOOL)newCopyEnabled;
- (BOOL) deleteStatusWhenCopied;
- (void) setDeleteStatusWhenCopied:(BOOL)newDeleteWhenCopied;
- (NSString*) remotePath;
- (void) setRemotePath:(NSString*)newRemotePath;
- (NSString*) remoteHost;
- (void) setRemoteHost:(NSString*)newRemoteHost;
- (NSString*) remoteUserName;
- (void) setRemoteUserName:(NSString*)newRemoteUserName;
- (NSString*) passWord;
- (void) setPassWord:(NSString*)newPassWord;
- (eFileTransferType) transferType;
- (void) setTransferType:(eFileTransferType)newTransferType;
- (BOOL) verbose;
- (void) setVerbose:(BOOL)newVerbose;


#pragma mark •••Data Handling
- (void) processData:(ORDataPacket*)someData;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket;

#pragma mark •••File Copying
- (void) sendFile:(NSString*)fullPath;
- (void) fileMoverIsDone: (NSNotification*)aNote;
- (BOOL) shouldRemoveFile:(NSString*)aFile;
- (void) sendAll;
- (void) deleteAll;

@end

#pragma mark •••External String Definitions
extern NSString* ORReplayDirChangedNotification;
extern NSString* ORReplayFileChangedNotification;
extern NSString* ORReplayFileStatusChangedNotification;
extern NSString* ORReplayFileSizeChangedNotification;

extern NSString* ORReplayFileCopyEnabledChangedNotification;
extern NSString* ORReplayFileDeleteWhenCopiedChangedNotification;
extern NSString* ORReplayFileCopyStatusEnabledChangedNotification;
extern NSString* ORReplayFileDeleteStatusWhenCopiedChangedNotification;
extern NSString* ORReplayFileRemotePathChangedNotification;
extern NSString* ORReplayFileRemoteHostChangedNotification;
extern NSString* ORReplayFilePassWordChangedNotification;
extern NSString* ORReplayFileUserNameChangedNotification;
extern NSString* ORReplayFileTransferTypeChangedNotification;
extern NSString* ORReplayFileVerboseChangedNotification;
