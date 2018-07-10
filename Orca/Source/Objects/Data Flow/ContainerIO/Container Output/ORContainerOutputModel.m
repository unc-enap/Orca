//
//  ORContainerOutputModel.m
//  Orca
//
//  Created by Mark Howe on Wed Oct 12, 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORContainerOutputModel.h"
#import "ORMessagePipe.h"

#pragma mark ¥¥¥String Definitions
static NSString *kContainerOutputConnectorKey[4]  = {
    @"Container Output Connector 1",
    @"Container Output Connector 2",
    @"Container Output Connector 3",
    @"Container Output Connector 4",
};

@implementation ORContainerOutputModel

#pragma mark ¥¥¥Initialization
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"ContainerOutput"]];
	[super setUpImage];
}


- (void) makeMainController
{
    [self linkToController:@"ORContainerOutputController"];
}

- (int) ioType
{
	return kOutputConnector;
}

#pragma mark ¥¥¥Accessors
- (NSString*) connectorKey:(int)i
{
	if(i>=0 && i<4)return kContainerOutputConnectorKey[i];
	else return @"";
}

#pragma mark ¥¥¥Subclass responsiblility
- (void) setUpMessagePipeLocal:(ORConnector*)localConnector remote:(ORConnector*)remoteConnector  pipe:(ORMessagePipe*)aPipe
{
	[localConnector setIoType:kInputConnector];

	[localConnector setObjectLink:aPipe];
	[aPipe setDestination:remoteConnector];
}


@end
