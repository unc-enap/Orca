//-------------------------------------------------------------------------
//  ORInFluxDBModel.h
//
// Created by Mark Howe on 12/7/2022.

//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
@class ORInFluxDB;
@class ORAlarm;

@interface ORInFluxDBModel : OrcaObject
{
@private
	NSString*       remoteHostName;
    NSString*       userName;
    NSString*       password;
    NSString*       localHostName;
    NSUInteger      portNumber;
	//cache
    NSString*       thisHostAdress;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) applicationIsTerminating:(NSNotification*)aNote;


#pragma mark ***Accessors
- (NSString*) password;
- (void) setPortNumber:(NSUInteger)aPort;
- (NSUInteger) portNumber;
- (void) setPassword:(NSString*)aPassword;
- (NSString*) userName;
- (void) setUserName:(NSString*)aUserName;
- (NSString*) remoteHostName;
- (void) setRemoteHostName:(NSString*)aHostName;
- (NSString*) localHostName;
- (void) setLocalHostName:(NSString*)aHostName;
- (id) nextObject;
- (NSString*) databaseName;

#pragma mark ***DB Access
- (ORInFluxDB*) remoteDBRef:(NSString*)aDatabaseName;
- (ORInFluxDB*) remoteDBRef;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORInFluxDBPasswordChanged;
extern NSString* ORInFluxDBPortNumberChanged;
extern NSString* ORInFluxDBUserNameChanged;
extern NSString* ORInFluxDBRemoteHostNameChanged;
extern NSString* ORInFluxDBModelDBInfoChanged;
extern NSString* ORInFluxDBLocalHostNameChanged;
extern NSString* ORInFluxDBLock;



