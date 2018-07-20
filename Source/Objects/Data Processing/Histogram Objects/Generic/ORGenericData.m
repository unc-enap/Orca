//
//  ORGenericData.m
//  Orca
//
//  Created by Mark Howe on Sun Nov 17 2002.
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


#import "ORGenericData.h"

@implementation ORGenericData
- (id) init
{
    self = [super init];
	dataLock = [[NSLock alloc] init];
    return self;
}

- (void)dealloc
{
	[dataLock release];
    [genericData release];
    [super dealloc];
}

#pragma mark ¥¥¥Accessors


#pragma mark ¥¥¥Data Management
-(void)clear
{
	[dataLock lock];
    [genericData release];
    genericData = nil;
    [self setTotalCounts:0];
	[dataLock unlock];
}


#pragma mark ¥¥¥Data Source Methods

- (NSString*)   name
{
	[dataLock lock];
	NSString* temp = [[genericData retain] autorelease];
	[dataLock unlock];
    return [NSString stringWithFormat:@"%@ %@ Counts: %u",key, temp, [self totalCounts]];
}


- (void) setGenericData:(NSString*)aGenericData
{
	[dataLock lock];
    [genericData autorelease];
    genericData = [aGenericData copy];
    if(aGenericData)[self incrementTotalCounts];
	[dataLock unlock];
}
- (NSString*) genericData
{
	return genericData;
}

- (void) setCalibration:(id)aCalibration
{
}

#pragma mark ¥¥¥Archival
static NSString *ORGenericDataKey 			= @"GenericData Key";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	dataLock = [[NSLock alloc] init];
    
    [self setKey:[decoder decodeObjectForKey:ORGenericDataKey]];
    
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:key forKey:ORGenericDataKey];
}


@end
