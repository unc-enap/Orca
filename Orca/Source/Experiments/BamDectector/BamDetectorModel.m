//
//  BamDetectorModel.m
//  Orca
//
//  Created by Mark Howe on Thur Jan,27 2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark ¥¥¥Imported Files
#import "BamDetectorModel.h"
#import "ORSegmentGroup.h"

@implementation BamDetectorModel

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"BamDetector"]];
}

- (void) makeMainController
{
    [self linkToController:@"BamDetectorController"];
}

- (NSString*) helpURL
{
	return @"KATRIN/BamDetector.html";
}

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
	NSMutableArray* mapEntries = [self setupMapEntries:0];//default set	
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"BamDetector" numSegments:14 mapEntries:mapEntries];
	[self addGroup:group];
	[group release];
}

- (int)  maxNumSegments
{
	return 14;
}

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"BamDetectorMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"BamDetectorDetectorLock";
}

- (NSString*) experimentDetailsLock	
{
	return @"BamDetectorDetailsLock";
}

@end