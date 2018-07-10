//
//  ORCRSetterModel.m
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
#import "ORCRSetterModel.h"
#import "ORProcessThread.h"
#import "ORProcessInConnector.h"

@implementation ORCRSetterModel

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
	[processResult release];
	processResult = nil;
	[super dealloc];
}

- (void) setUpImage
{
    if([self state]) [self setImage:[NSImage imageNamed:@"CRSetterOn"]];
    else             [self setImage:[NSImage imageNamed:@"CRSetterOff"]];
    [self addOverLay];
}

-(void)makeConnectors
{
    ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:OROutputElementInConnection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
}


- (void) makeMainController
{
    [self linkToController:@"ORCRSetterController"];
}

- (NSString*) elementName
{
	return @"CR Setter";
}

- (NSString*) fullHwName
{
    return [NSString stringWithFormat:@"CR Bit %d",[self bit]];;
}

- (void) setBit:(int)aBit
{
	if(aBit<0)aBit = 0;
	else if(aBit>255)aBit = 255;
	[super setBit:aBit];
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
		initWithString:[NSString stringWithFormat:@"%d",[self bit]] 
			attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
	
	NSSize textSize = [n size];
	[n drawInRect:NSMakeRect(theIconSize.width/2-textSize.width/2,theIconSize.height/2-textSize.height/2,textSize.width,textSize.height)];
	[n release];

    
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
}

//--------------------------------
//runs in the process logic thread

- (void) processIsStarting
{
    [super processIsStarting];
	[processResult release];
	processResult = nil;
}

- (id) eval
{
	if(!alreadyEvaluated){
		id obj = [self objectConnectedTo:OROutputElementInConnection];
		processResult = [obj eval];
		[self setState:[processResult boolValue]];
	}
	[ORProcessThread setCR:bit value:processResult];
	
    [self setEvaluatedState:processResult != nil];
	return processResult;
}
//--------------------------------
- (void) processIsStopping
{
    [super processIsStopping];
	[processResult release];
	processResult = nil;
}

@end
