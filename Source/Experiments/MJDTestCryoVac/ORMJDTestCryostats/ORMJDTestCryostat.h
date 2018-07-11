//
//  ORMJDTestCryostat.h
//  Orca
//
//  Created by Mark Howe on Mon Aug 13, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORVacuumParts.h"

@class ORVacuumGateValve;
@class ORVacuumPipe;

#define kNotConnected			0
#define kConnectedToLeftSide	1
#define kConnectedToRightSide	2

@interface ORMJDTestCryostat : NSObject
{
	id					 delegate;
	int					 connectionStatus; 
	NSUInteger	         tag;
	NSMutableDictionary* partDictionary;
	NSMutableDictionary* valueDictionary;
	NSMutableDictionary* statusDictionary;
	NSMutableArray*		 parts;
}

#pragma mark ***Accessors
- (id) model;
- (int) connectionStatus;
- (void) setConnectionStatus:(int) aState;
- (NSUInteger) tag;
- (void) setTag:(NSUInteger)aValue;
- (BOOL) showGrid;
- (void) setDelegate:(id)aDelegate;
- (void) makeParts;
- (NSArray*) parts;
- (int) stateOfGateValve:(int)aTag;
- (NSArray*) pipesForRegion:(int)aTag;
- (ORVacuumPipe*) onePipeFromRegion:(int)aTag;
- (NSArray*) gateValves;
- (ORVacuumGateValve*) gateValve:(int)aTag;
- (NSArray*) valueLabels;
- (NSArray*) statusLabels;
- (NSArray*) staticLabels;
- (NSArray*) gateValvesConnectedTo:(int)aRegion;
- (NSColor*) colorOfRegion:(int)aRegion;
- (NSString*) namesOfRegionsWithColor:(NSColor*)aColor;
- (NSString*) valueLabel:(int)region;
- (NSString*) statusLabel:(int)region;
- (void) openDialogForComponent:(int)i;
- (NSString*) regionName:(int)i;

#pragma mark ***Notificatons
- (void) pressureGaugeChanged:(NSNotification*)aNote;
- (void) temperatureGaugeChanged:(NSNotification*)aNote;


@end

extern NSString* ORMJDTestCryoConnectionChanged;

