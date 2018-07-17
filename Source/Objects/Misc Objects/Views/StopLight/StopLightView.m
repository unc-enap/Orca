//
//  StopLightView.m
//  Orca
//
//  Created by Mark Howe on 4/27/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "StopLightView.h"
#import "ORDotImage.h"

@implementation StopLightView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setGoLight:[ORDotImage bigDotWithColor:[NSColor greenColor]]];
        [self setCautionLight:[ORDotImage bigDotWithColor:[NSColor yellowColor]]];
        [self setStopLight:[ORDotImage bigDotWithColor:[NSColor redColor]]];
        [self setOffLight:[ORDotImage bigDotWithColor:[NSColor lightGrayColor]]];
    }
    return self;
}

- (void) dealloc
{
    [offLight release];
    [goLight release];
    [cautionLight release];
    [stopLight release];
    [super dealloc];
}
- (void) hideCautionLight
{
    hideCautionLight = YES;
}

#pragma mark ***Accessors

- (ORDotImage*) offLight
{
    return offLight;
}

- (void) setOffLight:(ORDotImage*)aOffLight
{
    [aOffLight retain];
    [offLight release];
    offLight = aOffLight;
}

- (int) state
{
    return state;
}

- (void) setState:(int)aState
{
    state = aState;
    [self setNeedsDisplay:YES];
}

- (ORDotImage*) goLight
{
    return goLight;
}

- (void) setGoLight:(ORDotImage*)aGoLight
{
    [aGoLight retain];
    [goLight release];
    goLight = aGoLight;
}

- (ORDotImage*) cautionLight
{
    return cautionLight;
}

- (void) setCautionLight:(ORDotImage*)aCautionLight
{
    [aCautionLight retain];
    [cautionLight release];
    cautionLight = aCautionLight;
}

- (ORDotImage*) stopLight
{
    return stopLight;
}

- (void) setStopLight:(ORDotImage*)aStopLight
{
    [aStopLight retain];
    [stopLight release];
    stopLight = aStopLight;

}

- (void)drawRect:(NSRect)rect 
{    
    [super drawRect:rect];
    NSRect frame = [self bounds];
    NSRect sourceRect = NSMakeRect(0,0,[goLight size].width,[goLight size].height);
    if(state == kStoppedLight){
        [stopLight      drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:1];
    }
    else {
        [offLight      drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:1];
    }
    
    if(!hideCautionLight){
        frame.origin.y += 35;
        if(state == kCautionLight){
            [cautionLight drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:1];
        }
        else {
            [offLight      drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:1];
        }
    }
    
    frame.origin.y += 35;
    if(state == kGoLight){
        [goLight drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:1];
    }
    else {
        [offLight      drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:1];
    }
}

@end


