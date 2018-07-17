//
//  ORPlotView.m
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
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORPlotView.h"
#import "ORPlot.h"
#import "ORAxis.h"
#import "ORPlotAttributeStrings.h"

@implementation ORPlotView

#pragma mark ***Initialization
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setDefaults];
    }
    return self;
}

- (void) dealloc
{
    delegate = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [plotArray release];
    [attributes release];
    [gradient release];
	[backgroundImage release];
	[comment release];
    [super dealloc];
}

- (void) awakeFromNib
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver: self
                     selector: @selector(redrawEvent:)
                         name: ORPlotViewRedrawEvent
                       object: nil];	
	[self becomeFirstResponder];
	[[self window] disableCursorRects];
}

- (void) redrawEvent:(NSNotification*)aNote
{
	if([[self topPlot] redrawEvent:aNote]){
		[self setNeedsDisplay:YES];
	}
}

- (id) dataSource //temp until conversion complete
{
	return delegate;
}

- (BOOL) isOpaque 
{
    return ( [[self backgroundColor] alphaComponent] == 1.0 );
}

#pragma mark ***Accessors
- (void) setViewForPDF:(NSView*)aView
{
	viewForPDF = aView; //don't retain
}

- (void) setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

- (id) delegate 
{
    return delegate;
}

- (BOOL) shiftKeyIsDown
{
	return shiftKeyIsDown;
}

- (BOOL) commandKeyIsDown
{
	return commandKeyIsDown;
}

- (void) setComment:(NSString*)aComment
{
	[comment autorelease];
	comment = [aComment copy];
}

#pragma mark ***Parts
- (void) setZScale:(id)anAxis
{
	zScale = anAxis; //don't retain
}
- (void) setXScale:(id)anAxis
{
	xScale = anAxis; //don't retain
}

- (void) setYScale:(id)anAxis
{
	yScale = anAxis; //don't retain
}

- (id) xScale
{
	return xScale; 
}

- (id) yScale
{ 
	return yScale; 
}

- (id) zScale
{ 
	return zScale; 
}

- (id) colorScale
{
	return colorScale;
}
- (void) setColorScale:(id)aColorScale
{
	colorScale = aColorScale; //don't retain
}

- (NSTextField*) titleField
{
	return titleField;
}

#pragma mark ***Plots
- (ORPlot*) topPlot
{
	if([plotArray count]) return [plotArray objectAtIndex:0];
	else return nil;
}

- (void) addPlot:(id)aPlot
{
    NSAssert(aPlot != nil, @"Component was nil in addComponent:" );
	if(!plotArray) plotArray = [[NSMutableArray array]retain];
	[aPlot setPlotView:self];
    [plotArray addObject:aPlot];
    [self setNeedsDisplay:YES];
}

- (void) removePlot:(id)aPlot
{
    NSAssert(aPlot != nil, @"Component was nil in addComponent:" );
    [plotArray removeObject:aPlot];
    [self setNeedsDisplay:YES];
}

- (void) removeAllPlots 
{
    [plotArray removeAllObjects];
    [self setNeedsDisplay:YES];
}

- (int) numberOfPlots
{
	return (int)[plotArray count];
}

- (id)  plot:(int)i
{
	if(i<[self numberOfPlots]){
		return [plotArray objectAtIndex:i];
	}
	else return nil;
}

- (id)  plotWithTag:(int)aTag
{
	for(id aPlot in plotArray){
		if([aPlot tag] == aTag) return aPlot;
	}
    if([plotArray count]) return [plotArray objectAtIndex:0];
    else return nil;
}

#pragma mark ***Attributes
- (void) setDefaults
{
    if(!attributes){
        [self setAttributes:[NSMutableDictionary dictionary]];
        [self setBackgroundColor:[NSColor whiteColor]];
        [self setUseGradient:YES];
        [self setShowGrid:YES];
        [self setGridColor:[NSColor grayColor]];
    }
    [self setNeedsDisplay:YES];
}

- (NSMutableDictionary *)attributes 
{
    return attributes; 
}

- (void)setAttributes:(NSMutableDictionary *)anAttributes 
{
    [anAttributes retain];
    [attributes release];
    attributes = anAttributes;
}

- (BOOL) useGradient
{
	return [[attributes objectForKey:ORPlotUseGradient] boolValue];
}

- (void) setUseGradient:(BOOL)aFlag
{
    [attributes setObject:[NSNumber numberWithBool:aFlag] forKey:ORPlotUseGradient];	
	[self setNeedsDisplay:YES];
}

- (BOOL) showGrid
{
	return [[attributes objectForKey:ORPlotShowGrid] boolValue];
}

- (void) setShowGrid:(BOOL)aFlag
{
    [attributes setObject:[NSNumber numberWithBool:aFlag] forKey:ORPlotShowGrid];	
	[self setNeedsDisplay:YES];
}

- (void) setBackgroundColor:(NSColor *)aColor
{
    [attributes setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:ORPlotBackgroundColor];
	[gradient release];
	gradient = nil;
    [self setNeedsDisplay:YES];
}

- (NSColor*) backgroundColor
{
	NSData* d = [attributes objectForKey:ORPlotBackgroundColor];
	if(!d)return [NSColor whiteColor];
    else return [NSUnarchiver unarchiveObjectWithData:d];
}

- (void) setGridColor:(NSColor *)aColor
{
    [attributes setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:ORPlotGridColor];
    [self setNeedsDisplay:YES];
}

- (NSColor*) gridColor
{
	NSData* d = [attributes objectForKey:ORPlotGridColor];
	if(!d) return [NSColor grayColor];
    else return [NSUnarchiver unarchiveObjectWithData:d];
}

- (void) setBackgroundImage:(NSImage*)anImage
{
	[anImage retain];
	[backgroundImage release];
	backgroundImage = anImage;
}

- (NSDictionary*) textAttributes
{
	NSFont* font = [NSFont systemFontOfSize:12.0];
//	float red,green,blue,alpha;
//	NSColor* color = [[self backgroundColor] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
//	[color getRed:&red green:&green blue:&blue alpha:&alpha];
//	NSColor* textBackgroundColor = [NSColor colorWithCalibratedRed:red
//															 green:green
//															  blue:blue
//															 alpha:.5];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,/*textBackgroundColor,NSBackgroundColorAttributeName,*/nil];
}

#pragma mark ***Drawing
- (void) drawRect:(NSRect)rect 
{	
	NSAssert([NSThread mainThread],@"ORPlotView drawing from non-gui thread");
	// Draw components in order
	[self drawBackground];
	if(backgroundImage){
        [backgroundImage drawAtPoint:NSZeroPoint fromRect:[backgroundImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
	}
	if([self showGrid]){
		[NSBezierPath setDefaultLineWidth:.2];
		[[self xScale] drawGridInFrame:[self bounds] usingColor:[self gridColor]];
		[[self yScale] drawGridInFrame:[self bounds] usingColor:[self gridColor]];
	}

	
	for ( id aPlot in plotArray) {
		[aPlot drawData];		
    }
	[[self xScale] drawMarkInFrame:[self bounds] usingColor:[NSColor blackColor]];
	[[self yScale] drawMarkInFrame:[self bounds] usingColor:[NSColor blackColor]];
		
    if ([[self delegate] respondsToSelector:@selector(plotViewDidDraw:)] ) {
        [[self delegate] plotViewDidDraw:self];
	}
	
	[[self topPlot] drawExtras];
	[self drawComment];
	if(dragInProgress){
		[NSBezierPath setDefaultLineWidth:.5];
		[[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.05] set];
		[NSBezierPath fillRect:NSMakeRect(MIN(startDragXValue,currentDragXValue),MIN(startDragYValue,currentDragYValue),fabs(currentDragXValue-startDragXValue),fabs(currentDragYValue-startDragYValue))];
		[[NSColor redColor] set];
		[NSBezierPath strokeRect:NSMakeRect(MIN(startDragXValue,currentDragXValue),MIN(startDragYValue,currentDragYValue),fabs(currentDragXValue-startDragXValue),fabs(currentDragYValue-startDragYValue))];
	}
}

- (void) drawComment
{
	if([comment length]){
		float height = [self bounds].size.height;
		float width  = [self bounds].size.width;
		NSFont* font = [NSFont systemFontOfSize:12.0];
		NSArray* lines = [comment componentsSeparatedByString:@"\\n"];
		int longest = 0;
		NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:.8],NSBackgroundColorAttributeName,nil];
		for(id aLine in lines){
			NSAttributedString* s = [[NSAttributedString alloc] initWithString:aLine attributes:attrsDictionary];
			NSSize labelSize = [s size];
			if(labelSize.width > longest)longest = labelSize.width;
			[s release];
		}
		float starty = height;
		for(id aLine in lines){
			NSAttributedString* s = [[NSAttributedString alloc] initWithString:aLine attributes:attrsDictionary];
			NSSize labelSize = [s size];
			[s drawAtPoint:NSMakePoint(width - longest - 10,starty-labelSize.height-5)];
			starty -= labelSize.height;
			[s release];
		}
	}
}

- (void) drawBackground
{
	NSRect bounds = [self bounds];
	
	if([self useGradient]){
		if(!gradient){
			CGFloat red,green,blue,alpha;
			NSColor* color = [[self backgroundColor] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
			[color getRed:&red green:&green blue:&blue alpha:&alpha];
			
			red *= .75;
			green *= .75;
			blue *= .75;
			
			NSColor* endingColor = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
			
			[gradient release];
			gradient = [[NSGradient alloc ] initWithStartingColor:color endingColor:endingColor];
		}
		[gradient drawInRect:bounds angle:270.];
	}
	else {
		[[self backgroundColor] set];
		[NSBezierPath fillRect:bounds];
	}
	//[[NSColor darkGrayColor] set];
	//[NSBezierPath strokeRect:bounds];
}

- (NSData*) plotAsPDFData:(NSRect)aRect
{
	return [viewForPDF dataWithPDFInsideRect: aRect];
}


#pragma mark ***Component Switching
- (void) orderChanged
{
	if ( [self delegate] && [[self delegate] respondsToSelector:@selector(plotOrderDidChange:)] ) {
        [[self delegate] plotOrderDidChange:self];
	}
	[self setNeedsDisplay:YES];
		
}

- (void) nextComponent
{
	if([[self topPlot] nextComponent]){
		if([plotArray count]>1) {
			id firstPlot = [[plotArray objectAtIndex:0] retain];
			[plotArray insertObject:firstPlot atIndex:[plotArray count]];
			[plotArray removeObjectAtIndex:0];
			[firstPlot release];
		}
	}
}

- (void) lastComponent
{
	if([[self topPlot] lastComponent]){
		if([plotArray count]>1) {
			ORPlot* lastPlot = [[plotArray lastObject] retain];
			[plotArray insertObject:lastPlot atIndex:0];
			[plotArray removeLastObject];
			[lastPlot release];
		}
	}
}

#pragma mark ***Event Handling
- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (void) keyDown:(NSEvent*)theEvent
{
	unsigned short keyCode = [theEvent keyCode];
	if(keyCode == 0)		{[self autoScaleX:nil];[self autoScaleY:nil];}		//'a'
	else if(keyCode == 7)	[self autoScaleX:nil];		//'x'
	else if(keyCode == 16)	[self autoScaleY:nil];		//'y'
	else if(keyCode == 6)	[self autoScaleZ:nil];		//'z'
	else if(keyCode == 15)	[self resetScales:nil];		//'r'
	else if(keyCode == 8)	[self centerOnPeak:nil];	//'c'
	else if(keyCode == 48){
		if([theEvent modifierFlags] & NSEventModifierFlagShift)	[self lastComponent];
		else											[self nextComponent];
		[self orderChanged];
	}
	else [[self topPlot] keyDown:theEvent];

	[[self window] resetCursorRects];
}

- (BOOL) plotterShouldShowRoi:(id)aPlot
{
	id aDataSource = [aPlot dataSource];
	if([aDataSource respondsToSelector:@selector(plotterShouldShowRoi:)]){
		return [aDataSource plotterShouldShowRoi:aPlot];
	}
	else return NO;
	
}

-(void)	mouseDown:(NSEvent*)theEvent
{
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if([self mouse:p inRect:[self bounds]]){
		if([self plotterShouldShowRoi:[self topPlot]]){
			[[self topPlot] mouseDown:theEvent];		
		}
		else if(controlKeyIsDown){
			startDragXValue = currentDragXValue = p.x;
			startDragYValue = currentDragYValue = p.y;
			dragInProgress  = YES;
		}
	}	
	[self setNeedsDisplay:YES];
}

- (void) mouseDragged:(NSEvent*)theEvent
{
	[[self window] disableCursorRects];
	if([self plotterShouldShowRoi:[self topPlot]]){
		[[self topPlot] mouseDragged:theEvent];
	}
	else if(dragInProgress){
		NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		currentDragXValue = p.x;
		currentDragYValue = p.y;
		if(currentDragXValue>[self bounds].size.width)currentDragXValue =[self bounds].size.width;
		if(currentDragXValue<0)currentDragXValue = 0;
		if(currentDragYValue>[self bounds].size.height)currentDragYValue =[self bounds].size.height;
		if(currentDragYValue<0)currentDragYValue = 0;
		
	}
	
	[self setNeedsDisplay:YES];
}

- (void) mouseUp:(NSEvent*)theEvent
{
	if([self plotterShouldShowRoi:[self topPlot]]){
		[[self topPlot] mouseUp:theEvent];
	}
	else {
		if(controlKeyIsDown){
			if(fabs(currentDragXValue-startDragXValue)>10 && fabs(currentDragYValue-startDragYValue)>10){
				float newXMin = [xScale getValAbs:MIN(currentDragXValue,startDragXValue)];
				float newXMax = [xScale getValAbs:MAX(currentDragXValue,startDragXValue)];
				float newYMin = [yScale getValAbs:MIN(currentDragYValue,startDragYValue)];
				float newYMax = [yScale getValAbs:MAX(currentDragYValue,startDragYValue)];
				NSUndoManager* undoManager = [(ORAppDelegate*)[NSApp delegate] undoManager];
				[undoManager beginUndoGrouping];
				[xScale	setRngLow:newXMin withHigh:newXMax];
				[yScale	setRngLow:newYMin withHigh:newYMax];
				[xScale rangingDonePostChange];
				[yScale rangingDonePostChange];
				 
				[undoManager endUndoGrouping];
			}
		}
	}
	dragInProgress = NO;
	currentDragXValue=currentDragYValue=startDragXValue=startDragYValue=0;
	[[self window] resetCursorRects];
	[self setNeedsDisplay:YES];	
}

- (void) flagsChanged:(NSEvent *)theEvent
{
	[[self topPlot] flagsChanged:theEvent];
    shiftKeyIsDown = ([theEvent modifierFlags] & NSEventModifierFlagShift)!=0;
    commandKeyIsDown = ([theEvent modifierFlags] & NSEventModifierFlagCommand)!=0;
    optionKeyIsDown = ([theEvent modifierFlags] & NSEventModifierFlagOption)!=0;
    controlKeyIsDown = ([theEvent modifierFlags] & NSEventModifierFlagControl)!=0;
	
    [[self window] resetCursorRects];
	
	if(dragInProgress && !controlKeyIsDown){
		dragInProgress = NO;
	}
	else if(currentDragXValue>0 && currentDragYValue>0 && startDragXValue>0 && startDragYValue>0){
		dragInProgress = YES;
	}
	
	[self setNeedsDisplay:YES];
}

- (void) resetCursorRects
{
	[[self topPlot] resetCursorRects];
}

- (void) enableCursorRects
{
    [[self window] enableCursorRects];
}

- (void) disableCursorRects
{
    [[self window] disableCursorRects];
}

#pragma mark ***Actions
- (IBAction)copy:(id)sender
{	
	//declare our custom type.
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	[pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:self];
	NSMutableString* string = [NSMutableString string];
	
	int maxPoints = 0;
	BOOL allPlotsValid = YES;
	for(id aPlot in plotArray){
		if([aPlot respondsToSelector:@selector(numberPoints)]){
			maxPoints = (int)MAX(maxPoints,[aPlot numberPoints]);
		}
		if(![aPlot respondsToSelector:@selector(valueAsStringAtPoint:)]){
			allPlotsValid = NO;
			break;
		}
	}
	if(allPlotsValid){
		//make a string with the data
		int i;
		for(i=0;i<maxPoints;i++){
			[string appendFormat:@"%d ",i];
			for(id aPlot in plotArray){
				NSString* theValueAsString = [aPlot valueAsStringAtPoint:i];
				[string appendFormat:@"\t%@",theValueAsString];
			}
			[string appendFormat:@"\n"];
		}
		
		if([string length]){
			[pboard setData:[string dataUsingEncoding:NSASCIIStringEncoding] forType:NSStringPboardType]; 
		}
	}	
	else {
		NSBeep();
		NSLog(@"Sorry.. can't copy data from that plot\n");
	}
}

- (IBAction) writeToFile:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save Plot CSV Data As"];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
    [savePanel setNameFieldLabel:@"File Name:"];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [self savePlotDataAs:[[savePanel URL]path]];
        }
    }];
}

- (void) savePlotDataAs:(NSString*)aPath
{
	NSMutableString* string = [NSMutableString string];
  	int maxPoints = 0;
	BOOL allPlotsValid = YES;
	for(id aPlot in plotArray){
		if([aPlot respondsToSelector:@selector(numberPoints)]){
			maxPoints = (int)MAX(maxPoints,[aPlot numberPoints]);
		}
		if(![aPlot respondsToSelector:@selector(valueAsStringAtPoint:)]){
			allPlotsValid = NO;
			break;
		}
	}
	if(allPlotsValid){
		//make a string with the data
		int i;
		for(i=0;i<maxPoints;i++){
			[string appendFormat:@"%d",i];
			for(id aPlot in plotArray){
				NSString* theValueAsString = [aPlot valueAsStringAtPoint:i];
				[string appendFormat:@",%@",theValueAsString];
			}
			[string appendFormat:@"\n"];
		}
		
		if([string length]){
            [string writeToFile:aPath atomically:NO encoding:NSASCIIStringEncoding error:nil];
		}
	}
	else {
		NSBeep();
		NSLog(@"Sorry.. can't write data from that plot\n");
	}
}

- (IBAction) refresh:(id)sender		 { [self setNeedsDisplay:YES]; }
- (IBAction) logLin:(id)sender		 { [[self topPlot] logLin];  }
- (IBAction) autoScale:(id)sender	 { [self autoscaleAll:sender];}

- (IBAction) resetScales:(id)sender	 
{ 
	[xScale setFullRng];
	[yScale setDefaultRng];
	[zScale setFullRng];
}

- (IBAction) autoscaleAll:(id)sender	 
{ 
	[self autoScaleX:self];
	[self autoScaleY:self];
	[self autoScaleZ:self];
}

- (IBAction) centerOnPeak:(id)sender 
{ 
	double xMin= [xScale minValue];
	double xMax= [xScale maxValue];
    double oldCenter = xMin+(xMax-xMin)/2;

    double dx = oldCenter - [[self topPlot] maxValueChannelinXRangeFrom:xMin to:xMax];
    double new_lowX  = xMin - dx;
    double new_highX = xMax - dx;
    
    [xScale setRngLow:new_lowX withHigh:new_highX];
    [xScale setNeedsDisplay:YES];	
}

- (IBAction) autoScaleX:(id)sender
{ 
	double minX = 0;
	double maxX = 0;
	[[self topPlot] getxMin:&minX xMax:&maxX];
	double pad = 0.2*fabs(maxX-minX);
	if(minX == 0) [xScale setRngLow:0 withHigh:maxX+pad];
	else		  [xScale setRngLow:minX-pad withHigh:maxX+pad];
	[xScale setNeedsDisplay:YES];	
}

- (IBAction) autoScaleY:(id)sender
{ 
	if([[self topPlot] canScaleY]){
		double minY = 0;
		double maxY = 0;
		[[self topPlot] getyMin:&minY yMax:&maxY];
		[yScale setRngLimitsLow:-3E9 withHigh:3E9 withMinRng:[yScale minimumRange]];
		double pad = 0.2*fabs(maxY-minY);
		//double pad = MAX((0.2*maxY),(0.2*minY));
		if(minY == 0) [yScale setRngLow:0 withHigh:maxY+pad];
		else		  [yScale setRngLow:minY-pad withHigh:maxY+pad];
		[yScale setNeedsDisplay:YES];	
	}
}

- (IBAction) autoScaleZ:(id)sender
{ 
	if([[self topPlot] respondsToSelector:@selector(getzMax)]){
		double maxZ = [[self topPlot] getzMax];
		[zScale setRngLow:0.0 withHigh:maxZ];
		[zScale setNeedsDisplay:YES];
	}
}

- (IBAction) zoomIn:(id)sender		 { [xScale zoomIn:self]; }
- (IBAction) zoomOut:(id)sender		 { [xScale zoomOut:self];}
- (IBAction) zoomXYIn:(id)sender	 { [xScale zoomIn:self]; [yScale zoomIn:self]; }
- (IBAction) zoomXYOut:(id)sender	 { [xScale zoomOut:self];[yScale zoomOut:self];}

@end
