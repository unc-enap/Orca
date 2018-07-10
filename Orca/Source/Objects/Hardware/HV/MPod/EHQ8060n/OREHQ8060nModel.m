//
//  OREHQ8060nModel.m
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
#import "OREHQ8060nModel.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizSelection.h"

NSString*  OREHQ8060nSettingsLock = @"OREHQ8060nSettingsLock";

@implementation OREHQ8060nModel

#pragma mark ***Initialization

- (NSString*) imageName
{
    return @"EHQ8060n";
}
- (void) makeMainController
{
    [self linkToController:@"OREHQ8060nController"];
}

- (NSString*) settingsLock
{
	 return OREHQ8060nSettingsLock;
}

- (NSString*) name
{
	 return @"EHQ8060n";
}

- (BOOL) polarity
{
	return kNegativePolarity;
}
- (NSString*) helpURL
{
	return @"MPod/EHQ8060n.html";
}
#pragma mark ***Accessors


- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel	name:@"Crate"	className:@"ORMPodCrate"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel		name:@"Card"	className:@"OREHQ8060nModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel	name:@"Channel" className:@"OREHQ8060nModel"]];
    return a;
	
}
@end
