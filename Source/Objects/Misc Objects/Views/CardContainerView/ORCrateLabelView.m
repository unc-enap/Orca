//
//  ORCrateLabelView.m
//  test
//
//  Created by Mark Howe on 1/11/07.
//  Copyright 2007 University of North Carolina. All rights reserved.
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

#import "ORCrateLabelView.h"
#import "ORCard.h"
#import "ORCrate.h"
#import "OROrderedObjManager.h"

@implementation ORCrateLabelView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void) dealloc
{
	[ciImage release];
	[filter release];
	[super dealloc];
}

    
- (void) setShowLabels:(BOOL)aState
{
	showLabels = aState;
	[self forceRedraw];
}

- (void) forceRedraw
{
	if(!scheduledForRedraw){
		scheduledForRedraw = YES;
		[self performSelector:@selector(removeImage) withObject:self afterDelay:.01];
	}
}

- (void) removeImage
{
	[filter release];
	filter = nil;
	[ciImage release];
	ciImage = nil;
	[self setNeedsDisplay:YES];
	scheduledForRedraw = NO;
}

- (NSImage *)rotateIndividualImage: (NSImage *)image
                         clockwise: (BOOL)clockwise
{
    NSSize existingSize = [image size];
    NSSize newSize = NSMakeSize(existingSize.height,
                                existingSize.width);
    NSImage *rotatedImage = [[NSImage alloc] initWithSize:newSize];

    [rotatedImage lockFocus];

    NSAffineTransform *rotateTF = [NSAffineTransform transform];
    NSPoint centerPoint = NSMakePoint(newSize.width / 2,
                                      newSize.height / 2);

    [rotateTF translateXBy: centerPoint.x yBy: centerPoint.y];
    [rotateTF rotateByDegrees: (clockwise) ? -90 : 90];
    [rotateTF translateXBy: -centerPoint.y yBy: -centerPoint.x];
    [rotateTF concat];

    [image drawAtPoint:NSZeroPoint
                   fromRect:NSMakeRect(0, 0, existingSize.width,
                                       existingSize.height)
                   operation:NSCompositingOperationSourceOver
                   fraction:1.0];

    [rotatedImage unlockFocus];

    return [rotatedImage autorelease];
}

- (void) drawRect:(NSRect)rect
{
	if(!ciImage){
		int numSlots = [[self crate] maxNumberOfObjects];
		NSRect newRect = NSMakeRect(0,0,[self frame].size.height,[self frame].size.width);
		NSImage*  contentImage = [[NSImage alloc] initWithSize:newRect.size];

		[contentImage lockFocus];
		[[NSColor clearColor] set];
		[NSBezierPath fillRect:newRect]; 
		if(showLabels){
			NSFont* theFont = [NSFont fontWithName:@"Geneva" size:10];
			NSDictionary* attrib = [NSDictionary dictionaryWithObjectsAndKeys:
										theFont ,NSFontAttributeName,
										[NSColor blackColor],NSForegroundColorAttributeName,
										[NSColor lightGrayColor],NSBackgroundColorAttributeName,
										nil];
																			
			float slotWidth  = [self frame].size.width/(float)numSlots; 
			int i;
			for(i=0;i<numSlots;i++){
				id card = [[OROrderedObjManager for:[self crate]] objectInSlot:numSlots-i-1];
				if(card){
					int numSlotsUsed = [card numberSlotsUsed];
					NSString* shortName = [card shortName];
					NSAttributedString* s = [[NSAttributedString alloc] initWithString:shortName attributes:attrib];
					NSSize textSize = [s size];
					float y = slotWidth*i + (slotWidth*numSlotsUsed)/2. - textSize.height/2.;
					[s drawAtPoint:NSMakePoint(0,y)];
					[s release];
					int skip;
					for(skip=0;skip<numSlotsUsed-1;skip++){
						i++;
					}
				}
			}
		}
		[contentImage unlockFocus];
		
		// convert NSImage to bitmap
		NSData*			  tiffData = [[self rotateIndividualImage:contentImage clockwise:NO] TIFFRepresentation];
		NSBitmapImageRep* bitmap   = [NSBitmapImageRep imageRepWithData:tiffData];

		ciImage = [[CIImage alloc] initWithBitmapImageRep:bitmap]; 
		[contentImage release];
	}
	
    CGRect  cg = CGRectMake(NSMinX(rect), NSMinY(rect), NSWidth(rect), NSHeight(rect));
    
	CIContext* context = [[NSGraphicsContext currentContext] CIContext];

    if(filter == nil){
        filter = [CIFilter filterWithName:@"CIPerspectiveTransform" keysAndValues: 
            @"inputImage",		ciImage,
            @"inputTopLeft",	[CIVector vectorWithX:50 Y:80], 
            @"inputTopRight",	[CIVector vectorWithX:[self frame].size.width-50 Y:80], 
            @"inputBottomRight",[CIVector vectorWithX:[self frame].size.width Y:0], 
            @"inputBottomLeft", [CIVector vectorWithX:0 Y:0], 
			nil];
        [filter retain];
    }

	if (context != nil){
		[context drawImage: [filter valueForKey: @"outputImage"]
			inRect: cg  fromRect: cg];
	}
}

- (ORCrate*) crate
{
	id group = [crateView group];
	if([group isKindOfClass:[ORCrate class]])return (ORCrate*)group;
	else return nil;
}

@end
