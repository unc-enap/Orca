//
//  ORBitStrip.m
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of  
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of2DHisto Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORBitStrip.h"
#import "ORPlotView.h"
#import "ORAxis.h"

@implementation ORBitStrip
- (void) dealloc
{
	[bitName release];
	[super dealloc];
}
- (void) setDataSource:(id)ds
{
	if( ![ds respondsToSelector:@selector(numberPointsInPlot:)] || 
	   ![ds respondsToSelector:@selector(plotter:index:x:y:)]){
		ds = nil;
	}
	dataSource = ds;	
}

- (void) setBitNum:(int)aBitNum
{
	bitNum = aBitNum;
}

- (int) bitNum
{
	return bitNum;
}

- (void) setBitName:(NSString*)aName
{
	[bitName autorelease];
	bitName = [aName copy];
}

- (NSString*) bitName
{
	return bitName;
}

- (BOOL) canScaleY
{
	return NO;
}

#pragma mark ***Drawing
- (void) drawData
{
	NSAssert([NSThread mainThread],@"ORBitStrip drawing from non-gui thread");
	
	int numPoints = [dataSource numberPointsInPlot:self];
    if(numPoints == 0) return;
	
	ORAxis*    mXScale = [plotView xScale];
	
    NSBezierPath* theDataPath = [NSBezierPath bezierPath];

	int i;
	double xValue;
	double yValue;  
	float height = [plotView bounds].size.height;
	float bitOffset = height - 5 - (11*bitNum);
	float maxX = [mXScale maxValue];
	for (i=0; i<numPoints;++i) {
		[dataSource plotter:self index:i x:&xValue y:&yValue];
		if(xValue > maxX) break;
		float x = [mXScale getPixAbs:xValue];
		int bitValue = yValue>.5;
		float y = bitOffset - (6 - (bitValue * 6));
		if(i==0)[theDataPath moveToPoint:NSMakePoint(x,y)];
		else	[theDataPath lineToPoint:NSMakePoint(x,y)];
	}
	
	if([self useConstantColor] || [plotView topPlot] == self)	[[self lineColor] set];
	else [[[self lineColor] highlightWithLevel:.5]set];
	
	[theDataPath setLineWidth:[self lineWidth]];
	[theDataPath stroke];
	[self drawExtras];
}

- (void) drawExtras 
{	
	float height	= [plotView bounds].size.height;
	float width		= [plotView bounds].size.width;
	float bitOffset = height - 2 - (11*bitNum);
	
	NSFont* font = [NSFont systemFontOfSize:9.0];
	NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
	
	NSString* aName = [self bitName];
	if(!aName){
		aName = [NSString stringWithFormat:@"%d",bitNum];
	}
	NSAttributedString* s	 = [[NSAttributedString alloc] initWithString:aName attributes:attrsDictionary];
	NSSize labelSize         = [s size];
	
	[s drawAtPoint:NSMakePoint(3,bitOffset-labelSize.height)];
	if(!([plotView commandKeyIsDown])){
		[s drawAtPoint:NSMakePoint(width-labelSize.width-3,bitOffset-labelSize.height)];
	}
	[s release];
	
	if([plotView commandKeyIsDown] && showCursorPosition){
		NSFont* font = [NSFont systemFontOfSize:12.0];
		NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:.8],NSBackgroundColorAttributeName,nil];
		int numPoints = [dataSource numberPointsInPlot:self];
		NSString* aName = [self bitName];
		if(!aName){
			aName = [NSString stringWithFormat:@"Bit%d",bitNum];
		}
		NSString* infoString = [NSString stringWithFormat:@"x:%.0f %@:%.0f",cursorPosition.x,aName,cursorPosition.x<numPoints?cursorPosition.y:0.0];
		s = [[NSAttributedString alloc] initWithString:infoString attributes:attrsDictionary];
		labelSize = [s size];
		[s drawAtPoint:NSMakePoint(width - labelSize.width - 10,height-labelSize.height-5)];
		[s release];
		
		double xValue;
		double yValue;
		double x=0;
		if(cursorPosition.x < numPoints){
			[dataSource plotter:self index:cursorPosition.x x:&xValue y:&yValue];
			x = [[plotView xScale] getPixAbs:xValue];
			//y = [[plotView yScale] getPixAbs:yValue];
		}
		
		[[NSColor blackColor] set];
		[NSBezierPath setDefaultLineWidth:.75];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0) toPoint:NSMakePoint(x,height)];
	}
}

@end					
