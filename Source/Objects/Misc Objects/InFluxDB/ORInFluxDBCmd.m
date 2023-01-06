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

- (void) logResult:(id)aResult delegate:(ORInFluxDBModel*)delegate
{
    if(aResult) NSLog(@"%@\n",aResult);
}

- (NSString*)uniqueName:(NSString*)aName
{
    NSString* suffix = computerName();
    return [NSString stringWithFormat:@"%@_%@",aName,suffix];
}

@end

//----------------------------------------------------------------
//  Delete Bucket
//----------------------------------------------------------------
@implementation ORInFluxDBDeleteBucket
+ (ORInFluxDBDeleteBucket *)inFluxDBDeleteBucket
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
    NSString* requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/buckets/%@",[delegate hostName],[delegate portNumber],bucketId];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    request.HTTPMethod = @"DELETE";
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]]                     forHTTPHeaderField:@"Authorization"];
    [request setValue:@"text/plain; application/json" forHTTPHeaderField:@"Accept"];
    requestSize = [requestString length];
    return request;
}
@end

//----------------------------------------------------------------
//  List Buckets
//----------------------------------------------------------------
@implementation ORInFluxDBListBuckets
+ (ORInFluxDBListBuckets *)inFluxDBListBuckets
{
    return [[[self alloc] init:kFluxListBuckets] autorelease];
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/buckets",[delegate hostName],[delegate portNumber]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    request.HTTPMethod = @"GET";
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]]                     forHTTPHeaderField:@"Authorization"];
    requestSize = [requestString length];

    return request;
}

- (void) logResult:(id)result delegate:(ORInFluxDBModel*)delegate
{
    NSArray* anArray = [result objectForKey:@"buckets"];
    if([anArray count]){
        NSLog(@"%d InFluxDB Buckets:\n",[anArray count]);
        for(id aBucket in anArray){
            if(![[aBucket objectForKey:@"name"] hasPrefix:@"_"]){
                NSLog(@"ORCA bucket:   %@ : ID = %@\n",[aBucket objectForKey:@"name"],[aBucket objectForKey:@"id"] );
            }
            else  {
                NSLog(@"System bucket: %@\n",[aBucket objectForKey:@"name"] );
            }
        }
        [delegate decodeBucketList:result];
    }
    else NSLog(@"No InfluxDB buckets found");
}
@end

//----------------------------------------------------------------
//  List Orgs
//----------------------------------------------------------------
@implementation ORInFluxDBListOrgs
+ (ORInFluxDBListOrgs *)inFluxDBListOrgs
{
    return [[[self alloc] init:kFluxListOrgs] autorelease];
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/orgs",[delegate hostName],[delegate portNumber]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    request.HTTPMethod = @"GET";
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]] forHTTPHeaderField:@"Authorization"];
    requestSize = [requestString length];

    return request;
}

- (void) logResult:(id)result delegate:(ORInFluxDBModel*)delegate
{
    NSArray* anArray = [result objectForKey:@"orgs"];
    if([anArray count]){
        NSLog(@"InFluxDB Orgs:\n");
        for(id anOrg in anArray){
            NSLog(@"%@ : ID = %@\n",[anOrg objectForKey:@"name"],[anOrg objectForKey:@"id"] );
        }
        [delegate decodeOrgList:result];
    }
    else  NSLog(@"InFluxDB Organization not defined\n");


}
@end

//----------------------------------------------------------------
//  Create Bucket
//----------------------------------------------------------------
@implementation ORInFluxDBCreateBucket

+ (ORInFluxDBCreateBucket*) inFluxDBCreateBucket:(NSString*)aName orgId:(NSString*)anId expireTime:(long)seconds
{
    return [[[self alloc] init:kFluxCreateBucket bucket:aName orgId:anId expireTime:seconds] autorelease];
}

- (id) init:(int)aType bucket:(NSString*) aBucket orgId:(NSString*)anId expireTime:(long)seconds
{
    self        = [super init:aType];
    bucket      = [[self uniqueName:aBucket] copy];
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
    NSString* requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/buckets",[delegate hostName],[delegate portNumber]];
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

    return request;
}
@end

//----------------------------------------------------------------
//  Measurements
//----------------------------------------------------------------
@implementation ORInFluxDBMeasurement
+ (ORInFluxDBMeasurement *)inFluxDBMeasurement:(NSString*)aBucket org:(NSString*)anOrg
{
    return [[[self alloc] init:kFluxMeasurement bucket:aBucket org:anOrg]autorelease];
}

- (id) init:(int)aType bucket:(NSString*) aBucket  org:(NSString*)anOrg
{
    self   = [super init:aType];
    bucket = [[self uniqueName:aBucket] copy];
    org    = [anOrg copy];
    return self;
}

- (void) dealloc
{
    [bucket release];
    [org release];
    [outputBuffer release];
    [super dealloc];
}

- (void) start:(NSString*)section withTags:(NSString*)someTags
{
    if(!outputBuffer) outputBuffer = [[NSMutableString alloc] init];
    if(!someTags){someTags = @"";}
    someTags = [someTags stringByReplacingOccurrencesOfString:@" " withString:@"_"];

    [outputBuffer appendFormat:@"%@,%@ ",section,someTags];
 }

- (void) removeEndingComma
{
    NSRange lastComma = [outputBuffer rangeOfString:@"," options:NSBackwardsSearch];

    if(lastComma.location == [outputBuffer length]-1) {
        [outputBuffer replaceCharactersInRange:lastComma
                                           withString: @""];
    }
}

- (void) addLong:(NSString*)aValueName withValue:(long)aValue
{
    [outputBuffer appendFormat:@"%@=%ld,",aValueName,aValue];
}

- (void) addDouble:(NSString*)aValueName withValue:(double)aValue
{
    [outputBuffer appendFormat:@"%@=%f,",aValueName,aValue];
}

- (void) addString:(NSString*)aValueName withValue:(NSString*)aValue
{
    [outputBuffer appendFormat:@"%@=\"%@\",",aValueName,aValue];
}
- (void) executeCmd:(ORInFluxDBModel*)aSender
{
    [self removeEndingComma];
    [outputBuffer appendFormat:@"   \n"];
    [aSender sendCmd:self];
}

- (NSString*) outputBuffer
{
    return outputBuffer;
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/write?org=%@&bucket=%@&precision=ns",[delegate hostName],[delegate portNumber],org,bucket];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    request.HTTPMethod = @"POST";
    [request setValue:@"text/plain; application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[NSString stringWithFormat:@"Token %@",[delegate authToken]]                     forHTTPHeaderField:@"Authorization"];
    request.HTTPBody = [outputBuffer dataUsingEncoding:NSASCIIStringEncoding];
    requestSize = [requestString length];
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
    bucket  = [[self uniqueName:aBucket] copy];
    start   = [aStart copy];
    stop    = [aStop copy];
    org     = [anOrg copy];
    return self;
}

- (void) dealloc
{
    [start  release];
    [stop   release];
    [bucket release];
    [org    release];
    [super dealloc];
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/delete?org=%@&bucket=%@",[delegate hostName],[delegate portNumber],org,bucket];
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

    return request;
}
@end

//----------------------------------------------------------------
//  Delete Selected Data
//----------------------------------------------------------------
@implementation ORInFluxDBDeleteSelectedData

+ (ORInFluxDBDeleteSelectedData*) inFluxDBDeleteSelectedData:(NSString*)aName org:(NSString*)anOrg  start:(NSString*)aStart stop:(NSString*)aStop  predicate:(NSString*)aPredicate
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
    [predicate dealloc];
    [super dealloc];
}

- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate
{
    NSString* requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/delete?org=%@&bucket=%@",[delegate hostName],[delegate portNumber],org,bucket];
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

    return request;
}
@end
