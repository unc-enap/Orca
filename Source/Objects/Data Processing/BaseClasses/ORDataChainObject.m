//
//  ORDataChainObject.m
//  OrcaIntel
//
//  Created by Mark Howe on 12/18/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
//
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
#import "ORDataChainObject.h"

NSString* ORDataChainObjectInvolvedInCurrentRun = @"ORDataChainObjectInvolvedInCurrentRun";

@implementation ORDataChainObject
- (BOOL) involvedInCurrentRun
{
	return involvedInCurrentRun;
}

- (void) setInvolvedInCurrentRun:(BOOL)state
{
	involvedInCurrentRun = state;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORDataChainObjectInvolvedInCurrentRun object: self];
}


- (void) addObjectInfoToArray:(NSMutableArray*)anArray
{
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	if([self respondsToSelector:@selector(addParametersToDictionary:)]){
		[self addParametersToDictionary:dictionary];
	}
	if([dictionary count]){
		[anArray addObject:dictionary];
	}
}

- (void) runIsStopping:(NSDictionary*)userInfo     { }
- (void) endOfRunCleanup:(NSDictionary*)userInfo   { }
- (void) setRunMode:(int)aMode          { }
- (void) runTaskStarted:(NSDictionary*)userInfo     { }
- (void) runTaskStopped:(NSDictionary*)userInfo     { }
- (void) closeOutRun:(NSDictionary*)userInfo     { }
- (void) subRunTaskStarted:(NSDictionary*)userInfo     { }

- (BOOL) runModals
{
	//objects can override.
	//return NO if run should not proceed.
	return YES;
}

@end

@implementation ORDataChainObjectWithGroup
- (BOOL) involvedInCurrentRun
{
	return involvedInCurrentRun;
}

- (void) setInvolvedInCurrentRun:(BOOL)state
{
	involvedInCurrentRun = state;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORDataChainObjectInvolvedInCurrentRun object: self];
}


- (void) addObjectInfoToArray:(NSMutableArray*)anArray
{
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	if([self respondsToSelector:@selector(addParametersToDictionary:)]){
		[self addParametersToDictionary:dictionary];
	}
	if([dictionary count]){
		[anArray addObject:dictionary];
	}
}

- (void) runIsStopping:(NSDictionary*)userInfo     { }
- (void) endOfRunCleanup:(NSDictionary*)userInfo   { }
- (void) setRunMode:(int)aMode          { }

- (BOOL) runModals
{
	//objects can override.
	//return NO if run should not proceed.
	return YES;
}

@end

