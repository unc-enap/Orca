//
//  ORJoinerModel.m
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
#import "ORJoinerModel.h"

@implementation ORJoinerModel

#pragma mark ¥¥¥Initialization

- (void) setUpImage
{
    NSSize theNewSize = NSMakeSize(43,32);
    [self setFrame:NSMakeRect([self frame].origin.x,[self frame].origin.y,theNewSize.width,theNewSize.height)];
}

-(void) makeConnectors
{
    [super makeConnectors];
    ORConnector* aConnector;
    aConnector = [[self connectors] objectForKey:ORSimpleLogicIn1Connection];
    [aConnector setLocalFrame: NSMakeRect(0,0,kConnectorSize,kConnectorSize)];
    
    aConnector = [[self connectors] objectForKey:ORSimpleLogicIn2Connection];
    [aConnector setLocalFrame: NSMakeRect(0,[self frame].size.height-kConnectorSize,kConnectorSize,kConnectorSize)];

    aConnector = [[self connectors] objectForKey:ORSimpleLogicOutConnection];
    [aConnector setLocalFrame: NSMakeRect([self frame].size.width-kConnectorSize,[self frame].size.height-kConnectorSize,kConnectorSize,kConnectorSize)];

}

- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency
{
    if([self useAltView])return;
	
    NSBezierPath* path = [NSBezierPath bezierPath];
	[path setLineWidth:.5];
    
    NSPoint inPoint1 = NSMakePoint([self frame].origin.x+kConnectorSize/2,[self frame].origin.y+[self frame].size.height-kConnectorSize/2);
    NSPoint inPoint2 = NSMakePoint([self frame].origin.x+ kConnectorSize/2,[self frame].origin.y+kConnectorSize/2);
    NSPoint outPoint = NSMakePoint([self frame].origin.x+[self frame].size.width-kConnectorSize/2,[self frame].origin.y+[self frame].size.height-kConnectorSize/2);
    
    float x;
        	
	[path moveToPoint:inPoint1];
	[path lineToPoint:outPoint];
	
	switch ([[[NSUserDefaults standardUserDefaults] objectForKey: ORLineType] intValue]){
		case straightLines:
			[path moveToPoint:inPoint2];
			[path lineToPoint:outPoint];
		break;
			
		case squareLines:
			x = inPoint1.x + fabs(outPoint.x - inPoint1.x)/2;
			[path moveToPoint:NSMakePoint(x,inPoint1.y)];
			[path lineToPoint:NSMakePoint(x,inPoint2.y)];
			[path lineToPoint:NSMakePoint(inPoint2.x,inPoint2.y)];
			break;
			
		case curvedLines:
			[path moveToPoint:inPoint2];
			x = inPoint2.x + fabs(outPoint.x - inPoint2.x)/2;
			[path curveToPoint:outPoint controlPoint1:NSMakePoint(x,outPoint.y) controlPoint2:NSMakePoint(x,outPoint.y)];
			break;
	}
	
	[colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORLineColor]) set];            
    [path stroke];
    
    [self drawConnections:aRect withTransparency:aTransparency];
    
}

- (NSString*) elementName
{
	return @"Or Gate";
}
	
//--------------------------------
//runs in the process logic thread
- (id) eval
{
    [self setState:[[self evalInput1] boolValue] | [[self evalInput2] boolValue]];
    [self setEvaluatedState: [self state]];
	return [ORProcessResult processState:evaluatedState value:evaluatedState];
}
//--------------------------------

@end
