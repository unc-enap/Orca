//
//  ORSplitterModel.m
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
#import "ORSplitterModel.h"
#import "ORProcessNub.h"
#import "ORProcessInConnector.h"
#import "ORProcessOutConnector.h"

NSString* ORSpliterOutConnection  = @"ORSpliterOutConnection";


@implementation ORSplitterModel

#pragma mark ¥¥¥Initialization
-(void)dealloc
{
    [outputNub release];
    [super dealloc];
}
- (void) setUpImage
{
    NSSize theNewSize = NSMakeSize(43,32);
    [self setFrame:NSMakeRect([self frame].origin.x,[self frame].origin.y,theNewSize.width,theNewSize.height)];
}

-(void) makeConnectors
{
	ORProcessInConnector* inConnector;
	ORProcessOutConnector* outConnector;

    inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,[self frame].size.height-kConnectorSize) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORSimpleLogicIn1Connection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];

    outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize ,[self frame].size.height-kConnectorSize) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORSimpleLogicOutConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];

    outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize ,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORSpliterOutConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
}

- (NSString*) elementName
{
	return @"Or Gate";
}

- (void) setUpNubs
{
    if(!outputNub)outputNub = [[ORProcessNub alloc] init];
    [outputNub setGuardian:self];
    ORConnector* aConnector = [[self connectors] objectForKey: ORSpliterOutConnection];
    [aConnector setObjectLink:outputNub];
}


- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency
{
    if([self useAltView])return;
    
    NSBezierPath* path = [NSBezierPath bezierPath];
	[path setLineWidth:.5];
    
    NSPoint inPoint   = NSMakePoint([self frame].origin.x+kConnectorSize/2,[self frame].origin.y+[self frame].size.height-kConnectorSize/2);
    NSPoint outPoint1 = NSMakePoint([self frame].origin.x+[self frame].size.width-kConnectorSize/2,[self frame].origin.y+[self frame].size.height-kConnectorSize/2);
    NSPoint outPoint2 = NSMakePoint([self frame].origin.x+[self frame].size.width-kConnectorSize/2,[self frame].origin.y+kConnectorSize/2);
    
    float x;
        	
	[path moveToPoint:inPoint];
	[path lineToPoint:outPoint1];
	
	switch ([[[NSUserDefaults standardUserDefaults] objectForKey: ORLineType] intValue]){
		case straightLines:
			[path moveToPoint:inPoint];
			[path lineToPoint:outPoint2];
		break;
			
		case squareLines:
			x = inPoint.x + fabs(outPoint1.x - inPoint.x)/2;
			[path moveToPoint:NSMakePoint(x,outPoint1.y)];
			[path lineToPoint:NSMakePoint(x,outPoint2.y)];
			[path lineToPoint:NSMakePoint(outPoint2.x,outPoint2.y)];
		break;
			
		case curvedLines:
			[path moveToPoint:inPoint];
			x = inPoint.x + fabs(outPoint2.x - inPoint.x)/2;
			[path curveToPoint:outPoint2 controlPoint1:NSMakePoint(x,outPoint1.y) controlPoint2:NSMakePoint(x,outPoint1.y)];
		break;
	}
	
	[colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORLineColor]) set];            
    [path stroke];
    
    [self drawConnections:aRect withTransparency:aTransparency];
    
}
//--------------------------------
//runs in the process logic thread
- (id) eval
{
    if(!alreadyEvaluated){
        alreadyEvaluated = YES;
        ORProcessResult* result = [self evalInput1];
        [self setState:[result boolValue]];
        value = [result analogValue];
    }
    [self setEvaluatedState: [self state]];
	return [ORProcessResult processState:evaluatedState value:value];
}
//--------------------------------

@end
