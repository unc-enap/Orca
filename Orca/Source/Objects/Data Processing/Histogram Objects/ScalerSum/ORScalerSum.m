//
//  ORScalerSum.m
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


#import "ORScalerSum.h"

@implementation ORScalerSum
- (id) init
{
    self = [super init];
	dataLock = [[NSLock alloc] init];
    return self;
}

- (void)dealloc
{
	[dataLock release];
    [super dealloc];
}

#pragma mark ¥¥¥Accessors


#pragma mark ¥¥¥Data Management

- (void) runTaskBoundary
{
	[dataLock lock];
    scalerSum += scalerValue;
    scalerValue = 0;
    [self incrementTotalCounts];
	[dataLock unlock];
}
- (void) runTaskStopped
{
	[dataLock lock];
    scalerSum += scalerValue;
    scalerValue = 0;
    long total = [self totalCounts]-1;
    if(total<0)total = 1;
    [self setTotalCounts:total];
	[dataLock unlock];
}


-(void)clear
{
	[dataLock lock];
    scalerValue = 0;
    scalerSum = 0;
    [self setTotalCounts:0];
	[dataLock unlock];
}


#pragma mark ¥¥¥Data Source Methods

- (NSString*)   name
{
	[dataLock lock];
	unsigned long temp = scalerSum;
	[dataLock unlock];
    return [NSString stringWithFormat:@"%@ #runs: %lu  scaler total: %lu",key,[self totalCounts],temp];
}

- (void) loadScalerValue:(unsigned long)newScaler
{
	[dataLock lock];
    scalerValue = newScaler;
	[dataLock unlock];
}

#pragma mark ¥¥¥Archival
static NSString *ORScalerSumKey 			= @"ScalerSum Key";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	dataLock = [[NSLock alloc] init];
    
    [self setKey:[decoder decodeObjectForKey:ORScalerSumKey]];
    
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:key forKey:ORScalerSumKey];
}


@end
