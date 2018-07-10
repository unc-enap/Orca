
//
//  ORVme64CrateController.m
//  Orca
//
//  Created by Mark Howe on Tue Oct 23 2007.
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


#pragma mark ¥¥¥Imported Files
#import "ORVme64CrateController.h"
#import "ORVme64CrateModel.h"

@implementation ORVme64CrateController

- (id) init
{
    self = [super initWithWindowNibName:@"Vme64Crate"];
    return self;
}

- (void) setCrateTitle
{
	[[self window] setTitle:[NSString stringWithFormat:@"VME64 crate %u",[model crateNumber]]];
}

@end
