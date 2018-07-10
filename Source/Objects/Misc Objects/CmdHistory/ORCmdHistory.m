//
//  ORCmdHistory.m
//  OrcaIntel
//
//  Created by Mark Howe on 12/26/07.
//  Copyright 2007 University of North Carolina. All rights reserved.
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

#import "ORCmdHistory.h"

NSString* ORCmdHistoryChangedNotification	= @"ORCmdHistoryChangedNotification";

@implementation ORCmdHistory

- (void) dealloc
{
	[history release];
	[super dealloc];
}

- (void) addCommandToHistory:(NSString*)aCommandString
{
	if(!history){
		history = [[NSMutableArray array] retain];
		historyIndex = 0;
	}
	if(aCommandString){
		[history addObject:aCommandString];
		if([history count] > 50)[history removeObjectAtIndex:0];
		historyIndex = [history count]-1;
	}
}

- (void) moveInHistoryDown
{
	if(historyIndex<[history count]-1)historyIndex++;
	NSString* theCommand = [history objectAtIndex:historyIndex];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCmdHistoryChangedNotification 
														object:self 
													  userInfo:[NSDictionary dictionaryWithObject:theCommand forKey:ORCmdHistoryChangedNotification]];	
}

- (void) moveInHistoryUp
{
	if(historyIndex>0)historyIndex--;
	NSString* theCommand = [history objectAtIndex:historyIndex];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCmdHistoryChangedNotification 
														object:self 
													  userInfo:[NSDictionary dictionaryWithObject:theCommand forKey:ORCmdHistoryChangedNotification]];
}

@end
