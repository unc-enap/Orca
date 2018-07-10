//-------------------------------------------------------------------------
//  ORRaidMonitorModel.h
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

#pragma mark ***Imported Files

#import "OrcaObject.h"
@class ORAlarm;
@class ORFileMoverOp;
@class ORFileGetterOp;

@interface ORRaidMonitorModel : OrcaObject
{
  @private
    NSOperationQueue*	fileQueue;
    NSString*           userName;
    NSString*           password;
    NSString*           ipAddress;
    NSString*           remotePath;
    NSString*           localPath;
    NSMutableString*    allOutput;
    NSMutableDictionary* resultDict;
    BOOL                running;
	ORAlarm*            noConnectionAlarm;
	ORAlarm*            diskFullAlarm;
	ORAlarm*            scriptNotRunningAlarm;
	ORAlarm*            badDiskAlarm;
    NSDateFormatter*    dateFormatter;
    NSDateFormatter*    dateConvertFormatter;
    ORFileMoverOp*      fileMover;
    ORFileGetterOp*     mover;
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

#pragma mark ***Accessors
- (NSDictionary*)   resultDictionary;
- (NSString*)   localPath;
- (void)        setLocalPath:(NSString*)aLocalPath;
- (NSString*)   remotePath;
- (void)        setRemotePath:(NSString*)aRemotePath;
- (NSString*)   ipAddress;
- (void)        setIpAddress:(NSString*)aIpAddress;
- (NSString*)   password;
- (void)        setPassword:(NSString*)aPassword;
- (NSString*)   userName;
- (void)        setUserName:(NSString*)aUserName;
- (void)        checkAlarms;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***scp action
- (void) getStatus;
- (void) fileGetterIsDone;
- (void) shutdown;
- (void) fileMoverIsDone;
@end

extern NSString* ORRaidMonitorModelResultDictionaryChanged;
extern NSString* ORRaidMonitorModelLocalPathChanged;
extern NSString* ORRaidMonitorModelRemotePathChanged;
extern NSString* ORRaidMonitorIpAddressChanged;
extern NSString* ORRaidMonitorPasswordChanged;
extern NSString* ORRaidMonitorUserNameChanged;
extern NSString* ORRaidMonitorLock;


