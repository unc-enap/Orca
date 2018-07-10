//
//  main.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 03 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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



#import "NetSocket.h"
//#import <Foundation/NSDebug.h>

int main(int argc, const char *argv[])
{
#if defined(MAC_OS_X_VERSION_10_9) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9)
    [[NSProcessInfo processInfo] beginActivityWithOptions:(/*NSActivityLatencyCritical |*/ NSActivityUserInitiated)
                                                   reason:@"Real-time control/DAQ"];
#endif
	//NSZombieEnabled = YES;
    signal(SIGPIPE,SIG_IGN); //even with this line, Xcode will hit an automatic break point here
                            //put a breakpoint on this above line and edit the breakpoint to add the following debugger command
                            //process handle SIGPIPE -n false -s false
                            //and select the option to automatically continue
	[NetSocket ignoreBrokenPipes];
	return  NSApplicationMain(argc, argv);
}
