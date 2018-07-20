//
//  ORDataTypeAssigner.m
//  Orca
//
//  Created by Mark Howe on 9/22/04.
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


#import "ORDataTypeAssigner.h"

@implementation ORDataTypeAssigner
- (id) init
{
    shortDeviceType = 32;
    longDeviceType  = 1; //reserve 0 for the header
    self = [super init];
    return self;
}

- (void) reset
{
    shortDeviceType = 32;
    longDeviceType  = 1; //reserve 0 for the header
}

- (void) assignDataIds
{
	
    NSMutableArray* classList = [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsRespondingTo:@selector(setDataIds:)] mutableCopy];
    
    while([classList count]){
        int i;
        Class lastObjectClass = [[classList lastObject] class];
        id firstObj = [[classList objectAtIndex:[classList count]-1] retain];
        [firstObj setDataIds:self];
        [classList removeObject:firstObj];
        
        for(i=(int)[classList count]-1;i>=0;i--){
            id anObj = [classList objectAtIndex:i];
            if( [anObj class] == lastObjectClass){
                [anObj syncDataIdsWith:firstObj];
                [classList removeObject:anObj];
            }
        }
        [firstObj release];
    }
    [classList release];
}

- (uint32_t) assignDataIds:(BOOL)wantsShort
{
    //a short device type is of the form 1xxx xx00 0000 0000 0000 0000 0000 0000  Note that the top bit is ALWAYS set
    //a int32_t device type is of the form  0xxx xxxx xxxx xx00 0000 0000 0000 0000  Note that the top bit is ALWAYS clear
    if(wantsShort && shortDeviceType<0x3f){ //11 1111 = 63
        return shortDeviceType++ << 26;
    }
    else {
        if(longDeviceType>(0x1fff-0x1)){ //limit - reserved ids
            [NSException raise:@"Device Type Assignment Error" format:@"Too many devices"];
        }
		if(longDeviceType+1 == 0x3C3C)longDeviceType++;	//0x3c3c is reserved for detecting the older files 
														//that don't wrap the xml header with an ORCA header.
        return longDeviceType++ << 18;
    }
}

- (uint32_t) reservedDataId:(NSString*)aClassName
{
	//reserved ids -- if you add to this list, don't forget to change the limit in the code above
	//ORCARootService -> 0x1fff
	if([aClassName isEqualToString: @"ORCARootService"]){
		return 0x1fff << 18;
	}
	[NSException raise:@"Device Type Assignment Error" format:@"Illegal Reserved Class"];
	return -1;
}

@end
