//
//  ORLevelMonitor.m
//  Orca
//
//  Created by Mark Howe on Sat Sept 2007.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORLevelMonitor.h"

#define kBugPad 10

@implementation ORLevelMonitor
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setTankColor:[NSColor colorWithCalibratedRed:.8 green:.8 blue:.9 alpha:1]];
        [self setContentsColor:[NSColor colorWithCalibratedRed:.7 green:1 blue:.7 alpha:.8]];
 		lowLevelBugImage = [[NSImage imageNamed:@"leftBug"] retain];
		hiLevelBugImage  = [[NSImage imageNamed:@"leftBug"] retain];
 		lowFillPointBugImage = [[NSImage imageNamed:@"rightBug"] retain];
		hiFillPointBugImage  = [[NSImage imageNamed:@"rightBug"] retain];

	}
    return self;
}

- (void) dealloc
{
	[lowFillPointBugImage release];
	[hiFillPointBugImage release];
	[lowLevelBugImage release];
	[hiLevelBugImage release];
	[levelGradient release];
	[tankGradient release];
	[tankColor release];
	[contentsColor release];
	[super dealloc];
}

- (void) awakeFromNib
{
	if(!tankColor)[self setTankColor:[NSColor whiteColor]];
	if(!contentsColor)[self setContentsColor:[NSColor greenColor]];
}

#pragma mark ¥¥¥Accessors
- (void) setShowFillPoints:(BOOL)aState
{
	showFillPoints = aState;
	[self setNeedsDisplay:YES];
}

- (void) setTankColor:(NSColor*)aColor
{
	[aColor retain];
	[tankColor release];
	tankColor = aColor;
	
	CGFloat red,green,blue,alpha;
	[tankColor  getRed:&red green:&green blue:&blue alpha:&alpha];
	
	red   *= .5;
	green *= .5;
	blue  *= .5;
	
	NSColor* endingColor = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];


	[tankGradient release];
	tankGradient = [[NSGradient alloc] initWithStartingColor:tankColor endingColor:endingColor];


    [self setNeedsDisplay: YES];
}

- (NSColor*) tankColor
{
	return tankColor;
}

- (void) setContentsColor:(NSColor*)aColor
{
	[aColor retain];
	[contentsColor release];
	contentsColor = aColor;
	
	CGFloat red,green,blue,alpha;
	[contentsColor getRed:&red green:&green blue:&blue alpha:&alpha];
	
	red   *= .5;
	green *= .5;
	blue  *= .5;
	
	NSColor* endingColor = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
	
	[levelGradient release];
	levelGradient = [[NSGradient alloc] initWithStartingColor:contentsColor endingColor:endingColor];

    [self setNeedsDisplay: YES];	
}

- (NSColor*) contentsColor
{
	return contentsColor;
}


#pragma mark ¥¥¥Drawing
- (void)drawRect:(NSRect)rect 
{
	NSRect b = [self bounds];
	b.origin.x += kBugPad;
	b.origin.y += kBugPad/2;
	b.size.height -= kBugPad;
	if(showFillPoints)	b.size.width -= 2*kBugPad;
	else				b.size.width -= kBugPad;
	
	[tankGradient drawInRect:NSMakeRect(kBugPad,kBugPad/2,b.size.width,b.size.height) angle:270.];

	if([dataSource respondsToSelector:@selector(levelMonitorLevel:)]){
		float level = [dataSource levelMonitorLevel:self]; //level will be a value from 0 - 100%
		float y =  b.size.height * level/100.;
		[levelGradient drawInRect:NSMakeRect(b.origin.x,b.origin.y,b.size.width,y) angle:270.];
	}
	else {
		[NSBezierPath fillRect:NSMakeRect(b.origin.x+1,50,b.size.width-2,b.size.height/3-2)];
	}

	[[NSColor blackColor] set];
	[NSBezierPath setDefaultLineWidth:.5];
	float lowAlarmLevel = 25;
	float hiAlarmLevel = 75;
	if([dataSource respondsToSelector:@selector(levelMonitorLowAlarmLevel:)]){
		lowAlarmLevel = b.origin.y + b.size.height * [dataSource levelMonitorLowAlarmLevel:self]/100.;
	}
	[lowLevelBugImage drawAtPoint:NSMakePoint(0, lowAlarmLevel-[lowLevelBugImage size].height/2.) fromRect:[lowLevelBugImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(kBugPad,lowAlarmLevel) toPoint:NSMakePoint(b.size.width+kBugPad,lowAlarmLevel)];

	if([dataSource respondsToSelector:@selector(levelMonitorHiAlarmLevel:)]){
		hiAlarmLevel = b.origin.y + b.size.height * [dataSource levelMonitorHiAlarmLevel:self]/100.;
	}
	[hiLevelBugImage drawAtPoint:NSMakePoint(0, hiAlarmLevel-[lowLevelBugImage size].height/2.) fromRect:[hiLevelBugImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(kBugPad,hiAlarmLevel) toPoint:NSMakePoint(b.size.width+kBugPad,hiAlarmLevel)];

	if(showFillPoints){
		float lowFillPoint = 25;
		float hiFillPoint = 75;
		if([dataSource respondsToSelector:@selector(levelMonitorLowFillPoint:)]){
			lowFillPoint = b.origin.y + b.size.height * [dataSource levelMonitorLowFillPoint:self]/100.;
		}
		[lowFillPointBugImage drawAtPoint:NSMakePoint(b.size.width+kBugPad, lowFillPoint-[lowFillPointBugImage size].height/2.) fromRect:[lowFillPointBugImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];

		[NSBezierPath strokeLineFromPoint:NSMakePoint(kBugPad,lowFillPoint) toPoint:NSMakePoint(b.size.width+kBugPad,lowFillPoint)];
		
		if([dataSource respondsToSelector:@selector(levelMonitorHiFillPoint:)]){
			hiFillPoint = b.origin.y + b.size.height * [dataSource levelMonitorHiFillPoint:self]/100.;
		}
		[hiFillPointBugImage drawAtPoint:NSMakePoint(b.size.width+kBugPad, hiFillPoint-[hiFillPointBugImage size].height/2.) fromRect:[hiFillPointBugImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(kBugPad,hiFillPoint) toPoint:NSMakePoint(b.size.width+kBugPad,hiFillPoint)];
	}
	
	[NSBezierPath strokeRect:b];
}


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    if([decoder allowsKeyedCoding]){
        [self setTankColor:[decoder decodeObjectForKey:@"tankColor"]]; 
        [self setContentsColor:  [decoder decodeObjectForKey:@"contentsColor"]]; 
	}
	else {
        [self setTankColor:[decoder decodeObject]]; 
        [self setContentsColor:  [decoder decodeObject]]; 
	}
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    if([encoder allowsKeyedCoding]){
        [encoder encodeObject:tankColor forKey:@"tankColor"];
        [encoder encodeObject:contentsColor   forKey:@"contentsColor"];
	}
	else {
        [encoder encodeObject:tankColor];
        [encoder encodeObject:contentsColor];
	}
}

- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

- (void) mouseDown:(NSEvent*)event
{

	[[self undoManager] disableUndoRegistration];
    NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];

	NSRect b = [self bounds];
	b.origin.x += kBugPad;
	b.origin.y += kBugPad/2;
	b.size.height -= kBugPad;
	if(showFillPoints) b.size.width -= 2*kBugPad;
	else			   b.size.width -= kBugPad;

	movingLowAlarm		= NO;
	movingHiAlarm		= NO;
	movingLowFillPoint	= NO;
	movingHiFillPoint	= NO;
	
	if([dataSource respondsToSelector:@selector(levelMonitorLowAlarmLevel:)]){
		float orginalValue = [dataSource levelMonitorLowAlarmLevel:self];
		float lowAlarmLevel = b.origin.y + b.size.height * orginalValue/100.;

		NSRect r1 = NSMakeRect(0,lowAlarmLevel-kBugPad/2,kBugPad,kBugPad);
		NSRect r2 = NSMakeRect(b.origin.x,lowAlarmLevel-2,b.size.width,4);
		if(NSPointInRect(localPoint,r1) || NSPointInRect(localPoint,r2)){
			movingLowAlarm = YES;
			[dataSource setLevelMonitor:self lowAlarm:orginalValue];
			[[NSCursor closedHandCursor] set];
			[self setNeedsDisplay:YES];
			return;
		}
	}

	if([dataSource respondsToSelector:@selector(levelMonitorHiAlarmLevel:)]){
		float orginalValue = [dataSource levelMonitorHiAlarmLevel:self];
		float hiAlarmLevel = b.origin.y + b.size.height * orginalValue/100.;
		NSRect r3 = NSMakeRect(0,hiAlarmLevel-kBugPad/2,kBugPad,kBugPad);
		NSRect r4 = NSMakeRect(b.origin.x,hiAlarmLevel-2,b.size.width,4);
		if(NSPointInRect(localPoint,r3)|| NSPointInRect(localPoint,r4)){
			movingHiAlarm = YES;
			[dataSource setLevelMonitor:self hiAlarm:orginalValue];
			[[NSCursor closedHandCursor] set];
			[self setNeedsDisplay:YES];
			return;
		}
	}

	
	if([dataSource respondsToSelector:@selector(levelMonitorLowFillPoint:)]){
		float orginalValue = [dataSource levelMonitorLowFillPoint:self];
		float lowFillPoint = b.origin.y + b.size.height * orginalValue/100.;
		
		NSRect r1 = NSMakeRect([self bounds].size.width-kBugPad,lowFillPoint-kBugPad/2,kBugPad,kBugPad);
		NSRect r2 = NSMakeRect(b.origin.x,lowFillPoint-2,b.size.width,4);
		if(NSPointInRect(localPoint,r1) || NSPointInRect(localPoint,r2)){
			movingLowFillPoint = YES;
			[dataSource setLevelMonitor:self lowFillPoint:orginalValue];
			[[NSCursor closedHandCursor] set];
			[self setNeedsDisplay:YES];
			return;
		}
	}

	if([dataSource respondsToSelector:@selector(levelMonitorHiFillPoint:)]){
		float orginalValue = [dataSource levelMonitorHiFillPoint:self];
		float hiFillPoint = b.origin.y + b.size.height * orginalValue/100.;
		NSRect r3 = NSMakeRect([self bounds].size.width-kBugPad,hiFillPoint-kBugPad/2,kBugPad,kBugPad);
		NSRect r4 = NSMakeRect(b.origin.x,hiFillPoint-2,b.size.width,4);

		if(NSPointInRect(localPoint,r3)|| NSPointInRect(localPoint,r4)){
			movingHiFillPoint = YES;
			[dataSource setLevelMonitor:self hiFillPoint:orginalValue];
			[[NSCursor closedHandCursor] set];
			[self setNeedsDisplay:YES];
			return;
		}
	}
}

- (void) mouseDragged:(NSEvent*)event
{
	NSRect b = [self bounds];
	b.origin.x += kBugPad;
	b.origin.y += kBugPad/2;
	b.size.height -= kBugPad;
	if(showFillPoints) b.size.width -= 2*kBugPad;
	else			   b.size.width -= kBugPad;

	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	float level = 100.*(localPoint.y - b.origin.y)/b.size.height;
	if(movingLowAlarm){
		if([dataSource respondsToSelector:@selector(setLevelMonitor:lowAlarm:)]){
			[dataSource setLevelMonitor:self lowAlarm:level];
		}
	}
	else if(movingHiAlarm){
		if([dataSource respondsToSelector:@selector(setLevelMonitor:hiAlarm:)]){
			[dataSource setLevelMonitor:self hiAlarm:level];
		}
	}
	else if(movingLowFillPoint){
		if([dataSource respondsToSelector:@selector(setLevelMonitor:lowFillPoint:)]){
			[dataSource setLevelMonitor:self lowFillPoint:level];
		}
	}
	else if(movingHiFillPoint){
		if([dataSource respondsToSelector:@selector(setLevelMonitor:hiFillPoint:)]){
			[dataSource setLevelMonitor:self hiFillPoint:level];
		}
	}
	
	[self setNeedsDisplay:YES];
}

- (void) mouseUp:(NSEvent*)event
{
	[[self undoManager] enableUndoRegistration];
	
	NSRect b = [self bounds];
	b.origin.x += kBugPad;
	b.origin.y += kBugPad/2;
	b.size.height -= kBugPad;
	if(showFillPoints) b.size.width -= 2*kBugPad;
	else			   b.size.width -= kBugPad;
	
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	float level = 100.*(localPoint.y - b.origin.y)/b.size.height;

	if(movingLowAlarm){
		if([dataSource respondsToSelector:@selector(setLevelMonitor:lowAlarm:)]){
			[dataSource setLevelMonitor:self lowAlarm:level];
		}
	}
	else if(movingHiAlarm){
		if([dataSource respondsToSelector:@selector(setLevelMonitor:hiAlarm:)]){
			[dataSource setLevelMonitor:self hiAlarm:level];
		}
	}
	
	if(movingLowFillPoint){
		if([dataSource respondsToSelector:@selector(setLevelMonitor:lowFillPoint:)]){
			[dataSource setLevelMonitor:self lowFillPoint:level];
		}
	}
	else if(movingHiFillPoint){
		if([dataSource respondsToSelector:@selector(setLevelMonitor:hiFillPoint:)]){
			[dataSource setLevelMonitor:self hiFillPoint:level];
		}
	}
	
	if([dataSource respondsToSelector:@selector(loadAlarmsToHardware)]){
		[dataSource loadAlarmsToHardware];
	}
	[NSCursor pop];

	movingLowAlarm = NO;
	movingHiAlarm = NO;
	movingLowFillPoint = NO;
	movingHiFillPoint = NO;
	[self setNeedsDisplay:YES];
    [[self window] resetCursorRects];
}

- (BOOL)mouseDownCanMoveWindow
{
    return NO;
}

- (void) resetCursorRects
{
	NSRect b = [self bounds];
	b.origin.x += kBugPad;
	b.origin.y += kBugPad/2;
	b.size.height -= kBugPad;
	if(showFillPoints) b.size.width -= 2*kBugPad;
	else			   b.size.width -= kBugPad;

	if([dataSource respondsToSelector:@selector(levelMonitorLowAlarmLevel:)]){
		float lowAlarmLevel = [dataSource levelMonitorLowAlarmLevel:self];
		NSRect r1 = NSMakeRect(0,lowAlarmLevel-kBugPad/2,kBugPad,kBugPad);
		NSRect r2 = NSMakeRect(b.origin.x,lowAlarmLevel-3,b.size.width,6);
		[self addCursorRect:r1 cursor:[NSCursor openHandCursor]];
		[self addCursorRect:r2 cursor:[NSCursor openHandCursor]];
	}
	
	if([dataSource respondsToSelector:@selector(levelMonitorHiAlarmLevel:)]){
		float hiAlarmLevel = [dataSource levelMonitorHiAlarmLevel:self];
		NSRect r3 = NSMakeRect(0,hiAlarmLevel-kBugPad/2,kBugPad,kBugPad);
		NSRect r4 = NSMakeRect(b.origin.x,hiAlarmLevel-3,b.size.width,6);
		[self addCursorRect:r3 cursor:[NSCursor openHandCursor]];
		[self addCursorRect:r4 cursor:[NSCursor openHandCursor]];
	}
	if([dataSource respondsToSelector:@selector(levelMonitorLowFillPoint:)]){
		float lowFillPoint = [dataSource levelMonitorLowFillPoint:self];
		NSRect r1 = NSMakeRect([self bounds].size.width-kBugPad,lowFillPoint-kBugPad/2,kBugPad,kBugPad);
		NSRect r2 = NSMakeRect(kBugPad,lowFillPoint-3,b.size.width,6);
		[self addCursorRect:r1 cursor:[NSCursor openHandCursor]];
		[self addCursorRect:r2 cursor:[NSCursor openHandCursor]];
	}
	
	if([dataSource respondsToSelector:@selector(levelMonitorHiFillPoint:)]){
		float hiFillPoint = [dataSource levelMonitorHiFillPoint:self];
		NSRect r3 = NSMakeRect([self bounds].size.width-kBugPad,hiFillPoint-kBugPad/2,kBugPad,kBugPad);
		NSRect r4 = NSMakeRect(kBugPad,hiFillPoint-3,b.size.width,6);
		[self addCursorRect:r3 cursor:[NSCursor openHandCursor]];
		[self addCursorRect:r4 cursor:[NSCursor openHandCursor]];
	}
	
}

@end
