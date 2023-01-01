//-------------------------------------------------------------------------
//  ORInFluxDBCmd.h
//
// Created by Mark Howe on 12/30/2022.

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


NS_ASSUME_NONNULL_BEGIN
@class ORInFluxDBModel;
enum {
    kFluxMeasurement,
    kFluxCreateBucket,
    kFluxDeleteBucket,
    kFluxListBuckets,
    kFluxListOrgs
};

//----------------------------------------------------------------
//  Base Class
//----------------------------------------------------------------
@interface ORInFluxDBCmd : NSObject
{
    int cmdType;
    long requestSize;
}
+ (ORInFluxDBCmd*) inFluxDBCmd:(int)aType;
- (id) init:(int)aType;
- (void) dealloc;
- (int)  cmdType;
- (long) requestSize;
- (NSMutableURLRequest*) requestFrom:(ORInFluxDBModel*)delegate;
- (void) executeCmd:(ORInFluxDBModel*)aSender;
- (void) logResult:(id)aResult delegate:(ORInFluxDBModel*)delegate;
@end

//----------------------------------------------------------------
//  Delete bucket
//----------------------------------------------------------------
@interface ORInFluxDBDeleteBucket : ORInFluxDBCmd
{
    NSString* bucketId;
}
+ (ORInFluxDBDeleteBucket*) inFluxDBDeleteBucket;
- (void) dealloc;
- (void) setBucketId:(NSString*) anId;
@end

//----------------------------------------------------------------
//  List buckets
//----------------------------------------------------------------
@interface ORInFluxDBListBuckets : ORInFluxDBCmd
+ (ORInFluxDBListBuckets*) inFluxDBListBuckets;
@end

//----------------------------------------------------------------
//  List Orgs
//----------------------------------------------------------------
@interface ORInFluxDBListOrgs : ORInFluxDBCmd
+ (ORInFluxDBListOrgs*) inFluxDBListOrgs;
@end

//----------------------------------------------------------------
//  create bucket
//----------------------------------------------------------------
@interface ORInFluxDBCreateBucket : ORInFluxDBCmd
{
    NSString* bucket;
    NSString* orgId;
    long      expireTime;
}
+ (ORInFluxDBCreateBucket*) inFluxDBCreateBucket:(NSString*)aName orgId:(NSString*)anId expireTime:(long)seconds;
- (id) init:(int)aType bucket:(NSString*) aBucket orgId:(NSString*)anId expireTime:(long)seconds;
@end

//----------------------------------------------------------------
//  Measurements
//----------------------------------------------------------------
@interface ORInFluxDBMeasurement : ORInFluxDBCmd
{
    NSMutableString* outputBuffer;
    NSString* bucket;
    NSString* org;
}
+ (ORInFluxDBMeasurement*)inFluxDBMeasurement:(NSString*)aBucket org:(NSString*)anOrg;
- (id) init:(int)aType bucket:(NSString*)aBucket org:(NSString*)anOrg;
- (void) start:(NSString*)section withTags:(NSString*)someTags;
- (void) removeEndingComma;
- (void) addLong:(NSString*)aValueName withValue:(long)aValue;
- (void) addDouble:(NSString*)aValueName withValue:(double)aValue;
- (void) addString:(NSString*)aValueName withValue:(NSString*)aValue;
@end

NS_ASSUME_NONNULL_END
