//
//  OREDSF130pModel.m
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
#import "OREDSF130pModel.h"
#import "ORHWWizSelection.h"

NSString*  OREDSF130pSettingsLock = @"OREDSF130pSettingsLock";

#define kMaxVoltage 3000

@implementation OREDSF130pModel

#pragma mark ***Initialization
- (NSString*) imageName
{
    return @"EDSF130p";
}

- (void) makeMainController
{
    [self linkToController:@"OREDSF130pController"];
}

- (NSString*) settingsLock
{
	 return OREDSF130pSettingsLock;
}

- (NSString*) name
{
	 return @"EDSF130p";
}

- (BOOL) polarity
{
	return kPositivePolarity;
}
- (NSString*) helpURL
{
	return @"MPod/EDSF130p.html";
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
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel		name:@"Card"	className:@"OREDSF130pModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel	name:@"Channel" className:@"OREDSF130pModel"]];
    return a;
}
@end
