//
//  ORRemoteSocketStep.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 28, 2013.
//  Copyright (c) 2013  University of North Carolina. All rights reserved.
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

#import "OROpSeqStep.h"
@class ORRemoteSocketModel;

@interface ORRemoteSocketStep : OROpSeqStep
{
	NSMutableArray*        commands;
	ORRemoteSocketModel*   socketObject;
    NSNumber*              cmdIndexToExecute;
	NSString*              outputStateKey;
}

@property (retain) ORRemoteSocketModel*   socketObject;
@property (retain) NSMutableArray*        commands;
@property (retain) NSNumber*              cmdIndexToExecute;
@property (copy) NSString*                outputStateKey;

+ (ORRemoteSocketStep*)remoteSocket:(ORRemoteSocketModel*)aSocketObj commandSelection:(id)anIndex commands:(NSString *)aCmd, ... NS_REQUIRES_NIL_TERMINATION;
- (void) executeCmd:(NSString*)aCmd;

@end
