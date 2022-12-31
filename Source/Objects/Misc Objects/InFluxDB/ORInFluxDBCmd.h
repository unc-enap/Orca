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
    kInfluxDBMeasurement,
    kInFluxDBCreateBuckets,
    kInFluxDBDeleteBucket,
    kInFluxDBListBuckets,
    kInFluxDBListOrgs
};

@interface ORInFluxDBCmd : NSObject
{
    int cmdType;
    NSMutableString* outputBuffer;
}
- (id) initWithCmdType:(int)aType;
- (void) dealloc;
- (int) cmdType;
- (void) start:(NSString*)section withTags:(NSString*)someTags;
- (void) removeEndingComma;
- (void) addLong:(NSString*)aValueName withValue:(long)aValue;
- (void) addDouble:(NSString*)aValueName withValue:(double)aValue;
- (void) addString:(NSString*)aValueName withValue:(NSString*)aValue;
- (void) end:(ORInFluxDBModel*)aSender;
- (NSData*)   payload;
- (NSString*) outputBuffer;
@end

NS_ASSUME_NONNULL_END
