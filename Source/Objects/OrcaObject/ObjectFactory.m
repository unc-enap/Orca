//
//  ObjectFactory.m
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


#import "ObjectFactory.h"
#import "OrcaObject.h"

@interface ObjectFactory (private)
- (void) setObject:(id)anObject;
@end

@implementation ObjectFactory

#pragma mark ¥¥¥Initialization
- (id) initWithFrame:(NSRect)frameRect
{
	self=[super initWithFrame:frameRect];
	[self setImagePosition:NSImageOnly];
	[self setBordered:NO];
	return self;
}

- (void) dealloc
{
    [object release];
    [super dealloc];
}

#pragma mark ¥¥¥Mouse Events
-(BOOL) acceptsFirstMouse:(NSEvent*)event
{
    return YES;
}

- (BOOL) shouldDelayWindowOrderingForEvent:(NSEvent*)theEvent
{
    return YES;
}

-(void)mouseDown:(NSEvent*)theEvent
{
    [NSApp preventWindowOrdering];
    
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:@"ORGroupDragBoardItem", nil] owner:self];
    
    // the actual data doesn't matter since We're not really putting anything on the pasteboard. We are
    //using it to control the process. We save the objects locally and will provide them on request.
    [pboard setData:[NSData data] forType:@"ORObjArrayPtrPBType"]; 
    
    [self makeObject];
    NSRect bds = [object bounds];
    NSImage *theImage = [[NSImage alloc] initWithSize:bds.size];
    [theImage lockFocus];
    [object drawSelf:bds withTransparency:.75 ];
    [theImage unlockFocus];
    float w = [self bounds].size.width;
    float h = [self bounds].size.height;
    [self dragImage : theImage
                 at : NSMakePoint(w/2. - [theImage size].width/2.,h/2+[theImage size].height/2.)
             offset : NSMakeSize(0.0, 0.0)
              event : theEvent
         pasteboard : pboard
             source : self
          slideBack : YES ];
    
    [theImage release];
}


- (void) mouseUp:(NSEvent*)theEvent
{
	[object release];
	object = nil;
}
- (BOOL)ignoreModifierKeysWhileDragging
{
    return YES;
}

#pragma mark ¥¥¥Pasteboard and Dragging
- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
	//load the saved objects pointers into the paste board.
    NSArray* pointerArray = [NSArray arrayWithObject:[NSNumber numberWithLong:(unsigned long)object]];
    
    NSMutableData *itemData = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:itemData];
    //PH comment out so archiver uses the default binary plist format
    //[archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
    [archiver encodeObject:pointerArray forKey:@"ORObjArrayPtrPBType"];
    [archiver finishEncoding];
    [archiver release];
    
    [sender setData:itemData forType:@"ORGroupDragBoardItem"];
}


- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
    return NSDragOperationCopy;
}

#pragma mark ¥¥¥Factory method
- (void) makeObject
{
    if(!object)[self setObject:[ObjectFactory makeObject:[self toolTip]]];
}

+ (id) makeObject:(NSString*)aClassName
{
    Class aClass = NSClassFromString(aClassName);
    id obj		 = [[aClass alloc] init];
	
    if([obj respondsToSelector:@selector(setUpImage)])		[obj setUpImage];
    if([obj respondsToSelector:@selector(makeConnectors)])	[obj makeConnectors];
    if([obj respondsToSelector:@selector(setHighlighted:)])	[obj setHighlighted:YES];
	
    return [obj autorelease];
}

@end


@implementation ObjectFactory (private)
- (void) setObject:(id)anObject
{
    [anObject retain];
    [object release];
    object = anObject;
}
@end


