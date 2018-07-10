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

typedef enum _eFileOpTransferType {
	eOpUseCURL	= 0,
	eOpUseSCP 	= 1,
	eOpUseSFTP 	= 2,
	eOpUseFTP 	= 3
}eFileOpTransferType;

@interface ORFileMoverOp : NSOperation {
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
	eFileOpTransferType   transferType;
	BOOL                verbose;
	BOOL                moveFilesToSentFolder;
	BOOL                useTempFile;
}
- (id)   init;
- (void) dealloc;

#pragma mark •••Accessors
- (void) setDelegate:(id)newDelegate;

- (void) setMoveParams:(NSString*)fullPath to:(NSString*)remoteFilePath remoteHost:(NSString*)remoteHost userName:(NSString*)remoteUserName passWord:(NSString*)passWord;
- (void) doNotMoveFilesToSentFolder;
- (void) moveFilesToSentFolder;
- (void) doNotUseTempFile;

#pragma mark •••Move Methods
- (void) main;
- (void) moveToSentFolder;
- (void) cleanSentFolder:(NSString*)dirPath;
- (void) readOutput:(NSFileHandle*)fileHandle;
- (void) checkOutput;

@property (copy)    NSString*   fileName;
@property (copy)    NSString*   remoteHost;
@property (copy)    NSString*   remotePath;
@property (copy)    NSString*   remoteUserName;
@property (copy)    NSString*   remotePassWord;
@property (copy)    NSString*   scriptFilePath;
@property (copy)    NSString*   fullPath;
@property (assign)  BOOL        verbose;
@property (assign)  eFileOpTransferType   transferType;
@property (assign)  id   delegate;
@property (retain)  NSTask*     task;

@end

@interface NSObject (ORFileMoverOpDelegate)
- (void) stopTheQueue;
- (BOOL) shouldRemoveFile:(NSString*)aFile;
- (void) fileMoverPercentChanged:(NSNumber*)aNumber;
- (void) fileMoverIsDone;

@end
