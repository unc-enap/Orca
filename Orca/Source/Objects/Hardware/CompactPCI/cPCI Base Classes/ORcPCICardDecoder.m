//
//  ORVmeCardDecoder.m
//  Orca
//
//  Created by Mark Howe on 9/21/04.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORcPCICardDecoder.h"

#pragma mark ¥¥¥Static Definitions

static NSString* kCardKey[32] = {
	//pre-make some keys for speed.
	@"Card  0", @"Card  1", @"Card  2", @"Card  3",
	@"Card  4", @"Card  5", @"Card  6", @"Card  7",
	@"Card  8", @"Card  9", @"Card 10", @"Card 11",
	@"Card 12", @"Card 13", @"Card 14", @"Card 15",
	@"Card 16", @"Card 17", @"Card 18", @"Card 19",
	@"Card 20", @"Card 21", @"Card 22", @"Card 23",
	@"Card 24", @"Card 25", @"Card 26", @"Card 27",
	@"Card 28", @"Card 29", @"Card 30", @"Card 31"
};

@implementation ORcPCICardDecoder

- (NSString*) getCardKey:(unsigned short)aCard
{
	if(aCard<16) return kCardKey[aCard];
	else return [NSString stringWithFormat:@"Card %2d",aCard];		
	
}

@end
