//
//  MonspectrometerModel.m
//  Orca
//
//  Created by Mark Howe on Wed Dec 8 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
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
#import "MonspectrometerModel.h"
#import "ORSegmentGroup.h"
#import "ORDataSet.h"

static NSString* MonSpecDbConnector		= @"MonSpecDbConnector";


@implementation MonspectrometerModel

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"monspectrometer"]];
}

- (void) makeMainController
{
    [self linkToController:@"MonspectrometerController"];
}

- (NSString*) helpURL
{
	return @"KATRIN/Monspectrometer.html";
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:MonSpecDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB O' ];
	[ aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
	NSMutableArray* mapEntries = [self setupMapEntries:0];//default set	
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"Monspectrometer" numSegments:5 mapEntries:mapEntries];
	[self addGroup:group];
	[group release];
}

- (float) getTotalRate
{
	float rate=0;
	if([segmentGroups count]!=0) rate = [[segmentGroups objectAtIndex:0] rate];
	return rate;
}

- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		NSString* cardName = [aGroup segment:index objectForKey:@"kCardSlot"];
		NSString* chanName = [aGroup segment:index objectForKey:@"kChannel"];
		if(cardName && chanName && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
					id histoObj = [arrayOfHistos objectAtIndex:0];
						
					aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"FLT", @"Energy", @"Crate  0",
															[NSString stringWithFormat:@"Station %2d",[cardName intValue]], 
															[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
															nil]];
					
					
					[aDataSet doDoubleClick:nil];
				}
			}
		}
	}
}

- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index
{
	ORSegmentGroup* theGroup = [segmentGroups objectAtIndex:aGroup];
	
	NSString* crateName = [theGroup segment:index objectForKey:@"kCrate"];
	NSString* cardName  = [theGroup segment:index objectForKey:@"kCardSlot"];
	NSString* chanName  = [theGroup segment:index objectForKey:@"kChannel"];
	
	return [NSString stringWithFormat:@"FLT,Energy Histogram (HW),Crate %2d,Station %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}

- (int)  maxNumSegments
{
	return 5;
}

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"MonspectrometerMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"MonspectrometerDetectorLock";
}

- (NSString*) experimentDetailsLock	
{
	return @"MonspectrometerDetailsLock";
}

@end