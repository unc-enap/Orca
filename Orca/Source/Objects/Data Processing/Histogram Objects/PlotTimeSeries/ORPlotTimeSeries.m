//
//  ORPlotTimeSeries.m
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


#import "ORPlotTimeSeries.h"
#import "ORDataPacket.h"
#import "ORTimeSeries.h"

NSString* ORPlotTimeSeriesShowChanged = @"ORPlotTimeSeriesShowChanged";

@implementation ORPlotTimeSeries

- (id) init 
{
    self = [super init];
	dataLock = [[NSRecursiveLock alloc] init];
    return self;    
}

- (void) dealloc
{
	[timeSeries release];
	[dataLock release];
    [super dealloc];
}


#pragma mark ¥¥¥Accessors
- (void) addValue:(float)aValue atTime:(unsigned long)aTime
{
    if(!timeSeries){
        timeSeries = [[ORTimeSeries alloc] init];
    }
	[dataSetLock lock];
	[timeSeries addValue:aValue atTime:aTime];
	[dataSetLock unlock];
	[self incrementTotalCounts];

}


- (ORTimeSeries*) timeSeries
{
	return timeSeries;
}

#pragma mark ¥¥¥Data Management
-(void)clear
{
	[dataSetLock lock];
	[timeSeries clear];
    [self setTotalCounts:0];
	[dataSetLock unlock];
}

- (void) incrementTotalCounts
{
	[super incrementTotalCounts];
}

- (int)	count
{
	return [timeSeries count];
}

#pragma mark ¥¥¥Writing Data
- (void) writeDataToFile:(FILE*)aFile
{
/*	[dataSetLock lock];
    fprintf( aFile, "WAVES/I/N=(%d) '%s'\nBEGIN\n",numberBins,[shortName cStringUsingEncoding:NSASCIIStringEncoding]);
    int i;
    for (i=0; i<numberBins; ++i) {
        fprintf(aFile, "%ld\n",histogram[i]);
    }
    fprintf(aFile, "END\n\n");
	[dataSetLock unlock];
*/
}

- (void) processResponse:(NSDictionary*)aResponse
{
	[dataSet processResponse:aResponse];
}

#pragma mark ¥¥¥Data Source Methods

- (id)   name
{
    return [NSString stringWithFormat:@"%@ Counts: %lu",[self key], [self totalCounts]];
}

- (BOOL) canJoinMultiPlot
{
    return YES;
}

#pragma  mark ¥¥¥Actions
- (void) makeMainController
{
    [self linkToController:@"ORPlotTimeSeriesController"];
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	dataLock = [[NSRecursiveLock alloc] init];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}


@end
