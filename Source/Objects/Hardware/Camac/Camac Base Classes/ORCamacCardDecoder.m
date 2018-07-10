//
//  ORCamacCardDecoder.m
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


#import "ORCamacCardDecoder.h"

#pragma mark •••Static Definitions
static NSString* kChanKey[32] = {
	//pre-make some keys for speed.
	@"Channel  0", @"Channel  1", @"Channel  2", @"Channel  3",
	@"Channel  4", @"Channel  5", @"Channel  6", @"Channel  7",
	@"Channel  8", @"Channel  9", @"Channel 10", @"Channel 11",
	@"Channel 12", @"Channel 13", @"Channel 14", @"Channel 15",
	@"Channel 16", @"Channel 17", @"Channel 18", @"Channel 19",
	@"Channel 20", @"Channel 21", @"Channel 22", @"Channel 23",
	@"Channel 24", @"Channel 25", @"Channel 26", @"Channel 27",
	@"Channel 28", @"Channel 29", @"Channel 30", @"Channel 31"
};

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

static NSString* kCrateKey[16] = {
	//pre-make some keys for speed.
	@"Crate  0", @"Crate  1", @"Crate  2", @"Crate  3",
	@"Crate  4", @"Crate  5", @"Crate  6", @"Crate  7",
	@"Crate  8", @"Crate  9", @"Crate 10", @"Crate 11",
	@"Crate 12", @"Crate 13", @"Crate 14", @"Crate 15"
};

@implementation ORCamacCardDecoder

- (NSString*) getChannelKey:(unsigned short)aChan
{
	if(aChan<32) return kChanKey[aChan];
	else return [NSString stringWithFormat:@"Channel %2d",aChan];	
}

- (NSString*) getCrateKey:(unsigned short)aCrate
{
	if(aCrate<16) return kCrateKey[aCrate];
	else return [NSString stringWithFormat:@"Crate %2d",aCrate];		
}

- (NSString*) getStationKey:(unsigned short)aStation
{
	if(aStation<32) return kStationKey[aStation];
	else return [NSString stringWithFormat:@"Station %2d",aStation];		
}
- (NSString*) getCardKey:(unsigned short)aCard
{
	return [self getStationKey:aCard];
}
@end
