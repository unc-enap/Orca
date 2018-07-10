//
//  ORCamacCard.m
//  Orca
//
//  Created by Mark Howe on Wed Dec 29 2004.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

#pragma mark ¥¥¥imports
#import "ORCamacCard.h"


#pragma mark ¥¥¥Notification Strings
NSString* ORCamacCardSlotChangedNotification 	= @"ORCamacCardSlotChangedNotification";

// methods
@implementation ORCamacCard
#pragma mark ¥¥¥accessors

- (int) tagBase
{
    return 1;
}

- (NSString*) fullID
{
    return [NSString stringWithFormat:@"%@,%d,%d",NSStringFromClass([self class]),[self crateNumber], [self stationNumber]];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORCamacCrateModel");
}

- (NSString*) cardSlotChangedNotification
{
    return ORCamacCardSlotChangedNotification;
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"station %d",[self stationNumber]];
}

- (int) slot
{
	return [self tag];
}

- (int) stationNumber
{
    return [self tag]+1;
}

- (BOOL)    cmdResponse
{
    return cmdResponse;
}

- (void)    setCmdResponse:(BOOL)aValue
{
    cmdResponse = aValue;
}

- (BOOL)    cmdAccepted
{
    return cmdAccepted;
}

- (void)    setCmdAccepted:(BOOL)aValue
{
    cmdAccepted = aValue;
}

- (BOOL)    inhibit
{
    return inhibit;
}

- (void)    setInhibit:(BOOL)aValue
{
    inhibit = aValue;
}

- (BOOL)    lookAtMe
{
    return lookAtMe;
}

- (void)    setLookAtMe:(BOOL)aValue
{
    lookAtMe = aValue;
}

- (void) decodeStatus:(unsigned short)aStatusWord
{
    lookAtMe    = aStatusWord & 0x0001;
    inhibit     = ( aStatusWord >> 1 ) & 0x0001;
    cmdAccepted = ( aStatusWord >> 2 ) & 0x0001;
    cmdResponse    = ( aStatusWord >> 3 ) & 0x0001;
}


#pragma mark ¥¥¥archival
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithInt:[self stationNumber]] forKey:@"Card"];
    [dictionary setObject:objDictionary forKey:[self identifier]];
    return objDictionary;
}

@end
