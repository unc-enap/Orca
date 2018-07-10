//
//  ORTimeMultiPlot.m
//  Orca
//
//  Created by Mark Howe on Fri May 16, 2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.//-----------------------------------------------------------
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


#import "ORTimeMultiPlot.h"

@implementation ORTimeMultiPlot
#pragma mark •••Accessors
- (id)   name
{
    if(plotName == nil) [self setPlotName:@"TimeMultiPlot"];
    return plotName;
}

- (void) makeMainController
{
    [self linkToController:@"ORTimeMultiPlotController"];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{ 
    if(!cachedDataSets)[self reCache:nil];
    if(set>=[cachedDataSets count])return 0;
    else return [[cachedDataSets objectAtIndex:set] count];
}

@end

