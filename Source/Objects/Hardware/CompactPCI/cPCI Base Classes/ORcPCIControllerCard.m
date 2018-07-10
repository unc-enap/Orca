//
//  ORcPCIControllerCard.m
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
#import "ORcPCIControllerCard.h"

@implementation ORcPCIControllerCard

#pragma mark ¥¥¥Accessors
- (void) setGuardian:(id)aGuardian
{
    if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:[self adapter]];			
		}
	}
    else [[self guardian] setAdapter:nil];
    
    [super setGuardian:aGuardian];
}

- (id) adapter
{
	return self;
}

- (id) controller
{
    return [[self crate] controllerCard];
}


- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}

@end
