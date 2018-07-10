//
//  ORCRGetterModel.m
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
#import "ORCRGetterModel.h"
#import "ORProcessThread.h"
#import "ORProcessOutConnector.h"

@implementation ORCRGetterModel

#pragma mark ¥¥¥Initialization

- (void) setUpImage
{
    if([self state]) [self setImage:[NSImage imageNamed:@"CRGetterOn"]];
    else             [self setImage:[NSImage imageNamed:@"CRGetterOff"]];
    [self addOverLay];
}

-(void)makeConnectors
{
    
    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORInputElementOutConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
    
}


- (void) makeMainController
{
    [self linkToController:@"ORCRGetterController"];
}

- (NSString*) elementName
{
	return @"CR Getter";
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
- (id) eval
{
	ORProcessResult* theResult =  [ORProcessThread getCR:bit];
	[self setState:[theResult boolValue]];
	return theResult;
}
//--------------------------------

@end
