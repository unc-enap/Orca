//
//  OrcaObjectFactory.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 30 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

#import "OrcaObjectFactory.h"

@implementation OrcaObjectFactory

#pragma mark ¥¥¥Initialization
- (void)awakeFromNib
{
	[[(ORAppDelegate*)[NSApp delegate] undoManager] disableUndoRegistration];
	
	//these are objects that need to draw themselves in the catalog....
	//otherwise we make the objects on demand when the user clicks
	NSArray* specialObjectsToPreMake = [NSArray arrayWithObjects:
										@"ORFanInModel",
										@"ORFanOutModel",
										@"ORJoinerModel",
										@"ORSplitterModel",
										nil];
	
	if([specialObjectsToPreMake containsObject:[self toolTip]]){
		[self makeObject];
	}
	
	[[(ORAppDelegate*)[NSApp delegate] undoManager] enableUndoRegistration];
}

- (BOOL) isFlipped
{
	return NO;
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    [object drawSelf:rect];
}

#pragma mark ¥¥¥Mouse Events
-(void)mouseDown:(NSEvent*)theEvent
{
	[[(ORAppDelegate*)[NSApp delegate] undoManager] disableUndoRegistration];
    [self makeObject];
	[[(ORAppDelegate*)[NSApp delegate] undoManager] enableUndoRegistration];
	
    [NSApp preventWindowOrdering];
    
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:ORGroupDragBoardItem, nil] owner:self];
    
    // the actual data doesn't matter since We're not really putting anything on the pasteboard. We are
    //using it to control the process. We save the objects locally and will provide them on request.
    [pboard setData:[NSData data] forType:ORObjArrayPtrPBType]; 
    
    NSRect bds = [object bounds];
    NSImage *theImage = [[NSImage alloc] initWithSize:bds.size];
    [theImage lockFocus];
    [object drawSelf:bds withTransparency:1.0 ];
    [theImage unlockFocus];
    
    float w = [self bounds].size.width;
    float h = [self bounds].size.height;
    NSPoint atPoint;
	if([self isFlipped]){
		atPoint = NSMakePoint(w/2. - [theImage size].width/2.,h/2+[theImage size].height/2.);
	}
	else {
		atPoint = NSMakePoint(w/2. - [theImage size].width/2.,0);
	}
	
    [self dragImage : theImage
                 at : atPoint
             offset : NSMakeSize(0.0, 0.0)
              event : theEvent
         pasteboard : pboard
             source : self
          slideBack : YES ];
    
    [theImage release];
    
}

- (void) mouseUp:(NSEvent*)theEvent
{
}

- (void) makeObject
{
	[super makeObject];
    if([object respondsToSelector:@selector(setHighlighted:)])	[object setHighlighted:NO];
}

@end
