//
//  ScriptStepView.m
//  CocoaScript
//
//  Created by Matt Gallagher on 2010/11/01.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "OROpSeqStepView.h"

@implementation OROpSeqStepView

@synthesize state;
@synthesize selected;

- (void)setSelected:(BOOL)flag
{
	selected = flag;
	[self setNeedsDisplay:YES];
}

- (void)setState:(enumScriptStepState)newState
{
	if (newState == kSeqStepActive && state != kSeqStepActive){
		[progressIndicator setHidden:NO];
		[progressIndicator startAnimation:self];
	}
	else if (state == kSeqStepActive && newState != kSeqStepActive){
		[progressIndicator setHidden:YES];
		[progressIndicator stopAnimation:nil];
	}
	
	if (newState == kSeqStepSuccess){
		[imageView setImage:[NSImage imageNamed:@"checkMark"]];
		[imageView setHidden:NO];
		[errorLabel setHidden:NO];
	}
	else if (newState == kSeqStepWarning){
		[imageView setImage:[NSImage imageNamed:@"warning"]];
		[imageView setHidden:NO];
		[errorLabel setHidden:NO];
	}
	else if (newState == kSeqStepFailed){
		[imageView setImage:[NSImage imageNamed:@"exMark"]];
		[imageView setHidden:NO];
		[errorLabel setHidden:NO];
	}
    else if(newState == kSeqStepCancelled){
		[imageView setImage:[NSImage imageNamed:@"dashMark"]];
		[imageView setHidden:NO];
		[errorLabel setHidden:YES];
    }
	else { // cancelled and pending
		[imageView setHidden:YES];
		[errorLabel setHidden:YES];
	}

	state = newState;

	[self setNeedsDisplay:YES];
}

- (void)setErrorsString:(NSString *)string
{
    if(string==nil)string = @"";
	[errorLabel setStringValue:string];
}

- (NSArray *)currentGradientColors
{
	if (state == kSeqStepActive){
        //orange
		return [NSArray arrayWithObjects:
			[NSColor colorWithDeviceRed:1.0 green:0.70 blue:0.0 alpha:1.0],
			[NSColor colorWithDeviceRed:1.0 green:0.85 blue:0.0 alpha:1.0],
		nil];
	}
	//gray
	return [NSArray arrayWithObjects:
		[NSColor colorWithDeviceWhite:0.80 alpha:1.0],
		[NSColor colorWithDeviceWhite:0.98 alpha:1.0],
	nil];
}

- (void)drawRect:(NSRect)rect
{
	NSBezierPath *frame = [NSBezierPath
		bezierPathWithRoundedRect:NSOffsetRect(NSInsetRect([self bounds], 2.5, 2.5), -1, 1)
		xRadius:4
		yRadius:4];

	NSArray *gradientColors = [self currentGradientColors];
	
	if (selected && state != kSeqStepActive){
		gradientColors = [NSArray arrayWithObjects:
			[[gradientColors objectAtIndex:0] blendedColorWithFraction:0.4 ofColor:[NSColor selectedControlColor]],
			[[gradientColors objectAtIndex:1] blendedColorWithFraction:0.4 ofColor:[NSColor selectedControlColor]],
		nil];
	}

	[[NSGraphicsContext currentContext] saveGraphicsState];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:0 alpha:0.35]];
	[shadow setShadowOffset:NSMakeSize(1.5, selected ? 0.5 : -1.5)];
	[shadow setShadowBlurRadius:2];
	[shadow set];
	[frame fill];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[frame addClip];
	NSGradient *gradient =
		[[[NSGradient alloc]
			initWithColors:gradientColors]
		autorelease];
	[gradient drawInRect:[self bounds] angle:90];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	[frame setLineWidth:selected ? 1.25 : 1.0];
	[(selected ? [NSColor colorWithDeviceRed:0.5 green:0 blue:0 alpha:1.0] : [NSColor darkGrayColor])
		setStroke];
	[frame stroke];
}

// Preserve IBOutlets we require across archiving/dearchiving
- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	if (self) {
	    progressIndicator   = [decoder decodeObjectForKey:@"progressIndicator"];
	    imageView           = [decoder decodeObjectForKey:@"imageView"];
	    errorLabel          = [decoder decodeObjectForKey:@"errorLabel"];
	}
	return self;
}

// Preserve IBOutlets we require across archiving/dearchiving
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:progressIndicator     forKey:@"progressIndicator"];
    [encoder encodeObject:imageView             forKey:@"imageView"];
    [encoder encodeObject:errorLabel   forKey:@"errorLabel"];
}
@end
