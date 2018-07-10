//
//  ORRunVetoModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
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
#import "ORRunVetoModel.h"
#import "ORProcessInConnector.h"

@implementation ORRunVetoModel

#pragma mark ¥¥¥Initialization

-(void)makeConnectors
{
	ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:OROutputElementInConnection];
    [inConnector setConnectorType: 'LP1 ' ];
    [inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
}

- (NSString*) elementName
{
	return @"Run Veto";
}

- (id) stateValue
{
	if([self state])return @"Run Vetoed";
	else			return @"Go for Run";
}

- (void) postStateChange
{
	[super postStateChange];
	NSString* vetoName    = [NSString stringWithFormat:@"Process %lu RunVeto %lu",[guardian uniqueIdNumber],[self uniqueIdNumber]];
	NSString* vetoComment = [self comment];
	if([vetoComment length] == 0)vetoComment = @"No reason given.";
	
	if([self state]) [[ORGlobal sharedGlobal] addRunVeto:vetoName comment:vetoComment]; 
	else			 [[ORGlobal sharedGlobal] removeRunVeto:vetoName]; 
	
}

- (void) setUpImage
{
	if([self state])[self setImage:[NSImage imageNamed:@"RunVetoed"]];
	else			[self setImage:[NSImage imageNamed:@"RunNotVetoed"]];
	[self addOverLay];
}

- (void) makeMainController
{
    [self linkToController:@"ORRunVetoController"];
}

- (void) processIsStopping
{
    [super processIsStopping];
    [self setState:NO];
}

- (void) addOverLay
{
    if(!guardian) return;

    NSImage* aCachedImage = [self image];
    NSSize theIconSize = [aCachedImage size];
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];        
    NSFont* theFont = [NSFont messageFontOfSize:9];
	NSAttributedString* n = [[NSAttributedString alloc] 
		initWithString:[NSString stringWithFormat:@"%lu",[self uniqueIdNumber]] 
			attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
	
	NSSize textSize = [n size];
	[n drawInRect:NSMakeRect(0,theIconSize.height-textSize.height,textSize.width,textSize.height)];
	[n release];
    
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
}


@end
