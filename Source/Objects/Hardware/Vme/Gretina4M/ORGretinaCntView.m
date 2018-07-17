//
//  ORGretinaCntView.m
//  Orca
//
//  Created by Mark Howe on 1/25/13.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
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

#import "ORGretinaCntView.h"
#import "ORGretina4MController.h"

#define kBugPad 10

@implementation ORGretinaCntView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
 		bugImage   = [[NSImage imageNamed:@"topBug"] retain];
        plotGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:.75 alpha:1.0]];

        b               = [self bounds];
        b.origin.x      += kBugPad/2.;
        b.size.height   -= kBugPad;
        b.size.width    -= kBugPad;
	}
    return self;
}

- (void) dealloc
{
	[bugImage release];
	[plotGradient release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self loadLocalFields];
}

#pragma mark ¥¥¥Drawing
- (void)drawRect:(NSRect)rect 
{
	[plotGradient drawInRect:b angle:270.];

    if([self anythingSelected]){
        
        [self loadLocalFields];
        
        [[NSColor blackColor] set];
        [NSBezierPath setDefaultLineWidth:.5];

        //draw the flat top counter
        [bugImage drawAtPoint:NSMakePoint( postRisingEdgeBugX-kBugPad/2.,b.size.height) fromRect:[bugImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(postRisingEdgeBugX,0) toPoint:NSMakePoint(postRisingEdgeBugX,b.size.height)];
        
        //draw the post rising edge counter
        [bugImage drawAtPoint:NSMakePoint( risingEdgeBugX-kBugPad/2.,b.size.height) fromRect:[bugImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(risingEdgeBugX,0) toPoint:NSMakePoint(risingEdgeBugX,b.size.height)];
     
        //draw the pre rising edge counter
        [bugImage drawAtPoint:NSMakePoint( preRisingEdgeBugX-kBugPad/2.,b.size.height) fromRect:[bugImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(preRisingEdgeBugX,0) toPoint:NSMakePoint(preRisingEdgeBugX,b.size.height)];

        [NSBezierPath setDefaultLineWidth:2.];
        [[NSColor redColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(kBugPad/2., 10) toPoint:NSMakePoint(preRisingEdgeBugX, 10)];
     
        [[NSColor blueColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(preRisingEdgeBugX, 10) toPoint:NSMakePoint(risingEdgeBugX, 10)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(risingEdgeBugX, 10) toPoint:NSMakePoint(risingEdgeBugX, 50)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(risingEdgeBugX, 50) toPoint:NSMakePoint(postRisingEdgeBugX, 50)];

        [[NSColor redColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(postRisingEdgeBugX, 50) toPoint:NSMakePoint(b.size.width+kBugPad/2, 50)];

        [NSBezierPath setDefaultLineWidth:1.];
        [[NSColor blackColor] set];
        
        int postPlusPre   = [postReField intValue] + [preReField intValue];
        NSColor* reColor;
        if(postPlusPre<1024)reColor = [NSColor blackColor];
        else                reColor = [NSColor redColor];
        NSString* ps = [NSString stringWithFormat:@"%d",postPlusPre];
        
        NSFont* theFont = [NSFont fontWithName:@"Geneva" size:9];
        NSDictionary* theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,reColor,NSForegroundColorAttributeName,nil];
        NSAttributedString* s = [[NSAttributedString alloc] initWithString:ps attributes:theAttributes];
        NSSize stringSize = [s size];
        float x = preRisingEdgeBugX + (postRisingEdgeBugX-preRisingEdgeBugX)/2. - stringSize.width/2.;
        float y = b.size.height-stringSize.height-5;
        [s drawAtPoint:NSMakePoint(x,y)];
        [s release];
 
        int risingEdge   = 2019 - ([flatTopField intValue] + [postReField intValue]);
        ps = [NSString stringWithFormat:@"%d",risingEdge];
        theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil];
        s = [[NSAttributedString alloc] initWithString:ps attributes:theAttributes];
        stringSize = [s size];
        x = risingEdgeBugX - stringSize.width/2.;
        y = b.size.height-stringSize.height-45;
        [s drawAtPoint:NSMakePoint(x,y)];
        [s release];

        
        
        
        
        if(baseline<1024)reColor = [NSColor blackColor];
        else             reColor = [NSColor redColor];
        
        NSString* bls = [NSString stringWithFormat:@"%d",baseline];
        theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,reColor,NSForegroundColorAttributeName,nil];
        s = [[NSAttributedString alloc] initWithString:bls attributes:theAttributes];
        stringSize = [s size];
        x = MAX(kBugPad/2.,kBugPad/2. + (preRisingEdgeBugX-kBugPad/2.)/2. - stringSize.width/2.);
        [s drawAtPoint:NSMakePoint(x,b.size.height-stringSize.height-5)];
        [s release];

        if([flatTopField intValue]<1024)reColor = [NSColor blackColor];
        else                            reColor = [NSColor redColor];
        
        NSString* fts = [NSString stringWithFormat:@"%d",[flatTopField intValue]];
        theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,reColor,NSForegroundColorAttributeName,nil];
        s = [[NSAttributedString alloc] initWithString:fts attributes:theAttributes];
        stringSize = [s size];
        x = postRisingEdgeBugX + (b.size.width-postRisingEdgeBugX)/2. - stringSize.width/2.;
        if(x + stringSize.width/2 > b.size.width)x = b.size.width-stringSize.width;
        [s drawAtPoint:NSMakePoint(x,b.size.height-stringSize.height-5)];
        [s release];

    }
	[NSBezierPath strokeRect:b];
}

- (BOOL) anythingSelected
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i])return YES;
    }
    return NO;
}

- (void) initBugs
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i]){
            int ftCnt       = [[dataSource model] ftCnt:i];
            int postrecnt   = [[dataSource model] postrecnt:i];
            int prerecnt    = [[dataSource model] prerecnt:i];
                        
            postRisingEdgeBugX  = b.origin.x + (2019 - ftCnt)* b.size.width/2019;
            risingEdgeBugX      = b.origin.x + (2019 - ftCnt - postrecnt)* b.size.width/2019;
            preRisingEdgeBugX   = b.origin.x + (2019 - ftCnt - postrecnt-prerecnt)* b.size.width/2019;
            break;
        }
    }
}

- (void) loadLocalFields
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i]){
            [preReField setIntValue:[[dataSource model] prerecnt:i]];
            [postReField setIntValue:[[dataSource model] postrecnt:i]];
            [flatTopField setIntValue:[[dataSource model] ftCnt:i]];
            baseline = [[dataSource model] baseLineLength:i];
            break;
        }
    }
}

- (void) applyConstrainsts
{
    float minX = b.origin.x;
    float maxX = b.size.width + kBugPad/2.;
    
    if(movingPostRisingEdge){
        if(postRisingEdgeBugX < minX)      postRisingEdgeBugX = minX;
        else if(postRisingEdgeBugX > maxX) postRisingEdgeBugX = maxX;

        if(postRisingEdgeBugX < risingEdgeBugX+1)      postRisingEdgeBugX = risingEdgeBugX+1;
    }
    else if(movingRisingEdge){
        if(risingEdgeBugX < minX)      risingEdgeBugX = minX;
        else if(risingEdgeBugX > maxX) risingEdgeBugX = maxX;

        if(risingEdgeBugX < preRisingEdgeBugX+1)risingEdgeBugX = preRisingEdgeBugX+1;
        else if(risingEdgeBugX > postRisingEdgeBugX-1)risingEdgeBugX = postRisingEdgeBugX-1;
    }
    else if(movingPreRisingEdge){
        if(preRisingEdgeBugX < minX)      preRisingEdgeBugX = minX;
        else if(preRisingEdgeBugX > maxX) preRisingEdgeBugX = maxX;

        if(preRisingEdgeBugX > risingEdgeBugX-1)preRisingEdgeBugX = risingEdgeBugX-1;
    }
}

- (void) setValues:(BOOL)finalValues
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i]){
            [self setValues:i final:finalValues];
        }
    }
}

- (void) setValues:(short)channel final:(BOOL)finalValues
{
	if(!finalValues)[[(ORAppDelegate*)[NSApp delegate] undoManager] disableUndoRegistration];
    
    int ftCnt = 2019 - (postRisingEdgeBugX-b.origin.x)*2019/b.size.width;
    [[dataSource model] setFtCnt:channel withValue:ftCnt];
    
    int postCnt = ((postRisingEdgeBugX - risingEdgeBugX)-b.origin.x)*2019/b.size.width;
    [[dataSource model] setPostrecnt:channel withValue:postCnt];
 
    int preCnt = ((risingEdgeBugX - preRisingEdgeBugX)-b.origin.x)*2019/b.size.width;
    [[dataSource model] setPrerecnt:channel withValue:preCnt];

    
	if(!finalValues)[[(ORAppDelegate*)[NSApp delegate] undoManager] enableUndoRegistration];
}

#pragma mark ¥¥¥Archival
- (void) mouseDown:(NSEvent*)event
{
    optionKeyDown = ([event modifierFlags] & NSEventModifierFlagOption)!=0;

	[[self undoManager] disableUndoRegistration];
    NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    if(optionKeyDown){
        postXDelta   = fabs(postRisingEdgeBugX - risingEdgeBugX);
        preXDelta    = fabs(risingEdgeBugX - preRisingEdgeBugX);
    }
    movingPreRisingEdge		= NO;
    movingRisingEdge        = NO;
    movingPostRisingEdge    = NO;

    if(NSPointInRect(localPoint,NSMakeRect(preRisingEdgeBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad)) || NSPointInRect(localPoint,NSMakeRect(preRisingEdgeBugX-2,0,4,b.size.height))){
        movingPreRisingEdge = YES;
    }

    else if(NSPointInRect(localPoint,NSMakeRect(postRisingEdgeBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad)) || NSPointInRect(localPoint,NSMakeRect(postRisingEdgeBugX-2,0,4,b.size.height))){
        movingPostRisingEdge = YES;
    }
    
    else if(NSPointInRect(localPoint,NSMakeRect(risingEdgeBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad)) || NSPointInRect(localPoint,NSMakeRect(risingEdgeBugX-2,0,4,b.size.height))){
        movingRisingEdge = YES;
    }
    
     
    if(movingPostRisingEdge || movingRisingEdge || movingPreRisingEdge){
        [[NSCursor closedHandCursor] set];
        [self setNeedsDisplay:YES];
    }
 }

- (void) mouseDragged:(NSEvent*)event
{
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    if(optionKeyDown){
        
        float newPreRisingEdgeBugX = 0.0;
        float newRisingEdgeBugX = 0.0;
        float newPostRisingEdgeBugX = 0.0;
        
        if(movingPreRisingEdge){
            newPreRisingEdgeBugX   = localPoint.x;
            newRisingEdgeBugX      = newPreRisingEdgeBugX + preXDelta;
            newPostRisingEdgeBugX  = newPreRisingEdgeBugX +  postXDelta;
        }
        else if(movingRisingEdge){
            newRisingEdgeBugX      = localPoint.x;
            newPreRisingEdgeBugX   = newRisingEdgeBugX - preXDelta;
            newPostRisingEdgeBugX  = newRisingEdgeBugX +  postXDelta;
        }
        else if(movingPostRisingEdge){
            newPostRisingEdgeBugX  = localPoint.x;
            newRisingEdgeBugX      = newPostRisingEdgeBugX - postXDelta;
            newPreRisingEdgeBugX   = newRisingEdgeBugX - preXDelta;
        }
            
        if(movingPreRisingEdge || movingRisingEdge || movingPostRisingEdge){
            float minX = b.origin.x;
            float maxX = b.size.width + kBugPad/2.;
            if(newPreRisingEdgeBugX>minX && newPostRisingEdgeBugX<maxX){
                preRisingEdgeBugX   = newPreRisingEdgeBugX;
                risingEdgeBugX      = newRisingEdgeBugX;
                postRisingEdgeBugX  = newPostRisingEdgeBugX;
            }
        }
    }
    else {
        if(movingPostRisingEdge)        postRisingEdgeBugX  = localPoint.x;
        else if(movingRisingEdge)       risingEdgeBugX      = localPoint.x;
        else if(movingPreRisingEdge)    preRisingEdgeBugX   = localPoint.x;
    }
    
    if(movingPostRisingEdge || movingRisingEdge || movingPreRisingEdge){
        [self applyConstrainsts];
        [self setValues:NO];
        [self loadLocalFields];
        [self setNeedsDisplay:YES];
    }
}

- (void) mouseUp:(NSEvent*)event
{
	[[self undoManager] enableUndoRegistration];
    
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    if(optionKeyDown){
        
        float newPreRisingEdgeBugX  = 0.0;
        float newRisingEdgeBugX     = 0.0;
        float newPostRisingEdgeBugX = 0.0;
        
        if(movingPreRisingEdge){
            newPreRisingEdgeBugX   = localPoint.x;
            newRisingEdgeBugX      = newPreRisingEdgeBugX + preXDelta;
            newPostRisingEdgeBugX  = newPreRisingEdgeBugX +  postXDelta;
        }
        else if(movingRisingEdge){
            newRisingEdgeBugX      = localPoint.x;
            newPreRisingEdgeBugX   = newRisingEdgeBugX - preXDelta;
            newPostRisingEdgeBugX  = newRisingEdgeBugX +  postXDelta;
        }
        else if(movingPostRisingEdge){
            newPostRisingEdgeBugX  = localPoint.x;
            newRisingEdgeBugX      = newPostRisingEdgeBugX - postXDelta;
            newPreRisingEdgeBugX   = newRisingEdgeBugX - preXDelta;
        }
        
        if(movingPreRisingEdge || movingRisingEdge || movingPostRisingEdge){
            float minX = b.origin.x;
            float maxX = b.size.width + kBugPad/2.;
            
            if(newPreRisingEdgeBugX>minX && newPostRisingEdgeBugX<maxX){
                preRisingEdgeBugX   = newPreRisingEdgeBugX;
                risingEdgeBugX      = newRisingEdgeBugX;
                postRisingEdgeBugX  = newPostRisingEdgeBugX;
            }
        }
    }

    else {

        if(movingPostRisingEdge)        postRisingEdgeBugX = localPoint.x;
        else if(movingRisingEdge)       risingEdgeBugX = localPoint.x;
        else if(movingPreRisingEdge)    preRisingEdgeBugX = localPoint.x;
        
        if(movingPostRisingEdge || movingRisingEdge || movingPreRisingEdge){
            [self applyConstrainsts];
            [self setValues:YES];
            [self setNeedsDisplay:YES];
            [self loadLocalFields];
            [NSCursor pop];
        }
	}

	optionKeyDown           = NO;
	movingPreRisingEdge     = NO;
	movingRisingEdge        = NO;
	movingPostRisingEdge    = NO;
    
    [[self window] resetCursorRects];
}

- (BOOL)mouseDownCanMoveWindow
{
    return NO;
}

- (void) resetCursorRects
{    
    NSRect r1 = NSMakeRect(postRisingEdgeBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad);
    NSRect r2 = NSMakeRect(postRisingEdgeBugX-2,0,4,b.size.height);
    [self addCursorRect:r1 cursor:[NSCursor openHandCursor]];
    [self addCursorRect:r2 cursor:[NSCursor openHandCursor]];

    r1 = NSMakeRect(risingEdgeBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad);
    r2 = NSMakeRect(risingEdgeBugX-2,0,4,b.size.height);
    [self addCursorRect:r1 cursor:[NSCursor openHandCursor]];
    [self addCursorRect:r2 cursor:[NSCursor openHandCursor]];

    r1 = NSMakeRect(preRisingEdgeBugX-kBugPad/2.,b.size.height,kBugPad,kBugPad);
    r2 = NSMakeRect(preRisingEdgeBugX-2,0,4,b.size.height);
    [self addCursorRect:r1 cursor:[NSCursor openHandCursor]];
    [self addCursorRect:r2 cursor:[NSCursor openHandCursor]];
}

- (int)  firstOneSelected
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i])return i;
    }
    return -1;
}

- (IBAction) tweakFlatTopCounts:(id)sender
{
    int firstOneSelected = [self firstOneSelected];
    if(firstOneSelected >= 0){
        int ftCnt       = [[dataSource model] ftCnt:firstOneSelected] + ([sender tag]?1:-1);
        
        int i;
        for(i=0;i<kNumGretina4MChannels;i++){
            if([[dataSource model]easySelected:i])[[dataSource model] setFtCnt:i withValue:ftCnt];
        }
        movingPostRisingEdge  = YES;
        [self applyConstrainsts];
        [self loadLocalFields];
        [self initBugs];
        movingPostRisingEdge  = NO;
        [self setNeedsDisplay:YES];
    }
}

- (IBAction) tweakPostReCounts:(id)sender
{
    int firstOneSelected = [self firstOneSelected];
    if(firstOneSelected >= 0){
        int postrecnt   = [[dataSource model] postrecnt:firstOneSelected]+([sender tag]?1:-1);
        int i;
        for(i=0;i<kNumGretina4MChannels;i++){
            if([[dataSource model]easySelected:i])[[dataSource model] setPostrecnt:i withValue:postrecnt];
        }
        movingRisingEdge  = YES;
        [self applyConstrainsts];
        [self loadLocalFields];
        [self initBugs];
        movingRisingEdge  = YES;
        [self setNeedsDisplay:YES];
    }
}

- (IBAction) tweakPreReCounts:(id)sender
{
    int firstOneSelected = [self firstOneSelected];
    if(firstOneSelected >= 0){
        int prerecnt    = [[dataSource model] prerecnt:firstOneSelected] + ([sender tag]?1:-1);
        int i;
        for(i=0;i<kNumGretina4MChannels;i++){
            if([[dataSource model]easySelected:i])[[dataSource model] setPrerecnt:i withValue:prerecnt];
        }
        movingPreRisingEdge  = YES;
        [self applyConstrainsts];
        [self loadLocalFields];
        [self initBugs];
        movingPreRisingEdge  = NO;
        [self setNeedsDisplay:YES];
    }
}

- (IBAction) flatTopCounts:(id)sender
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i])[[dataSource model] setFtCnt:i withValue:[sender intValue]];
    }
    [self applyConstrainsts];
    [self initBugs];
    [self setNeedsDisplay:YES];
}

- (IBAction) postReCounts:(id)sender
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i])[[dataSource model] setPostrecnt:i withValue:[sender intValue]];
    }
    [self applyConstrainsts];
    [self initBugs];
    [self setNeedsDisplay:YES];
    
}

- (IBAction) preReCounts:(id)sender
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        if([[dataSource model]easySelected:i])[[dataSource model] setPrerecnt:i withValue:[sender intValue]];
    }
    [self applyConstrainsts];
    [self initBugs];
    [self setNeedsDisplay:YES];
}


@end
