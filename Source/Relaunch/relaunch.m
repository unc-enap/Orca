//
//  relaunchOrca
//
//  Original by Matt Patenaude on 4/16/09.
//  Modified by Mark Howe on June 14, 2014 for incorporation into ORCA
//  Copyright © 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import <Cocoa/Cocoa.h>
//This is a separate XCode target in the ORCA build.
//The resulting binary is bundled in ORCA as a resource
//Used to relaunch the ORCA applicatin from the Archive Center

int main(int argc, char *argv[])
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	pid_t parentPID = atoi(argv[2]);
    while([NSRunningApplication runningApplicationWithProcessIdentifier:parentPID]!=nil){
        sleep(1);
	}
	NSString* appPath = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
	BOOL success = [[NSWorkspace sharedWorkspace] openFile:[appPath stringByExpandingTildeInPath]];
	
	if (!success) NSLog(@"Error: could not relaunch ORCA at %@", appPath);
	
	[pool release];
	return success ? 0 : 1;
}
