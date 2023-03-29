//-------------------------------------------------------------------------
//  ORInFluxDBCommand.m
//  Created by Mark Howe on 12/30/2022.
//  Copyright (c) 2022 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//Washington reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORInFluxDBCmd.h"
#import "ORInFluxDBModel.h"

//----------------------------------------------------------------
//  Base Class
//----------------------------------------------------------------
@implementation ORInFluxDBCmd
+ (ORInFluxDBCmd *)inFluxDBCmd:(int)aType
{
    return [[[self alloc] init:aType]autorelease];
}

- (id) init:(int)aType;
{
    self = [super init];
    cmdType = aType;
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (int) cmdType
{
    return cmdType;
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    //subclasses must override
    return nil;
}

- (long) requestSize
{
    return requestSize;
}

- (void) executeCmd:(ORInFluxDBModel*)aSender
{
    [aSender sendCmd:self];
}

- (void) logResult:(id)result code:(int)aCode delegate:(ORInFluxDBModel*)delegate
{
    if(aCode == 200){/*success*/}

    else if(aCode==400){
        [delegate setErrorString:[NSString stringWithFormat:@"Bad Request:%@",result]];
    }
    else if(aCode==401)[delegate setErrorString:@"Unauthorized Access"];
    else if(aCode==413)[delegate setErrorString:@"Request too large"];
    else if(aCode==422)[delegate setErrorString:@"Request unprocessable"];
    else if(aCode==429)[delegate setErrorString:@"Too many requests"];
    else if(aCode==500)[delegate setErrorString:@"Service error"];
    else if(aCode==503)[delegate setErrorString:@"Service unavailable"];
}

@end

//----------------------------------------------------------------
//  Delete Bucket
//----------------------------------------------------------------
@implementation ORInFluxDBDeleteBucket
+ (ORInFluxDBDeleteBucket *)deleteBucket
{
    return [[[self alloc] init:kFluxDeleteBucket] autorelease];
}

- (void) dealloc
{
    [bucketId release];
    [super dealloc];
}

- (void) setBucketId:(NSString*) anId
{
    [bucketId autorelease];
    bucketId = [anId copy];
}
- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"%@/api/v2/buckets/%@",[delegate hostName],bucketId];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    request.HTTPMethod = @"DELETE";
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]]                     forHTTPHeaderField:@"Authorization"];
    [request setValue:@"text/plain; application/json" forHTTPHeaderField:@"Accept"];
    requestSize = [requestString length];
    return request;
}

- (void) logResult:(id)result code:(int)aCode delegate:(ORInFluxDBModel*)delegate
{
    if(aCode == 204)NSLog(@"Deleted Bucket (id:%@)\n",bucketId);
    else if(aCode==400){
        [delegate setErrorString:[NSString stringWithFormat:@"Delete Bucket: Bad Request: %@",result]];
    }
    else if(aCode==401){
        [delegate setErrorString:@"Delete Bucket: Unauthorized access"];
    }
    else if(aCode==404){
        [delegate setErrorString:[NSString stringWithFormat:@"Delete Bucket: BucketID: %@ not found\n",bucketId]];
    }
    else [super logResult:result code:aCode delegate:delegate];

}
@end

//----------------------------------------------------------------
//  List Buckets
//----------------------------------------------------------------
@implementation ORInFluxDBListBuckets
+ (ORInFluxDBListBuckets *)listBuckets
{
    return [[[self alloc] init:kFluxListBuckets] autorelease];
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"%@/api/v2/buckets?org=%@",[delegate hostName],[delegate org]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    request.HTTPMethod = @"GET";
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]]                     forHTTPHeaderField:@"Authorization"];
    requestSize = [requestString length];
    return request;
}

- (void) logResult:(id)aResult code:(int)aCode delegate:(ORInFluxDBModel*)delegate;
{
    if(aCode == 200)[delegate decodeBucketList:aResult];
    else [super logResult:aResult code:aCode delegate:delegate];
}
@end
//----------------------------------------------------------------
//  Delay
//----------------------------------------------------------------
@implementation ORInFluxDBDelayCmd
+ (ORInFluxDBDelayCmd*) delay:(int)aSeconds
{
    return [[[self alloc] init:kFluxDelay delay:aSeconds] autorelease];
}

- (id) init:(int)aType delay:(int)aSeconds
{
    self        = [super init:aType];
    delayTime   = aSeconds;
    return self;
}

- (int) delayTime
{
    return delayTime;
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"%@/api/v2/orgs",[delegate hostName]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];

    request.HTTPMethod = @"GET";
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]] forHTTPHeaderField:@"Authorization"];
    requestSize = [requestString length];

    return request;
}

- (void) logResult:(id)aResult code:(int)aCode delegate:(ORInFluxDBModel*)delegate;
{
}

@end
//----------------------------------------------------------------
//  List Orgs
//----------------------------------------------------------------
@implementation ORInFluxDBListOrgs
+ (ORInFluxDBListOrgs *)listOrgs
{
    return [[[self alloc] init:kFluxListOrgs] autorelease];
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"%@/api/v2/orgs",[delegate hostName]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];

    request.HTTPMethod = @"GET";
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]] forHTTPHeaderField:@"Authorization"];
    requestSize = [requestString length];

    return request;
}

- (void) logResult:(id)result code:(int)aCode delegate:(ORInFluxDBModel*)delegate
{
    if(aCode == 200)[delegate decodeOrgList:result];
    else if(aCode==400){
        [delegate setErrorString:[NSString stringWithFormat:@"List Orgs: Bad Request: %@",result]];
    }
    else [super logResult:result code:aCode delegate:delegate];
}
@end

//----------------------------------------------------------------
//  Create Bucket
//----------------------------------------------------------------
@implementation ORInFluxDBCreateBucket

+ (ORInFluxDBCreateBucket*) createBucket:(NSString*)aName orgId:(NSString*)anId expireTime:(long)seconds
{
    return [[[self alloc] init:kFluxCreateBucket bucket:aName orgId:anId expireTime:seconds] autorelease];
}

- (id) init:(int)aType bucket:(NSString*) aBucket orgId:(NSString*)anId expireTime:(long)seconds
{
    self        = [super init:aType];
    bucket      = [aBucket copy];
    orgId       = [anId copy];
    expireTime  = seconds;
    return self;
}

- (void) dealloc
{
    [bucket release];
    [orgId release];
    [super dealloc];
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"%@/api/v2/buckets",[delegate hostName]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"text/plain; application/json" forHTTPHeaderField:@"Accept"];

    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:orgId  forKey:@"orgID"];
    [dict setObject:bucket forKey:@"name"];
    if(expireTime){
        NSMutableDictionary* ret = [NSMutableDictionary dictionary];
        [ret setObject:@"expire" forKey:@"type"];
        [ret setObject:[NSNumber numberWithLong:expireTime] forKey:@"everySeconds"];
        [ret setObject:[NSNumber numberWithInt:0] forKey:@"shardGroupDurationSeconds"];
        NSArray* retArray = [NSArray arrayWithObject:ret];
        [dict setObject:retArray forKey:@"retentionRules"];
    }
    NSError* error;
    NSData*  jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                        options:0 //because don't care about readability
                                                          error:&error];
    request.HTTPBody = jsonData;
    requestSize = [requestString length];
    requestSize += [jsonData length];

    return request;
}
- (void) logResult:(id)result code:(int)aCode delegate:(ORInFluxDBModel*)delegate
{
    if(aCode == 201)   NSLog(@"Influx: Created Bucket: %@\n",bucket);
    else if(aCode==400){
        [delegate setErrorString:[NSString stringWithFormat:@"Create Bucket: Bad Request:%@",result]];
    }
    else if(aCode==401)[delegate setErrorString:@"Create Bucket: Unauthorized access"];
    else if(aCode==403)[delegate setErrorString:@"Create Bucket: Quota exceeded"];
    else if(aCode==422)[delegate setErrorString:[NSString stringWithFormat:@"Bucket: %@ already exists",bucket]];
    else [super logResult:result code:aCode delegate:delegate];
}
@end

//----------------------------------------------------------------
//  Measurements
//----------------------------------------------------------------
@implementation ORInFluxDBMeasurement
+ (ORInFluxDBMeasurement *)measurementForBucket:(NSString*)aBucket org:(NSString*)anOrg
{
    return [[[self alloc] init:kFluxMeasurement bucket:aBucket org:anOrg]autorelease];
}

- (id) init:(int)aType bucket:(NSString*) aBucket  org:(NSString*)anOrg
{
    self         = [super init:aType];
    bucket       = [aBucket copy];
    org          = [anOrg copy];
    tags         = [[NSMutableArray array] retain];
    measurements = [[NSMutableArray array]retain];
    return self;
}

- (void) dealloc
{
    [bucket       release];
    [org          release];
    [tags         release];
    [measurement  release];
    [measurements release];
    [super dealloc];
}
- (void) setTimeStamp:(double)aTimeStamp
{
    timeStamp = aTimeStamp;
}

- (void) start:(NSString*)aMeasurement withTags:(NSString*)someTags
{
    measurement = [aMeasurement copy];
    [tags addObject:someTags];
}

- (void) start:(NSString*)aMeasurement
{
    measurement = [aMeasurement copy];
}

- (NSString*) bucket
{
    return bucket;
}

- (NSString*) org
{
    return org;
}

- (void) addTag:(NSString*)aLabel withString:(NSString*)aValue
{
    [tags addObject:[NSString stringWithFormat:@"%@=%@",aLabel,aValue]];
}

- (void) addTag:(NSString*)aLabel withBoolean:(BOOL)aValue
{
    [tags addObject:[NSString stringWithFormat:@"%@=%@",aLabel,aValue?@"true":@"false"]];
}

- (void) addTag:(NSString*)aLabel withLong:(long)aValue
{
    [tags addObject:[NSString stringWithFormat:@"%@=%ld",aLabel,aValue]];
}

- (void) addTag:(NSString*)aLabel withDouble:(double)aValue
{
    [tags addObject:[NSString stringWithFormat:@"%@=%f",aLabel,aValue]];
}

- (void) addField:(NSString*)aValueName withBoolean:(BOOL)aValue
{
    [measurements addObject:[NSString stringWithFormat:@"%@=%@",aValueName,aValue?@"true":@"false"]];
}

- (void) addField:(NSString*)aValueName withLong:(long)aValue
{
    [measurements addObject:[NSString stringWithFormat:@"%@=%ldi",aValueName,aValue]];
}

- (void) addField:(NSString*)aValueName withDouble:(double)aValue
{
    [measurements addObject:[NSString stringWithFormat:@"%@=%f",aValueName,aValue]];
}

- (void) addField:(NSString*)aValueName withString:(NSString*)aValue
{
    [measurements addObject:[NSString stringWithFormat:@"%@=\"%@\"",aValueName,aValue]];
}

- (void) executeCmd:(ORInFluxDBModel*)aSender
{
    [aSender bufferMeasurement:self];
}

- (NSString*) cmdLine
{
    if([tags count]>0)return [NSString stringWithFormat:@"%@,%@ %@ %@",
                              measurement,
                              [tags componentsJoinedByString:@","],
                              [measurements componentsJoinedByString:@","],
                              timeStamp?[NSString stringWithFormat:@"%ld\n",(long)(timeStamp*1E9)]:@"\n"];
    else return [NSString stringWithFormat:@"%@ %@ %@",
                        measurement,
                        [measurements componentsJoinedByString:@","],
                        timeStamp?[NSString stringWithFormat:@"%ld\n",(long)(timeStamp*1E9)]:@"\n"];

}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* cmdLine = [self cmdLine];
            
    NSString* requestString = [NSString stringWithFormat:@"%@/api/v2/write?org=%@&bucket=%@&precision=ns",[delegate hostName],org,bucket];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];

    request.HTTPMethod = @"POST";
    [request setValue:@"text/plain; application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]]                     forHTTPHeaderField:@"Authorization"];
    
    request.HTTPBody = [cmdLine dataUsingEncoding:NSASCIIStringEncoding];
    requestSize = [cmdLine length];
    
    return request;
}
@end

@implementation ORInFluxDBCmdLineMode
+ (ORInFluxDBCmdLineMode*)lineModeForBucket:(NSString*)aBucket org:(NSString*)anOrg
{
    return [[[self alloc] init:kFluxLineMode bucket:aBucket org:anOrg]autorelease];
}

- (id) init:(int)aType bucket:(NSString*) aBucket  org:(NSString*)anOrg
{
    self         = [super init:aType];
    bucket       = [aBucket copy];
    org          = [anOrg copy];
    line         = [[NSMutableString stringWithCapacity:5000] retain];
    return self;
}

- (void) dealloc
{
    [bucket release];
    [org    release];
    [line   release];
    [super dealloc];
}

- (void) appendLine:(NSString*)aLine
{
    [line appendString:aLine];
}

- (NSString*) line
{
    return line;
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* cmdLine = [self line];
    NSString* requestString = [NSString stringWithFormat:@"%@/api/v2/write?org=%@&bucket=%@&precision=ns",[delegate hostName],org,bucket];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    request.HTTPMethod = @"POST";
    [request setValue:@"text/plain; application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]]                     forHTTPHeaderField:@"Authorization"];
    
    request.HTTPBody = [cmdLine dataUsingEncoding:NSASCIIStringEncoding];
    requestSize = [cmdLine length];
    
    return request;
}

@end
//----------------------------------------------------------------
//  Delete Data
//----------------------------------------------------------------
@implementation ORInFluxDBDeleteAllData

+ (ORInFluxDBDeleteAllData*) inFluxDBDeleteAllData:(NSString*)aName org:(NSString*)anOrg  start:(NSString*)aStart  stop:(NSString*)aStop
{
    return [[[self alloc] init:kFluxDeleteData bucket:aName  org:anOrg start:aStart stop:aStop] autorelease];
}

- (id) init:(int)aType bucket:(NSString*) aBucket  org:(NSString*)anOrg  start:(NSString*)aStart  stop:(NSString*)aStop
{
    self    = [super init:aType];
    bucket  = [aBucket copy];
    start   = [aStart copy];
    stop    = [aStop copy];
    org     = [anOrg copy];
    return self;
}

- (void) dealloc
{
    [bucket release];
    [org    release];
    [start  release];
    [stop   release];
    [super dealloc];
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"%@/api/v2/delete?org=%@&bucket=%@",[delegate hostName],org,bucket];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"text/plain; application/json" forHTTPHeaderField:@"Accept"];

    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:start forKey:@"start"];
    [dict setObject:stop forKey:@"stop"];

    NSError* error;
    NSData*  jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                        options:0 //because don't care about readability
                                                          error:&error];
    request.HTTPBody = jsonData;
    requestSize = [requestString length];
    requestSize += [jsonData length];

    return request;
}
@end

//----------------------------------------------------------------
//  Delete Selected Data
//----------------------------------------------------------------
@implementation ORInFluxDBDeleteSelectedData

+ (ORInFluxDBDeleteSelectedData*) deleteSelectedData:(NSString*)aName org:(NSString*)anOrg  start:(NSString*)aStart stop:(NSString*)aStop  predicate:(NSString*)aPredicate
{
    return [[[self alloc] init:kFluxDeleteData bucket:aName  org:anOrg start:aStart stop:aStop  predicate:aPredicate] autorelease];
}

- (id) init:(int)aType bucket:(NSString*) aBucket  org:(NSString*)anOrg  start:(NSString*)aStart  stop:(NSString*)aStop  predicate:(NSString*)aPredicate
{
    self    = [super init:aType bucket:aBucket org:anOrg start:aStart stop:aStop];
    predicate   = [aPredicate copy];
    return self;
}

- (void) dealloc
{
    [predicate release];
    [super dealloc];
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"%@/api/v2/delete?org=%@&bucket=%@",[delegate hostName],org,bucket];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"text/plain; application/json" forHTTPHeaderField:@"Accept"];

    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:start       forKey:@"start"];
    [dict setObject:stop        forKey:@"stop"];
    [dict setObject:predicate   forKey:@"predicate"];

    NSError* error;
    NSData*  jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                        options:0 //because don't care about readability
                                                          error:&error];
    request.HTTPBody = jsonData;
    requestSize = [requestString length];
    requestSize += [jsonData length];

    return request;
}
@end
