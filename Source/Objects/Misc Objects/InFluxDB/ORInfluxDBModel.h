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

enum {
    kUseInFluxHttpProtocol,
    kUseTelegrafLineProtocol,
};
@interface ORInFluxDBModel : OrcaObject <NSURLConnectionDelegate,NSStreamDelegate>
{
@private
    NSMutableString* outputBuffer;
    NSString*      hostName;
    NSInteger      portNumber;
    NSInteger      accessType;
    NSString*      tags;
    NSTimer*       timer;
    NSInteger      totalSent;
    NSInteger      messageRate;
    //----queue thread--------
    bool           canceled;
    NSThread*      processThread;
    ORSafeQueue*   messageQueue;
    
    //----telegraf vars--------
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;

    NSInputStream*  inputStream;
    NSOutputStream* outputStream;
    short socketStatus;
    
    //----http vars--------
    NSMutableData* responseData;
    bool           isConnected;
    NSString*      authToken;
    NSString*      org;
    NSString*      bucket;
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) applicationIsTerminating:(NSNotification*)aNote;

#pragma mark ***Accessors
- (void)        setPortNumber:(NSUInteger)aPort;
- (NSUInteger)  portNumber;
- (void)        setAccessType:(NSInteger)aType;
- (NSInteger)   accessType;
- (NSString*)   hostName;
- (void)        setHostName:(NSString*)aHost;
- (NSString*)   authToken;
- (void)        setAuthToken:(NSString*)aToken;
- (NSString*)   org;
- (void)        setBucket:(NSString*)anOrg;
- (NSString*)   bucket;
- (void)        setOrg:(NSString*)anOrg;
- (id)          nextObject;
- (short)       socketStatus;
- (BOOL)        isConnected;
- (void)        setIsConnected:(BOOL)aState;
- (uint32_t)    queueMaxSize;
- (NSInteger)   messageRate;

#pragma mark ***Measurements
- (void) setTags:(NSString*) someTags;
- (void) startMeasurement:(NSString*)aSection;
- (void) endMeasurement;

- (void) addLong:(NSString*)aValueName withValue:(long)aValue;
- (void) addDouble:(NSString*)aValueName withValue:(double)aValue;
- (void) addString:(NSString*)aValueName withValue:(NSString*)aValue;
- (void) push;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

- (void) testPost;

@end

extern NSString* ORInFluxDBPortNumberChanged;
extern NSString* ORInFluxDBHostNameChanged;
extern NSString* ORInFluxDBRateChanged;
extern NSString* ORInFluxDBAuthTokenChanged;
extern NSString* ORInFluxDBOrgChanged;
extern NSString* ORInFluxDBBucketChanged;
extern NSString* ORInFluxDBTimeConnectedChanged;
extern NSString* ORInFluxDBAccessTypeChanged;
extern NSString* ORInFluxDBSocketStatusChanged;

extern NSString* ORInFluxDBLock;



