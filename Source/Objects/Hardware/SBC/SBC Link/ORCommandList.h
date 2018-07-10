//
//  ORCommandList.h
//  Orca
//
//  Created by Mark Howe on 12/11/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//
/*-----------------------------------------------------------
 This program was prepared for the Regents of the University of 
 Washington at the Center for Experimental Nuclear Physics and 
 Astrophysics (CENPA) sponsored in part by the United States 
 Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
 The University has certain rights in the program pursuant to 
 the contract and the program should not be copied or distributed 
 outside your organization.  The DOE and the University of 
 Washington reserve all rights in the program. Neither the authors,
 University of Washington, or U.S. Government make any warranty, 
 express or implied, or assume any liability or responsibility 
 for the use of this software.
 -------------------------------------------------------------*/
#import "SBC_Cmds.h"
@interface ORCommandList : NSObject {
	NSMutableArray*	commands;
}
+ (id) commandList;
- (int) addCommand:(id)aCommand;
- (NSEnumerator*) objectEnumerator;
- (NSMutableArray*) commands;
- (int) addCommands:(ORCommandList*)anOtherList;
- (id) command:(int)index;
- (void) SBCPacket:(SBC_Packet*)blockPacket;
- (void) extractData:(SBC_Packet*) aPacket;
- (long) longValueForCmd:(int)anIndex;
- (short) shortValueForCmd:(int)anIndex;
- (NSData*) dataForCmd:(int)anIndex;
@end
