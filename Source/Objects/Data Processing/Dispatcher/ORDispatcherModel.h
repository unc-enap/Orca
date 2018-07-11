//
//  ORDispatcherModel.h
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORDataChainObject.h"
#import "ORDataProcessing.h"

#pragma mark ¥¥¥Forward Declarations
@class NetSocket;
@class ORDispatcherClient;
@class ORDecoder;

#define kORDispatcherPort 44666


@interface ORDispatcherModel :  ORDataChainObject <ORDataProcessing>  
{
    @private
	int             socketPort;
	NetSocket*      serverSocket;
	NSMutableArray*	clients;
	NSMutableDictionary*         currentHeader;
    BOOL            checkAllowed;
    BOOL            checkRefused;
	BOOL            _ignoreMode;
	BOOL            scheduledForUpdate;
    NSArray*        allowedList;
    NSArray*        refusedList;
	BOOL            runInProgress;
	int             runMode;
    BOOL            ignoreBlock;
}

- (void)serve;

#pragma mark ¥¥¥Accessors
- (int) socketPort;
- (void) setSocketPort:(int)aPort;
- (void) setClients:(NSMutableArray*)someClients;
- (NSArray*)clients;
- (BOOL) isAlreadyConnected:(ORDispatcherClient*)aNewClient;
- (BOOL) checkAllowed;
- (void) setCheckAllowed: (BOOL) flag;
- (BOOL) checkRefused;
- (void) setCheckRefused: (BOOL) flag;
- (NSArray *) allowedList;
- (void) setAllowedList: (NSArray *) AllowedList;
- (NSArray *) refusedList;
- (void) setRefusedList: (NSArray *) RefusedList;
- (void) parseAllowedList:(NSString*)aString;
- (void) parseRefusedList:(NSString*)aString;
- (BOOL) allowConnection:(ORDispatcherClient*)aNewClient;
- (BOOL) refuseConnection:(ORDispatcherClient*)aNewClient;
- (void) checkConnectedClients;
- (void) report;
- (NSUInteger) clientCount;
- (void) scheduleUpdateOnMainThread;
- (void) postUpdateOnMainThread;
- (void) postUpdate;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) runAboutToStop:(NSNotification*) aNote;

#pragma mark ¥¥¥Data Handling
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
- (void) runTaskStarted:(NSDictionary*)userInfo;
- (void) runTaskStopped:(NSDictionary*)userInfo;
- (void) preCloseOut:(NSDictionary*)userInfo;
- (void) closeOutRun:(NSDictionary*)userInfo;
- (void) clientDisconnected:(id)aClient;

#pragma mark ¥¥¥Delegate Methods
- (void) netsocket:(NetSocket*)inNetSocket connectionAccepted:(NetSocket*)inNewNetSocket;
- (void) clientChanged:(id)aClient;
- (void) setRunMode:(int)aMode;

@end

extern NSString* ORDispatcherPortChangedNotification;
extern NSString* ORDispatcherClientsChangedNotification;
extern NSString* ORDispatcherClientDataChangedNotification;
extern NSString* ORDispatcherCheckRefusedChangedNotification;
extern NSString* ORDispatcherCheckAllowedChangedNotification;
extern NSString* ORDispatcherLock;


