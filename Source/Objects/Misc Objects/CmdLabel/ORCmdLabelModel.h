//
//  ORLabelModel.h
//  Orca
//
//  Created by Mark Howe on Tuesday Apr 6,2009.
//  Copyright © 20010 University of North Carolina. All rights reserved.
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
#import "ORLabelModel.h"

@interface ORCmdLabelModel : ORLabelModel  
{
	NSMutableArray* commands;
}

#pragma mark •••Initialization
- (id) init;
- (void) makeMainController;
- (void) setUpImage;

#pragma mark •••Accessor
- (NSMutableArray*) commands;
- (void) setCommands:(NSMutableArray*)anArray;
- (NSDictionary*) commandAtIndex:(int)index;
- (NSUInteger) commandCount;
- (void) postDetailsChanged;
- (void) addCommand;
- (void) removeCommand:(int)index;
- (BOOL) checkSyntax:(int)index;
- (void) executeCommand:(int) index;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORCmdLableDetailsChanged;
extern NSString* ORCmdLabelTextSizeChanged;
