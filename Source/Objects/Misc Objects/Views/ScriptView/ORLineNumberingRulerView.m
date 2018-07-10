//  ORLineNumberingRulerView.m
//  ORCA
//
//  Created by Mark Howe on 1/3/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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

#import "ORLineNumberingRulerView.h"
#import "ORLineMarker.h"

#define kCornerRadius		 3.0
#define kMarkerHeight		13.0
#define kDefaultThickness	22.0
#define kRulerMargin		 5.0

NSString* ORBreakpointsAction = @"ORBreakpointsAction";

@interface ORLineNumberingRulerView (Private)
- (NSMutableArray*) lineIndices;
- (void) invalidateLineIndices;
- (void) calculateLines;
- (NSUInteger) lineNumberForCharacterIndex:(NSUInteger)index inText:(NSString*)text;
- (NSDictionary*) textAttributes;
- (NSDictionary*) markerTextAttributes;
@end

@implementation ORLineNumberingRulerView

- (id) initWithScrollView:(NSScrollView*)aScrollView
{
    if ((self = [super initWithScrollView:aScrollView orientation:NSVerticalRuler]) != nil) {
		linesToMarkers = [[NSMutableDictionary alloc] init];
		
        [self setClientView:[aScrollView documentView]];
    }
    return self;
}

- (void) awakeFromNib
{
	linesToMarkers = [[NSMutableDictionary alloc] init];
	[self setClientView:[[self scrollView] documentView]];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [lineIndices release];
	[linesToMarkers release];
    [font release];
 	[markerImage release];
	
    [super dealloc];
}

- (void) setRuleThickness:(float)thickness
{
	[super setRuleThickness:thickness];
	
	// Overridden to reset the size of the marker image forcing it to redraw with the new width.
	// If doing this in a non-subclass of NoodleLineNumberView, you can set it to post frame 
	// notifications and listen for them.
	[markerImage setSize:NSMakeSize(thickness, kMarkerHeight)];	
}

- (void) showBreakpoints:(BOOL)aState
{
	showBreakpoints = aState;
	[self setNeedsDisplay:YES];
}

- (void) drawMarkerImageIntoRep:(id)rep
{	
	NSRect rect = NSMakeRect(1.0, 2.0, [rep size].width - 2.0, [rep size].height - 3.0);
	
	NSBezierPath* path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect) + NSHeight(rect) / 2)];
	[path lineToPoint:NSMakePoint(NSMaxX(rect) - 5.0, NSMaxY(rect))];
	
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect) + kCornerRadius, NSMaxY(rect) - kCornerRadius) radius:kCornerRadius startAngle:90 endAngle:180];
	
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect) + kCornerRadius, NSMinY(rect) + kCornerRadius) radius:kCornerRadius startAngle:180 endAngle:270];
	[path lineToPoint:NSMakePoint(NSMaxX(rect) - 5.0, NSMinY(rect))];
	[path closePath];
	
	[[NSColor colorWithCalibratedRed:0.003 green:0.56 blue:0.85 alpha:1.0] set];
	[path fill];
	
	[[NSColor colorWithCalibratedRed:0 green:0.44 blue:0.8 alpha:1.0] set];
	
	[path setLineWidth:2.0];
	[path stroke];
}

- (NSImage*) markerImageWithSize:(NSSize)size
{
	if (markerImage == nil){		
		markerImage = [[NSImage alloc] initWithSize:size];
		NSCustomImageRep* rep = [[NSCustomImageRep alloc] initWithDrawSelector:@selector(drawMarkerImageIntoRep:) delegate:self];
		[rep setSize:size];
		[markerImage addRepresentation:rep];
		[rep release];
	}
	return markerImage;
}

- (void) mouseDown:(NSEvent*)theEvent
{	
	
	if(!showBreakpoints)return;
	
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSInteger line = [self lineNumberForLocation:location.y];
	if (line != NSNotFound) {
		ORLineMarker* marker = [self markerAtLine:line];
		if (marker != nil) [self removeMarker:marker];
		else {
			marker = [[ORLineMarker alloc] initWithRulerView:self
												  lineNumber:line
													   image:[self markerImageWithSize:NSMakeSize([self ruleThickness], kMarkerHeight)]
												 imageOrigin:NSMakePoint(0, kMarkerHeight / 2)];
			[self addMarker:marker];
			[marker release];
		}
		[self setNeedsDisplay:YES];
	}
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:linesToMarkers forKey:@"lineMarkers"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORBreakpointsAction object:self userInfo:userInfo];
}

- (void) loadLineMarkers:(NSDictionary*)someLineMarkers;
{
	NSDictionary* aCopy = [someLineMarkers copy]; 
	[linesToMarkers removeAllObjects];
	[super setMarkers:nil];
	
	NSEnumerator* e = [aCopy objectEnumerator];
	ORLineMarker* aMarker;
	while (aMarker = [e nextObject]) {
		unsigned aLine = [aMarker lineNumber];
		ORLineMarker* marker = [[ORLineMarker alloc] initWithRulerView:self
											  lineNumber:aLine
												   image:[self markerImageWithSize:NSMakeSize([self ruleThickness], kMarkerHeight)]
											 imageOrigin:NSMakePoint(0, kMarkerHeight / 2)];
		[self addMarker:marker];
		[marker release];
	}
	[aCopy release];
	[self setNeedsDisplay:YES];
}

- (void) setFont:(NSFont*)aFont
{
    if (font != aFont) {
		[font autorelease];		
		font = [aFont retain];
    }
}

- (NSFont*) font
{
	if (font == nil) {
		return [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]];
	}
    return font;
}

- (void) setTextColor:(NSColor*)color
{
	if (textColor != color) {
		[textColor autorelease];
		textColor  = [color retain];
	}
}

- (NSColor*) textColor
{
	if (textColor == nil) {
		return [NSColor colorWithCalibratedWhite:0.42 alpha:1.0];
	}
	return textColor;
}

- (void) setAlternateTextColor:(NSColor*)color
{
	if (alternateTextColor != color) {
		[alternateTextColor autorelease];
		alternateTextColor = [color retain];
	}
}

- (NSColor*) alternateTextColor
{
	if (alternateTextColor == nil){
		return [NSColor whiteColor];
	}
	return alternateTextColor;
}

- (void) setBackgroundColor:(NSColor*)color
{
	if (backgroundColor != color){
		[backgroundColor autorelease];
		backgroundColor = [color retain];
	}
}

- (NSColor*) backgroundColor
{
	return backgroundColor;
}

- (void) setClientView:(NSView *)aView
{	
	id oldClientView = [self clientView];
	
    if ((oldClientView != aView) && [oldClientView isKindOfClass:[NSTextView class]]){
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextStorageDidProcessEditingNotification object:[(NSTextView *)oldClientView textStorage]];
    }
    [super setClientView:aView];
    if ((aView != nil) && [aView isKindOfClass:[NSTextView class]]){
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextStorageDidProcessEditingNotification object:[(NSTextView *)aView textStorage]];
		
		[self invalidateLineIndices];
    }
}

- (NSMutableArray*) lineIndices
{
	if (lineIndices == nil) {
		[self calculateLines];
	}
	return lineIndices;
}

- (void) invalidateLineIndices
{
	[lineIndices release];
	lineIndices = nil;
}

- (void) textDidChange:(NSNotification*)notification
{
	// Invalidate the line indices. They will be recalculated and recached on demand.
	[self invalidateLineIndices];
    [self setNeedsDisplay:YES];
}

- (NSUInteger) lineNumberForLocation:(float)location
{		
	id view = [self clientView];
	NSRect visibleRect = [[[self scrollView] contentView] bounds];
	
	NSMutableArray* lines = [self lineIndices];
	
	location += NSMinY(visibleRect);
	
	if ([view isKindOfClass:[NSTextView class]]) {
		NSRange nullRange = NSMakeRange(NSNotFound, 0);
		NSLayoutManager* layoutManager = [view layoutManager];
		NSTextContainer* container = [view textContainer];
		unsigned count = [lines count];
		unsigned line;
		for (line = 0; line < count; line++){
			unsigned index = [[lines objectAtIndex:line] unsignedIntValue];
			unsigned rectCount;
			NSRectArray rects = [layoutManager rectArrayForCharacterRange:NSMakeRange(index, 0)
											 withinSelectedCharacterRange:nullRange
														  inTextContainer:container
																rectCount:&rectCount];
			unsigned i;
			for (i = 0; i < rectCount; i++) {
				if ((location >= NSMinY(rects[i])) && (location < NSMaxY(rects[i]))) {
					return line + 1;
				}
			}
		}	
	}
	return NSNotFound;
}

- (ORLineMarker*) markerAtLine:(NSUInteger)line
{
	return [linesToMarkers objectForKey:[NSNumber numberWithUnsignedInt:line - 1]];
}


- (void) calculateLines
{
    id view = [self clientView];
    
    if ([view isKindOfClass:[NSTextView class]]) {
        
        NSString* text = [view string];
        unsigned stringLength = [text length];
        [lineIndices release];
        lineIndices = [[NSMutableArray alloc] init];
        
        unsigned index = 0;
        unsigned numberOfLines = 0;
        do {
            [lineIndices addObject:[NSNumber numberWithUnsignedInt:index]];
            index = NSMaxRange([text lineRangeForRange:NSMakeRange(index, 0)]);
            numberOfLines++;
        } while (index < stringLength);
		
        // Check if text ends with a new line.
		unsigned lineEnd;
		unsigned contentEnd;
        [text getLineStart:NULL end:&lineEnd contentsEnd:&contentEnd forRange:NSMakeRange([[lineIndices lastObject] unsignedIntValue], 0)];
        if (contentEnd < lineEnd) {
            [lineIndices addObject:[NSNumber numberWithUnsignedInt:index]];
        }
		
        float oldThickness = [self ruleThickness];
        float newThickness = [self requiredThickness];
        if (fabs(oldThickness - newThickness) > 1) {			
			// Not a good idea to resize the view during calculations (which can happen during
			// display). Do a delayed perform (using NSInvocation since arg is a float).
			NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(setRuleThickness:)]];
			[invocation setSelector:@selector(setRuleThickness:)];
			[invocation setTarget:self];
			[invocation setArgument:&newThickness atIndex:2];
			
			[invocation performSelector:@selector(invoke) withObject:nil afterDelay:0.0];
        }
	}
}

- (NSUInteger) lineNumberForCharacterIndex:(NSUInteger)index inText:(NSString*)text
{
	NSMutableArray* lines = [self lineIndices];
	
    // Binary search
    unsigned left = 0;
    unsigned right = [lines count];
	
    while ((right - left) > 1) {
		unsigned mid = (right + left) / 2;
        unsigned lineStart = [[lines objectAtIndex:mid] unsignedIntValue];
        if (index < lineStart) right = mid;
        else if (index > lineStart) left = mid;
        else return mid;
    }
    return left;
}

- (NSDictionary*) textAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [self font], NSFontAttributeName, 
            [self textColor], NSForegroundColorAttributeName,
            nil];
}

- (NSDictionary*) markerTextAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
            [self font], NSFontAttributeName, 
            [self alternateTextColor], NSForegroundColorAttributeName,
			nil];
}

- (float) requiredThickness
{    
    long lineCount = [[self lineIndices] count];
    long digits    = (NSUInteger)log10(lineCount) + 1;
	NSMutableString* sampleString = [NSMutableString string];
	long i;
    for (i = 0; i < digits; i++) {
        // Use "8" since it is one of the fatter numbers. Anything but "1"
        // will probably be ok here. I could be pedantic and actually find the fattest
		// number for the current font but nah.
        [sampleString appendString:@"8"];
    }
    NSSize stringSize = [sampleString sizeWithAttributes:[self textAttributes]];
	// Round up the value. There is a bug on 10.4 where the display gets all wonky when scrolling if you don't
	// return an integral value here.
    return ceilf(MAX(kDefaultThickness, stringSize.width + kRulerMargin * 2));
}

- (void) drawHashMarksAndLabelsInRect:(NSRect)aRect
{
	NSRect bounds = [self bounds];
	
	if (backgroundColor != nil) {
		[backgroundColor set];
		NSRectFill(bounds);
		
		[[NSColor colorWithCalibratedWhite:0.58 alpha:1.0] set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(bounds) - 0/5, NSMinY(bounds)) toPoint:NSMakePoint(NSMaxX(bounds) - 0.5, NSMaxY(bounds))];
	}
	
    id view = [self clientView];
	
    if ([view isKindOfClass:[NSTextView class]]) {
		
        NSLayoutManager* layoutManager = [view layoutManager];
        NSTextContainer* container = [view textContainer];
        NSString* text = [view string];
        NSRange nullRange = NSMakeRange(NSNotFound, 0);
		
		float yinset = [view textContainerInset].height;        
        NSRect visibleRect = [[[self scrollView] contentView] bounds];
		
        NSDictionary* textAttributes = [self textAttributes];
		
		NSMutableArray* lines = [self lineIndices];
		
        // Find the characters that are currently visible
        NSRange glyphRange = [layoutManager glyphRangeForBoundingRect:visibleRect inTextContainer:container];
        NSRange range = [layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
        
        // Fudge the range a tad in case there is an extra new line at end.
        // It doesn't show up in the glyphs so would not be accounted for.
        range.length++;
        
        unsigned count = [lines count];
        unsigned index = 0;
        unsigned line;
        for (line = [self lineNumberForCharacterIndex:range.location inText:text]; line < count; line++) {
            index = [[lines objectAtIndex:line] unsignedIntValue];
            
            if (NSLocationInRange(index, range)) {        
				unsigned rectCount;
				NSRectArray rects = [layoutManager rectArrayForCharacterRange:NSMakeRange(index, 0)
												 withinSelectedCharacterRange:nullRange
															  inTextContainer:container
																	rectCount:&rectCount];
				
                if (rectCount > 0){
                    // Note that the ruler view is only as tall as the visible
                    // portion. Need to compensate for the clipview's coordinates.
                    float ypos = yinset + NSMinY(rects[0]) - NSMinY(visibleRect);
					
					ORLineMarker* marker = [linesToMarkers objectForKey:[NSNumber numberWithUnsignedInt:line]];
					if(showBreakpoints){
						
						if (marker != nil){
							markerImage = [marker image];
							NSSize markerSize = [markerImage size];
							NSRect markerRect = NSMakeRect(0.0, 0.0, markerSize.width, markerSize.height);
							
							// Marker is flush right and centered vertically within the line.
							markerRect.origin.x = NSWidth(bounds) - [markerImage size].width - 1.0;
							markerRect.origin.y = ypos + NSHeight(rects[0]) / 2.0 - [marker imageOrigin].y;
							
							[markerImage drawInRect:markerRect fromRect:NSMakeRect(0, 0, markerSize.width, markerSize.height) operation:NSCompositeSourceOver fraction:1.0];
						}
                    }
                    // Line numbers are internally stored starting at 0
                    NSString* labelText = [NSString stringWithFormat:@"%d", line + 1];
                    
                    NSSize stringSize = [labelText sizeWithAttributes:textAttributes];
					
					NSDictionary* currentTextAttributes;
					if (marker == nil || !showBreakpoints)	currentTextAttributes = textAttributes;
					else				currentTextAttributes = [self markerTextAttributes];
					
                    // Draw string flush right, centered vertically within the line
                    [labelText drawInRect:
					 NSMakeRect(NSWidth(bounds) - stringSize.width - kRulerMargin,
								ypos + (NSHeight(rects[0]) - stringSize.height) / 2.0,
								NSWidth(bounds) - kRulerMargin * 2.0, NSHeight(rects[0]))
                           withAttributes:currentTextAttributes];
                }
            }
			if (index > NSMaxRange(range)) break;
        }
    }
}

- (void) setMarkers:(NSArray*)markers
{
	[linesToMarkers removeAllObjects];
	[super setMarkers:nil];
	
	NSEnumerator* e = [markers objectEnumerator];
	NSRulerMarker* marker;
	while ((marker = [e nextObject]) != nil) {
		[self addMarker:marker];
	}
}

- (void) addMarker:(NSRulerMarker*)aMarker
{
	if ([aMarker isKindOfClass:[ORLineMarker class]]) {
		[linesToMarkers setObject:aMarker
						   forKey:[NSNumber numberWithUnsignedInt:[(ORLineMarker *)aMarker lineNumber] - 1]];
	}
	else [super addMarker:aMarker];
}

- (void) removeMarker:(NSRulerMarker*)aMarker
{
	if ([aMarker isKindOfClass:[ORLineMarker class]]) {
		[linesToMarkers removeObjectForKey:[NSNumber numberWithUnsignedInt:[(ORLineMarker *)aMarker lineNumber] - 1]];
	}
	else [super removeMarker:aMarker];
}

#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder*)decoder
{
	if ((self = [super initWithCoder:decoder]) != nil) {
		if ([decoder allowsKeyedCoding]) {
			font = [[decoder decodeObjectForKey:@"font"] retain];
			textColor = [[decoder decodeObjectForKey:@"textColor"] retain];
			alternateTextColor = [[decoder decodeObjectForKey:@"alternateTextColor"] retain];
			backgroundColor = [[decoder decodeObjectForKey:@"backgroundColor"] retain];
		}
		else {
			font = [[decoder decodeObject] retain];
			textColor = [[decoder decodeObject] retain];
			alternateTextColor = [[decoder decodeObject] retain];
			backgroundColor = [[decoder decodeObject] retain];
		}
		linesToMarkers = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
	if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject:font forKey:@"font"];
		[encoder encodeObject:textColor forKey:@"textColor"];
		[encoder encodeObject:alternateTextColor forKey:@"alternateTextColor"];
		[encoder encodeObject:backgroundColor forKey:@"backgroundColor"];
	}
	else {
		[encoder encodeObject:font];
		[encoder encodeObject:textColor];
		[encoder encodeObject:alternateTextColor];
		[encoder encodeObject:backgroundColor];
	}
}

@end
