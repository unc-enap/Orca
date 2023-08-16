//-------------------------------------------------------------------------
//  ORSensorPushModel.m
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
#import "ORSensorPushModel.h"

NSString* ORSensorPushPasswordChanged  = @"ORSensorPushPasswordChanged";
NSString* ORSensorPushUserNameChanged  = @"ORSensorPushUserNameChanged";
NSString* ORSensorPushListChanged      = @"ORSensorPushListChanged";
NSString* ORSensorPushDataChanged      = @"ORSensorPushDataChanged";
NSString* ORSensorPushPollingTimesChanged     = @"ORSensorPushPollingTimesChanged";
NSString* ORSensorPushThreadRunningChanged    = @"ORSensorPushThreadRunningChanged";

NSString* ORSensorPushLock             = @"ORSensorPushLock";

@interface ORSensorPushModel (private)
- (void)          postDBRecords;
- (void)          postCouchDBRecord;
- (void)          postInFluxRecord;
- (void)          sensorDataThread;
- (void)          sensorListThread;
- (void)          gatewayListThread;

- (NSString*)     getAuthorization;
- (NSString*)     getToken:(NSString*)auth;
- (NSDictionary*) getSensorList;
- (NSDictionary*) getGatewayList;
- (NSDictionary*) getSensorData;
- (NSString*)     getFreshToken;
- (void)          createSensorTree:(NSDictionary*)aDictionary;

- (NSDictionary*) doCurl:(NSArray*)params;
@end

@implementation ORSensorPushModel

#pragma mark ***Initialization

@synthesize  lastTimePolled;
@synthesize  nextPollScheduled;

- (id) init 
{
    self = [super init];
    pollTime = kSensorPushPollTime;

    return self;
}

- (void) dealloc 
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:nil object:nil];
    [password release];
    [userName release];
    [token release];
    [sensorData release];
    [sensorList release];
    [sensorTree release];

    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SensorPush"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORSensorPushController"];
}

#pragma mark ***Accessors
- (NSString*) password
{
    if(!password)return @"";
    else return password;
}

- (void) setPassword:(NSString*)aPassword
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
    
    [password autorelease];
    password = [aPassword copy];    

    [self performSelector:@selector(requestSensorData) withObject:nil afterDelay:5];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSensorPushPasswordChanged object:self];
}

- (NSString*) userName
{
    if(!userName)return @"";
    else return userName;
}

- (void) setUserName:(NSString*)aUserName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
    
    [userName autorelease];
    userName = [aUserName copy];
    
    [self performSelector:@selector(requestSensorData) withObject:nil afterDelay:5];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSensorPushUserNameChanged object:self];
}

- (void) setLastTimePolled:(NSDate*) aDate
{
    [aDate retain];
    [lastTimePolled release];
    lastTimePolled = aDate;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSensorPushPollingTimesChanged object:self];
}

- (unsigned int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(unsigned int)aPollTime
{
    if(aPollTime==0 || aPollTime>=kSensorPushPollTime)aPollTime = kSensorPushPollTime;
    pollTime = aPollTime;
    [self requestSensorData];
}
- (void) setSensorList:(NSDictionary*)aList
{
    [sensorList release];
    [aList retain];
    sensorList =  aList;
    [self createSensorTree:aList];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSensorPushListChanged object:self];
}

- (NSDictionary*) sensorList
{
    return sensorList;
}

- (ORNode*) sensorTree
{
    return sensorTree;
}

- (void) setSensorData:(NSDictionary*)aList
{
    [sensorData release];
    [aList retain];
    sensorData =  aList;
    
    [self postDBRecords];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSensorPushDataChanged object:self];

}
- (NSDictionary*) sensorData
{
    return sensorData;

}
- (NSInteger) numOfSensors
{
    if(sensorData && sensorList){
        return [[[sensorData objectForKey:@"sensors"] allKeys]count];
    }
    else return 0;
}
- (void) setRunning
{
    running = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSensorPushThreadRunningChanged object:self];

}
- (void) setNotRunning
{
    running = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSensorPushThreadRunningChanged object:self];
}
- (BOOL)isRunning
{
    return running;
}
- (id) getSensor:(NSInteger)i value:(NSString*)name
{
    //get the sensor id from the sensor list
    NSString* value = @"?";
    NSDictionary* allSensorDataDict = [sensorData objectForKey:@"sensors"];
    NSArray* keys = [allSensorDataDict allKeys];
    if(i<[keys count]){
        NSArray* aSensorDataDict = [allSensorDataDict objectForKey:[keys objectAtIndex:i]];
        if([name isEqualToString:@"name"]){
            //get the name from the sensorList
            NSDictionary* listDict = [sensorList objectForKey:[keys objectAtIndex:i]];
            return [listDict objectForKey:@"name"];
        }
        else {
            return [[aSensorDataDict objectAtIndex:0] objectForKey:name];
        }
    }
    return value;
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    pollTime = kSensorPushPollTime;

    [[self undoManager] disableUndoRegistration];
    [self setPassword:  [decoder decodeObjectForKey:@"password"]];
    [self setUserName:  [decoder decodeObjectForKey:@"userName"]];
    [self setSensorList:[decoder decodeObjectForKey:@"@sensorList"]];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:password   forKey:@"password"];
    [encoder encodeObject:userName   forKey:@"userName"];
    [encoder encodeObject:sensorList forKey:@"sensorList"];
}

#pragma mark •••curl thread
- (void) requestSensorData
{
    //NSLog(@"%@\n",[self convertGMTTimeString:@"2023-08-03T21:05:32.000"]);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    if(!running){
        if(userName && password){
            [NSThread detachNewThreadSelector:@selector(sensorDataThread) toTarget:self withObject:nil];
        }
    }
    [self performSelector:@selector(requestSensorData) withObject:nil afterDelay:[self pollTime]];
    [self setNextPollScheduled:[NSDate dateWithTimeIntervalSinceNow:[self pollTime]]];
    [self setLastTimePolled:[NSDate date]];
}

- (void) requestSensorList
{
    if(!running){
        [NSThread detachNewThreadSelector:@selector(sensorListThread) toTarget:self withObject:nil];
    }
}
- (void) requestGatewayList
{
    if(!running){
        [NSThread detachNewThreadSelector:@selector(gatewayListThread) toTarget:self withObject:nil];
    }
}

- (NSString*) convertGMTTimeString:(NSString*)aTimeStamp
{
    //2023-08-03T21:05:32.000Z to local time
    aTimeStamp = [aTimeStamp stringByReplacingOccurrencesOfString:@"...Z" withString:@" GMT"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    NSDate* date = [dateFormatter dateFromString:aTimeStamp];
    NSString *localDateString      = [dateFormatter stringFromDate:date];
    return localDateString;
}

@end

@implementation ORSensorPushModel (private)
- (void) postDBRecords
{
    [self postCouchDBRecord];
    [self postInFluxRecord];
}

- (void) postCouchDBRecord
{
    if(sensorData){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:sensorData];
    }
}

- (void) postInFluxRecord
{
    if(sensorData && sensorList){
        NSDictionary* sensors = [sensorData objectForKey:@"sensors"];
        for(id aKey in sensorList){
            
            NSDictionary*     aSensorList  = [sensorList objectForKey:aKey]; //general list of parameters
            NSDictionary*         aSensor  = [[sensors objectForKey:aKey]objectAtIndex:0];    //data values, i.e. temp,humidity
            NSMutableDictionary*     tags  = [NSMutableDictionary dictionary];

            [tags setObject: [aSensorList objectForKey:@"name"] forKey:@"name"];
            [tags setObject: [aSensorList objectForKey:@"id"]   forKey:@"id"];

            NSMutableDictionary* inFluxRecord = [NSMutableDictionary dictionary];
            [inFluxRecord setObject:@"SlowControls" forKey:@"bucket"];          //bucket assumed to exist
            [inFluxRecord setObject:@"measurement"  forKey:@"sensorPushValues"];     //the measurement  name
            [inFluxRecord setObject:tags            forKey:@"tags"];            //add tag dictionary
            NSMutableDictionary* fields = [NSMutableDictionary dictionary];
            for(id k in [aSensor allKeys]){
                [fields setObject:[aSensor objectForKey:k] forKey:k];
            }
            [inFluxRecord setObject:fields forKey:@"fields"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORInFluxAddMeasurement" object:self userInfo:inFluxRecord];

        }
    }
        
//        for(id aKey in [sensors allKeys]){
//            NSDictionary *    aSensor = [sensors objectForKey:aKey];
//            NSMutableDictionary* tags = [NSMutableDictionary dictionary];
//
//            [tags setObject: [aSensor objectForKey:@"name"] forKey:@"name"];
//            [tags setObject: [aSensor objectForKey:@"id"]   forKey:@"id"];
//
//            NSMutableDictionary* inFluxRecord = [NSMutableDictionary dictionary];
//            [inFluxRecord setObject:@"SlowControls" forKey:@"bucket"];          //bucket assumed to exist
//            [inFluxRecord setObject:@"measurement"  forKey:@"sensor_push"];     //the measurement  name
//            [inFluxRecord setObject:tags            forKey:@"tags"];            //add tag dictionary
//            [inFluxRecord setObject:aSensor         forKey:@"fields"];          //add field dictionary
//
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORInFluxAddMeasurement" object:self userInfo:inFluxRecord];
//        }
//    }
}
- (void) createSensorTree:(NSDictionary*)aDictionary
{
    [sensorTree release];
    sensorTree = [[ORNode alloc]init];
    //lift the sensor name to the top
    NSMutableDictionary* dict = [aDictionary mutableCopy];
    for(NSString* aKey in [dict allKeys]){
        NSMutableDictionary* sensorDict = [dict objectForKey:aKey];
        NSString* sensorName = [sensorDict objectForKey:@"name"];;
        [dict setObject:sensorDict forKey:sensorName];
        [dict removeObjectForKey:aKey];
    }
    [sensorTree addDictionary:dict];
}

//----------------------------Thread Stuff-----------------------
//the following methods are not asycronous, so must not be called
//outside of the a background thread.
//---------------------------------------------------------------
- (void) sensorDataThread
{
    @autoreleasepool {
        [self performSelectorOnMainThread:@selector(setRunning) withObject:nil waitUntilDone:YES];

        if(![self sensorList]){
            NSDictionary*   list       = [self getSensorList];
            [self performSelectorOnMainThread:@selector(setSensorList:) withObject:list waitUntilDone:YES];
        }

        NSDictionary*   sensorData = [self getSensorData];
        [self performSelectorOnMainThread:@selector(setSensorData:) withObject:sensorData waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(setNotRunning) withObject:nil waitUntilDone:YES];
    }
}

- (void) sensorListThread
{
    @autoreleasepool {
        [self performSelectorOnMainThread:@selector(setRunning) withObject:nil waitUntilDone:YES];
        NSDictionary* list = [self getSensorList];
        [self performSelectorOnMainThread:@selector(setSensorList:) withObject:list waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(setNotRunning) withObject:nil waitUntilDone:YES];
    }
}

- (void) gatewayListThread
{
    @autoreleasepool {
        [self performSelectorOnMainThread:@selector(setRunning) withObject:nil waitUntilDone:YES];
        NSLog(@"gateways = %@\n",[self getGatewayList]);
    
        [self performSelectorOnMainThread:@selector(setNotRunning) withObject:nil waitUntilDone:YES];
    }
}
- (NSString*) getFreshToken
{
    //tokens expire after 30 minutes.
    //Faster to use the old one as long as we can.
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if(fabs(now - tokenTime) > 30*60 || (token==nil)){
        NSString*       auth       = [self getAuthorization];
        NSString*       newToken   = [self getToken:auth];
        [token release];
        token = [newToken retain];
        if(token){
            tokenTime = now;
        }
        return token;
    }
    else return token;
}

- (NSString*) getAuthorization
{
//-----------------------------------------------------------------------
//curl -X POST "https://api.sensorpush.com/api/v1/oauth/authorize" \
//     -H "accept: application/json" \
//     -H "Content-Type: application/json" \
//     -d {"email": "<userName>", "password": "<password>" }
//-----------------------------------------------------------------------
    NSMutableArray* params = [NSMutableArray array];
    [params addObject:@"-sS"];
    [params addObject:@"-X"];
    [params addObject:@"POST"];
    [params addObject:@"https://api.sensorpush.com/api/v1/oauth/authorize"];
    [params addObject:@"-H"];
    [params addObject:@"accept: application/json"];
    [params addObject:@"-H"];
    [params addObject:@"Content-Type: application/json"];
    [params addObject:@"-d"];
    [params addObject:[NSString stringWithFormat:@"{ \"email\": \"%@\", \"password\": \"%@\"}",userName,password]];

    NSDictionary* result = [self doCurl:params];
    NSString*     auth   = [result objectForKey:@"authorization"];
    if(auth) return auth;
    else     return nil;
}

- (NSString*) getToken:(NSString*)auth
{
//-----------------------------------------------------------------------
//curl  -X POST "https://api.sensorpush.com/api/v1/oauth/accesstoken" \
//      -H "accept: application/json" \
//      -H "Content-Type: application/json" \
//      -d "{"authorization": "<authString>"}"
//-----------------------------------------------------------------------
    NSMutableArray* params = [NSMutableArray array];
    [params addObject:@"-sS"];
    [params addObject:@"-X"];
    [params addObject:@"POST"];
    [params addObject:@"https://api.sensorpush.com/api/v1/oauth/accesstoken"];
    [params addObject:@"-H"];
    [params addObject:@"accept: application/json"];
    [params addObject:@"-H"];
    [params addObject:@"Content-Type: application/json"];
    [params addObject:@"-d"];
    [params addObject:[NSString stringWithFormat:@"{ \"authorization\": \"%@\" }",auth]];
    
    NSDictionary* result = [self doCurl:params];
    NSString* token = [result objectForKey:@"accesstoken"];
    if(token)   return token;
    else        return nil;
}
- (NSDictionary*) getGatewayList
{
//    curl -X POST "https://api.sensorpush.com/api/v1/devices/gateways" \
//    -H "accept: application/json" \
//    -H "Authorization: <accesstoken>" \
//    -d {}
    
    NSString*       token  = [self getFreshToken];
    NSMutableArray* params = [NSMutableArray array];
    [params addObject:@"-sS"];
    [params addObject:@"-X"];
    [params addObject:@"POST"];
    [params addObject:@"https://api.sensorpush.com/api/v1/devices/gateways"];
    [params addObject:@"-H"];
    [params addObject:@"accept: application/json"];
    [params addObject:@"-H"];
    [params addObject:[NSString stringWithFormat:@"Authorization : %@",token]];
    [params addObject:@"-d"];
    [params addObject:[NSString stringWithFormat:@"{}"]];
    
    NSDictionary* result = [self doCurl:params];
    if(result)  return result;
    else        return nil;
}

-(NSDictionary*) getSensorList
{
//-----------------------------------------------------------------------
//get list of sensors
//curl -X POST "https://api.sensorpush.com/api/v1/devices/sensors" \
//     -H "accept: application/json"\
//     -H "Authorization: <accesstoken>"\
//     -d {}
//-----------------------------------------------------------------------
    NSString*       token      = [self getFreshToken];
    
    NSMutableArray* params = [NSMutableArray array];
    [params addObject:@"-sS"];
    [params addObject:@"-X"];
    [params addObject:@"POST"];
    [params addObject:@"https://api.sensorpush.com/api/v1/devices/sensors"];
    [params addObject:@"-H"];
    [params addObject:@"accept: application/json"];
    [params addObject:@"-H"];
    [params addObject:[NSString stringWithFormat:@"Authorization : %@",token]];

    [params addObject:@"-d"];
    [params addObject:[NSString stringWithFormat:@"{}"]];
    
    NSDictionary* result = [self doCurl:params];
    if(result)  return result;
    else        return nil;
}

-(NSDictionary*) getSensorData
{
//-----------------------------------------------------------------------
//get list of sensors
//curl  -X POST "https://api.sensorpush.com/api/v1/samples"
//      -H "accept: application/json"
//      -H "Authorization: <accesstoken>"
//      -d { "limit": 20 }
//-----------------------------------------------------------------------
    
    NSString*       token      = [self getFreshToken];

    NSMutableArray* params = [NSMutableArray array];
    [params addObject:@"-sS"];
    [params addObject:@"-X"];
    [params addObject:@"POST"];
    [params addObject:@"https://api.sensorpush.com/api/v1/samples"];
    [params addObject:@"-H"];
    [params addObject:@"accept: application/json"];
    [params addObject:@"-H"];
    [params addObject:[NSString stringWithFormat:@"Authorization : %@",token]];

    [params addObject:@"-d"];
    //[params addObject:@"{\"limit\":1,\"startTime\": \"2023-08-03T00:00:00.000Z\"}"];
    [params addObject:@"{\"limit\":1}"];

    NSDictionary* result = [self doCurl:params];
    if(result)  return result;
    else        return nil;
}

- (NSDictionary*)doCurl:(NSArray*)params
{
    NSPipe*        pipe = [NSPipe pipe];
    NSFileHandle*  fileHandle = [pipe fileHandleForReading];
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/curl"];
    [task setArguments:params];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    [task launch];
    
    NSMutableData* taskData = [NSMutableData data];
    NSData* data = nil;
    while ((data = [fileHandle availableData]) && ([data length])!=0){
        [taskData appendData:data];
    }
    
    [task waitUntilExit];
    
    //NSString* taskDataString = [[NSString alloc] initWithData: taskData encoding: NSASCIIStringEncoding];
    NSDictionary* result = [NSJSONSerialization JSONObjectWithData:taskData
                                                           options:NSJSONReadingMutableContainers
                                                             error:nil];
    //[taskDataString release];
    
    [task release];
    return result;
}
@end

@implementation ORNode
- (void) dealloc
{
    [name release];
    [description release];
    [super dealloc];
}

- (void) setName:(NSString*)aName
{
    [name release];
    name = [aName copy];
}

- (NSString*)name
{
    return name;
}

- (void) setDescription:(NSString*)aDescription
{
    [description release];
    description = [aDescription copy];
}

- (NSString*)description
{
    return description;
}

- (NSArray*)children
{
    return children;
}

- (ORNode*) addDictionary:(NSDictionary*)aDictionary
{
    for(id aKey in [aDictionary allKeys]){
        id obj = [aDictionary objectForKey:aKey];
        if([obj isKindOfClass:[NSDictionary class]]){
            ORNode* aNode = [[ORNode alloc] init];
            [aNode setName:aKey];
            if(!children)children = [[NSMutableArray array]retain];
            [children addObject:aNode];
            [aNode addDictionary:obj];
        }
        else {
            //leaf node
            ORNode* aNode = [[ORNode alloc] init];
            if(!children)children = [[NSMutableArray array]retain];
            [aNode setName:aKey];
            [aNode setDescription:obj];
            [children addObject:aNode];
        }
    }
    return self;
}
- (NSInteger) count
{
    return [children count];
}

- (ORNode*)childAt:(NSInteger)i
{
    if(i<[children count])return [children objectAtIndex:i];
    else return nil;
}

@end
