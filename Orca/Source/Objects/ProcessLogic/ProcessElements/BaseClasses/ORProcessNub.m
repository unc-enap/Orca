//
//  ORProcessNub.m
//  Orca
//
//  Created by Mark Howe on 11/21/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORProcessNub.h"

//this is a placeholder class for logic objects that have to intercept the
//eval message and do something to the state before returning it.

@implementation ORProcessNub
- (void) setGuardian:(id)aGuardian
{
    //note the children do NOT retain their guardians to avoid retain cycles.
    guardian = aGuardian;
}

- (BOOL) highlighted
{
	return [guardian highlighted];
}

- (int) state
{
	return [guardian state];
}

- (int) evaluatedState
{
    return [guardian evaluatedState];
}

- (id) eval
{
    return [guardian eval];
}

- (void) processIsStopping
{
    [guardian processIsStopping];
}

- (void) processIsStarting
{
    [guardian processIsStarting];
}

- (BOOL) partOfRun
{
	return [guardian partOfRun];
}

- (NSString*) description:(NSString*)prefix
{
    return [guardian description:prefix];
}

- (void) connectionChanged
{
	//nothing to do.... prevents a run-time error
}
@end
