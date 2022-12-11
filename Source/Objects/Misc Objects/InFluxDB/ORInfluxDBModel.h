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

@interface ORInFluxDBModel : OrcaObject <NSURLConnectionDelegate>
{
@private
    NSMutableData *_responseData;
	NSString*  hostName;
    NSUInteger portNumber;
    NSString*  authToken;
    NSString*  org;
    NSString*  bucket;
    NSDate*    timeConnected;
    uint32_t   amountInBuffer;
    uint32_t   totalSent;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) applicationIsTerminating:(NSNotification*)aNote;

#pragma mark ***Accessors
- (void)        setPortNumber:(NSUInteger)aPort;
- (NSUInteger)  portNumber;
- (NSString*)   hostName;
- (void)        setHostName:(NSString*)aHostName;
- (NSString*)   authToken;
- (void)        setAuthToken:(NSString*)aToken;
- (NSString*)   org;
- (void)        setBucket:(NSString*)anOrg;
- (NSString*)   bucket;
- (void)        setOrg:(NSString*)anOrg;
- (id)          nextObject;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

- (void) testPost;

@end
//a thin wrapper around NSOperationQueue to make a shared queue for InFlux access
@interface ORInFluxDBQueue : NSObject {
    NSOperationQueue* queue;
}
+ (ORInFluxDBQueue*) sharedInFluxDBQueue;
+ (void) addOperation:(NSOperation*)anOp;
+ (NSOperationQueue*) queue;
+ (NSUInteger) operationCount;
+ (void) cancelAllOperations;
- (void) addOperation:(NSOperation*)anOp;
- (NSOperationQueue*) queue;
- (void) cancelAllOperations;
- (NSInteger) operationCount;
@end

extern NSString* ORInFluxDBPortNumberChanged;
extern NSString* ORInFluxDBHostNameChanged;
extern NSString* ORInFluxDBAuthTokenChanged;
extern NSString* ORInFluxDBOrgChanged;
extern NSString* ORInFluxDBBucketChanged;
extern NSString* ORInFluxDBTimeConnectedChanged;
extern NSString* ORInFluxDBLock;



