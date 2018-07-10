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


#import "ORVmeCardDecoder.h"

#pragma mark •••Static Definitions


static NSString* kMModuleKey[16] = {
	//pre-make some keys for speed.
	@"Module 0", @"Module  1", @"Module  2", @"Module  3"
};


@implementation ORVmeCardDecoder

- (NSString*) getMModuleKey:(unsigned short)aModule
{
	if(aModule<4)return kMModuleKey[aModule];
	else return @"???";
}

@end
