//-------------------------------------------------------------------------
//  ORSensorPushModel.h
//
//  Created by Mark Howe on Friday 08/04/2023.
//  Copyright (c) 2023 University of North Carolina. All rights reserved.
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
@class ORNode;

@interface ORSensorPushModel : OrcaObject
{
  @private
    NSString*           userName;
    NSString*           password;
    bool                running;
    NSTask*             task;
    NSTimeInterval      tokenTime; //Tokens valid for 30 minutes
    NSString*           token;
    NSDictionary*       sensorList;
    ORNode*             sensorTree;
    NSDictionary*       sensorData;
    NSDate*              lastTimePolled;
    NSDate*              nextPollScheduled;
    unsigned int         pollTime;

}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

#pragma mark ***Accessors
- (NSString*)   password;
- (void)        setPassword:(NSString*)aPassword;
- (NSString*)   userName;
- (unsigned int) pollTime;
- (void) setPollTime:(unsigned int)aPollTime;

- (void)        setUserName:(NSString*)aUserName;
- (void)        setSensorList:(NSDictionary*)aList;
- (NSDictionary*) sensorList;
- (ORNode*)     sensorTree;
- (void)        setSensorData:(NSDictionary*)aList;
- (NSDictionary*) sensorData;
- (NSInteger) numOfSensors;
- (id) getSensor:(NSInteger)i value:(NSString*)name;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***Thread Stuff
- (void) requestGatewayList;
- (void) requestSensorData;


@property (retain,nonatomic) NSDate* lastTimePolled;
@property (retain,nonatomic) NSDate* nextPollScheduled;

@end

extern NSString* ORSensorPushPasswordChanged;
extern NSString* ORSensorPushUserNameChanged;
extern NSString* ORSensorPushListChanged;
extern NSString* ORSensorPushDataChanged;
extern NSString* ORSensorPushPollingTimesChanged;
extern NSString* ORSensorPushThreadRunningChanged;
extern NSString* ORSensorPushLock;

#define kSensorPushPollTime       60


@interface ORNode : NSObject
{
    NSString*       name;
    NSString*       description;
    NSMutableArray* children;
}
- (void) dealloc;
- (void) setName:(NSString*)aName;
- (NSString*)name;
- (void) setDescription:(NSString*)aDescription;
- (NSString*)description;
- (NSArray*)children;
- (ORNode*) addDictionary:(NSDictionary*)aDictionary;
- (NSInteger) count; //returns children cound
- (ORNode*)childAt:(NSInteger)i;
@end
