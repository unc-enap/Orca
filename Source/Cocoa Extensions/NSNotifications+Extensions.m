//
//  NSNotifications+Extensions.m
//  Orca
//
//  Created by Mark Howe on 12/24/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
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

#import <pthread.h>
#import "NSNotifications+Extensions.h"

@implementation NSNotificationCenter (OrcaExtensions)
- (void) postNotificationOnMainThread:(NSNotification *) notification 
{
	if( pthread_main_np() ) return [self postNotification:notification];
	[self postNotificationOnMainThread:notification waitUntilDone:NO];
}

- (void) postNotificationOnMainThread:(NSNotification *) notification waitUntilDone:(BOOL) wait 
{
	if( pthread_main_np() ) return [self postNotification:notification];
	[self performSelectorOnMainThread:@selector( _postNotification: ) withObject:notification waitUntilDone:wait];
}

- (void) _postNotification:(NSNotification *) notification 
{
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void) postNotificationOnMainThreadWithName:(NSString *) name object:(id) object 
{
	if( pthread_main_np() ) return [self postNotificationName:name object:object userInfo:nil];
	[self postNotificationOnMainThreadWithName:name object:object userInfo:nil waitUntilDone:NO];
}

- (void) postNotificationOnMainThreadWithName:(NSString *) name object:(id) object userInfo:(NSDictionary *) userInfo 
{
	if( pthread_main_np() ) return [self postNotificationName:name object:object userInfo:userInfo];
	[self postNotificationOnMainThreadWithName:name object:object userInfo:userInfo waitUntilDone:NO];
}

- (void) postNotificationOnMainThreadWithName:(NSString *) name object:(id) object userInfo:(NSDictionary *) userInfo waitUntilDone:(BOOL) wait 
{
	if( pthread_main_np() ) return [self postNotificationName:name object:object userInfo:userInfo];
	
	//******The info dictionary is released in _postNotificationName.
	NSMutableDictionary *info = [[NSMutableDictionary allocWithZone:nil] initWithCapacity:3];
	if( name ) [info setObject:name forKey:@"name"];
	if( object ) [info setObject:object forKey:@"object"];
	if( userInfo ) [info setObject:userInfo forKey:@"userInfo"];
	
	[self performSelectorOnMainThread:@selector( _postNotificationName: ) withObject:info waitUntilDone:wait];
}

- (void) _postNotificationName:(NSDictionary *) info 
{
	NSString *name = [info objectForKey:@"name"];
	id object = [info objectForKey:@"object"];
	NSDictionary *userInfo = [info objectForKey:@"userInfo"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:object userInfo:userInfo];
	
	[info release]; // Balance the alloc in postNotificationOnMainThreadWithName.
}
@end
