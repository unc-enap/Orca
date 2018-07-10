//
//  ORProcessHistoryModel.m
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
#import "ORProcessHistoryModel.h"
#import "ORProcessInConnector.h"
#import "ORTimeRate.h"

NSString* ORProcessHistoryModelShowInAltViewChanged = @"ORProcessHistoryModelShowInAltViewChanged";
NSString* ORProcessHistoryModelHistoryLabelChanged = @"ORProcessHistoryModelHistoryLabelChanged";
NSString* ORHistoryElementIn1Connection   = @"ORHistoryElementIn1Connection";
NSString* ORHistoryElementIn2Connection   = @"ORHistoryElementIn2Connection";
NSString* ORHistoryElementIn3Connection   = @"ORHistoryElementIn3Connection";
NSString* ORHistoryElementIn4Connection   = @"ORHistoryElementIn4Connection";
NSString* ORHistoryElementDataChanged = @"ORHistoryElementDataChanged";

NSString* historyConnectors[4] = {
	@"ORHistoryElementIn1Connection",
	@"ORHistoryElementIn2Connection",
	@"ORHistoryElementIn3Connection",
	@"ORHistoryElementIn4Connection"
};

@interface ORProcessHistoryModel (private)
- (NSImage*) composeIcon;
- (NSImage*) composeLowLevelIcon;
- (NSImage*) composeHighLevelIcon;
- (void) drawPlotRepIntoRect:(NSRect)aRect maxPoints:(int)maxNumPoints;
@end

@implementation ORProcessHistoryModel

#pragma mark ¥¥¥Initialization

- (void) dealloc
{
	int i;
	for(i=0;i<4;i++)[inputValue[i] release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[lastEval release];
	[super dealloc];
}

- (void) sleep
{
	[super sleep];
	scheduledToRedraw = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark ***Accessors

- (BOOL) showInAltView
{
    return showInAltView;
}

- (void) setShowInAltView:(BOOL)aShowInAltView
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowInAltView:showInAltView];
    showInAltView = aShowInAltView;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessHistoryModelShowInAltViewChanged object:self];

	[self postStateChange];
}


- (void) makeConnectors
{
	ORProcessInConnector* inConnector;
	
	float yoffset = 0;
	int i;
	for(i=0;i<4;i++){
		inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,yoffset) withGuardian:self withObjectLink:self];
		[[self connectors] setObject:inConnector forKey:historyConnectors[i]];
		[inConnector setConnectorType: 'LP1 ' ];
		[inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
		[inConnector release];
		yoffset += kConnectorSize;
	}
}


- (void) setUpImage
{
	[self setImage:[self composeIcon]];
}

- (void) makeMainController
{
    [self linkToController:@"ORProcessHistoryController"];
}

- (NSString*) elementName
{
	return @"History";
}

- (void) postUpdate
{
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORHistoryElementDataChanged
					  object:self];
	
	if(!scheduledToRedraw){
        [self performSelector:@selector(updateIcon) withObject:nil afterDelay:5.0];
        scheduledToRedraw = YES;
    }
}

- (void) updateIcon
{
	scheduledToRedraw = NO;
	[self setUpImage];
}

- (BOOL) canBeInAltView
{
	return showInAltView;
}

- (void) processIsStarting
{
    [super processIsStarting];
	int i;
	for(i=0;i<4;i++){
		id obj = [self objectConnectedTo:historyConnectors[i]];
		[obj processIsStarting];
		[inputValue[i] release];
		inputValue[i] = [[ORTimeRate alloc] init];
		[inputValue[i] setSampleTime:1];
	}
	[lastEval release];
	lastEval = nil;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHistoryElementDataChanged object:self];
}

- (void) processIsStopping
{
    [super processIsStopping];
	int i;
	for(i=0;i<4;i++){
		id obj = [self objectConnectedTo:historyConnectors[i]];
		[obj processIsStopping];
	}
	[lastEval release];
	lastEval = nil;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHistoryElementDataChanged object:self];
}

//--------------------------------
//runs in the process logic thread
- (id) eval
{
	NSDate* now = [NSDate date];
	if(lastEval == nil || [now timeIntervalSinceDate:lastEval] >= 1){
		[lastEval release];
		lastEval = [now retain];
		int i;
		for(i=0;i<4;i++){
			id obj = [self objectConnectedTo:historyConnectors[i]];
			ORProcessResult* theResult = [obj eval];
			float valueToPlot = [theResult analogValue];
			[inputValue[i] addDataToTimeAverage:valueToPlot];
		}	
		[self performSelectorOnMainThread:@selector(postUpdate) withObject:nil waitUntilDone:NO];
	}
	return nil;
}


//--------------------------------

#pragma mark ¥¥¥Plot Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
	int set = [aPlotter tag];
	return [inputValue[set] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int set = [aPlotter tag];
	int count = [inputValue[set] count];
	int index = count-i-1;
	*yValue =  [inputValue[set] valueAtIndex:index];
	*xValue =  [inputValue[set] timeSampledAtIndex:index];
}

- (NSColor*) plotColor:(int)plotIndex
{
	NSColor* theColors[4] = {
		[NSColor redColor],
		[NSColor blueColor],
		[NSColor blackColor],
		[NSColor greenColor],
	};
	
	if(plotIndex<0 || plotIndex>=4)return theColors[0];
	else return theColors[plotIndex];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setShowInAltView:[decoder decodeBoolForKey:@"showInAltView"]];
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:showInAltView forKey:@"showInAltView"];
}

@end

@implementation ORProcessHistoryModel (private)

- (NSImage*) composeIcon
{
	if(![self useAltView])	return [self composeLowLevelIcon];
	else					return [self composeHighLevelIcon];
}

- (NSImage*) composeLowLevelIcon
{
	
	NSFont* theFont = [NSFont messageFontOfSize:9];
	NSAttributedString* iconLabel =  [[[NSAttributedString alloc] 
											initWithString:[NSString stringWithFormat:@"%lu",[self processID]]
											attributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]]autorelease];
	NSSize textSize = [iconLabel size];
	NSImage* anImage = [NSImage imageNamed:@"ProcessHistory"];
	
	NSSize theIconSize	= [anImage size];
	
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage drawAtPoint:NSZeroPoint fromRect:[anImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
	[self drawPlotRepIntoRect:NSMakeRect(18,6,theIconSize.width-29,theIconSize.height-11) maxPoints:250];
	
	[iconLabel drawInRect:NSMakeRect(theIconSize.width - textSize.width - 2,theIconSize.height-textSize.height-3,textSize.width,textSize.height)];
	
    [finalImage unlockFocus];
	return [finalImage autorelease];	
}


- (NSImage*) composeHighLevelIcon
{
	
	NSFont* theFont = [NSFont messageFontOfSize:10];
	NSAttributedString* iconLabel;
	if([[self customLabel] length]){
		iconLabel =  [[[NSAttributedString alloc] 
				 initWithString:[NSString stringWithFormat:@"%@",[self customLabel]]
				 attributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]]autorelease];
	}
	else {
		iconLabel =  [[[NSAttributedString alloc] 
					   initWithString:[NSString stringWithFormat:@"History %lu",[self processID]] 
					   attributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]]autorelease];
	}
	NSSize textSize = [iconLabel size];
	NSImage* anImage = [NSImage imageNamed:@"ProcessHistoryHL"];
	NSSize theIconSize	= [anImage size];
	
	float textStart		= 60;
	
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage drawAtPoint:NSZeroPoint fromRect:[anImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    [self drawPlotRepIntoRect:NSMakeRect(textStart,17,theIconSize.width-textStart-5,23) maxPoints:500];
	
	
	[iconLabel drawInRect:NSMakeRect(textStart, 0 , MIN(textSize.width,theIconSize.width-textStart),textSize.height)];
	
    [finalImage unlockFocus];
	return [finalImage autorelease];	
}

- (void) drawPlotRepIntoRect:(NSRect)aRect maxPoints:(int)maxNumPoints
{
	float scaleFactorY = 0;
	float scaleFactorX = 0;
	int i,plot,numPoints;
	float yValue,xValue;
	int count = [inputValue[0] count];
	if(aRect.size.width != 0 && aRect.size.height != 0){
		[NSBezierPath setDefaultLineWidth:0];
		[[NSColor colorWithCalibratedRed:.9 green:.9 blue:.9 alpha:1] set];
		[NSBezierPath fillRect:aRect];
		[[NSColor colorWithCalibratedRed:.8 green:.8 blue:.8 alpha:1] set];
		[NSBezierPath strokeRect:aRect];
		[[NSColor colorWithCalibratedRed:.8 green:.8 blue:.8 alpha:1] set];
		yValue = aRect.origin.y;
		for(i=0;i<3;i++){
			[NSBezierPath strokeLineFromPoint:NSMakePoint(aRect.origin.x, yValue) toPoint:NSMakePoint(aRect.origin.x+aRect.size.width,yValue)];
			yValue += aRect.size.height/3.;
		}
		xValue = aRect.origin.x;
		for(i=0;i<10;i++){
			[NSBezierPath strokeLineFromPoint:NSMakePoint(xValue,aRect.origin.y) toPoint:NSMakePoint(xValue,aRect.origin.y+aRect.size.height)];
			xValue += aRect.size.width/10.;
		}
		//get the scaleFactors
		numPoints = MIN(maxNumPoints,count);
		float minY = 9.9E99;
		float maxY = -9.9E99;
		for(plot=0;plot<4;plot++){
			if([[self connectorWithName:historyConnectors[plot]] isConnected]){
				for(i=0;i<numPoints;i++){
					int index = count-i-1;
					yValue =  [inputValue[plot] valueAtIndex:index];
					if(yValue<minY)minY = yValue;
					if(yValue>maxY)maxY = yValue;
				}
			}
		}
		if(maxY!=minY){
            maxY = maxY + maxY*.1;
            minY = minY - minY*.1;
            
			scaleFactorY = aRect.size.height/fabs(maxY-minY);
			scaleFactorX = aRect.size.width/(float)maxNumPoints;

			//draw the last part of the plot into the icon
			for(plot=0;plot<4;plot++){
				if([[self connectorWithName:historyConnectors[plot]] isConnected]){
					[[self plotColor:plot] set];
					NSBezierPath* path = [NSBezierPath bezierPath];
					for(i=0;i<numPoints;i++){
						int index = count-i-1;
						yValue =  [inputValue[plot] valueAtIndex:index];
						if(i==0)[path moveToPoint:NSMakePoint(aRect.origin.x + scaleFactorX*i,aRect.origin.y + scaleFactorY*(yValue-minY))];
						else	[path lineToPoint:NSMakePoint(aRect.origin.x + scaleFactorX*i,aRect.origin.y + scaleFactorY*(yValue-minY))];
					}
					[path setLineWidth:0];
					[path stroke];
				}
			}
		}
	}
}
@end