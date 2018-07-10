//
//  ORSNOCard.m
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORSNOCard.h"
#import "ORSNOCrateModel.h"

BOOL sEnableNotifications = YES;

#pragma mark •••Notification Strings
NSString* ORSNOCardSlotChanged		= @"ORSNOCardSlotChanged";
NSString* ORSNOCardBoardIDChanged 	= @"ORSNOCardBoardIDChanged";

@implementation ORSNOCard
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
	[self setBoardID:@"0000"];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}
#pragma mark •••Accessors
- (Class) guardianClass 
{
	return NSClassFromString(@"ORSNOCrateModel");
}

- (NSString*) cardSlotChangedNotification
{
    return ORSNOCardSlotChanged;
}

- (int) tagBase
{
    return 0;
}

- (int) stationNumber
{
	return [[self crate] maxNumberOfObjects] - [self slot] - 1;
}

- (NSString*) fullID
{
	return [NSString stringWithFormat:@"%@,%d,%d",NSStringFromClass([self class]),[self crateNumber], [self stationNumber]];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
}

- (void) positionConnector:(ORConnector*)aConnector
{
}

- (NSString*) boardID
{
	if(!boardID)return @"0000";
	return boardID;
}

- (void) setBoardID:(NSString*)anId
{
	if(!anId)anId = @"0000";
	[boardID autorelease];
    boardID = [anId copy];    

    [self postNotificationName:ORSNOCardBoardIDChanged];
	
}

- (void) postNotificationName: (NSString*)name
{
    if (sEnableNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:self];
    }
}

+ (void) disableNotifications
{
    sEnableNotifications = NO;
}

+ (void) enableNotifications
{
    sEnableNotifications = YES;
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setBoardID:	[decoder decodeObjectForKey:  @"boardID"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:boardID forKey:@"boardID"];
}

//Added the following during a sweep to put the CrateView functionality into the Crate  objects MAH 11/18/08
- (int) station
{
	return [[self crate] maxNumberOfObjects] - [self slot] - 1;
}


@end

