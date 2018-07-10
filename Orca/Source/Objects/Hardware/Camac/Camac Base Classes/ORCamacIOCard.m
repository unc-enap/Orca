//
//  ORCamacIOCard.m
//  Orca
//
//  Created by Mark Howe on Wed Dec 29 2004.
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
#import "ORCamacIOCard.h"


NSString* ORCamacIOCardExceptionCountChanged 			= @"ORCamacIOCardExceptionCountChanged";

@implementation ORCamacIOCard 

- (id)	adapter
{
	id anAdapter = [[self guardian] adapter];
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No adapter" format:@"You must place a Camac controller card into the crate."];
	return nil;
}

- (void)  checkCratePower
{   
    [[self adapter] checkCratePower];
}


- (unsigned long)   exceptionCount
{
    return exceptionCount;
}

- (void)clearExceptionCount
{
    exceptionCount = 0;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORCamacIOCardExceptionCountChanged
					   object:self]; 
    
}

- (void)incExceptionCount
{
    ++exceptionCount;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORCamacIOCardExceptionCountChanged
					   object:self]; 
}

@end