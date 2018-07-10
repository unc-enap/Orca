//
//  OREHS130nModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "OREHS130nModel.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizSelection.h"

NSString*  OREHS130nSettingsLock = @"OREHS130nSettingsLock";

@implementation OREHS130nModel

#pragma mark ***Initialization
- (NSString*) imageName
{
    return @"EHS130n";
}

- (void) makeMainController
{
    [self linkToController:@"OREHS130nController"];
}

- (NSString*) settingsLock
{
	 return OREHS130nSettingsLock;
}

- (NSString*) name
{
	 return @"EHS130n";
}

- (BOOL) polarity
{
	return kNegativePolarity;
}
- (NSString*) helpURL
{
	return @"MPod/EHS130n.html";
}
#pragma mark ***Accessors

- (int) numberOfChannels
{
    return 16;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel	name:@"Crate"	className:@"ORMPodCrate"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel		name:@"Card"	className:@"OREHS130nModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel	name:@"Channel" className:@"OREHS130nModel"]];
    return a;
}
@end
