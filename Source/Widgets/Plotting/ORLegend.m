//
//  ORLegend.m
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of  
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORLegend.h"
#import "ORPlotView.h"
#import "ORPlot.h"

@implementation ORLegend

@synthesize plotView,legend;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) dealloc
{
	[legend release];
	[super dealloc];
}

- (void) awakeFromNib
{
	//nothing to do
}

- (void) setPlotView:(ORPlotView*)aPlotView
{
	plotView = aPlotView; //don't retain
}

- (void) setUpLegend
{
	NSMutableAttributedString* s = [[NSMutableAttributedString alloc] init];
	int numPlots = [plotView numberOfPlots];
	int i;
	NSFont* theFont = [NSFont fontWithName:@"Helvetica" size:11];
	for(i=0;i<numPlots;i++){
		ORPlot* aPlot = [plotView plot:i];
		NSColor* thePlotColor = [aPlot lineColor];
		NSString* thePlotName = [aPlot name];
		if(!thePlotColor)thePlotColor = [NSColor blackColor];
		if([thePlotName length]){
			thePlotName = [thePlotName stringByAppendingString:@"\r"];
			[s replaceCharactersInRange:NSMakeRange([s length], 0) withString:thePlotName];
			NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:thePlotColor,NSForegroundColorAttributeName,theFont,NSFontAttributeName,nil];
			[s setAttributes:attrs range:NSMakeRange([s length]-[thePlotName length],[thePlotName length])];
		}
	}
	
	if([s length])[s replaceCharactersInRange:NSMakeRange([s length]-1, 1) withString:@""];

	[self setLegend:s];
	[s release];
	NSSize theSize = [legend size];
	[self setFrame:NSMakeRect(0,0,theSize.width+5,theSize.height+10)];
}

- (void) drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	[legend drawInRect:[self bounds]];
}

@end
