//
//  ORcPCICard.m
//  Orca
//
//  Created by Mark Howe on Mon Feb 6 2006.
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
#import "ORcPCICard.h"


#pragma mark ¥¥¥Notification Strings
NSString* ORcPCICardSlotChangedNotification 	= @"ORcPCICardSlotChangedNotification";

// methods
@implementation ORcPCICard
#pragma mark ¥¥¥accessors

- (int) tagBase
{
    return 1;
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORcPCICrateModel");
}

- (NSString*) cardSlotChangedNotification
{
    return ORcPCICardSlotChangedNotification;
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"station %d",[self stationNumber]];
}

- (int) stationNumber
{
    return [self tag]+1;
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
