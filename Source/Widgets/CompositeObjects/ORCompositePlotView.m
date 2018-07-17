//
//  ORCompositePlotView.m
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

#import "ORCompositePlotView.h"
#import "ORAxis.h"
#import "ORTimeLine.h"
#import "ORTimeAxis.h"
#import "ORPlotView.h"
#import "ORPlot.h"
#import "ORLegend.h"
#import "ORCalibration.h"
#import "ORDataSetModel.h"
#import "ORColorBar.h"
#import "ORRamperView.h"
#import "ORPlotPublisher.h"

@implementation ORCompositePlotView

@synthesize showLegend,xAxis,yAxis,plotView,delegate,legend,titleField;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
	}
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    self.delegate   = nil;
	self.xAxis      = nil;
	self.yAxis      = nil;
	self.legend     = nil;
	self.plotView   = nil;
	self.titleField = nil;
	[super dealloc];
}

- (void) awakeFromNib
{
	[self setUpViews];
	[xAxis awakeFromNib];
	[yAxis awakeFromNib];
	[legend awakeFromNib];
	[plotView awakeFromNib];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustPositionsAndSizes) name:ORDataSetCalibrationChanged object:nil];
	[self adjustPositionsAndSizes];
}

- (BOOL) isFlipped
{
	return NO;
}

- (void) setUpViews
{
	//set up the *rough* positions of the various parts
	[self makeTitle];
	[self makeYAxis];
	[self makeXAxis];
	[self makePlotView];
	[self makeLegend];
	
	[plotView setXScale:xAxis];
	[plotView setYScale:yAxis];
	
	[legend setPlotView:plotView];
	[yAxis setViewToScale:plotView];
	[xAxis setViewToScale:plotView];
	
	[self adjustPositionsAndSizes];
}

- (void) makeTitle
{
	//do the title -- size will be fixed when we know more
	NSRect plotRect = [self bounds];
	NSTextField* aTitleField = [[NSTextField alloc] initWithFrame:NSMakeRect(0,plotRect.size.height,0,plotRect.size.width)];
	[aTitleField setEditable:NO];
	[aTitleField setSelectable:NO];
	[aTitleField setBordered:NO];
	[aTitleField setAlignment:NSTextAlignmentCenter];
	[aTitleField setBackgroundColor:[NSColor clearColor]];
	[aTitleField setAutoresizingMask:NSViewMinYMargin | NSViewMinXMargin | NSViewMaxXMargin | NSViewWidthSizable];
	[self addSubview:aTitleField];
	self.titleField = aTitleField;
	[aTitleField release];
}

- (void) makeXAxis
{
	//do the xAxis -- frame size will be fixed when we know more
	NSRect plotRect = [self bounds];
	ORAxis* anAxis = [[ORAxis alloc] initWithFrame:NSMakeRect(0,0,plotRect.size.width,50)];
	[anAxis setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
	[self addSubview:anAxis];
	self.xAxis = anAxis;
	[anAxis release];
}

- (void) makeYAxis
{
	//do the yAxis -- frame size will be fixed when we know more
	NSRect plotRect = [self bounds];
	ORAxis* anAxis = [[ORAxis alloc] initWithFrame:NSMakeRect(0,0, 50, plotRect.size.height)];
	[anAxis setAutoresizingMask:NSViewHeightSizable | NSViewMaxXMargin];
	[self addSubview:anAxis];
	self.yAxis = anAxis;
	[anAxis release];
}

- (void) makePlotView
{
	//do the plotView -- frame size will be fixed when we know more
	float x = [yAxis bounds].size.width;
	float y = [xAxis bounds].size.height;
	float width = [self bounds].size.width;
	float height = [self bounds].size.height;
	
	ORPlotView* aPlotView = [[ORPlotView alloc] initWithFrame:NSMakeRect(52,52,width-x,height-y)];
	[aPlotView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    [aPlotView setDelegate:delegate];
    [aPlotView setViewForPDF:self];
    
    [self addSubview:aPlotView];

    self.plotView = aPlotView;
    
	[aPlotView release];

}

- (void) makeLegend
{
	//do the legend -- frame size will be fixed when we know more
	ORLegend* aLegend = [[ORLegend alloc] initWithFrame:NSMakeRect(0,0,10,10)];
	[aLegend setAutoresizingMask:NSViewMinXMargin];
	[self addSubview:aLegend];
	self.legend = aLegend;
	[aLegend release];
}

- (void) adjustPositionsAndSizes
{
	[xAxis checkForCalibrationAdjustment];
	[yAxis checkForCalibrationAdjustment];

	NSRect xAxisRect = [xAxis bounds];
	NSRect yAxisRect = [yAxis bounds];
	NSRect legendRect= [legend bounds];
	
	float titleHeight;
	if([[titleField stringValue]length]) {
		titleHeight = [[titleField font] pointSize]+3; 
		[titleField setFrame:NSMakeRect(0,[self bounds].size.height-titleHeight,[self bounds].size.width,titleHeight)];
	}
	else {
		titleHeight = 0;
		[titleField setFrame:NSMakeRect(0,[self bounds].size.height,[self bounds].size.width,0)];
	}
	float widthOfYAxis	= yAxisRect.size.width;
	float heightOfXAxis = xAxisRect.size.height;
		
	//adjust position of yAxis to be on the left, against the top
	[yAxis setFrame:NSMakeRect(0,
							   heightOfXAxis,
							   widthOfYAxis,
							   [self bounds].size.height-heightOfXAxis-titleHeight) ];
	
	//adjust position of xAxis to be on the right, against the bottom
	float legendXDelta = 0;
	if(showLegend)legendXDelta = .5*[xAxis lowOffset]-legendRect.size.width;
	[xAxis setFrame:NSMakeRect(widthOfYAxis-[xAxis lowOffset]+1 , 
							   [yAxis lowOffset]-1 , 
							   [self bounds].size.width-widthOfYAxis+[xAxis lowOffset]+legendXDelta , 
							   heightOfXAxis) ];
	
	//adjust position of legend to be on the right, at the bottom of the plot
	if(showLegend){
		legendXDelta = legendRect.size.width;
		[legend setFrame:NSMakeRect([self bounds].size.width - legendXDelta,
									xAxisRect.size.height+10,
									legendRect.size.width, 
									legendRect.size.height)]; 
	}

	[plotView setFrame:NSMakeRect(widthOfYAxis+1, 
								  heightOfXAxis+[yAxis lowOffset], 
								  [xAxis highOffset]-[xAxis lowOffset], 
								  [yAxis highOffset]-[yAxis lowOffset]) ];
					
}


- (void) setShowLegend:(BOOL)state
{
	showLegend = state;
	[legend setUpLegend];
	[self adjustPositionsAndSizes];
}

- (void) setXTempLabel:(NSString*)aLabel
{
	[xAxis setTempLabel:aLabel];
	[self adjustPositionsAndSizes];
}

- (void) setYTempLabel:(NSString*)aLabel
{
	[yAxis setTempLabel:aLabel];
	[self adjustPositionsAndSizes];
}

- (void) setXLabel:(NSString*)aLabel
{
	[xAxis setLabel:aLabel];
	[self adjustPositionsAndSizes];
}

- (void) setYLabel:(NSString*)aLabel
{
	[yAxis setLabel:aLabel];
	[self adjustPositionsAndSizes];
}

- (void) setPlotTitle:(NSString*)aTitle
{
	[titleField setStringValue:aTitle];
	[self adjustPositionsAndSizes];	
}

#pragma mark •••Pass-thru Methods
- (id)  plotWithTag:(int)aTag				  { return  [plotView plotWithTag:aTag]; }
- (id)  plot:(int)aTag						  { return  [plotView plot:aTag]; }
- (int) numberOfPlots					      { return [plotView numberOfPlots]; }
- (void) enableCursorRects					  { [plotView enableCursorRects]; }
- (void) disableCursorRects					  { [plotView disableCursorRects]; }
- (NSData*) plotAsPDFData					  { return [plotView plotAsPDFData:[self bounds]]; }
- (void) setUseGradient:(BOOL)state			  { [plotView setUseGradient:state]; }
- (void) setBackgroundColor:(NSColor*)aColor  { [plotView setBackgroundColor:aColor]; }
- (void) addPlot:(id)aPlot					  { [plotView addPlot:aPlot]; }
- (ORPlot*) topPlot							  { return [plotView topPlot]; }
- (void) removeAllPlots						  { [plotView removeAllPlots];}
- (void) setComment:(NSString*)aComment		  { [plotView setComment:aComment];}
- (void) setPlot:(int)i name:(NSString*)aName 
{
	[(ORPlot*)[plotView plot:i] setName:aName];
	[legend setUpLegend];
	[self adjustPositionsAndSizes];
}
- (void) setShowGrid:(BOOL)aFlag				{ [plotView setShowGrid:aFlag];}
- (void) setBackgroundImage:(NSImage*)anImage	{ [plotView setBackgroundImage:anImage];}
- (void) setGridColor:(NSColor*)aColor			{ [plotView setGridColor:aColor];}

- (IBAction) zoomIn:(id)sender		 { [xAxis zoomIn:self]; }
- (IBAction) zoomOut:(id)sender		 { [xAxis zoomOut:self];}
- (IBAction) zoomXYIn:(id)sender	 { [xAxis zoomIn:self]; [yAxis zoomIn:self]; }
- (IBAction) zoomXYOut:(id)sender	 { [xAxis zoomOut:self];[yAxis zoomOut:self];}

- (IBAction) setLogX:(id)sender		 { [xAxis setLog:[sender intValue]]; }
- (IBAction) setLogY:(id)sender		 { [yAxis setLog:[sender intValue]]; }
- (IBAction) centerOnPeak:(id)sender { [plotView centerOnPeak:sender]; }
- (IBAction) autoScaleX:(id)sender	 { [plotView autoScaleX:sender]; }
- (IBAction) autoScaleY:(id)sender	 { [plotView autoScaleY:sender]; }
- (IBAction) resetScales:(id)sender	 { [plotView resetScales:sender]; } 
- (IBAction) autoscaleAll:(id)sender { [plotView autoscaleAll:sender]; } 

- (IBAction) refresh:(id)sender		 { [plotView refresh:sender]; } 
- (IBAction) logLin:(id)sender		 { [plotView logLin:sender]; } 
- (IBAction) autoScale:(id)sender	 { [plotView autoscaleAll:sender]; } 
- (IBAction) copy:(id)sender		 { [plotView copy:sender]; } 
- (IBAction) shiftXLeft:(id)sender	 { [xAxis shiftLeft:self]; }
- (IBAction) shiftXRight:(id)sender	 { [xAxis shiftRight:self]; }
- (IBAction) publishToPDF:(id)sender
{	
	[ORPlotPublisher publishPlot:self];
}

@end

@implementation ORCompositeMultiPlotView
- (void) makeTitle
{
	//no title here... it's built into the dialog so the user can edit it.
}
@end

@implementation ORCompositeTimeLineView
- (void) makeXAxis
{
	//do the xAxis -- frame size will be fixed when we know more
	NSRect plotRect = [self bounds];
	ORAxis* anAxis = [[ORTimeAxis alloc] initWithFrame:NSMakeRect(0,0,plotRect.size.width,50)];
	[anAxis setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
	[self addSubview:anAxis];
	self.xAxis = anAxis;
	[anAxis release];
}
@end

@implementation ORCompositeTimeSeriesView
- (void) makeXAxis
{
	//do the xAxis -- frame size will be fixed when we know more
	NSRect plotRect = [self bounds];
	ORAxis* anAxis = [[ORTimeLine alloc] initWithFrame:NSMakeRect(0,0,plotRect.size.width,50)];
	[anAxis setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
	[self addSubview:anAxis];
	self.xAxis = anAxis;
	[anAxis release];
}
@end

@implementation ORCompositeRamperView
- (void) makePlotView
{
	//do the plotView -- frame size will be fixed when we know more
	float x = [yAxis bounds].size.width;
	float y = [xAxis bounds].size.height;
	float width = [self bounds].size.width;
	float height = [self bounds].size.height;
	
	ORRamperView* aPlotView = [[ORRamperView alloc] initWithFrame:NSMakeRect(52,52,width-x,height-y)];
	[aPlotView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[self addSubview:aPlotView];
	self.plotView = aPlotView;
	[aPlotView release];
}


@end



