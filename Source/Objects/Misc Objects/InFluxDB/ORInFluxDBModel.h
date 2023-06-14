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
@class ORSafeQueue;
#import "ORInFluxDBCmd.h"

typedef enum { kInFluxDBConnectionBad,
               kInFluxDBConnectionOK,
               kInFluxDBConnectionUnknown } ORInFluxDBConnectionStatus;

@interface ORInFluxDBModel : OrcaObject
{
@private
    NSString*      hostName;
    NSTimer*       timer;
    NSInteger      totalSent;
    NSInteger      messageRate;
    BOOL           stealthMode;
    BOOL           scheduledForRunInfoUpdate;
    //NSString*      alertMessage;
    //int            alertType;
    NSString*      thisHostAddress;
    NSString*      experimentName;
    NSString*      runNumberString;
    NSString*      errorString;
    short          measurementTimeOut;
    short          maxLineCount;
    
    //----queue thread--------
    bool           canceled;
    NSThread*      processThread;
    ORSafeQueue*   messageQueue;
    
    NSMutableArray* bucketArray;
    NSArray*       orgArray;
    NSString*      org;
    NSMutableDictionary* cmdBuffer;
    
    //----http vars--------
    NSString*      authToken;
    ORInFluxDBConnectionStatus connectionStatus;
    ORAlarm*                   connectionAlarm;
    NSDate*                    lastAlarmDate;
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) applicationIsTerminating : (NSNotification*)aNote;
- (void) alarmPosted              : (NSNotification*)aNote;
- (void) alarmCleared             : (NSNotification*)aNote;
- (void) alarmAcknowledged        : (NSNotification*)aNote;

#pragma mark ***Accessors
- (ORInFluxDBConnectionStatus) connectionStatus;
- (void)        setConnectionStatus:(ORInFluxDBConnectionStatus)status;
- (void)        setConnectionStatusBad;
- (void)        setConnectionStatusOK;
- (void)        setConnectionStatusUnknown;
- (NSString*)   experimentName;
- (void)        setExperimentName:(NSString*)aName;
- (NSString*)   hostName;
- (void)        setHostName:(NSString*)aHost;
- (NSString*)   authToken;
- (void)        setAuthToken:(NSString*)aToken;
- (NSString*)   org;
- (NSString*)   orgId;
- (void)        setOrg:(NSString*)anOrg;
- (id)          nextObject;
- (NSInteger)   messageRate;
- (BOOL)        stealthMode;
- (void)        setStealthMode:(BOOL)aStealthMode;
- (void)        executeDBCmd:(id)aCmd;
- (NSArray*)    bucketArray;
- (NSArray*)    orgArray;
- (void)        deleteBucket:(NSInteger)index;
- (void)        createBuckets;
- (void)        decodeOrgList:(NSDictionary*)result;
- (void)        decodeBucketList:(NSDictionary*)result;
- (NSString*)   errorString;
- (void)        setErrorString:(NSString*)anError;
- (short)       measurementTimeOut;
- (void)        setMeasurementTimeOut:(short)aValue;
- (short)       maxLineCount;
- (void)        setMaxLineCount:(short)aValue;
- (void)        cmdFlush;

#pragma mark ***Thread
- (void) sendCmd:(ORInFluxDBCmd*)aCmd;
- (void) bufferMeasurement:(ORInFluxDBCmd*)aCmd;
- (void) sendMeasurments;

#pragma mark ***Scripting
-(ORInFluxDBMeasurement*) cmdForBucket:(NSString*)aBucket;


#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end


extern NSString* ORInFluxDBOrgArrayChanged;
extern NSString* ORInFluxDBBucketArrayChanged;
extern NSString* ORInFluxDBPortNumberChanged;
extern NSString* ORInFluxDBHostNameChanged;
extern NSString* ORInFluxDBRateChanged;
extern NSString* ORInFluxDBAuthTokenChanged;
extern NSString* ORInFluxDBOrgChanged;
extern NSString* ORInFluxDBStealthModeChanged;
extern NSString* ORInFluxDBBucketChanged;
extern NSString* ORInFluxDBErrorChanged;
extern NSString* ORInFluxDBConnectionStatusChanged;
extern NSString* ORInFluxDBMaxLineCountChanged;
extern NSString* ORInFluxDBMeasurementTimeOutChanged;;

extern NSString* ORInFluxDBLock;
