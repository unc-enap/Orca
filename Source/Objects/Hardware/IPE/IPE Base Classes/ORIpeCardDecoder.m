//
//  ORIpeStationDecoder.m
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


#import "ORIpeCardDecoder.h"

#pragma mark ¥¥¥Static Definitions

static NSString* kStationKey[32] = {
	//pre-make some keys for speed.
	@"Station  0", @"Station  1", @"Station  2", @"Station  3",
	@"Station  4", @"Station  5", @"Station  6", @"Station  7",
	@"Station  8", @"Station  9", @"Station 10", @"Station 11",
	@"Station 12", @"Station 13", @"Station 14", @"Station 15",
	@"Station 16", @"Station 17", @"Station 18", @"Station 19",
	@"Station 20", @"Station 21", @"Station 22", @"Station 23",
	@"Station 24", @"Station 25", @"Station 26", @"Station 27",
	@"Station 28", @"Station 29", @"Station 30", @"Station 31"
};


@implementation ORIpeCardDecoder

- (NSString*) getStationKey:(unsigned short)aStation
{
	if(aStation<32) return kStationKey[aStation];
	else return [NSString stringWithFormat:@"Station %2d",aStation];		
	
}

@end
