//
//  OREHS130nModel.h
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
#import "ORiSegHVCard.h"

@interface OREHS130nModel : ORiSegHVCard
{
}

#pragma mark ***Initialization
- (NSString*) imageName;
- (void) makeMainController;

#pragma mark ***Accessors
- (NSString*) settingsLock;
- (NSString*) name;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Hardware Wizard
- (NSArray*) wizardSelections;
@end

extern NSString*  OREHS130nSettingsLock;