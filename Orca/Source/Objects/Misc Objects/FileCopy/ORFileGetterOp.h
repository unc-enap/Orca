//
//  ORFileGetterOp.h
//  Orca
//
//  Created by Mark Howe on Saturday 12/21/2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
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

@interface ORFileGetterOp : NSOperation {
	id                  delegate;
	NSString*           scriptFilePath;
	NSMutableString*    allOutput;
	NSTask*             task;
	NSString*           remotePath;
	NSString*           ipAddress;
	NSString*           userName;
	NSString*           passWord;
	NSString*           localPath;
	NSString*           fullPath;
    NSString*           doneSelectorName;
    BOOL                useFTP;   //default. If false will use SCP
}
- (id)   init;
- (void) dealloc;

#pragma mark •••Accessors
- (void) setDelegate:(id)newDelegate;
- (void) setParams:(NSString*)remoteFilePath localPath:(NSString*)aLocalPath ipAddress:(NSString*)anIpAddress userName:(NSString*)remoteUserName passWord:(NSString*)passWord;

#pragma mark •••Move Methods
- (void) main;
- (void) readOutput:(NSFileHandle*)fileHandle;

@property (copy)    NSString*   ipAddress;
@property (copy)    NSString*   remotePath;
@property (copy)    NSString*   localPath;
@property (copy)    NSString*   userName;
@property (copy)    NSString*   passWord;
@property (copy)    NSString*   scriptFilePath;
@property (copy)    NSString*   fullPath;
@property (assign)  id          delegate;
@property (retain)  NSTask*     task;
@property (assign)  BOOL        useFTP;
@property (copy)    NSString*   doneSelectorName;

@end

