//
//  ORVmeMCard.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORVmeMCard.h"

@implementation ORVmeMCard

- (int) slotConv
{
    int conv[4] = {0,1,2,3};
    int aSlot = [self slot];
    if(aSlot>=0 && aSlot<=3)return conv[aSlot];
    else return -1;
}


- (NSString*) identifier
{
	int i = [self slotConv];
    if(i<0)return @"Bad Slot???";
	NSString* s[4]={
		@" M-Module 0",
		@" M-Module 1",
		@" M-Module 2",
		@" M-Module 3"
	};
	return [NSString stringWithString:s[i]];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORMCarrierModel");
}


- (unsigned long) baseAddress
{
    return [[self guardian] baseAddress]+ [self slot] * 0x200;
}

@end
