//
//  ORFileMover.h
//  Orca
//
//  Created by Mark Howe on Tue Jul 29 2003.
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

typedef enum _eFileTransferType {
	eUseCURL	= 0,
	eUseSCP 	= 1,
	eUseSFTP 	= 2,
	eUseFTP 	= 3
}eFileTransferType;

@interface ORFileMover : NSObject {
	id                  delegate;
	NSString*           fileName;
	NSString*           scriptFilePath;
	NSMutableString*    allOutput;
	NSTask*             task;
	NSString*           remotePath;
	NSString*           remoteHost;
	NSString*           remoteUserName;
	NSString*           remotePassWord;
	NSString*           fullPath;
    NSFileHandle*       readHandle;
	int                 percentDone;
	eFileTransferType   transferType;
	BOOL verbose;
	BOOL moveFilesToSentFolder;
	BOOL useTempFile;
}
- (id) init;
- (void) dealloc;

#pragma mark •••Accessors
- (id) delegate;
- (void) setDelegate:(id)newDelegate;
- (NSString*) fileName;
- (void) setFileName:(NSString*)newFileName;
- (NSTask*) task;
- (void) setTask:(NSTask*)newTask;
- (NSString*) scriptFilePath;
- (void) setScriptFilePath:(NSString*)newScriptFilePath;
- (NSString*) remotePath;
- (void) setRemotePath:(NSString*)newRemotePath;
- (NSString*) remoteHost;
- (void) setRemoteHost:(NSString*)newRemoteHost;
- (NSString*) remoteUserName;
- (void) setRemoteUserName:(NSString*)newRemoteUserName;
- (eFileTransferType) transferType;
- (void) setTransferType:(eFileTransferType)newTransferType;
- (BOOL) verbose;
- (void) setVerbose:(BOOL)newVerbose;
- (void) setMoveParams:(NSString*)fullPath to:(NSString*)remoteFilePath remoteHost:(NSString*)remoteHost userName:(NSString*)remoteUserName passWord:(NSString*)passWord;
- (void) setFullPath:(NSString*)aFullPath;
- (void) setRemotePassWord:(NSString*)aPassWord;
- (int) percentDone;
- (void) setPercentDone: (int) aPercentDone;
- (void) doNotMoveFilesToSentFolder;
- (void) moveFilesToSentFolder;
- (void) doNotUseTempFile;

#pragma mark •••Move Methods
- (void) launch;
- (void) doMove;
- (void) moveToSentFolder;
- (void) cleanSentFolder:(NSString*)dirPath;
- (void) stop;
- (void) tasksCompleted:(id)sender;
@end

extern NSString* ORFileMoverIsDoneNotification;
extern NSString* ORFileMoverCopiedFile;
extern NSString* ORFileMoverPercentDoneChanged;

@interface NSObject (ORFileMoverDelegate)
- (BOOL)shouldRemoveFile:(NSString*)aFile;
- (void) fileMoverPercentChanged: (NSNotification*)aNote;
- (void) fileMoverIsDone:(NSNotification*)aNote;
@end
